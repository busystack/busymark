import 'dart:io';

import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/export/writerside_pdf_configuration.dart';
import 'package:busymark/src/export/writerside_pdf_export_service.dart';
import 'package:busymark/src/export/writerside_pdf_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  test('generated configuration contains every documented PDF option', () {
    const codec = WritersidePdfConfigurationCodec();
    final document = XmlDocument.parse(
      codec.encode(
        const WritersidePdfOptions(
          orientation: MarkdownPdfOrientation.landscape,
          layout: 'GNOME',
          cover: WritersidePdfCoverOptions(
            enabled: true,
            title: 'Busy & Mark',
            logoPath: '/host/logo.svg',
            description: 'User <Guide>',
            copyright: 'BusyStack © 2026',
          ),
          header: 'BusyMark guide',
          footer: 'Confidential',
          tocTitle: 'Contents',
        ),
        containerLogoPath: '/opt/sources/Writerside/images/logo.svg',
      ),
    );

    final root = document.rootElement;
    expect(root.name.local, 'pdf');
    expect(root.getAttribute('landscape'), 'true');
    expect(
      root.getElement('cover-page')?.getElement('title')?.innerText,
      'Busy & Mark',
    );
    expect(
      root.getElement('cover-page')?.getElement('logo')?.innerText,
      '/opt/sources/Writerside/images/logo.svg',
    );
    expect(
      root.getElement('cover-page')?.getElement('description')?.innerText,
      'User <Guide>',
    );
    expect(root.getElement('header')?.innerText, 'BusyMark guide');
    expect(root.getElement('footer')?.innerText, 'Confidential');
    expect(root.getElement('toc-title')?.innerText, 'Contents');
    expect(root.getElement('layout')?.innerText, 'GNOME');
  });

  test('discovers PDF configurations and instance keymap layouts', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-pdf-config-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final cfg = await Directory(p.join(root.path, 'cfg')).create();
    await File(p.join(cfg.path, 'PDF.xml')).writeAsString('<pdf/>');
    await File(
      p.join(cfg.path, 'not-pdf.xml'),
    ).writeAsString('<buildprofiles/>');
    await File(p.join(cfg.path, 'broken.xml')).writeAsString('<pdf>');
    await File(p.join(cfg.path, 'buildprofiles.xml')).writeAsString('''
<buildprofiles>
  <shortcuts>
    <layout name="Windows" display-name="Windows and Linux"/>
    <layout name="macOS" display-name="macOS" instance="other"/>
  </shortcuts>
  <shortcuts instance="guide,reference">
    <layout name="GNOME" display-name="Linux"/>
  </shortcuts>
</buildprofiles>
''');
    const codec = WritersidePdfConfigurationCodec();

    final configurations = await codec.discover(
      moduleRoot: root.path,
      buildConfigDirectory: 'cfg',
    );
    final layouts = await codec.discoverLayouts(
      moduleRoot: root.path,
      buildConfigDirectory: 'cfg',
      instanceId: 'guide',
    );

    expect(configurations, [p.join(cfg.path, 'PDF.xml')]);
    expect(layouts.map((item) => item.name), ['Windows', 'GNOME']);
    expect(layouts.map((item) => item.displayName), [
      'Windows and Linux',
      'Linux',
    ]);
  });

  test(
    'generated export keeps project entries read-only and sources unchanged',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      final fixture = await _WritersideFixture.create(withConfig: false);
      addTearDown(fixture.dispose);
      final runner = _FakeBuilderRunner();
      final service = WritersidePdfExportService(
        dockerLocator: const _FixedDockerLocator(),
        commandRunner: runner,
      );
      final destination = p.join(fixture.root.path, 'guide.pdf');

      final result = await service.export(
        fixture.request(
          destinationPath: destination,
          options: const WritersidePdfOptions(
            cover: WritersidePdfCoverOptions(enabled: true, title: 'Guide'),
          ),
        ),
      );

      final arguments = runner.buildArguments!;
      expect(result.destinationPath, destination);
      expect(result.pageCount, 1);
      expect(await File(destination).exists(), isTrue);
      expect(
        await Directory(p.join(fixture.module.path, 'cfg')).exists(),
        isFalse,
      );
      expect(
        await Directory(p.join(fixture.root.path, '.idea')).exists(),
        isFalse,
      );
      expect(arguments, containsAllInOrder(['--network', 'none']));
      expect(arguments, contains('SOURCE_DIR=/opt/sources'));
      expect(arguments, contains('MODULE_INSTANCE=Writerside/guide'));
      expect(arguments, contains('PDF=BusyMark-PDF.xml'));
      expect(
        arguments,
        contains(
          '$writersideBuilderRepository:$writersideBuilderDefaultVersion',
        ),
      );
      expect(runner.generatedConfiguration, contains('<title>Guide</title>'));
      expect(
        runner.mountTargets,
        contains('/opt/sources/Writerside/writerside.cfg'),
      );
      expect(
        runner.readOnlyMountTargets,
        containsAll([
          '/opt/sources/Writerside/writerside.cfg',
          '/opt/sources/Writerside/guide.tree',
          '/opt/sources/Writerside/topics',
        ]),
      );
      expect(runner.readOnlyMountTargets, isNot(contains('/opt/sources')));
      expect(runner.calls.where((call) => call.first == 'pull'), isEmpty);
    },
  );

  test(
    'existing project PDF configuration is passed through unchanged',
    () async {
      if (!Platform.isLinux) {
        return;
      }
      final fixture = await _WritersideFixture.create(withConfig: true);
      addTearDown(fixture.dispose);
      final runner = _FakeBuilderRunner();
      final service = WritersidePdfExportService(
        dockerLocator: const _FixedDockerLocator(),
        commandRunner: runner,
      );
      final destination = p.join(fixture.root.path, 'configured.pdf');

      await service.export(
        fixture.request(
          destinationPath: destination,
          configurationMode: WritersidePdfConfigurationMode.projectFile,
          projectConfigurationPath: fixture.configurationFile.path,
        ),
      );

      expect(runner.buildArguments, contains('PDF=Release-PDF.xml'));
      expect(
        runner.mountTargets,
        containsAll(['/opt/sources', '/opt/sources/Writerside', '/opt/output']),
      );
      expect(runner.mountTargets, hasLength(3));
      expect(runner.readOnlyMountTargets, ['/opt/sources/Writerside']);
      expect(
        await Directory(p.join(fixture.root.path, '.idea')).exists(),
        isFalse,
      );
      expect(
        await fixture.configurationFile.readAsString(),
        '<pdf><toc-title>Release contents</toc-title></pdf>',
      );
    },
  );

  test(
    'missing builder image is reported without starting a container',
    () async {
      final fixture = await _WritersideFixture.create(withConfig: false);
      addTearDown(fixture.dispose);
      final runner = _FakeBuilderRunner(imageAvailable: false);
      final service = WritersidePdfExportService(
        dockerLocator: const _FixedDockerLocator(),
        commandRunner: runner,
      );

      await expectLater(
        service.export(
          fixture.request(
            destinationPath: p.join(fixture.root.path, 'missing.pdf'),
          ),
        ),
        throwsA(
          isA<WritersidePdfExportException>().having(
            (error) => error.code,
            'code',
            WritersidePdfFailureCode.builderImageUnavailable,
          ),
        ),
      );
      expect(runner.buildArguments, isNull);
    },
  );

  test(
    'pre-cancelled export reports the Writerside cancellation type',
    () async {
      final fixture = await _WritersideFixture.create(withConfig: false);
      addTearDown(fixture.dispose);
      final token = WritersidePdfCancellationToken()..cancel();
      final service = WritersidePdfExportService(
        dockerLocator: const _FixedDockerLocator(),
        commandRunner: _FakeBuilderRunner(),
      );

      await expectLater(
        service.export(
          fixture.request(
            destinationPath: p.join(fixture.root.path, 'cancelled.pdf'),
          ),
          cancellationToken: token,
        ),
        throwsA(
          isA<WritersidePdfExportException>().having(
            (error) => error.code,
            'code',
            WritersidePdfFailureCode.cancelled,
          ),
        ),
      );
    },
  );

  test(
    'generated overlay rejects symlinks outside the selected source root',
    () async {
      final fixture = await _WritersideFixture.create(withConfig: false);
      final outside = await Directory.systemTemp.createTemp(
        'busymark-writerside-pdf-outside-test-',
      );
      addTearDown(fixture.dispose);
      addTearDown(() => outside.delete(recursive: true));
      await File(p.join(outside.path, 'private.txt')).writeAsString('private');
      await Link(p.join(fixture.module.path, 'outside')).create(outside.path);
      final runner = _FakeBuilderRunner();
      final service = WritersidePdfExportService(
        dockerLocator: const _FixedDockerLocator(),
        commandRunner: runner,
      );

      await expectLater(
        service.export(
          fixture.request(
            destinationPath: p.join(fixture.root.path, 'unsafe.pdf'),
          ),
        ),
        throwsA(
          isA<WritersidePdfExportException>()
              .having(
                (error) => error.code,
                'code',
                WritersidePdfFailureCode.invalidRequest,
              )
              .having((error) => error.detail, 'detail', contains('symlink')),
        ),
      );
      expect(runner.buildArguments, isNull);
    },
  );

  test('builder runner force-stops a process after its timeout', () async {
    if (!Platform.isLinux) {
      return;
    }
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-pdf-timeout-test-',
    );
    addTearDown(() => root.delete(recursive: true));
    final executable = File(p.join(root.path, 'slow-builder'));
    await executable.writeAsString('''#!/bin/sh
trap '' TERM
while :; do :; done
''');
    final chmod = await Process.run('chmod', ['700', executable.path]);
    expect(chmod.exitCode, 0);
    final stopwatch = Stopwatch()..start();

    await expectLater(
      const DartWritersideBuilderCommandRunner().run(
        executable: executable.path,
        arguments: const [],
        timeout: const Duration(milliseconds: 100),
        cancellationToken: WritersidePdfCancellationToken(),
      ),
      throwsA(
        isA<WritersidePdfExportException>().having(
          (error) => error.code,
          'code',
          WritersidePdfFailureCode.timedOut,
        ),
      ),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test(
    'official builder exports the Writerside demo through Docker',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'busymark-writerside-pdf-integration-test-',
      );
      addTearDown(() => output.delete(recursive: true));
      final module = Directory('demo/writerside-instances').absolute;
      final destination = p.join(output.path, 'writerside-demo.pdf');
      const service = WritersidePdfExportService();

      expect(
        await service.isBuilderAvailable(writersideBuilderDefaultVersion),
        isTrue,
        reason:
            'Install $writersideBuilderRepository:'
            '$writersideBuilderDefaultVersion before running this test.',
      );
      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: module.path,
          sourceRoot: module.parent.path,
          moduleName: 'BusyMark Instance Demo',
          buildConfigDirectory: 'cfg',
          instanceId: 'guide',
          destinationPath: destination,
          overwrite: false,
          builderVersion: writersideBuilderDefaultVersion,
          configurationMode: WritersidePdfConfigurationMode.projectFile,
          projectConfigurationPath: p.join(module.path, 'cfg', 'PDF.xml'),
        ),
      );

      expect(await File(destination).length(), greaterThan(1024));
      expect(result.pageCount, isNotNull);
    },
    skip: Platform.environment['BUSYMARK_WRITERSIDE_PDF_INTEGRATION'] == '1'
        ? false
        : 'Set BUSYMARK_WRITERSIDE_PDF_INTEGRATION=1 after installing the '
              'official builder image.',
    timeout: const Timeout(Duration(minutes: 16)),
  );

  test(
    'official builder accepts generated BusyMark PDF settings',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'busymark-writerside-pdf-generated-integration-test-',
      );
      addTearDown(() => output.delete(recursive: true));
      final module = Directory('demo/writerside-instances').absolute;
      final destination = p.join(output.path, 'writerside-customized.pdf');
      const service = WritersidePdfExportService();

      expect(
        await service.isBuilderAvailable(writersideBuilderDefaultVersion),
        isTrue,
        reason:
            'Install $writersideBuilderRepository:'
            '$writersideBuilderDefaultVersion before running this test.',
      );
      final result = await service.export(
        WritersidePdfExportRequest(
          moduleRoot: module.path,
          sourceRoot: module.parent.path,
          moduleName: 'BusyMark Instance Demo',
          buildConfigDirectory: 'cfg',
          instanceId: 'guide',
          destinationPath: destination,
          overwrite: false,
          builderVersion: writersideBuilderDefaultVersion,
          configurationMode: WritersidePdfConfigurationMode.generated,
          options: WritersidePdfOptions(
            orientation: MarkdownPdfOrientation.landscape,
            cover: WritersidePdfCoverOptions(
              enabled: true,
              title: 'Customized BusyMark Guide',
              logoPath: p.join(module.path, 'images', 'busymark-mark.svg'),
              description: 'Generated configuration integration test',
              copyright: 'BusyStack © 2026',
            ),
            header: 'BusyMark Writerside export',
            footer: 'Generated by the official Writerside builder',
            tocTitle: 'Customized contents',
          ),
        ),
      );

      expect(await File(destination).length(), greaterThan(1024));
      expect(result.pageCount, isNotNull);
    },
    skip: Platform.environment['BUSYMARK_WRITERSIDE_PDF_INTEGRATION'] == '1'
        ? false
        : 'Set BUSYMARK_WRITERSIDE_PDF_INTEGRATION=1 after installing the '
              'official builder image.',
    timeout: const Timeout(Duration(minutes: 16)),
  );
}

