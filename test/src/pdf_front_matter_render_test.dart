import 'dart:io';

import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _source = '''---
title: RUNNING_TEXT_SENTINEL
author: Source author
lang: en
---
# Original heading

BODY_START_SENTINEL is only in the document body.

## Nested heading

NESTED_BODY_SENTINEL stays linked.

### Deep heading

DEEP_BODY_SENTINEL stays present.
''';
const _cover = PdfTitlePageData(title: 'COVER_ONLY_SENTINEL');

void main() {
  final compiler = Platform.environment['BUSYMARK_TYPST_PATH'];
  final available =
      compiler != null &&
      File(compiler).existsSync() &&
      File('/usr/bin/pdftotext').existsSync() &&
      File('/usr/bin/pdftohtml').existsSync();
  final skip = available
      ? false
      : 'Requires BUSYMARK_TYPST_PATH and Poppler tools.';
  late Directory root;
  late MarkdownPdfExportService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf-front-matter-');
    service = MarkdownPdfExportService(
      compilerLocator: TypstCompilerLocator(
        environment: {'BUSYMARK_TYPST_PATH': compiler ?? '/unavailable'},
      ),
      templateLoader: () => File('assets/export/markdown.typ').readAsString(),
    );
  });
  tearDown(() async {
    // Optional retained output is useful for manual visual inspection.
    final artifacts = Platform.environment['BUSYMARK_PDF_ARTIFACTS'];
    if (artifacts != null) {
      await Directory(artifacts).create(recursive: true);
      for (final file in root.listSync().whereType<File>()) {
        if (p.extension(file.path) == '.pdf') {
          await file.copy(p.join(artifacts, p.basename(file.path)));
        }
      }
    }
    await root.delete(recursive: true);
  });

  Future<String> export(
    String name,
    PdfExportOptions options, {
    String source = _source,
    PdfTitlePageData? cover = _cover,
  }) async {
    final path = p.join(root.path, '$name.pdf');
    final result = await service.export(
      MarkdownPdfExportRequest(
        source: source,
        filePath: p.join(root.path, 'source.md'),
        workspaceRoot: root.path,
        destinationPath: path,
        options: options,
        titlePage: cover,
        overwrite: false,
      ),
    );
    expect(result.warnings, isEmpty);
    return path;
  }

  for (final writerside in [false, true]) {
    for (final cover in [false, true]) {
      for (final toc in [false, true]) {
        test(
          '${writerside ? "Writerside" : "Markdown"}: cover=$cover toc=$toc section order and native links',
          () async {
            final options = PdfExportOptions(
              includeTitlePage: cover,
              content: ExportContentOptions(
                includeToc: toc,
                tocDepth: 2,
                numberHeadings: true,
              ),
            );
            final bodyIndex = (cover ? 1 : 0) + (toc ? 1 : 0);
            final name =
                '${writerside ? "writerside" : "markdown"}-$cover-$toc';
            final String path;
            if (writerside) {
              final fixture = Directory(
                'test/fixtures/writerside/pdf_front_matter',
              ).absolute;
              final before = {
                for (final file
                    in fixture.listSync(recursive: true).whereType<File>())
                  file.path: file.readAsBytesSync(),
              };
              path = p.join(root.path, '$name.pdf');
              await WritersidePdfExportService(
                markdownExporter: service,
              ).export(
                WritersidePdfExportRequest(
                  moduleRoot: fixture.path,
                  instanceId: 'guide',
                  destinationPath: path,
                  overwrite: false,
                  options: options,
                ),
              );
              for (final entry in before.entries) {
                expect(File(entry.key).readAsBytesSync(), entry.value);
              }
            } else {
              final sourceFile = File(p.join(root.path, 'source.md'));
              await sourceFile.writeAsString(_source);
              path = await export(name, options);
              expect(await sourceFile.readAsString(), _source);
            }
            final pages = await _pages(path);
            expect(pages, hasLength(bodyIndex + 1));
            expect(
              pages.indexWhere((page) => page.contains('BODY_START_SENTINEL')),
              bodyIndex,
            );
            expect(pages.every((page) => page.trim().isNotEmpty), isTrue);
            expect(pages[bodyIndex], contains('Original heading'));
            expect(pages[bodyIndex], matches(r'1\s+Original heading'));
            expect(pages[bodyIndex], matches(r'1\.1\s+Nested heading'));
            if (cover) {
              expect(
                pages.first,
                contains(
                  writerside ? 'Instance cover default' : 'COVER_ONLY_SENTINEL',
                ),
              );
              expect(pages.first, isNot(contains('Original heading')));
              expect(
                pages.first.replaceAll(RegExp(r'\s+'), ' ').trim(),
                writerside
                    ? 'Instance cover default 2.0'
                    : 'COVER_ONLY_SENTINEL',
              );
            }
            final xml = await _xml(path);
            // Bookmarks survive even when the printed outline is disabled.
            expect(
              xml
                  .findAllElements('outline')
                  .expand((e) => e.findAllElements('item'))
                  .map((e) => e.innerText),
              contains(contains('Original heading')),
            );
            if (toc) {
              final index = cover ? 1 : 0;
              expect(pages[index], contains('Contents'));
              expect(pages[index], contains('Nested heading'));
              expect(pages[index], isNot(contains('Deep heading')));
              expect(pages[index], isNot(contains('Excluded heading')));
              expect(pages[index], isNot(contains('BODY_SENTINEL')));
              expect(pages[index], isNot(contains('BODY_START_SENTINEL')));
              expect(
                pages[index],
                matches(RegExp('Nested heading[^\n]*${bodyIndex + 1}')),
              );
              final links = xml
                  .findAllElements('page')
                  .elementAt(index)
                  .findAllElements('a')
                  .toList();
              expect(
                links.where((e) => e.innerText.contains('Original heading')),
                isNotEmpty,
              );
              for (final link in links) {
                expect(
                  link.getAttribute('href'),
                  endsWith('#${bodyIndex + 1}'),
                );
              }
            }
            if (writerside) {
              expect(pages[bodyIndex], contains('HIDDEN_BODY_SENTINEL'));
            }
          },
          skip: skip,
        );
      }
    }
  }

  test(
    'multipage native outline ends before any body paragraphs; links and page references stay correct',
    () async {
      final source = List.generate(
        115,
        (i) => '# Topic ${i + 1}\n\nPARAGRAPH_${i + 1}_MARKER\n',
      ).join('\n');
      final path = await export(
        'multipage-toc',
        const PdfExportOptions(
          includeTitlePage: true,
          pageNumbers: PdfPageNumberPosition.off,
          content: ExportContentOptions(includeToc: true),
        ),
        source: source,
      );
      final pages = await _pages(path);
      final bodyIndex = pages.indexWhere(
        (page) => page.contains('PARAGRAPH_1_MARKER'),
      );
      expect(bodyIndex, greaterThanOrEqualTo(3));
      expect(pages.every((page) => page.trim().isNotEmpty), isTrue);
      for (final page in pages.take(bodyIndex)) {
        expect(page, isNot(contains('PARAGRAPH_')));
      }
      final xmlPages = (await _xml(path)).findAllElements('page').toList();
      var headingLinks = 0;
      for (var i = 1; i < bodyIndex; i++) {
        for (final link in xmlPages[i].findAllElements('a')) {
          final match = RegExp(r'Topic (\d+)').firstMatch(link.innerText);
          if (match == null) continue;
          headingLinks++;
          final topic = match[1]!;
          final target =
              pages.indexWhere(
                (page) => page.contains('PARAGRAPH_${topic}_MARKER'),
              ) +
              1;
          expect(link.getAttribute('href'), endsWith('#$target'));
          expect(pages[i], matches(RegExp('Topic $topic\\s[^\n]*$target')));
        }
      }
      expect(headingLinks, 115);
    },
    skip: skip,
  );

  for (final firstPage in [false, true]) {
    for (final numbers in [
      PdfPageNumberPosition.bottomCenter,
      PdfPageNumberPosition.off,
    ]) {
      test(
        'cover suppresses running text, physical first=$firstPage numbers=${numbers.name}',
        () async {
          final options = PdfExportOptions(
            includeTitlePage: true,
            header: PdfRunningText.documentTitle,
            footer: PdfRunningText.documentTitle,
            pageNumbers: numbers,
            showHeaderFooterOnFirstPage: firstPage,
            content: const ExportContentOptions(includeToc: true),
          );
          final path = await export(
            'running-$firstPage-${numbers.name}',
            options,
          );
          final pages = await _pages(path);
          expect(pages, hasLength(3));
          expect(pages.first, isNot(contains('RUNNING_TEXT_SENTINEL')));
          final boxes = await _boxes(path);
          for (var i = 0; i < 3; i++) {
            if (i > 0) {
              expect(
                RegExp('RUNNING_TEXT_SENTINEL').allMatches(pages[i]),
                hasLength(2),
              );
            }
            final footerWords = _words(boxes[i]).where(
              (w) =>
                  double.parse(w.getAttribute('yMin')!) >
                  options.geometry.heightPt -
                      options.geometry.margins.bottom *
                          PdfPageGeometry.pointsPerMm,
            );
            expect(
              footerWords.where((w) => w.innerText == '${i + 1}'),
              hasLength(i > 0 && numbers != PdfPageNumberPosition.off ? 1 : 0),
            );
          }
          expect(pages[1], matches(r'Original heading[^\n]*3'));
        },
        skip: skip,
      );
    }
  }

  for (final font in ExportBodyTypography.values) {
    for (final landscape in [false, true]) {
      test(
        'cover wraps Unicode and multiline metadata within ${font.name} ${landscape ? "landscape" : "portrait"} margins',
        () async {
          final options = PdfExportOptions(
            includeTitlePage: true,
            bodyTypography: font,
            orientation: landscape
                ? PdfOrientation.landscape
                : PdfOrientation.portrait,
            margin: PdfMarginPreset.custom,
            customMargins: const PdfMargins(
              top: 17,
              bottom: 23,
              left: 29,
              right: 19,
            ),
            content: const ExportContentOptions(includeToc: true),
          );
          final path = await export(
            'layout-${font.name}-$landscape',
            options,
            cover: const PdfTitlePageData(
              title:
                  'A long, carefully wrapped title — Résumé of Привет and documentation across multiple platforms',
              subtitle:
                  'A multiline subtitle\nSecond line with café and Unicode Ω\nPlain #eval("never executed") text',
              author: 'Author name',
              organization: 'An organization with a longer display name',
              version: 'Release candidate v3.0',
              date: 'Autumn / someday',
            ),
          );
          final pages = await _pages(path);
          expect(pages, hasLength(3));
          expect(pages.first, contains('Привет'));
          expect(pages.first, contains('Second line'));
          expect(pages.first, contains('#eval'));
          expect(pages.first, contains('Autumn / someday'));
          final boxPages = await _boxes(path);
          for (final word in _words(boxPages.first)) {
            expect(
              double.parse(word.getAttribute('xMin')!),
              greaterThanOrEqualTo(
                options.geometry.margins.left * PdfPageGeometry.pointsPerMm - 1,
              ),
            );
            expect(
              double.parse(word.getAttribute('xMax')!),
              lessThanOrEqualTo(
                options.geometry.widthPt -
                    options.geometry.margins.right *
                        PdfPageGeometry.pointsPerMm +
                    1,
              ),
            );
            expect(
              double.parse(word.getAttribute('yMin')!),
              greaterThanOrEqualTo(
                options.geometry.margins.top * PdfPageGeometry.pointsPerMm - 1,
              ),
            );
            expect(
              double.parse(word.getAttribute('yMax')!),
              lessThanOrEqualTo(
                options.geometry.heightPt -
                    options.geometry.margins.bottom *
                        PdfPageGeometry.pointsPerMm +
                    1,
              ),
            );
          }
          final xml = await _xml(path);
          final body = xml
              .findAllElements('text')
              .firstWhere((e) => e.innerText.contains('BODY_START_SENTINEL'));
          final bodyFont = xml
              .findAllElements('fontspec')
              .firstWhere(
                (e) => e.getAttribute('id') == body.getAttribute('font'),
              );
          expect(
            double.parse(bodyFont.getAttribute('size')!),
            closeTo(options.bodyFontSize, 1),
          );
          expect(bodyFont.getAttribute('color'), isNot(options.accentColor));
        },
        skip: skip,
      );
    }
  }

  test(
    'request defaults come from source metadata and native outline title stays localized',
    () async {
      final path = await export(
        'french-defaults',
        const PdfExportOptions(
          includeTitlePage: true,
          content: ExportContentOptions(includeToc: true, tocDepth: 1),
        ),
        cover: null,
        source: _source
            .replaceFirst('lang: en', 'lang: fr')
            .replaceFirst(
              'author: Source author',
              'author: Source author\nsubtitle: Sous-titre\norganization: Équipe\nversion: 01.020-rc\ndate: Plus tard',
            ),
      );
      final pages = await _pages(path);
      expect(pages, hasLength(3));
      expect(pages.first, contains('RUNNING_TEXT_SENTINEL'));
      for (final value in [
        'Source author',
        'Sous-titre',
        'Équipe',
        '01.020-rc',
        'Plus tard',
      ]) {
        expect(pages.first, contains(value));
      }
      expect(pages[1], contains('Table des matières'));
      expect(pages[1], isNot(contains('Nested heading')));
      expect(pages[1], matches(r'Original heading[^\n]*3'));
      expect(pages[2], contains('BODY_START_SENTINEL'));
    },
    skip: skip,
  );

  test(
    'an oversized cover fails clearly and leaves the existing PDF untouched',
    () async {
      final destination = File(p.join(root.path, 'existing.pdf'));
      const original = '%PDF-previous-result';
      await destination.writeAsString(original);
      await expectLater(
        service.export(
          MarkdownPdfExportRequest(
            source: _source,
            filePath: p.join(root.path, 'source.md'),
            workspaceRoot: root.path,
            destinationPath: destination.path,
            overwrite: true,
            options: const PdfExportOptions(includeTitlePage: true),
            titlePage: PdfTitlePageData(
              title: 'Cannot fit',
              subtitle: List.filled(200, 'A subtitle line').join('\n'),
            ),
          ),
        ),
        throwsA(
          isA<MarkdownPdfExportException>().having(
            (e) => e.detail,
            'clear fit error',
            contains('title page does not fit'),
          ),
        ),
      );
      expect(await destination.readAsString(), original);
      final token = MarkdownPdfCancellationToken()..cancel();
      await expectLater(
        service.export(
          MarkdownPdfExportRequest(
            source: _source,
            filePath: '',
            workspaceRoot: root.path,
            destinationPath: destination.path,
            overwrite: true,
            options: const PdfExportOptions(includeTitlePage: true),
          ),
          cancellationToken: token,
        ),
        throwsA(
          isA<MarkdownPdfExportException>().having(
            (e) => e.code,
            'cancelled',
            MarkdownPdfFailureCode.cancelled,
          ),
        ),
      );
      expect(await destination.readAsString(), original);
    },
    skip: skip,
  );
}

Future<List<String>> _pages(String path) async {
  final result = await Process.run('/usr/bin/pdftotext', [
    '-layout',
    path,
    '-',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  final pages = (result.stdout as String).split('\f');
  if (pages.last.trim().isEmpty) pages.removeLast();
  return pages;
}

Future<XmlDocument> _xml(String path) async {
  final result = await Process.run('/usr/bin/pdftohtml', [
    '-xml',
    '-i',
    '-zoom',
    '1',
    '-stdout',
    path,
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return XmlDocument.parse(result.stdout as String);
}

Future<List<XmlElement>> _boxes(String path) async {
  final result = await Process.run('/usr/bin/pdftotext', ['-bbox', path, '-']);
  expect(result.exitCode, 0);
  return XmlDocument.parse(result.stdout as String).descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 'page')
      .toList();
}

Iterable<XmlElement> _words(XmlElement page) => page.descendants
    .whereType<XmlElement>()
    .where((e) => e.name.local == 'word');
