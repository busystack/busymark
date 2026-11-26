import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;

import '../../core/uri_utils.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/busymark_markdown_serializer.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/raw_html_adapter.dart';
import '../../markdown/raw_html_policy.dart';
import '../../platform/rich_clipboard_service.dart';
import '../../writerside/writerside_html_reference_scanner.dart';
import '../../writerside/writerside_video.dart';
import '../inline_semantics.dart';
import 'wysiwyg_document_controller.dart';
import 'wysiwyg_inline_controller.dart';

const _maxNodes = 10000;
const _maxDepth = 64;

class WysiwygClipboardFragment {
  const WysiwygClipboardFragment({
    required this.blocks,
    required this.mode,
    this.sourcePath = '',
    this.mediaPaths = const {},
  });

  final List<BusyWysiwygStyledBlock> blocks;
  final MarkdownMode mode;
  final String sourcePath;
  final Map<String, String> mediaPaths;

  List<BusyBlock> get documentBlocks => [
    for (final block in blocks) busyMarkWysiwygClipboardBlock(block),
  ];

  String get markdown => const BusyMarkMarkdownSerializer().serialize(
    BusyDocument(filePath: sourcePath, mode: mode, blocks: documentBlocks),
  );

  String serializeFor({
    required MarkdownMode destinationMode,
    required String destinationFilePath,
  }) => const BusyMarkMarkdownSerializer().serialize(
    BusyDocument(
      filePath: destinationFilePath,
      mode: destinationMode,
      blocks: [
        for (final block in documentBlocks)
          _destinationSerializationBlock(block),
      ],
    ),
  );

  bool get isInlineSourceFragment {
    final values = documentBlocks;
    return values.length == 1 &&
        !busyMarkClipboardRequiresCompleteBlockInsertion(blocks.single) &&
        values.single.kind == BusyBlockKind.paragraph &&
        values.single.children.isEmpty &&
        !values.single.isSourceOnly;
  }

  String serializeInlineFor({
    required MarkdownMode destinationMode,
    required String destinationFilePath,
    bool tableCell = false,
    bool atBlockStart = false,
  }) {
    final inlines = sourceInsertionInlinesFor(tableCell: tableCell);
    if (inlines.isEmpty) return '';
    return const BusyMarkMarkdownSerializer().serializeInlineFragment(
      inlines,
      tableCell: tableCell,
      atBlockStart: atBlockStart,
      readableHardBreakRuns: !tableCell,
    );
  }

  /// Returns the exact semantic inline sequence used for Source insertion.
  /// Table destinations receive the same flattened, newline-free model as
  /// Editor table-cell insertion.
  List<BusyInline> sourceInsertionInlinesFor({required bool tableCell}) {
    final values = sourceInsertionBlocks;
    if (tableCell) {
      return busyMarkTableCellInlinesFromBlocks(values);
    }
    if (!isInlineSourceFragment) return const [];
    return values.single.inlines;
  }

  List<BusyBlock> get sourceInsertionBlocks => List.unmodifiable([
    for (final block in documentBlocks) _destinationSerializationBlock(block),
  ]);

  /// Flattens structured blocks with the same semantics as an Editor table
  /// cell: block and line boundaries become spaces and inline styles survive.
  String serializeTableCellFor({
    required MarkdownMode destinationMode,
    required String destinationFilePath,
    bool atBlockStart = false,
  }) {
    final inlines = sourceInsertionInlinesFor(tableCell: true);
    return const BusyMarkMarkdownSerializer().serializeInlineFragment(
      inlines,
      tableCell: true,
      atBlockStart: atBlockStart,
      readableHardBreakRuns: false,
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'mode': mode.name,
    'sourcePath': sourcePath,
    'mediaPaths': mediaPaths,
    'blocks': [
      for (final block in blocks)
        {
          'kind': block.kind.name,
          'text': block.text,
          'attributes': block.attributes,
          'ranges': [
            for (final range in block.ranges)
              {
                'start': range.start,
                'end': range.end,
                'kind': range.kind.name,
                if (range.destination != null) 'destination': range.destination,
                if (range.attributes.isNotEmpty) 'attributes': range.attributes,
              },
          ],
          if (block.completeBlock != null)
            'completeBlock': _encodeBlock(block.completeBlock!),
        },
    ],
  });

