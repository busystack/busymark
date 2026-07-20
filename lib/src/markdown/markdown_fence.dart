class MarkdownFence {
  const MarkdownFence._({required this.marker, required this.info});

  static final RegExp _pattern = RegExp(
    r'^ {0,3}(?:(`{3,})([^`]*)|(~{3,})(.*))$',
  );

  final String marker;
  final String info;

  static MarkdownFence? parse(String line) {
    final match = _pattern.firstMatch(line);
    if (match == null) {
      return null;
    }
    return MarkdownFence._(
      marker: match.group(1) ?? match.group(3)!,
      info: match.group(2) ?? match.group(4) ?? '',
    );
  }

  String? get language {
    final normalized = info.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized.split(RegExp(r'[ \t]+')).first;
  }

  bool closes(String line) {
    final candidate = parse(line);
    return candidate != null &&
        candidate.info.trim().isEmpty &&
        candidate.marker.codeUnitAt(0) == marker.codeUnitAt(0) &&
        candidate.marker.length >= marker.length;
  }
}
