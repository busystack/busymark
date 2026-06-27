import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/busymark_design.dart';

enum HeaderBarAction {
  back,
  sidebarToggle,
  search,
  refresh,
  save,
  menu,
  settings,
  keyboardShortcuts,
  aboutBusyMark,
  viewModeEditor,
  viewModeSource,
  viewModePreview,
  viewModeSplit,
}

enum AppViewMode { editor, source, preview, split }

class HeaderBarActionEvent {
  const HeaderBarActionEvent({required this.sequence, required this.action});

  final int sequence;
  final HeaderBarAction action;

  @override
  bool operator ==(Object other) {
    return other is HeaderBarActionEvent &&
        other.sequence == sequence &&
        other.action == action;
  }

  @override
  int get hashCode => Object.hash(sequence, action);
}

class HeaderBarLabels {
  const HeaderBarLabels({
    required this.editor,
    required this.source,
    required this.preview,
    required this.split,
    required this.viewMode,
    required this.search,
    required this.refresh,
    required this.menu,
    required this.sidebar,
    required this.back,
    required this.save,
    required this.settings,
    required this.keyboardShortcuts,
    required this.aboutBusyMark,
  });

  final String editor;
  final String source;
  final String preview;
  final String split;
  final String viewMode;
  final String search;
  final String refresh;
  final String menu;
  final String sidebar;
  final String back;
  final String save;
  final String settings;
  final String keyboardShortcuts;
  final String aboutBusyMark;

  Map<String, String> toMap() => {
    'editor': editor,
    'source': source,
    'preview': preview,
    'split': split,
    'viewMode': viewMode,
    'search': search,
    'refresh': refresh,
    'menu': menu,
    'sidebar': sidebar,
    'back': back,
    'save': save,
    'settings': settings,
    'keyboardShortcuts': keyboardShortcuts,
    'aboutBusyMark': aboutBusyMark,
  };
}

class HeaderBarTheme {
  const HeaderBarTheme({
    required this.preferDark,
    required this.backgroundColor,
    required this.sidebarBackgroundColor,
    required this.foregroundColor,
    required this.mutedForegroundColor,
    required this.disabledForegroundColor,
    required this.controlColor,
    required this.controlHoverColor,
    required this.accentColor,
    required this.accentForegroundColor,
    required this.popoverBackgroundColor,
    required this.borderColor,
    required this.shadeColor,
    required this.modalBarrierColor,
  });

  factory HeaderBarTheme.fromContext(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final barrier = Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: BusyMarkAlpha.modalBarrier);
    return HeaderBarTheme(
      preferDark: Theme.of(context).brightness == Brightness.dark,
      backgroundColor: colors.view,
      sidebarBackgroundColor: colors.sidebar,
      foregroundColor: colors.foreground,
      mutedForegroundColor: colors.mutedForeground,
      disabledForegroundColor: colors.disabledForeground,
      controlColor: colors.control,
      controlHoverColor: colors.controlHover,
      accentColor: Theme.of(context).colorScheme.primary,
      accentForegroundColor: Theme.of(context).colorScheme.onPrimary,
      popoverBackgroundColor: colors.popover,
      borderColor: colors.subtleBorder,
      shadeColor: colors.shade,
      modalBarrierColor: barrier,
    );
  }

  final bool preferDark;
  final Color backgroundColor;
  final Color sidebarBackgroundColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;
  final Color disabledForegroundColor;
  final Color controlColor;
  final Color controlHoverColor;
  final Color accentColor;
  final Color accentForegroundColor;
  final Color popoverBackgroundColor;
  final Color borderColor;
  final Color shadeColor;
  final Color modalBarrierColor;

  Map<String, Object> toMap() => {
    'preferDark': preferDark,
    'backgroundColor': _cssColor(backgroundColor),
    'sidebarBackgroundColor': _cssColor(sidebarBackgroundColor),
    'foregroundColor': _cssColor(foregroundColor),
    'mutedForegroundColor': _cssColor(mutedForegroundColor),
    'disabledForegroundColor': _cssColor(disabledForegroundColor),
    'controlColor': _cssColor(controlColor),
    'controlHoverColor': _cssColor(controlHoverColor),
    'accentColor': _cssColor(accentColor),
    'accentForegroundColor': _cssColor(accentForegroundColor),
    'popoverBackgroundColor': _cssColor(popoverBackgroundColor),
    'borderColor': _cssColor(borderColor),
    'shadeColor': _cssColor(shadeColor),
    'modalBarrierColor': _cssColor(modalBarrierColor),
  };
}

