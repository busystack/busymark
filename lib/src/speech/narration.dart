import 'package:characters/characters.dart';
import 'package:html/parser.dart' as html;

import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_source_map.dart';
import 'speech_provider.dart';

enum NarrationScope { selection, block, section, document }

enum NarrationLinks { label, labelAndUrl, skip }

enum NarrationOmission {
  headings,
  code,
  tables,
  quotes,
  images,
  footnotes,
  math,
  media,
  hidden,
  unmappedSelection,
}

class NarrationRules {
  const NarrationRules({
    this.headings = true,
    this.codeBlocks = false,
    this.inlineCode = true,
    this.tables = true,
    this.quotes = true,
    this.images = true,
    this.footnotes = false,
    this.links = NarrationLinks.label,
    this.blockPause = const Duration(milliseconds: 220),
    this.sectionPause = const Duration(milliseconds: 450),
  });

  factory NarrationRules.fromJson(Map<Object?, Object?> json) {
    final defaults = const NarrationRules();
    Duration pause(String key, Duration fallback) => Duration(
      milliseconds:
          (json[key] is int ? json[key] as int : fallback.inMilliseconds).clamp(
            0,
            3000,
          ),
    );
    return NarrationRules(
      headings: json['headings'] != false,
      codeBlocks: json['codeBlocks'] == true,
      inlineCode: json['inlineCode'] != false,
      tables: json['tables'] != false,
      quotes: json['quotes'] != false,
      images: json['images'] != false,
      footnotes: json['footnotes'] == true,
      links:
          NarrationLinks.values
              .where((value) => value.name == json['links'])
              .firstOrNull ??
          defaults.links,
      blockPause: pause('blockPause', defaults.blockPause),
      sectionPause: pause('sectionPause', defaults.sectionPause),
    );
  }

  final bool headings;
  final bool codeBlocks;
  final bool inlineCode;
  final bool tables;
  final bool quotes;
  final bool images;
  final bool footnotes;
  final NarrationLinks links;
  final Duration blockPause;
  final Duration sectionPause;

  Map<String, Object> toJson() => {
    'headings': headings,
    'codeBlocks': codeBlocks,
    'inlineCode': inlineCode,
    'tables': tables,
    'quotes': quotes,
    'images': images,
    'footnotes': footnotes,
    'links': links.name,
    'blockPause': blockPause.inMilliseconds,
    'sectionPause': sectionPause.inMilliseconds,
  };
}

class NarrationPlan {
  NarrationPlan({
    required this.documentId,
    required this.providerId,
    required this.revision,
    required this.scope,
    required this.insertionOffset,
    required Iterable<({SpeechSegment speech, SourceSpan? source})> passages,
    required Iterable<NarrationOmission> omissions,
  }) : passages = List.unmodifiable(passages),
       omissions = Set.unmodifiable(omissions);

  final String documentId;
  final String providerId;
  final int revision;
  final NarrationScope scope;
  final int insertionOffset;
  final List<({SpeechSegment speech, SourceSpan? source})> passages;
  final Set<NarrationOmission> omissions;
  List<SpeechSegment> get segments => [
    for (final entry in passages) entry.speech,
  ];
  String get text => passages.map((entry) => entry.speech.text).join('\n\n');
}

class NarrationProjection {
  const NarrationProjection();

