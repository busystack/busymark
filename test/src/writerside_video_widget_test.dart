import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/editor/writerside_video_player_host.dart';
import 'package:busymark/src/editor/writerside_video_view.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets('video card embeds a supported YouTube source in place', (
    tester,
  ) async {
    final host = _FakeVideoPlayerHost();
    WritersideVideoPlaybackSource? posterRequest;
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
            playerHost: host,
            hostedPosterLoader: (source) async {
              posterRequest = source;
              return 'https://i.ytimg.com/vi/${source.value}/hqdefault.jpg';
            },
          ),
        ),
      ),
    );

    expect(find.text('YouTube'), findsOneWidget);
    expect(find.byIcon(BusyMarkGlyphs.play), findsOneWidget);
    await tester.pump();
    expect(posterRequest?.kind, WritersideVideoPlaybackKind.youtube);
    final poster = tester.widget<Image>(find.byType(Image));
    expect(
      (poster.image as NetworkImage).url,
      'https://i.ytimg.com/vi/BeJu9bMPLGU/hqdefault.jpg',
    );
    await tester.tap(find.byType(BusyMarkWritersideVideoView));
    await tester.pump();
    await tester.pump();

    expect(host.shown, hasLength(1));
    expect(host.shown.single.source.kind, WritersideVideoPlaybackKind.youtube);
    expect(host.shown.single.source.value, 'BeJu9bMPLGU');
    expect(host.shown.single.miniPlayer, isFalse);
    expect(host.shown.single.rect.size, const Size(700, 393.75));
    expect(find.text('YouTube'), findsNothing);
    expect(find.byIcon(BusyMarkGlyphs.play), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(host.hidden, contains(host.shown.single.playerId));
  });

  testWidgets('mini-player embeds Vimeo with the reduced video ID', (
    tester,
  ) async {
    final host = _FakeVideoPlayerHost();
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
            playerHost: host,
            hostedPosterLoader: (_) async => null,
          ),
        ),
      ),
    );

    expect(find.text('Vimeo'), findsNothing);
    expect(find.byIcon(BusyMarkGlyphs.play), findsOneWidget);
    await tester.tap(find.byType(BusyMarkWritersideVideoView));
    await tester.pump();
    await tester.pump();

    expect(host.shown.single.source.kind, WritersideVideoPlaybackKind.vimeo);
    expect(host.shown.single.source.value, '76979871');
    expect(host.shown.single.miniPlayer, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('local video player receives only a canonical media path', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('busymark-video-widget-');
    addTearDown(() => root.deleteSync(recursive: true));
    final topics = Directory(p.join(root.path, 'topics'))..createSync();
    final images = Directory(p.join(root.path, 'images'))..createSync();
    final topicPath = p.join(topics.path, 'video.md');
    File(topicPath).writeAsStringSync('');
    final video = File(p.join(images.path, 'demo.mp4'))
      ..writeAsBytesSync([0, 0, 0, 0]);
    final host = _FakeVideoPlayerHost();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BusyMarkWritersideVideoView(
            source: 'demo.mp4',
            previewSource: null,
            activeFilePath: topicPath,
            workspaceRoot: topics.path,
            writersideRoot: root.path,
            imagesDir: 'images',
            allowRemoteImages: false,
            playerHost: host,
            width: 640,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BusyMarkWritersideVideoView));
    await tester.pump();
    await tester.pump();

    expect(
      host.shown.single.source.kind,
      WritersideVideoPlaybackKind.localFile,
    );
    expect(host.shown.single.source.value, video.resolveSymbolicLinksSync());
    expect(host.shown.single.rect.size, const Size(640, 360));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('video dimensions preserve ratio and scale to available width', (
    tester,
  ) async {
    Future<Size> render({double? width, double? height}) async {
      final host = _FakeVideoPlayerHost();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: BusyMarkWritersideVideoView(
                key: ValueKey('video-$width-$height'),
                source: 'https://youtu.be/BeJu9bMPLGU',
                previewSource: null,
                activeFilePath: '/workspace/topics/video.md',
                workspaceRoot: '/workspace/topics',
                writersideRoot: '/workspace',
                imagesDir: 'images',
                allowRemoteImages: false,
                playerHost: host,
                width: width,
                height: height,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(BusyMarkGlyphs.play));
      await tester.pump();
      await tester.pump();
      return host.shown.single.rect.size;
    }

    expect(await render(width: 320), const Size(320, 180));
    expect(await render(height: 180), const Size(320, 180));
    expect(await render(width: 640, height: 400), const Size(500, 312.5));
  });

  testWidgets('failed native player leaves a usable poster fallback', (
    tester,
  ) async {
    final host = _FakeVideoPlayerHost()..showResult = false;
    var failures = 0;
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
            playerHost: host,
            onOpenFailed: () => failures += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BusyMarkWritersideVideoView));
    await tester.pump();
    await tester.pump();

    expect(failures, 1);
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

class _FakeVideoPlayerHost implements WritersideVideoPlayerHost {
  final shown = <WritersideVideoPlayerRequest>[];
  final updates = <Rect>[];
  final hidden = <String>[];
  bool showResult = true;
  bool updateResult = true;

  @override
  Future<void> hide(String playerId) async {
    hidden.add(playerId);
  }

  @override
  Future<bool> show(WritersideVideoPlayerRequest request) async {
    shown.add(request);
    return showResult;
  }

  @override
  Future<bool> update(String playerId, Rect rect) async {
    updates.add(rect);
    return updateResult;
  }
}
