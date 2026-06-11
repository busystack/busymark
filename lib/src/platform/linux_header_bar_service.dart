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
  problems,
  menu,
  settings,
  aboutBusyMark,
  exportPreview,
  viewModeSource,
  viewModePreview,
  viewModeSplit,
}

enum AppViewMode { source, preview, split }

class HeaderBarLabels {
  const HeaderBarLabels({
    required this.source,
    required this.preview,
    required this.split,
    required this.viewMode,
    required this.search,
    required this.refresh,
    required this.problems,
    required this.menu,
    required this.sidebar,
    required this.back,
    required this.save,
    required this.settings,
    required this.aboutBusyMark,
    required this.exportPreview,
  });

  final String source;
  final String preview;
  final String split;
  final String viewMode;
  final String search;
  final String refresh;
  final String problems;
  final String menu;
  final String sidebar;
  final String back;
  final String save;
  final String settings;
  final String aboutBusyMark;
  final String exportPreview;

  Map<String, String> toMap() => {
    'source': source,
    'preview': preview,
    'split': split,
    'viewMode': viewMode,
    'search': search,
    'refresh': refresh,
    'problems': problems,
    'menu': menu,
    'sidebar': sidebar,
    'back': back,
    'save': save,
    'settings': settings,
    'aboutBusyMark': aboutBusyMark,
    'exportPreview': exportPreview,
  };
}

class HeaderBarTheme {
  const HeaderBarTheme({
    required this.backgroundColor,
    required this.sidebarBackgroundColor,
    required this.foregroundColor,
    required this.mutedForegroundColor,
    required this.disabledForegroundColor,
    required this.controlColor,
    required this.controlHoverColor,
    required this.controlActiveColor,
    required this.accentColor,
    required this.accentForegroundColor,
    required this.popoverBackgroundColor,
    required this.borderColor,
    required this.sidebarBorderColor,
    required this.shadeColor,
    required this.modalBarrierColor,
  });

  factory HeaderBarTheme.fromContext(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final barrier = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32);
    return HeaderBarTheme(
      backgroundColor: colors.view,
      sidebarBackgroundColor: colors.sidebar,
      foregroundColor: colors.foreground,
      mutedForegroundColor: colors.mutedForeground,
      disabledForegroundColor: colors.disabledForeground,
      controlColor: colors.control,
      controlHoverColor: colors.controlHover,
      controlActiveColor: colors.controlActive,
      accentColor: Theme.of(context).colorScheme.primary,
      accentForegroundColor: Theme.of(context).colorScheme.onPrimary,
      popoverBackgroundColor: colors.popover,
      borderColor: colors.subtleBorder,
      sidebarBorderColor: colors.sidebarBorder,
      shadeColor: colors.shade,
      modalBarrierColor: barrier,
    );
  }

  final Color backgroundColor;
  final Color sidebarBackgroundColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;
  final Color disabledForegroundColor;
  final Color controlColor;
  final Color controlHoverColor;
  final Color controlActiveColor;
  final Color accentColor;
  final Color accentForegroundColor;
  final Color popoverBackgroundColor;
  final Color borderColor;
  final Color sidebarBorderColor;
  final Color shadeColor;
  final Color modalBarrierColor;

  Map<String, String> toMap() => {
    'backgroundColor': _cssColor(backgroundColor),
    'sidebarBackgroundColor': _cssColor(sidebarBackgroundColor),
    'foregroundColor': _cssColor(foregroundColor),
    'mutedForegroundColor': _cssColor(mutedForegroundColor),
    'disabledForegroundColor': _cssColor(disabledForegroundColor),
    'controlColor': _cssColor(controlColor),
    'controlHoverColor': _cssColor(controlHoverColor),
    'controlActiveColor': _cssColor(controlActiveColor),
    'accentColor': _cssColor(accentColor),
    'accentForegroundColor': _cssColor(accentForegroundColor),
    'popoverBackgroundColor': _cssColor(popoverBackgroundColor),
    'borderColor': _cssColor(borderColor),
    'sidebarBorderColor': _cssColor(sidebarBorderColor),
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
  var _initialized = false;
  var _available = false;

  bool get isAvailable => _available;
  bool get usesNativeHeaderBar => _available;

  Stream<HeaderBarAction> get actions => _actions.stream;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (!Platform.isLinux) {
      return;
    }
    try {
      _available = await _channel.invokeMethod<bool>('initialize') ?? false;
    } on MissingPluginException {
      _available = false;
    } on Object {
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

  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!_available) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      _available = false;
    } on Object {
      // Native headerbar is a progressive Linux enhancement. Flutter fallback
      // remains usable if the host shell rejects an update.
    }
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    final action = _actionFromMethod(call.method);
    if (action != null && !_actions.isClosed) {
      _actions.add(action);
    }
  }

  HeaderBarAction? _actionFromMethod(String method) {
    return switch (method) {
      'back' => HeaderBarAction.back,
      'sidebarToggle' => HeaderBarAction.sidebarToggle,
      'search' => HeaderBarAction.search,
      'refresh' => HeaderBarAction.refresh,
      'save' => HeaderBarAction.save,
      'problems' => HeaderBarAction.problems,
      'menu' => HeaderBarAction.menu,
      'settings' => HeaderBarAction.settings,
      'aboutBusyMark' => HeaderBarAction.aboutBusyMark,
      'exportPreview' => HeaderBarAction.exportPreview,
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

final headerBarActionsProvider = StreamProvider<HeaderBarAction>((ref) {
  return ref.watch(linuxHeaderBarServiceProvider).actions;
});

String _cssColor(Color color) {
  final alpha = (color.a).clamp(0.0, 1.0).toStringAsFixed(3);
  return 'rgba(${(color.r * 255).round()},'
      '${(color.g * 255).round()},'
      '${(color.b * 255).round()},'
      '$alpha)';
}
