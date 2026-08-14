import '../mcp.dart';
import '../v2026/enums.dart';
import '../v2026/types.dart';
import '../map_model.dart';

/// A [MapModel] that also satisfies [MCP].
///
/// Use as the base class when the model _is_ the underlying map
/// (e.g. [DiscoverResult], [ClientCapabilities]).
abstract class MapMC<K, V> extends MapModel<K, V> implements MCP {
  /// Creates a [MapMC].
  MapMC(super.data);
}

/// A JSON-RPC 2.0 error response.
///
/// Sent in reply to a request when an error occurred on the receiver's side.
class JSONRPCErrorResponse extends JSONRPCMessage {
  /// JSON-RPC version string, always `"2.0"`.
  String jsonrpc;

  /// The id of the originating request, if available.
  String? id;

  /// The structured error payload.
  Error error;

  /// Creates a [JSONRPCErrorResponse].
  JSONRPCErrorResponse({this.jsonrpc = '2.0', this.id, required this.error});

  /// Converts this [JSONRPCErrorResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'error': error.toMap()};
  }

  /// Builds a [JSONRPCErrorResponse] from a decoded MCP JSON map.
  factory JSONRPCErrorResponse.toMCP(Map<String, Object?> map) {
    return JSONRPCErrorResponse(
      jsonrpc: map['jsonrpc']?.toString() ?? '2.0',
      id: map['id']?.toString() ?? '-1',
      error: Error.toMCP(map['error'] as Map<String, Object?>),
    );
  }
}

/// A JSON-RPC 2.0 error object.
class Error extends MCP {
  /// Machine-readable error code (e.g. `-32600` for invalid request).
  int code;

  /// Short, human-readable error description.
  String message;

  /// Optional additional error data (provider-defined).
  Object? data;

  /// Creates an [Error].
  Error({required this.code, required this.message, this.data});

  /// Converts this [Error] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'code': code, 'message': message, 'data': data};
  }

  /// Builds an [Error] from a decoded MCP JSON map.
  factory Error.toMCP(Map<String, Object?> map) {
    return Error(
      code: map['code'] as int,
      message: map['message'] as String,
      data: map['data'],
    );
  }
}

/// Union base for all JSON-RPC wire objects.
abstract class JSONRPCMessage extends MCP {}

/// A JSON-RPC 2.0 notification (a request with no expected response).
class JSONRPCNotification extends JSONRPCMessage {
  /// JSON-RPC version string.
  String jsonrpc;

  /// The notification method name.
  String method;

  /// Optional notification parameters.
  Map<String, Object?>? params;

  /// Creates a [JSONRPCNotification].
  JSONRPCNotification({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
  });

  /// Converts this [JSONRPCNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params};
  }

  /// Builds a [JSONRPCNotification] from a decoded MCP JSON map.
  factory JSONRPCNotification.toMCP(Map<String, Object?> map) {
    return JSONRPCNotification(
      jsonrpc: map['jsonrpc'] as String,
      method: map['method'] as String,
      params: map['params'] as Map<String, Object?>?,
    );
  }
}

/// Abstract base for all JSON-RPC response objects.
abstract class JSONRPCResponse extends JSONRPCMessage {}

/// A successful JSON-RPC 2.0 response carrying a [Result].
class JSONRPCResultResponse extends JSONRPCResponse {
  /// JSON-RPC version string.
  String jsonrpc;

  /// The id of the originating request.
  String? id;

  /// The result payload.
  Result result;

  /// Creates a [JSONRPCResultResponse].
  JSONRPCResultResponse({this.jsonrpc = '2.0', this.id, required this.result});

  /// Converts this [JSONRPCResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [JSONRPCResultResponse] from a decoded MCP JSON map.
  factory JSONRPCResultResponse.toMCP(Map<String, Object?> map) {
    return JSONRPCResultResponse(
      jsonrpc: map['jsonrpc'] as String,
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// Generic MCP result that may carry arbitrary extra fields.
///
/// Every result produced by a server implementing protocol version
/// 2026-07-28 MUST include [resultType] on the wire; it defaults to
/// `'complete'` for ergonomics. A client talking to an older server that
/// omits the field MUST treat its absence as `'complete'`.
class Result extends MCP {
  /// Optional `_meta` object.
  ResultMetaObject? $meta;

  /// Indicates how the client should parse this result.
  ///
  /// `'complete'` means the result contains the final content. Other values
  /// (e.g. `'input_required'`) signal that the payload is actually an
  /// [InputRequiredResult].
  String resultType;

  /// Any additional unknown fields returned by the server.
  Map<String, Object?>? unknown;

  /// Creates a [Result].
  Result({this.$meta, this.resultType = 'complete', this.unknown});

  /// Converts this [Result] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'resultType': resultType,
      ...?unknown,
    };
  }

  /// Builds a [Result] from a decoded MCP JSON map.
  factory Result.toMCP(Map<String, Object?> map) {
    return Result(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      unknown: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => key == '_meta' || key == 'resultType'),
    );
  }
}

/// The `_meta` object carried inside a [Result].
///
/// May contain `"io.modelcontextprotocol/serverInfo"`, plus arbitrary
/// server-defined passthrough keys.
class ResultMetaObject extends MapMC<String, Object?> {
  /// Creates a [ResultMetaObject].
  ResultMetaObject({
    Implementation? serverInfo,
    Map<String, Object?>? additionalData,
  }) : super({
          if (serverInfo != null)
            'io.modelcontextprotocol/serverInfo': serverInfo.toMap(),
          ...?additionalData,
        });

  /// Identifies the server software producing the response.
  Implementation? get serverInfo =>
      data['io.modelcontextprotocol/serverInfo'] != null
          ? Implementation.toMCP(
              data['io.modelcontextprotocol/serverInfo']
                  as Map<String, Object?>,
            )
          : null;

  set serverInfo(Implementation? value) =>
      data['io.modelcontextprotocol/serverInfo'] = value?.toMap();

  /// Converts this [ResultMetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() => data;

  /// Builds a [ResultMetaObject] from a decoded MCP JSON map.
  factory ResultMetaObject.toMCP(Map<String, Object?> map) {
    return ResultMetaObject(additionalData: map);
  }
}

/// The `_meta` object carried inside notification params.
///
/// May contain `"io.modelcontextprotocol/subscriptionId"`, plus arbitrary
/// notification-defined passthrough keys.
class NotificationMetaObject extends MapMC<String, Object?> {
  /// Creates a [NotificationMetaObject].
  NotificationMetaObject({
    String? subscriptionId,
    Map<String, Object?>? additionalData,
  }) : super({
          if (subscriptionId != null)
            'io.modelcontextprotocol/subscriptionId': subscriptionId,
          ...?additionalData,
        });

  /// Identifies the `subscriptions/listen` stream this notification was
  /// delivered on. Absent for notifications not delivered via a
  /// subscription stream (e.g. progress notifications).
  String? get subscriptionId =>
      data['io.modelcontextprotocol/subscriptionId']?.toString();

  set subscriptionId(String? value) =>
      data['io.modelcontextprotocol/subscriptionId'] = value;

  /// Converts this [NotificationMetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() => data;

  /// Builds a [NotificationMetaObject] from a decoded MCP JSON map.
  factory NotificationMetaObject.toMCP(Map<String, Object?> map) {
    return NotificationMetaObject(additionalData: map);
  }
}

/// A result indicating the original request requires additional client
/// input before the server can produce a final answer.
///
/// Sent as the `result` payload of a [CallToolResultResponse],
/// [GetPromptResultResponse], or [ReadResourceResultResponse] when
/// [resultType] is `"input_required"`. The client should collect
/// [inputRequests] from the user (and/or echo back [requestState]) and
/// retry the original request with `inputResponses`/`requestState` set.
class InputRequiredResult extends MapMC<String, Object?>
    implements
        CallToolResultOutcome,
        GetPromptResultOutcome,
        ReadResourceResultOutcome {
  /// Fixed discriminator — always `"input_required"`.
  String get resultType => 'input_required';

  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();

  /// The input the client should collect from the user before retrying.
  InputRequests? get inputRequests => data['inputRequests'];

  set inputRequests(InputRequests? value) => data['inputRequests'] = value;

  /// Opaque state token to echo back verbatim on retry.
  String? get requestState => data['requestState'] as String?;

  set requestState(String? value) => data['requestState'] = value;

  /// Creates an [InputRequiredResult].
  InputRequiredResult({
    ResultMetaObject? $meta,
    InputRequests? inputRequests,
    String? requestState,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': 'input_required',
          if (inputRequests != null) 'inputRequests': inputRequests,
          if (requestState != null) 'requestState': requestState,
          ...?additionalData,
        });

  /// Converts this [InputRequiredResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() => data;

  /// Builds an [InputRequiredResult] from a decoded MCP JSON map.
  factory InputRequiredResult.toMCP(Map<String, Object?> map) {
    return InputRequiredResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      inputRequests: map['inputRequests'],
      requestState: map['requestState'] as String?,
      additionalData: Map<String, Object?>.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'inputRequests' ||
              key == 'requestState',
        ),
    );
  }
}

/// Discriminated union: either an [InputRequiredResult] pause or the
/// completed [CallToolResult], as returned by `CallToolResultResponse.result`.
abstract class CallToolResultOutcome implements MCP {
  /// Builds a [CallToolResultOutcome] from a decoded MCP JSON map.
  factory CallToolResultOutcome.toMCP(Map<String, Object?> map) {
    if (map['resultType'] == 'input_required') {
      return InputRequiredResult.toMCP(map);
    }
    return CallToolResult.toMCP(map);
  }
}

/// Discriminated union: either an [InputRequiredResult] pause or the
/// completed [GetPromptResult], as returned by `GetPromptResultResponse.result`.
abstract class GetPromptResultOutcome implements MCP {
  /// Builds a [GetPromptResultOutcome] from a decoded MCP JSON map.
  factory GetPromptResultOutcome.toMCP(Map<String, Object?> map) {
    if (map['resultType'] == 'input_required') {
      return InputRequiredResult.toMCP(map);
    }
    return GetPromptResult.toMCP(map);
  }
}

/// Discriminated union: either an [InputRequiredResult] pause or the
/// completed [ReadResourceResult], as returned by
/// `ReadResourceResultResponse.result`.
abstract class ReadResourceResultOutcome implements MCP {
  /// Builds a [ReadResourceResultOutcome] from a decoded MCP JSON map.
  factory ReadResourceResultOutcome.toMCP(Map<String, Object?> map) {
    if (map['resultType'] == 'input_required') {
      return InputRequiredResult.toMCP(map);
    }
    return ReadResourceResult.toMCP(map);
  }
}

/// Holds the `_meta` map present on many MCP types.
class MetaObject extends MCP {
  Map<String, Object?> _data;

  /// Creates a [MetaObject].
  MetaObject(this._data);

  /// Converts this [MetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return _data;
  }

  /// Builds a [MetaObject] from a decoded MCP JSON map.
  factory MetaObject.toMCP(Map<String, Object?> map) {
    return MetaObject(map);
  }
}

/// A JSON-RPC 2.0 request that expects a response.
class JSONRPCRequest extends MCP {
  /// The request method name.
  String method;

  /// Optional request parameters.
  Map<String, Object?>? params;

  /// JSON-RPC version string.
  String jsonrpc;

  /// Unique request identifier.
  String id;

  /// Creates a [JSONRPCRequest].
  JSONRPCRequest({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
    required this.id,
  });

  /// Converts this [JSONRPCRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params, 'id': id};
  }

  /// Builds a [JSONRPCRequest] from a decoded MCP JSON map.
  factory JSONRPCRequest.toMCP(Map<String, Object?> map) {
    return JSONRPCRequest(
      jsonrpc: map['jsonrpc'] as String,
      method: map['method'] as String,
      params: map['params'] as Map<String, Object?>?,
      id: map['id']?.toString() ?? '-1',
    );
  }
}

/// Optional client hints attached to MCP content objects.
///
/// See [MCP spec – Annotations](https://modelcontextprotocol.io/specification/2026-07-28/schema).
class Annotations extends MCP {
  /// Importance from `0` (least) to `1` (most important).
  int? priority;

  /// ISO 8601 timestamp of last modification.
  String? lastModified;

  /// Intended audience roles for this content.
  List<Role>? audience;

  /// Creates an [Annotations].
  Annotations({this.priority, this.lastModified, this.audience});

  /// Converts this [Annotations] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (priority != null) 'priority': priority,
      if (lastModified != null) 'lastModified': lastModified,
      if (audience != null)
        'audience': audience!.map((e) => e.toString()).toList(),
    };
  }

  /// Builds an [Annotations] from a decoded MCP JSON map.
  factory Annotations.toMCP(Map<String, Object?> map) {
    return Annotations(
      priority: map['priority'] as int?,
      lastModified: map['lastModified'] as String?,
      audience: map['audience'] != null
          ? (map['audience'] as List<dynamic>)
              .map((e) => Role.to(e as String))
              .toList()
          : null,
    );
  }
}

/// A successful result that carries no data.
class EmptyResult extends Result {
  /// Creates an [EmptyResult].
  EmptyResult({super.$meta, super.resultType = 'complete'});
}

/// An optionally-sized icon that may be displayed in a UI.
class Icon extends MCP {
  /// URI pointing to the icon resource (HTTP/HTTPS or `data:` URI).
  String src;

  /// Optional MIME-type override.
  String? mimeType;

  /// Sizes at which the icon can be used, e.g. `["48x48", "any"]`.
  List<String>? sizes;

  /// Theme the icon is designed for.
  Theme? theme;

  /// Creates an [Icon].
  Icon({required this.src, this.mimeType, this.sizes, this.theme});

  /// Converts this [Icon] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'src': src,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizes != null) 'sizes': sizes,
      if (theme != null) 'theme': theme!.name,
    };
  }

  /// Builds an [Icon] from a decoded MCP JSON map.
  factory Icon.toMCP(Map<String, Object?> map) {
    return Icon(
      src: map['src'] as String,
      mimeType: map['mimeType'] as String?,
      sizes: (map['sizes'] as List<dynamic>?)?.cast<String>(),
      theme: map['theme'] != null ? Theme.to(map['theme'] as String) : null,
    );
  }
}

/// Parameters shared by MCP notifications.
class NotificationParams extends MCP {
  /// Optional notification metadata.
  NotificationMetaObject? $meta;

  /// Creates a [NotificationParams].
  NotificationParams({this.$meta});

