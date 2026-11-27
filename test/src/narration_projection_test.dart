import 'dart:io';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/speech/narration.dart';
import 'package:busymark/src/speech/speech_preferences.dart';
import 'package:busymark/src/speech/speech_provider.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

NarrationPlan project(
  String source, {
  NarrationScope scope = NarrationScope.document,
  NarrationRules rules = const NarrationRules(),
  int anchor = 0,
  int start = 0,
  int end = 0,
}) {
  final document = const MarkdownParser()
      .parse(
        filePath: 'draft.md',
        source: source,
        mode: MarkdownMode.gfm,
        validateLocalReferences: false,
      )
      .busyDocument;
  return projectDocument(
    document,
    source,
    scope: scope,
    rules: rules,
    anchor: anchor,
    start: start,
    end: end,
  );
}

NarrationPlan projectDocument(
  BusyDocument document,
  String source, {
  NarrationScope scope = NarrationScope.document,
  NarrationRules rules = const NarrationRules(),
  int anchor = 0,
  int start = 0,
  int end = 0,
}) => const NarrationProjection().project(
  document: document,
  capturedSource: source,
  documentId: 'document',
  providerId: 'filesystem',
  revision: 7,
  scope: scope,
  anchor: anchor,
  selectionStart: start,
  selectionEnd: end,
  rules: rules,
  completedTask: 'Done.',
  incompleteTask: 'Open.',
);

Future<BusyDocument> resolvedTopic(String source) async {
  final root = await Directory.systemTemp.createTemp('busymark-xml-speech-');
  addTearDown(() => root.delete(recursive: true));
  await Directory('${root.path}/topics').create();
  await File('${root.path}/writerside.cfg').writeAsString(
    '<ihp><topics dir="topics"/><instance src="web.tree"/></ihp>',
  );
  await File('${root.path}/web.tree').writeAsString(
    '<instance-profile id="web" name="Web" start-page="main.topic">'
    '<toc-element topic="main.topic"/></instance-profile>',
  );
  await File('${root.path}/topics/shared.topic').writeAsString(
    '<topic id="shared" title="Library"><snippet id="example">'
    '<p>Shared example.</p><p instance="!web">Unavailable include.</p>'
    '</snippet></topic>',
  );
  const saved = '<topic id="main" title="Main"><p>Saved.</p></topic>';
  final topic = await File(
    '${root.path}/topics/main.topic',
  ).writeAsString(saved);
  const service = WorkspaceService();
  final workspace = await service.openPath(root.path);
  final document = await service.buildNarrationDocument(
    workspace.copyWith(activeFilePath: topic.path),
    DocumentBuffer(
      id: 'draft',
      filePath: topic.path,
      text: source,
      lastSavedText: saved,
      dirty: true,
      revision: 7,
    ),
  );
  expect(await topic.readAsString(), saved);
  return document!;
}

