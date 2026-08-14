/// A thin [Map] wrapper that delegates all operations to an inner [data] map.
///
/// Used as a base for MCP types whose serialised form _is_ the map itself
/// (e.g. [ClientCapabilities], [InitializeResult]).
class MapModel<A, B> implements Map<A, B> {
  /// The underlying map data.
  final Map<A, B> data;

  /// Wraps the given [data] map.
  MapModel(this.data);

  /// Delegates to the underlying map's `[]` operator.
  @override
  B? operator [](Object? key) => data[key];

  /// Delegates to the underlying map's `[]=` operator.
  @override
  void operator []=(A key, B value) => data[key] = value;

  /// See [Map.addAll].
  @override
  void addAll(Map<A, B> other) => data.addAll(other);

  /// See [Map.addEntries].
  @override
  void addEntries(Iterable<MapEntry<A, B>> newEntries) =>
      data.addEntries(newEntries);

  /// See [Map.cast].
  @override
  Map<RK, RV> cast<RK, RV>() => data.cast<RK, RV>();

  /// See [Map.clear].
  @override
  void clear() {
    data.clear();
  }

  /// See [Map.containsKey].
  @override
  bool containsKey(Object? key) {
    return data.containsKey(key);
  }

  /// See [Map.containsValue].
  @override
  bool containsValue(Object? value) {
    return data.containsValue(value);
  }

  /// See [Map.entries].
  @override
  Iterable<MapEntry<A, B>> get entries => data.entries;

  /// See [Map.forEach].
  @override
  void forEach(void Function(A key, B value) action) {
    data.forEach(action);
  }

  /// See [Map.isEmpty].
  @override
  bool get isEmpty => data.isEmpty;

  /// See [Map.isNotEmpty].
  @override
  bool get isNotEmpty => data.isNotEmpty;

  /// See [Map.keys].
  @override
  Iterable<A> get keys => data.keys;

  /// See [Map.length].
  @override
  int get length => data.length;

  /// See [Map.map].
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(A key, B value) convert) {
    return data.map(convert);
  }

  /// See [Map.putIfAbsent].
  @override
  B putIfAbsent(A key, B Function() ifAbsent) {
    return data.putIfAbsent(key, ifAbsent);
  }

  /// See [Map.remove].
  @override
  B? remove(Object? key) {
    return data.remove(key);
  }

  /// See [Map.removeWhere].
  @override
  void removeWhere(bool Function(A key, B value) test) {
    data.removeWhere(test);
  }

  /// See [Map.update].
  @override
  B update(A key, B Function(B value) update, {B Function()? ifAbsent}) {
    return data.update(key, update, ifAbsent: ifAbsent);
  }

  /// See [Map.updateAll].
  @override
  void updateAll(B Function(A key, B value) update) {
    data.updateAll(update);
  }

  /// See [Map.values].
  @override
  Iterable<B> get values => data.values;
}
