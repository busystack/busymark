import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

// These files own general control implementation or native window chrome.
// A feature-local wrapper does not acquire this permission.
const _designOwners = {
  'src/app/busymark_design.dart',
  'src/app/busymark_dialogs.dart',
  'src/app/busymark_dialog_identity.dart',
  'src/app/busymark_search_field.dart',
  'src/app/linux/linux_window_host.dart',
};

const _controls = {
  'AlertDialog',
  'SimpleDialog',
  'Dialog',
  'DialogRoute',
  'RawDialogRoute',
  'DropdownButton',
  'DropdownButtonFormField',
  'DropdownMenu',
  'FilledButton',
  'ElevatedButton',
  'OutlinedButton',
  'TextButton',
  'IconButton',
  'Checkbox',
  'CheckboxListTile',
  'Radio',
  'RadioListTile',
  'Switch',
  'SwitchListTile',
  'TextField',
  'TextFormField',
  'Slider',
  'RangeSlider',
  'PopupMenuButton',
  'PopupMenuItem',
  'CheckedPopupMenuItem',
  'MenuAnchor',
  'MenuItemButton',
  'SegmentedButton',
  'ToggleButtons',
  'SnackBar',
  'LinearProgressIndicator',
  'CircularProgressIndicator',
  'Tooltip',
  'RawTooltip',
};

const _routes = {
  'showDialog',
  'showAdaptiveDialog',
  'showGeneralDialog',
  'showModalBottomSheet',
  'showMenu',
};

// Existing feature call sites predate the shared-control requirement. Keep the
// allowance attached to the original declaration and capped by control count.
// New controls belong in the design system even in files on this list.
const _legacyCalls = <String, Map<String, int>>{
  'src/ai/ai_edit_ui.dart': {
    '_AiProposalDialogState.build CircularProgressIndicator': 1,
  },
  'src/editor/document_collapsible.dart': {
    '_BusyMarkDocumentCollapsibleState._header.row IconButton': 1,
    '_BusyMarkDocumentCollapsibleState._header.row Tooltip': 1,
  },
  'src/editor/markdown_image_view.dart': {
    '_RemoteImageBlockedPlaceholderState.build Tooltip': 1,
  },
  'src/editor/source/source_editor.dart': {
    'BusyMarkSourceEditorState.build TextField': 1,
    '_SourceSearchPanelState.build TextField': 1,
  },
  'src/editor/source/source_gutter.dart': {
    '_SourceDiagnosticMarkerDot.build Tooltip': 1,
  },
  'src/editor/writerside_video_view.dart': {
    '_BusyMarkWritersideVideoViewState._buildVideo Tooltip': 1,
    '_BusyMarkWritersideVideoViewState._buildVideo.activePlayer CircularProgressIndicator':
        1,
  },
  'src/editor/wysiwyg/writerside_properties.dart': {
    'BusyMarkWritersideProperties.build Tooltip': 1,
    '_PropertyContextHelpState.build Tooltip': 1,
    '_PropertySectionState.build TextButton': 1,
  },
  'src/editor/wysiwyg/wysiwyg_block_widgets.dart': {
    'BusyMarkWysiwygBlockField._blockContent TextField': 1,
    '_RenderedHtmlBlockEditor.build Tooltip': 1,
    '_TableCellEditorState.build TextField': 1,
  },
  'src/export/html_export_ui.dart': {
    '_ProgressState.build LinearProgressIndicator': 1,
  },
  'src/export/markdown_pdf_export_ui.dart': {
    '_MarkdownPdfProgressDialogState.build CircularProgressIndicator': 1,
  },
  'src/export/writerside_pdf_export_ui.dart': {
    '_WritersidePdfProgressDialogState.build CircularProgressIndicator': 1,
  },
  'src/feedback/presentation/feedback_dialog.dart': {
    '_BusyMarkFeedbackDialogState.build TextField': 3,
  },
  'src/local_history/local_history_comparison_view.dart': {
    '_ComparisonBody.build IconButton': 2,
    '_ComparisonBody.build LinearProgressIndicator': 1,
    '_ComparisonBody.build OutlinedButton': 3,
    '_LocalHistoryComparisonViewState.build CircularProgressIndicator': 1,
  },
  'src/local_history/local_history_panel.dart': {
    '_LocalHistoryHeader.build Tooltip': 1,
    '_LocalHistoryPanelState.build CircularProgressIndicator': 1,
  },
  'src/math/math_widget.dart': {'_MathFormulaState._fallback Tooltip': 1},
  'src/nextcloud_notes/presentation/nextcloud_settings.dart': {
    '_NextcloudNotesSettingsState.build CircularProgressIndicator': 1,
    '_NextcloudNotesSettingsState.build LinearProgressIndicator': 1,
    '_ServerNotesSettingsState.build LinearProgressIndicator': 2,
  },
  'src/nextcloud_notes/presentation/notes_sidebar.dart': {
    'NextcloudNoteStatus.build IconButton': 1,
    'NextcloudNoteStatus.build LinearProgressIndicator': 1,
    'NextcloudNotesSidebarState._editNote LinearProgressIndicator': 1,
    'NextcloudNotesSidebarState.build CircularProgressIndicator': 1,
    '_ManagedAttachmentsState.build LinearProgressIndicator': 1,
    '_UncertainAttachmentsState.build LinearProgressIndicator': 1,
    'showNextcloudConflict LinearProgressIndicator': 1,
  },
  'src/nextcloud_notes/presentation/notes_workspace_ui.dart': {
    '_NotesImportScanDialogState.build LinearProgressIndicator': 1,
    '_NotesOfflineDialogState.build LinearProgressIndicator': 2,
    '_NotesRecoveryDialogState.build LinearProgressIndicator': 1,
    '_NotesTransferProgressDialogState.build LinearProgressIndicator': 1,
    'showNotesBatch LinearProgressIndicator': 1,
  },
  'src/search/search_sidebar.dart': {
    'SearchSidebar.build LinearProgressIndicator': 1,
    'SearchSidebar.build TextButton': 1,
    'SearchSidebar.build Tooltip': 3,
  },
  'src/visualization/visualization_card.dart': {
    '_BusyMarkVisualizationCardState._buildDiagnostics TextButton': 1,
    '_BusyMarkVisualizationCardState._buildOutput CircularProgressIndicator': 1,
    '_BusyMarkVisualizationCardState._buildStatus CircularProgressIndicator': 1,
    '_OpenApiSummaryState.build FilledButton': 1,
    '_OpenApiSummaryState.build TextField': 1,
  },
  'src/workspace/presentation/document_format_indicator.dart': {
    'BusyMarkDocumentFormatIndicator.build Tooltip': 1,
  },
  'src/workspace/presentation/document_status_bar.dart': {
    '_DocumentStatusAction.build Tooltip': 1,
    '_SaveStatusIndicator.build Tooltip': 1,
  },
  'src/workspace/presentation/keyboard_shortcuts_settings.dart': {
    '_ShortcutEditorState.build LinearProgressIndicator': 1,
  },
  'src/workspace/presentation/settings_screen.dart': {
    '_AiSettingsPageState.build CircularProgressIndicator': 1,
    '_SettingsPageSelector.build Tooltip': 1,
    '_SpellingDictionaryResourceRow.build LinearProgressIndicator': 1,
  },
  'src/workspace/presentation/welcome_screen.dart': {
    '_WelcomeScreenState.build.welcomeContent LinearProgressIndicator': 1,
  },
  'src/workspace/presentation/workspace_screen.dart': {
    '_SidebarHeaderLine.build Tooltip': 2,
    '_TocHeader.build Tooltip': 1,
    '_WorkspaceReplacementProgressState.build CircularProgressIndicator': 1,
    '_previewInlineSpan PopupMenuButton': 1,
    '_previewInlineSpan PopupMenuItem': 1,
    '_previewInlineSpan Tooltip': 1,
  },
  'src/workspace/presentation/writerside_instance_dialog.dart': {
    '_BusyMarkWritersideInstanceDialogState._importFileSelection TextButton': 2,
    '_BusyMarkWritersideInstanceDialogState.build CircularProgressIndicator': 1,
  },
  'src/workspace/presentation/writerside_markdown_import_dialog.dart': {
    '_WritersideMarkdownImportDialogState.build TextButton': 2,
  },
  'src/workspace/presentation/writerside_template_dialogs.dart': {
    '_TemplateSourceEntryState.build TextField': 1,
  },
  'src/workspace/presentation/writerside_toc_dialogs.dart': {
    '_WritersideTitleDialogState._field TextField': 1,
    '_WritersideTitleDialogState.build TextButton': 2,
  },
  'src/writerside/writerside_tabs_view.dart': {
    '_WritersideTabsViewState.build TextButton': 1,
  },
};

