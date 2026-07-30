import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/busymark_design.dart';

enum AppViewMode { editor, source, preview, split }

@immutable
class HeaderBarLabels {
  const HeaderBarLabels({
    required this.editor,
    required this.source,
    required this.preview,
    required this.split,
    required this.viewMode,
    required this.editorShortcut,
    required this.sourceShortcut,
    required this.previewShortcut,
    required this.splitShortcut,
    required this.search,
    required this.refresh,
    required this.menu,
    required this.sidebar,
    required this.sidebarShortcut,
    required this.back,
    required this.save,
    required this.settings,
    required this.settingsShortcut,
    required this.keyboardShortcuts,
    required this.keyboardShortcutsShortcut,
    required this.markdownAndHtml,
    required this.markdownAndHtmlShortcut,
    required this.reportIssue,
    required this.aboutBusyMark,
  });

  final String editor;
  final String source;
  final String preview;
  final String split;
  final String viewMode;
  final String editorShortcut;
  final String sourceShortcut;
  final String previewShortcut;
  final String splitShortcut;
  final String search;
  final String refresh;
  final String menu;
  final String sidebar;
  final String sidebarShortcut;
  final String back;
  final String save;
  final String settings;
  final String settingsShortcut;
  final String keyboardShortcuts;
  final String keyboardShortcutsShortcut;
  final String markdownAndHtml;
  final String markdownAndHtmlShortcut;
  final String reportIssue;
  final String aboutBusyMark;

  Map<String, String> toMap() => {
    'editor': editor,
    'source': source,
    'preview': preview,
    'split': split,
    'viewMode': viewMode,
    'editorShortcut': editorShortcut,
    'sourceShortcut': sourceShortcut,
    'previewShortcut': previewShortcut,
    'splitShortcut': splitShortcut,
    'search': search,
    'refresh': refresh,
    'menu': menu,
    'sidebar': sidebar,
    'sidebarShortcut': sidebarShortcut,
    'back': back,
    'save': save,
    'settings': settings,
    'settingsShortcut': settingsShortcut,
    'keyboardShortcuts': keyboardShortcuts,
    'keyboardShortcutsShortcut': keyboardShortcutsShortcut,
    'markdownAndHtml': markdownAndHtml,
    'markdownAndHtmlShortcut': markdownAndHtmlShortcut,
    'reportIssue': reportIssue,
    'aboutBusyMark': aboutBusyMark,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeaderBarLabels && mapEquals(toMap(), other.toMap());
  }

  @override
  int get hashCode => Object.hashAll(toMap().entries);
}

@immutable
class HeaderBarTheme {
  const HeaderBarTheme({
    required this.preferDark,
    required this.backgroundColor,
    required this.sidebarBackgroundColor,
    required this.foregroundColor,
    required this.sidebarBorderColor,
    required this.modalBarrierColor,
  });

  factory HeaderBarTheme.fromContext(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return HeaderBarTheme(
      preferDark: Theme.of(context).brightness == Brightness.dark,
      backgroundColor: colors.view,
      sidebarBackgroundColor: colors.sidebar,
      foregroundColor: colors.foreground,
      sidebarBorderColor: colors.sidebarBorder,
      modalBarrierColor: colors.shade,
    );
  }

  final bool preferDark;
  final Color backgroundColor;
  final Color sidebarBackgroundColor;
  final Color foregroundColor;
  final Color sidebarBorderColor;
  final Color modalBarrierColor;

  Map<String, Object> toMap() => {
    'preferDark': preferDark,
    'backgroundColor': _cssColor(backgroundColor),
    'sidebarBackgroundColor': _cssColor(sidebarBackgroundColor),
    'foregroundColor': _cssColor(foregroundColor),
    'sidebarBorderColor': _cssColor(sidebarBorderColor),
    'modalBarrierColor': _cssColor(modalBarrierColor),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeaderBarTheme &&
            preferDark == other.preferDark &&
            backgroundColor == other.backgroundColor &&
            sidebarBackgroundColor == other.sidebarBackgroundColor &&
            foregroundColor == other.foregroundColor &&
            sidebarBorderColor == other.sidebarBorderColor &&
            modalBarrierColor == other.modalBarrierColor;
  }

