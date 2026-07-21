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
    expect(router, contains('NoTransitionPage<void>(child: SettingsScreen())'));
    expect(router, isNot(contains('builder: (context, state)')));
    expect(router, isNot(contains('CustomTransitionPage')));
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
    expect(design, contains('cardTheme.shape ?? RoundedRectangleBorder'));
    expect(design, contains('clipBehavior: Clip.antiAlias'));
    expect(design, contains('height: BusyMarkStroke.hairline'));
    expect(design, isNot(contains('YaruTileList')));
    expect(design, isNot(contains('YaruBorderContainer')));
  });

  test('BusyMark dialog title bars use the same surface as dialog body', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogShell = RegExp(
      r'class BusyMarkDialogShell[\s\S]*?class SectionLabel',
    ).firstMatch(design)!.group(0)!;

    expect(dialogShell, contains('final colors = BusyMarkSurfaceColors.of'));
    expect(dialogShell, contains('YaruDialogTitleBar('));
    expect(dialogShell, contains('backgroundColor: colors.dialog'));
    expect(dialogShell, contains('border: BorderSide.none'));
  });

  test('BusyMark dialog buttons use shared shadowed accent surfaces', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final dialogButton = RegExp(
      r'class BusyMarkDialogButton[\s\S]*?enum BusyMarkFloatingTextEntryPosition',
    ).firstMatch(design)!.group(0)!;

    expect(dialogButton, contains('busyMarkSurfaceDecoration('));
    expect(dialogButton, contains('color: background'));
    expect(dialogButton, contains('elevated: _enabled'));
    expect(dialogButton, contains('return colorScheme.primary;'));
    expect(dialogButton, contains('colorScheme.onPrimary'));
    expect(dialogButton, isNot(contains('border: Border.all')));
    expect(dialogButton, isNot(contains('final borderColor')));
  });

  test('shared row hover uses the themed control hover color', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    final helper = RegExp(
      r'Color busyMarkRowHoverColor\(BuildContext context\) \{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(design)!.group(1)!;
    expect(helper, contains('BusyMarkSurfaceColors.of(context).controlHover'));
    expect(helper, isNot(contains('colors.foreground.withValues')));
    expect(design, contains('class _BusyMarkHoverBackground'));
    expect(design, contains('return MouseRegion('));
    expect(design, contains('ColoredBox('));
    expect(design, isNot(contains('AnimatedContainer(')));
    final actionRow = RegExp(
      r'class BusyMarkActionRow[\s\S]*?class BusyMarkSwitchRow',
    ).firstMatch(design)!.group(0)!;
    expect(actionRow, contains('_BusyMarkHoverBackground('));
    expect(actionRow, contains('hoverColor: BusyMarkLinuxPalette.transparent'));
    final switchRow = RegExp(
      r'class BusyMarkSwitchRow[\s\S]*?class BusyMarkDialogShell',
    ).firstMatch(design)!.group(0)!;
    expect(switchRow, contains('_BusyMarkHoverBackground('));
    expect(switchRow, contains('hoverColor: BusyMarkLinuxPalette.transparent'));
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

  test('filled grouped action surfaces use the shared grouped surface', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();

    final groupedSurface = RegExp(
      r'class _BusyMarkGroupedListSurface.*?class BusyMarkActionRow',
      dotAll: true,
    ).firstMatch(design)!.group(0)!;
    expect(groupedSurface, contains('final dividerColor = colors.view'));
    expect(groupedSurface, contains('height: BusyMarkStroke.hairline'));
    expect(groupedSurface, contains('thickness: BusyMarkStroke.hairline'));
    expect(groupedSurface, contains('color: dividerColor'));
    expect(design, contains('required this.groupedList'));
    expect(design, contains('groupedList: Color(0xFFFFFFFF)'));
    expect(design, contains('groupedList: Color(0xFF383838)'));
    expect(groupedSurface, contains('final color = colors.groupedList'));
    expect(groupedSurface, contains('decoration: busyMarkSurfaceDecoration'));
    expect(groupedSurface, contains('ClipRRect('));
    expect(groupedSurface, contains('color: BusyMarkLinuxPalette.transparent'));
    expect(groupedSurface, isNot(contains('borderColor')));
    expect(groupedSurface, isNot(contains('Border.all')));
    expect(groupedSurface, isNot(contains('color: colors.control')));
    expect(groupedSurface, isNot(contains('BusyMarkShadow.surfaceShadows')));
    expect(groupedSurface, isNot(contains('elevation: cardTheme.elevation')));
    expect(welcome, isNot(contains('_welcomeGroupedCardColor')));
    expect(welcome, isNot(contains('cardTheme: theme.cardTheme.copyWith')));
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

  test('preview resolves HTML direction and keeps code LTR by default', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final preview = File(
      'lib/src/markdown/preview_model.dart',
    ).readAsStringSync();

    expect(workspace, contains('_previewBlockTextDirection'));
    expect(
      workspace,
      contains("final explicitDirection = block.attributes['dir']"),
    );
    expect(workspace, contains('Bidi.startsWithRtl(text)'));
    expect(
      workspace,
      contains(
        'PreviewBlockKind.code || PreviewBlockKind.raw => TextDirection.ltr',
      ),
    );
    expect(preview, contains('attributes: block.attributes'));
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
      contains('side: const WidgetStatePropertyAll(BorderSide.none)'),
    );
    expect(theme, contains('return accentColor;'));
    expect(theme, contains('return onAccent;'));
    expect(theme, contains('return selectedContainer;'));
    expect(settings, contains('class _SegmentLabel'));
    expect(settings, contains('maxLines: 1'));
    expect(settings, contains('overflow: TextOverflow.ellipsis'));
    expect(
      settings,
      contains('label: _SegmentLabel(context.l10n.bottomRight)'),
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
      contains('icon: _sidebarTabIcon(tab, Directionality.of(context))'),
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

  test('shared header popup menu matches native popover shape', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    expect(design, contains('showMenu<T>'));
    expect(design, contains('_BusyMarkHeaderPopoverShape'));
    expect(design, contains('_busyMarkHeaderPopoverArrowHeight'));
    expect(design, contains('BorderRadius.circular(BusyMarkRadius.window)'));
    expect(design, contains('color: colors.subtleBorder'));
    expect(design, contains('popupMenuShortcutWidth'));
    expect(design, contains('BoxConstraints.tightFor(width: menuWidth)'));
    expect(design, contains('popUpAnimationStyle: AnimationStyle.noAnimation'));
    expect(design, contains('hoverColor: colors.controlHover'));
    expect(design, contains('static const double nativeHeaderButton = 6'));
    expect(
      design,
      contains('double borderRadius = BusyMarkRadius.headerButton'),
    );
    expect(design, contains('BorderRadius.circular(borderRadius)'));
    expect(design, contains('final String? shortcut;'));
    expect(design, contains('final shortcutText = shortcut == null'));
    expect(design, contains('textDirection: TextDirection.ltr'));
    expect(design, isNot(contains("message: '\${widget.label}")));
    expect(design, contains('this.enabled = true'));
    expect(design, contains('enabled: widget.enabled'));
    expect(design, contains('colors.disabledForeground'));
    expect(
      design,
      contains('EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm)'),
    );
  });

  test('Git branch menu lives in workspace header outside Commit panel', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final gitSidebar = File(
      'lib/src/git/presentation/git_sidebar_tab.dart',
    ).readAsStringSync();

    expect(workspace, contains('BusyMarkHeaderPopupMenuButton<_SidebarTab>'));
    expect(workspace, contains('Future<void> _showWorkspaceBranchMenu'));
    expect(
      workspace,
      contains('Future<_BranchMenuAction?> _showSidebarBranchMenu'),
    );
    expect(workspace, contains('controller.loadBranches()'));
    expect(workspace, contains('label: context.l10n.gitNewBranch'));
    expect(workspace, contains('label: context.l10n.gitPull'));
    expect(workspace, contains('label: context.l10n.gitPush'));
    expect(workspace, contains('value: const _PullBranchMenuAction()'));
    expect(workspace, contains('value: const _PushBranchMenuAction()'));
    expect(workspace, contains('enabled: repository.upstreamBranch != null'));
    expect(workspace, contains('enabled: repository.hasRemote'));
    expect(workspace, contains('tooltip: context.l10n.gitBranches'));
    expect(workspace, contains('Future<void> _showWorkspacePathMenu'));
    expect(
      workspace,
      contains('Future<_PathMenuAction?> _showSidebarPathMenu'),
    );
    expect(workspace, contains('tooltip: context.l10n.openInFiles'));
    expect(workspace, contains('icon: WorkspaceGlyphs.branch'));
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
      contains('branch = YaruIcons.network_wired'),
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
    expect(gitChanges, contains('BusyMarkDialogButton('));
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

  test('settings language selector uses native hover and popover styling', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();

    expect(settings, isNot(contains('DropdownButton<String>')));
    expect(settings, contains('BusyMarkPopupSelector<String>('));
    expect(settings, isNot(contains('class _LanguageSelectorButton')));
    expect(design, contains('class BusyMarkPopupSelector<T>'));
    expect(design, contains('MouseRegion('));
    expect(design, contains('colors.controlHover'));
    expect(design, contains('elevation: BusyMarkElevation.window'));
    expect(design, contains('BusyMarkAlpha.languageMenuShadow'));
    expect(design, contains('softWrap: false'));
  });

  test('report issue form uses shared BusyMark desktop controls', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final settings = File(
      'lib/src/workspace/presentation/settings_screen.dart',
    ).readAsStringSync();
    final feedback = File(
      'lib/src/feedback/presentation/feedback_dialog.dart',
    ).readAsStringSync();

    expect(design, contains('class BusyMarkPopupSelector<T>'));
    expect(design, contains('class BusyMarkStatusBox'));
    expect(settings, contains('BusyMarkPopupSelector<String>('));
    expect(feedback, contains('BusyMarkPopupSelector<FeedbackCategory>('));
    expect(
      RegExp(r'BusyMarkFloatingTextEntry\(').allMatches(feedback).length,
      3,
    );
    expect(feedback, contains('BusyMarkGroupedList('));
    expect(feedback, contains('BusyMarkSwitchRow('));
    expect(feedback, contains('BusyMarkStatusBox('));
    expect(feedback, isNot(contains('DropdownButtonFormField')));
    expect(feedback, isNot(contains('TextField(')));
    expect(feedback, isNot(contains('InputDecoration(')));
    expect(feedback, isNot(contains('InkWell(')));
  });

  test('Writerside project dialog uses floating Adwaita-style entries', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();
    final welcome = File(
      'lib/src/workspace/presentation/welcome_screen.dart',
    ).readAsStringSync();

    expect(design, contains('class BusyMarkFloatingTextEntry'));
    expect(design, contains('class BusyMarkFloatingTextEntryGroup'));
    expect(design, contains('busyMarkSurfaceDecoration('));
    expect(design, contains('elevated: !grouped'));
    expect(design, contains('AnimatedPositionedDirectional('));
    expect(design, contains('AnimatedDefaultTextStyle('));
    expect(design, contains('AnimatedOpacity('));
    expect(design, contains('BusyMarkRadius.headerButton'));
    expect(design, contains('MouseRegion('));
    expect(design, contains('EditableText('));
    expect(design, contains('BusyMarkGlyphs.edit'));
    expect(design, contains('end: BusyMarkSizes.iconButton'));
    expect(design, contains('opacity: focused || !widget.enabled ? 0 : 1'));
    expect(design, contains('final labelColor = widget.enabled'));
    expect(design, contains(': colors.disabledForeground;'));
    expect(design, isNot(contains('final labelColor = focused')));
    expect(design, contains('hint: widget.errorText'));
    expect(design, contains('if (hasError)'));
    expect(design, contains('widget.errorText!'));
    expect(design, contains('final bool enabled;'));
    expect(design, contains('final TextInputType? keyboardType;'));
    expect(design, contains('final int minLines;'));
    expect(design, contains('final int maxLines;'));
    expect(design, contains('BusyMarkSizes.floatingTextAreaHeight'));
    expect(design, contains('readOnly: !widget.enabled'));
    expect(design, isNot(contains('class BusyMarkDialogTextEntry')));
    expect(design, isNot(contains('InputDecoration(')));
    expect(welcome, contains('BusyMarkFloatingTextEntryGroup('));
    expect(
      RegExp(r'BusyMarkFloatingTextEntryGroup\(').allMatches(welcome).length,
      2,
    );
    expect(
      RegExp(
        r'groupPosition: BusyMarkFloatingTextEntryPosition\.first',
      ).allMatches(welcome).length,
      2,
    );
    expect(
      RegExp(
        r'groupPosition: BusyMarkFloatingTextEntryPosition\.last',
      ).allMatches(welcome).length,
      2,
    );
    expect(welcome, contains('BusyMarkFloatingTextEntry('));
    expect(welcome, isNot(contains('BusyMarkDialogTextEntry(')));
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
    expect(workspace, contains('onSecondaryTapDown'));
    expect(
      RegExp(
        r'SingleActivator\(LogicalKeyboardKey\.delete\)',
      ).allMatches(workspace).length,
      greaterThanOrEqualTo(2),
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
    expect(workspace, contains('headingId: heading.id'));
    expect(workspace, contains('line: heading.span.startLine'));
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
    expect(toolbar, contains('BusyMarkHeaderIconButton('));
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
    expect(workspace, contains('padding: BusyMarkInsets.previewPane'));
    expect(workspace, contains('first: index == 0'));
    expect(
      workspace,
      contains('top: first ? 0 : BusyMarkSizes.previewHeadingTop'),
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