class _WritersideFixture {
  _WritersideFixture({
    required this.root,
    required this.module,
    required this.configurationFile,
  });

  final Directory root;
  final Directory module;
  final File configurationFile;

  static Future<_WritersideFixture> create({required bool withConfig}) async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-writerside-pdf-service-test-',
    );
    final module = await Directory(p.join(root.path, 'Writerside')).create();
    await File(
      p.join(module.path, 'writerside.cfg'),
    ).writeAsString('<ihp><instance src="guide.tree"/></ihp>');
    await File(
      p.join(module.path, 'guide.tree'),
    ).writeAsString('<instance-profile id="guide" name="Guide"/>');
    final topics = await Directory(p.join(module.path, 'topics')).create();
    await File(p.join(topics.path, 'intro.md')).writeAsString('# Introduction');
    final configurationFile = File(
      p.join(module.path, 'cfg', 'Release-PDF.xml'),
    );
    if (withConfig) {
      await configurationFile.parent.create();
      await configurationFile.writeAsString(
        '<pdf><toc-title>Release contents</toc-title></pdf>',
      );
    }
    return _WritersideFixture(
      root: root,
      module: module,
      configurationFile: configurationFile,
    );
  }

  WritersidePdfExportRequest request({
    required String destinationPath,
    WritersidePdfConfigurationMode configurationMode =
        WritersidePdfConfigurationMode.generated,
    String? projectConfigurationPath,
    WritersidePdfOptions options = const WritersidePdfOptions(),
  }) {
    return WritersidePdfExportRequest(
      moduleRoot: module.path,
      sourceRoot: root.path,
      moduleName: 'Writerside',
      buildConfigDirectory: 'cfg',
      instanceId: 'guide',
      destinationPath: destinationPath,
      overwrite: false,
      builderVersion: writersideBuilderDefaultVersion,
      configurationMode: configurationMode,
      projectConfigurationPath: projectConfigurationPath,
      options: options,
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
}

class _FixedDockerLocator extends DockerExecutableLocator {
  const _FixedDockerLocator();

  @override
  String locate() => '/bin/true';
}

class _FakeBuilderRunner implements WritersideBuilderCommandRunner {
  _FakeBuilderRunner({this.imageAvailable = true});

  final bool imageAvailable;
  final List<List<String>> calls = [];
  List<String>? buildArguments;
  String? generatedConfiguration;
  final List<String> mountTargets = [];
  final List<String> readOnlyMountTargets = [];

  @override
  Future<WritersideBuilderProcessResult> run({
    required String executable,
    required List<String> arguments,
    required Duration timeout,
    required WritersidePdfCancellationToken cancellationToken,
    String? containerName,
  }) async {
    cancellationToken.throwIfCancelled();
    calls.add(List.unmodifiable(arguments));
    if (arguments.first == 'version') {
      return const WritersideBuilderProcessResult(
        exitCode: 0,
        stdout: '28.5.1',
        stderr: '',
      );
    }
    if (arguments.first == 'image') {
      return WritersideBuilderProcessResult(
        exitCode: imageAvailable ? 0 : 1,
        stdout: imageAvailable ? 'sha256:test' : '',
        stderr: imageAvailable ? '' : 'No such image',
      );
    }
    if (arguments.first != 'run') {
      return const WritersideBuilderProcessResult(
        exitCode: 0,
        stdout: '',
        stderr: '',
      );
    }
    buildArguments = List.unmodifiable(arguments);
    String? outputPath;
    String? sourceOverlayPath;
    for (var index = 0; index < arguments.length - 1; index++) {
      if (arguments[index] != '--mount') {
        continue;
      }
      final mount = _mountValues(arguments[index + 1]);
      final target = mount['target']!;
      mountTargets.add(target);
      if (mount.containsKey('readonly')) {
        readOnlyMountTargets.add(target);
      }
      if (target == '/opt/output') {
        outputPath = mount['source'];
      }
      if (target == '/opt/sources' && !mount.containsKey('readonly')) {
        sourceOverlayPath = mount['source'];
      }
    }
    if (sourceOverlayPath != null) {
      await File(
        p.join(sourceOverlayPath, '.idea', 'workspace.xml'),
      ).writeAsString('<project/>');
    }
    if (sourceOverlayPath != null &&
        arguments.contains('PDF=BusyMark-PDF.xml')) {
      generatedConfiguration = await File(
        p.join(sourceOverlayPath, 'Writerside', 'cfg', 'BusyMark-PDF.xml'),
      ).readAsString();
    }
    await File(
      p.join(outputPath!, 'pdfSourceGUIDE.pdf'),
    ).writeAsBytes(_validPdf, flush: true);
    return const WritersideBuilderProcessResult(
      exitCode: 0,
      stdout: 'PDF generated',
      stderr: '',
    );
  }

  Map<String, String> _mountValues(String specification) {
    return {
      for (final part in specification.split(','))
        if (part.contains('='))
          part.substring(0, part.indexOf('=')): part.substring(
            part.indexOf('=') + 1,
          )
        else
          part: '',
    };
  }
}

final _validPdf =
    '''%PDF-1.7
1 0 obj
<< /Type /Page >>
endobj
%%EOF
'''
        .codeUnits;