  @override
  int get hashCode => Object.hashAll([
    preferDark,
    backgroundColor,
    sidebarBackgroundColor,
    foregroundColor,
    sidebarBorderColor,
    modalBarrierColor,
  ]);
}

@immutable
class HeaderBarConfiguration {
  const HeaderBarConfiguration({
    this.revision = 0,
    required this.title,
    required this.viewMode,
    required this.searchQuery,
    required this.textDirection,
    required this.canRefresh,
    required this.documentControlsVisible,
    required this.searchActive,
    required this.searchVisible,
    required this.sidebarVisible,
    required this.sidebarToggleVisible,
    required this.backVisible,
    required this.modalBarrierDepth,
    required this.sidebarWidth,
    required this.labels,
    required this.theme,
  }) : assert(revision >= 0),
       assert(modalBarrierDepth >= 0);

  final int revision;
  final String title;
  final AppViewMode viewMode;
  final String searchQuery;
  final TextDirection textDirection;
  final bool canRefresh;
  final bool documentControlsVisible;
  final bool searchActive;
  final bool searchVisible;
  final bool sidebarVisible;
  final bool sidebarToggleVisible;
  final bool backVisible;
  final int modalBarrierDepth;
  final double sidebarWidth;
  final HeaderBarLabels labels;
  final HeaderBarTheme theme;

  bool get modalBarrierVisible => modalBarrierDepth > 0;

  HeaderBarConfiguration copyWith({
    int? revision,
    String? title,
    AppViewMode? viewMode,
    String? searchQuery,
    TextDirection? textDirection,
    bool? canRefresh,
    bool? documentControlsVisible,
    bool? searchActive,
    bool? searchVisible,
    bool? sidebarVisible,
    bool? sidebarToggleVisible,
    bool? backVisible,
    int? modalBarrierDepth,
    double? sidebarWidth,
    HeaderBarLabels? labels,
    HeaderBarTheme? theme,
  }) {
    return HeaderBarConfiguration(
      revision: revision ?? this.revision,
      title: title ?? this.title,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      textDirection: textDirection ?? this.textDirection,
      canRefresh: canRefresh ?? this.canRefresh,
      documentControlsVisible:
          documentControlsVisible ?? this.documentControlsVisible,
      searchActive: searchActive ?? this.searchActive,
      searchVisible: searchVisible ?? this.searchVisible,
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      sidebarToggleVisible: sidebarToggleVisible ?? this.sidebarToggleVisible,
      backVisible: backVisible ?? this.backVisible,
      modalBarrierDepth: modalBarrierDepth ?? this.modalBarrierDepth,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      labels: labels ?? this.labels,
      theme: theme ?? this.theme,
    );
  }

  Map<String, Object> toMap() => {
    'revision': revision,
    'title': title,
    'viewMode': viewMode.name,
    'searchQuery': searchQuery,
    'textDirection': textDirection == TextDirection.rtl ? 'rtl' : 'ltr',
    'canRefresh': canRefresh,
    'documentControlsVisible': documentControlsVisible,
    'searchActive': searchActive,
    'searchVisible': searchVisible,
    'sidebarVisible': sidebarVisible,
    'sidebarToggleVisible': sidebarToggleVisible,
    'backVisible': backVisible,
    'modalBarrierVisible': modalBarrierVisible,
    'modalBarrierDepth': modalBarrierDepth,
    'sidebarWidth': sidebarWidth,
    'labels': labels.toMap(),
    'theme': theme.toMap(),
  };

