// ignore_for_file: avoid_print
import 'package:mcp_models/mcp_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// This example demonstrates the key workflows exposed by mcp_models under the
// MCP 2026-07-28 schema:
//
//  1. Build a `server/discover` request/response (out-of-band capability
//     advertisement — there is no more `initialize` handshake; every request
//     carries its own protocol version and capabilities instead).
//  2. Register tools, resources and prompts with McpBuilder.
//  3. Serialise a tool-call request and deserialise the response.
//  4. Open a `subscriptions/listen` stream for change notifications.
//  5. Produce error responses.
//  6. Emit a progress notification.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  _discover();
  _toolsWithMcpBuilder();
  _callToolRoundTrip();
  _subscriptionsListen();
  _errorResponse();
  _progressNotification();
}

// ── 1. server/discover ────────────────────────────────────────────────────────

/// Builds the request metadata every MCP request now carries: protocol
/// version and capabilities are declared per-request rather than negotiated
/// once via an `initialize` handshake.
RequestMetaObject _requestMeta() => RequestMetaObject(
      protocolVersion: '2026-07-28',
      clientCapabilities: ClientCapabilities({'elicitation': {}}),
      clientInfo: Implementation(name: 'example_client', version: '1.0.0'),
    );

void _discover() {
  print('\n── server/discover ────────────────────────────────────────────────');

  // Client asks the server what it supports.
  final request = DiscoverRequest(
    id: '1',
    params: RequestParams($meta: _requestMeta()),
  );

  print('→ ${request.toMap()}');

  // Server responds with its supported versions and capabilities.
  final result = DiscoverResult(
    supportedVersions: ['2026-07-28', '2025-11-25'],
    capabilities: ServerCapabilities({
      'tools': {'listChanged': true},
      'resources': {'listChanged': true, 'subscribe': true},
    }),
    instructions: 'Call tools/list to discover available tools.',
    ttlMs: 3600000,
    cacheScope: CacheScope.public,
  );

  print('← ${result.toMap()}');
}

// ── 2. Register tools / resources / prompts with McpBuilder ──────────────────

void _toolsWithMcpBuilder() {
  print('\n── McpBuilder registration ───────────────────────────────────────');

  final builder = McpBuilder();

  // Register a tool.
  builder.tool(
    name: 'add',
    description: 'Adds two integers and returns the sum.',
    inputSchema: ToolSchema(
      properties: {
        'a': {'type': 'integer', 'description': 'First operand'},
        'b': {'type': 'integer', 'description': 'Second operand'},
      },
      required: ['a', 'b'],
    ),
    annotations: ToolAnnotations(readOnlyHint: true, idempotentHint: true),
    handler: (req) async {
      final args = req.params.arguments ?? {};
      final sum = (args['a'] as int) + (args['b'] as int);
      return CallToolResult(
        content: [TextContent(text: '$sum', mimeType: 'text/plain')],
      );
    },
  );

  // Register a static resource.
  builder.resource(
    name: 'config',
    uri: 'file:///config.json',
    mimeType: 'application/json',
    description: 'Application configuration',
    handler: (req) async => ReadResourceResult(
      contents: [
        TextResourceContents(
          uri: 'file:///config.json',
          text: '{"debug": false}',
          mimeType: 'application/json',
        ),
      ],
      // A config file rarely changes — cache it for a minute.
      ttlMs: 60000,
      cacheScope: CacheScope.private,
    ),
  );

  // Register a resource template.
  builder.resourceTemplate(
    name: 'file',
    uriTemplate: 'file:///{path}',
    description: 'Read any file by path',
  );

  // Register a prompt.
  builder.prompt(
    name: 'summarise',
    description: 'Summarise a block of text',
    arguments: [PromptArgument(name: 'text', required: true)],
    handler: (req) async => GetPromptResult(
      messages: [
        PromptMessage(
          role: Role.user,
          content: TextContent(
            text: 'Summarise: ${req.params.arguments?['text'] ?? ''}',
            mimeType: 'text/plain',
          ),
        ),
      ],
    ),
  );

  // Discover what was registered.
  final toolsResult = builder.buildToolsResult();
  print('Tools: ${toolsResult.tools.map((t) => t.name).toList()}');

  final resourcesResult = builder.buildResourcesResult();
  print('Resources: ${resourcesResult.resources.map((r) => r.uri).toList()}');

  final templatesResult = builder.buildResourceTemplatesResult();
  print(
    'Templates: '
    '${templatesResult.resourceTemplates.map((t) => t.uriTemplate).toList()}',
  );

  final promptsResult = builder.buildPromptsResult();
  print('Prompts: ${promptsResult.prompts.map((p) => p.name).toList()}');
}

