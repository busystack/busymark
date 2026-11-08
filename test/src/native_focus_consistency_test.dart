import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('pointer focus is retained without an accent ring $brightness', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBusyMarkTheme(
            brightness: brightness,
            accentColor: const Color(0xffb34cb4),
          ),
          home: Scaffold(
            body: BusyMarkSidebarRecordRow<void>(
              icon: BusyMarkGlyphs.folder,
              title: 'Recent workspace',
              subtitle: '/long/path',
              selected: true,
              focusNode: node,
              onTap: () {},
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(tester.getCenter(find.text('Recent workspace')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      final decorations = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final borders = decorations
          .map((w) => w.foregroundDecoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>();
      expect(
        borders.every((b) => b.top.color.a == 0),
        isTrue,
        reason:
            'Pointer selection retains input focus without a keyboard focus ring',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final keyboard = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((w) => w.foregroundDecoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>();
      expect(
        keyboard.any((b) => b.top.color.a > 0 && b.top.color.a < 1),
        isTrue,
        reason: 'Keyboard interaction must reveal a restrained focus indicator',
      );
    });
    testWidgets('input focus uses semantic translucent border $brightness', (
      tester,
    ) async {
      final theme = buildBusyMarkTheme(
        brightness: brightness,
        accentColor: const Color(0xffb34cb4),
      );
      final border = theme.inputDecorationTheme.focusedBorder!;
      expect(border.borderSide.color.a, lessThan(1));
      expect(border.borderSide.width, 2);
      expect(theme.colorScheme.primary, const Color(0xffb34cb4));
    });
  }
}
