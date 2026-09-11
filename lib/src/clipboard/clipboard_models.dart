import 'dart:convert';
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

enum BusyMarkClipboardContentKind { text, richText, image }

@immutable
class BusyMarkClipboardOrigin {
  const BusyMarkClipboardOrigin({
    required this.documentId,
    required this.documentName,
    this.documentPath,
  });

  final String documentId;
  final String documentName;
  final String? documentPath;
}

/// An immutable, source-independent clipboard snapshot.
///
/// [sourceText] is the representation inserted into Source mode. [text] is
/// the interoperable plain-text representation. A rich fragment is an opaque,
/// validated BusyMark schema and is never reconstructed from plain-text
/// equality.
@immutable
class BusyMarkClipboardPayload {
  BusyMarkClipboardPayload({
    required this.id,
    required this.acquiredAt,
    required this.kind,
    this.text,
    this.sourceText,
    this.html,
    this.richFragment,
    Uint8List? imageBytes,
    this.imageMimeType,
    this.imageDisplayName,
    this.imageWidth,
    this.imageHeight,
    this.origin,
    Map<String, Uint8List> mediaBytes = const {},
    this.mediaComplete = true,
    this.external = false,
  }) : imageBytes = imageBytes == null ? null : Uint8List.fromList(imageBytes),
       mediaBytes = Map.unmodifiable({
         for (final entry in mediaBytes.entries)
           entry.key: Uint8List.fromList(entry.value),
       }),
       fingerprint = _fingerprint(
         kind: kind,
         text: text,
         sourceText: sourceText,
         html: html,
         richFragment: richFragment,
         imageBytes: imageBytes,
         imageMimeType: imageMimeType,
         imageDisplayName: imageDisplayName,
         imageWidth: imageWidth,
         imageHeight: imageHeight,
         origin: origin,
         mediaBytes: mediaBytes,
         mediaComplete: mediaComplete,
       ),
       accountedBytes = _accountedBytes(
         text: text,
         sourceText: sourceText,
         html: html,
         richFragment: richFragment,
         imageBytes: imageBytes,
         imageMimeType: imageMimeType,
         imageDisplayName: imageDisplayName,
         imageWidth: imageWidth,
         imageHeight: imageHeight,
         origin: origin,
         mediaBytes: mediaBytes,
       );

  final String id;
  final DateTime acquiredAt;
  final BusyMarkClipboardContentKind kind;
  final String? text;
  final String? sourceText;
  final String? html;
  final String? richFragment;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final String? imageDisplayName;
  final int? imageWidth;
  final int? imageHeight;
  final BusyMarkClipboardOrigin? origin;
  final Map<String, Uint8List> mediaBytes;
  final bool mediaComplete;
  final bool external;
  final String fingerprint;
  final int accountedBytes;

  bool get hasMeaningfulTextRepresentation =>
      sourceText != null || text != null;

  String? get preferredSourceText => sourceText ?? text;

  bool equivalentTo(BusyMarkClipboardPayload other) =>
      fingerprint == other.fingerprint &&
      kind == other.kind &&
      text == other.text &&
      sourceText == other.sourceText &&
      html == other.html &&
      richFragment == other.richFragment &&
      imageMimeType == other.imageMimeType &&
      imageDisplayName == other.imageDisplayName &&
      imageWidth == other.imageWidth &&
      imageHeight == other.imageHeight &&
      origin?.documentId == other.origin?.documentId &&
      origin?.documentPath == other.origin?.documentPath &&
      mediaComplete == other.mediaComplete &&
      _sameMediaBytes(mediaBytes, other.mediaBytes) &&
      listEquals(imageBytes, other.imageBytes);

