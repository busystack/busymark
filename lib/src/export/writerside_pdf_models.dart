import 'package:flutter/foundation.dart';

import 'markdown_pdf_models.dart';

/// The current official Writerside builder documented by JetBrains when this
/// BusyMark release was prepared. The repository is intentionally fixed; users
/// may select another version tag, but not an arbitrary container image.
const writersideBuilderRepository = 'jetbrains/writerside-builder';
const writersideBuilderDefaultVersion = '2026.07.8925';

enum WritersidePdfConfigurationMode { generated, projectFile }

@immutable
class WritersidePdfKeymapLayout {
  const WritersidePdfKeymapLayout({
    required this.name,
    required this.displayName,
  });

  final String name;
  final String displayName;
}

@immutable
class WritersidePdfCoverOptions {
  const WritersidePdfCoverOptions({
    this.enabled = false,
    this.title = '',
    this.logoPath = '',
    this.description = '',
    this.copyright = '',
  });

  final bool enabled;
  final String title;
  final String logoPath;
  final String description;
  final String copyright;

  WritersidePdfCoverOptions copyWith({
    bool? enabled,
    String? title,
    String? logoPath,
    String? description,
    String? copyright,
  }) {
    return WritersidePdfCoverOptions(
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      logoPath: logoPath ?? this.logoPath,
      description: description ?? this.description,
      copyright: copyright ?? this.copyright,
    );
  }
}

@immutable
class WritersidePdfOptions {
  const WritersidePdfOptions({
    this.orientation = MarkdownPdfOrientation.portrait,
    this.layout = '',
    this.cover = const WritersidePdfCoverOptions(),
    this.header = '',
    this.footer = '',
    this.tocTitle = '',
  });

  final MarkdownPdfOrientation orientation;
  final String layout;
  final WritersidePdfCoverOptions cover;
  final String header;
  final String footer;
  final String tocTitle;

  WritersidePdfOptions copyWith({
    MarkdownPdfOrientation? orientation,
    String? layout,
    WritersidePdfCoverOptions? cover,
    String? header,
    String? footer,
    String? tocTitle,
  }) {
    return WritersidePdfOptions(
      orientation: orientation ?? this.orientation,
      layout: layout ?? this.layout,
      cover: cover ?? this.cover,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      tocTitle: tocTitle ?? this.tocTitle,
    );
  }
}

@immutable
class WritersidePdfExportRequest {
  const WritersidePdfExportRequest({
    required this.moduleRoot,
    required this.sourceRoot,
    required this.moduleName,
    required this.buildConfigDirectory,
    required this.instanceId,
    required this.destinationPath,
    required this.overwrite,
    required this.builderVersion,
    required this.configurationMode,
    this.options = const WritersidePdfOptions(),
    this.projectConfigurationPath,
    this.allowNetwork = false,
  });

  final String moduleRoot;
  final String sourceRoot;
  final String moduleName;
  final String buildConfigDirectory;
  final String instanceId;
  final String destinationPath;
  final bool overwrite;
  final String builderVersion;
  final WritersidePdfConfigurationMode configurationMode;
  final WritersidePdfOptions options;
  final String? projectConfigurationPath;
  final bool allowNetwork;

  String get builderImage => '$writersideBuilderRepository:$builderVersion';
}

@immutable
class WritersidePdfExportResult {
  const WritersidePdfExportResult({
    required this.destinationPath,
    required this.pageCount,
    required this.builderVersion,
    required this.buildLog,
  });

  final String destinationPath;
  final int? pageCount;
  final String builderVersion;
  final String buildLog;
}

enum WritersidePdfFailureCode {
  dockerUnavailable,
  builderImageUnavailable,
  invalidRequest,
  invalidConfiguration,
  buildFailed,
  timedOut,
  cancelled,
  invalidOutput,
  destinationExists,
  fileSystem,
}

class WritersidePdfExportException implements Exception {
  const WritersidePdfExportException(this.code, {this.detail = '', this.cause});

  final WritersidePdfFailureCode code;
  final String detail;
  final Object? cause;

  @override
  String toString() => detail.isEmpty
      ? 'Writerside PDF export failed: ${code.name}'
      : 'Writerside PDF export failed: ${code.name}: $detail';
}

class WritersidePdfCancellationToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _onCancel?.call();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.cancelled,
      );
    }
  }

  void attach(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) {
      onCancel();
    }
  }

  void detach() {
    _onCancel = null;
  }
}
