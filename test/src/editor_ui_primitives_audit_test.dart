import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source editor overlays use shared semantic surfaces', () {
    final source = File(
      'lib/src/editor/source/source_editor.dart',
    ).readAsStringSync();
    final searchPanel = RegExp(
      r'class _SourceSearchPanel[\s\S]*?class _SearchPanelIconButton',
    ).firstMatch(source)!.group(0)!;
    final searchButtons = RegExp(
      r'class _SearchPanelIconButton[\s\S]*?class _SourceLargeFileBanner',
    ).firstMatch(source)!.group(0)!;
    final largeFileBanner = RegExp(
      r'class _SourceLargeFileBanner[\s\S]*?'
      r'class _SourceEditorShortcutIntent',
    ).firstMatch(source)!.group(0)!;

    expect(searchPanel, contains('return BusyMarkSurface('));
    expect(searchPanel, contains('color: colors.panel'));
    expect(searchPanel, isNot(contains('DecoratedBox(')));
    expect(searchPanel, isNot(contains('Border.all(')));
    expect(searchPanel, isNot(contains('elevation:')));
    expect(RegExp(r'YaruIconButton\(').allMatches(searchButtons).length, 2);
    expect(searchButtons, contains('iconSize: 28'));
    expect(searchButtons, contains('isSelected: selected'));
    expect(searchButtons, isNot(contains('WidgetStateProperty.resolveWith')));
    expect(searchButtons, isNot(contains('backgroundColor:')));
    expect(searchButtons, isNot(contains('fixedSize:')));
    expect(largeFileBanner, contains('return ConstrainedBox('));
    expect(largeFileBanner, contains('child: BusyMarkStatusBox('));
    expect(largeFileBanner, contains('maxWidth: BusyMarkSizes.dialogCompact'));
    expect(largeFileBanner, isNot(contains('Material(')));
    expect(largeFileBanner, isNot(contains('DecoratedBox(')));
  });

  test('WYSIWYG content actions and table menus use shared controls', () {
    final widgets = File(
      'lib/src/editor/wysiwyg/wysiwyg_block_widgets.dart',
    ).readAsStringSync();
    final htmlBlock = RegExp(
      r'class _RenderedHtmlBlock[\s\S]*?class _RenderedHtmlBlocks',
    ).firstMatch(widgets)!.group(0)!;
    final tableEditor = RegExp(
      r'class _TableBlockEditor[\s\S]*?class _TableCornerCell',
    ).firstMatch(widgets)!.group(0)!;
    final tableMenu = RegExp(
      r'class _TableControlMenuButton[\s\S]*?class _TableCellEditor',
    ).firstMatch(widgets)!.group(0)!;

    expect(htmlBlock, contains('BusyMarkHeaderIconButton('));
    expect(htmlBlock, isNot(matches(RegExp(r'(?<![A-Za-z])IconButton\('))));
    expect(tableEditor, contains('BusyMarkHeaderIconButton('));
    expect(tableMenu, contains('BusyMarkHeaderPopupMenuButton'));
    expect(RegExp(r'BusyMarkPopupMenuItem\(').allMatches(tableMenu).length, 3);
    expect(tableMenu, isNot(matches(RegExp(r'(?<![A-Za-z])PopupMenuItem\('))));
  });

  test('problems dialog delegates its list surface to shared grouping', () {
    final workspace = File(
      'lib/src/workspace/presentation/workspace_screen.dart',
    ).readAsStringSync();
    final problemsList = RegExp(
      r'class _ProblemsList[\s\S]*?class _SearchSidebar',
    ).firstMatch(workspace)!.group(0)!;

    expect(problemsList, contains('return BusyMarkGroupedSurface('));
    expect(problemsList, isNot(contains('DecoratedBox(')));
    expect(problemsList, isNot(contains('Border.all(')));
    expect(problemsList, isNot(contains('ClipRRect(')));
  });
}
