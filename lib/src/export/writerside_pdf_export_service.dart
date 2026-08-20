import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/atomic_file_writer.dart';
import 'writerside_pdf_configuration.dart';
import 'writerside_pdf_models.dart';

class DockerExecutableLocator {
  const DockerExecutableLocator({this.environment});

  final Map<String, String>? environment;

  String? locate() {
    final values = environment ?? Platform.environment;
    final override = values['BUSYMARK_DOCKER_PATH']?.trim();
    if (override != null && override.isNotEmpty) {
      return _executable(override);
    }
    for (final directory in (values['PATH'] ?? '').split(':')) {
      if (directory.isEmpty) {
        continue;
      }
      final candidate = _executable(p.join(directory, 'docker'));
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  String? _executable(String path) {
    try {
      final file = File(p.normalize(p.absolute(path)));
      final stat = file.statSync();
      return stat.type == FileSystemEntityType.file && stat.mode & 0x49 != 0
          ? file.path
          : null;
    } on FileSystemException {
      return null;
    }
  }
}

class WritersideBuilderProcessResult {
  const WritersideBuilderProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract class WritersideBuilderCommandRunner {
  Future<WritersideBuilderProcessResult> run({
    required String executable,
    required List<String> arguments,
    required Duration timeout,
    required WritersidePdfCancellationToken cancellationToken,
    String? containerName,
  });
}

class DartWritersideBuilderCommandRunner
    implements WritersideBuilderCommandRunner {
  const DartWritersideBuilderCommandRunner({
    this.maximumDiagnosticBytes = 1024 * 1024,
  });

  final int maximumDiagnosticBytes;

  @override
  Future<WritersideBuilderProcessResult> run({
    required String executable,
    required List<String> arguments,
    required Duration timeout,
    required WritersidePdfCancellationToken cancellationToken,
    String? containerName,
  }) async {
    cancellationToken.throwIfCancelled();
    final Process process;
    try {
      process = await Process.start(
        executable,
        arguments,
        includeParentEnvironment: true,
        runInShell: false,
      );
    } on Object catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.dockerUnavailable,
        detail: error.toString(),
        cause: error,
      );
    }

    var cancelled = false;
    var exited = false;
    final exitCode = process.exitCode.then((value) {
      exited = true;
      return value;
    });
    cancellationToken.attach(() {
      cancelled = true;
      process.kill(ProcessSignal.sigterm);
      if (containerName != null) {
        unawaited(_removeContainer(executable, containerName));
      }
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (!exited) {
            process.kill(ProcessSignal.sigkill);
          }
        }),
      );
    });
    final stdout = _collectBounded(process.stdout);
    final stderr = _collectBounded(process.stderr);
    try {
      final code = await exitCode.timeout(timeout);
      if (cancelled || cancellationToken.isCancelled) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.cancelled,
        );
      }
      return WritersideBuilderProcessResult(
        exitCode: code,
        stdout: await stdout,
        stderr: await stderr,
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      if (containerName != null) {
        unawaited(_removeContainer(executable, containerName));
      }
      await Future.any<void>([
        exitCode.then((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 500)),
      ]);
      if (!exited) {
        process.kill(ProcessSignal.sigkill);
      }
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.timedOut,
      );
    } finally {
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

  Future<void> _removeContainer(String executable, String name) async {
    try {
      await Process.run(executable, [
        'rm',
        '--force',
        name,
      ], runInShell: false).timeout(const Duration(seconds: 10));
    } on Object {
      // Best-effort cleanup; cancellation/timeout remains the primary result.
    }
  }
}

class WritersidePdfExportService {
  const WritersidePdfExportService({
    this.dockerLocator = const DockerExecutableLocator(),
    this.commandRunner = const DartWritersideBuilderCommandRunner(),
    this.configurationCodec = const WritersidePdfConfigurationCodec(),
    this.fileWriter = const AtomicFileWriter(),
    this.buildTimeout = const Duration(minutes: 15),
    this.pullTimeout = const Duration(hours: 1),
    this.maximumPdfBytes = 250 * 1024 * 1024,
    this.maximumSourceCopyBytes = 2 * 1024 * 1024 * 1024,
    this.maximumSourceCopyEntries = 100000,
  });

