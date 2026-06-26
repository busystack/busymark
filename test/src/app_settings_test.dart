import 'package:busymark/src/app/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('window behavior defaults protect unsaved changes', () {
    final settings = AppSettings.defaults();

    expect(settings.confirmCloseWithUnsavedChanges, isTrue);
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

  test('language defaults to system locale', () {
    final settings = AppSettings.defaults();

    expect(settings.localeTag, isNull);
    expect(settings.locale, isNull);
    expect(settings.toJson()['localeTag'], isNull);
  });

  test('language override persists as locale tag', () {
    final settings = AppSettings.fromJson(<String, Object?>{'localeTag': 'de'});

    expect(settings.localeTag, 'de');
    expect(settings.locale, const Locale('de'));
    expect(settings.toJson()['localeTag'], 'de');
    expect(settings.copyWith(localeTag: null).locale, isNull);
  });

  test('window behavior settings persist', () async {
    final store = _MemorySettingsStore();
    final controller = AppSettingsController(store);
    await Future<void>.delayed(Duration.zero);

    await controller.setConfirmCloseWithUnsavedChanges(false);

    expect(store.value['confirmCloseWithUnsavedChanges'], isFalse);
    expect(controller.state.confirmCloseWithUnsavedChanges, isFalse);

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
