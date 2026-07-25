import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/l10n/generated/app_localizations_de.dart';
import 'package:busymark/l10n/generated/app_localizations_en.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/source/source_editor.dart';
import 'package:busymark/src/editor/source/source_search.dart';
import 'package:busymark/src/editor/source_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  testWidgets('source editor remains LTR inside an Arabic interface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
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
              text: '# مقدمة\npath: docs/مقدمة-v2.md\n',
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
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester
          .widgetList<Row>(find.byType(Row))
          .any((row) => row.textDirection == TextDirection.ltr),
      isTrue,
    );
  });

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

  testWidgets('source search localizes an invalid regular expression', (
    tester,
  ) async {
    final de = AppLocalizationsDe();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: 'Text',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: true,
              searchOptions: const SourceSearchOptions(query: '[', regex: true),
              onSearchOptionsChanged: (_) {},
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(de.sourceSearchInvalidRegex), findsOneWidget);
  });

  testWidgets('source fold and search options use semantic icon buttons', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    SourceSearchOptions? updatedOptions;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: BusyMarkLinuxPalette.blueAccent,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkSourceEditor(
              text: '# Intro\nBody\n',
              language: SourceSyntaxLanguage.markdown,
              filePath: '/project/topic.md',
              diagnostics: const [],
              editorFontSize: 14,
              wordWrap: true,
              searchActive: true,
              searchOptions: const SourceSearchOptions(caseSensitive: true),
              onSearchOptionsChanged: (options) => updatedOptions = options,
              onChanged: (_, _) {},
              onOpenSearch: () {},
              onCloseSearch: () {},
            ),
          ),
        ),
      ),
    );

    final foldTooltip = find.byTooltip(en.collapseKind(en.foldKindSection));
    final foldButton = find.ancestor(
      of: foldTooltip,
      matching: find.byType(BusyMarkCompactIconButton),
    );
    expect(foldTooltip, findsOneWidget);
    expect(foldButton, findsOneWidget);

    final caseButton = find.ancestor(
      of: find.byTooltip(en.sourceSearchCaseSensitive),
      matching: find.byType(YaruIconButton),
    );
    final wholeWordButton = find.ancestor(
      of: find.byTooltip(en.sourceSearchWholeWord),
      matching: find.byType(YaruIconButton),
    );
    expect(tester.widget<YaruIconButton>(caseButton).isSelected, isTrue);
    expect(tester.widget<YaruIconButton>(wholeWordButton).isSelected, isFalse);

    await tester.tap(wholeWordButton);
    await tester.pump();
    expect(updatedOptions?.caseSensitive, isTrue);
    expect(updatedOptions?.wholeWord, isTrue);

    await tester.tap(foldButton);
    await tester.pump();
    expect(find.byTooltip(en.expandKind(en.foldKindSection)), findsOneWidget);
  });
}
