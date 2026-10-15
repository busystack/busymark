import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_block_widgets.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

BusyDocument parse(String text) => const MarkdownParser()
    .parse(
      filePath: 'hover.md',
      source: text,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    )
    .busyDocument;
Widget app(Widget editor, {TextDirection direction = TextDirection.ltr}) =>
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: editor),
        ),
      ),
    );
Iterable<BusyBlock> walk(List<BusyBlock> blocks) sync* {
  for (final b in blocks) {
    yield b;
    yield* walk(b.children);
  }
}

void main() {
  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      'one reachable margin control inspects B independently of A ($direction)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const source =
            '# Topic\n\nCaret A\n\n## Heading B\n\nParagraph B\n\n```text\nCode B\n```\n\n![Image B](missing.png)\n\n- Item B\n  - Nested B\n';
        final document = parse(source);
        final explicit = <String?>[];
        var opened = 0;
        final changes = <String>[];
        await tester.pumpWidget(
          app(
            BusyMarkWysiwygEditor(
              document: document,
              documentId: 'd',
              contentRevision: 0,
              onSourceChanged: (_, s) => changes.add(s),
              onPropertiesRequested: () => opened++,
              onInspectElement:
                  (
                    _,
                    id,
                    inline,
                    requested,
                    multiple, {
                    bool revisionRefresh = false,
                  }) {
                    if (requested) {
                      explicit.add(id);
                      expect(inline, isNull);
                      expect(multiple, isFalse);
                    }
                  },
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('wysiwyg-writerside-properties')),
          findsNothing,
        );
        final caret = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'Caret A',
        );
        await tester.tap(caret);
        await tester.pumpAndSettle();
        final field = tester.widget<TextField>(caret);
        field.controller!.selection = const TextSelection.collapsed(offset: 3);
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(1, 1));
        for (final text in [
          'Heading B',
          'Paragraph B',
          'Code B',
          'Image B',
          'Item B',
          'Nested B',
        ]) {
          final block = walk(
            document.blocks,
          ).singleWhere((b) => b.plainText == text);
          final target = find.byWidgetPredicate(
            (w) => w is BusyMarkWysiwygBlockField && w.block.id == block.id,
          );
          final before = tester.getRect(target);
          await mouse.moveTo(before.center);
          await tester.pumpAndSettle();
          final icon = find.byWidgetPredicate(
            (w) =>
                w is BusyMarkHeaderIconButton &&
                w.tooltip == 'Element Properties',
          );
          expect(icon, findsOneWidget, reason: text);
          expect(
            tester.getRect(target),
            before,
            reason: 'Hover must not move $text',
          );
          expect(explicit.length, opened);
          final region = tester.getRect(icon);
          expect(
            region.overlaps(before),
            isFalse,
            reason: 'Properties must not cover $text',
          );
          await mouse.moveTo(region.center);
          await tester.pumpAndSettle();
          expect(
            icon,
            findsOneWidget,
            reason: 'The margin remains reachable for $text',
          );
          await mouse.down(region.center);
          await mouse.up();
          await tester.pumpAndSettle();
          expect(explicit.last, block.id);
          expect(
            field.controller!.selection,
            const TextSelection.collapsed(offset: 3),
          );
          expect(changes, isEmpty);
          expect(opened, explicit.length);
        }
        await mouse.removePointer();
      },
    );
  }
  testWidgets(
    'a captured margin action rejects a replacement after revision change',
    (tester) async {
      var document = parse('# Topic\n\nCaret A\n\n## Heading B\n');
      var revision = 0;
      var opened = 0;
      final explicit = <String?>[];
      Widget host() => app(
        BusyMarkWysiwygEditor(
          document: document,
          documentId: 'd',
          contentRevision: revision,
          onSourceChanged: (_, _) => fail('Inspection cannot edit source'),
          onPropertiesRequested: () => opened++,
          onInspectElement:
              (_, id, _, requested, _, {bool revisionRefresh = false}) {
                if (requested) explicit.add(id);
              },
        ),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      final heading = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Heading B',
      );
      await mouse.moveTo(tester.getCenter(heading));
      await tester.pumpAndSettle();
      final oldAction = tester
          .widget<BusyMarkHeaderIconButton>(
            find.byWidgetPredicate(
              (w) =>
                  w is BusyMarkHeaderIconButton &&
                  w.tooltip == 'Element Properties',
            ),
          )
          .onPressed!;
      document = parse('# Topic\n\nCaret A\n\n## Replacement\n');
      revision++;
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      oldAction();
      await tester.pumpAndSettle();
      expect(explicit, isEmpty);
      expect(opened, 0);
      await mouse.removePointer();
    },
  );
}
