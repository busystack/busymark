import 'package:busymark/src/app/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test('auto save defaults to enabled', () {
    final settings = AppSettings.defaults();

    expect(settings.autoSave, isTrue);
    expect(settings.toJson()['autoSave'], isTrue);
  });

  test('remote images default to blocked', () {
    final settings = AppSettings.defaults();

    expect(settings.allowRemoteImages, isFalse);
    expect(settings.remoteImageAllowedWorkspacePaths, isEmpty);
    expect(settings.allowsRemoteImagesForWorkspace('/tmp/docs'), isFalse);
    expect(settings.toJson()['allowRemoteImages'], isFalse);
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

  test('legacy Norwegian locale tag migrates to Bokmal', () {
    final settings = AppSettings.fromJson(<String, Object?>{'localeTag': 'no'});

    expect(settings.localeTag, 'nb');
    expect(settings.locale, const Locale('nb'));
    expect(settings.toJson()['localeTag'], 'nb');
  });

  test('unused product settings are not persisted', () {
    final json = AppSettings.defaults().toJson();

    expect(json, isNot(containsPair('previewMode', anything)));
    expect(json, isNot(containsPair('validationLevel', anything)));
    expect(json, isNot(containsPair('checkExternalLinks', anything)));
    expect(json, isNot(containsPair('checkExternalImages', anything)));
    expect(
      json,
      isNot(containsPair('officialBuilderIntegrationEnabled', anything)),
    );
  });

  test('window behavior settings persist', () async {
    final store = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [localSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.setConfirmCloseWithUnsavedChanges(false);

    expect(store.value['confirmCloseWithUnsavedChanges'], isFalse);
    expect(
      container
          .read(appSettingsControllerProvider)
          .confirmCloseWithUnsavedChanges,
      isFalse,
    );
  });

  test('auto save setting persists', () async {
    final store = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [localSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.setAutoSave(false);

    expect(store.value['autoSave'], isFalse);
    expect(container.read(appSettingsControllerProvider).autoSave, isFalse);
  });

  test('remote image permissions persist globally and per workspace', () async {
    final store = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [localSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.allowRemoteImagesForWorkspace('/tmp/docs/../docs');

    var settings = container.read(appSettingsControllerProvider);
    expect(settings.allowRemoteImages, isFalse);
    expect(settings.allowsRemoteImagesForWorkspace('/tmp/docs'), isTrue);
    expect(settings.allowsRemoteImagesForWorkspace('/tmp/other'), isFalse);
    expect(store.value['remoteImageAllowedWorkspacePaths'], ['/tmp/docs']);

    await controller.setAllowRemoteImages(true);

    settings = container.read(appSettingsControllerProvider);
    expect(settings.allowRemoteImages, isTrue);
    expect(settings.allowsRemoteImagesForWorkspace('/tmp/other'), isTrue);
    expect(store.value['allowRemoteImages'], isTrue);

    await controller.clearRemoteImageWorkspacePermissions();

    settings = container.read(appSettingsControllerProvider);
    expect(settings.remoteImageAllowedWorkspacePaths, isEmpty);
    expect(store.value['remoteImageAllowedWorkspacePaths'], isEmpty);
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
