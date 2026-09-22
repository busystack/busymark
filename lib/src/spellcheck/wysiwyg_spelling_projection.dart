import '../editor/wysiwyg/wysiwyg_inline_controller.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_parser.dart';
import '../markdown/markdown_source_structure.dart';
import 'markdown_spelling_projection.dart';
import 'spelling_inline_projection.dart';
import 'spelling_projection.dart';

final class WysiwygSpellingProjector {
  const WysiwygSpellingProjector();

  SpellingProjectionResult project({
    required BusyDocument document,
    required String languageId,
    required SpellingSnapshotIdentity snapshot,
    required int documentGeneration,
  }) {
    final richRuns = <SpellingProseRun>[];
    final fieldKeysByTarget = <String, String>{};
    var sequence = 0;
    var complete = true;

    void addOrdinary(BusyBlock block, SpellingEditorTarget target) {
      for (final projection in projectSpellingInlineRuns(
        inlines: block.inlines,
        sourceBase: -1,
        context: target is SpellingRichTableCellTarget
            ? SpellingSourceContext.markdownTableCell
            : SpellingSourceContext.markdownProse,
      )) {
        final run = SpellingProseRun(
          id: 'wysiwyg:${sequence++}:${block.id}',
          text: projection.text,
          languageId: languageId,
          atoms: projection.atoms,
          target: target,
          snapshot: snapshot,
          tokenizationContext: projection.tokenizationContext,
          tokenizationContextStart: projection.tokenizationContextStart,
        );
        if (run.hasValidMapping) {
          richRuns.add(run);
        } else {
          complete = false;
        }
      }
    }

    void addMathSource(BusyBlock block, SpellingEditorTarget target) {
      final fieldText = busyMarkWysiwygEditableText(block);
      final projected = const MarkdownSpellingProjector().project(
        filePath: document.filePath,
        source: fieldText,
        mode: document.mode,
        languageId: languageId,
        snapshot: snapshot,
        proseContext: target is SpellingRichTableCellTarget
            ? SpellingSourceContext.markdownTableCell
            : SpellingSourceContext.markdownProse,
      );
      complete = complete && projected.complete;
      for (final sourceRun in projected.runs) {
        richRuns.add(
          SpellingProseRun(
            id: 'wysiwyg-math:${sequence++}:${block.id}',
            text: sourceRun.text,
            languageId: languageId,
            atoms: [
              for (final atom in sourceRun.atoms)
                SpellingSourceAtom(
                  logicalText: atom.logicalText,
                  logicalStart: atom.logicalStart,
                  logicalEnd: atom.logicalEnd,
                  sourceStart: -1,
                  sourceEnd: -1,
                  fieldStart: atom.sourceStart,
                  fieldEnd: atom.sourceEnd,
                  transformation: atom.transformation,
                  context: atom.context,
                ),
            ],
            target: target,
            snapshot: snapshot,
            formattingWrappers: [
              for (final wrapper in sourceRun.formattingWrappers)
                SpellingFormattingWrapper(
                  logicalStart: wrapper.logicalStart,
                  logicalEnd: wrapper.logicalEnd,
                  openingStart: -1,
                  openingEnd: -1,
                  closingStart: -1,
                  closingEnd: -1,
                  removableWhenLogicallyEmpty:
                      wrapper.removableWhenLogicallyEmpty,
                  fieldOpeningStart: wrapper.openingStart,
                  fieldOpeningEnd: wrapper.openingEnd,
                  fieldClosingStart: wrapper.closingStart,
                  fieldClosingEnd: wrapper.closingEnd,
                  structuralKind: wrapper.structuralKind,
                ),
            ],
            complete: sourceRun.complete,
            tokenizationContext: sourceRun.tokenizationContext,
            tokenizationContextStart: sourceRun.tokenizationContextStart,
          ),
        );
      }
    }

    void visit(BusyBlock block, List<int> path) {
      if (block.isGenerated ||
          block.isSourceProtected ||
          block.isSourceOnly ||
          !_eligibleBlockKinds.contains(block.kind)) {
        return;
      }
      if (block.kind == BusyBlockKind.table) {
        for (final (rowIndex, row) in block.children.indexed) {
          for (final (columnIndex, cell) in row.children.indexed) {
            final target = SpellingRichTableCellTarget(
              tableBlockId: block.id,
              cellId: cell.id,
              documentGeneration: documentGeneration,
            );
            fieldKeysByTarget[_targetIdentity(target)] =
                '${path.join('.')}:table:$rowIndex:$columnIndex';
            if (busyMarkWysiwygBlockContainsMath(cell)) {
              addMathSource(cell, target);
            } else {
              addOrdinary(cell, target);
            }
          }
        }
        return;
      }
      if (block.inlines.isNotEmpty) {
        final target = SpellingRichBlockTarget(
          blockId: block.id,
          documentGeneration: documentGeneration,
        );
        fieldKeysByTarget[_targetIdentity(target)] = '${path.join('.')}:block';
        if (busyMarkWysiwygBlockContainsMath(block)) {
          addMathSource(block, target);
        } else {
          addOrdinary(block, target);
        }
      }
      for (final (index, child) in block.children.indexed) {
        visit(child, [...path, index]);
      }
    }

    for (final (index, block) in document.blocks.indexed) {
      visit(block, [index]);
    }
    final source = document.source;
    if (source == null) {
      return SpellingProjectionResult(
        runs: List.unmodifiable(richRuns),
        complete: complete,
        message: complete ? null : 'Some rich-text fields could not be mapped.',
      );
    }

    final sourceProjection = const MarkdownSpellingProjector().project(
      filePath: document.filePath,
      source: source,
      mode: document.mode,
      languageId: languageId,
      snapshot: snapshot,
    );
    final currentDocument = const MarkdownParser()
        .parse(
          filePath: document.filePath,
          source: source,
          mode: document.mode,
          validateLocalReferences: false,
        )
        .busyDocument;
    var merged = _mergeCurrentSourceMappings(
      richRuns: richRuns,
      sourceRuns: sourceProjection.runs,
      fieldKeysByTarget: fieldKeysByTarget,
      sourceRegions: _sourceFieldRegions(source, currentDocument.blocks),
    );
    if (!merged.allRichRunsMapped) {
      // The parser deliberately omits some block spans when its lossless
      // scanner and AST have different container shapes (e.g. nested lists).
      // Live editor-only empty paragraphs can also shift tree paths. In that
      // case require an exact, complete ordered correspondence of prose runs;
      // never search ahead for matching text or publish a partial guessed
      // pairing. Repeated words retain their occurrence order and provenance.
      final ordered = _mergeFieldMappings(
        richRuns: richRuns,
        sourceRuns: sourceProjection.runs,
        sourceOnlyRegions: _sourceOnlyRegions(currentDocument.blocks),
      );
      if (ordered.allRichRunsMapped) merged = ordered;
    }
    // document.source is the source already committed by the workspace. Dirty
    // blocks can retain pre-edit spans; serializing this rebased tree a second
    // time is not a validity check and can apply the same edit twice. Validate
    // the complete rich/source correspondence instead.
    complete =
        complete && sourceProjection.complete && merged.allRichRunsMapped;
    return SpellingProjectionResult(
      runs: merged.runs,
      complete: complete,
      message: complete
          ? null
          : 'Some rich-text fields could not be mapped to the current source.',
    );
  }
}