  final DockerExecutableLocator dockerLocator;
  final WritersideBuilderCommandRunner commandRunner;
  final WritersidePdfConfigurationCodec configurationCodec;
  final AtomicFileWriter fileWriter;
  final Duration buildTimeout;
  final Duration pullTimeout;
  final int maximumPdfBytes;
  final int maximumSourceCopyBytes;
  final int maximumSourceCopyEntries;

  Future<List<String>> discoverProjectConfigurations({
    required String moduleRoot,
    required String buildConfigDirectory,
  }) {
    return configurationCodec.discover(
      moduleRoot: moduleRoot,
      buildConfigDirectory: buildConfigDirectory,
    );
  }

  Future<List<WritersidePdfKeymapLayout>> discoverLayouts({
    required String moduleRoot,
    required String buildConfigDirectory,
    required String instanceId,
  }) {
    return configurationCodec.discoverLayouts(
      moduleRoot: moduleRoot,
      buildConfigDirectory: buildConfigDirectory,
      instanceId: instanceId,
    );
  }

  Future<bool> isBuilderAvailable(
    String version, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    _validateBuilderVersion(version);
    final token = cancellationToken ?? WritersidePdfCancellationToken();
    final executable = dockerLocator.locate();
    if (executable == null) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.dockerUnavailable,
      );
    }
    await _verifyDocker(executable, token);
    return _imageExists(executable, version, token);
  }

  Future<void> downloadBuilder(
    String version, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    _validateBuilderVersion(version);
    final token = cancellationToken ?? WritersidePdfCancellationToken();
    final executable = _dockerExecutable();
    await _verifyDocker(executable, token);
    final image = '$writersideBuilderRepository:$version';
    final result = await commandRunner.run(
      executable: executable,
      arguments: ['pull', image],
      timeout: pullTimeout,
      cancellationToken: token,
    );
    if (result.exitCode != 0) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.builderImageUnavailable,
        detail: _safeDetail('${result.stderr}\n${result.stdout}'),
      );
    }
  }

  Future<WritersidePdfExportResult> export(
    WritersidePdfExportRequest request, {
    WritersidePdfCancellationToken? cancellationToken,
  }) async {
    final token = cancellationToken ?? WritersidePdfCancellationToken();
    token.throwIfCancelled();
    final validated = await _validateRequest(request);
    final executable = _dockerExecutable();
    await _verifyDocker(executable, token);
    if (!await _imageExists(executable, request.builderVersion, token)) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.builderImageUnavailable,
        detail: request.builderImage,
      );
    }

    final exportRoot = await Directory.systemTemp.createTemp(
      'busymark-writerside-pdf-',
    );
    final outputDirectory = await Directory(
      p.join(exportRoot.path, 'output'),
    ).create();
    try {
      final configurationArgument = switch (request.configurationMode) {
        WritersidePdfConfigurationMode.projectFile =>
          validated.projectConfigurationRelativePath!,
        WritersidePdfConfigurationMode.generated => 'BusyMark-PDF.xml',
      };
      final sourceOverlay = switch (request.configurationMode) {
        WritersidePdfConfigurationMode.projectFile =>
          await _createProjectSourceOverlay(
            exportRoot: exportRoot,
            validated: validated,
            cancellationToken: token,
          ),
        WritersidePdfConfigurationMode.generated =>
          await _createGeneratedSourceOverlay(
            exportRoot: exportRoot,
            validated: validated,
            configurationXml: configurationCodec.encode(
              request.options,
              containerLogoPath: validated.containerLogoPath,
            ),
            cancellationToken: token,
          ),
      };

      final containerName =
          'busymark-writerside-$pid-${DateTime.now().microsecondsSinceEpoch}';
      final arguments = <String>[
        'run',
        '--rm',
        '--pull=never',
        '--name',
        containerName,
        '--shm-size',
        '1g',
        if (!request.allowNetwork) ...['--network', 'none'],
        '--mount',
        _mount(sourceOverlay.directory.path, '/opt/sources'),
        '--mount',
        _mount(outputDirectory.path, '/opt/output'),
        '-e',
        'SOURCE_DIR=/opt/sources',
        '-e',
        'MODULE_INSTANCE=${request.moduleName}/${request.instanceId}',
        '-e',
        'OUTPUT_DIR=/opt/output',
        '-e',
        'RUNNER=other',
        '-e',
        'PDF=${_posix(configurationArgument)}',
        request.builderImage,
      ];
      var build = await commandRunner.run(
        executable: executable,
        arguments: arguments,
        timeout: buildTimeout,
        cancellationToken: token,
        containerName: containerName,
      );
      if (build.exitCode != 0) {
        throw WritersidePdfExportException(
          WritersidePdfFailureCode.buildFailed,
          detail: _safeDetail('${build.stderr}\n${build.stdout}'),
        );
      }
      token.throwIfCancelled();
      File artifact;
      try {
        artifact = await _findPdfArtifact(
          outputDirectory,
          request.instanceId,
          build,
        );
      } on WritersidePdfExportException {
        if (!_isRecoverablePdfProcessCrash(build)) {
          rethrow;
        }
        final retry = await commandRunner.run(
          executable: executable,
          arguments: arguments,
          timeout: buildTimeout,
          cancellationToken: token,
          containerName: containerName,
        );
        if (retry.exitCode != 0) {
          throw WritersidePdfExportException(
            WritersidePdfFailureCode.buildFailed,
            detail: _safeDetail('${retry.stderr}\n${retry.stdout}'),
          );
        }
        build = WritersideBuilderProcessResult(
          exitCode: retry.exitCode,
          stdout: '${build.stdout}\nPDF generation retried.\n${retry.stdout}',
          stderr: '${build.stderr}\n${retry.stderr}',
        );
        artifact = await _findPdfArtifact(
          outputDirectory,
          request.instanceId,
          build,
        );
      }
      final artifactLength = await artifact.length();
      if (artifactLength <= 8 || artifactLength > maximumPdfBytes) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidOutput,
        );
      }
      final bytes = await artifact.readAsBytes();
      if (bytes.length != artifactLength || !_isPdf(bytes)) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidOutput,
        );
      }
      try {
        await fileWriter.writeBytes(
          request.destinationPath,
          bytes,
          overwrite: request.overwrite,
        );
      } on AtomicFileAlreadyExistsException catch (error) {
        throw WritersidePdfExportException(
          WritersidePdfFailureCode.destinationExists,
          detail: error.path,
          cause: error,
        );
      }
      return WritersidePdfExportResult(
        destinationPath: p.normalize(p.absolute(request.destinationPath)),
        pageCount: _pageCount(bytes),
        builderVersion: request.builderVersion,
        buildLog: _safeDetail('${build.stdout}\n${build.stderr}'),
      );
    } on WritersidePdfExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.fileSystem,
        detail: error.message,
        cause: error,
      );
    } finally {
      await _deleteBestEffort(exportRoot);
    }
  }

  String _dockerExecutable() {
    final executable = dockerLocator.locate();
    if (executable == null) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.dockerUnavailable,
      );
    }
    return executable;
  }

  Future<void> _verifyDocker(
    String executable,
    WritersidePdfCancellationToken token,
  ) async {
    final result = await commandRunner.run(
      executable: executable,
      arguments: const ['version', '--format', '{{.Server.Version}}'],
      timeout: const Duration(seconds: 30),
      cancellationToken: token,
    );
    if (result.exitCode != 0) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.dockerUnavailable,
        detail: _safeDetail('${result.stderr}\n${result.stdout}'),
      );
    }
  }

  Future<bool> _imageExists(
    String executable,
    String version,
    WritersidePdfCancellationToken token,
  ) async {
    final image = '$writersideBuilderRepository:$version';
    final result = await commandRunner.run(
      executable: executable,
      arguments: ['image', 'inspect', '--format', '{{.Id}}', image],
      timeout: const Duration(seconds: 30),
      cancellationToken: token,
    );
    return result.exitCode == 0;
  }

  Future<_ValidatedWritersidePdfRequest> _validateRequest(
    WritersidePdfExportRequest request,
  ) async {
    _validateBuilderVersion(request.builderVersion);
    _validateIdentifier(request.moduleName, 'module');
    _validateIdentifier(request.instanceId, 'instance');
    final buildConfigDirectory = _normalizeRelativeDirectory(
      request.buildConfigDirectory,
    );
    final sourceRoot = await _canonicalDirectory(request.sourceRoot);
    final moduleRoot = await _canonicalDirectory(request.moduleRoot);
    if (!p.equals(sourceRoot, moduleRoot) &&
        !p.isWithin(sourceRoot, moduleRoot)) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The help module is outside the selected source root.',
      );
    }
    _validateMountPath(sourceRoot);
    final moduleRelative = p.relative(moduleRoot, from: sourceRoot);
    final buildConfigPath = p.normalize(
      p.join(moduleRoot, buildConfigDirectory),
    );
    if (!p.isWithin(moduleRoot, buildConfigPath)) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The build configuration directory leaves the help module.',
      );
    }
    String? canonicalBuildConfig;
    final buildConfigType = await FileSystemEntity.type(
      buildConfigPath,
      followLinks: false,
    );
    if (buildConfigType == FileSystemEntityType.directory ||
        buildConfigType == FileSystemEntityType.link) {
      canonicalBuildConfig = await _canonicalDirectory(buildConfigPath);
      if (!p.equals(moduleRoot, canonicalBuildConfig) &&
          !p.isWithin(moduleRoot, canonicalBuildConfig)) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidRequest,
          detail: 'The build configuration directory leaves the help module.',
        );
      }
    } else if (buildConfigType != FileSystemEntityType.notFound) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The build configuration path is not a directory.',
      );
    }

    String? projectConfigurationRelativePath;
    if (request.configurationMode ==
        WritersidePdfConfigurationMode.projectFile) {
      final path = request.projectConfigurationPath;
      if (path == null || path.trim().isEmpty) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidConfiguration,
          detail: 'No Writerside PDF configuration was selected.',
        );
      }
      if (canonicalBuildConfig == null) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidConfiguration,
          detail: 'The build configuration directory does not exist.',
        );
      }
      final canonical = await _canonicalFile(path);
      if (!p.equals(canonicalBuildConfig, p.dirname(canonical)) &&
          !p.isWithin(canonicalBuildConfig, canonical)) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidConfiguration,
          detail: 'The PDF configuration must be inside the build directory.',
        );
      }
      final configurationFile = File(canonical);
      if (await configurationFile.length() > 1024 * 1024 ||
          !configurationCodec.isPdfConfiguration(
            await configurationFile.readAsString(),
          )) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidConfiguration,
          detail: 'The selected XML root must be <pdf>.',
        );
      }
      projectConfigurationRelativePath = p.relative(
        canonical,
        from: canonicalBuildConfig,
      );
    }

    String? containerLogoPath;
    final logo = request.options.cover.logoPath.trim();
    if (request.configurationMode == WritersidePdfConfigurationMode.generated &&
        request.options.cover.enabled &&
        logo.isNotEmpty) {
      final canonicalLogo = await _canonicalFile(logo);
      if (!p.equals(sourceRoot, canonicalLogo) &&
          !p.isWithin(sourceRoot, canonicalLogo)) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidConfiguration,
          detail: 'The cover logo must be inside the selected source root.',
        );
      }
      containerLogoPath = _containerPath([
        '/opt/sources',
        p.relative(canonicalLogo, from: sourceRoot),
      ]);
    }
    return _ValidatedWritersidePdfRequest(
      sourceRoot: sourceRoot,
      moduleRelativePath: moduleRelative,
      buildConfigDirectory: buildConfigDirectory,
      projectConfigurationRelativePath: projectConfigurationRelativePath,
      containerLogoPath: containerLogoPath,
    );
  }

  Future<_SourceOverlay> _createGeneratedSourceOverlay({
    required Directory exportRoot,
    required _ValidatedWritersidePdfRequest validated,
    required String configurationXml,
    required WritersidePdfCancellationToken cancellationToken,
  }) async {
    final directory = await Directory(
      p.join(exportRoot.path, 'source-overlay'),
    ).create();
    await _copySourceTree(
      sourceRoot: validated.sourceRoot,
      destination: directory,
      cancellationToken: cancellationToken,
    );
    final configurationDirectory = Directory(
      p.joinAll([
        directory.path,
        if (validated.moduleRelativePath != '.') validated.moduleRelativePath,
        validated.buildConfigDirectory,
      ]),
    );
    await configurationDirectory.create(recursive: true);
    await File(
      p.join(configurationDirectory.path, 'BusyMark-PDF.xml'),
    ).writeAsString(configurationXml, flush: true);
    return _SourceOverlay(directory: directory);
  }

  Future<void> _copySourceTree({
    required String sourceRoot,
    required Directory destination,
    required WritersidePdfCancellationToken cancellationToken,
  }) async {
    final budget = _SourceCopyBudget(
      maximumBytes: maximumSourceCopyBytes,
      maximumEntries: maximumSourceCopyEntries,
    );
    await _copyDirectoryContents(
      sourceDirectory: sourceRoot,
      destinationDirectory: destination.path,
      sourceRoot: sourceRoot,
      excludedPath: p.dirname(destination.path),
      budget: budget,
      activeDirectories: <String>{},
      cancellationToken: cancellationToken,
    );
    await Directory(p.join(destination.path, '.idea')).create();
  }

  Future<_SourceOverlay> _createProjectSourceOverlay({
    required Directory exportRoot,
    required _ValidatedWritersidePdfRequest validated,
    required WritersidePdfCancellationToken cancellationToken,
  }) async {
    final directory = await Directory(
      p.join(exportRoot.path, 'source-overlay'),
    ).create();
    await _copySourceTree(
      sourceRoot: validated.sourceRoot,
      destination: directory,
      cancellationToken: cancellationToken,
    );
    return _SourceOverlay(directory: directory);
  }

  Future<void> _copyDirectoryContents({
    required String sourceDirectory,
    required String destinationDirectory,
    required String sourceRoot,
    required String excludedPath,
    required _SourceCopyBudget budget,
    required Set<String> activeDirectories,
    required WritersidePdfCancellationToken cancellationToken,
  }) async {
    cancellationToken.throwIfCancelled();
    final canonicalDirectory = p.normalize(
      await Directory(sourceDirectory).resolveSymbolicLinks(),
    );
    if (!activeDirectories.add(canonicalDirectory)) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The selected source root contains a circular symlink.',
      );
    }
    try {
      await Directory(destinationDirectory).create(recursive: true);
      final entities = await Directory(
        sourceDirectory,
      ).list(followLinks: false).toList();
      entities.sort((left, right) => left.path.compareTo(right.path));
      for (final entity in entities) {
        cancellationToken.throwIfCancelled();
        final name = p.basename(entity.path);
        final resolved = await _canonicalOverlayEntity(entity.path, sourceRoot);
        if (p.equals(resolved.path, excludedPath) ||
            p.isWithin(excludedPath, resolved.path)) {
          continue;
        }
        if (resolved.type == FileSystemEntityType.directory &&
            const {'.git', '.hg', '.svn', '.idea'}.contains(name)) {
          continue;
        }
        if (resolved.type == FileSystemEntityType.file &&
            RegExp(r'^pdfSource.+\.(?:pdf|html)$').hasMatch(name)) {
          continue;
        }
        budget.addEntry(name);
        final destinationPath = p.join(destinationDirectory, name);
        switch (resolved.type) {
          case FileSystemEntityType.directory:
            await _copyDirectoryContents(
              sourceDirectory: resolved.path,
              destinationDirectory: destinationPath,
              sourceRoot: sourceRoot,
              excludedPath: excludedPath,
              budget: budget,
              activeDirectories: activeDirectories,
              cancellationToken: cancellationToken,
            );
          case FileSystemEntityType.file:
            final sourceFile = File(resolved.path);
            budget.addBytes(await sourceFile.length(), name);
            await sourceFile.copy(destinationPath);
          case FileSystemEntityType.link:
          case FileSystemEntityType.unixDomainSock:
          case FileSystemEntityType.pipe:
          case FileSystemEntityType.notFound:
            throw WritersidePdfExportException(
              WritersidePdfFailureCode.invalidRequest,
              detail: 'Unsupported filesystem entry in the source: $name',
            );
        }
      }
    } finally {
      activeDirectories.remove(canonicalDirectory);
    }
  }

  Future<_ResolvedOverlayEntity> _canonicalOverlayEntity(
    String entityPath,
    String sourceRoot,
  ) async {
    try {
      final resolved = p.normalize(
        await File(entityPath).resolveSymbolicLinks(),
      );
      if (!p.equals(sourceRoot, resolved) &&
          !p.isWithin(sourceRoot, resolved)) {
        throw const WritersidePdfExportException(
          WritersidePdfFailureCode.invalidRequest,
          detail: 'A help-module symlink leaves the selected source root.',
        );
      }
      final type = await FileSystemEntity.type(resolved, followLinks: false);
      return _ResolvedOverlayEntity(path: resolved, type: type);
    } on WritersidePdfExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: error.message,
        cause: error,
      );
    }
  }

  String _normalizeRelativeDirectory(String value) {
    final normalized = p.normalize(value.trim());
    if (normalized.isEmpty ||
        normalized == '.' ||
        p.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        normalized.contains('\u0000')) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The build configuration directory is invalid.',
      );
    }
    return normalized;
  }

  void _validateBuilderVersion(String value) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(value)) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The Writerside builder version is invalid.',
      );
    }
  }

  void _validateIdentifier(String value, String label) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > 200 ||
        normalized.contains('/') ||
        normalized.runes.any((value) => value < 0x20 || value == 0x7f)) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'The Writerside $label name is invalid.',
      );
    }
  }

  Future<String> _canonicalDirectory(String value) async {
    try {
      final directory = Directory(p.normalize(p.absolute(value)));
      final resolved = p.normalize(await directory.resolveSymbolicLinks());
      if (await FileSystemEntity.type(resolved, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw FileSystemException('Directory does not exist', resolved);
      }
      return resolved;
    } on FileSystemException catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: error.message,
        cause: error,
      );
    }
  }

  Future<String> _canonicalFile(String value) async {
    try {
      final file = File(p.normalize(p.absolute(value)));
      final resolved = p.normalize(await file.resolveSymbolicLinks());
      if (await FileSystemEntity.type(resolved, followLinks: false) !=
          FileSystemEntityType.file) {
        throw FileSystemException('File does not exist', resolved);
      }
      return resolved;
    } on FileSystemException catch (error) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidConfiguration,
        detail: error.message,
        cause: error,
      );
    }
  }

  void _validateMountPath(String value) {
    if (value.contains(',') ||
        value.contains('\n') ||
        value.contains('\r') ||
        value.contains('\u0000')) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail: 'A Docker mount path contains unsupported characters.',
      );
    }
  }

  String _mount(String source, String target, {bool readOnly = false}) {
    _validateMountPath(source);
    _validateMountPath(target);
    return [
      'type=bind',
      'source=${p.normalize(p.absolute(source))}',
      'target=$target',
      if (readOnly) 'readonly',
    ].join(',');
  }

  String _containerPath(List<String> parts) {
    final result = <String>[];
    for (final part in parts) {
      final normalized = _posix(part);
      if (normalized.isEmpty || normalized == '.') {
        continue;
      }
      result.add(normalized.replaceAll(RegExp(r'^/+|/+$'), ''));
    }
    return '/${result.join('/')}';
  }

  String _posix(String value) => value.replaceAll('\\', '/');

  Future<File> _findPdfArtifact(
    Directory output,
    String instanceId,
    WritersideBuilderProcessResult build,
  ) async {
    final expectedName = 'pdfSource${instanceId.toUpperCase()}.pdf';
    final candidates = <File>[];
    await for (final entity in output.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.pdf') {
        if (p.basename(entity.path) == expectedName) {
          return entity;
        }
        candidates.add(entity);
      }
    }
    if (candidates.length == 1) {
      return candidates.single;
    }
    final log = _safeDetail('${build.stderr}\n${build.stdout}');
    final crashed = _isRecoverablePdfProcessCrash(build);
    throw WritersidePdfExportException(
      crashed
          ? WritersidePdfFailureCode.buildFailed
          : WritersidePdfFailureCode.invalidOutput,
      detail: [
        candidates.isEmpty
            ? 'The Writerside builder did not produce a PDF artifact.'
            : 'The Writerside builder produced multiple PDF artifacts.',
        if (log.isNotEmpty) log,
      ].join('\n\n'),
    );
  }

  bool _isRecoverablePdfProcessCrash(WritersideBuilderProcessResult build) {
    return build.stderr.toLowerCase().contains('stack smashing detected') ||
        build.stdout.toLowerCase().contains('stack smashing detected');
  }

  bool _isPdf(List<int> bytes) {
    const header = [0x25, 0x50, 0x44, 0x46, 0x2d];
    if (bytes.length < header.length) {
      return false;
    }
    for (var index = 0; index < header.length; index++) {
      if (bytes[index] != header[index]) {
        return false;
      }
    }
    final tailStart = (bytes.length - 2048).clamp(0, bytes.length);
    return latin1.decode(bytes.sublist(tailStart)).contains('%%EOF');
  }

  int? _pageCount(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    final count = RegExp(r'/Type\s*/Page(?!s)\b').allMatches(text).length;
    return count == 0 ? null : count;
  }

  String _safeDetail(String value) {
    final normalized = value.replaceAll('\u0000', '').trim();
    if (normalized.length <= 12000) {
      return normalized;
    }
    const half = 6000;
    return '${normalized.substring(0, half)}\n'
        '… builder output truncated …\n'
        '${normalized.substring(normalized.length - half)}';
  }

  Future<void> _deleteBestEffort(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on Object {
      // Export completion and failure must not be hidden by cleanup.
    }
  }
}

