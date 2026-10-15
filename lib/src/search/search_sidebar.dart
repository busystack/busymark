import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_settings.dart';
import '../app/app_router.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_search_field.dart';
import '../app/busymark_toast.dart';
import '../app/command_registry.dart';
import '../app/localization.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import '../nextcloud_notes/presentation/notes_workspace_ui.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_glyphs.dart';
import '../workspace/workspace_safety.dart';
import 'search_session.dart';
import 'search_result_preview.dart';

String searchCategoryLabel(BuildContext context, SearchCategory category) =>
    switch (category) {
      SearchCategory.text => context.l10n.searchTextCategory,
      SearchCategory.outline => context.l10n.outline,
      SearchCategory.documents => context.l10n.searchDocumentsCategory,
      SearchCategory.topics => context.l10n.searchTopicsCategory,
      SearchCategory.recent => context.l10n.recent,
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
        hintText: context.l10n.searchQueryHint(
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
    final remote =
        ref.watch(workspaceControllerProvider).workspace?.isRemote == true;
    return LayoutBuilder(
      builder: (context, constraints) => Focus(
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
            Visibility(
              visible: !browsingOutline,
              maintainState: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BusyMarkSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text('${context.l10n.search}: '),
                        Expanded(
                          child: DropdownButton<SearchCategory>(
                            key: const ValueKey('search-category'),
                            isExpanded: true,
                            value:
                                controller.categories.contains(state.category)
                                ? state.category
                                : controller.categories.first,
                            items: [
                              for (final category in controller.categories)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    searchCategoryLabel(context, category),
                                  ),
                                ),
                            ],
                            onChanged: (category) {
                              if (category != null) {
                                controller.open(category: category);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .48,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.textActive) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BusyMarkSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Text('${context.l10n.location}: '),
                                  Expanded(
                                    child: DropdownButton<SearchLocation>(
                                      key: const ValueKey('search-location'),
                                      isExpanded: true,
                                      value: state.location,
                                      items: [
                                        DropdownMenuItem(
                                          value: SearchLocation.document,
                                          child: Text(
                                            context.l10n.searchCurrentDocument,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: SearchLocation.workspace,
                                          child: Text(
                                            context.l10n.searchCurrentWorkspace,
                                          ),
                                        ),
                                        if (state.location ==
                                            SearchLocation.recovery)
                                          DropdownMenuItem(
                                            value: SearchLocation.recovery,
                                            child: Text(
                                              context.l10n.notesRecovery,
                                            ),
                                          ),
                                      ],
                                      onChanged: (location) {
                                        if (location != null) {
                                          controller.open(
                                            category: SearchCategory.text,
                                            location: location,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: BusyMarkSpacing.xs,
                              children: [
                                if (!remote ||
                                    state.location == SearchLocation.document)
                                  FilterChip(
                                    label: Text(
                                      context.l10n.sourceSearchCaseSensitive,
                                    ),
                                    selected: state.caseSensitive,
                                    onSelected: (v) => controller.set(
                                      state.copyWith(caseSensitive: v),
                                    ),
                                  ),
                                FilterChip(
                                  label: Text(
                                    context.l10n.sourceSearchWholeWord,
                                  ),
                                  selected: state.wholeWord,
                                  onSelected: (v) => controller.set(
                                    state.copyWith(wholeWord: v),
                                  ),
                                ),
                                if (!remote ||
                                    state.location == SearchLocation.document)
                                  FilterChip(
                                    label: Text(context.l10n.sourceSearchRegex),
                                    selected: state.regex,
                                    onSelected: (v) => controller.set(
                                      state.copyWith(regex: v),
                                    ),
                                  ),
                              ],
                            ),
                            if (remote &&
                                state.location != SearchLocation.document)
                              Padding(
                                padding: const EdgeInsets.all(
                                  BusyMarkSpacing.sm,
                                ),
                                child: Text(context.l10n.notesSearchHelp),
                              ),
                            if (!remote &&
                                state.location == SearchLocation.workspace &&
                                onReviewReplacement != null &&
                                state.query.isNotEmpty &&
                                !state.searching)
                              Padding(
                                padding: const EdgeInsets.all(
                                  BusyMarkSpacing.sm,
                                ),
                                child: BusyMarkPushButton.standard(
                                  onPressed: () =>
                                      unawaited(onReviewReplacement!()),
                                  child: Text(context.l10n.workspaceReplace),
                                ),
                              ),
                          ],
                          if (state.searching)
                            const LinearProgressIndicator(
                              key: ValueKey('workspace-search-progress'),
                            ),
                          if (state.indexing) Text(context.l10n.notesIndexing),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                              child: Text(state.error!),
                            ),
                          if (state.invalidRegex)
                            Text(context.l10n.sourceSearchInvalidRegex),
                          if (state.hasZeroLengthMatches)
                            Text(
                              context.l10n.sourceSearchZeroLengthUnsupported,
                            ),
                          if (state.skippedFiles.isNotEmpty)
                            Tooltip(
                              message: state.skippedFiles.join('\n'),
                              child: Text(
                                '${context.l10n.workspaceSearchSkippedFiles}\n${state.skippedFiles.join('\n')}',
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (state.truncated)
                    Padding(
                      padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                      child: Column(
                        children: [
                          Text(
                            context.l10n.workspaceSearchIncomplete,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            onPressed: controller.showMore,
                            child: Text(context.l10n.workspaceSearchShowMore),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: outline != null
                  ? outline!
                  : state.results.isEmpty
                  ? state.error != null ||
                            state.invalidRegex ||
                            state.hasZeroLengthMatches ||
                            state.skippedFiles.isNotEmpty
                        ? const SizedBox.shrink()
                        : Center(
                            child: Text(
                              state.searching
                                  ? ''
                                  : state.textActive && state.query.isEmpty
                                  ? context.l10n.searchQueryHint(
                                      context.l10n.searchTextCategory,
                                    )
                                  : context.l10n.noResults,
                            ),
                          )
                  : SearchResultList(
                      results: state.results,
                      selected: state.selected,
                      onActivate: (result) =>
                          activateSearchResult(context, ref, result),
                    ),
            ),
          ],
        ),
      ),
    );
  }
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
    // Recent is always two sections, each bounded to twelve records.
    final recent = widget.results.whereType<RecentSearchResult>().toList();
    final rows = recent.isEmpty
        ? widget.results
        : <SidebarSearchResult>[
            ...recent.where((r) => r.resource.isDocument),
            ...recent.where((r) => !r.resource.isDocument),
          ];
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
          String? section;
          if (result is RecentSearchResult &&
              (index == 0 ||
                  (rows[index - 1] as RecentSearchResult).resource.isDocument !=
                      result.resource.isDocument)) {
            section = result.resource.isDocument
                ? context.l10n.recentDocuments
                : context.l10n.recentWorkspaces;
          }
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
            final record = BusyMarkSidebarRecordRow<_RecentNavigationAction>(
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
              onMenuSelected: (action) =>
                  unawaited(_recentAction(context, ref, resource, action)),
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
            if (section == null) return focusable;
            return Column(
              key: key,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                  child: Text(
                    section,
                    style: busyMarkSectionHeaderStyle(context),
                  ),
                ),
                focusable,
              ],
            );
          }
          if (section == null) return row;
          return Column(
            key: key,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(BusyMarkSpacing.sm),
                child: Text(
                  section,
                  style: busyMarkSectionHeaderStyle(context),
                ),
              ),
              row,
            ],
          );
        },
      ),
    );
  }
}

