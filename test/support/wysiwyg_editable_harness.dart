import 'document_history_harness.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/clipboard/clipboard_insertion.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/platform/rich_clipboard_service.dart';
import 'package:material_ui/material_ui.dart';

/// Accepts editor output and rebuilds from the accepted source, as the workspace
/// does. Selection-only tests retain their separate, non-editable harness.
class WysiwygEditableHarness extends StatefulWidget {
  const WysiwygEditableHarness({
    super.key,
    required this.source,
    required this.clipboard,
    this.session = const WysiwygEditorSessionState(),
    required this.history,
    this.insertionRegistry,
  });

  final String source;
  final RichClipboardService clipboard;
  final WysiwygEditorSessionState session;
  final DocumentHistoryHarness history;
  final BusyMarkClipboardInsertionRegistry? insertionRegistry;

  @override
  State<WysiwygEditableHarness> createState() => WysiwygEditableHarnessState();
}

class WysiwygEditableHarnessState extends State<WysiwygEditableHarness> {
  static const parser = MarkdownParser();
  var editorKey = GlobalKey<BusyMarkWysiwygEditorState>();
  final changes = <String>[];
  List<String> get undoSources => widget
      .history
      .buffer
      .editorState
      .undoState
      .undo
      .map((entry) => entry.text)
      .toList();
  DocumentHistoryHarness get history => widget.history;
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
    widget.history.controller.updateActiveWysiwygText(next, document: document);
    changes.add(next);
    setState(() {
      source = widget.history.buffer.text;
      _parse();
    });
  }

  void replaceSource(
    String next, {
    String? id,
    WysiwygEditorSessionState? restoredSession,
  }) {
    setState(() {
      widget.history.controller.updateActiveText(next);
      final buffer = widget.history.buffer;
      widget.history.controller.updateDocumentEditorState(
        buffer.id,
        buffer.editorState.copyWith(
          undoState: const DocumentUndoState(),
          wysiwygState: restoredSession ?? session,
        ),
      );
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
    widget.history.controller.undoActiveBuffer();
    setState(() {
      source = widget.history.buffer.text;
      session = widget.history.buffer.editorState.wysiwygState;
      _parse();
    });
  }

  void _redo() {
    redoCalls++;
    widget.history.controller.redoActiveBuffer();
    setState(() {
      source = widget.history.buffer.text;
      session = widget.history.buffer.editorState.wysiwygState;
      _parse();
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: busyMarkLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BusyMarkWysiwygEditor(
        key: editorKey,
        document: document,
        documentId: documentId,
        clipboardService: widget.clipboard,
        clipboardInsertionRegistry: widget.insertionRegistry,
        initialSessionState: session,
        readEditBase: widget.history.readBase,
        readSessionState: () => widget.history.buffer.editorState.wysiwygState,
        onDocumentChanged: (value) => document = value,
        onUndo: _undo,
        onRedo: _redo,
        onSessionChanged: (id, value) {
          sessions[id] = value;
          if (id == documentId) {
            session = value;
            widget.history.controller.updateDocumentEditorState(
              widget.history.buffer.id,
              widget.history.buffer.editorState.copyWith(wysiwygState: value),
            );
          }
        },
        onSourceChanged: (_, value) => _accept(value),
      ),
    ),
  );
}
