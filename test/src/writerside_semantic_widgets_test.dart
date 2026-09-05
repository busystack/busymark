import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/writerside/writerside_tabs_view.dart';
import 'package:busymark/src/writerside/writerside_table_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PreviewBlock tabs(String suffix) => PreviewBlock(
    kind: PreviewBlockKind.tabs,
    text: '',
    attributes: const {'group': 'os'},
    children: [
      for (final label in ['Linux', 'Windows'])
        PreviewBlock(
          kind: PreviewBlockKind.tabs,
          text: '$label $suffix',
          attributes: {'group-key': label},
          children: [
            PreviewBlock(
              kind: PreviewBlockKind.paragraph,
              text: '$label body $suffix',
            ),
          ],
        ),
    ],
  );
  Widget panel(List<PreviewBlock> blocks) =>
      Column(children: [for (final block in blocks) Text(block.text)]);
  testWidgets('tabs synchronize and support arrow, Home and End keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WritersidePreviewScope(
            child: Column(
              children: [
                WritersideTabsView(block: tabs('A'), panelBuilder: panel),
                WritersideTabsView(block: tabs('B'), panelBuilder: panel),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Linux body A'), findsOneWidget);
    expect(find.text('Windows body A'), findsNothing);
    await tester.tap(find.text('Windows A'));
    await tester.pump();
    expect(find.text('Windows body A'), findsOneWidget);
    expect(find.text('Windows body B'), findsOneWidget);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Windows A'),
    );
    button.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(find.text('Linux body B'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(find.text('Windows body B'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Linux body A'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(button.focusNode!.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('table sorting is numeric and excludes disabled columns', (
    tester,
  ) async {
    final block = PreviewBlock(
      kind: PreviewBlockKind.table,
      text: '',
      attributes: const {'sortable': 'true', 'sticky-header': 'true'},
      children: [
        const PreviewBlock(
          kind: PreviewBlockKind.table,
          text: '',
          attributes: {'header': 'true'},
          children: [
            PreviewBlock(kind: PreviewBlockKind.paragraph, text: 'Score'),
            PreviewBlock(
              kind: PreviewBlockKind.paragraph,
              text: 'Notes',
              attributes: {'sortable': 'false'},
            ),
          ],
        ),
        for (final score in ['10', '2', '1'])
          PreviewBlock(
            kind: PreviewBlockKind.table,
            text: '',
            children: [
              PreviewBlock(kind: PreviewBlockKind.paragraph, text: score),
              PreviewBlock(
                kind: PreviewBlockKind.paragraph,
                text: 'Note $score',
              ),
            ],
          ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WritersideTableView(
              block: block,
              cellBuilder: (cell, header) => Text(cell.text),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Score'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('1')).dy,
      lessThan(tester.getTopLeft(find.text('2')).dy),
    );
    expect(
      tester.getTopLeft(find.text('2')).dy,
      lessThan(tester.getTopLeft(find.text('10')).dy),
    );
    await tester.tap(find.text('Score'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('10')).dy,
      lessThan(tester.getTopLeft(find.text('2')).dy),
    );
    expect(
      find.ancestor(of: find.text('Notes'), matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('table spans preserve geometry and sticky header position', (
    tester,
  ) async {
    final block = PreviewBlock(
      kind: PreviewBlockKind.table,
      text: '',
      attributes: const {'sticky-header': 'true', 'column-width': 'fixed'},
      children: [
        const PreviewBlock(
          kind: PreviewBlockKind.table,
          text: '',
          attributes: {'header': 'true'},
          children: [
            PreviewBlock(
              kind: PreviewBlockKind.paragraph,
              text: 'Wide header',
              attributes: {'colspan': '2'},
            ),
          ],
        ),
        const PreviewBlock(
          kind: PreviewBlockKind.table,
          text: '',
          children: [
            PreviewBlock(
              kind: PreviewBlockKind.paragraph,
              text: 'Tall',
              attributes: {'rowspan': '2'},
            ),
            PreviewBlock(kind: PreviewBlockKind.paragraph, text: 'Right'),
          ],
        ),
        const PreviewBlock(
          kind: PreviewBlockKind.table,
          text: '',
          children: [
            PreviewBlock(kind: PreviewBlockKind.paragraph, text: 'Below right'),
          ],
        ),
        for (var i = 0; i < 25; i++)
          PreviewBlock(
            kind: PreviewBlockKind.table,
            text: '',
            children: [
              PreviewBlock(kind: PreviewBlockKind.paragraph, text: 'Row $i'),
              const PreviewBlock(
                kind: PreviewBlockKind.paragraph,
                text: 'Value',
              ),
            ],
          ),
      ],
    );
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              controller: controller,
              child: WritersideTableView(
                block: block,
                cellBuilder: (cell, header) => Text(cell.text),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Right')).dx,
      tester.getTopLeft(find.text('Below right')).dx,
    );
    controller.jumpTo(160);
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Wide header')).dy,
      inInclusiveRange(0, 20),
    );
    expect(tester.takeException(), isNull);
  });
}
