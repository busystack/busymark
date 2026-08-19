import 'markdown_fence.dart';
import 'markdown_model.dart';
import 'markdown_parser.dart';

const String busyMarkTocStartMarker = '<!-- busymark:toc:start -->';
const String busyMarkTocEndMarker = '<!-- busymark:toc:end -->';

enum MarkdownTocFailure { malformedMarkers, noHeadings }

class MarkdownTocException implements Exception {
  const MarkdownTocException(this.failure);

  final MarkdownTocFailure failure;
}

class MarkdownTocResult {
  const MarkdownTocResult({
    required this.source,
    required this.entryCount,
    required this.updated,
  });

  final String source;
  final int entryCount;
  final bool updated;
}

/// Generates a parser-derived, marker-delimited Markdown table of contents.
///
/// Existing generated regions are replaced in place. Marker-like lines inside
/// fenced code blocks remain ordinary code and are never interpreted.
class MarkdownTocGenerator {
  const MarkdownTocGenerator({this.parser = const MarkdownParser()});

  final MarkdownParser parser;

  MarkdownTocResult generate({
    required String source,
    required String filePath,
    required MarkdownMode mode,
    required String title,
  }) {
    final newline = source.contains('\r\n') ? '\r\n' : '\n';
    final region = _generatedRegion(source);
    final sourceWithoutToc = region == null
        ? source
        : source.replaceRange(region.start, region.end, '');
    final parsed = parser.parse(
      filePath: filePath,
      source: sourceWithoutToc,
      mode: mode,
      validateLocalReferences: false,
    );
    final headings = parsed.headings
        .where((heading) => heading.text.trim().isNotEmpty)
        .toList(growable: false);
    final documentTitle = headings.isNotEmpty && headings.first.level == 1
        ? headings.first
        : null;
    final entries = headings
        .skip(documentTitle == null ? 0 : 1)
        .toList(growable: false);
    if (entries.isEmpty) {
      throw const MarkdownTocException(MarkdownTocFailure.noHeadings);
    }

    final baseLevel = documentTitle == null
        ? entries.map((heading) => heading.level).reduce(_minimum)
        : 2;
    final toc = _tocBlock(
      entries: entries,
      title: title.trim().isEmpty ? 'Table of contents' : title.trim(),
      headingLevel: baseLevel.clamp(1, 6).toInt(),
      listBaseLevel: baseLevel,
      newline: newline,
    );
    if (region != null) {
      return MarkdownTocResult(
        source: source.replaceRange(region.start, region.end, toc),
        entryCount: entries.length,
        updated: true,
      );
    }

    final insertionOffset = documentTitle == null
        ? _frontMatterEnd(sourceWithoutToc)
        : _lineEndAfter(sourceWithoutToc, documentTitle.span.endOffset);
    return MarkdownTocResult(
      source: _insertBlock(sourceWithoutToc, insertionOffset, toc, newline),
      entryCount: entries.length,
      updated: false,
    );
  }

  _GeneratedRegion? _generatedRegion(String source) {
    final starts = <_SourceLine>[];
    final ends = <_SourceLine>[];
    MarkdownFence? fence;
    for (final line in _sourceLines(source)) {
      final content = line.content;
      if (fence case final openFence?) {
        if (openFence.closes(content)) {
          fence = null;
        }
        continue;
      }
      final opening = MarkdownFence.parse(content);
      if (opening != null) {
        fence = opening;
        continue;
      }
      switch (content.trim()) {
        case busyMarkTocStartMarker:
          starts.add(line);
        case busyMarkTocEndMarker:
          ends.add(line);
      }
    }
    if (starts.isEmpty && ends.isEmpty) {
      return null;
    }
    if (starts.length != 1 ||
        ends.length != 1 ||
        starts.single.start >= ends.single.start) {
      throw const MarkdownTocException(MarkdownTocFailure.malformedMarkers);
    }
    return _GeneratedRegion(start: starts.single.start, end: ends.single.end);
  }

  String _tocBlock({
    required List<MarkdownHeading> entries,
    required String title,
    required int headingLevel,
    required int listBaseLevel,
    required String newline,
  }) {
    final buffer = StringBuffer()
      ..write(busyMarkTocStartMarker)
      ..write(newline)
      ..write('${_repeat('#', headingLevel)} $title')
      ..write(newline)
      ..write(newline);
    for (final heading in entries) {
      final depth = (heading.level - listBaseLevel).clamp(0, 5).toInt();
      buffer
        ..write(_repeat('  ', depth))
        ..write('- [${_escapeLabel(heading.text.trim())}](#${heading.id})')
        ..write(newline);
    }
    buffer
      ..write(busyMarkTocEndMarker)
      ..write(newline);
    return buffer.toString();
  }

  String _escapeLabel(String value) => value.replaceAllMapped(
    RegExp(r'([\\\[\]])'),
    (match) => '\\${match.group(1)}',
  );

  int _frontMatterEnd(String source) {
    final lines = _sourceLines(source);
    if (lines.isEmpty || lines.first.content.trim() != '---') {
      return 0;
    }
    for (final line in lines.skip(1)) {
      final value = line.content.trim();
      if (value == '---' || value == '...') {
        return line.end;
      }
    }
    return 0;
  }

  int _lineEndAfter(String source, int offset) {
    final newline = source.indexOf(
      '\n',
      offset.clamp(0, source.length).toInt(),
    );
    return newline == -1 ? source.length : newline + 1;
  }

  String _insertBlock(String source, int offset, String block, String newline) {
    final safeOffset = offset.clamp(0, source.length).toInt();
    final before = source.substring(0, safeOffset);
    final after = source.substring(safeOffset);
    final beforeSeparator = before.isEmpty
        ? ''
        : before.endsWith('$newline$newline')
        ? ''
        : before.endsWith(newline)
        ? newline
        : '$newline$newline';
    final afterSeparator = after.isEmpty
        ? ''
        : after.startsWith('$newline$newline')
        ? ''
        : after.startsWith(newline)
        ? ''
        : '$newline$newline';
    return '$before$beforeSeparator$block$afterSeparator$after';
  }

  List<_SourceLine> _sourceLines(String source) {
    final lines = <_SourceLine>[];
    var start = 0;
    while (start < source.length) {
      final newline = source.indexOf('\n', start);
      final end = newline == -1 ? source.length : newline + 1;
      var contentEnd = newline == -1 ? source.length : newline;
      if (contentEnd > start && source.codeUnitAt(contentEnd - 1) == 13) {
        contentEnd -= 1;
      }
      lines.add(
        _SourceLine(
          start: start,
          end: end,
          content: source.substring(start, contentEnd),
        ),
      );
      start = end;
    }
    return lines;
  }
}

int _minimum(int first, int second) => first < second ? first : second;

String _repeat(String value, int count) => List.filled(count, value).join();

class _GeneratedRegion {
  const _GeneratedRegion({required this.start, required this.end});

  final int start;
  final int end;
}

class _SourceLine {
  const _SourceLine({
    required this.start,
    required this.end,
    required this.content,
  });

  final int start;
  final int end;
  final String content;
}
