import 'dart:convert';

import 'package:busymark/src/ai/ai_markdown_edit_resolver.dart';
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
        input: 'x' * 37000,
        model: 'model',
        sourceRevision: 1,
      ),
      throwsA(isA<AiException>()),
    );
  });

  test('token estimates are independent from UTF-8 transport bytes', () {
    expect(utf8.encode('Résumé 漢字 😀').length, greaterThan(11));
    expect(AiTokenEstimator.estimate('Résumé 漢字 😀'), 9);
    expect(AiTokenEstimator.estimate('abcdefghijkl'), 4);

    final request = AiPromptBuilder.build(
      id: 'translated-output',
      targetId: 'doc:translation',
      feature: AiFeature.translate,
      scope: AiScope.selection,
      input: 'Source prose.',
      model: 'model',
      sourceRevision: 1,
      instruction: 'Chinese',
    );
    final translated = '漢' * 2000;
    expect(
      utf8.encode(translated).length,
      greaterThan(request.maxOutputTokens),
    );
    expect(
      () => const AiMarkdownGuard().validate(request, translated),
      returnsNormally,
    );
  });

  test('generated-output byte limits are independent from provider tokens', () {
    final request = AiPromptBuilder.build(
      id: 'output-bytes',
      targetId: 'doc:output',
      feature: AiFeature.rewrite,
      scope: AiScope.selection,
      input: 'Source prose.',
      model: 'model',
      sourceRevision: 1,
    );
    final oversized = '😀' * ((AiPolicy.maxGeneratedOutputBytes ~/ 4) + 1);

    expect(
      () => const AiMarkdownGuard().validate(request, oversized),
      throwsA(
        isA<AiException>().having(
          (error) => error.code,
          'code',
          AiFailureCode.responseTooLarge,
        ),
      ),
    );
  });

  test('large summaries are split into token-bounded hierarchy stages', () {
    final source = '😀' * 30000;
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
        (chunk) => AiTokenEstimator.estimate(chunk) <= 12000,
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
        input: 'x' * 700000,
        model: 'model',
        sourceRevision: 1,
      ),
      throwsA(isA<AiException>()),
    );
  });

  group('Markdown AI edit ranges', () {
    const resolver = AiMarkdownEditResolver();

    test('Draft keeps selected notes and inserts after their block', () {
      const source = '# Plan\n\nUse these notes for the release.\n\nAfter.\n';
      final start = source.indexOf('Use these');
      final end = source.indexOf('\n\nAfter');
      final target = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: start,
        selectionEnd: end,
      );

      expect(target.scope, AiScope.insertion);
      expect(target.input, 'Use these notes for the release.');
      expect(target.replacementStart, target.replacementEnd);
      expect(target.replacementStart, source.indexOf('After.'));
      expect(target.replacementOriginal, isEmpty);
    });

    test('Draft at a cursor uses nearby context and a safe block boundary', () {
      const source = '''---
title: Guide
---

Paragraph context.

```text
protected
```

After.
''';
      final paragraphCursor = source.indexOf('context');
      final paragraphTarget = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: paragraphCursor,
        selectionEnd: paragraphCursor,
      );
      expect(paragraphTarget.input, 'Paragraph context.');
      expect(
        paragraphTarget.replacementStart,
        greaterThan(source.indexOf('Paragraph context.')),
      );

      final frontMatterCursor = source.indexOf('Guide');
      final frontMatterTarget = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: frontMatterCursor,
        selectionEnd: frontMatterCursor,
      );
      expect(frontMatterTarget.input, isEmpty);
      expect(
        frontMatterTarget.replacementStart,
        greaterThan(source.indexOf('---\n\nParagraph')),
      );
      final frontMatterOpeningTarget = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: 0,
        selectionEnd: 0,
      );
      expect(
        frontMatterOpeningTarget.replacementStart,
        frontMatterTarget.replacementStart,
      );

      final fenceCursor = source.indexOf('protected');
      final fenceTarget = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: fenceCursor,
        selectionEnd: fenceCursor,
      );
      expect(fenceTarget.input, isEmpty);
      expect(
        fenceTarget.replacementStart,
        greaterThan(source.indexOf('```\n\nAfter')),
      );
    });

    test('Summarise expands a partial selection to complete blocks', () {
      const source =
          'Read [the guide](https://example.test).\n\nNext paragraph.\n';
      final start = source.indexOf('the guide');
      final target = resolver.resolve(
        feature: AiFeature.summarize,
        source: source,
        selectionStart: start,
        selectionEnd: start + 3,
      );

      expect(target.replacementStart, 0);
      expect(target.input, 'Read [the guide](https://example.test).');
      expect(target.replacementOriginal, target.input);
    });

    test('Summarise rejects a partial front-matter selection', () {
      const source = '---\ntitle: Guide\n---\n\nBody.\n';
      final start = source.indexOf('Guide');

      expect(
        () => resolver.resolve(
          feature: AiFeature.summarize,
          source: source,
          selectionStart: start,
          selectionEnd: start + 3,
        ),
        throwsA(isA<AiException>()),
      );
    });

    test('replacement selections expand complete inline code constructs', () {
      const source = 'Use ``code ` value`` safely.\n';
      final start = source.indexOf('code');
      final target = resolver.resolve(
        feature: AiFeature.rewrite,
        source: source,
        selectionStart: start,
        selectionEnd: start + 4,
      );

      expect(target.input, '``code ` value``');
      expect(target.replacementStart, source.indexOf('``'));
    });

    test('replacement selections expand complete Markdown links', () {
      const source = 'Read [the guide](https://example.test) today.\n';
      final start = source.indexOf('the guide');
      final target = resolver.resolve(
        feature: AiFeature.rewrite,
        source: source,
        selectionStart: start,
        selectionEnd: start + 3,
      );

      expect(target.input, '[the guide](https://example.test)');
      expect(target.replacementStart, source.indexOf('['));
    });

    test('replacement selections reject protected raw blocks', () {
      const source = '<note>Protected</note>\n';
      final start = source.indexOf('Protected');
      expect(
        () => resolver.resolve(
          feature: AiFeature.rewrite,
          source: source,
          selectionStart: start,
          selectionEnd: start + 4,
        ),
        throwsA(isA<AiException>()),
      );
    });

    test('validation and application use the exact block insertion', () {
      const source = '# Heading\n\nParagraph.\n';
      final cursor = source.indexOf('Paragraph');
      final target = resolver.resolve(
        feature: AiFeature.draft,
        source: source,
        selectionStart: cursor,
        selectionEnd: cursor,
      );
      final request = AiPromptBuilder.build(
        id: 'safe-draft',
        targetId: 'doc:draft',
        feature: AiFeature.draft,
        scope: target.scope,
        input: target.input,
        model: 'model',
        sourceRevision: 1,
        instruction: 'Add a conclusion.',
        replacementOriginal: target.replacementOriginal,
        documentSource: source,
        replacementStart: target.replacementStart,
        replacementEnd: target.replacementEnd,
        replacementPrefix: target.replacementPrefix,
        replacementSuffix: target.replacementSuffix,
        trimReplacementOutput: target.trimReplacementOutput,
      );
      const output = '\nConclusion.\n';
      final exactReplacement = request.appliedReplacement(output);

      expect(
        exactReplacement,
        '${target.replacementPrefix}Conclusion.${target.replacementSuffix}',
      );
      expect(
        request.candidateDocument(output),
        source.replaceRange(
          target.replacementStart,
          target.replacementEnd,
          exactReplacement,
        ),
      );
      expect(
        () => const AiMarkdownGuard().validate(request, output),
        returnsNormally,
      );
    });
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
