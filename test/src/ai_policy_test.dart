import 'dart:convert';

import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_policy.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI editing is enabled only for Markdown document kinds', () {
    expect(DocumentKind.markdown.supportsAiMarkdownEditing, isTrue);
    expect(
      DocumentKind.writersideMarkdownTopic.supportsAiMarkdownEditing,
      isTrue,
    );
    for (final kind in [
      DocumentKind.writersideXmlTopic,
      DocumentKind.tree,
      DocumentKind.config,
      DocumentKind.variables,
      DocumentKind.categories,
      DocumentKind.resource,
      DocumentKind.unknown,
      DocumentKind.image,
    ]) {
      expect(kind.supportsAiMarkdownEditing, isFalse, reason: kind.name);
    }
  });

  group('Markdown preservation', () {
    const document = '''---
title: Stable title
---

# Guide {#stable-id}

Read [alpha][guide] and [beta](https://example.test/beta). See <https://example.test/auto>.

Use ``code ` value`` and [^note].

| Name | Value |
| --- | --- |
| A | B |

<note title="Keep me">Writerside markup</note>

```dart
print('safe');
```

[guide]: https://example.test/guide
[^note]: Stable footnote.
''';

    test('accepts a prose-only replacement in the complete document', () {
      final start = document.indexOf('Read');
      const original =
          'Read [alpha][guide] and [beta](https://example.test/beta). See <https://example.test/auto>.';
      const replacement =
          'Consult [alpha][guide] and [beta](https://example.test/beta). See <https://example.test/auto>.';
      final request = _selectionRequest(
        source: document,
        start: start,
        end: start + original.length,
        input: original,
      );

      expect(
        () => const AiMarkdownGuard().validate(request, replacement),
        returnsNormally,
      );
    });

    test('rejects swapped URL associations even when the URL set is equal', () {
      const source = '[A](https://one.test) [B](https://two.test)';
      final request = _selectionRequest(
        source: source,
        start: 0,
        end: source.length,
        input: source,
      );

      expect(
        () => const AiMarkdownGuard().validate(
          request,
          '[A](https://two.test) [B](https://one.test)',
        ),
        throwsA(isA<AiException>()),
      );
    });

    test(
      'full-document validation catches edits made inside protected syntax',
      () {
        final destinationStart = document.indexOf('https://example.test/beta');
        final request = _selectionRequest(
          source: document,
          start: destinationStart,
          end: destinationStart + 'https://example.test/beta'.length,
          input: 'https://example.test/beta',
        );

        expect(
          () => const AiMarkdownGuard().validate(
            request,
            'https://attacker.test',
          ),
          throwsA(isA<AiException>()),
        );
      },
    );

    test(
      'protects front matter, references, footnotes, tables, HTML and IDs',
      () {
        final request = _selectionRequest(
          source: document,
          start: 0,
          end: document.length,
          input: document,
        );
        final mutations = [
          document.replaceFirst('Stable title', 'Changed title'),
          document.replaceFirst('[alpha][guide]', '[alpha][other]'),
          document.replaceFirst('[^note]', '[^renamed]'),
          document.replaceFirst('| A | B |', '| A | Changed |'),
          document.replaceFirst('title="Keep me"', 'title="Changed"'),
          document.replaceFirst('{#stable-id}', '{#changed-id}'),
          document.replaceFirst('``code ` value``', '``changed ` value``'),
        ];

        for (final mutation in mutations) {
          expect(
            () => const AiMarkdownGuard().validate(request, mutation),
            throwsA(isA<AiException>()),
            reason: mutation,
          );
        }
      },
    );

    test('protects list and heading structure', () {
      const source = '# Heading\n\n- First\n- Second\n';
      final request = _selectionRequest(
        source: source,
        start: 0,
        end: source.length,
        input: source,
      );

      expect(
        () => const AiMarkdownGuard().validate(
          request,
          'Heading\n\nFirst\n\nSecond\n',
        ),
        throwsA(isA<AiException>()),
      );
    });

    test('protects implicit heading identifiers from prose rewrites', () {
      const source = '# Stable heading\n\nSee [the section](#stable-heading).';
      const original = 'Stable heading';
      final start = source.indexOf(original);
      final request = _selectionRequest(
        source: source,
        start: start,
        end: start + original.length,
        input: original,
      );

      expect(
        () => const AiMarkdownGuard().validate(request, 'Changed heading'),
        throwsA(isA<AiException>()),
      );
    });

    test(
      'Improve code may change exactly one fenced block, not its language',
      () {
        const source = 'Before.\n\n```dart\nfinal x = 1;\n```\n\nAfter.\n';
        final start = source.indexOf('```dart');
        final end = source.indexOf('```\n\nAfter') + 4;
        final request = AiPromptBuilder.build(
          id: 'improve',
          targetId: 'doc:code',
          feature: AiFeature.improveCode,
          scope: AiScope.codeBlock,
          input: source.substring(start, end),
          model: 'model',
          sourceRevision: 1,
          replacementOriginal: source.substring(start, end),
          documentSource: source,
          replacementStart: start,
          replacementEnd: end,
        );

        expect(
          () => const AiMarkdownGuard().validate(
            request,
            '```dart\nconst x = 1;\n```\n',
          ),
          returnsNormally,
        );
        expect(
          () => const AiMarkdownGuard().validate(
            request,
            '```python\nx = 1\n```\n',
          ),
          throwsA(isA<AiException>()),
        );
      },
    );
  });

  test('selection prompts never attach the surrounding document', () {
    const source = 'Private prefix. Selected text. Private suffix.';
    final start = source.indexOf('Selected');
    final request = AiPromptBuilder.build(
      id: 'minimized',
      targetId: 'doc:selection',
      feature: AiFeature.rewrite,
      scope: AiScope.selection,
      input: 'Selected text.',
      model: 'model',
      sourceRevision: 1,
      documentSource: source,
      replacementStart: start,
      replacementEnd: start + 'Selected text.'.length,
    );
    final data = jsonDecode(request.userPrompt) as Map<String, Object?>;

    expect(data['document_data'], 'Selected text.');
    expect(request.userPrompt, isNot(contains('Private prefix')));
    expect(request.userPrompt, isNot(contains('Private suffix')));
  });

  test('instructions and direct prompts have explicit token budgets', () {
    expect(
      () => AiPromptBuilder.build(
        id: 'instruction-limit',
        targetId: 'doc:selection',
        feature: AiFeature.translate,
        scope: AiScope.selection,
        input: 'Text',
        model: 'model',
        sourceRevision: 1,
        instruction: 'x' * 2001,
      ),
      throwsA(isA<AiException>()),
    );
    expect(
      () => AiPromptBuilder.build(
        id: 'prompt-limit',
        targetId: 'doc:selection',
        feature: AiFeature.rewrite,
        scope: AiScope.selection,
        input: 'x' * 13000,
        model: 'model',
        sourceRevision: 1,
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('large summaries are split into UTF-8 bounded hierarchy stages', () {
    final source = '😀' * 12000;
    final request = AiPromptBuilder.build(
      id: 'hierarchy',
      targetId: 'doc:summary',
      feature: AiFeature.summarize,
      scope: AiScope.document,
      input: source,
      model: 'model',
      sourceRevision: 1,
    );

    expect(request.hierarchicalChunks.length, greaterThan(1));
    expect(
      request.hierarchicalChunks.every(
        (chunk) => AiTokenEstimator.conservative(chunk) <= 12000,
      ),
      isTrue,
    );
    expect(
      request.estimatedTotalPromptTokens,
      lessThanOrEqualTo(request.maxTotalInputTokens),
    );
    expect(() => AiPolicy.validateRequest(request), returnsNormally);
  });

  test('hierarchical summaries enforce a total request budget', () {
    expect(
      () => AiPromptBuilder.build(
        id: 'hierarchy-limit',
        targetId: 'doc:summary',
        feature: AiFeature.summarize,
        scope: AiScope.document,
        input: 'x' * 220000,
        model: 'model',
        sourceRevision: 1,
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('commit proposals require a bounded subject and blank separator', () {
    final request = AiPromptBuilder.build(
      id: 'commit',
      targetId: 'git:commit',
      feature: AiFeature.draftCommitMessage,
      scope: AiScope.gitDiff,
      input: 'diff --git a/a.md b/a.md',
      model: 'model',
      sourceRevision: 0,
      contentFormat: AiContentFormat.plainText,
    );

    expect(
      () => const AiMarkdownGuard().validate(
        request,
        'Improve documentation\n\nClarify the setup steps.',
      ),
      returnsNormally,
    );
    expect(
      () => const AiMarkdownGuard().validate(
        request,
        'Improve documentation\nBody without blank separator.',
      ),
      throwsA(isA<AiException>()),
    );
    expect(
      () => const AiMarkdownGuard().validate(request, 'x' * 73),
      throwsA(isA<AiException>()),
    );
  });
}

AiRequest _selectionRequest({
  required String source,
  required int start,
  required int end,
  required String input,
}) => AiPromptBuilder.build(
  id: 'selection',
  targetId: 'doc:$start:$end',
  feature: AiFeature.rewrite,
  scope: AiScope.selection,
  input: input,
  model: 'model',
  sourceRevision: 1,
  replacementOriginal: source.substring(start, end),
  documentSource: source,
  replacementStart: start,
  replacementEnd: end,
);