  static WysiwygClipboardFragment? decode(String source) {
    if (source.length > maxRichClipboardBytes ||
        utf8.encode(source).length > maxRichClipboardBytes ||
        !_boundedJsonDepth(source)) {
      return null;
    }
    try {
      final reader = _FragmentReader();
      final map = reader.map(jsonDecode(source));
      if (map['version'] != 1) return null;
      final mode = MarkdownMode.values.byName(reader.string(map['mode']));
      final origin = reader.string(map['sourcePath']);
      final media = map['mediaPaths'] == null
          ? const <String, String>{}
          : reader.attributes(map['mediaPaths']);
      final blocks = <BusyWysiwygStyledBlock>[];
      for (final item in reader.list(map['blocks'])) {
        reader.visit(0);
        final block = reader.map(item);
        final kind = BusyBlockKind.values.byName(reader.string(block['kind']));
        final text = reader.string(block['text']);
        final ranges = <BusyInlineStyleRange>[];
        for (final item in reader.list(block['ranges'])) {
          reader.visit(0);
          final range = reader.map(item);
          final start = range['start'];
          final end = range['end'];
          if (start is! int ||
              end is! int ||
              start < 0 ||
              end < start ||
              end > text.length) {
            throw const FormatException('Invalid clipboard text range');
          }
          ranges.add(
            BusyInlineStyleRange(
              start: start,
              end: end,
              kind: BusyInlineKind.values.byName(reader.string(range['kind'])),
              destination: reader.optionalString(range['destination']),
              attributes: range['attributes'] == null
                  ? const {}
                  : reader.attributes(range['attributes']),
            ),
          );
        }
        final complete = block['completeBlock'] == null
            ? null
            : reader.block(block['completeBlock'], 0);
        if (complete != null &&
            (complete.kind != kind || complete.plainText != text)) {
          throw const FormatException('Inconsistent clipboard block');
        }
        blocks.add(
          BusyWysiwygStyledBlock(
            kind: kind,
            text: text,
            ranges: List.unmodifiable(ranges),
            attributes: reader.attributes(block['attributes']),
            completeBlock: complete,
          ),
        );
      }
      return blocks.isEmpty
          ? null
          : WysiwygClipboardFragment(
              blocks: List.unmodifiable(blocks),
              mode: mode,
              sourcePath: origin,
              mediaPaths: media,
            );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  /// Rebase authored references, without opening or fetching clipboard URLs.
  WysiwygClipboardFragment rebase(
    String targetPath, {
    Map<String, String> mediaDestinations = const {},
  }) {
    final rebaseRelativeReferences =
        sourcePath.isNotEmpty &&
        targetPath.isNotEmpty &&
        !p.equals(sourcePath, targetPath);
    if (!rebaseRelativeReferences && mediaDestinations.isEmpty) {
      return this;
    }
    String? destination(
      String? value, {
      bool media = false,
      bool rawHtml = false,
    }) {
      if (value == null || value.isEmpty) return value;
      final uri = Uri.tryParse(value);
      if (uri == null) return value;
      final retained = media ? mediaDestinations[value] : null;
      if (retained != null) {
        return withReferenceSuffix(Uri.parse(retained), uri).toString();
      }
      if (!rebaseRelativeReferences || uri.hasScheme || uri.hasAuthority) {
        return value;
      }
      final mediaPath = media ? mediaPaths[value] : null;
      if (!rawHtml && mediaPath != null && p.isAbsolute(mediaPath)) {
        return withReferenceSuffix(Uri(path: mediaPath), uri).toString();
      }
      final resolvedPath = mediaPath != null && p.isAbsolute(mediaPath)
          ? mediaPath
          : Uri(
              scheme: 'file',
              path: Uri.file(p.absolute(sourcePath)).resolveUri(uri).path,
            ).toFilePath();
      final path = p.relative(
        resolvedPath,
        from: p.dirname(p.absolute(targetPath)),
      );
      return withReferenceSuffix(Uri(path: path), uri).toString();
    }

    Map<String, String> attributes(
      Map<String, String> values, {
      bool rawHtml = false,
      Set<String> mediaAttributes = const {'src'},
    }) => {
      for (final entry in values.entries)
        entry.key:
            mediaAttributes.contains(entry.key) ||
                const {'href', 'destination', 'cite'}.contains(entry.key)
            ? destination(
                    entry.value,
                    media: mediaAttributes.contains(entry.key),
                    rawHtml: rawHtml,
                  ) ??
                  entry.value
            : entry.value,
    };
    BusyInline inline(BusyInline value, bool rawHtml) => BusyInline(
      kind: value.kind,
      text: value.text,
      destination: destination(
        value.destination,
        media: value.kind == BusyInlineKind.image,
        rawHtml: rawHtml,
      ),
      attributes: attributes(value.attributes, rawHtml: rawHtml),
      children: [for (final child in value.children) inline(child, rawHtml)],
      imageSpan: value.imageSpan,
    );
    String? rebaseHtml(String? source) {
      if (source == null) return null;
      final fragment = const RawHtmlAdapter().parseSafeRawHtml(source);
      if (fragment == null) return source;
      var changed = false;
      for (final element in fragment.querySelectorAll(
        '[href], [src], [cite]',
      )) {
        final tag = element.localName!;
        final allowed = sanitizeHtmlAttributes(tag, element.attributes)!;
        for (final attribute in const ['href', 'src', 'cite']) {
          final previous = allowed[attribute];
          if (previous == null) continue;
          final updated = destination(
            previous,
            media: tag == 'img' && attribute == 'src',
            rawHtml: true,
          );
          if (updated != null && updated != previous) {
            element.attributes[attribute] = updated;
            changed = true;
          }
        }
      }
      return changed ? fragment.outerHtml : source;
    }

    BusyBlock block(BusyBlock value, {bool withinRawHtml = false}) {
      final rawHtml = withinRawHtml || value.kind == BusyBlockKind.htmlBlock;
      final rebasedAttributes = attributes(
        value.attributes,
        rawHtml: rawHtml,
        mediaAttributes: value.kind == BusyBlockKind.video
            ? busyMarkVideoMediaAttributes
            : const {'src'},
      );
      final rebasedInlines = [
        for (final child in value.inlines) inline(child, rawHtml),
      ];
      bool referencesChanged(BusyInline before, BusyInline after) =>
          before.destination != after.destination ||
          !mapEquals(before.attributes, after.attributes) ||
          [
            for (var i = 0; i < before.children.length; i++)
              referencesChanged(before.children[i], after.children[i]),
          ].any((v) => v);
      final source = value.rawSource;
      final rawSource = switch (value.kind) {
        BusyBlockKind.video when source != null =>
          const WritersideAuthoredHtmlReferenceScanner()
              .rewriteAttributeValues(source, 'video', {
                for (final name in busyMarkVideoMediaAttributes)
                  if (rebasedAttributes[name] case final reference?
                      when reference != value.attributes[name])
                    name: reference,
              }),
        BusyBlockKind.htmlBlock => rebaseHtml(value.rawSource),
        _ => value.rawSource,
      };
      return BusyBlock(
        id: value.id,
        kind: value.kind,
        inlines: rebasedInlines,
        children: [
          for (final child in value.children)
            block(child, withinRawHtml: rawHtml),
        ],
        attributes: rebasedAttributes,
        rawSource: rawSource,
        preserveRaw: value.preserveRaw,
        isSourceOnly: value.isSourceOnly,
        isGenerated: value.isGenerated,
        isSourceProtected: value.isSourceProtected,
        dirty:
            value.dirty ||
            rawSource != value.rawSource ||
            !mapEquals(value.attributes, rebasedAttributes) ||
            [
              for (var i = 0; i < value.inlines.length; i++)
                referencesChanged(value.inlines[i], rebasedInlines[i]),
            ].any((v) => v),
      );
    }

    return WysiwygClipboardFragment(
      mode: mode,
      sourcePath: targetPath.isEmpty ? sourcePath : targetPath,
      mediaPaths: mediaPaths,
      blocks: [
        for (final value in blocks)
          BusyWysiwygStyledBlock(
            kind: value.kind,
            text: value.text,
            attributes: attributes(value.attributes),
            ranges: [
              for (final range in value.ranges)
                BusyInlineStyleRange(
                  start: range.start,
                  end: range.end,
                  kind: range.kind,
                  attributes: attributes(range.attributes),
                  destination: destination(
                    range.destination,
                    media: range.kind == BusyInlineKind.image,
                  ),
                ),
            ],
            completeBlock: value.completeBlock == null
                ? null
                : block(value.completeBlock!),
          ),
      ],
    );
  }
}

Map<String, Object?> _encodeInline(BusyInline inline) => {
  'kind': inline.kind.name,
  'text': inline.text,
  if (inline.destination != null) 'destination': inline.destination,
  'attributes': inline.attributes,
  'children': [for (final child in inline.children) _encodeInline(child)],
};

Map<String, Object?> _encodeBlock(BusyBlock block) => {
  'kind': block.kind.name,
  'inlines': [for (final inline in block.inlines) _encodeInline(inline)],
  'children': [for (final child in block.children) _encodeBlock(child)],
  'attributes': block.attributes,
  if (block.rawSource != null) 'rawSource': block.rawSource,
  'preserveRaw': block.preserveRaw,
  'sourceOnly': block.isSourceOnly,
  'generated': block.isGenerated,
  'sourceProtected': block.isSourceProtected,
  'dirty': block.dirty,
};

bool _boundedJsonDepth(String source) {
  var depth = 0;
  var quoted = false;
  var escaped = false;
  for (final unit in source.codeUnits) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (unit == 92) {
        escaped = true;
      } else if (unit == 34) {
        quoted = false;
      }
    } else if (unit == 34) {
      quoted = true;
    } else if (unit == 91 || unit == 123) {
      if (++depth > _maxDepth * 2 + 8) return false;
    } else if (unit == 93 || unit == 125) {
      depth--;
    }
  }
  return true;
}

