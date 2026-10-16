import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_search_field.dart';
import '../app/command_registry.dart';
import '../app/localization.dart';
import '../local_history/local_history_controller.dart';
import '../local_history/local_history_models.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../workspace/recent_navigation.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_glyphs.dart';
import 'search_activation.dart';
import 'search_option_button.dart';
import 'search_result_preview.dart';
import 'search_session.dart';

String searchCategoryLabel(BuildContext context, SearchCategory category) =>
    switch (category) {
      SearchCategory.file => context.l10n.searchInFile,
      SearchCategory.workspace => context.l10n.searchInWorkspace,
      SearchCategory.outline => context.l10n.outline,
      SearchCategory.documents => context.l10n.searchDocumentsCategory,
      SearchCategory.topics => context.l10n.searchTopicsCategory,
      SearchCategory.recent => context.l10n.recent,
      SearchCategory.localHistory => context.l10n.localHistory,
      SearchCategory.actions => context.l10n.actions,
    };

bool _resultBodyHasFocus() {
  var result = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is IconButton ||
        widget is BusyMarkCompactIconButton ||
        widget is BusyMarkMenuButton) {
      return false;
    }
    if (widget is SearchResultList) {
      result = true;
      return false;
    }
    return true;
  });
  return result;
}

/// The only query entry, mounted in the existing header on both routes.
class SearchHeaderField extends ConsumerStatefulWidget {
  const SearchHeaderField({super.key});
  @override
  ConsumerState<SearchHeaderField> createState() => _SearchHeaderFieldState();
}

class _SearchHeaderFieldState extends ConsumerState<SearchHeaderField> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchSessionProvider);
    if (_text.text != state.query) {
      _text.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }
    final controller = ref.read(searchSessionProvider.notifier);
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || _text.value.composing.isValid) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowUp) {
          controller.moveSelection(
            key == LogicalKeyboardKey.arrowDown ? 1 : -1,
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: BusyMarkSearchField(
        key: const ValueKey('shared-search-query'),
        controller: _text,
        hintText: state.fileActive || state.workspaceActive
            ? '${searchCategoryLabel(context, state.category)}…'
            : context.l10n.searchQueryHint(
                searchCategoryLabel(context, state.category),
              ),
        autofocus: state.active,
        focusRequest: state.focusRequest,
        clearOnEscape: false,
        onChanged: controller.query,
        onMoveSelection: controller.moveSelection,
        onClear: () => controller.query(''),
        onEscape: controller.close,
        onSubmitted: (_) =>
            unawaited(activateSelectedSearchResult(context, ref)),
      ),
    );
  }
}

