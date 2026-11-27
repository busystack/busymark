import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/speech/narration.dart';
import 'package:busymark/src/speech/speech_preferences.dart';
import 'package:busymark/src/speech/speech_provider.dart';
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
  return const NarrationProjection().project(
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
