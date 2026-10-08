import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_inline_controller.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/spellcheck/markdown_spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_projection.dart';
import 'package:busymark/src/spellcheck/spelling_replacement.dart';
import 'package:busymark/src/spellcheck/wysiwyg_spelling_projection.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _snapshot = SpellingSnapshotIdentity(
  bufferId: 'line-breaks',
  contentRevision: 1,
  documentKind: DocumentKind.markdown,
  contextGeneration: 1,
);

void _expectProseAndCorrection(
  String source,
  String expectedText,
  MarkdownMode mode,
) {
  const filePath = '/line-breaks.md';
  final document = const MarkdownParser()
      .parse(
        filePath: filePath,
        source: source,
        mode: mode,
        validateLocalReferences: false,
      )
      .busyDocument;
  final plain = const MarkdownSpellingProjector().project(
    filePath: filePath,
    source: source,
    mode: mode,
    languageId: 'en-CA',
    snapshot: _snapshot,
  );
  final rich = const WysiwygSpellingProjector().project(
    document: document,
    languageId: 'en-CA',
    snapshot: _snapshot,
    documentGeneration: 1,
  );
  for (final projection in [plain, rich]) {
    expect(
      projection.complete,
      isTrue,
      reason: '$source: ${projection.message}',
    );
    expect(projection.runs.map((run) => run.text), [
      expectedText,
    ], reason: source);
    final run = projection.runs.single;
    expect(run.hasValidMapping, isTrue);
    for (final word in ['helo', 'wrld']) {
      final offset = run.text.indexOf(word);
      final occurrence = SpellingOccurrence(
        id: word,
        run: run,
        logicalStart: offset,
        logicalEnd: offset + word.length,
        word: word,
        outcome: SpellingCheckOutcome.rejected,
      );
      expect(occurrence.sourceStart, source.indexOf(word));
      expect(occurrence.sourceEnd, source.indexOf(word) + word.length);
      final replacement = word == 'helo' ? 'hello' : 'world';
      final plan = const SpellingReplacementPlanner().build(
        occurrence: occurrence,
        suggestion: replacement,
      );
      final expectedSource = source.replaceFirst(word, replacement);
      expect(plan.applyToSource(source), expectedSource);
      if (identical(projection, rich)) {
        expect(run.target, isA<SpellingRichBlockTarget>());
        final target = run.target as SpellingRichBlockTarget;
        final controller = BusyMarkWysiwygDocumentController(
          document: document,
        );
        try {
          expect(
            controller.replaceSpellingInBlock(
              blockId: target.blockId,
              expectedFieldText: busyMarkWysiwygEditableText(
                controller.blockById(target.blockId)!,
              ),
              plan: plan,
            ),
            isTrue,
          );
          expect(controller.markdown, expectedSource);
        } finally {
          controller.dispose();
        }
      }
    }
  }
}

