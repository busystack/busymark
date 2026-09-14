import 'dart:convert';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_payload_builder.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cover preference defaults off, serializes and copies independently',
    () {
      const defaults = PdfExportOptions();
      expect(defaults.includeTitlePage, isFalse);
      expect(defaults.content.includeToc, isFalse);
      expect(PdfExportOptions.fromJson({}).includeTitlePage, isFalse);
      expect(
        PdfExportOptions.fromJson({
          'includeTitlePage': 'true',
        }).includeTitlePage,
        isFalse,
      );
      final options = defaults.copyWith(includeTitlePage: true);
      expect(options.copyWith(bodyFontSize: 14).includeTitlePage, isTrue);
      expect(
        options.copyWith(includeTitlePage: false).toJson(),
        defaults.toJson(),
      );
      final stored = AppSettings.defaults().copyWith(pdfExportOptions: options);
      final loaded = AppSettings.fromJson(
        jsonDecode(jsonEncode(stored.toJson())) as Map<String, dynamic>,
      );
      expect(loaded.pdfExportOptions.includeTitlePage, isTrue);
      expect(
        loaded.htmlExportOptions.toJson(),
        const HtmlExportOptions().toJson(),
      );
      expect(options.toJson().keys, isNot(contains('titlePage')));
      expect(
        const ExportContentOptions().toJson().keys,
        isNot(contains('includeTitlePage')),
      );
    },
  );

  test('cover title and authors use the established metadata precedence', () {
    const document = BusyDocument(
      filePath: '/docs/Filename.md',
      mode: MarkdownMode.commonMark,
      title: 'Document title',
      frontMatter: {'title': 'Metadata title', 'authors': 'Ada, Lin'},
      blocks: [],
    );
    expect(
      PdfTitlePageData.fromDocument(document, titleOverride: 'Override').title,
      'Override',
    );
    expect(PdfTitlePageData.fromDocument(document).title, 'Metadata title');
    expect(PdfTitlePageData.fromDocument(document).author, 'Ada, Lin');
    expect(
      PdfTitlePageData.fromDocument(
        document.copyWith(
          frontMatter: {'author': 'First', 'authors': 'Second'},
        ),
      ).author,
      'First',
    );
    expect(
      PdfTitlePageData.fromDocument(document.copyWith(frontMatter: {})).title,
      'Document title',
    );
    expect(
      PdfTitlePageData.fromDocument(
        document.copyWith(frontMatter: {}, title: ''),
      ).title,
      'Filename',
    );
    expect(
      PdfTitlePageData.fromDocument(
        const BusyDocument(
          filePath: '',
          mode: MarkdownMode.commonMark,
          blocks: [],
        ),
      ).title,
      'Untitled',
    );
  });

  test(
    'snapshot metadata, display text, explicit clears and plain JSON remain independent',
    () {
      final document = const MarkdownParser()
          .parse(
            source: '''---
title: Unsaved title
subtitle: Résumé and Ω
author: Ada
organization: Example team
version: 01.020-rc
date: Whenever / later
---
# Original source heading

Body.
''',
            filePath: '/docs/snapshot.md',
          )
          .busyDocument;
      final defaults = PdfTitlePageData.fromDocument(document);
      expect(defaults.toJson(), {
        'title': 'Unsaved title',
        'subtitle': 'Résumé and Ω',
        'author': 'Ada',
        'organization': 'Example team',
        'version': '01.020-rc',
        'date': 'Whenever / later',
      });
      final edited = defaults.copyWith(
        title: '#eval("plain text")',
        subtitle: 'Line one\nLine two',
        author: '',
        organization: ' ',
        version: '',
        date: '',
      );
      expect(edited.validate(), isEmpty);
      expect(edited.toJson(), {
        'title': '#eval("plain text")',
        'subtitle': 'Line one\nLine two',
      });
      expect(
        edited.copyWith(title: ' \n').validate().single.field,
        'titlePage.title',
      );
      final export = const MarkdownExportMapper().map(document);
      final payload = const TypstPayloadBuilder().build(
        document: export,
        options: const PdfExportOptions(includeTitlePage: true),
        titlePage: edited,
        assets: {},
      );
      expect(payload['titlePage'], edited.toJson());
      expect(
        jsonDecode(jsonEncode(payload))['titlePage']['title'],
        '#eval("plain text")',
      );
      expect(
        const TypstPayloadBuilder()
            .build(
              document: export,
              options: const PdfExportOptions(),
              titlePage: edited,
              assets: {},
            )
            .containsKey('titlePage'),
        isFalse,
      );
      expect(
        () => const TypstPayloadBuilder().build(
          document: export,
          options: const PdfExportOptions(includeTitlePage: true),
          titlePage: edited.copyWith(title: ''),
          assets: {},
        ),
        throwsA(isA<ExportOptionsException>()),
      );
      expect(defaults.title, 'Unsaved title');
      final next = PdfTitlePageData.fromDocument(
        const BusyDocument(
          filePath: '/docs/Next.md',
          mode: MarkdownMode.commonMark,
          blocks: [],
        ),
      );
      expect(next.toJson(), {'title': 'Next'});
    },
  );

  test(
    'instance title uses its display name and only known project metadata',
    () {
      const instance = WritersideInstance(
        id: 'guide',
        name: 'Whole instance',
        sourceTreePath: '/project/guide.tree',
        startPage: 'Topic with a different name.topic',
        status: '',
        isLibrary: false,
        tocRoots: [],
        diagnostics: [],
        globalVersion: 'Project version',
        version: 'Instance version',
      );
      expect(PdfTitlePageData.forInstance(instance).toJson(), {
        'title': 'Whole instance',
        'version': 'Instance version',
      });
    },
  );
}
