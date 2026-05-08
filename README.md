# mcp_models

[![pub.dev](https://img.shields.io/pub/v/mcp_models.svg)](https://pub.dev/packages/mcp_models)
[![Dart](https://github.com/uproid/mcp_models/actions/workflows/dart.yml/badge.svg)](https://github.com/uproid/mcp_models/actions/workflows/dart.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Dart model classes for the [Model Context Protocol (MCP) 2025-11-25](https://modelcontextprotocol.io/specification/2025-11-25/schema).

Every type defined in the official MCP schema is available as a plain Dart class
with `toMap()` serialisation and a named factory `TypeName.toMCP(Map)` for
deserialisation — no code generation required.

---

## Features

- Full coverage of the MCP 2025-11-25 schema: JSON-RPC messages, tools,
  resources, prompts, sampling, elicitation, tasks, notifications and more.
- Zero runtime dependencies — pure Dart.
- `McpBuilder` helper for declarative server capability registration.
- `MapMC<K,V>` and `MapModel<K,V>` base classes for types whose serialised form
  _is_ the underlying map.

---

## Installation

```yaml
dependencies:
  mcp_models: ^1.0.0
```

Or with the CLI:

```sh
dart pub add mcp_models
```

---

## Quick start

```dart
import 'package:mcp_models/mcp_models.dart';

// Build an initialize request.
final request = InitializeRequest(
  id: '1',
  params: InitializeRequestParams(
    protocolVersion: '2025-11-25',
    capabilities: ClientCapabilities({}),
    clientInfo: Implementation(name: 'my_client', version: '1.0.0'),
  ),
);

// Serialise to a Map (ready for JSON encoding).
final json = request.toMap();

// Deserialise back.
final restored = InitializeRequest.toMCP(json);
```

---

## McpBuilder

`McpBuilder` lets you declare all server capabilities in one place and look up
handlers by name/URI at runtime:

```dart
final builder = McpBuilder();

builder.tool(
  name: 'add',
  description: 'Adds two integers.',
  inputSchema: ToolSchema(
    properties: {
      'a': {'type': 'integer'},
      'b': {'type': 'integer'},
    },
    required: ['a', 'b'],
  ),
  handler: (req) async {
    final args = req.params.arguments ?? {};
    final sum = (args['a'] as int) + (args['b'] as int);
    return CallToolResult(
      content: [TextContent(text: '$sum', mimeType: 'text/plain')],
    );
  },
);

builder.resource(
  name: 'config',
  uri: 'file:///config.json',
  handler: (req) async => ReadResourceResult(contents: []),
);

builder.prompt(
  name: 'greet',
  handler: (req) async => GetPromptResult(messages: []),
);

// Serve a tools/list response.
final toolsResult = builder.buildToolsResult();

// Dispatch a tools/call request.
final handler = builder.toolHandler('add');
if (handler != null) {
  final result = await handler(callToolRequest);
}
```

---

## Supported MCP types

| Category | Types |
|---|---|
| JSON-RPC core | `JSONRPCRequest`, `JSONRPCNotification`, `JSONRPCResultResponse`, `JSONRPCErrorResponse` |
| Errors | `Error`, `ParseError`, `InvalidRequestError`, `MethodNotFoundError`, `InvalidParamsError`, `InternalError` |
| Initialization | `InitializeRequest`, `InitializeRequestParams`, `InitializeResult`, `Implementation`, `ClientCapabilities`, `ServerCapabilities` |
| Tools | `Tool`, `ToolSchema`, `ToolAnnotations`, `ToolExecution`, `CallToolRequest`, `CallToolResult`, `ListToolsResult` |
| Resources | `Resource`, `ResourceTemplate`, `TextResourceContents`, `BlobResourceContents`, `ReadResourceResult`, `ListResourcesResult` |
| Prompts | `Prompt`, `PromptArgument`, `PromptMessage`, `GetPromptResult`, `ListPromptsResult` |
| Sampling | `CreateMessageRequest`, `CreateMessageResult`, `SamplingMessage`, `ModelPreferences`, `ModelHint`, `ToolChoice` |
| Elicitation | `ElicitRequest`, `ElicitResult`, `StringSchema`, `NumberSchema`, `BooleanSchema`, `UntitledSingleSelectEnumSchema`, `TitledSingleSelectEnumSchema` |
| Tasks | `Task`, `TaskStatus`, `TaskMetadata`, `ListTasksResult` |
| Content blocks | `TextContent`, `ImageContent`, `AudioContent`, `EmbeddedResource`, `ResourceLink` |
| Notifications | `InitializedNotification`, `CancelledNotification`, `ProgressNotification`, `LoggingMessageNotificationParams`, `ToolListChangedNotification`, `ResourceListChangedNotification` |
| Misc | `PingRequest`, `EmptyResult`, `Annotations`, `Role`, `LoggingLevel`, `MetaObject`, `Icon`, `Theme` |

See the [example](example/mcp_models_example.dart) for end-to-end usage.

---

## MCP specification

This package targets the **MCP 2025-11-25** schema:
<https://modelcontextprotocol.io/specification/2025-11-25/schema>

---

## Contributing

Contributions, bug reports, and feature requests are very welcome!

**We especially encourage Dart developers to open GitHub Issues to help guide
the development and keep this package up to date with the evolving MCP
specification.**

Ways to contribute:

- **Found a bug or missing type?**
  [Open a bug report](https://github.com/uproid/mcp_models/issues/new?template=bug_report.md)

- **Want a new feature or schema update?**
  [Open a feature request](https://github.com/uproid/mcp_models/issues/new?template=feature_request.md)

- **Want to submit code?** See [CONTRIBUTING.md](.github/CONTRIBUTING.md).

Every issue, no matter how small, helps keep this package accurate and useful
for the entire Dart community. Thank you!

---

## License

MIT — see [LICENSE](LICENSE).
