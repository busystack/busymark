import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('source editor shows large-file fallback status', (tester) async {
    final source = 'a' * 300001;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Large file: highlighting and folding are paused'),
      findsOneWidget,
    );
  });

  testWidgets('source editor renders visible diagnostic gutter tooltip', (
    tester,
  ) async {
    const filePath = '/project/topic.md';
    const source = '# Intro\nBody\n';
    final diagnostic = Diagnostic(
      code: 'markdown.heading.duplicate-id',
      severity: DiagnosticSeverity.warning,
      filePath: filePath,
      args: const {'id': 'intro'},
      sourceSpan: SourceSpan.fromOffsets(
        filePath: filePath,
        source: source,
        startOffset: 0,
        endOffset: 7,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.dark,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: source,
              language: SourceSyntaxLanguage.markdown,
              filePath: filePath,
              diagnostics: [diagnostic],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: false,
              searchOptions: const SourceSearchOptions(),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Duplicate heading ID "intro".'), findsOneWidget);
  });
}
