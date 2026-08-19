import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/ai/ai_models.dart';
import 'package:busymark/src/ai/ai_usage_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usage ledger aggregates locally by month and provider', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-ai-usage-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/usage.json';
    final store = AiUsageStore(
      filePathOverride: path,
      clock: () => DateTime.utc(2026, 8, 19),
    );

    await Future.wait([
      store.record(
        const AiUsage(
          inputTokens: 10,
          outputTokens: 4,
          providerId: 'openai',
          model: 'model-a',
        ),
      ),
      store.record(
        const AiUsage(
          inputTokens: 20,
          outputTokens: 6,
          providerId: 'gemini',
          model: 'model-b',
        ),
      ),
    ]);
    final usage = await store.read();

    expect(usage.month, '2026-08');
    expect(usage.requests, 2);
    expect(usage.inputTokens, 30);
    expect(usage.outputTokens, 10);
    expect(usage.byProvider['openai']?.requests, 1);
    expect(usage.byProvider['gemini']?.outputTokens, 6);
    final persisted = jsonDecode(await File(path).readAsString()) as Map;
    expect(persisted.toString(), isNot(contains('model-a')));
    expect(persisted.toString(), isNot(contains('document')));
  });

  test('usage ledger starts a clean aggregate in a new month', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-ai-usage-month-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/usage.json';
    var now = DateTime.utc(2026, 8, 31);
    final store = AiUsageStore(filePathOverride: path, clock: () => now);
    await store.record(
      const AiUsage(inputTokens: 8, outputTokens: 2, providerId: 'openai'),
    );

    now = DateTime.utc(2026, 9, 1);
    final usage = await store.read();

    expect(usage.month, '2026-09');
    expect(usage.requests, 0);
    expect(usage.inputTokens, 0);
  });

  test('malformed ledger data is treated as empty, not surfaced', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-ai-usage-corrupt-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/usage.json';
    await File(path).writeAsString('{broken');
    final store = AiUsageStore(
      filePathOverride: path,
      clock: () => DateTime.utc(2026, 8, 19),
    );

    expect((await store.read()).requests, 0);
    await store.record(
      const AiUsage(inputTokens: 1, outputTokens: 1, providerId: 'ollama'),
    );
    expect((await store.read()).requests, 1);
  });
}
