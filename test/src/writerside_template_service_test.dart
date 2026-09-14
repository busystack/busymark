import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/writerside/writerside_template_service.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late WritersideTemplateService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-templates-test-');
    service = WritersideTemplateService(
      storagePath: p.join(root.path, 'support/templates.json'),
      loadBundledSource: () =>
          File('assets/writerside/templates.json').readAsString(),
    );
  });
  tearDown(() => root.delete(recursive: true));

  test(
    'real installed catalog has six default families and 22 bundled TGDP topics',
    () async {
      final templates = await service.catalog();
      expect(
        templates
            .where((entry) => entry.category == 'default')
            .map((entry) => entry.name)
            .toSet(),
        {
          'How to',
          'Overview',
          'Reference',
          'Section Starting Page',
          'Starter',
          'Tutorial',
        },
      );
      expect(
        templates.where((entry) => entry.category == 'default'),
        hasLength(10),
      );
      expect(
        templates.where((entry) => entry.category == 'tgdp'),
        hasLength(22),
      );
      expect(await Directory(p.join(root.path, 'support')).exists(), isFalse);
      final resources =
          jsonDecode(
                await File('assets/writerside/templates.json').readAsString(),
              )
              as List;
      for (final resource in resources) {
        expect(
          sha256.convert(utf8.encode(resource['source'] as String)).toString(),
          resource['sha256'],
          reason: resource['resource'] as String,
        );
      }
      for (final template in templates) {
        final generated = WritersideTemplateService.generate(
          template,
          title: 'New title',
          id: 'new-topic',
        );
        if (template.extension == 'topic') {
          final xml = XmlDocument.parse(generated);
          expect(xml.rootElement.getAttribute('id'), 'new-topic');
          expect(xml.rootElement.getAttribute('title'), 'New title');
        } else {
          expect(generated, contains('# New title'));
        }
        if (template.category == 'default') {
          expect(generated, isNot(contains(r'${TITLE}')));
        }
      }
    },
  );

  test(
    'literal substitution is simultaneous, case-sensitive, XML-only escaped',
    () {
      const md = WritersideTemplate(
        id: 'test',
        name: 'Test',
        category: 'custom',
        extension: 'md',
        source: r'${TITLE} ${ID} ${OTHER} $TITLE #set($x=1)',
      );
      expect(
        WritersideTemplateService.generate(
          md,
          title: r'${ID} & *title*',
          id: 'new',
        ),
        r'${ID} & *title* new ${OTHER} $TITLE #set($x=1)',
      );
      final xml = md.copyWith(
        extension: 'topic',
        source: '<topic title="\${TITLE}" id="\${ID}"/>',
      );
      expect(
        WritersideTemplateService.generate(
          xml,
          title: 'A & "B" <C>\u0000\u007f\u0085\u009f',
          id: 'new',
        ),
        '<topic title="A &amp; &quot;B&quot; &lt;C&gt;&#127;\u0085&#159;" id="new"/>',
      );
      expect(
        WritersideTemplateService.filenameFromTitle('  Hello, world! A_B  '),
        'Hello-world-A-B',
      );
    },
  );

  test('save source matches installed first-match substring behavior', () {
    expect(
      WritersideTemplateService.prepareSavedSource(
        source: '# Guide\n# Guide extra\n',
        title: 'Guide',
        format: WritersideTopicFormat.markdown,
      ),
      '# \${TITLE}\n# \${TITLE} extra\n',
    );
    expect(
      WritersideTemplateService.prepareSavedSource(
        source: 'Guide\n===\nBody',
        title: 'Guide',
        format: WritersideTopicFormat.markdown,
      ),
      '# \${TITLE}\nBody',
    );
    expect(
      WritersideTemplateService.prepareSavedSource(
        source: '<topic title = "Guide" id="old"><p title="Guide"/></topic>',
        title: 'Guide',
        id: 'old',
        format: WritersideTopicFormat.xml,
      ),
      '<topic title="\${TITLE}" id="\${ID}"><p title="Guide"/></topic>',
    );
    expect(
      WritersideTemplateService.prepareSavedSource(
        source: '# Base\n<title instance="api">Context</title>',
        title: 'Context',
        format: WritersideTopicFormat.markdown,
      ),
      '# Base\n<title instance="api">Context</title>',
    );
  });

  test('TGDP brace escaping preserves attribute blocks and rewrites relative links', () {
    const template = WritersideTemplate(
      id: 'sample',
      name: 'Sample',
      category: 'tgdp',
      extension: 'md',
      url:
          'https://gitlab.com/tgdp/templates/-/blob/v1.2.0/how-to/template_how-to.md',
      source:
          '# Old\n\n{Project} {style="note"}\n\n[Guide](guide_how-to.md) [Anchor](#here) [Web](https://example.com)\n',
    );
    final result = WritersideTemplateService.generate(
      template,
      title: 'New',
      id: 'new',
    );
    expect(result, startsWith('# New\n'));
    expect(result, contains('{(Project)} {style="note"}'));
    expect(
      result,
      contains(
        '(https://gitlab.com/tgdp/templates/-/blob/v1.2.0/how-to/guide_how-to.md)',
      ),
    );
    expect(result, contains('[Anchor](#here) [Web](https://example.com)'));
    final repeated = WritersideTemplateService.generate(
      template.copyWith(
        source:
            '# Title\n\n`[Code](same.md)` [same.md](same.md) [Again](same.md) ![same.md](same.md)\n',
      ),
      title: 'New',
      id: 'new',
    );
    expect(
      repeated,
      '# New\n\n`[Code](same.md)` [same.md](https://gitlab.com/tgdp/templates/-/blob/v1.2.0/how-to/same.md) [Again](https://gitlab.com/tgdp/templates/-/blob/v1.2.0/how-to/same.md) ![same.md](https://gitlab.com/tgdp/templates/-/blob/v1.2.0/how-to/same.md)\n',
    );
  });

  test(
    'save, unique naming, restart, cancellation snapshot and stale edit rejection',
    () async {
      final topic = const WritersideTopicParser().parseXml(
        filePath: '/project/topics/guide.topic',
        source: '<topic id="guide" title="Guide"><p>Keep body</p></topic>',
        topicsRoot: '/project/topics',
      );
      final first = await service.saveTopic(
        topic: topic,
        contextualTitle: 'Guide',
      );
      expect(first.name, 'Writerside_guide');
      final snapshot = await service.read();
      final second = await service.saveTopic(
        topic: topic,
        contextualTitle: 'Guide',
      );
      expect(second.name, 'Writerside_guide (1)');
      await expectLater(
        service.save(snapshot, []),
        throwsA(isA<WritersideTemplateConflict>()),
      );
      final reopened = WritersideTemplateService(
        storagePath: service.storagePath,
      );
      expect((await reopened.read()).entries, hasLength(2));
      final latest = await service.read();
      await service.save(latest, [
        first.copyWith(
          name: 'Renamed',
          source: '<topic id="\${ID}" title="\${TITLE}"><p>Edited</p></topic>',
        ),
      ]);
      expect((await reopened.read()).entries.single.name, 'Renamed');
      expect(
        topic.document.source,
        '<topic id="guide" title="Guide"><p>Keep body</p></topic>',
      );
    },
  );

  test('concurrent saves serialize without losing templates', () async {
    final topic = const WritersideTopicParser().parseMarkdown(
      filePath: '/guide.md',
      source: '# Guide',
      topicsRoot: '/',
    );
    final other = WritersideTemplateService(storagePath: service.storagePath);
    await Future.wait([
      service.saveTopic(topic: topic, contextualTitle: 'Guide'),
      other.saveTopic(topic: topic, contextualTitle: 'Guide'),
    ]);
    expect((await service.read()).entries.map((entry) => entry.name).toSet(), {
      'Writerside_guide',
      'Writerside_guide (1)',
    });
  });

  test('corrupt and symbolic-link stores are never replaced', () async {
    final path = service.storagePath!;
    await File(path).parent.create(recursive: true);
    await File(path).writeAsString('{broken');
    await expectLater(service.read(), throwsFormatException);
    await expectLater(
      service.save(const WritersideTemplateSnapshot([], null), []),
      throwsFormatException,
    );
    expect(await File(path).readAsString(), '{broken');
    await File(path).delete();
    final target = File(p.join(root.path, 'keep.json'));
    await target.writeAsString('keep');
    await Link(path).create(target.path);
    await expectLater(service.read(), throwsA(isA<FileSystemException>()));
    expect(await target.readAsString(), 'keep');
  });

  test(
    'builtin overrides persist independently and reset reveals original source',
    () async {
      final original = (await service.bundled()).first;
      await service.save(await service.read(), [
        original.copyWith(source: '# \${TITLE}\nEdited'),
      ]);
      expect((await service.catalog()).first.source, '# \${TITLE}\nEdited');
      await service.save(await service.read(), []);
      expect((await service.catalog()).first.source, original.source);
    },
  );

  test(
    'template bytes are published in the guarded creation transaction and rolled back on conflict',
    () async {
      final tree = File(p.join(root.path, 'guide.tree'));
      await tree.writeAsString(
        '<instance-profile id="guide"><toc-element toc-title="Group"/></instance-profile>',
      );
      final template = (await service.bundled()).first;
      final content = WritersideTemplateService.generate(
        template,
        title: 'New',
        id: 'new',
      );
      final target = WritersideTopicCreateTarget(
        rootPath: root.path,
        treePath: tree.path,
        topicsRootDir: 'topics',
        existingTopicIds: {},
      );
      const request = WritersideTopicCreateRequest(
        title: 'New',
        fileName: 'new.md',
        format: WritersideTopicFormat.markdown,
        placement: WritersideTopicCreatePlacement.root,
      );
      var checks = 0;
      await expectLater(
        const WritersideTopicCreator().create(
          target,
          request,
          initialSource: content,
          validateBeforePublish: () async {
            if (++checks == 2) throw StateError('dirty inactive tree');
          },
        ),
        throwsStateError,
      );
      expect(await File(p.join(root.path, 'topics/new.md')).exists(), isFalse);
      expect(await tree.readAsString(), isNot(contains('new.md')));
      final result = await const WritersideTopicCreator().create(
        target,
        request,
        initialSource: content,
      );
      expect(await File(result.topicPath).readAsString(), content);
      expect(await tree.readAsString(), contains('new.md'));
    },
  );

  test(
    'invalid XML templates and colliding root IDs never publish a topic or TOC edit',
    () async {
      final tree = File(p.join(root.path, 'guide.tree'));
      const original = '<instance-profile id="guide"/>';
      await tree.writeAsString(original);
      final target = WritersideTopicCreateTarget(
        rootPath: root.path,
        treePath: tree.path,
        topicsRootDir: 'topics',
        existingTopicIds: {'occupied'},
      );
      for (final source in ['<topic', '<chapter/>', '<topic id="occupied"/>']) {
        await expectLater(
          const WritersideTopicCreator().create(
            target,
            const WritersideTopicCreateRequest(
              title: 'New',
              fileName: 'new.topic',
              format: WritersideTopicFormat.xml,
            ),
            initialSource: source,
          ),
          throwsA(isA<BusyMarkException>()),
        );
        expect(await tree.readAsString(), original);
        expect(await Directory(p.join(root.path, 'topics')).exists(), isFalse);
      }
    },
  );
}
