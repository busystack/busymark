import 'package:flutter/foundation.dart';

import '../clipboard/clipboard_insertion.dart';
import '../clipboard/clipboard_models.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_model.dart';
import '../platform/rich_clipboard_service.dart';
import 'wysiwyg/wysiwyg_clipboard_fragment.dart';
import 'wysiwyg/wysiwyg_clipboard_html.dart';

enum BusyMarkPasteDestination {
  editor,
  markdownSource,
  writersideXmlSource,
  genericXmlSource,
  plainSource,
}

@immutable
class BusyMarkClipboardSnapshot {
  BusyMarkClipboardSnapshot({
    this.text,
    this.sourceText,
    this.html,
    this.richFragment,
    Map<String, Uint8List> mediaBytes = const {},
    this.mediaComplete = true,
    Uint8List? imageBytes,
    this.imageMimeType,
    this.imageDisplayName,
    this.origin,
    required this.external,
    required this.sessionOwned,
    this.contentKind,
    required this.fromSystemClipboard,
  }) : mediaBytes = Map.unmodifiable({
         for (final entry in mediaBytes.entries)
           entry.key: Uint8List.fromList(entry.value),
       }),
       imageBytes = imageBytes == null ? null : Uint8List.fromList(imageBytes);

  factory BusyMarkClipboardSnapshot.fromSystem(RichClipboardData data) =>
      BusyMarkClipboardSnapshot(
        text: data.text,
        sourceText: data.sourceText,
        html: data.html,
        richFragment: data.richFragment,
        mediaBytes: data.mediaBytes,
        mediaComplete: data.mediaComplete,
        origin: data.origin,
        external: !data.sessionOwned,
        sessionOwned: data.sessionOwned,
        fromSystemClipboard: true,
      );

  factory BusyMarkClipboardSnapshot.fromPayload(
    BusyMarkClipboardPayload payload,
  ) => BusyMarkClipboardSnapshot(
    text: payload.text,
    sourceText: payload.sourceText,
    html: payload.html,
    richFragment: payload.richFragment,
    mediaBytes: payload.mediaBytes,
    mediaComplete: payload.mediaComplete,
    imageBytes: payload.imageBytes,
    imageMimeType: payload.imageMimeType,
    imageDisplayName: payload.imageDisplayName,
    origin: payload.origin,
    external: payload.external,
    sessionOwned: !payload.external,
    contentKind: payload.kind,
    fromSystemClipboard: false,
  );

  final String? text;
  final String? sourceText;
  final String? html;
  final String? richFragment;
  final Map<String, Uint8List> mediaBytes;
  final bool mediaComplete;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final String? imageDisplayName;
  final BusyMarkClipboardOrigin? origin;
  final bool external;
  final bool sessionOwned;
  final BusyMarkClipboardContentKind? contentKind;
  final bool fromSystemClipboard;
}

enum BusyMarkStructuredClipboardSource { richFragment, html }

sealed class BusyMarkPasteCandidate {
  const BusyMarkPasteCandidate();
}

@immutable
class BusyMarkStructuredPasteCandidate extends BusyMarkPasteCandidate {
  const BusyMarkStructuredPasteCandidate({
    required this.fragment,
    required this.source,
  });

  final WysiwygClipboardFragment fragment;
  final BusyMarkStructuredClipboardSource source;
}

@immutable
class BusyMarkSourceTextPasteCandidate extends BusyMarkPasteCandidate {
  const BusyMarkSourceTextPasteCandidate(this.text);

  final String text;
}

@immutable
class BusyMarkPlainTextPasteCandidate extends BusyMarkPasteCandidate {
  const BusyMarkPlainTextPasteCandidate(this.text);

  final String text;
}

@immutable
class BusyMarkImagePasteCandidate extends BusyMarkPasteCandidate {
  const BusyMarkImagePasteCandidate({
    required this.bytes,
    this.mimeType,
    this.displayName,
  });

  final Uint8List bytes;
  final String? mimeType;
  final String? displayName;
}

/// Marks the separate native image boundary. The insertion adapter must
/// acquire the bytes and revalidate the system clipboard identity.
@immutable
class BusyMarkNativeImagePasteCandidate extends BusyMarkPasteCandidate {
  const BusyMarkNativeImagePasteCandidate();
}

@immutable
class BusyMarkPastePlan {
  const BusyMarkPastePlan(this.candidates);

  final List<BusyMarkPasteCandidate> candidates;

  bool get isEmpty => candidates.isEmpty;
}

class BusyMarkClipboardPasteResolver {
  const BusyMarkClipboardPasteResolver();

