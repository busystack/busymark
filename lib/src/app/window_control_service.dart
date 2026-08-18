import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:window_manager/window_manager.dart';

enum WindowCloseAction { cancel, discard, save }

abstract interface class NativeWindowController {
  Future<void> setPreventClose(bool value);

  Future<bool> isFullScreen();

  Future<void> setFullScreen(bool value);

  Future<void> close();

  void addListener(WindowListener listener);

  void removeListener(WindowListener listener);
}

class WindowManagerNativeWindowController implements NativeWindowController {
  const WindowManagerNativeWindowController();

  @override
  Future<void> setPreventClose(bool value) {
    return _ignoreMissingPlugin(() => windowManager.setPreventClose(value));
  }

  @override
  Future<bool> isFullScreen() async {
    try {
      return await windowManager.isFullScreen();
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setFullScreen(bool value) {
    return _ignoreMissingPlugin(() => windowManager.setFullScreen(value));
  }

  @override
  Future<void> close() {
    return _ignoreMissingPlugin(windowManager.close);
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

class WindowControlService extends ChangeNotifier {
  WindowControlService({required NativeWindowController nativeWindow})
    : _nativeWindow = nativeWindow;

  final NativeWindowController _nativeWindow;
  WindowListener? _listener;
  Future<void> Function()? _onCloseRequest;
  var _closeInProgress = false;
  var _initialized = false;
  var _disposed = false;
  var _fullScreen = false;
  var _fullScreenChangeInProgress = false;

  bool get isFullScreen => _fullScreen;

  Future<void> initialize() async {
    if (_initialized || _disposed) {
      return;
    }
    _initialized = true;
    final listener = _BusyMarkWindowListener(
      onCloseRequest: _handleNativeCloseRequest,
      onFullScreenChanged: _setFullScreen,
    );
    _listener = listener;
    _nativeWindow.addListener(listener);
    await _nativeWindow.setPreventClose(true);
    final fullScreen = await _nativeWindow.isFullScreen();
    if (!_disposed) {
      _setFullScreen(fullScreen);
    }
  }

  void registerCloseHandler(Future<void> Function() onCloseRequest) {
    _onCloseRequest = onCloseRequest;
  }

  void unregisterCloseHandler() {
    _onCloseRequest = null;
  }

  Future<void> toggleFullScreen() async {
    if (_disposed || _fullScreenChangeInProgress) {
      return;
    }
    _fullScreenChangeInProgress = true;
    try {
      final next = !await _nativeWindow.isFullScreen();
      await _nativeWindow.setFullScreen(next);
      if (!_disposed) {
        _setFullScreen(next);
      }
    } finally {
      _fullScreenChangeInProgress = false;
    }
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

  void _handleNativeCloseRequest() {
    final handler = _onCloseRequest;
    if (handler != null) {
      unawaited(handler());
    }
  }

  void _setFullScreen(bool value) {
    if (_disposed || _fullScreen == value) {
      return;
    }
    _fullScreen = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _onCloseRequest = null;
    final listener = _listener;
    if (listener != null) {
      _nativeWindow.removeListener(listener);
      _listener = null;
    }
    super.dispose();
  }
}

class _BusyMarkWindowListener with WindowListener {
  const _BusyMarkWindowListener({
    required this.onCloseRequest,
    required this.onFullScreenChanged,
  });

  final VoidCallback onCloseRequest;
  final ValueChanged<bool> onFullScreenChanged;

  @override
  void onWindowClose() {
    onCloseRequest();
  }

  @override
  void onWindowEnterFullScreen() {
    onFullScreenChanged(true);
  }

  @override
  void onWindowLeaveFullScreen() {
    onFullScreenChanged(false);
  }
}

final nativeWindowControllerProvider = Provider<NativeWindowController>(
  (ref) => const WindowManagerNativeWindowController(),
);

final windowControlServiceProvider =
    ChangeNotifierProvider<WindowControlService>((ref) {
      final service = WindowControlService(
        nativeWindow: ref.watch(nativeWindowControllerProvider),
      );
      return service;
    });
