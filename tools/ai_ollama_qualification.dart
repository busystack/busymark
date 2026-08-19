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
  const code = '''```dart
Iterable<String> releaseTags(Iterable<String> tags) sync* {
  for (final tag in tags) {
    if (tag.startsWith('release/')) yield tag.substring(8);
  }
}
```''';
  final codeStart = source.indexOf(code);

  AiRequest selection(String id, AiFeature feature, {String? instruction}) =>
      AiPromptBuilder.build(
        id: id,
        targetId: 'qualification:$id',
        provider: AiProviderKind.ollamaLocal,
        feature: feature,
        scope: AiScope.selection,
        input: paragraph,
        modelCandidates: [model],
        sourceRevision: 1,
        instruction: instruction,
        replacementOriginal: paragraph,
        documentSource: source,
        replacementStart: paragraphStart,
        replacementEnd: paragraphStart + paragraph.length,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
      );

  return [
    _Fixture('Rewrite', selection('rewrite', AiFeature.rewrite)),
    _Fixture('Shorten', selection('shorten', AiFeature.shorten)),
    _Fixture(
      'Change tone',
      selection(
        'tone',
        AiFeature.tone,
        instruction: 'neutral technical documentation',
      ),
    ),
    _Fixture(
      'Translate',
      selection('translate', AiFeature.translate, instruction: 'German'),
    ),
    _Fixture('Proofread', selection('proofread', AiFeature.proofread)),
    _Fixture(
      'Whole-document summary',
      AiPromptBuilder.build(
        id: 'summary',
        targetId: 'qualification:summary',
        provider: AiProviderKind.ollamaLocal,
        feature: AiFeature.summarize,
        scope: AiScope.document,
        input: source,
        modelCandidates: [model],
        sourceRevision: 1,
        documentSource: source,
        replacementOriginal: '',
        replacementStart: source.length,
        replacementEnd: source.length,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
      ),
    ),
    _Fixture(
      'Draft',
      AiPromptBuilder.build(
        id: 'draft',
        targetId: 'qualification:draft',
        provider: AiProviderKind.ollamaLocal,
        feature: AiFeature.draft,
        scope: AiScope.insertion,
        input: '- Ubuntu 24.04\n- 8 GB RAM\n- 20 GB free disk space',
        modelCandidates: [model],
        sourceRevision: 1,
        instruction: 'Write a concise deployment prerequisites section.',
        documentSource: source,
        replacementOriginal: '',
        replacementStart: source.length,
        replacementEnd: source.length,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
      ),
    ),
    _Fixture(
      'Explain fenced code',
      AiPromptBuilder.build(
        id: 'explain-code',
        targetId: 'qualification:explain-code',
        provider: AiProviderKind.ollamaLocal,
        feature: AiFeature.explainCode,
        scope: AiScope.codeBlock,
        input: code,
        modelCandidates: [model],
        sourceRevision: 1,
        documentSource: source,
        replacementOriginal: '',
        replacementStart: codeStart + code.length,
        replacementEnd: codeStart + code.length,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
      ),
    ),
    _Fixture(
      'Improve fenced code',
      AiPromptBuilder.build(
        id: 'improve-code',
        targetId: 'qualification:improve-code',
        provider: AiProviderKind.ollamaLocal,
        feature: AiFeature.improveCode,
        scope: AiScope.codeBlock,
        input: code,
        modelCandidates: [model],
        sourceRevision: 1,
        documentSource: source,
        replacementOriginal: code,
        replacementStart: codeStart,
        replacementEnd: codeStart + code.length,
        deadline: const Duration(minutes: 5),
        maxRetries: 0,
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
