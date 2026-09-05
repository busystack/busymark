import '../markdown/markdown_model.dart';
import 'export_options.dart';
export 'export_options.dart';
import '../markdown/busymark_document.dart';

class HtmlExportWarning {
  const HtmlExportWarning(
    this.code,
    this.message, {
    this.sourcePath = '',
    this.line = 1,
  });
  final String code;
  final String message;
  final String sourcePath;
  final int line;
  @override
  String toString() =>
      '${sourcePath.isEmpty ? '' : '$sourcePath:$line: '}$message';
}

class HtmlExportException implements Exception {
  const HtmlExportException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

class HtmlExportCancellationToken {
  bool _cancelled = false;
  final Set<void Function()> _listeners = {};
  bool get isCancelled => _cancelled;
  void cancel() {
    _cancelled = true;
    for (final listener in _listeners.toList()) {
      listener();
    }
  }

  void attach(void Function() listener) {
    _listeners.add(listener);
    if (_cancelled) listener();
  }

  void detach(void Function() listener) => _listeners.remove(listener);
  void check() {
    if (_cancelled) {
      throw const HtmlExportException(
        'HTML export cancelled.',
        cancelled: true,
      );
    }
  }
}

class HtmlExportLimits {
  const HtmlExportLimits({
    this.topics = 2000,
    this.sourceBytes = 64 * 1024 * 1024,
    this.assetBytes = 16 * 1024 * 1024,
    this.totalAssetBytes = 128 * 1024 * 1024,
    this.assets = 2048,
    this.graphics = 512,
    this.depth = 64,
    this.renderTimeout = const Duration(seconds: 45),
  });
  final int topics,
      sourceBytes,
      assetBytes,
      totalAssetBytes,
      assets,
      graphics,
      depth;
  final Duration renderTimeout;
}

class MarkdownHtmlExportRequest {
  const MarkdownHtmlExportRequest({
    required this.source,
    required this.filePath,
    required this.workspaceRoot,
    required this.destinationPath,
    this.overwrite = false,
    this.mode = MarkdownMode.commonMark,
    this.document,
    this.options = const HtmlExportOptions(),
  });
  final String source, filePath, workspaceRoot, destinationPath;
  final bool overwrite;
  final MarkdownMode mode;
  final BusyDocument? document;
  final HtmlExportOptions options;
}

class HtmlExportResult {
  const HtmlExportResult({
    required this.entryPointPath,
    required this.warnings,
    this.assetsPath,
    this.pageCount = 1,
  });
  final String entryPointPath;
  final String? assetsPath;
  final int pageCount;
  final List<HtmlExportWarning> warnings;
}

typedef HtmlExportProgress = void Function(int completed, int total);
