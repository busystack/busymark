import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/markdown_model.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/remote_image_permissions.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const url = 'https://example.com/identity.png';
  const image = '![Image]($url)';

  final workspace = const WorkspaceService().createUntitledMarkdown();
  WorkspaceState state(DocumentBuffer buffer) => WorkspaceState(
    workspace: workspace,
    documentBuffers: [buffer],
    activeBufferId: buffer.id,
  );
  SourceSpan span(String text, {bool last = false}) {
    final start = last ? text.lastIndexOf(image) : text.indexOf(image);
    return SourceSpan.fromOffsets(
      filePath: '',
      source: text,
      startOffset: start,
      endOffset: start + image.length,
    );
  }

  test(
    'identical markup cannot inherit a grant through an ambiguous deletion',
    () {
      final permissions = RemoteImagePermissions();
      addTearDown(permissions.dispose);
      final before = DocumentBuffer.untitled(
        id: 'draft',
        name: 'Draft',
        text: '$image\n\n$image\n',
      );
      final target = permissions.capture(
        state(before),
        before,
        before.text,
        span(before.text, last: true),
        url,
        null,
      )!;
      expect(
        permissions.apply(target, RemoteImagePermission.image, state(before)),
        isTrue,
      );
      final after = before.edited('$image\n');
      permissions.update(state(before), state(after));
      expect(
        permissions.allows(after, after.text, span(after.text), url),
        isFalse,
      );
    },
  );

  test(
    'source changing out of and back into image syntax invalidates a pending grant',
    () {
      final permissions = RemoteImagePermissions();
      addTearDown(permissions.dispose);
      final before = DocumentBuffer.untitled(
        id: 'draft',
        name: 'Draft',
        text: 'Text\n\n$image\n',
      );
      final target = permissions.capture(
        state(before),
        before,
        before.text,
        span(before.text),
        url,
        null,
      )!;
      final asCode = before.edited('Text\n\n```md\n$image\n');
      final restored = asCode.edited(before.text);
      permissions.update(state(before), state(asCode));
      permissions.update(state(asCode), state(restored));
      expect(
        permissions.apply(
          target,
          RemoteImagePermission.document,
          state(restored),
        ),
        isFalse,
      );
      expect(
        permissions.allows(restored, restored.text, span(restored.text), url),
        isFalse,
      );
    },
  );

  test(
    'a pending grant stays with its opening even when another tab is active',
    () {
      final permissions = RemoteImagePermissions();
      addTearDown(permissions.dispose);
      final origin = DocumentBuffer.untitled(
        id: 'draft',
        name: 'Draft',
        text: '$image\n',
      );
      final other = DocumentBuffer.untitled(
        id: 'other',
        name: 'Other',
        text: origin.text,
      );
      final range = span(origin.text);
      final target = permissions.capture(
        state(origin),
        origin,
        origin.text,
        range,
        url,
        null,
      )!;
      final switched = WorkspaceState(
        workspace: workspace,
        documentBuffers: [origin, other],
        activeBufferId: other.id,
      );
      permissions.update(state(origin), switched);
      expect(
        permissions.apply(target, RemoteImagePermission.document, switched),
        isTrue,
      );
      expect(permissions.allows(origin, origin.text, range, url), isTrue);
      expect(permissions.allows(other, other.text, range, url), isFalse);

      final pending = permissions.capture(
        switched,
        origin,
        origin.text,
        range,
        url,
        null,
      )!;
      final replacement = DocumentBuffer.untitled(
        id: origin.id,
        name: origin.displayName,
        text: origin.text,
      );
      permissions.update(switched, state(replacement));
      expect(
        permissions.apply(
          pending,
          RemoteImagePermission.global,
          state(replacement),
        ),
        isFalse,
      );
      expect(
        permissions.capture(
          state(replacement),
          origin,
          origin.text,
          range,
          url,
          null,
        ),
        isNull,
      );
    },
  );

  test(
    'remote image spans cover brackets, whitespace destinations and references',
    () {
      const source = '''
Before [![Link](https://example.com/linked.png)](https://example.org/) after.

![Spaces](https://example.com/two words.png)

![Reference][ref]

[ref]: https://example.com/reference.png
''';
      final parsed = const MarkdownParser().parse(filePath: '', source: source);
      final all = parsed.busyDocument.blocks.expand((b) => b.inlines);
      final images = [
        for (final inline in all) ...[inline, ...inline.children],
      ].where((inline) => inline.imageSpan != null);
      expect(
        images.map((inline) {
          final span = inline.imageSpan!;
          return source.substring(span.startOffset, span.endOffset);
        }),
        [
          '![Link](https://example.com/linked.png)',
          '![Spaces](https://example.com/two words.png)',
          '![Reference][ref]',
        ],
      );
    },
  );
  for (final (mode, source, markup) in [
    (
      MarkdownMode.commonMark,
      '> ![Real](https://example.com/real.png)\n>\n>     ![Example](https://example.com/example.png)\n',
      '![Real](https://example.com/real.png)',
    ),
    (
      MarkdownMode.commonMark,
      '>     ![Real](https://example.com/real.png)\n>\n> ![Real](https://example.com/real.png)\n',
      '![Real](https://example.com/real.png)',
    ),
    (
      MarkdownMode.commonMark,
      '> - `![Example](https://example.com/example.png)` and [![Real][ref]](https://example.com/)\n>\n>   ```md\n>   ![Example](https://example.com/example.png)\n>   ```\n\n[ref]: https://example.com/real.png\n',
      '![Real][ref]',
    ),
    (
      MarkdownMode.writersideMarkdown,
      '# Topic\n\n<chapter title="Images">\n<img src="https://example.com/real.png" alt="Real"/>\n</chapter>\n',
      '<img src="https://example.com/real.png" alt="Real"/>',
    ),
  ]) {
    test(
      'binds only authored images in ${mode.name}: ${source.split('\n').first}',
      () {
        final document = const MarkdownParser()
            .parse(filePath: 'draft.md', source: source, mode: mode)
            .busyDocument;
        Iterable<BusyInline> images(Iterable<BusyInline> inlines) sync* {
          for (final inline in inlines) {
            if (inline.kind == BusyInlineKind.image) yield inline;
            yield* images(inline.children);
          }
        }

        Iterable<BusyInline> blockImages(Iterable<BusyBlock> blocks) sync* {
          for (final block in blocks) {
            yield* images(block.inlines);
            yield* blockImages(block.children);
          }
        }

        final occurrence = blockImages(document.blocks).single;
        final range = occurrence.imageSpan!;
        const real = 'https://example.com/real.png';
        expect(occurrence.destination, real);
        expect(source.substring(range.startOffset, range.endOffset), markup);
        expect(range.startOffset, source.lastIndexOf(markup));
        final permissions = RemoteImagePermissions();
        addTearDown(permissions.dispose);
        final buffer = DocumentBuffer.untitled(
          id: 'draft',
          name: 'Draft',
          text: source,
        );
        final target = permissions.capture(
          state(buffer),
          buffer,
          source,
          range,
          real,
          null,
        )!;
        expect(target.hasOccurrence, isTrue);
        expect(
          permissions.apply(target, RemoteImagePermission.image, state(buffer)),
          isTrue,
        );
        expect(permissions.allows(buffer, source, range, real), isTrue);
        expect(
          permissions.allows(
            buffer,
            source,
            range,
            'https://example.com/example.png',
          ),
          isFalse,
        );
        expect(
          permissions.apply(
            target,
            RemoteImagePermission.global,
            state(buffer),
          ),
          isFalse,
        );
      },
    );
  }
}
