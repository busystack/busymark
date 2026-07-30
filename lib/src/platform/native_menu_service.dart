import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@visibleForTesting
const nativeMenuChannelName = 'busymark/native_menus';

/// Identifies one native menu presentation.
///
/// The host compares this identity when dismissing a menu, so a retiring
/// widget cannot close a newer caller's popover.
@immutable
final class NativeMenuSession {
  NativeMenuSession() : id = _nextId++;

  static int _nextId = 1;

  final int id;
}

/// One semantic row exposed by a host-toolkit menu.
@immutable
final class NativeMenuEntry {
  const NativeMenuEntry.command({
    required this.label,
    this.iconName,
    this.shortcut,
    this.enabled = true,
    this.checkable = false,
    this.selected = false,
  }) : separator = false;

  const NativeMenuEntry.separator()
    : label = '',
      iconName = null,
      shortcut = null,
      enabled = false,
      checkable = false,
      selected = false,
      separator = true;

  final String label;
  final String? iconName;
  final String? shortcut;
  final bool enabled;
  final bool checkable;
  final bool selected;
  final bool separator;

  Map<String, Object> _toPlatformMap() {
    return <String, Object>{
      'label': label,
      if (iconName != null && iconName!.isNotEmpty) 'icon': iconName!,
      if (shortcut != null && shortcut!.isNotEmpty) 'shortcut': shortcut!,
      'enabled': enabled,
      'checkable': checkable,
      'selected': selected,
      'separator': separator,
    };
  }
}

/// Result of asking the host toolkit to present a native menu.
@immutable
final class NativeMenuResult {
  const NativeMenuResult.available({this.selectedIndex}) : available = true;

  const NativeMenuResult.unavailable()
    : available = false,
      selectedIndex = null;

  final bool available;
  final int? selectedIndex;
}

/// Presents anchored menus through the host desktop toolkit when available.
class NativeMenuService {
  const NativeMenuService({
    MethodChannel channel = const MethodChannel(nativeMenuChannelName),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<NativeMenuResult> show({
    required NativeMenuSession session,
    required Rect anchor,
    required List<NativeMenuEntry> entries,
    bool focusFirst = false,
    bool preferAbove = false,
  }) async {
    try {
      final selectedIndex = await _channel.invokeMethod<int>('show', {
        'sessionId': session.id,
        'anchor': <String, double>{
          'x': anchor.left,
          'y': anchor.top,
          'width': anchor.width,
          'height': anchor.height,
        },
        'entries': [for (final entry in entries) entry._toPlatformMap()],
        'focusFirst': focusFirst,
        'preferredPosition': preferAbove ? 'top' : 'bottom',
      });
      return NativeMenuResult.available(selectedIndex: selectedIndex);
    } on MissingPluginException {
      return const NativeMenuResult.unavailable();
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') {
        return const NativeMenuResult.unavailable();
      }
      rethrow;
    }
  }

  Future<bool> dismiss(NativeMenuSession session) async {
    try {
      return await _channel.invokeMethod<bool>('dismiss', {
            'sessionId': session.id,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') {
        return false;
      }
      rethrow;
    }
  }
}
