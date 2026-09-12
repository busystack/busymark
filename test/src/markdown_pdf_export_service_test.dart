import 'dart:convert';
import 'dart:io';

import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final typstPath = Platform.environment['BUSYMARK_TYPST_PATH'];
  final canRunTypst = typstPath != null && File(typstPath).existsSync();
  final canMeasurePdf = canRunTypst && File('/usr/bin/pdftotext').existsSync();

  test('display images do not reserve a fixed-height letterbox', () {
    final template = File('assets/export/markdown.typ').readAsStringSync();
    final renderer = RegExp(
      r'#let render-fitted-image[\s\S]*?#let render-table',
    ).firstMatch(template)?.group(0);

    expect(renderer, isNotNull);
    expect(renderer, contains('let natural-size = measure(image(asset))'));
    expect(
      renderer,
      contains(
        'let scaled-height = natural-size.height * '
        '(size.width / natural-size.width)',
      ),
    );
    expect(renderer, contains('image(asset, width: 100%'));
    expect(renderer, contains('image(asset, height: maximum-height'));
    expect(renderer, isNot(contains('height: 72% * size.height')));
  });

  test('quotes and admonitions use the existing callout presentation', () {
    final template = File('assets/export/markdown.typ').readAsStringSync();
    final callouts = RegExp(
      r'#let render-callout[\s\S]*?else if kind == "thematicBreak"',
    ).firstMatch(template)?.group(0);

    expect(callouts, isNotNull);
    expect(callouts, contains('stroke: (left: 2pt + accent)'));
    expect(
      callouts,
      contains('title: value-or(block-data, "title", default-title)'),
    );
    expect(callouts, contains('fill: rgb("f5f7fa")'));
    expect(callouts, contains('accent: rgb("4b5563")'));
    expect(callouts, isNot(contains('quote(\n      block: true')));
  });

  test('PDF export ignores redundant blank lines between blocks', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-empty-paragraph-export-test-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final runner = _CapturingTypstRunner();
    final service = MarkdownPdfExportService(
      compilerLocator: const TypstCompilerLocator(
        environment: {'BUSYMARK_TYPST_PATH': '/bin/true'},
      ),
      commandRunner: runner,
      templateLoader: () => File('assets/export/markdown.typ').readAsString(),
    );

    Future<void> export(String source, String name) => service.export(
      MarkdownPdfExportRequest(
        source: source,
        filePath: '/workspace/empty-lines.md',
        workspaceRoot: '/workspace',
        destinationPath: p.join(temporaryDirectory.path, name),
        options: const PdfExportOptions(),
        overwrite: false,
      ),
    );

    await export(
      '# Test Title 1\n\n'
          'Lorem ipsum dolor\n\n'
          'Lorem ipsume dolor 2\n\n'
          'Sincerely,\n\n'
          'User name\n',
      'ordinary.pdf',
    );
    final ordinaryBlocks = runner.payload!['blocks'] as List<dynamic>;
    await export(
      '# Test Title 1\n\n'
          'Lorem ipsum dolor\n\n\n\n'
          'Lorem ipsume dolor 2\n\n\n'
          'Sincerely,\n\n'
          'User name\n',
      'redundant.pdf',
    );
    final redundantBlocks = runner.payload!['blocks'] as List<dynamic>;

    expect(redundantBlocks, ordinaryBlocks);
    expect(
      redundantBlocks.map((value) => (value as Map<String, dynamic>)['kind']),
      ['heading', 'paragraph', 'paragraph', 'paragraph', 'paragraph'],
    );
  });

  test('PDF payload preserves an explicit blank line as two breaks', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-explicit-blank-line-payload-test-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final runner = _CapturingTypstRunner();
    final service = MarkdownPdfExportService(
      compilerLocator: const TypstCompilerLocator(
        environment: {'BUSYMARK_TYPST_PATH': '/bin/true'},
      ),
      commandRunner: runner,
      templateLoader: () => File('assets/export/markdown.typ').readAsString(),
    );

    await service.export(
      MarkdownPdfExportRequest(
        source: 'Before\n<br>\n<br>\nAfter\n',
        filePath: '/workspace/blank-line.md',
        workspaceRoot: '/workspace',
        destinationPath: p.join(temporaryDirectory.path, 'blank-line.pdf'),
        options: const PdfExportOptions(),
        overwrite: false,
      ),
    );

    final blocks = runner.payload!['blocks'] as List<dynamic>;
    final paragraph = blocks.single as Map<String, dynamic>;
    final inlines = paragraph['inlines'] as List<dynamic>;
    expect(inlines.map((value) => (value as Map<String, dynamic>)['kind']), [
      'text',
      'hardBreak',
      'hardBreak',
      'text',
    ]);
  });

  test(
    'bundled template renders two explicit breaks as one blank PDF line',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-explicit-blank-line-typst-test-',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final service = MarkdownPdfExportService(
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      Future<double> textBaselineDelta(String source, String name) async {
        final destination = p.join(temporaryDirectory.path, '$name.pdf');
        await service.export(
          MarkdownPdfExportRequest(
            source: source,
            filePath: p.join(temporaryDirectory.path, '$name.md'),
            workspaceRoot: temporaryDirectory.path,
            destinationPath: destination,
            options: const PdfExportOptions(),
            overwrite: false,
          ),
        );
        final extracted = await Process.run('/usr/bin/pdftotext', [
          '-bbox-layout',
          destination,
          '-',
        ]);
        expect(extracted.exitCode, 0, reason: extracted.stderr.toString());
        final positions = <String, double>{};
        final wordPattern = RegExp(
          r'<word xMin="[^"]+" yMin="([^"]+)" xMax="[^"]+" yMax="[^"]+">(Before|After)</word>',
        );
        for (final match in wordPattern.allMatches(
          extracted.stdout as String,
        )) {
          positions[match.group(2)!] = double.parse(match.group(1)!);
        }
        expect(positions.keys, containsAll(['Before', 'After']));
        return positions['After']! - positions['Before']!;
      }

      final oneBreak = await textBaselineDelta(
        'Before<br>After\n',
        'one-break',
      );
      final twoBreaks = await textBaselineDelta(
        'Before\n<br>\n<br>\nAfter\n',
        'two-breaks',
      );

      expect(oneBreak, greaterThan(0));
      expect(twoBreaks, greaterThan(oneBreak * 1.8));
    },
    skip: canMeasurePdf
        ? false
        : 'Set BUSYMARK_TYPST_PATH and install pdftotext to measure PDF lines.',
  );

  test(
    'bundled template renders redundant blank lines identically',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-empty-paragraph-typst-test-',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final ordinaryDestination = p.join(
        temporaryDirectory.path,
        'ordinary.pdf',
      );
      final redundantDestination = p.join(
        temporaryDirectory.path,
        'redundant.pdf',
      );
      final service = MarkdownPdfExportService(
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      await service.export(
        MarkdownPdfExportRequest(
          source:
              '# Test Title 1\n\n'
              'Lorem ipsum dolor\n\n'
              'Lorem ipsume dolor 2\n\n'
              'Sincerely,\n\n'
              'User name\n',
          filePath: '/workspace/empty-lines.md',
          workspaceRoot: '/workspace',
          destinationPath: ordinaryDestination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      );
      await service.export(
        MarkdownPdfExportRequest(
          source:
              '# Test Title 1\n\n'
              'Lorem ipsum dolor\n\n\n\n'
              'Lorem ipsume dolor 2\n\n\n'
              'Sincerely,\n\n'
              'User name\n',
          filePath: '/workspace/empty-lines.md',
          workspaceRoot: '/workspace',
          destinationPath: redundantDestination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      );

      final ordinaryBytes = await File(ordinaryDestination).readAsBytes();
      final redundantBytes = await File(redundantDestination).readAsBytes();
      expect(ordinaryBytes.take(5), [0x25, 0x50, 0x44, 0x46, 0x2d]);
      expect(redundantBytes, ordinaryBytes);
    },
    skip: canRunTypst
        ? false
        : 'Set BUSYMARK_TYPST_PATH to run the real Typst integration test.',
  );

  test(
    'bundled template exports representative Markdown to a valid PDF',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-export-test-',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final destination = p.join(temporaryDirectory.path, 'guide.pdf');
      final service = MarkdownPdfExportService(
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      final result = await service.export(
        MarkdownPdfExportRequest(
          source: r'''
---
title: BusyMark PDF Test
author: BusyMark
lang: en
---

# Introduction

Unicode: Ελληνικά, العربية, हिन्दी, Українська, 😀.

Text with **bold**, *emphasis*, ~~strike~~, `inline code`, and [a link](https://example.com).

> A block quote with #let injected = true and $not-math$.

1. First item
2. Second item

- [x] Complete
- [ ] Pending

```dart
void main() => print("Hello");
```

| Feature | Status |
| :--- | ---: |
| PDF | Ready |

![Local image](../writerside/basic_project/images/logo.png)

![Remote image](https://example.com/tracker.png)
''',
          filePath: p.absolute('test/fixtures/markdown/export-test.md'),
          workspaceRoot: p.absolute('test/fixtures'),
          destinationPath: destination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      );

      final bytes = await File(destination).readAsBytes();
      expect(bytes.take(5), [0x25, 0x50, 0x44, 0x46, 0x2d]);
      expect(bytes.length, greaterThan(1000));
      expect(result.destinationPath, p.normalize(p.absolute(destination)));
      expect(result.pageCount, anyOf(isNull, greaterThanOrEqualTo(1)));
      expect(
        result.warnings.map((warning) => warning.code),
        contains(MarkdownPdfWarningCode.remoteImageSkipped),
      );
    },
    skip: canRunTypst
        ? false
        : 'Set BUSYMARK_TYPST_PATH to run the real Typst integration test.',
  );

  test(
    'Writerside video poster and link compile into a valid PDF',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-video-export-test-',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final destination = p.join(temporaryDirectory.path, 'video.pdf');
      final service = MarkdownPdfExportService(
        parser: const _WritersideMarkdownParser(),
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      final result = await service.export(
        MarkdownPdfExportRequest(
          source: '''# Video

<video src="https://youtu.be/BeJu9bMPLGU" preview-src="../writerside/basic_project/images/logo.png" width="640"/>
''',
          filePath: p.absolute('test/fixtures/markdown/video.md'),
          workspaceRoot: p.absolute('test/fixtures'),
          destinationPath: destination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      );

      final bytes = await File(destination).readAsBytes();
      expect(bytes.take(5), [0x25, 0x50, 0x44, 0x46, 0x2d]);
      expect(bytes.length, greaterThan(1000));
      expect(result.warnings, isEmpty);
    },
    skip: canRunTypst
        ? false
        : 'Set BUSYMARK_TYPST_PATH to run the real Typst integration test.',
  );

  test(
    'Writerside admonitions compile into a valid PDF',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-admonition-export-test-',
      );
      addTearDown(() async {
        if (await temporaryDirectory.exists()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final destination = p.join(temporaryDirectory.path, 'admonitions.pdf');
      final service = MarkdownPdfExportService(
        parser: const _WritersideMarkdownParser(),
        templateLoader: () => File('assets/export/markdown.typ').readAsString(),
      );

      final result = await service.export(
        MarkdownPdfExportRequest(
          source: '''# Admonitions

> Helpful tip.

> Important note.
{style="note"}

> Dangerous operation.
{style="warning"}

<quote>Neutral quotation.</quote>
''',
          filePath: p.absolute('test/fixtures/markdown/admonitions.md'),
          workspaceRoot: p.absolute('test/fixtures'),
          destinationPath: destination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      );

      final bytes = await File(destination).readAsBytes();
      expect(bytes.take(5), [0x25, 0x50, 0x44, 0x46, 0x2d]);
      expect(bytes.length, greaterThan(1000));
      expect(result.warnings, isEmpty);
    },
    skip: canRunTypst
        ? false
        : 'Set BUSYMARK_TYPST_PATH to run the real Typst integration test.',
  );
}

class _WritersideMarkdownParser extends MarkdownParser {
  const _WritersideMarkdownParser();

  @override
  Future<ParsedMarkdownDocument> parseAsync({
    required String filePath,
    required String source,
    MarkdownMode mode = MarkdownMode.commonMark,
    String? workspaceRoot,
    bool validateLocalReferences = true,
  }) {
    return super.parseAsync(
      filePath: filePath,
      source: source,
      mode: MarkdownMode.writersideMarkdown,
      workspaceRoot: workspaceRoot,
      validateLocalReferences: validateLocalReferences,
    );
  }
}

class _CapturingTypstRunner implements TypstCommandRunner {
  Map<String, dynamic>? payload;

  @override
  Future<TypstProcessResult> compile({
    required String executable,
    required Directory workingDirectory,
    required Duration timeout,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    payload =
        jsonDecode(
              await File(
                p.join(workingDirectory.path, 'document.json'),
              ).readAsString(),
            )
            as Map<String, dynamic>;
    await File(
      p.join(workingDirectory.path, 'output.pdf'),
    ).writeAsString('%PDF-1.7\n1 0 obj\n<<>>\nendobj\n%%EOF\n', flush: true);
    return const TypstProcessResult(exitCode: 0, stdout: '', stderr: '');
  }
}