class LinuxHeaderBarService {
  LinuxHeaderBarService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.busymark.app/headerbar') {
    _channel.setMethodCallHandler(_handleNativeAction);
  }

  static final LinuxHeaderBarService instance = LinuxHeaderBarService();

  final MethodChannel _channel;
  final _actions = StreamController<HeaderBarAction>.broadcast();
  final _actionEvents = StreamController<HeaderBarActionEvent>.broadcast();
  final _searchQueries = StreamController<String>.broadcast();
  var _initialized = false;
  var _channelReady = false;
  var _available = false;
  var _actionSequence = 0;

  bool get isAvailable => _available;
  bool get usesNativeHeaderBar => _available;

  Stream<HeaderBarAction> get actions => _actions.stream;
  Stream<HeaderBarActionEvent> get actionEvents => _actionEvents.stream;
  Stream<String> get searchQueries => _searchQueries.stream;

  Future<void> initialize() async {
    if (_channelReady || (_initialized && !Platform.isLinux)) {
      return;
    }
    if (!Platform.isLinux) {
      _initialized = true;
      return;
    }
    _initialized = true;
    try {
      _available = await _channel.invokeMethod<bool>('initialize') ?? false;
      _channelReady = true;
    } on MissingPluginException {
      _initialized = false;
      _channelReady = false;
      _available = false;
    } on Object {
      _initialized = false;
      _channelReady = false;
      _available = false;
    }
  }

  Future<void> setTitleRange(String value) {
    return _invoke('setTitleRange', value);
  }

  Future<void> setViewMode(AppViewMode mode) {
    return _invoke('setViewMode', mode.name);
  }

  Future<void> setCanRefresh(bool value) {
    return _invoke('setCanRefresh', value);
  }

  Future<void> setCanSave(bool value) {
    return _invoke('setCanSave', value);
  }

  Future<void> setDocumentControlsVisible(bool value) {
    return _invoke('setDocumentControlsVisible', value);
  }

  Future<void> setSearchActive(bool value) {
    return _invoke('setSearchActive', value);
  }

  Future<void> setSearchQuery(String value) {
    return _invoke('setSearchQuery', value);
  }

  Future<void> setSidebarVisible(bool value) {
    return _invoke('setSidebarVisible', value);
  }

  Future<void> setSidebarToggleVisible(bool value) {
    return _invoke('setSidebarToggleVisible', value);
  }

  Future<void> setSidebarWidth(double value) {
    return _invoke('setSidebarWidth', value);
  }

  Future<void> setBackVisible(bool value) {
    return _invoke('setBackVisible', value);
  }

  Future<void> setLocalizedLabels(HeaderBarLabels labels) {
    return _invoke('setLocalizedLabels', labels.toMap());
  }

  Future<void> setTheme(HeaderBarTheme theme) {
    return _invoke('setTheme', theme.toMap());
  }

  Future<void> setModalBarrierVisible(bool value) {
    return _invoke('setModalBarrierVisible', value);
  }

  Future<void> _invoke(
    String method, [
    Object? arguments,
    bool requireHeaderBar = true,
  ]) async {
    if (!_channelReady) {
      await initialize();
    }
    if (!_channelReady || (requireHeaderBar && !_available)) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      _channelReady = false;
      _available = false;
    } on Object {
      // Native headerbar is a progressive Linux enhancement. Flutter fallback
      // remains usable if the host shell rejects an update.
    }
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    if (call.method == 'searchQueryChanged') {
      if (!_searchQueries.isClosed) {
        _searchQueries.add((call.arguments as String?) ?? '');
      }
      return;
    }
    final action = _actionFromMethod(call.method);
    if (action != null) {
      _actionSequence++;
      if (!_actions.isClosed) {
        _actions.add(action);
      }
      if (!_actionEvents.isClosed) {
        _actionEvents.add(
          HeaderBarActionEvent(sequence: _actionSequence, action: action),
        );
      }
    }
  }

  HeaderBarAction? _actionFromMethod(String method) {
    return switch (method) {
      'back' => HeaderBarAction.back,
      'sidebarToggle' => HeaderBarAction.sidebarToggle,
      'search' => HeaderBarAction.search,
      'refresh' => HeaderBarAction.refresh,
      'save' => HeaderBarAction.save,
      'menu' => HeaderBarAction.menu,
      'settings' => HeaderBarAction.settings,
      'keyboardShortcuts' => HeaderBarAction.keyboardShortcuts,
      'aboutBusyMark' => HeaderBarAction.aboutBusyMark,
      'viewModeEditor' => HeaderBarAction.viewModeEditor,
      'viewModeSource' => HeaderBarAction.viewModeSource,
      'viewModePreview' => HeaderBarAction.viewModePreview,
      'viewModeSplit' => HeaderBarAction.viewModeSplit,
      _ => null,
    };
  }
}

final linuxHeaderBarServiceProvider = Provider<LinuxHeaderBarService>(
  (ref) => LinuxHeaderBarService.instance,
);

final headerBarActionsProvider = StreamProvider<HeaderBarActionEvent>((ref) {
  return ref.watch(linuxHeaderBarServiceProvider).actionEvents;
});

final headerBarSearchQueriesProvider = StreamProvider<String>((ref) {
  return ref.watch(linuxHeaderBarServiceProvider).searchQueries;
});

String _cssColor(Color color) {
  final alpha = (color.a).clamp(0.0, 1.0).toStringAsFixed(3);
  return 'rgba(${(color.r * 255).round()},'
      '${(color.g * 255).round()},'
      '${(color.b * 255).round()},'
      '$alpha)';
}
