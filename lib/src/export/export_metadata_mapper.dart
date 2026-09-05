import 'package:path/path.dart' as p;
import '../markdown/busymark_document.dart';
import 'markdown_export_document.dart';

class ExportMetadataMapper {
  const ExportMetadataMapper();
  MarkdownExportMetadata map(
    BusyDocument document, {
    String? titleOverride,
    String defaultLanguage = 'en',
  }) {
    final frontMatter = {
      for (final entry in document.frontMatter.entries)
        entry.key.toLowerCase().trim(): entry.value.trim(),
    };
    final title = _firstNonEmpty([
      titleOverride,
      frontMatter['title'],
      document.title,
      document.filePath.isEmpty
          ? null
          : p.basenameWithoutExtension(document.filePath),
      'Untitled',
    ])!;
    final keywords = _firstNonEmpty([
      frontMatter['keywords'],
      frontMatter['tags'],
    ]);
    return MarkdownExportMetadata(
      title: title,
      author:
          _firstNonEmpty([frontMatter['author'], frontMatter['authors']]) ?? '',
      description:
          _firstNonEmpty([
            frontMatter['description'],
            frontMatter['summary'],
            frontMatter['web-summary'],
          ]) ??
          '',
      language: _normalizedLanguage(
        _firstNonEmpty([frontMatter['lang'], frontMatter['language']]) ??
            defaultLanguage,
      ),
      keywords: keywords == null
          ? const []
          : keywords
                .split(RegExp(r'[,;]'))
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .take(32)
                .toList(growable: false),
    );
  }

  String _normalizedLanguage(String? value) {
    final normalized = value?.trim().replaceAll('_', '-') ?? 'en';
    return RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$').hasMatch(normalized)
        ? normalized
        : 'und';
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
