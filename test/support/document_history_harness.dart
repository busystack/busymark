import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/editor/document_edit_history.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real workspace history and edit producers with disposable memory stores.
class DocumentHistoryHarness {
  DocumentHistoryHarness._(this.container, this.controller);

  static Future<DocumentHistoryHarness> create({
    DocumentViewModePreference mode = DocumentViewModePreference.editor,
  }) async {
    final container = ProviderContainer(
      overrides: [
        localSettingsStoreProvider.overrideWithValue(_HistorySettings()),
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
      ],
    );
    final settings = container.read(appSettingsControllerProvider.notifier);
    await settings.waitUntilLoaded();
    await settings.setAutoSave(false);
    await settings.setValidateOnEdit(false);
    final controller = container.read(workspaceControllerProvider.notifier);
    await controller.createMarkdownFile();
    controller.updateActiveEditorMode(mode);
    controller.updateActiveText('abc');
    return DocumentHistoryHarness._(container, controller);
  }

  final ProviderContainer container;
  final WorkspaceController controller;
  DocumentBuffer get buffer =>
      container.read(workspaceControllerProvider).activeBuffer!;

  DocumentEditBase readBase() => DocumentEditBase(
    buffer.text,
    buffer.revision,
    buffer.editorState.undoState,
  );

  TextEditingValue? undoText() =>
      controller.undoActiveBuffer() ? _editingValue : null;
  TextEditingValue? redoText() =>
      controller.redoActiveBuffer() ? _editingValue : null;
  TextEditingValue get _editingValue => TextEditingValue(
    text: buffer.text,
    selection: buffer.editorState.selection,
  );

  void dispose() => container.dispose();
}

class _HistorySettings implements LocalSettingsStore {
  @override
  Future<Map<String, Object?>> load() async => AppSettings.defaults().toJson();
  @override
  Future<void> save(Map<String, Object?> values) async {}
}
