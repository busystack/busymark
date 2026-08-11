import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'markdown_pdf_models.dart';

const typstCompilerVersion = '0.15.1';

class TypstCompilerLocator {
  const TypstCompilerLocator({this.environment, this.resolvedExecutable});

  final Map<String, String>? environment;
  final String? resolvedExecutable;

  String? locate() {
    final processEnvironment = environment ?? Platform.environment;
    final candidates = <String>[
      if (processEnvironment['BUSYMARK_TYPST_PATH'] case final override?)
        override,
      if (processEnvironment['SNAP'] case final snapRoot?)
        p.join(snapRoot, 'libexec', 'busymark', 'typst'),
      p.join(
        p.dirname(resolvedExecutable ?? Platform.resolvedExecutable),
        'libexec',
        'busymark',
        'typst',
      ),
    ];
    for (final candidate in candidates) {
      if (candidate.trim().isEmpty) {
        continue;
      }
      try {
        final file = File(p.normalize(p.absolute(candidate)));
        final stat = file.statSync();
        if (stat.type == FileSystemEntityType.file && stat.mode & 0x49 != 0) {
          return file.path;
        }
      } on FileSystemException {
        // Try the next deterministic bundle location.
      }
    }
    return null;
  }
}

class TypstProcessResult {
  const TypstProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract class TypstCommandRunner {
  Future<TypstProcessResult> compile({
    required String executable,
    required Directory workingDirectory,
    required Duration timeout,
    required MarkdownPdfCancellationToken cancellationToken,
  });
}

class DartTypstCommandRunner implements TypstCommandRunner {
  const DartTypstCommandRunner({this.maximumDiagnosticBytes = 64 * 1024});

  final int maximumDiagnosticBytes;

  @override
  Future<TypstProcessResult> compile({
    required String executable,
    required Directory workingDirectory,
    required Duration timeout,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    Process process;
    try {
      process = await Process.start(
        executable,
        const [
          'compile',
          '--root',
          '.',
          '--format',
          'pdf',
          '--pdf-standard',
          '1.7',
          '--creation-timestamp',
          '0',
          '--diagnostic-format',
          'short',
          'document.typ',
          'output.pdf',
        ],
        workingDirectory: workingDirectory.path,
        environment: {
          'TYPST_PACKAGE_PATH': p.join(workingDirectory.path, 'packages'),
          'TYPST_PACKAGE_CACHE_PATH': p.join(workingDirectory.path, 'cache'),
        },
        includeParentEnvironment: true,
        runInShell: false,
      );
    } on Object catch (error) {
      throw MarkdownPdfExportException(
        MarkdownPdfFailureCode.compilerUnavailable,
        detail: error.toString(),
        cause: error,
      );
    }

    var cancelled = false;
    var processExited = false;
    final exitCodeFuture = process.exitCode.then((exitCode) {
      processExited = true;
      return exitCode;
    });
    cancellationToken.attach(() {
      cancelled = true;
      process.kill(ProcessSignal.sigterm);
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (!processExited) {
            process.kill(ProcessSignal.sigkill);
          }
        }),
      );
    });
    final stdoutFuture = _collectBounded(process.stdout);
    final stderrFuture = _collectBounded(process.stderr);
    try {
      final exitCode = await exitCodeFuture.timeout(
        timeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigterm);
          throw const MarkdownPdfExportException(
            MarkdownPdfFailureCode.timedOut,
          );
        },
      );
      processExited = true;
      if (cancelled || cancellationToken.isCancelled) {
        throw const MarkdownPdfExportException(
          MarkdownPdfFailureCode.cancelled,
        );
      }
      return TypstProcessResult(
        exitCode: exitCode,
        stdout: await stdoutFuture,
        stderr: await stderrFuture,
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw const MarkdownPdfExportException(MarkdownPdfFailureCode.timedOut);
    } on MarkdownPdfExportException catch (error) {
      if (error.code == MarkdownPdfFailureCode.timedOut) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        process.kill(ProcessSignal.sigkill);
      }
      rethrow;
    } finally {
      processExited = true;
      cancellationToken.detach();
    }
  }

  Future<String> _collectBounded(Stream<List<int>> stream) async {
    final bytes = <int>[];
    await for (final chunk in stream) {
      final remaining = maximumDiagnosticBytes - bytes.length;
      if (remaining > 0) {
        bytes.addAll(chunk.take(remaining));
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
