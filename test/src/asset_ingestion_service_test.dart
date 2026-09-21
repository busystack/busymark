import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/assets/asset_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  test('ingests workspace images with safe names and portable paths', () async {
    final workspace = await Directory.systemTemp.createTemp('busymark-assets-');
    addTearDown(() => workspace.delete(recursive: true));
    final document = File(p.join(workspace.path, 'docs', 'guide.md'));
    await document.parent.create(recursive: true);
    await document.writeAsString('# Guide\n');
    final source = File(p.join(workspace.path, 'Screen shot (1).txt'));
    await source.writeAsBytes(png);
    const service = AssetIngestionService();

    final result = await service.ingestFile(
      sourcePath: source.path,
      request: AssetIngestionRequest(
        documentFilePath: document.path,
        workspaceKind: AssetWorkspaceKind.markdownWorkspace,
        workspaceRoot: workspace.path,
      ),
      origin: AssetIngestionOrigin.imagePicker,
    );

    expect(
      result.absolutePath,
      p.join(workspace.path, 'images', 'Screen-shot-1.png'),
    );
    expect(result.markdownPath, '../images/Screen-shot-1.png');
    expect(result.mimeType, 'image/png');
    expect(result.reusedExisting, isFalse);
    expect(await File(result.absolutePath).readAsBytes(), png);
  });

  test('reuses identical assets and resolves name collisions', () async {
    final workspace = await Directory.systemTemp.createTemp('busymark-assets-');
    addTearDown(() => workspace.delete(recursive: true));
    final document = File(p.join(workspace.path, 'note.md'))
      ..writeAsStringSync('');
    const service = AssetIngestionService();
    final request = AssetIngestionRequest(
      documentFilePath: document.path,
      workspaceKind: AssetWorkspaceKind.markdownWorkspace,
      workspaceRoot: workspace.path,
    );

    final first = await service.ingestBytes(
      bytes: png,
      suggestedFileName: 'image.png',
      request: request,
      origin: AssetIngestionOrigin.screenshotPaste,
    );
    await service.commit(first);
    final reused = await service.ingestBytes(
      bytes: png,
      suggestedFileName: 'different.png',
      request: request,
      origin: AssetIngestionOrigin.clipboardImageFile,
    );
    await File(first.absolutePath).writeAsBytes(<int>[...png.take(8), 1]);
    final collision = await service.ingestBytes(
      bytes: png,
      suggestedFileName: 'image.png',
      request: request,
      origin: AssetIngestionOrigin.dragAndDrop,
    );

    expect(reused.absolutePath, first.absolutePath);
    expect(reused.reusedExisting, isTrue);
    expect(p.basename(collision.absolutePath), 'image-2.png');
  });

  for (final identicalBytes in [true, false]) {
    test(
      'overlapping ${identicalBytes ? 'identical' : 'different'} publications keep the committed owner',
      () async {
        final workspace = await Directory.systemTemp.createTemp(
          'busymark-asset-ownership-',
        );
        addTearDown(() => workspace.delete(recursive: true));
        final firstDocument = File(p.join(workspace.path, 'first.md'))
          ..writeAsStringSync('');
        final secondDocument = File(p.join(workspace.path, 'second.md'))
          ..writeAsStringSync('');
        final firstPublished = Completer<void>();
        final releaseFirst = Completer<void>();
        final firstService = AssetIngestionService(
          hooks: AssetIngestionHooks(
            afterPublication: (asset) async {
              firstPublished.complete();
              await releaseFirst.future;
            },
          ),
        );
        const secondService = AssetIngestionService();
        final firstRequest = AssetIngestionRequest(
          documentFilePath: firstDocument.path,
          workspaceKind: AssetWorkspaceKind.markdownWorkspace,
          workspaceRoot: workspace.path,
        );
        final secondRequest = AssetIngestionRequest(
          documentFilePath: secondDocument.path,
          workspaceKind: AssetWorkspaceKind.markdownWorkspace,
          workspaceRoot: workspace.path,
        );
        final otherBytes = Uint8List.fromList(png);
        if (!identicalBytes) otherBytes[otherBytes.length - 1] ^= 1;

        final firstFuture = firstService.ingestBytes(
          bytes: png,
          suggestedFileName: 'image.png',
          request: firstRequest,
          origin: AssetIngestionOrigin.screenshotPaste,
        );
        await firstPublished.future;
        final committed = await secondService.ingestBytes(
          bytes: otherBytes,
          suggestedFileName: 'image.png',
          request: secondRequest,
          origin: AssetIngestionOrigin.clipboardImageFile,
        );
        await secondService.commit(committed);
        releaseFirst.complete();
        final stale = await firstFuture;
        await firstService.rollback(stale);

        expect(committed.absolutePath, isNot(stale.absolutePath));
        expect(await File(committed.absolutePath).exists(), isTrue);
        expect(await File(committed.absolutePath).readAsBytes(), otherBytes);
        expect(await File(stale.absolutePath).exists(), isFalse);
      },
    );
  }

  for (final identicalBytes in [true, false]) {
    test(
      'separate processes protect ${identicalBytes ? 'identical' : 'different'} pending publications with equal filenames',
      () async {
        final workspace = await Directory.systemTemp.createTemp(
          'busymark-asset-process-ownership-',
        );
        addTearDown(() => workspace.delete(recursive: true));
        final firstDocument = File(p.join(workspace.path, 'first.md'))
          ..writeAsStringSync('');
        final secondDocument = File(p.join(workspace.path, 'second.md'))
          ..writeAsStringSync('');
        final otherBytes = Uint8List.fromList(png);
        if (!identicalBytes) otherBytes[otherBytes.length - 1] ^= 1;

        final first = await _startAssetProcess(
          'wait',
          workspace.path,
          firstDocument.path,
          'image.png',
          png,
        );
        addTearDown(() => first.process.kill());
        final second = await _runAssetProcess(
          'commit',
          workspace.path,
          secondDocument.path,
          'image.png',
          otherBytes,
        );
        first.process.stdin.writeln('rollback');
        await first.process.stdin.flush();
        expect(await first.process.exitCode, 0);

        expect(second['path'], isNot(first.message['path']));
        final committed = File(second['path']! as String);
        expect(await committed.exists(), isTrue);
        expect(await committed.readAsBytes(), otherBytes);
        expect(await File(first.message['path']! as String).exists(), isFalse);
      },
    );
  }

  test(
    'failed publication releases only its own filesystem reservation',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-asset-process-failure-',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final document = File(p.join(workspace.path, 'note.md'))
        ..writeAsStringSync('');

      final failed = await _runAssetProcess(
        'fail-publication',
        workspace.path,
        document.path,
        'image.png',
        png,
      );
      expect(failed['error'], contains('injected publication failure'));
      final committed = await _runAssetProcess(
        'commit',
        workspace.path,
        document.path,
        'image.png',
        png,
      );

      expect(p.basename(committed['path']! as String), 'image.png');
      expect(await File(committed['path']! as String).readAsBytes(), png);
    },
  );

  test(
    'terminated provisional owner remains reserved across processes',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-asset-process-termination-',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final firstDocument = File(p.join(workspace.path, 'first.md'))
        ..writeAsStringSync('');
      final secondDocument = File(p.join(workspace.path, 'second.md'))
        ..writeAsStringSync('');
      final first = await _startAssetProcess(
        'wait',
        workspace.path,
        firstDocument.path,
        'image.png',
        png,
      );
      first.process.kill();
      await first.process.exitCode;

      final second = await _runAssetProcess(
        'commit',
        workspace.path,
        secondDocument.path,
        'image.png',
        png,
      );

      expect(second['path'], isNot(first.message['path']));
      expect(await File(first.message['path']! as String).readAsBytes(), png);
      expect(await File(second['path']! as String).readAsBytes(), png);
    },
  );

  test(
    'rollback cannot delete an asset after its publication is committed',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-asset-commit-',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final document = File(p.join(workspace.path, 'note.md'))
        ..writeAsStringSync('');
      const service = AssetIngestionService();
      final asset = await service.ingestBytes(
        bytes: png,
        suggestedFileName: 'image.png',
        request: AssetIngestionRequest(
          documentFilePath: document.path,
          workspaceKind: AssetWorkspaceKind.markdownWorkspace,
          workspaceRoot: workspace.path,
        ),
        origin: AssetIngestionOrigin.screenshotPaste,
      );

      await service.commit(asset);
      await service.rollback(asset);

      expect(await File(asset.absolutePath).readAsBytes(), png);
    },
  );

  test('uses the configured Writerside images directory', () async {
    final project = await Directory.systemTemp.createTemp(
      'busymark-ws-assets-',
    );
    addTearDown(() => project.delete(recursive: true));
    final document = File(p.join(project.path, 'topics', 'guide.md'));
    await document.parent.create(recursive: true);
    await document.writeAsString('');

    final result = await const AssetIngestionService().ingestBytes(
      bytes: png,
      suggestedFileName: 'diagram.png',
      request: AssetIngestionRequest(
        documentFilePath: document.path,
        workspaceKind: AssetWorkspaceKind.writerside,
        writersideRoot: project.path,
        imagesDir: 'media/images',
      ),
      origin: AssetIngestionOrigin.imagePicker,
    );

    expect(
      result.absolutePath,
      p.join(project.path, 'media', 'images', 'diagram.png'),
    );
    expect(result.markdownPath, '../media/images/diagram.png');
  });

  test(
    'restores retained Writerside video bytes without widening image paste',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'busymark-video-assets-',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final document = File(p.join(workspace.path, 'topic.md'))
        ..writeAsStringSync('');
      final video = Uint8List.fromList([
        0,
        0,
        0,
        20,
        ...ascii.encode('ftypmp42'),
        0,
        0,
        0,
        0,
      ]);
      const service = AssetIngestionService();
      final request = AssetIngestionRequest(
        documentFilePath: document.path,
        workspaceKind: AssetWorkspaceKind.standalone,
      );

      expect(
        service.canIngestMediaBytes(
          bytes: video,
          suggestedFileName: 'clip.mp4',
        ),
        isTrue,
      );
      final result = await service.ingestMediaBytes(
        bytes: video,
        suggestedFileName: 'clip.mp4',
        request: request,
        origin: AssetIngestionOrigin.clipboardImageFile,
      );

      expect(result.markdownPath, 'images/clip.mp4');
      expect(result.mimeType, 'video/mp4');
      expect(await File(result.absolutePath).readAsBytes(), video);
      expect(
        service.canIngestMediaBytes(
          bytes: video,
          suggestedFileName: 'clip.bin',
        ),
        isFalse,
      );
      expect(
        () => service.ingestMediaBytes(
          bytes: video,
          suggestedFileName: 'clip.bin',
          request: request,
          origin: AssetIngestionOrigin.clipboardImageFile,
        ),
        throwsA(
          isA<AssetIngestionException>().having(
            (error) => error.code,
            'code',
            'asset.invalid-media-type',
          ),
        ),
      );
      expect(
        () => service.ingestBytes(
          bytes: video,
          suggestedFileName: 'clip.mp4',
          request: request,
          origin: AssetIngestionOrigin.clipboardImageFile,
        ),
        throwsA(
          isA<AssetIngestionException>().having(
            (error) => error.code,
            'code',
            'asset.invalid-image-type',
          ),
        ),
      );
    },
  );

  test('requires saving untitled documents and rejects non-images', () async {
    const service = AssetIngestionService();
    const untitled = AssetIngestionRequest(
      documentFilePath: '',
      workspaceKind: AssetWorkspaceKind.standalone,
    );

    expect(
      () => service.ingestBytes(
        bytes: png,
        suggestedFileName: 'image.png',
        request: untitled,
        origin: AssetIngestionOrigin.imagePicker,
      ),
      throwsA(isA<AssetSaveRequiredException>()),
    );

    final directory = await Directory.systemTemp.createTemp('busymark-assets-');
    addTearDown(() => directory.delete(recursive: true));
    expect(
      () => service.ingestBytes(
        bytes: utf8.encode('not an image'),
        suggestedFileName: 'fake.png',
        request: AssetIngestionRequest(
          documentFilePath: p.join(directory.path, 'note.md'),
          workspaceKind: AssetWorkspaceKind.standalone,
        ),
        origin: AssetIngestionOrigin.imagePicker,
      ),
      throwsA(
        isA<AssetIngestionException>().having(
          (error) => error.code,
          'code',
          'asset.invalid-image-type',
        ),
      ),
    );
  });
}

Future<({Process process, Map<String, Object?> message})> _startAssetProcess(
  String action,
  String workspace,
  String document,
  String filename,
  List<int> bytes,
) async {
  final dart = p.join(
    Platform.environment['FLUTTER_ROOT']!,
    'bin',
    'cache',
    'dart-sdk',
    'bin',
    'dart',
  );
  final process = await Process.start(dart, [
    'run',
    'test/support/asset_ingestion_process.dart',
    action,
    workspace,
    document,
    filename,
    base64Encode(bytes),
  ]);
  final messages = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  final message = jsonDecode(await messages.first) as Map<String, Object?>;
  return (process: process, message: message);
}

Future<Map<String, Object?>> _runAssetProcess(
  String action,
  String workspace,
  String document,
  String filename,
  List<int> bytes,
) async {
  final running = await _startAssetProcess(
    action,
    workspace,
    document,
    filename,
    bytes,
  );
  final stderrText = await running.process.stderr
      .transform(utf8.decoder)
      .join();
  final exitCode = await running.process.exitCode;
  expect(exitCode, 0, reason: stderrText);
  return running.message;
}
