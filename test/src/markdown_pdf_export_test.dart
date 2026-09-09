import 'dart:io';

import 'package:busymark/src/core/atomic_file_writer.dart';
import 'package:busymark/src/export/markdown_export_assets.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/export/markdown_pdf_export_service.dart';
import 'package:busymark/src/export/markdown_pdf_export_ui.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/typst_compiler.dart';
import 'package:busymark/src/export/writerside_pdf_export_ui.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('PDF export eligibility is limited to active regular Markdown', () {
    const parser = MarkdownParser();
    final parsed = parser.parse(
      filePath: '/docs/readme.md',
      source: '# Read me',
      validateLocalReferences: false,
    );
    final markdownFile = DocumentFile(
      absolutePath: '/docs/readme.md',
      relativePath: 'readme.md',
      kind: DocumentKind.markdown,
      size: 9,
      lastModified: DateTime(2026),
    );
    Workspace workspace(WorkspaceKind kind) => Workspace(
      id: 'workspace',
      rootPath: '/docs',
      kind: kind,
      openedAt: DateTime(2026),
      activeFilePath: '/docs/readme.md',
      files: [markdownFile],
      diagnostics: const [],
      markdown: parsed,
    );

    expect(
      canExportActiveMarkdown(
        WorkspaceState(workspace: workspace(WorkspaceKind.singleMarkdown)),
      ),
      isTrue,
    );
    expect(
      canExportActiveMarkdown(
        WorkspaceState(workspace: workspace(WorkspaceKind.markdownFolder)),
      ),
      isTrue,
    );
    expect(
      canExportActiveMarkdown(
        WorkspaceState(workspace: workspace(WorkspaceKind.writersideModule)),
      ),
      isFalse,
    );
    expect(canExportActiveMarkdown(const WorkspaceState()), isFalse);
  });

  test('workspace PDF export accepts a Writerside module instance', () async {
    final module = await const WritersideModuleService().load(
      'test/fixtures/writerside/basic_project',
    );
    final workspace = Workspace(
      id: 'writerside',
      rootPath: module.rootPath,
      kind: WorkspaceKind.writersideModule,
      openedAt: DateTime(2026),
      files: const [],
      diagnostics: const [],
      writersideModule: module,
    );

    expect(canExportWorkspacePdf(WorkspaceState(workspace: workspace)), isTrue);
    expect(
      canExportActiveMarkdown(WorkspaceState(workspace: workspace)),
      isFalse,
    );
    expect(defaultWritersideModuleName(module), 'BusyMark Test');
  });

  test('atomic PDF publication never replaces without confirmation', () async {
    if (!Platform.isLinux) {
      return;
    }
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-atomic-export-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final path = p.join(temporaryDirectory.path, 'document.pdf');
    const writer = AtomicFileWriter();

    await writer.writeBytes(path, [1, 2, 3], overwrite: false);
    expect(await File(path).readAsBytes(), [1, 2, 3]);
    await expectLater(
      writer.writeBytes(path, [4, 5, 6], overwrite: false),
      throwsA(isA<AtomicFileAlreadyExistsException>()),
    );
    expect(await File(path).readAsBytes(), [1, 2, 3]);

    await writer.writeBytes(path, [4, 5, 6], overwrite: true);
    expect(await File(path).readAsBytes(), [4, 5, 6]);
  });

  test('service rejects compiler output that is not a PDF', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-invalid-pdf-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final destination = p.join(temporaryDirectory.path, 'document.pdf');
    final service = MarkdownPdfExportService(
      compilerLocator: const _FixedCompilerLocator('/bin/true'),
      commandRunner: const _InvalidOutputRunner(),
      templateLoader: () async => '#text("test")',
    );

    await expectLater(
      service.export(
        MarkdownPdfExportRequest(
          source: '# Test',
          filePath: p.join(temporaryDirectory.path, 'document.md'),
          workspaceRoot: temporaryDirectory.path,
          destinationPath: destination,
          options: const PdfExportOptions(),
          overwrite: false,
        ),
      ),
      throwsA(
        isA<MarkdownPdfExportException>().having(
          (error) => error.code,
          'code',
          MarkdownPdfFailureCode.invalidOutput,
        ),
      ),
    );
    expect(await File(destination).exists(), isFalse);
  });

  test('compiler locator prefers the explicit development override', () {
    const locator = TypstCompilerLocator(
      environment: {'BUSYMARK_TYPST_PATH': '/bin/true'},
      resolvedExecutable: '/application/busymark',
    );
    expect(locator.locate(), '/bin/true');
  });

  test('compiler cancellation force-stops an unresponsive process', () async {
    if (!Platform.isLinux) {
      return;
    }
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'busymark-cancel-compiler-test-',
    );
    addTearDown(() => temporaryDirectory.delete(recursive: true));
    final executable = File(p.join(temporaryDirectory.path, 'fake-typst'));
    await executable.writeAsString('''#!/bin/sh
trap '' TERM
while :; do :; done
''');
    final chmod = await Process.run('chmod', ['700', executable.path]);
    expect(chmod.exitCode, 0);
    final cancellationToken = MarkdownPdfCancellationToken();
    final stopwatch = Stopwatch()..start();
    final operation = const DartTypstCommandRunner().compile(
      executable: executable.path,
      workingDirectory: temporaryDirectory,
      timeout: const Duration(seconds: 10),
      cancellationToken: cancellationToken,
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));
    cancellationToken.cancel();

    await expectLater(
      operation,
      throwsA(
        isA<MarkdownPdfExportException>().having(
          (error) => error.code,
          'code',
          MarkdownPdfFailureCode.cancelled,
        ),
      ),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test(
    'asset staging accepts passive SVG and rejects external content',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'busymark-unsafe-svg-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final markdownPath = p.join(temporaryDirectory.path, 'document.md');
      final safeSvgPath = p.join(temporaryDirectory.path, 'safe.svg');
      final svgPath = p.join(temporaryDirectory.path, 'unsafe.svg');
      await File(safeSvgPath).writeAsString('''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <circle cx="5" cy="5" r="4" fill="#2563a5" />
</svg>
''');
      await File(svgPath).writeAsString('''
<svg xmlns="http://www.w3.org/2000/svg">
  <image href="https://example.com/tracking.png" />
</svg>
''');
      const parser = MarkdownParser();
      final parsed = parser.parse(
        filePath: markdownPath,
        source: '![Safe](safe.svg)\n\n![Unsafe](unsafe.svg)',
        validateLocalReferences: false,
      );
      final document = const MarkdownExportMapper().map(parsed.busyDocument);
      final exportRoot = await Directory(
        p.join(temporaryDirectory.path, 'export'),
      ).create();

      final result = await const MarkdownExportAssetStager().stage(
        document: document,
        exportRoot: exportRoot,
        activeFilePath: markdownPath,
        workspaceRoot: temporaryDirectory.path,
        cancellationToken: MarkdownPdfCancellationToken(),
      );

      expect(result.assets.keys, contains('safe.svg'));
      expect(result.assets.keys, isNot(contains('unsafe.svg')));
      expect(result.warnings, hasLength(1));
      expect(
        result.warnings.single.code,
        MarkdownPdfWarningCode.imageUnsupported,
      );
    },
  );

  test('Linux packaging pins and installs the bundled Typst compiler', () {
    final fetchScript = File('tools/fetch_typst.sh').readAsStringSync();
    final cmake = File('linux/CMakeLists.txt').readAsStringSync();
    final snapcraft = File('snap/snapcraft.yaml').readAsStringSync();

    expect(fetchScript, contains('TYPST_VERSION="0.15.1"'));
    expect(
      fetchScript,
      contains(
        'TYPST_SHA256="a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c"',
      ),
    );
    expect(
      fetchScript,
      contains(
        'TYPST_SHA256="5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee"',
      ),
    );
    expect(
      fetchScript,
      contains(
        'TYPST_BINARY_SHA256="29273eaa04f6d00edd0c2bec578f565fc9c65be856bfbffc894567c68ed0b237"',
      ),
    );
    expect(fetchScript, contains('sha256sum --check --status'));
    expect(cmake, contains('libexec/busymark'));
    expect(cmake, contains('share/licenses/typst'));
    expect(snapcraft, contains('TYPST_FONT_PATHS:'));
    expect(snapcraft, contains('fonts-noto-core'));
  });
}

class _FixedCompilerLocator extends TypstCompilerLocator {
  const _FixedCompilerLocator(this.path);

  final String path;

  @override
  String locate() => path;
}

class _InvalidOutputRunner implements TypstCommandRunner {
  const _InvalidOutputRunner();

  @override
  Future<TypstProcessResult> compile({
    required String executable,
    required Directory workingDirectory,
    required Duration timeout,
    required MarkdownPdfCancellationToken cancellationToken,
  }) async {
    await File(
      p.join(workingDirectory.path, 'output.pdf'),
    ).writeAsString('not a pdf', flush: true);
    return const TypstProcessResult(exitCode: 0, stdout: '', stderr: '');
  }
}
