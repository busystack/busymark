import 'package:flutter/widgets.dart';
import '../app/localization.dart';
import '../editor/source/source_search.dart';
import 'workspace_text_search.dart';

String stripMarkdownForSearchResult(String line, {BuildContext? context}) {
  // Preview navigation also calls this helper directly with source lines.
  var value = boundedSearchSnippet(line).trim();
  final fence = RegExp(
    r'^(```+|~~~+)\s*([A-Za-z0-9_+\-#.]*)',
  ).firstMatch(value);
  if (fence != null) {
    final language = fence.group(2)?.trim() ?? '';
    return language.isEmpty
        ? context?.l10n.codeBlock ?? 'code block'
        : language;
  }

  value = value
      .replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}>\s?'), '')
      .replaceFirst(RegExp(r'^\s{0,3}[-+*]\s+\[[ xX]\]\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}[-+*]\s+'), '')
      .replaceFirst(RegExp(r'^\s{0,3}\d+[.)]\s+'), '')
      .trim();
  final replacements = <RegExp, String Function(Match)>{
    RegExp(r'!\[([^\]]*)\]\([^)]+\)'): (match) => match.group(1) ?? '',
    RegExp(r'\[([^\]]+)\]\([^)]+\)'): (match) => match.group(1) ?? '',
    RegExp(r'\[([^\]]+)\]\[[^\]]*\]'): (match) => match.group(1) ?? '',
    RegExp(r'`([^`]*)`'): (match) => match.group(1) ?? '',
    RegExp(r'\*\*([^*]+)\*\*'): (match) => match.group(1) ?? '',
    RegExp(r'__([^_]+)__'): (match) => match.group(1) ?? '',
    RegExp(r'\*([^*]+)\*'): (match) => match.group(1) ?? '',
    RegExp(r'_([^_]+)_'): (match) => match.group(1) ?? '',
    RegExp(r'~~([^~]+)~~'): (match) => match.group(1) ?? '',
    RegExp(r'<[^>]+>'): (_) => '',
  };
  for (final entry in replacements.entries) {
    value = value.replaceAllMapped(entry.key, entry.value);
  }
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return value.isEmpty
      ? context?.l10n.untitledResult ?? 'untitled result'
      : value;
}

String searchResultTitle(BuildContext context, String line) {
  final trimmed = stripMarkdownForSearchResult(line, context: context);
  if (trimmed.length <= 120) {
    return trimmed;
  }
  var end = 117;
  if (!sourceSearchRangeHasSafeBoundaries(trimmed, end, end)) end--;
  return '${trimmed.substring(0, end)}...';
}