bool actionEnabled(WidgetRef ref, ActionSearchResult result) {
  final controller = ref.read(searchSessionProvider.notifier);
  final command = result.command;
  final registry = BusyMarkCommandRegistryScope.read(ref.context);
  if (registry == null) return false;
  final workspace = ref.read(workspaceControllerProvider);
  final target = controller.commandTarget;
  if (registry.requiresDocumentTarget(command) &&
      (!controller.workspaceVisible ||
          target?.bufferId == null ||
          target?.isCurrent(workspace) != true)) {
    return false;
  }
  final activeNotesAction =
      controller.workspaceVisible &&
      (workspace.workspace?.isRemote == true ||
          controller.actionAccountId != null) &&
      {
        BusyMarkCommandIds.newNote,
        BusyMarkCommandIds.browseNotes,
      }.contains(command.id);
  if ((registry.requiresWorkspaceTarget(command) || activeNotesAction) &&
      (!controller.workspaceVisible ||
          target?.workspaceId == null ||
          target?.workspaceId != workspace.workspace?.id)) {
    return false;
  }
  if (registry.isContextual(command)) {
    return controller.workspaceVisible &&
        target?.isCurrent(ref.read(workspaceControllerProvider)) == true &&
        registry.canExecuteInContext(command.id, target!.context);
  }
  if (!controller.workspaceVisible &&
      command.scope != BusyMarkCommandScope.application) {
    return false;
  }
  return command.canExecute;
}

