import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'search_result_presentation.dart';
import 'search_action_availability.dart';
import 'search_session.dart';

String searchCategoryLabel(BuildContext context, SearchCategory category) =>
    switch (category) {
      SearchCategory.file => context.l10n.searchInDocument,
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
        hintText: switch (state.category) {
          SearchCategory.file => context.l10n.searchDocumentHint,
          SearchCategory.workspace => context.l10n.searchWorkspaceHint,
          SearchCategory.outline => context.l10n.searchOutlineHint,
          SearchCategory.documents => context.l10n.searchDocumentsHint,
          SearchCategory.topics => context.l10n.searchTopicsHint,
          SearchCategory.recent => context.l10n.searchRecentHint,
          SearchCategory.localHistory => context.l10n.searchHistoryHint,
          SearchCategory.actions => context.l10n.searchActionsHint,
        },
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

/// One lazy result surface, shared by all categories and both application routes.
class SearchSidebar extends ConsumerWidget {
  const SearchSidebar({super.key, this.onReviewReplacement});
  final Future<void> Function()? onReviewReplacement;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchSessionProvider);
    if (!state.active) return const SizedBox.shrink();
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
            enabled: searchActionEnabled(
              commands,
              c,
              controller,
              ref.read(workspaceControllerProvider),
            ),
            disabledReason:
                {
                      BusyMarkCommandIds.syncNotes,
                      BusyMarkCommandIds.exportNotes,
                      BusyMarkCommandIds.importNotesFolder,
                      BusyMarkCommandIds.importNotesFile,
                    }.contains(c.id) &&
                    ref.read(workspaceControllerProvider).workspace?.isRemote !=
                        true
                ? context.l10n.searchRequiresNotesWorkspace
                : c.disabledReason?.call(context),
          ),
      ]);
    }
    final workspace = ref.watch(workspaceControllerProvider);
    final remote = workspace.workspace?.isRemote == true;
    final historyDocuments =
        state.category == SearchCategory.localHistory &&
            state.historyDocumentId != null
        ? ref.watch(localHistoryControllerProvider).snapshot.documents
        : const <LocalHistoryDocument>[];
    final container = ProviderScope.containerOf(context, listen: false);
    final accountId = workspace.workspace?.nextcloudAccountId;
    final activeAccount =
        remote && container.exists(nextcloudConnectionProvider)
        ? ref.watch(nextcloudConnectionProvider).account
        : null;
    final cachedAccount =
        remote && container.exists(nextcloudNotesRepositoryProvider)
        ? ref
              .watch(nextcloudNotesRepositoryProvider)
              .value
              ?.accountById(accountId ?? '')
        : null;
    final account = activeAccount?.id == accountId
        ? activeAccount
        : cachedAccount;
    final historyDocument = state.historyDocumentId == null
        ? null
        : historyDocuments
              .where((d) => d.id == state.historyDocumentId)
              .firstOrNull;
    final contextLabel =
        state.fileActive || state.category == SearchCategory.outline
        ? workspace.activeBuffer?.displayName
        : state.workspaceActive ||
              state.category == SearchCategory.documents ||
              state.category == SearchCategory.topics
        ? (state.recovery
              ? context.l10n.notesRecovery
              : remote
              ? (account?.id == workspace.workspace?.nextcloudAccountId
                    ? '${account!.loginName} · ${account.server.host}'
                    : context.l10n.searchAccountUnavailable)
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
          if (remote && state.workspaceActive)
            _SearchNotice(context.l10n.notesSearchHelp),
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
          Expanded(
            child: (state.results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                      child: Text(
                        state.searching ||
                                state.error != null ||
                                state.skippedFiles.isNotEmpty
                            ? ''
                            : state.waitingForInput
                            ? context.l10n.searchEnterText
                            : state.showingInitialList
                            ? (state.category == SearchCategory.recent
                                  ? context.l10n.searchRecentEmpty
                                  : context.l10n.commandUnavailableInContext)
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
  final _focusNodes = <String, FocusNode>{};
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
    if (!identical(oldWidget.results, widget.results)) {
      _keys.clear();
      final retained = {for (final result in widget.results) result.identity};
      final obsolete = [
        for (final id in _focusNodes.keys)
          if (!retained.contains(id)) id,
      ];
      final released = [for (final id in obsolete) _focusNodes.remove(id)!];
      // Old lazy rows detach this frame. Keep focus by resource identity when
      // availability reorders Actions; release handles for discarded pages.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in released) {
          node.dispose();
        }
      });
    }
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
          _focusNodes[results[index].identity]?.requestFocus();
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
    final container = ProviderScope.containerOf(context, listen: false);
    final activeAccount = container.exists(nextcloudConnectionProvider)
        ? ref.watch(nextcloudConnectionProvider).account
        : null;
    final cachedAccounts = container.exists(nextcloudNotesRepositoryProvider)
        ? ref.watch(nextcloudNotesRepositoryProvider).value?.accounts
        : null;
    final accountLabels = <String, String>{
      for (final account in cachedAccounts ?? [])
        account.id: '${account.loginName} · ${account.server.host}',
      if (activeAccount != null)
        activeAccount.id:
            '${activeAccount.loginName} · ${activeAccount.server.host}',
    };
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: ListView.builder(
        key: const ValueKey('sidebar-search-results'),
        controller: _scroll,
        padding: BusyMarkInsets.sidebarList,
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final result = rows[index];
          final presentation = presentSearchResult(
            context,
            result,
            accountLabel: (id) => accountLabels[id],
          );
          final title = presentation.title, subtitle = presentation.subtitle;
          final shortcut = presentation.shortcut;
          final enabled = result is! ActionSearchResult || result.enabled;
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
          return BusyMarkSidebarRecordRow<RecentNavigationAction>(
            key: key,
            icon: result is RecentSearchResult
                ? WorkspaceGlyphs.forRecent(result.resource)
                : result is ActionSearchResult
                ? BusyMarkGlyphs.keyboard
                : result is OutlineSearchResult
                ? BusyMarkGlyphs.tag
                : result is HistorySearchResult
                ? BusyMarkGlyphs.history
                : BusyMarkGlyphs.document,
            selected: selected,
            compact: true,
            focusNode: _focusNodes.putIfAbsent(result.identity, FocusNode.new),
            onFocusChange: (focused) {
              if (focused &&
                  widget.selected >= 0 &&
                  ref.read(searchSessionProvider).active) {
                ref.read(searchSessionProvider.notifier).select(index);
              }
            },
            semanticsLabel:
                '$title\n$subtitle${presentation.details == null ? '' : '\n${presentation.details}'}${shortcut == null ? '' : '\n$shortcut'}',
            content: Column(
              key: _keys.putIfAbsent(index, GlobalKey.new),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled ? colors.foreground : colors.mutedForeground,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
            trailing:
                result is NoteSearchResult &&
                    !result.recovery &&
                    result.hit.start != null
                ? BusyMarkCompactIconButton(
                    tooltip: context.l10n.notesSourceLocation,
                    icon: BusyMarkGlyphs.code,
                    onPressed: () => unawaited(
                      activateSearchResult(context, ref, result, source: true),
                    ),
                  )
                : shortcut == null
                ? null
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(
                      shortcut,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
            onTap: enabled ? () => unawaited(widget.onActivate(result)) : null,
            menuTooltip: result is RecentSearchResult
                ? context.l10n.actions
                : null,
            menuItemsBuilder: result is RecentSearchResult
                ? (context) => _recentMenuItems(context, result.resource)
                : null,
            onMenuSelected: result is RecentSearchResult
                ? (action) => unawaited(
                    runRecentNavigationAction(
                      context,
                      ref,
                      result.resource,
                      action,
                    ),
                  )
                : null,
          );
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
