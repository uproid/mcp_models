/// Dart model classes for the Model Context Protocol (MCP) 2025-11-25.
///
/// This library exposes every type defined in the official MCP schema
/// (<https://modelcontextprotocol.io/specification/2025-11-25/schema>)
/// as plain Dart classes with `toMap()` / `fromMap()` serialisation.
///
/// ## Quick start
/// ```dart
/// import 'package:mcp_models/mcp_models.dart';
///
/// final request = InitializeRequest(
///   id: '1',
///   params: InitializeRequestParams(
///     protocolVersion: '2025-11-25',
///     capabilities: ClientCapabilities({}),
///     clientInfo: Implementation(name: 'my_client', version: '1.0.0'),
///   ),
/// );
/// final json = request.toMap();
/// ```
library;

export 'src/mcp_builder.dart';
export 'src/mcp_base.dart';