Future<void> activateSelectedSearchResult(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = ref.read(searchSessionProvider.notifier);
  if (!await controller.submit() || !context.mounted) return;
  final state = ref.read(searchSessionProvider);
  if (state.category == SearchCategory.outline) {
    controller.activateOutline?.call();
    return;
  }
  if (state.results.isEmpty) return;
  await activateSearchResult(context, ref, state.results[state.selected]);
}

final _searchActivationProvider = Provider((ref) => _SearchActivation());

class _SearchActivation {
  bool busy = false;
}

Future<void> activateSearchResult(
  BuildContext context,
  WidgetRef ref,
  SidebarSearchResult result, {
  bool source = false,
}) async {
  final guard = ref.read(_searchActivationProvider);
  if (guard.busy) return;
  guard.busy = true;
  final session = ref.read(searchSessionProvider.notifier);
  final snapshot = ref.read(searchSessionProvider);
  final workspace = ref.read(workspaceControllerProvider).workspace;
  final controller = ref.read(workspaceControllerProvider.notifier);
  void unavailable() {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.commandUnavailableInContext,
      );
    }
  }

  try {
    if (!snapshot.active ||
        !snapshot.results.any((r) => identical(r, result))) {
      unavailable();
      return;
    }
    bool currentRequest() =>
        ref.context.mounted &&
        session.workspaceVisible &&
        ref.read(workspaceControllerProvider).workspace?.id == workspace?.id &&
        ref.read(searchSessionProvider).active &&
        ref.read(searchSessionProvider).requestRevision ==
            snapshot.requestRevision &&
        ref.read(searchSessionProvider).focusRequest == snapshot.focusRequest &&
        ref.read(searchSessionProvider).query == snapshot.query &&
        ref.read(searchSessionProvider).category == snapshot.category &&
        ref.read(searchSessionProvider).location == snapshot.location;
    switch (result) {
      case ActionSearchResult(:final command):
        if (!actionEnabled(ref, result)) {
          unavailable();
          return;
        }
        final registry = BusyMarkCommandRegistryScope.read(context)!;
        final success = await registry.executeInContext(
          command.id,
          session.commandTarget?.context,
        );
        if (success &&
            ref.context.mounted &&
            ref.read(searchSessionProvider).focusRequest ==
                snapshot.focusRequest &&
            ref.read(searchSessionProvider).category == snapshot.category) {
          session.close();
        }
      case RecentSearchResult(:final resource):
        await openRecentResource(context, ref, resource);
      case DocumentSearchResult(
        :final workspaceId,
        :final accountId,
        :final document,
      ):
        if (!session.workspaceVisible || workspace?.id != workspaceId) {
          unavailable();
          return;
        }
        if (accountId != null) {
          final repo = await ref.read(nextcloudNotesRepositoryProvider.future);
          final note = repo.noteById(document.localId!);
          if (!context.mounted ||
              !currentRequest() ||
              ref.read(workspaceControllerProvider).workspace?.id !=
                  workspaceId ||
              note?.accountId != accountId ||
              isNotesRecovery(note!) ||
              repo.isCreationCandidateBinding(note.localId)) {
            unavailable();
            return;
          }
          if (await controller.openNextcloudNote(
            document.localId!,
            acceptNavigation: currentRequest,
          )) {
            if (!currentRequest()) return;
            session.close(restoreFocus: false);
          }
        } else {
          if (!workspace!.files.any(
            (f) => f.absolutePath == document.filePath,
          )) {
            unavailable();
            return;
          }
          if (await controller.openActiveFile(
            document.filePath!,
            acceptNavigation: currentRequest,
          )) {
            if (!currentRequest()) return;
            session.close(restoreFocus: false);
          }
        }
      case TopicSearchResult(:final workspaceId, :final path):
        if (!session.workspaceVisible ||
            workspace?.id != workspaceId ||
            ![
              for (final module
                  in workspace!.writersideProject?.modules ??
                      [
                        if (workspace.writersideModule != null)
                          workspace.writersideModule!,
                      ])
                ...module.topics,
            ].any((t) => p.equals(t.filePath, path))) {
          unavailable();
          return;
        }
        if (await controller.openActiveFile(
          path,
          acceptNavigation: currentRequest,
        )) {
          if (!currentRequest()) return;
          session.close(restoreFocus: false);
        }
      case TextSearchResult(:final workspaceId, :final match):
        if (!session.workspaceVisible || workspace?.id != workspaceId) {
          unavailable();
          return;
        }
        if (match.bufferId != null) {
          if (ref.read(workspaceControllerProvider).activeBufferId !=
                  match.bufferId &&
              !await controller.activateDocumentBuffer(
                match.bufferId!,
                acceptNavigation: currentRequest,
              )) {
            return;
          }
        } else if (match.filePath != null) {
          if (!await controller.openActiveFile(
            match.filePath!,
            acceptNavigation: currentRequest,
          )) {
            return;
          }
        } else {
          unavailable();
          return;
        }
        if (!context.mounted ||
            !currentRequest() ||
            ref.read(workspaceControllerProvider).workspace?.id !=
                workspaceId) {
          return;
        }
        final buffer = ref.read(workspaceControllerProvider).activeBuffer;
        if (buffer == null ||
            notesSearchDigest(buffer.text) != match.digest ||
            match.endOffset > buffer.text.length) {
          unavailable();
          return;
        }
        ref
            .read(notesMatchNavigationProvider.notifier)
            .navigate(
              buffer.remoteNote?.localId ?? buffer.filePath ?? buffer.id,
              match.startOffset,
              match.endOffset,
              match.digest,
              accountId: buffer.remoteNote?.accountId,
            );
      case NoteSearchResult(:final accountId, :final hit, :final recovery):
        final repo = await ref.read(nextcloudNotesRepositoryProvider.future);
        final note = repo.noteById(hit.localId);
        if (!context.mounted ||
            !currentRequest() ||
            ref
                    .read(workspaceControllerProvider)
                    .workspace
                    ?.nextcloudAccountId !=
                accountId ||
            note?.accountId != accountId ||
            isNotesRecovery(note!) != recovery) {
          unavailable();
          return;
        }
        if (recovery) {
          session.close(restoreFocus: false);
          await showNotesRecovery(context, ref, note);
          return;
        }
        if (!await controller.openNextcloudNote(
              hit.localId,
              acceptNavigation: currentRequest,
            ) ||
            !context.mounted ||
            !currentRequest()) {
          return;
        }
        final buffer = ref.read(workspaceControllerProvider).activeBuffer;
        if (buffer?.remoteNote?.accountId != accountId ||
            buffer?.remoteNote?.localId != hit.localId ||
            notesSearchDigest(buffer!.text) != hit.digest) {
          unavailable();
          return;
        }
        if (source) {
          controller.updateActiveEditorMode(DocumentViewModePreference.source);
          await ref
              .read(appSettingsControllerProvider.notifier)
              .setDocumentViewMode(DocumentViewModePreference.source);
          if (!context.mounted || !currentRequest()) return;
        }
        if (hit.start != null && hit.end != null) {
          ref
              .read(notesMatchNavigationProvider.notifier)
              .navigate(
                hit.localId,
                hit.start!,
                hit.end!,
                hit.digest,
                accountId: accountId,
              );
        }
    }
  } finally {
    guard.busy = false;
  }
}

