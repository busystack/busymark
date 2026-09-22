import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/workspace/presentation/document_status_bar.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _lfFormat = TextFormatMetadata(
  hasUtf8Bom: false,
  lineEnding: DocumentLineEnding.lf,
  hasFinalNewline: true,
  lfCount: 1,
);

void main() {
  testWidgets('places interactive spelling at start and format at end', (
    tester,
  ) async {
    var presses = 0;
    await _pumpStatusBar(
      tester,
      spellingLabel: 'English (Canada)',
      onSpellingPressed: () => presses += 1,
    );

    final bar = find.byKey(const ValueKey('document-status-bar'));
    final spelling = find.byKey(
      const ValueKey('document-spelling-language-status'),
    );
    final format = find.text('LF');
    expect(find.text('English (Canada)'), findsOneWidget);
    expect(format, findsOneWidget);
    expect(
      tester.getCenter(spelling).dx,
      lessThan(tester.getCenter(format).dx),
    );
    expect(tester.getSize(bar).height, BusyMarkSizes.documentStatusBarHeight);

    final context = tester.element(bar);
    final colors = BusyMarkSurfaceColors.of(context);
    final decoration = tester.widget<DecoratedBox>(bar).decoration;
    expect(decoration, isA<BoxDecoration>());
    final box = decoration as BoxDecoration;
    expect(box.color, colors.headerbarFlat);
    expect(box.border?.top.color, colors.subtleBorder);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip).first).message,
      'Choose spelling language',
    );

    await tester.tap(spelling);
    expect(presses, 1);
  });

  testWidgets('keeps passive format when spelling is unsupported', (
    tester,
  ) async {
    await _pumpStatusBar(tester, spellingLabel: null);

    expect(find.byKey(const ValueKey('document-status-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('document-spelling-language-status')),
      findsNothing,
    );
    expect(find.text('LF'), findsOneWidget);
  });

  testWidgets('truncates a long one-line language without displacing format', (
    tester,
  ) async {
    await _pumpStatusBar(
      tester,
      width: 220,
      spellingLabel:
          'An intentionally very long localized spelling language name',
      onSpellingPressed: () {},
    );

    final label = tester.widget<Text>(
      find.text('An intentionally very long localized spelling language name'),
    );
    final format = find.text('LF');
    expect(label.maxLines, 1);
    expect(label.softWrap, isFalse);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(format, findsOneWidget);
    expect(
      tester.getTopRight(format).dx,
      lessThanOrEqualTo(
        tester
            .getTopRight(find.byKey(const ValueKey('document-status-bar')))
            .dx,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses directional start and end placement in RTL', (
    tester,
  ) async {
    await _pumpStatusBar(
      tester,
      spellingLabel: 'العربية',
      onSpellingPressed: () {},
      textDirection: TextDirection.rtl,
    );

    final spelling = find.byKey(
      const ValueKey('document-spelling-language-status'),
    );
    final format = find.text('LF');
    expect(
      tester.getCenter(spelling).dx,
      greaterThan(tester.getCenter(format).dx),
    );
  });
}

Future<void> _pumpStatusBar(
  WidgetTester tester, {
  required String? spellingLabel,
  VoidCallback? onSpellingPressed,
  double width = 500,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildBusyMarkTheme(
        brightness: Brightness.dark,
        accentColor: BusyMarkLinuxPalette.blueAccent,
      ),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: BusyMarkDocumentStatusBar(
                format: _lfFormat,
                spellingLabel: spellingLabel,
                spellingTooltip: spellingLabel == null
                    ? null
                    : 'Choose spelling language',
                onSpellingPressed: onSpellingPressed,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
