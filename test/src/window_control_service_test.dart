import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test('initializes prevent-close and always-on-top from settings', () async {
    final native = _FakeNativeWindowController();
    final service = WindowControlService(nativeWindow: native);

    final applied = await service.initialize(
      AppSettings.defaults().copyWith(alwaysOnTop: true),
    );

    expect(applied, isTrue);
    expect(native.alwaysOnTopValues, [true]);
    expect(native.preventCloseValues, [true]);
  });

  test(
    'initialization reports unsupported always-on-top without breaking close interception',
    () async {
      final native = _FakeNativeWindowController(alwaysOnTopApplied: false);
      final service = WindowControlService(nativeWindow: native);

      final applied = await service.initialize(
        AppSettings.defaults().copyWith(alwaysOnTop: true),
      );

      expect(applied, isFalse);
      expect(native.alwaysOnTopValues, [true]);
      expect(native.preventCloseValues, [true]);
    },
  );

  test(
    'reapplies always-on-top even when the requested value repeats',
    () async {
      final native = _FakeNativeWindowController();
      final service = WindowControlService(nativeWindow: native);

      await service.applyAlwaysOnTop(true);
      await service.applyAlwaysOnTop(true);

      expect(native.alwaysOnTopValues, [true, true]);
    },
  );

  test('always-on-top failure is surfaced to callers', () async {
    final native = _FakeNativeWindowController(alwaysOnTopApplied: false);
    final service = WindowControlService(nativeWindow: native);

    await expectLater(
      service.applyAlwaysOnTop(true),
      throwsA(isA<WindowControlException>()),
    );

    expect(native.alwaysOnTopValues, [true]);
  });

  test('always-on-top support is queried from native window layer', () async {
    final native = _FakeNativeWindowController(alwaysOnTopSupported: false);
    final service = WindowControlService(nativeWindow: native);

    expect(await service.isAlwaysOnTopSupported(), isFalse);
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
  _FakeNativeWindowController({
    this.alwaysOnTopApplied = true,
    this.alwaysOnTopSupported = true,
  });

  final bool alwaysOnTopApplied;
  final bool alwaysOnTopSupported;
  final preventCloseValues = <bool>[];
  final alwaysOnTopValues = <bool>[];
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
  Future<bool> isAlwaysOnTopSupported() async {
    return alwaysOnTopSupported;
  }

  @override
  Future<bool> setAlwaysOnTop(bool value) async {
    alwaysOnTopValues.add(value);
    return alwaysOnTopApplied;
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
