import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

import '../core/uri_utils.dart';

const maxRawHtmlDepth = 100;
const maxRawHtmlNodes = 5000;

const safeBlockHtmlTags = {
  'article',
  'aside',
  'div',
  'section',
  'header',
  'footer',
  'main',
  'nav',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'p',
  'blockquote',
  'address',
  'hr',
  'ul',
  'ol',
  'li',
  'dl',
  'dt',
  'dd',
  'table',
  'caption',
  'colgroup',
  'col',
  'thead',
  'tbody',
  'tfoot',
  'tr',
  'th',
  'td',
  'pre',
  'details',
  'summary',
  'figure',
  'figcaption',
};

const safeInlineHtmlTags = {
  'br',
  'span',
  'strong',
  'em',
  'b',
  'i',
  'u',
  's',
  'small',
  'mark',
  'sub',
  'sup',
  'code',
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
  'del',
  'ruby',
  'rt',
  'rp',
  'a',
  'img',
};

const safeHtmlTags = {...safeBlockHtmlTags, ...safeInlineHtmlTags};

const voidHtmlTags = {'br', 'hr', 'img', 'wbr', 'col'};

const unsafeHtmlTags = {
  'script',
  'style',
  'iframe',
  'object',
  'embed',
  'video',
  'applet',
  'canvas',
  'svg',
  'math',
  'form',
  'input',
  'button',
  'select',
  'option',
  'textarea',
  'label',
  'fieldset',
  'legend',
  'html',
  'head',
  'body',
  'base',
  'link',
  'meta',
  'title',
  'template',
  'slot',
  'noscript',
  'frame',
  'frameset',
  'noframes',
  'param',
  'xmp',
  'plaintext',
  'noembed',
};

const obsoleteHtmlTags = {
  'center',
  'font',
  'big',
  'tt',
  'strike',
  'acronym',
  'dir',
  'basefont',
  'menuitem',
};

const globalAllowedAttributes = {'id', 'class', 'title', 'lang', 'dir', 'role'};

const perTagAllowedAttributes = <String, Set<String>>{
  'a': {'href', 'title', 'target', 'rel'},
  'img': {'src', 'alt', 'title', 'width', 'height', 'loading'},
  'table': {'summary'},
  'th': {'colspan', 'rowspan', 'scope', 'align'},
  'td': {'colspan', 'rowspan', 'align'},
  'col': {'span'},
  'blockquote': {'cite'},
  'q': {'cite'},
  'ins': {'cite', 'datetime'},
  'del': {'cite', 'datetime'},
  'time': {'datetime'},
  'ol': {'start', 'reversed', 'type'},
  'li': {'value'},
  'code': {'class'},
  'pre': {'class'},
};

bool isSafeHtmlTag(String tag) {
  final normalized = _normalizeName(tag);
  return safeHtmlTags.contains(normalized) && !isUnsafeHtmlTag(normalized);
}

bool isUnsafeHtmlTag(String tag) {
  final normalized = _normalizeName(tag);
  return unsafeHtmlTags.contains(normalized) ||
      obsoleteHtmlTags.contains(normalized);
}

bool isSafeInlineHtmlTag(String tag) {
  return safeInlineHtmlTags.contains(_normalizeName(tag));
}

bool isSafeBlockHtmlTag(String tag) {
  return safeBlockHtmlTags.contains(_normalizeName(tag));
}

Map<String, String>? sanitizeHtmlAttributes(
  String tag,
  Map<Object, String> attributes,
) {
  final normalizedTag = _normalizeName(tag);
  final sanitized = <String, String>{};
  for (final entry in attributes.entries) {
    final name = _normalizeName(entry.key.toString());
    final value = entry.value;
    if (name.isEmpty) {
      continue;
    }
    if (name == 'style' || name.startsWith('on')) {
      return null;
    }
    if (!_isAllowedAttribute(normalizedTag, name)) {
      continue;
    }
    if (!_isSafeHtmlUrlAttribute(normalizedTag, name, value)) {
      return null;
    }
    sanitized[name] = value;
  }
  return sanitized;
}

