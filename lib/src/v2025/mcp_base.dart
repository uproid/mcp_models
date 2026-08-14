import '../mcp.dart';
import '../map_model.dart';
import '../v2025/enums.dart';
import '../v2025/types.dart';

/// A [MapModel] that also satisfies [MCP].
///
/// Use as the base class when the model _is_ the underlying map
/// (e.g. [InitializeResult], [ClientCapabilities]).
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
class Result extends MCP implements CancelTaskResult {
  /// Optional `_meta` object.
  MetaObject? meta;

  /// Any additional unknown fields returned by the server.
  Map<String, Object?>? unknown;

  /// Creates a [Result].
  Result({this.meta, this.unknown});

  /// Converts this [Result] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'meta': meta?.toMap(), ...?unknown};
  }

  /// Builds a [Result] from a decoded MCP JSON map.
  factory Result.toMCP(Map<String, Object?> map) {
    return Result(
      meta: map['meta'] != null
          ? MetaObject.toMCP(map['meta'] as Map<String, Object?>)
          : null,
      unknown: map['unknown'] as Map<String, Object?>?,
    );
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
/// See [MCP spec – Annotations](https://modelcontextprotocol.io/specification/2025-11-25/schema).
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
  EmptyResult() : super(meta: null, unknown: null);

  /// Converts this [EmptyResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {};
  }
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
class NotificationParams extends TaskStatusNotificationParams {
  /// Optional request metadata.
  RequestMetaObject? $meta;

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
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

/// The `_meta` object carried inside request params.
///
/// May contain a `progressToken` used for out-of-band progress notifications.
class RequestMetaObject extends MapMC<String, Object?> {
  /// Creates a [RequestMetaObject].
  RequestMetaObject({String? progressToken})
      : super({'progressToken': progressToken});

  /// If specified, the caller is requesting out-of-band progress notifications for this request (as represented by notifications/progress).
  String? get progressToken => data['progressToken'] as String?;

  set progressToken(String? value) => data['progressToken'] = value;

  /// Converts this [RequestMetaObject] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [RequestMetaObject] from a decoded MCP JSON map.
  factory RequestMetaObject.toMCP(Map<String, Object?> map) {
    return RequestMetaObject(progressToken: map['progressToken']?.toString());
  }
}

/// Request params for paginated MCP list calls.
class PaginatedRequestParams extends MCP {
  /// Opaque pagination cursor from a previous response.
  String? cursor;

  /// Optional request metadata.
  RequestMetaObject? $meta;

  /// Creates a [PaginatedRequestParams].
  PaginatedRequestParams({this.cursor, this.$meta});

  /// Converts this [PaginatedRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (cursor != null) 'cursor': cursor,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