class _ValidatedWritersidePdfRequest {
  const _ValidatedWritersidePdfRequest({
    required this.sourceRoot,
    required this.moduleRelativePath,
    required this.buildConfigDirectory,
    required this.projectConfigurationRelativePath,
    required this.containerLogoPath,
  });

  final String sourceRoot;
  final String moduleRelativePath;
  final String buildConfigDirectory;
  final String? projectConfigurationRelativePath;
  final String? containerLogoPath;
}

class _SourceOverlay {
  const _SourceOverlay({required this.directory});

  final Directory directory;
}

class _SourceCopyBudget {
  _SourceCopyBudget({required this.maximumBytes, required this.maximumEntries});

  final int maximumBytes;
  final int maximumEntries;
  var _bytes = 0;
  var _entries = 0;

  void addEntry(String name) {
    _entries++;
    if (_entries > maximumEntries) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail:
            'The selected source contains more than $maximumEntries entries.',
      );
    }
  }

  void addBytes(int bytes, String name) {
    _bytes += bytes;
    if (_bytes > maximumBytes) {
      throw WritersidePdfExportException(
        WritersidePdfFailureCode.invalidRequest,
        detail:
            'The selected source exceeds the private-copy limit while '
            'copying $name.',
      );
    }
  }
}

class _ResolvedOverlayEntity {
  const _ResolvedOverlayEntity({required this.path, required this.type});

  final String path;
  final FileSystemEntityType type;
}
