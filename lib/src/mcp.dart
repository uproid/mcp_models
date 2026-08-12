/// Base interface for all MCP model objects.
///
/// Every concrete MCP type must implement [toMap] to produce a
/// JSON-serialisable `Map<String, Object?>`.
abstract class MCP {
  Map<String, Object?> toMap();
}
