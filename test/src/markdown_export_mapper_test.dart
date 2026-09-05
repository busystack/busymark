import 'dart:convert';

import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_payload_builder.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = MarkdownParser();
  const mapper = MarkdownExportMapper();

  test('maps Markdown semantics into renderer-neutral export blocks', () {
    final parsed = parser.parse(
      filePath: '/workspace/guide.md',
      source: '''
---
title: Export guide
author: BusyMark Team
lang: fr-CA
tags: markdown, pdf
---

# Introduction

Text with **bold**, [safe](https://example.com), and [unsafe](javascript:alert(1)).

1. First
2. Second

- [x] Done

| Name | Value |
| --- | ---: |
| A | 1 |
''',
      validateLocalReferences: false,
    );

    final document = mapper.map(parsed.busyDocument);

    expect(document.metadata.title, 'Export guide');
    expect(document.metadata.author, 'BusyMark Team');
    expect(document.metadata.language, 'fr-CA');
    expect(document.metadata.keywords, ['markdown', 'pdf']);
    expect(
      document.blocks.map((block) => block.kind),
      containsAll([
        MarkdownExportBlockKind.heading,
        MarkdownExportBlockKind.paragraph,
        MarkdownExportBlockKind.list,
        MarkdownExportBlockKind.table,
      ]),
    );
    final lists = document.blocks
        .where((block) => block.kind == MarkdownExportBlockKind.list)
        .toList();
    expect(lists.first.attributes['ordered'], isTrue);
    expect(lists.first.children, hasLength(2));
    expect(lists.last.children.single.attributes['task'], isTrue);

    final paragraph = document.blocks.firstWhere(
      (block) => block.kind == MarkdownExportBlockKind.paragraph,
    );
    final links = paragraph.inlines
        .where((inline) => inline.kind == MarkdownExportInlineKind.link)
        .toList();
    expect(links.first.destination, 'https://example.com');
    expect(links.last.destination, isNull);
  });

  test('omits reference definitions while preserving their resolved links', () {
    final parsed = parser.parse(
      filePath: '/workspace/guide.md',
      source: '''
[1]: https://example.com/exports "Exports"
[2]: https://example.com/security "Security"

# Plan

Review [the export guide][1].
''',
      validateLocalReferences: false,
    );

    expect(
      parsed.busyDocument.blocks.where((block) => block.isSourceOnly),
      hasLength(2),
    );

    final document = mapper.map(parsed.busyDocument);
    expect(document.blocks.map((block) => block.kind), [
      MarkdownExportBlockKind.heading,
      MarkdownExportBlockKind.paragraph,
    ]);

    final link = document.blocks.last.inlines.singleWhere(
      (inline) => inline.kind == MarkdownExportInlineKind.link,
    );
    expect(link.destination, 'https://example.com/exports');

    final payload = const TypstPayloadBuilder().build(
      document: document,
      options: const PdfExportOptions(),
      assets: const {},
    );
    expect(jsonEncode(payload), isNot(contains('[1]:')));
    expect(jsonEncode(payload), isNot(contains('[2]:')));
  });

  test('Typst payload contains data but never raw local image paths', () {
    final parsed = parser.parse(
      filePath: '/workspace/guide.md',
      source: r'![Diagram](private/diagram.png) #let hacked = true',
      validateLocalReferences: false,
    );
    final document = mapper.map(parsed.busyDocument);
    final payload = const TypstPayloadBuilder().build(
      document: document,
      options: const PdfExportOptions(),
      assets: const {'private/diagram.png': 'assets/safe.png'},
    );
    final json = jsonEncode(payload);

    expect(json, contains(r'#let hacked = true'));
    expect(json, contains('assets/safe.png'));
    expect(json, isNot(contains('private/diagram.png')));
  });
}
