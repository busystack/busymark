import 'package:busymark/src/app/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('window behavior defaults protect unsaved changes without pinning', () {
    final settings = AppSettings.defaults();

    expect(settings.confirmCloseWithUnsavedChanges, isTrue);
    expect(settings.alwaysOnTop, isFalse);
  });

  test('document view mode defaults to split', () {
    final settings = AppSettings.defaults();

    expect(settings.documentViewMode, DocumentViewModePreference.split);
    expect(settings.previewVisible, isTrue);
  });

  test('legacy preview visibility migrates to source mode when hidden', () {
    final settings = AppSettings.fromJson(<String, Object?>{
      'previewVisible': false,
    });

    expect(settings.documentViewMode, DocumentViewModePreference.source);
    expect(settings.previewVisible, isFalse);
  });

  test('window behavior settings persist', () async {
    final store = _MemorySettingsStore();
    final controller = AppSettingsController(store);
    await Future<void>.delayed(Duration.zero);

    await controller.setConfirmCloseWithUnsavedChanges(false);
    await controller.setAlwaysOnTop(true);

    expect(store.value['confirmCloseWithUnsavedChanges'], isFalse);
    expect(store.value['alwaysOnTop'], isTrue);
    expect(controller.state.confirmCloseWithUnsavedChanges, isFalse);
    expect(controller.state.alwaysOnTop, isTrue);

    controller.dispose();
  });
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}
