import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../platform/linux_header_bar_service.dart';
import 'app_settings.dart';

enum WindowCloseAction { cancel, discard, save }

abstract interface class NativeWindowController {
  Future<void> setPreventClose(bool value);

  Future<void> close();

  Future<bool> isAlwaysOnTopSupported();

  Future<bool> setAlwaysOnTop(bool value);

  void addListener(WindowListener listener);

  void removeListener(WindowListener listener);
}

class WindowControlException implements Exception {
  const WindowControlException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WindowManagerNativeWindowController implements NativeWindowController {
  const WindowManagerNativeWindowController();

  @override
  Future<void> setPreventClose(bool value) {
    return _ignoreMissingPlugin(() => windowManager.setPreventClose(value));
  }

  @override
  Future<void> close() {
    return _ignoreMissingPlugin(windowManager.close);
  }

  @override
  Future<bool> isAlwaysOnTopSupported() {
    return LinuxHeaderBarService.instance.isAlwaysOnTopSupported();
  }

  @override
  Future<bool> setAlwaysOnTop(bool value) async {
    await _ignoreMissingPlugin(() => windowManager.setAlwaysOnTop(value));
    return LinuxHeaderBarService.instance.setAlwaysOnTop(value);
  }

  @override
  void addListener(WindowListener listener) {
    windowManager.addListener(listener);
  }

  @override
  void removeListener(WindowListener listener) {
    windowManager.removeListener(listener);
  }

  Future<void> _ignoreMissingPlugin(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      // Widget tests do not have the native window_manager plugin attached.
    }
  }
}

class WindowControlService {
  WindowControlService({required NativeWindowController nativeWindow})
    : _nativeWindow = nativeWindow;

  final NativeWindowController _nativeWindow;
  WindowListener? _listener;
  var _closeInProgress = false;

  Future<bool> initialize(AppSettings settings) async {
    try {
      await applyAlwaysOnTop(settings.alwaysOnTop);
    } on WindowControlException {
      // Persisted window stacking preferences are best-effort at startup.
      await _nativeWindow.setPreventClose(true);
      return false;
    }
    await _nativeWindow.setPreventClose(true);
    return true;
  }

  Future<bool> isAlwaysOnTopSupported() {
    return _nativeWindow.isAlwaysOnTopSupported();
  }

  Future<void> applyAlwaysOnTop(bool value) async {
    final applied = await _nativeWindow.setAlwaysOnTop(value);
    if (!applied) {
      throw const WindowControlException(
        'Always-on-top is not supported by this desktop environment.',
      );
    }
  }

  void registerCloseHandler(Future<void> Function() onCloseRequest) {
    unregisterCloseHandler();
    final listener = _BusyMarkWindowListener(onCloseRequest);
    _listener = listener;
    _nativeWindow.addListener(listener);
  }

  void unregisterCloseHandler() {
    final listener = _listener;
    if (listener == null) {
      return;
    }
    _nativeWindow.removeListener(listener);
    _listener = null;
  }

  Future<void> handleCloseRequest({
    required bool hasUnsavedChanges,
    required bool confirmCloseWithUnsavedChanges,
    required Future<WindowCloseAction?> Function() showCloseDialog,
    required Future<bool> Function() saveChanges,
  }) async {
    if (_closeInProgress) {
      return;
    }
    if (!hasUnsavedChanges || !confirmCloseWithUnsavedChanges) {
      await closeWindow();
      return;
    }

    final action = await showCloseDialog();
    switch (action) {
      case WindowCloseAction.discard:
        await closeWindow();
      case WindowCloseAction.save:
        if (await saveChanges()) {
          await closeWindow();
        } else {
          await _nativeWindow.setPreventClose(true);
        }
      case WindowCloseAction.cancel:
      case null:
        await _nativeWindow.setPreventClose(true);
    }
  }

  Future<void> closeWindow() async {
    if (_closeInProgress) {
      return;
    }
    _closeInProgress = true;
    await _nativeWindow.setPreventClose(false);
    await _nativeWindow.close();
  }
}

class _BusyMarkWindowListener with WindowListener {
  const _BusyMarkWindowListener(this.onCloseRequest);

  final Future<void> Function() onCloseRequest;

  @override
  void onWindowClose() {
    unawaited(onCloseRequest());
  }
}

final nativeWindowControllerProvider = Provider<NativeWindowController>(
  (ref) => const WindowManagerNativeWindowController(),
);

final windowControlServiceProvider = Provider<WindowControlService>((ref) {
  final service = WindowControlService(
    nativeWindow: ref.watch(nativeWindowControllerProvider),
  );
  ref.onDispose(service.unregisterCloseHandler);
  return service;
});
