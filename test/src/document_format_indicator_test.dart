import 'package:busymark/src/app/localization.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/workspace/presentation/document_format_indicator.dart';
import 'package:busymark/src/workspace/text_format_metadata.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows only a compact line-ending label', (tester) async {
    await _pumpIndicator(
      tester,
      const TextFormatMetadata(
        hasUtf8Bom: false,
        lineEnding: DocumentLineEnding.lf,
        hasFinalNewline: true,
        lfCount: 2,
      ),
    );

    expect(find.text('LF'), findsOneWidget);
    expect(find.textContaining('UTF-8'), findsNothing);
    expect(find.textContaining('Final newline'), findsNothing);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      'UTF-8 · LF · Final newline',
    );
    final size = tester.getSize(find.byType(BusyMarkDocumentFormatIndicator));
    expect(size.width, lessThan(80));
    expect(size.height, lessThan(32));
  });

  testWidgets('makes BOM visible and keeps final-newline detail compact', (
    tester,
  ) async {
    await _pumpIndicator(
      tester,
      const TextFormatMetadata(
        hasUtf8Bom: true,
        lineEnding: DocumentLineEnding.crlf,
        hasFinalNewline: false,
        crlfCount: 2,
      ),
    );

    expect(find.text('BOM · CRLF'), findsOneWidget);
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      'UTF-8 BOM · CRLF · No final newline',
    );
  });

  testWidgets('uses a compact technical label for mixed line endings', (
    tester,
  ) async {
    await _pumpIndicator(
      tester,
      const TextFormatMetadata(
        hasUtf8Bom: false,
        lineEnding: DocumentLineEnding.mixed,
        hasFinalNewline: true,
        lfCount: 1,
        crlfCount: 1,
      ),
    );

    expect(find.text('LF/CRLF'), findsOneWidget);
  });
}

Future<void> _pumpIndicator(WidgetTester tester, TextFormatMetadata format) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: busyMarkLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildBusyMarkTheme(
        brightness: Brightness.dark,
        accentColor: BusyMarkLinuxPalette.blueAccent,
      ),
      home: Scaffold(
        body: Center(child: BusyMarkDocumentFormatIndicator(format: format)),
      ),
    ),
  );
}
