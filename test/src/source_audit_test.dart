import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source tree has BusyMark identity and no removed domain surfaces', () {
    final files = <File>[
      for (final path in ['lib', 'linux', 'test'])
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => _isText(file.path)),
      File('README.md'),
      File('pubspec.yaml'),
    ];
    final combined = files.map((file) => file.readAsStringSync()).join('\n');

    expect(
      combined,
      isNot(
        contains(
          'package:busy'
          'max',
        ),
      ),
    );
    expect(
      combined,
      isNot(
        contains(
          'Busy'
          'Max',
        ),
      ),
    );
    expect(
      combined,
      isNot(
        contains(
          'GOOGLE_'
          'OAUTH',
        ),
      ),
    );
    expect(
      combined,
      isNot(
        contains(
          'MICROSOFT_'
          'OAUTH',
        ),
      ),
    );
    expect(
      combined.toLowerCase(),
      isNot(
        contains(
          'sign'
          '-in',
        ),
      ),
    );
    expect(
      combined.toLowerCase(),
      isNot(
        contains(
          'google'
          '_tasks',
        ),
      ),
    );
    expect(
      combined.toLowerCase(),
      isNot(
        contains(
          'microsoft'
          '_todo',
        ),
      ),
    );
    expect(combined, contains('BusyMark'));
  });

  test('pubspec package name is busymark', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('name: busymark'));
  });

  test('Flutter UI uses Yaru glyphs instead of Material icon constants', () {
    final materialIconUse = RegExp(r'(^|[^A-Za-z])Icons\.', multiLine: true);
    final files = <File>[
      for (final path in ['lib', 'test'])
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => _isText(file.path)),
    ];

    for (final file in files) {
      expect(
        materialIconUse.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }

    final glyphs = File('lib/src/app/busymark_glyphs.dart').readAsStringSync();
    expect(glyphs, contains("import 'package:yaru/yaru.dart';"));
    expect(glyphs, contains('YaruIcons.'));
  });

  test('grouped action rows use one BusyMark-owned rounded surface', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    expect(design, contains('class _BusyMarkGroupedListSurface'));
    expect(design, contains('cardTheme.shape ?? RoundedRectangleBorder'));
    expect(design, contains('clipBehavior: Clip.antiAlias'));
    expect(design, contains('Divider(height: 1'));
    expect(design, isNot(contains('YaruTileList')));
    expect(design, isNot(contains('YaruBorderContainer')));
  });

  test('shared row hover uses the themed control hover color', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    final helper = RegExp(
      r'Color busyMarkRowHoverColor\(BuildContext context\) \{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(design)!.group(1)!;
    expect(helper, contains('BusyMarkSurfaceColors.of(context).controlHover'));
    expect(helper, isNot(contains('colors.foreground.withValues')));
  });

  test('shared surfaces use semantic BusyMark shadows', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();
    final theme = File('lib/src/app/app_theme.dart').readAsStringSync();

    expect(design, contains('return BusyMarkSurfaceColors.of(context).shade'));
    expect(design, contains('surfaceShadowsFor'));
    expect(design, contains('floatingShadowsFor'));
    expect(design, contains('windowShadowsFor'));
    expect(design, contains('edgeShadowsFor'));
    expect(design, contains('_scaleAlpha(color, 0.28)'));
    expect(design, contains('blurRadius: 8'));
    expect(design, contains('offset: const Offset(0, -1)'));
    expect(design, contains('BoxDecoration busyMarkSurfaceDecoration'));
    expect(
      design,
      contains(
        'boxShadow: elevated ? BusyMarkShadow.surfaceShadowsFor(context) : null',
      ),
    );
    expect(design, contains('final cardTheme = Theme.of(context).cardTheme'));
    final surface = RegExp(
      r'class BusyMarkSurface.*?class BusyMarkGroupedList',
      dotAll: true,
    ).firstMatch(design)!.group(0)!;
    expect(surface, contains('cardTheme.color ?? colors.card'));
    expect(surface, contains('decoration: busyMarkSurfaceDecoration'));
    expect(theme, contains('shadowColor: colors.shade'));
    expect(theme, contains('cardTheme: CardThemeData'));
    expect(dialogs, contains('elevation: BusyMarkElevation.popover'));
    expect(
      dialogs,
      contains('shadowColor: BusyMarkShadow.floatingColor(context)'),
    );
    expect(
      theme,
      contains('boxShadow: BusyMarkShadow.floatingShadows(colors.shade)'),
    );
  });

  test('filled grouped action surfaces use themed card surfaces', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    final groupedSurface = RegExp(
      r'class _BusyMarkGroupedListSurface.*?class BusyMarkActionRow',
      dotAll: true,
    ).firstMatch(design)!.group(0)!;
    expect(groupedSurface, contains('final borderColor = colors.subtleBorder'));
    expect(groupedSurface, contains('final dividerColor = colors.view'));
    expect(
      groupedSurface,
      contains('Divider(height: 1, thickness: 1, color: dividerColor)'),
    );
    expect(groupedSurface, contains('border: Border.all(color: borderColor)'));
    expect(
      groupedSurface,
      contains('final color = cardTheme.color ?? colors.card'),
    );
    expect(groupedSurface, contains('decoration: busyMarkSurfaceDecoration'));
    expect(groupedSurface, isNot(contains('color: colors.control')));
    expect(groupedSurface, isNot(contains('BusyMarkShadow.surfaceShadows')));
    expect(groupedSurface, isNot(contains('elevation: cardTheme.elevation')));
  });

  test(
    'problems are opened from a popup instead of a bottom panel setting',
    () {
      final workspace = File(
        'lib/src/workspace/presentation/workspace_screen.dart',
      ).readAsStringSync();
      final settings = File('lib/src/app/app_settings.dart').readAsStringSync();
      final settingsScreen = File(
        'lib/src/workspace/presentation/settings_screen.dart',
      ).readAsStringSync();

      expect(workspace, contains('_showProblemsDialog'));
      expect(workspace, contains('_validateActiveAndShowProblems'));
      expect(workspace, contains(').validateActive()'));
      expect(workspace, contains('class _ProblemsList'));
      expect(workspace, isNot(contains("tooltip: 'Problems'")));
      expect(workspace, isNot(contains('_ProblemsPanel')));
      expect(workspace, isNot(contains('problemsVisible')));
      expect(settings, isNot(contains('problemsVisible')));
      expect(settings, isNot(contains('setProblemsVisible')));
      expect(settingsScreen, isNot(contains('Show problems panel')));
    },
  );

  test('native search action opens workspace search UI', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('case HeaderBarAction.search:'));
    expect(workspace, contains('_toggleSearch(ref)'));
    expect(workspace, contains('_workspaceSearchProvider'));
    expect(workspace, contains('class _HeaderSearchField'));
    expect(workspace, contains('class _SearchSidebar'));
    expect(workspace, contains('_workspaceSearchResults'));
    expect(workspace, contains('_searchNavigationTargetProvider'));
  });

  test('preview links are actionable instead of styled-only text', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('url_launcher:'));
    expect(workspace, contains('TapGestureRecognizer'));
    expect(workspace, contains('LaunchMode.externalApplication'));
    expect(workspace, contains('_openPreviewLink(context, ref, destination)'));
    expect(workspace, contains('openActiveFile(file.absolutePath)'));
    expect(workspace, contains('_navigatePreviewAnchor'));
    expect(workspace, contains('SystemMouseCursors.click'));
  });

  test('workspace sidebar tabs match the opened workspace kind', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    final folderClause = RegExp(
      r'WorkspaceKind\.markdownFolder => const \[(.*?)\]',
      dotAll: true,
    ).firstMatch(workspace)!.group(1)!;
    final writersideClause = RegExp(
      r'WorkspaceKind\.writersideModule => const \[(.*?)\]',
      dotAll: true,
    ).firstMatch(workspace)!.group(1)!;

    final singleMarkdownClause = RegExp(
      r'WorkspaceKind\.singleMarkdown => const \[(.*?)\]',
      dotAll: true,
    ).firstMatch(workspace)!.group(1)!;

    expect(singleMarkdownClause, contains('_SidebarTab.outline'));
    expect(singleMarkdownClause, isNot(contains('_SidebarTab.files')));
    expect(singleMarkdownClause, isNot(contains('_SidebarTab.toc')));
    expect(
      workspace,
      contains('if (!widget.searchState.active && tabs.length > 1)'),
    );
    expect(workspace, contains('_preferredSidebarTabIndex'));
    expect(workspace, contains('_shouldShowOutlineForOpenFile'));
    expect(workspace, contains('tabs.indexOf(_SidebarTab.outline)'));
    expect(
      workspace,
      contains('widget.workspace.activeFilePath != _activeFilePath'),
    );
    expect(folderClause, contains('_SidebarTab.files'));
    expect(folderClause, contains('_SidebarTab.outline'));
    expect(folderClause, isNot(contains('_SidebarTab.toc')));
    expect(writersideClause, contains('_SidebarTab.files'));
    expect(writersideClause, contains('_SidebarTab.toc'));
    expect(writersideClause, contains('_SidebarTab.outline'));
  });

  test('sidebar tabs and editor hover use neutral native surfaces', () {
    final theme = File('lib/src/app/app_theme.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(theme, contains('segmentedButtonTheme: SegmentedButtonThemeData'));
    expect(
      theme,
      contains('side: const WidgetStatePropertyAll(BorderSide.none)'),
    );
    expect(workspace, contains('hoverColor: Colors.transparent'));
    expect(workspace, contains('focusColor: Colors.transparent'));
    expect(workspace, contains('selectionHeightStyle: BoxHeightStyle.max'));
    expect(workspace, contains('selectionWidthStyle: BoxWidthStyle.tight'));
    expect(workspace, contains('cursorColor: colors.foreground.withValues'));
    expect(workspace, contains('cursorHeight: widget.editorFontSize * 1.22'));
    expect(workspace, contains('cursorWidth: 1.4'));
  });

  test('sidebar selector uses shared semantic shadow', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('SegmentedButton<int>'));
    expect(
      workspace,
      contains('boxShadow: BusyMarkShadow.surfaceShadows(colors.shade)'),
    );
    expect(workspace, contains('BusyMarkRadius.headerButton'));
  });

  test('sidebar trees share the expandable Yaru-style row', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('class _SidebarTreeRow'));
    expect(workspace, contains('class _FileTreeNode'));
    expect(workspace, contains('_buildFileTree'));
    expect(workspace, contains('_visibleFileTreeEntries'));
    expect(workspace, contains('class _TocTab extends ConsumerStatefulWidget'));
    expect(workspace, contains('_visibleTocTreeEntries'));
    expect(workspace, contains('_expandedNodeKeys'));
    expect(
      workspace,
      contains('class _OutlineTab extends ConsumerStatefulWidget'),
    );
    expect(workspace, contains('_buildOutlineTree'));
    expect(workspace, contains('_visibleOutlineTreeEntries'));
    expect(workspace, contains('onToggle: hasChildren ? toggle : null'));
    expect(workspace, contains('AnimatedRotation'));
    expect(workspace, contains('YaruIcons.pan_end'));
    expect(workspace, contains('YaruIcons.folder_open'));
    expect(workspace, contains('YaruIcons.folder'));
    expect(workspace, contains('busyMarkRowHoverColor(context)'));
    expect(workspace, contains('_isOpenableTextDocument(file)'));
    expect(workspace, contains('enabled: node.isFolder || openable'));
    expect(workspace, contains('openActiveFile(file.absolutePath)'));
    expect(workspace, isNot(contains('class _FileTreeRow')));
    expect(workspace, isNot(contains('class _SidebarTile')));
    expect(workspace, isNot(contains('title: file.relativePath')));
    expect(workspace, isNot(contains('subtitle: _documentKindLabel')));
  });

  test('outline tree drives source and preview heading navigation', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('_outlineNavigationTargetProvider'));
    expect(workspace, contains('_OutlineNavigationTarget'));
    expect(workspace, contains('headingId: heading.id'));
    expect(workspace, contains('line: heading.span.startLine'));
    expect(workspace, contains('_sourceFocusNode.requestFocus()'));
    expect(workspace, contains('_unfoldSourceLine(line)'));
    expect(workspace, contains('_sourceLineLayoutEntries'));
    expect(workspace, contains('_sourceScrollOffsetForLine'));
    expect(workspace, contains('_jumpSourceScrollToLine'));
    expect(workspace, contains('scrollController: _sourceScrollController'));
    expect(workspace, contains('Scrollable.ensureVisible'));
    expect(workspace, contains('alignment: 0.0'));
    expect(workspace, isNot(contains('alignment: 0.04')));
    expect(workspace, contains('headingKeys: _previewHeadingKeys'));
    expect(workspace, contains('headingKey: _keyForBlock(block)'));
    expect(workspace, contains('key: headingKey'));
    expect(workspace, contains('scrollToHeadingId: _wysiwygScrollHeadingId'));
    expect(workspace, contains('scrollRequest: _wysiwygScrollRequest'));
    final wysiwyg = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();
    expect(wysiwyg, contains('void _scheduleHeadingScroll()'));
    expect(wysiwyg, contains('Scrollable.ensureVisible'));
    expect(workspace, contains("block.attributes['id']"));
  });

  test('source editor line numbers use measured editor layout', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('isCollapsed: true'));
    expect(workspace, contains('_sourceLineHeight(context, sourceStrutStyle)'));
    expect(workspace, contains('_SourceRenderedTextLayer'));
    expect(workspace, contains('renderText = false'));
    expect(workspace, contains('controller.buildSourceTextSpan'));
    expect(workspace, contains('TextPainter('));
    expect(workspace, contains('computeLineMetrics()'));
    expect(workspace, contains('getOffsetForCaret'));
    expect(workspace, contains('_sourceTextHeightForLine'));
    expect(workspace, contains('_CollapsedSourceLineOverlay'));
    expect(workspace, contains('_sourceStrutStyle('));
    expect(workspace, contains('folded: _foldedRegionKeys.isNotEmpty'));
    expect(workspace, contains('if (folded)'));
    expect(workspace, contains('return null'));
    expect(workspace, contains('StrutStyle.fromTextStyle(_sourceTextStyle)'));
    expect(workspace, contains('strutStyle: sourceStrutStyle'));
    expect(workspace, contains('TextOverflow.ellipsis'));
    expect(workspace, contains('Color.alphaBlend'));
    expect(workspace, contains("'\$trimmed ...'"));
  });

  test('document view modes drive source preview and split layouts', () {
    final settings = File('lib/src/app/app_settings.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final settingsScreen = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();

    expect(
      settings,
      contains(
        'enum DocumentViewModePreference { editor, source, preview, split }',
      ),
    );
    expect(
      settings,
      contains('documentViewMode: DocumentViewModePreference.split'),
    );
    expect(settings, contains('Future<void> setDocumentViewMode'));
    expect(workspace, contains('final editorVisible = widget.viewMode =='));
    expect(workspace, contains('DocumentViewModePreference.editor'));
    expect(
      workspace,
      contains('widget.viewMode != DocumentViewModePreference.preview'),
    );
    expect(
      workspace,
      contains('widget.viewMode != DocumentViewModePreference.source'),
    );
    expect(workspace, contains('BusyMarkWysiwygEditor'));
    expect(workspace, contains('visualMarkdown = false'));
    expect(workspace, isNot(contains('class _VisualMarkdownEditorPane')));
    expect(workspace, contains('if (sourceVisible && previewVisible)'));
    expect(workspace, contains('if (previewVisible)'));
    expect(settingsScreen, isNot(contains('Show preview pane')));
    expect(settingsScreen, isNot(contains('setPreviewVisible')));
  });

  test('WYSIWYG toolbar exposes fuller Markdown controls', () {
    final toolbar = File(
      'lib/src/editor/wysiwyg/wysiwyg_toolbar.dart',
    ).readAsStringSync();
    final commands = File(
      'lib/src/editor/wysiwyg/wysiwyg_commands.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/src/editor/wysiwyg/wysiwyg_document_controller.dart',
    ).readAsStringSync();
    final serializer = File(
      'lib/src/markdown/busymark_markdown_serializer.dart',
    ).readAsStringSync();

    for (final label in [
      'Heading 4',
      'Heading 5',
      'Heading 6',
      'Toggle task checked',
      'Indent list item',
      'Outdent list item',
      'Code block language',
      'Inline image',
      'Table',
      'Hard line break',
    ]) {
      expect(toolbar, contains(label));
    }
    expect(commands, contains('heading4'));
    expect(commands, contains('heading5'));
    expect(commands, contains('heading6'));
    expect(controller, contains('insertTableAfter'));
    expect(controller, contains('replaceTable'));
    expect(controller, contains('insertTableRow'));
    expect(controller, contains('deleteTableRow'));
    expect(controller, contains('insertTableColumn'));
    expect(controller, contains('deleteTableColumn'));
    expect(controller, contains('deleteTable'));
    expect(controller, contains('insertInlineImage'));
    expect(controller, contains('insertHardBreak'));
    expect(controller, contains('applyCodeBlockLanguage'));
    expect(controller, contains('toggleTaskChecked'));
    expect(controller, contains('indentListItems'));
    expect(controller, contains('outdentListItems'));
    expect(serializer, contains('String _listItem('));
    expect(serializer, contains('String _indentBlock('));
    expect(toolbar, isNot(contains('transparent: true')));
    expect(toolbar, contains('BusyMarkHeaderIconButton('));
    final blockWidgets = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    expect(blockWidgets, contains('Insert column left'));
    expect(blockWidgets, contains('Insert column right'));
    expect(blockWidgets, contains('Insert row above'));
    expect(blockWidgets, contains('Insert row below'));
    expect(blockWidgets, contains('Delete table'));
  });

  test('WYSIWYG text selection does not paint full text block backgrounds', () {
    final blockWidgets = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final background = RegExp(
      r'Color _background\(BuildContext context\).*?BoxBorder\?',
      dotAll: true,
    ).firstMatch(blockWidgets)!.group(0)!;

    expect(background, isNot(contains('if (selected)')));
    expect(background, isNot(contains('colorScheme.primary.withValues')));
    expect(blockWidgets, contains('_WysiwygSelectionPainter'));
    expect(blockWidgets, contains('getBoxesForSelection'));
  });

  test('Markdown image blocks render frameless and edit through dialog', () {
    final imageView = File(
      'lib/src/editor/markdown_image_view.dart',
    ).readAsStringSync();
    final blockWidgets = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();
    final prefix = RegExp(
      r'Widget\? _prefix\(BuildContext context\).*?Color _background',
      dotAll: true,
    ).firstMatch(blockWidgets)!.group(0)!;
    final imageBlockEditor = RegExp(
      r'class _ImageBlockEditor.*?String _imageSource',
      dotAll: true,
    ).firstMatch(blockWidgets)!.group(0)!;

    expect(imageView, isNot(contains('color: colors.panel')));
    expect(
      imageView,
      isNot(contains('Border.all(color: colors.subtleBorder)')),
    );
    expect(prefix, isNot(contains('BusyBlockKind.image => Icon')));
    expect(imageBlockEditor, isNot(contains('height: 240')));
    expect(imageBlockEditor, isNot(contains('hintText: \'Alt text\'')));
    expect(
      blockWidgets,
      contains("ValueKey('wysiwyg-image-block-\${block.id}')"),
    );
    expect(blockWidgets, contains('block.kind == BusyBlockKind.image'));
    expect(blockWidgets, contains('_editImageBlock'));
    expect(editor, contains('_handleImageBlockEditRequested'));
    expect(editor, contains('initialSource: _imageSourceForBlock(block)'));
    expect(editor, contains("submitLabel: 'Apply'"));
  });

  test('source view has compact gutter without pane status chrome', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('static const double _gutterWidth = 58;'));
    expect(
      workspace,
      contains(
        '_SourceEditorFrame.editorPaddingTop,\n            24,\n            34',
      ),
    );
    expect(workspace, contains('first: index == 0'));
    expect(workspace, contains('top: first ? 0 : 18'));
    expect(workspace, isNot(contains('class _PaneHeader')));
    expect(workspace, isNot(contains('class _StatusPill')));
    expect(workspace, isNot(contains("'Not saved' : 'Saved'")));
  });
}

bool _isText(String path) {
  return path.endsWith('.dart') ||
      path.endsWith('.cc') ||
      path.endsWith('.h') ||
      path.endsWith('.yaml') ||
      path.endsWith('.desktop') ||
      path.endsWith('.md');
}