  static String _fingerprint({
    required BusyMarkClipboardContentKind kind,
    required String? text,
    required String? sourceText,
    required String? html,
    required String? richFragment,
    required Uint8List? imageBytes,
    required String? imageMimeType,
    required String? imageDisplayName,
    required int? imageWidth,
    required int? imageHeight,
    required BusyMarkClipboardOrigin? origin,
    required Map<String, Uint8List> mediaBytes,
    required bool mediaComplete,
  }) {
    final bytes = BytesBuilder(copy: false);
    void addText(String label, String? value) {
      bytes.add(utf8.encode('$label\u0000${value ?? ''}\u0000'));
    }

    addText('kind', kind.name);
    addText('text', text);
    addText('source', sourceText);
    addText('html', html);
    addText('fragment', richFragment);
    addText('mime', imageMimeType);
    addText('name', imageDisplayName);
    addText('width', imageWidth?.toString());
    addText('height', imageHeight?.toString());
    addText('origin-document', origin?.documentId);
    addText('origin-path', origin?.documentPath);
    addText('media-complete', mediaComplete.toString());
    final mediaKeys = mediaBytes.keys.toList()..sort();
    for (final key in mediaKeys) {
      addText('media-key', key);
      bytes.add(mediaBytes[key]!);
    }
    if (imageBytes != null) bytes.add(imageBytes);
    return sha256.convert(bytes.takeBytes()).toString();
  }

  static int _accountedBytes({
    required String? text,
    required String? sourceText,
    required String? html,
    required String? richFragment,
    required Uint8List? imageBytes,
    required String? imageMimeType,
    required String? imageDisplayName,
    required int? imageWidth,
    required int? imageHeight,
    required BusyMarkClipboardOrigin? origin,
    required Map<String, Uint8List> mediaBytes,
  }) {
    var result = imageBytes?.lengthInBytes ?? 0;
    for (final value in [
      text,
      sourceText,
      html,
      richFragment,
      imageMimeType,
      imageDisplayName,
      imageWidth?.toString(),
      imageHeight?.toString(),
      origin?.documentId,
      origin?.documentName,
      origin?.documentPath,
    ]) {
      if (value != null) result += utf8.encode(value).length;
    }
    for (final entry in mediaBytes.entries) {
      result += utf8.encode(entry.key).length + entry.value.lengthInBytes;
    }
    return result;
  }
}

@immutable
class BusyMarkClipboardCapture {
  const BusyMarkClipboardCapture({
    required this.kind,
    this.text,
    this.sourceText,
    this.html,
    this.richFragment,
    this.imageBytes,
    this.imageMimeType,
    this.imageDisplayName,
    this.imageWidth,
    this.imageHeight,
    this.origin,
    this.mediaBytes = const {},
    this.mediaComplete = true,
    this.external = false,
  });

  final BusyMarkClipboardContentKind kind;
  final String? text;
  final String? sourceText;
  final String? html;
  final String? richFragment;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final String? imageDisplayName;
  final int? imageWidth;
  final int? imageHeight;
  final BusyMarkClipboardOrigin? origin;
  final Map<String, Uint8List> mediaBytes;
  final bool mediaComplete;
  final bool external;

  bool get isSupported => switch (kind) {
    BusyMarkClipboardContentKind.text => text != null || sourceText != null,
    BusyMarkClipboardContentKind.richText =>
      mediaComplete &&
          (richFragment != null ||
              html != null ||
              sourceText != null ||
              text != null),
    BusyMarkClipboardContentKind.image =>
      imageBytes != null && imageBytes!.isNotEmpty,
  };
}

bool _sameMediaBytes(
  Map<String, Uint8List> left,
  Map<String, Uint8List> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!listEquals(entry.value, right[entry.key])) return false;
  }
  return true;
}

@immutable
class ClipboardHistoryPolicy {
  const ClipboardHistoryPolicy({
    this.maximumEntries = 100,
    this.maximumBytes = 64 * 1024 * 1024,
    this.maximumThumbnailBytes = 8 * 1024 * 1024,
  }) : assert(maximumEntries > 0),
       assert(maximumBytes > 0),
       assert(maximumThumbnailBytes > 0);

  final int maximumEntries;
  final int maximumBytes;
  final int maximumThumbnailBytes;
}

enum ClipboardRetentionResult { retained, deduplicated, disabled, oversized }

enum ClipboardPasteResult { inserted, staleTarget, unsupported, unavailable }
