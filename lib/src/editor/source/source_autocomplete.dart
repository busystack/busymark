import 'package:path/path.dart' as p;

import 'source_document.dart';
import '../../writerside/writerside_schema.dart';
import '../../writerside/writerside_project.dart';

enum SourceAutocompleteKind {
  topic,
  link,
  image,
  include,
  variable,
  category,
  xmlTag,
  xmlAttribute,
  codeLanguage,
  heading,
  localWord,
}

class SourceAutocompleteSuggestion {
  const SourceAutocompleteSuggestion({
    required this.label,
    required this.insertText,
    required this.kind,
  });

  final String label;
  final String insertText;
  final SourceAutocompleteKind kind;
}

class SourceAutocompleteContext {
  const SourceAutocompleteContext({
    this.projectFiles = const [],
    this.variables = const [],
    this.categories = const [],
    this.topicIds = const [],
    this.parentElement,
    this.currentElement,
    this.projectIndex,
    this.moduleId,
  });

  final List<String> projectFiles;
  final List<String> variables;
  final List<String> categories;
  final List<String> topicIds;
  final String? parentElement;
  final String? currentElement;
  final WritersideProjectIndex? projectIndex;
  final String? moduleId;

  SourceAutocompleteContext atCaret(String source, int offset) {
    final xml = writersideXmlCaretContext(source, offset);
    return SourceAutocompleteContext(
      projectFiles: projectFiles,
      variables: variables,
      categories: categories,
      topicIds: topicIds,
      parentElement: parentElement ?? xml.parentElement,
      currentElement: currentElement ?? xml.currentElement,
      projectIndex: projectIndex,
      moduleId: moduleId,
    );
  }
}

class WritersideXmlCaretContext {
  const WritersideXmlCaretContext({
    required this.parentElement,
    required this.currentElement,
  });

  final String? parentElement;
  final String? currentElement;
}

class SourceAutocompleteProvider {
  const SourceAutocompleteProvider();

  List<SourceAutocompleteSuggestion> suggestions({
    required SourceDocument document,
    required int fullOffset,
    SourceAutocompleteContext context = const SourceAutocompleteContext(),
    int limit = 40,
  }) {
    context = context.atCaret(document.fullText, fullOffset);
    final prefix = _prefixBefore(document.fullText, fullOffset).toLowerCase();
    final suggestions = <SourceAutocompleteSuggestion>[
      for (final tag in WritersideSchema.childElementNames(
        context.parentElement,
      ).take(context.parentElement == null ? 15 : 60))
        SourceAutocompleteSuggestion(
          label: tag,
          insertText: tag,
          kind: SourceAutocompleteKind.xmlTag,
        ),
      for (final attr
          in context.currentElement == null
              ? WritersideSchema.commonConditionalAttributes
              : WritersideSchema.attributesFor(context.currentElement!))
        SourceAutocompleteSuggestion(
          label: attr,
          insertText: attr,
          kind: SourceAutocompleteKind.xmlAttribute,
        ),
      for (final language in _codeLanguages)
        SourceAutocompleteSuggestion(
          label: language,
          insertText: language,
          kind: SourceAutocompleteKind.codeLanguage,
        ),
      for (final heading in _headings(document.fullText))
        SourceAutocompleteSuggestion(
          label: heading,
          insertText: _anchorForHeading(heading),
          kind: SourceAutocompleteKind.heading,
        ),
      for (final file in context.projectFiles)
        SourceAutocompleteSuggestion(
          label: file,
          insertText: file,
          kind: _imageExtensions.contains(p.extension(file).toLowerCase())
              ? SourceAutocompleteKind.image
              : SourceAutocompleteKind.link,
        ),
      for (final topic in context.topicIds)
        SourceAutocompleteSuggestion(
          label: topic,
          insertText: topic,
          kind: SourceAutocompleteKind.topic,
        ),
      for (final topic
          in context.projectIndex?.names(
                WritersideSymbolKind.topic,
                moduleId: context.moduleId,
              ) ??
              const <String>[])
        SourceAutocompleteSuggestion(
          label: topic,
          insertText: topic,
          kind: SourceAutocompleteKind.topic,
        ),
      for (final variable in context.variables)
        SourceAutocompleteSuggestion(
          label: variable,
          insertText: variable,
          kind: SourceAutocompleteKind.variable,
        ),
      for (final variable
          in context.projectIndex?.names(
                WritersideSymbolKind.variable,
                moduleId: context.moduleId,
              ) ??
              const <String>[])
        SourceAutocompleteSuggestion(
          label: variable,
          insertText: variable,
          kind: SourceAutocompleteKind.variable,
        ),
      for (final category in context.categories)
        SourceAutocompleteSuggestion(
          label: category,
          insertText: category,
          kind: SourceAutocompleteKind.category,
        ),
      for (final category
          in context.projectIndex?.names(
                WritersideSymbolKind.category,
                moduleId: context.moduleId,
              ) ??
              const <String>[])
        SourceAutocompleteSuggestion(
          label: category,
          insertText: category,
          kind: SourceAutocompleteKind.category,
        ),
      for (final word in _localWords(document.fullText))
        SourceAutocompleteSuggestion(
          label: word,
          insertText: word,
          kind: SourceAutocompleteKind.localWord,
        ),
    ];

    final seen = <String>{};
    final filtered =
        [
          for (final suggestion in suggestions)
            if (seen.add('${suggestion.kind.name}:${suggestion.label}') &&
                (prefix.isEmpty ||
                    suggestion.label.toLowerCase().startsWith(prefix)))
              suggestion,
        ]..sort((a, b) {
          final kind = a.kind.index.compareTo(b.kind.index);
          if (kind != 0) {
            return kind;
          }
          return a.label.compareTo(b.label);
        });
    return filtered.take(limit).toList(growable: false);
  }
}

