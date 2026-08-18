import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'header_bar_configuration.dart';

export 'header_bar_configuration.dart';

enum HeaderBarAction {
  back,
  sidebarToggle,
  search,
  refresh,
  save,
  exportPdf,
  menu,
  settings,
  keyboardShortcuts,
  markdownAndHtml,
  reportIssue,
  aboutBusyMark,
  viewModeEditor,
  viewModeSource,
  viewModePreview,
  viewModeSplit,
  sidebarFiles,
  sidebarToc,
  sidebarOutline,
  sidebarGit,
  sidebarHistory,
}

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

sealed class HeaderBarSearchEvent {
  const HeaderBarSearchEvent();
}

class HeaderBarSearchQueryChanged extends HeaderBarSearchEvent {
  const HeaderBarSearchQueryChanged(this.query);

  final String query;
}

class HeaderBarSearchSubmitted extends HeaderBarSearchEvent {
  const HeaderBarSearchSubmitted(this.query);

  final String query;
}

class HeaderBarSearchFocusChanged extends HeaderBarSearchEvent {
  const HeaderBarSearchFocusChanged(this.focused);

  final bool focused;
}

class HeaderBarSearchCleared extends HeaderBarSearchEvent {
  const HeaderBarSearchCleared();
}

class HeaderBarSearchEscapePressed extends HeaderBarSearchEvent {
  const HeaderBarSearchEscapePressed();
}

class LinuxHeaderBarService extends ChangeNotifier {
  LinuxHeaderBarService({
    MethodChannel? channel,
    @visibleForTesting String? sessionId,
  }) : assert(sessionId == null || sessionId != ''),
       _channel = channel ?? const MethodChannel('com.busymark.app/headerbar'),
       _sessionId = sessionId ?? const Uuid().v4() {
    configurationSynchronizer = HeaderBarConfigurationSynchronizer(
      apply: _applyConfiguration,
    );
    _channel.setMethodCallHandler(_handleNativeAction);
  }

  static final LinuxHeaderBarService instance = LinuxHeaderBarService();

  final MethodChannel _channel;
  final String _sessionId;
  final _actions = StreamController<HeaderBarAction>.broadcast();
  final _actionEvents = StreamController<HeaderBarActionEvent>.broadcast();
  final _searchEvents = StreamController<HeaderBarSearchEvent>.broadcast();

  late final HeaderBarConfigurationSynchronizer configurationSynchronizer;

  var _initialized = false;
  var _channelReady = false;
  var _available = false;
  var _actionSequence = 0;
  bool? _atomicConfigurationSupported;

  bool get isAvailable => _available;
  bool get usesNativeHeaderBar => _available;

