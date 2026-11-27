import 'package:html/dom.dart' as html;

import '../core/source_span.dart';
import 'raw_html_policy.dart';

/// The path portion of a document-relative audio reference belongs to the
/// provider. Query and fragment components remain part of the authored URL.
String busyMarkAudioResourcePath(String reference) {
  final uri = Uri.tryParse(reference);
  if (uri == null ||
      uri.hasAuthority ||
      uri.hasScheme && uri.scheme != 'busymark-attachment') {
    return reference;
  }
  final suffix = reference.indexOf(RegExp(r'[?#]'));
  return suffix < 0 ? reference : reference.substring(0, suffix);
}

/// The authored media description shared by Editor, Preview and export.
class BusyAudio {
  BusyAudio({
    required Map<String, String> attributes,
    required Iterable<BusyAudioSource> sources,
    required this.rawSource,
    this.directSource,
    this.sourceSpan,
  }) : attributes = Map.unmodifiable(attributes),
       sources = List.unmodifiable(sources);

  static BusyAudio fromHtml(html.Element element) {
    final opening = element.sourceSpan;
    final closing = element.endSourceSpan;
    final source = opening?.file.getText(0);
    SourceSpan? span(int? start, int? end) =>
        source == null || start == null || end == null
        ? null
        : SourceSpan.fromOffsets(
            filePath: '',
            source: source,
            startOffset: start,
            endOffset: end,
          );

    BusyAudioSource? readSource(html.Element node, Map<String, String> attrs) {
      final destination = attrs['src'];
      if (destination == null) return null;
      final location = node.attributeValueSpans?['src'];
      return BusyAudioSource(
        destination: destination,
        type: attrs['type'],
        sourceSpan: span(location?.start.offset, location?.end.offset),
      );
    }

    final attributes = sanitizeHtmlAttributes('audio', element.attributes)!;
    final start = opening?.start.offset;
    final end = closing?.end.offset;
    return BusyAudio(
      attributes: attributes,
      directSource: readSource(element, attributes),
      sources: [
        for (final child in element.children)
          if (child.localName == 'source')
            if (readSource(
                  child,
                  sanitizeHtmlAttributes('source', child.attributes)!,
                )
                case final item?)
              item,
      ],
      rawSource: source != null && start != null && end != null
          ? source.substring(start, end)
          : element.outerHtml,
      sourceSpan: span(start, end),
    );
  }

  final Map<String, String> attributes;
  final BusyAudioSource? directSource;
  final List<BusyAudioSource> sources;
  final String rawSource;
  final SourceSpan? sourceSpan;

  List<BusyAudioSource> get playbackSources => switch (directSource) {
    final source? => [source],
    null => sources,
  };

  Iterable<BusyAudioSource> get authoredSources sync* {
    if (directSource case final source?) yield source;
    yield* sources;
  }

  bool get controls => attributes.containsKey('controls');
  bool get loop => attributes.containsKey('loop');
  bool get muted => attributes.containsKey('muted');
  bool get autoplay => attributes.containsKey('autoplay');

  String? get accessibleName => attributes['aria-label'] ?? attributes['title'];
}

class BusyAudioSource {
  const BusyAudioSource({
    required this.destination,
    this.type,
    this.sourceSpan,
  });

  final String destination;
  final String? type;

  /// The URL value without its surrounding quote characters.
  final SourceSpan? sourceSpan;
}
