import 'dart:convert';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/export/export_options.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/typst_payload_builder.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'defaults retain PDF geometry and independent HTML reading appearance',
    () {
      const pdf = PdfExportOptions();
      const html = HtmlExportOptions();
      expect(pdf.geometry.widthMm, 210);
      expect(pdf.geometry.heightMm, 297);
      expect(pdf.geometry.contentWidthPt, closeTo(595.27559 - 114, .001));
      expect(pdf.bodyFontSize, 10.5);
      expect(pdf.headingFontSize(1), 22);
      expect(pdf.accentColor, '#2563a5');
      expect(pdf.pageNumbers, PdfPageNumberPosition.bottomCenter);
      expect(pdf.content.includeToc, isFalse);
      expect(html.content.includeToc, isTrue); // Existing HTML heading outline.
      expect(html.baseFontSize, 17);
      expect(html.contentMaxWidth, 918);
      expect(html.theme, HtmlExportTheme.light);
      expect(html.packaging, HtmlPackaging.assetsDirectory);
      expect(
        [pdf.content.numberHeadings, html.content.numberHeadings],
        [false, false],
      );
      expect(pdf.validate(), isEmpty);
      expect(html.validate(), isEmpty);
    },
  );

  const pdf = PdfExportOptions(
    content: ExportContentOptions(
      includeToc: true,
      tocDepth: 3,
      numberHeadings: true,
    ),
    pageSize: PdfPageSize.custom,
    customWidthMm: 240,
    customHeightMm: 310,
    orientation: PdfOrientation.landscape,
    margin: PdfMarginPreset.custom,
    customMargins: PdfMargins(top: 10, right: 20, bottom: 30, left: 40),
    bodyTypography: ExportBodyTypography.sansSerif,
    bodyFontSize: 14,
    codeFontSize: 11,
    accentColor: '#123abc',
    header: PdfRunningText.documentTitle,
    footer: PdfRunningText.documentTitle,
    pageNumbers: PdfPageNumberPosition.bottomRight,
    showHeaderFooterOnFirstPage: false,
  );
  const html = HtmlExportOptions(
    content: ExportContentOptions(
      includeToc: false,
      tocDepth: 4,
      numberHeadings: true,
    ),
    theme: HtmlExportTheme.automatic,
    bodyTypography: ExportBodyTypography.serif,
    baseFontSize: 20,
    contentMaxWidth: 1100,
    accentColor: '#ab1234',
    customCssPath: '/styles/custom.css',
    packaging: HtmlPackaging.singleFile,
  );

  test('every option persists and copies without losing unrelated fields', () {
    expect(
      PdfExportOptions.fromJson(jsonDecode(jsonEncode(pdf.toJson()))).toJson(),
      pdf.toJson(),
    );
    expect(
      HtmlExportOptions.fromJson(
        jsonDecode(jsonEncode(html.toJson())),
      ).toJson(),
      html.toJson(),
    );
    expect(
      pdf.copyWith(bodyFontSize: 15).copyWith(bodyFontSize: 14).toJson(),
      pdf.toJson(),
    );
    expect(html.copyWith(customCssPath: null).customCssPath, isNull);
    expect(html.copyWith().toJson(), html.toJson());
    final settings = AppSettings.defaults().copyWith(
      pdfExportOptions: pdf,
      htmlExportOptions: html,
    );
    final loaded = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
    );
    expect(loaded.pdfExportOptions.toJson(), pdf.toJson());
    expect(loaded.htmlExportOptions.toJson(), html.toJson());
  });

  test('absent and malformed persisted values fall back per field', () {
    final settings = AppSettings.fromJson({});
    expect(
      settings.pdfExportOptions.toJson(),
      const PdfExportOptions().toJson(),
    );
    expect(
      settings.htmlExportOptions.toJson(),
      const HtmlExportOptions().toJson(),
    );
    final broken = PdfExportOptions.fromJson({
      'pageSize': 'wrong',
      'margin': 'custom',
      'customMargins': {'left': 500, 'right': -1},
      'bodyFontSize': '14',
      'codeFontSize': 11,
      'accentColor': '#abc',
      'content': {'tocDepth': 7, 'numberHeadings': true},
    });
    expect(broken.validate(), isEmpty);
    expect(broken.bodyFontSize, 10.5);
    expect(broken.codeFontSize, 11);
    expect(broken.content.numberHeadings, isTrue);
    expect(broken.content.tocDepth, 6);
    final brokenHtml = HtmlExportOptions.fromJson({
      'theme': [],
      'baseFontSize': double.infinity,
      'contentMaxWidth': 1000,
      'customCssPath': 'https://example.com/a.css',
      'packaging': false,
    });
    expect(brokenHtml.validate(), isEmpty);
    expect(brokenHtml.baseFontSize, 17);
    expect(brokenHtml.contentMaxWidth, 1000);
    expect(brokenHtml.customCssPath, isNull);
    expect(
      AppSettings.fromJson({
        'pdfExportOptions': [],
        'htmlExportOptions': false,
      }).pdfExportOptions.validate(),
      isEmpty,
    );
  });

  test(
    'geometry resolves dimensions, orientation and four independent margins',
    () {
      expect(pdf.geometry.widthMm, 310);
      expect(pdf.geometry.heightMm, 240);
      expect(pdf.geometry.contentWidthPt, closeTo(250 * 72 / 25.4, .001));
      expect(pdf.geometry.contentHeightPt, closeTo(200 * 72 / 25.4, .001));
      expect(
        pdf
            .copyWith(
              pageSize: PdfPageSize.letter,
              orientation: PdfOrientation.portrait,
            )
            .geometry
            .widthPt,
        closeTo(612, .001),
      );
      expect(
        pdf
            .copyWith(
              pageSize: PdfPageSize.legal,
              orientation: PdfOrientation.portrait,
            )
            .geometry
            .heightPt,
        closeTo(1008, .001),
      );
      for (final value in [double.nan, double.infinity, -1.0, 0.0, 1201.0]) {
        expect(pdf.copyWith(customWidthMm: value).validate(), isNotEmpty);
      }
      expect(
        pdf
            .copyWith(customMargins: const PdfMargins(left: 300, right: 20))
            .validate()
            .map((i) => i.field),
        contains('pageGeometry'),
      );
      expect(
        pdf
            .copyWith(customMargins: const PdfMargins(top: -1))
            .validate()
            .map((i) => i.field),
        contains('margin.top'),
      );
      expect(pdf.copyWith(bodyFontSize: 25).validate(), isNotEmpty);
      expect(pdf.copyWith(codeFontSize: 5).validate(), isNotEmpty);
      expect(
        pdf.copyWith(accentColor: 'red); eval("bad")').validate(),
        isNotEmpty,
      );
      expect(
        html.copyWith(baseFontSize: 11, contentMaxWidth: 2000).validate(),
        hasLength(2),
      );
      expect(
        () => html
            .copyWith(content: const ExportContentOptions(tocDepth: 0))
            .validateOrThrow(),
        throwsA(isA<ExportOptionsException>()),
      );
    },
  );

  test(
    'payload contains resolved geometry and every renderer option as data',
    () {
      final doc = const MarkdownExportMapper().map(
        const MarkdownParser()
            .parse(filePath: '/source.md', source: '# Title\n\nSafe text')
            .busyDocument,
      );
      final payload = const TypstPayloadBuilder().build(
        document: doc,
        options: pdf,
        assets: {},
      );
      expect(payload['schemaVersion'], 2);
      final options = payload['options'] as Map;
      expect(options['page'], pdf.geometry.toJson());
      expect(options['typography'], {
        'bodyFont': 'Noto Sans',
        'codeFont': 'Noto Sans Mono',
        'bodySizePt': 14.0,
        'codeSizePt': 11.0,
        'headingSizesPt': [
          for (var level = 1; level <= 6; level++) pdf.headingFontSize(level),
        ],
      });
      expect(options['content'], pdf.content.toJson());
      expect(options['header'], 'documentTitle');
      expect(options['footer'], 'documentTitle');
      expect(options['pageNumbers'], 'bottomRight');
      expect(options['showHeaderFooterOnFirstPage'], false);
      expect(options['accentColor'], '#123abc');
      expect(options.containsKey('customWidthMm'), isFalse);
      expect(jsonEncode(payload), isNot(contains('renderEm')));
    },
  );
}
