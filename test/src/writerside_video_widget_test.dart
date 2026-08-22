import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/editor/writerside_video_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('video card launches a supported remote source', (tester) async {
    Uri? launched;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkWritersideVideoView(
            source: 'https://youtu.be/BeJu9bMPLGU',
            previewSource: null,
            activeFilePath: '/workspace/topics/video.md',
            workspaceRoot: '/workspace/topics',
            writersideRoot: '/workspace',
            imagesDir: 'images',
            allowRemoteImages: false,
            launcher: (uri) async {
              launched = uri;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.text('YouTube'), findsOneWidget);
    expect(find.byIcon(BusyMarkGlyphs.play), findsOneWidget);
    await tester.tap(find.byType(BusyMarkWritersideVideoView));
    await tester.pump();
    expect(launched, Uri.parse('https://youtu.be/BeJu9bMPLGU'));
  });

  testWidgets('mini-player card hides the source label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkWritersideVideoView(
            source: 'https://vimeo.com/76979871',
            previewSource: null,
            activeFilePath: '/workspace/topics/video.md',
            workspaceRoot: '/workspace/topics',
            writersideRoot: '/workspace',
            imagesDir: 'images',
            allowRemoteImages: false,
            miniPlayer: true,
            launcher: (_) async => true,
          ),
        ),
      ),
    );

    expect(find.text('Vimeo'), findsNothing);
    expect(find.byIcon(BusyMarkGlyphs.play), findsOneWidget);
  });

  testWidgets('WYSIWYG renders a Writerside video without rewriting source', (
    tester,
  ) async {
    const source = '''# Video

<video src="https://youtu.be/BeJu9bMPLGU" width="640"/>
''';
    final document = const MarkdownParser()
        .parse(
          filePath: 'topic.md',
          source: source,
          mode: MarkdownMode.writersideMarkdown,
          validateLocalReferences: false,
        )
        .busyDocument;
    var emitted = source;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: BusyMarkWysiwygEditor(
              document: document,
              onSourceChanged: (_, value) => emitted = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BusyMarkWritersideVideoView), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(emitted, source);
  });
}
