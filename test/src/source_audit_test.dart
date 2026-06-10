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

  test('grouped action rows use one BusyMark-owned rounded surface', () {
    final design = File('lib/src/app/busymark_design.dart').readAsStringSync();

    expect(design, contains('class _BusyMarkGroupedListSurface'));
    expect(design, contains('shape: RoundedRectangleBorder'));
    expect(design, contains('clipBehavior: Clip.antiAlias'));
    expect(design, contains('Divider(height: 1'));
    expect(design, isNot(contains('YaruTileList')));
    expect(design, isNot(contains('YaruBorderContainer')));
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
      expect(workspace, contains('class _ProblemsList'));
      expect(workspace, isNot(contains('_ProblemsPanel')));
      expect(workspace, isNot(contains('problemsVisible')));
      expect(settings, isNot(contains('problemsVisible')));
      expect(settings, isNot(contains('setProblemsVisible')));
      expect(settingsScreen, isNot(contains('Show problems panel')));
    },
  );

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
    expect(workspace, contains('if (tabs.length > 1)'));
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
    expect(workspace, contains('_isOpenableMarkdownFile(file)'));
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
    expect(workspace, contains('TextPainter'));
    expect(workspace, contains('getOffsetForCaret'));
    expect(workspace, contains('_sourceScrollOffsetForTextOffset'));
    expect(workspace, contains('_jumpSourceScrollToTextOffset'));
    expect(workspace, contains('scrollController: _sourceScrollController'));
    expect(workspace, contains('Scrollable.ensureVisible'));
    expect(workspace, contains('headingKeys: _previewHeadingKeys'));
    expect(workspace, contains("block.attributes['id']"));
  });

  test('document view modes drive source preview and split layouts', () {
    final settings = File('lib/src/app/app_settings.dart').readAsStringSync();
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();

    expect(
      settings,
      contains('enum DocumentViewModePreference { source, preview, split }'),
    );
    expect(
      settings,
      contains('documentViewMode: DocumentViewModePreference.split'),
    );
    expect(settings, contains('Future<void> setDocumentViewMode'));
    expect(
      workspace,
      contains(
        'final sourceVisible = widget.viewMode != DocumentViewModePreference.preview',
      ),
    );
    expect(
      workspace,
      contains(
        'final previewVisible = widget.viewMode != DocumentViewModePreference.source',
      ),
    );
    expect(workspace, contains('if (sourceVisible && previewVisible)'));
    expect(workspace, contains('if (previewVisible)'));
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
