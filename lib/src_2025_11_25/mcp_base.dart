import 'package:mcp_models/mcp_models_2025_11_25.dart';
import 'package:mcp_models/src_2025_11_25/map_model.dart';

/// Base interface for all MCP model objects.
///
/// Every concrete MCP type must implement [toMap] to produce a
/// JSON-serialisable `Map<String, Object?>`.
abstract interface class MCP {
  Map<String, Object?> toMap();
}

/// A [MapModel] that also satisfies [MCP].
///
/// Use as the base class when the model _is_ the underlying map
/// (e.g. [InitializeResult], [ClientCapabilities]).
abstract class MapMC<K, V> extends MapModel<K, V> implements MCP {
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

  JSONRPCErrorResponse({this.jsonrpc = '2.0', this.id, required this.error});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'error': error.toMap()};
  }

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

  Error({required this.code, required this.message, this.data});

  @override
  Map<String, Object?> toMap() {
    return {'code': code, 'message': message, 'data': data};
  }

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

  JSONRPCNotification({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
  });

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params};
  }

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

  JSONRPCResultResponse({this.jsonrpc = '2.0', this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

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

  Result({this.meta, this.unknown});

  @override
  Map<String, Object?> toMap() {
    return {'meta': meta?.toMap(), ...?unknown};
  }

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
  MetaObject(this._data);

  @override
  Map<String, Object?> toMap() {
    return _data;
  }

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

  JSONRPCRequest({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
    required this.id,
  });

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params, 'id': id};
  }

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

  Annotations({this.priority, this.lastModified, this.audience});

  @override
  Map<String, Object?> toMap() {
    return {
      if (priority != null) 'priority': priority,
      if (lastModified != null) 'lastModified': lastModified,
      if (audience != null)
        'audience': audience!.map((e) => e.toString()).toList(),
    };
  }

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
  EmptyResult() : super(meta: null, unknown: null);
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

  Icon({required this.src, this.mimeType, this.sizes, this.theme});
  @override
  Map<String, Object?> toMap() {
    return {
      'src': src,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizes != null) 'sizes': sizes,
      if (theme != null) 'theme': theme!.name,
    };
  }

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

  NotificationParams({this.$meta});

  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap()};
  }

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
  RequestMetaObject({String? progressToken})
      : super({'progressToken': progressToken});

  String? get progressToken => data['progressToken'] as String?;

  set progressToken(String? value) => data['progressToken'] = value;

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

  PaginatedRequestParams({this.cursor, this.$meta});

  @override
  Map<String, Object?> toMap() {
    return {
      if (cursor != null) 'cursor': cursor,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

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
  InternalError({required super.message, super.data}) : super(code: -32603);
}

/// JSON-RPC invalid params error (code -32602).
class InvalidParamsError extends Error {
  InvalidParamsError({required super.message, super.data})
      : super(code: -32602);
}

/// JSON-RPC invalid request error (code -32600).
class InvalidRequestError extends Error {
  InvalidRequestError({required super.message, super.data})
      : super(code: -32600);
}

/// JSON-RPC method not found error (code -32601).
class MethodNotFoundError extends Error {
  MethodNotFoundError({required super.message, super.data})
      : super(code: -32601);
}

/// JSON-RPC parse error (code -32700).
class ParseError extends Error {
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

  ContentBlock({
    required this.type,
    required this.data,
    required this.mimeType,
    this.annotations,
    this.$meta,
  });

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
  AudioContent({
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'audio');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap()};
  }

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

  @override
  Map<String, Object?> toMap() {
    return {
      'uri': uri,
      if (mimeType != null) 'mimeType': mimeType,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

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
  BlobResourceContents({
    required this.blob,
    required super.uri,
    super.mimeType,
    super.$meta,
  });

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'blob': blob};
  }

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

  TextResourceContent({
    required this.text,
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'text');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

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

  EmbeddedResource({
    required this.resource,
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'resource');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'resource': resource.toMap()};
  }

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
  ImageContent({
    required super.data,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'image');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap()};
  }

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

  TextContent({
    required this.text,
    required super.mimeType,
    super.annotations,
    super.$meta,
  }) : super(type: 'text', data: '');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

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

  TextResourceContents({
    required this.text,
    required super.uri,
    super.mimeType,
    super.$meta,
  });

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'text': text};
  }

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

class CompleteRequestParamsArgument extends MCP {
  String name;
  String value;

  CompleteRequestParamsArgument({required this.name, required this.value});

  @override
  Map<String, Object?> toMap() {
    return {'name': name, 'value': value};
  }

  factory CompleteRequestParamsArgument.toMCP(Map<String, Object?> map) {
    return CompleteRequestParamsArgument(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }
}

class CompleteRequestParamsContext extends MCP {
  Map<String, String>? arguments;

  CompleteRequestParamsContext({this.arguments});

  @override
  Map<String, Object?> toMap() {
    return {'arguments': arguments};
  }

  factory CompleteRequestParamsContext.toMCP(Map<String, Object?> map) {
    return CompleteRequestParamsContext(
      arguments:
          (map['arguments'] as Map<String, dynamic>?)?.cast<String, String>(),
    );
  }
}

class CompleteRequestParams extends MCP {
  RequestMetaObject? $meta;
  Reference ref;
  CompleteRequestParamsArgument argument;
  CompleteRequestParamsContext? context;

