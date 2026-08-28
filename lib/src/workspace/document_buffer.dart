import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../app/app_settings.dart';
import '../editor/source/source_search.dart';
import '../editor/wysiwyg/wysiwyg_session_state.dart';
import 'text_format_metadata.dart';
import 'workspace_file_snapshot.dart';

const Object _bufferUnset = Object();

enum DocumentDiskState { present, changed, deleted, conflict }

class DocumentUndoState {
  const DocumentUndoState({this.undo = const [], this.redo = const []});

  static const historyLimit = 100;

  final List<String> undo;
  final List<String> redo;

  DocumentUndoState push(String text) => DocumentUndoState(
    undo: List.unmodifiable(
      [...undo, text].skip(math.max(0, undo.length + 1 - historyLimit)),
    ),
    redo: const [],
  );

  DocumentUndoState afterUndo(String currentText) => DocumentUndoState(
    undo: List.unmodifiable(undo.take(undo.length - 1)),
    redo: List.unmodifiable(
      [...redo, currentText].skip(math.max(0, redo.length + 1 - historyLimit)),
    ),
  );

  DocumentUndoState afterRedo(String currentText) => DocumentUndoState(
    undo: List.unmodifiable(
      [...undo, currentText].skip(math.max(0, undo.length + 1 - historyLimit)),
    ),
    redo: List.unmodifiable(redo.take(redo.length - 1)),
  );
}

class DocumentEditorState {
  const DocumentEditorState({
    this.mode = DocumentViewModePreference.editor,
    this.selection = const TextSelection.collapsed(offset: 0),
    this.scrollOffset = 0,
    this.foldedRegionKeys = const {},
    this.searchOptions = const SourceSearchOptions(),
    this.searchReplacement = '',
    this.searchCurrentMatchIndex,
    this.undoState = const DocumentUndoState(),
    this.wysiwygState = const WysiwygEditorSessionState(),
  });

  final DocumentViewModePreference mode;
  final TextSelection selection;
  final double scrollOffset;
  final Set<String> foldedRegionKeys;
  final SourceSearchOptions searchOptions;
  final String searchReplacement;
  final int? searchCurrentMatchIndex;
  final DocumentUndoState undoState;
  final WysiwygEditorSessionState wysiwygState;

