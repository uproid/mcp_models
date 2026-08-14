// ignore_for_file: avoid_print
import 'package:mcp_models/mcp_models_v2025.dart';

// ─────────────────────────────────────────────────────────────────────────────
// This example demonstrates the key workflows exposed by mcp_models:
//
//  1. Build an initialize handshake (client → server).
//  2. Register tools, resources and prompts with McpBuilder.
//  3. Serialise a tool-call request and deserialise the response.
//  4. Construct a sampling (createMessage) request.
//  5. Produce error responses.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  _initializeHandshake();
  _toolsWithMcpBuilder();
  _callToolRoundTrip();
  _samplingRequest();
  _errorResponse();
  _progressNotification();
}

// ── 1. Initialize handshake ───────────────────────────────────────────────────

void _initializeHandshake() {
  print('\n── Initialize handshake ──────────────────────────────────────────');

  // Client sends an initialize request.
  final request = InitializeRequest(
    id: '1',
    params: InitializeRequestParams(
      protocolVersion: '2025-11-25',
      capabilities: ClientCapabilities({}),
      clientInfo: Implementation(
        name: 'example_client',
        version: '1.0.0',
        description: 'A minimal MCP client example',
      ),
    ),
  );

  print('→ ${request.toMap()}');

  // Server responds with its capabilities.
  final result = InitializeResult(
    protocolVersion: '2025-11-25',
    capabilities: ServerCapabilities({}),
    serverInfo: Implementation(name: 'example_server', version: '1.0.0'),
    instructions: 'Call tools/list to discover available tools.',
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

  // Server returns a result.
  final callResult = CallToolResultResponse(
    id: '2',
    result: CallToolResult(
      content: [TextContent(text: '10', mimeType: 'text/plain')],
    ),
  );

  final resultMap = callResult.toMap();
  print('← $resultMap');

  // Client deserialises the response.
  final parsedResult = CallToolResultResponse.toMCP(resultMap);
  final text = (parsedResult.result.content.first as TextContent).text;
  print('  Result text: $text');
}

// ── 4. Sampling (createMessage) request ──────────────────────────────────────

void _samplingRequest() {
  print('\n── Sampling request ──────────────────────────────────────────────');

  final createMsg = CreateMessageRequest(
    params: CreateMessageRequestParams(
      messages: [
        SamplingMessage(
          role: Role.user,
          content: [
            TextContent(
              text: 'What is the capital of France?',
              mimeType: 'text/plain',
            )
          ],
        ),
      ],
      maxTokens: 256,
      temperature: 0.7,
      systemPrompt: 'You are a helpful geography assistant.',
    ),
  );

  print('→ ${createMsg.toMap()}');

  // The client returns a result after querying its LLM.
  final msgResult = CreateMessageResult(
    model: 'gpt-4o',
    role: Role.assistant,
    content: [
      TextContent(text: 'Paris.', mimeType: 'text/plain'),
    ],
    stopReason: 'end_turn',
  );

  print('← ${msgResult.toMap()}');
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
