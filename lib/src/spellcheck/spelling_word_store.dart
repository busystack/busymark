import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:unorm_dart/unorm_dart.dart' as unicode;

import '../core/atomic_file_writer.dart';
import 'spelling_language.dart';

final class SpellingWordEntry {
  const SpellingWordEntry({required this.key, required this.display});

  final String key;
  final String display;

  Map<String, Object?> toJson() => {'key': key, 'display': display};
}

final class SpellingWordStoreSnapshot {
  const SpellingWordStoreSnapshot({
    required this.revision,
    required this.wordsByLanguage,
    this.projectLanguage,
  });

  final int revision;
  final Map<String, List<SpellingWordEntry>> wordsByLanguage;
  final String? projectLanguage;

  Iterable<String> wordsFor(String languageId) =>
      wordsByLanguage[languageId]?.map((entry) => entry.display) ?? const [];
}

/// A serialized, atomic JSON word store. Each mutation rereads the current
/// file, so independent external additions and removals are not overwritten by
/// a stale in-memory snapshot.
final class SpellingWordStore {
  SpellingWordStore({
    required this.filePath,
    this.projectStore = false,
    AtomicFileWriter writer = const AtomicFileWriter(),
  }) : _writer = writer;

  final String filePath;
  final bool projectStore;
  final AtomicFileWriter _writer;
  Future<void> _writeTail = Future<void>.value();

  Future<SpellingWordStoreSnapshot> read() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const SpellingWordStoreSnapshot(revision: 0, wordsByLanguage: {});
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        throw const FormatException('Unsupported spelling word-store schema.');
      }
      final words = <String, List<SpellingWordEntry>>{};
      final rawWords = decoded['words'];
      if (rawWords is Map) {
        for (final entry in rawWords.entries) {
          final language = normalizeSpellingLanguageId(entry.key);
          if (language == null || entry.value is! List) continue;
          final values = <SpellingWordEntry>[];
          for (final item in (entry.value as List)) {
            if (item is String) {
              final display = item.trim();
              if (display.isNotEmpty) {
                values.add(
                  SpellingWordEntry(
                    key: normalizeSpellingWordKey(display),
                    display: display,
                  ),
                );
              }
            } else if (item is Map) {
              final display = item['display']?.toString().trim() ?? '';
              final key = item['key']?.toString().trim() ?? '';
              if (display.isNotEmpty && key.isNotEmpty) {
                values.add(SpellingWordEntry(key: key, display: display));
              }
            }
          }
          values.sort((left, right) => left.display.compareTo(right.display));
          words[language] = List.unmodifiable(values);
        }
      }
      return SpellingWordStoreSnapshot(
        revision: (decoded['revision'] as num?)?.toInt() ?? 0,
        projectLanguage: normalizeSpellingLanguageId(
          decoded['projectLanguage'],
        ),
        wordsByLanguage: Map.unmodifiable(words),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Could not read spelling words: $error');
    }
  }

  Future<SpellingWordStoreSnapshot> addWord(String languageId, String word) =>
      _mutate((snapshot) {
        final display = word.trim();
        if (display.isEmpty) throw ArgumentError.value(word, 'word');
        final key = normalizeSpellingWordKey(display);
        final words = _mutableWords(snapshot);
        final language = words.putIfAbsent(languageId, () => []);
        if (!language.any((entry) => entry.key == key)) {
          language.add(SpellingWordEntry(key: key, display: display));
        }
        return SpellingWordStoreSnapshot(
          revision: snapshot.revision + 1,
          projectLanguage: snapshot.projectLanguage,
          wordsByLanguage: words,
        );
      });

  Future<SpellingWordStoreSnapshot> removeWord(
    String languageId,
    String word,
  ) => _mutate((snapshot) {
    final words = _mutableWords(snapshot);
    words[languageId]?.removeWhere(
      (entry) => entry.key == normalizeSpellingWordKey(word),
    );
    return SpellingWordStoreSnapshot(
      revision: snapshot.revision + 1,
      projectLanguage: snapshot.projectLanguage,
      wordsByLanguage: words,
    );
  });

  Future<SpellingWordStoreSnapshot> setProjectLanguage(String? languageId) {
    if (!projectStore) {
      throw StateError('Personal word stores do not have a project language.');
    }
    return _mutate(
      (snapshot) => SpellingWordStoreSnapshot(
        revision: snapshot.revision + 1,
        projectLanguage: normalizeSpellingLanguageId(languageId),
        wordsByLanguage: _mutableWords(snapshot),
      ),
    );
  }

  Future<SpellingWordStoreSnapshot> _mutate(
    SpellingWordStoreSnapshot Function(SpellingWordStoreSnapshot) change,
  ) {
    final completer = Completer<SpellingWordStoreSnapshot>();
    _writeTail = _writeTail.catchError((_) {}).then((_) async {
      try {
        final current = await read();
        final updated = change(current);
        await _publish(updated);
        completer.complete(await read());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _publish(SpellingWordStoreSnapshot snapshot) async {
    final parent = Directory(p.dirname(filePath));
    if (!await parent.exists()) await parent.create(recursive: true);
    final json = <String, Object?>{
      'schemaVersion': 1,
      'revision': snapshot.revision,
      if (projectStore) 'projectLanguage': snapshot.projectLanguage,
      'words': {
        for (final entry in snapshot.wordsByLanguage.entries)
          entry.key: [
            for (final word
                in entry.value..sort(
                  (left, right) => left.display.compareTo(right.display),
                ))
              word.toJson(),
          ],
      },
    };
    await _writer.writeBytes(
      filePath,
      utf8.encode('${const JsonEncoder.withIndent('  ').convert(json)}\n'),
      overwrite: true,
    );
  }
}

Map<String, List<SpellingWordEntry>> _mutableWords(
  SpellingWordStoreSnapshot snapshot,
) => {
  for (final entry in snapshot.wordsByLanguage.entries)
    entry.key: [...entry.value],
};

String normalizeSpellingWordKey(String word) =>
    unicode.nfc(word.trim()).toLowerCase();