final class _MergedRichProjection {
  const _MergedRichProjection({
    required this.runs,
    required this.allRichRunsMapped,
  });

  final List<SpellingProseRun> runs;
  final bool allRichRunsMapped;
}

/// Pairs the live rich fields with the current authored source in source
/// order. Extra source runs (for example a link title with no rich field) stay
/// source targets, while matched runs retain both their exact source atoms and
/// their rich leaf addresses.
_MergedRichProjection _mergeCurrentSourceMappings({
  required List<SpellingProseRun> richRuns,
  required List<SpellingProseRun> sourceRuns,
  required Map<String, String> fieldKeysByTarget,
  required List<_SourceFieldRegion> sourceRegions,
}) {
  final richByField = <String, List<SpellingProseRun>>{};
  for (final run in richRuns) {
    final key = fieldKeysByTarget[_targetIdentity(run.target)];
    if (key == null) continue;
    richByField.putIfAbsent(key, () => []).add(run);
  }
  final sourceByField = <String, List<SpellingProseRun>>{};
  final sourceFieldKeys = <SpellingProseRun, String>{};
  for (final run in sourceRuns) {
    int? start;
    int? end;
    for (final atom in run.atoms) {
      if (atom.sourceStart < 0 || atom.sourceEnd < 0) continue;
      start = start == null || atom.sourceStart < start
          ? atom.sourceStart
          : start;
      end = end == null || atom.sourceEnd > end ? atom.sourceEnd : end;
    }
    if (start == null || end == null) continue;
    _SourceFieldRegion? region;
    for (final candidate in sourceRegions) {
      if (candidate.start > start || candidate.end < end) continue;
      if (region == null ||
          candidate.end - candidate.start < region.end - region.start) {
        region = candidate;
      }
    }
    if (region == null) continue;
    sourceFieldKeys[run] = region.key;
    sourceByField.putIfAbsent(region.key, () => []).add(run);
  }

  final mergedByField = <String, _MergedRichProjection>{};
  var allRichRunsMapped = true;
  for (final entry in richByField.entries) {
    final merged = _mergeFieldMappings(
      richRuns: entry.value,
      sourceRuns: sourceByField[entry.key] ?? const [],
    );
    mergedByField[entry.key] = merged;
    allRichRunsMapped = allRichRunsMapped && merged.allRichRunsMapped;
  }

  final result = <SpellingProseRun>[];
  final emittedFields = <String>{};
  for (final sourceRun in sourceRuns) {
    final key = sourceFieldKeys[sourceRun];
    if (key == null || !richByField.containsKey(key)) {
      result.add(sourceRun);
    } else if (emittedFields.add(key)) {
      result.addAll(mergedByField[key]!.runs);
    }
  }
  for (final entry in richByField.entries) {
    if (emittedFields.add(entry.key)) {
      result.addAll(mergedByField[entry.key]!.runs);
      allRichRunsMapped = false;
    }
  }
  return _MergedRichProjection(
    runs: List.unmodifiable(result),
    allRichRunsMapped: allRichRunsMapped,
  );
}

