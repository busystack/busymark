import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test transport for the real native menu contract. It renders no fallback
/// widgets: assertions inspect the exact GTK packet and select its leaf index.
class NativeMenuProbe {
  NativeMenuProbe(this.tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      _call,
    );
    addTearDown(dispose);
  }
  static const channel = MethodChannel('busymark/native_menus');
  final WidgetTester tester;
  List<Map<String, dynamic>> entries = [];
  List<Map<String, dynamic>> _scope = [];
  final packets = <Map>[];
  Completer<int?>? _reply;

  Future<dynamic> _call(MethodCall call) async {
    if (call.method == 'dismiss') {
      close();
      return true;
    }
    if (call.method != 'show') return null;
    final packet = call.arguments as Map;
    packets.add(packet);
    entries = [];
    List<Map<String, dynamic>> flatten(List rows) => [
      for (final item in rows)
        () {
          final entry = Map<String, dynamic>.from(item as Map);
          entries.add(entry);
          if (entry['children'] case final List children) {
            entry['children'] = flatten(children);
          }
          return entry;
        }(),
    ];

    _scope = flatten(packet['entries'] as List);
    _reply = Completer<int?>();
    return _reply!.future;
  }

  bool get isOpen => _reply != null;
  Iterable<Object> matching(String label, {bool includeShortcut = true}) =>
      isOpen
      ? _scope.where(
          (e) =>
              e['label'] == label || includeShortcut && e['shortcut'] == label,
        )
      : find.text(label).evaluate();
  Future<void> activate(String label) async {
    if (!isOpen) {
      await tester.tap(find.text(label));
      return;
    }
    final entry = _scope.singleWhere((e) => e['label'] == label);
    expect(entry['enabled'], isTrue);
    if (entry['children'] != null) {
      expect(entry['children'], isNotEmpty);
      _scope = (entry['children'] as List).cast<Map<String, dynamic>>();
      return;
    }
    select(label);
  }

  bool contains(String label) => _scope.any((e) => e['label'] == label);
  bool enabled(String label) =>
      _scope.singleWhere((e) => e['label'] == label)['enabled'] == true;

  /// Complete the transport without pumping, like tester.tap on a menu item.
  void select(String label) {
    final selected = _scope
        .where((e) => e['label'] == label && e['children'] == null)
        .singleOrNull;
    final index = selected == null ? -1 : entries.indexOf(selected);
    expect(
      index,
      greaterThanOrEqualTo(0),
      reason: 'Native action $label must exist',
    );
    expect(
      enabled(label),
      isTrue,
      reason: 'Native action $label must be enabled',
    );
    expect(_reply, isNotNull, reason: 'A native menu must be open');
    _reply!.complete(index);
    _reply = null;
  }

  Future<void> choose(String label, {bool settle = true}) async {
    select(label);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  void close() {
    if (_reply?.isCompleted == false) _reply!.complete(null);
    _reply = null;
  }

  void dispose() {
    close();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  }
}
