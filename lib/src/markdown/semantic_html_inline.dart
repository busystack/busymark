import 'package:html/dom.dart' as dom;

import 'busymark_document.dart';
import 'raw_html_policy.dart';

/// These elements have inline semantics that Markdown cannot express.
const semanticHtmlInlineTags = {
  'small',
  'mark',
  'sub',
  'sup',
  'kbd',
  'samp',
  'var',
  'abbr',
  'cite',
  'q',
  'dfn',
  'time',
  'data',
  'bdi',
  'bdo',
  'wbr',
  'ins',
  'ruby',
  'rt',
  'rp',
};

/// Creates the sanitized wrapper for modeled inline HTML. Each destination
/// supplies its own children so it can apply its normal reference policy.
dom.Element? semanticHtmlInlineElement(BusyInline inline) {
  if (inline.kind != BusyInlineKind.html) return null;
  final tag = semanticHtmlInlineTag(inline.attributes);
  if (tag == null) return null;
  final attributes = sanitizeHtmlAttributes(tag, inline.attributes);
  return dom.Element.tag(tag)..attributes.addAll(attributes ?? const {});
}

String? semanticHtmlInlineTag(Map<String, String> attributes) {
  final tag = attributes['htmlTag'];
  return tag == 'span' || semanticHtmlInlineTags.contains(tag) ? tag : null;
}
