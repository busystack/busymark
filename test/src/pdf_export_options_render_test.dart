import 'dart:io';
import 'package:xml/xml.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final typst = Platform.environment['BUSYMARK_TYPST_PATH'];
  final available = typst != null && File(typst).existsSync();
  final profiles = <String, PdfExportOptions>{
    'default-a4': const PdfExportOptions(),
    'letter-landscape': const PdfExportOptions(
      pageSize: PdfPageSize.letter,
      orientation: PdfOrientation.landscape,
      margin: PdfMarginPreset.narrow,
      pageNumbers: PdfPageNumberPosition.bottomLeft,
    ),
    'legal-serif': const PdfExportOptions(
      pageSize: PdfPageSize.legal,
      margin: PdfMarginPreset.wide,
      bodyFontSize: 13,
      codeFontSize: 10,
      pageNumbers: PdfPageNumberPosition.bottomRight,
    ),
    'custom-sans': const PdfExportOptions(
      pageSize: PdfPageSize.custom,
      customWidthMm: 240,
      customHeightMm: 320,
      margin: PdfMarginPreset.custom,
      customMargins: PdfMargins(top: 12, right: 23, bottom: 34, left: 45),
      bodyTypography: ExportBodyTypography.sansSerif,
      bodyFontSize: 16,
      codeFontSize: 12,
      accentColor: '#247550',
      header: PdfRunningText.documentTitle,
      footer: PdfRunningText.documentTitle,
      showHeaderFooterOnFirstPage: false,
      content: ExportContentOptions(
        includeToc: true,
        tocDepth: 2,
        numberHeadings: true,
      ),
    ),
    'no-numbers': const PdfExportOptions(
      pageNumbers: PdfPageNumberPosition.off,
      header: PdfRunningText.documentTitle,
      footer: PdfRunningText.documentTitle,
      content: ExportContentOptions(includeToc: true, tocDepth: 6),
    ),
    'numbered-no-outline': const PdfExportOptions(
      content: ExportContentOptions(numberHeadings: true),
      footer: PdfRunningText.documentTitle,
    ),
  };
  for (final profile in profiles.entries) {
    test(
      'bundled Typst compiles ${profile.key} and preserves document data',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pdf-options-render-',
        );
        addTearDown(() => root.delete(recursive: true));
        final source =
            '''---
title: 'Running title #eval("not code")'
author: BusyMark
lang: en-CA
---
# Main

[Child link](#child) and [External](https://example.com).

## Child

### Nested

```dart
void main() { print("<safe>"); }
```

${List.filled(140, 'A paragraph of readable content to exercise later pages.\n').join('\n')}
''';
        final result =
            await MarkdownPdfExportService(
              compilerLocator: TypstCompilerLocator(
                environment: {'BUSYMARK_TYPST_PATH': typst!},
              ),
              templateLoader: () =>
                  File('assets/export/markdown.typ').readAsString(),
            ).export(
              MarkdownPdfExportRequest(
                source: source,
                filePath: p.join(root.path, 'source.md'),
                workspaceRoot: root.path,
                destinationPath: p.join(root.path, 'result.pdf'),
                options: profile.value,
                overwrite: false,
              ),
            );
        expect(result.warnings, isEmpty);
        final bytes = await File(result.destinationPath).readAsBytes();
        expect(bytes.take(5), [37, 80, 68, 70, 45]);
        expect(bytes.length, greaterThan(2000));
        if (await File('/usr/bin/pdfinfo').exists()) {
          final info = await Process.run('/usr/bin/pdfinfo', [
            result.destinationPath,
          ]);
          expect(info.exitCode, 0);
          final dims = RegExp(
            r'Page size:\s+([\d.]+) x ([\d.]+) pts',
          ).firstMatch(info.stdout as String)!;
          expect(
            double.parse(dims[1]!),
            closeTo(profile.value.geometry.widthPt, .01),
          );
          expect(
            double.parse(dims[2]!),
            closeTo(profile.value.geometry.heightPt, .01),
          );
        }
        if (await File('/usr/bin/pdftohtml').exists()) {
          final converted = await Process.run('/usr/bin/pdftohtml', [
            '-xml',
            '-i',
            '-zoom',
            '1',
            '-stdout',
            result.destinationPath,
          ]);
          final xml = XmlDocument.parse(converted.stdout as String);
          final fonts = {
            for (final font in xml.findAllElements('fontspec'))
              font.getAttribute('id'): double.parse(font.getAttribute('size')!),
          };
          final code = xml
              .findAllElements('text')
              .firstWhere((t) => t.innerText == 'void');
          final body = xml
              .findAllElements('text')
              .firstWhere((t) => t.innerText.startsWith('A paragraph'));
          expect(
            fonts[code.getAttribute('font')],
            closeTo(profile.value.codeFontSize, 1),
          );
          expect(
            fonts[body.getAttribute('font')],
            closeTo(profile.value.bodyFontSize, 1),
          );
        }
        if (await File('/usr/bin/pdffonts').exists()) {
          final fonts = await Process.run('/usr/bin/pdffonts', [
            result.destinationPath,
          ]);
          expect(
            fonts.stdout,
            contains(
              profile.value.bodyTypography == ExportBodyTypography.sansSerif
                  ? 'NotoSans'
                  : 'NotoSerif',
            ),
          );
          expect(fonts.stdout, contains('NotoSansMono'));
        }
        if (await File('/usr/bin/pdftotext').exists()) {
          final positioned = await Process.run('/usr/bin/pdftotext', [
            '-bbox',
            result.destinationPath,
            '-',
          ]);
          final boxes = XmlDocument.parse(positioned.stdout as String)
              .descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 'page')
              .toList();
          final o = profile.value;
          for (final pageIndex in [0, 1]) {
            final pageBox = boxes[pageIndex];
            final bottom =
                o.geometry.heightPt -
                o.geometry.margins.bottom * PdfPageGeometry.pointsPerMm;
            final counters = pageBox.descendants
                .whereType<XmlElement>()
                .where(
                  (e) =>
                      e.name.local == 'word' &&
                      e.innerText == '${pageIndex + 1}' &&
                      double.parse(e.getAttribute('yMin')!) > bottom,
                )
                .toList();
            final visible =
                o.pageNumbers != PdfPageNumberPosition.off &&
                (pageIndex > 0 || o.showHeaderFooterOnFirstPage);
            expect(counters, hasLength(visible ? 1 : 0));
            if (visible) {
              final left = double.parse(counters.single.getAttribute('xMin')!);
              final right = double.parse(counters.single.getAttribute('xMax')!);
              final contentLeft =
                  o.geometry.margins.left * PdfPageGeometry.pointsPerMm;
              final contentRight =
                  o.geometry.widthPt -
                  o.geometry.margins.right * PdfPageGeometry.pointsPerMm;
              switch (o.pageNumbers) {
                case PdfPageNumberPosition.bottomLeft:
                  expect(left, closeTo(contentLeft, 1));
                case PdfPageNumberPosition.bottomRight:
                  expect(right, closeTo(contentRight, 1));
                case PdfPageNumberPosition.bottomCenter:
                  expect(
                    (left + right) / 2,
                    closeTo((contentLeft + contentRight) / 2, 1),
                  );
                case PdfPageNumberPosition.off:
                  break;
              }
            }
          }
          final text = await Process.run('/usr/bin/pdftotext', [
            '-layout',
            result.destinationPath,
            '-',
          ]);
          expect(text.exitCode, 0);
          final pages = (text.stdout as String).split('\f');
          expect(pages.first, contains('Main'));
          expect(
            pages.first.contains('Contents'),
            profile.value.content.includeToc,
          );
          if (profile.value.content.includeToc) {
            expect(
              pages.first.split('Main').skip(1).join('Main'),
              matches(r'Child[^\n]*1'),
              reason:
                  'Native outline retains destination page numbers even with hidden first-page footers.',
            );
          }
          expect(text.stdout, contains('void main()'));
          if (profile.value.content.numberHeadings) {
            expect(text.stdout, matches(r'1\.1\s+Child'));
          }
          if (profile.value.header != PdfRunningText.none ||
              profile.value.footer != PdfRunningText.none) {
            expect(
              pages.first.contains('Running title #eval'),
              profile.value.showHeaderFooterOnFirstPage,
            );
            expect(pages[1], contains('Running title #eval'));
          }
          if (profile.value.content.includeToc &&
              profile.value.content.tocDepth == 2) {
            final beforeBody = pages.first
                .split(RegExp(r'\n\s*1\s+Main'))
                .first;
            expect(beforeBody, isNot(contains('Nested')));
          }
        }
      },
      skip: available
          ? false
          : 'Set BUSYMARK_TYPST_PATH to the bundled compiler.',
    );
  }
}
