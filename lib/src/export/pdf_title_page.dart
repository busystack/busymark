import 'package:flutter/foundation.dart';

import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../writerside/writerside_model.dart';
import 'export_metadata_mapper.dart';
import 'export_options.dart';

/// Resolved text for one PDF export, never a global preference. Empty optional
/// values deliberately suppress metadata defaults. All values are plain text.
@immutable
class PdfTitlePageData {
  const PdfTitlePageData({
    required this.title,
    this.subtitle = '',
    this.author = '',
    this.organization = '',
    this.version = '',
    this.date = '',
  });

  factory PdfTitlePageData.fromDocument(
    BusyDocument document, {
    String? titleOverride,
  }) {
    final metadata = const ExportMetadataMapper().map(
      document,
      titleOverride: titleOverride,
    );
    final source = {
      for (final entry in document.frontMatter.entries)
        entry.key.toLowerCase().trim(): entry.value,
    };
    return PdfTitlePageData(
      title: metadata.title,
      author: metadata.author,
      subtitle: source['subtitle'] ?? '',
      organization: source['organization'] ?? '',
      version: source['version'] ?? '',
      date: source['date'] ?? '',
    );
  }

  factory PdfTitlePageData.forInstance(WritersideInstance instance) =>
      PdfTitlePageData.fromDocument(
        BusyDocument(
          filePath: '',
          mode: MarkdownMode.writersideMarkdown,
          title: instance.name,
          blocks: const [],
        ),
        titleOverride: instance.name,
      ).copyWith(version: instance.effectiveVersion ?? '');

  final String title, subtitle, author, organization, version, date;

  PdfTitlePageData copyWith({
    String? title,
    String? subtitle,
    String? author,
    String? organization,
    String? version,
    String? date,
  }) => PdfTitlePageData(
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    author: author ?? this.author,
    organization: organization ?? this.organization,
    version: version ?? this.version,
    date: date ?? this.date,
  );

  List<ExportOptionIssue> validate() => [
    if (title.trim().isEmpty) const ExportOptionIssue('titlePage.title'),
  ];

  Map<String, String> toJson() => {
    'title': title,
    if (subtitle.trim().isNotEmpty) 'subtitle': subtitle,
    if (author.trim().isNotEmpty) 'author': author,
    if (organization.trim().isNotEmpty) 'organization': organization,
    if (version.trim().isNotEmpty) 'version': version,
    if (date.trim().isNotEmpty) 'date': date,
  };
}
