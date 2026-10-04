import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:flutter/material.dart';

/// Accepts editor output and rebuilds from the accepted source, as the workspace
/// does. Selection-only tests retain their separate, non-editable harness.
class WysiwygEditableHarness extends StatefulWidget {
  const WysiwygEditableHarness({
    super.key,
    required this.source,
    required this.clipboard,
    this.session = const WysiwygEditorSessionState(),
    this.externalHistory = false,
    this.insertionRegistry,
  });

  final String source;
  final RichClipboardService clipboard;
  final WysiwygEditorSessionState session;
  final bool externalHistory;
  final BusyMarkClipboardInsertionRegistry? insertionRegistry;

  @override
  State<WysiwygEditableHarness> createState() => WysiwygEditableHarnessState();
}

class WysiwygEditableHarnessState extends State<WysiwygEditableHarness> {
  static const parser = MarkdownParser();
  var editorKey = GlobalKey<BusyMarkWysiwygEditorState>();
  final changes = <String>[];
  final undoSources = <String>[];
  final redoSources = <String>[];
  late String source;
  late BusyDocument document;
  late WysiwygEditorSessionState session;
  final sessions = <String, WysiwygEditorSessionState>{};
  String documentId = 'editable';
  var parses = 0;
  var undoCalls = 0;
  var redoCalls = 0;

  @override
  void initState() {
    super.initState();
    source = widget.source;
    session = widget.session;
    _parse();
  }

  void _parse() {
    parses++;
    document = parser
        .parse(filePath: '/$documentId.md', source: source)
        .busyDocument;
  }

  void _accept(String next) {
    if (widget.externalHistory) {
      undoSources.add(source);
      redoSources.clear();
    }
    changes.add(next);
    setState(() {
      source = next;
      _parse();
    });
  }

  void replaceSource(
    String next, {
    String? id,
    WysiwygEditorSessionState? restoredSession,
  }) {
    setState(() {
      documentId = id ?? documentId;
      if (restoredSession != null) session = restoredSession;
      source = next;
      _parse();
    });
  }

  void recreate(WysiwygEditorSessionState saved) {
    setState(() {
      session = saved;
      editorKey = GlobalKey<BusyMarkWysiwygEditorState>();
    });
  }

  void _undo() {
    undoCalls++;
    if (undoSources.isEmpty) return;
    redoSources.add(source);
    replaceSource(undoSources.removeLast());
  }

  void _redo() {
    redoCalls++;
    if (redoSources.isEmpty) return;
    undoSources.add(source);
    replaceSource(redoSources.removeLast());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BusyMarkWysiwygEditor(
        key: editorKey,
        document: document,
        documentId: documentId,
        clipboardService: widget.clipboard,
        clipboardInsertionRegistry: widget.insertionRegistry,
        initialSessionState: session,
        useExternalUndoHistory: widget.externalHistory,
        onUndo: _undo,
        onRedo: _redo,
        onSessionChanged: (id, value) {
          sessions[id] = value;
          if (id == documentId) session = value;
        },
        onSourceChanged: (_, value) => _accept(value),
      ),
    ),
  );
}
