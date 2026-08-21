import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/atomic_file_writer.dart';
import '../markdown/markdown_parser.dart';
import 'markdown_export_assets.dart';
import 'markdown_export_mapper.dart';
import 'markdown_pdf_models.dart';
import 'markdown_visualization_export.dart';
import 'typst_compiler.dart';
import 'typst_payload_builder.dart';

typedef TypstTemplateLoader = Future<String> Function();

class MarkdownPdfExportService {
  const MarkdownPdfExportService({
    this.parser = const MarkdownParser(),
    this.mapper = const MarkdownExportMapper(),
    this.assetStager = const MarkdownExportAssetStager(),
    this.payloadBuilder = const TypstPayloadBuilder(),
    this.compilerLocator = const TypstCompilerLocator(),
    this.commandRunner = const DartTypstCommandRunner(),
    this.fileWriter = const AtomicFileWriter(),
    this.templateLoader = _loadBundledTemplate,
    this.compileTimeout = const Duration(seconds: 45),
    this.maximumPdfBytes = 100 * 1024 * 1024,
    this.visualizationRenderer,
  });

  final MarkdownParser parser;
  final MarkdownExportMapper mapper;
  final MarkdownExportAssetStager assetStager;
  final TypstPayloadBuilder payloadBuilder;
  final TypstCompilerLocator compilerLocator;
  final TypstCommandRunner commandRunner;
  final AtomicFileWriter fileWriter;
  final TypstTemplateLoader templateLoader;
  final Duration compileTimeout;
  final int maximumPdfBytes;
  final MarkdownVisualizationExportRenderer? visualizationRenderer;

  Future<MarkdownPdfExportResult> export(
    MarkdownPdfExportRequest request, {
    MarkdownPdfCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? MarkdownPdfCancellationToken();
    token.throwIfCancelled();
    final executable = compilerLocator.locate();
    if (executable == null) {
      throw const MarkdownPdfExportException(
        MarkdownPdfFailureCode.compilerUnavailable,
        detail: 'The bundled Typst compiler could not be found.',
      );
    }

    final exportRoot = await Directory.systemTemp.createTemp(
      'busymark-pdf-export-',
    );
    try {
      final effectiveFilePath = request.filePath.isEmpty
          ? p.join(
              request.workspaceRoot.isEmpty
                  ? exportRoot.path
                  : request.workspaceRoot,
              'untitled.md',
            )
          : request.filePath;
      final parsed = await parser.parseAsync(
        filePath: effectiveFilePath,
        source: request.source,
        workspaceRoot: request.workspaceRoot.isEmpty
            ? null
            : request.workspaceRoot,
        validateLocalReferences: false,
      );
      token.throwIfCancelled();
      final visualizationPreparation = visualizationRenderer == null
          ? const MarkdownVisualizationExportPreparation(
              blockOverrides: {},
              warnings: [],
            )
          : await visualizationRenderer!.prepare(
              document: parsed.busyDocument,
              exportRoot: exportRoot,
              documentPath: effectiveFilePath,
              workspaceRoot: request.workspaceRoot,
              cancellationToken: token,
            );
      token.throwIfCancelled();
      final document = mapper.map(
        parsed.busyDocument,
        blockOverrides: visualizationPreparation.blockOverrides,
      );
      final stagedAssets = await assetStager.stage(
        document: document,
        exportRoot: exportRoot,
        activeFilePath: effectiveFilePath,
        workspaceRoot: request.workspaceRoot,
        cancellationToken: token,
      );
      final payload = payloadBuilder.build(
        document: document,
        options: request.options,
        assets: stagedAssets.assets,
      );
      await Future.wait([
        File(
          p.join(exportRoot.path, 'document.json'),
        ).writeAsString(jsonEncode(payload), flush: true),
        templateLoader().then(
          (template) => File(
            p.join(exportRoot.path, 'document.typ'),
          ).writeAsString(template, flush: true),
        ),
      ]);
      token.throwIfCancelled();
      final processResult = await commandRunner.compile(
        executable: executable,
        workingDirectory: exportRoot,
        timeout: compileTimeout,
        cancellationToken: token,
      );
      if (processResult.exitCode != 0) {
        throw MarkdownPdfExportException(
          MarkdownPdfFailureCode.compilerFailed,
          detail: _safeCompilerDetail(processResult.stderr),
        );
      }
      final output = File(p.join(exportRoot.path, 'output.pdf'));
      if (!await output.exists()) {
        throw const MarkdownPdfExportException(
          MarkdownPdfFailureCode.invalidOutput,
          detail: 'Typst did not produce a PDF file.',
        );
      }
      final outputSize = await output.length();
      if (outputSize <= 8 || outputSize > maximumPdfBytes) {
        throw const MarkdownPdfExportException(
          MarkdownPdfFailureCode.invalidOutput,
          detail: 'The generated PDF has an invalid size.',
        );
      }
      final pdfBytes = await output.readAsBytes();
      if (!_isPdf(pdfBytes)) {
        throw const MarkdownPdfExportException(
          MarkdownPdfFailureCode.invalidOutput,
          detail: 'The generated file is not a valid PDF.',
        );
      }
      token.throwIfCancelled();
      try {
        await fileWriter.writeBytes(
          request.destinationPath,
          pdfBytes,
          overwrite: request.overwrite,
        );
      } on AtomicFileAlreadyExistsException catch (error) {
        throw MarkdownPdfExportException(
          MarkdownPdfFailureCode.destinationExists,
          detail: error.path,
          cause: error,
        );
      } on FileSystemException catch (error) {
        throw MarkdownPdfExportException(
          MarkdownPdfFailureCode.fileSystem,
          detail: error.message,
          cause: error,
        );
      }
      return MarkdownPdfExportResult(
        destinationPath: p.normalize(p.absolute(request.destinationPath)),
        pageCount: _pageCount(pdfBytes),
        warnings: [
          ...visualizationPreparation.warnings,
          ...stagedAssets.warnings,
        ],
      );
    } on MarkdownPdfExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw MarkdownPdfExportException(
        MarkdownPdfFailureCode.fileSystem,
        detail: error.message,
        cause: error,
      );
    } finally {
      await _deleteExportRootBestEffort(exportRoot);
    }
  }

  static Future<String> _loadBundledTemplate() {
    return rootBundle.loadString('assets/export/markdown.typ');
  }

  String _safeCompilerDetail(String stderr) {
    final normalized = stderr
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.length <= 1000
        ? normalized
        : '${normalized.substring(0, 1000)}…';
  }

  bool _isPdf(List<int> bytes) {
    const header = [0x25, 0x50, 0x44, 0x46, 0x2d];
    if (bytes.length < header.length ||
        !List.generate(
          header.length,
          (index) => bytes[index] == header[index],
        ).every((matches) => matches)) {
      return false;
    }
    final tailStart = (bytes.length - 2048).clamp(0, bytes.length);
    return latin1.decode(bytes.sublist(tailStart)).contains('%%EOF');
  }

  int? _pageCount(List<int> bytes) {
    const needle = [
      0x2f,
      0x54,
      0x79,
      0x70,
      0x65,
      0x20,
      0x2f,
      0x50,
      0x61,
      0x67,
      0x65,
    ];
    var count = 0;
    for (var index = 0; index <= bytes.length - needle.length; index++) {
      var matches = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (bytes[index + offset] != needle[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        count++;
        index += needle.length - 1;
      }
    }
    return count == 0 ? null : count;
  }

  Future<void> _deleteExportRootBestEffort(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on Object {
      // Export completion and failure must not be hidden by cleanup.
    }
  }
}
