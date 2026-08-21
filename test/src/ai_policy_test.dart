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
  });

  test(
    'the prompt contains only the context explicitly selected by the user',
    () {
      const source = 'Private prefix. Selected text. Private suffix.';
      final start = source.indexOf('Selected');
      final request = _selectionRequest(
        source: source,
        start: start,
        end: start + 'Selected text.'.length,
        input: 'Selected text.',
      );
      final data = jsonDecode(request.userPrompt) as Map<String, Object?>;

      expect(data['document_data'], 'Selected text.');
      expect(request.userPrompt, isNot(contains('Private prefix')));
      expect(request.userPrompt, isNot(contains('Private suffix')));
    },
  );

  test('instructions and direct prompts have explicit token budgets', () {
    expect(
      () => _editRequest(input: 'Text', instruction: 'x' * 2001),
      throwsA(isA<AiException>()),
    );
    expect(() => _editRequest(input: 'x' * 73000), throwsA(isA<AiException>()));
  });

  test('token estimates are independent from UTF-8 transport bytes', () {
    expect(utf8.encode('Résumé 漢字 😀').length, greaterThan(11));
    expect(AiTokenEstimator.estimate('Résumé 漢字 😀'), 9);
    expect(AiTokenEstimator.estimate('abcdefghijkl'), 4);

    final request = _editRequest(input: 'Source prose.');
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
    final request = _editRequest(input: 'Source prose.');
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

  group('user-selected Markdown target and context', () {
    const resolver = AiMarkdownEditResolver();
    const source =
        '# First\n\nAlpha paragraph.\n\n## Child\n\nBeta paragraph.\n\n# Second\n\nGamma.\n';

    test('selection target and block context remain independent', () {
      final start = source.indexOf('Alpha');
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.selection,
        editContext: AiEditContextKind.block,
        source: source,
        selectionStart: start,
        selectionEnd: start + 'Alpha'.length,
        anchorOffset: start,
      );

      expect(target.replacementOriginal, 'Alpha');
      expect(target.input, 'Alpha paragraph.');
    });

    test('insert-after-block target can send no document context', () {
      final cursor = source.indexOf('Alpha');
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.insertAfterBlock,
        editContext: AiEditContextKind.none,
        source: source,
        selectionStart: cursor,
        selectionEnd: cursor,
        anchorOffset: cursor,
      );

      expect(target.input, isEmpty);
      expect(target.replacementStart, target.replacementEnd);
      expect(target.replacementStart, source.indexOf('## Child'));
    });

    test('current block can use complete-document context', () {
      final cursor = source.indexOf('Beta');
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.block,
        editContext: AiEditContextKind.document,
        source: source,
        selectionStart: cursor,
        selectionEnd: cursor,
        anchorOffset: cursor,
      );

      expect(target.replacementOriginal, 'Beta paragraph.');
      expect(target.input, source);
    });

    test('current section includes descendants but not its sibling', () {
      final cursor = source.indexOf('Alpha');
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.section,
        editContext: AiEditContextKind.section,
        source: source,
        selectionStart: cursor,
        selectionEnd: cursor,
        anchorOffset: cursor,
      );

      expect(target.replacementOriginal, contains('## Child'));
      expect(target.replacementOriginal, contains('Beta paragraph.'));
      expect(target.replacementOriginal, isNot(contains('# Second')));
      expect(target.input, target.replacementOriginal);
    });

    test('complete-document target is explicit', () {
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.document,
        editContext: AiEditContextKind.none,
        source: source,
        selectionStart: 0,
        selectionEnd: 0,
        anchorOffset: 0,
      );

      expect(target.replacementStart, 0);
      expect(target.replacementEnd, source.length);
      expect(target.replacementOriginal, source);
    });

    test('partial protected selections are rejected instead of expanded', () {
      const linked = 'Read [the guide](https://example.test).\n';
      final start = linked.indexOf('the guide');
      expect(
        () => resolver.resolve(
          editTarget: AiEditTargetKind.selection,
          editContext: AiEditContextKind.selection,
          source: linked,
          selectionStart: start,
          selectionEnd: start + 3,
          anchorOffset: start,
        ),
        throwsA(isA<AiException>()),
      );
    });

    test('validation and application use the exact block insertion', () {
      final cursor = source.indexOf('Gamma');
      final target = resolver.resolve(
        editTarget: AiEditTargetKind.insertAfterBlock,
        editContext: AiEditContextKind.block,
        source: source,
        selectionStart: cursor,
        selectionEnd: cursor,
        anchorOffset: cursor,
      );
      final request = AiPromptBuilder.build(
        id: 'safe-insertion',
        targetId: 'doc:insertion',
        feature: AiFeature.editDocument,
        scope: target.scope,
        input: target.input,
        model: 'model',
        sourceRevision: 1,
        editTarget: target.editTarget,
        editContext: target.editContext,
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
  feature: AiFeature.editDocument,
  scope: AiScope.markdownEdit,
  input: input,
  model: 'model',
  sourceRevision: 1,
  editTarget: AiEditTargetKind.selection,
  editContext: AiEditContextKind.selection,
  instruction: 'Rewrite for clarity.',
  replacementOriginal: source.substring(start, end),
  documentSource: source,
  replacementStart: start,
  replacementEnd: end,
);

AiRequest _editRequest({
  required String input,
  String instruction = 'Translate into Chinese.',
}) => AiPromptBuilder.build(
  id: 'edit',
  targetId: 'doc:edit',
  feature: AiFeature.editDocument,
  scope: AiScope.markdownEdit,
  input: input,
  model: 'model',
  sourceRevision: 1,
  editTarget: AiEditTargetKind.selection,
  editContext: AiEditContextKind.selection,
  instruction: instruction,
);
