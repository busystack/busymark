import 'dart:async';
import 'dart:io';

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

  test('editing button direction defaults to horizontal', () {
    final defaults = AppSettings.defaults();
    final missing = AppSettings.fromJson(const <String, Object?>{});
    final unknown = AppSettings.fromJson(const <String, Object?>{
      'editorToolbarDirection': 'diagonal',
    });

    expect(defaults.editorToolbarDirection, EditorToolbarDirection.horizontal);
    expect(missing.editorToolbarDirection, EditorToolbarDirection.horizontal);
    expect(unknown.editorToolbarDirection, EditorToolbarDirection.horizontal);
    expect(defaults.toJson()['editorToolbarDirection'], 'horizontal');
  });

  test('editing button direction round-trips through settings JSON', () {
    final stored = AppSettings.defaults()
        .copyWith(editorToolbarDirection: EditorToolbarDirection.vertical)
        .toJson();
    final reloaded = AppSettings.fromJson(stored);

    expect(reloaded.editorToolbarDirection, EditorToolbarDirection.vertical);
    expect(reloaded.toJson()['editorToolbarDirection'], 'vertical');
  });

  test('remote images default to blocked', () {
    final settings = AppSettings.defaults();

    expect(settings.allowRemoteImages, isFalse);
    expect(settings.remoteImageAllowedWorkspacePaths, isEmpty);
    expect(settings.allowsRemoteImagesForWorkspace('/tmp/docs'), isFalse);
    expect(settings.toJson()['allowRemoteImages'], isFalse);
  });

  test('Git workspaces default to untrusted', () {
    final settings = AppSettings.defaults();

    expect(settings.trustedGitWorkspacePaths, isEmpty);
    expect(settings.trustsGitWorkspace('/tmp/docs'), isFalse);
    expect(settings.toJson()['trustedGitWorkspacePaths'], isEmpty);
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

  test('supported script variants canonicalize to the available catalog', () {
    final settings = AppSettings.fromJson(<String, Object?>{
      'localeTag': 'fa-Arab',
    });

    expect(settings.localeTag, 'fa');
    expect(settings.locale, const Locale('fa'));
  });

  test('regional variants canonicalize and unsupported tags are discarded', () {
    final regional = AppSettings.fromJson(<String, Object?>{
      'localeTag': 'de-DE',
    });
    final unsupported = AppSettings.fromJson(<String, Object?>{
      'localeTag': 'eo',
    });

    expect(regional.localeTag, 'de');
    expect(regional.locale, const Locale('de'));
    expect(unsupported.localeTag, isNull);
    expect(unsupported.locale, isNull);
    expect(AppSettings.defaults().copyWith(localeTag: 'eo').localeTag, isNull);
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

  test('editing button direction setting persists', () async {
    final store = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [localSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appSettingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.setEditorToolbarDirection(EditorToolbarDirection.vertical);

    expect(store.value['editorToolbarDirection'], 'vertical');
    expect(
      container.read(appSettingsControllerProvider).editorToolbarDirection,
      EditorToolbarDirection.vertical,
    );
  });

  test(
    'initial load preserves user actions made before it completes',
    () async {
      final store = _DelayedSettingsStore();
      final container = ProviderContainer(
        overrides: [localSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(appSettingsControllerProvider.notifier);

      final autoSaveFuture = controller.setAutoSave(false);
      final recentFuture = controller.recordOpenedWorkspace(
        path: '/tmp/new.md',
        kind: WorkspaceKindForTest.singleMarkdown,
      );
      var initialActionsCompleted = false;
      unawaited(
        Future.wait([autoSaveFuture, recentFuture]).then((_) {
          initialActionsCompleted = true;
        }),
      );

      await Future<void>.delayed(Duration.zero);
      expect(initialActionsCompleted, isTrue);

      store.completeLoad(
        AppSettings.defaults()
            .copyWith(
              wordWrap: false,
              recentWorkspaces: [
                RecentWorkspace(
                  path: '/tmp/old.md',
                  kind: WorkspaceKindForTest.singleMarkdown,
                  lastOpenedAt: DateTime(2026),
                ),
              ],
            )
            .toJson(),
      );
      await store.saved;

      final settings = container.read(appSettingsControllerProvider);
      expect(settings.wordWrap, isFalse);
      expect(settings.autoSave, isFalse);
      expect(settings.recentWorkspaces.map((item) => item.path), [
        '/tmp/new.md',
        '/tmp/old.md',
      ]);
      expect(store.value['wordWrap'], isFalse);
      expect(store.value['autoSave'], isFalse);
      expect(
        (store.value['recentWorkspaces'] as List)
            .cast<Map<String, Object?>>()
            .map((item) => item['path']),
        ['/tmp/new.md', '/tmp/old.md'],
      );
    },
  );

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

  test(
    'Git workspace trust persists, normalizes, and can be cleared',
    () async {
      final store = _MemorySettingsStore();
      final container = ProviderContainer(
        overrides: [localSettingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final controller = container.read(appSettingsControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.trustGitWorkspace('/tmp/docs/../docs');

      var settings = container.read(appSettingsControllerProvider);
      expect(settings.trustsGitWorkspace('/tmp/docs'), isTrue);
      expect(settings.trustsGitWorkspace('/tmp/other'), isFalse);
      expect(store.value['trustedGitWorkspacePaths'], ['/tmp/docs']);

      await controller.clearTrustedGitWorkspaces();

      settings = container.read(appSettingsControllerProvider);
      expect(settings.trustedGitWorkspacePaths, isEmpty);
      expect(store.value['trustedGitWorkspacePaths'], isEmpty);
    },
  );

  test(
    'Git workspace trust follows the canonical workspace identity',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark-git-trust-');
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final first = await Directory('${root.path}/first').create();
      final second = await Directory('${root.path}/second').create();
      final workspaceLink = Link('${root.path}/workspace');
      await workspaceLink.create(first.path);

      final settings = AppSettings.defaults().copyWith(
        trustedGitWorkspacePaths: [first.path],
      );
      expect(settings.trustsGitWorkspace(workspaceLink.path), isTrue);

      await workspaceLink.delete();
      await workspaceLink.create(second.path);

      expect(settings.trustsGitWorkspace(workspaceLink.path), isFalse);
    },
    skip: Platform.isWindows,
  );

  test(
    'stored Git trust does not follow a replaced canonical path',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-stored-git-trust-',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final trustedPath = await Directory('${root.path}/trusted').create();
      final replacement = await Directory('${root.path}/replacement').create();
      final stored = AppSettings.defaults()
          .copyWith(trustedGitWorkspacePaths: [trustedPath.path])
          .toJson();

      await trustedPath.delete();
      await Link(trustedPath.path).create(replacement.path);
      final reloaded = AppSettings.fromJson(stored);

      expect(reloaded.trustsGitWorkspace(trustedPath.path), isFalse);
      expect(reloaded.trustedGitWorkspacePaths, [trustedPath.path]);
    },
    skip: Platform.isWindows,
  );

  test('Git trust preserves leading and trailing path whitespace', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-git-trust-whitespace-',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });
    final plain = await Directory('${root.path}/repo').create();
    final spaced = await Directory('${root.path}/repo ').create();

    final plainTrusted = AppSettings.fromJson(<String, Object?>{
      'trustedGitWorkspacePaths': [plain.path],
    });
    expect(plainTrusted.trustsGitWorkspace(plain.path), isTrue);
    expect(plainTrusted.trustsGitWorkspace(spaced.path), isFalse);

    final spacedTrusted = AppSettings.fromJson(<String, Object?>{
      'trustedGitWorkspacePaths': [spaced.path],
    });
    expect(spacedTrusted.trustsGitWorkspace(spaced.path), isTrue);
    expect(spacedTrusted.trustsGitWorkspace(plain.path), isFalse);
  });
}

abstract final class WorkspaceKindForTest {
  static const singleMarkdown = 'singleMarkdown';
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

class _DelayedSettingsStore implements LocalSettingsStore {
  final _load = Completer<Map<String, Object?>>();
  final _saved = Completer<void>();
  Map<String, Object?> value = <String, Object?>{};

  Future<void> get saved => _saved.future;

  void completeLoad(Map<String, Object?> json) {
    value = json;
    _load.complete(json);
  }

  @override
  Future<Map<String, Object?>> load() => _load.future;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
    if (!_saved.isCompleted) {
      _saved.complete();
    }
  }
}