  Stream<HeaderBarAction> get actions => _actions.stream;
  Stream<HeaderBarActionEvent> get actionEvents => _actionEvents.stream;
  Stream<HeaderBarSearchEvent> get searchEvents => _searchEvents.stream;

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
      final available =
          await _channel.invokeMethod<bool>('initialize', {
            'sessionId': _sessionId,
          }) ??
          false;
      _channelReady = true;
      _setAvailable(available);
    } on MissingPluginException {
      _markUnavailable();
    } on Object {
      _markUnavailable();
    }
  }

  /// Legacy setters remain available for an older Linux runner. Product
  /// screens publish a complete [HeaderBarConfiguration] instead.
  Future<void> setTitleRange(String value) {
    return _invokeLegacy('setTitleRange', value);
  }

  Future<void> setViewMode(AppViewMode mode) {
    return _invokeLegacy('setViewMode', mode.name);
  }

  Future<void> setCanRefresh(bool value) {
    return _invokeLegacy('setCanRefresh', value);
  }

  Future<void> setCanExportPdf(bool value) {
    return _invokeLegacy('setCanExportPdf', value);
  }

  Future<void> setDocumentControlsVisible(bool value) {
    return _invokeLegacy('setDocumentControlsVisible', value);
  }

  Future<void> setSearchActive(bool value) {
    return _invokeLegacy('setSearchActive', value);
  }

  Future<void> setSearchVisible(bool value) {
    return _invokeLegacy('setSearchVisible', value);
  }

  Future<void> setSearchQuery(String value) {
    return _invokeLegacy('setSearchQuery', value);
  }

  Future<bool> focusSearch() async {
    if (!_channelReady) {
      await initialize();
    }
    if (!_channelReady || !_available) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('focusSearch') ?? false;
    } on MissingPluginException {
      _markUnavailable();
    } on Object {
      _markUnavailable();
    }
    return false;
  }

  Future<void> setSidebarVisible(bool value) {
    return _invokeLegacy('setSidebarVisible', value);
  }

  Future<void> setSidebarToggleVisible(bool value) {
    return _invokeLegacy('setSidebarToggleVisible', value);
  }

  Future<void> setSidebarWidth(double value) {
    return _invokeLegacy('setSidebarWidth', value);
  }

  Future<void> setTextDirection(TextDirection value) {
    return _invokeLegacy(
      'setTextDirection',
      value == TextDirection.rtl ? 'rtl' : 'ltr',
    );
  }

  Future<void> setBackVisible(bool value) {
    return _invokeLegacy('setBackVisible', value);
  }

  Future<void> setLocalizedLabels(HeaderBarLabels labels) {
    return _invokeLegacy('setLocalizedLabels', labels.toMap());
  }

  Future<void> setTheme(HeaderBarTheme theme) {
    return _invokeLegacy('setTheme', theme.toMap());
  }

  Future<void> setModalBarrierDepth(int value) async {
    if (!_available) {
      return;
    }
    final depth = value < 0 ? 0 : value;
    final hasPublishedConfiguration =
        configurationSynchronizer.desiredConfiguration != null;
    await configurationSynchronizer.setModalBarrierDepth(depth);
    if (!hasPublishedConfiguration) {
      await _invokeLegacy('setModalBarrierDepth', depth);
    }
  }

  Future<void> setModalBarrierVisible(bool value) {
    return setModalBarrierDepth(value ? 1 : 0);
  }

  Future<bool> _applyConfiguration(HeaderBarConfiguration configuration) async {
    if (!_channelReady) {
      await initialize();
    }
    if (!_channelReady || !_available) {
      return false;
    }
    if (_atomicConfigurationSupported == false) {
      return _applyLegacyConfiguration(configuration);
    }
    try {
      final appliedRevision = await _channel.invokeMethod<int>(
        'applyConfiguration',
        <String, Object?>{'sessionId': _sessionId, ...configuration.toMap()},
      );
      if (appliedRevision != configuration.revision) {
        _markUnavailable();
        return false;
      }
      _atomicConfigurationSupported = true;
      return true;
    } on MissingPluginException {
      _atomicConfigurationSupported = false;
      return _applyLegacyConfiguration(configuration);
    } on PlatformException catch (error) {
      if (error.code == 'not_implemented' ||
          error.code == 'unimplemented' ||
          error.code == 'method_not_found') {
        _atomicConfigurationSupported = false;
        return _applyLegacyConfiguration(configuration);
      }
      _markUnavailable();
      return false;
    } on Object {
      _markUnavailable();
      return false;
    }
  }

  Future<bool> _applyLegacyConfiguration(
    HeaderBarConfiguration configuration,
  ) async {
    final updates = <(String, Object?)>[
      ('setTextDirection', configuration.textDirection.name),
      ('setSidebarWidth', configuration.sidebarWidth),
      ('setTheme', configuration.theme.toMap()),
      ('setLocalizedLabels', configuration.labels.toMap()),
      ('setTitleRange', configuration.title),
      ('setViewMode', configuration.viewMode.name),
      ('setCanRefresh', configuration.canRefresh),
      ('setCanExportPdf', configuration.canExportPdf),
      ('setDocumentControlsVisible', configuration.documentControlsVisible),
      ('setSearchVisible', configuration.searchVisible),
      ('setSidebarVisible', configuration.sidebarVisible),
      ('setSidebarToggleVisible', configuration.sidebarToggleVisible),
      ('setBackVisible', configuration.backVisible),
      ('setSearchQuery', configuration.searchQuery),
      ('setSearchActive', configuration.searchActive),
      ('setModalBarrierVisible', configuration.modalBarrierVisible),
    ];
    for (final (method, arguments) in updates) {
      if (!configurationSynchronizer.isLatestRevision(configuration.revision)) {
        return false;
      }
      if (!await _tryInvokeLegacy(method, arguments)) {
        return false;
      }
    }
    return configurationSynchronizer.isLatestRevision(configuration.revision);
  }

  Future<void> _invokeLegacy(String method, [Object? arguments]) async {
    await _tryInvokeLegacy(method, arguments);
  }

  Future<bool> _tryInvokeLegacy(String method, [Object? arguments]) async {
    if (!_channelReady) {
      await initialize();
    }
    if (!_channelReady || !_available) {
      return false;
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return true;
    } on MissingPluginException {
      _markUnavailable();
      return false;
    } on Object {
      _markUnavailable();
      return false;
    }
  }

  void _markUnavailable() {
    _initialized = false;
    _channelReady = false;
    _setAvailable(false);
  }

  void _setAvailable(bool value) {
    if (_available == value) {
      return;
    }
    _available = value;
    notifyListeners();
  }

  Future<void> _handleNativeAction(MethodCall call) async {
    final searchEvent = switch ((call.method, call.arguments)) {
      ('searchQueryChanged', final String query) => HeaderBarSearchQueryChanged(
        query,
      ),
      ('searchSubmitted', final String query) => HeaderBarSearchSubmitted(
        query,
      ),
      ('searchFocusChanged', final bool focused) => HeaderBarSearchFocusChanged(
        focused,
      ),
      ('searchCleared', _) => const HeaderBarSearchCleared(),
      ('searchEscapePressed', _) => const HeaderBarSearchEscapePressed(),
      _ => null,
    };
    if (searchEvent != null) {
      if (!_searchEvents.isClosed) {
        _searchEvents.add(searchEvent);
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
      'exportPdf' => HeaderBarAction.exportPdf,
      'menu' => HeaderBarAction.menu,
      'settings' => HeaderBarAction.settings,
      'keyboardShortcuts' => HeaderBarAction.keyboardShortcuts,
      'markdownAndHtml' => HeaderBarAction.markdownAndHtml,
      'reportIssue' => HeaderBarAction.reportIssue,
      'aboutBusyMark' => HeaderBarAction.aboutBusyMark,
      'viewModeEditor' => HeaderBarAction.viewModeEditor,
      'viewModeSource' => HeaderBarAction.viewModeSource,
      'viewModePreview' => HeaderBarAction.viewModePreview,
      'viewModeSplit' => HeaderBarAction.viewModeSplit,
      'sidebarFiles' => HeaderBarAction.sidebarFiles,
      'sidebarToc' => HeaderBarAction.sidebarToc,
      'sidebarOutline' => HeaderBarAction.sidebarOutline,
      'sidebarGit' => HeaderBarAction.sidebarGit,
      'sidebarHistory' => HeaderBarAction.sidebarHistory,
      _ => null,
    };
  }
}

final linuxHeaderBarServiceProvider = Provider<LinuxHeaderBarService>((ref) {
  final service = LinuxHeaderBarService.instance;
  void notifyConsumers() => ref.notifyListeners();
  service.addListener(notifyConsumers);
  ref.onDispose(() => service.removeListener(notifyConsumers));
  return service;
});

final headerBarActionsProvider = StreamProvider<HeaderBarActionEvent>((ref) {
  return ref.watch(linuxHeaderBarServiceProvider).actionEvents;
});

final headerBarSearchEventsProvider = StreamProvider<HeaderBarSearchEvent>((
  ref,
) {
  return ref.watch(linuxHeaderBarServiceProvider).searchEvents;
});