Future<void> openRecentResource(
  BuildContext context,
  WidgetRef ref,
  RecentWorkspace resource,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final origin = ref.read(appRouterProvider).routeInformationProvider.value.uri;
  final search = ref.read(searchSessionProvider);
  bool currentRequest() =>
      context.mounted &&
      ref.read(appRouterProvider).routeInformationProvider.value.uri ==
          origin &&
      ref.read(searchSessionProvider).requestRevision ==
          search.requestRevision &&
      (!search.active ||
          ref.read(searchSessionProvider).active &&
              ref.read(searchSessionProvider).focusRequest ==
                  search.focusRequest &&
              ref.read(searchSessionProvider).category == search.category &&
              ref.read(searchSessionProvider).query == search.query);
  final current = ref.read(workspaceControllerProvider).workspace;
  bool opened = false;
  if (resource.accountId != null) {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!context.mounted || !currentRequest()) return;
    final account = repository.accounts
        .where((a) => a.id == resource.accountId)
        .firstOrNull;
    final note = resource.localId == null
        ? null
        : repository.noteById(resource.localId!);
    if (account == null ||
        resource.isDocument &&
            (note?.accountId != resource.accountId ||
                isNotesRecovery(note!) ||
                repository.isCreationCandidateBinding(note.localId))) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.searchResourceUnavailable,
      );
      return;
    }
    if (current?.nextcloudAccountId != resource.accountId) {
      if (!await confirmSafeToContinue(context, ref) ||
          !context.mounted ||
          !currentRequest()) {
        return;
      }
      if (!await controller.openNextcloudWorkspace(
        resource.accountId!,
        acceptNavigation: currentRequest,
      )) {
        return;
      }
    }
    opened =
        resource.localId == null ||
        await controller.openNextcloudNote(
          resource.localId!,
          acceptNavigation: currentRequest,
        );
  } else {
    if (!await FileSystemEntity.isFile(resource.path) &&
        !await Directory(resource.path).exists()) {
      if (context.mounted) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
      }
      return;
    }
    if (!context.mounted || !currentRequest()) return;
    final sameOwner =
        current != null &&
        (resource.ownerRoot != null
            ? p.equals(current.rootPath, resource.ownerRoot!)
            : current.files.any(
                (f) => p.equals(f.absolutePath, resource.path),
              ));
    if (resource.isDocument && sameOwner) {
      opened = await controller.openActiveFile(
        resource.path,
        acceptNavigation: currentRequest,
      );
    } else {
      if (!await confirmSafeToContinue(context, ref) ||
          !context.mounted ||
          !currentRequest()) {
        return;
      }
      await controller.openPath(
        resource.ownerRoot ?? resource.path,
        acceptNavigation: currentRequest,
      );
      if (!context.mounted || !currentRequest()) return;
      final workspace = ref.read(workspaceControllerProvider).workspace;
      if (workspace == null) return;
      if (resource.ownerRoot != null &&
          workspace.writersideProject == null &&
          workspace.writersideModule == null) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
        return;
      }
      opened =
          resource.ownerRoot == null ||
          await controller.openActiveFile(
            resource.path,
            acceptNavigation: currentRequest,
          );
    }
  }
  if (opened && context.mounted) {
    await ref
        .read(appSettingsControllerProvider.notifier)
        .recordRecent(
          RecentWorkspace(
            path: resource.path,
            kind: resource.kind,
            accountId: resource.accountId,
            accountLabel: resource.accountLabel,
            localId: resource.localId,
            title: resource.title,
            ownerRoot: resource.ownerRoot,
            document: resource.isDocument,
            lastOpenedAt: DateTime.now(),
          ),
        );
    if (!context.mounted || !currentRequest()) return;
    ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
    context.go('/workspace');
  }
}

