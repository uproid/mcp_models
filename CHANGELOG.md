# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-08

### Added

- Full Dart model coverage for the [MCP 2025-11-25 schema](https://modelcontextprotocol.io/specification/2025-11-25/schema).
- `MCP` base interface with `toMap()` and named factory `TypeName.toMCP(Map)` on every type.
- `MapMC<K,V>` / `MapModel<K,V>` base classes for types whose serialised form is the map itself.
- `McpBuilder` helper for declarative server capability registration (tools, resources, prompts, resource templates, custom methods).
- JSON-RPC core types: `JSONRPCRequest`, `JSONRPCNotification`, `JSONRPCResultResponse`, `JSONRPCErrorResponse`.
- Standard error types: `ParseError`, `InvalidRequestError`, `MethodNotFoundError`, `InvalidParamsError`, `InternalError`.
- Initialization types: `InitializeRequest`, `InitializeResult`, `Implementation`, `ClientCapabilities`, `ServerCapabilities`.
- Tool types: `Tool`, `ToolSchema`, `ToolAnnotations`, `ToolExecution`, `CallToolRequest`, `CallToolResult`, `ListToolsResult`.
- Resource types: `Resource`, `ResourceTemplate`, `TextResourceContents`, `BlobResourceContents`, `ReadResourceResult`, `ListResourcesResult`.
- Prompt types: `Prompt`, `PromptArgument`, `PromptMessage`, `GetPromptResult`, `ListPromptsResult`.
- Sampling types: `CreateMessageRequest`, `CreateMessageResult`, `SamplingMessage`, `ModelPreferences`, `ModelHint`, `ToolChoice`.
- Elicitation types: `ElicitRequest`, `ElicitResult`, `StringSchema`, `NumberSchema`, `BooleanSchema`, `UntitledSingleSelectEnumSchema`, `TitledSingleSelectEnumSchema`.
- Task types: `Task`, `TaskStatus`, `TaskMetadata`, `ListTasksResult`.
- Content block types: `TextContent`, `ImageContent`, `AudioContent`, `EmbeddedResource`, `ResourceLink`.
- Notification types: `InitializedNotification`, `CancelledNotification`, `ProgressNotification`, `ToolListChangedNotification`, `ResourceListChangedNotification`, `LoggingMessageNotificationParams`.
- Miscellaneous types: `PingRequest`, `EmptyResult`, `Annotations`, `Role`, `LoggingLevel`, `MetaObject`, `Icon`, `Theme`.
- Dart doc comments on all public classes and fields.
- Comprehensive test suite covering serialisation round-trips, enum factories, error codes, and `McpBuilder` registration.
- End-to-end example in `example/mcp_models_example.dart`.

[1.0.0]: https://github.com/uproid/mcp_models/releases/tag/v1.0.0