  bool hasSameContentAs(HeaderBarConfiguration other) {
    return title == other.title &&
        viewMode == other.viewMode &&
        searchQuery == other.searchQuery &&
        textDirection == other.textDirection &&
        canRefresh == other.canRefresh &&
        documentControlsVisible == other.documentControlsVisible &&
        searchActive == other.searchActive &&
        searchVisible == other.searchVisible &&
        sidebarVisible == other.sidebarVisible &&
        sidebarToggleVisible == other.sidebarToggleVisible &&
        backVisible == other.backVisible &&
        modalBarrierDepth == other.modalBarrierDepth &&
        sidebarWidth == other.sidebarWidth &&
        labels == other.labels &&
        theme == other.theme;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HeaderBarConfiguration &&
            revision == other.revision &&
            hasSameContentAs(other);
  }

  @override
  int get hashCode => Object.hashAll([
    revision,
    title,
    viewMode,
    searchQuery,
    textDirection,
    canRefresh,
    documentControlsVisible,
    searchActive,
    searchVisible,
    sidebarVisible,
    sidebarToggleVisible,
    backVisible,
    modalBarrierDepth,
    sidebarWidth,
    labels,
    theme,
  ]);
}

typedef HeaderBarConfigurationApplier =
    Future<bool> Function(HeaderBarConfiguration configuration);

/// Serializes native header updates, coalesces pending state, and assigns the
/// monotonic revisions that make the native side latest-wins.
class HeaderBarConfigurationSynchronizer {
  HeaderBarConfigurationSynchronizer({
    required HeaderBarConfigurationApplier apply,
  }) : _apply = apply;

  final HeaderBarConfigurationApplier _apply;
  final Map<int, List<Completer<bool>>> _waiters = {};

  HeaderBarConfiguration? _baseConfiguration;
  HeaderBarConfiguration? _desiredConfiguration;
  HeaderBarConfiguration? _appliedConfiguration;
  Future<void>? _drainFuture;
  var _lastRevision = 0;
  var _modalBarrierDepth = 0;

  HeaderBarConfiguration? get desiredConfiguration => _desiredConfiguration;
  HeaderBarConfiguration? get appliedConfiguration => _appliedConfiguration;
  int get latestRevision => _lastRevision;

  bool isLatestRevision(int revision) {
    return _desiredConfiguration?.revision == revision;
  }

  Future<bool> setConfiguration(HeaderBarConfiguration configuration) {
    _baseConfiguration = configuration.copyWith(revision: 0);
    return _enqueueEffectiveConfiguration();
  }

  Future<bool> setModalBarrierDepth(int depth) {
    final effectiveDepth = depth < 0 ? 0 : depth;
    if (_modalBarrierDepth == effectiveDepth) {
      return _waitForDesiredConfiguration();
    }
    _modalBarrierDepth = effectiveDepth;
    return _enqueueEffectiveConfiguration();
  }

  Future<bool> setModalBarrierVisible(bool visible) {
    return setModalBarrierDepth(visible ? 1 : 0);
  }

  Future<bool> _enqueueEffectiveConfiguration() {
    final base = _baseConfiguration;
    if (base == null) {
      return Future<bool>.value(true);
    }
    final effective = base.copyWith(
      revision: 0,
      modalBarrierDepth: _modalBarrierDepth,
    );
    final desired = _desiredConfiguration;
    if (desired != null && desired.hasSameContentAs(effective)) {
      if (_appliedConfiguration case final applied?
          when applied.revision >= desired.revision) {
        return Future<bool>.value(true);
      }
      final future = _waitForRevision(desired.revision);
      _drainFuture ??= _drain();
      return future;
    }
    final applied = _appliedConfiguration;
    if (_drainFuture == null &&
        applied != null &&
        applied.hasSameContentAs(effective)) {
      return Future<bool>.value(true);
    }

    final revision = ++_lastRevision;
    _desiredConfiguration = effective.copyWith(revision: revision);
    final future = _waitForRevision(revision);
    _drainFuture ??= _drain();
    return future;
  }