  NarrationPlan project({
    required BusyDocument document,
    required String capturedSource,
    required String documentId,
    required String providerId,
    required int revision,
    required NarrationScope scope,
    required int anchor,
    required int selectionStart,
    required int selectionEnd,
    required NarrationRules rules,
    String language = '',
    String completedTask = '',
    String incompleteTask = '',
  }) {
    final run = _NarrationRun(
      document: document,
      source: capturedSource,
      rules: rules,
      language: language,
      completedTask: completedTask,
      incompleteTask: incompleteTask,
    );
    final blocks = document.blocks;
    var start = 0;
    var end = capturedSource.length;
    final xmlScope =
        document.resolvedWritersideXml &&
        (scope == NarrationScope.block || scope == NarrationScope.section);
    if (scope == NarrationScope.selection) {
      start = selectionStart.clamp(0, capturedSource.length);
      end = selectionEnd.clamp(start, capturedSource.length);
    } else if (xmlScope) {
      end = run.visitXmlScope(anchor, section: scope == NarrationScope.section);
    } else if (scope == NarrationScope.block ||
        scope == NarrationScope.section) {
      if (scope == NarrationScope.block) {
        final match = blocks
            .where((block) {
              final span = block.sourceSpan;
              return run.owns(span) &&
                  span!.startOffset <= anchor &&
                  anchor <= span.endOffset;
            })
            .firstOrNull
            ?.sourceSpan;
        start = match?.startOffset ?? 0;
        end = match?.endOffset ?? start;
      } else {
        final headings = blocks
            .where(
              (block) =>
                  block.kind == BusyBlockKind.heading &&
                  run.owns(block.sourceSpan),
            )
            .toList();
        final current = headings.lastIndexWhere(
          (block) => block.sourceSpan!.startOffset <= anchor,
        );
        if (current >= 0) {
          final heading = headings[current];
          start = heading.sourceSpan!.startOffset;
          final level = int.tryParse(heading.attributes['level'] ?? '') ?? 1;
          for (final next in headings.skip(current + 1)) {
            if ((int.tryParse(next.attributes['level'] ?? '') ?? 1) <= level) {
              end = next.sourceSpan!.startOffset;
              break;
            }
          }
        } else if (headings.isNotEmpty) {
          end = headings.first.sourceSpan!.startOffset;
        }
      }
    }

    if (!xmlScope && (start < end || scope == NarrationScope.document)) {
      for (final block in blocks) {
        final span = block.sourceSpan;
        if (scope == NarrationScope.document) {
          run.visit(block);
        } else if (scope == NarrationScope.selection &&
            document.resolvedWritersideXml) {
          run.visitXmlSelection(block, start, end);
        } else if (run.owns(span) &&
            span!.startOffset < end &&
            span.endOffset > start) {
          if (scope == NarrationScope.selection &&
              (span.startOffset < start || span.endOffset > end)) {
            run.partial(block, start, end);
          } else {
            run.visit(block);
          }
        }
      }
    }
    return NarrationPlan(
      documentId: documentId,
      providerId: providerId,
      revision: revision,
      scope: scope,
      insertionOffset: end,
      passages: run.passages,
      omissions: run.omissions,
    );
  }
}

class _NarrationRun {
  _NarrationRun({
    required this.document,
    required this.source,
    required this.rules,
    required this.language,
    required this.completedTask,
    required this.incompleteTask,
  });

  final BusyDocument document;
  final String source;
  final NarrationRules rules;
  final String language;
  final String completedTask;
  final String incompleteTask;
  final passages = <({SpeechSegment speech, SourceSpan? source})>[];
  final omissions = <NarrationOmission>{};
  late final _inlineParser = const MarkdownSourceMapper()
      .createInlineParserContext(documentSource: source, mode: document.mode);
  late final _tabSelection = _selectTabs(document.blocks);

  bool owns(SourceSpan? span) =>
      span != null &&
      span.filePath == document.filePath &&
      span.startOffset >= 0 &&
      span.endOffset <= source.length;

  bool _activeVariant(Map<String, String> attributes) {
    final selected = attributes['switcher-default'];
    final keys = attributes['switcher-key'];
    return selected == null ||
        keys == null ||
        keys.split(',').any((key) => key.trim() == selected);
  }

  bool _tabGroup(BusyBlock block) =>
      block.kind == BusyBlockKind.writersideTabs &&
      block.attributes['element'] == 'tabs';