_MergedRichProjection _mergeFieldMappings({
  required List<SpellingProseRun> richRuns,
  required List<SpellingProseRun> sourceRuns,
  List<({int start, int end})> sourceOnlyRegions = const [],
}) {
  final result = <SpellingProseRun>[];
  var richCursor = 0;
  var complete = true;
  for (var sourceRun in sourceRuns) {
    if (_sourceOnlyMetadataRun(sourceRun) ||
        sourceOnlyRegions.any(
          (region) => sourceRun.atoms.every(
            (atom) =>
                atom.sourceStart >= region.start &&
                atom.sourceEnd <= region.end,
          ),
        )) {
      result.add(sourceRun);
      continue;
    }
    var richRun = richCursor < richRuns.length ? richRuns[richCursor] : null;
    if (richRun == null) {
      complete = false;
      result.add(sourceRun);
      continue;
    }
    // Field identity and run ordinal establish provenance. Text equality is
    // only an integrity check; a mismatch consumes this pair so it cannot
    // cascade into duplicate/falsely matched runs later in the field.
    richCursor++;
    if (sourceRun.text != richRun.text &&
        sourceRun.text.trim() == richRun.text.trim()) {
      // Boundary HTML breaks can be represented as rich whitespace atoms
      // but blank lines/indentation in Source. Ignore only that boundary space;
      // all prose and its source/field intervals must still match exactly.
      sourceRun = _withoutBoundaryWhitespace(sourceRun);
      richRun = _withoutBoundaryWhitespace(richRun);
    }
    if (!_compatibleRuns(sourceRun, richRun)) {
      complete = false;
      result.add(sourceRun);
      continue;
    }
    final mergedAtoms = _mergeRunAtoms(sourceRun, richRun);
    if (mergedAtoms == null) {
      complete = false;
      result.add(sourceRun);
      continue;
    }
    result.add(
      SpellingProseRun(
        id: richRun.id,
        text: richRun.text,
        languageId: richRun.languageId,
        atoms: mergedAtoms,
        target: richRun.target,
        snapshot: richRun.snapshot,
        formattingWrappers: _mergeFormattingWrappers(
          sourceRun.formattingWrappers,
          richRun.formattingWrappers,
        ),
        complete: sourceRun.complete && richRun.complete,
        tokenizationContext: sourceRun.tokenizationContext,
        tokenizationContextStart: sourceRun.tokenizationContextStart,
      ),
    );
  }
  if (richCursor < richRuns.length) {
    complete = false;
    result.addAll(richRuns.skip(richCursor));
  }
  return _MergedRichProjection(
    runs: List.unmodifiable(result),
    allRichRunsMapped: complete,
  );
}

