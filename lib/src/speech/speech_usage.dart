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
  SpeechUsageLedger({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static final shared = SpeechUsageLedger();
  final Future<Directory> Function() _supportDirectory;

  Future<void> _pending = Future.value();

  Future<void> recordRequest(SpeechBackend backend, SpeechUsage? usage) {
    if (!backend.isCloud) return Future.value();
    final operation = _pending.then((_) => _update(backend, usage));
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _update(SpeechBackend backend, SpeechUsage? usage) async {
    final support = await _supportDirectory();
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
                    'requests',
                    'unreportedRequests',
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

      add('requests', 1);
      final counts = <String, int>{
        if (usage?.inputTokens case final count? when count >= 0)
          'inputTokens': count,
        if (usage?.outputTokens case final count? when count >= 0)
          'outputTokens': count,
        if (usage?.inputAudioTokens case final count? when count >= 0)
          'inputAudioTokens': count,
        if (usage?.outputAudioTokens case final count? when count >= 0)
          'outputAudioTokens': count,
        if (usage?.characters case final count? when count >= 0)
          'characters': count,
      };
      if (counts.isEmpty) add('unreportedRequests', 1);
      counts.forEach(add);
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