  Map<BusyBlock, BusyBlock> _selectTabs(List<BusyBlock> roots) {
    final selected = <BusyBlock, BusyBlock>{};
    final groups = <String, String>{};
    void walk(BusyBlock block) {
      if (_hidden(block)) return;
      if (!_tabGroup(block)) {
        block.children.forEach(walk);
        return;
      }
      final panels = block.children.where(
        (panel) => panel.attributes['element'] == 'tab' && !_hidden(panel),
      );
      final first = panels.firstOrNull;
      if (first == null) return;
      final group = block.attributes['group'];
      String key(BusyBlock panel) =>
          panel.attributes['group-key'] ?? panel.plainText;
      final shared = group == null
          ? null
          : groups.putIfAbsent(group, () => key(first));
      final panel =
          panels.where((panel) => key(panel) == shared).firstOrNull ?? first;
      selected[block] = panel;
      walk(panel);
    }

    roots.forEach(walk);
    return selected;
  }

  bool _hidden(BusyBlock block) =>
      block.attributes['topic-switcher'] == 'true' ||
      !_activeVariant(block.attributes);

  Iterable<BusyBlock> _children(BusyBlock block) {
    if (!_tabGroup(block)) return block.children;
    final panel = _tabSelection[block];
    if (block.children.any((child) => !identical(child, panel))) {
      omissions.add(NarrationOmission.hidden);
    }
    return [if (panel != null) panel];
  }

  int visitXmlScope(int anchor, {required bool section}) {
    List<BusyBlock> pathAt(List<BusyBlock> blocks) {
      for (final block in blocks) {
        final span = block.sourceSpan;
        if (owns(span) &&
            span!.startOffset <= anchor &&
            anchor < span.endOffset) {
          return [block, ...pathAt(block.children)];
        }
      }
      return const [];
    }

    bool isSection(BusyBlock block) =>
        block.attributes['element'] == 'chapter' ||
        block.attributes['writerside-section'] == 'true';

    final path = pathAt(document.blocks);
    final target = section ? path.lastIndexWhere(isSection) : path.length - 1;
    if (target < 0) {
      if (!section) return anchor.clamp(0, source.length);
      final first = document.blocks.where(isSection).firstOrNull;
      final firstStart = first?.sourceSpan?.startOffset ?? source.length;
      if (anchor > firstStart) {
        final block = path.firstOrNull;
        if (block != null) visit(block);
        return block?.sourceSpan?.endOffset ?? anchor.clamp(0, source.length);
      }
      for (final block in document.blocks.takeWhile(
        (block) => !isSection(block),
      )) {
        visit(block);
      }
      return firstStart;
    }
    final end = path[target].sourceSpan!.endOffset;
    String? inheritedLanguage;
    for (final (index, block) in path.take(target + 1).indexed) {
      final omission = skip(block);
      if (omission != null && omission != NarrationOmission.headings) {
        omissions.add(omission);
        return end;
      }
      if (_tabGroup(block) &&
          index < target &&
          !identical(path[index + 1], _tabSelection[block])) {
        omissions.add(NarrationOmission.hidden);
        return end;
      }
      if (index < target) {
        inheritedLanguage = block.attributes['lang'] ?? inheritedLanguage;
      }
    }
    visit(path[target], inheritedLanguage: inheritedLanguage);
    return end;
  }

  void add(
    String text,
    SourceSpan? span,
    String? lang, {
    bool heading = false,
    bool literal = false,
  }) {
    final normalized = literal
        ? text.trim()
        : text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return;
    passages.add((
      speech: SpeechSegment(
        normalized,
        language:
            lang ??
            document.frontMatter['lang'] ??
            (language.isEmpty ? null : language),
        pauseAfter: heading ? rules.sectionPause : rules.blockPause,
      ),
      source: span,
    ));
  }

