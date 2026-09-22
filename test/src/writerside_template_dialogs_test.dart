import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_search_field.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/workspace/presentation/writerside_template_dialogs.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_template_service.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaru/yaru.dart';

void main() {
  late Directory root;
  late WritersideTemplateService service;
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(
        const MethodChannel('yaru_window'),
        (call) async => call.method == 'state' ? <String, Object?>{} : null,
      )
      ..setMockMethodCallHandler(
        const MethodChannel('yaru_window/events'),
        (_) async => null,
      );
    root = await Directory.systemTemp.createTemp('busymark-template-dialog-');
    service = WritersideTemplateService(
      storagePath: p.join(root.path, 'templates.json'),
      loadBundledSource: () =>
          File('assets/writerside/templates.json').readAsString(),
    );
  });
  tearDown(() => root.delete(recursive: true));

  Future<void> show(
    WidgetTester tester,
    Widget dialog, {
    TextDirection direction = TextDirection.ltr,
    Size size = const Size(1300, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          writersideTemplateServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: buildBusyMarkTheme(
            brightness: Brightness.light,
            accentColor: const Color(0xFFE95420),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      Directionality(textDirection: direction, child: dialog),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await settle(tester);
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'creation selects real variants, validates and submits in $direction',
      (tester) async {
        String? created;
        await show(
          tester,
          WritersideTemplateDialog(
            existingIds: {'existing'},
            previewBuilder: (context, template, title, filename) =>
                SingleChildScrollView(
                  child: Text(
                    WritersideTemplateService.generate(
                      template,
                      title: title,
                      id: filename,
                    ),
                  ),
                ),
            onCreate: (template, title, filename) async {
              created = WritersideTemplateService.generate(
                template,
                title: title,
                id: filename,
              );
              return null;
            },
          ),
          direction: direction,
        );
        expect(find.text('Create Topic from Template'), findsOneWidget);
        final sidebarCenter = tester
            .getRect(find.byType(BusyMarkSidebarSurface))
            .center
            .dx;
        final formCenter = tester
            .getRect(find.byKey(const ValueKey('template-title')))
            .center
            .dx;
        expect(
          sidebarCenter,
          direction == TextDirection.ltr
              ? lessThan(formCenter)
              : greaterThan(formCenter),
        );
        expect(
          tester.getCenter(find.byKey(const ValueKey('template-format-md'))).dy,
          closeTo(
            tester
                .getCenter(find.byKey(const ValueKey('template-format-topic')))
                .dy,
            1,
          ),
        );
        final markdown = tester.widget<BusyMarkRadioButton<String>>(
          find.byKey(const ValueKey('template-format-md')),
        );
        final xml = tester.widget<BusyMarkRadioButton<String>>(
          find.byKey(const ValueKey('template-format-topic')),
        );
        expect(markdown.value, 'md');
        expect(xml.value, 'topic');
        expect(markdown.groupValue, 'md');
        expect(xml.groupValue, 'md');
        await tester.tap(find.text('XML (.topic)'));
        await tester.pump();
        expect(
          tester
              .widget<BusyMarkRadioButton<String>>(
                find.byKey(const ValueKey('template-format-md')),
              )
              .groupValue,
          'topic',
        );
        expect(
          tester
              .widget<BusyMarkRadioButton<String>>(
                find.byKey(const ValueKey('template-format-topic')),
              )
              .groupValue,
          'topic',
        );
        await tester.enterText(editableUnderKey('template-title'), 'A & B');
        await tester.enterText(
          editableUnderKey('template-filename'),
          'existing',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        expect(created, isNull);
        await tester.enterText(editableUnderKey('template-filename'), '../bad');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        expect(created, isNull);
        await tester.enterText(
          editableUnderKey('template-filename'),
          'from-template',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        await settle(tester);
        expect(created, contains('title="A &amp; B" id="from-template"'));
        expect(
          created,
          contains('A How-to article is an action-oriented type of document.'),
        );
        expect(find.text('Create Topic from Template'), findsNothing);
      },
    );
  }

  testWidgets('creation uses native master-detail controls and filters', (
    tester,
  ) async {
    await show(
      tester,
      WritersideTemplateDialog(
        existingIds: const {},
        previewBuilder: (_, template, title, filename) =>
            Text('${template.id}:$title:$filename'),
        onCreate: (_, _, _) async => null,
      ),
      size: const Size(650, 900),
    );

    expect(find.byType(BusyMarkSearchField), findsOneWidget);
    expect(find.byType(YaruExpandable), findsNWidgets(3));
    expect(find.byType(YaruMasterTile), findsWidgets);
    expect(find.byType(BusyMarkGroupedTextEntry), findsNWidgets(2));
    expect(find.byType(BusyMarkActionRow), findsOneWidget);
    expect(find.byType(BusyMarkRadioButton<String>), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(BusyMarkRadioButton<String>),
        matching: find.byType(YaruRadioButton<String>),
      ),
      findsNWidgets(2),
    );
    expect(find.byType(BusyMarkSidebarSurface), findsOneWidget);
    final formatTile = tester.widget<YaruListTile>(
      find.byKey(const ValueKey('template-format')),
    );
    expect(formatTile.trailing, isNull);
    expect(formatTile.title, isA<Wrap>());
    expect(
      tester.getCenter(find.byKey(const ValueKey('template-format-topic'))).dy,
      greaterThan(
        tester.getCenter(find.byKey(const ValueKey('template-format-md'))).dy,
      ),
    );

    await tester.enterText(editableUnderKey('template-search'), 'Overview');
    await tester.pumpAndSettle();
    final overviewTile = find.byKey(
      const ValueKey('template-Writerside Overview MD Topic.md'),
    );
    expect(overviewTile, findsOneWidget);
    expect(
      find.byKey(const ValueKey('template-Writerside How to MD Topic.md')),
      findsNothing,
    );
    await tester.tap(overviewTile);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<YaruMasterTile>(
            find.byKey(
              const ValueKey('template-Writerside Overview MD Topic.md'),
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<EditableText>(editableUnderKey('template-title'))
          .controller
          .text,
      'Overview',
    );

    await tester.enterText(
      editableUnderKey('template-search'),
      'API quickstart',
    );
    await tester.pumpAndSettle();
    final markdownOnlyTile = find.byKey(
      const ValueKey('template-api-quickstart/template_api-quickstart.md'),
    );
    expect(markdownOnlyTile, findsOneWidget);
    await tester.tap(markdownOnlyTile);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BusyMarkRadioButton<String>>(
            find.byKey(const ValueKey('template-format-md')),
          )
          .onChanged,
      isNotNull,
    );
    expect(
      tester
          .widget<BusyMarkRadioButton<String>>(
            find.byKey(const ValueKey('template-format-topic')),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets('creation opens both template editor entry points', (
    tester,
  ) async {
    await show(
      tester,
      WritersideTemplateDialog(
        existingIds: const {},
        previewBuilder: (_, _, _, _) => const SizedBox.shrink(),
        onCreate: (_, _, _) async => null,
      ),
    );

    await tester.tap(find.text('Edit templates...'));
    await settle(tester);
    expect(find.byType(YaruTabBar), findsOneWidget);
    expect(find.byType(BusyMarkPopupSelector<String>), findsOneWidget);
    expect(find.byType(BusyMarkGroupedTextEntry), findsWidgets);
    expect(find.byType(BusyMarkSidebarSurface), findsNWidgets(2));
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Cancel').last);
    await settle(tester);

    await tester.ensureVisible(find.text('Create custom template...'));
    await tester.tap(find.text('Create custom template...'));
    await settle(tester);
    expect(find.text('File and Code Templates'), findsOneWidget);
    expect(find.byType(YaruTabBar), findsOneWidget);
    expect(find.byType(BusyMarkPopupSelector<String>), findsOneWidget);
    expect(
      find.byKey(const ValueKey('template-editor-source')),
      findsOneWidget,
    );
  });

  testWidgets('catalog failure keeps BusyMark status and retry controls', (
    tester,
  ) async {
    service = _FailingTemplateService();
    await show(
      tester,
      WritersideTemplateDialog(
        existingIds: const {},
        previewBuilder: (_, _, _, _) => const SizedBox.shrink(),
        onCreate: (_, _, _) async => null,
      ),
    );

    expect(find.byType(BusyMarkStatusBox), findsOneWidget);
    expect(find.widgetWithText(BusyMarkDialogButton, 'Retry'), findsOneWidget);
  });

  testWidgets('Files editor stages new content, cancels and persists on OK', (
    tester,
  ) async {
    await show(tester, const WritersideTemplatesEditor(createNew: true));
    await tester.enterText(
      editableUnderKey('template-editor-name'),
      'My template',
    );
    await tester.enterText(
      find.byKey(const ValueKey('template-editor-source')),
      '# \${TITLE}\nCustom body',
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await tester.runAsync(service.read))!.entries, isEmpty);
    await tester.tap(find.text('Open'));
    await settle(tester);
    await tester.enterText(
      editableUnderKey('template-editor-name'),
      'My template',
    );
    await tester.enterText(
      find.byKey(const ValueKey('template-editor-source')),
      '# \${TITLE}\nCustom body',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    final saved = (await tester.runAsync(service.read))!.entries;
    expect(
      saved,
      hasLength(1),
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .join('\n'),
    );
    final stored = saved.single;
    expect(stored.name, 'My template');
    expect(stored.source, '# \${TITLE}\nCustom body');
    expect(find.text('File and Code Templates'), findsNothing);
  });

  testWidgets('source surface exposes its label and focus boundary', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await show(tester, const WritersideTemplatesEditor(createNew: true));

    final source = find.byKey(const ValueKey('template-editor-source'));
    final surface = find.byKey(
      const ValueKey('template-editor-source-surface'),
    );
    expect(tester.widget<BusyMarkGroupedSurface>(surface).focused, isFalse);
    expect(tester.getSemantics(source).label, contains('Source'));
    final field = tester.widget<TextField>(source);
    expect(field.decoration?.border, InputBorder.none);
    expect(field.decoration?.focusedBorder, InputBorder.none);

    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(tester.widget<BusyMarkGroupedSurface>(surface).focused, isTrue);
    semantics.dispose();
  });

  testWidgets(
    'New toolbar command stages an editable draft and Cancel drops it',
    (tester) async {
      await show(tester, const WritersideTemplatesEditor());
      expect(
        find.byKey(const ValueKey('template-editor-source')),
        findsNothing,
      );

      await tester.tap(
        find.widgetWithText(BusyMarkDialogButton, 'New template...'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unnamed.md'), findsOneWidget);
      final nameEntry = tester.widget<BusyMarkGroupedTextEntry>(
        find.byKey(const ValueKey('template-editor-name')),
      );
      expect(nameEntry.readOnly, isFalse);
      await tester.enterText(editableUnderKey('template-editor-name'), 'Draft');
      await tester.enterText(
        find.byKey(const ValueKey('template-editor-source')),
        '# Draft',
      );

      await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Cancel'));
      await settle(tester);
      expect((await tester.runAsync(service.read))!.entries, isEmpty);
    },
  );

  testWidgets('custom XML template cannot publish a mismatching root ID', (
    tester,
  ) async {
    const invalidTemplate = WritersideTemplate(
      id: 'custom-invalid-xml-id',
      name: 'Broken XML ID',
      category: 'custom',
      extension: 'topic',
      source: '<topic id="fixed-wrong-id" title="\${TITLE}"/>',
    );
    await tester.runAsync(
      () async => service.save(await service.read(), [invalidTemplate]),
    );
    final project = Directory(p.join(root.path, 'project'))..createSync();
    final tree = File(p.join(project.path, 'guide.tree'));
    const originalTree = '<instance-profile id="guide"/>\n';
    tree.writeAsStringSync(originalTree);
    var createAttempts = 0;

    await show(
      tester,
      WritersideTemplateDialog(
        existingIds: const {},
        previewBuilder: (_, template, title, filename) => Text(
          WritersideTemplateService.generate(
            template,
            title: title,
            id: filename,
          ),
        ),
        onCreate: (template, title, filename) async {
          createAttempts++;
          try {
            await const WritersideTopicCreator().create(
              WritersideTopicCreateTarget(
                rootPath: project.path,
                treePath: tree.path,
                topicsRootDir: 'topics',
                existingTopicIds: const {},
              ),
              WritersideTopicCreateRequest(
                title: title,
                fileName: '$filename.topic',
                format: WritersideTopicFormat.xml,
              ),
              initialSource: WritersideTemplateService.generate(
                template,
                title: title,
                id: filename,
              ),
            );
            return null;
          } on BusyMarkException catch (error) {
            return error.code;
          }
        },
      ),
    );
    await tester.tap(find.text('Broken XML ID'));
    await tester.pumpAndSettle();
    await tester.enterText(editableUnderKey('template-filename'), 'setup');
    await tester.tap(find.text('Create'));
    await settle(tester);

    expect(createAttempts, 1);
    expect(find.text('writerside.topic-file.root-id-mismatch'), findsOneWidget);
    expect(find.text('Create Topic from Template'), findsOneWidget);
    expect(
      File(p.join(project.path, 'topics', 'setup.topic')).existsSync(),
      isFalse,
    );
    expect(Directory(p.join(project.path, 'topics')).existsSync(), isFalse);
    expect(tree.readAsStringSync(), originalTree);
  });

  testWidgets(
    'save-as-template appears under Custom; edit, duplicate and delete preserve cancel',
    (tester) async {
      final topic = const WritersideTopicParser().parseMarkdown(
        filePath: '/topic.md',
        source: '# Authored\nBody',
        topicsRoot: '/',
      );
      await tester.runAsync(
        () => service.saveTopic(topic: topic, contextualTitle: 'Authored'),
      );
      await show(tester, const WritersideTemplatesEditor());
      expect(find.text('Writerside_topic.md'), findsOneWidget);
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(find.text('Writerside_topic (1).md'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Writerside_topic (1).md'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('template-editor-source')),
        'unsaved',
      );
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(
        (await tester.runAsync(service.read))!.entries.single.source,
        '# \${TITLE}\nBody',
      );
    },
  );

  testWidgets('stale settings reject OK and retain draft for recovery', (
    tester,
  ) async {
    await show(tester, const WritersideTemplatesEditor(createNew: true));
    await tester.enterText(editableUnderKey('template-editor-name'), 'Draft');
    await tester.enterText(
      find.byKey(const ValueKey('template-editor-source')),
      '# draft',
    );
    await tester.runAsync(
      () => service.saveTopic(
        topic: const WritersideTopicParser().parseMarkdown(
          filePath: '/other.md',
          source: '# Other',
          topicsRoot: '/',
        ),
        contextualTitle: 'Other',
      ),
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(
      find.text(
        'Templates changed in another window. Cancel and reopen the editor before editing again.',
      ),
      findsOneWidget,
    );
    expect(find.text('# draft'), findsOneWidget);
    expect(
      (await tester.runAsync(service.read))!.entries.single.name,
      'Writerside_other',
    );
  });

  testWidgets('Internal reset is staged, cancellable, and publishable', (
    tester,
  ) async {
    final builtin = (await tester.runAsync(service.bundled))!.firstWhere(
      (entry) => entry.name == 'Starter' && entry.extension == 'md',
    );
    final override = builtin.copyWith(source: '# Internal override');
    await tester.runAsync(
      () async => service.save(await service.read(), [override]),
    );

    await show(tester, WritersideTemplatesEditor(selectedId: builtin.id));
    final nameEntry = tester.widget<BusyMarkGroupedTextEntry>(
      find.byKey(const ValueKey('template-editor-name')),
    );
    expect(nameEntry.readOnly, isTrue);
    final reset = tester.widget<BusyMarkDialogButton>(
      find.widgetWithText(BusyMarkDialogButton, 'Reset'),
    );
    expect(reset.destructive, isFalse);
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('template-editor-source')),
          )
          .controller!
          .text,
      builtin.source,
    );
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Cancel'));
    await settle(tester);
    expect(
      (await tester.runAsync(service.read))!.entries.single.source,
      '# Internal override',
    );

    await tester.tap(find.text('Open'));
    await settle(tester);
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'Reset'));
    await tester.tap(find.widgetWithText(BusyMarkDialogButton, 'OK'));
    await settle(tester);
    expect((await tester.runAsync(service.read))!.entries, isEmpty);
  });

  for (final customFirst in [true, false]) {
    testWidgets(
      'Files and Internal Starter.md both save (custom first: $customFirst)',
      (tester) async {
        final builtin = (await tester.runAsync(service.bundled))!.firstWhere(
          (entry) => entry.name == 'Starter' && entry.extension == 'md',
        );
        const custom = WritersideTemplate(
          id: 'custom-starter',
          name: 'Starter',
          category: 'custom',
          extension: 'md',
          source: '# Custom',
        );
        await tester.runAsync(
          () async => service.save(await service.read(), [
            customFirst
                ? custom
                : builtin.copyWith(source: '# Internal override'),
          ]),
        );
        await show(
          tester,
          WritersideTemplatesEditor(
            createNew: !customFirst,
            selectedId: customFirst ? builtin.id : null,
          ),
        );
        if (!customFirst) {
          await tester.enterText(
            editableUnderKey('template-editor-name'),
            'Starter',
          );
        }
        await tester.enterText(
          find.byKey(const ValueKey('template-editor-source')),
          customFirst ? '# Internal override' : '# Custom',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await settle(tester);
        expect(find.text('File and Code Templates'), findsNothing);
        final entries = (await tester.runAsync(service.read))!.entries;
        expect(
          {
            for (final entry in entries)
              '${entry.category}:${entry.name}.${entry.extension}':
                  entry.source,
          },
          {
            'default:Starter.md': '# Internal override',
            'custom:Starter.md': '# Custom',
          },
        );
      },
    );
  }
}

class _FailingTemplateService extends WritersideTemplateService {
  @override
  Future<List<WritersideTemplate>> catalog() async => throw StateError('load');
}

Finder editableUnderKey(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(EditableText),
);

Future<void> settle(WidgetTester tester) async {
  // The real store uses async filesystem calls, not a synchronous fake.
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
