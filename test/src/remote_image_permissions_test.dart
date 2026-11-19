import 'package:busymark/src/core/source_span.dart';
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
}
