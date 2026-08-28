import 'dart:collection';

import 'math_models.dart';

class MathRenderCache {
  MathRenderCache({this.maximumEntries = 256});

  final int maximumEntries;
  final LinkedHashMap<String, RenderedMathResult> _entries = LinkedHashMap();

  RenderedMathResult? get(String key) {
    final result = _entries.remove(key);
    if (result != null) {
      _entries[key] = result;
    }
    return result;
  }

  void put(String key, RenderedMathResult result) {
    _entries.remove(key);
    _entries[key] = result;
    while (_entries.length > maximumEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  int get length => _entries.length;

  void clear() => _entries.clear();
}