  CompleteRequestParams({
    this.$meta,
    required this.ref,
    required this.argument,
    this.context,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'ref': ref.toMap(),
      'argument': argument.toMap(),
      if (context != null) 'context': context!.toMap(),
    };
  }

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

abstract class Reference extends MCP {}

class PromptReference extends Reference {
  String name;
  String? title;
  String type = 'ref/prompt';

  PromptReference({required this.name, this.title});
  @override
  Map<String, Object?> toMap() {
    return {'name': name, if (title != null) 'title': title, 'type': type};
  }

  factory PromptReference.toMCP(Map<String, Object?> map) {
    return PromptReference(
      name: map['name'] as String,
      title: map['title'] as String?,
    );
  }
}

class ResourceTemplateReference extends Reference {
  String type = 'ref/resource_template';
  String uri;

  ResourceTemplateReference({required this.uri});

  @override
  Map<String, Object?> toMap() {
    return {'type': type, 'uri': uri};
  }

  factory ResourceTemplateReference.toMCP(Map<String, Object?> map) {
    return ResourceTemplateReference(uri: map['uri'] as String);
  }
}

class CompleteRequest extends MCP {
  String id;
  CompleteRequestParams params;
  String jsonrpc = '2.0';
  String method = 'completion/complete';

  CompleteRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

