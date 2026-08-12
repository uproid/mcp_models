import 'package:mcp_models/mcp_models_v2026.dart';
import 'package:test/test.dart';

RequestMetaObject _meta({String? progressToken}) => RequestMetaObject(
      progressToken: progressToken,
      protocolVersion: '2026-07-28',
      clientCapabilities: ClientCapabilities({}),
    );

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

    test('HeaderMismatchError has code -32020', () {
      expect(HeaderMismatchError(message: 'mismatch').code, -32020);
    });

    test('MissingRequiredClientCapabilityError has code -32021 and data', () {
      final e = MissingRequiredClientCapabilityError(
        message: 'missing capability',
        requiredCapabilities: ClientCapabilities({'elicitation': {}}),
      );
      expect(e.code, -32021);
      final data = e.data as Map<String, Object?>;
      expect(
        (data['requiredCapabilities'] as Map)['elicitation'],
        isNotNull,
      );
    });

    test('UnsupportedProtocolVersionError has code -32022 and data', () {
      final e = UnsupportedProtocolVersionError(
        message: 'unsupported version',
        supported: ['2026-07-28', '2025-11-25'],
        requested: '2024-01-01',
      );
      expect(e.code, -32022);
      final data = e.data as Map<String, Object?>;
      expect(data['supported'], ['2026-07-28', '2025-11-25']);
      expect(data['requested'], '2024-01-01');
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
        result: Result(),
      );
      final map = resp.toMap();
      expect(map['jsonrpc'], '2.0');
      expect(map['id'], '2');

      final restored = JSONRPCResultResponse.toMCP(map);
      expect(restored.id, '2');
    });
  });

  // ── Result ─────────────────────────────────────────────────────────────────

  group('Result', () {
    test('resultType defaults to complete and is always emitted', () {
      final r = Result();
      expect(r.toMap()['resultType'], 'complete');
    });

    test('toMap / toMCP round-trip with meta and unknown fields', () {
      final r = Result(
        $meta: ResultMetaObject(
          serverInfo: Implementation(name: 'srv', version: '1.0.0'),
        ),
        unknown: {'extra': 'value'},
      );
      final map = r.toMap();
      expect(map['_meta'], isNotNull);
      expect(map['extra'], 'value');

      final restored = Result.toMCP(map);
      expect(restored.resultType, 'complete');
      expect(restored.$meta?.serverInfo?.name, 'srv');
      expect(restored.unknown?['extra'], 'value');
    });
  });

  // ── RequestMetaObject / ResultMetaObject / NotificationMetaObject ─────────

  group('RequestMetaObject', () {
    test('toMap / toMCP round-trip with required fields', () {
      final meta = RequestMetaObject(
        progressToken: 'tok-1',
        protocolVersion: '2026-07-28',
        clientCapabilities: ClientCapabilities({'elicitation': {}}),
        clientInfo: Implementation(name: 'client', version: '1.0.0'),
      );
      final map = meta.toMap();
      expect(map['io.modelcontextprotocol/protocolVersion'], '2026-07-28');

      final restored = RequestMetaObject.toMCP(map);
      expect(restored.protocolVersion, '2026-07-28');
      expect(restored.progressToken, 'tok-1');
      expect(restored.clientInfo?.name, 'client');
    });

    test('deprecated logLevel round-trips', () {
      // ignore: deprecated_member_use_from_same_package
      final meta = RequestMetaObject(
        protocolVersion: '2026-07-28',
        clientCapabilities: ClientCapabilities({}),
        // ignore: deprecated_member_use_from_same_package
        logLevel: LoggingLevel.warning,
      );
      // ignore: deprecated_member_use_from_same_package
      expect(
          RequestMetaObject.toMCP(meta.toMap()).logLevel, LoggingLevel.warning);
    });
  });

  group('ResultMetaObject', () {
    test('toMap / toMCP round-trip', () {
      final meta = ResultMetaObject(
        serverInfo: Implementation(name: 'server', version: '2.0.0'),
      );
      final restored = ResultMetaObject.toMCP(meta.toMap());
      expect(restored.serverInfo?.name, 'server');
    });
  });

  group('NotificationMetaObject', () {
    test('toMap / toMCP round-trip with subscriptionId', () {
      final meta = NotificationMetaObject(subscriptionId: 'sub-1');
      final restored = NotificationMetaObject.toMCP(meta.toMap());
      expect(restored.subscriptionId, 'sub-1');
    });
  });

  // ── JSONRPCNotification ────────────────────────────────────────────────────

  group('JSONRPCNotification', () {
    test('toMap / toMCP round-trip', () {
      final notif = JSONRPCNotification(
        method: 'notifications/tools/list_changed',
        params: {'key': 'value'},
      );
      final map = notif.toMap();
      expect(map['method'], 'notifications/tools/list_changed');
      expect((map['params'] as Map)['key'], 'value');

      final restored = JSONRPCNotification.toMCP(map);
      expect(restored.method, 'notifications/tools/list_changed');
    });
  });

  // ── JSONRPCRequest ─────────────────────────────────────────────────────────

  group('JSONRPCRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = JSONRPCRequest(
        method: 'tools/call',
        id: '42',
        params: {'a': 1},
      );
      final map = req.toMap();
      expect(map['method'], 'tools/call');
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

  // ── LoggingLevel (deprecated) ─────────────────────────────────────────────

  group('LoggingLevel', () {
    test('all values round-trip via toString / to', () {
      // ignore: deprecated_member_use_from_same_package
      for (final level in LoggingLevel.values) {
        // ignore: deprecated_member_use_from_same_package
        expect(LoggingLevel.to(level.toString()), level);
      }
    });
  });

  // ── CacheScope ────────────────────────────────────────────────────────────

  group('CacheScope', () {
    test('toString / to round-trip', () {
      for (final scope in CacheScope.values) {
        expect(CacheScope.to(scope.toString()), scope);
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

  // ── Implementation ────────────────────────────────────────────────────────

  group('Implementation', () {
    test('optional fields omitted from map', () {
      final impl = Implementation(name: 'cli', version: '0.0.1');
      final m = impl.toMap();
      expect(m.containsKey('description'), isFalse);
      expect(m['version'], '0.0.1');
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

  // ── ClientCapabilities / ServerCapabilities ───────────────────────────────

  group('ClientCapabilities', () {
    test('is a raw passthrough map', () {
      final caps = ClientCapabilities({
        'elicitation': {'form': {}}
      });
      final restored = ClientCapabilities.toMCP(caps.toMap());
      expect(restored['elicitation'], isNotNull);
    });
  });

  group('ServerCapabilities', () {
    test('is a raw passthrough map', () {
      final caps = ServerCapabilities({
        'tools': {'listChanged': true}
      });
      final restored = ServerCapabilities.toMCP(caps.toMap());
      expect((restored['tools'] as Map)['listChanged'], isTrue);
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

  // ── ToolSchema ────────────────────────────────────────────────────────────

  group('ToolSchema', () {
    test('round-trips arbitrary JSON Schema keywords losslessly', () {
      final schema = ToolSchema(
        properties: {
          'items': {'type': 'array'},
        },
        additionalData: {
          'oneOf': [
            {
              'required': ['a']
            },
            {
              'required': ['b']
            },
          ],
        },
      );
      final restored = ToolSchema.toMCP(schema.toMap());
      expect(restored.properties?['items'], isNotNull);
      expect(restored.additionalData?['oneOf'], isNotNull);
    });
  });

  // ── CallToolRequest ───────────────────────────────────────────────────────

  group('CallToolRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = CallToolRequest(
        id: '5',
        params: CallToolRequestParams(
          $meta: _meta(),
          name: 'search',
          arguments: {'query': 'dart'},
        ),
      );
      final m = req.toMap();
      expect(m['method'], 'tools/call');

      final r = CallToolRequest.toMCP(m);
      expect(r.params.name, 'search');
      expect(r.params.arguments?['query'], 'dart');
      expect(r.params.$meta.protocolVersion, '2026-07-28');
    });
  });

  // ── CallToolResult / CallToolResultResponse ───────────────────────────────

  group('CallToolResult', () {
    test('isError defaults to null and resultType defaults to complete', () {
      final res = CallToolResult(
        content: [TextContent(text: 'ok', mimeType: 'text/plain')],
      );
      expect(res.isError, isNull);
      expect(res.resultType, 'complete');
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

  group('CallToolResultResponse', () {
    test('dispatches complete results to CallToolResult', () {
      final resp = CallToolResultResponse(
        id: '1',
        result: CallToolResult(
          content: [TextContent(text: 'ok', mimeType: 'text/plain')],
        ),
      );
      final restored = CallToolResultResponse.toMCP(resp.toMap());
      expect(restored.result, isA<CallToolResult>());
      expect(
        (restored.result as CallToolResult).content.first,
        isA<TextContent>(),
      );
    });

    test('dispatches input_required results to InputRequiredResult', () {
      final map = {
        'jsonrpc': '2.0',
        'id': '1',
        'result': {
          'resultType': 'input_required',
          'requestState': 'state-token',
        },
      };
      final restored = CallToolResultResponse.toMCP(map);
      expect(restored.result, isA<InputRequiredResult>());
      expect(
        (restored.result as InputRequiredResult).requestState,
        'state-token',
      );
    });
  });

  // ── InputRequiredResult ───────────────────────────────────────────────────

  group('InputRequiredResult', () {
    test('resultType is fixed to input_required', () {
      final res = InputRequiredResult(requestState: 'tok');
      expect(res.toMap()['resultType'], 'input_required');
    });

    test('toMap / toMCP round-trip with inputRequests', () {
      final res = InputRequiredResult(
        inputRequests: {'form': 'schema'},
        requestState: 'tok',
      );
      final restored = InputRequiredResult.toMCP(res.toMap());
      expect(restored.inputRequests, {'form': 'schema'});
      expect(restored.requestState, 'tok');
    });
  });

  // ── ListToolsResult ───────────────────────────────────────────────────────

  group('ListToolsResult', () {
    test('toMap / toMCP round-trip', () {
      final res = ListToolsResult(
        tools: [
          Tool(name: 'ping', inputSchema: ToolSchema(type: 'object')),
        ],
        ttlMs: 60000,
        cacheScope: CacheScope.public,
      );
      final m = res.toMap();
      expect(m['ttlMs'], 60000);
      expect(m['cacheScope'], 'public');

      final r = ListToolsResult.toMCP(m);
      expect(r.tools.length, 1);
      expect(r.tools.first.name, 'ping');
      expect(r.ttlMs, 60000);
      expect(r.cacheScope, CacheScope.public);
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

  // ── ReadResourceResult / ReadResourceResultResponse ──────────────────────

  group('ReadResourceResult', () {
    test('toMap / toMCP round-trip', () {
      final res = ReadResourceResult(
        contents: [
          TextResourceContents(text: 'hello', uri: 'file:///a.txt'),
        ],
        ttlMs: 0,
        cacheScope: CacheScope.private,
      );
      final r = ReadResourceResult.toMCP(res.toMap());
      expect(r.contents.length, 1);
      expect((r.contents.first as TextResourceContents).text, 'hello');
      expect(r.cacheScope, CacheScope.private);
    });
  });

  group('ReadResourceResultResponse', () {
    test('dispatches on resultType', () {
      final map = {
        'jsonrpc': '2.0',
        'id': '1',
        'result': {
          'resultType': 'input_required',
          'requestState': 'need-more',
        },
      };
      final restored = ReadResourceResultResponse.toMCP(map);
      expect(restored.result, isA<InputRequiredResult>());
    });
  });

  // ── ListResourcesResult ───────────────────────────────────────────────────

  group('ListResourcesResult', () {
    test('toMap / toMCP round-trip with cursor', () {
      final res = ListResourcesResult(
        resources: [Resource(name: 'f', uri: 'file:///f.txt')],
        nextCursor: 'tok123',
        ttlMs: 30000,
        cacheScope: CacheScope.public,
      );
      final r = ListResourcesResult.toMCP(res.toMap());
      expect(r.nextCursor, 'tok123');
      expect(r.resources.first.name, 'f');
      expect(r.ttlMs, 30000);
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

  // ── GetPromptResult / GetPromptResultResponse ────────────────────────────

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
      expect(r.resultType, 'complete');
    });
  });

  group('GetPromptResultResponse', () {
    test('dispatches on resultType', () {
      final resp = GetPromptResultResponse(
        id: '1',
        result: GetPromptResult(messages: []),
      );
      final restored = GetPromptResultResponse.toMCP(resp.toMap());
      expect(restored.result, isA<GetPromptResult>());
    });
  });

  // ── CancelledNotification ─────────────────────────────────────────────────

  group('CancelledNotification', () {
    test('uses the plural method name and requires requestId', () {
      final notif = CancelledNotification(
        params: CancelledNotificationParams(
          requestId: 'req-1',
          reason: 'done',
        ),
      );
      expect(notif.toMap()['method'], 'notifications/cancelled');

      final r = CancelledNotification.toMCP(notif.toMap());
      expect(r.params.requestId, 'req-1');
      expect(r.params.reason, 'done');
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

    test('toMCP round-trip', () {
      final notif = ProgressNotification(
        params: ProgressNotificationParams(
          progressToken: 'tok',
          progress: 10,
        ),
      );
      final r = ProgressNotification.toMCP(notif.toMap());
      expect(r.params.progressToken, 'tok');
      expect(r.params.progress, 10);
    });
  });

  // ── ResourceUpdatedNotification ───────────────────────────────────────────

  group('ResourceUpdatedNotificationParams', () {
    test('shape is just _meta? and uri', () {
      final params = ResourceUpdatedNotificationParams(
        uri: 'file:///watched.txt',
      );
      final m = params.toMap();
      expect(m, {'uri': 'file:///watched.txt'});

      final r = ResourceUpdatedNotificationParams.toMCP(m);
      expect(r.uri, 'file:///watched.txt');
    });
  });

  // ── CompleteRequest / Reference union ────────────────────────────────────

  group('CompleteRequest', () {
    test('toMap / toMCP round-trip with a prompt reference', () {
      final req = CompleteRequest(
        id: '8',
        params: CompleteRequestParams(
          $meta: _meta(),
          ref: PromptReference(name: 'greet'),
          argument: CompleteRequestParamsArgument(name: 'name', value: 'Al'),
        ),
      );
      final r = CompleteRequest.toMCP(req.toMap());
      expect(r.params.argument.value, 'Al');
      expect(r.params.ref, isA<PromptReference>());
    });

    test('Reference.toMCP dispatches ref/resource to ResourceTemplateReference',
        () {
      final ref = ResourceTemplateReference(uri: 'file:///{path}');
      expect(ref.type, 'ref/resource');

      final restored = Reference.toMCP(ref.toMap());
      expect(restored, isA<ResourceTemplateReference>());
      expect((restored as ResourceTemplateReference).uri, 'file:///{path}');
    });
  });

  group('CompleteResultCompletion', () {
    test('uses the `values` field name', () {
      final completion = CompleteResultCompletion(
        values: ['a', 'b'],
        total: 2,
        hasMore: false,
      );
      final m = completion.toMap();
      expect(m['values'], ['a', 'b']);
      expect(m.containsKey('value'), isFalse);

      final r = CompleteResultCompletion.toMCP(m);
      expect(r.values, ['a', 'b']);
    });
  });

  group('CompleteResult', () {
    test('toMap / toMCP round-trip includes resultType', () {
      final result = CompleteResult(
        completion: CompleteResultCompletion(values: ['x']),
      );
      final m = result.toMap();
      expect(m['resultType'], 'complete');

      final r = CompleteResult.toMCP(m);
      expect(r.completion.values, ['x']);
      expect(r.resultType, 'complete');
    });
  });

  // ── Elicitation ───────────────────────────────────────────────────────────

  group('ElicitRequest', () {
    test('uses the elicitation/create method', () {
      final req = ElicitRequest(
        id: '1',
        params: ElicitRequestFormParams(message: 'Please confirm'),
      );
      expect(req.toMap()['method'], 'elicitation/create');
    });
  });

  group('ElicitRequestParams', () {
    test('form params default to mode "form"', () {
      final params = ElicitRequestFormParams(message: 'Please confirm');
      expect(params.toMap()['mode'], 'form');

      final restored = ElicitRequestParams.toMCP(params.toMap());
      expect(restored, isA<ElicitRequestFormParams>());
    });

    test('url params use mode "url" and dispatch correctly', () {
      final params = ElicitRequestURLParams(
        message: 'Please authorize',
        url: 'https://example.com/authorize',
      );
      final m = params.toMap();
      expect(m['mode'], 'url');

      final restored = ElicitRequestParams.toMCP(m);
      expect(restored, isA<ElicitRequestURLParams>());
      expect((restored as ElicitRequestURLParams).url,
          'https://example.com/authorize');
    });
  });

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

  // ── StringSchema / NumberSchema / BooleanSchema ──────────────────────────

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

  group('NumberSchema', () {
    test('toMap / toMCP round-trip', () {
      final s = NumberSchema(minimum: 0, maximum: 10, defaultValue: 5);
      final r = NumberSchema.toMCP(s.toMap());
      expect(r.minimum, 0);
      expect(r.maximum, 10);
    });
  });

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

  group('LegacyTitledEnumSchema', () {
    test('is deprecated but still round-trips', () {
      // ignore: deprecated_member_use_from_same_package
      final s = LegacyTitledEnumSchema(
        $enum: ['a', 'b'],
        enumNames: ['A', 'B'],
      );
      // ignore: deprecated_member_use_from_same_package
      final r = LegacyTitledEnumSchema.toMCP(s.toMap());
      expect(r.$enum, ['a', 'b']);
      expect(r.enumNames, ['A', 'B']);
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
    test('toMap always includes resultType', () {
      expect(EmptyResult().toMap(), {'resultType': 'complete'});
    });
  });

  // ── PaginatedRequestParams / RequestParams ───────────────────────────────

  group('PaginatedRequestParams', () {
    test('toMCP round-trip with cursor and required _meta', () {
      final p = PaginatedRequestParams(cursor: 'cur1', $meta: _meta());
      final r = PaginatedRequestParams.toMCP(p.toMap());
      expect(r.cursor, 'cur1');
      expect(r.$meta.protocolVersion, '2026-07-28');
    });
  });

  group('RequestParams', () {
    test('_meta is required', () {
      final p = RequestParams($meta: _meta());
      final r = RequestParams.toMCP(p.toMap());
      expect(r.$meta.protocolVersion, '2026-07-28');
    });
  });

  // ── ToolListChangedNotification / ResourceListChangedNotification ───────

  group('ToolListChangedNotification', () {
    test('toMap has correct method', () {
      final n = ToolListChangedNotification();
      expect(n.toMap()['method'], 'notifications/tools/list_changed');
    });
  });

  group('ResourceListChangedNotification', () {
    test('toMap has correct method', () {
      final n = ResourceListChangedNotification();
      expect(n.toMap()['method'], 'notifications/resources/list_changed');
    });
  });

  // ── server/discover ──────────────────────────────────────────────────────

  group('DiscoverRequest', () {
    test('toMap / toMCP round-trip', () {
      final req =
          DiscoverRequest(id: '1', params: RequestParams($meta: _meta()));
      expect(req.toMap()['method'], 'server/discover');

      final r = DiscoverRequest.toMCP(req.toMap());
      expect(r.params.$meta.protocolVersion, '2026-07-28');
    });
  });

  group('DiscoverResult', () {
    test('toMap / toMCP round-trip with required ttlMs/cacheScope', () {
      final result = DiscoverResult(
        supportedVersions: ['2026-07-28', '2025-11-25'],
        capabilities: ServerCapabilities({'tools': {}}),
        instructions: 'Call server/discover first.',
        ttlMs: 3600000,
        cacheScope: CacheScope.public,
      );
      final m = result.toMap();
      expect(m['resultType'], 'complete');
      expect(m['ttlMs'], 3600000);

      final r = DiscoverResult.toMCP(m);
      expect(r.supportedVersions, ['2026-07-28', '2025-11-25']);
      expect(r.cacheScope, CacheScope.public);
      expect(r.instructions, 'Call server/discover first.');
    });
  });

  group('DiscoverResultResponse', () {
    test('toMap / toMCP round-trip', () {
      final resp = DiscoverResultResponse(
        id: '1',
        result: DiscoverResult(
          supportedVersions: ['2026-07-28'],
          capabilities: ServerCapabilities({}),
          ttlMs: 0,
          cacheScope: CacheScope.private,
        ),
      );
      final r = DiscoverResultResponse.toMCP(resp.toMap());
      expect(r.result.supportedVersions, ['2026-07-28']);
    });
  });

  // ── subscriptions/listen ──────────────────────────────────────────────────

  group('SubscriptionFilter', () {
    test('toMap / toMCP round-trip', () {
      final filter = SubscriptionFilter(
        toolsListChanged: true,
        resourceSubscriptions: ['file:///a.txt'],
      );
      final r = SubscriptionFilter.toMCP(filter.toMap());
      expect(r.toolsListChanged, isTrue);
      expect(r.resourceSubscriptions, ['file:///a.txt']);
    });
  });

  group('SubscriptionsListenRequest', () {
    test('toMap / toMCP round-trip', () {
      final req = SubscriptionsListenRequest(
        id: '1',
        params: SubscriptionsListenRequestParams(
          $meta: _meta(),
          notifications: SubscriptionFilter(toolsListChanged: true),
        ),
      );
      expect(req.toMap()['method'], 'subscriptions/listen');

      final r = SubscriptionsListenRequest.toMCP(req.toMap());
      expect(r.params.notifications.toolsListChanged, isTrue);
    });
  });

  group('SubscriptionsListenResult', () {
    test('toMap / toMCP round-trip', () {
      final result = SubscriptionsListenResult(
        $meta: SubscriptionsListenResultMetaObject(subscriptionId: '1'),
      );
      final r = SubscriptionsListenResult.toMCP(result.toMap());
      expect(r.$meta.subscriptionId, '1');
      expect(r.resultType, 'complete');
    });
  });

  group('SubscriptionsAcknowledgedNotification', () {
    test('toMap / toMCP round-trip', () {
      final notif = SubscriptionsAcknowledgedNotification(
        params: SubscriptionsAcknowledgedNotificationParams(
          notifications: SubscriptionFilter(promptsListChanged: true),
        ),
      );
      expect(
        notif.toMap()['method'],
        'notifications/subscriptions/acknowledged',
      );

      final r = SubscriptionsAcknowledgedNotification.toMCP(notif.toMap());
      expect(r.params.notifications.promptsListChanged, isTrue);
    });
  });

  // ── Deprecated sampling / roots types still round-trip ───────────────────

  group('Deprecated sampling types', () {
    test('SamplingMessage only accepts non-resource content blocks', () {
      // ignore: deprecated_member_use_from_same_package
      final msg = SamplingMessage(
        role: Role.user,
        content: [TextContent(text: 'hi', mimeType: 'text/plain')],
      );
      // ignore: deprecated_member_use_from_same_package
      final r = SamplingMessage.toMCP(msg.toMap());
      expect(r.content.first, isA<TextContent>());
    });

    test('CreateMessageRequest / CreateMessageResult round-trip', () {
      // ignore: deprecated_member_use_from_same_package
      final req = CreateMessageRequest(
        params: CreateMessageRequestParams(
          // ignore: deprecated_member_use_from_same_package
          messages: [
            SamplingMessage(
              role: Role.user,
              content: [TextContent(text: 'hi', mimeType: 'text/plain')],
            ),
          ],
          maxTokens: 100,
        ),
      );
      expect(req.toMap()['method'], 'sampling/createMessage');

      final result = CreateMessageResult(
        model: 'test-model',
        role: Role.assistant,
        content: [TextContent(text: 'hello back', mimeType: 'text/plain')],
      );
      final r = CreateMessageResult.toMCP(result.toMap());
      expect(r.model, 'test-model');
    });
  });

  group('Deprecated roots types', () {
    test('Root / ListRootsResult round-trip', () {
      // ignore: deprecated_member_use_from_same_package
      final result = ListRootsResult(
        // ignore: deprecated_member_use_from_same_package
        roots: [Root(uri: 'file:///project')],
      );
      // ignore: deprecated_member_use_from_same_package
      final r = ListRootsResult.toMCP(result.toMap());
      expect(r.roots.first.uri, 'file:///project');
    });
  });

  group('Deprecated LoggingMessageNotification', () {
    test('toMap / toMCP round-trip', () {
      // ignore: deprecated_member_use_from_same_package
      final notif = LoggingMessageNotification(
        // ignore: deprecated_member_use_from_same_package
        params: LoggingMessageNotificationParams(
          // ignore: deprecated_member_use_from_same_package
          level: LoggingLevel.warning,
          data: 'careful',
        ),
      );
      expect(notif.toMap()['method'], 'notifications/message');

      // ignore: deprecated_member_use_from_same_package
      final r = LoggingMessageNotification.toMCP(notif.toMap());
      // ignore: deprecated_member_use_from_same_package
      expect(r.params.level, LoggingLevel.warning);
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
      expect(result.ttlMs, 0);
      expect(result.cacheScope, CacheScope.private);
    });

    test('registers resource and returns it in buildResourcesResult', () {
      final builder = McpBuilder();
      builder.resource(
        name: 'readme',
        uri: 'file:///README.md',
        handler: (req) async => ReadResourceResult(
          contents: [],
          ttlMs: 0,
          cacheScope: CacheScope.private,
        ),
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
        handler: (req) async => ReadResourceResult(
          contents: [],
          ttlMs: 0,
          cacheScope: CacheScope.private,
        ),
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
}