void main() {
  for (final mode in [
    MarkdownMode.commonMark,
    MarkdownMode.gfm,
    MarkdownMode.writersideMarkdown,
  ]) {
    group(mode.name, () {
      for (final (name, prefix, continuation) in [
        ('paragraph', '', ''),
        ('numbered list', '1. ', '   '),
        ('lazy list continuation', '1. ', ''),
        ('bulleted list', '- ', '  '),
        ('blockquote', '> ', '> '),
        ('list in a blockquote', '> 1. ', '>    '),
      ]) {
        for (final (breakName, suffix, expected) in [
          ('soft break', '', 'helo wrld'),
          ('space before soft break', ' ', 'helo wrld'),
          ('two-space hard break', '  ', 'helo wrld'),
          ('three-space hard break', '   ', 'helo wrld'),
          ('backslash hard break', '\\', 'helo wrld'),
          ('escaped backslash', '\\\\', 'helo\\ wrld'),
          ('escaped backslash before hard break', '\\\\\\', 'helo\\ wrld'),
          ('tab before soft break', '\t', 'helo\t wrld'),
          ('space and tab before soft break', ' \t', 'helo \t wrld'),
        ]) {
          test('$name preserves $breakName and correction positions', () {
            for (final lineEnding in ['\n', '\r\n', '\r']) {
              _expectProseAndCorrection(
                '$prefix'
                'helo$suffix$lineEnding$continuation**wrld**$lineEnding',
                expected,
                mode,
              );
            }
          });
        }
      }

      test('literal numbered continuation remains prose', () {
        for (final marker in ['2.', '2)']) {
          _expectProseAndCorrection(
            'helo\n$marker wrld\n',
            'helo $marker wrld',
            mode,
          );
        }
      });

      test('indented paragraph continuation follows parser boundaries', () {
        _expectProseAndCorrection('helo\n    wrld\n', 'helo     wrld', mode);
      });

      test('inline HTML breaks retain surrounding prose and corrections', () {
        for (final tag in ['<br>', '<br/>', '<br />', '<BR>']) {
          _expectProseAndCorrection('helo $tag **wrld**\n', 'helo  wrld', mode);
          _expectProseAndCorrection('helo $tag wrld\n', 'helo   wrld', mode);
        }
      });

      test('HTML layout newlines do not add extra spelling breaks', () {
        for (final (source, expected) in [
          ('helo<br>\nwrld\n', 'helo wrld'),
          ('helo\n<br>\n**wrld**\n', 'helo wrld'),
          ('- helo<br>\n  wrld\n', 'helo wrld'),
          ('> helo<br>\n> wrld\n', 'helo wrld'),
          ('helo  <br>  wrld\n', 'helo   wrld'),
          ('a <u>helo<br>wrld</u>\n', 'a helo wrld'),
          ('helo <br\n data-id="break"> wrld\n', 'helo   wrld'),
          ('[helo<br>wrld](target)\n', 'helo wrld'),
          ('[helo<br>\nwrld](target)\n', 'helo wrld'),
          ('[helo\n<br>\n**wrld**](target)\n', 'helo  wrld'),
          ('helo<br><br>wrld\n', 'helo  wrld'),
          ('helo  &amp;  <br>wrld\n', 'helo &  wrld'),
          ('helo<br>wrld&nbsp;text\n', 'helo wrld text'),
        ]) {
          _expectProseAndCorrection(source, expected, mode);
        }
      });

      test('HTML breaks keep readable metadata as a separate spelling run', () {
        for (final lineEnding in [' ', '\n', '\r\n']) {
          for (final linked in [false, true]) {
            final prose = 'helo<br${lineEnding}title="titel">wrld';
            final source = linked ? '[$prose](target)\n' : '$prose\n';
            final document = const MarkdownParser()
                .parse(
                  filePath: '/break-metadata.md',
                  source: source,
                  mode: mode,
                  validateLocalReferences: false,
                )
                .busyDocument;
            final rich = const WysiwygSpellingProjector().project(
              document: document,
              languageId: 'en-CA',
              snapshot: _snapshot,
              documentGeneration: 1,
            );
            expect(rich.complete, isTrue, reason: source);
            expect(rich.runs.map((run) => run.text), [
              'helo wrld',
              'titel',
            ], reason: source);
            final metadata = rich.runs.last;
            expect(metadata.target, isA<SpellingSourceTarget>());
            final occurrence = SpellingOccurrence(
              id: 'title',
              run: metadata,
              logicalStart: 0,
              logicalEnd: 5,
              word: 'titel',
              outcome: SpellingCheckOutcome.rejected,
            );
            final plan = const SpellingReplacementPlanner().build(
              occurrence: occurrence,
              suggestion: 'title',
            );
            expect(
              plan.applyToSource(source),
              source.replaceFirst('titel', 'title'),
            );
          }
        }
      });

      test('formatting can contain a container line break', () {
        for (final (prefix, continuation) in [('-', '  '), ('>', '> ')]) {
          _expectProseAndCorrection(
            '$prefix **helo  \n$continuation'
                'wrld**\n',
            'helo wrld',
            mode,
          );
        }
      });

      test('HTML displayed as literal text keeps exact spelling targets', () {
        const literal = '<a href="javascript:void(0)">helo wrld</a>';
        _expectProseAndCorrection('$literal\n', literal, mode);
      });
    });
  }
}