// Source-only content (for example protected raw HTML) is still checked, but
// it has no editable rich field and must not consume the next rich run. Only
// current parser-provided intervals establish that distinction.
List<({int start, int end})> _sourceOnlyRegions(List<BusyBlock> blocks) {
  final result = <({int start, int end})>[];
  void visit(BusyBlock block) {
    if (!_eligibleBlockKinds.contains(block.kind) ||
        block.isSourceProtected ||
        block.isGenerated ||
        block.isSourceOnly) {
      final span = block.sourceSpan;
      if (span != null) {
        result.add((start: span.startOffset, end: span.endOffset));
      }
      return;
    }
    for (final child in block.children) {
      visit(child);
    }
  }

  for (final block in blocks) {
    visit(block);
  }
  return result;
}

SpellingProseRun _withoutBoundaryWhitespace(SpellingProseRun run) {
  final text = run.text.trim();
  if (text == run.text) return run;
  final start = run.text.length - run.text.trimLeft().length;
  final end = start + text.length;
  final atoms = <SpellingSourceAtom>[];
  for (final atom in run.atoms) {
    if (atom.logicalEnd <= start) continue;
    if (atom.logicalStart >= end) break;
    final keptStart = atom.logicalStart.clamp(start, end);
    final keptEnd = atom.logicalEnd.clamp(start, end);
    final source = atom.sourceIntervalFor(keptStart, keptEnd);
    final field = atom.fieldIntervalFor(keptStart, keptEnd);
    atoms.add(
      SpellingSourceAtom(
        logicalText: atom.logicalText.substring(
          keptStart - atom.logicalStart,
          keptEnd - atom.logicalStart,
        ),
        logicalStart: keptStart - start,
        logicalEnd: keptEnd - start,
        sourceStart: source?.start ?? -1,
        sourceEnd: source?.end ?? -1,
        fieldStart: field?.start,
        fieldEnd: field?.end,
        richLeafPath: atom.richLeafPath,
        transformation: atom.transformation,
        context: atom.context,
      ),
    );
  }
  return SpellingProseRun(
    id: run.id,
    text: text,
    languageId: run.languageId,
    atoms: atoms,
    target: run.target,
    snapshot: run.snapshot,
    formattingWrappers: [
      for (final wrapper in run.formattingWrappers)
        if (wrapper.logicalStart < end && wrapper.logicalEnd > start)
          SpellingFormattingWrapper(
            logicalStart: wrapper.logicalStart.clamp(start, end) - start,
            logicalEnd: wrapper.logicalEnd.clamp(start, end) - start,
            openingStart: wrapper.openingStart,
            openingEnd: wrapper.openingEnd,
            closingStart: wrapper.closingStart,
            closingEnd: wrapper.closingEnd,
            removableWhenLogicallyEmpty: wrapper.removableWhenLogicallyEmpty,
            fieldOpeningStart: wrapper.fieldOpeningStart,
            fieldOpeningEnd: wrapper.fieldOpeningEnd,
            fieldClosingStart: wrapper.fieldClosingStart,
            fieldClosingEnd: wrapper.fieldClosingEnd,
            structuralKind: wrapper.structuralKind,
          ),
    ],
    complete: run.complete,
    tokenizationContext: run.tokenizationContext,
    tokenizationContextStart: run.tokenizationContextStart + start,
  );
}