  /// Converts this [NotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap()};
  }

  /// Builds a [NotificationParams] from a decoded MCP JSON map.
  factory NotificationParams.toMCP(Map<String, Object?> map) {
    return NotificationParams(
      $meta: map['_meta'] != null
          ? NotificationMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// The `_meta` object carried inside request params.
///
/// Every request now declares its own protocol negotiation state —
/// [protocolVersion] and [clientCapabilities] are required on every request
/// rather than negotiated once via an `initialize` handshake.
class RequestMetaObject extends MapMC<String, Object?> {
  /// Creates a [RequestMetaObject].
  RequestMetaObject({
    String? progressToken,
    required String protocolVersion,
    required ClientCapabilities clientCapabilities,
    Implementation? clientInfo,
    @Deprecated(
      'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
      'Remains in the specification for at least twelve months.',
    )
    LoggingLevel? logLevel,
    Map<String, Object?>? additionalData,
  }) : super({
          if (progressToken != null) 'progressToken': progressToken,
          'io.modelcontextprotocol/protocolVersion': protocolVersion,
          'io.modelcontextprotocol/clientCapabilities':
              clientCapabilities.toMap(),
          if (clientInfo != null)
            'io.modelcontextprotocol/clientInfo': clientInfo.toMap(),
          if (logLevel != null)
            'io.modelcontextprotocol/logLevel': logLevel.toString(),
          ...?additionalData,
        });

  /// Out-of-band progress-notification correlation token.
  String? get progressToken => data['progressToken'] as String?;

  set progressToken(String? value) => data['progressToken'] = value;

  /// The MCP protocol version being used for this request. Required.
  String get protocolVersion =>
      data['io.modelcontextprotocol/protocolVersion'] as String;

  set protocolVersion(String value) =>
      data['io.modelcontextprotocol/protocolVersion'] = value;

  /// The client's capabilities for this specific request. Required.
  ClientCapabilities get clientCapabilities => ClientCapabilities.toMCP(
        data['io.modelcontextprotocol/clientCapabilities']
            as Map<String, Object?>,
      );

  set clientCapabilities(ClientCapabilities value) =>
      data['io.modelcontextprotocol/clientCapabilities'] = value.toMap();

  /// Self-reported information about the calling client.
  Implementation? get clientInfo =>
      data['io.modelcontextprotocol/clientInfo'] != null
          ? Implementation.toMCP(
              data['io.modelcontextprotocol/clientInfo']
                  as Map<String, Object?>,
            )
          : null;

  set clientInfo(Implementation? value) =>
      data['io.modelcontextprotocol/clientInfo'] = value?.toMap();

  /// The desired log level for this request.
  @Deprecated(
    'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
    'Remains in the specification for at least twelve months.',
  )
  LoggingLevel? get logLevel => data['io.modelcontextprotocol/logLevel'] != null
      ? LoggingLevel.to(data['io.modelcontextprotocol/logLevel'] as String)
      : null;

  @Deprecated(
    'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
    'Remains in the specification for at least twelve months.',
  )
  set logLevel(LoggingLevel? value) =>
      data['io.modelcontextprotocol/logLevel'] = value?.toString();

  /// Converts this [RequestMetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [RequestMetaObject] from a decoded MCP JSON map.
  factory RequestMetaObject.toMCP(Map<String, Object?> map) {
    return RequestMetaObject(
      progressToken: map['progressToken']?.toString(),
      protocolVersion:
          map['io.modelcontextprotocol/protocolVersion'] as String? ??
              '2025-11-25',
      clientCapabilities: ClientCapabilities.toMCP(
        map['io.modelcontextprotocol/clientCapabilities']
                as Map<String, Object?>? ??
            <String, Object?>{},
      ),
      clientInfo: map['io.modelcontextprotocol/clientInfo'] != null
          ? Implementation.toMCP(
              map['io.modelcontextprotocol/clientInfo'] as Map<String, Object?>,
            )
          : null,
      // ignore: deprecated_member_use_from_same_package
      logLevel: map['io.modelcontextprotocol/logLevel'] != null
          ? LoggingLevel.to(map['io.modelcontextprotocol/logLevel'] as String)
          : null,
      additionalData: Map<String, Object?>.from(map)
        ..removeWhere(
          (key, _) =>
              key == 'progressToken' ||
              key == 'io.modelcontextprotocol/protocolVersion' ||
              key == 'io.modelcontextprotocol/clientCapabilities' ||
              key == 'io.modelcontextprotocol/clientInfo' ||
              key == 'io.modelcontextprotocol/logLevel',
        ),
    );
  }
}

/// Request params for paginated MCP list calls.
class PaginatedRequestParams extends MCP {
  /// Opaque pagination cursor from a previous response.
  String? cursor;

  /// Request metadata (required — carries protocol version & capabilities).
  RequestMetaObject $meta;

  /// Creates a [PaginatedRequestParams].
  PaginatedRequestParams({this.cursor, required this.$meta});

  /// Converts this [PaginatedRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (cursor != null) 'cursor': cursor,
      '_meta': $meta.toMap(),
    };
  }

  /// Builds a [PaginatedRequestParams] from a decoded MCP JSON map.
  factory PaginatedRequestParams.toMCP(Map<String, Object?> map) {
    return PaginatedRequestParams(
      cursor: map['cursor'] as String?,
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
    );
  }
}

/// Base params shape for requests that may resume a paused multi-round-trip
/// operation by supplying [inputResponses] and/or [requestState].
///
/// [GetPromptRequestParams], [ReadResourceRequestParams], and
/// [CallToolRequestParams] all extend this.
class InputResponseRequestParams extends MCP {
  /// Request metadata (required — carries protocol version & capabilities).
  RequestMetaObject $meta;

  /// Responses to a prior [InputRequiredResult.inputRequests].
  InputResponses? inputResponses;

  /// Opaque state token echoed back from a prior [InputRequiredResult].
  String? requestState;

  /// Creates an [InputResponseRequestParams].
  InputResponseRequestParams({
    required this.$meta,
    this.inputResponses,
    this.requestState,
  });

  /// Converts this [InputResponseRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      '_meta': $meta.toMap(),
      if (inputResponses != null) 'inputResponses': inputResponses,
      if (requestState != null) 'requestState': requestState,
    };
  }

  /// Builds an [InputResponseRequestParams] from a decoded MCP JSON map.
  factory InputResponseRequestParams.toMCP(Map<String, Object?> map) {
    return InputResponseRequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
      inputResponses: map['inputResponses'],
      requestState: map['requestState'] as String?,
    );
  }
}

/// JSON-RPC internal error (code -32603).
class InternalError extends Error {
  /// Creates an [InternalError].
  InternalError({required super.message, super.data}) : super(code: -32603);
}

/// JSON-RPC invalid params error (code -32602).
class InvalidParamsError extends Error {
  /// Creates an [InvalidParamsError].
  InvalidParamsError({required super.message, super.data})
      : super(code: -32602);
}

/// JSON-RPC invalid request error (code -32600).
class InvalidRequestError extends Error {
  /// Creates an [InvalidRequestError].
  InvalidRequestError({required super.message, super.data})
      : super(code: -32600);
}

/// JSON-RPC method not found error (code -32601).
class MethodNotFoundError extends Error {
  /// Creates a [MethodNotFoundError].
  MethodNotFoundError({required super.message, super.data})
      : super(code: -32601);
}

/// JSON-RPC parse error (code -32700).
class ParseError extends Error {
  /// Creates a [ParseError].
  ParseError({required super.message, super.data}) : super(code: -32700);
}

/// Base class for all MCP content blocks (text, image, audio, resource, etc.).
class ContentBlock extends MCP {
  /// The content type discriminator (e.g. `"text"`, `"image"`, `"audio"`).
  String type;

  /// Base64-encoded binary data (used for image / audio content).
  String data;

  /// MIME type of [data].
  String mimeType;

  /// Optional client annotations.
  Annotations? annotations;

  /// Optional metadata.
  MetaObject? $meta;

  /// Creates a [ContentBlock].
  ContentBlock({
    required this.type,
    required this.data,
    required this.mimeType,
    this.annotations,
    this.$meta,
  });

