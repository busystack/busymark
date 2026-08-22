import 'dart:io';

import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final typstPath = Platform.environment['BUSYMARK_TYPST_PATH'];
  final canRunTypst = typstPath != null && File(typstPath).existsSync();

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
          options: const MarkdownPdfOptions(),
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
          options: const MarkdownPdfOptions(),
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