bool _sourceOnlyMetadataRun(SpellingProseRun run) {
  if (run.atoms.isEmpty) return false;
  return run.atoms.every(
    (atom) => switch (atom.context) {
      SpellingSourceContext.markdownSingleQuotedTitle ||
      SpellingSourceContext.markdownDoubleQuotedTitle ||
      SpellingSourceContext.xmlSingleQuotedAttribute ||
      SpellingSourceContext.xmlDoubleQuotedAttribute => true,
      _ => false,
    },
  );
}

bool _compatibleRuns(SpellingProseRun source, SpellingProseRun rich) {
  if (source.text != rich.text ||
      source.languageId != rich.languageId ||
      source.atoms.isEmpty ||
      rich.atoms.isEmpty) {
    return false;
  }
  return source.atoms.first.context == rich.atoms.first.context;
}

List<SpellingSourceAtom>? _mergeRunAtoms(
  SpellingProseRun source,
  SpellingProseRun rich,
) {
  final result = <SpellingSourceAtom>[];
  var richCursor = 0;
  for (final sourceAtom in source.atoms) {
    while (richCursor < rich.atoms.length &&
        rich.atoms[richCursor].logicalEnd <= sourceAtom.logicalStart) {
      richCursor++;
    }
    if (richCursor >= rich.atoms.length) return null;
    final richAtom = rich.atoms[richCursor];
    if (richAtom.logicalStart > sourceAtom.logicalStart ||
        richAtom.logicalEnd < sourceAtom.logicalEnd) {
      return null;
    }
    final fieldRange = richAtom.fieldIntervalFor(
      sourceAtom.logicalStart,
      sourceAtom.logicalEnd,
    );
    if (fieldRange == null) return null;
    result.add(
      SpellingSourceAtom(
        logicalText: sourceAtom.logicalText,
        logicalStart: sourceAtom.logicalStart,
        logicalEnd: sourceAtom.logicalEnd,
        sourceStart: sourceAtom.sourceStart,
        sourceEnd: sourceAtom.sourceEnd,
        fieldStart: fieldRange.start,
        fieldEnd: fieldRange.end,
        richLeafPath: richAtom.richLeafPath,
        transformation: sourceAtom.transformation,
        context: sourceAtom.context,
      ),
    );
  }
  return List.unmodifiable(result);
}

List<SpellingFormattingWrapper> _mergeFormattingWrappers(
  List<SpellingFormattingWrapper> source,
  List<SpellingFormattingWrapper> field,
) {
  final used = <int>{};
  return List.unmodifiable([
    for (final sourceWrapper in source)
      if (_matchingFieldWrapper(sourceWrapper, field, used)
          case final fieldWrapper?)
        SpellingFormattingWrapper(
          logicalStart: sourceWrapper.logicalStart,
          logicalEnd: sourceWrapper.logicalEnd,
          openingStart: sourceWrapper.openingStart,
          openingEnd: sourceWrapper.openingEnd,
          closingStart: sourceWrapper.closingStart,
          closingEnd: sourceWrapper.closingEnd,
          removableWhenLogicallyEmpty:
              sourceWrapper.removableWhenLogicallyEmpty &&
              fieldWrapper.removableWhenLogicallyEmpty,
          fieldOpeningStart: fieldWrapper.fieldOpeningStart,
          fieldOpeningEnd: fieldWrapper.fieldOpeningEnd,
          fieldClosingStart: fieldWrapper.fieldClosingStart,
          fieldClosingEnd: fieldWrapper.fieldClosingEnd,
          structuralKind: sourceWrapper.structuralKind,
        )
      else
        sourceWrapper,
  ]);
}

