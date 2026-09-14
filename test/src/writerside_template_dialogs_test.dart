import 'dart:io';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/workspace/presentation/writerside_template_dialogs.dart';
import 'package:busymark/src/writerside/writerside_template_service.dart';
import 'package:busymark/src/writerside/writerside_parsers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
  }) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          writersideTemplateServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
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
        await tester.tap(find.text('XML (.topic)'));
        await tester.enterText(
          find.byKey(const ValueKey('template-title')),
          'A & B',
        );
        await tester.enterText(
          find.byKey(const ValueKey('template-filename')),
          'existing',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        expect(created, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('template-filename')),
          '../bad',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Create'));
        expect(created, isNull);
        await tester.enterText(
          find.byKey(const ValueKey('template-filename')),
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

  testWidgets('Files editor stages new content, cancels and persists on OK', (
    tester,
  ) async {
    await show(tester, const WritersideTemplatesEditor(createNew: true));
    await tester.enterText(
      find.byKey(const ValueKey('template-editor-name')),
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
      find.byKey(const ValueKey('template-editor-name')),
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
    await tester.enterText(
      find.byKey(const ValueKey('template-editor-name')),
      'Draft',
    );
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
}

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