  NarrationOmission? skip(BusyBlock block) {
    if (_hidden(block) ||
        block.isSourceOnly ||
        block.kind == BusyBlockKind.frontMatter ||
        block.attributes['unsupported'] == 'true' ||
        block.kind == BusyBlockKind.writersideRawXml &&
            !const {'deflist', 'def'}.contains(block.attributes['element']) ||
        block.attributes['htmlTag'] == 'summary' && block.plainText.isEmpty) {
      return NarrationOmission.hidden;
    }
    if (block.attributes.containsKey('html-footnotes') && !rules.footnotes) {
      return NarrationOmission.footnotes;
    }
    return switch (block.kind) {
      BusyBlockKind.heading when !rules.headings => NarrationOmission.headings,
      BusyBlockKind.codeBlock when !rules.codeBlocks => NarrationOmission.code,
      BusyBlockKind.table when !rules.tables => NarrationOmission.tables,
      BusyBlockKind.blockquote when !rules.quotes => NarrationOmission.quotes,
      BusyBlockKind.image when !rules.images => NarrationOmission.images,
      BusyBlockKind.math => NarrationOmission.math,
      BusyBlockKind.audio || BusyBlockKind.video => NarrationOmission.media,
      BusyBlockKind.unknown
          when !block.attributes.containsKey('html-footnotes') =>
        NarrationOmission.hidden,
      BusyBlockKind.htmlBlock
          when block.inlines.isEmpty && block.children.isEmpty =>
        NarrationOmission.hidden,
      _ => null,
    };
  }

  void visit(BusyBlock block, {String? inheritedLanguage}) {
    final omission = skip(block);
    final lang = block.attributes['lang'] ?? inheritedLanguage;
    if (omission != null) {
      omissions.add(omission);
      if (omission == NarrationOmission.headings) {
        for (final child in _children(block)) {
          visit(child, inheritedLanguage: lang);
        }
      }
      return;
    }
    if (block.kind == BusyBlockKind.table) {
      table(block, lang);
      return;
    }
    final notes = block.attributes['html-footnotes'];
    if (notes != null) {
      final fragment = html.parseFragment(notes);
      for (final backlink in fragment.querySelectorAll('a.footnote-backref')) {
        backlink.remove();
      }
      for (final note in fragment.querySelectorAll('.footnotes > ol > li')) {
        add(note.text, block.sourceSpan, lang);
      }
      return;
    }
    if (block.kind == BusyBlockKind.codeBlock) {
      add(block.plainText, block.sourceSpan, lang, literal: true);
      return;
    }
    final prefix = block.kind == BusyBlockKind.taskListItem
        ? (block.attributes['task'] == 'true' ? completedTask : incompleteTask)
        : '';
    final text = inlineText(block.inlines);
    add(
      prefix.isEmpty ? text : '$prefix $text',
      block.sourceSpan,
      lang,
      heading: block.kind == BusyBlockKind.heading,
    );
    for (final child in _children(block)) {
      visit(child, inheritedLanguage: lang);
    }
  }

  void table(BusyBlock table, String? lang) {
    final headers = <int, String>{};
    final covered = <int, int>{};
    for (final (rowIndex, row) in table.children.indexed) {
      if (_hidden(row)) {
        omissions.add(NarrationOmission.hidden);
        continue;
      }
      var column = 0;
      final parts = <String>[];
      final header = row.attributes['header'] == 'true';
      for (final cell in row.children) {
        while ((covered[column] ?? 0) > rowIndex) {
          column++;
        }
        final span = (int.tryParse(cell.attributes['colspan'] ?? '') ?? 1)
            .clamp(1, 100);
        final rows = (int.tryParse(cell.attributes['rowspan'] ?? '') ?? 1)
            .clamp(1, 100);
        final hidden = _hidden(cell);
        if (hidden) omissions.add(NarrationOmission.hidden);
        final text = hidden ? '' : inlineText(cell.inlines).trim();
        final labels = <String>{};
        for (var offset = 0; offset < span; offset++) {
          covered[column + offset] = rowIndex + rows;
          if (header) {
            headers[column + offset] = text;
          } else if (headers[column + offset] case final label?
              when label.isNotEmpty) {
            labels.add(label);
          }
        }
        if (text.isNotEmpty) {
          parts.add(labels.isEmpty ? text : '${labels.join(', ')}. $text');
        }
        column += span;
      }
      if (!header) {
        add(parts.join('. '), row.sourceSpan ?? table.sourceSpan, lang);
      }
    }
    if (table.children.every((row) => row.attributes['header'] == 'true')) {
      add(headers.values.toSet().join('. '), table.sourceSpan, lang);
    }
  }

  String inlineText(List<BusyInline> inlines) => inlines.map(inline).join();

