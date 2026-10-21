import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final layout in [
    'ordinary',
    'linked ancestor',
    'linked state directory',
  ]) {
    for (final flow in ['settings', 'session', 'recovery']) {
      test('$flow persists through $layout', () async {
        if (!Platform.isLinux) return;
        final root = await Directory.systemTemp.createTemp('bm-linked-state-');
        addTearDown(() => root.delete(recursive: true));
        final real = await Directory(p.join(root.path, 'real')).create();
        final actual = await Directory(p.join(real.path, 'state')).create();
        final ancestorMode = (await real.stat()).mode;
        final String statePath;
        if (layout == 'linked ancestor') {
          final link = await Link(
            p.join(root.path, 'ancestor'),
          ).create(real.path);
          statePath = p.join(link.path, 'state');
        } else if (layout == 'linked state directory') {
          statePath = (await Link(
            p.join(root.path, 'state'),
          ).create(actual.path)).path;
        } else {
          statePath = actual.path;
        }
        if (flow == 'settings') {
          final settings = AppSettings.defaults().copyWith(
            wordWrap: false,
            editorFontSize: 19,
          );
          final store = JsonFileLocalSettingsStore(
            settingsFilePathOverride: p.join(statePath, 'settings.json'),
          );
          await store.save(settings.toJson());
          expect(await store.load(), settings.toJson());
        } else if (flow == 'session') {
          final path = p.join(statePath, 'session.json');
          final store = JsonDocumentSessionStore(filePathOverride: path);
          const session = WorkspaceSessionSnapshot(
            workspacePath: '/workspace',
            tabs: [],
            activeBufferId: null,
          );
          await store.save(session);
          expect((await store.load())?.workspacePath, '/workspace');
          expect((await actual.stat()).mode & 511, 448);
          expect((await File(path).stat()).mode & 511, 384);
        } else {
          final path = p.join(statePath, 'recovery.json');
          final store = JsonDocumentRecoveryStore(filePathOverride: path);
          expect((await store.beginRun()).cleanShutdown, isTrue);
          final draft = DocumentBuffer.untitled(
            id: 'draft',
            name: 'Draft',
            text: 'Retained edit',
          );
          await store.writeEntries([
            DocumentRecoveryEntry.fromBuffer(draft, workspacePath: null),
          ]);
          final reopened = JsonDocumentRecoveryStore(filePathOverride: path);
          final recovered = await reopened.beginRun();
          expect(recovered.cleanShutdown, isFalse);
          expect(recovered.entries.single.text, 'Retained edit');
          await reopened.markCleanShutdown();
          expect(
            (await JsonDocumentRecoveryStore(
              filePathOverride: path,
            ).beginRun()).cleanShutdown,
            isTrue,
          );
          expect((await actual.stat()).mode & 511, 448);
          expect((await File(path).stat()).mode & 511, 384);
        }
        expect((await real.stat()).mode, ancestorMode);
        expect(
          await actual
              .list()
              .where(
                (entity) => p.basename(entity.path).startsWith('.busymark-'),
              )
              .isEmpty,
          isTrue,
        );
        if (layout == 'linked state directory') {
          expect(await Link(statePath).target(), actual.path);
        }
      });
    }
  }
}