WritersideXmlCaretContext writersideXmlCaretContext(String source, int offset) {
  final limit = offset.clamp(0, source.length).toInt();
  final stack = <String>[];
  var cursor = 0;
  while (cursor < limit) {
    final opening = source.indexOf('<', cursor);
    if (opening < 0 || opening >= limit) {
      break;
    }
    if (source.startsWith('<!--', opening)) {
      final end = source.indexOf('-->', opening + 4);
      if (end < 0 || end + 3 > limit) {
        break;
      }
      cursor = end + 3;
      continue;
    }
    if (source.startsWith('<![CDATA[', opening)) {
      final end = source.indexOf(']]>', opening + 9);
      if (end < 0 || end + 3 > limit) {
        break;
      }
      cursor = end + 3;
      continue;
    }
    final closing = _xmlTagEnd(source, opening + 1, limit);
    if (closing == null) {
      final fragment = source.substring(opening + 1, limit).trimLeft();
      if (fragment.startsWith('/') ||
          fragment.startsWith('!') ||
          fragment.startsWith('?')) {
        return WritersideXmlCaretContext(
          parentElement: stack.length > 1 ? stack[stack.length - 2] : null,
          currentElement: stack.lastOrNull,
        );
      }
      final name = RegExp(
        r'^([A-Za-z_][A-Za-z0-9_.:-]*)',
      ).firstMatch(fragment)?.group(1);
      return WritersideXmlCaretContext(
        parentElement: stack.lastOrNull,
        currentElement: name,
      );
    }
    final content = source.substring(opening + 1, closing).trim();
    if (content.startsWith('/') && stack.isNotEmpty) {
      final name = RegExp(
        r'^/\s*([A-Za-z_][A-Za-z0-9_.:-]*)',
      ).firstMatch(content)?.group(1);
      final matching = name == null ? -1 : stack.lastIndexOf(name);
      if (matching >= 0) {
        stack.removeRange(matching, stack.length);
      }
    } else if (!content.startsWith('!') && !content.startsWith('?')) {
      final name = RegExp(
        r'^([A-Za-z_][A-Za-z0-9_.:-]*)',
      ).firstMatch(content)?.group(1);
      if (name != null && !content.endsWith('/')) {
        stack.add(name);
      }
    }
    cursor = closing + 1;
  }
  return WritersideXmlCaretContext(
    parentElement: stack.lastOrNull,
    currentElement: null,
  );
}

({int start, int end}) sourceAutocompleteReplacementRange(
  String text,
  int offset,
) {
  final end = offset.clamp(0, text.length).toInt();
  var start = end;
  while (start > 0) {
    final unit = text.codeUnitAt(start - 1);
    final word =
        (unit >= 48 && unit <= 57) ||
        (unit >= 65 && unit <= 90) ||
        (unit >= 97 && unit <= 122) ||
        unit == 45 ||
        unit == 46 ||
        unit == 47 ||
        unit == 58 ||
        unit == 95;
    if (!word) {
      break;
    }
    start--;
  }
  return (start: start, end: end);
}

int? _xmlTagEnd(String source, int start, int limit) {
  var quote = 0;
  for (var index = start; index < limit; index++) {
    final unit = source.codeUnitAt(index);
    if (quote != 0) {
      if (unit == quote) {
        quote = 0;
      }
      continue;
    }
    if (unit == 34 || unit == 39) {
      quote = unit;
    } else if (unit == 62) {
      return index;
    }
  }
  return null;
}

String _prefixBefore(String text, int offset) {
  final safeOffset = offset.clamp(0, text.length).toInt();
  var start = safeOffset;
  while (start > 0) {
    final unit = text.codeUnitAt(start - 1);
    final word =
        (unit >= 48 && unit <= 57) ||
        (unit >= 65 && unit <= 90) ||
        (unit >= 97 && unit <= 122) ||
        unit == 45 ||
        unit == 46 ||
        unit == 47 ||
        unit == 58 ||
        unit == 95;
    if (!word) {
      break;
    }
    start--;
  }
  return text.substring(start, safeOffset);
}

Iterable<String> _headings(String text) sync* {
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final match = RegExp(r'^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$').firstMatch(line);
    if (match != null) {
      yield match.group(1)!.trim();
    }
  }
}

Iterable<String> _localWords(String text) sync* {
  for (final match in RegExp(
    r'\b[A-Za-z][A-Za-z0-9_-]{3,}\b',
  ).allMatches(text)) {
    yield match.group(0)!;
  }
}

String _anchorForHeading(String heading) {
  return heading
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');
}

const _codeLanguages = [
  'xml',
  'html',
  'json',
  'yaml',
  'shell',
  'dart',
  'kotlin',
  'javascript',
  'typescript',
  'python',
];

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

const _imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'};