  NarrationOmission? _inlineOmission(BusyInline value) {
    if (!_activeVariant(value.attributes)) return NarrationOmission.hidden;
    return switch (value.kind) {
      BusyInlineKind.math => NarrationOmission.math,
      BusyInlineKind.audio => NarrationOmission.media,
      BusyInlineKind.html ||
      BusyInlineKind.unknown ||
      BusyInlineKind.writersideVariable => NarrationOmission.hidden,
      BusyInlineKind.image when !rules.images => NarrationOmission.images,
      BusyInlineKind.code when !rules.inlineCode => NarrationOmission.code,
      BusyInlineKind.link when value.destination?.startsWith('#fn') == true =>
        NarrationOmission.footnotes,
      _ => null,
    };
  }

  String inline(BusyInline value) {
    final omission = _inlineOmission(value);
    if (omission != null) {
      omissions.add(omission);
      return '';
    }
    String label() =>
        value.children.isEmpty ? value.text : inlineText(value.children);
    return switch (value.kind) {
      BusyInlineKind.link when rules.links == NarrationLinks.skip => '',
      BusyInlineKind.link => _link(label(), value.destination),
      BusyInlineKind.softBreak || BusyInlineKind.hardBreak => ' ',
      _ => label(),
    };
  }

  String _link(String label, String? href) {
    final url = Uri.tryParse(label.trim());
    final bare =
        label == href ||
        label == href?.replaceFirst('mailto:', '') ||
        url != null &&
            (url.scheme == 'http' ||
                url.scheme == 'https' ||
                url.scheme == 'mailto');
    if (rules.links == NarrationLinks.labelAndUrl && href != null) {
      return bare ? href : '$label $href';
    }
    return bare ? '' : label;
  }

  void visitXmlSelection(
    BusyBlock block,
    int start,
    int end, {
    String? inheritedLanguage,
  }) {
    final span = block.sourceSpan;
    if (!owns(span) || span!.startOffset >= end || span.endOffset <= start) {
      return;
    }
    if (start <= span.startOffset && span.endOffset <= end) {
      visit(block, inheritedLanguage: inheritedLanguage);
      return;
    }
    final omission = skip(block);
    if (omission != null) {
      omissions.add(omission);
      if (omission != NarrationOmission.headings) return;
    }
    final lang = block.attributes['lang'] ?? inheritedLanguage;
    if (block.kind == BusyBlockKind.codeBlock) {
      omissions.add(NarrationOmission.unmappedSelection);
      return;
    }
    if (omission == null) {
      add(
        block.inlines.map((value) => _clipXml(value, start, end)).join(),
        SourceSpan.fromOffsets(
          filePath: span.filePath,
          source: source,
          startOffset: start.clamp(span.startOffset, span.endOffset),
          endOffset: end.clamp(span.startOffset, span.endOffset),
        ),
        lang,
        heading: block.kind == BusyBlockKind.heading,
      );
    }
    for (final child in _children(block)) {
      visitXmlSelection(child, start, end, inheritedLanguage: lang);
    }
  }

  String _clipXml(BusyInline value, int start, int end) {
    final span = value.sourceSpan;
    if (span == null) return '';
    if (!owns(span)) {
      omissions.add(NarrationOmission.unmappedSelection);
      return '';
    }
    if (span.startOffset >= end || span.endOffset <= start) return '';
    final omission = _inlineOmission(value);
    if (omission != null) {
      omissions.add(omission);
      return '';
    }
    final fullySelected = start <= span.startOffset && span.endOffset <= end;
    if (value.kind == BusyInlineKind.link &&
        (rules.links == NarrationLinks.skip ||
            _link(value.plainText, value.destination).isEmpty)) {
      return '';
    }
    if (value.children.isNotEmpty) {
      final text = value.children
          .map((child) => _clipXml(child, start, end))
          .join();
      return value.kind == BusyInlineKind.link &&
              fullySelected &&
              text.isNotEmpty
          ? _link(text, value.destination)
          : text;
    }
    if (value.kind == BusyInlineKind.hardBreak) return fullySelected ? ' ' : '';
    if (value.kind == BusyInlineKind.image) {
      return fullySelected ? inline(value) : '';
    }
    if (source.substring(span.startOffset, span.endOffset) != value.text) {
      omissions.add(NarrationOmission.unmappedSelection);
      return '';
    }
    final result = StringBuffer();
    var offset = span.startOffset;
    for (final character in value.text.characters) {
      final boundary = offset + character.length;
      if (offset >= start && boundary <= end) {
        result.write(character);
      } else if (offset < end && boundary > start) {
        omissions.add(NarrationOmission.unmappedSelection);
      }
      offset = boundary;
    }
    return result.toString();
  }

