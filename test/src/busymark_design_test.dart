import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'popup menu rows show shortcuts without redundant hover tooltips',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BusyMarkHeaderIconButton(
                  tooltip: 'Main menu',
                  icon: BusyMarkGlyphs.menuVertical,
                  onPressed: () {},
                ),
                const BusyMarkPopupMenuItem<String>(
                  value: 'editor',
                  label: 'Editor',
                  shortcut: 'Ctrl+1',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Ctrl+1'), findsOneWidget);
      expect(find.byTooltip('Editor (Ctrl+1)'), findsNothing);
      expect(find.byTooltip('Main menu'), findsOneWidget);
    },
  );
}
