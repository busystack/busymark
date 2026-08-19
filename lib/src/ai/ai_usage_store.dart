import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ai_models.dart';

class AiMonthlyUsage {
  const AiMonthlyUsage({
    required this.month,
    required this.requests,
    required this.inputTokens,
    required this.outputTokens,
    required this.byProvider,
  });

  factory AiMonthlyUsage.empty(DateTime now) => AiMonthlyUsage(
    month: _monthKey(now),
    requests: 0,
    inputTokens: 0,
    outputTokens: 0,
    byProvider: const {},
  );

  factory AiMonthlyUsage.fromJson(Map<String, Object?> json, DateTime now) {
    final expectedMonth = _monthKey(now);
    if (json['month'] != expectedMonth) {
      return AiMonthlyUsage.empty(now);
    }
    final rawProviders = json['byProvider'];
    return AiMonthlyUsage(
      month: expectedMonth,
      requests: _nonNegativeInt(json['requests']),
      inputTokens: _nonNegativeInt(json['inputTokens']),
      outputTokens: _nonNegativeInt(json['outputTokens']),
      byProvider: rawProviders is Map
          ? Map.unmodifiable({
              for (final entry in rawProviders.entries)
                if (entry.value is Map)
                  entry.key.toString(): AiProviderUsage.fromJson(
                    (entry.value as Map).cast<String, Object?>(),
                  ),
            })
          : const {},
    );
  }

  final String month;
  final int requests;
  final int inputTokens;
  final int outputTokens;
  final Map<String, AiProviderUsage> byProvider;

  AiMonthlyUsage add(AiUsage usage) {
    final provider = usage.providerId ?? 'unknown';
    final existing = byProvider[provider] ?? const AiProviderUsage();
    final input = usage.inputTokens ?? 0;
    final output = usage.outputTokens ?? 0;
    return AiMonthlyUsage(
      month: month,
      requests: requests + 1,
      inputTokens: inputTokens + input,
      outputTokens: outputTokens + output,
      byProvider: Map.unmodifiable({
        ...byProvider,
        provider: existing.add(input, output),
      }),
    );
  }

  Map<String, Object?> toJson() => {
    'month': month,
    'requests': requests,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'byProvider': {
      for (final entry in byProvider.entries) entry.key: entry.value.toJson(),
    },
  };
}

class AiProviderUsage {
  const AiProviderUsage({
    this.requests = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  factory AiProviderUsage.fromJson(Map<String, Object?> json) =>
      AiProviderUsage(
        requests: _nonNegativeInt(json['requests']),
        inputTokens: _nonNegativeInt(json['inputTokens']),
        outputTokens: _nonNegativeInt(json['outputTokens']),
      );

  final int requests;
  final int inputTokens;
  final int outputTokens;

  AiProviderUsage add(int input, int output) => AiProviderUsage(
    requests: requests + 1,
    inputTokens: inputTokens + input,
    outputTokens: outputTokens + output,
  );

  Map<String, Object?> toJson() => {
    'requests': requests,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
  };
}

class AiUsageStore {
  AiUsageStore({String? filePathOverride, DateTime Function()? clock})
    : _filePathOverride = filePathOverride,
      _clock = clock ?? DateTime.now;

  final String? _filePathOverride;
  final DateTime Function() _clock;
  Future<void> _pending = Future.value();

  Future<AiMonthlyUsage> read() async {
    final file = File(await _path());
    if (!await file.exists()) {
      return AiMonthlyUsage.empty(_clock());
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return AiMonthlyUsage.empty(_clock());
      }
      return AiMonthlyUsage.fromJson(decoded.cast<String, Object?>(), _clock());
    } on FileSystemException {
      return AiMonthlyUsage.empty(_clock());
    } on FormatException {
      return AiMonthlyUsage.empty(_clock());
    }
  }

  Future<void> record(AiUsage usage) {
    final previous = _pending;
    final operation = () async {
      await previous;
      final next = (await read()).add(usage);
      final path = await _path();
      final target = File(path);
      await target.parent.create(recursive: true);
      final staged = File('$path.tmp');
      await staged.writeAsString(jsonEncode(next.toJson()), flush: true);
      await staged.rename(path);
    }();
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  Future<String> _path() async {
    final override = _filePathOverride;
    if (override != null) {
      return override;
    }
    final support = await getApplicationSupportDirectory();
    return p.join(support.path, 'ai-usage.json');
  }
}

int _nonNegativeInt(Object? value) {
  final number = switch (value) {
    final int number => number,
    final num number => number.toInt(),
    _ => 0,
  };
  return number < 0 ? 0 : number;
}

String _monthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
