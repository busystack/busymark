import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;

import '../app/localization.dart';
import '../app/app_settings.dart';
import '../local_history/local_history_models.dart';
import '../workspace/recent_presentation.dart';
import 'search_result_preview.dart';
import 'search_session.dart';

/// Display projections never change the metadata used for activation or matching.
class SearchResultPresentation {
  const SearchResultPresentation(
    this.title,
    this.subtitle, {
    this.shortcut,
    this.details,
  });
  final String title, subtitle;
  final String? shortcut, details;
}

SearchResultPresentation presentSearchResult(
  BuildContext context,
  SidebarSearchResult result, {
  String? Function(String accountId)? accountLabel,
  Iterable<RecentResource> recentResources = const [],
  String? workspaceRoot,
}) {
  String account(String id) =>
      accountLabel?.call(id) ?? context.l10n.searchAccountUnavailable;
  String location(String path, String title) {
    if (p.basename(path) == title ||
        p.basenameWithoutExtension(path) == title) {
      final parent = p.dirname(path);
      return parent == '.' ? '' : parent;
    }
    return path;
  }

  return switch (result) {
    TextSearchResult(:final match) => SearchResultPresentation(
      searchResultTitle(context, match.lineText ?? ''),
      context.l10n.searchResultLine(match.relativePath, match.line),
    ),
    NoteSearchResult(:final hit, :final accountId) => SearchResultPresentation(
      hit.snippet.isEmpty ? hit.title : hit.snippet,
      [
        hit.title,
        if (hit.category.isNotEmpty) hit.category,
        account(accountId),
      ].join(' · '),
    ),
    DocumentSearchResult(:final document, :final accountId) =>
      SearchResultPresentation(
        accountId == null ? p.basename(document.path) : document.title,
        accountId == null
            ? location(document.path, p.basename(document.path))
            : [
                if (document.path.isNotEmpty) document.path,
                account(accountId),
              ].join(' · '),
        details: accountId == null ? document.filePath ?? document.path : null,
      ),
    TopicSearchResult(
      :final title,
      :final module,
      :final topicId,
      :final relativePath,
    ) =>
      SearchResultPresentation(
        title,
        [
          module,
          if (topicId != p.basenameWithoutExtension(relativePath)) topicId,
          location(relativePath, title),
        ].where((s) => s.isNotEmpty).toSet().join(' · '),
        details: relativePath,
      ),
    RecentSearchResult(:final resource) => SearchResultPresentation(
      recentResourceTitle(context, resource),
      recentResourceLocation(
        context,
        resource,
        recentResources: recentResources,
        workspaceRoot: workspaceRoot,
        accountLabel: resource.accountId == null
            ? null
            : accountLabel?.call(resource.accountId!),
      ),
      details: resource.accountId == null
          ? resource.path
          : recentResourceLocation(
              context,
              resource,
              accountLabel: accountLabel?.call(resource.accountId!),
            ),
    ),
    OutlineSearchResult(
      :final heading,
      :final ancestors,
      :final documentName,
    ) =>
      SearchResultPresentation(
        heading.text,
        [
          context.l10n.headingLevelAbbreviation(heading.level),
          if (ancestors.isNotEmpty) ancestors.join(' › ') else documentName,
        ].join(' · '),
      ),
    HistorySearchResult(:final match) => SearchResultPresentation(
      match.document.displayName,
      [
        if (match is LocalHistoryRevisionMatch)
          DateFormat.yMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_Hms().format(match.revision.capturedAt.toLocal()),
        if (match.document.remoteNote != null)
          account(match.document.remoteNote!.accountId)
        else
          location(
            match is LocalHistoryRevisionMatch
                ? match.revision.historicalPath ?? ''
                : match.document.currentPath ??
                      match.document.historicalPaths.lastOrNull ??
                      '',
            match.document.displayName,
          ),
      ].where((s) => s.isNotEmpty).join(' · '),
    ),
    ActionSearchResult(
      :final title,
      :final category,
      :final command,
      :final enabled,
      :final disabledReason,
    ) =>
      SearchResultPresentation(
        title,
        enabled
            ? category
            : '$category · ${disabledReason ?? context.l10n.commandUnavailableInContext}',
        shortcut: command.shortcut?.label,
      ),
  };
}