enum _RecentNavigationAction { openInFiles, copyPath, removeFromRecent }

List<PopupMenuEntry<_RecentNavigationAction>> _recentMenuItems(
  BuildContext context,
  RecentWorkspace resource,
) => [
  if (resource.accountId == null) ...[
    BusyMarkPopupMenuItem(
      value: _RecentNavigationAction.openInFiles,
      label: context.l10n.openInFiles,
      icon: BusyMarkGlyphs.folderOpen,
    ),
    BusyMarkPopupMenuItem(
      value: _RecentNavigationAction.copyPath,
      label: context.l10n.copyPath,
      icon: BusyMarkGlyphs.copy,
    ),
  ],
  BusyMarkPopupMenuItem(
    value: _RecentNavigationAction.removeFromRecent,
    label: context.l10n.removeFromRecent,
    icon: BusyMarkGlyphs.clear,
  ),
];
Future<void> _recentAction(
  BuildContext context,
  WidgetRef ref,
  RecentWorkspace resource,
  _RecentNavigationAction action,
) async {
  switch (action) {
    case _RecentNavigationAction.removeFromRecent:
      await ref
          .read(appSettingsControllerProvider.notifier)
          .removeRecentWorkspace(resource.identity);
    case _RecentNavigationAction.copyPath:
      await Clipboard.setData(ClipboardData(text: resource.path));
    case _RecentNavigationAction.openInFiles:
      final type = await FileSystemEntity.type(resource.path);
      if (!context.mounted) return;
      if (type == FileSystemEntityType.notFound) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
        return;
      }
      await launchUrl(
        Uri.directory(
          type == FileSystemEntityType.directory
              ? resource.path
              : p.dirname(resource.path),
        ),
      );
  }
}
