import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/workspace/presentation/writerside_toc_dialogs.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_document.dart';
import 'package:busymark/src/writerside/writerside_document_parser.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:busymark/src/writerside/writerside_title_editor.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  const service = WorkspaceService();

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['yaru_window', 'yaru_window/events']) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (call) async => call.method == 'state' ? <String, Object?>{} : null,
      );
    }
  });
  tearDown(() {
    for (final name in ['yaru_window', 'yaru_window/events']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
  });

  Future<Directory> fixture(
    String source, {
    String extension = 'md',
    String? tree,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-title-review-',
    );
    addTearDown(() => root.delete(recursive: true));
    await Directory(p.join(root.path, 'topics')).create();
    await File(
      p.join(root.path, 'topics/topic.$extension'),
    ).writeAsString(source);
    await File(p.join(root.path, 'writerside.cfg')).writeAsString(
      '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
    );
    await File(p.join(root.path, 'guide.tree')).writeAsString(
      tree ??
          '<instance-profile id="guide"><toc-element topic="topic.$extension"/></instance-profile>',
    );
    return root;
  }

  Future<WritersideTitleEditSession> session(Directory root) async {
    final workspace = await service.openPath(root.path);
    final instance = workspace.writersideModule!.instances.single;
    final topic = workspace.writersideModule!.topics.single;
    return service.prepareWritersideTitleEdit(
      workspace,
      treePath: instance.sourceTreePath,
      tocPath: [0],
      identity: WritersideTocNodeIdentity.fromNode(instance.tocRoots.first),
      topicModuleRoot: workspace.writersideModule!.rootPath,
      topicPath: topic.filePath,
    );
  }

  Future<void> save(
    WritersideTitleEditSession session,
    WritersideTitleEdit edit,
  ) async {
    await service.editWritersideTitles(
      session,
      edit,
      validateBeforeCommit: () {},
      onCommitted: (_, _) {},
    );
  }

  test(
    'title edit preserves the resolved topic owner across modules',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-title-owner-',
      );
      addTearDown(() => root.delete(recursive: true));
      final mainTopics = await Directory(p.join(root.path, 'topics')).create();
      final sharedRoot = await Directory(p.join(root.path, 'shared')).create();
      final sharedTopics = await Directory(
        p.join(sharedRoot.path, 'topics'),
      ).create();
      await File(p.join(root.path, 'writerside.cfg')).writeAsString('''
<ihp><module name="main"/><topics dir="topics"/><instance src="guide.tree"/></ihp>
''');
      await File(p.join(root.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide"><toc-element topic="shared.md" origin="shared"/></instance-profile>
''');
      final mainTopic = File(p.join(mainTopics.path, 'shared.md'));
      await mainTopic.writeAsString('# Main title\n');
      await File(p.join(sharedRoot.path, 'writerside.cfg')).writeAsString('''
<ihp><module name="shared"/><topics dir="topics"/><instance src="library.tree"/></ihp>
''');
      await File(p.join(sharedRoot.path, 'library.tree')).writeAsString('''
<instance-profile id="library" is-library="true"><toc-element topic="shared.md"/></instance-profile>
''');
      final sharedTopic = File(p.join(sharedTopics.path, 'shared.md'));
      await sharedTopic.writeAsString('# Shared title\n');

      final workspace = await service.openPath(root.path);
      final instance = workspace.writersideModule!.instances.single;
      final node = instance.tocRoots.single;
      final owner = workspace.writersideProject!.modulesByOrigin['shared']!;
      final resolved = owner.topicByReference(node.topicReference!)!;
      final editSession = await service.prepareWritersideTitleEdit(
        workspace,
        treePath: instance.sourceTreePath,
        tocPath: [0],
        identity: WritersideTocNodeIdentity.fromNode(node),
        topicModuleRoot: owner.rootPath,
        topicPath: resolved.filePath,
      );

      expect(editSession.topic.title, 'Shared title');
      await save(
        editSession,
        const WritersideTitleEdit(title: 'Shared updated'),
      );
      expect(await mainTopic.readAsString(), '# Main title\n');
      expect(await sharedTopic.readAsString(), '# Shared updated\n');
    },
  );

  for (final newline in ['\n', '\r\n']) {
    for (final quote in ['"', "'"]) {
      test(
        'multiline quoted titles change and clear safely (${newline.length}, $quote)',
        () async {
          final source =
              '<topic id="topic" title=${quote}Old${newline}base$quote audience="keep">'
              '$newline<title instance="guide">Old${newline}instance</title>'
              '$newline<title instance="other">Other &amp; title</title>'
              '$newline<p id="body">Unchanged</p>$newline</topic>';
          final tree =
              '<instance-profile id="guide" name="Keep">$newline'
              '<toc-element topic="topic.topic" toc-title=${quote}Old${newline}navigation$quote hidden="true" audience="keep"/>'
              '$newline</instance-profile>';
          final root = await fixture(source, extension: 'topic', tree: tree);
          final first = await session(root);
          final span =
              first.topic.document.rootElement!.attributeSpans['title']!;
          expect(
            first.topicLoad.text.substring(span.startOffset, span.endOffset),
            'Old\nbase',
          );
          final rawSpan = const WritersideDocumentParser()
              .parseXml(filePath: first.topic.filePath, source: source)
              .rootElement!
              .attributeSpans['title']!;
          expect(
            source.substring(rawSpan.startOffset, rawSpan.endOffset),
            'Old${newline}base',
          );
          await save(
            first,
            const WritersideTitleEdit(
              title: 'New & "base"',
              instanceTitle: 'New & instance',
              tocTitle: 'New & navigation',
            ),
          );
          final changed = await session(root);
          final xml = XmlDocument.parse(changed.topicLoad.text).rootElement;
          final toc = XmlDocument.parse(
            changed.treeLoad.text,
          ).findAllElements('toc-element').single;
          expect(
            xml.attributes.where((a) => a.name.local == 'title'),
            hasLength(1),
          );
          expect(xml.getAttribute('title'), 'New & "base"');
          expect(xml.getAttribute('audience'), 'keep');
          expect(
            xml.getElement('p')!.toXmlString(),
            '<p id="body">Unchanged</p>',
          );
          expect(xml.getElement('title')!.innerText, 'New & instance');
          expect(
            changed.topicLoad.text,
            contains('<title instance="other">Other &amp; title</title>'),
          );
          expect(
            toc.attributes.where((a) => a.name.local == 'toc-title'),
            hasLength(1),
          );
          expect(toc.getAttribute('toc-title'), 'New & navigation');
          expect(toc.getAttribute('hidden'), 'true');
          expect(toc.getAttribute('audience'), 'keep');
          await save(
            changed,
            const WritersideTitleEdit(instanceTitle: '', tocTitle: ''),
          );
          final cleared = await session(root);
          expect(cleared.topic.titleOverrides.map((title) => title.instance), [
            'other',
          ]);
          expect(cleared.identity.tocTitle, isNull);
          expect(cleared.topicLoad.text, contains('audience="keep"'));
          expect(
            cleared.treeLoad.text,
            contains('hidden="true" audience="keep"'),
          );
          expect(cleared.topic.title, 'New & "base"');
          if (newline == '\r\n') {
            expect(
              (await File(
                cleared.topic.filePath,
              ).readAsString()).replaceAll('\r\n', ''),
              isNot(contains('\n')),
            );
            expect(
              (await File(
                cleared.treePath,
              ).readAsString()).replaceAll('\r\n', ''),
              isNot(contains('\n')),
            );
          }
        },
      );

      test(
        'clearing a multiline TOC override removes the existing attribute (${newline.length}, $quote)',
        () async {
          final root = await fixture(
            '# Base\n',
            tree:
                '<instance-profile id="guide"><toc-element topic="topic.md" toc-title=${quote}Old${newline}navigation$quote hidden="true"/></instance-profile>',
          );
          final first = await session(root);
          await save(first, const WritersideTitleEdit(tocTitle: ''));
          final cleared = await session(root);
          expect(cleared.identity.tocTitle, isNull);
          expect(cleared.identity.hidden, isTrue);
          expect(cleared.topicLoad.text, first.topicLoad.text);
        },
      );
    }
  }

  test(
    'normalized title identity still rejects changed content and raw matching stays exact',
    () {
      const identity = WritersideTocNodeIdentity(
        hidden: false,
        tocTitle: 'Old\r\nnavigation',
      );
      final same = XmlDocument.parse(
        '<toc-element toc-title="Old\nnavigation"/>',
      ).rootElement;
      final changed = XmlDocument.parse(
        '<toc-element toc-title="Other\nnavigation"/>',
      ).rootElement;
      expect(identity.matches(same), isFalse);
      expect(identity.matches(same, normalizedText: true), isTrue);
      expect(identity.matches(changed, normalizedText: true), isFalse);
    },
  );

  for (final missing in [true, false]) {
    test(
      'title transaction rejects ${missing ? 'missing' : 'corrupt'} attribute ranges before publication',
      () async {
        final root = await fixture(
          '<topic id="topic" title="Old"><p>Body</p></topic>',
          extension: 'topic',
        );
        final original = await session(root);
        final topic =
            WritersideTopicParser(
              documentParser: _BrokenTitleSpanParser(missing: missing),
            ).parseXml(
              filePath: original.topic.filePath,
              source: original.topicLoad.text,
            );
        final broken = WritersideTitleEditSession(
          topic: topic,
          topicModuleRoot: original.topicModuleRoot,
          instanceId: original.instanceId,
          treePath: original.treePath,
          tocPath: original.tocPath,
          identity: original.identity,
          topicLoad: original.topicLoad,
          treeLoad: original.treeLoad,
        );
        var reachedPublication = false;
        await expectLater(
          service.editWritersideTitles(
            broken,
            const WritersideTitleEdit(
              title: 'Changed',
              tocTitle: 'Changed navigation',
            ),
            validateBeforeCommit: () => reachedPublication = true,
            onCommitted: (_, _) => reachedPublication = true,
          ),
          throwsA(isA<BusyMarkException>()),
        );
        expect(reachedPublication, isFalse);
        expect(
          await File(original.topic.filePath).readAsString(),
          original.topicLoad.text,
        );
        expect(
          await File(original.treePath).readAsString(),
          original.treeLoad.text,
        );
      },
    );
  }

  test(
    'title publication rejects duplicate attributes in resulting XML',
    () async {
      final root = await fixture(
        '<topic id="topic" title="Old" custom="a" custom="b"/>',
        extension: 'topic',
      );
      final original = await session(root);
      await expectLater(
        save(
          original,
          const WritersideTitleEdit(title: 'Changed', tocTitle: 'Changed'),
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(
        await File(original.topic.filePath).readAsString(),
        original.topicLoad.text,
      );
      expect(
        await File(original.treePath).readAsString(),
        original.treeLoad.text,
      );
    },
  );

  for (final quote in ['"', "'"]) {
    test(
      'semantic Markdown instance titles ignore fenced examples and decode once ($quote)',
      () {
        final topic = const WritersideTopicParser().parseMarkdown(
          filePath: '/topics/topic.md',
          topicsRoot: '/topics',
          source:
              '# Base\n\n```xml\n<title instance="guide">Wrong &amp; example</title>\n```\n\n'
              '<title instance=${quote}guide$quote>A &amp; B &amp;amp; C</title>\n',
        );
        expect(topic.titleOverrides, hasLength(1));
        expect(topic.titleOverrides.single.instance, 'guide');
        expect(topic.titleOverrides.single.title, 'A & B &amp; C');
      },
    );
  }

  Future<WritersideTitleEdit?> showTitle(
    WidgetTester tester,
    WritersideTitleEditSession current, {
    String? value,
    bool inspectHelp = false,
  }) async {
    WritersideTitleEdit? edit;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  edit = await showDialog<WritersideTitleEdit>(
                    context: context,
                    builder: (_) => WritersideTitleDialog(session: current),
                  ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced Settings'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, "Title for 'guide':");
    expect(
      tester.widget<TextField>(field).controller!.text,
      current.topic.titleOverrides
              .where((t) => t.instance == 'guide')
              .firstOrNull
              ?.title ??
          '',
    );
    if (inspectHelp) {
      expect(
        find.text(
          'Used for the current instance only. By default, inherited from topic title.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Used in TOC only.', findRichText: true),
        findsOneWidget,
      );
      final link = find.widgetWithText(TextButton, 'here');
      expect(link, findsOneWidget);
      MethodCall? launched;
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        launched = call;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        launched?.arguments['url'],
        'https://www.jetbrains.com/help/writerside/topics.html',
      );
    }
    if (value != null) await tester.enterText(field, value);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    return edit;
  }

  testWidgets(
    'instance title save, reopen, unchanged OK, and edit keep one escaping layer',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const example =
          '```xml\n<title instance="guide">Fenced &amp; example</title>\n```';
      final root = (await tester.runAsync(
        () => fixture('# Base\n\n$example\n'),
      ))!;
      var current = (await tester.runAsync(() => session(root)))!;
      expect(current.topic.titleOverrides, isEmpty);
      final first = (await showTitle(
        tester,
        current,
        value: 'A & B',
        inspectHelp: true,
      ))!;
      expect(first.instanceTitle, 'A & B');
      await tester.runAsync(() => save(current, first));
      current = (await tester.runAsync(() => session(root)))!;
      expect(
        current.topicLoad.text,
        contains('<title instance="guide">A &amp; B</title>'),
      );
      expect(current.topic.titleOverrides.single.title, 'A & B');
      final unchanged = (await showTitle(tester, current))!;
      expect(unchanged.instanceTitle, isNull);
      final next = (await showTitle(tester, current, value: 'A & B updated'))!;
      await tester.runAsync(() => save(current, next));
      current = (await tester.runAsync(() => session(root)))!;
      expect(
        current.topicLoad.text,
        contains('<title instance="guide">A &amp; B updated</title>'),
      );
      expect(current.topicLoad.text, isNot(contains('&amp;amp; B')));
      expect(current.topicLoad.text, contains(example));
      expect(current.topic.titleOverrides.single.title, 'A & B updated');
    },
  );

  testWidgets(
    'single-quoted Markdown override reopens decoded and edits without touching example',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const example = "~~~xml\n<title instance='guide'>Example</title>\n~~~";
      final root = (await tester.runAsync(
        () => fixture(
          "# Base\n\n$example\n\n<title instance='guide'>A &amp; B</title>\n",
        ),
      ))!;
      final current = (await tester.runAsync(() => session(root)))!;
      expect(current.topic.titleOverrides.single.title, 'A & B');
      final edit = (await showTitle(tester, current, value: 'A & B updated'))!;
      await tester.runAsync(() => save(current, edit));
      final updated = (await tester.runAsync(() => session(root)))!;
      expect(updated.topic.titleOverrides.single.title, 'A & B updated');
      expect(updated.topicLoad.text, contains(example));
    },
  );
}

class _BrokenTitleSpanParser extends WritersideDocumentParser {
  const _BrokenTitleSpanParser({required this.missing});
  final bool missing;
  @override
  WritersideDocument parseXml({
    required String filePath,
    required String source,
  }) {
    final parsed = super.parseXml(filePath: filePath, source: source);
    final root = parsed.rootElement!;
    final span = root.attributeSpans['title']!;
    return parsed.copyWith(
      nodes: [
        WritersideGenericElementNode(
          schemaKnown: true,
          name: root.name,
          qualifiedName: root.qualifiedName,
          attributes: root.attributes,
          qualifiedAttributes: root.qualifiedAttributes,
          attributeSpans: {
            for (final entry in root.attributeSpans.entries)
              if (entry.key != 'title') entry.key: entry.value,
            if (!missing)
              'title': SourceSpan.fromOffsets(
                filePath: filePath,
                source: source,
                startOffset: span.startOffset,
                endOffset: span.endOffset + 1,
              ),
          },
          children: root.children,
          span: root.span,
          rawSource: root.rawSource,
        ),
      ],
    );
  }
}
