import 'package:busymark/src/app/keyboard_shortcut_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scaled shortcut badges wrap between complete modifier names', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: const Center(
            child: SizedBox(
              width: 120,
              child: BusyMarkKeyboardShortcutBadge('Ctrl+Shift+P'),
            ),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.semanticsLabel, 'Ctrl+Shift+P');
    expect(text.data!.replaceAll('\u200B', ''), 'Ctrl+Shift+P');
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final start = text.data!.indexOf('Shift');
    expect(
      paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + 'Shift'.length),
      ),
      hasLength(1),
      reason: 'The modifier must stay together even when the badge wraps.',
    );
    expect(tester.takeException(), isNull);
  });
}
