/// Base interface for all MCP model objects.
///
/// Every concrete MCP type must implement [toMap] to produce a
/// JSON-serialisable `Map<String, Object?>`.
abstract class MCP {
  /// Converts this object into a JSON-compatible map.
  Map<String, Object?> toMap();
}