SpellingFormattingWrapper? _matchingFieldWrapper(
  SpellingFormattingWrapper source,
  List<SpellingFormattingWrapper> field,
  Set<int> used,
) {
  int? fallback;
  for (var index = 0; index < field.length; index++) {
    if (used.contains(index)) continue;
    final candidate = field[index];
    if (candidate.logicalStart != source.logicalStart ||
        candidate.logicalEnd != source.logicalEnd) {
      continue;
    }
    fallback ??= index;
    final sameKind = candidate.structuralKind == source.structuralKind;
    final sameDelimiterShape =
        candidate.fieldOpeningEnd! - candidate.fieldOpeningStart! ==
            source.openingEnd - source.openingStart &&
        candidate.fieldClosingEnd! - candidate.fieldClosingStart! ==
            source.closingEnd - source.closingStart;
    if (sameKind && sameDelimiterShape) {
      used.add(index);
      return candidate;
    }
  }
  if (fallback case final index?) {
    used.add(index);
    return field[index];
  }
  return null;
}

final class _SourceFieldRegion {
  const _SourceFieldRegion({
    required this.key,
    required this.start,
    required this.end,
  });

  final String key;
  final int start;
  final int end;
}

List<_SourceFieldRegion> _sourceFieldRegions(
  String source,
  List<BusyBlock> blocks,
) {
  final result = <_SourceFieldRegion>[];

  void visit(BusyBlock block, List<int> path) {
    if (block.isGenerated ||
        block.isSourceProtected ||
        block.isSourceOnly ||
        !_eligibleBlockKinds.contains(block.kind)) {
      return;
    }
    if (block.kind == BusyBlockKind.table) {
      for (final region in busyMarkMarkdownTableCellRegions(
        source: source,
        table: block,
      )) {
        result.add(
          _SourceFieldRegion(
            key: '${path.join('.')}:table:${region.row}:${region.column}',
            start: region.span.startOffset,
            end: region.span.endOffset,
          ),
        );
      }
      return;
    }
    final span = block.sourceSpan;
    if (block.inlines.isNotEmpty && span != null) {
      result.add(
        _SourceFieldRegion(
          key: '${path.join('.')}:block',
          start: span.startOffset,
          end: span.endOffset,
        ),
      );
    }
    for (final (index, child) in block.children.indexed) {
      visit(child, [...path, index]);
    }
  }

  for (final (index, block) in blocks.indexed) {
    visit(block, [index]);
  }
  return List.unmodifiable(result);
}

String _targetIdentity(SpellingEditorTarget target) => switch (target) {
  SpellingRichBlockTarget(:final blockId) => 'block:$blockId',
  SpellingRichTableCellTarget(:final tableBlockId, :final cellId) =>
    'table:$tableBlockId:$cellId',
  SpellingSourceTarget(:final filePath) => 'source:$filePath',
};

const _eligibleBlockKinds = {
  BusyBlockKind.heading,
  BusyBlockKind.paragraph,
  BusyBlockKind.unorderedListItem,
  BusyBlockKind.orderedListItem,
  BusyBlockKind.taskListItem,
  BusyBlockKind.blockquote,
  BusyBlockKind.image,
  BusyBlockKind.table,
  BusyBlockKind.writersideAdmonition,
  BusyBlockKind.writersideTabs,
  BusyBlockKind.writersideProcedure,
};
