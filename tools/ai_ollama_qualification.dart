import 'dart:async';
import 'dart:io';

import 'package:busymark/src/ai/ai_coordinator.dart';
import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ollama_ai_provider.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tools/ai_ollama_qualification.dart '
      '--model <installed-model> [--endpoint http://127.0.0.1:11434]',
    );
    exitCode = 64;
    return;
  }

  final client = http.Client();
  final provider = OllamaAiProvider(client: client, endpoint: options.endpoint);
  final coordinator = AiCoordinator(provider: provider);
  try {
    final healthToken = AiCancellationToken();
    try {
      final health = await provider.checkHealth(
        model: options.model,
        cancellationToken: healthToken,
      );
      stdout.writeln(
        'Generation verified: ${health.model.name}'
        '${health.model.inputTokenLimit == null ? '' : ' '
                  '(context ${health.model.inputTokenLimit})'}',
      );
    } finally {
      await healthToken.dispose();
    }

    for (final fixture in _fixtures(options.model)) {
      final output = StringBuffer();
      var completed = false;
      await for (final event in coordinator.stream(fixture.request)) {
        switch (event) {
          case AiTextDelta(:final text):
            output.write(text);
          case AiCompleted():
            completed = true;
          case AiStarted() || AiUsageEvent():
            break;
        }
      }
      if (!completed || output.toString().trim().isEmpty) {
        throw StateError('${fixture.name} returned no complete proposal.');
      }
      stdout
        ..writeln('\n[PASS] ${fixture.name}')
        ..writeln(output.toString().trim());
    }
    stdout.writeln('\nAll structural qualification cases passed.');
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('Qualification failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  } finally {
    await coordinator.dispose();
    client.close();
  }
}

List<_Fixture> _fixtures(String model) {
  const source = '''---
title: Release operations
---

# Release operations {#release-operations}

The documentation owner should carry out all of the release validation steps in the documented order so the published guide does not become inconsistent with the application.

Read the [operator guide][operations] and retain `release-report.json`.

| Environment | Approval |
| --- | --- |
| Production | Security reviewer |

<note title="Protected">Keep the rollback record.</note>

```dart
Iterable<String> releaseTags(Iterable<String> tags) sync* {
  for (final tag in tags) {
    if (tag.startsWith('release/')) yield tag.substring(8);
  }
}
```

[operations]: https://docs.example.test/operations
''';
  const paragraph =
      'The documentation owner should carry out all of the release validation steps in the documented order so the published guide does not become inconsistent with the application.';
  final paragraphStart = source.indexOf(paragraph);
  AiRequest edit({
    required String id,
    required String instruction,
    required AiEditTargetKind target,
    required AiEditContextKind context,
    required String input,
    required int replacementStart,
    required int replacementEnd,
    String replacementPrefix = '',
  }) => AiPromptBuilder.build(
    id: id,
    targetId: 'qualification:$id',
    provider: AiProviderKind.ollamaLocal,
    feature: AiFeature.editDocument,
    scope: AiScope.markdownEdit,
    input: input,
    modelCandidates: [model],
    sourceRevision: 1,
    instruction: instruction,
    editTarget: target,
    editContext: context,
    replacementOriginal: source.substring(replacementStart, replacementEnd),
    documentSource: source,
    replacementStart: replacementStart,
    replacementEnd: replacementEnd,
    replacementPrefix: replacementPrefix,
    trimReplacementOutput: target == AiEditTargetKind.insertAfterBlock,
    deadline: const Duration(minutes: 5),
    maxRetries: 0,
  );

  final sectionStart = source.indexOf('# Release operations');
  return [
    _Fixture(
      'Selection target and selection context',
      edit(
        id: 'selection',
        instruction: 'Rewrite for clarity without changing meaning.',
        target: AiEditTargetKind.selection,
        context: AiEditContextKind.selection,
        input: paragraph,
        replacementStart: paragraphStart,
        replacementEnd: paragraphStart + paragraph.length,
      ),
    ),
    _Fixture(
      'Block target and document context',
      edit(
        id: 'block',
        instruction: 'Proofread the target paragraph.',
        target: AiEditTargetKind.block,
        context: AiEditContextKind.document,
        input: source,
        replacementStart: paragraphStart,
        replacementEnd: paragraphStart + paragraph.length,
      ),
    ),
    _Fixture(
      'Section target and section context',
      edit(
        id: 'section',
        instruction:
            'Improve the prose while preserving every Markdown structure and protected construct exactly.',
        target: AiEditTargetKind.section,
        context: AiEditContextKind.section,
        input: source.substring(sectionStart),
        replacementStart: sectionStart,
        replacementEnd: source.length,
      ),
    ),
    _Fixture(
      'Insertion target without document context',
      edit(
        id: 'insertion',
        instruction:
            'Write a concise deployment prerequisites section for Ubuntu 24.04, 8 GB RAM, and 20 GB free disk space.',
        target: AiEditTargetKind.insertAfterBlock,
        context: AiEditContextKind.none,
        input: '',
        replacementStart: source.length,
        replacementEnd: source.length,
        replacementPrefix: '\n\n',
      ),
    ),
    _Fixture(
      'Document target',
      edit(
        id: 'document',
        instruction:
            'Proofread all prose while preserving every Markdown structure and protected construct exactly.',
        target: AiEditTargetKind.document,
        context: AiEditContextKind.document,
        input: source,
        replacementStart: 0,
        replacementEnd: source.length,
      ),
    ),
    _Fixture(
      'Staged-diff commit message',
      AiPromptBuilder.build(
        id: 'commit',
        targetId: 'qualification:commit',
        provider: AiProviderKind.ollamaLocal,
        feature: AiFeature.draftCommitMessage,
        scope: AiScope.gitDiff,
        input: '''diff --git a/guide.md b/guide.md
index 1111111..2222222 100644
--- a/guide.md
+++ b/guide.md
@@ -1 +1 @@
-# Deployment
+# Deployment prerequisites''',
        modelCandidates: [model],
        sourceRevision: 0,
        contentFormat: AiContentFormat.plainText,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
      ),
    ),
  ];
}

class _Fixture {
  const _Fixture(this.name, this.request);

  final String name;
  final AiRequest request;
}

class _Options {
  const _Options({required this.model, required this.endpoint});

  final String model;
  final String endpoint;

  static _Options? parse(List<String> arguments) {
    String? model;
    var endpoint = 'http://127.0.0.1:11434';
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (argument == '--model' && index + 1 < arguments.length) {
        model = arguments[++index].trim();
      } else if (argument == '--endpoint' && index + 1 < arguments.length) {
        endpoint = arguments[++index].trim();
      } else {
        return null;
      }
    }
    if (model == null || model.isEmpty) {
      return null;
    }
    return _Options(model: model, endpoint: endpoint);
  }
}
