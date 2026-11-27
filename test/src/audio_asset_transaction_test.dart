import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/assets/asset_ingestion_service.dart';
import 'package:busymark/src/assets/audio_asset_format.dart';
import 'package:busymark/src/editor/audio_authoring.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_document_controller.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final wave = encodeSpeechWave(SpeechPcm(Uint8List(4800), sampleRate: 24000));

  test(
    'audio uses managed ownership, preserves Unicode and deduplicates',
    () async {
      final root = await Directory.systemTemp.createTemp('audio-assets-');
      addTearDown(() => root.delete(recursive: true));
      final source = File(p.join(root.path, 'notes.md'));
      await source.writeAsString('Note');
      final request = AssetIngestionRequest(
        documentFilePath: source.path,
        workspaceKind: AssetWorkspaceKind.standalone,
        audioDir: 'Recordings',
      );
      const service = AssetIngestionService();
      Future<IngestedAsset> ingest(String filename) => service.ingestAudioBytes(
        bytes: wave,
        suggestedFileName: filename,
        request: request,
        origin: AssetIngestionOrigin.audioPicker,
      );
      final first = await ingest('Récit (1) #é.wav');
      final concurrent = await ingest('Récit (1) #é.wav');
      expect(first.markdownPath, 'Recordings/Récit (1) #é.wav');
      expect(first.mimeType, 'audio/wav');
      expect(concurrent.absolutePath, isNot(first.absolutePath));
      await service.rollback(concurrent);
      expect(await File(concurrent.absolutePath).exists(), isFalse);

      await service.commit(first);
      final reused = await ingest('different.wav');
      expect(reused.reusedExisting, isTrue);
      expect(reused.absolutePath, first.absolutePath);
      await service.rollback(reused);
      expect(await File(first.absolutePath).readAsBytes(), wave);
      final markup = audioReferenceMarkup(first.markdownPath, localPath: true);
      final audio = parseAuthoredAudio(markup)!;
      expect(
        await resolveDocumentAudioPath(
          audio.directSource!.destination,
          documentPath: source.path,
          rootPath: root.path,
        ),
        first.absolutePath,
      );
    },
  );

  test(
    'audio publication owns the original bytes across the async write',
    () async {
      final root = await Directory.systemTemp.createTemp('audio-captured-');
      addTearDown(() => root.delete(recursive: true));
      final document = await File(
        p.join(root.path, 'doc.md'),
      ).writeAsString('');
      final request = AssetIngestionRequest(
        documentFilePath: document.path,
        workspaceKind: AssetWorkspaceKind.standalone,
      );
      const service = AssetIngestionService();
      final callerBytes = Uint8List.fromList(wave);
      final publication = service.ingestAudioBytes(
        bytes: callerBytes,
        suggestedFileName: 'recording.wav',
        request: request,
        origin: AssetIngestionOrigin.audioPicker,
      );
      callerBytes.fillRange(0, callerBytes.length, 63);
      final asset = await publication;
      await service.commit(asset);
      expect(await File(asset.absolutePath).readAsBytes(), wave);
    },
  );

  test(
    'audio destination symlinks cannot create directories outside the root',
    () async {
      final root = await Directory.systemTemp.createTemp('audio-root-');
      final outside = await Directory.systemTemp.createTemp('audio-outside-');
      addTearDown(() async {
        await root.delete(recursive: true);
        await outside.delete(recursive: true);
      });
      final source = File(p.join(root.path, 'test.md'));
      await source.writeAsString('test');
      await Link(p.join(root.path, 'outside')).create(outside.path);
      await expectLater(
        const AssetIngestionService().ingestAudioBytes(
          bytes: wave,
          suggestedFileName: 'narration.wav',
          request: AssetIngestionRequest(
            documentFilePath: source.path,
            workspaceKind: AssetWorkspaceKind.standalone,
            audioDir: 'outside/nested',
          ),
          origin: AssetIngestionOrigin.speechGeneration,
        ),
        throwsA(isA<AssetIngestionException>()),
      );
      expect(await Directory(p.join(outside.path, 'nested')).exists(), isFalse);
      expect(AudioAssetFormat.identify([0, 9, 64, 5]), isNull);
    },
  );

  test(
    'rich clipboard rebases all audio sources and retains exact surrounding markup',
    () {
      const markup = """<audio controls='false' data-extra='preserved'>
<source src=first.ogg type='audio/ogg'>
<source src="second.wav?take=8&amp;sample=1">
<span data-extra='Keep'><a href=second.wav#download>Recording</a></span>
<a href="transcript.md">Transcript</a></audio>""";
      final parsed = const MarkdownParser()
          .parse(
            filePath: '/docs/source.md',
            source: markup,
            validateLocalReferences: false,
          )
          .busyDocument;
      final block = parsed.blocks.single;
      final fragment = WysiwygClipboardFragment(
        blocks: [
          BusyWysiwygStyledBlock(
            kind: block.kind,
            text: block.plainText,
            ranges: const [],
            attributes: block.attributes,
            completeBlock: block,
          ),
        ],
        mode: parsed.mode,
        sourcePath: parsed.filePath,
      );
      final decoded = WysiwygClipboardFragment.decode(fragment.encode())!;
      expect(decoded.documentBlocks.single.kind, BusyBlockKind.audio);
      expect(decoded.audioReferences, {
        'first.ogg',
        'second.wav?take=8&sample=1',
        'second.wav#download',
      });
      final pasted = decoded.rebase(
        '/docs/target.md',
        mediaDestinations: {
          'first.ogg': 'audio/rebased.ogg',
          'second.wav?take=8&sample=1': 'audio/other.wav',
        },
      );
      final result = pasted.documentBlocks.single.audio!;
      expect(
        result.rawSource,
        markup
            .replaceFirst('first.ogg', 'audio/rebased.ogg')
            .replaceFirst('second.wav?', 'audio/other.wav?')
            .replaceFirst('second.wav#download', 'audio/other.wav#download'),
      );
      expect(result.controls, isTrue);
    },
  );
}
