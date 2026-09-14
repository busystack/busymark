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