  Future<bool> _waitForDesiredConfiguration() {
    final desired = _desiredConfiguration;
    if (desired == null ||
        _appliedConfiguration?.revision == desired.revision) {
      return Future<bool>.value(true);
    }
    final future = _waitForRevision(desired.revision);
    _drainFuture ??= _drain();
    return future;
  }

  Future<bool> _waitForRevision(int revision) {
    if (_appliedConfiguration case final applied?
        when applied.revision >= revision) {
      return Future<bool>.value(true);
    }
    final completer = Completer<bool>();
    _waiters.putIfAbsent(revision, () => []).add(completer);
    return completer.future;
  }

  Future<void> _drain() async {
    try {
      while (true) {
        final target = _desiredConfiguration;
        if (target == null ||
            _appliedConfiguration?.revision == target.revision) {
          return;
        }
        var succeeded = false;
        try {
          succeeded = await _apply(target);
        } on Object {
          succeeded = false;
        }
        if (succeeded) {
          _appliedConfiguration = target;
          _completeWaitersThrough(target.revision, succeeded: true);
          continue;
        }
        if (_desiredConfiguration?.revision != target.revision) {
          continue;
        }
        _completeWaitersThrough(target.revision, succeeded: false);
        return;
      }
    } finally {
      _drainFuture = null;
    }
  }

  void _completeWaitersThrough(int revision, {required bool succeeded}) {
    final completedRevisions = _waiters.keys
        .where((candidate) => candidate <= revision)
        .toList(growable: false);
    for (final completedRevision in completedRevisions) {
      final completers = _waiters.remove(completedRevision);
      if (completers == null) {
        continue;
      }
      for (final completer in completers) {
        if (!completer.isCompleted) {
          completer.complete(succeeded);
        }
      }
    }
  }
}

class HeaderBarConfigurationDefaults extends InheritedWidget {
  const HeaderBarConfigurationDefaults({
    super.key,
    required this.configuration,
    required super.child,
  });

  final HeaderBarConfiguration configuration;

  static HeaderBarConfiguration of(BuildContext context) {
    final defaults = context
        .dependOnInheritedWidgetOfExactType<HeaderBarConfigurationDefaults>();
    assert(defaults != null, 'No HeaderBarConfigurationDefaults in context');
    return defaults!.configuration;
  }

  @override
  bool updateShouldNotify(HeaderBarConfigurationDefaults oldWidget) {
    return configuration != oldWidget.configuration;
  }
}

class HeaderBarConfigurationPublisher extends StatefulWidget {
  const HeaderBarConfigurationPublisher({
    super.key,
    required this.synchronizer,
    required this.configuration,
    required this.enabled,
    required this.child,
  });

  final HeaderBarConfigurationSynchronizer synchronizer;
  final HeaderBarConfiguration configuration;
  final bool enabled;
  final Widget child;

  @override
  State<HeaderBarConfigurationPublisher> createState() =>
      _HeaderBarConfigurationPublisherState();
}

class _HeaderBarConfigurationPublisherState
    extends State<HeaderBarConfigurationPublisher> {
  @override
  void initState() {
    super.initState();
    _publish();
  }

  @override
  void didUpdateWidget(HeaderBarConfigurationPublisher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled ||
        widget.synchronizer != oldWidget.synchronizer ||
        widget.configuration != oldWidget.configuration) {
      _publish();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _publish() {
    if (!widget.enabled) {
      return;
    }
    unawaited(widget.synchronizer.setConfiguration(widget.configuration));
  }
}

String _cssColor(Color color) {
  final alpha = (color.a).clamp(0.0, 1.0).toStringAsFixed(3);
  return 'rgba(${(color.r * 255).round()},'
      '${(color.g * 255).round()},'
      '${(color.b * 255).round()},'
      '$alpha)';
}
