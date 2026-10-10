import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

String normalizeNotesSearch(String value) => unorm.nfc(value).toLowerCase();

class NotesSearchTerm {
  const NotesSearchTerm(this.text, this.field);
  final String text;
  final String? field;
  String get literal => normalizeNotesSearch(text);
}

/// Only these two field prefixes and quotes are grammar. Everything else,
/// including SQL/FTS operators, punctuation and wildcards, is literal text.
class NotesSearchQuery {
  NotesSearchQuery(this.text, {this.wholeWord = false}) {
    if (text.length > 512) throw const FormatException('Search is too long.');
    if ('"'.allMatches(text).length.isOdd) {
      throw const FormatException('Close the quoted phrase.');
    }
    final tokens = RegExp(r'(title:|category:)?("[^"]*"|[^\s]+)');
    terms = [
      for (final token in tokens.allMatches(text))
        if (token.group(2)!.replaceAll('"', '').isNotEmpty)
          NotesSearchTerm(
            token.group(2)!.startsWith('"')
                ? token.group(2)!.substring(1, token.group(2)!.length - 1)
                : token.group(2)!,
            token.group(1)?.replaceAll(':', ''),
          ),
    ];
    if (terms.length > 32) {
      throw const FormatException('Too many search terms.');
    }
  }
  final String text;
  final bool wholeWord;
  late final List<NotesSearchTerm> terms;
  String? get ftsCandidates {
    final indexable = terms.where((t) => t.literal.runes.length >= 3);
    if (indexable.isEmpty) return null;
    return indexable
        .map((t) {
          final quoted = '"${t.literal.replaceAll('"', '""')}"';
          return t.field == null ? quoted : '${t.field}:$quoted';
        })
        .join(' AND ');
  }
}

class NotesSearchHit {
  const NotesSearchHit({
    required this.localId,
    required this.revision,
    required this.digest,
    required this.title,
    required this.category,
    required this.snippet,
    required this.snippetStart,
    this.start,
    this.end,
    this.snippetMatchStart,
    this.snippetMatchEnd,
  });
  final String localId;
  final int revision;
  final String digest;
  final String title;
  final String category;
  final String snippet;
  final int snippetStart;
  final int? start;
  final int? end;
  final int? snippetMatchStart, snippetMatchEnd;
  Map<String, Object?> toJson() => {
    'id': localId,
    'revision': revision,
    'digest': digest,
    'title': title,
    'category': category,
    'snippet': snippet,
    'snippetStart': snippetStart,
    'start': start,
    'end': end,
    'snippetMatchStart': snippetMatchStart,
    'snippetMatchEnd': snippetMatchEnd,
  };
  factory NotesSearchHit.fromJson(Map<String, dynamic> json) => NotesSearchHit(
    localId: json['id'] as String,
    revision: json['revision'] as int,
    digest: json['digest'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    snippet: json['snippet'] as String,
    snippetStart: json['snippetStart'] as int,
    start: json['start'] as int?,
    end: json['end'] as int?,
    snippetMatchStart: json['snippetMatchStart'] as int?,
    snippetMatchEnd: json['snippetMatchEnd'] as int?,
  );
}

String notesSearchDigest(String source) =>
    sha256.convert(utf8.encode(source)).toString();
final _word = RegExp(r'[\p{L}\p{M}\p{N}_]', unicode: true);

Iterable<({int start, int end})> _ranges(
  String normalized,
  String term,
  bool wholeWord,
) sync* {
  var position = 0;
  while (position <= normalized.length) {
    final start = normalized.indexOf(term, position);
    if (start < 0) break;
    final end = start + term.length;
    // Unicode identifier boundaries; punctuation in the query remains literal.
    if (!wholeWord ||
        ((start == 0 ||
                !_word.hasMatch(
                  String.fromCharCode(normalized.runesBefore(start)),
                )) &&
            (end == normalized.length ||
                !_word.hasMatch(
                  String.fromCharCode(normalized.runesAt(end)),
                )))) {
      yield (start: start, end: end);
    }
    position = end;
  }
}

extension on String {
  int runesBefore(int offset) {
    var start = offset - 1;
    if (start > 0 &&
        codeUnitAt(start) >= 0xdc00 &&
        codeUnitAt(start) <= 0xdfff) {
      start--;
    }
    return substring(start, offset).runes.first;
  }

