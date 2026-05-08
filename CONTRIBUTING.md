# Contributing to mcp_models

Thank you for your interest in contributing! This guide explains the simple rules to follow.

---

## What is this package?

`mcp_models` provides plain Dart model classes for the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/specification/2025-11-25/schema).  
Every class maps 1-to-1 to a type defined in the official MCP schema — no magic, no code generation.

---

## The Golden Rule

> **All code must follow the MCP Protocol structure.**

The MCP specification is the source of truth. Before adding or changing anything, check the [MCP 2025-11-25 schema](https://modelcontextprotocol.io/specification/2025-11-25/schema) first.

---

## Simple Rules

### 1. Every model must implement `MCP`

Every class that represents an MCP type must implement the `MCP` interface from `mcp_base.dart`:

```dart
class MyType implements MCP {
  @override
  Map<String, Object?> toMap() { ... }

  factory MyType.toMCP(Map<String, Object?> map) { ... }
}
```

- `toMap()` — serialises the object to a JSON-safe map.
- `TypeName.toMCP(map)` — named factory that deserialises from a map.

### 2. No runtime dependencies

This package has **zero runtime dependencies**. Keep it that way.  
Do not add any `dependencies` to `pubspec.yaml`. Dev dependencies (for testing/linting) are fine.

### 3. Match the MCP schema exactly

- Field names must match the MCP schema property names (camelCase as defined in the spec).
- Do not add fields that are not in the spec.
- Do not rename or restructure types to suit personal preference.

### 4. No code generation

Everything is hand-written plain Dart. Do not introduce `build_runner`, `json_serializable`, or similar tools.

### 5. Write tests

Every new model class needs a test in `test/mcp_models_test.dart` that covers:

- Serialisation: `toMap()` produces the expected map.
- Deserialisation: `TypeName.toMCP(map)` restores the object correctly.

### 6. Use existing base classes

| When your type... | Extend / implement |
|---|---|
| Is a regular MCP object | `implements MCP` |
| **Is** the map itself (e.g. capabilities, metadata) | `extends MapMC<K, V>` |
| Is a JSON-RPC message | `extends JSONRPCMessage` |

## How to Contribute

1. **Fork** the repository and create a branch from `main`.
2. **Check the MCP spec** for the type you are adding or changing.
3. **Write your code** following the rules above.
4. **Add tests** for the new or changed code.
5. Run `dart test` and make sure all tests pass.
6. Run `dart analyze` — there should be no warnings or errors.
7. Open a **Pull Request** with a clear description of what you changed and which part of the MCP spec it covers.

## Questions?

Open an [issue](https://github.com/uproid/mcp_models/issues) and describe what you want to add or fix.