  factory CompleteRequest.toMCP(Map<String, Object?> map) {
    return CompleteRequest(
      id: map['id']?.toString() ?? '-1',
      params: CompleteRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class CompleteResultResponse extends MCP {
  String jsonrpc = '2.0';
  String id;
  CompleteResult result;

  CompleteResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory CompleteResultResponse.toMCP(Map<String, Object?> map) {
    return CompleteResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CompleteResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class CompleteResult extends MapMC<String, Object?> {
  MetaObject? $meta;
  CompleteResultCompletion completion;
  CompleteResult({this.$meta, required this.completion})
      : super({'_meta': $meta, 'completion': completion});

  @override
  Map<String, Object?> toMap() {
    return {...data, 'completion': completion.toMap(), '_meta': $meta?.toMap()};
  }

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

class CompleteResultCompletion extends MCP {
  List<String> value;
  int? total;
  bool? hasMore;

  CompleteResultCompletion({required this.value, this.total, this.hasMore});

  @override
  Map<String, Object?> toMap() {
    return {
      'value': value,
      if (total != null) 'total': total,
      if (hasMore != null) 'hasMore': hasMore,
    };
  }

  factory CompleteResultCompletion.toMCP(Map<String, Object?> map) {
    return CompleteResultCompletion(
      value: (map['value'] as List<dynamic>).cast<String>(),
      total: map['total'] as int?,
      hasMore: map['hasMore'] as bool?,
    );
  }
}

class ElicitRequest extends MCP {
  String id;
  ElicitRequestParams params;
  String jsonrpc = '2.0';
  String method = 'completion/elicit';

  ElicitRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

  factory ElicitRequest.toMCP(Map<String, Object?> map) {
    return ElicitRequest(
      id: map['id']?.toString() ?? '-1',
      params: ElicitRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

class ElicitRequestParams extends MCP {
  String jsonrpc = '2.0';
  String id;
  ElicitResult result;

  ElicitRequestParams({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ElicitRequestParams.toMCP(Map<String, Object?> map) {
    return ElicitRequestParams(
      id: map['id']?.toString() ?? '-1',
      result: ElicitResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ElicitResult extends MapMC<String, Object?> {
  MetaObject? $meta;
  ActionType action;
  Map<String, Object?> content;

  ElicitResult({this.$meta, required this.action, required this.content})
      : super({});

  @override
  Map<String, Object?> toMap() {
    return {
      ...data,
      'action': action.toString(),
      '_meta': $meta?.toMap(),
      'content': content,
    };
  }

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

class Schema<T> extends MCP {
  String type;
  String? title;
  String? description;
  T? defaultValue;

  Schema({required this.type, this.title, this.description, this.defaultValue});

  @override
  Map<String, Object?> toMap() {
    return {
      'type': type,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
  }

  factory Schema.toMCP(Map<String, Object?> map) {
    return Schema(
      type: map['type'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      defaultValue: map['default'] as T?,
    );
  }
}

class BooleanSchema extends PrimitiveSchemaDefinition<bool> {
  @override
  String get type => 'boolean';

  BooleanSchema({super.title, super.description, super.defaultValue})
      : super(type: 'boolean');

  factory BooleanSchema.toMCP(Map<String, Object?> map) {
    return BooleanSchema(
      title: map['title'] as String?,
      description: map['description'] as String?,
      defaultValue: map['default'] as bool?,
    );
  }
}

class ElicitRequestURLParams extends ElicitRequestParams {
  TaskMetadata? task;
  RequestMetaObject? $meta;
  String node = "url";
  String message;
  String elicitationId;
  String url;

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

class TaskMetadata extends MCP {
  int? ttl;

  TaskMetadata({this.ttl});

  @override
  Map<String, Object?> toMap() {
    return {if (ttl != null) 'ttl': ttl};
  }

  factory TaskMetadata.toMCP(Map<String, Object?> map) {
    return TaskMetadata(ttl: map['ttl'] as int?);
  }
}

abstract class EnumSchema<T> extends PrimitiveSchemaDefinition<T> {
  EnumSchema({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

abstract class SingleSelectEnumSchema<T> extends EnumSchema<T> {
  SingleSelectEnumSchema({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

class UntitledSingleSelectEnumSchema extends SingleSelectEnumSchema<String> {
  List<String> $enum;

  UntitledSingleSelectEnumSchema({
    required this.$enum,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');
  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'enum': $enum};
  }

  factory UntitledSingleSelectEnumSchema.toMCP(Map<String, Object?> map) {
    return UntitledSingleSelectEnumSchema(
      $enum: (map['enum'] as List<dynamic>).cast<String>(),
      defaultValue: map['default'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
    );
  }
}

class TitledSingleSelectEnumSchema extends SingleSelectEnumSchema<String> {
  List<({String $const, String title})> oneOf;

  TitledSingleSelectEnumSchema({
    required this.oneOf,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'oneOf': oneOf.map((e) => {'const': e.$const, 'title': e.title}).toList(),
    };
  }

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

abstract class MultiSelectEnumSchema<T> extends EnumSchema<List<T>> {
  MultiSelectEnumSchema({super.title, super.description, super.defaultValue})
      : super(type: 'array');
}

class UntitledMultiSelectEnumSchema extends MultiSelectEnumSchema<String> {
  int? minItems;
  int? maxItems;
  List<String> items;

  UntitledMultiSelectEnumSchema({
    required this.items,
    this.minItems,
    this.maxItems,
    super.defaultValue,
    super.title,
    super.description,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      'items': {'type': 'string', 'enum': items},
    };
  }

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

class TitledMultiSelectEnumSchema extends UntitledMultiSelectEnumSchema {
  TitledMultiSelectEnumSchema({
    required super.items,
    super.minItems,
    super.maxItems,
    super.defaultValue,
    super.title,
    super.description,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      'items': {'type': 'string', 'anyOf': items},
    };
  }

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

class LegacyTitledEnumSchema extends EnumSchema<String> {
  List<String> $enum;
  List<String>? enumNames;

  LegacyTitledEnumSchema({
    required this.$enum,
    this.enumNames,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'enum': $enum, 'enumNames': enumNames};
  }

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

class ElicitRequestFormParams extends ElicitRequestParams {
  TaskMetadata? task;
  RequestMetaObject? $meta;
  String node = "form";
  String message;
  ElicitRequestFormParamsSchema? requestedSchema;

  ElicitRequestFormParams({
    this.task,
    this.$meta,
    required this.message,
    this.requestedSchema,
  }) : super(
          id: '',
          result: ElicitResult(action: ActionType.accept, content: {}),
        );

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

class ElicitRequestFormParamsSchema extends MCP {
  String? $schema;
  String type = 'object';
  Map<String, PrimitiveSchemaDefinition> properties = {};
  List<String>? required;

  ElicitRequestFormParamsSchema({
    this.$schema,
    this.required,
    this.type = 'object',
    required this.properties,
  });

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

abstract class PrimitiveSchemaDefinition<T> extends Schema<T> {
  PrimitiveSchemaDefinition({
    required super.type,
    super.title,
    super.description,
    super.defaultValue,
  });
}

class StringSchema extends PrimitiveSchemaDefinition<String> {
  int? minLength;
  int? maxLength;
  StringFormat? format;

  StringSchema({
    this.minLength,
    this.maxLength,
    this.format,
    super.defaultValue,
    super.title,
    super.description,
  }) : super(type: 'string');

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (format != null) 'format': format!.value,
    };
  }

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

class NumberSchema extends PrimitiveSchemaDefinition<num> {
  num? minimum;
  num? maximum;

  NumberSchema({
    super.type = 'number',
    this.minimum,
    this.maximum,
    super.defaultValue,
    super.title,
    super.description,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
    };
  }

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

  InitializeRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'id': id,
      'params': params.toMap(),
    };
  }

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

  InitializeRequestParams({
    this.$meta,
    required this.protocolVersion,
    required this.capabilities,
    required this.clientInfo,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '\$meta': $meta!.toMap(),
      'protocolVersion': protocolVersion,
      'capabilities': capabilities.toMap(),
      'clientInfo': clientInfo.toMap(),
    };
  }

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
  ClientCapabilities(super.data);

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

  Implementation({
    this.icons,
    required this.name,
    this.description,
    this.title,
    this.version,
    this.websiteUrl,
  });

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

class InitializeResultResponse extends MCP {
  String jsonrpc = '2.0';
  String id;
  InitializeResult result;

  InitializeResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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
  ServerCapabilities(super.data);

  @override
  Map<String, Object?> toMap() {
    return data;
  }

  factory ServerCapabilities.toMCP(Map<String, Object?> map) {
    return ServerCapabilities(map);
  }
}

class SetLevelRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "logging/setLevel";
  SetLevelRequestParams params;

  SetLevelRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory SetLevelRequest.toMCP(Map<String, Object?> map) {
    return SetLevelRequest(
      id: map['id']?.toString() ?? '-1',
      params: SetLevelRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class SetLevelRequestParams extends MCP {
  RequestMetaObject? $meta;
  LoggingLevel level;

  SetLevelRequestParams({this.$meta, required this.level});

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'level': level.toString(),
    };
  }

  factory SetLevelRequestParams.toMCP(Map<String, Object?> map) {
    return SetLevelRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      level: LoggingLevel.to(map['level'] as String),
    );
  }
}

class SetLevelResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  SetLevelResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory SetLevelResultResponse.toMCP(Map<String, Object?> map) {
    return SetLevelResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class CancelledNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notification/cancelled";
  CancelledNotificationParams params;

  CancelledNotification({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  factory CancelledNotification.toMCP(Map<String, Object?> map) {
    return CancelledNotification(
      params: CancelledNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class CancelledNotificationParams extends MCP {
  MetaObject? $meta;
  String? requestId;
  String? reason;

  CancelledNotificationParams({this.$meta, this.requestId, this.reason});

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      if (requestId != null) 'requestId': requestId,
      if (reason != null) 'reason': reason,
    };
  }

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

class InitializedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/initialized";
  NotificationParams? params;

  InitializedNotification({this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory InitializedNotification.toMCP(Map<String, Object?> map) {
    return InitializedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class TaskStatusNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/tasks/status";
  TaskStatusNotificationParams params;

  TaskStatusNotification({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  factory TaskStatusNotification.toMCP(Map<String, Object?> map) {
    return TaskStatusNotification(
      params: Task.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

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

  Task({
    required this.taskId,
    required this.status,
    this.statusMessage,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.ttl,
    this.pollInterval,
  });

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

  LoggingMessageNotificationParams({
    this.$meta,
    required this.level,
    this.logger,
    required this.data,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'level': level.toString(),
      if (logger != null) 'logger': logger,
      'data': data,
    };
  }

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

class ProgressNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/progress”;
  ///params: ProgressNotificationParams;

  String jsonrpc = "2.0";
  String method = "notifications/progress";
  ProgressNotificationParams params;

  ProgressNotification({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }
}

class ProgressNotificationParams extends MCP {
  ///_meta?: MetaObject;
  ///progressToken: ProgressToken;
  ///progress: number;
  ///total?: number;
  ///message?: string;

  MetaObject? $meta;
  String progressToken;
  num progress;
  num? total;
  String? message;

  ProgressNotificationParams({
    this.$meta,
    required this.progressToken,
    required this.progress,
    this.total,
    this.message,
  });

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

class ResourceListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/resources/list_changed";
  NotificationParams? params;

  ResourceListChangedNotification({this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ResourceListChangedNotification.toMCP(Map<String, Object?> map) {
    return ResourceListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ResourceUpdatedNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/resources/updated”;
  ///params: ResourceUpdatedNotificationParams;

  String jsonrpc = "2.0";
  String method = "notifications/resources/updated";
  ResourceUpdatedNotificationParams params;

  ResourceUpdatedNotification({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  factory ResourceUpdatedNotification.toMCP(Map<String, Object?> map) {
    return ResourceUpdatedNotification(
      params: ResourceUpdatedNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class ResourceUpdatedNotificationParams extends MCP {
  /// jsonrpc: “2.0”;
  /// method: “notifications/resources/updated”;
  /// params: ResourceUpdatedNotificationParams;

  MetaObject? $meta;
  String resourceId;
  String? resourceType;
  Map<String, Object?>? data;

  ResourceUpdatedNotificationParams({
    this.$meta,
    required this.resourceId,
    this.resourceType,
    this.data,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      'resourceId': resourceId,
      if (resourceType != null) 'resourceType': resourceType,
      if (data != null) 'data': data,
    };
  }

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

class RootsListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/roots/list_changed";
  NotificationParams? params;

  RootsListChangedNotification({this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory RootsListChangedNotification.toMCP(Map<String, Object?> map) {
    return RootsListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ToolListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/tools/list_changed";
  NotificationParams? params;

  ToolListChangedNotification({this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ToolListChangedNotification.toMCP(Map<String, Object?> map) {
    return ToolListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ElicitationCompleteNotification extends MCP {
  ///jsonrpc: “2.0”;
  ///method: “notifications/elicitation/complete”;
  ///params: { elicitationId: string };

  String jsonrpc = "2.0";
  String method = "notifications/elicitation/complete";
  ElicitationCompleteNotificationParams params;

  ElicitationCompleteNotification({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'method': method, 'params': params.toMap()};
  }

  factory ElicitationCompleteNotification.toMCP(Map<String, Object?> map) {
    return ElicitationCompleteNotification(
      params: ElicitationCompleteNotificationParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class ElicitationCompleteNotificationParams extends MCP {
  String elicitationId;

  ElicitationCompleteNotificationParams({required this.elicitationId});

  @override
  Map<String, Object?> toMap() {
    return {'elicitationId': elicitationId};
  }

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

  PingRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory PingRequest.toMCP(Map<String, Object?> map) {
    return PingRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? RequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class RequestParams extends MCP {
  MetaObject? $meta;

  RequestParams({this.$meta});

  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap()};
  }

  factory RequestParams.toMCP(Map<String, Object?> map) {
    return RequestParams(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
    );
  }
}

class PromptListChangedNotification extends MCP {
  String jsonrpc = "2.0";
  String method = "notifications/prompts/list_changed";
  NotificationParams? params;

  PromptListChangedNotification({this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory PromptListChangedNotification.toMCP(Map<String, Object?> map) {
    return PromptListChangedNotification(
      params: map['params'] != null
          ? NotificationParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class PingResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  PingResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory PingResultResponse.toMCP(Map<String, Object?> map) {
    return PingResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class CreateTaskResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CreateTaskResult result;

  CreateTaskResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory CreateTaskResultResponse.toMCP(Map<String, Object?> map) {
    return CreateTaskResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CreateTaskResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class CreateTaskResult extends MapMC<String, Object?> {
  Task get task => Task.toMCP(data['task'] as Map<String, Object?>);

  set task(Task value) => data['task'] = value.toMap();

  CreateTaskResult({MetaObject? $meta, required Task task})
      : super(
            {if ($meta != null) '_meta': $meta.toMap(), 'task': task.toMap()});

  @override
  Map<String, Object?> toMap() {
    return data;
  }

  factory CreateTaskResult.toMCP(Map<String, Object?> map) {
    return CreateTaskResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      task: Task.toMCP(map['task'] as Map<String, Object?>),
    );
  }
}

class RelatedTaskMetadata extends MCP {
  String taskId;
  String? relationshipType;

  RelatedTaskMetadata({required this.taskId, this.relationshipType});

  @override
  Map<String, Object?> toMap() {
    return {
      'taskId': taskId,
      if (relationshipType != null) 'relationshipType': relationshipType,
    };
  }

  factory RelatedTaskMetadata.toMCP(Map<String, Object?> map) {
    return RelatedTaskMetadata(
      taskId: map['taskId'] as String,
      relationshipType: map['relationshipType'] as String?,
    );
  }
}

class GetTaskRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/get";
  GetTaskRequestParams params;

  GetTaskRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory GetTaskRequest.toMCP(Map<String, Object?> map) {
    return GetTaskRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

class GetTaskRequestParams extends MCP {
  String taskId;

  GetTaskRequestParams({required this.taskId});

  @override
  Map<String, Object?> toMap() {
    return {'taskId': taskId};
  }

  factory GetTaskRequestParams.toMCP(Map<String, Object?> map) {
    return GetTaskRequestParams(taskId: map['taskId'] as String);
  }
}

class GetTaskPayloadRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/result";
  GetTaskRequestParams params;

  GetTaskPayloadRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory GetTaskPayloadRequest.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

class GetTaskPayloadResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  GetTaskPayloadResult result;

  GetTaskPayloadResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory GetTaskPayloadResultResponse.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: GetTaskPayloadResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class GetTaskPayloadResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();

  GetTaskPayloadResult({
    MetaObject? $meta,
    Map<String, Object?>? additionalData,
  }) : super({if ($meta != null) '_meta': $meta.toMap(), ...?additionalData});

  @override
  Map<String, Object?> toMap() {
    return data;
  }

  factory GetTaskPayloadResult.toMCP(Map<String, Object?> map) {
    return GetTaskPayloadResult(
      $meta: map['_meta'] != null
          ? MetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      additionalData: Map.from(map)..remove('_meta'),
    );
  }
}

class ListTasksRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/list";
  PaginatedRequestParams? params;

  ListTasksRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ListTasksRequest.toMCP(Map<String, Object?> map) {
    return ListTasksRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ListTasksResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListTasksResult result;

  ListTasksResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ListTasksResultResponse.toMCP(Map<String, Object?> map) {
    return ListTasksResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListTasksResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ListTasksResult extends MapMC<String, Object?> {
  MetaObject? $meta;
  String? nextCursor;
  List<Task> tasks;

  ListTasksResult({
    this.$meta,
    this.nextCursor,
    required this.tasks,
    Map<String, Object?>? additionalData,
  }) : super(additionalData ?? {});

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.data,
      if ($meta != null) '_meta': $meta!.toMap(),
      if (nextCursor != null) 'nextCursor': nextCursor,
      'tasks': tasks.map((e) => e.toMap()).toList(),
    };
  }

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

class CancelTaskRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tasks/cancel";
  GetTaskRequestParams params;

  CancelTaskRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory CancelTaskRequest.toMCP(Map<String, Object?> map) {
    return CancelTaskRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetTaskRequestParams.toMCP(map['params'] as Map<String, Object?>),
    );
  }
}

class CancelTaskResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CancelTaskResult result;
  CancelTaskResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory CancelTaskResultResponse.toMCP(Map<String, Object?> map) {
    return CancelTaskResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CancelTaskResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

abstract class CancelTaskResult implements MCP {
  factory CancelTaskResult.toMCP(Map<String, Object?> map) {
    return Task(
      taskId: map['taskId'] as String,
      status: TaskStatus.to(map['status'] as String),
      createdAt: map['createdAt'] as String,
      lastUpdatedAt: map['lastUpdatedAt'] as String,
    );
  }
}

class GetPromptRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "prompts/get";
  GetPromptRequestParams params;

  GetPromptRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory GetPromptRequest.toMCP(Map<String, Object?> map) {
    return GetPromptRequest(
      id: map['id']?.toString() ?? '-1',
      params: GetPromptRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class GetPromptRequestParams extends MCP {
  RequestMetaObject? $meta;
  InputResponses? inputResponses;
  String? requestState;
  String name;
  Map<String, String>? arguments;

  GetPromptRequestParams({
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.name,
    this.arguments,
  });

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

class GetPromptResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  GetPromptResult result;

  GetPromptResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result};
  }

  factory GetPromptResultResponse.toMCP(Map<String, Object?> map) {
    return GetPromptResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: GetPromptResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class GetPromptResult extends MapMC<String, Object?> {
  MetaObject? $meta;
  String? description;
  List<PromptMessage> messages;

  GetPromptResult({
    this.$meta,
    this.description,
    required this.messages,
    Map<String, Object?>? additionalData,
  }) : super(additionalData ?? {});

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.data,
      if ($meta != null) '_meta': $meta!.toMap(),
      if (description != null) 'description': description,
      'messages': messages.map((e) => e.toMap()).toList(),
    };
  }

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

class PromptMessage extends MCP {
  Role role;
  ContentBlock content;
  PromptMessage({required this.role, required this.content});
  @override
  Map<String, Object?> toMap() {
    return {'role': role.toString(), 'content': content.toMap()};
  }

  factory PromptMessage.toMCP(Map<String, Object?> map) {
    return PromptMessage(
      role: Role.to(map['role'] as String),
      content: ContentBlock.toMCP(map['content'] as Map<String, Object?>),
    );
  }
}

class ListPromptsRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "prompts/list";
  PaginatedRequestParams? params;

  ListPromptsRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ListPromptsRequest.toMCP(Map<String, Object?> map) {
    return ListPromptsRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ListPromptsResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListPromptsResult result;
  ListPromptsResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ListPromptsResultResponse.toMCP(Map<String, Object?> map) {
    return ListPromptsResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListPromptsResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ListPromptsResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  String? get nextCursor => data['nextCursor'] as String?;
  List<Prompt> get prompts => (data['prompts'] as List<dynamic>)
      .map((e) => Prompt.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set prompts(List<Prompt> value) =>
      data['prompts'] = value.map((e) => e.toMap()).toList();

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

  Prompt({
    this.icons,
    required this.name,
    this.title,
    this.description,
    this.arguments,
    this.$meta,
  });

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

  PromptArgument({
    required this.name,
    this.title,
    this.description,
    this.required,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      'name': name,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (required != null) 'required': required,
    };
  }

  factory PromptArgument.toMCP(Map<String, Object?> map) {
    return PromptArgument(
      name: map['name'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      required: map['required'] as bool?,
    );
  }
}

class ListResourcesRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/list";
  PaginatedRequestParams? params;

  ListResourcesRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ListResourcesRequest.toMCP(Map<String, Object?> map) {
    return ListResourcesRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ListResourcesResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListResourcesResult result;

  ListResourcesResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ListResourcesResultResponse.toMCP(Map<String, Object?> map) {
    return ListResourcesResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListResourcesResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ListResourcesResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  String? get nextCursor => data['nextCursor'] as String?;
  List<Resource> get resources => (data['resources'] as List<dynamic>)
      .map((e) => Resource.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resources(List<Resource> value) =>
      data['resources'] = value.map((e) => e.toMap()).toList();

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

class ReadResourceRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/read";
  ReadResourceRequestParams params;

  ReadResourceRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory ReadResourceRequest.toMCP(Map<String, Object?> map) {
    return ReadResourceRequest(
      id: map['id']?.toString() ?? '-1',
      params: ReadResourceRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class ReadResourceRequestParams extends MCP {
  RequestMetaObject? $meta;
  InputResponses? inputResponses;
  String? requestState;
  String uri;

  ReadResourceRequestParams({
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.uri,
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($meta != null) '_meta': $meta!.toMap(),
      if (inputResponses != null) 'inputResponses': inputResponses!.toMap(),
      if (requestState != null) 'requestState': requestState,
      'uri': uri,
    };
  }

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

class ReadResourceResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ReadResourceResult result;

  ReadResourceResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ReadResourceResultResponse.toMCP(Map<String, Object?> map) {
    return ReadResourceResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ReadResourceResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

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

  ReadResourceResult({
    MetaObject? $meta,
    required List<ResourceContents> contents,
    Map<String, Object?>? additionalData,
  }) : super({
          if ($meta != null) '_meta': $meta.toMap(),
          'contents': contents.map((e) => e.toMap()).toList(),
          ...?additionalData,
        });

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

class ListResourceTemplatesRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/templates/list";
  PaginatedRequestParams? params;

  ListResourceTemplatesRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ListResourceTemplatesRequest.toMCP(Map<String, Object?> map) {
    return ListResourceTemplatesRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ListResourceTemplatesResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListResourceTemplatesResult result;

  ListResourceTemplatesResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ListResourceTemplatesResultResponse.toMCP(Map<String, Object?> map) {
    return ListResourceTemplatesResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListResourceTemplatesResult.toMCP(
        map['result'] as Map<String, Object?>,
      ),
    );
  }
}

class ListResourceTemplatesResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  String? get nextCursor => data['nextCursor'] as String?;
  List<ResourceTemplate> get resourceTemplates =>
      (data['resourceTemplates'] as List<dynamic>)
          .map((e) => ResourceTemplate.toMCP(e as Map<String, Object?>))
          .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set resourceTemplates(List<ResourceTemplate> value) =>
      data['resourceTemplates'] = value.map((e) => e.toMap()).toList();

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

class SubscribeRequestParams extends MCP {
  RequestMetaObject? $meta;
  String uri;

  SubscribeRequestParams({this.$meta, required this.uri});

  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap(), 'uri': uri};
  }

  factory SubscribeRequestParams.toMCP(Map<String, Object?> map) {
    return SubscribeRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      uri: map['uri'] as String,
    );
  }
}

class SubscribeRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "resources/subscribe";
  SubscribeRequestParams params;

  SubscribeRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

  factory SubscribeRequest.toMCP(Map<String, Object?> map) {
    return SubscribeRequest(
      id: map['id']?.toString() ?? '-1',
      params: SubscribeRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class SubscribeResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  SubscribeResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory SubscribeResultResponse.toMCP(Map<String, Object?> map) {
    return SubscribeResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class UnsubscribeRequestParams extends MCP {
  RequestMetaObject? $meta;
  String uri;

  UnsubscribeRequestParams({this.$meta, required this.uri});

  @override
  Map<String, Object?> toMap() {
    return {if ($meta != null) '_meta': $meta!.toMap(), 'uri': uri};
  }

  factory UnsubscribeRequestParams.toMCP(Map<String, Object?> map) {
    return UnsubscribeRequestParams(
      $meta: map['_meta'] != null
          ? RequestMetaObject.toMCP(map['_meta'] as Map<String, Object?>)
          : null,
      uri: map['uri'] as String,
    );
  }
}

class UnsubscribeResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  Result result;

  UnsubscribeResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory UnsubscribeResultResponse.toMCP(Map<String, Object?> map) {
    return UnsubscribeResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: Result.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class Root extends MCP {
  String uri;
  String? name;
  MetaObject? $meta;

  Root({required this.uri, this.name, this.$meta});

  @override
  Map<String, Object?> toMap() {
    return {
      'uri': uri,
      if (name != null) 'name': name,
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

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

class ListRootsResult extends MCP {
  List<Root> roots;

  ListRootsResult({required this.roots});

  @override
  Map<String, Object?> toMap() {
    return {'roots': roots.map((e) => e.toMap()).toList()};
  }

  factory ListRootsResult.toMCP(Map<String, Object?> map) {
    return ListRootsResult(
      roots: (map['roots'] as List<dynamic>)
          .map((e) => Root.toMCP(e as Map<String, Object?>))
          .toList(),
    );
  }
}

class ListRootsRequest extends MCP {
  String method = "roots/list";
  RequestParams? params;

  ListRootsRequest({this.params});

  @override
  Map<String, Object?> toMap() {
    return {'method': method, if (params != null) 'params': params!.toMap()};
  }

  factory ListRootsRequest.toMCP(Map<String, Object?> map) {
    return ListRootsRequest(
      params: map['params'] != null
          ? RequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ModelHint extends MCP {
  String? name;

  ModelHint({this.name});

  @override
  Map<String, Object?> toMap() {
    return {if (name != null) 'name': name};
  }

  factory ModelHint.toMCP(Map<String, Object?> map) {
    return ModelHint(name: map['name'] as String?);
  }
}

class ModelPreferences extends MCP {
  List<ModelHint>? hints;
  num? costPriority;
  num? speedPriority;
  num? intelligencePriority;

  ModelPreferences({
    this.hints,
    this.costPriority,
    this.speedPriority,
    this.intelligencePriority,
  });

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

class SamplingMessage extends MCP {
  Role role;
  List<ContentBlock> content;
  MetaObject? $meta;

  SamplingMessage({required this.role, required this.content, this.$meta});

  @override
  Map<String, Object?> toMap() {
    return {
      'role': role.toString(),
      'content': content.map((e) => e.toMap()).toList(),
      if ($meta != null) '_meta': $meta!.toMap(),
    };
  }

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

class ToolChoice extends MCP {
  String? mode;

  ToolChoice({this.mode});

  @override
  Map<String, Object?> toMap() {
    return {if (mode != null) 'mode': mode};
  }

  factory ToolChoice.toMCP(Map<String, Object?> map) {
    return ToolChoice(mode: map['mode'] as String?);
  }
}

class ToolResultContent extends ContentBlock {
  String toolUseId;
  List<ContentBlock> content;
  Map<String, Object?>? structuredContent;
  bool? isError;

  ToolResultContent({
    required this.toolUseId,
    required this.content,
    this.structuredContent,
    this.isError,
    super.annotations,
    super.$meta,
  }) : super(type: 'tool_result', data: '', mimeType: '');

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

class ToolUseContent extends ContentBlock {
  String id;
  String name;
  Map<String, Object?> input;

  ToolUseContent({
    required this.id,
    required this.name,
    required this.input,
    super.annotations,
    super.$meta,
  }) : super(type: 'tool_use', data: '', mimeType: '');

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

  ToolAnnotations({
    this.title,
    this.readOnlyHint,
    this.destructiveHint,
    this.idempotentHint,
    this.openWorldHint,
  });

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

  ToolExecution({this.taskSupport});

  @override
  Map<String, Object?> toMap() {
    return {if (taskSupport != null) 'taskSupport': taskSupport};
  }

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

  ToolSchema({
    this.$schema,
    this.properties,
    this.required,
    this.type = 'object',
  });

  @override
  Map<String, Object?> toMap() {
    return {
      if ($schema != null) r'$schema': $schema,
      'type': type,
      if (properties != null) 'properties': properties,
      if (required != null) 'required': required,
    };
  }

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

class CreateMessageRequestParams extends MCP {
  List<SamplingMessage> messages;
  ModelPreferences? modelPreferences;
  String? systemPrompt;
  String? includeContext;
  num? temperature;
  int maxTokens;
  List<String>? stopSequences;
  Map<String, Object?>? metadata;
  List<Tool>? tools;
  ToolChoice? toolChoice;

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

class CreateMessageRequest extends MCP {
  String method = "sampling/createMessage";
  CreateMessageRequestParams params;

  CreateMessageRequest({required this.params});

  @override
  Map<String, Object?> toMap() {
    return {'method': method, 'params': params.toMap()};
  }

  factory CreateMessageRequest.toMCP(Map<String, Object?> map) {
    return CreateMessageRequest(
      params: CreateMessageRequestParams.toMCP(
        map['params'] as Map<String, Object?>,
      ),
    );
  }
}

class CreateMessageResult extends MCP {
  String model;
  String? stopReason;
  Role role;
  List<ContentBlock> content;
  MetaObject? $meta;

  CreateMessageResult({
    required this.model,
    this.stopReason,
    required this.role,
    required this.content,
    this.$meta,
  });

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

  CallToolRequestParams({
    this.task,
    this.$meta,
    this.inputResponses,
    this.requestState,
    required this.name,
    this.arguments,
  });

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

  CallToolRequest({required this.id, required this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      'params': params.toMap(),
    };
  }

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
  bool? get isError => data['isError'] as bool?;

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set content(List<ContentBlock> value) =>
      data['content'] = value.map((e) => e.toMap()).toList();
  set structuredContent(Map<String, Object?>? value) =>
      data['structuredContent'] = value;
  set isError(bool? value) => data['isError'] = value;

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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

class CallToolResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  CallToolResult result;

  CallToolResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory CallToolResultResponse.toMCP(Map<String, Object?> map) {
    return CallToolResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: CallToolResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ListToolsRequest extends MCP {
  String jsonrpc = "2.0";
  String id;
  String method = "tools/list";
  PaginatedRequestParams? params;

  ListToolsRequest({required this.id, this.params});

  @override
  Map<String, Object?> toMap() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params!.toMap(),
    };
  }

  factory ListToolsRequest.toMCP(Map<String, Object?> map) {
    return ListToolsRequest(
      id: map['id']?.toString() ?? '-1',
      params: map['params'] != null
          ? PaginatedRequestParams.toMCP(map['params'] as Map<String, Object?>)
          : null,
    );
  }
}

class ListToolsResultResponse extends MCP {
  String jsonrpc = "2.0";
  String id;
  ListToolsResult result;

  ListToolsResultResponse({required this.id, required this.result});

  @override
  Map<String, Object?> toMap() {
    return {'jsonrpc': jsonrpc, 'id': id, 'result': result.toMap()};
  }

  factory ListToolsResultResponse.toMCP(Map<String, Object?> map) {
    return ListToolsResultResponse(
      id: map['id']?.toString() ?? '-1',
      result: ListToolsResult.toMCP(map['result'] as Map<String, Object?>),
    );
  }
}

class ListToolsResult extends MapMC<String, Object?> {
  MetaObject? get $meta => data['_meta'] != null
      ? MetaObject.toMCP(data['_meta'] as Map<String, Object?>)
      : null;
  String? get nextCursor => data['nextCursor'] as String?;
  List<Tool> get tools => (data['tools'] as List<dynamic>)
      .map((e) => Tool.toMCP(e as Map<String, Object?>))
      .toList();

  set $meta(MetaObject? value) => data['_meta'] = value?.toMap();
  set nextCursor(String? value) => data['nextCursor'] = value;
  set tools(List<Tool> value) =>
      data['tools'] = value.map((e) => e.toMap()).toList();

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

  @override
  Map<String, Object?> toMap() {
    return data;
  }

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
