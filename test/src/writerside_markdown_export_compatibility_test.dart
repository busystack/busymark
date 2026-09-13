import 'dart:io';

import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  final fixture = Directory(
    'test/fixtures/writerside/markdown_export_compatibility',
  ).absolute;
  late Directory output;
  setUp(() async {
    output = await Directory.systemTemp.createTemp('writerside-md-export-');
  });
  tearDown(() => output.delete(recursive: true));

  test(
    'HTML retains complex Markdown and resolves both heading ID spellings',
    () async {
      final result = await const HtmlExportService().exportWriterside(
        projectRoot: fixture.path,
        moduleRoot: fixture.path,
        instanceId: 'guide',
        destinationPath: p.join(output.path, 'site'),
      );
      expect(result.warnings, isEmpty);
      final document = html.parse(
        await File(result.entryPointPath).readAsString(),
      );
      final article = document.querySelector('article')!;
      final links = article
          .querySelectorAll('a')
          .where(
            (link) => [
              'Writerside heading',
              'Existing Markdown heading',
            ].contains(link.text),
          )
          .toList();
      expect(links, hasLength(2));
      expect(
        links.map((link) => link.attributes['href']).toSet(),
        hasLength(1),
      );
      final target = Uri.parse(links.first.attributes['href']!);
      final targetDocument = html.parse(
        await File(
          p.join(p.dirname(result.entryPointPath), target.path),
        ).readAsString(),
      );
      expect(
        targetDocument.getElementById(target.fragment)!.text,
        'Step 6: Update CMakeLists.txt',
      );
      expect(
        article.querySelectorAll('pre code').map((code) => code.text),
        containsAll([
          contains("echo '<literal>'"),
          contains('<note><p>Repeated semantic note.</p></note>'),
        ]),
      );
      expect(article.querySelectorAll('.admonition'), hasLength(2));
      for (final phrase in [
        'Before the list & after the metadata.',
        'A continuation paragraph.',
        'Nested action',
        'Second action',
        'Between the notes.',
        'Final compatibility paragraph.',
      ]) {
        expect(phrase.allMatches(article.text), hasLength(1), reason: phrase);
      }
    },
  );

  final typst = Platform.environment['BUSYMARK_TYPST_PATH'];
  test(
    'PDF retains complex Markdown and resolved heading links',
    () async {
      final result =
          await WritersidePdfExportService(
            markdownExporter: MarkdownPdfExportService(
              compilerLocator: TypstCompilerLocator(
                environment: {'BUSYMARK_TYPST_PATH': typst!},
              ),
              templateLoader: () =>
                  File('assets/export/markdown.typ').readAsString(),
            ),
          ).export(
            WritersidePdfExportRequest(
              moduleRoot: fixture.path,
              instanceId: 'guide',
              destinationPath: p.join(output.path, 'result.pdf'),
              overwrite: false,
            ),
          );
      expect(
        result.warnings,
        isEmpty,
        reason: result.warnings
            .map((w) => '${w.code}: ${w.destination}')
            .join('\n'),
      );
      final extracted = await Process.run('/usr/bin/pdftotext', [
        '-layout',
        result.destinationPath,
        '-',
      ]);
      expect(extracted.exitCode, 0, reason: '${extracted.stderr}');
      final text = extracted.stdout as String;
      for (final phrase in [
        'Before the list & after the metadata.',
        'A continuation paragraph.',
        'Nested action',
        'Second action',
        'Between the notes.',
        'Final compatibility paragraph.',
        'Step 6: Update CMakeLists.txt',
        'Retained CMake explanation.',
        'Following chapter explanation.',
      ]) {
        expect(phrase.allMatches(text), hasLength(1), reason: phrase);
      }
      expect('Repeated semantic note.'.allMatches(text), hasLength(3));
      final linked = await Process.run('/usr/bin/pdftohtml', [
        '-xml',
        '-i',
        '-stdout',
        result.destinationPath,
      ]);
      expect(linked.exitCode, 0, reason: '${linked.stderr}');
      final xml = XmlDocument.parse(linked.stdout as String);
      final links = xml
          .findAllElements('a')
          .where(
            (a) => [
              'Writerside heading',
              'Existing Markdown heading',
            ].contains(a.innerText),
          )
          .toList();
      expect(links, hasLength(2));
      expect(links.map((a) => a.getAttribute('href')).toSet(), hasLength(1));
      final targetPage = xml
          .findAllElements('page')
          .singleWhere(
            (page) => page.innerText.contains('Step 6: Update CMakeLists.txt'),
          );
      expect(
        links.first.getAttribute('href'),
        endsWith('#${targetPage.getAttribute('number')}'),
      );
    },
    skip:
        typst == null ||
        !File(typst).existsSync() ||
        !File('/usr/bin/pdftotext').existsSync() ||
        !File('/usr/bin/pdftohtml').existsSync(),
  );
}
