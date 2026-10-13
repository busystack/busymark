import 'dart:io';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_effective_properties.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'configured capitalization uses existing variable resolution and source owners',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-caps-scope-',
      );
      addTearDown(() => root.delete(recursive: true));
      await Directory('${root.path}/topics').create();
      await File('${root.path}/writerside.cfg').writeAsString(
        '<ihp><topics dir="topics"/><vars src="v.list"/><instance src="web.tree"/><settings><default-property element-name="chapter" property-name="caps" value="%case%"/></settings></ihp>',
      );
      await File(
        '${root.path}/v.list',
      ).writeAsString('<vars><var name="case" value="title"/></vars>');
      await File('${root.path}/web.tree').writeAsString(
        '<instance-profile id="web" name="Web" start-page="main.topic"><toc-element topic="main.topic"/></instance-profile>',
      );
      const source =
          '<topic id="main" title="Topic"><var name="localcase" value="upper"/><chapter id="module" title="a journey through HTTP and APIs"><p>Body</p></chapter><chapter id="local" title="another journey" caps="%localcase%"><p>Body</p></chapter></topic>';
      await File('${root.path}/topics/main.topic').writeAsString(source);
      final module = await const WritersideModuleService().load(root.path);
      final topic = module.topicByReference('main.topic')!;
      final context = WritersideResolveContext(
        module: module,
        topic: topic,
        instance: module.instances.single,
      );
      final occurrences = const WritersideDocumentResolver()
          .resolvePropertyOccurrences(topic.document, context);
      final first = occurrences[source.indexOf('<chapter id="module"')]!;
      final local = occurrences[source.indexOf('<chapter id="local"')]!;
      expect(first['caps'], 'title');
      expect(local['caps'], 'upper');
      final effective = WritersideEffectiveProperties(
        settings: module.config.settings,
        resolvedValues: first,
      );
      expect(
        effective.resolve('chapter', 'caps', {}).origin,
        WritersidePropertyOrigin.module,
      );
      expect(effective.resolve('chapter', 'caps', {}).value, 'title');
      expect(
        await File('${root.path}/topics/main.topic').readAsString(),
        source,
      );
      expect(
        topic.document.elements
            .where((e) => e.name == 'chapter')
            .where((e) => e.attributes['id'] == 'module')
            .every((e) => !e.attributes.containsKey('caps')),
        isTrue,
      );
    },
  );
  const rule = WritersideCapsRule(style: 'title', target: 'chapter');
  test(
    'omitted capitalization has the published as-written built-in value',
    () {
      final p = const WritersideEffectiveProperties().resolve(
        'chapter',
        'caps',
        {},
      );
      expect(p.authored, isNull);
      expect(p.value, 'aswritten');
      expect(p.origin, WritersidePropertyOrigin.builtIn);
      expect(p.limitation, isNull);
    },
  );
  for (final target in ['chapter', 'topic', 'toc-element']) {
    test(
      '$target rule is retained with the verified ignored-rule limitation',
      () {
        final r = WritersideEffectiveProperties(
          settings: WritersideSettingsConfig(
            capsRules: [
              WritersideCapsRule(style: 'title', target: target),
              WritersideCapsRule(style: 'sentence', target: target),
            ],
          ),
        );
        final p = r.resolve(target, 'caps', {});
        expect(p.value, 'aswritten');
        expect(p.origin, WritersidePropertyOrigin.builtIn);
        expect(p.limitation, 'module-caps-ignored');
        final other = r.resolve(
          target == 'chapter' ? 'topic' : 'chapter',
          'caps',
          {},
        );
        expect(other.value, 'aswritten');
        expect(other.limitation, isNull);
      },
    );
  }
  test(
    'generic defaults apply; the first declaration wins for capitalization',
    () {
      const r = WritersideEffectiveProperties(
        settings: WritersideSettingsConfig(
          capsRules: [rule],
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'chapter',
              propertyName: 'caps',
              value: 'title',
            ),
            WritersideDefaultProperty(
              elementName: 'chapter',
              propertyName: 'caps',
              value: 'sentence',
            ),
            WritersideDefaultProperty(
              elementName: 'topic',
              propertyName: 'caps',
              value: 'upper',
            ),
          ],
        ),
      );
      final p = r.resolve('chapter', 'caps', {});
      expect(p.value, 'title');
      expect(p.origin, WritersidePropertyOrigin.module);
      expect(p.limitation, 'module-caps-ignored');
      final local = r.resolve('chapter', 'caps', {'caps': 'aswritten'});
      expect(local.value, 'aswritten');
      expect(local.origin, WritersidePropertyOrigin.element);
      expect(local.limitation, isNull);
      // A chapter default never leaks into an unrelated element.
      expect(r.resolve('tab', 'caps', {}).value, 'aswritten');
    },
  );
  test(
    'variable-valued local and generic capitalization use existing resolution',
    () {
      const r = WritersideEffectiveProperties(
        variables: {'case': 'title'},
        settings: WritersideSettingsConfig(
          capsRules: [rule],
          defaultProperties: [
            WritersideDefaultProperty(
              elementName: 'chapter',
              propertyName: 'caps',
              value: '%case%',
            ),
          ],
        ),
      );
      expect(r.resolve('chapter', 'caps', {}).value, 'title');
      expect(
        r.resolve('chapter', 'caps', {}).origin,
        WritersidePropertyOrigin.module,
      );
      expect(
        r.resolve('chapter', 'caps', {'caps': '%case%'}).origin,
        WritersidePropertyOrigin.element,
      );
      final missing = r.resolve('chapter', 'caps', {'caps': '%unknown%'});
      expect(missing.value, isNull);
      expect(missing.origin, WritersidePropertyOrigin.unresolved);
      expect(missing.authored, '%unknown%');
    },
  );
  test(
    'capitalization edits/reset keep heading text, inline formatting and source owners',
    () {
      const source =
          '# Topic\n\n## a journey through HTTP and APIs\n\nBody **formatting**.\n';
      final document = const MarkdownParser()
          .parse(
            filePath: 'caps.md',
            source: source,
            mode: MarkdownMode.writersideMarkdown,
          )
          .busyDocument;
      final c = BusyMarkWysiwygDocumentController(document: document);
      addTearDown(c.dispose);
      final heading = c.document.blocks[1];
      expect(c.updateWritersideProperty(heading.id, 'caps', 'upper'), isTrue);
      expect(
        c.markdown,
        contains('## a journey through HTTP and APIs {caps="upper"}'),
      );
      expect(c.markdown, endsWith('Body **formatting**.\n'));
      expect(c.updateWritersideProperty(heading.id, 'caps', null), isTrue);
      expect(c.markdown, source);
    },
  );
}
