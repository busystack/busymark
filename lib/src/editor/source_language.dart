enum SourceSyntaxLanguage { markdown, xml, plain }

SourceSyntaxLanguage sourceSyntaxLanguageForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
    return SourceSyntaxLanguage.markdown;
  }
  if (lower.endsWith('.xml') ||
      lower.endsWith('.tree') ||
      lower.endsWith('.cfg')) {
    return SourceSyntaxLanguage.xml;
  }
  return SourceSyntaxLanguage.plain;
}