  DocumentEditorState copyWith({
    DocumentViewModePreference? mode,
    TextSelection? selection,
    double? scrollOffset,
    Set<String>? foldedRegionKeys,
    SourceSearchOptions? searchOptions,
    String? searchReplacement,
    Object? searchCurrentMatchIndex = _bufferUnset,
    DocumentUndoState? undoState,
    WysiwygEditorSessionState? wysiwygState,
  }) {
    return DocumentEditorState(
      mode: mode ?? this.mode,
      selection: selection ?? this.selection,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      foldedRegionKeys: Set.unmodifiable(
        foldedRegionKeys ?? this.foldedRegionKeys,
      ),
      searchOptions: searchOptions ?? this.searchOptions,
      searchReplacement: searchReplacement ?? this.searchReplacement,
      searchCurrentMatchIndex: identical(searchCurrentMatchIndex, _bufferUnset)
          ? this.searchCurrentMatchIndex
          : searchCurrentMatchIndex as int?,
      undoState: undoState ?? this.undoState,
      wysiwygState: wysiwygState ?? this.wysiwygState,
    );
  }

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'selectionBase': selection.baseOffset,
    'selectionExtent': selection.extentOffset,
    'scrollOffset': scrollOffset,
    'foldedRegionKeys': foldedRegionKeys.toList(),
    'searchQuery': searchOptions.query,
    'searchCaseSensitive': searchOptions.caseSensitive,
    'searchWholeWord': searchOptions.wholeWord,
    'searchRegex': searchOptions.regex,
    'searchReplacement': searchReplacement,
    'searchCurrentMatchIndex': searchCurrentMatchIndex,
    'wysiwygState': wysiwygState.toJson(),
  };

  factory DocumentEditorState.fromJson(Map<String, Object?> json) {
    return DocumentEditorState(
      mode: DocumentViewModePreference.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => DocumentViewModePreference.editor,
      ),
      selection: TextSelection(
        baseOffset: (json['selectionBase'] as num?)?.toInt() ?? 0,
        extentOffset: (json['selectionExtent'] as num?)?.toInt() ?? 0,
      ),
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0,
      foldedRegionKeys:
          (json['foldedRegionKeys'] as List?)
              ?.map((value) => value.toString())
              .toSet() ??
          const {},
      searchOptions: SourceSearchOptions(
        query: json['searchQuery']?.toString() ?? '',
        caseSensitive: json['searchCaseSensitive'] as bool? ?? false,
        wholeWord: json['searchWholeWord'] as bool? ?? false,
        regex: json['searchRegex'] as bool? ?? false,
      ),
      searchReplacement: json['searchReplacement']?.toString() ?? '',
      searchCurrentMatchIndex: (json['searchCurrentMatchIndex'] as num?)
          ?.toInt(),
      wysiwygState: WysiwygEditorSessionState.fromJson(
        (json['wysiwygState'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
    );
  }
}

class DocumentBuffer {
  const DocumentBuffer({
    required this.id,
    required this.text,
    required this.lastSavedText,
    required this.dirty,
    this.filePath,
    this.untitledName,
    this.diskSnapshot,
    this.format = TextFormatMetadata.utf8Lf,
    this.editorState = const DocumentEditorState(),
    this.revision = 0,
    this.diskState = DocumentDiskState.present,
    this.diskVersionText,
    this.diskVersionSnapshot,
    this.recovered = false,
  });

  factory DocumentBuffer.file({
    required String id,
    required String filePath,
    required String text,
    required WorkspaceFileSnapshot snapshot,
    required TextFormatMetadata format,
    DocumentViewModePreference mode = DocumentViewModePreference.editor,
  }) {
    return DocumentBuffer(
      id: id,
      filePath: filePath,
      text: text,
      lastSavedText: text,
      dirty: false,
      diskSnapshot: snapshot,
      format: format,
      editorState: DocumentEditorState(mode: mode),
    );
  }

  factory DocumentBuffer.untitled({
    required String id,
    required String name,
    String text = '',
    DocumentViewModePreference mode = DocumentViewModePreference.editor,
  }) {
    return DocumentBuffer(
      id: id,
      untitledName: name,
      text: text,
      lastSavedText: '',
      dirty: true,
      editorState: DocumentEditorState(mode: mode),
    );
  }

  final String id;
  final String? filePath;
  final String? untitledName;
  final String text;
  final String lastSavedText;
  final bool dirty;
  final WorkspaceFileSnapshot? diskSnapshot;
  final TextFormatMetadata format;
  final DocumentEditorState editorState;
  final int revision;
  final DocumentDiskState diskState;
  final String? diskVersionText;
  final WorkspaceFileSnapshot? diskVersionSnapshot;
  final bool recovered;

  bool get isUntitled => filePath == null;
  bool get isDirty => dirty;
  bool get hasConflict => diskState == DocumentDiskState.conflict;
  bool get deletedOnDisk => diskState == DocumentDiskState.deleted;
  String get identity => filePath ?? id;
  String get displayName => untitledName ?? filePath?.split('/').last ?? id;

  DocumentBuffer edited(String nextText) {
    if (nextText == text) {
      return this;
    }
    return copyWith(
      text: nextText,
      dirty: nextText != lastSavedText || isUntitled,
      format: format.copyWith(hasFinalNewline: nextText.endsWith('\n')),
      revision: revision + 1,
      editorState: editorState.copyWith(
        undoState: editorState.undoState.push(text),
      ),
    );
  }

  DocumentBuffer copyWith({
    Object? filePath = _bufferUnset,
    Object? untitledName = _bufferUnset,
    String? text,
    String? lastSavedText,
    bool? dirty,
    Object? diskSnapshot = _bufferUnset,
    TextFormatMetadata? format,
    DocumentEditorState? editorState,
    int? revision,
    DocumentDiskState? diskState,
    Object? diskVersionText = _bufferUnset,
    Object? diskVersionSnapshot = _bufferUnset,
    bool? recovered,
  }) {
    return DocumentBuffer(
      id: id,
      filePath: identical(filePath, _bufferUnset)
          ? this.filePath
          : filePath as String?,
      untitledName: identical(untitledName, _bufferUnset)
          ? this.untitledName
          : untitledName as String?,
      text: text ?? this.text,
      lastSavedText: lastSavedText ?? this.lastSavedText,
      dirty: dirty ?? this.dirty,
      diskSnapshot: identical(diskSnapshot, _bufferUnset)
          ? this.diskSnapshot
          : diskSnapshot as WorkspaceFileSnapshot?,
      format: format ?? this.format,
      editorState: editorState ?? this.editorState,
      revision: revision ?? this.revision,
      diskState: diskState ?? this.diskState,
      diskVersionText: identical(diskVersionText, _bufferUnset)
          ? this.diskVersionText
          : diskVersionText as String?,
      diskVersionSnapshot: identical(diskVersionSnapshot, _bufferUnset)
          ? this.diskVersionSnapshot
          : diskVersionSnapshot as WorkspaceFileSnapshot?,
      recovered: recovered ?? this.recovered,
    );
  }
}