// ── 3. Tool call round-trip ───────────────────────────────────────────────────

void _callToolRoundTrip() {
  print('\n── Tool call round-trip ──────────────────────────────────────────');

  // Client builds a tools/call request.
  final callRequest = CallToolRequest(
    id: '2',
    params: CallToolRequestParams(
      $meta: _requestMeta(),
      name: 'add',
      arguments: {'a': 3, 'b': 7},
    ),
  );

  final requestMap = callRequest.toMap();
  print('→ $requestMap');

  // Deserialise on the server side.
  final parsed = CallToolRequest.toMCP(requestMap);
  print('  Tool name : ${parsed.params.name}');
  print('  Arguments : ${parsed.params.arguments}');

  // Server returns a result. `result` is a discriminated union of
  // InputRequiredResult | CallToolResult — here the call completed normally.
  final callResult = CallToolResultResponse(
    id: '2',
    result: CallToolResult(
      content: [TextContent(text: '10', mimeType: 'text/plain')],
    ),
  );

  final resultMap = callResult.toMap();
  print('← $resultMap');

  // Client deserialises the response and dispatches on resultType.
  final parsedResult = CallToolResultResponse.toMCP(resultMap);
  final outcome = parsedResult.result;
  if (outcome is CallToolResult) {
    final text = (outcome.content.first as TextContent).text;
    print('  Result text: $text');
  } else if (outcome is InputRequiredResult) {
    print('  Server needs more input: ${outcome.requestState}');
  }
}

// ── 4. subscriptions/listen ───────────────────────────────────────────────────

void _subscriptionsListen() {
  print('\n── subscriptions/listen ──────────────────────────────────────────');

  // Client opens a long-lived stream for change notifications, replacing the
  // former resources/subscribe + resources/unsubscribe RPC pair.
  final listenRequest = SubscriptionsListenRequest(
    id: '3',
    params: SubscriptionsListenRequestParams(
      $meta: _requestMeta(),
      notifications: SubscriptionFilter(
        toolsListChanged: true,
        resourcesListChanged: true,
        resourceSubscriptions: ['file:///config.json'],
      ),
    ),
  );

  print('→ ${listenRequest.toMap()}');

  // Server immediately acknowledges the stream.
  final ack = SubscriptionsAcknowledgedNotification(
    params: SubscriptionsAcknowledgedNotificationParams(
      notifications: SubscriptionFilter(
        toolsListChanged: true,
        resourcesListChanged: true,
        resourceSubscriptions: ['file:///config.json'],
      ),
    ),
  );
  print('← ${ack.toMap()}');

  // ... time passes, config.json changes on disk ...
  final updated = ResourceUpdatedNotification(
    params: ResourceUpdatedNotificationParams(
      $meta: NotificationMetaObject(subscriptionId: '3'),
      uri: 'file:///config.json',
    ),
  );
  print('← ${updated.toMap()}');
}

// ── 5. Error response ─────────────────────────────────────────────────────────

void _errorResponse() {
  print('\n── Error response ────────────────────────────────────────────────');

  final errorResp = JSONRPCErrorResponse(
    id: '99',
    error: MethodNotFoundError(message: 'tools/unknown is not registered'),
  );

  print(errorResp.toMap());

  // Parse it back.
  final parsed = JSONRPCErrorResponse.toMCP(errorResp.toMap());
  print('Error code   : ${parsed.error.code}');
  print('Error message: ${parsed.error.message}');
}

// ── 6. Progress notification ──────────────────────────────────────────────────

void _progressNotification() {
  print('\n── Progress notification ─────────────────────────────────────────');

  final notif = ProgressNotification(
    params: ProgressNotificationParams(
      progressToken: 'job-42',
      progress: 75,
      total: 100,
      message: 'Processing batch 3 of 4…',
    ),
  );

  print(notif.toMap());
}