  void partial(BusyBlock block, int start, int end) {
    final omission = skip(block);
    if (omission != null) {
      omissions.add(omission);
      return;
    }
    final span = block.sourceSpan!;
    if (document.isXmlTopic || block.kind == BusyBlockKind.codeBlock) {
      omissions.add(NarrationOmission.unmappedSelection);
      return;
    }
    final fragment = source.substring(span.startOffset, span.endOffset);
    final mapped = _inlineParser.parsePositionedBlocks(
      fragment,
      includeCodeBlocks: false,
      requireUnambiguousPositions: true,
    );
    if (mapped.isEmpty) {
      omissions.add(NarrationOmission.unmappedSelection);
    }
    for (final part in mapped) {
      if (!part.positionRecordsComplete) {
        omissions.add(NarrationOmission.unmappedSelection);
        continue;
      }
      final partStart = part.sourceStart ?? 0;
      final partEnd = part.sourceEnd ?? fragment.length;
      String clip(List<BusyInline> values, int left, int right) {
        final result = StringBuffer();
        var cursor = left;
        for (final (index, value) in values.indexed) {
          final range = part.ranges[value];
          if (range == null &&
              (value.kind == BusyInlineKind.softBreak ||
                  value.kind == BusyInlineKind.hardBreak)) {
            result.write(' ');
            continue;
          }
          final next =
              values
                  .skip(index + 1)
                  .map((item) => part.ranges[item]?.start)
                  .whereType<int>()
                  .firstOrNull ??
              right;
          final candidate =
              range?.start ?? fragment.indexOf(value.text, cursor);
          final finish = range?.end ?? candidate + value.text.length;
          if (candidate < cursor || finish > next || finish > right) {
            omissions.add(NarrationOmission.unmappedSelection);
            continue;
          }
          cursor = finish;
          final a = start - span.startOffset;
          final b = end - span.startOffset;
          if (candidate >= b || finish <= a) continue;
          if (a <= candidate && finish <= b) {
            result.write(inline(value));
            continue;
          }
          if (value.kind == BusyInlineKind.audio ||
              value.kind == BusyInlineKind.math ||
              value.kind == BusyInlineKind.image ||
              value.kind == BusyInlineKind.html) {
            continue;
          }
          if (value.kind == BusyInlineKind.link &&
              (rules.links == NarrationLinks.skip ||
                  _link(value.plainText, value.destination).isEmpty)) {
            continue;
          }
          if (value.children.isNotEmpty) {
            result.write(
              clip(
                value.children,
                range?.labelStart ?? candidate,
                range?.labelEnd ?? finish,
              ),
            );
            continue;
          }
          if (value.kind == BusyInlineKind.text &&
              finish - candidate == value.text.length &&
              fragment.startsWith(value.text, candidate)) {
            var offset = candidate;
            for (final character in value.text.characters) {
              final boundary = offset + character.length;
              if (offset >= a && boundary <= b) result.write(character);
              offset = boundary;
            }
          } else {
            omissions.add(NarrationOmission.unmappedSelection);
          }
        }
        return result.toString();
      }

      add(
        clip(part.inlines, partStart, partEnd),
        SourceSpan.fromOffsets(
          filePath: span.filePath,
          source: source,
          startOffset: start.clamp(span.startOffset, span.endOffset),
          endOffset: end.clamp(span.startOffset, span.endOffset),
        ),
        block.attributes['lang'],
      );
    }
  }
}