void main() {
  test('narrates semantic content with structure and records omissions', () {
    const source = '''
---
lang: fr
private: Hidden key
---

# Bonjour

**Marie** aime [la musique](https://example.org/private). `Bonjour()`.

> Les oiseaux chantent.

- [x] Course
- [ ] Retour

| Ville | Numéro |
| --- | --- |
| Paris | 12 |

![Un chat](chat.png)

<!-- Hidden comment. -->

```text
Private code.
```

<audio controls src="secret.wav"><a href="secret.wav">Download</a></audio>

[The longer transcript](transcript.md)
''';
    final plan = project(source);
    expect(plan.passages.map((entry) => entry.speech.text), [
      'Bonjour',
      'Marie aime la musique. Bonjour().',
      'Les oiseaux chantent.',
      'Done. Course',
      'Open. Retour',
      'Ville. Paris. Numéro. 12',
      'Un chat',
      'The longer transcript',
    ]);
    expect(
      plan.passages.first.speech.pauseAfter,
      const Duration(milliseconds: 450),
    );
    expect(
      plan.passages.every((entry) => entry.speech.language == 'fr'),
      isTrue,
    );
    expect(
      plan.omissions,
      containsAll([
        NarrationOmission.hidden,
        NarrationOmission.media,
        NarrationOmission.code,
      ]),
    );
    expect(plan.revision, 7);
  });

  test('section ends at the next heading at the same or higher level', () {
    const source =
        '# Before\n\nOutside.\n\n## In scope\n\nFirst.\n\n### Child\n\nSecond.\n\n## Next\n\nOutside again.\n';
    final plan = project(
      source,
      scope: NarrationScope.section,
      anchor: source.indexOf('First.'),
    );
    expect(plan.text, 'In scope\n\nFirst.\n\nChild\n\nSecond.');
    expect(plan.insertionOffset, source.indexOf('## Next'));
  });

  test('partial selections exclude adjacent prose and formatting syntax', () {
    const source =
        'First **bold éclair** and [label](https://example.com) lasts.';
    final plan = project(
      source,
      scope: NarrationScope.selection,
      start: source.indexOf('éclair'),
      end: source.indexOf('label') + 3,
    );
    expect(plan.text, 'éclair and lab');
  });

  test('link and quote rules never read metadata or bare links by default', () {
    const source =
        '> quote\n\nRead [the article](https://a.test) and <https://b.test>.';
    expect(project(source).text, 'quote\n\nRead the article and .');
    final options = project(
      source,
      rules: const NarrationRules(
        links: NarrationLinks.labelAndUrl,
        quotes: false,
      ),
    );
    expect(options.text, 'Read the article https://a.test and https://b.test.');
    expect(options.omissions, contains(NarrationOmission.quotes));
  });

  test(
    'resolved Writerside narrates one switcher variant and one tab per group',
    () async {
      const source = '''<topic id="main" title="Main" switcher-label="Platform">
  <p switcher-key="Unix">Shell.</p><p switcher-key="Windows">PowerShell.</p>
  <p>Use <b switcher-key="Unix">Terminal</b><b switcher-key="Windows">Console</b>.</p>
  <chapter switcher-key="Windows" title="Other chapter"><p>Other body.</p></chapter>
  <p>Shared instructions.</p>
  <p instance="!web">Other instance.</p>
  <include from="shared.topic" element-id="example"/>
  <tabs group="platform">
    <tab title="Shell" group-key="sh"><p>First command.</p></tab>
    <tab title="PowerShell" group-key="ps"><p>Unused command.</p></tab>
  </tabs>
  <tabs group="platform">
    <tab title="PowerShell" group-key="ps"><p>Unused output.</p></tab>
    <tab title="Shell" group-key="sh"><p>First output.</p></tab>
  </tabs>
  <chapter title="Details" collapsible="true"><p>Collapsed chapter.</p></chapter>
  <deflist collapsible="true"><def title="Term"><p>Definition.</p></def></deflist>
  <code-block collapsible="true" lang="text">Hidden code by default.</code-block>
</topic>''';
      final document = await resolvedTopic(source);
      final plan = projectDocument(document, source);
      expect(
        plan.text,
        [
          'Shell.',
          'Use Terminal.',
          'Shared instructions.',
          'Shared example.',
          'Shell',
          'First command.',
          'Shell',
          'First output.',
          'Details',
          'Collapsed chapter.',
          'Term',
          'Definition.',
        ].join('\n\n'),
      );
      expect(
        plan.omissions,
        containsAll([NarrationOmission.hidden, NarrationOmission.code]),
      );
      final inactive = projectDocument(
        document,
        source,
        scope: NarrationScope.block,
        anchor: source.indexOf('Unused output.'),
      );
      expect(inactive.text, isEmpty);
      expect(inactive.omissions, contains(NarrationOmission.hidden));
    },
  );

  test(
    'Writerside XML scopes follow nested chapters and the deepest block',
    () async {
      const source = '''<topic id="main" title="Main">
  <p>Before chapters.</p>
  <chapter title="Outer">
    <p>First outer.</p>
    <chapter title="Inner">
      <p>First inner.</p><p>Second inner.</p>
    </chapter>
    <p>Second outer.</p>
  </chapter>
  <chapter title="Next"><p>Next chapter.</p></chapter>
  <p>After chapters.</p>
</topic>''';
      final document = await resolvedTopic(source);
      NarrationPlan at(
        String anchor,
        NarrationScope scope, {
        NarrationRules rules = const NarrationRules(),
      }) => projectDocument(
        document,
        source,
        anchor: source.indexOf(anchor),
        scope: scope,
        rules: rules,
      );
      expect(at('Second inner.', NarrationScope.block).text, 'Second inner.');
      final inner = at('Second inner.', NarrationScope.section);
      expect(inner.text, 'Inner\n\nFirst inner.\n\nSecond inner.');
      expect(
        inner.insertionOffset,
        source.indexOf('</chapter>') + '</chapter>'.length,
      );
      expect(
        at('First outer.', NarrationScope.section).text,
        'Outer\n\nFirst outer.\n\nInner\n\nFirst inner.\n\nSecond inner.\n\nSecond outer.',
      );
      expect(
        at('Before chapters.', NarrationScope.section).text,
        'Before chapters.',
      );
      expect(
        at('After chapters.', NarrationScope.section).text,
        'After chapters.',
      );
      expect(
        at(
          'First inner.',
          NarrationScope.section,
          rules: const NarrationRules(headings: false),
        ).text,
        'First inner.\n\nSecond inner.',
      );
    },
  );

  test(
    'Writerside XML clips formatted text and reports unmapped substitutions',
    () async {
      const source = '''<topic id="main" title="Main">
  <var name="secret" value="Substituted content"/>
  <chapter title="Scoped"><p>Earlier <b>éclair</b> and <i>chocolat</i> later.</p>
  <p><b>%secret%</b><i> safe.</i></p></chapter>
</topic>''';
      final document = await resolvedTopic(source);
      expect(
        projectDocument(document, source).text,
        'Scoped\n\nEarlier éclair and chocolat later.\n\nSubstituted content safe.',
      );
      NarrationPlan select(int start, int end) => projectDocument(
        document,
        source,
        scope: NarrationScope.selection,
        start: start,
        end: end,
      );
      final start = source.indexOf('éclair') + 1;
      final end = source.indexOf('chocolat') + 4;
      final formatted = select(start, end);
      expect(formatted.text, 'clair and choc');
      expect(formatted.passages.single.source!.startOffset, start);
      expect(formatted.passages.single.source!.endOffset, end);
      expect(
        formatted.omissions,
        isNot(contains(NarrationOmission.unmappedSelection)),
      );
      final title = source.indexOf('Scoped');
      expect(select(title, title + 5).text, 'Scope');

      final ambiguous = select(
        source.indexOf('%secret%') + 1,
        source.indexOf(' safe.') + ' safe.'.length,
      );
      expect(ambiguous.text, 'safe.');
      expect(
        ambiguous.omissions,
        contains(NarrationOmission.unmappedSelection),
      );
    },
  );

  test('speech settings round-trip without changing the text provider', () {
    final original = AppSettings.defaults().copyWith(
      aiProviderPreference: AiProviderPreference.ollamaLocal,
      speech: const SpeechPreferences(
        backend: SpeechBackend.espeak,
        audioDirectory: 'recitals',
        outputName: 'French example.wav',
        providers: {
          SpeechBackend.espeak: SpeechOptions(
            voice: 'fr',
            speed: 0.9,
            pitch: 40,
          ),
        },
        narration: NarrationRules(footnotes: true, inlineCode: false),
      ),
    );
    final restored = AppSettings.fromJson(original.toJson());
    expect(restored.aiProviderPreference, AiProviderPreference.ollamaLocal);
    expect(restored.speech.options.voice, 'fr');
    expect(restored.speech.options.speed, 0.9);
    expect(restored.speech.options.pitch, 40);
    expect(restored.speech.narration.footnotes, true);
    expect(restored.speech.narration.inlineCode, false);
    expect(restored.speech.audioDirectory, 'recitals');
    expect(restored.speech.outputName, 'French example.wav');
    expect(AppSettings.fromJson({}).speech.backend, SpeechBackend.espeak);
  });
}
