import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_export_mapper.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/speech/speech_pcm.dart';
import 'package:busymark/src/speech/speech_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory destination;
  late Uint8List wav;
  late HtmlExportService service;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-html-audio-');
    final artifactRoot = Platform.environment['BUSYMARK_AUDIO_HTML_ARTIFACTS'];
    destination = artifactRoot == null ? root : Directory(artifactRoot);
    await destination.create(recursive: true);
    final waveform = ByteData(16000 * 2);
    for (var i = 0; i < 16000; i++) {
      final sample = (math.sin(i * 2 * math.pi * 440 / 16000) * 2400).round();
      waveform.setInt16(i * 2, sample, Endian.little);
    }
    wav = encodeSpeechWave(
      SpeechPcm(waveform.buffer.asUint8List(), sampleRate: 16000),
    );
    await File(p.join(root.path, 'a voice.wav')).writeAsBytes(wav);
    await File(p.join(root.path, 'wrong.mp3')).writeAsString('Wrong format.');
    service = HtmlExportService(
      stylesheetLoader: () => File('assets/export/html.css').readAsString(),
    );
  });
  tearDown(() async => root.delete(recursive: true));

  Future<HtmlExportResult> export(
    String source,
    String name,
    HtmlExportOptions options,
  ) => service.exportMarkdown(
    MarkdownHtmlExportRequest(
      source: source,
      filePath: p.join(root.path, 'source.md'),
      workspaceRoot: root.path,
      destinationPath: p.join(destination.path, '$name.html'),
      options: options,
    ),
  );

  test(
    'packaged and embedded audio use validated bytes after relocation',
    timeout: const Timeout(Duration(seconds: 90)),
    () async {
      const source = '''
# Audio

<audio controls="false" loop muted autoplay preload=auto aria-label="Sample">
<source src=wrong.mp3 type=audio/mpeg>
<source src="a%20voice.wav#t=0.1" type="audio/wav">
<a href="a%20voice.wav">Download</a>
</audio>

Inline <audio src="a%20voice.wav"></audio> audio without controls.
''';
      for (final packaging in HtmlPackaging.values) {
        final embedded = packaging == HtmlPackaging.singleFile;
        final result = await export(
          source,
          embedded ? 'audio-single' : 'audio-assets',
          HtmlExportOptions(packaging: packaging),
        );
        final doc = html.parse(
          await File(result.entryPointPath).readAsString(),
        );
        final player = doc.querySelector('audio[controls]')!;
        expect(player.attributes['preload'], 'none');
        expect(player.attributes, isNot(contains('autoplay')));
        expect(player.attributes, contains('loop'));
        expect(player.attributes, contains('muted'));
        expect(player.attributes['aria-label'], 'Sample');
        expect(player.querySelector('a')!.text, 'Download');
        final selected = player.querySelectorAll('source').single;
        expect(selected.attributes['type'], 'audio/wav');
        final selectedUrl = selected.attributes['src']!;
        expect(selectedUrl, endsWith('#t=0.1'));
        expect(
          doc.querySelector('p audio')!.attributes,
          isNot(contains('controls')),
        );
        final csp = doc
            .querySelector('meta[http-equiv="Content-Security-Policy"]')!
            .attributes['content'];
        expect(csp, contains("script-src 'none'"));
        if (embedded) {
          expect(selectedUrl, startsWith('data:audio/wav;base64,'));
          expect(csp, contains("media-src 'self' file: data:"));
          expect(result.assetsPath, isNull);
        } else {
          final path = Uri.decodeComponent(Uri.parse(selectedUrl).path);
          expect(await File(p.join(destination.path, path)).readAsBytes(), wav);
          expect(csp, isNot(contains('data:')));
        }
        expect(
          result.warnings.map((warning) => warning.code),
          contains('asset.unavailable'),
        );
      }
    },
  );

  test(
    'remote media stays an offline link unless the export opts in',
    () async {
      const source =
          '<audio controls src="https://media.example:8443/a.mp3" '
          'crossorigin=use-credentials><source src="a%20voice.wav"></audio>';
      for (final remote in [false, true]) {
        final result = await export(
          source,
          'remote-$remote',
          HtmlExportOptions(allowRemoteAudio: remote),
        );
        final doc = html.parse(
          await File(result.entryPointPath).readAsString(),
        );
        final csp = doc
            .querySelector('meta[http-equiv]')!
            .attributes['content'];
        if (remote) {
          expect(
            doc.querySelector('audio')!.attributes['src'],
            'https://media.example:8443/a.mp3',
          );
          expect(
            doc.querySelector('audio')!.attributes['crossorigin'],
            'anonymous',
          );
          expect(
            csp,
            contains('media-src \'self\' file: https://media.example:8443;'),
          );
        } else {
          expect(doc.querySelector('audio'), isNull);
          expect(
            doc.querySelector('a[href^="https://media.example"]'),
            isNotNull,
          );
          expect(csp, isNot(contains('media.example')));
        }
        expect(
          result.assetsPath,
          isNull,
          reason: 'Direct src wins over the local child.',
        );
      }
    },
  );

  test('PDF audio fallback links only to distributable destinations', () {
    const source = '''
<audio aria-label="Local voice" src="x.wav">Read the transcript.</audio>

<audio aria-label="Remote voice" src="https://example.test/voice.wav"></audio>
''';
    final parsed = const MarkdownParser().parse(
      filePath: 'recording.md',
      source: source,
      validateLocalReferences: false,
    );
    final exported = const MarkdownExportMapper().map(parsed.busyDocument);
    final local = exported.blocks.first.inlines.single;
    expect(local.kind, MarkdownExportInlineKind.text);
    expect(
      local.children.map((item) => item.text).join(),
      'Local voice — Read the transcript.',
    );
    expect(local.destination, isNull);
    final remote = exported.blocks.last.inlines.single;
    expect(remote.kind, MarkdownExportInlineKind.link);
    expect(remote.destination, 'https://example.test/voice.wav');
  });
}
