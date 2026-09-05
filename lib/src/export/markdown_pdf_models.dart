import 'package:flutter/foundation.dart';

import '../markdown/markdown_model.dart';
import 'export_options.dart';
import '../markdown/busymark_document.dart';

export 'export_options.dart';

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
  writersideResolution,
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
    this.document,
  });

  final String source;
  final String filePath;
  final String workspaceRoot;
  final String destinationPath;
  final PdfExportOptions options;
  final bool overwrite;
  final MarkdownMode mode;

  /// A pre-parsed semantic document. When present, PDF export consumes this
  /// tree directly and [source] is not reparsed.
  final BusyDocument? document;
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
