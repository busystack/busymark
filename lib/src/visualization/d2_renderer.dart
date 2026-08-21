import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'generated_svg_normalizer.dart';
import 'visualization_models.dart';
import 'visualization_raster_sizing.dart';
import 'visualization_renderer.dart';
import 'web_render_host.dart';

const _d2ImportsDisabledMessage = 'D2 imports are disabled in fenced diagrams.';
const _d2ExternalAssetsDisabledMessage =
    'D2 icon and image assets are disabled in fenced diagrams.';
const _d2SourceTooLargeMessage = 'D2 source exceeds the size limit.';
const _d2UnavailableMessage = 'The bundled D2 renderer could not be found.';
const _d2InvalidUtf8Message = 'D2 returned invalid UTF-8 output.';

class D2ExecutableLocator {
  const D2ExecutableLocator({this.environment, this.resolvedExecutable});

  final Map<String, String>? environment;
  final String? resolvedExecutable;

  String? locate() {
    final processEnvironment = environment ?? Platform.environment;
    final candidates = <String>[
      if (processEnvironment['BUSYMARK_D2_PATH'] case final override?) override,
      if (processEnvironment['SNAP'] case final snapRoot?)
        p.join(snapRoot, 'libexec', 'busymark', 'd2'),
      p.join(
        p.dirname(resolvedExecutable ?? Platform.resolvedExecutable),
        'libexec',
        'busymark',
        'd2',
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

class D2SourcePolicy {
  const D2SourcePolicy();

  VisualizationDiagnostic? validate(String source) {
    var inBlockComment = false;
    String? blockStringTerminator;
    final lines = const LineSplitter().convert(source);
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      var line = lines[lineIndex];
      var offset = 0;
      if (blockStringTerminator != null) {
        final firstNonWhitespace = line.length - line.trimLeft().length;
        if (!line.startsWith(blockStringTerminator, firstNonWhitespace)) {
          continue;
        }
        offset = firstNonWhitespace + blockStringTerminator.length;
        blockStringTerminator = null;
      }

      final visible = StringBuffer();
      for (var index = offset; index < line.length;) {
        if (inBlockComment) {
          final end = line.indexOf('"""', index);
          if (end < 0) {
            index = line.length;
            continue;
          }
          inBlockComment = false;
          index = end + 3;
          continue;
        }
        if (line.startsWith('"""', index)) {
          inBlockComment = true;
          index += 3;
          continue;
        }
        final character = line[index];
        if (character == '#') {
          break;
        }
        if (character == '"' || character == "'") {
          final quote = character;
          visible.write(' ');
          index++;
          while (index < line.length) {
            if (line[index] == r'\' && index + 1 < line.length) {
              visible.write('  ');
              index += 2;
              continue;
            }
            visible.write(' ');
            if (line[index] == quote) {
              index++;
              break;
            }
            index++;
          }
          continue;
        }
        visible.write(character);
        index++;
      }

      final inspectable = visible.toString();
      final importColumn = inspectable.indexOf('@');
      if (importColumn >= 0) {
        return VisualizationDiagnostic(
          code: 'visualization.d2ImportsDisabled',
          message: _d2ImportsDisabledMessage,
          severity: VisualizationDiagnosticSeverity.error,
          line: lineIndex + 1,
          column: importColumn + 1,
        );
      }
      final iconMatch = RegExp(
        r'(?<![A-Za-z0-9_-])icon\s*:',
        caseSensitive: false,
      ).firstMatch(inspectable);
      if (iconMatch != null) {
        return VisualizationDiagnostic(
          code: 'visualization.d2ExternalAssetsDisabled',
          message: _d2ExternalAssetsDisabledMessage,
          severity: VisualizationDiagnosticSeverity.error,
          line: lineIndex + 1,
          column: iconMatch.start + 1,
        );
      }

      final opening = RegExp(
        r':\s*(\|[^A-Za-z0-9_\s]*)[A-Za-z0-9_]*\s*$',
      ).firstMatch(inspectable);
      if (opening != null) {
        blockStringTerminator = opening.group(1)!.split('').reversed.join();
      }
    }
    return null;
  }
}

class D2ProcessResult {
  const D2ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final Uint8List stdout;
  final String stderr;
}

abstract interface class D2CommandRunner {
  Future<D2ProcessResult> render({
    required String executable,
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  });
}

class DartD2CommandRunner implements D2CommandRunner {
  const DartD2CommandRunner({
    this.timeout = const Duration(seconds: 12),
    this.maximumOutputBytes = 16 * 1024 * 1024,
    this.maximumDiagnosticBytes = 64 * 1024,
  });

  final Duration timeout;
  final int maximumOutputBytes;
  final int maximumDiagnosticBytes;

  @override
  Future<D2ProcessResult> render({
    required String executable,
    required String source,
    required VisualizationTheme theme,
    required VisualizationCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    final workingDirectory = await Directory.systemTemp.createTemp(
      'busymark-d2-',
    );
    Process? process;
    Timer? forceKillTimer;
    var processExited = false;
    void terminate() {
      final activeProcess = process;
      if (activeProcess == null || processExited) {
        return;
      }
      activeProcess.kill(ProcessSignal.sigterm);
      forceKillTimer ??= Timer(const Duration(milliseconds: 300), () {
        if (!processExited) {
          activeProcess.kill(ProcessSignal.sigkill);
        }
      });
    }

    try {
      final themeId = theme == VisualizationTheme.dark ? '200' : '0';
      process = await Process.start(
        p.normalize(p.absolute(executable)),
        [
          '--layout',
          'dagre',
          '--theme',
          themeId,
          '--dark-theme',
          themeId,
          '--pad',
          '24',
          '--timeout',
          '10',
          '--bundle=false',
          '--omit-version',
          '--no-xml-tag',
          '-',
          '-',
        ],
        workingDirectory: workingDirectory.path,
        environment: const {
          'LANG': 'C.UTF-8',
          'LC_ALL': 'C.UTF-8',
          'BROWSER': '0',
          'IMG_CACHE': '0',
        },
        includeParentEnvironment: false,
        runInShell: false,
      );
      cancellationToken.onCancel(terminate);
      process.stdin.write(source);
      await process.stdin.close();

      final values =
          await Future.wait<Object>([
            process.exitCode.then((value) {
              processExited = true;
              return value;
            }),
            _collectBounded(
              process.stdout,
              maximumOutputBytes,
              onLimitExceeded: terminate,
            ),
            _collectBounded(
              process.stderr,
              maximumDiagnosticBytes,
              onLimitExceeded: terminate,
            ),
          ]).timeout(
            timeout,
            onTimeout: () {
              terminate();
              throw const D2ProcessException(
                'visualization.timeout',
                'The D2 renderer timed out.',
              );
            },
          );
      cancellationToken.throwIfCancelled();
      return D2ProcessResult(
        exitCode: values[0] as int,
        stdout: values[1] as Uint8List,
        stderr: utf8.decode(values[2] as Uint8List, allowMalformed: true),
      );
    } on D2ProcessException {
      rethrow;
    } on VisualizationCancelledException {
      rethrow;
    } on Object catch (error) {
      throw D2ProcessException(
        'visualization.d2Unavailable',
        'The bundled D2 renderer could not be started: $error',
      );
    } finally {
      cancellationToken.removeListener(terminate);
      terminate();
      if (!processExited) {
        process?.kill(ProcessSignal.sigkill);
        try {
          await process?.exitCode.timeout(const Duration(seconds: 1));
        } on Object {
          // The process has already received SIGKILL; cleanup remains best effort.
        }
      }
      forceKillTimer?.cancel();
      await _deleteDirectoryBestEffort(workingDirectory);
    }
  }

  Future<Uint8List> _collectBounded(
    Stream<List<int>> stream,
    int limit, {
    required void Function() onLimitExceeded,
  }) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (bytes.length + chunk.length > limit) {
        onLimitExceeded();
        throw const D2ProcessException(
          'visualization.outputTooLarge',
          'D2 output exceeds the size limit.',
        );
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<void> _deleteDirectoryBestEffort(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException {
      // Temporary rendering data is best-effort cleanup.
    }
  }
}

class D2ProcessException implements Exception {
  const D2ProcessException(this.code, this.message);

  final String code;
  final String message;
}

class D2VisualizationRenderer implements VisualizationRenderer {
  const D2VisualizationRenderer({
    required this.webRenderHost,
    this.locator = const D2ExecutableLocator(),
    this.commandRunner = const DartD2CommandRunner(),
    this.sourcePolicy = const D2SourcePolicy(),
    this.svgNormalizer = const GeneratedSvgNormalizer(),
    this.rasterSizingPolicy = const VisualizationRasterSizingPolicy(),
    this.maximumSourceCharacters = 500000,
  });

  final WebRenderHost webRenderHost;
  final D2ExecutableLocator locator;
  final D2CommandRunner commandRunner;
  final D2SourcePolicy sourcePolicy;
  final GeneratedSvgNormalizer svgNormalizer;
  final VisualizationRasterSizingPolicy rasterSizingPolicy;
  final int maximumSourceCharacters;

  @override
  Set<VisualizationRendererKind> get supportedKinds => const {
    VisualizationRendererKind.d2,
  };

  @override
  Future<VisualizationRenderRequest> prepare(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    return request;
  }

  @override
  Future<VisualizationRenderResult> render(
    VisualizationRenderRequest request,
    VisualizationCancellationToken cancellationToken,
  ) async {
    if (request.source.length > maximumSourceCharacters) {
      return const UnsupportedVisualizationResult(
        feature: 'visualization.sourceTooLarge',
        diagnostics: [
          VisualizationDiagnostic(
            code: 'visualization.sourceTooLarge',
            message: _d2SourceTooLargeMessage,
            severity: VisualizationDiagnosticSeverity.error,
          ),
        ],
      );
    }
    if (sourcePolicy.validate(request.source) case final diagnostic?) {
      return UnsupportedVisualizationResult(
        feature: diagnostic.code,
        diagnostics: [diagnostic],
      );
    }
    final executable = locator.locate();
    if (executable == null) {
      return const FailedVisualizationResult(
        code: 'visualization.d2Unavailable',
        message: _d2UnavailableMessage,
        retryable: false,
      );
    }
    try {
      final processResult = await commandRunner.render(
        executable: executable,
        source: request.source,
        theme: request.theme,
        cancellationToken: cancellationToken,
      );
      cancellationToken.throwIfCancelled();
      if (processResult.exitCode != 0) {
        final diagnostics = _diagnostics(processResult.stderr);
        return FailedVisualizationResult(
          code: 'visualization.invalidD2',
          message: diagnostics.isEmpty
              ? 'D2 could not render this block.'
              : diagnostics.first.message,
          retryable: false,
          diagnostics: diagnostics,
        );
      }
      final svg = utf8.decode(processResult.stdout);
      final normalized = svgNormalizer.normalize(svg);
      cancellationToken.throwIfCancelled();
      if (normalized.vectorSafeSvg == null) {
        final rasterSize = rasterSizingPolicy.fit(
          width: normalized.width,
          height: normalized.height,
          profile: request.profile,
        );
        final png = await webRenderHost.rasterizeSvg(
          svg: normalized.browserSafeSvg,
          width: normalized.width,
          height: normalized.height,
          scale: rasterSize.scale,
          cancellationToken: cancellationToken,
        );
        cancellationToken.throwIfCancelled();
        return RasterVisualizationResult(
          pngBytes: png,
          width: rasterSize.pixelWidth,
          height: rasterSize.pixelHeight,
        );
      }
      return SvgVisualizationResult(
        svg: normalized.vectorSafeSvg!,
        width: normalized.width,
        height: normalized.height,
      );
    } on VisualizationCancelledException {
      rethrow;
    } on D2ProcessException catch (error) {
      return FailedVisualizationResult(
        code: error.code,
        message: error.message,
      );
    } on GeneratedSvgException catch (error) {
      return FailedVisualizationResult(
        code: error.code,
        message: error.message,
        retryable: false,
      );
    } on FormatException {
      return const FailedVisualizationResult(
        code: 'visualization.invalidD2Output',
        message: _d2InvalidUtf8Message,
        retryable: false,
      );
    }
  }

  List<VisualizationDiagnostic> _diagnostics(String stderr) {
    final diagnostics = <VisualizationDiagnostic>[];
    final pattern = RegExp(r'(?:^|\s)-:(\d+):(\d+):\s*([^\r\n]+)');
    for (final match in pattern.allMatches(stderr)) {
      diagnostics.add(
        VisualizationDiagnostic(
          code: 'visualization.invalidD2',
          message: match.group(3)!.trim(),
          severity: VisualizationDiagnosticSeverity.error,
          line: int.parse(match.group(1)!),
          column: int.parse(match.group(2)!),
        ),
      );
    }
    return diagnostics;
  }
}