  /// Converts this [ContentBlock] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'type': type,
      'data': data,
      'mimeType': mimeType,
      if (annotations != null) 'annotations': annotations!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [ContentBlock] from a decoded MCP JSON map.
  factory ContentBlock.toMCP(Map<String, Object?> map) {
    if (map['type'] == 'text') {
      return TextContent.toMCP(map);
    } else if (map['type'] == 'image') {
      return ImageContent.toMCP(map);
    } else if (map['type'] == 'audio') {
      return AudioContent.toMCP(map);
    } else if (map['type'] == 'resource') {
      return EmbeddedResource.toMCP(map);
    } else if (map['type'] == 'resource_link') {
      return ResourceLink.toMCP(map);
    }
    return ContentBlock(
      type: map['type'] as String,
      data: map['data'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Audio content block for LLM interactions.
///
/// [data] must be base64-encoded audio bytes.
class AudioContent extends ContentBlock
    // ignore: deprecated_member_use_from_same_package
    implements
        SamplingMessageContentBlock {
  /// Creates an [AudioContent].
  AudioContent({
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'audio');

  /// Converts this [AudioContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap()};
  }

  /// Builds an [AudioContent] from a decoded MCP JSON map.
  factory AudioContent.toMCP(Map<String, Object?> map) {
    return AudioContent(
      data: map['data'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Base interface for resource content (text or blob).
interface class ResourceContents extends MCP {
  /// The resource URI.
  String uri;

  /// Optional MIME type of the resource.
  String? mimeType;

  /// Optional metadata.
  MetaObject? $meta;

  ResourceContents({required this.uri, this.mimeType, this.$meta});

  /// Converts this [AudioContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'uri': uri,
      if (mimeType != null) 'mimeType': mimeType,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [ResourceContents] from a decoded MCP JSON map.
  factory ResourceContents.toMCP(Map<String, Object?> map) {
    if (map['text'] != null) {
      return TextResourceContents.toMCP(map);
    } else if (map['blob'] != null) {
      return BlobResourceContents.toMCP(map);
    }
    return ResourceContents(
      uri: map['uri'] as String,
      mimeType: map['mimeType'] as String?,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Binary resource content encoded as base64.
class BlobResourceContents extends ResourceContents {
  /// Base64-encoded binary content.
  String blob;

  /// Creates a [BlobResourceContents].
  BlobResourceContents({
    required this.blob,
    required super.uri,
    super.mimeType,
    super.$meta,
  });

  /// Converts this [BlobResourceContents] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'blob': blob};
  }

  /// Builds a [BlobResourceContents] from a decoded MCP JSON map.
  factory BlobResourceContents.toMCP(Map<String, Object?> map) {
    return BlobResourceContents(
      blob: map['blob'] as String,
      uri: map['uri'] as String,
      mimeType: map['mimeType'] as String?,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// An MCP resource embedded inside a prompt or tool-call result.
class EmbeddedResource extends ContentBlock {
  /// The embedded resource contents.
  ResourceContents resource;

  /// Creates an [EmbeddedResource].
  EmbeddedResource({
    required this.resource,
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'resource');

  /// Converts this [EmbeddedResource] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'resource': resource.toMap()};
  }

  /// Builds an [EmbeddedResource] from a decoded MCP JSON map.
  factory EmbeddedResource.toMCP(Map<String, Object?> map) {
    return EmbeddedResource(
      resource: ResourceContents.toMCP(map['resource'] as Map<String, Object?>),
      data: map['data'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Image content block for LLM interactions.
///
/// [data] must be base64-encoded image bytes.
class ImageContent extends ContentBlock
    // ignore: deprecated_member_use_from_same_package
    implements
        SamplingMessageContentBlock {
  /// Creates an [ImageContent].
  ImageContent({
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'image');

  /// Converts this [ImageContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap()};
  }

  /// Builds an [ImageContent] from a decoded MCP JSON map.
  factory ImageContent.toMCP(Map<String, Object?> map) {
    return ImageContent(
      data: map['data'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A resource link returned by a tool or included in a prompt.
///
/// Note: these links are not guaranteed to appear in `resources/list`.
class ResourceLink extends ContentBlock {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic name of the resource.
  String name;

  /// Human-readable display title.
  String? title;

  /// The resource URI.
  String uri;

  /// Human-readable description.
  String? description;

  /// Size of the raw resource in bytes, if known.
  int? size;

  /// Creates a [ResourceLink].
  ResourceLink({
    this.icons,
    required this.name,
    this.title,
    required this.uri,
    this.description,
    this.size,
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'resource_link');

  /// Converts this [ResourceLink] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (title != null) 'title': title,
      'uri': uri,
      if (description != null) 'description': description,
      if (size != null) 'size': size,
    };
  }

  /// Builds a [ResourceLink] from a decoded MCP JSON map.
  factory ResourceLink.toMCP(Map<String, Object?> map) {
    return ResourceLink(
      icons: map['icons'] != null
          ? (map['icons'] as List<dynamic>)
              .map((e) => Icon.toMCP(e as Map<String, Object?>))
              .toList()
          : null,
      name: map['name'] as String,
      title: map['title'] as String?,
      uri: map['uri'] as String,
      description: map['description'] as String?,
      size: map['size'] as int?,
      data: map['data'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Plain-text content for LLM interactions.
class TextContent extends ContentBlock
    // ignore: deprecated_member_use_from_same_package
    implements
        SamplingMessageContentBlock {
  /// The text payload.
  String text;

  /// Creates a [TextContent].
  TextContent({
    required this.text,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'text', data: '');

  /// Converts this [TextContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

  /// Builds a [TextContent] from a decoded MCP JSON map.
  factory TextContent.toMCP(Map<String, Object?> map) {
    return TextContent(
      text: map['text'] as String,
      mimeType: map['mimeType'] as String,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// UTF-8 text resource contents.
class TextResourceContents extends ResourceContents {
  /// The text payload.
  String text;

  /// Creates a [TextResourceContents].
  TextResourceContents({
    required this.text,
    required super.uri,
    super.mimeType,
    super.$meta,
  });

  /// Converts this [TextResourceContents] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

  /// Builds a [TextResourceContents] from a decoded MCP JSON map.
  factory TextResourceContents.toMCP(Map<String, Object?> map) {
    return TextResourceContents(
      text: map['text'] as String,
      uri: map['uri'] as String,
      mimeType: map['mimeType'] as String?,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// The MCP `CompleteRequestParamsArgument` schema type.
class CompleteRequestParamsArgument extends MCP {
  String name;
  String value;

  /// Creates a [CompleteRequestParamsArgument].
  CompleteRequestParamsArgument({required this.name, required this.value});

  /// Converts this [CompleteRequestParamsArgument] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'name': name, 'value': value};
  }

  /// Builds a [CompleteRequestParamsArgument] from a decoded MCP JSON map.
  factory CompleteRequestParamsArgument.toMCP(Map<String, Object?> map) {
    return CompleteRequestParamsArgument(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }
}

/// The MCP `CompleteRequestParamsContext` schema type.
class CompleteRequestParamsContext extends MCP {
  Map<String, String>? arguments;

  /// Creates a [CompleteRequestParamsContext].
  CompleteRequestParamsContext({this.arguments});

  /// Converts this [CompleteRequestParamsContext] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'arguments': arguments};
  }

  /// Builds a [CompleteRequestParamsContext] from a decoded MCP JSON map.
  factory CompleteRequestParamsContext.toMCP(Map<String, Object?> map) {
    return CompleteRequestParamsContext(
      arguments:
          (map['arguments'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

/// Parameters for a completion/complete request.
class CompleteRequestParams extends MCP {
  RequestMetaObject $meta;
  Reference ref;

  /// The argument's information
  CompleteRequestParamsArgument argument;

  /// Additional, optional context for completions
  CompleteRequestParamsContext? context;

  /// Creates a [CompleteRequestParams].
  CompleteRequestParams({
    required this.$meta,
    required this.ref,
    required this.argument,
    this.context,
  });

  /// Converts this [CompleteRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      '_meta': $meta.toMap(),
      'ref': ref.toMap(),
      'argument': argument.toMap(),
      if (context != null) 'context': context!.toMap(),
    };
  }

  /// Builds a [CompleteRequestParams] from a decoded MCP JSON map.
  factory CompleteRequestParams.toMCP(Map<String, Object?> map) {
    return CompleteRequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
      ref: Reference.toMCP(map['ref'] as Map<String, Object?>),
      argument: CompleteRequestParamsArgument.toMCP(
        map['argument'] as Map<String, Object?>,
      ),
      context: map['context'] != null
          ? CompleteRequestParamsContext.toMCP(
              map['context'] as Map<String, Object?>,
            )
          : null,
    );
  }
}

/// Discriminated union of completion reference targets: either a
/// [PromptReference] (`type: "ref/prompt"`) or a [ResourceTemplateReference]
/// (`type: "ref/resource"`).
abstract class Reference extends MCP {
  /// Creates a [Reference].
  Reference();

  /// Builds a [Reference] from a decoded MCP JSON map.
  factory Reference.toMCP(Map<String, Object?> map) {
    if (map['type'] == 'ref/resource') {
      return ResourceTemplateReference.toMCP(map);
    }
    return PromptReference.toMCP(map);
  }
}

/// Identifies a prompt.
class PromptReference extends Reference {
  /// Intended for programmatic or logical use, but used as a display name in past specs or fallback (if title isn't present).
  String name;

  /// Intended for UI and end-user contexts — optimized to be human-readable and easily understood, even by those unfamiliar with domain-specific terminology.
  String? title;
  String type = 'ref/prompt';

  /// Creates a [PromptReference].
  PromptReference({required this.name, this.title});

  /// Converts this [PromptReference] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'name': name, if (title != null) 'title': title, 'type': type};
  }

  /// Builds a [PromptReference] from a decoded MCP JSON map.
  factory PromptReference.toMCP(Map<String, Object?> map) {
    return PromptReference(
      name: map['name'] as String,
      title: map['title'] as String?,
    );
  }
}

/// A reference to a resource or resource template definition.
class ResourceTemplateReference extends Reference {
  /// Discriminator. Note this is `"ref/resource"`, shared with plain
  /// resource references — not `"ref/resource_template"`.
  String type = 'ref/resource';

  /// The URI or URI template of the resource.
  String uri;

  /// Creates a [ResourceTemplateReference].
  ResourceTemplateReference({required this.uri});

  /// Converts this [ResourceTemplateReference] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'type': type, 'uri': uri};
  }

  /// Builds a [ResourceTemplateReference] from a decoded MCP JSON map.
  factory ResourceTemplateReference.toMCP(Map<String, Object?> map) {
    return ResourceTemplateReference(uri: map['uri'] as String);
  }
}

/// A request from the client to the server, to ask for completion options.
class CompleteRequest extends MCP {
  String id;
  CompleteRequestParams params;
  String jsonrpc = '2.0';
  String method = 'completion/complete';

  /// Creates a [CompleteRequest].
  CompleteRequest({required this.id, required this.params});

  /// Converts this [CompleteRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

  /// Builds a [CompleteRequest] from a decoded MCP JSON map.
  factory CompleteRequest.toMCP(Map<String, Object?> map) {
    return CompleteRequest(
      id: map['id']?.toString() ?? '-1',
      params: CompleteRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// A successful response from the server for a completion/complete request.
class CompleteResultResponse extends MCP {
  String jsonrpc = '2.0';
  String id;
  CompleteResult result;

  /// Creates a [CompleteResultResponse].
  CompleteResultResponse({required this.id, required this.result});

  /// Converts this [CompleteResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [CompleteResultResponse] from a decoded MCP JSON map.
  factory CompleteResultResponse.toMCP(Map<String, Object?> map) {
    return CompleteResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CompleteResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a completion/complete request.
class CompleteResult extends MapMC<String, Object?> {
  ResultMetaObject? $meta;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String resultType;

  /// An array of completion values.
  CompleteResultCompletion completion;

  /// Creates a [CompleteResult].
  CompleteResult({
    this.$meta,
    this.resultType = 'complete',
    required this.completion,
    Map<String, Object?>? additionalData,
  }) : super(additionalData ?? {});

  /// Converts this [CompleteResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.data,
      if ($meta != null) '_meta': $meta!.toMap(),
      'resultType': resultType,
      'completion': completion.toMap(),
    };
  }

  /// Builds a [CompleteResult] from a decoded MCP JSON map.
  factory CompleteResult.toMCP(Map<String, Object?> map) {
    return CompleteResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      completion: CompleteResultCompletion.toMCP(
        map['completion'] as Map<String, Object?>,
      ),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' || key == 'resultType' || key == 'completion',
        ),
    );
  }
}

/// The MCP `CompleteResultCompletion` schema type.
class CompleteResultCompletion extends MCP {
  /// Completion values. Must not exceed 100 items.
  List<String> values;
  int? total;
  bool? hasMore;

  /// Creates a [CompleteResultCompletion].
  CompleteResultCompletion({required this.values, this.total, this.hasMore});

  /// Converts this [CompleteResultCompletion] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'values': values,
      if (total != null) 'total': total,
      if (hasMore != null) 'hasMore': hasMore,
    };
  }

  /// Builds a [CompleteResultCompletion] from a decoded MCP JSON map.
  factory CompleteResultCompletion.toMCP(Map<String, Object?> map) {
    return CompleteResultCompletion(
      values: (map['values'] as List<dynamic>).cast<String>(),
      total: map['total'] as int?,
      hasMore: map['hasMore'] as bool?,
    );
  }
}

/// A request from the server to elicit additional information from the user via the client.
class ElicitRequest extends MCP {
  String id;
  ElicitRequestParams params;
  String jsonrpc = '2.0';
  String method = 'elicitation/create';

  /// Creates an [ElicitRequest].
  ElicitRequest({required this.id, required this.params});

  /// Converts this [ElicitRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

  /// Builds an [ElicitRequest] from a decoded MCP JSON map.
  factory ElicitRequest.toMCP(Map<String, Object?> map) {
    return ElicitRequest(
      id: map['id']?.toString() ?? '-1',
      params: ElicitRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// Discriminated union of the two [ElicitRequest] param shapes, dispatched
/// on [ElicitRequestFormParams.mode] / [ElicitRequestURLParams.mode]:
/// a form-based elicitation, or a URL-based one.
abstract class ElicitRequestParams extends MCP {
  /// Creates an [ElicitRequestParams].
  ElicitRequestParams();

  /// Builds an [ElicitRequestParams] from a decoded MCP JSON map.
  factory ElicitRequestParams.toMCP(Map<String, Object?> map) {
    if (map['mode'] == 'url') {
      return ElicitRequestURLParams.toMCP(map);
    }
    return ElicitRequestFormParams.toMCP(map);
  }
}

/// The result returned by the client for an elicitation/create request.
class ElicitResult extends MapMC<String, Object?> {
  MetaObject? $meta;

  /// The user action in response to the elicitation.
  ActionType action;

  /// The submitted form data, only present when action is "accept" and mode was "form".
  Map<String, Object?> content;

  /// Creates an [ElicitResult].
  ElicitResult({this.$meta, required this.action, required this.content})
      : super({});

  /// Converts this [ElicitResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...data,
      'action': action.toString(),
      '_meta': $meta?.toMap(),
      'content': content,
    };
  }

  /// Builds an [ElicitResult] from a decoded MCP JSON map.
  factory ElicitResult.toMCP(Map<String, Object?> map) {
    return ElicitResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      action: ActionType.to(map['action'] as String),
      content: map['content'] as Map<String, Object?>,
    )..data.addAll(
        map
          ..removeWhere(
            (key, value) =>
                key == 'action' || key == '_meta' || key == 'content',
          ),
      );
  }
}

/// The MCP `Schema` schema type.
class Schema<T> extends MCP {
  String type;
  String? title;
  String? description;
  T? defaultValue;

  /// Creates a [Schema].
  Schema({required this.type, this.title, this.description, this.defaultValue});

  /// Converts this [Schema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'type': type,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
  }

  /// Builds a [Schema] from a decoded MCP JSON map.
  factory Schema.toMCP(Map<String, Object?> map) {
    return Schema(
      type: map['type'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      defaultValue: map['default'] as T?,
    );
  }
}

/// The MCP `BooleanSchema` schema type.
class BooleanSchema extends PrimitiveSchemaDefinition<bool> {
  @override
  String get type => 'boolean';

  /// Creates a [BooleanSchema].
  BooleanSchema({super.title, super.description, super.defaultValue})
      : super(type: 'boolean');

  /// Builds a [BooleanSchema] from a decoded MCP JSON map.
  factory BooleanSchema.toMCP(Map<String, Object?> map) {
    return BooleanSchema(
      title: map['title'] as String?,
      description: map['description'] as String?,
      defaultValue: map['default'] as bool?,
    );
  }
}

/// The parameters for a request to elicit information from the user via a URL in the client.
class ElicitRequestURLParams extends ElicitRequestParams {
  /// Discriminator — always `"url"`.
  String mode = "url";

  /// The message to present to the user explaining why the interaction is needed.
  String message;

  /// The URL that the user should navigate to.
  String url;

  /// Creates an [ElicitRequestURLParams].
  ElicitRequestURLParams({required this.message, required this.url});

  /// Converts this [ElicitRequestURLParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'mode': mode,
      'message': message,
      'url': url,
    };
  }

  /// Builds an [ElicitRequestURLParams] from a decoded MCP JSON map.
  factory ElicitRequestURLParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestURLParams(
      message: map['message'] as String,
      url: map['url'] as String,
    );
  }
}

/// The MCP `EnumSchema` schema type.
abstract class EnumSchema<T> extends PrimitiveSchemaDefinition<T> {
  /// Creates an [EnumSchema].
  EnumSchema({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

/// The MCP `SingleSelectEnumSchema` schema type.
abstract class SingleSelectEnumSchema<T> extends EnumSchema<T> {
  /// Creates a [SingleSelectEnumSchema].
  SingleSelectEnumSchema({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

/// Schema for single-selection enumeration without display titles for options.
class UntitledSingleSelectEnumSchema extends SingleSelectEnumSchema<String> {
  /// Array of enum values to choose from.
  List<String> $enum;

  /// Creates an [UntitledSingleSelectEnumSchema].
  UntitledSingleSelectEnumSchema({
    required this.$enum,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  /// Converts this [UntitledSingleSelectEnumSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'enum': $enum};
  }

  /// Builds an [UntitledSingleSelectEnumSchema] from a decoded MCP JSON map.
  factory UntitledSingleSelectEnumSchema.toMCP(Map<String, Object?> map) {
    return UntitledSingleSelectEnumSchema(
      $enum: (map['enum'] as List<dynamic>).cast<String>(),
      defaultValue: map['default'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

/// Schema for single-selection enumeration with display titles for each option.
class TitledSingleSelectEnumSchema extends SingleSelectEnumSchema<String> {
  List<({String $const, String title})> oneOf;

  /// Creates a [TitledSingleSelectEnumSchema].
  TitledSingleSelectEnumSchema({
    required this.oneOf,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  /// Converts this [TitledSingleSelectEnumSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'oneOf': oneOf.map((e) => {'const': e.$const, 'title': e.title}).toList(),
    };
  }

  /// Builds a [TitledSingleSelectEnumSchema] from a decoded MCP JSON map.
  factory TitledSingleSelectEnumSchema.toMCP(Map<String, Object?> map) {
    return TitledSingleSelectEnumSchema(
      oneOf: (map['oneOf'] as List<dynamic>)
          .map(
            (e) => ($const: e['const'] as String, title: e['title'] as String),
          )
          .toList(),
      defaultValue: map['default'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

/// The MCP `MultiSelectEnumSchema` schema type.
abstract class MultiSelectEnumSchema<T> extends EnumSchema<List<T>> {
  /// Creates a [MultiSelectEnumSchema].
  MultiSelectEnumSchema({super.title, super.description, super.defaultValue})
      : super(type: 'array');
}

/// Schema for multiple-selection enumeration without display titles for options.
class UntitledMultiSelectEnumSchema extends MultiSelectEnumSchema<String> {
  /// Minimum number of items to select.
  int? minItems;

  /// Maximum number of items to select.
  int? maxItems;

  /// Schema for the array items.
  List<String> items;

  /// Creates an [UntitledMultiSelectEnumSchema].
  UntitledMultiSelectEnumSchema({
    required this.items,
    this.minItems,
    this.maxItems,
    super.defaultValue,
    super.title,
    super.description,
  });

  /// Converts this [UntitledMultiSelectEnumSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      'items': {'type': 'string', 'enum': items},
    };
  }

  /// Builds an [UntitledMultiSelectEnumSchema] from a decoded MCP JSON map.
  factory UntitledMultiSelectEnumSchema.toMCP(Map<String, Object?> map) {
    final itemsMap = map['items'] as Map<String, Object?>;
    return UntitledMultiSelectEnumSchema(
      items: (itemsMap['enum'] as List<dynamic>).cast<String>(),
      minItems: map['minItems'] as int?,
      maxItems: map['maxItems'] as int?,
      defaultValue: map['default'] != null
          ? (map['default'] as List<dynamic>).cast<String>()
          : null,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

/// Schema for multiple-selection enumeration with display titles for each option.
class TitledMultiSelectEnumSchema extends UntitledMultiSelectEnumSchema {
  /// Creates a [TitledMultiSelectEnumSchema].
  TitledMultiSelectEnumSchema({
    required super.items,
    super.minItems,
    super.maxItems,
    super.defaultValue,
    super.title,
    super.description,
  });

  /// Converts this [TitledMultiSelectEnumSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      'items': {'type': 'string', 'anyOf': items},
    };
  }

  /// Builds a [TitledMultiSelectEnumSchema] from a decoded MCP JSON map.
  factory TitledMultiSelectEnumSchema.toMCP(Map<String, Object?> map) {
    final itemsMap = map['items'] as Map<String, Object?>;
    return TitledMultiSelectEnumSchema(
      items: (itemsMap['anyOf'] as List<dynamic>).cast<String>(),
      minItems: map['minItems'] as int?,
      maxItems: map['maxItems'] as int?,
      defaultValue: map['default'] != null
          ? (map['default'] as List<dynamic>).cast<String>()
          : null,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

@Deprecated('Use TitledSingleSelectEnumSchema instead.')

/// Use TitledSingleSelectEnumSchema instead.
class LegacyTitledEnumSchema extends EnumSchema<String> {
  List<String> $enum;

  /// (Legacy) Display names for enum values.
  List<String>? enumNames;

  /// Creates a [LegacyTitledEnumSchema].
  LegacyTitledEnumSchema({
    required this.$enum,
    this.enumNames,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  /// Converts this [LegacyTitledEnumSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'enum': $enum, 'enumNames': enumNames};
  }

  /// Builds a [LegacyTitledEnumSchema] from a decoded MCP JSON map.
  factory LegacyTitledEnumSchema.toMCP(Map<String, Object?> map) {
    return LegacyTitledEnumSchema(
      $enum: (map['enum'] as List<dynamic>).cast<String>(),
      defaultValue: map['default'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      enumNames: (map['enumNames'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// The parameters for a request to elicit non-sensitive information from the user via a form in the client.
class ElicitRequestFormParams extends ElicitRequestParams {
  /// Discriminator — always `"form"` (the default).
  String mode = "form";

  /// The message to present to the user describing what information is being requested.
  String message;

  /// A restricted subset of JSON Schema.
  ElicitRequestFormParamsSchema? requestedSchema;

  /// Creates an [ElicitRequestFormParams].
  ElicitRequestFormParams({
    required this.message,
    this.requestedSchema,
  });

  /// Converts this [ElicitRequestFormParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'mode': mode,
      'message': message,
      if (requestedSchema != null) 'requestedSchema': requestedSchema!.toMap(),
    };
  }

  /// Builds an [ElicitRequestFormParams] from a decoded MCP JSON map.
  factory ElicitRequestFormParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestFormParams(
      message: map['message'] as String,
      requestedSchema: map['requestedSchema'] != null
          ? ElicitRequestFormParamsSchema.toMCP(
              map['requestedSchema'] as Map<String, Object?>,
            )
          : null,
    );
  }
}

/// The MCP `ElicitRequestFormParamsSchema` schema type.
class ElicitRequestFormParamsSchema extends MCP {
  String? $schema;
  String type = 'object';
  Map<String, PrimitiveSchemaDefinition> properties = {};
  List<String>? required;

  /// Creates an [ElicitRequestFormParamsSchema].
  ElicitRequestFormParamsSchema({
    this.$schema,
    this.required,
    this.type = 'object',
    required this.properties,
  });

  /// Converts this [ElicitRequestFormParamsSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($schema != null) r'$schema': $schema,
      'type': type,
      if (properties.isNotEmpty)
        'properties': properties.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      if (required != null) 'required': required,
    };
  }

  /// Builds an [ElicitRequestFormParamsSchema] from a decoded MCP JSON map.
  factory ElicitRequestFormParamsSchema.toMCP(Map<String, Object?> map) {
    final propertiesMap = map['properties'] as Map<String, Object?>?;
    return ElicitRequestFormParamsSchema(
      $schema: map[r'$schema'] as String?,
      type: map['type'] as String? ?? 'object',
      properties: propertiesMap != null
          ? propertiesMap.map(
              (key, value) => MapEntry(
                key,
                StringSchema.toMCP(value as Map<String, Object?>),
              ),
            )
          : {},
      required: (map['required'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Restricted schema definitions that only allow primitive types without nested objects or arrays.
abstract class PrimitiveSchemaDefinition<T> extends Schema<T> {
  /// Creates a [PrimitiveSchemaDefinition].
  PrimitiveSchemaDefinition({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

/// The MCP `StringSchema` schema type.
class StringSchema extends PrimitiveSchemaDefinition<String> {
  int? minLength;
  int? maxLength;
  StringFormat? format;

  /// Creates a [StringSchema].
  StringSchema({
    this.minLength,
    this.maxLength,
    this.format,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  /// Converts this [StringSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (format != null) 'format': format!.value,
    };
  }

  /// Builds a [StringSchema] from a decoded MCP JSON map.
  factory StringSchema.toMCP(Map<String, Object?> map) {
    return StringSchema(
      minLength: map['minLength'] as int?,
      maxLength: map['maxLength'] as int?,
      format: map['format'] != null
          ? StringFormat.to(map['format'] as String)
          : null,
      defaultValue: map['default'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

/// The MCP `NumberSchema` schema type.
class NumberSchema extends PrimitiveSchemaDefinition<num> {
  num? minimum;
  num? maximum;

  /// Creates a [NumberSchema].
  NumberSchema({
    super.type = 'number',
    this.minimum,
    this.maximum,
    super.defaultValue,
    super.title,
    super.description,
  });

  /// Converts this [NumberSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
    };
  }

  /// Builds a [NumberSchema] from a decoded MCP JSON map.
  factory NumberSchema.toMCP(Map<String, Object?> map) {
    return NumberSchema(
      minimum: map['minimum'] as num?,
      maximum: map['maximum'] as num?,
      defaultValue: map['default'] as num?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'number',
    );
  }
}

/// Capabilities declared by the MCP client.
///
/// Known keys: `experimental`, `elicitation` (`{form?, url?}`),
/// `extensions`.
///
/// `roots` and `sampling` remain valid keys but are deprecated as of
/// protocol version 2026-07-28 (SEP-2577); they remain in the specification
/// for at least twelve months. See the deprecated features registry.
class ClientCapabilities extends MapMC<String, Object?> {
  /// Creates a [ClientCapabilities].
  ClientCapabilities(super.data);

  /// Converts this [ClientCapabilities] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ClientCapabilities] from a decoded MCP JSON map.
  factory ClientCapabilities.toMCP(Map<String, Object?> map) {
    return ClientCapabilities(map);
  }
}

/// Describes an MCP client or server implementation.
class Implementation extends MCP {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic name.
  String name;

  /// Optional human-readable description.
  String? description;

  /// Optional human-readable display title.
  String? title;

  /// Implementation version string.
  String version;

  /// Optional website URL.
  String? websiteUrl;

  /// Creates an [Implementation].
  Implementation({
    this.icons,
    required this.name,
    this.description,
    this.title,
    required this.version,
    this.websiteUrl,
  });

  /// Converts this [Implementation] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (description != null) 'description': description,
      if (title != null) 'title': title,
      'version': version,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
    };
  }

  /// Builds an [Implementation] from a decoded MCP JSON map.
  factory Implementation.toMCP(Map<String, Object?> map) {
    return Implementation(
      icons: map['icons'] != null
          ? (map['icons'] as List<dynamic>)
              .map((e) => Icon.toMCP(e as Map<String, Object?>))
              .toList()
          : null,
      name: map['name'] as String,
      description: map['description'] as String?,
      title: map['title'] as String?,
      version: map['version'] as String,
      websiteUrl: map['websiteUrl'] as String?,
    );
  }
}

/// Capabilities declared by the MCP server.
///
/// Known keys: `experimental`, `completions`, `prompts` (`{listChanged?}`),
/// `resources` (`{subscribe?, listChanged?}`), `tools` (`{listChanged?}`),
/// `extensions`.
///
/// `logging` remains a valid key but is deprecated as of protocol version
/// 2026-07-28 (SEP-2577); it remains in the specification for at least
/// twelve months. See the deprecated features registry.
class ServerCapabilities extends MapMC<String, Object?> {
  /// Creates a [ServerCapabilities].
  ServerCapabilities(super.data);

  /// Converts this [ServerCapabilities] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ServerCapabilities] from a decoded MCP JSON map.
  factory ServerCapabilities.toMCP(Map<String, Object?> map) {
    return ServerCapabilities(map);
  }
}

/// Sent by the client to indicate it is cancelling a previously-issued
/// request.
///
/// On stdio, the server also sends this notification, solely to terminate a
/// [SubscriptionsListenRequest] stream: it references the ID of the
/// `subscriptions/listen` request that opened the stream. Servers MUST NOT
/// use this notification to cancel any other request.
class CancelledNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/cancelled";
  CancelledNotificationParams params;

  /// Creates a [CancelledNotification].
  CancelledNotification({required this.params});

  /// Converts this [CancelledNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds a [CancelledNotification] from a decoded MCP JSON map.
  factory CancelledNotification.toMCP(Map<String, Object?> map) {
    return CancelledNotification(
      params: CancelledNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for a notifications/cancelled notification.
class CancelledNotificationParams extends MCP {
  NotificationMetaObject? $meta;

  /// The ID of the request to cancel.
  String requestId;

  /// An optional string describing the reason for the cancellation.
  String? reason;

  /// Creates a [CancelledNotificationParams].
  CancelledNotificationParams({
    this.$meta,
    required this.requestId,
    this.reason,
  });

  /// Converts this [CancelledNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'requestId': requestId,
      if (reason != null) 'reason': reason,
    };
  }

  /// Builds a [CancelledNotificationParams] from a decoded MCP JSON map.
  factory CancelledNotificationParams.toMCP(Map<String, Object?> map) {
    return CancelledNotificationParams(
      $meta: map['_meta'] != null
          ? NotificationMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      requestId: map['requestId'] as String,
      reason: map['reason'] as String?,
    );
  }
}

/// Parameters for a `notifications/message` notification.
@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Parameters for a notifications/message notification.
class LoggingMessageNotificationParams extends MCP {
  /// Optional metadata.
  MetaObject? $meta;

  /// Severity level.
  LoggingLevel level;

  /// Optional name of the issuing logger.
  String? logger;

  /// Arbitrary log data (string or JSON-serialisable object).
  dynamic data;

  /// Creates a [LoggingMessageNotificationParams].
  LoggingMessageNotificationParams({
    this.$meta,
    required this.level,
    this.logger,
    required this.data,
  });

  /// Converts this [LoggingMessageNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'level': level.toString(),
      if (logger != null) 'logger': logger,
      'data': data,
    };
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [LoggingMessageNotificationParams] from a decoded MCP JSON map.
  factory LoggingMessageNotificationParams.toMCP(Map<String, Object?> map) {
    return LoggingMessageNotificationParams(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      level: LoggingLevel.to(map['level'] as String),
      logger: map['logger'] as String?,
      data: map['data'],
    );
  }
}

/// A `notifications/message` (`logging/message`) notification.
@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// JSONRPCNotification of a log message passed from server to client.
class LoggingMessageNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/message";

  // ignore: deprecated_member_use_from_same_package
  LoggingMessageNotificationParams params;

  /// Creates a [LoggingMessageNotification].
  LoggingMessageNotification({required this.params});

  /// Converts this [LoggingMessageNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [LoggingMessageNotification] from a decoded MCP JSON map.
  factory LoggingMessageNotification.toMCP(Map<String, Object?> map) {
    return LoggingMessageNotification(
      params: LoggingMessageNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// An out-of-band notification used to inform the receiver of a progress update for a long-running request.
class ProgressNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/progress";
  ProgressNotificationParams params;

  /// Creates a [ProgressNotification].
  ProgressNotification({required this.params});

  /// Converts this [ProgressNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds a [ProgressNotification] from a decoded MCP JSON map.
  factory ProgressNotification.toMCP(Map<String, Object?> map) {
    return ProgressNotification(
      params: ProgressNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for a notifications/progress notification.
class ProgressNotificationParams extends MCP {
  NotificationMetaObject? $meta;

  /// The progress token which was given in the initial request, used to associate this notification with the request that is proceeding.
  String progressToken;

  /// The progress thus far.
  num progress;

  /// Total number of items to process (or total progress required), if known.
  num? total;

  /// An optional message describing the current progress.
  String? message;

  /// Creates a [ProgressNotificationParams].
  ProgressNotificationParams({
    this.$meta,
    required this.progressToken,
    required this.progress,
    this.total,
    this.message,
  });

  /// Converts this [ProgressNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'progressToken': progressToken,
      'progress': progress,
      if (total != null) 'total': total,
      if (message != null) 'message': message,
    };
  }

  /// Builds a [ProgressNotificationParams] from a decoded MCP JSON map.
  factory ProgressNotificationParams.toMCP(Map<String, Object?> map) {
    return ProgressNotificationParams(
      $meta: map['_meta'] != null
          ? NotificationMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      progressToken: map['progressToken'] as String,
      progress: map['progress'] as num,
      total: map['total'] as num?,
      message: map['message'] as String?,
    );
  }
}

/// An optional notification from the server to the client, informing it that the list of resources it can read from has changed.
class ResourceListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/resources/list_changed";
  NotificationParams? params;

  /// Creates a [ResourceListChangedNotification].
  ResourceListChangedNotification({this.params});

  /// Converts this [ResourceListChangedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ResourceListChangedNotification] from a decoded MCP JSON map.
  factory ResourceListChangedNotification.toMCP(Map<String, Object?> map) {
    return ResourceListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A notification from the server to the client, informing it that a resource has changed and may need to be read again.
class ResourceUpdatedNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/resources/updated”;
  ///params: ResourceUpdatedNotificationParams;

  String jsonrpc = "2.0";
  String method = "notifications/resources/updated";
  ResourceUpdatedNotificationParams params;

  /// Creates a [ResourceUpdatedNotification].
  ResourceUpdatedNotification({required this.params});

  /// Converts this [ResourceUpdatedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds a [ResourceUpdatedNotification] from a decoded MCP JSON map.
  factory ResourceUpdatedNotification.toMCP(Map<String, Object?> map) {
    return ResourceUpdatedNotification(
      params: ResourceUpdatedNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for a notifications/resources/updated notification.
class ResourceUpdatedNotificationParams extends MCP {
  NotificationMetaObject? $meta;

  /// The URI of the resource that has been updated.
  String uri;

  /// Creates a [ResourceUpdatedNotificationParams].
  ResourceUpdatedNotificationParams({this.$meta, required this.uri});

  /// Converts this [ResourceUpdatedNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'uri': uri,
    };
  }

  /// Builds a [ResourceUpdatedNotificationParams] from a decoded MCP JSON map.
  factory ResourceUpdatedNotificationParams.toMCP(Map<String, Object?> map) {
    return ResourceUpdatedNotificationParams(
      $meta: map['_meta'] != null
          ? NotificationMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      uri: map['uri'] as String,
    );
  }
}

/// A JSON-RPC notification for the `rootsListChanged` event.
class RootsListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/roots/list_changed";
  NotificationParams? params;

  /// Creates a [RootsListChangedNotification].
  RootsListChangedNotification({this.params});

  /// Converts this [RootsListChangedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [RootsListChangedNotification] from a decoded MCP JSON map.
  factory RootsListChangedNotification.toMCP(Map<String, Object?> map) {
    return RootsListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// An optional notification from the server to the client, informing it that the list of tools it offers has changed.
class ToolListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/tools/list_changed";
  NotificationParams? params;

  /// Creates a [ToolListChangedNotification].
  ToolListChangedNotification({this.params});

  /// Converts this [ToolListChangedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ToolListChangedNotification] from a decoded MCP JSON map.
  factory ToolListChangedNotification.toMCP(Map<String, Object?> map) {
    return ToolListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Common params for any request.
///
/// Every request declares its own protocol negotiation state via [$meta]
/// rather than relying on a one-time `initialize` handshake.
class RequestParams extends MCP {
  RequestMetaObject $meta;

  /// Creates a [RequestParams].
  RequestParams({required this.$meta});

  /// Converts this [RequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'_meta': $meta.toMap()};
  }

  /// Builds a [RequestParams] from a decoded MCP JSON map.
  factory RequestParams.toMCP(Map<String, Object?> map) {
    return RequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
    );
  }
}

/// An optional notification from the server to the client, informing it that the list of prompts it offers has changed.
class PromptListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/prompts/list_changed";
  NotificationParams? params;

  /// Creates a [PromptListChangedNotification].
  PromptListChangedNotification({this.params});

  /// Converts this [PromptListChangedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [PromptListChangedNotification] from a decoded MCP JSON map.
  factory PromptListChangedNotification.toMCP(Map<String, Object?> map) {
    return PromptListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Used by the client to get a prompt provided by the server.
class GetPromptRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "prompts/get";
  GetPromptRequestParams params;

  /// Creates a [GetPromptRequest].
  GetPromptRequest({required this.id, required this.params});

  /// Converts this [GetPromptRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [GetPromptRequest] from a decoded MCP JSON map.
  factory GetPromptRequest.toMCP(Map<String, Object?> map) {
    return GetPromptRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetPromptRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for a prompts/get request.
class GetPromptRequestParams extends InputResponseRequestParams {
  /// The name of the prompt or prompt template.
  String name;

  /// Arguments to use for templating the prompt.
  Map<String, String>? arguments;

  /// Creates a [GetPromptRequestParams].
  GetPromptRequestParams({
    required super.$meta,
    super.inputResponses,
    super.requestState,
    required this.name,
    this.arguments,
  });

  /// Converts this [GetPromptRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'name': name,
      if (arguments != null) 'arguments': arguments,
    };
  }

  /// Builds a [GetPromptRequestParams] from a decoded MCP JSON map.
  factory GetPromptRequestParams.toMCP(Map<String, Object?> map) {
    return GetPromptRequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
      inputResponses: map['inputResponses'],
      requestState: map['requestState'] as String?,
      name: map['name'] as String,
      arguments: (map['arguments'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
  }
}

/// A successful response from the server for a prompts/get request.
class GetPromptResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  GetPromptResultOutcome result;

  /// Creates a [GetPromptResultResponse].
  GetPromptResultResponse({required this.id, required this.result});

  /// Converts this [GetPromptResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [GetPromptResultResponse] from a decoded MCP JSON map.
  factory GetPromptResultResponse.toMCP(Map<String, Object?> map) {
    return GetPromptResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: GetPromptResultOutcome.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

/// The result returned by the server for a prompts/get request.
class GetPromptResult extends MapMC<String, Object?>
    implements GetPromptResultOutcome {
  ResultMetaObject? $meta;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String resultType;

  /// An optional description for the prompt.
  String? description;
  List<PromptMessage> messages;

  /// Creates a [GetPromptResult].
  GetPromptResult({
    this.$meta,
    this.resultType = 'complete',
    this.description,
    required this.messages,
    Map<String, Object?>? additionalData,
  }) : super(additionalData ?? {});

  /// Converts this [GetPromptResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.data,
      if ($meta != null) '_meta': $meta!.toMap(),
      'resultType': resultType,
      if (description != null) 'description': description,
      'messages': messages.map((e) => e.toMap()).toList(),
    };
  }

  /// Builds a [GetPromptResult] from a decoded MCP JSON map.
  factory GetPromptResult.toMCP(Map<String, Object?> map) {
    return GetPromptResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      description: map['description']?.toString(),
      messages: (map['messages'] as List<Map<String, Object?>>)
          .map((e) => PromptMessage.toMCP(e))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'description' ||
              key == 'messages',
        ),
    );
  }
}

/// Describes a message returned as part of a prompt.
class PromptMessage extends MCP {
  Role role;
  ContentBlock content;

  /// Creates a [PromptMessage].
  PromptMessage({required this.role, required this.content});

  /// Converts this [PromptMessage] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'role': role.toString(), 'content': content.toMap()};
  }

  /// Builds a [PromptMessage] from a decoded MCP JSON map.
  factory PromptMessage.toMCP(Map<String, Object?> map) {
    return PromptMessage(
      role: Role.to(map['role'] as String),
      content: ContentBlock.toMCP(map['content'] as Map<String, Object?>),
    );
  }
}

/// Sent from the client to request a list of prompts and prompt templates the server has.
class ListPromptsRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "prompts/list";
  PaginatedRequestParams? params;

  /// Creates a [ListPromptsRequest].
  ListPromptsRequest({required this.id, this.params});

  /// Converts this [ListPromptsRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ListPromptsRequest] from a decoded MCP JSON map.
  factory ListPromptsRequest.toMCP(Map<String, Object?> map) {
    return ListPromptsRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A successful response from the server for a prompts/list request.
class ListPromptsResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListPromptsResult result;

  /// Creates a [ListPromptsResultResponse].
  ListPromptsResultResponse({required this.id, required this.result});

  /// Converts this [ListPromptsResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ListPromptsResultResponse] from a decoded MCP JSON map.
  factory ListPromptsResultResponse.toMCP(Map<String, Object?> map) {
    return ListPromptsResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListPromptsResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a prompts/list request.
class ListPromptsResult extends MapMC<String, Object?> {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Prompt> get prompts => (data['prompts'] as List<dynamic>)
      .map((e) => Prompt.toMCP(e as Map<String, Object?>))
      .toList();

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set nextCursor(String? value) => data['nextCursor'] = value;
  set prompts(List<Prompt> value) =>
      data['prompts'] = value.map((e) => e.toMap()).toList();
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [ListPromptsResult].
  ListPromptsResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    String? nextCursor,
    required List<Prompt> prompts,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          if (nextCursor != null) 'nextCursor': nextCursor,
          'prompts': prompts.map((e) => e.toMap()).toList(),
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [ListPromptsResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ListPromptsResult] from a decoded MCP JSON map.
  factory ListPromptsResult.toMCP(Map<String, Object?> map) {
    return ListPromptsResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      nextCursor: map['nextCursor'] as String?,
      prompts: (map['prompts'] as List<dynamic>)
          .map((e) => Prompt.toMCP(e as Map<String, Object?>))
          .toList(),
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) => key == '_meta' || key == 'nextCursor' || key == 'prompts',
        ),
    );
  }
}

/// A prompt or prompt template offered by the server.
class Prompt extends MCP {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic name.
  String name;

  /// Human-readable display title.
  String? title;

  /// Optional description.
  String? description;

  /// Accepted template arguments.
  List<PromptArgument>? arguments;

  /// Optional metadata.
  MetaObject? $meta;

  /// Creates a [Prompt].
  Prompt({
    this.icons,
    required this.name,
    this.title,
    this.description,
    this.arguments,
    this.$meta,
  });

  /// Converts this [Prompt] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (arguments != null)
        'arguments': arguments!.map((e) => e.toMap()).toList(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [Prompt] from a decoded MCP JSON map.
  factory Prompt.toMCP(Map<String, Object?> map) {
    return Prompt(
      icons: (map['icons'] as List<dynamic>?)
          ?.map((e) => Icon.toMCP(e as Map<String, Object?>))
          .toList(),
      name: map['name'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      arguments: (map['arguments'] as List<dynamic>?)
          ?.map((e) => PromptArgument.toMCP(e as Map<String, Object?>))
          .toList(),
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Describes an argument accepted by a [Prompt].
class PromptArgument extends MCP {
  /// Programmatic argument name.
  String name;

  /// Human-readable display title.
  String? title;

  /// Optional description of the argument.
  String? description;

  /// Whether the argument must be provided.
  bool? required;

  /// Creates a [PromptArgument].
  PromptArgument({
    required this.name,
    this.title,
    this.description,
    this.required,
  });

  /// Converts this [PromptArgument] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'name': name,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (required != null) 'required': required,
    };
  }

  /// Builds a [PromptArgument] from a decoded MCP JSON map.
  factory PromptArgument.toMCP(Map<String, Object?> map) {
    return PromptArgument(
      name: map['name'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      required: map['required'] as bool?,
    );
  }
}

/// Sent from the client to request a list of resources the server has.
class ListResourcesRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/list";
  PaginatedRequestParams? params;

  /// Creates a [ListResourcesRequest].
  ListResourcesRequest({required this.id, this.params});

  /// Converts this [ListResourcesRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ListResourcesRequest] from a decoded MCP JSON map.
  factory ListResourcesRequest.toMCP(Map<String, Object?> map) {
    return ListResourcesRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A successful response from the server for a resources/list request.
class ListResourcesResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListResourcesResult result;

  /// Creates a [ListResourcesResultResponse].
  ListResourcesResultResponse({required this.id, required this.result});

  /// Converts this [ListResourcesResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ListResourcesResultResponse] from a decoded MCP JSON map.
  factory ListResourcesResultResponse.toMCP(Map<String, Object?> map) {
    return ListResourcesResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListResourcesResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a resources/list request.
class ListResourcesResult extends MapMC<String, Object?> {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Resource> get resources => (data['resources'] as List<dynamic>)
      .map((e) => Resource.toMCP(e as Map<String, Object?>))
      .toList();

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resources(List<Resource> value) =>
      data['resources'] = value.map((e) => e.toMap()).toList();
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [ListResourcesResult].
  ListResourcesResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    String? nextCursor,
    required List<Resource> resources,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          if (nextCursor != null) 'nextCursor': nextCursor,
          'resources': resources.map((e) => e.toMap()).toList(),
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [ListResourcesResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ListResourcesResult] from a decoded MCP JSON map.
  factory ListResourcesResult.toMCP(Map<String, Object?> map) {
    return ListResourcesResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      nextCursor: map['nextCursor'] as String?,
      resources: (map['resources'] as List<dynamic>)
          .map((e) => Resource.toMCP(e as Map<String, Object?>))
          .toList(),
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'nextCursor' ||
              key == 'resources' ||
              key == 'ttlMs' ||
              key == 'cacheScope',
        ),
    );
  }
}

/// A known resource that the server can serve.
class Resource extends MCP {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic name.
  String name;

  /// Human-readable display title.
  String? title;

  /// The resource URI.
  String uri;

  /// Human-readable description.
  String? description;

  /// Optional MIME type.
  String? mimeType;

  /// Optional client annotations.
  Annotations? annotations;

  /// Raw resource size in bytes, if known.
  int? size;

  /// Optional metadata.
  MetaObject? $meta;

  /// Creates a [Resource].
  Resource({
    this.icons,
    required this.name,
    this.title,
    required this.uri,
    this.description,
    this.mimeType,
    this.annotations,
    this.size,
    this.$meta,
  });

  /// Converts this [Resource] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (title != null) 'title': title,
      'uri': uri,
      if (description != null) 'description': description,
      if (mimeType != null) 'mimeType': mimeType,
      if (annotations != null) 'annotations': annotations!.toMap(),
      if (size != null) 'size': size,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [Resource] from a decoded MCP JSON map.
  factory Resource.toMCP(Map<String, Object?> map) {
    return Resource(
      icons: (map['icons'] as List<dynamic>?)
          ?.map((e) => Icon.toMCP(e as Map<String, Object?>))
          .toList(),
      name: map['name'] as String,
      title: map['title'] as String?,
      uri: map['uri'] as String,
      description: map['description'] as String?,
      mimeType: map['mimeType'] as String?,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      size: map['size'] as int?,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Sent from the client to the server, to read a specific resource URI.
class ReadResourceRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/read";
  ReadResourceRequestParams params;

  /// Creates a [ReadResourceRequest].
  ReadResourceRequest({required this.id, required this.params});

  /// Converts this [ReadResourceRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [ReadResourceRequest] from a decoded MCP JSON map.
  factory ReadResourceRequest.toMCP(Map<String, Object?> map) {
    return ReadResourceRequest(
      id: map['id']?.toString() ?? '-1',
      params: ReadResourceRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for a resources/read request.
class ReadResourceRequestParams extends InputResponseRequestParams {
  /// The URI of the resource.
  String uri;

  /// Creates a [ReadResourceRequestParams].
  ReadResourceRequestParams({
    required super.$meta,
    super.inputResponses,
    super.requestState,
    required this.uri,
  });

  /// Converts this [ReadResourceRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'uri': uri};
  }

  /// Builds a [ReadResourceRequestParams] from a decoded MCP JSON map.
  factory ReadResourceRequestParams.toMCP(Map<String, Object?> map) {
    return ReadResourceRequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
      inputResponses: map['inputResponses'],
      requestState: map['requestState'] as String?,
      uri: map['uri'] as String,
    );
  }
}

/// A successful response from the server for a resources/read request.
class ReadResourceResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ReadResourceResultOutcome result;

  /// Creates a [ReadResourceResultResponse].
  ReadResourceResultResponse({required this.id, required this.result});

  /// Converts this [ReadResourceResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ReadResourceResultResponse] from a decoded MCP JSON map.
  factory ReadResourceResultResponse.toMCP(Map<String, Object?> map) {
    return ReadResourceResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ReadResourceResultOutcome.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

/// The result returned by the server for a resources/read request.
class ReadResourceResult extends MapMC<String, Object?>
    implements ReadResourceResultOutcome {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';
  List<ResourceContents> get contents => (data['contents'] as List<dynamic>)
      .map((e) => ResourceContents.toMCP(e as Map<String, Object?>))
      .toList();

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set contents(List<ResourceContents> value) =>
      data['contents'] = value.map((e) => e.toMap()).toList();
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [ReadResourceResult].
  ReadResourceResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    required List<ResourceContents> contents,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          'contents': contents.map((e) => e.toMap()).toList(),
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [ReadResourceResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ReadResourceResult] from a decoded MCP JSON map.
  factory ReadResourceResult.toMCP(Map<String, Object?> map) {
    return ReadResourceResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      contents: (map['contents'] as List<dynamic>)
          .map((e) => ResourceContents.toMCP(e as Map<String, Object?>))
          .toList(),
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'contents' ||
              key == 'ttlMs' ||
              key == 'cacheScope',
        ),
    );
  }
}

/// A URI template (RFC 6570) describing a family of resources.
class ResourceTemplate extends MCP {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic name.
  String name;

  /// Human-readable display title.
  String? title;

  /// RFC 6570 URI template.
  String uriTemplate;

  /// Human-readable description of the template.
  String? description;

  /// Shared MIME type for all resources matching this template.
  String? mimeType;

  /// Optional client annotations.
  Annotations? annotations;

  /// Optional metadata.
  MetaObject? $meta;

  /// Creates a [ResourceTemplate].
  ResourceTemplate({
    this.icons,
    required this.name,
    this.title,
    required this.uriTemplate,
    this.description,
    this.mimeType,
    this.annotations,
    this.$meta,
  });

  /// Converts this [ResourceTemplate] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (title != null) 'title': title,
      'uriTemplate': uriTemplate,
      if (description != null) 'description': description,
      if (mimeType != null) 'mimeType': mimeType,
      if (annotations != null) 'annotations': annotations!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [ResourceTemplate] from a decoded MCP JSON map.
  factory ResourceTemplate.toMCP(Map<String, Object?> map) {
    return ResourceTemplate(
      icons: (map['icons'] as List<dynamic>?)
          ?.map((e) => Icon.toMCP(e as Map<String, Object?>))
          .toList(),
      name: map['name'] as String,
      title: map['title'] as String?,
      uriTemplate: map['uriTemplate'] as String,
      description: map['description'] as String?,
      mimeType: map['mimeType'] as String?,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Sent from the client to request a list of resource templates the server has.
class ListResourceTemplatesRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/templates/list";
  PaginatedRequestParams? params;

  /// Creates a [ListResourceTemplatesRequest].
  ListResourceTemplatesRequest({required this.id, this.params});

  /// Converts this [ListResourceTemplatesRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ListResourceTemplatesRequest] from a decoded MCP JSON map.
  factory ListResourceTemplatesRequest.toMCP(Map<String, Object?> map) {
    return ListResourceTemplatesRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A successful response from the server for a resources/templates/list request.
class ListResourceTemplatesResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListResourceTemplatesResult result;

  /// Creates a [ListResourceTemplatesResultResponse].
  ListResourceTemplatesResultResponse({required this.id, required this.result});

  /// Converts this [ListResourceTemplatesResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ListResourceTemplatesResultResponse] from a decoded MCP JSON map.
  factory ListResourceTemplatesResultResponse.toMCP(Map<String, Object?> map) {
    return ListResourceTemplatesResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListResourceTemplatesResult.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

/// The result returned by the server for a resources/templates/list request.
class ListResourceTemplatesResult extends MapMC<String, Object?> {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<ResourceTemplate> get resourceTemplates =>
      (data['resourceTemplates'] as List<dynamic>)
          .map((e) => ResourceTemplate.toMCP(e as Map<String, Object?>))
          .toList();

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resourceTemplates(List<ResourceTemplate> value) =>
      data['resourceTemplates'] = value.map((e) => e.toMap()).toList();
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [ListResourceTemplatesResult].
  ListResourceTemplatesResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    String? nextCursor,
    required List<ResourceTemplate> resourceTemplates,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          if (nextCursor != null) 'nextCursor': nextCursor,
          'resourceTemplates': resourceTemplates.map((e) => e.toMap()).toList(),
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [ListResourceTemplatesResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ListResourceTemplatesResult] from a decoded MCP JSON map.
  factory ListResourceTemplatesResult.toMCP(Map<String, Object?> map) {
    return ListResourceTemplatesResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      nextCursor: map['nextCursor'] as String?,
      resourceTemplates: (map['resourceTemplates'] as List<dynamic>)
          .map((e) => ResourceTemplate.toMCP(e as Map<String, Object?>))
          .toList(),
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'nextCursor' ||
              key == 'resourceTemplates' ||
              key == 'ttlMs' ||
              key == 'cacheScope',
        ),
    );
  }
}

/// Filter describing which change notifications a `subscriptions/listen`
/// stream should deliver.
class SubscriptionFilter extends MCP {
  /// If true, receive notifications/tools/list\_changed.
  bool? toolsListChanged;

  /// If true, receive notifications/prompts/list\_changed.
  bool? promptsListChanged;

  /// If true, receive notifications/resources/list\_changed.
  bool? resourcesListChanged;

  /// Subscribe to notifications/resources/updated for these resource URIs.
  List<String>? resourceSubscriptions;

  /// Creates a [SubscriptionFilter].
  SubscriptionFilter({
    this.toolsListChanged,
    this.promptsListChanged,
    this.resourcesListChanged,
    this.resourceSubscriptions,
  });

  /// Converts this [SubscriptionFilter] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (toolsListChanged != null) 'toolsListChanged': toolsListChanged,
      if (promptsListChanged != null) 'promptsListChanged': promptsListChanged,
      if (resourcesListChanged != null)
        'resourcesListChanged': resourcesListChanged,
      if (resourceSubscriptions != null)
        'resourceSubscriptions': resourceSubscriptions,
    };
  }

  /// Builds a [SubscriptionFilter] from a decoded MCP JSON map.
  factory SubscriptionFilter.toMCP(Map<String, Object?> map) {
    return SubscriptionFilter(
      toolsListChanged: map['toolsListChanged'] as bool?,
      promptsListChanged: map['promptsListChanged'] as bool?,
      resourcesListChanged: map['resourcesListChanged'] as bool?,
      resourceSubscriptions:
          (map['resourceSubscriptions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

/// Parameters for a subscriptions/listen request.
class SubscriptionsListenRequestParams extends MCP {
  RequestMetaObject $meta;

  /// The notifications the client opts in to on this stream.
  SubscriptionFilter notifications;

  /// Creates a [SubscriptionsListenRequestParams].
  SubscriptionsListenRequestParams({
    required this.$meta,
    required this.notifications,
  });

  /// Converts this [SubscriptionsListenRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'_meta': $meta.toMap(), 'notifications': notifications.toMap()};
  }

  /// Builds a [SubscriptionsListenRequestParams] from a decoded MCP JSON map.
  factory SubscriptionsListenRequestParams.toMCP(Map<String, Object?> map) {
    return SubscriptionsListenRequestParams(
      $meta: RequestMetaObject.toMCP(
          map['_meta'] as Map<String, Object?>? ?? <String, Object?>{}),
      notifications: SubscriptionFilter.toMCP(
        map['notifications'] as Map<String, Object?>,
      ),
    );
  }
}

/// Opens a long-lived stream on which the server pushes change
/// notifications, replacing the former `resources/subscribe` /
/// `resources/unsubscribe` RPCs.
class SubscriptionsListenRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "subscriptions/listen";
  SubscriptionsListenRequestParams params;

  /// Creates a [SubscriptionsListenRequest].
  SubscriptionsListenRequest({required this.id, required this.params});

  /// Converts this [SubscriptionsListenRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [SubscriptionsListenRequest] from a decoded MCP JSON map.
  factory SubscriptionsListenRequest.toMCP(Map<String, Object?> map) {
    return SubscriptionsListenRequest(
      id: map['id']?.toString() ?? '-1',
      params: SubscriptionsListenRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// The `_meta` object carried on a [SubscriptionsListenResult].
class SubscriptionsListenResultMetaObject extends MapMC<String, Object?> {
  /// Creates a [SubscriptionsListenResultMetaObject].
  SubscriptionsListenResultMetaObject({
    Implementation? serverInfo,
    required String subscriptionId,
    Map<String, Object?>? additionalData,
  }) : super({
          if (serverInfo != null)
            'io.modelcontextprotocol/serverInfo': serverInfo.toMap(),
          'io.modelcontextprotocol/subscriptionId': subscriptionId,
          ...?additionalData,
        });

  Implementation? get serverInfo =>
      data['io.modelcontextprotocol/serverInfo'] != null
          ? Implementation.toMCP(
              data['io.modelcontextprotocol/serverInfo']
                  as Map<String, Object?>,
            )
          : null;

  set serverInfo(Implementation? value) =>
      data['io.modelcontextprotocol/serverInfo'] = value?.toMap();

  /// The JSON-RPC ID of the `subscriptions/listen` request that opened this
  /// stream.
  String get subscriptionId =>
      data['io.modelcontextprotocol/subscriptionId'].toString();

  set subscriptionId(String value) =>
      data['io.modelcontextprotocol/subscriptionId'] = value;

  /// Converts this [SubscriptionsListenResultMetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() => data;

  /// Builds a [SubscriptionsListenResultMetaObject] from a decoded MCP JSON map.
  factory SubscriptionsListenResultMetaObject.toMCP(Map<String, Object?> map) {
    return SubscriptionsListenResultMetaObject(
      serverInfo: map['io.modelcontextprotocol/serverInfo'] != null
          ? Implementation.toMCP(
              map['io.modelcontextprotocol/serverInfo'] as Map<String, Object?>,
            )
          : null,
      subscriptionId: map['io.modelcontextprotocol/subscriptionId'].toString(),
      additionalData: Map<String, Object?>.from(map)
        ..removeWhere(
          (key, _) =>
              key == 'io.modelcontextprotocol/serverInfo' ||
              key == 'io.modelcontextprotocol/subscriptionId',
        ),
    );
  }
}

/// Sent by the server, at most once, to gracefully terminate a
/// `subscriptions/listen` stream. The result body is otherwise empty.
class SubscriptionsListenResult extends MapMC<String, Object?> {
  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';
  SubscriptionsListenResultMetaObject get $meta =>
      SubscriptionsListenResultMetaObject.toMCP(
        data['_meta'] as Map<String, Object?>,
      );

  set resultType(String value) => data['resultType'] = value;
  set $meta(SubscriptionsListenResultMetaObject value) =>
      data['_meta'] = value.toMap();

  /// Creates a [SubscriptionsListenResult].
  SubscriptionsListenResult({
    String resultType = 'complete',
    required SubscriptionsListenResultMetaObject $meta,
    Map<String, Object?>? additionalData,
  }) : super({
          'resultType': resultType,
          '_meta': $meta.toMap(),
          ...?additionalData,
        });

  /// Converts this [SubscriptionsListenResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() => data;

  /// Builds a [SubscriptionsListenResult] from a decoded MCP JSON map.
  factory SubscriptionsListenResult.toMCP(Map<String, Object?> map) {
    return SubscriptionsListenResult(
      resultType: map['resultType'] as String? ?? 'complete',
      $meta: SubscriptionsListenResultMetaObject.toMCP(
        map['_meta'] as Map<String, Object?>,
      ),
      additionalData: Map<String, Object?>.from(map)
        ..removeWhere((key, _) => key == 'resultType' || key == '_meta'),
    );
  }
}

/// A successful response from the server for a subscriptions/listen request, sent when the server tears the subscription down gracefully.
class SubscriptionsListenResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  SubscriptionsListenResult result;

  /// Creates a [SubscriptionsListenResultResponse].
  SubscriptionsListenResultResponse({required this.id, required this.result});

  /// Converts this [SubscriptionsListenResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [SubscriptionsListenResultResponse] from a decoded MCP JSON map.
  factory SubscriptionsListenResultResponse.toMCP(Map<String, Object?> map) {
    return SubscriptionsListenResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: SubscriptionsListenResult.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

/// The first message a server sends after a client opens a new
/// `subscriptions/listen` stream, acknowledging which notifications it will
/// deliver on it.
class SubscriptionsAcknowledgedNotificationParams extends MCP {
  NotificationMetaObject? $meta;

  /// The subset of requested notification types the server agreed to honor.
  SubscriptionFilter notifications;

  /// Creates a [SubscriptionsAcknowledgedNotificationParams].
  SubscriptionsAcknowledgedNotificationParams({
    this.$meta,
    required this.notifications,
  });

  /// Converts this [SubscriptionsAcknowledgedNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'notifications': notifications.toMap(),
    };
  }

  /// Builds a [SubscriptionsAcknowledgedNotificationParams] from a decoded MCP JSON map.
  factory SubscriptionsAcknowledgedNotificationParams.toMCP(
    Map<String, Object?> map,
  ) {
    return SubscriptionsAcknowledgedNotificationParams(
      $meta: map['_meta'] != null
          ? NotificationMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      notifications: SubscriptionFilter.toMCP(
        map['notifications'] as Map<String, Object?>,
      ),
    );
  }
}

/// Sent by the server to acknowledge that a subscriptions/listen subscription has been established and to report which notification types it agreed to honor.
class SubscriptionsAcknowledgedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/subscriptions/acknowledged";
  SubscriptionsAcknowledgedNotificationParams params;

  /// Creates a [SubscriptionsAcknowledgedNotification].
  SubscriptionsAcknowledgedNotification({required this.params});

  /// Converts this [SubscriptionsAcknowledgedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds a [SubscriptionsAcknowledgedNotification] from a decoded MCP JSON map.
  factory SubscriptionsAcknowledgedNotification.toMCP(
    Map<String, Object?> map,
  ) {
    return SubscriptionsAcknowledgedNotification(
      params: SubscriptionsAcknowledgedNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Represents a root directory or file that the server can operate on.
class Root extends MCP {
  /// The URI identifying the root.
  String uri;

  /// An optional name for the root.
  String? name;
  MetaObject? $meta;

  /// Creates a [Root].
  Root({required this.uri, this.name, this.$meta});

  /// Converts this [Root] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'uri': uri,
      if (name != null) 'name': name,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [Root] from a decoded MCP JSON map.
  factory Root.toMCP(Map<String, Object?> map) {
    return Root(
      uri: map['uri'] as String,
      name: map['name'] as String?,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// The result returned by the client for a roots/list request.
class ListRootsResult extends MCP {
  // ignore: deprecated_member_use_from_same_package
  List<Root> roots;

  /// Creates a [ListRootsResult].
  ListRootsResult({required this.roots});

  /// Converts this [ListRootsResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'roots': roots.map((e) => e.toMap()).toList()};
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [ListRootsResult] from a decoded MCP JSON map.
  factory ListRootsResult.toMCP(Map<String, Object?> map) {
    return ListRootsResult(
      roots: (map['roots'] as List<dynamic>)
          // ignore: deprecated_member_use_from_same_package
          .map((e) => Root.toMCP(e as Map<String, Object?>))
          .toList(),
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Sent from the server to request a list of root URIs from the client.
class ListRootsRequest extends MCP {
  String method = "roots/list";
  RequestParams? params;

  /// Creates a [ListRootsRequest].
  ListRootsRequest({this.params});

  /// Converts this [ListRootsRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'method': method, if (params != null) 'params': params!.toMap()};
  }

  /// Builds a [ListRootsRequest] from a decoded MCP JSON map.
  factory ListRootsRequest.toMCP(Map<String, Object?> map) {
    return ListRootsRequest(
      params: map['params'] != null
          ? RequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Hints to use for model selection.
class ModelHint extends MCP {
  /// A hint for a model name.
  String? name;

  /// Creates a [ModelHint].
  ModelHint({this.name});

  /// Converts this [ModelHint] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if (name != null) 'name': name};
  }

  /// Builds a [ModelHint] from a decoded MCP JSON map.
  factory ModelHint.toMCP(Map<String, Object?> map) {
    return ModelHint(name: map['name'] as String?);
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// The server's preferences for model selection, requested of the client during sampling.
class ModelPreferences extends MCP {
  // ignore: deprecated_member_use_from_same_package
  /// Optional hints to use for model selection.
  List<ModelHint>? hints;

  /// How much to prioritize cost when selecting a model.
  num? costPriority;

  /// How much to prioritize sampling speed (latency) when selecting a model.
  num? speedPriority;

  /// How much to prioritize intelligence and capabilities when selecting a model.
  num? intelligencePriority;

  /// Creates a [ModelPreferences].
  ModelPreferences({
    this.hints,
    this.costPriority,
    this.speedPriority,
    this.intelligencePriority,
  });

  /// Converts this [ModelPreferences] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (hints != null) 'hints': hints!.map((e) => e.toMap()).toList(),
      if (costPriority != null) 'costPriority': costPriority,
      if (speedPriority != null) 'speedPriority': speedPriority,
      if (intelligencePriority != null)
        'intelligencePriority': intelligencePriority,
    };
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [ModelPreferences] from a decoded MCP JSON map.
  factory ModelPreferences.toMCP(Map<String, Object?> map) {
    return ModelPreferences(
      hints: (map['hints'] as List<dynamic>?)
          // ignore: deprecated_member_use_from_same_package
          ?.map((e) => ModelHint.toMCP(e as Map<String, Object?>))
          .toList(),
      costPriority: map['costPriority'] as num?,
      speedPriority: map['speedPriority'] as num?,
      intelligencePriority: map['intelligencePriority'] as num?,
    );
  }
}

/// Restricted content-block union accepted by [SamplingMessage.content].
///
/// Unlike the general [ContentBlock] union, sampling messages may only
/// carry [TextContent], [ImageContent], [AudioContent], [ToolUseContent],
/// or [ToolResultContent] — never a [ResourceLink] or [EmbeddedResource].
@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// The MCP `SamplingMessageContentBlock` schema type.
abstract class SamplingMessageContentBlock implements MCP {
  /// Builds a [SamplingMessageContentBlock] from a decoded MCP JSON map.
  factory SamplingMessageContentBlock.toMCP(Map<String, Object?> map) {
    final block = ContentBlock.toMCP(map);
    if (block is SamplingMessageContentBlock) {
      return block as SamplingMessageContentBlock;
    }
    throw ArgumentError(
      'Unsupported SamplingMessageContentBlock type: ${map['type']}',
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Describes a message issued to or received from an LLM API.
class SamplingMessage extends MCP {
  Role role;

  // ignore: deprecated_member_use_from_same_package
  List<SamplingMessageContentBlock> content;
  MetaObject? $meta;

  /// Creates a [SamplingMessage].
  SamplingMessage({required this.role, required this.content, this.$meta});

  /// Converts this [SamplingMessage] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'role': role.toString(),
      'content': content.map((e) => e.toMap()).toList(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [SamplingMessage] from a decoded MCP JSON map.
  factory SamplingMessage.toMCP(Map<String, Object?> map) {
    return SamplingMessage(
      role: Role.to(map['role'] as String),
      content: (map['content'] as List<dynamic>)
          // ignore: deprecated_member_use_from_same_package
          .map(
            (e) => SamplingMessageContentBlock.toMCP(e as Map<String, Object?>),
          )
          .toList(),
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Controls tool selection behavior for sampling requests.
class ToolChoice extends MCP {
  /// Controls the tool use ability of the model:
  String? mode;

  /// Creates a [ToolChoice].
  ToolChoice({this.mode});

  /// Converts this [ToolChoice] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if (mode != null) 'mode': mode};
  }

  /// Builds a [ToolChoice] from a decoded MCP JSON map.
  factory ToolChoice.toMCP(Map<String, Object?> map) {
    return ToolChoice(mode: map['mode'] as String?);
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// The result of a tool use, provided by the user back to the assistant.
class ToolResultContent extends ContentBlock
    // ignore: deprecated_member_use_from_same_package
    implements
        SamplingMessageContentBlock {
  /// The ID of the tool use this result corresponds to.
  String toolUseId;

  /// The unstructured result content of the tool use.
  List<ContentBlock> content;

  /// An optional structured result value.
  Map<String, Object?>? structuredContent;

  /// Whether the tool use resulted in an error.
  bool? isError;

  /// Creates a [ToolResultContent].
  ToolResultContent({
    required this.toolUseId,
    required this.content,
    this.structuredContent,
    this.isError,
    super.annotations,
    super.$meta,
  }) : super(type: 'tool_result', data: '', mimeType: '');

  /// Converts this [ToolResultContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'type': type,
      'toolUseId': toolUseId,
      'content': content.map((e) => e.toMap()).toList(),
      if (structuredContent != null) 'structuredContent': structuredContent,
      if (isError != null) 'isError': isError,
      if (annotations != null) 'annotations': annotations!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [ToolResultContent] from a decoded MCP JSON map.
  factory ToolResultContent.toMCP(Map<String, Object?> map) {
    return ToolResultContent(
      toolUseId: map['toolUseId'] as String,
      content: (map['content'] as List<dynamic>)
          .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
          .toList(),
      structuredContent: map['structuredContent'] as Map<String, Object?>?,
      isError: map['isError'] as bool?,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// A request from the assistant to call a tool.
class ToolUseContent extends ContentBlock
    // ignore: deprecated_member_use_from_same_package
    implements
        SamplingMessageContentBlock {
  /// A unique identifier for this tool use.
  String id;

  /// The name of the tool to call.
  String name;

  /// The arguments to pass to the tool, conforming to the tool's input schema.
  Map<String, Object?> input;

  /// Creates a [ToolUseContent].
  ToolUseContent({
    required this.id,
    required this.name,
    required this.input,
    super.annotations,
    super.$meta,
  }) : super(type: 'tool_use', data: '', mimeType: '');

  /// Converts this [ToolUseContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'input': input,
      if (annotations != null) 'annotations': annotations!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [ToolUseContent] from a decoded MCP JSON map.
  factory ToolUseContent.toMCP(Map<String, Object?> map) {
    return ToolUseContent(
      id: map['id']?.toString() ?? '-1',
      name: map['name'] as String,
      input: map['input'] as Map<String, Object?>,
      annotations: map['annotations'] != null
          ? Annotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Behavioural hints for a [Tool] (all properties are advisory).
class ToolAnnotations extends MCP {
  /// Human-readable title.
  String? title;

  /// If `true`, the tool does not modify its environment.
  bool? readOnlyHint;

  /// If `true`, the tool may perform destructive updates.
  bool? destructiveHint;

  /// If `true`, repeated calls with identical arguments have no extra effect.
  bool? idempotentHint;

  /// If `true`, the tool interacts with an open world of external entities.
  bool? openWorldHint;

  /// Creates a [ToolAnnotations].
  ToolAnnotations({
    this.title,
    this.readOnlyHint,
    this.destructiveHint,
    this.idempotentHint,
    this.openWorldHint,
  });

  /// Converts this [ToolAnnotations] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (title != null) 'title': title,
      if (readOnlyHint != null) 'readOnlyHint': readOnlyHint,
      if (destructiveHint != null) 'destructiveHint': destructiveHint,
      if (idempotentHint != null) 'idempotentHint': idempotentHint,
      if (openWorldHint != null) 'openWorldHint': openWorldHint,
    };
  }

  /// Builds a [ToolAnnotations] from a decoded MCP JSON map.
  factory ToolAnnotations.toMCP(Map<String, Object?> map) {
    return ToolAnnotations(
      title: map['title'] as String?,
      readOnlyHint: map['readOnlyHint'] as bool?,
      destructiveHint: map['destructiveHint'] as bool?,
      idempotentHint: map['idempotentHint'] as bool?,
      openWorldHint: map['openWorldHint'] as bool?,
    );
  }
}

/// Execution-related properties for a [Tool].
/// JSON Schema (2020-12) object used for a tool's [Tool.inputSchema] or
/// [Tool.outputSchema].
///
/// Exposes [properties]/[required]/[type] as typed convenience accessors,
/// but preserves any other JSON Schema keyword (`oneOf`, `$ref`, `items`,
/// `$defs`, etc.) losslessly via [additionalData].
class ToolSchema extends MCP {
  /// Optional `$schema` URI. Defaults to JSON Schema 2020-12 when absent.
  String? $schema;

  /// Root type; always `"object"` for tool schemas.
  String type;

  /// Property definitions.
  Map<String, Object?>? properties;

  /// Required property names.
  List<String>? required;

  /// Any other JSON Schema keyword not covered by a typed field above,
  /// preserved losslessly on round-trip.
  Map<String, Object?>? additionalData;

  /// Creates a [ToolSchema].
  ToolSchema({
    this.$schema,
    this.properties,
    this.required,
    this.type = 'object',
    this.additionalData,
  });

  /// Converts this [ToolSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...?additionalData,
      if ($schema != null) r'$schema': $schema,
      'type': type,
      if (properties != null) 'properties': properties,
      if (required != null) 'required': required,
    };
  }

  /// Builds a [ToolSchema] from a decoded MCP JSON map.
  factory ToolSchema.toMCP(Map<String, Object?> map) {
    return ToolSchema(
      $schema: map[r'$schema'] as String?,
      properties: map['properties'] as Map<String, Object?>?,
      required: (map['required'] as List<dynamic>?)?.cast<String>(),
      type: map['type'] as String? ?? 'object',
      additionalData: Map<String, Object?>.from(map)
        ..removeWhere(
          (key, _) =>
              key == r'$schema' ||
              key == 'properties' ||
              key == 'required' ||
              key == 'type',
        ),
    );
  }
}

/// A tool that the server exposes for the client to call.
class Tool extends MCP {
  /// Optional display icons.
  List<Icon>? icons;

  /// Programmatic tool name.
  String name;

  /// Human-readable display title.
  String? title;

  /// Human-readable description of what the tool does.
  String? description;

  /// JSON Schema for the expected call arguments.
  ToolSchema inputSchema;

  /// Optional JSON Schema for the structured output.
  ToolSchema? outputSchema;

  /// Optional behavioural hints.
  ToolAnnotations? annotations;

  /// Optional metadata.
  MetaObject? $meta;

  /// Creates a [Tool].
  Tool({
    this.icons,
    required this.name,
    this.title,
    this.description,
    required this.inputSchema,
    this.outputSchema,
    this.annotations,
    this.$meta,
  });

  /// Converts this [Tool] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (icons != null) 'icons': icons!.map((e) => e.toMap()).toList(),
      'name': name,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'inputSchema': inputSchema.toMap(),
      if (outputSchema != null) 'outputSchema': outputSchema!.toMap(),
      if (annotations != null) 'annotations': annotations!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [Tool] from a decoded MCP JSON map.
  factory Tool.toMCP(Map<String, Object?> map) {
    return Tool(
      icons: (map['icons'] as List<dynamic>?)
          ?.map((e) => Icon.toMCP(e as Map<String, Object?>))
          .toList(),
      name: map['name'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      inputSchema: ToolSchema.toMCP(map['inputSchema'] as Map<String, Object?>),
      outputSchema: map['outputSchema'] != null
          ? ToolSchema.toMCP(map['outputSchema'] as Map<String, Object?>)
          : null,
      annotations: map['annotations'] != null
          ? ToolAnnotations.toMCP(map['annotations'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// Parameters for a sampling/createMessage request.
class CreateMessageRequestParams extends MCP {
  // ignore: deprecated_member_use_from_same_package
  List<SamplingMessage> messages;
  // ignore: deprecated_member_use_from_same_package
  /// The server's preferences for which model to select.
  ModelPreferences? modelPreferences;

  /// An optional system prompt the server wants to use for sampling.
  String? systemPrompt;

  /// A request to include context from one or more MCP servers (including the caller), to be attached to the prompt.
  String? includeContext;
  num? temperature;

  /// The requested maximum number of tokens to sample (to prevent runaway completions).
  int maxTokens;
  List<String>? stopSequences;

  /// Optional metadata to pass through to the LLM provider.
  Map<String, Object?>? metadata;

  /// Tools that the model may use during generation.
  List<Tool>? tools;
  // ignore: deprecated_member_use_from_same_package
  /// Controls how the model uses tools.
  ToolChoice? toolChoice;

  /// Creates a [CreateMessageRequestParams].
  CreateMessageRequestParams({
    required this.messages,
    this.modelPreferences,
    this.systemPrompt,
    this.includeContext,
    this.temperature,
    required this.maxTokens,
    this.stopSequences,
    this.metadata,
    this.tools,
    this.toolChoice,
  });

  /// Converts this [CreateMessageRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'messages': messages.map((e) => e.toMap()).toList(),
      if (modelPreferences != null)
        'modelPreferences': modelPreferences!.toMap(),
      if (systemPrompt != null) 'systemPrompt': systemPrompt,
      if (includeContext != null) 'includeContext': includeContext,
      if (temperature != null) 'temperature': temperature,
      'maxTokens': maxTokens,
      if (stopSequences != null) 'stopSequences': stopSequences,
      if (metadata != null) 'metadata': metadata,
      if (tools != null) 'tools': tools!.map((e) => e.toMap()).toList(),
      if (toolChoice != null) 'toolChoice': toolChoice!.toMap(),
    };
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [CreateMessageRequestParams] from a decoded MCP JSON map.
  factory CreateMessageRequestParams.toMCP(Map<String, Object?> map) {
    return CreateMessageRequestParams(
      messages: (map['messages'] as List<dynamic>)
          // ignore: deprecated_member_use_from_same_package
          .map((e) => SamplingMessage.toMCP(e as Map<String, Object?>))
          .toList(),
      modelPreferences: map['modelPreferences'] != null
          // ignore: deprecated_member_use_from_same_package
          ? ModelPreferences.toMCP(
              map['modelPreferences'] as Map<String, Object?>,
            )
          : null,
      systemPrompt: map['systemPrompt'] as String?,
      includeContext: map['includeContext'] as String?,
      temperature: map['temperature'] as num?,
      maxTokens: map['maxTokens'] as int,
      stopSequences: (map['stopSequences'] as List<dynamic>?)?.cast<String>(),
      metadata: map['metadata'] as Map<String, Object?>?,
      tools: (map['tools'] as List<dynamic>?)
          ?.map((e) => Tool.toMCP(e as Map<String, Object?>))
          .toList(),
      toolChoice: map['toolChoice'] != null
          // ignore: deprecated_member_use_from_same_package
          ? ToolChoice.toMCP(map['toolChoice'] as Map<String, Object?>)
          : null,
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// A request from the server to sample an LLM via the client.
class CreateMessageRequest extends MCP {
  String method = "sampling/createMessage";

  // ignore: deprecated_member_use_from_same_package
  CreateMessageRequestParams params;

  /// Creates a [CreateMessageRequest].
  CreateMessageRequest({required this.params});

  /// Converts this [CreateMessageRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'method': method, 'params': params.toMap()};
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds a [CreateMessageRequest] from a decoded MCP JSON map.
  factory CreateMessageRequest.toMCP(Map<String, Object?> map) {
    return CreateMessageRequest(
      params: CreateMessageRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

@Deprecated(
  'Deprecated as of protocol version 2026-07-28 (SEP-2577). '
  'Remains in the specification for at least twelve months.',
)

/// The result returned by the client for a sampling/createMessage request.
class CreateMessageResult extends MCP {
  /// The name of the model that generated the message.
  String model;

  /// The reason why sampling stopped, if known.
  String? stopReason;
  Role role;
  List<ContentBlock> content;
  MetaObject? $meta;

  /// Creates a [CreateMessageResult].
  CreateMessageResult({
    required this.model,
    this.stopReason,
    required this.role,
    required this.content,
    this.$meta,
  });

  /// Converts this [CreateMessageResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'model': model,
      if (stopReason != null) 'stopReason': stopReason,
      'role': role.toString(),
      'content': content.map((e) => e.toMap()).toList(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [CreateMessageResult] from a decoded MCP JSON map.
  factory CreateMessageResult.toMCP(Map<String, Object?> map) {
    return CreateMessageResult(
      model: map['model'] as String,
      stopReason: map['stopReason'] as String?,
      role: Role.to(map['role'] as String),
      content: (map['content'] as List<dynamic>)
          .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
          .toList(),
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Parameters for a `tools/call` request.
class CallToolRequestParams extends InputResponseRequestParams {
  /// Name of the tool to invoke.
  String name;

  /// Tool call arguments.
  Map<String, Object?>? arguments;

  /// Creates a [CallToolRequestParams].
  CallToolRequestParams({
    required super.$meta,
    super.inputResponses,
    super.requestState,
    required this.name,
    this.arguments,
  });

  /// Converts this [CallToolRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'name': name,
      if (arguments != null) 'arguments': arguments,
    };
  }

  /// Builds a [CallToolRequestParams] from a decoded MCP JSON map.
  factory CallToolRequestParams.toMCP(Map<String, Object?> map) {
    return CallToolRequestParams(
      $meta: RequestMetaObject.toMCP(
          (map['_meta'] ?? <String, Object?>{}) as Map<String, Object?>),
      inputResponses: map['inputResponses'],
      requestState: map['requestState'] as String?,
      name: map['name'] as String,
      arguments: map['arguments'] as Map<String, Object?>?,
    );
  }
}

/// A `tools/call` JSON-RPC request.
class CallToolRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tools/call";
  CallToolRequestParams params;

  /// Creates a [CallToolRequest].
  CallToolRequest({required this.id, required this.params});

  /// Converts this [CallToolRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [CallToolRequest] from a decoded MCP JSON map.
  factory CallToolRequest.toMCP(Map<String, Object?> map) {
    return CallToolRequest(
      id: map['id']?.toString() ?? '-1',
      params: CallToolRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// The server's response to a `tools/call` request.
class CallToolResult extends MapMC<String, Object?>
    implements CallToolResultOutcome {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';
  List<ContentBlock> get content => (data['content'] as List<dynamic>)
      .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
      .toList();
  Map<String, Object?>? get structuredContent =>
      data['structuredContent'] as Map<String, Object?>?;

  /// Whether the tool call ended in an error.
  bool? get isError => data['isError'] as bool?;

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set content(List<ContentBlock> value) =>
      data['content'] = value.map((e) => e.toMap()).toList();
  set structuredContent(Map<String, Object?>? value) =>
      data['structuredContent'] = value;
  set isError(bool? value) => data['isError'] = value;

  /// Creates a [CallToolResult].
  CallToolResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    required List<ContentBlock> content,
    Map<String, Object?>? structuredContent,
    bool? isError,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          'content': content.map((e) => e.toMap()).toList(),
          if (structuredContent != null) 'structuredContent': structuredContent,
          if (isError != null) 'isError': isError,
          ...?additionalData,
        });

  /// Converts this [CallToolResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [CallToolResult] from a decoded MCP JSON map.
  factory CallToolResult.toMCP(Map<String, Object?> map) {
    return CallToolResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      content: ((map['content'] ?? []) as List<dynamic>)
          .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
          .toList(),
      structuredContent: map['structuredContent'] as Map<String, Object?>?,
      isError: map['isError'] as bool?,
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'content' ||
              key == 'structuredContent' ||
              key == 'isError',
        ),
    );
  }
}

/// A successful response from the server for a tools/call request.
class CallToolResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CallToolResultOutcome result;

  /// Creates a [CallToolResultResponse].
  CallToolResultResponse({required this.id, required this.result});

  /// Converts this [CallToolResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [CallToolResultResponse] from a decoded MCP JSON map.
  factory CallToolResultResponse.toMCP(Map<String, Object?> map) {
    return CallToolResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CallToolResultOutcome.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

/// Sent from the client to request a list of tools the server has.
class ListToolsRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tools/list";
  PaginatedRequestParams? params;

  /// Creates a [ListToolsRequest].
  ListToolsRequest({required this.id, this.params});

  /// Converts this [ListToolsRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ListToolsRequest] from a decoded MCP JSON map.
  factory ListToolsRequest.toMCP(Map<String, Object?> map) {
    return ListToolsRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A successful response from the server for a tools/list request.
class ListToolsResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListToolsResult result;

  /// Creates a [ListToolsResultResponse].
  ListToolsResultResponse({required this.id, required this.result});

  /// Converts this [ListToolsResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ListToolsResultResponse] from a decoded MCP JSON map.
  factory ListToolsResultResponse.toMCP(Map<String, Object?> map) {
    return ListToolsResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListToolsResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a tools/list request.
class ListToolsResult extends MapMC<String, Object?> {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Tool> get tools => (data['tools'] as List<dynamic>)
      .map((e) => Tool.toMCP(e as Map<String, Object?>))
      .toList();

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set nextCursor(String? value) => data['nextCursor'] = value;
  set tools(List<Tool> value) =>
      data['tools'] = value.map((e) => e.toMap()).toList();
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [ListToolsResult].
  ListToolsResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    String? nextCursor,
    required List<Tool> tools,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          if (nextCursor != null) 'nextCursor': nextCursor,
          'tools': tools.map((e) => e.toMap()).toList(),
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [ListToolsResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [ListToolsResult] from a decoded MCP JSON map.
  factory ListToolsResult.toMCP(Map<String, Object?> map) {
    return ListToolsResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      nextCursor: map['nextCursor'] as String?,
      tools: (map['tools'] as List<dynamic>)
          .map((e) => Tool.toMCP(e as Map<String, Object?>))
          .toList(),
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'nextCursor' ||
              key == 'tools' ||
              key == 'ttlMs' ||
              key == 'cacheScope',
        ),
    );
  }
}

// ── server/discover ──────────────────────────────────────────────────────────

/// Requests the server's capability advertisement out-of-band, replacing
/// the former `initialize` handshake now that protocol negotiation happens
/// per-request via [RequestMetaObject].
class DiscoverRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "server/discover";
  RequestParams params;

  /// Creates a [DiscoverRequest].
  DiscoverRequest({required this.id, required this.params});

  /// Converts this [DiscoverRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [DiscoverRequest] from a decoded MCP JSON map.
  factory DiscoverRequest.toMCP(Map<String, Object?> map) {
    return DiscoverRequest(
      id: map['id']?.toString() ?? '-1',
      params: RequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// A successful response from the server for a server/discover request.
class DiscoverResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  DiscoverResult result;

  /// Creates a [DiscoverResultResponse].
  DiscoverResultResponse({required this.id, required this.result});

  /// Converts this [DiscoverResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [DiscoverResultResponse] from a decoded MCP JSON map.
  factory DiscoverResultResponse.toMCP(Map<String, Object?> map) {
    return DiscoverResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: DiscoverResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The server's capability advertisement, servers implementing this
/// protocol version MUST support `server/discover`.
class DiscoverResult extends MapMC<String, Object?> {
  ResultMetaObject? get $meta => data['_meta'] != null
      ? ResultMetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// Indicates the type of the result, which allows the client to determine how to parse the result object.
  String get resultType => data['resultType'] as String? ?? 'complete';
  List<String> get supportedVersions =>
      (data['supportedVersions'] as List<dynamic>).cast<String>();
  ServerCapabilities get capabilities =>
      ServerCapabilities.toMCP(data['capabilities'] as Map<String, Object?>);

  /// Natural-language guidance describing the server and its features.
  String? get instructions => data['instructions'] as String?;

  /// A hint from the server indicating how long (in milliseconds) the client MAY cache this response before re-fetching.
  num get ttlMs => data['ttlMs'] as num;
  CacheScope get cacheScope => CacheScope.to(data['cacheScope'] as String);

  set $meta(ResultMetaObject? value) => data['_meta'] = value?.toMap();
  set resultType(String value) => data['resultType'] = value;
  set supportedVersions(List<String> value) =>
      data['supportedVersions'] = value;
  set capabilities(ServerCapabilities value) =>
      data['capabilities'] = value.toMap();
  set instructions(String? value) => data['instructions'] = value;
  set ttlMs(num value) => data['ttlMs'] = value;
  set cacheScope(CacheScope value) => data['cacheScope'] = value.toString();

  /// Creates a [DiscoverResult].
  DiscoverResult({
    ResultMetaObject? $meta,
    String resultType = 'complete',
    required List<String> supportedVersions,
    required ServerCapabilities capabilities,
    String? instructions,
    required num ttlMs,
    required CacheScope cacheScope,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'resultType': resultType,
          'supportedVersions': supportedVersions,
          'capabilities': capabilities.toMap(),
          if (instructions != null) 'instructions': instructions,
          'ttlMs': ttlMs,
          'cacheScope': cacheScope.toString(),
          ...?additionalData,
        });

  /// Converts this [DiscoverResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [DiscoverResult] from a decoded MCP JSON map.
  factory DiscoverResult.toMCP(Map<String, Object?> map) {
    return DiscoverResult(
      $meta: map['_meta'] != null
          ? ResultMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resultType: map['resultType'] as String? ?? 'complete',
      supportedVersions:
          (map['supportedVersions'] as List<dynamic>).cast<String>(),
      capabilities: ServerCapabilities.toMCP(
        map['capabilities'] as Map<String, Object?>,
      ),
      instructions: map['instructions'] as String?,
      ttlMs: map['ttlMs'] as num,
      cacheScope: CacheScope.to(map['cacheScope'] as String),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'resultType' ||
              key == 'supportedVersions' ||
              key == 'capabilities' ||
              key == 'instructions' ||
              key == 'ttlMs' ||
              key == 'cacheScope',
        ),
    );
  }
}

// ── New protocol-level errors (2026-07-28) ───────────────────────────────────

/// Returned when a server rejects a request because HTTP header values do
/// not match the corresponding values in the request body, or required
/// headers are missing/malformed. For HTTP, the response status MUST be
/// `400 Bad Request`.
class HeaderMismatchError extends Error {
  /// Creates a [HeaderMismatchError].
  HeaderMismatchError({required super.message, super.data})
      : super(code: -32020);
}

/// Returned when a request omits a client capability the server requires
/// for the requested operation.
class MissingRequiredClientCapabilityError extends Error {
  /// Creates a [MissingRequiredClientCapabilityError].
  MissingRequiredClientCapabilityError({
    required super.message,
    required ClientCapabilities requiredCapabilities,
  }) : super(
          code: -32021,
          data: {'requiredCapabilities': requiredCapabilities.toMap()},
        );
}

/// Returned when a server does not support the protocol version requested
/// via `RequestMetaObject["io.modelcontextprotocol/protocolVersion"]`.
class UnsupportedProtocolVersionError extends Error {
  /// Creates an [UnsupportedProtocolVersionError].
  UnsupportedProtocolVersionError({
    required super.message,
    required List<String> supported,
    required String requested,
  }) : super(
          code: -32022,
          data: {'supported': supported, 'requested': requested},
        );
}
