import 'dart:io';

import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_video.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const parser = MarkdownParser();

  test('Writerside Markdown models video and preserves its exact source', () {
    const source = '''# Video

<video src="sample.mp4" preview-src="poster.png" width="640" height="360" mini-player="true" border-effect="rounded"/>

After.
''';

    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final video = parsed.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.video,
    );

    expect(video.attributes, containsPair('src', 'sample.mp4'));
    expect(video.attributes, containsPair('preview-src', 'poster.png'));
    expect(video.attributes, containsPair('width', '640'));
    expect(video.attributes, containsPair('height', '360'));
    expect(video.attributes, containsPair('mini-player', 'true'));
    expect(video.attributes, containsPair('border-effect', 'rounded'));
    expect(video.preserveRaw, isTrue);
    expect(video.sourceSpan?.startLine, 3);
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );

    final preview = const MarkdownPreviewBuilder().build(parsed);
    final previewVideo = preview.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.video,
    );
    expect(previewVideo.text, 'sample.mp4');
    expect(previewVideo.attributes['preview-src'], 'poster.png');
  });

  test('video remains blocked raw HTML outside Writerside Markdown', () {
    const source = '<video src="sample.mp4"/>\n';
    final parsed = parser.parse(
      filePath: 'README.md',
      source: source,
      validateLocalReferences: false,
    );

    expect(
      parsed.busyDocument.blocks.where(
        (block) => block.kind == BusyBlockKind.video,
      ),
      isEmpty,
    );
    expect(
      parsed.diagnostics.map((diagnostic) => diagnostic.code),
      contains('markdown.raw-html.unsafe'),
    );
  });

  test('multiline Writerside video attributes remain one semantic block', () {
    const source = '''# Video

<video src="sample.mp4"
       preview-src="sample.png"
       width="640"
       height="360"/>

After.
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final video = parsed.busyDocument.blocks.singleWhere(
      (block) => block.kind == BusyBlockKind.video,
    );

    expect(video.attributes['src'], 'sample.mp4');
    expect(video.attributes['preview-src'], 'sample.png');
    expect(video.sourceSpan?.startLine, 3);
    expect(video.sourceSpan?.endLine, 6);
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test('video markup inside an ordinary code fence is not interpreted', () {
    const source = '''# Example

```xml
<video src="sample.mp4"/>
```
''';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );

    expect(
      parsed.busyDocument.blocks.where(
        (block) => block.kind == BusyBlockKind.video,
      ),
      isEmpty,
    );
    expect(
      parsed.busyDocument.blocks
          .singleWhere((block) => block.kind == BusyBlockKind.codeBlock)
          .plainText,
      contains('<video'),
    );
  });

  test('Writerside topic parser exposes video attributes', () {
    const source = '''<topic id="sample" title="Sample">
  <video src="https://youtu.be/BeJu9bMPLGU" width="720" mini-player="true" border-effect="line"/>
</topic>''';
    final topic = const WritersideTopicParser().parseXml(
      filePath: 'sample.topic',
      source: source,
    );

    expect(topic.videos, hasLength(1));
    expect(topic.videos.single.source, 'https://youtu.be/BeJu9bMPLGU');
    expect(topic.videos.single.width, '720');
    expect(topic.videos.single.miniPlayer, isTrue);
    expect(topic.videos.single.borderEffect, 'line');
    expect(topic.semanticElementNames, contains('video'));
  });

  test('Writerside .topic preview creates a first-class video block', () async {
    final root = Directory.systemTemp.createTempSync('busymark-video-topic-');
    addTearDown(() => root.deleteSync(recursive: true));
    final topics = Directory(p.join(root.path, 'topics'))..createSync();
    File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp>
  <module name="Video test"/>
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="guide.tree"/>
</ihp>
''');
    File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="video.topic">
  <toc-element topic="video.topic"/>
</instance-profile>
''');
    const source = '''<topic id="video" title="Video">
  <video src="https://vimeo.com/76979871" width="640" height="360" border-effect="rounded"/>
</topic>''';
    final topicPath = p.join(topics.path, 'video.topic');
    File(topicPath).writeAsStringSync(source);

    const service = WorkspaceService();
    final workspace = await service.openPath(root.path);
    final preview = service.buildPreview(
      workspace.copyWith(activeFilePath: topicPath),
      source,
    );
    final video = preview!.blocks.singleWhere(
      (block) => block.kind == PreviewBlockKind.video,
    );

    expect(video.text, 'https://vimeo.com/76979871');
    expect(video.attributes['width'], '640');
    expect(video.attributes['height'], '360');
    expect(video.attributes['border-effect'], 'rounded');
  });

  test('safe video resolver accepts documented hosts and local media', () {
    final root = Directory.systemTemp.createTempSync('busymark-video-');
    addTearDown(() => root.deleteSync(recursive: true));
    final topics = Directory(p.join(root.path, 'topics'))..createSync();
    final images = Directory(p.join(root.path, 'images'))..createSync();
    final topic = File(p.join(topics.path, 'sample.md'))..writeAsStringSync('');
    final video = File(p.join(images.path, 'sample.mp4'))
      ..writeAsBytesSync([0, 0, 0, 0]);

    expect(
      resolveWritersideVideoUri(
        source: 'https://youtu.be/BeJu9bMPLGU',
        activeFilePath: topic.path,
        workspaceRoot: topics.path,
        writersideRoot: root.path,
        imagesDir: 'images',
      )?.host,
      'youtu.be',
    );
    expect(
      resolveWritersideVideoUri(
        source: 'https://vimeo.com/76979871',
        activeFilePath: topic.path,
        workspaceRoot: topics.path,
        writersideRoot: root.path,
        imagesDir: 'images',
      )?.host,
      'vimeo.com',
    );
    expect(
      resolveWritersideVideoUri(
        source: 'sample.mp4',
        activeFilePath: topic.path,
        workspaceRoot: topics.path,
        writersideRoot: root.path,
        imagesDir: 'images',
      )?.toFilePath(),
      video.resolveSymbolicLinksSync(),
    );
    for (final unsafe in [
      'http://youtu.be/BeJu9bMPLGU',
      'https://example.com/sample.mp4',
      'javascript:alert(1)',
      '/tmp/sample.mp4',
      '../outside.mp4',
      'sample.txt',
    ]) {
      expect(
        resolveWritersideVideoUri(
          source: unsafe,
          activeFilePath: topic.path,
          workspaceRoot: topics.path,
          writersideRoot: root.path,
          imagesDir: 'images',
        ),
        isNull,
        reason: unsafe,
      );
    }
  });

  test(
    'Writerside module reports invalid and incomplete video sources',
    () async {
      final root = Directory.systemTemp.createTempSync('busymark-video-diag-');
      addTearDown(() => root.deleteSync(recursive: true));
      final topics = Directory(p.join(root.path, 'topics'))..createSync();
      final images = Directory(p.join(root.path, 'images'))..createSync();
      File(p.join(images.path, 'no-poster.mp4')).writeAsBytesSync([0, 0, 0, 0]);
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync('''
<ihp>
  <topics dir="topics"/>
  <images dir="images"/>
  <instance src="guide.tree"/>
</ihp>
''');
      File(p.join(root.path, 'guide.tree')).writeAsStringSync('''
<instance-profile id="guide" name="Guide" start-page="video.md">
  <toc-element topic="video.md"/>
</instance-profile>
''');
      File(p.join(topics.path, 'video.md')).writeAsStringSync('''# Video

<video src="missing.mp4"/>

<video src="no-poster.mp4"/>

<video src="https://example.com/video.mp4"/>
''');

      final module = await const WritersideModuleService().load(root.path);
      final codes = module.diagnostics.map((diagnostic) => diagnostic.code);

      expect(codes, contains('writerside.video.missing-file'));
      expect(codes, contains('writerside.video.missing-preview'));
      expect(codes, contains('writerside.video.unsupported-source'));
    },
  );

  test('local poster defaults to matching PNG and can be overridden', () {
    expect(
      writersideVideoPreviewSource('clips/demo.mp4', null),
      'clips/demo.png',
    );
    expect(
      writersideVideoPreviewSource('clips/demo.mp4', 'covers/demo.webp'),
      'covers/demo.webp',
    );
    expect(
      writersideVideoPreviewSource('https://youtu.be/BeJu9bMPLGU', null),
      isEmpty,
    );
  });

  test('PDF export carries a first-class linked video poster', () {
    const source = '<video src="demo.mp4" preview-src="demo.png"/>\n';
    final parsed = parser.parse(
      filePath: 'topic.md',
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      validateLocalReferences: false,
    );
    final exported = const MarkdownExportMapper().map(parsed.busyDocument);

    expect(exported.blocks.single.kind, MarkdownExportBlockKind.video);
    expect(exported.blocks.single.attributes['source'], 'demo.mp4');
    expect(exported.blocks.single.attributes['preview'], 'demo.png');
    expect(exported.imageDestinations, contains('demo.png'));
  });
}
