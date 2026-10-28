import 'dart:async';

import 'package:busymark/src/app/window_control_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test(
    'button and native close requests share one pending confirmation',
    () async {
      final native = _FakeNativeWindowController();
      final service = WindowControlService(nativeWindow: native);
      addTearDown(service.dispose);
      await service.initialize();
      final confirmation = Completer<void>();
      var requests = 0;
      service.registerCloseHandler(() {
        requests++;
        return confirmation.future;
      });

      final first = service.requestClose();
      final second = service.requestClose();
      native.listeners.single.onWindowClose();
      expect(second, same(first));
      expect(requests, 1);

      confirmation.complete();
      await first;
      await service.requestClose();
      expect(requests, 2);
      expect(native.closeCount, 0);
    },
  );
  for (final action in <WindowCloseAction?>[
    null,
    WindowCloseAction.save,
    WindowCloseAction.discard,
  ]) {
    for (final allowed in [true, false]) {
      test(
        'final guard follows $action metadata and permits close=$allowed',
        () async {
          final native = _FakeNativeWindowController();
          final service = WindowControlService(nativeWindow: native);
          addTearDown(service.dispose);
          await service.initialize();
          final entered = Completer<void>();
          final release = Completer<bool>();
          final order = <String>[];
          Future<void> metadata() async {
            await Future<void>.value();
            order.add('metadata');
          }

          final closing = service.handleCloseRequest(
            hasUnsavedChanges: action != null,
            confirmCloseWithUnsavedChanges: true,
            showCloseDialog: () async => action,
            saveChanges: () async {
              order.add('save');
              return true;
            },
            beforeClose: metadata,
            discardChanges: metadata,
            finalCloseGuard: () {
              order.add('guard');
              entered.complete();
              return release.future;
            },
          );
          await entered.future.timeout(const Duration(seconds: 5));
          expect(order, [
            if (action == WindowCloseAction.save) 'save',
            'metadata',
            'guard',
          ]);
          expect(native.closeCount, 0);
          expect(native.preventCloseValues, [true]);
          release.complete(allowed);
          await closing;
          expect(native.closeCount, allowed ? 1 : 0);
          expect(native.preventCloseValues.last, !allowed);
        },
      );
    }
  }

  test('initializes prevent-close interception', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);

    await service.initialize();

    expect(native.preventCloseValues, [true]);
    expect(native.listeners, hasLength(1));
  });

  test('toggles full screen and tracks native window-state changes', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);

    await service.initialize();
    await service.toggleFullScreen();

    expect(native.fullScreenValues, [true]);
    expect(service.isFullScreen, isTrue);

    native.listeners.single.onWindowLeaveFullScreen();
    expect(service.isFullScreen, isFalse);
    native.listeners.single.onWindowEnterFullScreen();
    expect(service.isFullScreen, isTrue);
  });

  test('no dirty documents closes without dialog', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);
    var dialogShown = false;

    await service.handleCloseRequest(
      hasUnsavedChanges: false,
      confirmCloseWithUnsavedChanges: true,
      showCloseDialog: () async {
        dialogShown = true;
        return WindowCloseAction.cancel;
      },
      saveChanges: () async => throw StateError('save should not be called'),
    );

    expect(dialogShown, isFalse);
    expect(native.preventCloseValues, [false]);
    expect(native.closeCount, 1);
  });

  test('dirty documents with confirmation enabled show dialog', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);
    var dialogShown = false;

    await service.handleCloseRequest(
      hasUnsavedChanges: true,
      confirmCloseWithUnsavedChanges: true,
      showCloseDialog: () async {
        dialogShown = true;
        return WindowCloseAction.cancel;
      },
      saveChanges: () async => true,
    );

    expect(dialogShown, isTrue);
    expect(native.closeCount, 0);
    expect(native.preventCloseValues, [true]);
  });

  test('dirty documents with confirmation disabled close directly', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);
    var dialogShown = false;

    await service.handleCloseRequest(
      hasUnsavedChanges: true,
      confirmCloseWithUnsavedChanges: false,
      showCloseDialog: () async {
        dialogShown = true;
        return WindowCloseAction.cancel;
      },
      saveChanges: () async => throw StateError('save should not be called'),
    );

    expect(dialogShown, isFalse);
    expect(native.preventCloseValues, [false]);
    expect(native.closeCount, 1);
  });

  test('discard closes after disabling prevent-close', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);

    await service.handleCloseRequest(
      hasUnsavedChanges: true,
      confirmCloseWithUnsavedChanges: true,
      showCloseDialog: () async => WindowCloseAction.discard,
      saveChanges: () async => throw StateError('save should not be called'),
    );

    expect(native.preventCloseValues, [false]);
    expect(native.closeCount, 1);
  });

  test('save closes only when saving succeeds', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);
    var saveCount = 0;

    await service.handleCloseRequest(
      hasUnsavedChanges: true,
      confirmCloseWithUnsavedChanges: true,
      showCloseDialog: () async => WindowCloseAction.save,
      saveChanges: () async {
        saveCount++;
        return true;
      },
    );

    expect(saveCount, 1);
    expect(native.preventCloseValues, [false]);
    expect(native.closeCount, 1);
  });

  test('save failure keeps the app open', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);
    var saveCount = 0;

    await service.handleCloseRequest(
      hasUnsavedChanges: true,
      confirmCloseWithUnsavedChanges: true,
      showCloseDialog: () async => WindowCloseAction.save,
      saveChanges: () async {
        saveCount++;
        return false;
      },
    );

    expect(saveCount, 1);
    expect(native.preventCloseValues, [true]);
    expect(native.closeCount, 0);
  });
}

class _FakeNativeWindowController implements NativeWindowController {
  final preventCloseValues = <bool>[];
  final fullScreenValues = <bool>[];
  final listeners = <WindowListener>[];
  var closeCount = 0;
  var fullScreen = false;

  @override
  Future<void> setPreventClose(bool value) async {
    preventCloseValues.add(value);
  }

  @override
  Future<void> close() async {
    closeCount++;
  }

  @override
  Future<bool> isFullScreen() async => fullScreen;

  @override
  Future<void> setFullScreen(bool value) async {
    fullScreen = value;
    fullScreenValues.add(value);
  }

  @override
  void addListener(WindowListener listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(WindowListener listener) {
    listeners.remove(listener);
  }
}
