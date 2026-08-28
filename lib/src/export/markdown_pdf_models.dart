import 'package:flutter/foundation.dart';

import '../markdown/markdown_model.dart';

enum MarkdownPdfPageSize { a4, letter }

enum MarkdownPdfOrientation { portrait, landscape }

enum MarkdownPdfMargin { narrow, normal, wide }

@immutable
class MarkdownPdfOptions {
  const MarkdownPdfOptions({
    this.pageSize = MarkdownPdfPageSize.a4,
    this.orientation = MarkdownPdfOrientation.portrait,
    this.margin = MarkdownPdfMargin.normal,
    this.pageNumbers = true,
  });

  final MarkdownPdfPageSize pageSize;
  final MarkdownPdfOrientation orientation;
  final MarkdownPdfMargin margin;
  final bool pageNumbers;

  MarkdownPdfOptions copyWith({
    MarkdownPdfPageSize? pageSize,
    MarkdownPdfOrientation? orientation,
    MarkdownPdfMargin? margin,
    bool? pageNumbers,
  }) {
    return MarkdownPdfOptions(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      margin: margin ?? this.margin,
      pageNumbers: pageNumbers ?? this.pageNumbers,
    );
  }

  Map<String, Object> toJson() {
    final (horizontalMargin, verticalMargin) = switch (margin) {
      MarkdownPdfMargin.narrow => (36, 36),
      MarkdownPdfMargin.normal => (57, 57),
      MarkdownPdfMargin.wide => (78, 72),
    };
    return {
      'paper': pageSize == MarkdownPdfPageSize.a4 ? 'a4' : 'us-letter',
      'landscape': orientation == MarkdownPdfOrientation.landscape,
      'marginHorizontalPt': horizontalMargin,
      'marginVerticalPt': verticalMargin,
      'pageNumbers': pageNumbers,
    };
  }
}

enum MarkdownPdfWarningCode {
  remoteImageSkipped,
  imageNotFound,
  imageUnsupported,
  imageTooLarge,
  imageLimitReached,
  imageReadFailed,
  visualizationRenderFailed,
  visualizationLimitReached,
  mathRenderFailed,
  mathLimitReached,
}

@immutable
class MarkdownPdfWarning {
  const MarkdownPdfWarning(this.code, this.destination);

  final MarkdownPdfWarningCode code;
  final String destination;
}

@immutable
class MarkdownPdfExportRequest {
  const MarkdownPdfExportRequest({
    required this.source,
    required this.filePath,
    required this.workspaceRoot,
    required this.destinationPath,
    required this.options,
    required this.overwrite,
    this.mode = MarkdownMode.commonMark,
  });

  final String source;
  final String filePath;
  final String workspaceRoot;
  final String destinationPath;
  final MarkdownPdfOptions options;
  final bool overwrite;
  final MarkdownMode mode;
}

@immutable
class MarkdownPdfExportResult {
  const MarkdownPdfExportResult({
    required this.destinationPath,
    required this.pageCount,
    required this.warnings,
  });

  final String destinationPath;
  final int? pageCount;
  final List<MarkdownPdfWarning> warnings;
}

enum MarkdownPdfFailureCode {
  compilerUnavailable,
  compilerFailed,
  timedOut,
  cancelled,
  invalidOutput,
  destinationExists,
  fileSystem,
}

class MarkdownPdfExportException implements Exception {
  const MarkdownPdfExportException(this.code, {this.detail = '', this.cause});

  final MarkdownPdfFailureCode code;
  final String detail;
  final Object? cause;

  @override
  String toString() => detail.isEmpty
      ? 'Markdown PDF export failed: ${code.name}'
      : 'Markdown PDF export failed: ${code.name}: $detail';
}

class MarkdownPdfCancellationToken {
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
      throw const MarkdownPdfExportException(MarkdownPdfFailureCode.cancelled);
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
