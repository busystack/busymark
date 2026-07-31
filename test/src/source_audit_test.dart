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

  test('top-level app routes do not animate between desktop surfaces', () {
    final router = File('lib/src/app/app_router.dart').readAsStringSync();

    expect(router, contains('NoTransitionPage<void>(child: WelcomeScreen())'));
    expect(
      router,
      contains('NoTransitionPage<void>(child: WorkspaceScreen())'),
    );
    expect(router, contains('NoTransitionPage<void>('));
    expect(router, contains('child: SettingsScreen('));
    expect(router, isNot(contains('builder: (context, state)')));
    expect(router, isNot(contains('CustomTransitionPage')));
  });

  test('Flutter UI resolves icons through the BusyMark glyph catalog', () {
    final materialIconUse = RegExp(r'(^|[^A-Za-z])Icons\.', multiLine: true);
    final glyphCatalog = File('lib/src/app/busymark_glyphs.dart');
    final files = <File>[
      for (final path in ['lib', 'test'])
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => _isText(file.path)),
    ];

    for (final file in files) {
      if (file.path == glyphCatalog.path) {
        continue;
      }
      expect(
        materialIconUse.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }

    final glyphs = glyphCatalog.readAsStringSync();
    expect(glyphs, contains("import 'package:yaru/yaru.dart';"));
    expect(glyphs, contains('YaruIcons.'));
    expect(
      RegExp(
        r'\bIcons\.[A-Za-z0-9_]+',
      ).allMatches(glyphs).map((match) => match.group(0)),
      orderedEquals(<String>[
        'Icons'
            '.fork_right',
      ]),
    );
  });

  test('preview output actions are not present', () {
    final files = <File>[
      for (final path in ['lib', 'linux'])
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => _isText(file.path)),
    ];
    final combined = files.map((file) => file.readAsStringSync()).join('\n');

    for (final removed in [
      'export'
          'Preview',
      '_Print'
          'Active'
          'Intent',
      '_print'
          'Active'
          'Preview',
      'busy'
          'mark-print',
      'xdg'
          '-open',
    ]) {
      expect(combined, isNot(contains(removed)));
    }
    expect(RegExp(r'Ctrl\+P(?![A-Za-z])').hasMatch(combined), isFalse);
  });

  test('product stderr logging is isolated behind debug logging', () {
    final files = <File>[
      for (final path in ['lib'])
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => _isText(file.path)),
    ];

    for (final file in files) {
      if (file.path.endsWith('lib/src/core/debug_log.dart')) {
        continue;
      }
      expect(
        file.readAsStringSync(),
        isNot(contains('stderr.writeln')),
        reason: file.path,
      );
    }
  });

  test('grouped action rows use one BusyMark-owned rounded surface', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    expect(design, contains('class _BusyMarkGroupedListSurface'));
    expect(design, contains('final fallbackShape = RoundedRectangleBorder'));
    expect(design, contains('BorderRadius.circular(BusyMarkRadius.lg)'));
    expect(design, contains('this.clipBehavior = Clip.antiAlias'));
    expect(design, contains('height: 1'));
    expect(design, isNot(contains('YaruTileList')));
    expect(design, isNot(contains('YaruBorderContainer')));
  });

  test('BusyMark dialog title bars use the same surface as dialog body', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogChrome = RegExp(
      r'Color busyMarkDialogSurfaceColor[\s\S]*?class BusyMarkDialogShell',
    ).firstMatch(design)!.group(0)!;
    final dialogShell = RegExp(
      r'class BusyMarkDialogShell[\s\S]*?abstract final class BusyMarkPushButton',
    ).firstMatch(design)!.group(0)!;

    expect(dialogChrome, contains('busyMarkDialogSurfaceColor(context)'));
    expect(dialogChrome, contains('YaruDialogTitleBar('));
    expect(dialogChrome, contains('backgroundColor: dialogSurface'));
    expect(dialogChrome, contains('border:'));
    expect(dialogShell, contains('child: Dialog('));
    expect(dialogShell, contains('clipBehavior: Clip.antiAlias'));
  });

  test('BusyMark dialog buttons are thin semantic framework adapters', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogButton = RegExp(
      r'class BusyMarkDialogButton[\s\S]*?class BusyMarkFloatingTextEntryGroup',
    ).firstMatch(design)!.group(0)!;

    expect(design, contains('abstract final class BusyMarkPushButton'));
    expect(design, contains('static FilledButton standard('));
    expect(design, contains('static FilledButton standardIcon('));
    expect(design, contains('return FilledButton.icon('));
    expect(design, contains('static ElevatedButton suggested('));
    expect(design, contains('static ElevatedButton destructive('));
    expect(dialogButton, contains('BusyMarkPushButton.standard('));
    expect(dialogButton, contains('BusyMarkPushButton.suggested('));
    expect(dialogButton, contains('BusyMarkPushButton.destructive('));
    expect(dialogButton, isNot(contains('FocusableActionDetector(')));
    expect(dialogButton, isNot(contains('GestureDetector(')));
    expect(dialogButton, isNot(contains('busyMarkSurfaceDecoration(')));
    expect(dialogButton, isNot(contains('minHeight:')));
    expect(dialogButton, isNot(contains('minWidth:')));
  });

  test('Writerside topic controls use shared semantic adapters', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final createTopicDialog = RegExp(
      r'class _CreateWritersideTopicDialogState[\s\S]*?'
      r'  String _dialogTitle',
    ).firstMatch(workspace)!.group(0)!;

    expect(workspace, contains('BusyMarkPushButton.standardIcon('));
    expect(workspace, isNot(contains('FilledButton.icon(')));
    expect(createTopicDialog, contains('BusyMarkModalEditorScaffold('));
    expect(
      RegExp(
        r'BusyMarkGroupedTextEntry\(',
      ).allMatches(createTopicDialog).length,
      2,
    );
    expect(
      RegExp(r'BusyMarkComboRow<').allMatches(createTopicDialog).length,
      2,
    );
    expect(createTopicDialog, isNot(contains('BusyMarkDialogShell(')));
    expect(createTopicDialog, isNot(contains('SegmentedButton<')));
    expect(createTopicDialog, isNot(contains('BusyMarkFloatingTextEntry')));
    expect(createTopicDialog, isNot(contains('InputDecoration(')));
  });

  test('shared row hover delegates to Yaru interaction state', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    final helper = RegExp(
      r'Color busyMarkRowHoverColor\(BuildContext context\) \{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(design)!.group(1)!;
    expect(helper, contains('final hover = theme.hoverColor'));
    expect(helper, contains('BusyMarkAlpha.groupedRowLightHoverStrength'));
    expect(helper, isNot(contains('colors.foreground.withValues')));
    expect(design, isNot(contains('class _BusyMarkHoverBackground')));
    final actionRow = RegExp(
      r'class BusyMarkActionRow[\s\S]*?class BusyMarkSwitchRow',
    ).firstMatch(design)!.group(0)!;
    expect(actionRow, contains('final row = YaruListTile.square('));
    expect(actionRow, isNot(contains('MouseRegion(')));
    expect(
      actionRow,
      contains(
        'hoverColor: widget.hoverColor ?? busyMarkRowHoverColor(context)',
      ),
    );
    final switchRow = RegExp(
      r'class BusyMarkSwitchRow[\s\S]*?class BusyMarkDialogShell',
    ).firstMatch(design)!.group(0)!;
    expect(switchRow, contains('return YaruSwitchListTile('));
    expect(switchRow, isNot(contains('MouseRegion(')));
    expect(switchRow, contains('hoverColor: busyMarkRowHoverColor(context)'));
    expect(switchRow, contains('shape: const RoundedRectangleBorder()'));
  });

  test('shared grouped surfaces use native card shadow layers', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogs = File(
      'lib/src/app/busymark_dialogs.dart',
    ).readAsStringSync();
    final theme = File('lib/src/app/app_theme.dart').readAsStringSync();

    expect(design, contains('abstract final class BusyMarkShadow'));
    expect(design, contains('nativeCardShadows(Color semanticShadow)'));
    expect(design, contains('BoxShadow('));
    expect(design, isNot(contains('busyMarkSurfaceDecoration')));
    expect(design, contains('final cardTheme = CardTheme.of(context)'));
    final surface = RegExp(
      r'class BusyMarkSurface.*?class BusyMarkGroupedList',
      dotAll: true,
    ).firstMatch(design)!.group(0)!;
    expect(surface, contains('cardTheme.color ?? surfaceColors.card'));
    expect(surface, contains('BusyMarkShadow.nativeCardShadowsFor(context)'));
    expect(surface, contains('shadowColor: Colors.transparent'));
    expect(surface, contains('color: busyMarkGroupedSurfaceColor(context)'));
    expect(theme, contains('shadowColor: colorScheme.shadow'));
    expect(theme, contains('cardTheme: base.cardTheme.copyWith'));

    final modalEditor = RegExp(
      r'class BusyMarkModalEditorSurface[\s\S]*?void showBusyMarkAboutDialog',
    ).firstMatch(dialogs)!.group(0)!;
    expect(modalEditor, contains('Dialog('));
    expect(modalEditor, isNot(contains('AlertDialog(')));
    expect(modalEditor, isNot(contains('child: Material(')));
    expect(modalEditor, isNot(contains('BusyMarkElevation.')));
    expect(modalEditor, isNot(contains('BusyMarkShadow.')));
  });

  test('filled grouped action surfaces use the shared grouped surface', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();

    final groupedSurface = RegExp(
      r'class _BusyMarkGroupedListSurface.*?class BusyMarkActionRow',
      dotAll: true,
    ).firstMatch(design)!.group(0)!;
    expect(groupedSurface, contains('height: 1'));
    expect(groupedSurface, contains('thickness: 1'));
    expect(groupedSurface, contains('color: colors.cardShade'));
    expect(design, contains('required this.groupedSurface'));
    expect(design, contains('required this.cardShade'));
    expect(
      design,
      contains('BusyMarkSurfaceColors.fromTheme(ThemeData theme)'),
    );
    expect(
      design,
      contains('return _busyMarkSemanticSurfaceColors(theme.brightness)'),
    );
    expect(design, contains('groupedSurface: groupedSurface'));
    expect(design, contains('cardShade:'));
    expect(design, contains('class BusyMarkGroupedSurface'));
    expect(groupedSurface, contains('return BusyMarkGroupedSurface('));
    expect(groupedSurface, isNot(contains('busyMarkSurfaceDecoration')));
    expect(groupedSurface, isNot(contains('borderColor')));
    expect(groupedSurface, isNot(contains('Border.all')));
    expect(groupedSurface, isNot(contains('color: colors.control')));
    expect(welcome, isNot(contains('_welcomeGroupedCardColor')));
    expect(welcome, isNot(contains('cardTheme: theme.cardTheme.copyWith')));
  });

  test(
    'semantic surfaces are centralized while inputs retain Yaru geometry',
    () {
      final design = File(
        'lib/src/app/busymark_design.dart',
      ).readAsStringSync();
      final theme = File('lib/src/app/app_theme.dart').readAsStringSync();
      final surfaceFactory = RegExp(
        r'factory BusyMarkSurfaceColors\.fromTheme[\s\S]*?'
        r'static BusyMarkSurfaceColors of',
      ).firstMatch(design)!.group(0)!;

      expect(theme, contains('BusyMarkSurfaceColors.fromTheme(base)'));
      expect(
        theme,
        contains(
          'final inputDecorationTheme = '
          'base.inputDecorationTheme',
        ),
      );
      expect(theme, isNot(contains('_semanticInputDecorationTheme')));
      expect(theme, isNot(contains('filled: true')));
      expect(theme, isNot(contains('fillColor: colors.control')));
      expect(
        surfaceFactory,
        contains('return _busyMarkSemanticSurfaceColors(theme.brightness)'),
      );
      expect(design, contains('Modern Yaru/libadwaita semantic roles'));
      expect(design, contains('final window = switch (brightness)'));
      expect(design, contains('final floatingSurface = switch (brightness)'));
      expect(design, contains('window: window'));
      expect(design, contains('groupedSurface: groupedSurface'));
      expect(design, contains('dialog: floatingSurface'));
      expect(design, contains('popover: floatingSurface'));
      expect(design, contains('dialogOutline:'));
      expect(
        theme,
        contains(
          'final dialogSurfaceSide = '
          'BorderSide(color: colors.dialogOutline)',
        ),
      );
      expect(theme, contains('ShapeBorder? _withOutlineSide'));
      expect(
        theme,
        isNot(contains('final accentContainer = Color.alphaBlend')),
      );
      expect(theme, isNot(contains('selectedTileColor: accentContainer')));
      expect(theme, contains('shape: _withOutlineSide(base.dialogTheme.shape'));
      expect(theme, contains('_withOutlineSide(base.popupMenuTheme.shape'));
      expect(theme, contains('side: WidgetStatePropertyAll(side)'));
      expect(theme, contains('surfaceContainerLowest: colors.view'));
      expect(theme, contains('surfaceContainerLow: colors.window'));
      expect(theme, contains('surfaceContainer: colors.panel'));
      expect(theme, contains('surfaceContainerHigh: colors.secondarySidebar'));
      expect(theme, contains('surfaceContainerHighest: colors.sidebar'));
      expect(theme, contains('outlineVariant: colors.divider'));
      expect(surfaceFactory, isNot(contains('fromBrightness')));
    },
  );

  test('split-view sidebars share one directional semantic boundary', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final sidebarSurface = RegExp(
      r'class BusyMarkSidebarSurface[\s\S]*?class BusyMarkGroupedList',
    ).firstMatch(design)!.group(0)!;

    expect(sidebarSurface, contains('color: colors.sidebar'));
    expect(sidebarSurface, contains('BorderDirectional('));
    expect(sidebarSurface, contains('end: BorderSide('));
    expect(sidebarSurface, contains('color: colors.sidebarBorder'));
    expect(workspace, contains('return BusyMarkSidebarSurface('));
    expect(welcome, contains('return BusyMarkSidebarSurface('));
    expect(
      workspace,
      isNot(contains('decoration: BoxDecoration(color: colors.sidebar)')),
    );
    expect(
      welcome,
      isNot(contains('decoration: BoxDecoration(color: colors.sidebar)')),
    );
  });

  test('hardcoded UI colors stay in the shared design layer', () {
    final colorLiteral = RegExp(
      r'\bColors\.|\b(?:const\s+)?Color\(|\bColor\.fromRGBO\(',
    );
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.endsWith('lib/src/app/busymark_design.dart') &&
              !file.path.contains('/l10n/generated/'),
        );

    for (final file in files) {
      expect(
        colorLiteral.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
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
    expect(workspace, contains('return BusyMarkSearchField('));
    final searchField = RegExp(
      r'class _HeaderSearchField[\s\S]*?class _HeaderSeparator',
    ).firstMatch(workspace)!.group(0)!;
    expect(searchField, isNot(contains('TextField(')));
    expect(searchField, isNot(contains('OutlineInputBorder(')));
    expect(searchField, contains('onEscape: widget.onEscape'));
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

  test('inline preview images do not inherit link text decoration', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final imageSpanStart = workspace.indexOf(
      'InlineSpan _previewInlineImageSpan(',
    );
    final imageSpanEnd = workspace.indexOf(
      'List<InlineSpan>? _highlightedPreviewTextSpans(',
      imageSpanStart,
    );
    final imageSpan = workspace.substring(imageSpanStart, imageSpanEnd);

    expect(imageSpan, contains('WidgetSpan('));
    expect(imageSpan, contains('style: const TextStyle('));
    expect(imageSpan, contains('decoration: TextDecoration.none'));
    expect(imageSpan, contains('fontStyle: FontStyle.normal'));
  });

  test('document views share direction resolution and keep code LTR', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final direction = File(
      'lib/src/editor/document_text_direction.dart',
    ).readAsStringSync();
    final preview = File(
      'lib/src/markdown/preview_model.dart',
    ).readAsStringSync();

    expect(workspace, contains('_previewBlockTextDirection'));
    expect(workspace, contains("explicitDirection: block.attributes['dir']"));
    expect(workspace, contains('busyMarkDocumentTextDirection('));
    expect(direction, contains('Bidi.startsWithRtl(text)'));
    expect(direction, contains('if (technical)'));
    expect(direction, contains('return TextDirection.ltr'));
    expect(preview, contains('attributes: block.attributes'));
  });

  test('Editor and Preview reuse the shared document callout surface', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();
    final blocks = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final callout = File(
      'lib/src/editor/document_callout.dart',
    ).readAsStringSync();

    expect(callout, contains('class BusyMarkDocumentCallout'));
    expect(workspace, contains('BusyMarkDocumentCallout('));
    expect(editor, contains('BusyMarkDocumentCallout('));
    expect(blocks, contains('BusyMarkDocumentCallout('));
    expect(workspace, isNot(contains('class _PreviewCallout')));
    expect(blocks, isNot(contains('BusyMarkWysiwygBlockquoteFrame')));
  });

  test('document views reuse one code-block surface and typography', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final blocks = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();
    final codeBlock = File(
      'lib/src/editor/document_code_block.dart',
    ).readAsStringSync();
    final surface = File(
      'lib/src/editor/document_surface.dart',
    ).readAsStringSync();

    expect(surface, contains('class BusyMarkDocumentSurface'));
    expect(codeBlock, contains('class BusyMarkDocumentCodeBlock'));
    expect(codeBlock, contains('busyMarkDocumentCodeTextStyle'));
    expect(
      workspace,
      contains('PreviewBlockKind.code => BusyMarkDocumentCodeBlock('),
    );
    expect(workspace, contains('busyMarkDocumentCodeTextStyle(context)'));
    expect(blocks, contains('child: BusyMarkDocumentCodeBlock('));
    expect(blocks, contains('BusyMarkDocumentCodeBlockVariant.embedded'));
    expect(blocks, contains('busyMarkDocumentCodeTextStyle(context)'));
    expect(blocks, contains('busyMarkWysiwygTextLayoutInsets'));
    expect(editor, contains('busyMarkWysiwygTextLayoutInsets(block)'));
    expect(workspace, isNot(contains('PreviewBlockKind.code => Container(')));
    expect(
      workspace,
      contains('PreviewBlockKind.raw => BusyMarkDocumentCodeBlock('),
    );
  });

  test('Editor and Preview reuse one prose line-height style', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final blocks = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();
    final surface = File(
      'lib/src/editor/document_surface.dart',
    ).readAsStringSync();

    expect(surface, contains('busyMarkDocumentBodyTextStyle('));
    expect(surface, contains('height: BusyMarkTypography.bodyLineHeight'));
    expect(workspace, contains('busyMarkDocumentBodyTextStyle(context)'));
    expect(blocks, contains('busyMarkDocumentBodyTextStyle(context)'));
    expect(editor, contains('busyMarkDocumentBodyTextStyle(context)'));
  });

  test('workspace isolates technical labels only at rendering boundaries', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final compact = workspace.replaceAll(RegExp(r'\s+'), ' ');

    expect(workspace, contains('String _tocNodeDisplayLabel('));
    expect(
      workspace,
      contains(
        'await _copyToClipboard(topic == null ? rawLabel : topic.baseName)',
      ),
    );
    expect(
      compact,
      isNot(matches(RegExp(r'l10n\.\w+\([^)]*busyMark(?:Ltr|Bidi)Isolate'))),
    );
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
    expect(singleMarkdownClause, isNot(contains('_SidebarTab.git')));
    expect(
      workspace,
      contains('showTabMenu: !widget.searchState.active && tabs.length > 1'),
    );
    expect(workspace, contains('_preferredSidebarTabIndex'));
    expect(workspace, contains('_shouldShowOutlineForOpenFile'));
    expect(workspace, contains('tabs.indexOf(_SidebarTab.outline)'));
    expect(
      workspace,
      contains('widget.workspace.activeFilePath != _activeFilePath'),
    );
    final activeFileUpdateClause = RegExp(
      r'if \(widget\.workspace\.activeFilePath != _activeFilePath\) \{(.*?)\n    \}',
      dotAll: true,
    ).firstMatch(workspace)!.group(1)!;
    expect(
      activeFileUpdateClause,
      contains('_activeFilePath = widget.workspace.activeFilePath;'),
    );
    expect(
      activeFileUpdateClause,
      isNot(contains('_tab = _preferredSidebarTabIndex')),
    );
    expect(folderClause, contains('_SidebarTab.files'));
    expect(folderClause, contains('_SidebarTab.outline'));
    expect(folderClause, contains('_SidebarTab.git'));
    expect(folderClause, isNot(contains('_SidebarTab.toc')));
    expect(writersideClause, contains('_SidebarTab.files'));
    expect(writersideClause, contains('_SidebarTab.toc'));
    expect(writersideClause, contains('_SidebarTab.outline'));
    expect(writersideClause, contains('_SidebarTab.git'));
  });

  test('sidebar tabs and editor hover use neutral native surfaces', () {
    final theme = File('lib/src/app/app_theme.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final sourceEditor = File(
      'lib/src/editor/source/source_editor.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();

    expect(theme, contains('segmentedButtonTheme: SegmentedButtonThemeData'));
    expect(
      theme,
      contains('final yaruButtonGeometry = base.filledButtonTheme.style'),
    );
    expect(theme, contains('shape: segmentedShape'));
    expect(theme, contains('padding: yaruButtonGeometry?.padding'));
    expect(theme, contains('minimumSize: segmentedMinimumSize'));
    expect(theme, isNot(contains('StadiumBorder')));
    expect(
      theme,
      contains('side: const WidgetStatePropertyAll(BorderSide.none)'),
    );
    expect(theme, contains('return colors.controlActive;'));
    expect(theme, contains('return colors.control;'));
    expect(theme, contains('return colors.foreground;'));
    expect(theme, isNot(contains('return selectedContainer;')));
    expect(settings, isNot(contains('SegmentedButton<')));
    expect(settings, isNot(contains('ButtonSegment(')));
    expect(settings, isNot(contains('class _SegmentLabel')));
    expect(
      settings,
      contains('BusyMarkPopupSelector<BusyMarkThemeModePreference>('),
    );
    expect(
      settings,
      contains('BusyMarkPopupSelector<EditorToolbarPlacement>('),
    );
    expect(
      settings,
      contains('BusyMarkPopupSelector<EditorToolbarDirection>('),
    );
    expect(workspace, contains('BusyMarkHeaderPopupMenuButton<_SidebarTab>'));
    expect(workspace, isNot(contains('class _SidebarSegmentLabel')));
    expect(workspace, contains('softWrap: false'));
    expect(
      sourceEditor,
      contains('hoverColor: BusyMarkLinuxPalette.transparent'),
    );
    expect(
      sourceEditor,
      contains('focusColor: BusyMarkLinuxPalette.transparent'),
    );
    expect(sourceEditor, contains('selectionHeightStyle: BoxHeightStyle.max'));
    expect(sourceEditor, contains('selectionWidthStyle: BoxWidthStyle.tight'));
    expect(sourceEditor, contains('cursorColor: colors.foreground.withValues'));
    expect(sourceEditor, contains('BusyMarkAlpha.sourceCursor'));
    expect(
      sourceEditor,
      contains('BusyMarkTypography.sourceCursorHeightScale'),
    );
    expect(sourceEditor, contains('cursorWidth: BusyMarkStroke.sourceCursor'));
  });

  test('sidebar header menu uses shared popup menu', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(workspace, contains('BusyMarkHeaderPopupMenuButton<_SidebarTab>'));
    expect(workspace, contains('BusyMarkPopupMenuItem('));
    expect(workspace, contains('tooltip: context.l10n.sidebarViewMenu'));
    expect(workspace, contains('icon: _sidebarTabIcon('));
    expect(workspace, contains('transparent: true'));
    expect(
      workspace,
      contains('borderRadius: BusyMarkRadius.nativeHeaderButton'),
    );
    expect(
      workspace,
      matches(
        RegExp(
          r'icon: _sidebarTabIcon\(\s*tab,\s*Directionality\.of\(context\),?\s*\)',
        ),
      ),
    );
    expect(workspace, contains('shortcut: _sidebarTabShortcut(tab)'));
    expect(workspace, contains('BusyMarkSidebarShortcutActivators.history'));
    expect(workspace, contains('LogicalKeyboardKey.numpad5'));
    expect(
      workspace,
      contains('_SidebarTab.files => BusyMarkGlyphs.documentOpen'),
    );
    expect(
      workspace,
      contains('_SidebarTab.toc => BusyMarkGlyphs.orderedList'),
    );
    expect(workspace, contains('_SidebarTab.outline => BusyMarkGlyphs.indent'));
    expect(workspace, contains('_SidebarTab.git => BusyMarkGlyphs.checklist'));
    expect(
      workspace,
      contains('_SidebarTab.gitHistory => BusyMarkGlyphs.history'),
    );
    expect(
      workspace,
      contains(
        '_SidebarTab.gitHistory => BusyMarkSidebarShortcutLabels.history',
      ),
    );
    expect(workspace, contains('checked: tab == selectedTab'));
    expect(workspace, contains('trailingCheck: true'));
    expect(workspace, isNot(contains('SegmentedButton<int>')));
    expect(workspace, isNot(contains('DropdownButton<_SidebarTab>')));
    expect(workspace, isNot(contains('BusyMarkMenuSelectorButton')));
  });

  test('shared popup menus prefer GTK with a themed framework fallback', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final headerPopup = RegExp(
      r'class BusyMarkHeaderPopupMenuButton<T>[\s\S]*?Future<T\?> '
      r'showBusyMarkContextMenu',
    ).firstMatch(design)!.group(0)!;
    final popupItem = RegExp(
      r'class BusyMarkPopupMenuItem<T>[\s\S]*?class BusyMarkPopupSelectorOption',
    ).firstMatch(design)!.group(0)!;

    expect(headerPopup, contains('NativeMenuService'));
    expect(headerPopup, contains('showBusyMarkMenu<T>('));
    expect(headerPopup, contains('_busyMarkNativeMenuEntries'));
    expect(headerPopup, contains('BusyMarkMenuSession'));
    expect(headerPopup, contains('nativeMenuService.show('));
    expect(headerPopup, contains('showMenu<T>('));
    expect(headerPopup, contains('BusyMarkHeaderIconButton('));
    expect(
      headerPopup,
      contains('selected: widget.highlightWhenOpen && (_loading || _open)'),
    );
    expect(headerPopup, contains('requestFocus: true'));
    expect(headerPopup, contains('findRenderObject()'));
    expect(headerPopup, contains('BoxConstraints.tightFor'));
    expect(headerPopup, isNot(contains('PopupMenuButton<T>(')));
    expect(headerPopup, isNot(contains('popupMenuShortcutWidth')));
    expect(headerPopup, isNot(contains('RelativeRect.fromLTRB')));
    expect(headerPopup, isNot(contains('_BusyMarkHeaderPopoverShape')));
    expect(headerPopup, isNot(contains('shape:')));
    expect(headerPopup, isNot(contains('color:')));
    expect(headerPopup, isNot(contains('elevation:')));
    expect(headerPopup, isNot(contains('shadowColor:')));
    expect(design, isNot(contains('BusyMarkPopupEscapeDismissBinding')));
    expect(
      design,
      contains('static const double nativeHeaderButton = kYaruButtonRadius'),
    );
    expect(
      design,
      contains('double borderRadius = BusyMarkRadius.headerButton'),
    );
    expect(design, contains('BorderRadius.circular(borderRadius)'));
    final headerIcon = RegExp(
      r'class BusyMarkHeaderIconButton[\s\S]*?class '
      r'BusyMarkCompactIconButton',
    ).firstMatch(design)!.group(0)!;
    expect(headerIcon, contains('final button = IconButton('));
    expect(headerIcon, contains('style: style.merge(yaruDefaults)'));
    expect(headerIcon, contains('isSelected: selected'));
    expect(headerIcon, contains('padding: EdgeInsets.zero'));
    expect(headerIcon, contains('YaruFocusBorder.primary('));
    expect(headerIcon, contains('YaruTheme.maybeOf(context)?.focusBorders'));
    expect(headerIcon, isNot(contains('return YaruIconButton(')));
    expect(headerIcon, isNot(contains('DecoratedBox(')));
    expect(headerIcon, isNot(contains('BoxShadow(')));
    expect(popupItem, contains('extends PopupMenuItem<T>'));
    expect(popupItem, contains('child: KeyedSubtree('));
    expect(popupItem, contains('_BusyMarkPopupMenuItemContent('));
    expect(popupItem, contains('textDirection: TextDirection.ltr'));
    expect(popupItem, isNot(contains('Navigator.pop')));
    expect(popupItem, isNot(contains('InkWell(')));
  });

  test('Git branch actions use the shared workspace-header popup', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final gitSidebar = File(
      'lib/src/git/presentation/git_sidebar_tab.dart',
    ).readAsStringSync();

    expect(workspace, contains('BusyMarkHeaderPopupMenuButton<_SidebarTab>'));
    expect(
      workspace,
      contains('BusyMarkHeaderPopupMenuButton<_BranchMenuAction>'),
    );
    expect(workspace, contains('_loadWorkspaceBranchMenuItems'));
    expect(workspace, contains('_sidebarBranchMenuItems'));
    expect(workspace, contains('_performWorkspaceBranchAction'));
    expect(workspace, contains('controller.loadBranches()'));
    expect(workspace, contains('label: context.l10n.gitNewBranch'));
    expect(workspace, contains('label: context.l10n.gitPull'));
    expect(workspace, contains('label: context.l10n.gitPush'));
    expect(workspace, contains('value: const _PullBranchMenuAction()'));
    expect(workspace, contains('value: const _PushBranchMenuAction()'));
    expect(workspace, contains('enabled: repository.upstreamBranch != null'));
    expect(workspace, contains('enabled: repository.hasRemote'));
    expect(workspace, contains('tooltip: context.l10n.gitBranchActions'));
    expect(workspace, contains("ValueKey('workspace-sidebar-branch-menu')"));
    expect(workspace, isNot(contains('_showWorkspaceBranchMenu')));
    expect(workspace, isNot(contains('_showSidebarBranchMenu')));
    expect(workspace, isNot(contains('_sidebarMenuLeft')));
    expect(workspace, isNot(contains('_BoldDownArrowIcon')));
    expect(workspace, contains("ValueKey('workspace-sidebar-primary-row')"));
    expect(workspace, contains('class _SidebarHeaderRow'));
    expect(workspace, contains('minHeight: BusyMarkSizes.iconButton'));
    expect(
      RegExp(
        r"ValueKey\('workspace-sidebar-first-content'\)",
      ).allMatches(workspace).length,
      greaterThanOrEqualTo(4),
    );
    expect(workspace, contains('text: _workspaceDisplayName(context'));
    expect(workspace, contains("ValueKey('workspace-sidebar-outline-tree')"));
    expect(
      workspace,
      isNot(contains("ValueKey('workspace-sidebar-outline-heading')")),
    );
    expect(workspace, isNot(contains('_outlineHeaderHeading')));
    expect(workspace, isNot(contains('_outlineTreeHeadings')));
    expect(
      workspace,
      contains('widget.searchState.active ? null : selectedTab'),
    );
    expect(workspace, contains('selectedTab == _SidebarTab.git'));
    expect(workspace, contains('selectedTab == _SidebarTab.gitHistory'));
    expect(workspace, contains('Future<void> _showWorkspacePathMenu'));
    expect(
      workspace,
      contains('Future<_PathMenuAction?> _showSidebarPathMenu'),
    );
    expect(workspace, contains('showBusyMarkContextMenu<_PathMenuAction>'));
    expect(
      workspace,
      contains('BusyMarkHeaderPopupMenuButton<_PathMenuAction>'),
    );
    expect(workspace, contains('_sidebarPathMenuItems'));
    expect(workspace, contains('_performWorkspacePathAction'));
    expect(workspace, contains("ValueKey('workspace-sidebar-path-menu')"));
    expect(workspace, contains('tooltip: context.l10n.pathActions'));
    expect(workspace, contains('icon: BusyMarkGlyphs.menuVertical'));
    expect(workspace, isNot(contains('SystemMouseCursors.contextMenu')));
    expect(workspace, contains('onSecondaryTapUp: (lineContext, details)'));
    expect(workspace, contains('position: details.globalPosition'));
    expect(
      workspace,
      contains('tooltip: busyMarkLtrIsolateFor(context, path)'),
    );
    expect(
      workspace,
      contains('selectedTab == _SidebarTab.files && path.isNotEmpty'),
    );
    expect(workspace, isNot(contains('tooltip: context.l10n.openInFiles')));
    expect(workspace, contains('icon: WorkspaceGlyphs.branch'));
    expect(workspace, isNot(contains('boldLeadingIcon')));
    expect(workspace, isNot(contains('_BoldBranchIcon')));
    expect(workspace, isNot(contains('_BoldBranchIconPainter')));
    expect(workspace, contains('inlineTrailing: _branchSyncIndicators'));
    expect(workspace, contains('repository.behindCount > 0'));
    expect(workspace, contains('context.l10n.gitBehindCount'));
    expect(workspace, contains('repository.aheadCount > 0'));
    expect(workspace, contains('context.l10n.gitAheadCount'));
    expect(workspace, contains('class _BranchSyncIndicator'));
    expect(gitSidebar, isNot(contains('_RepositoryStrip')));
    expect(
      gitSidebar,
      isNot(contains('BusyMarkHeaderPopupMenuButton<GitView>')),
    );
    expect(
      gitSidebar,
      isNot(contains('BusyMarkHeaderPopupMenuButton<_BranchMenuAction>')),
    );
    expect(gitSidebar, isNot(contains('context.l10n.gitClean')));
    expect(gitSidebar, isNot(contains('context.l10n.gitAheadCount')));
    expect(gitSidebar, isNot(contains('color: colors.secondarySidebar')));
    expect(
      File('lib/src/app/busymark_glyphs.dart').readAsStringSync(),
      contains(
        'branch = Icons'
        '.fork_right',
      ),
    );
    expect(gitSidebar, isNot(contains('OutlinedButton(')));
    expect(gitSidebar, isNot(contains('SegmentedButton<GitView>')));
    expect(gitSidebar, isNot(contains('GitBranchesView')));
    expect(gitSidebar, isNot(contains('git_branches_view.dart')));
  });

  test('Git changes view uses an integrated commit panel', () {
    final gitChanges = File(
      'lib/src/git/presentation/git_changes_view.dart',
    ).readAsStringSync();
    final gitFileStatusColors = File(
      'lib/src/git/presentation/git_file_status_colors.dart',
    ).readAsStringSync();

    expect(gitChanges, contains('class _CommitPanel'));
    expect(gitChanges, contains('context.l10n.gitCommitMessage'));
    expect(gitChanges, contains('BusyMarkCheckbox('));
    expect(gitChanges, isNot(contains('_CommitSelectionCheckbox')));
    expect(gitChanges, isNot(contains('YaruCheckbox(')));
    expect(
      File('lib/src/app/busymark_design.dart').readAsStringSync(),
      contains('YaruCheckbox('),
    );
    expect(gitChanges, contains('context.l10n.gitSelectForCommit'));
    expect(gitChanges, contains('context.l10n.gitCommitSelectedFiles'));
    expect(gitChanges, contains('busyMarkVcsFileStatusColor'));
    expect(gitChanges, contains('busyMarkVcsFileColorForGitStatus(file)'));
    expect(gitFileStatusColors, contains('BusyMarkVcsFileColor.modified'));
    expect(gitChanges, contains('BusyMarkPushButton.suggested('));
    expect(gitChanges, isNot(contains('BusyMarkDialogButton(')));
    expect(gitChanges, isNot(contains('context.l10n.git${'Include'}InCommit')));
    expect(
      gitChanges,
      isNot(contains('context.l10n.git${'Exclude'}FromCommit')),
    );
    expect(gitChanges, isNot(contains('context.l10n.git${'Not'}Included')));
    expect(gitChanges, isNot(contains('_FileAction.${'include'}')));
    expect(gitChanges, isNot(contains('_FileAction.${'exclude'}')));
    expect(gitChanges, isNot(contains('context.l10n.gitStage')));
    expect(gitChanges, isNot(contains('context.l10n.gitUnstage')));
    expect(gitChanges, isNot(contains('FilledButton.icon')));
    expect(gitChanges, isNot(contains('showDialog<void>')));
    expect(gitChanges, isNot(contains('GitCommitDialog')));
  });

  test('Git sidebar actions use the shared semantic button adapter', () {
    final gitSidebar = File(
      'lib/src/git/presentation/git_sidebar_tab.dart',
    ).readAsStringSync();

    expect(gitSidebar, contains('BusyMarkPushButton.standard('));
    expect(gitSidebar, isNot(contains('FilledButton(')));
  });

  test('settings selectors delegate to the shared native menu', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(settings, isNot(contains('DropdownButton<String>')));
    expect(settings, contains('BusyMarkPopupSelector<String>('));
    expect(
      settings,
      contains('BusyMarkPopupSelector<BusyMarkThemeModePreference>('),
    );
    expect(
      settings,
      contains('BusyMarkPopupSelector<EditorToolbarPlacement>('),
    );
    expect(
      settings,
      contains('BusyMarkPopupSelector<EditorToolbarDirection>('),
    );
    expect(settings, isNot(contains('SegmentedButton<')));
    expect(settings, isNot(contains('class _LanguageSelectorButton')));
    expect(workspace, isNot(contains('DropdownButtonFormField')));
    expect(
      workspace,
      contains('BusyMarkPopupSelector<WritersideTopicRedirectTarget>'),
    );
    expect(
      workspace,
      contains('BusyMarkComboRow<WritersideTopicCreatePlacement>'),
    );
    final selector = RegExp(
      r'class BusyMarkPopupSelector<T>[\s\S]*?'
      r'InputDecorationThemeData busyMarkGroupedInputDecorationTheme',
    ).firstMatch(design)!.group(0)!;
    expect(selector, contains('BusyMarkMenuButton<T>('));
    expect(selector, contains('Theme.of(context).outlinedButtonTheme.style'));
    expect(
      selector,
      contains('side: const WidgetStatePropertyAll(BorderSide.none)'),
    );
    expect(selector, contains('BusyMarkPopupMenuItem<T>('));
    expect(selector, contains('softWrap: false'));
    expect(selector, contains('BusyMarkPushButton.standard('));
    expect(selector, isNot(contains('WidgetStatesController()')));
    expect(selector, isNot(contains('showMenu<T>(')));
    expect(selector, isNot(contains('MouseRegion(')));
    expect(selector, isNot(contains('shape:')));
    expect(selector, isNot(contains('color:')));
    expect(selector, isNot(contains('elevation:')));
    expect(selector, isNot(contains('shadowColor:')));
  });

  test('report issue form uses the native grouped modal editor', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();
    final feedback = File(
      'lib/src/feedback/presentation/feedback_dialog.dart',
    ).readAsStringSync();

    expect(design, contains('class BusyMarkPopupSelector<T>'));
    expect(design, contains('class BusyMarkComboRow<T>'));
    expect(design, contains('class BusyMarkModalEditorScaffold'));
    expect(design, contains('busyMarkGroupedTextFieldDecoration('));
    expect(settings, contains('BusyMarkPopupSelector<String>('));
    expect(RegExp(r'YaruListTile\.square\(').allMatches(feedback).length, 3);
    expect(feedback, contains('BusyMarkModalEditorScaffold('));
    expect(feedback, contains('BusyMarkComboRow<FeedbackCategory?>('));
    expect(
      feedback,
      contains('values: const [null, ...FeedbackCategory.values]'),
    );
    expect(feedback, contains('busyMarkGroupedTextFieldDecoration('));
    expect(feedback, contains('YaruCheckboxListTile('));
    expect(feedback, contains('CallbackShortcuts('));
    expect(feedback, isNot(contains('BusyMarkDialogShell(')));
    expect(feedback, isNot(contains('BusyMarkDialogButton(')));
    expect(
      feedback,
      isNot(contains('BusyMarkPopupSelector<FeedbackCategory>')),
    );
    expect(feedback, isNot(contains('BusyMarkFloatingTextEntry(')));
    expect(feedback, isNot(contains('BusyMarkSwitchRow(')));
    expect(feedback, isNot(contains('BusyMarkStatusBox(')));
    expect(feedback, isNot(contains('DropdownButtonFormField')));
    expect(feedback, isNot(contains('InputDecoration(')));
    expect(feedback, isNot(contains('InkWell(')));
    expect(
      design,
      contains("delegated to BusyMark's GTK menu bridge on Linux"),
    );
  });

  test('data-entry dialogs use native grouped modal editors', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
    ).readAsStringSync();

    expect(design, contains('class BusyMarkGroupedTextEntry'));
    final entries = RegExp(
      r'class BusyMarkGroupedTextEntry[\s\S]*?class BusyMarkClamp',
    ).firstMatch(design)!.group(0)!;
    expect(entries, contains('return YaruListTile.square('));
    expect(entries, contains('title: TextFormField('));
    expect(entries, contains('busyMarkGroupedTextFieldDecoration('));
    expect(entries, contains('trailing: trailing'));
    expect(entries, isNot(contains('EditableText(')));
    expect(entries, isNot(contains('MouseRegion(')));
    expect(entries, isNot(contains('GestureDetector(')));
    expect(entries, isNot(contains('busyMarkSurfaceDecoration(')));
    expect(welcome, contains('showBusyMarkModalEditorDialog<bool>('));
    expect(welcome, contains('BusyMarkModalEditorScaffold('));
    expect(RegExp(r'BusyMarkGroupedTextEntry\(').allMatches(welcome).length, 5);
    expect(workspace, contains('showBusyMarkModalEditorDialog<String>('));
    expect(workspace, contains('showBusyMarkModalEditorDialog<void>('));
    expect(editor, contains('showBusyMarkModalEditorDialog<T>('));
    expect(welcome, isNot(contains('BusyMarkFloatingTextEntry')));
    expect(workspace, isNot(contains('BusyMarkFloatingTextEntry')));
    expect(editor, isNot(contains('BusyMarkFloatingTextEntry')));
    expect(welcome, isNot(contains('autofocus: true')));
    expect(
      welcome,
      isNot(contains('hintText: context.l10n.defaultProjectName')),
    );
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
    expect(
      workspace,
      contains('BusyMarkGlyphs.collapsedTreeArrowFor(direction)'),
    );
    expect(workspace, contains('YaruIcons.folder_open'));
    expect(workspace, contains('YaruIcons.folder'));
    expect(workspace, contains('busyMarkRowHoverColor(context)'));
    expect(workspace, contains('_FileTreeVcsStatusColors.fromSnapshot'));
    expect(workspace, contains('vcsColor: vcsStatusColors.colorForNode(node)'));
    expect(
      workspace,
      contains('busyMarkVcsFileStatusColor(context, vcsColor!)'),
    );
    expect(workspace, contains('busyMarkVcsFileColorForGitStatus(status)'));
    expect(workspace, contains('_isOpenableTextDocument(file)'));
    expect(workspace, contains('enabled: node.isFolder || openable'));
    expect(workspace, contains('openActiveFile(file.absolutePath)'));
    expect(workspace, contains('_showFileTreeMenu'));
    expect(workspace, contains('onSecondaryTapUp'));
    expect(
      RegExp(
        r'BusyMarkTreeShortcutActivators\.deleteSelection',
      ).allMatches(workspace).length,
      greaterThanOrEqualTo(2),
    );
    expect(
      RegExp(
        r'shortcut: BusyMarkTreeShortcutLabels\.deleteSelection',
      ).allMatches(workspace).length,
      greaterThanOrEqualTo(2),
    );
    expect(
      RegExp(
        r'SingleActivator\s*\(\s*LogicalKeyboardKey\.delete',
      ).hasMatch(workspace),
      isFalse,
    );
    expect(
      RegExp(r'''shortcut:\s*['"]Delete['"]''').hasMatch(workspace),
      isFalse,
    );
    expect(workspace, contains('class _WritersideTopicRemovalDialog'));
    expect(workspace, contains('class _WritersideTopicUsagesSidebar'));
    expect(workspace, contains('analyzeWritersideTopicRemoval('));
    expect(workspace, contains('applyWritersideTopicRemoval('));
    expect(workspace, contains('context.l10n.safeDeleteTopicFile'));
    expect(workspace, contains('context.l10n.removeTocElement'));
    expect(workspace, contains('label: context.l10n.newFile'));
    expect(workspace, contains('label: context.l10n.rename'));
    expect(workspace, contains('label: context.l10n.cut'));
    expect(workspace, contains('label: context.l10n.paste'));
    expect(workspace, contains('label: context.l10n.delete'));
    expect(workspace, contains('label: context.l10n.addToGit'));
    expect(workspace, contains('createWorkspaceFile('));
    expect(workspace, contains('renameWorkspaceEntity('));
    expect(workspace, contains('moveWorkspaceEntity('));
    expect(workspace, contains('deleteWorkspaceEntity('));
    expect(workspace, contains('stageFiles(['));
    expect(workspace, contains('label: context.l10n.copyName'));
    expect(workspace, contains('label: context.l10n.copyPath'));
    expect(workspace, contains('label: context.l10n.openInFiles'));
    expect(workspace, contains('_FileTreeAction.openInFiles'));
    expect(workspace, contains('class _FileHistorySidebar'));
    expect(workspace, contains('_fileHistoryFile'));
    expect(workspace, contains('onBack: _closeFileHistory'));
    expect(workspace, contains('label: context.l10n.fileHistory'));
    expect(workspace, contains('loadFileHistory('));
    expect(workspace, contains('file.absolutePath'));
    final tocHeader = RegExp(
      r'class _TocHeader[\s\S]*?class _CreateWritersideTopicDialog',
    ).firstMatch(workspace)!.group(0)!;
    expect(
      tocHeader,
      contains('BusyMarkHeaderPopupMenuButton<_TocHeaderAction>'),
    );
    expect(tocHeader, contains("ValueKey('workspace-sidebar-toc-menu')"));
    expect(tocHeader, contains('tooltip: context.l10n.tocActions'));
    expect(tocHeader, contains('icon: BusyMarkGlyphs.menuVertical'));
    expect(tocHeader, contains('highlightWhenOpen: false'));
    expect(tocHeader, contains('label: context.l10n.newTopic'));
    expect(tocHeader, isNot(contains('BusyMarkHeaderIconButton')));
    expect(tocHeader, isNot(contains('context.l10n.newChildTopic')));
    expect(tocHeader, isNot(contains('onCreateChildTopic')));
    expect(workspace, contains('_TocTreeAction.newChildTopic'));
    expect(workspace, contains('label: context.l10n.newChildTopic'));
    expect(
      workspace,
      isNot(contains('_selectTab(_SidebarTab.gitHistory, tabs)')),
    );
    expect(workspace, isNot(contains('class _FileTreeRow')));
    expect(workspace, isNot(contains('class _SidebarTile')));
    expect(workspace, isNot(contains('title: file.relativePath')));
    expect(workspace, isNot(contains('subtitle: _documentKindLabel')));
  });

  test('outline tree drives source and preview heading navigation', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final sourceEditor = File(
      'lib/src/editor/source/source_editor.dart',
    ).readAsStringSync();

    expect(workspace, contains('_outlineNavigationTargetProvider'));
    expect(workspace, contains('_OutlineNavigationTarget'));
    expect(workspace, contains('outline: _activeDocumentOutline(state)'));
    expect(workspace, contains('return preview.outline'));
    expect(workspace, contains('headingId: heading.id'));
    expect(workspace, contains('line: heading.sourceStartLine'));
    expect(workspace, contains('workspaceId: widget.workspace.id'));
    expect(workspace, isNot(contains('widget.workspace.markdown?.headings')));
    expect(workspace, contains('_sourceEditorKey.currentState?.scrollToLine'));
    expect(sourceEditor, contains('_focusNode.requestFocus()'));
    expect(sourceEditor, contains('_unfoldSourceLine(line)'));
    expect(sourceEditor, contains('sourceLineLayoutEntries'));
    expect(sourceEditor, contains('_scrollOffsetForLine'));
    expect(sourceEditor, contains('_jumpScrollToLine'));
    expect(sourceEditor, contains('scrollController: _scrollController'));
    expect(workspace, contains('Scrollable.ensureVisible'));
    expect(workspace, contains('alignment: 0.0'));
    expect(workspace, isNot(contains('alignment: 0.04')));
    expect(workspace, contains('headingKeys: _previewHeadingKeys'));
    expect(workspace, contains('keyedHeadingIds'));
    expect(
      workspace,
      contains('headingKey: _keyForBlock(block, keyedHeadingIds)'),
    );
    expect(workspace, contains('if (!keyedHeadingIds.add(id))'));
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

  test('preview search navigation targets clicked result source span', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final preview = File(
      'lib/src/markdown/preview_model.dart',
    ).readAsStringSync();

    expect(workspace, contains('_previewSearchBlockIndex'));
    expect(workspace, contains('_previewBlockContainsSearchTarget'));
    expect(workspace, contains('_previewBlockTargetFraction'));
    expect(workspace, contains('_schedulePreviewSearchScroll'));
    expect(workspace, contains('localToGlobal'));
    expect(workspace, contains('position.pixels + targetY - viewportTop'));
    expect(workspace, contains('target.startOffset >= startOffset'));
    expect(workspace, contains('target.line >= startLine'));
    expect(workspace, contains('_scrollPreviewToApproximateLine'));
    expect(workspace, contains('nearestBeforeIndex'));
    expect(workspace, isNot(contains('return fallbackIndex')));
    expect(
      workspace,
      contains('Future<void>.delayed(BusyMarkMotion.previewSearchDelay'),
    );
    expect(preview, contains('sourceStartLine'));
    expect(preview, contains('sourceStartOffset'));
    expect(preview, contains('span.startLine'));
    expect(preview, contains('span.startOffset'));
  });

  test('source editor line numbers use measured editor layout', () {
    final sourceEditor = File(
      'lib/src/editor/source/source_editor.dart',
    ).readAsStringSync();
    final sourceGutter = File(
      'lib/src/editor/source/source_gutter.dart',
    ).readAsStringSync();
    final sourceController = File(
      'lib/src/editor/source/source_controller.dart',
    ).readAsStringSync();

    expect(sourceEditor, contains('isCollapsed: true'));
    expect(
      sourceEditor,
      contains('_sourceLineHeight(context, sourceStrutStyle)'),
    );
    expect(sourceEditor, contains('_SourceRenderedTextLayer'));
    expect(sourceController, contains('renderText = false'));
    expect(sourceEditor, contains('controller.buildSourceTextSpan'));
    expect(sourceGutter, contains('TextPainter('));
    expect(sourceGutter, contains('computeLineMetrics()'));
    expect(sourceGutter, contains('getOffsetForCaret'));
    expect(sourceGutter, contains('sourceTextHeightForLine'));
    expect(sourceEditor, contains('_CollapsedSourceLineOverlay'));
    expect(sourceEditor, contains('_sourceStrutStyle('));
    expect(sourceEditor, contains('folded: _foldedRegionKeys.isNotEmpty'));
    expect(sourceEditor, contains('if (folded)'));
    expect(sourceEditor, contains('return null'));
    expect(
      sourceEditor,
      contains('StrutStyle.fromTextStyle(_sourceTextStyle)'),
    );
    expect(sourceEditor, contains('strutStyle: sourceStrutStyle'));
    expect(sourceEditor, contains('TextOverflow.ellipsis'));
    expect(sourceEditor, contains('Color.alphaBlend'));
    expect(sourceEditor, contains("'\$trimmed ...'"));
  });

  test('document view modes drive source preview and split layouts', () {
    final settings = File('lib/src/app/app_settings.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final sourceController = File(
      'lib/src/editor/source/source_controller.dart',
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
    expect(sourceController, contains('visualMarkdown = false'));
    expect(workspace, isNot(contains('class _VisualMarkdownEditorPane')));
    expect(workspace, contains('if (sourceVisible && previewVisible)'));
    expect(workspace, contains('if (previewVisible)'));
    expect(workspace, isNot(contains('class _DiffSharedHunkHeader')));
    expect(
      workspace,
      contains('target: _diffChangeTarget(diff, _currentChangeIndex)'),
    );
    expect(workspace, contains('format: context.l10n.gitDiffHunkRange'));
    expect(workspace, contains('noLinesText: context.l10n.gitDiffNoLines'));
    expect(workspace, contains('showFileActions: !splitVisible'));
    expect(workspace, contains('showHunkHeaders: !splitVisible'));
    expect(settingsScreen, isNot(contains('Show preview pane')));
    expect(settingsScreen, isNot(contains('setPreviewVisible')));
  });

  test('WYSIWYG toolbar exposes fuller Markdown controls', () {
    final toolbar = File(
      'lib/src/editor/wysiwyg/wysiwyg_toolbar.dart',
    ).readAsStringSync();
    final editor = File(
      'lib/src/editor/wysiwyg/wysiwyg_editor.dart',
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
      'context.l10n.heading4',
      'context.l10n.heading5',
      'context.l10n.heading6',
      'context.l10n.toggleTaskChecked',
      'context.l10n.indentListItem',
      'context.l10n.outdentListItem',
      'context.l10n.codeBlockLanguage',
      'context.l10n.inlineImage',
      'context.l10n.table',
      'context.l10n.hardLineBreak',
    ]) {
      expect(toolbar, contains(label));
    }
    for (final shortcut in [
      'BusyMarkEditorShortcutLabels.textStyle',
      'BusyMarkEditorShortcutLabels.toggleTask',
      'BusyMarkEditorShortcutLabels.indent',
      'BusyMarkEditorShortcutLabels.outdent',
      'BusyMarkEditorShortcutLabels.blockquote',
      'BusyMarkEditorShortcutLabels.codeBlock',
      'BusyMarkEditorShortcutLabels.codeBlockLanguage',
      'BusyMarkEditorShortcutLabels.image',
      'BusyMarkEditorShortcutLabels.inlineImage',
      'BusyMarkEditorShortcutLabels.table',
      'BusyMarkEditorShortcutLabels.thematicBreak',
      'BusyMarkEditorShortcutLabels.hardLineBreak',
    ]) {
      expect(toolbar, contains(shortcut));
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
    expect(RegExp(r'transparent: false').allMatches(toolbar), hasLength(2));
    expect(toolbar, contains('BusyMarkHeaderIconButton('));
    expect(toolbar, contains('_editorToolbarButtonBackground(context)'));
    expect(toolbar, contains('return theme.colorScheme.primary'));
    expect(
      RegExp(
        r'foregroundColor: BusyMarkLinuxPalette\.white',
      ).allMatches(toolbar),
      hasLength(2),
    );
    expect(toolbar, isNot(contains('busyMarkContainedControlBackground(')));
    expect(toolbar, isNot(contains('foregroundColor: colors.foreground')));
    expect(RegExp(r'elevated: true').allMatches(toolbar), hasLength(2));
    expect(toolbar, isNot(contains('accented: true')));
    expect(toolbar, contains('clipBehavior: Clip.none'));
    expect(toolbar, contains('hitTestBehavior: HitTestBehavior.deferToChild'));
    expect(toolbar, contains('horizontal: BusyMarkSpacing.sm'));
    expect(toolbar, contains('vertical: BusyMarkSpacing.xs'));
    expect(toolbar, contains('horizontal: BusyMarkSpacing.xs'));
    expect(toolbar, contains('vertical: BusyMarkSpacing.sm'));
    expect(toolbar, isNot(contains('boxShadow:')));
    expect(toolbar, isNot(contains('BusyMarkShadow.')));
    final floatingToolbar = RegExp(
      r'class _FloatingWysiwygToolbar[\s\S]*?class _EditorToolbarMenuAction',
    ).firstMatch(editor)!.group(0)!;
    expect(floatingToolbar, contains('elevated: true'));
    expect(floatingToolbar, contains('accented: true'));
    expect(
      floatingToolbar,
      contains('foregroundColor: BusyMarkLinuxPalette.white'),
    );
    expect(floatingToolbar, isNot(contains('_editorToolbarButtonBackground')));
    expect(floatingToolbar, isNot(contains('boxShadow:')));
    expect(floatingToolbar, isNot(contains('BusyMarkShadow.')));
    final blockWidgets = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    expect(blockWidgets, contains('context.l10n.insertColumnLeft'));
    expect(blockWidgets, contains('context.l10n.insertColumnRight'));
    expect(blockWidgets, contains('context.l10n.insertRowAbove'));
    expect(blockWidgets, contains('context.l10n.insertRowBelow'));
    expect(blockWidgets, contains('context.l10n.deleteTable'));
    final tableControlMenu = RegExp(
      r'class _TableControlMenuButton[\s\S]*?class _TableCellEditor',
    ).firstMatch(blockWidgets)!.group(0)!;
    expect(tableControlMenu, contains('BusyMarkHeaderPopupMenuButton'));
    expect(tableControlMenu, isNot(contains('theme.copyWith')));
    expect(tableControlMenu, isNot(contains('color: colors.popover')));
    expect(tableControlMenu, isNot(contains('elevation: BusyMarkElevation')));
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
    final imageDialog = RegExp(
      r'class _ImageDialog extends.*?class _TableDialogResult',
      dotAll: true,
    ).firstMatch(editor)!.group(0)!;

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
    expect(editor, contains('submitLabel: context.l10n.apply'));
    expect(imageDialog, contains('BusyMarkModalEditorScaffold('));
    expect(imageDialog, contains('BusyMarkGroupedList('));
    expect(imageDialog, contains('BusyMarkGroupedTextEntry('));
    expect(imageDialog, contains('BusyMarkPushButton.standardIcon('));
    expect(imageDialog, contains("hintText: 'images/example.png'"));
    expect(imageDialog, contains('hintText: context.l10n.describeTheImage'));
    expect(imageDialog, isNot(contains('BusyMarkDialogShell(')));
    expect(imageDialog, isNot(contains('BusyMarkFloatingTextEntry(')));
    expect(imageDialog, isNot(contains('BusyMarkDialogButton(')));
    expect(imageDialog, isNot(contains('AlertDialog(')));
    expect(imageDialog, isNot(contains('TextField(')));
    expect(imageDialog, isNot(contains('InputDecoration(')));
    expect(imageDialog, isNot(contains('OutlinedButton(')));
    expect(imageDialog, isNot(contains('TextButton(')));
    expect(imageDialog, isNot(contains('FilledButton(')));
  });

  test('native context menus wait for the secondary pointer release', () {
    final contextMenuSources = <String>[
      File(
        'lib/src/workspace/presentation/workspace_screen.dart',
      ).readAsStringSync(),
      File('lib/src/git/presentation/git_history_view.dart').readAsStringSync(),
      File('lib/src/editor/wysiwyg/wysiwyg_editor.dart').readAsStringSync(),
    ];

    for (final source in contextMenuSources) {
      expect(source, contains('onSecondaryTapUp'));
      expect(source, isNot(contains('onSecondaryTapDown')));
    }
  });

  test('source view has compact gutter without pane status chrome', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final sourceEditor = File(
      'lib/src/editor/source/source_editor.dart',
    ).readAsStringSync();
    final sourceGutter = File(
      'lib/src/editor/source/source_gutter.dart',
    ).readAsStringSync();

    expect(
      sourceEditor,
      contains(
        'static const double _gutterWidth = BusyMarkSizes.sourceGutterWidth;',
      ),
    );
    expect(
      sourceGutter,
      contains(
        'static const double _foldButtonSize = BusyMarkSizes.sourceFoldButton;',
      ),
    );
    expect(sourceGutter, contains('BusyMarkSizes.sourceFoldButtonRightInset'));
    expect(sourceEditor, contains('Positioned.fill('));
    expect(sourceGutter, contains('alignment: Alignment.center'));
    expect(workspace, contains('BusyMarkDocumentLayoutSpec.splitPreview'));
    expect(workspace, contains('BusyMarkDocumentContentFrame('));
    expect(workspace, contains('first: index == 0'));
    expect(
      workspace,
      contains('BusyMarkInsets.documentHeadingBlock.copyWith(top: 0)'),
    );
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
