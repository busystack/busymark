import 'package:busymark/src/markdown/audio_media.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/busymark_markdown_serializer.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_attachment_references.dart';
import 'package:busymark/src/references/markdown_references.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedMarkdownDocument parse(String source) => const MarkdownParser().parse(
  filePath: 'recording.md',
  source: source,
  mode: MarkdownMode.gfm,
  validateLocalReferences: false,
);

Iterable<BusyAudio> inlines(List<BusyInline> values) sync* {
  for (final value in values) {
    if (value.audio case final audio?) yield audio;
    yield* inlines(value.children);
  }
}

Iterable<BusyAudio> audioIn(List<BusyBlock> blocks) sync* {
  for (final block in blocks) {
    if (block.audio case final audio?) yield audio;
    yield* inlines(block.inlines);
    yield* audioIn(block.children);
  }
}

void main() {
  test('standard audio owns fallback, ordered sources and author spelling', () {
    const direct =
        '<AuDiO controls="false" preload="none" src="média/one (1).mp3"'
        ' autoplay="false" muted loop custom="preserve">'
        '<source src=ignored.ogg type="audio/ogg; codecs=opus"></AuDiO>';
    const fallback = """<audio controls aria-label='Voice'>
  <source src='first.ogg?a=1&amp;b=2' type="audio/ogg; codecs=opus">
  <source src=again.mp3 type=audio/mpeg>
  <a href='again.mp3'>Download &amp; listen</a>
</audio>""";
    const source = '# Recordings\n\n$direct\n\n$fallback\n';
    final parsed = parse(source);
    final audio = audioIn(parsed.busyDocument.blocks).toList();
    expect(audio.map((entry) => entry.rawSource), [direct, fallback]);
    expect(audio.first.controls, isTrue);
    expect(audio.first.autoplay, isTrue);
    expect(audio.first.muted, isTrue);
    expect(audio.first.loop, isTrue);
    expect(audio.first.attributes, isNot(contains('custom')));
    expect(audio.first.playbackSources.single.destination, 'média/one (1).mp3');
    expect(audio.first.sources.single.destination, 'ignored.ogg');
    expect(audio.last.playbackSources.map((s) => s.destination), [
      'first.ogg?a=1&b=2',
      'again.mp3',
    ]);
    expect(audio.last.playbackSources.first.type, 'audio/ogg; codecs=opus');
    expect(
      parsed.busyDocument.blocks.last.plainText.trim(),
      'Download & listen',
    );
    final preview = const MarkdownPreviewBuilder().build(parsed);
    expect(preview.blocks.last.kind, PreviewBlockKind.audio);
    expect(preview.blocks.last.audio?.accessibleName, 'Voice');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test('nested and inline audio retain a distinct semantic occurrence', () {
    const element =
        '<audio src="Voice.wav">Download https://example.org/ for *later*</audio>';
    const source =
        '''Start $element end.

- Clip $element

> Quoted $element

| Label |
| --- |
| Table $element |

<figure><p>HTML $element after.</p></figure>
''';
    final parsed = parse(source);
    final audio = audioIn(parsed.busyDocument.blocks).toList();
    expect(audio, hasLength(5));
    expect(audio.map((item) => item.rawSource), everyElement(element));
    for (final item in audio) {
      final span = item.sourceSpan!;
      expect(span.filePath, 'recording.md');
      expect(source.substring(span.startOffset, span.endOffset), element);
      final destination = item.directSource!.sourceSpan!;
      expect(
        source.substring(destination.startOffset, destination.endOffset),
        'Voice.wav',
      );
    }
    expect(parsed.busyDocument.blocks.first.inlines.first.text, 'Start ');
    expect(parsed.busyDocument.blocks.first.inlines.last.text, ' end.');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });

  test(
    'asset scanners retain exact attributes and ignore literal appearances',
    () {
      const source = """
<audio src='média/one (1).mp3?a=1&amp;b=2#t=3'>
  <source src=other.ogg>
  <source src=other.ogg>
</audio>

A string src=other.ogg.

`<audio src=other.ogg></audio>`

<!--
<audio src=other.ogg></audio>
-->

```html
<audio src=other.ogg></audio>
```
""";
      final refs = markdownReferences(identity: 'recording.md', source: source);
      expect(refs.where((r) => r.isAudio).map((r) => r.destination), [
        'média/one (1).mp3?a=1&b=2#t=3',
        'other.ogg',
        'other.ogg',
      ]);
      final notes = notesAttachmentReferences(source);
      expect(notes, hasLength(3));
      expect(notes.every((entry) => entry.audio), isTrue);
      expect(notes.first.reference, 'média/one (1).mp3');
      expect(
        source.substring(notes.first.start, notes.first.end),
        'média/one (1).mp3?a=1&amp;b=2#t=3',
      );
      final result = replaceNotesAttachmentReferences(source, notes, {
        'other.ogg': 'different.ogg?x=1&y=2',
        'média/one (1).mp3': 'portable.mp3',
      });
      expect(
        RegExp('src="different.ogg\\?x=1&amp;y=2"').allMatches(result),
        hasLength(2),
      );
      expect(result, contains('A string src=other.ogg.'));
      expect(result, contains("src='portable.mp3?a=1&amp;b=2#t=3'"));
      expect(result, contains('`<audio src=other.ogg></audio>`'));
    },
  );

  test('unsafe audio and orphan source remain source text', () {
    const source =
        '<audio src="javascript:alert(1)" controls></audio>\n\n'
        '<source src=orphan.mp3>\n\n'
        'Say <audio src=broken.mp3 here.\n\n'
        'Other paragraph.\n';
    final parsed = parse(source);
    expect(audioIn(parsed.busyDocument.blocks), isEmpty);
    expect(
      parsed.diagnostics.map((item) => item.code),
      containsAll([
        'markdown.raw-html.unsafe',
        'markdown.audio.invalid-structure',
      ]),
    );
    expect(parsed.busyDocument.blocks.last.plainText, 'Other paragraph.');
    expect(
      const BusyMarkMarkdownSerializer().serialize(parsed.busyDocument),
      source,
    );
  });
}
