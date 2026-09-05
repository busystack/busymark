import 'dart:io';
import 'dart:convert';
import 'package:busymark/src/core/atomic_file_writer.dart';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_publisher.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('html-publication-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  Future<void> put(String name, String source) async {
    final f = File(p.join(root.path, name));
    await f.parent.create(recursive: true);
    await f.writeAsString(source);
  }

  Future<void> module(String dir, String name, String tree) async {
    await put(
      '$dir/writerside.cfg',
      '<ihp version="2.0"><module name="$name"/><topics dir="topics"/><images dir="images"/><vars src="v.list"/><instance src="guide.tree"/></ihp>',
    );
    await put('$dir/guide.tree', tree);
    await put(
      '$dir/v.list',
      '<vars><var name="product" value="BusyMark" instance="guide"/><var name="product" value="Other" instance="other"/></vars>',
    );
  }

  Future<HtmlExportResult> site({
    String dir = 'module',
    String output = 'site',
    bool overwrite = false,
  }) => const HtmlExportService().exportWriterside(
    projectRoot: root.path,
    moduleRoot: p.join(root.path, dir),
    instanceId: 'guide',
    destinationPath: p.join(root.path, output),
    overwrite: overwrite,
  );
  test(
    'Writerside module origins preserve includes, variables, file identity and nullable links',
    () async {
      await module(
        'main',
        'main',
        '<instance-profile id="guide" name="Guide" start-page="Start.topic"><toc-element topic="Start.topic"/><toc-element topic="Shared.topic" origin="shared"/></instance-profile>',
      );
      await module(
        'shared',
        'shared',
        '<instance-profile id="lib" name="Library" is-library="true"><toc-element topic="Shared.topic"/></instance-profile>',
      );
      await put(
        'main/topics/Start.topic',
        '<topic id="Start" title="%product%"><p instance="guide">Selected content</p><p instance="other">Excluded content</p><include origin="shared" from="Shared.topic" element-id="piece"><var name="label" value="Caller"/></include><img src="logo.svg"/><a origin="shared" href="Shared.topic" anchor="same"/><a href="Absent.topic" nullable="true">Optional</a><a href="Absent.topic">Required</a></topic>',
      );
      await put(
        'shared/topics/Shared.topic',
        '<topic id="Shared" title="Shared"><snippet id="piece"><var name="label" value="Default"/><p>%label%</p><img src="logo.svg"/></snippet><chapter id="same" title="Shared section"><p>Text</p></chapter></topic>',
      );
      await put(
        'main/images/logo.svg',
        '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="red"/></svg>',
      );
      await put(
        'shared/images/logo.svg',
        '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="blue"/></svg>',
      );
      final result = await site(dir: 'main');
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelector('h1')!.text, 'BusyMark');
      expect(doc.body!.text, contains('Caller'));
      expect(doc.body!.text, isNot(contains('Excluded content')));
      final images = doc.querySelectorAll('img');
      expect(images.length, 2);
      expect(images[0].attributes['src'], isNot(images[1].attributes['src']));
      expect(
        doc.querySelector('a[href="shared.html#same"]')!.text,
        'Shared section',
      );
      expect(
        doc.querySelectorAll('a').where((a) => a.text == 'Optional'),
        isEmpty,
      );
      expect(doc.body!.text, contains('Optional'));
      expect(
        result.warnings.any((w) => w.code == 'writerside.link.unavailable'),
        isTrue,
      );
      expect(
        doc.querySelectorAll('a').where((a) => a.text == 'Required'),
        isEmpty,
      );
      expect(
        result.warnings.any((w) => w.code == 'writerside.variable.unresolved'),
        isFalse,
      );
    },
  );
  test('definition lists preserve individual disclosure states and IDs', () async {
    await module(
      'module',
      'docs',
      '<instance-profile id="guide" name="Guide" start-page="Start.topic"><toc-element topic="Start.topic"/></instance-profile>',
    );
    await put(
      'module/topics/Start.topic',
      '<topic id="Start" title="Definitions"><deflist collapsible="true"><def title="First term" id="first"><p>First definition</p></def><def title="Second term" id="second" default-state="expanded"><p>Second definition</p></def></deflist><a anchor="first">Term</a></topic>',
    );
    final result = await site();
    final doc = html.parse(await File(result.entryPointPath).readAsString());
    expect(result.warnings, isEmpty);
    expect(doc.querySelectorAll('dl dt').map((e) => e.text), [
      'First term',
      'Second term',
    ]);
    expect(
      doc.querySelector('dd#first details')!.attributes.containsKey('open'),
      isFalse,
    );
    expect(
      doc.querySelector('dd#second details')!.attributes.containsKey('open'),
      isTrue,
    );
    expect(doc.querySelector('details dl'), isNull);
  });
  test(
    'web filename and index collisions identify both topics before publication',
    () async {
      await module(
        'module',
        'docs',
        '<instance-profile id="guide" name="Guide" start-page="Guide_A.topic"><toc-element topic="Guide_A.topic"/><toc-element topic="Guide-A.topic"/></instance-profile>',
      );
      await put(
        'module/topics/Guide_A.topic',
        '<topic id="Guide_A" title="A"><p>One</p></topic>',
      );
      await put(
        'module/topics/Guide-A.topic',
        '<topic id="Guide-A" title="B"><p>Two</p></topic>',
      );
      await expectLater(
        site(),
        throwsA(
          isA<HtmlExportException>().having(
            (e) => e.message,
            'conflicts',
            allOf(contains('Guide_A.topic'), contains('Guide-A.topic')),
          ),
        ),
      );
      expect(await Directory(p.join(root.path, 'site')).exists(), isFalse);
      await put(
        'module/topics/Guide-A.topic',
        '<topic id="Guide-A" title="B"><web-file-name>index.html</web-file-name></topic>',
      );
      await expectLater(
        site(),
        throwsA(
          isA<HtmlExportException>().having(
            (e) => e.message,
            'reserved',
            contains('reserved'),
          ),
        ),
      );
      await put(
        'module/topics/Guide-A.topic',
        '<topic id="Guide-A" title="B"><web-file-name>../escape.html</web-file-name></topic>',
      );
      await expectLater(
        site(),
        throwsA(
          isA<HtmlExportException>().having(
            (e) => e.message,
            'invalid',
            contains('Invalid web filename'),
          ),
        ),
      );
    },
  );
  test(
    'source and media are captured before progress or later editor changes',
    () async {
      const svg =
          '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="red"/></svg>';
      await put('logo.svg', svg);
      await put('source.md', '# Disk');
      final request = MarkdownHtmlExportRequest(
        source: '# Unsaved\n\n![Logo](logo.svg)',
        filePath: p.join(root.path, 'source.md'),
        workspaceRoot: root.path,
        destinationPath: p.join(root.path, 'out.html'),
      );
      final result = await const HtmlExportService().exportMarkdown(
        request,
        onProgress: (done, total) {
          File(p.join(root.path, 'source.md')).writeAsStringSync('# Later');
          File(
            p.join(root.path, 'logo.svg'),
          ).writeAsStringSync(svg.replaceAll('red', 'blue'));
        },
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelector('h1')!.text, 'Unsaved');
      expect(
        await File(
          p.join(root.path, doc.querySelector('img')!.attributes['src']!),
        ).readAsString(),
        contains('red'),
      );
    },
  );
  test(
    'publication failure retains previous HTML and referenced immutable assets',
    () async {
      await put(
        'logo.svg',
        '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="red"/></svg>',
      );
      MarkdownHtmlExportRequest request(String source) =>
          MarkdownHtmlExportRequest(
            source: source,
            filePath: p.join(root.path, 'source.md'),
            workspaceRoot: root.path,
            destinationPath: p.join(root.path, 'out.html'),
            overwrite: true,
          );
      final original = await const HtmlExportService().exportMarkdown(
        request('# Old\n\n![Logo](logo.svg)'),
      );
      final bytes = await File(original.entryPointPath).readAsBytes();
      await put(
        'logo.svg',
        '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="blue"/></svg>',
      );
      final service = HtmlExportService(
        publisher: HtmlExportPublisher(fileWriter: _FailHtmlWrite()),
      );
      await expectLater(
        service.exportMarkdown(request('# New\n\n![Logo](logo.svg)')),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File(original.entryPointPath).readAsBytes(), bytes);
      final url = html
          .parse(utf8.decode(bytes))
          .querySelector('img')!
          .attributes['src']!;
      expect(
        await File(p.join(root.path, url)).readAsString(),
        contains('red'),
      );
      expect(
        await root
            .list()
            .where((f) => p.basename(f.path).startsWith('.busymark-html-'))
            .length,
        0,
      );
    },
  );
  test(
    'duplicate explicit IDs warn, non-Latin footnotes and document IDs resolve',
    () async {
      final result = await const HtmlExportService().exportMarkdown(
        MarkdownHtmlExportRequest(
          source:
              '# Ids\n\nNote[^日本語].\n\n[^日本語]: Return.\n\n<div id="busymark-content">Reserved source ID</div>\n\n<p id="twice">One</p>\n\n<p id="twice">Two</p>',
          filePath: p.join(root.path, 'source.md'),
          workspaceRoot: root.path,
          destinationPath: p.join(root.path, 'out.html'),
          mode: MarkdownMode.gfm,
        ),
      );
      final doc = html.parse(await File(result.entryPointPath).readAsString());
      expect(doc.querySelectorAll('[id="twice"]').length, 1);
      expect(doc.querySelectorAll('[id="busymark-content"]').length, 1);
      expect(result.warnings.any((w) => w.code == 'anchor.duplicate'), isTrue);
    },
  );
}

class _FailHtmlWrite extends AtomicFileWriter {
  @override
  Future<void> writeBytes(
    String targetPath,
    List<int> bytes, {
    required bool overwrite,
  }) async {
    if (targetPath.endsWith('.html')) {
      throw const FileSystemException('Simulated permission failure');
    }
    return super.writeBytes(targetPath, bytes, overwrite: overwrite);
  }
}