  BusyMarkPastePlan resolve({
    required BusyMarkClipboardSnapshot snapshot,
    required BusyMarkPasteMode mode,
    required BusyMarkPasteDestination destination,
    MarkdownMode? markdownMode,
  }) {
    final text = _available(snapshot.text);
    if (mode == BusyMarkPasteMode.plainText) {
      return BusyMarkPastePlan(
        text == null ? const [] : [BusyMarkPlainTextPasteCandidate(text)],
      );
    }

    final supportsImages = switch (destination) {
      BusyMarkPasteDestination.editor ||
      BusyMarkPasteDestination.markdownSource ||
      BusyMarkPasteDestination.writersideXmlSource => true,
      BusyMarkPasteDestination.genericXmlSource ||
      BusyMarkPasteDestination.plainSource => false,
    };
    if (snapshot.contentKind == BusyMarkClipboardContentKind.image) {
      final bytes = snapshot.imageBytes;
      return BusyMarkPastePlan(
        supportsImages && bytes != null && bytes.isNotEmpty
            ? [
                BusyMarkImagePasteCandidate(
                  bytes: bytes,
                  mimeType: snapshot.imageMimeType,
                  displayName: snapshot.imageDisplayName,
                ),
              ]
            : const [],
      );
    }

    final sourceText = _available(snapshot.sourceText);
    final candidates = <BusyMarkPasteCandidate>[];
    final supportsStructured =
        destination == BusyMarkPasteDestination.editor ||
        destination == BusyMarkPasteDestination.markdownSource;
    if (supportsStructured) {
      final encoded = _available(snapshot.richFragment);
      final nativeFragment = encoded == null
          ? null
          : WysiwygClipboardFragment.decode(encoded);
      if (nativeFragment != null) {
        candidates.add(
          BusyMarkStructuredPasteCandidate(
            fragment: nativeFragment,
            source: BusyMarkStructuredClipboardSource.richFragment,
          ),
        );
      }
      final html = _available(snapshot.html);
      if (html != null) {
        try {
          final decoded = const WysiwygClipboardHtml().decode(
            html,
            mode: markdownMode ?? MarkdownMode.commonMark,
          );
          if (decoded != null && hasUsableClipboardHtmlContent(decoded)) {
            candidates.add(
              BusyMarkStructuredPasteCandidate(
                fragment: decoded,
                source: BusyMarkStructuredClipboardSource.html,
              ),
            );
          }
        } on FormatException {
          // A malformed richer representation never suppresses fallbacks.
        } on ArgumentError {
          // Treat invalid HTML input as unavailable.
        }
      }
    }

    switch (destination) {
      case BusyMarkPasteDestination.editor:
        if (text != null) candidates.add(BusyMarkPlainTextPasteCandidate(text));
        if (text == null && sourceText != null) {
          candidates.add(BusyMarkSourceTextPasteCandidate(sourceText));
        }
      case BusyMarkPasteDestination.markdownSource:
        if (sourceText != null) {
          candidates.add(BusyMarkSourceTextPasteCandidate(sourceText));
        }
        if (text != null) candidates.add(BusyMarkPlainTextPasteCandidate(text));
      case BusyMarkPasteDestination.writersideXmlSource:
      case BusyMarkPasteDestination.genericXmlSource:
      case BusyMarkPasteDestination.plainSource:
        if (sourceText != null) {
          candidates.add(BusyMarkSourceTextPasteCandidate(sourceText));
        }
        if (text != null) candidates.add(BusyMarkPlainTextPasteCandidate(text));
    }
    if (candidates.isEmpty && snapshot.fromSystemClipboard && supportsImages) {
      candidates.add(const BusyMarkNativeImagePasteCandidate());
    }
    return BusyMarkPastePlan(List.unmodifiable(candidates));
  }
}

BusyMarkClipboardCapture busyMarkClipboardCaptureFromSnapshot(
  BusyMarkClipboardSnapshot snapshot, {
  Uint8List? imageBytes,
  String? imageMimeType,
  String? imageDisplayName,
}) {
  final retainedImageBytes = imageBytes ?? snapshot.imageBytes;
  final kind = retainedImageBytes != null && retainedImageBytes.isNotEmpty
      ? BusyMarkClipboardContentKind.image
      : snapshot.contentKind ??
            (snapshot.richFragment != null || snapshot.html != null
                ? BusyMarkClipboardContentKind.richText
                : BusyMarkClipboardContentKind.text);
  return BusyMarkClipboardCapture(
    kind: kind,
    text: snapshot.text,
    sourceText: snapshot.sourceText,
    html: snapshot.html,
    richFragment: snapshot.richFragment,
    imageBytes: retainedImageBytes,
    imageMimeType: imageMimeType ?? snapshot.imageMimeType,
    imageDisplayName: imageDisplayName ?? snapshot.imageDisplayName,
    origin: snapshot.origin,
    mediaBytes: snapshot.mediaBytes,
    mediaComplete: snapshot.mediaComplete,
    external: snapshot.external,
  );
}

bool hasUsableClipboardHtmlContent(WysiwygClipboardFragment fragment) =>
    fragment.documentBlocks.any(_hasUsableClipboardBlockContent);

bool _hasUsableClipboardBlockContent(BusyBlock block) {
  if (block.plainText.isNotEmpty ||
      block.kind == BusyBlockKind.image ||
      block.kind == BusyBlockKind.video ||
      block.kind == BusyBlockKind.thematicBreak ||
      block.kind == BusyBlockKind.table ||
      block.inlines.any(_hasUsableClipboardInlineContent)) {
    return true;
  }
  return block.children.any(_hasUsableClipboardBlockContent);
}

bool _hasUsableClipboardInlineContent(BusyInline inline) =>
    inline.kind == BusyInlineKind.image ||
    inline.children.any(_hasUsableClipboardInlineContent);

String? _available(String? value) =>
    value == null || value.isEmpty ? null : value;
