import '../editor/wysiwyg/wysiwyg_inline_controller.dart';
import '../markdown/busymark_document.dart';
import '../markdown/busymark_markdown_serializer.dart';
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
            complete: sourceRun.complete,
          ),
        );
      }
    }

    void visit(BusyBlock block) {
      if (block.isGenerated ||
          block.isSourceProtected ||
          block.isSourceOnly ||
          !_eligibleBlockKinds.contains(block.kind)) {
        return;
      }
      if (block.kind == BusyBlockKind.table) {
        for (final row in block.children) {
          for (final cell in row.children) {
            final target = SpellingRichTableCellTarget(
              tableBlockId: block.id,
              cellId: cell.id,
              documentGeneration: documentGeneration,
            );
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
        if (busyMarkWysiwygBlockContainsMath(block)) {
          addMathSource(block, target);
        } else {
          addOrdinary(block, target);
        }
      }
      for (final child in block.children) {
        visit(child);
      }
    }

    for (final block in document.blocks) {
      visit(block);
    }
    final source = document.source;
    if (source == null) {
      return SpellingProjectionResult(
        runs: List.unmodifiable(richRuns),
        complete: complete,
        message: complete ? null : 'Some rich-text fields could not be mapped.',
      );
    }

    final serialized = const BusyMarkMarkdownSerializer().serialize(document);
    final sourceProjection = const MarkdownSpellingProjector().project(
      filePath: document.filePath,
      source: source,
      mode: document.mode,
      languageId: languageId,
      snapshot: snapshot,
    );
    final merged = _mergeCurrentSourceMappings(
      richRuns: richRuns,
      sourceRuns: sourceProjection.runs,
    );
    complete =
        complete &&
        sourceProjection.complete &&
        merged.allRichRunsMapped &&
        serialized == source;
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
}) {
  final result = <SpellingProseRun>[];
  var richCursor = 0;
  var allRichRunsMapped = true;
  for (final sourceRun in sourceRuns) {
    final richRun = richCursor < richRuns.length ? richRuns[richCursor] : null;
    if (richRun == null || !_compatibleRuns(sourceRun, richRun)) {
      result.add(sourceRun);
      continue;
    }
    final mergedAtoms = _mergeRunAtoms(sourceRun, richRun);
    if (mergedAtoms == null) {
      allRichRunsMapped = false;
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
        complete: sourceRun.complete && richRun.complete,
      ),
    );
    richCursor++;
  }
  if (richCursor < richRuns.length) {
    allRichRunsMapped = false;
    result.addAll(richRuns.skip(richCursor));
  }
  return _MergedRichProjection(
    runs: List.unmodifiable(result),
    allRichRunsMapped: allRichRunsMapped,
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
    final fieldStart = richAtom.fieldStart;
    final fieldEnd = richAtom.fieldEnd;
    if (fieldStart == null || fieldEnd == null) return null;
    final localStart = sourceAtom.logicalStart - richAtom.logicalStart;
    final localEnd = sourceAtom.logicalEnd - richAtom.logicalStart;
    if (fieldStart + localEnd > fieldEnd) return null;
    result.add(
      SpellingSourceAtom(
        logicalText: sourceAtom.logicalText,
        logicalStart: sourceAtom.logicalStart,
        logicalEnd: sourceAtom.logicalEnd,
        sourceStart: sourceAtom.sourceStart,
        sourceEnd: sourceAtom.sourceEnd,
        fieldStart: fieldStart + localStart,
        fieldEnd: fieldStart + localEnd,
        richLeafPath: richAtom.richLeafPath,
        transformation: sourceAtom.transformation,
        context: sourceAtom.context,
      ),
    );
  }
  return List.unmodifiable(result);
}

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