BusyBlock _destinationSerializationBlock(
  BusyBlock block, {
  bool authoredStructure = false,
}) => BusyBlock(
  id: block.id,
  kind: block.kind,
  inlines: block.inlines,
  children: [
    for (final child in block.children)
      _destinationSerializationBlock(
        child,
        authoredStructure:
            authoredStructure || busyMarkIsWritersideContainer(block),
      ),
  ],
  attributes: block.attributes,
  rawSource: block.rawSource,
  preserveRaw: false,
  isSourceOnly: block.isSourceOnly,
  isGenerated: block.isGenerated,
  isSourceProtected: false,
  dirty: authoredStructure || busyMarkIsWritersideContainer(block)
      ? block.dirty
      : true,
);

class _FragmentReader {
  var nodes = 0;

  void visit(int depth) {
    if (++nodes > _maxNodes || depth > _maxDepth) {
      throw const FormatException('Clipboard nesting or node limit exceeded');
    }
  }

  Map<String, dynamic> map(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected object');
    }
    return value;
  }

  List<dynamic> list(dynamic value) {
    if (value is! List || value.length > _maxNodes) {
      throw const FormatException('Expected bounded list');
    }
    return value;
  }

  String string(dynamic value) {
    if (value is! String || value.contains('\u0000')) {
      throw const FormatException('Expected text');
    }
    return value;
  }

  String? optionalString(dynamic value) => value == null ? null : string(value);
  bool boolean(dynamic value) {
    if (value is! bool) throw const FormatException('Expected boolean');
    return value;
  }

  Map<String, String> attributes(dynamic value) {
    final entries = map(value);
    if (entries.length > 256) {
      throw const FormatException('Too many attributes');
    }
    return Map.unmodifiable({
      for (final entry in entries.entries) entry.key: string(entry.value),
    });
  }

  BusyInline inline(dynamic value, int depth) {
    visit(depth);
    final data = map(value);
    return BusyInline(
      kind: BusyInlineKind.values.byName(string(data['kind'])),
      text: string(data['text']),
      destination: optionalString(data['destination']),
      attributes: attributes(data['attributes']),
      children: List.unmodifiable([
        for (final child in list(data['children'])) inline(child, depth + 1),
      ]),
    );
  }

  BusyBlock block(dynamic value, int depth) {
    visit(depth);
    final data = map(value);
    final id = 'clipboard-$nodes';
    return BusyBlock(
      id: id,
      kind: BusyBlockKind.values.byName(string(data['kind'])),
      inlines: List.unmodifiable([
        for (final child in list(data['inlines'])) inline(child, depth + 1),
      ]),
      children: List.unmodifiable([
        for (final child in list(data['children'])) block(child, depth + 1),
      ]),
      attributes: attributes(data['attributes']),
      rawSource: optionalString(data['rawSource']),
      preserveRaw: boolean(data['preserveRaw']),
      isSourceOnly: boolean(data['sourceOnly']),
      isGenerated: boolean(data['generated']),
      isSourceProtected: boolean(data['sourceProtected']),
      dirty: data['dirty'] == null || boolean(data['dirty']),
    );
  }
}
