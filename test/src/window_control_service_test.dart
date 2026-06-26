import 'package:busymark/src/app/window_control_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test('initializes prevent-close interception', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);

    await service.initialize();

    expect(native.preventCloseValues, [true]);
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
  final listeners = <WindowListener>[];
  var closeCount = 0;

  @override
  Future<void> setPreventClose(bool value) async {
    preventCloseValues.add(value);
  }

  @override
  Future<void> close() async {
    closeCount++;
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
