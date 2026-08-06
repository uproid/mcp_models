## 2.0.0
Full migration to the [MCP 2026-07-28 schema](https://modelcontextprotocol.io/specification/2026-07-28/schema). This is a breaking release — no backward-compatible shim is provided.

- Added:
  - `server/discover` RPC family: `DiscoverRequest`, `DiscoverResultResponse`, `DiscoverResult`. Servers now advertise capabilities out-of-band instead of via a one-time handshake.
  - `subscriptions/listen` RPC family: `SubscriptionFilter`, `SubscriptionsListenRequest`/`SubscriptionsListenRequestParams`, `SubscriptionsListenResultMetaObject`, `SubscriptionsListenResult`/`SubscriptionsListenResultResponse`, `SubscriptionsAcknowledgedNotification`/`SubscriptionsAcknowledgedNotificationParams`. Replaces `resources/subscribe` / `resources/unsubscribe`.
  - Multi-round-trip support: `InputRequiredResult`, `InputResponseRequestParams` (base for `GetPromptRequestParams`, `ReadResourceRequestParams`, `CallToolRequestParams`), and `resultType`-discriminated outcome unions (`CallToolResultOutcome`, `GetPromptResultOutcome`, `ReadResourceResultOutcome`).
  - `RequestMetaObject`, `NotificationMetaObject`, `ResultMetaObject`: purpose-specific `_meta` shapes replacing the generic, undifferentiated `MetaObject` on requests/notifications/results. `RequestMetaObject` now carries per-request protocol negotiation state (`protocolVersion`, `clientCapabilities`, `clientInfo`).
  - New error types: `HeaderMismatchError` (-32020), `MissingRequiredClientCapabilityError` (-32021), `UnsupportedProtocolVersionError` (-32022).
  - `CacheScope` enum (`public`/`private`) and required `ttlMs`/`cacheScope` fields on cacheable list/read results.
  - `SamplingMessageContentBlock` restricted content-block union (deprecated on arrival, SEP-2577).
  - `LoggingMessageNotification` wrapper class (deprecated on arrival, SEP-2577), joining the pre-existing `LoggingMessageNotificationParams`.
- Changed (breaking):
  - `_meta` is now **required** (non-nullable `RequestMetaObject`) on `RequestParams`, `PaginatedRequestParams`, and every concrete `*RequestParams` type — protocol version and capabilities are declared on every request instead of once via `initialize`.
  - `Result` gained a required-on-the-wire `resultType` field (defaults to `'complete'`) and a `ResultMetaObject? $meta` (was a bare, mis-serialised `meta` field writing the wrong wire key `'meta'` instead of `'_meta'`).
  - `CallToolResultResponse.result`, `GetPromptResultResponse.result`, `ReadResourceResultResponse.result` are now discriminated unions (`InputRequiredResult | <Result>`) dispatched on `resultType`.
  - `CancelledNotification` method fixed from `"notification/cancelled"` to `"notifications/cancelled"`; `CancelledNotificationParams.requestId` is now required.
  - `CompleteResultCompletion.value` renamed to `values` (matches the wire key).
  - `ResourceTemplateReference.type` fixed from `"ref/resource_template"` to `"ref/resource"`.
  - `ElicitRequest.method` fixed to `"elicitation/create"`; `ElicitRequestParams` is now a proper discriminated union (`ElicitRequestFormParams | ElicitRequestURLParams`) dispatched on a `mode` field (was `node`); dropped the unspecified `task`/`elicitationId` fields.
  - `ResourceUpdatedNotificationParams` reshaped to `{_meta?, uri}` (was `{resourceId, resourceType, data}`).
  - `Implementation.version` is now required.
  - `Tool.inputSchema`/`outputSchema` (`ToolSchema`) now round-trip arbitrary JSON Schema 2020-12 keywords losslessly via `additionalData`, alongside the existing typed `properties`/`required`/`type` convenience fields.
- Removed:
  - The entire Task system: `Task`, `TaskStatus`, `TaskMetadata`, `TaskStatusNotification`(+Params), `CreateTaskResult`(+Response), `GetTaskRequest`(+Params), `GetTaskPayloadRequest`/`GetTaskPayloadResult`(+Response), `ListTasksRequest`/`ListTasksResult`(+Response), `CancelTaskRequest`/`CancelTaskResult`(+Response), `RelatedTaskMetadata`. Superseded by `resultType: "input_required"` + `InputRequiredResult`.
  - The `initialize` handshake and `ping`: `InitializeRequest`/`InitializeRequestParams`/`InitializeResult`/`InitializeResultResponse`, `InitializedNotification`, `PingRequest`/`PingResultResponse`. The 2026-07-28 schema reference no longer defines these — every request now carries its own protocol negotiation state via `RequestMetaObject`, and `server/discover` replaces capability advertisement.
  - `logging/setLevel`: `SetLevelRequest`/`SetLevelRequestParams`/`SetLevelResultResponse`. Superseded by the (deprecated) `RequestMetaObject.logLevel` field.
  - `ElicitationCompleteNotification`/`ElicitationCompleteNotificationParams`.
  - `resources/subscribe` / `resources/unsubscribe`: `SubscribeRequest`/`SubscribeRequestParams`/`SubscribeResultResponse`, `UnsubscribeRequestParams`/`UnsubscribeResultResponse`. Superseded by `subscriptions/listen`.
  - `Tool.execution` / `ToolExecution` (a Task-system casualty).
  - The dead, unused `TextResourceContent` class (singular — distinct from, and not to be confused with, `TextResourceContents`).
- Deprecated (SEP-2577, remain functional for at least twelve months): `LoggingLevel`, `LoggingMessageNotification`(+Params), `RequestMetaObject.logLevel`, `Root`, `ListRootsRequest`, `ListRootsResult`, `CreateMessageRequest`(+Params), `CreateMessageResult`, `ModelHint`, `ModelPreferences`, `SamplingMessage`, `SamplingMessageContentBlock`, `ToolChoice`, `ToolResultContent`, `ToolUseContent`, `LegacyTitledEnumSchema`. `ClientCapabilities.roots`/`.sampling` and `ServerCapabilities.logging` remain valid raw-map keys, now documented as deprecated.

[2.0.0]: https://github.com/uproid/mcp_models/releases/tag/v2.0.0

## 1.0.2
- Fixed some incorrect field types in the Dart models (e.g. `error` field in `JSONRPCErrorResponse`).
- Updated example code and tests to reflect these corrections.
- Added missing Dart doc comments on some public classes and fields.

## 1.0.1
- Fixed Pubspec metadata

## 1.0.0
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

