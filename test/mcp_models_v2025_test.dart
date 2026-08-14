import 'package:mcp_models/mcp_models_v2025.dart';
import 'package:test/test.dart';

void main() {
  // ── Error types ────────────────────────────────────────────────────────────

  group('Error', () {
    test('toMap includes all fields', () {
      final e = Error(code: -32600, message: 'Invalid request', data: 'extra');
      final m = e.toMap();
      expect(m['code'], -32600);
      expect(m['message'], 'Invalid request');
      expect(m['data'], 'extra');
    });

    test('toMCP round-trips', () {
      final src = Error(code: 42, message: 'oops');
      final restored = Error.toMCP(src.toMap());
      expect(restored.code, 42);
      expect(restored.message, 'oops');
      expect(restored.data, isNull);
    });

    test('InternalError has code -32603', () {
      expect(InternalError(message: 'err').code, -32603);
    });

    test('InvalidParamsError has code -32602', () {
      expect(InvalidParamsError(message: 'err').code, -32602);
    });

    test('InvalidRequestError has code -32600', () {
      expect(InvalidRequestError(message: 'err').code, -32600);
    });

    test('MethodNotFoundError has code -32601', () {
      expect(MethodNotFoundError(message: 'err').code, -32601);
    });

    test('ParseError has code -32700', () {
      expect(ParseError(message: 'err').code, -32700);
    });
  });

  // ── JSONRPCErrorResponse ───────────────────────────────────────────────────

  group('JSONRPCErrorResponse', () {
    test('toMap / toMCP round-trip', () {
      final resp = JSONRPCErrorResponse(
        id: '1',
        error: Error(code: -32601, message: 'Not found'),
      );
      final map = resp.toMap();
      expect(map['jsonrpc'], '2.0');
      expect(map['id'], '1');

      final restored = JSONRPCErrorResponse.toMCP(map);
      expect(restored.error.code, -32601);
      expect(restored.error.message, 'Not found');
    });
  });

  // ── JSONRPCResultResponse ──────────────────────────────────────────────────

  group('JSONRPCResultResponse', () {
    test('toMap / toMCP round-trip', () {
      final resp = JSONRPCResultResponse(
        id: '2',
        result: Result(meta: null),
      );
      final map = resp.toMap();
      expect(map['jsonrpc'], '2.0');
      expect(map['id'], '2');

      final restored = JSONRPCResultResponse.toMCP(map);
      expect(restored.id, '2');
    });
  });

  // ── JSONRPCNotification ────────────────────────────────────────────────────

  group('JSONRPCNotification', () {
    test('toMap / toMCP round-trip', () {
      final notif = JSONRPCNotification(
        method: 'notifications/initialized',
        params: {'key': 'value'},
      );
      final map = notif.toMap();
      expect(map['method'], 'notifications/initialized');
      expect((map['params'] as Map)['key'], 'value');

      final restored = JSONRPCNotification.toMCP(map);
      expect(restored.method, 'notifications/initialized');
    });
  });

  // ── JSONRPCRequest ─────────────────────────────────────────────────────────

  group('JSONRPCRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = JSONRPCRequest(
        method: 'ping',
        id: '42',
        params: {'a': 1},
      );
      final map = req.toMap();
      expect(map['method'], 'ping');
      expect(map['id'], '42');

      final restored = JSONRPCRequest.toMCP(map);
      expect(restored.id, '42');
    });
  });

  // ── Annotations ───────────────────────────────────────────────────────────

  group('Annotations', () {
    test('toMap includes set fields only', () {
      final ann = Annotations(
        priority: 1,
        lastModified: '2025-01-01T00:00:00Z',
        audience: [Role.user, Role.assistant],
      );
      final m = ann.toMap();
      expect(m['priority'], 1);
      expect(m['lastModified'], '2025-01-01T00:00:00Z');
      expect((m['audience'] as List).length, 2);
    });

    test('toMCP round-trip', () {
      final src = Annotations(audience: [Role.user]);
      final r = Annotations.toMCP(src.toMap());
      expect(r.audience?.first, Role.user);
    });

    test('empty annotations toMap has no keys', () {
      expect(Annotations().toMap(), isEmpty);
    });
  });

  // ── Role ──────────────────────────────────────────────────────────────────

  group('Role', () {
    test('toString returns name', () {
      expect(Role.user.toString(), 'user');
      expect(Role.assistant.toString(), 'assistant');
    });

    test('Role.to parses from string', () {
      expect(Role.to('user'), Role.user);
      expect(Role.to('assistant'), Role.assistant);
    });
  });

  // ── LoggingLevel ──────────────────────────────────────────────────────────

  group('LoggingLevel', () {
    test('all values round-trip via toString / to', () {
      for (final level in LoggingLevel.values) {
        expect(LoggingLevel.to(level.toString()), level);
      }
    });
  });

  // ── Icon ──────────────────────────────────────────────────────────────────

  group('Icon', () {
    test('toMap / toMCP round-trip', () {
      final icon = Icon(
        src: 'https://example.com/icon.png',
        mimeType: 'image/png',
        sizes: ['48x48'],
        theme: Theme.dark,
      );
      final m = icon.toMap();
      expect(m['src'], 'https://example.com/icon.png');

      final r = Icon.toMCP(m);
      expect(r.theme, Theme.dark);
      expect(r.sizes, ['48x48']);
    });
  });

  // ── TextContent ───────────────────────────────────────────────────────────

  group('TextContent', () {
    test('toMap / toMCP round-trip', () {
      final tc = TextContent(text: 'hello', mimeType: 'text/plain');
      final m = tc.toMap();
      expect(m['type'], 'text');
      expect(m['text'], 'hello');

      final r = TextContent.toMCP(m);
      expect(r.text, 'hello');
    });
  });

  // ── ImageContent ──────────────────────────────────────────────────────────

  group('ImageContent', () {
    test('toMap has type image', () {
      final ic = ImageContent(data: 'abc123', mimeType: 'image/png');
      expect(ic.toMap()['type'], 'image');
    });
  });

  // ── AudioContent ──────────────────────────────────────────────────────────

  group('AudioContent', () {
    test('toMap has type audio', () {
      final ac = AudioContent(data: 'abc123', mimeType: 'audio/wav');
      expect(ac.toMap()['type'], 'audio');
    });
  });

  // ── TextResourceContents ──────────────────────────────────────────────────

  group('TextResourceContents', () {
    test('toMap / toMCP round-trip', () {
      final trc = TextResourceContents(
        text: 'content',
        uri: 'file:///readme.md',
        mimeType: 'text/markdown',
      );
      final m = trc.toMap();
      expect(m['text'], 'content');
      expect(m['uri'], 'file:///readme.md');

      final r = TextResourceContents.toMCP(m);
      expect(r.text, 'content');
      expect(r.mimeType, 'text/markdown');
    });
  });

  // ── BlobResourceContents ──────────────────────────────────────────────────

  group('BlobResourceContents', () {
    test('toMap includes blob', () {
      final brc = BlobResourceContents(
        blob: 'base64data',
        uri: 'file:///image.png',
        mimeType: 'image/png',
      );
      final m = brc.toMap();
      expect(m['blob'], 'base64data');
    });

    test('toMCP round-trip', () {
      final src = BlobResourceContents(blob: 'xyz', uri: 'file:///a.bin');
      final r = BlobResourceContents.toMCP(src.toMap());
      expect(r.blob, 'xyz');
    });
  });

  // ── InitializeRequest ─────────────────────────────────────────────────────

  group('InitializeRequest', () {
    InitializeRequest buildRequest() => InitializeRequest(
          id: '1',
          params: InitializeRequestParams(
            protocolVersion: '2025-11-25',
            capabilities: ClientCapabilities({}),
            clientInfo: Implementation(name: 'test-client', version: '0.1.0'),
          ),
        );

    test('toMap has correct method', () {
      expect(buildRequest().toMap()['method'], 'initialize');
    });

    test('toMCP round-trip', () {
      final req = buildRequest();
      final r = InitializeRequest.toMCP(req.toMap());
      expect(r.params.protocolVersion, '2025-11-25');
      expect(r.params.clientInfo.name, 'test-client');
    });
  });

  // ── InitializeResult ──────────────────────────────────────────────────────

  group('InitializeResult', () {
    test('toMap / toMCP round-trip', () {
      final result = InitializeResult(
        protocolVersion: '2025-11-25',
        capabilities: ServerCapabilities({}),
        serverInfo: Implementation(name: 'my-server', version: '1.0.0'),
        instructions: 'Use me wisely.',
      );
      final m = result.toMap();
      expect(m['protocolVersion'], '2025-11-25');
      expect(m['instructions'], 'Use me wisely.');

      final r = InitializeResult.toMCP(m);
      expect(r.serverInfo.name, 'my-server');
      expect(r.instructions, 'Use me wisely.');
    });
  });

  // ── Implementation ────────────────────────────────────────────────────────

  group('Implementation', () {
    test('optional fields omitted from map', () {
      final impl = Implementation(name: 'cli');
      final m = impl.toMap();
      expect(m.containsKey('version'), isFalse);
      expect(m.containsKey('description'), isFalse);
    });

    test('toMCP round-trip with all fields', () {
      final src = Implementation(
        name: 'srv',
        title: 'Server',
        version: '2.0.0',
        description: 'desc',
        websiteUrl: 'https://example.com',
      );
      final r = Implementation.toMCP(src.toMap());
      expect(r.version, '2.0.0');
      expect(r.websiteUrl, 'https://example.com');
    });
  });

  // ── Tool ──────────────────────────────────────────────────────────────────

  group('Tool', () {
    Tool buildTool() => Tool(
          name: 'search',
          description: 'Search docs',
          inputSchema: ToolSchema(
            properties: {
              'query': {'type': 'string'},
            },
            required: ['query'],
          ),
        );

    test('toMap / toMCP round-trip', () {
      final tool = buildTool();
      final m = tool.toMap();
      expect(m['name'], 'search');

      final r = Tool.toMCP(m);
      expect(r.description, 'Search docs');
      expect(r.inputSchema.required, ['query']);
    });
  });

  // ── ToolAnnotations ───────────────────────────────────────────────────────

  group('ToolAnnotations', () {
    test('toMap / toMCP round-trip', () {
      final ann = ToolAnnotations(
        title: 'My Tool',
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      );
      final r = ToolAnnotations.toMCP(ann.toMap());
      expect(r.readOnlyHint, isTrue);
      expect(r.destructiveHint, isFalse);
    });
  });

  // ── CallToolRequest ───────────────────────────────────────────────────────

  group('CallToolRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = CallToolRequest(
        id: '5',
        params: CallToolRequestParams(
          name: 'search',
          arguments: {'query': 'dart'},
        ),
      );
      final m = req.toMap();
      expect(m['method'], 'tools/call');

      final r = CallToolRequest.toMCP(m);
      expect(r.params.name, 'search');
      expect(r.params.arguments?['query'], 'dart');
    });
  });

  // ── CallToolResult ────────────────────────────────────────────────────────

  group('CallToolResult', () {
    test('isError defaults to null', () {
      final res = CallToolResult(
        content: [TextContent(text: 'ok', mimeType: 'text/plain')],
      );
      expect(res.isError, isNull);
    });

    test('toMap / toMCP round-trip with error', () {
      final res = CallToolResult(
        content: [TextContent(text: 'fail', mimeType: 'text/plain')],
        isError: true,
      );
      final r = CallToolResult.toMCP(res.toMap());
      expect(r.isError, isTrue);
    });
  });

  // ── ListToolsResult ───────────────────────────────────────────────────────

  group('ListToolsResult', () {
    test('toMap / toMCP round-trip', () {
      final res = ListToolsResult(
        tools: [
          Tool(name: 'ping', inputSchema: ToolSchema()),
        ],
      );
      final m = res.toMap();
      final r = ListToolsResult.toMCP(m);
      expect(r.tools.length, 1);
      expect(r.tools.first.name, 'ping');
    });
  });

  // ── Resource ──────────────────────────────────────────────────────────────

  group('Resource', () {
    test('toMap / toMCP round-trip', () {
      final res = Resource(
        name: 'readme',
        uri: 'file:///README.md',
        mimeType: 'text/markdown',
        description: 'Project README',
        size: 1024,
      );
      final r = Resource.toMCP(res.toMap());
      expect(r.uri, 'file:///README.md');
      expect(r.size, 1024);
    });
  });

  // ── ResourceTemplate ──────────────────────────────────────────────────────

  group('ResourceTemplate', () {
    test('toMap / toMCP round-trip', () {
      final tmpl = ResourceTemplate(
        name: 'file',
        uriTemplate: 'file:///{path}',
        description: 'Any file',
      );
      final r = ResourceTemplate.toMCP(tmpl.toMap());
      expect(r.uriTemplate, 'file:///{path}');
    });
  });

  // ── ReadResourceResult ────────────────────────────────────────────────────

  group('ReadResourceResult', () {
    test('toMap / toMCP round-trip', () {
      final res = ReadResourceResult(
        contents: [
          TextResourceContents(text: 'hello', uri: 'file:///a.txt'),
        ],
      );
      final r = ReadResourceResult.toMCP(res.toMap());
      expect(r.contents.length, 1);
      expect((r.contents.first as TextResourceContents).text, 'hello');
    });
  });

  // ── ListResourcesResult ───────────────────────────────────────────────────

  group('ListResourcesResult', () {
    test('toMap / toMCP round-trip with cursor', () {
      final res = ListResourcesResult(
        resources: [Resource(name: 'f', uri: 'file:///f.txt')],
        nextCursor: 'tok123',
      );
      final r = ListResourcesResult.toMCP(res.toMap());
      expect(r.nextCursor, 'tok123');
      expect(r.resources.first.name, 'f');
    });
  });

  // ── Prompt ────────────────────────────────────────────────────────────────

  group('Prompt', () {
    test('toMap / toMCP round-trip', () {
      final prompt = Prompt(
        name: 'greet',
        description: 'A greeting prompt',
        arguments: [
          PromptArgument(name: 'name', required: true),
        ],
      );
      final r = Prompt.toMCP(prompt.toMap());
      expect(r.arguments?.first.name, 'name');
      expect(r.arguments?.first.required, isTrue);
    });
  });

  // ── GetPromptResult ───────────────────────────────────────────────────────

  group('GetPromptResult', () {
    test('toMap / toMCP round-trip', () {
      final res = GetPromptResult(
        description: 'Hello world prompt',
        messages: [
          PromptMessage(
            role: Role.user,
            content: TextContent(text: 'hi', mimeType: 'text/plain'),
          ),
        ],
      );
      final r = GetPromptResult.toMCP(res.toMap());
      expect(r.messages.length, 1);
      expect(r.messages.first.role, Role.user);
    });
  });

  // ── PingRequest ───────────────────────────────────────────────────────────

  group('PingRequest', () {
    test('toMap / toMCP round-trip', () {
      final ping = PingRequest(id: '7');
      final m = ping.toMap();
      expect(m['method'], 'ping');

      final r = PingRequest.toMCP(m);
      expect(r.id, '7');
    });
  });

  // ── CancelledNotification ─────────────────────────────────────────────────

  group('CancelledNotification', () {
    test('toMap / toMCP round-trip', () {
      final notif = CancelledNotification(
        params: CancelledNotificationParams(
          requestId: 'req-1',
          reason: 'done',
        ),
      );
      final r = CancelledNotification.toMCP(notif.toMap());
      expect(r.params.requestId, 'req-1');
      expect(r.params.reason, 'done');
    });
  });

  // ── Task ──────────────────────────────────────────────────────────────────

  group('Task', () {
    test('toMap / toMCP round-trip', () {
      const now = '2025-01-01T00:00:00Z';
      final task = Task(
        taskId: 'task-1',
        status: TaskStatus.working,
        createdAt: now,
        lastUpdatedAt: now,
        ttl: 60000,
        pollInterval: 1000,
      );
      final r = Task.toMCP(task.toMap());
      expect(r.taskId, 'task-1');
      expect(r.status, TaskStatus.working);
      expect(r.ttl, 60000);
    });
  });

  // ── SetLevelRequest ───────────────────────────────────────────────────────

  group('SetLevelRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = SetLevelRequest(
        id: '3',
        params: SetLevelRequestParams(level: LoggingLevel.warning),
      );
      final r = SetLevelRequest.toMCP(req.toMap());
      expect(r.params.level, LoggingLevel.warning);
    });
  });

  // ── ProgressNotification ──────────────────────────────────────────────────

  group('ProgressNotification', () {
    test('toMap includes all fields', () {
      final notif = ProgressNotification(
        params: ProgressNotificationParams(
          progressToken: 'tok',
          progress: 50,
          total: 100,
          message: 'half done',
        ),
      );
      final m = notif.toMap();
      expect(m['method'], 'notifications/progress');
      final p = m['params'] as Map;
      expect(p['progress'], 50);
      expect(p['total'], 100);
    });
  });

  // ── CompleteRequest ───────────────────────────────────────────────────────

  group('CompleteRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = CompleteRequest(
        id: '8',
        params: CompleteRequestParams(
          ref: PromptReference(name: 'greet'),
          argument: CompleteRequestParamsArgument(name: 'name', value: 'Al'),
        ),
      );
      final r = CompleteRequest.toMCP(req.toMap());
      expect(r.params.argument.value, 'Al');
    });
  });

  // ── StringSchema ──────────────────────────────────────────────────────────

  group('StringSchema', () {
    test('toMap / toMCP round-trip', () {
      final s = StringSchema(
        minLength: 1,
        maxLength: 100,
        format: StringFormat.email,
        title: 'Email',
      );
      final r = StringSchema.toMCP(s.toMap());
      expect(r.format, StringFormat.email);
      expect(r.minLength, 1);
      expect(r.maxLength, 100);
    });
  });

  // ── NumberSchema ──────────────────────────────────────────────────────────

  group('NumberSchema', () {
    test('toMap / toMCP round-trip', () {
      final s = NumberSchema(minimum: 0, maximum: 10, defaultValue: 5);
      final r = NumberSchema.toMCP(s.toMap());
      expect(r.minimum, 0);
      expect(r.maximum, 10);
    });
  });

  // ── BooleanSchema ─────────────────────────────────────────────────────────

  group('BooleanSchema', () {
    test('type is boolean', () {
      expect(BooleanSchema().type, 'boolean');
    });

    test('toMCP round-trip', () {
      final s = BooleanSchema(title: 'Enabled', defaultValue: true);
      final r = BooleanSchema.toMCP(s.toMap());
      expect(r.defaultValue, isTrue);
      expect(r.title, 'Enabled');
    });
  });

  // ── McpBuilder ────────────────────────────────────────────────────────────

  group('McpBuilder', () {
    test('registers tool and returns it in buildToolsResult', () {
      final builder = McpBuilder();
      builder.tool(
        name: 'echo',
        description: 'Echoes input',
        handler: (req) async => CallToolResult(
          content: [TextContent(text: 'ok', mimeType: 'text/plain')],
        ),
      );

      final result = builder.buildToolsResult();
      expect(result.tools.length, 1);
      expect(result.tools.first.name, 'echo');
    });

    test('registers resource and returns it in buildResourcesResult', () {
      final builder = McpBuilder();
      builder.resource(
        name: 'readme',
        uri: 'file:///README.md',
        handler: (req) async => ReadResourceResult(contents: []),
      );

      final result = builder.buildResourcesResult();
      expect(result.resources.length, 1);
      expect(result.resources.first.uri, 'file:///README.md');
    });

    test('registers prompt and returns it in buildPromptsResult', () {
      final builder = McpBuilder();
      builder.prompt(
        name: 'greet',
        handler: (req) async => GetPromptResult(messages: []),
      );

      final result = builder.buildPromptsResult();
      expect(result.prompts.length, 1);
      expect(result.prompts.first.name, 'greet');
    });

    test('toolHandler returns null for unknown tool', () {
      expect(McpBuilder().toolHandler('unknown'), isNull);
    });

    test('resourceHandlerByUri finds exact URI match', () {
      final builder = McpBuilder();
      builder.resource(
        name: 'doc',
        uri: 'file:///doc.md',
        handler: (req) async => ReadResourceResult(contents: []),
      );
      expect(builder.resourceHandlerByUri('file:///doc.md'), isNotNull);
      expect(builder.resourceHandlerByUri('file:///other.md'), isNull);
    });

    test('registers resource template', () {
      final builder = McpBuilder();
      builder.resourceTemplate(
        name: 'file',
        uriTemplate: 'file:///{path}',
      );
      expect(
          builder.buildResourceTemplatesResult().resourceTemplates.length, 1);
    });

    test('registers custom method handler', () {
      final builder = McpBuilder();
      builder.method('custom/method', (p) async => EmptyResult());
      expect(builder.methodHandler('custom/method'), isNotNull);
      expect(builder.methodHandler('other'), isNull);
    });
  });

  // ── ElicitResult ──────────────────────────────────────────────────────────

  group('ElicitResult', () {
    test('toMap / toMCP round-trip', () {
      final res = ElicitResult(
        action: ActionType.accept,
        content: {'name': 'Alice'},
      );
      final r = ElicitResult.toMCP(res.toMap());
      expect(r.action, ActionType.accept);
      expect(r.content['name'], 'Alice');
    });
  });

  // ── UntitledSingleSelectEnumSchema ────────────────────────────────────────

  group('UntitledSingleSelectEnumSchema', () {
    test('toMap / toMCP round-trip', () {
      final s = UntitledSingleSelectEnumSchema(
        $enum: ['a', 'b', 'c'],
        defaultValue: 'b',
      );
      final r = UntitledSingleSelectEnumSchema.toMCP(s.toMap());
      expect(r.$enum, ['a', 'b', 'c']);
      expect(r.defaultValue, 'b');
    });
  });

  // ── TitledSingleSelectEnumSchema ──────────────────────────────────────────

  group('TitledSingleSelectEnumSchema', () {
    test('toMap / toMCP round-trip', () {
      final s = TitledSingleSelectEnumSchema(
        oneOf: [
          ($const: 'v1', title: 'Value 1'),
          ($const: 'v2', title: 'Value 2'),
        ],
      );
      final r = TitledSingleSelectEnumSchema.toMCP(s.toMap());
      expect(r.oneOf.first.$const, 'v1');
      expect(r.oneOf.first.title, 'Value 1');
    });
  });

  // ── MetaObject ────────────────────────────────────────────────────────────

  group('MetaObject', () {
    test('toMap returns inner data', () {
      final meta = MetaObject.toMCP({'key': 'val'});
      expect(meta.toMap()['key'], 'val');
    });
  });

  // ── EmptyResult ───────────────────────────────────────────────────────────

  group('EmptyResult', () {
    test('toMap returns empty map', () {
      expect(EmptyResult().toMap(), isEmpty);
    });
  });

  // ── PaginatedRequestParams ────────────────────────────────────────────────

  group('PaginatedRequestParams', () {
    test('toMCP round-trip with cursor', () {
      final p = PaginatedRequestParams(cursor: 'cur1');
      final r = PaginatedRequestParams.toMCP(p.toMap());
      expect(r.cursor, 'cur1');
    });
  });

  // ── InitializedNotification ───────────────────────────────────────────────

  group('InitializedNotification', () {
    test('toMap has correct method', () {
      final n = InitializedNotification();
      expect(n.toMap()['method'], 'notifications/initialized');
    });
  });

  // ── ToolListChangedNotification ───────────────────────────────────────────

  group('ToolListChangedNotification', () {
    test('toMap has correct method', () {
      final n = ToolListChangedNotification();
      expect(n.toMap()['method'], 'notifications/tools/list_changed');
    });
  });

  // ── ResourceListChangedNotification ──────────────────────────────────────

  group('ResourceListChangedNotification', () {
    test('toMap has correct method', () {
      final n = ResourceListChangedNotification();
      expect(n.toMap()['method'], 'notifications/resources/list_changed');
    });
  });

  // ── ListTasksResult ───────────────────────────────────────────────────────

  group('ListTasksResult', () {
    test('toMap / toMCP round-trip', () {
      const now = '2025-01-01T00:00:00Z';
      final res = ListTasksResult(
        tasks: [
          Task(
            taskId: 't1',
            status: TaskStatus.completed,
            createdAt: now,
            lastUpdatedAt: now,
          ),
        ],
      );
      final r = ListTasksResult.toMCP(res.toMap());
      expect(r.tasks.first.taskId, 't1');
      expect(r.tasks.first.status, TaskStatus.completed);
    });
  });
}
