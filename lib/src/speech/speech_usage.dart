import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'speech_provider.dart';

Uri? speechPricingPage(SpeechBackend backend) => switch (backend) {
  SpeechBackend.gemini => Uri.parse(
    'https://aistudio.google.com/docs/pricing#gemini-3.8-flash-tts',
  ),
  SpeechBackend.openai => Uri.parse(
    'https://developers.openai.com/api/docs/models/gpt-realtime-2.1-mini#pricing',
  ),
  SpeechBackend.elevenLabs => Uri.parse('https://elevenlabs.io/pricing/api'),
  _ => null,
};

/// Aggregates provider counts only. Missing reports remain separate from
/// observed zero usage. No text, audio, server identifiers or keys are stored.
class SpeechUsageLedger {
  SpeechUsageLedger._();
  static final shared = SpeechUsageLedger._();

  Future<void> _pending = Future.value();

  Future<void> record(SpeechBackend backend, SpeechResult? result) {
    if (!backend.isCloud) return Future.value();
    final operation = _pending.then((_) => _update(backend, result));
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _update(SpeechBackend backend, SpeechResult? result) async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final target = File(p.join(support.path, 'speech-usage.json'));
    final lock = await File('${target.path}.lock').open(mode: FileMode.append);
    await lock.lock(FileLock.blockingExclusive);
    try {
      final now = DateTime.now().toUtc();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final records = <String, Object?>{'month': month};
      if (await target.exists() && await target.length() <= 65536) {
        try {
          final existing = jsonDecode(await target.readAsString());
          if (existing is Map && existing['month'] == month) {
            for (final kind in SpeechBackend.values.where(
              (value) => value.isCloud,
            )) {
              if (existing[kind.name] case final Map saved) {
                records[kind.name] = {
                  for (final field in [
                    'jobs',
                    'unreportedJobs',
                    'inputTokens',
                    'outputTokens',
                    'inputAudioTokens',
                    'outputAudioTokens',
                    'characters',
                  ])
                    if (saved[field] is int) field: saved[field],
                };
              }
            }
          }
        } on FormatException {
          // A damaged local ledger does not authenticate provider usage.
        }
      }
      final current = records[backend.name] as Map<String, Object?>? ?? {};
      void add(String key, int value) {
        final prior = current[key];
        current[key] = (prior is int && prior >= 0 ? prior : 0) + value;
      }

      add('jobs', 1);
      final reported = result?.usage ?? const <SpeechUsage>[];
      if (reported.isEmpty ||
          reported.any(
            (usage) =>
                usage.inputTokens == null &&
                usage.outputTokens == null &&
                usage.inputAudioTokens == null &&
                usage.outputAudioTokens == null &&
                usage.characters == null,
          )) {
        add('unreportedJobs', 1);
      }
      for (final usage in reported) {
        for (final (key, value) in [
          ('inputTokens', usage.inputTokens),
          ('outputTokens', usage.outputTokens),
          ('inputAudioTokens', usage.inputAudioTokens),
          ('outputAudioTokens', usage.outputAudioTokens),
          ('characters', usage.characters),
        ]) {
          if (value != null && value >= 0) add(key, value);
        }
      }
      records[backend.name] = current;
      final staged = File('${target.path}.tmp');
      await staged.writeAsString(jsonEncode(records), flush: true);
      await staged.rename(target.path);
    } finally {
      try {
        await lock.unlock();
      } finally {
        await lock.close();
      }
    }
  }
}