/// Shared presentation; the outline is the application's existing renderer.
class SearchSidebar extends ConsumerWidget {
  const SearchSidebar({
    super.key,
    this.outline,
    this.onReviewReplacement,
    this.outlineOnly = false,
  });
  final Widget? outline;
  final bool outlineOnly;
  final Future<void> Function()? onReviewReplacement;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchSessionProvider);
    final browsingOutline =
        outline != null &&
        (outlineOnly ||
            !state.active ||
            state.category != SearchCategory.outline);
    if (!state.active && outline == null) return const SizedBox.shrink();
    final controller = ref.read(searchSessionProvider.notifier);
    final commands = BusyMarkCommandRegistryScope.maybeOf(context);
    if (commands != null) {
      controller.configureCommands([
        for (final c in commands.visibleCommands())
          ActionSearchResult(
            c,
            c.label(context),
            c.category(context),
            c.description?.call(context),
          ),
      ]);
    }
    final workspace = ref.watch(workspaceControllerProvider);
    final remote = workspace.workspace?.isRemote == true;
    final historyDocuments = state.category == SearchCategory.localHistory
        ? ref.watch(localHistoryControllerProvider).snapshot.documents
        : const <LocalHistoryDocument>[];
    final account = remote && state.workspaceActive
        ? ref.watch(nextcloudConnectionProvider).account
        : null;
    final historyDocument = historyDocuments
        .where((d) => d.id == state.historyDocumentId)
        .firstOrNull;
    final contextLabel = state.fileActive
        ? workspace.activeBuffer?.displayName
        : state.workspaceActive
        ? (state.recovery
              ? context.l10n.notesRecovery
              : remote
              ? (account?.id == workspace.workspace?.nextcloudAccountId
                    ? '${account!.loginName} · ${account.server.host}'
                    : workspace.workspace?.nextcloudAccountId)
              : workspace.workspace?.filesystemRootPath)
        : state.category == SearchCategory.localHistory
        ? historyDocument?.displayName ??
              (state.historyDocumentId != null
                  ? context.l10n.searchResourceUnavailable
                  : null)
        : null;
    return Focus(
      onKeyEvent: (_, event) {
        if (!state.active || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          controller.close();
          return KeyEventResult.handled;
        }
        if (!_resultBodyHasFocus()) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          controller.moveSelection(
            event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1,
          );
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          unawaited(activateSelectedSearchResult(context, ref));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!browsingOutline) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BusyMarkSpacing.sm,
                vertical: BusyMarkSpacing.xs,
              ),
              child: BusyMarkMenuButton<SearchCategory>(
                key: const ValueKey('search-category'),
                tooltip: context.l10n.searchCategory,
                fallbackMenuWidth: BusyMarkSizes.sidebarWidth,
                items: [
                  for (final category in controller.categories)
                    BusyMarkPopupMenuItem(
                      value: category,
                      label: searchCategoryLabel(context, category),
                      checked: category == state.category,
                      trailingCheck: true,
                    ),
                ],
                onSelected: (category) => controller.open(category: category),
                triggerBuilder: (context, trigger) => trigger.anchor(
                  child: Tooltip(
                    message: context.l10n.searchCategory,
                    child: Semantics(
                      label: context.l10n.searchCategory,
                      expanded: trigger.isOpen,
                      child: BusyMarkPushButton.standard(
                        focusNode: trigger.focusNode,
                        onPressed: trigger.onPressed,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                searchCategoryLabel(context, state.category),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: BusyMarkSpacing.xs),
                            const Icon(
                              BusyMarkGlyphs.downArrow,
                              size: BusyMarkSizes.iconSm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (contextLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: contextLabel,
                        child: Text(
                          contextLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    if (state.category == SearchCategory.localHistory &&
                        state.historyDocumentId != null)
                      BusyMarkCompactIconButton(
                        tooltip: context.l10n.clearHistorySearchScope,
                        icon: BusyMarkGlyphs.clear,
                        onPressed: controller.clearHistoryScope,
                      ),
                  ],
                ),
              ),
            if (state.textActive)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (state.fileActive || !remote)
                      SearchOptionButton(
                        label: 'Aa',
                        tooltip: context.l10n.sourceSearchCaseSensitive,
                        selected: state.caseSensitive,
                        onPressed: () => controller.set(
                          state.copyWith(caseSensitive: !state.caseSensitive),
                        ),
                      ),
                    SearchOptionButton(
                      label: 'W',
                      tooltip: context.l10n.sourceSearchWholeWord,
                      selected: state.wholeWord,
                      onPressed: () => controller.set(
                        state.copyWith(wholeWord: !state.wholeWord),
                      ),
                    ),
                    if (state.fileActive || !remote)
                      SearchOptionButton(
                        label: '.*',
                        tooltip: context.l10n.sourceSearchRegex,
                        selected: state.regex,
                        onPressed: () =>
                            controller.set(state.copyWith(regex: !state.regex)),
                      ),
                    if (remote && state.workspaceActive)
                      BusyMarkCompactIconButton(
                        tooltip: context.l10n.notesSearchHelp,
                        icon: BusyMarkGlyphs.info,
                        onPressed: null,
                      ),
                  ],
                ),
              ),
            if (!remote &&
                state.workspaceActive &&
                !state.recovery &&
                onReviewReplacement != null &&
                state.query.isNotEmpty &&
                !state.searching)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.sm,
                ),
                child: BusyMarkPushButton.standard(
                  onPressed: () => unawaited(onReviewReplacement!()),
                  child: Text(context.l10n.workspaceReplace),
                ),
              ),
            if (state.searching)
              const LinearProgressIndicator(
                key: ValueKey('workspace-search-progress'),
              ),
            if (state.indexing) _SearchNotice(context.l10n.notesIndexing),
            if (state.error != null) _SearchNotice(state.error!),
            if (state.invalidRegex)
              _SearchNotice(context.l10n.sourceSearchInvalidRegex),
            if (state.hasZeroLengthMatches)
              _SearchNotice(context.l10n.sourceSearchZeroLengthUnsupported),
            if (state.skippedFiles.isNotEmpty)
              Tooltip(
                message: state.skippedFiles.join('\n'),
                child: _SearchNotice(
                  '${context.l10n.workspaceSearchSkippedFiles} · ${state.skippedFiles.length}\n'
                  '${state.skippedFiles.join('\n')}',
                ),
              ),
            if (state.truncated)
              _SearchNotice(context.l10n.workspaceSearchIncomplete),
            if (state.truncated)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BusyMarkSpacing.sm,
                ),
                child: Tooltip(
                  message: context.l10n.workspaceSearchIncomplete,
                  child: TextButton(
                    onPressed: controller.showMore,
                    child: Text(context.l10n.workspaceSearchShowMore),
                  ),
                ),
              ),
          ],
          Expanded(
            child:
                outline ??
                (state.results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                          child: Text(
                            state.searching ||
                                    state.error != null ||
                                    state.skippedFiles.isNotEmpty ||
                                    state.invalidRegex ||
                                    state.hasZeroLengthMatches
                                ? ''
                                : state.textActive && state.query.isEmpty
                                ? context.l10n.searchQueryHint(
                                    searchCategoryLabel(
                                      context,
                                      state.category,
                                    ),
                                  )
                                : context.l10n.noResults,
                          ),
                        ),
                      )
                    : SearchResultList(
                        results: state.results,
                        selected: state.selected,
                        onActivate: (result) =>
                            activateSearchResult(context, ref, result),
                      )),
          ),
        ],
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: BusyMarkSpacing.md,
      vertical: BusyMarkSpacing.xs,
    ),
    child: Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class SearchResultList extends ConsumerStatefulWidget {
  const SearchResultList({
    super.key,
    required this.results,
    this.selected = -1,
    required this.onActivate,
  });
  final List<SidebarSearchResult> results;
  final int selected;
  final Future<void> Function(SidebarSearchResult) onActivate;
  @override
  ConsumerState<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends ConsumerState<SearchResultList> {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  final _focusNodes = <int, FocusNode>{};
  @override
  void initState() {
    super.initState();
    final selected = widget.selected;
    final results = widget.results;
    if (selected >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_reveal(selected, results, restoreFocus: false));
      });
    }
  }

  @override
  void didUpdateWidget(covariant SearchResultList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.results, widget.results)) _keys.clear();
    if (widget.selected >= 0 &&
        (oldWidget.selected != widget.selected ||
            !identical(oldWidget.results, widget.results))) {
      final index = widget.selected;
      final results = widget.results;
      final restoreFocus = _resultBodyHasFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_reveal(index, results, restoreFocus: restoreFocus));
      });
    }
  }

  Future<void> _reveal(
    int index,
    List<SidebarSearchResult> results, {
    required bool restoreFocus,
  }) async {
    // Rows wrap and follow text scaling. Advance by actual viewports until the
    // lazy row mounts, then reveal its measured geometry rather than guessing
    // its offset from an assumed fixed row height.
    while (mounted &&
        _scroll.hasClients &&
        widget.selected == index &&
        identical(widget.results, results)) {
      final target = _keys[index]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: .5,
          duration: const Duration(milliseconds: 80),
        );
        if (restoreFocus &&
            mounted &&
            widget.selected == index &&
            identical(widget.results, results)) {
          _focusNodes[index]?.requestFocus();
        }
        return;
      }
      final mountedRows = _keys.entries.where(
        (entry) => entry.value.currentContext != null,
      );
      final before = mountedRows.isNotEmpty && index < mountedRows.first.key;
      final position = _scroll.position;
      final offset =
          (position.pixels + position.viewportDimension * (before ? -.8 : .8))
              .clamp(0.0, position.maxScrollExtent);
      if (offset == position.pixels) return;
      _scroll.jumpTo(offset);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.results;
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: ListView.builder(
        key: const ValueKey('sidebar-search-results'),
        controller: _scroll,
        padding: BusyMarkInsets.sidebarList,
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final result = rows[index];
          final (title, subtitle, shortcut) = switch (result) {
            TextSearchResult(:final match) => (
              searchResultTitle(context, match.lineText ?? ''),
              context.l10n.searchResultLine(match.relativePath, match.line),
              null,
            ),
            NoteSearchResult(:final hit) => (
              hit.title,
              '${hit.category}\n${hit.snippet}',
              null,
            ),
            DocumentSearchResult(:final document) => (
              document.title,
              document.path,
              null,
            ),
            TopicSearchResult(
              :final title,
              :final topicId,
              :final module,
              :final relativePath,
            ) =>
              (title, '$module · $topicId\n$relativePath', null),
            RecentSearchResult(:final resource) => (
              resource.title ??
                  (resource.accountId != null
                      ? context.l10n.nextcloudNotes
                      : p.basename(resource.path)),
              resource.accountId == null
                  ? '${resource.ownerRoot == null ? '' : '${resource.ownerRoot}\n'}${resource.path}'
                  : '${resource.accountLabel ?? resource.accountId}${resource.localId == null ? '' : ' · ${resource.localId}'}',
              null,
            ),
            HistorySearchResult(:final match) => (
              match.document.displayName,
              '${match is LocalHistoryRevisionMatch ? DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).add_Hms().format(match.revision.capturedAt.toLocal()) : context.l10n.localHistory}\n'
                  '${match is LocalHistoryRevisionMatch ? match.revision.historicalPath ?? '' : match.document.currentPath ?? match.document.historicalPaths.lastOrNull ?? ''}'
                  '${match.document.remoteNote == null ? '' : '\n${match.document.remoteNote!.accountId} · ${match.document.remoteNote!.localId}'}',
              null,
            ),
            ActionSearchResult(:final title, :final category, :final command) =>
              (
                title,
                actionEnabled(ref, result)
                    ? category
                    : command.disabledReason?.call(context) ??
                          context.l10n.commandUnavailableInContext,
                command.shortcut?.label,
              ),
          };
          final enabled =
              result is! ActionSearchResult || actionEnabled(ref, result);
          final selected =
              widget.selected >= 0 &&
              widget.selected < widget.results.length &&
              widget.results[widget.selected].identity == result.identity;
          final key = result is NoteSearchResult
              ? ValueKey((
                  'notes-search-hit',
                  result.hit.localId,
                  result.hit.start,
                  result.hit.end,
                ))
              : ValueKey(result.identity);
          final row = ListTile(
            key: key,
            selected: selected,
            enabled: enabled,
            focusNode: _focusNodes.putIfAbsent(index, FocusNode.new),
            onFocusChange: (focused) {
              if (focused &&
                  widget.selected >= 0 &&
                  ref.read(searchSessionProvider).active) {
                ref.read(searchSessionProvider.notifier).select(index);
              }
            },
            selectedTileColor: Color.alphaBlend(colors.control, colors.sidebar),
            contentPadding: BusyMarkInsets.searchResultRow,
            title: Text(title, maxLines: 3, overflow: TextOverflow.ellipsis),
            subtitle: Tooltip(
              key: _keys.putIfAbsent(index, GlobalKey.new),
              message: '$title\n$subtitle',
              child: Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: result is RecentSearchResult
                ? IconButton(
                    tooltip: context.l10n.removeFromRecent,
                    icon: const Icon(BusyMarkGlyphs.clear),
                    onPressed: () => unawaited(
                      ref
                          .read(appSettingsControllerProvider.notifier)
                          .removeRecentWorkspace(result.resource.identity),
                    ),
                  )
                : result is NoteSearchResult &&
                      !result.recovery &&
                      result.hit.start != null
                ? IconButton(
                    tooltip: context.l10n.notesSourceLocation,
                    icon: const Icon(BusyMarkGlyphs.code),
                    onPressed: () => unawaited(
                      activateSearchResult(context, ref, result, source: true),
                    ),
                  )
                : shortcut == null
                ? null
                : Text(shortcut, style: Theme.of(context).textTheme.labelSmall),
            onTap: enabled ? () => unawaited(widget.onActivate(result)) : null,
          );
          if (result is RecentSearchResult) {
            final resource = result.resource;
            final record = BusyMarkSidebarRecordRow<RecentNavigationAction>(
              key: key,
              icon: WorkspaceGlyphs.forRecent(resource),
              selected: selected,
              content: Tooltip(
                key: _keys.putIfAbsent(index, GlobalKey.new),
                message: '$title\n$subtitle',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 3, overflow: TextOverflow.ellipsis),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              onTap: () => unawaited(widget.onActivate(result)),
              menuTooltip: context.l10n.actions,
              menuItemsBuilder: (context) =>
                  _recentMenuItems(context, resource),
              onMenuSelected: (action) => unawaited(
                runRecentNavigationAction(context, ref, resource, action),
              ),
            );
            final focusable = Focus(
              focusNode: _focusNodes.putIfAbsent(index, FocusNode.new),
              onFocusChange: (focused) {
                if (focused &&
                    widget.selected >= 0 &&
                    ref.read(searchSessionProvider).active) {
                  ref.read(searchSessionProvider.notifier).select(index);
                }
              },
              child: record,
            );
            return focusable;
          }
          return row;
        },
      ),
    );
  }
}

List<PopupMenuEntry<RecentNavigationAction>> _recentMenuItems(
  BuildContext context,
  RecentResource resource,
) => [
  if (resource.accountId == null) ...[
    BusyMarkPopupMenuItem(
      value: RecentNavigationAction.openInFiles,
      label: context.l10n.openInFiles,
      icon: BusyMarkGlyphs.folderOpen,
    ),
    BusyMarkPopupMenuItem(
      value: RecentNavigationAction.copyPath,
      label: context.l10n.copyPath,
      icon: BusyMarkGlyphs.copy,
    ),
  ],
  BusyMarkPopupMenuItem(
    value: RecentNavigationAction.removeFromRecent,
    label: context.l10n.removeFromRecent,
    icon: BusyMarkGlyphs.clear,
  ),
];