bool isSafeHtmlUrlAttribute(String tag, String attribute, String value) {
  return _isSafeHtmlUrlAttribute(
    _normalizeName(tag),
    _normalizeName(attribute),
    value,
  );
}

bool hasUnsafeHtml(String content) {
  if (content.trim().isEmpty) {
    return false;
  }
  if (RegExp(
    r'(?<![A-Za-z0-9+.-])(?:java|vb)script\s*:',
    caseSensitive: false,
  ).hasMatch(content)) {
    return true;
  }
  if (RegExp(
    r'''\b(?:href|src|cite)\s*=\s*["']?\s*data\s*:''',
    caseSensitive: false,
  ).hasMatch(content)) {
    return true;
  }
  if (RegExp(
    r'\son[A-Za-z0-9_-]+\s*=',
    caseSensitive: false,
  ).hasMatch(content)) {
    return true;
  }
  for (final match in RegExp(
    r'</?\s*([A-Za-z][A-Za-z0-9_-]*)\b',
    caseSensitive: false,
  ).allMatches(content)) {
    final tag = match.group(1);
    if (tag != null && isUnsafeHtmlTag(tag)) {
      return true;
    }
  }
  try {
    final fragment = html_parser.parseFragment(content);
    return _hasUnsafeHtmlNode(fragment);
  } on Object {
    return true;
  }
}

bool _hasUnsafeHtmlNode(
  html.Node node, {
  int depth = 0,
  _HtmlWalkState? state,
}) {
  state ??= _HtmlWalkState();
  if (!state.visit(depth)) {
    return true;
  }
  if (node is html.Element) {
    final tag = node.localName?.toLowerCase() ?? '';
    if (isUnsafeHtmlTag(tag)) {
      return true;
    }
    if (isSafeHtmlTag(tag) &&
        sanitizeHtmlAttributes(tag, node.attributes) == null) {
      return true;
    }
  }
  for (final child in node.nodes) {
    if (_hasUnsafeHtmlNode(child, depth: depth + 1, state: state)) {
      return true;
    }
  }
  return false;
}

class _HtmlWalkState {
  var nodes = 0;

  bool visit(int depth) {
    if (depth > maxRawHtmlDepth || nodes >= maxRawHtmlNodes) {
      return false;
    }
    nodes += 1;
    return true;
  }
}

bool _isAllowedAttribute(String tag, String attribute) {
  return globalAllowedAttributes.contains(attribute) ||
      attribute.startsWith('aria-') ||
      attribute.startsWith('data-') ||
      (perTagAllowedAttributes[tag]?.contains(attribute) ?? false);
}

bool _isSafeHtmlUrlAttribute(String tag, String attribute, String value) {
  if (attribute != 'href' && attribute != 'src' && attribute != 'cite') {
    return true;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed)) {
    return false;
  }
  final compactForScheme = trimmed.replaceAll(RegExp(r'\s+'), '');
  final compactScheme = Uri.tryParse(compactForScheme)?.scheme.toLowerCase();
  if (compactScheme == 'javascript' ||
      compactScheme == 'vbscript' ||
      compactScheme == 'data' ||
      compactScheme == 'file') {
    return false;
  }
  if (trimmed.startsWith('#')) {
    return true;
  }
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) {
    return false;
  }
  final scheme = parsed.scheme.toLowerCase();
  if (scheme.isEmpty) {
    return !parsed.hasAuthority && _isSafeRelativeHtmlPath(parsed.path);
  }
  if (attribute == 'href') {
    return isLaunchableExternalUriScheme(scheme);
  }
  if (attribute == 'src' && tag == 'img') {
    return isRemoteResourceUriScheme(scheme);
  }
  return isRemoteResourceUriScheme(scheme);
}

bool _isSafeRelativeHtmlPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    return false;
  }
  return !p.posix.isAbsolute(path) &&
      !p.windows.isAbsolute(path) &&
      !path.startsWith('\\');
}

String _normalizeName(String name) => name.trim().toLowerCase();