  int runesAt(int offset) => substring(offset).runes.first;
}

/// Shared verifier for indexed durable documents, dirty overlays and stale
/// navigation. Offsets map back through grapheme clusters to authored UTF-16.
List<NotesSearchHit> matchNotesDocument({
  required NotesSearchQuery query,
  required String localId,
  required int revision,
  required String title,
  required String category,
  required String source,
  int limit = 80,
  int afterStart = -1,
  int afterEnd = -1,
}) {
  if (query.terms.isEmpty || limit <= 0) return [];
  final body = normalizeNotesSearch(source);
  final normalizedTitle = normalizeNotesSearch(title);
  final normalizedCategory = normalizeNotesSearch(category);
  final iterators = <Iterator<({int start, int end})>>[];
  ({String text, int start, int end})? metadataMatch;
  for (final term in query.terms) {
    final contentMatches =
        (term.field == null
                ? _ranges(body, term.literal, query.wholeWord)
                : const <({int start, int end})>[])
            .iterator;
    final hasContent = contentMatches.moveNext();
    final titleMatches = term.field != 'category'
        ? _ranges(normalizedTitle, term.literal, query.wholeWord)
        : <({int start, int end})>[];
    final categoryMatches = term.field != 'title'
        ? _ranges(normalizedCategory, term.literal, query.wholeWord)
        : <({int start, int end})>[];
    if (!hasContent && titleMatches.isEmpty && categoryMatches.isEmpty) {
      return [];
    }
    if (metadataMatch == null && titleMatches.isNotEmpty) {
      metadataMatch = (
        text: title,
        start: titleMatches.first.start,
        end: titleMatches.first.end,
      );
    } else if (metadataMatch == null && categoryMatches.isNotEmpty) {
      metadataMatch = (
        text: category,
        start: categoryMatches.first.start,
        end: categoryMatches.first.end,
      );
    }
    if (hasContent) iterators.add(contentMatches);
  }
  final digest = notesSearchDigest(source);
  if (iterators.isEmpty) {
    if (afterStart >= 0) return [];
    final match = metadataMatch!;
    var normalizedOffset = 0, originalOffset = 0, from = 0, to = 0;
    for (final cluster in match.text.characters) {
      final length = normalizeNotesSearch(cluster).length;
      if (match.start >= normalizedOffset &&
          match.start < normalizedOffset + length) {
        from = originalOffset;
      }
      if (match.end > normalizedOffset &&
          match.end <= normalizedOffset + length) {
        to = originalOffset + cluster.length;
      }
      normalizedOffset += length;
      originalOffset += cluster.length;
    }
    return [
      NotesSearchHit(
        localId: localId,
        revision: revision,
        digest: digest,
        title: title,
        category: category,
        snippet: match.text,
        snippetStart: 0,
        snippetMatchStart: from,
        snippetMatchEnd: to,
      ),
    ];
  }
  // Merge lazy per-term streams. Bounds limit transferred hits, never the
  // searchable occurrences. A range cursor also distinguishes overlapping terms.
  final ranges = <({int start, int end})>[];
  final normalizedAfterStart = afterStart < 0
      ? -1
      : normalizeNotesSearch(source.substring(0, afterStart)).length;
  final normalizedAfterEnd = afterEnd < 0
      ? -1
      : normalizeNotesSearch(source.substring(0, afterEnd)).length;
  ({int start, int end})? previous;
  while (iterators.isNotEmpty && ranges.length < limit) {
    iterators.sort((a, b) {
      final start = a.current.start.compareTo(b.current.start);
      return start != 0 ? start : a.current.end.compareTo(b.current.end);
    });
    final iterator = iterators.first;
    final range = iterator.current;
    if (range != previous &&
        (range.start > normalizedAfterStart ||
            range.start == normalizedAfterStart &&
                range.end > normalizedAfterEnd)) {
      ranges.add(range);
    }
    previous = range;
    if (!iterator.moveNext()) iterators.removeAt(0);
  }
  // Map only page boundaries through authored graphemes, including overlapping
  // occurrences. No array proportional to document length is transferred.
  final startBoundaries = ranges.map((r) => r.start).toSet().toList()..sort();
  final endBoundaries = ranges.map((r) => r.end).toSet().toList()..sort();
  final starts = <int, int>{}, ends = <int, int>{};
  var normalizedOffset = 0, originalOffset = 0, startIndex = 0, endIndex = 0;
  for (final cluster in source.characters) {
    final normalizedEnd =
        normalizedOffset + normalizeNotesSearch(cluster).length;
    while (startIndex < startBoundaries.length &&
        startBoundaries[startIndex] < normalizedEnd) {
      starts[startBoundaries[startIndex++]] = originalOffset;
    }
    while (endIndex < endBoundaries.length &&
        endBoundaries[endIndex] <= normalizedEnd) {
      ends[endBoundaries[endIndex++]] = originalOffset + cluster.length;
    }
    if (endIndex == endBoundaries.length) break;
    normalizedOffset = normalizedEnd;
    originalOffset += cluster.length;
  }
  final hits = <NotesSearchHit>[
    for (final range in ranges)
      if (starts.containsKey(range.start) && ends.containsKey(range.end))
        _hit(
          localId,
          revision,
          digest,
          title,
          category,
          source,
          starts[range.start]!,
          ends[range.end]!,
        ),
  ];
  return hits;
}

NotesSearchHit _hit(
  String id,
  int revision,
  String digest,
  String title,
  String category,
  String source,
  int start,
  int end,
) {
  var snippetStart = (start - 45).clamp(0, source.length);
  var snippetEnd = (end + 100).clamp(0, source.length);
  // Snippets must not split surrogate pairs.
  if (snippetStart > 0 &&
      source.codeUnitAt(snippetStart) >= 0xdc00 &&
      source.codeUnitAt(snippetStart) <= 0xdfff) {
    snippetStart--;
  }
  if (snippetEnd < source.length &&
      source.codeUnitAt(snippetEnd) >= 0xdc00 &&
      source.codeUnitAt(snippetEnd) <= 0xdfff) {
    snippetEnd++;
  }
  return NotesSearchHit(
    localId: id,
    revision: revision,
    digest: digest,
    title: title,
    category: category,
    snippet: source.substring(snippetStart, snippetEnd),
    snippetStart: snippetStart,
    start: start,
    end: end,
  );
}