class _MaterialBoundary extends RecursiveAstVisitor<void> {
  _MaterialBoundary(this.path);

  final String path;
  final errors = <String>[];
  final _counts = <String, int>{};

  void _check(AstNode node, Element? element, Set<String> restricted) {
    if (element == null || !restricted.contains(element.name)) return;
    final library = element.library?.uri.toString() ?? '';
    if (!library.startsWith('package:flutter/') &&
        !library.startsWith('package:material_ui/')) {
      return;
    }
    final scope = _scope(node);
    final use = '$scope ${element.name}';
    final count = _counts.update(use, (prior) => prior + 1, ifAbsent: () => 1);
    if (count > (_legacyCalls[path]?[use] ?? 0)) {
      errors.add(
        '$path:${node.offset}: use a BusyMark design component for $use',
      );
    }
  }

  static String _scope(AstNode node) {
    final scopes = <String>[];
    for (
      AstNode? parent = node.parent;
      parent != null;
      parent = parent.parent
    ) {
      switch (parent) {
        case MethodDeclaration():
          scopes.add(parent.name.lexeme);
        case FunctionDeclaration():
          scopes.add(parent.name.lexeme);
        case ConstructorDeclaration():
          scopes.add(parent.name?.lexeme ?? 'new');
        case VariableDeclaration():
          scopes.add(parent.name.lexeme);
        case ClassDeclaration():
          scopes.add(parent.namePart.typeName.lexeme);
      }
    }
    return scopes.reversed.join('.');
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _check(node, node.element?.enclosingElement, _controls);
    super.visitConstructorName(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    _check(node, node.superclass.element, _controls);
    super.visitExtendsClause(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is TopLevelFunctionElement) _check(node, element, _routes);
    super.visitSimpleIdentifier(node);
  }
}

List<String> auditMaterialControls(String relative, CompilationUnit unit) {
  if (_designOwners.contains(relative)) return const [];
  final visitor = _MaterialBoundary(relative);
  unit.accept(visitor);
  return visitor.errors;
}