  /// Builds a [PaginatedRequestParams] from a decoded MCP JSON map.
  factory PaginatedRequestParams.toMCP(Map<String, Object?> map) {
    return PaginatedRequestParams(
      cursor: map['cursor'] as String?,
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
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
class AudioContent extends ContentBlock {
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

/// Plain-text resource content embedded in a content block.
class TextResourceContent extends ContentBlock {
  /// The UTF-8 text of the resource.
  String text;

  /// Creates a [TextResourceContent].
  TextResourceContent({
    required this.text,
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'text');

  /// Converts this [TextResourceContent] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

  /// Builds a [TextResourceContent] from a decoded MCP JSON map.
  factory TextResourceContent.toMCP(Map<String, Object?> map) {
    return TextResourceContent(
      text: map['text'] as String,
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
class ImageContent extends ContentBlock {
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
class TextContent extends ContentBlock {
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
  RequestMetaObject? $meta;
  Reference ref;

  /// The argument's information
  CompleteRequestParamsArgument argument;

  /// Additional, optional context for completions
  CompleteRequestParamsContext? context;

  /// Creates a [CompleteRequestParams].
  CompleteRequestParams({
    this.$meta,
    required this.ref,
    required this.argument,
    this.context,
  });

  /// Converts this [CompleteRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'ref': ref.toMap(),
      'argument': argument.toMap(),
      if (context != null) 'context': context!.toMap(),
    };
  }

  /// Builds a [CompleteRequestParams] from a decoded MCP JSON map.
  factory CompleteRequestParams.toMCP(Map<String, Object?> map) {
    return CompleteRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      ref: PromptReference.toMCP(map['ref'] as Map<String, Object?>),
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

/// The MCP `Reference` schema type.
abstract class Reference extends MCP {}

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
  String type = 'ref/resource_template';

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
  MetaObject? $meta;

  /// An array of completion values.
  CompleteResultCompletion completion;

  /// Creates a [CompleteResult].
  CompleteResult({this.$meta, required this.completion})
      : super({'_meta': $meta, 'completion': completion});

  /// Converts this [CompleteResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {...data, 'completion': completion.toMap(), '_meta': $meta?.toMap()};
  }

  /// Builds a [CompleteResult] from a decoded MCP JSON map.
  factory CompleteResult.toMCP(Map<String, Object?> map) {
    return CompleteResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      completion: CompleteResultCompletion.toMCP(
        map['completion'] as Map<String, Object?>,
      ),
    );
  }
}

/// The MCP `CompleteResultCompletion` schema type.
class CompleteResultCompletion extends MCP {
  List<String> value;
  int? total;
  bool? hasMore;

  /// Creates a [CompleteResultCompletion].
  CompleteResultCompletion({required this.value, this.total, this.hasMore});

  /// Converts this [CompleteResultCompletion] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'value': value,
      if (total != null) 'total': total,
      if (hasMore != null) 'hasMore': hasMore,
    };
  }

  /// Builds a [CompleteResultCompletion] from a decoded MCP JSON map.
  factory CompleteResultCompletion.toMCP(Map<String, Object?> map) {
    return CompleteResultCompletion(
      value: (map['value'] as List<dynamic>).cast<String>(),
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
  String method = 'completion/elicit';

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

/// The parameters for a request to elicit additional information from the user via the client.
class ElicitRequestParams extends MCP {
  String jsonrpc = '2.0';
  String id;
  ElicitResult result;

  /// Creates an [ElicitRequestParams].
  ElicitRequestParams({required this.id, required this.result});

  /// Converts this [ElicitRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds an [ElicitRequestParams] from a decoded MCP JSON map.
  factory ElicitRequestParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestParams(
      id: map['id']?.toString() ?? '-1',
      result: ElicitResult.toMCP(map['result'] as Map<String, Object?>),
    );
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
  TaskMetadata? task;
  RequestMetaObject? $meta;
  String node = "url";

  /// The message to present to the user explaining why the interaction is needed.
  String message;
  String elicitationId;

  /// The URL that the user should navigate to.
  String url;

  /// Creates an [ElicitRequestURLParams].
  ElicitRequestURLParams({
    this.task,
    this.$meta,
    required this.message,
    required this.elicitationId,
    required this.url,
  }) : super(
          id: '',
          result: ElicitResult(action: ActionType.accept, content: {}),
        );

  /// Converts this [ElicitRequestURLParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (task != null) 'task': task!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
      'node': node,
      'message': message,
      'elicitationId': elicitationId,
      'url': url,
    };
  }

  /// Builds an [ElicitRequestURLParams] from a decoded MCP JSON map.
  factory ElicitRequestURLParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestURLParams(
      task: map['task'] != null
          ? TaskMetadata.toMCP(map['task'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      message: map['message'] as String,
      elicitationId: map['elicitationId'] as String,
      url: map['url'] as String,
    );
  }
}

/// The MCP `TaskMetadata` schema type.
class TaskMetadata extends MCP {
  int? ttl;

  /// Creates a [TaskMetadata].
  TaskMetadata({this.ttl});

  /// Converts this [TaskMetadata] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if (ttl != null) 'ttl': ttl};
  }

  /// Builds a [TaskMetadata] from a decoded MCP JSON map.
  factory TaskMetadata.toMCP(Map<String, Object?> map) {
    return TaskMetadata(ttl: map['ttl'] as int?);
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
  TaskMetadata? task;
  RequestMetaObject? $meta;
  String node = "form";

  /// The message to present to the user describing what information is being requested.
  String message;

  /// A restricted subset of JSON Schema.
  ElicitRequestFormParamsSchema? requestedSchema;

  /// Creates an [ElicitRequestFormParams].
  ElicitRequestFormParams({
    this.task,
    this.$meta,
    required this.message,
    this.requestedSchema,
  }) : super(
          id: '',
          result: ElicitResult(action: ActionType.accept, content: {}),
        );

  /// Converts this [ElicitRequestFormParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (task != null) 'task': task!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
      'node': node,
      'message': message,
      if (requestedSchema != null) 'requestedSchema': requestedSchema!.toMap(),
    };
  }

  /// Builds an [ElicitRequestFormParams] from a decoded MCP JSON map.
  factory ElicitRequestFormParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestFormParams(
      task: map['task'] != null
          ? TaskMetadata.toMCP(map['task'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      message: map['message'] as String,
      requestedSchema: ElicitRequestFormParamsSchema.toMCP(
        map['requestedSchema'] as Map<String, Object?>,
      ),
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

/// The MCP `initialize` request sent by the client on first connect.
class InitializeRequest extends MCP {
  /// JSON-RPC version string.
  String jsonrpc = '2.0';

  /// Fixed method name.
  String method = 'initialize';

  /// Request id.
  String id;

  /// Initialization parameters.
  InitializeRequestParams params;

  /// Creates an [InitializeRequest].
  InitializeRequest({required this.id, required this.params});

  /// Converts this [InitializeRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

  /// Builds an [InitializeRequest] from a decoded MCP JSON map.
  factory InitializeRequest.toMCP(Map<String, Object?> map) {
    return InitializeRequest(
      id: map['id']?.toString() ?? '-1',
      params: InitializeRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for an `initialize` request.
class InitializeRequestParams extends MCP {
  /// Optional request metadata.
  RequestMetaObject? $meta;

  /// Highest MCP protocol version the client supports.
  String protocolVersion;

  /// Client-declared capabilities.
  ClientCapabilities capabilities;

  /// Information about this client implementation.
  Implementation clientInfo;

  /// Creates an [InitializeRequestParams].
  InitializeRequestParams({
    this.$meta,
    required this.protocolVersion,
    required this.capabilities,
    required this.clientInfo,
  });

  /// Converts this [InitializeRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '\$meta': $meta!.toMap(),
      'protocolVersion': protocolVersion,
      'capabilities': capabilities.toMap(),
      'clientInfo': clientInfo.toMap(),
    };
  }

  /// Builds an [InitializeRequestParams] from a decoded MCP JSON map.
  factory InitializeRequestParams.toMCP(Map<String, Object?> map) {
    return InitializeRequestParams(
      $meta: map['\$meta'] != null
          ? RequestMetaObject.toMCP(map['\$meta'] as Map<String, Object?>)
          : null,
      protocolVersion: map['protocolVersion'] as String,
      capabilities: ClientCapabilities.toMCP(
        map['capabilities'] as Map<String, Object?>,
      ),
      clientInfo: Implementation.toMCP(
        map['clientInfo'] as Map<String, Object?>,
      ),
    );
  }
}

/// Capabilities declared by the MCP client.
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
  String? version;

  /// Optional website URL.
  String? websiteUrl;

  /// Creates an [Implementation].
  Implementation({
    this.icons,
    required this.name,
    this.description,
    this.title,
    this.version,
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
      if (version != null) 'version': version,
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
      version: map['version'] as String?,
      websiteUrl: map['websiteUrl'] as String?,
    );
  }
}

/// The JSON-RPC response wrapping a successful [InitializeResult].
class InitializeResultResponse extends MCP {
  String jsonrpc = '2.0';
  String id;
  InitializeResult result;

  /// Creates an [InitializeResultResponse].
  InitializeResultResponse({required this.id, required this.result});

  /// Converts this [InitializeResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds an [InitializeResultResponse] from a decoded MCP JSON map.
  factory InitializeResultResponse.toMCP(Map<String, Object?> map) {
    return InitializeResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: InitializeResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The server's response to an `initialize` request.
class InitializeResult extends MapMC<String, Object?> {
  /// Optional metadata.
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  String get protocolVersion => data['protocolVersion'] as String;
  ServerCapabilities get capabilities =>
      ServerCapabilities.toMCP(data['capabilities'] as Map<String, Object?>);
  Implementation get serverInfo =>
      Implementation.toMCP(data['serverInfo'] as Map<String, Object?>);
  String? get instructions => data['instructions'] as String?;

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set protocolVersion(String value) => data['protocolVersion'] = value;
  set capabilities(ServerCapabilities value) =>
      data['capabilities'] = value.toMap();
  set serverInfo(Implementation value) => data['serverInfo'] = value.toMap();
  set instructions(String? value) => data['instructions'] = value;

  /// Creates an [InitializeResult].
  InitializeResult({
    MetaObject? $meta,
    String? protocolVersion = '2025-11-25',
    required ServerCapabilities capabilities,
    required Implementation serverInfo,
    String? instructions,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'protocolVersion': protocolVersion,
          'capabilities': capabilities.toMap(),
          'serverInfo': serverInfo.toMap(),
          if (instructions != null) 'instructions': instructions,
        });

  /// Converts this [InitializeResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds an [InitializeResult] from a decoded MCP JSON map.
  factory InitializeResult.toMCP(Map<String, Object?> map) {
    return InitializeResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      protocolVersion: map['protocolVersion'] as String,
      capabilities: ServerCapabilities.toMCP(
        map['capabilities'] as Map<String, Object?>,
      ),
      serverInfo: Implementation.toMCP(
        map['serverInfo'] as Map<String, Object?>,
      ),
      instructions: map['instructions'] as String?,
    );
  }
}

/// Capabilities declared by the MCP server.
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

/// A JSON-RPC request for the `setLevel` operation.
class SetLevelRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "logging/setLevel";
  SetLevelRequestParams params;

  /// Creates a [SetLevelRequest].
  SetLevelRequest({required this.id, required this.params});

  /// Converts this [SetLevelRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [SetLevelRequest] from a decoded MCP JSON map.
  factory SetLevelRequest.toMCP(Map<String, Object?> map) {
    return SetLevelRequest(
      id: map['id']?.toString() ?? '-1',
      params: SetLevelRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for [SetLevelRequest].
class SetLevelRequestParams extends MCP {
  RequestMetaObject? $meta;
  LoggingLevel level;

  /// Creates a [SetLevelRequestParams].
  SetLevelRequestParams({this.$meta, required this.level});

  /// Converts this [SetLevelRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'level': level.toString(),
    };
  }

  /// Builds a [SetLevelRequestParams] from a decoded MCP JSON map.
  factory SetLevelRequestParams.toMCP(Map<String, Object?> map) {
    return SetLevelRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      level: LoggingLevel.to(map['level'] as String),
    );
  }
}

/// The JSON-RPC response to a [SetLevelRequest].
class SetLevelResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  /// Creates a [SetLevelResultResponse].
  SetLevelResultResponse({required this.id, required this.result});

  /// Converts this [SetLevelResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [SetLevelResultResponse] from a decoded MCP JSON map.
  factory SetLevelResultResponse.toMCP(Map<String, Object?> map) {
    return SetLevelResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// This notification is sent by the client to indicate that it is cancelling a request it previously issued.
class CancelledNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notification/cancelled";
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
  MetaObject? $meta;

  /// The ID of the request to cancel.
  String? requestId;

  /// An optional string describing the reason for the cancellation.
  String? reason;

  /// Creates a [CancelledNotificationParams].
  CancelledNotificationParams({this.$meta, this.requestId, this.reason});

  /// Converts this [CancelledNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      if (requestId != null) 'requestId': requestId,
      if (reason != null) 'reason': reason,
    };
  }

  /// Builds a [CancelledNotificationParams] from a decoded MCP JSON map.
  factory CancelledNotificationParams.toMCP(Map<String, Object?> map) {
    return CancelledNotificationParams(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      requestId: map['requestId'] as String?,
      reason: map['reason'] as String?,
    );
  }
}

/// A JSON-RPC notification for the `initialized` event.
class InitializedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/initialized";
  NotificationParams? params;

  /// Creates an [InitializedNotification].
  InitializedNotification({this.params});

  /// Converts this [InitializedNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds an [InitializedNotification] from a decoded MCP JSON map.
  factory InitializedNotification.toMCP(Map<String, Object?> map) {
    return InitializedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A JSON-RPC notification for the `taskStatus` event.
class TaskStatusNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/tasks/status";
  TaskStatusNotificationParams params;

  /// Creates a [TaskStatusNotification].
  TaskStatusNotification({required this.params});

  /// Converts this [TaskStatusNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds a [TaskStatusNotification] from a decoded MCP JSON map.
  factory TaskStatusNotification.toMCP(Map<String, Object?> map) {
    return TaskStatusNotification(
      params: Task.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// Parameters for [TaskStatusNotification].
abstract class TaskStatusNotificationParams implements MCP {}

/// Data associated with an MCP task.
class Task extends TaskStatusNotificationParams implements CancelTaskResult {
  /// Unique task identifier.
  String taskId;

  /// Current task state.
  TaskStatus status;

  /// Optional human-readable status description.
  String? statusMessage;

  /// ISO 8601 creation timestamp.
  String createdAt;

  /// ISO 8601 last-updated timestamp.
  String lastUpdatedAt;

  /// Retention duration in ms from creation; `null` = unlimited.
  int? ttl;

  /// Suggested polling interval in ms.
  int? pollInterval;

  /// Creates a [Task].
  Task({
    required this.taskId,
    required this.status,
    this.statusMessage,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.ttl,
    this.pollInterval,
  });

  /// Converts this [Task] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'taskId': taskId,
      'status': status.toString(),
      if (statusMessage != null) 'statusMessage': statusMessage,
      'createdAt': createdAt,
      'lastUpdatedAt': lastUpdatedAt,
      if (ttl != null) 'ttl': ttl,
      if (pollInterval != null) 'pollInterval': pollInterval,
    };
  }

  /// Builds a [Task] from a decoded MCP JSON map.
  factory Task.toMCP(Map<String, Object?> map) {
    return Task(
      taskId: map['taskId'] as String,
      status: TaskStatus.to(map['status'] as String),
      statusMessage: map['statusMessage'] as String?,
      createdAt: map['createdAt'] as String,
      lastUpdatedAt: map['lastUpdatedAt'] as String,
      ttl: map['ttl'] as int?,
      pollInterval: map['pollInterval'] as int?,
    );
  }
}

/// Parameters for a `logging/message` notification.
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

/// An out-of-band notification used to inform the receiver of a progress update for a long-running request.
class ProgressNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/progress”;
  ///params: ProgressNotificationParams;

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
}

/// Parameters for a notifications/progress notification.
class ProgressNotificationParams extends MCP {
  ///_meta?: MetaObject;
  ///progressToken: ProgressToken;
  ///progress: number;
  ///total?: number;
  ///message?: string;

  MetaObject? $meta;

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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
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
  /// jsonrpc: “2.0”;
  /// method: “notifications/resources/updated”;
  /// params: ResourceUpdatedNotificationParams;

  MetaObject? $meta;
  String resourceId;
  String? resourceType;
  Map<String, Object?>? data;

  /// Creates a [ResourceUpdatedNotificationParams].
  ResourceUpdatedNotificationParams({
    this.$meta,
    required this.resourceId,
    this.resourceType,
    this.data,
  });

  /// Converts this [ResourceUpdatedNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'resourceId': resourceId,
      if (resourceType != null) 'resourceType': resourceType,
      if (data != null) 'data': data,
    };
  }

  /// Builds a [ResourceUpdatedNotificationParams] from a decoded MCP JSON map.
  factory ResourceUpdatedNotificationParams.toMCP(Map<String, Object?> map) {
    return ResourceUpdatedNotificationParams(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      resourceId: map['resourceId'] as String,
      resourceType: map['resourceType'] as String?,
      data: map['data'] as Map<String, Object?>?,
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

/// A JSON-RPC notification for the `elicitationComplete` event.
class ElicitationCompleteNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/elicitation/complete”;
  ///params: { elicitationId: string };

  String jsonrpc = "2.0";
  String method = "notifications/elicitation/complete";
  ElicitationCompleteNotificationParams params;

  /// Creates an [ElicitationCompleteNotification].
  ElicitationCompleteNotification({required this.params});

  /// Converts this [ElicitationCompleteNotification] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  /// Builds an [ElicitationCompleteNotification] from a decoded MCP JSON map.
  factory ElicitationCompleteNotification.toMCP(Map<String, Object?> map) {
    return ElicitationCompleteNotification(
      params: ElicitationCompleteNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// Parameters for [ElicitationCompleteNotification].
class ElicitationCompleteNotificationParams extends MCP {
  String elicitationId;

  /// Creates an [ElicitationCompleteNotificationParams].
  ElicitationCompleteNotificationParams({required this.elicitationId});

  /// Converts this [ElicitationCompleteNotificationParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'elicitationId': elicitationId};
  }

  /// Builds an [ElicitationCompleteNotificationParams] from a decoded MCP JSON map.
  factory ElicitationCompleteNotificationParams.toMCP(
    Map<String, Object?> map,
  ) {
    return ElicitationCompleteNotificationParams(
      elicitationId: map['elicitationId'] as String,
    );
  }
}

/// A `ping` request used to check liveness of the other party.
class PingRequest extends MCP {
  /// JSON-RPC version string.
  String jsonrpc = "2.0";

  /// Request id.
  String id;

  /// Fixed method name.
  String method = "ping";

  /// Optional request params.
  RequestParams? params;

  /// Creates a [PingRequest].
  PingRequest({required this.id, this.params});

  /// Converts this [PingRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [PingRequest] from a decoded MCP JSON map.
  factory PingRequest.toMCP(Map<String, Object?> map) {
    return PingRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? RequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// Common params for any request.
class RequestParams extends MCP {
  MetaObject? $meta;

  /// Creates a [RequestParams].
  RequestParams({this.$meta});

  /// Converts this [RequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap()};
  }

  /// Builds a [RequestParams] from a decoded MCP JSON map.
  factory RequestParams.toMCP(Map<String, Object?> map) {
    return RequestParams(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
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

/// The JSON-RPC response to a [PingRequest].
class PingResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  /// Creates a [PingResultResponse].
  PingResultResponse({required this.id, required this.result});

  /// Converts this [PingResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [PingResultResponse] from a decoded MCP JSON map.
  factory PingResultResponse.toMCP(Map<String, Object?> map) {
    return PingResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The JSON-RPC response wrapping a successful [CreateTaskResult].
class CreateTaskResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CreateTaskResult result;

  /// Creates a [CreateTaskResultResponse].
  CreateTaskResultResponse({required this.id, required this.result});

  /// Converts this [CreateTaskResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [CreateTaskResultResponse] from a decoded MCP JSON map.
  factory CreateTaskResultResponse.toMCP(Map<String, Object?> map) {
    return CreateTaskResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CreateTaskResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The MCP `CreateTaskResult` schema type.
class CreateTaskResult extends MapMC<String, Object?> {
  Task get task => Task.toMCP(data['task'] as Map<String, Object?>);

  set task(Task value) => data['task'] = value.toMap();

  /// Creates a [CreateTaskResult].
  CreateTaskResult({MetaObject? $meta, required Task task})
      : super(
            {if ($meta != null) '_meta': $meta.toMap(), 'task': task.toMap()});

  /// Converts this [CreateTaskResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [CreateTaskResult] from a decoded MCP JSON map.
  factory CreateTaskResult.toMCP(Map<String, Object?> map) {
    return CreateTaskResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      task: Task.toMCP(map['task'] as Map<String, Object?>),
    );
  }
}

/// The MCP `RelatedTaskMetadata` schema type.
class RelatedTaskMetadata extends MCP {
  String taskId;
  String? relationshipType;

  /// Creates a [RelatedTaskMetadata].
  RelatedTaskMetadata({required this.taskId, this.relationshipType});

  /// Converts this [RelatedTaskMetadata] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'taskId': taskId,
      if (relationshipType != null) 'relationshipType': relationshipType,
    };
  }

  /// Builds a [RelatedTaskMetadata] from a decoded MCP JSON map.
  factory RelatedTaskMetadata.toMCP(Map<String, Object?> map) {
    return RelatedTaskMetadata(
      taskId: map['taskId'] as String,
      relationshipType: map['relationshipType'] as String?,
    );
  }
}

/// A JSON-RPC request for the `getTask` operation.
class GetTaskRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/get";
  GetTaskRequestParams params;

  /// Creates a [GetTaskRequest].
  GetTaskRequest({required this.id, required this.params});

  /// Converts this [GetTaskRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [GetTaskRequest] from a decoded MCP JSON map.
  factory GetTaskRequest.toMCP(Map<String, Object?> map) {
    return GetTaskRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// Parameters for [GetTaskRequest].
class GetTaskRequestParams extends MCP {
  String taskId;

  /// Creates a [GetTaskRequestParams].
  GetTaskRequestParams({required this.taskId});

  /// Converts this [GetTaskRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'taskId': taskId};
  }

  /// Builds a [GetTaskRequestParams] from a decoded MCP JSON map.
  factory GetTaskRequestParams.toMCP(Map<String, Object?> map) {
    return GetTaskRequestParams(taskId: map['taskId'] as String);
  }
}

/// A JSON-RPC request for the `getTaskPayload` operation.
class GetTaskPayloadRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/result";
  GetTaskRequestParams params;

  /// Creates a [GetTaskPayloadRequest].
  GetTaskPayloadRequest({required this.id, required this.params});

  /// Converts this [GetTaskPayloadRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [GetTaskPayloadRequest] from a decoded MCP JSON map.
  factory GetTaskPayloadRequest.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// The JSON-RPC response wrapping a successful [GetTaskPayloadResult].
class GetTaskPayloadResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  GetTaskPayloadResult result;

  /// Creates a [GetTaskPayloadResultResponse].
  GetTaskPayloadResultResponse({required this.id, required this.result});

  /// Converts this [GetTaskPayloadResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [GetTaskPayloadResultResponse] from a decoded MCP JSON map.
  factory GetTaskPayloadResultResponse.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: GetTaskPayloadResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result payload for a successful [GetTaskPayloadRequest].
class GetTaskPayloadResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();

  /// Creates a [GetTaskPayloadResult].
  GetTaskPayloadResult({
    MetaObject? $meta,
    Map<String, Object?>? additionalData,
  }) : super({if ($meta != null) '_meta': $meta.toMap(), ...?additionalData});

  /// Converts this [GetTaskPayloadResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return data;
  }

  /// Builds a [GetTaskPayloadResult] from a decoded MCP JSON map.
  factory GetTaskPayloadResult.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      additionalData: Map.from(map)..remove('_meta'),
    );
  }
}

/// A JSON-RPC request for the `listTasks` operation.
class ListTasksRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/list";
  PaginatedRequestParams? params;

  /// Creates a [ListTasksRequest].
  ListTasksRequest({required this.id, this.params});

  /// Converts this [ListTasksRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  /// Builds a [ListTasksRequest] from a decoded MCP JSON map.
  factory ListTasksRequest.toMCP(Map<String, Object?> map) {
    return ListTasksRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

/// The JSON-RPC response wrapping a successful [ListTasksResult].
class ListTasksResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListTasksResult result;

  /// Creates a [ListTasksResultResponse].
  ListTasksResultResponse({required this.id, required this.result});

  /// Converts this [ListTasksResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [ListTasksResultResponse] from a decoded MCP JSON map.
  factory ListTasksResultResponse.toMCP(Map<String, Object?> map) {
    return ListTasksResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListTasksResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result payload for a successful [ListTasksRequest].
class ListTasksResult extends MapMC<String, Object?> {
  MetaObject? $meta;
  String? nextCursor;
  List<Task> tasks;

  /// Creates a [ListTasksResult].
  ListTasksResult({
    this.$meta,
    this.nextCursor,
    required this.tasks,
    Map<String, Object?>? additionalData,
  }) : super(additionalData ?? {});

  /// Converts this [ListTasksResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.data,
      if ($meta != null) '_meta': $meta!.toMap(),
      if (nextCursor != null) 'nextCursor': nextCursor,
      'tasks': tasks.map((e) => e.toMap()).toList(),
    };
  }

  /// Builds a [ListTasksResult] from a decoded MCP JSON map.
  factory ListTasksResult.toMCP(Map<String, Object?> map) {
    return ListTasksResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      nextCursor: map['nextCursor'] as String?,
      tasks: (map['tasks'] as List<dynamic>)
          .map((e) => Task.toMCP(e as Map<String, Object?>))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) => key == '_meta' || key == 'nextCursor' || key == 'tasks',
        ),
    );
  }
}

/// A JSON-RPC request for the `cancelTask` operation.
class CancelTaskRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/cancel";
  GetTaskRequestParams params;

  /// Creates a [CancelTaskRequest].
  CancelTaskRequest({required this.id, required this.params});

  /// Converts this [CancelTaskRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [CancelTaskRequest] from a decoded MCP JSON map.
  factory CancelTaskRequest.toMCP(Map<String, Object?> map) {
    return CancelTaskRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

/// The JSON-RPC response wrapping a successful [CancelTaskResult].
class CancelTaskResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CancelTaskResult result;

  /// Creates a [CancelTaskResultResponse].
  CancelTaskResultResponse({required this.id, required this.result});

  /// Converts this [CancelTaskResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [CancelTaskResultResponse] from a decoded MCP JSON map.
  factory CancelTaskResultResponse.toMCP(Map<String, Object?> map) {
    return CancelTaskResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CancelTaskResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result payload for a successful [CancelTaskRequest].
abstract class CancelTaskResult implements MCP {
  /// Builds a [CancelTaskResult] from a decoded MCP JSON map.
  factory CancelTaskResult.toMCP(Map<String, Object?> map) {
    return Task(
      taskId: map['taskId'] as String,
      status: TaskStatus.to(map['status'] as String),
      createdAt: map['createdAt'] as String,
      lastUpdatedAt: map['lastUpdatedAt'] as String,
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
class GetPromptRequestParams extends MCP {
  RequestMetaObject? $meta;
  InputResponses? inputResponses;
  String? requestState;

  /// The name of the prompt or prompt template.
  String name;

  /// Arguments to use for templating the prompt.
  Map<String, String>? arguments;

  /// Creates a [GetPromptRequestParams].
  GetPromptRequestParams({
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.name,
    this.arguments,
  });

  /// Converts this [GetPromptRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      if (inputResponses != null) 'inputResponses': inputResponses!.toMap(),
      if (requestState != null) 'requestState': requestState,
      'name': name,
      if (arguments != null) 'arguments': arguments,
    };
  }

  /// Builds a [GetPromptRequestParams] from a decoded MCP JSON map.
  factory GetPromptRequestParams.toMCP(Map<String, Object?> map) {
    return GetPromptRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
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
  GetPromptResult result;

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
      result: GetPromptResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a prompts/get request.
class GetPromptResult extends MapMC<String, Object?> {
  MetaObject? $meta;

  /// An optional description for the prompt.
  String? description;
  List<PromptMessage> messages;

  /// Creates a [GetPromptResult].
  GetPromptResult({
    this.$meta,
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
      if (description != null) 'description': description,
      'messages': messages.map((e) => e.toMap()).toList(),
    };
  }

  /// Builds a [GetPromptResult] from a decoded MCP JSON map.
  factory GetPromptResult.toMCP(Map<String, Object?> map) {
    return GetPromptResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      description: map['description']?.toString(),
      messages: (map['messages'] as List<Map<String, Object?>>)
          .map((e) => PromptMessage.toMCP(e))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' || key == 'description' || key == 'messages',
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
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Prompt> get prompts => (data['prompts'] as List<dynamic>)
      .map((e) => Prompt.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set prompts(List<Prompt> value) =>
      data['prompts'] = value.map((e) => e.toMap()).toList();

  /// Creates a [ListPromptsResult].
  ListPromptsResult({
    MetaObject? $meta,
    String? nextCursor,
    required List<Prompt> prompts,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          if (nextCursor != null) 'nextCursor': nextCursor,
          'prompts': prompts.map((e) => e.toMap()).toList(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      nextCursor: map['nextCursor'] as String?,
      prompts: (map['prompts'] as List<dynamic>)
          .map((e) => Prompt.toMCP(e as Map<String, Object?>))
          .toList(),
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
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Resource> get resources => (data['resources'] as List<dynamic>)
      .map((e) => Resource.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resources(List<Resource> value) =>
      data['resources'] = value.map((e) => e.toMap()).toList();

  /// Creates a [ListResourcesResult].
  ListResourcesResult({
    MetaObject? $meta,
    String? nextCursor,
    required List<Resource> resources,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          if (nextCursor != null) 'nextCursor': nextCursor,
          'resources': resources.map((e) => e.toMap()).toList(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      nextCursor: map['nextCursor'] as String?,
      resources: (map['resources'] as List<dynamic>)
          .map((e) => Resource.toMCP(e as Map<String, Object?>))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' || key == 'nextCursor' || key == 'resources',
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
class ReadResourceRequestParams extends MCP {
  RequestMetaObject? $meta;
  InputResponses? inputResponses;
  String? requestState;

  /// The URI of the resource.
  String uri;

  /// Creates a [ReadResourceRequestParams].
  ReadResourceRequestParams({
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.uri,
  });

  /// Converts this [ReadResourceRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      if (inputResponses != null) 'inputResponses': inputResponses!.toMap(),
      if (requestState != null) 'requestState': requestState,
      'uri': uri,
    };
  }

  /// Builds a [ReadResourceRequestParams] from a decoded MCP JSON map.
  factory ReadResourceRequestParams.toMCP(Map<String, Object?> map) {
    return ReadResourceRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
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
  ReadResourceResult result;

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
      result: ReadResourceResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The result returned by the server for a resources/read request.
class ReadResourceResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  List<ResourceContents> get contents => (data['contents'] as List<dynamic>)
      .map((e) => ResourceContents.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set contents(List<ResourceContents> value) =>
      data['contents'] = value.map((e) => e.toMap()).toList();

  /// Creates a [ReadResourceResult].
  ReadResourceResult({
    MetaObject? $meta,
    required List<ResourceContents> contents,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'contents': contents.map((e) => e.toMap()).toList(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      contents: (map['contents'] as List<dynamic>)
          .map((e) => ResourceContents.toMCP(e as Map<String, Object?>))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) => key == '_meta' || key == 'contents',
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
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<ResourceTemplate> get resourceTemplates =>
      (data['resourceTemplates'] as List<dynamic>)
          .map((e) => ResourceTemplate.toMCP(e as Map<String, Object?>))
          .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resourceTemplates(List<ResourceTemplate> value) =>
      data['resourceTemplates'] = value.map((e) => e.toMap()).toList();

  /// Creates a [ListResourceTemplatesResult].
  ListResourceTemplatesResult({
    MetaObject? $meta,
    String? nextCursor,
    required List<ResourceTemplate> resourceTemplates,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          if (nextCursor != null) 'nextCursor': nextCursor,
          'resourceTemplates': resourceTemplates.map((e) => e.toMap()).toList(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      nextCursor: map['nextCursor'] as String?,
      resourceTemplates: (map['resourceTemplates'] as List<dynamic>)
          .map((e) => ResourceTemplate.toMCP(e as Map<String, Object?>))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
              key == 'nextCursor' ||
              key == 'resourceTemplates',
        ),
    );
  }
}

/// Parameters for [SubscribeRequest].
class SubscribeRequestParams extends MCP {
  RequestMetaObject? $meta;
  String uri;

  /// Creates a [SubscribeRequestParams].
  SubscribeRequestParams({this.$meta, required this.uri});

  /// Converts this [SubscribeRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap(), 'uri': uri};
  }

  /// Builds a [SubscribeRequestParams] from a decoded MCP JSON map.
  factory SubscribeRequestParams.toMCP(Map<String, Object?> map) {
    return SubscribeRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      uri: map['uri'] as String,
    );
  }
}

/// A JSON-RPC request for the `subscribe` operation.
class SubscribeRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/subscribe";
  SubscribeRequestParams params;

  /// Creates a [SubscribeRequest].
  SubscribeRequest({required this.id, required this.params});

  /// Converts this [SubscribeRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  /// Builds a [SubscribeRequest] from a decoded MCP JSON map.
  factory SubscribeRequest.toMCP(Map<String, Object?> map) {
    return SubscribeRequest(
      id: map['id']?.toString() ?? '-1',
      params: SubscribeRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

/// The JSON-RPC response to a [SubscribeRequest].
class SubscribeResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  /// Creates a [SubscribeResultResponse].
  SubscribeResultResponse({required this.id, required this.result});

  /// Converts this [SubscribeResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds a [SubscribeResultResponse] from a decoded MCP JSON map.
  factory SubscribeResultResponse.toMCP(Map<String, Object?> map) {
    return SubscribeResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

/// The MCP `UnsubscribeRequestParams` schema type.
class UnsubscribeRequestParams extends MCP {
  RequestMetaObject? $meta;
  String uri;

  /// Creates an [UnsubscribeRequestParams].
  UnsubscribeRequestParams({this.$meta, required this.uri});

  /// Converts this [UnsubscribeRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap(), 'uri': uri};
  }

  /// Builds an [UnsubscribeRequestParams] from a decoded MCP JSON map.
  factory UnsubscribeRequestParams.toMCP(Map<String, Object?> map) {
    return UnsubscribeRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      uri: map['uri'] as String,
    );
  }
}

/// The MCP `UnsubscribeResultResponse` schema type.
class UnsubscribeResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  /// Creates an [UnsubscribeResultResponse].
  UnsubscribeResultResponse({required this.id, required this.result});

  /// Converts this [UnsubscribeResultResponse] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  /// Builds an [UnsubscribeResultResponse] from a decoded MCP JSON map.
  factory UnsubscribeResultResponse.toMCP(Map<String, Object?> map) {
    return UnsubscribeResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

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

/// The result returned by the client for a roots/list request.
class ListRootsResult extends MCP {
  List<Root> roots;

  /// Creates a [ListRootsResult].
  ListRootsResult({required this.roots});

  /// Converts this [ListRootsResult] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'roots': roots.map((e) => e.toMap()).toList()};
  }

  /// Builds a [ListRootsResult] from a decoded MCP JSON map.
  factory ListRootsResult.toMCP(Map<String, Object?> map) {
    return ListRootsResult(
      roots: (map['roots'] as List<dynamic>)
          .map((e) => Root.toMCP(e as Map<String, Object?>))
          .toList(),
    );
  }
}

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

/// The server's preferences for model selection, requested of the client during sampling.
class ModelPreferences extends MCP {
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

  /// Builds a [ModelPreferences] from a decoded MCP JSON map.
  factory ModelPreferences.toMCP(Map<String, Object?> map) {
    return ModelPreferences(
      hints: (map['hints'] as List<dynamic>?)
          ?.map((e) => ModelHint.toMCP(e as Map<String, Object?>))
          .toList(),
      costPriority: map['costPriority'] as num?,
      speedPriority: map['speedPriority'] as num?,
      intelligencePriority: map['intelligencePriority'] as num?,
    );
  }
}

/// Describes a message issued to or received from an LLM API.
class SamplingMessage extends MCP {
  Role role;
  List<ContentBlock> content;
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

  /// Builds a [SamplingMessage] from a decoded MCP JSON map.
  factory SamplingMessage.toMCP(Map<String, Object?> map) {
    return SamplingMessage(
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

/// The result of a tool use, provided by the user back to the assistant.
class ToolResultContent extends ContentBlock {
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

/// A request from the assistant to call a tool.
class ToolUseContent extends ContentBlock {
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
class ToolExecution extends MCP {
  /// Whether this tool supports task-augmented execution.
  ///
  /// One of `"forbidden"` (default), `"optional"`, or `"required"`.
  String? taskSupport;

  /// Creates a [ToolExecution].
  ToolExecution({this.taskSupport});

  /// Converts this [ToolExecution] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {if (taskSupport != null) 'taskSupport': taskSupport};
  }

  /// Builds a [ToolExecution] from a decoded MCP JSON map.
  factory ToolExecution.toMCP(Map<String, Object?> map) {
    return ToolExecution(taskSupport: map['taskSupport'] as String?);
  }
}

/// JSON Schema object used for a tool's [inputSchema] or [outputSchema].
class ToolSchema extends MCP {
  /// Optional `$schema` URI.
  String? $schema;

  /// Root type; always `"object"`.
  String type = 'object';

  /// Property definitions.
  Map<String, Object?>? properties;

  /// Required property names.
  List<String>? required;

  /// Creates a [ToolSchema].
  ToolSchema({
    this.$schema,
    this.properties,
    this.required,
    this.type = 'object',
  });

  /// Converts this [ToolSchema] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
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

  /// Execution-related properties.
  ToolExecution? execution;

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
    this.execution,
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
      if (execution != null) 'execution': execution!.toMap(),
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
      execution: map['execution'] != null
          ? ToolExecution.toMCP(map['execution'] as Map<String, Object?>)
          : null,
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

/// Parameters for a sampling/createMessage request.
class CreateMessageRequestParams extends MCP {
  List<SamplingMessage> messages;

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

  /// Builds a [CreateMessageRequestParams] from a decoded MCP JSON map.
  factory CreateMessageRequestParams.toMCP(Map<String, Object?> map) {
    return CreateMessageRequestParams(
      messages: (map['messages'] as List<dynamic>)
          .map((e) => SamplingMessage.toMCP(e as Map<String, Object?>))
          .toList(),
      modelPreferences: map['modelPreferences'] != null
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
          ? ToolChoice.toMCP(map['toolChoice'] as Map<String, Object?>)
          : null,
    );
  }
}

/// A request from the server to sample an LLM via the client.
class CreateMessageRequest extends MCP {
  String method = "sampling/createMessage";
  CreateMessageRequestParams params;

  /// Creates a [CreateMessageRequest].
  CreateMessageRequest({required this.params});

  /// Converts this [CreateMessageRequest] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {'method': method, 'params': params.toMap()};
  }

  /// Builds a [CreateMessageRequest] from a decoded MCP JSON map.
  factory CreateMessageRequest.toMCP(Map<String, Object?> map) {
    return CreateMessageRequest(
      params: CreateMessageRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

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
class CallToolRequestParams extends MCP {
  /// Optional task-augmentation metadata.
  TaskMetadata? task;

  /// Optional request metadata.
  RequestMetaObject? $meta;

  /// Optional input responses (for multi-turn flows).
  InputResponses? inputResponses;

  /// Optional request state token.
  String? requestState;

  /// Name of the tool to invoke.
  String name;

  /// Tool call arguments.
  Map<String, Object?>? arguments;

  /// Creates a [CallToolRequestParams].
  CallToolRequestParams({
    this.task,
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.name,
    this.arguments,
  });

  /// Converts this [CallToolRequestParams] into a JSON-compatible map.
  @override
  Map<String, Object?> toMap() {
    return {
      if (task != null) 'task': task!.toMap(),
      if ($meta != null) '_meta': $meta!.toMap(),
      if (inputResponses != null) 'inputResponses': inputResponses!.toMap(),
      if (requestState != null) 'requestState': requestState,
      'name': name,
      if (arguments != null) 'arguments': arguments,
    };
  }

  /// Builds a [CallToolRequestParams] from a decoded MCP JSON map.
  factory CallToolRequestParams.toMCP(Map<String, Object?> map) {
    return CallToolRequestParams(
      task: map['task'] != null
          ? TaskMetadata.toMCP(map['task'] as Map<String, Object?>)
          : null,
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
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
class CallToolResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  List<ContentBlock> get content => (data['content'] as List<dynamic>)
      .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
      .toList();
  Map<String, Object?>? get structuredContent =>
      data['structuredContent'] as Map<String, Object?>?;

  /// Whether the tool call ended in an error.
  bool? get isError => data['isError'] as bool?;

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set content(List<ContentBlock> value) =>
      data['content'] = value.map((e) => e.toMap()).toList();
  set structuredContent(Map<String, Object?>? value) =>
      data['structuredContent'] = value;
  set isError(bool? value) => data['isError'] = value;

  /// Creates a [CallToolResult].
  CallToolResult({
    MetaObject? $meta,
    required List<ContentBlock> content,
    Map<String, Object?>? structuredContent,
    bool? isError,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      content: ((map['content'] ?? []) as List<dynamic>)
          .map((e) => ContentBlock.toMCP(e as Map<String, Object?>))
          .toList(),
      structuredContent: map['structuredContent'] as Map<String, Object?>?,
      isError: map['isError'] as bool?,
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) =>
              key == '_meta' ||
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
  CallToolResult result;

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
      result: CallToolResult.toMCP(map['result'] as Map<String, Object?>),
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
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;

  /// An opaque token representing the pagination position after the last returned result.
  String? get nextCursor => data['nextCursor'] as String?;
  List<Tool> get tools => (data['tools'] as List<dynamic>)
      .map((e) => Tool.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set tools(List<Tool> value) =>
      data['tools'] = value.map((e) => e.toMap()).toList();

  /// Creates a [ListToolsResult].
  ListToolsResult({
    MetaObject? $meta,
    String? nextCursor,
    required List<Tool> tools,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          if (nextCursor != null) 'nextCursor': nextCursor,
          'tools': tools.map((e) => e.toMap()).toList(),
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
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      nextCursor: map['nextCursor'] as String?,
      tools: (map['tools'] as List<dynamic>)
          .map((e) => Tool.toMCP(e as Map<String, Object?>))
          .toList(),
      additionalData: Map.from(map)
        ..removeWhere(
          (key, _) => key == '_meta' || key == 'nextCursor' || key == 'tools',
        ),
    );
  }
}
