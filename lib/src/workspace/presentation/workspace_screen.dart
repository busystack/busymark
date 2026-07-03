import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:yaru/yaru.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_shortcuts.dart';
import '../../app/localization.dart';
import '../../core/diagnostic.dart';
import '../../core/diagnostic_localizations.dart';
import '../../core/path_utils.dart' show slugForHeading;
import '../../core/uri_utils.dart';
import '../../editor/markdown_image_view.dart';
import '../../editor/source_folding.dart';
import '../../editor/source_highlighter.dart';
import '../../editor/wysiwyg/wysiwyg_editor.dart';
import '../../git/application/git_controller.dart';
import '../../git/domain/git_models.dart';
import '../../git/presentation/git_diff_viewer.dart';
import '../../git/presentation/git_sidebar_tab.dart';
import '../../markdown/busymark_document.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/markdown_parser.dart';
import '../../markdown/preview_model.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../writerside/writerside_model.dart';
import '../../writerside/writerside_topic_creator.dart';
import '../workspace_controller.dart';
import '../workspace_model.dart';
import '../workspace_message.dart';
import '../workspace_safety.dart';
import 'welcome_screen.dart';

final _outlineNavigationTargetProvider =
    NotifierProvider<
      _OutlineNavigationTargetController,
      _OutlineNavigationTarget?
    >(_OutlineNavigationTargetController.new);
final _sourceNavigationTargetProvider =
    NotifierProvider<
      _SourceNavigationTargetController,
      _SourceNavigationTarget?
    >(_SourceNavigationTargetController.new);
final _workspaceSearchProvider =
    NotifierProvider<_WorkspaceSearchController, _WorkspaceSearchState>(
      _WorkspaceSearchController.new,
    );
final _searchNavigationTargetProvider =
    NotifierProvider<
      _SearchNavigationTargetController,
      _SearchNavigationTarget?
    >(_SearchNavigationTargetController.new);
final _sidebarShortcutRequestProvider =
    NotifierProvider<_SidebarShortcutRequestController, _SidebarTab?>(
      _SidebarShortcutRequestController.new,
    );

class _OutlineNavigationTargetController
    extends Notifier<_OutlineNavigationTarget?> {
  @override
  _OutlineNavigationTarget? build() => null;

  void set(_OutlineNavigationTarget? target) {
    state = target;
  }
}

class _SourceNavigationTargetController
    extends Notifier<_SourceNavigationTarget?> {
  @override
  _SourceNavigationTarget? build() => null;

  void set(_SourceNavigationTarget? target) {
    state = target;
  }
}

class _WorkspaceSearchController extends Notifier<_WorkspaceSearchState> {
  @override
  _WorkspaceSearchState build() => const _WorkspaceSearchState();

  void set(_WorkspaceSearchState searchState) {
    state = searchState;
  }
}

class _SearchNavigationTargetController
    extends Notifier<_SearchNavigationTarget?> {
  @override
  _SearchNavigationTarget? build() => null;

  void set(_SearchNavigationTarget? target) {
    state = target;
  }
}

class _SidebarShortcutRequestController extends Notifier<_SidebarTab?> {
  @override
  _SidebarTab? build() => null;

  void select(_SidebarTab tab) {
    state = tab;
  }

  void clear() {
    state = null;
  }
}

const _sourceTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

ScrollPosition? _safeScrollPosition(ScrollController controller) {
  return controller.positions.isEmpty ? null : controller.positions.last;
}

double _safeScrollOffset(ScrollController controller) {
  return _safeScrollPosition(controller)?.pixels ?? 0.0;
}

double _safeMaxScrollExtent(ScrollController controller) {
  return _safeScrollPosition(controller)?.maxScrollExtent ?? 0.0;
}

bool _isPlainTabKey(HardwareKeyboard keyboard, LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.tab &&
      !keyboard.isControlPressed &&
      !keyboard.isShiftPressed &&
      !keyboard.isAltPressed &&
      !keyboard.isMetaPressed;
}

bool _isPlainShiftTabKey(HardwareKeyboard keyboard, LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.tab &&
      !keyboard.isControlPressed &&
      keyboard.isShiftPressed &&
      !keyboard.isAltPressed &&
      !keyboard.isMetaPressed;
}

class _OutlineNavigationTarget {
  const _OutlineNavigationTarget({
    required this.filePath,
    required this.headingId,
    required this.line,
  });

  final String filePath;
  final String headingId;
  final int line;
}

class _SourceNavigationTarget {
  const _SourceNavigationTarget({required this.filePath, required this.line});

  final String filePath;
  final int line;
}

class _WorkspaceSearchState {
  const _WorkspaceSearchState({this.active = false, this.query = ''});

  final bool active;
  final String query;

  _WorkspaceSearchState copyWith({bool? active, String? query}) {
    return _WorkspaceSearchState(
      active: active ?? this.active,
      query: query ?? this.query,
    );
  }
}

class _SearchNavigationTarget {
  const _SearchNavigationTarget({
    required this.filePath,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    required this.request,
  });

  final String filePath;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final int request;
}

class _ToggleSearchIntent extends Intent {
  const _ToggleSearchIntent();
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

enum _SourceInlineMarkdownCommand {
  bold,
  italic,
  underline,
  strikethrough,
  code,
  link,
}

enum _SourceBlockMarkdownCommand {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  orderedList,
  unorderedList,
  taskList,
}

class _SourceEditorShortcutIntent extends Intent {
  const _SourceEditorShortcutIntent(this.action);

  final BusyMarkEditorShortcutAction action;
}

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final workspace = state.workspace;
    if (workspace == null) {
      return const WelcomeScreen();
    }
    final searchState = ref.watch(_workspaceSearchProvider);
    final gitState = ref.watch(gitControllerProvider);
    final searchResults = _workspaceSearchResults(
      context,
      state,
      searchState.query,
    );

    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final sidebarVisible =
        settings.sidebarVisible && _hasWorkspaceSidebar(workspace);
    final sidebar = SizedBox(
      width: BusyMarkSizes.sidebarWidth,
      child: _Sidebar(
        workspace: workspace,
        searchState: searchState,
        searchResults: searchResults,
        onOpenSearchResult: (result) => _openSearchResult(context, ref, result),
      ),
    );
    final workspaceContent = Expanded(
      child: Column(
        children: [
          if (_shouldShowEditorTabs(workspace)) _EditorTabStrip(state: state),
          Expanded(
            child: gitState.selectedDiff == null
                ? _EditorPreviewSplit(
                    state: state,
                    viewMode: settings.documentViewMode,
                    editorFontSize: settings.editorFontSize,
                    editorToolbarPlacement: settings.editorToolbarPlacement,
                    wordWrap: settings.wordWrap,
                  )
                : GitDiffViewer(
                    diff: gitState.selectedDiff,
                    hasUnsavedEditorChanges: state.isDirty,
                    onOpenFile: (relativePath) =>
                        _openGitDiffFile(context, ref, relativePath),
                    onClose: () => ref
                        .read(gitControllerProvider.notifier)
                        .clearSelection(),
                  ),
          ),
        ],
      ),
    );
    final sidebarOnRight = Directionality.of(context) == TextDirection.rtl;
    final workspaceChildren = [
      if (!sidebarOnRight && sidebarVisible) sidebar,
      workspaceContent,
      if (sidebarOnRight && sidebarVisible) sidebar,
    ];
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((event) {
        _handleHeaderBarAction(context, ref, event.action);
      });
    });
    ref.listen(headerBarSearchQueriesProvider, (previous, next) {
      next.whenData((query) {
        final current = ref.read(_workspaceSearchProvider);
        if (current.query == query && current.active) {
          return;
        }
        _clearGitDetailSelection(ref);
        ref
            .read(_workspaceSearchProvider.notifier)
            .set(current.copyWith(active: true, query: query));
        unawaited(settingsController.setSidebarVisible(true));
      });
    });
    ref.listen<int>(workspaceSearchOpenRequestProvider, (previous, next) {
      if (previous != null && next != previous) {
        _openSearch(ref);
      }
    });
    ref.listen<int>(workspaceSearchCloseRequestProvider, (previous, next) {
      if (previous != null && next != previous) {
        _closeSearch(ref);
      }
    });
    ref.listen<WorkspaceState>(workspaceControllerProvider, (previous, next) {
      final nextWorkspace = next.workspace;
      if (nextWorkspace == null) {
        return;
      }
      ref.read(gitControllerProvider.notifier).attachWorkspace(nextWorkspace);
    });
    if (gitState.attachedWorkspace?.id != workspace.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gitControllerProvider.notifier).attachWorkspace(workspace);
      });
    }
    if (headerBar.isAvailable) {
      _configureHeaderBar(
        context,
        headerBar,
        workspace,
        state,
        settings,
        searchState,
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _handleWorkspaceKeyEvent(event, ref),
      child: Shortcuts(
        shortcuts: {
          BusyMarkAppShortcutActivators.find: const _OpenSearchIntent(),
        },
        child: Actions(
          actions: {
            _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
              onInvoke: (intent) {
                _openSearch(ref);
                return null;
              },
            ),
            _ToggleSearchIntent: CallbackAction<_ToggleSearchIntent>(
              onInvoke: (intent) {
                _toggleSearch(ref);
                return null;
              },
            ),
          },
          child: Scaffold(
            backgroundColor: colors.window,
            appBar: useNativeHeaderBar
                ? null
                : AppBar(
                    leadingWidth: 50,
                    titleSpacing: 0,
                    leading: Center(
                      child: BusyMarkHeaderIconButton(
                        tooltip: context.l10n.welcome,
                        icon: BusyMarkGlyphs.home,
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          if (await confirmSafeToContinue(context, ref)) {
                            router.go('/');
                          }
                        },
                      ),
                    ),
                    title: searchState.active
                        ? _HeaderSearchField(
                            query: searchState.query,
                            onChanged: (query) => _setSearchQuery(ref, query),
                            onSubmitted: () {
                              if (searchResults.isNotEmpty) {
                                unawaited(
                                  _openSearchResult(
                                    context,
                                    ref,
                                    searchResults.first,
                                  ),
                                );
                              }
                            },
                          )
                        : _HeaderTitle(
                            title: _activeFileName(context, workspace),
                            subtitle: _workspaceKindLabel(
                              context,
                              workspace.kind,
                            ),
                            dirty: state.isDirty,
                          ),
                    actions: [
                      const SizedBox(width: BusyMarkSpacing.sm),
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.validate,
                        icon: BusyMarkGlyphs.diagnostics,
                        onPressed: () => unawaited(
                          _validateActiveAndShowProblems(context, ref),
                        ),
                      ),
                      const _HeaderSeparator(),
                      BusyMarkHeaderIconButton(
                        tooltip: settings.sidebarVisible
                            ? context.l10n.hideSidebar
                            : context.l10n.showSidebar,
                        icon: BusyMarkGlyphs.sidebar,
                        selected: settings.sidebarVisible,
                        shortcut: BusyMarkSidebarShortcutLabels.toggleSidebar,
                        onPressed: () {
                          final visible = !settings.sidebarVisible;
                          if (!visible) {
                            _clearGitDetailSelection(ref);
                          }
                          unawaited(
                            settingsController.setSidebarVisible(visible),
                          );
                        },
                      ),
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.search,
                        icon: BusyMarkGlyphs.search,
                        selected: searchState.active,
                        shortcut: BusyMarkAppShortcutLabels.find,
                        onPressed: () => _toggleSearch(ref),
                      ),
                      BusyMarkHeaderIconButton(
                        tooltip:
                            settings.documentViewMode ==
                                DocumentViewModePreference.source
                            ? context.l10n.showPreview
                            : context.l10n.hidePreview,
                        icon: BusyMarkGlyphs.preview,
                        selected:
                            settings.documentViewMode !=
                            DocumentViewModePreference.source,
                        onPressed: () => settingsController.setPreviewVisible(
                          settings.documentViewMode ==
                              DocumentViewModePreference.source,
                        ),
                      ),
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.settings,
                        icon: BusyMarkGlyphs.settings,
                        shortcut: BusyMarkAppShortcutLabels.settings,
                        onPressed: () => context.go('/settings'),
                      ),
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.keyboardShortcuts,
                        icon: BusyMarkGlyphs.keyboard,
                        shortcut: BusyMarkAppShortcutLabels.keyboardShortcuts,
                        onPressed: () =>
                            showBusyMarkKeyboardShortcutsDialog(context),
                      ),
                      BusyMarkHeaderIconButton(
                        tooltip: context.l10n.aboutBusyMark,
                        icon: BusyMarkGlyphs.info,
                        onPressed: () => showBusyMarkAboutDialog(context),
                      ),
                      const SizedBox(width: BusyMarkSpacing.sm),
                    ],
                  ),
            body: Column(
              children: [
                if (state.message != null)
                  _InlineMessage(
                    icon: BusyMarkGlyphs.warning,
                    message: localizeWorkspaceMessage(context, state.message!),
                  ),
                Expanded(
                  child: Row(
                    textDirection: TextDirection.ltr,
                    children: workspaceChildren,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    if (search.active) {
      _closeSearch(ref);
    } else {
      _openSearch(ref);
    }
  }

  void _openSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    _clearGitDetailSelection(ref);
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(search.copyWith(active: true));
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    unawaited(headerBar.setSearchActive(true));
    unawaited(headerBar.setSearchQuery(search.query));
    unawaited(
      ref.read(appSettingsControllerProvider.notifier).setSidebarVisible(true),
    );
  }

  void _closeSearch(WidgetRef ref) {
    final search = ref.read(_workspaceSearchProvider);
    if (!search.active) {
      return;
    }
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(search.copyWith(active: false));
    unawaited(ref.read(linuxHeaderBarServiceProvider).setSearchActive(false));
  }

  KeyEventResult _handleWorkspaceKeyEvent(KeyEvent event, WidgetRef ref) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final action = BusyMarkSidebarShortcutActivators.actionForKeyEvent(
      event,
      HardwareKeyboard.instance,
    );
    final tab = _sidebarShortcutTabFor(action);
    if (tab == null) {
      return KeyEventResult.ignored;
    }
    _closeSearch(ref);
    unawaited(
      ref.read(appSettingsControllerProvider.notifier).setSidebarVisible(true),
    );
    ref.read(_sidebarShortcutRequestProvider.notifier).select(tab);
    return KeyEventResult.handled;
  }

  void _setSearchQuery(WidgetRef ref, String query) {
    final current = ref.read(_workspaceSearchProvider);
    ref
        .read(_workspaceSearchProvider.notifier)
        .set(current.copyWith(active: true, query: query));
    unawaited(ref.read(linuxHeaderBarServiceProvider).setSearchQuery(query));
  }

  void _configureHeaderBar(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    Workspace workspace,
    WorkspaceState state,
    AppSettings settings,
    _WorkspaceSearchState searchState,
  ) {
    final title = state.isDirty
        ? '*${_activeFileName(context, workspace)}'
        : _activeFileName(context, workspace);
    final hasSidebar = _hasWorkspaceSidebar(workspace);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await headerBar.setTitleRange(title);
        await headerBar.setSidebarWidth(BusyMarkSizes.sidebarWidth);
        await headerBar.setSidebarVisible(
          settings.sidebarVisible && hasSidebar,
        );
        await headerBar.setSidebarToggleVisible(hasSidebar);
        await headerBar.setBackVisible(true);
        await headerBar.setDocumentControlsVisible(true);
        await headerBar.setViewMode(
          _headerBarViewMode(settings.documentViewMode),
        );
        await headerBar.setCanRefresh(true);
        await headerBar.setSearchActive(searchState.active);
      }());
    });
  }

  void _handleHeaderBarAction(
    BuildContext context,
    WidgetRef ref,
    HeaderBarAction action,
  ) {
    final settings = ref.read(appSettingsControllerProvider);
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    switch (action) {
      case HeaderBarAction.back:
        final router = GoRouter.of(context);
        unawaited(() async {
          if (await confirmSafeToContinue(context, ref)) {
            router.go('/');
          }
        }());
      case HeaderBarAction.sidebarToggle:
        final visible = !settings.sidebarVisible;
        if (!visible) {
          _clearGitDetailSelection(ref);
        }
        unawaited(settingsController.setSidebarVisible(visible));
      case HeaderBarAction.refresh:
        unawaited(_validateActiveAndShowProblems(context, ref));
      case HeaderBarAction.save:
        break;
      case HeaderBarAction.settings:
        context.go('/settings');
      case HeaderBarAction.keyboardShortcuts:
        showBusyMarkKeyboardShortcutsDialog(context);
      case HeaderBarAction.markdownAndHtml:
        showBusyMarkMarkdownHtmlDialog(context);
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.viewModeEditor:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.editor,
          ),
        );
      case HeaderBarAction.viewModeSource:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.source,
          ),
        );
      case HeaderBarAction.viewModePreview:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.preview,
          ),
        );
      case HeaderBarAction.viewModeSplit:
        unawaited(
          settingsController.setDocumentViewMode(
            DocumentViewModePreference.split,
          ),
        );
      case HeaderBarAction.search:
        _toggleSearch(ref);
      case HeaderBarAction.menu:
        break;
    }
  }

  String _activeFileName(BuildContext context, Workspace workspace) {
    final path = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (path == null || path.isEmpty) {
      return switch (workspace.kind) {
        WorkspaceKind.markdownFolder ||
        WorkspaceKind.writersideModule => context.l10n.noOpenFile,
        WorkspaceKind.untitledMarkdown ||
        WorkspaceKind.singleMarkdown => context.l10n.untitledMarkdownFileName,
      };
    }
    return p.basename(path);
  }

  String _workspaceKindLabel(BuildContext context, WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown =>
        context.l10n.workspaceKindUnsavedMarkdown,
      WorkspaceKind.singleMarkdown => context.l10n.workspaceKindSingleMarkdown,
      WorkspaceKind.markdownFolder => context.l10n.workspaceKindMarkdownFolder,
      WorkspaceKind.writersideModule =>
        context.l10n.workspaceKindWritersideModule,
    };
  }

  AppViewMode _headerBarViewMode(DocumentViewModePreference mode) {
    return switch (mode) {
      DocumentViewModePreference.editor => AppViewMode.editor,
      DocumentViewModePreference.source => AppViewMode.source,
      DocumentViewModePreference.preview => AppViewMode.preview,
      DocumentViewModePreference.split => AppViewMode.split,
    };
  }

  Future<void> _openSearchResult(
    BuildContext context,
    WidgetRef ref,
    _WorkspaceSearchResult result,
  ) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (activePath != result.filePath) {
      if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
          !context.mounted) {
        return;
      }
      await ref
          .read(workspaceControllerProvider.notifier)
          .openActiveFile(result.filePath);
    }
    _clearGitDetailSelection(ref);
    if (!context.mounted) {
      return;
    }
    final previous = ref.read(_searchNavigationTargetProvider);
    ref
        .read(_searchNavigationTargetProvider.notifier)
        .set(
          _SearchNavigationTarget(
            filePath: result.filePath,
            line: result.line,
            startOffset: result.startOffset,
            endOffset: result.endOffset,
            query: result.query,
            request: (previous?.request ?? 0) + 1,
          ),
        );
  }

  void _showProblemsDialog(BuildContext context, WidgetRef ref) {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    if (workspace == null) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    final count = workspace.diagnostics.length;
    unawaited(
      showBusyMarkModalDialog<void>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.problems,
          maxWidth: BusyMarkSizes.contentWidth,
          children: [
            Text(
              context.l10n.diagnosticCount(count),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: BusyMarkSurfaceColors.of(context).mutedForeground,
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            SizedBox(
              width: BusyMarkSizes.problemsListWidth,
              height: BusyMarkSizes.problemsListHeight,
              child: _ProblemsList(workspace: workspace),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateActiveAndShowProblems(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(workspaceControllerProvider.notifier).validateActive();
    if (!context.mounted) {
      return;
    }
    _showProblemsDialog(context, ref);
  }
}

Future<void> _openGitDiffFile(
  BuildContext context,
  WidgetRef ref,
  String repoRelativePath,
) async {
  final repo = ref.read(gitControllerProvider).repositoryInfo;
  if (repo == null) {
    return;
  }
  if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
      !context.mounted) {
    return;
  }
  final absolutePath = p.normalize(p.join(repo.rootPath, repoRelativePath));
  final workspace = ref.read(workspaceControllerProvider).workspace;
  final fileInWorkspace =
      workspace?.files.any((file) => file.absolutePath == absolutePath) ??
      false;
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (fileInWorkspace) {
    await controller.openActiveFile(absolutePath);
  } else {
    await controller.openPath(absolutePath);
  }
  ref.read(gitControllerProvider.notifier).clearSelection();
}

void _clearGitDetailSelection(WidgetRef ref) {
  final gitState = ref.read(gitControllerProvider);
  if (gitState.selectedDiff != null ||
      gitState.selectedFilePath != null ||
      gitState.selectedCommitHash != null) {
    ref.read(gitControllerProvider.notifier).clearSelection();
  }
}

Future<bool> _confirmDiscardGitFiles(
  BuildContext context,
  WidgetRef ref,
  List<GitFileStatus> files,
) async {
  if (files.isEmpty ||
      !await confirmSafeToContinue(context, ref) ||
      !context.mounted) {
    return false;
  }
  final untracked = files.where((file) => file.untracked).toList();
  final tracked = files.where((file) => !file.untracked).toList();
  final title = context.l10n.gitConfirmDiscardTitle;
  final message = tracked.isNotEmpty && untracked.isNotEmpty
      ? context.l10n.gitConfirmDiscardMixed(files.length)
      : untracked.isNotEmpty
      ? context.l10n.gitConfirmDiscardUntracked(untracked.length)
      : context.l10n.gitConfirmDiscardTracked(tracked.length);
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: title,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.gitDiscard),
        ),
      ],
      children: [
        Text(message),
        const SizedBox(height: BusyMarkSpacing.md),
        _GitFileList(files: files),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmSwitchGitBranch(
  BuildContext context,
  WidgetRef ref,
  String branchName,
) async {
  if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
    return false;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.gitConfirmSwitchBranchTitle(branchName),
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.gitSwitchBranch),
        ),
      ],
      children: [Text(context.l10n.gitConfirmSwitchBranchMessage)],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmGitPushSetUpstream(
  BuildContext context,
  WidgetRef ref,
) async {
  final repo = ref.read(gitControllerProvider).repositoryInfo;
  if (repo?.upstreamBranch != null) {
    return false;
  }
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final confirmed = await showBusyMarkModalDialog<bool>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.gitConfirmPushSetUpstreamTitle,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.gitPush),
        ),
      ],
      children: [
        Text(
          context.l10n.gitConfirmPushSetUpstreamMessage(
            repo?.currentBranch ?? '',
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> _refreshWorkspaceAfterGitFileChanges(WidgetRef ref) async {
  await ref
      .read(workspaceControllerProvider.notifier)
      .refreshWorkspaceFromDiskPreservingOpenTabs();
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace != null) {
    ref.read(gitControllerProvider.notifier).attachWorkspace(workspace);
  }
}

class _GitFileList extends StatelessWidget {
  const _GitFileList({required this.files});

  final List<GitFileStatus> files;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(BusyMarkSpacing.sm),
          itemCount: files.length,
          itemBuilder: (context, index) => Text(
            files[index].repoRelativePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: BusyMarkTypography.monoFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.title,
    required this.subtitle,
    required this.dirty,
  });

  final String title;
  final String subtitle;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Row(
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dirty ? '*$title' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderSearchField extends StatefulWidget {
  const _HeaderSearchField({
    required this.query,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<_HeaderSearchField> createState() => _HeaderSearchFieldState();
}

class _HeaderSearchFieldState extends State<_HeaderSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query)
      ..addListener(_handleChanged);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HeaderSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return SizedBox(
      height: BusyMarkSizes.iconButton,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => widget.onSubmitted(),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(
            BusyMarkGlyphs.search,
            color: colors.mutedForeground,
            size: BusyMarkSizes.iconSm,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: BusyMarkSizes.iconButton,
            minHeight: BusyMarkSizes.iconButton,
          ),
          hintText: context.l10n.search,
          filled: true,
          fillColor: colors.control,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.md,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}

class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BusyMarkStroke.hairline,
      height: BusyMarkSizes.sidebarSeparatorHeight,
      margin: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
      color: BusyMarkSurfaceColors.of(context).subtleBorder,
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.lg,
          vertical: BusyMarkSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: BusyMarkSizes.iconSm),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerStatefulWidget {
  const _Sidebar({
    required this.workspace,
    required this.searchState,
    required this.searchResults,
    required this.onOpenSearchResult,
  });

  final Workspace workspace;
  final _WorkspaceSearchState searchState;
  final List<_WorkspaceSearchResult> searchResults;
  final Future<void> Function(_WorkspaceSearchResult result) onOpenSearchResult;

  @override
  ConsumerState<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<_Sidebar> {
  late int _tab;
  late String _workspaceId;
  String? _activeFilePath;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _activeFilePath = widget.workspace.activeFilePath;
    _tab = _initialSidebarTabIndex(widget.workspace);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(_sidebarShortcutRequestProvider.notifier).clear();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchState.active && !oldWidget.searchState.active) {
      _clearGitDetailSelection(ref);
    }
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _activeFilePath = widget.workspace.activeFilePath;
      _tab = _initialSidebarTabIndex(widget.workspace);
      return;
    }
    if (widget.workspace.activeFilePath != _activeFilePath) {
      _activeFilePath = widget.workspace.activeFilePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final tabs = _sidebarTabsFor(widget.workspace.kind);
    ref.listen<_SidebarTab?>(_sidebarShortcutRequestProvider, (_, next) {
      if (next == null) {
        return;
      }
      _selectTab(next, tabs);
      ref.read(_sidebarShortcutRequestProvider.notifier).clear();
    });
    final selectedIndex = tabs.isEmpty
        ? 0
        : _tab.clamp(0, tabs.length - 1).toInt();
    final selectedTab = tabs.isEmpty ? null : tabs[selectedIndex];
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.sidebar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(
            workspace: widget.workspace,
            tabs: tabs,
            selectedTab: selectedTab,
            showTabMenu: !widget.searchState.active && tabs.length > 1,
            onSelectTab: (tab) => _selectTab(tab, tabs),
          ),
          Expanded(
            child: widget.searchState.active
                ? _SearchSidebar(
                    query: widget.searchState.query,
                    results: widget.searchResults,
                    onOpenResult: widget.onOpenSearchResult,
                  )
                : switch (selectedTab) {
                    _SidebarTab.files => _FilesTab(workspace: widget.workspace),
                    _SidebarTab.toc => _TocTab(workspace: widget.workspace),
                    _SidebarTab.outline => _OutlineTab(
                      workspace: widget.workspace,
                    ),
                    _SidebarTab.git => GitSidebarTab(
                      workspace: widget.workspace,
                      onOpenFile: (relativePath) =>
                          _openGitDiffFile(context, ref, relativePath),
                      onConfirmDiscard: (files) =>
                          _confirmDiscardGitFiles(context, ref, files),
                      onAfterWorkspaceFilesChanged: () =>
                          _refreshWorkspaceAfterGitFileChanges(ref),
                      onConfirmSwitchBranch: (branchName) =>
                          _confirmSwitchGitBranch(context, ref, branchName),
                      onConfirmPushSetUpstream: () =>
                          _confirmGitPushSetUpstream(context, ref),
                    ),
                    null => const SizedBox.shrink(),
                  },
          ),
        ],
      ),
    );
  }

  void _selectTab(_SidebarTab tab, List<_SidebarTab> tabs) {
    final index = tabs.indexOf(tab);
    if (index < 0) {
      return;
    }
    setState(() => _tab = index);
    if (tab != _SidebarTab.git) {
      _clearGitDetailSelection(ref);
    }
  }

  int _initialSidebarTabIndex(Workspace workspace) {
    final tabs = _sidebarTabsFor(workspace.kind);
    final request = ref.read(_sidebarShortcutRequestProvider);
    final requestedIndex = request == null ? -1 : tabs.indexOf(request);
    return requestedIndex >= 0
        ? requestedIndex
        : _preferredSidebarTabIndex(workspace);
  }
}

enum _SidebarTab { files, toc, outline, git }

int _preferredSidebarTabIndex(Workspace workspace) {
  final tabs = _sidebarTabsFor(workspace.kind);
  if (_shouldShowOutlineForOpenFile(workspace)) {
    final outlineIndex = tabs.indexOf(_SidebarTab.outline);
    if (outlineIndex >= 0) {
      return outlineIndex;
    }
  }
  return 0;
}

bool _shouldShowOutlineForOpenFile(Workspace workspace) {
  return workspace.activeFilePath != null && workspace.markdown != null;
}

bool _hasWorkspaceSidebar(Workspace workspace) {
  return _sidebarTabsFor(workspace.kind).isNotEmpty;
}

List<_SidebarTab> _sidebarTabsFor(WorkspaceKind kind) {
  return switch (kind) {
    WorkspaceKind.untitledMarkdown => const [_SidebarTab.outline],
    WorkspaceKind.singleMarkdown => const [_SidebarTab.outline],
    WorkspaceKind.markdownFolder => const [
      _SidebarTab.files,
      _SidebarTab.outline,
      _SidebarTab.git,
    ],
    WorkspaceKind.writersideModule => const [
      _SidebarTab.files,
      _SidebarTab.toc,
      _SidebarTab.outline,
      _SidebarTab.git,
    ],
  };
}

String _sidebarTabLabel(BuildContext context, _SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => context.l10n.files,
    _SidebarTab.toc => context.l10n.toc,
    _SidebarTab.outline => context.l10n.outline,
    _SidebarTab.git => context.l10n.git,
  };
}

IconData _sidebarTabIcon(_SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => BusyMarkGlyphs.documentOpen,
    _SidebarTab.toc => BusyMarkGlyphs.orderedList,
    _SidebarTab.outline => BusyMarkGlyphs.indent,
    _SidebarTab.git => BusyMarkGlyphs.history,
  };
}

String _sidebarTabShortcut(_SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => BusyMarkSidebarShortcutLabels.files,
    _SidebarTab.toc => BusyMarkSidebarShortcutLabels.toc,
    _SidebarTab.outline => BusyMarkSidebarShortcutLabels.outline,
    _SidebarTab.git => BusyMarkSidebarShortcutLabels.git,
  };
}

_SidebarTab? _sidebarShortcutTabFor(BusyMarkSidebarShortcutAction? action) {
  return switch (action) {
    BusyMarkSidebarShortcutAction.files => _SidebarTab.files,
    BusyMarkSidebarShortcutAction.toc => _SidebarTab.toc,
    BusyMarkSidebarShortcutAction.outline => _SidebarTab.outline,
    BusyMarkSidebarShortcutAction.git => _SidebarTab.git,
    _ => null,
  };
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.workspace,
    required this.tabs,
    required this.selectedTab,
    required this.showTabMenu,
    required this.onSelectTab,
  });

  final Workspace workspace;
  final List<_SidebarTab> tabs;
  final _SidebarTab? selectedTab;
  final bool showTabMenu;
  final ValueChanged<_SidebarTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: BusyMarkInsets.sidebarHeader,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _workspaceName(context, workspace),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BusyMarkSpacing.xs),
                Text(
                  _workspaceDetail(context, workspace),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (showTabMenu && selectedTab != null) ...[
            const SizedBox(width: BusyMarkSpacing.sm),
            BusyMarkHeaderPopupMenuButton<_SidebarTab>(
              tooltip: context.l10n.sidebarViewMenu,
              icon: _sidebarTabIcon(selectedTab!),
              transparent: true,
              borderRadius: BusyMarkRadius.nativeHeaderButton,
              itemBuilder: (context) => [
                for (final tab in tabs)
                  BusyMarkPopupMenuItem(
                    value: tab,
                    label: _sidebarTabLabel(context, tab),
                    icon: _sidebarTabIcon(tab),
                    shortcut: _sidebarTabShortcut(tab),
                    checked: tab == selectedTab,
                    trailingCheck: true,
                  ),
              ],
              onSelected: onSelectTab,
            ),
          ],
        ],
      ),
    );
  }

  String _workspaceName(BuildContext context, Workspace workspace) {
    if (workspace.kind == WorkspaceKind.untitledMarkdown) {
      final filePath = workspace.markdown?.filePath;
      return filePath == null || filePath.isEmpty
          ? context.l10n.untitledMarkdownFileName
          : filePath;
    }
    final path = workspace.rootPath;
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  String _workspaceDetail(BuildContext context, Workspace workspace) {
    if (workspace.kind == WorkspaceKind.untitledMarkdown) {
      return context.l10n.markdownUnsaved;
    }
    return context.l10n.workspaceDetail(
      _workspaceKindLabel(context, workspace.kind),
      workspace.files.length,
    );
  }

  String _workspaceKindLabel(BuildContext context, WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown => context.l10n.markdown,
      WorkspaceKind.singleMarkdown => context.l10n.markdown,
      WorkspaceKind.markdownFolder => context.l10n.folder,
      WorkspaceKind.writersideModule => context.l10n.writerside,
    };
  }
}

class _FilesTab extends ConsumerStatefulWidget {
  const _FilesTab({required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<_FilesTab> {
  late String _workspaceId;
  late Set<String> _expandedPaths;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _expandedPaths = _initialExpandedFileTreePaths(widget.workspace);
  }

  @override
  void didUpdateWidget(covariant _FilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _expandedPaths = _initialExpandedFileTreePaths(widget.workspace);
      return;
    }
    if (widget.workspace.activeFilePath != oldWidget.workspace.activeFilePath) {
      _expandedPaths.addAll(_activeFileAncestorPaths(widget.workspace));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildFileTree(widget.workspace.files);
    final entries = _visibleFileTreeEntries(tree, _expandedPaths);
    if (widget.workspace.files.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.folder,
        title: context.l10n.noFiles,
      );
    }
    return ListView.builder(
      padding: BusyMarkInsets.sidebarList,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final node = entry.node;
        final file = node.file;
        final expanded = _expandedPaths.contains(node.relativePath);
        final openable = file != null && _isOpenableTextDocument(file);
        return _SidebarTreeRow(
          title: node.name,
          depth: entry.depth,
          icon: _fileTreeIcon(node, expanded: expanded),
          hasChildren: node.isFolder && node.children.isNotEmpty,
          expanded: expanded,
          selected:
              file != null &&
              file.absolutePath == widget.workspace.activeFilePath,
          enabled: node.isFolder || openable,
          onTap: node.isFolder
              ? () {
                  setState(() {
                    if (expanded) {
                      _expandedPaths.remove(node.relativePath);
                    } else {
                      _expandedPaths.add(node.relativePath);
                    }
                  });
                }
              : openable
              ? () async {
                  if (await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
                    await ref
                        .read(workspaceControllerProvider.notifier)
                        .openActiveFile(file.absolutePath);
                    _clearGitDetailSelection(ref);
                  }
                }
              : null,
        );
      },
    );
  }
}

class _SidebarTreeRow extends StatelessWidget {
  const _SidebarTreeRow({
    required this.title,
    required this.depth,
    required this.icon,
    this.leading,
    this.hasChildren = false,
    this.expanded = false,
    this.selected = false,
    this.enabled = true,
    this.muted = false,
    this.onToggle,
    this.onTap,
  });

  final String title;
  final int depth;
  final IconData icon;
  final Widget? leading;
  final bool hasChildren;
  final bool expanded;
  final bool selected;
  final bool enabled;
  final bool muted;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final clickable = enabled && onTap != null;
    final foreground = !enabled || muted
        ? colors.disabledForeground
        : selected
        ? colors.foreground
        : colors.mutedForeground;
    final titleColor = !enabled || muted
        ? colors.disabledForeground
        : colors.foreground;
    final titleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: titleColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkStroke.hairline),
      child: Material(
        color: selected
            ? busyMarkSelectedBackground(context)
            : BusyMarkLinuxPalette.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: clickable
              ? busyMarkRowHoverColor(context)
              : BusyMarkLinuxPalette.transparent,
          onTap: clickable ? onTap : null,
          child: SizedBox(
            height: BusyMarkSizes.sidebarTreeRowHeight,
            child: Row(
              children: [
                SizedBox(
                  width:
                      BusyMarkSizes.sidebarTreeDepthBase +
                      depth * BusyMarkSizes.sidebarTreeDepthIndent,
                ),
                SizedBox.square(
                  dimension: BusyMarkSizes.sidebarTreeControl,
                  child: hasChildren
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enabled ? onToggle ?? onTap : null,
                          child: AnimatedRotation(
                            turns: expanded ? 0.25 : 0,
                            duration: BusyMarkMotion.sidebarExpand,
                            child: Icon(
                              YaruIcons.pan_end,
                              size: BusyMarkSizes.sidebarTreeArrow,
                              color: foreground,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                SizedBox.square(
                  dimension: BusyMarkSizes.sidebarTreeControl,
                  child: Center(
                    child:
                        leading ??
                        Icon(
                          icon,
                          size: BusyMarkSizes.iconSm,
                          color: foreground,
                        ),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _fileTreeIcon(_FileTreeNode node, {required bool expanded}) {
  if (node.isFolder) {
    return expanded ? YaruIcons.folder_open : YaruIcons.folder;
  }
  return switch (node.file!.kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic => YaruIcons.text_editor,
    DocumentKind.writersideXmlTopic => YaruIcons.document,
    DocumentKind.tree => BusyMarkGlyphs.tree,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => BusyMarkGlyphs.symbols,
    DocumentKind.categories => BusyMarkGlyphs.category,
    DocumentKind.image => BusyMarkGlyphs.image,
    _ => YaruIcons.document,
  };
}

bool _isOpenableTextDocument(DocumentFile file) {
  return switch (file.kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic ||
    DocumentKind.writersideXmlTopic ||
    DocumentKind.tree ||
    DocumentKind.config ||
    DocumentKind.variables ||
    DocumentKind.categories ||
    DocumentKind.resource => true,
    DocumentKind.image || DocumentKind.unknown => false,
  };
}

class _FileTreeNode {
  const _FileTreeNode({
    required this.name,
    required this.relativePath,
    required this.children,
    this.file,
  });

  final String name;
  final String relativePath;
  final List<_FileTreeNode> children;
  final DocumentFile? file;

  bool get isFolder => file == null;
}

class _MutableFileTreeNode {
  _MutableFileTreeNode({required this.name, required this.relativePath});

  final String name;
  final String relativePath;
  DocumentFile? file;
  final children = <String, _MutableFileTreeNode>{};
}

class _FileTreeEntry {
  const _FileTreeEntry({required this.node, required this.depth});

  final _FileTreeNode node;
  final int depth;
}

List<_FileTreeNode> _buildFileTree(List<DocumentFile> files) {
  final root = _MutableFileTreeNode(name: '', relativePath: '');
  final sortedFiles = [...files]
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));

  for (final file in sortedFiles) {
    final parts = file.relativePath
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    var parent = root;
    for (var index = 0; index < parts.length; index++) {
      final name = parts[index];
      final relativePath = parts.take(index + 1).join('/');
      final node = parent.children.putIfAbsent(
        name,
        () => _MutableFileTreeNode(name: name, relativePath: relativePath),
      );
      if (index == parts.length - 1) {
        node.file = file;
      }
      parent = node;
    }
  }

  return root.children.values.map(_immutableFileTreeNode).toList()
    ..sort(_compareFileTreeNodes);
}

_FileTreeNode _immutableFileTreeNode(_MutableFileTreeNode node) {
  final children = node.children.values.map(_immutableFileTreeNode).toList()
    ..sort(_compareFileTreeNodes);
  return _FileTreeNode(
    name: node.name,
    relativePath: node.relativePath,
    file: node.file,
    children: children,
  );
}

int _compareFileTreeNodes(_FileTreeNode a, _FileTreeNode b) {
  if (a.isFolder != b.isFolder) {
    return a.isFolder ? -1 : 1;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

List<_FileTreeEntry> _visibleFileTreeEntries(
  List<_FileTreeNode> nodes,
  Set<String> expandedPaths,
) {
  final entries = <_FileTreeEntry>[];
  void visit(_FileTreeNode node, int depth) {
    entries.add(_FileTreeEntry(node: node, depth: depth));
    if (!node.isFolder || !expandedPaths.contains(node.relativePath)) {
      return;
    }
    for (final child in node.children) {
      visit(child, depth + 1);
    }
  }

  for (final node in nodes) {
    visit(node, 0);
  }
  return entries;
}

Set<String> _initialExpandedFileTreePaths(Workspace workspace) {
  final expanded = <String>{};
  for (final file in workspace.files) {
    final parts = file.relativePath.split('/').where((part) => part.isNotEmpty);
    if (parts.length > 1) {
      expanded.add(parts.first);
    }
  }
  expanded.addAll(_activeFileAncestorPaths(workspace));
  return expanded;
}

Set<String> _activeFileAncestorPaths(Workspace workspace) {
  final activeFilePath = workspace.activeFilePath;
  if (activeFilePath == null) {
    return const {};
  }

  String? relativePath;
  for (final file in workspace.files) {
    if (file.absolutePath == activeFilePath) {
      relativePath = file.relativePath;
      break;
    }
  }
  if (relativePath == null) {
    return const {};
  }

  final parts = relativePath
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList();
  final ancestors = <String>{};
  for (var index = 0; index < parts.length - 1; index++) {
    ancestors.add(parts.take(index + 1).join('/'));
  }
  return ancestors;
}

class _TocTab extends ConsumerStatefulWidget {
  const _TocTab({required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<_TocTab> createState() => _TocTabState();
}

class _TocTabState extends ConsumerState<_TocTab> {
  late String _workspaceId;
  late Set<String> _expandedNodeKeys;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _expandedNodeKeys = _initialExpandedTocNodeKeys(widget.workspace);
  }

  @override
  void didUpdateWidget(covariant _TocTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _expandedNodeKeys = _initialExpandedTocNodeKeys(widget.workspace);
      return;
    }
    if (widget.workspace.activeFilePath != oldWidget.workspace.activeFilePath) {
      _expandedNodeKeys.addAll(_activeTocAncestorKeys(widget.workspace));
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.workspace.writersideModule;
    if (module == null || module.instances.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.tree,
        title: context.l10n.noWritersideToc,
      );
    }
    final instance = module.instances.first;
    final entries = _visibleTocTreeEntries(
      instance.tocRoots,
      _expandedNodeKeys,
    );
    final activeTopicReference = _activeTocTopicReference(widget.workspace);
    return ListView.builder(
      padding: BusyMarkInsets.sidebarList,
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TocHeader(
            instanceName: instance.name,
            canCreateChild: activeTopicReference != null,
            onCreateTopic: () => _showCreateTopicDialog(
              context,
              placement: activeTopicReference == null
                  ? WritersideTopicCreatePlacement.root
                  : WritersideTopicCreatePlacement.sibling,
              referenceTopic: activeTopicReference,
            ),
            onCreateChildTopic: activeTopicReference == null
                ? null
                : () => _showCreateTopicDialog(
                    context,
                    placement: WritersideTopicCreatePlacement.child,
                    referenceTopic: activeTopicReference,
                  ),
          );
        }
        final entry = entries[index - 1];
        final node = entry.node;
        final key = _tocNodeKey(node);
        final expanded = _expandedNodeKeys.contains(key);
        final hasChildren = node.children.isNotEmpty;
        final topic = node.topicFileName == null
            ? null
            : module.topicByReference(node.topicFileName!)?.filePath;
        final label =
            node.tocTitle ??
            node.topicFileName ??
            node.href ??
            context.l10n.tocSection;
        void toggle() {
          setState(() {
            if (expanded) {
              _expandedNodeKeys.remove(key);
            } else {
              _expandedNodeKeys.add(key);
            }
          });
        }

        return _SidebarTreeRow(
          title: label,
          enabled: topic != null || hasChildren,
          selected: topic == widget.workspace.activeFilePath,
          depth: entry.depth,
          icon: node.href != null
              ? BusyMarkGlyphs.externalLink
              : BusyMarkGlyphs.document,
          hasChildren: hasChildren,
          expanded: expanded,
          muted: node.hidden,
          onToggle: hasChildren ? toggle : null,
          onTap: topic != null
              ? () async {
                  if (await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
                    await ref
                        .read(workspaceControllerProvider.notifier)
                        .openActiveFile(topic);
                    _clearGitDetailSelection(ref);
                  }
                }
              : hasChildren
              ? toggle
              : null,
        );
      },
    );
  }

  Future<void> _showCreateTopicDialog(
    BuildContext context, {
    required WritersideTopicCreatePlacement placement,
    required String? referenceTopic,
  }) async {
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    await showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (dialogContext) => _CreateWritersideTopicDialog(
        workspace: widget.workspace,
        placement: placement,
        referenceTopic: referenceTopic,
      ),
    );
  }
}

class _TocHeader extends StatelessWidget {
  const _TocHeader({
    required this.instanceName,
    required this.canCreateChild,
    required this.onCreateTopic,
    required this.onCreateChildTopic,
  });

  final String instanceName;
  final bool canCreateChild;
  final VoidCallback onCreateTopic;
  final VoidCallback? onCreateChildTopic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BusyMarkInsets.tocHeader,
      child: Row(
        children: [
          Expanded(
            child: Text(
              instanceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: busyMarkSectionHeaderStyle(context),
            ),
          ),
          BusyMarkHeaderIconButton(
            tooltip: context.l10n.newTopic,
            icon: BusyMarkGlyphs.newDocument,
            transparent: true,
            onPressed: onCreateTopic,
          ),
          const SizedBox(width: BusyMarkSpacing.xs),
          BusyMarkHeaderIconButton(
            tooltip: context.l10n.newChildTopic,
            icon: BusyMarkGlyphs.tree,
            transparent: true,
            onPressed: canCreateChild ? onCreateChildTopic : null,
          ),
        ],
      ),
    );
  }
}

class _CreateWritersideTopicDialog extends ConsumerStatefulWidget {
  const _CreateWritersideTopicDialog({
    required this.workspace,
    required this.placement,
    required this.referenceTopic,
  });

  final Workspace workspace;
  final WritersideTopicCreatePlacement placement;
  final String? referenceTopic;

  @override
  ConsumerState<_CreateWritersideTopicDialog> createState() =>
      _CreateWritersideTopicDialogState();
}

class _CreateWritersideTopicDialogState
    extends ConsumerState<_CreateWritersideTopicDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _fileNameController;
  var _format = WritersideTopicFormat.markdown;
  var _fileNameEdited = false;
  var _syncingFileName = false;
  var _creating = false;
  String? _creationError;
  var _localizedDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController()
      ..addListener(_handleTitleChanged);
    _fileNameController = TextEditingController(text: 'new-topic.md')
      ..addListener(_handleFileNameChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) {
      return;
    }
    _localizedDefaultsApplied = true;
    _titleController.text = context.l10n.defaultNewTopicTitle;
  }

  @override
  Widget build(BuildContext context) {
    final titleError = _titleError(context);
    final fileNameError = _fileNameError(context);
    final canCreate = !_creating && titleError == null && fileNameError == null;
    return BusyMarkDialogShell(
      title: _dialogTitle(context),
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: canCreate ? _submit : null,
          child: Text(_creating ? context.l10n.creating : context.l10n.create),
        ),
      ],
      children: [
        TextField(
          controller: _titleController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.topicTitle,
            errorText: titleError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        TextField(
          controller: _fileNameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canCreate) {
              _submit();
            }
          },
          decoration: InputDecoration(
            labelText: context.l10n.fileName,
            errorText: fileNameError,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        SegmentedButton<WritersideTopicFormat>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: WritersideTopicFormat.markdown,
              label: Text(context.l10n.markdown),
            ),
            ButtonSegment(
              value: WritersideTopicFormat.xml,
              label: Text(context.l10n.xml),
            ),
          ],
          selected: {_format},
          onSelectionChanged: (value) => _setFormat(value.first),
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
        if (_creationError != null) ...[
          _DialogMessage(message: _creationError!),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
        Text(
          context.l10n.location,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: BusyMarkSurfaceColors.of(context).mutedForeground,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: BusyMarkSurfaceColors.of(context).control,
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            border: Border.all(
              color: BusyMarkSurfaceColors.of(context).subtleBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.md),
            child: SelectableText(
              _targetPath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  String _dialogTitle(BuildContext context) {
    return widget.placement == WritersideTopicCreatePlacement.child
        ? context.l10n.newChildTopic
        : context.l10n.newTopic;
  }

  String? _titleError(BuildContext context) {
    if (_titleController.text.trim().isEmpty) {
      return context.l10n.topicTitleRequired;
    }
    return null;
  }

  String? _fileNameError(BuildContext context) {
    final value = _fileNameController.text.trim();
    if (value.isEmpty) {
      return context.l10n.fileNameRequired;
    }
    if (value == '.' ||
        value == '..' ||
        p.isAbsolute(value) ||
        value.contains('/') ||
        value.contains(r'\') ||
        value.contains('..')) {
      return context.l10n.useSingleSafeFileName;
    }
    final expectedExtension = _extensionFor(_format);
    final extension = p.extension(value).toLowerCase();
    if (extension.isNotEmpty && extension != expectedExtension) {
      return context.l10n.useExpectedExtension(expectedExtension);
    }
    final id = p.basenameWithoutExtension(value);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      return context.l10n.useIdentifierCharacters;
    }
    final existingIds = widget.workspace.writersideModule?.topics
        .map((topic) => topic.id)
        .toSet();
    if (existingIds?.contains(id) ?? false) {
      return context.l10n.topicIdAlreadyExists;
    }
    return null;
  }

  String get _targetPath {
    final module = widget.workspace.writersideModule;
    final topicsDir = module?.config.topicsDir ?? 'topics';
    return p.join(topicsDir, _effectiveFileName);
  }

  String get _effectiveFileName {
    final value = _fileNameController.text.trim();
    if (p.extension(value).isEmpty) {
      return '$value${_extensionFor(_format)}';
    }
    return value;
  }

  void _handleTitleChanged() {
    _creationError = null;
    if (!_fileNameEdited) {
      _syncingFileName = true;
      _fileNameController.text =
          '${_slugTopicName(_titleController.text)}${_extensionFor(_format)}';
      _syncingFileName = false;
    }
    setState(() {});
  }

  void _handleFileNameChanged() {
    _creationError = null;
    if (!_syncingFileName) {
      _fileNameEdited = true;
    }
    setState(() {});
  }

  void _setFormat(WritersideTopicFormat value) {
    final previousExtension = _extensionFor(_format);
    _format = value;
    final nextExtension = _extensionFor(value);
    if (!_fileNameEdited) {
      _syncingFileName = true;
      _fileNameController.text =
          '${_slugTopicName(_titleController.text)}$nextExtension';
      _syncingFileName = false;
    } else {
      final text = _fileNameController.text.trim();
      if (p.extension(text).toLowerCase() == previousExtension) {
        _syncingFileName = true;
        _fileNameController.text =
            '${p.basenameWithoutExtension(text)}'
            '$nextExtension';
        _syncingFileName = false;
      }
    }
    _creationError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_creating ||
        _titleError(context) != null ||
        _fileNameError(context) != null) {
      return;
    }
    setState(() {
      _creating = true;
      _creationError = null;
    });
    final created = await ref
        .read(workspaceControllerProvider.notifier)
        .createWritersideTopic(
          WritersideTopicCreateRequest(
            title: _titleController.text.trim(),
            fileName: _effectiveFileName,
            format: _format,
            placement: widget.placement,
            referenceTopic: widget.referenceTopic,
          ),
        );
    if (!mounted) {
      return;
    }
    if (created) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _creating = false;
      final message = ref.read(workspaceControllerProvider).message;
      _creationError = message == null
          ? context.l10n.createWritersideTopicFailed
          : localizeWorkspaceMessage(context, message);
    });
  }

  String _slugTopicName(String value) {
    final slug = slugForHeading(value);
    return slug.isEmpty ? 'new-topic' : slug;
  }

  String _extensionFor(WritersideTopicFormat format) {
    return switch (format) {
      WritersideTopicFormat.markdown => '.md',
      WritersideTopicFormat.xml => '.topic',
    };
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.admonitionWarning,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(BusyMarkGlyphs.warning),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _TocTreeEntry {
  const _TocTreeEntry({required this.node, required this.depth});

  final TocNode node;
  final int depth;
}

List<_TocTreeEntry> _visibleTocTreeEntries(
  List<TocNode> nodes,
  Set<String> expandedNodeKeys,
) {
  final entries = <_TocTreeEntry>[];
  void visit(TocNode node, int depth) {
    entries.add(_TocTreeEntry(node: node, depth: depth));
    if (!expandedNodeKeys.contains(_tocNodeKey(node))) {
      return;
    }
    for (final child in node.children) {
      visit(child, depth + 1);
    }
  }

  for (final node in nodes) {
    visit(node, 0);
  }
  return entries;
}

Set<String> _initialExpandedTocNodeKeys(Workspace workspace) {
  final module = workspace.writersideModule;
  if (module == null || module.instances.isEmpty) {
    return const {};
  }
  return {
    for (final node in module.instances.first.tocRoots.expand(
      (node) => node.flatten(),
    ))
      if (node.children.isNotEmpty) _tocNodeKey(node),
  }..addAll(_activeTocAncestorKeys(workspace));
}

Set<String> _activeTocAncestorKeys(Workspace workspace) {
  final module = workspace.writersideModule;
  final activeFilePath = workspace.activeFilePath;
  if (module == null || module.instances.isEmpty || activeFilePath == null) {
    return const {};
  }
  final ancestors = <String>{};
  bool visit(TocNode node) {
    final topic = node.topicFileName == null
        ? null
        : module.topicByReference(node.topicFileName!)?.filePath;
    if (topic == activeFilePath) {
      return true;
    }
    for (final child in node.children) {
      if (visit(child)) {
        ancestors.add(_tocNodeKey(node));
        return true;
      }
    }
    return false;
  }

  for (final node in module.instances.first.tocRoots) {
    visit(node);
  }
  return ancestors;
}

String? _activeTocTopicReference(Workspace workspace) {
  final module = workspace.writersideModule;
  final activeFilePath = workspace.activeFilePath;
  if (module == null || module.instances.isEmpty || activeFilePath == null) {
    return null;
  }
  for (final node in module.instances.first.tocRoots.expand(
    (node) => node.flatten(),
  )) {
    final topicReference = node.topicFileName;
    if (topicReference != null &&
        module.topicByReference(topicReference)?.filePath == activeFilePath) {
      return topicReference;
    }
  }
  return null;
}

String _tocNodeKey(TocNode node) {
  return node.id ??
      node.topicFileName ??
      node.href ??
      '${node.span.filePath}:${node.span.startLine}:${node.span.startColumn}:${node.tocTitle ?? ''}';
}

class _OutlineTab extends ConsumerStatefulWidget {
  const _OutlineTab({required this.workspace});

  final Workspace workspace;

  @override
  ConsumerState<_OutlineTab> createState() => _OutlineTabState();
}

class _OutlineTabState extends ConsumerState<_OutlineTab> {
  late String _outlineStateKey;
  late Set<String> _expandedNodeKeys;

  @override
  void initState() {
    super.initState();
    _outlineStateKey = _outlineStateSignature(widget.workspace);
    _expandedNodeKeys = _initialExpandedOutlineNodeKeys(widget.workspace);
  }

  @override
  void didUpdateWidget(covariant _OutlineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _outlineStateSignature(widget.workspace);
    if (nextKey != _outlineStateKey) {
      _outlineStateKey = nextKey;
      _expandedNodeKeys = _initialExpandedOutlineNodeKeys(widget.workspace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headings = widget.workspace.markdown?.headings ?? const [];
    if (headings.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.font,
        title: context.l10n.noOutline,
      );
    }
    final activeFilePath =
        widget.workspace.activeFilePath ?? widget.workspace.markdown?.filePath;
    final tree = _buildOutlineTree(headings);
    final entries = _visibleOutlineTreeEntries(tree, _expandedNodeKeys);
    return ListView.builder(
      padding: BusyMarkInsets.sidebarList,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final node = entry.node;
        final heading = node.heading;
        final key = _outlineNodeKey(heading);
        final expanded = _expandedNodeKeys.contains(key);
        final hasChildren = node.children.isNotEmpty;
        void toggle() {
          setState(() {
            if (expanded) {
              _expandedNodeKeys.remove(key);
            } else {
              _expandedNodeKeys.add(key);
            }
          });
        }

        return _SidebarTreeRow(
          title: heading.text,
          depth: entry.depth,
          icon: BusyMarkGlyphs.tag,
          leading: _HeadingBadge(level: heading.level),
          hasChildren: hasChildren,
          expanded: expanded,
          onToggle: hasChildren ? toggle : null,
          onTap: activeFilePath == null
              ? null
              : () {
                  ref
                      .read(_outlineNavigationTargetProvider.notifier)
                      .set(
                        _OutlineNavigationTarget(
                          filePath: activeFilePath,
                          headingId: heading.id,
                          line: heading.span.startLine,
                        ),
                      );
                },
        );
      },
    );
  }
}

class _OutlineTreeNode {
  const _OutlineTreeNode({required this.heading, required this.children});

  final MarkdownHeading heading;
  final List<_OutlineTreeNode> children;
}

class _MutableOutlineTreeNode {
  _MutableOutlineTreeNode(this.heading);

  final MarkdownHeading heading;
  final children = <_MutableOutlineTreeNode>[];
}

class _OutlineTreeEntry {
  const _OutlineTreeEntry({required this.node, required this.depth});

  final _OutlineTreeNode node;
  final int depth;
}

List<_OutlineTreeNode> _buildOutlineTree(List<MarkdownHeading> headings) {
  final roots = <_MutableOutlineTreeNode>[];
  final stack = <_MutableOutlineTreeNode>[];

  for (final heading in headings) {
    final node = _MutableOutlineTreeNode(heading);
    while (stack.isNotEmpty && stack.last.heading.level >= heading.level) {
      stack.removeLast();
    }
    if (stack.isEmpty) {
      roots.add(node);
    } else {
      stack.last.children.add(node);
    }
    stack.add(node);
  }

  return roots.map(_immutableOutlineTreeNode).toList();
}

_OutlineTreeNode _immutableOutlineTreeNode(_MutableOutlineTreeNode node) {
  return _OutlineTreeNode(
    heading: node.heading,
    children: node.children.map(_immutableOutlineTreeNode).toList(),
  );
}

List<_OutlineTreeEntry> _visibleOutlineTreeEntries(
  List<_OutlineTreeNode> nodes,
  Set<String> expandedNodeKeys,
) {
  final entries = <_OutlineTreeEntry>[];
  void visit(_OutlineTreeNode node) {
    entries.add(
      _OutlineTreeEntry(
        node: node,
        depth: (node.heading.level - 1).clamp(0, 5).toInt(),
      ),
    );
    if (!expandedNodeKeys.contains(_outlineNodeKey(node.heading))) {
      return;
    }
    for (final child in node.children) {
      visit(child);
    }
  }

  for (final node in nodes) {
    visit(node);
  }
  return entries;
}

Set<String> _initialExpandedOutlineNodeKeys(Workspace workspace) {
  final headings = workspace.markdown?.headings ?? const <MarkdownHeading>[];
  return {
    for (final node in _flattenOutlineTree(_buildOutlineTree(headings)))
      if (node.children.isNotEmpty) _outlineNodeKey(node.heading),
  };
}

Iterable<_OutlineTreeNode> _flattenOutlineTree(
  List<_OutlineTreeNode> nodes,
) sync* {
  for (final node in nodes) {
    yield node;
    yield* _flattenOutlineTree(node.children);
  }
}

String _outlineNodeKey(MarkdownHeading heading) {
  return '${heading.id}:${heading.span.startOffset}';
}

String _outlineStateSignature(Workspace workspace) {
  final headings = workspace.markdown?.headings ?? const <MarkdownHeading>[];
  return [
    workspace.activeFilePath ?? workspace.markdown?.filePath ?? workspace.id,
    for (final heading in headings)
      '${heading.id}:${heading.level}:${heading.span.startOffset}',
  ].join('|');
}

class _HeadingBadge extends StatelessWidget {
  const _HeadingBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
      ),
      child: Center(
        child: Text(
          context.l10n.headingLevelAbbreviation(level),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.mutedForeground),
            const SizedBox(height: BusyMarkSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

bool _shouldShowEditorTabs(Workspace workspace) {
  return switch (workspace.kind) {
        WorkspaceKind.markdownFolder || WorkspaceKind.writersideModule => true,
        WorkspaceKind.untitledMarkdown || WorkspaceKind.singleMarkdown => false,
      } &&
      workspace.openFilePaths.isNotEmpty;
}

class _EditorTabStrip extends ConsumerWidget {
  const _EditorTabStrip({required this.state});

  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = state.workspace;
    if (workspace == null || workspace.openFilePaths.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: SizedBox(
        height: BusyMarkSizes.paneHeaderHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            BusyMarkSpacing.sm,
            BusyMarkSpacing.xs,
            BusyMarkSpacing.sm,
            0,
          ),
          itemBuilder: (context, index) {
            final path = workspace.openFilePaths[index];
            final active = path == workspace.activeFilePath;
            return _EditorTab(
              workspace: workspace,
              path: path,
              active: active,
              dirty: active && state.isDirty,
              canClose: true,
              onSelected: () async {
                if (active) {
                  _clearGitDetailSelection(ref);
                  return;
                }
                if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
                    !context.mounted) {
                  return;
                }
                await ref
                    .read(workspaceControllerProvider.notifier)
                    .openActiveFile(path);
                _clearGitDetailSelection(ref);
              },
              onClose: () async {
                if (active &&
                    (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
                        !context.mounted)) {
                  return;
                }
                await ref
                    .read(workspaceControllerProvider.notifier)
                    .closeOpenFileTab(path);
                _clearGitDetailSelection(ref);
              },
            );
          },
          separatorBuilder: (context, index) =>
              const SizedBox(width: BusyMarkSpacing.xs),
          itemCount: workspace.openFilePaths.length,
        ),
      ),
    );
  }
}

class _EditorTab extends StatelessWidget {
  const _EditorTab({
    required this.workspace,
    required this.path,
    required this.active,
    required this.dirty,
    required this.canClose,
    required this.onSelected,
    required this.onClose,
  });

  final Workspace workspace;
  final String path;
  final bool active;
  final bool dirty;
  final bool canClose;
  final VoidCallback onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final file = _documentFileForPath(workspace, path);
    final icon = _documentKindIcon(file?.kind ?? DocumentKind.markdown);
    final foreground = active ? colors.foreground : colors.mutedForeground;
    final background = active ? colors.view : BusyMarkLinuxPalette.transparent;
    final borderColor = active
        ? colors.subtleBorder
        : BusyMarkLinuxPalette.transparent;
    return Material(
      color: background,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(BusyMarkRadius.sm),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BusyMarkRadius.sm),
        ),
        hoverColor: colors.controlHover,
        onTap: onSelected,
        child: Container(
          height: BusyMarkSizes.paneHeaderHeight - BusyMarkSpacing.xs,
          constraints: const BoxConstraints(minWidth: 112, maxWidth: 240),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BusyMarkRadius.sm),
            ),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsetsDirectional.only(
            start: BusyMarkSpacing.sm,
            end: BusyMarkSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dirty) ...[
                Container(
                  width: BusyMarkSizes.markerDot,
                  height: BusyMarkSizes.markerDot,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ] else ...[
                Icon(icon, size: BusyMarkSizes.iconSm, color: foreground),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
              Flexible(
                child: Text(
                  _relativeDocumentPath(workspace, path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (canClose) ...[
                const SizedBox(width: BusyMarkSpacing.xs),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(BusyMarkGlyphs.clear),
                  iconSize: 13,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 24,
                    height: 24,
                  ),
                  visualDensity: VisualDensity.compact,
                  color: foreground,
                  onPressed: onClose,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

DocumentFile? _documentFileForPath(Workspace workspace, String path) {
  for (final file in workspace.files) {
    if (file.absolutePath == path) {
      return file;
    }
  }
  return null;
}

class _EditorPreviewSplit extends ConsumerStatefulWidget {
  const _EditorPreviewSplit({
    required this.state,
    required this.viewMode,
    required this.editorFontSize,
    required this.editorToolbarPlacement,
    required this.wordWrap,
  });

  final WorkspaceState state;
  final DocumentViewModePreference viewMode;
  final double editorFontSize;
  final EditorToolbarPlacement editorToolbarPlacement;
  final bool wordWrap;

  @override
  ConsumerState<_EditorPreviewSplit> createState() =>
      _EditorPreviewSplitState();
}

class _EditorPreviewSplitState extends ConsumerState<_EditorPreviewSplit> {
  late BusyMarkSourceEditingController _controller;
  late final FocusNode _sourceFocusNode;
  late final ScrollController _sourceScrollController;
  late final ScrollController _previewScrollController;
  late UndoHistoryController _sourceUndoController;
  final _sourceEditorKey = GlobalKey();
  final _previewHeadingKeys = <String, GlobalKey>{};
  final _previewSearchKeys = <int, GlobalKey>{};
  final _foldedRegionKeys = <String>{};
  String _lastPath = '';
  var _previewSearchScrollRequest = 0;
  BusyDocument? _cachedWysiwygDocument;
  String? _cachedWysiwygPath;
  String? _cachedWysiwygSource;
  String? _wysiwygScrollHeadingId;
  String? _wysiwygSearchQuery;
  var _wysiwygScrollRequest = 0;

  @override
  void initState() {
    super.initState();
    _controller = BusyMarkSourceEditingController(
      text: widget.state.activeText,
      language: _sourceSyntaxLanguage(widget.state.workspace),
    )..renderText = false;
    _sourceFocusNode = FocusNode(onKeyEvent: _handleSourceKeyEvent);
    _sourceScrollController = ScrollController();
    _previewScrollController = ScrollController();
    _sourceUndoController = UndoHistoryController();
    _lastPath = widget.state.workspace?.activeFilePath ?? '';
  }

  KeyEventResult _handleSourceKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (BusyMarkAppShortcutActivators.find.accepts(event, keyboard)) {
      ref.read(workspaceSearchOpenRequestProvider.notifier).request();
      return KeyEventResult.handled;
    }
    if (_isPlainTabKey(keyboard, key)) {
      _insertSourceTab();
      return KeyEventResult.handled;
    }
    if (_isPlainShiftTabKey(keyboard, key)) {
      _outdentSourceSelection();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      ref.read(workspaceSearchCloseRequestProvider.notifier).request();
      return KeyEventResult.handled;
    }
    final shortcutAction = BusyMarkEditorShortcutActivators.actionForKeyEvent(
      event,
      keyboard,
    );
    if (shortcutAction != null) {
      _applySourceEditorShortcutAction(shortcutAction);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant _EditorPreviewSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.state.workspace?.activeFilePath ?? '';
    final language = _sourceSyntaxLanguage(widget.state.workspace);
    if (path != _lastPath) {
      _lastPath = path;
      _clearWysiwygCache();
      _foldedRegionKeys.clear();
      _previewHeadingKeys.clear();
      _previewSearchKeys.clear();
      _wysiwygScrollHeadingId = null;
      _wysiwygSearchQuery = null;
      _wysiwygScrollRequest = 0;
      _replaceSourceController(
        text: widget.state.activeText,
        language: language,
      );
    } else if (widget.state.activeText != oldWidget.state.activeText &&
        !_sourceFocusNode.hasFocus) {
      _controller.language = language;
      _controller.text = widget.state.activeText;
    } else {
      _controller.language = language;
    }
    if (oldWidget.viewMode == DocumentViewModePreference.editor &&
        widget.viewMode != DocumentViewModePreference.editor &&
        widget.viewMode != DocumentViewModePreference.source &&
        widget.state.workspace != null &&
        widget.state.isDirty) {
      final activeText = widget.state.activeText;
      final sourceFilePath = _activeEditorPath();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(workspaceControllerProvider.notifier)
            .updateActiveText(activeText, sourceFilePath: sourceFilePath);
      });
    }
  }

  @override
  void dispose() {
    _previewScrollController.dispose();
    _sourceScrollController.dispose();
    _sourceFocusNode.dispose();
    _sourceUndoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(_outlineNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (next.filePath != widget.state.workspace?.activeFilePath) {
        return;
      }
      _scrollToOutlineTarget(next);
    });
    ref.listen(_sourceNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (next.filePath != widget.state.workspace?.activeFilePath) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollSourceToLine(next.line);
        }
      });
    });
    ref.listen(_searchNavigationTargetProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (next.filePath != widget.state.workspace?.activeFilePath &&
          next.filePath != widget.state.workspace?.markdown?.filePath) {
        return;
      }
      _scrollToSearchTarget(next);
    });
    final colors = BusyMarkSurfaceColors.of(context);
    final editorVisible = widget.viewMode == DocumentViewModePreference.editor;
    final wysiwygDocument =
        editorVisible && _canUseWysiwyg(widget.state.workspace)
        ? _wysiwygDocument()
        : null;
    final wysiwygVisible =
        editorVisible &&
        _canUseWysiwyg(widget.state.workspace) &&
        wysiwygDocument != null;
    final sourceVisible =
        widget.viewMode != DocumentViewModePreference.preview &&
        !wysiwygVisible;
    final previewVisible =
        widget.viewMode != DocumentViewModePreference.source && !editorVisible;
    final activeEditorPath = _activeEditorPath();
    final foldRegions = _syncSourceFoldRegions();
    final sourceStrutStyle = _sourceStrutStyle(
      folded: _foldedRegionKeys.isNotEmpty,
    );
    final sourceLineHeight = _sourceLineHeight(context, sourceStrutStyle);
    _controller
      ..renderText = false
      ..visualMarkdown = false;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Row(
        children: [
          if (wysiwygVisible)
            Expanded(
              child: BusyMarkWysiwygEditor(
                document: wysiwygDocument,
                workspaceRoot: _imageWorkspaceRoot(widget.state.workspace),
                writersideRoot:
                    widget.state.workspace?.writersideModule?.rootPath,
                imagesDir:
                    widget
                        .state
                        .workspace
                        ?.writersideModule
                        ?.config
                        .imagesDir ??
                    'images',
                onDocumentChanged: _cacheWysiwygDocument,
                onSourceChanged: _handleWysiwygSourceChanged,
                toolbarPlacement: widget.editorToolbarPlacement,
                scrollToHeadingId: _wysiwygScrollHeadingId,
                scrollToSearchQuery: _wysiwygSearchQuery,
                scrollRequest: _wysiwygScrollRequest,
                onOpenSearch: () => ref
                    .read(workspaceSearchOpenRequestProvider.notifier)
                    .request(),
                onCloseSearch: () => ref
                    .read(workspaceSearchCloseRequestProvider.notifier)
                    .request(),
              ),
            ),
          if (sourceVisible)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(color: colors.view),
                child: _SourceEditorFrame(
                  controller: _controller,
                  scrollController: _sourceScrollController,
                  lineHeight: sourceLineHeight,
                  textStyle: _sourceTextStyle,
                  strutStyle: sourceStrutStyle,
                  collapsedRegionKeys: _foldedRegionKeys,
                  foldRegions: foldRegions,
                  onToggleFold: _toggleSourceFold,
                  child: SizedBox(
                    key: _sourceEditorKey,
                    child: KeyedSubtree(
                      key: ValueKey(activeEditorPath),
                      child: Shortcuts(
                        shortcuts: BusyMarkEditorShortcutActivators.intentMap(
                          _SourceEditorShortcutIntent.new,
                        ),
                        child: Actions(
                          actions: {
                            _SourceEditorShortcutIntent:
                                CallbackAction<_SourceEditorShortcutIntent>(
                                  onInvoke: (intent) {
                                    _applySourceEditorShortcutAction(
                                      intent.action,
                                    );
                                    return null;
                                  },
                                ),
                          },
                          child: TextField(
                            controller: _controller,
                            undoController: _sourceUndoController,
                            focusNode: _sourceFocusNode,
                            scrollController: _sourceScrollController,
                            keyboardType: widget.wordWrap
                                ? TextInputType.multiline
                                : TextInputType.text,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: _sourceTextStyle,
                            strutStyle: sourceStrutStyle,
                            selectionHeightStyle: BoxHeightStyle.max,
                            selectionWidthStyle: BoxWidthStyle.tight,
                            cursorColor: colors.foreground.withValues(
                              alpha: BusyMarkAlpha.sourceCursor,
                            ),
                            cursorHeight:
                                widget.editorFontSize *
                                BusyMarkTypography.sourceCursorHeightScale,
                            cursorWidth: BusyMarkStroke.sourceCursor,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              fillColor: BusyMarkLinuxPalette.transparent,
                              hoverColor: BusyMarkLinuxPalette.transparent,
                              focusColor: BusyMarkLinuxPalette.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: BusyMarkInsets.sourceEditor,
                            ),
                            onChanged: (value) => _handleSourceChanged(
                              value,
                              sourceFilePath: activeEditorPath,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (sourceVisible && previewVisible)
            VerticalDivider(
              width: BusyMarkStroke.hairline,
              color: colors.subtleBorder,
            ),
          if (previewVisible)
            Expanded(
              child: _PreviewPane(
                preview: widget.state.preview,
                workspace: widget.state.workspace,
                controller: _previewScrollController,
                headingKeys: _previewHeadingKeys,
                searchKeys: _previewSearchKeys,
              ),
            ),
        ],
      ),
    );
  }

  List<SourceFoldRegion> _syncSourceFoldRegions() {
    final foldRegions = sourceFoldRegions(
      _controller.text,
      _controller.language,
    );
    final validKeys = {for (final region in foldRegions) region.key};
    _foldedRegionKeys.removeWhere((key) => !validKeys.contains(key));
    _applyFoldedRegions();
    return foldRegions;
  }

  void _applyFoldedRegions() {
    _controller.setFoldedRegions(
      collapsedSourceFoldRegions(
        _controller.text,
        _controller.language,
        _foldedRegionKeys,
      ),
    );
  }

  void _toggleSourceFold(SourceFoldRegion region) {
    setState(() {
      if (_foldedRegionKeys.contains(region.key)) {
        _foldedRegionKeys.remove(region.key);
      } else {
        _foldedRegionKeys.add(region.key);
      }
      _applyFoldedRegions();
    });
  }

  void _handleSourceChanged(
    String value, {
    bool updatePreview = true,
    String? sourceFilePath,
  }) {
    final activePath = _activeEditorPath();
    if (sourceFilePath != null && sourceFilePath != activePath) {
      return;
    }
    if (_foldedRegionKeys.isNotEmpty) {
      setState(() {
        _foldedRegionKeys.clear();
        _controller.clearFoldedRegions();
      });
    }
    if (updatePreview) {
      _clearWysiwygCache();
    }
    ref
        .read(workspaceControllerProvider.notifier)
        .updateActiveText(
          value,
          updatePreview: updatePreview,
          sourceFilePath: sourceFilePath ?? activePath,
        );
  }

  void _handleWysiwygSourceChanged(String filePath, String value) {
    _handleSourceChanged(value, updatePreview: false, sourceFilePath: filePath);
  }

  void _applySourceEditorShortcutAction(BusyMarkEditorShortcutAction action) {
    switch (action) {
      case BusyMarkEditorShortcutAction.bold:
        _applySourceInlineMarkdownCommand(_SourceInlineMarkdownCommand.bold);
        break;
      case BusyMarkEditorShortcutAction.italic:
        _applySourceInlineMarkdownCommand(_SourceInlineMarkdownCommand.italic);
        break;
      case BusyMarkEditorShortcutAction.underline:
        _applySourceInlineMarkdownCommand(
          _SourceInlineMarkdownCommand.underline,
        );
        break;
      case BusyMarkEditorShortcutAction.strikethrough:
        _applySourceInlineMarkdownCommand(
          _SourceInlineMarkdownCommand.strikethrough,
        );
        break;
      case BusyMarkEditorShortcutAction.inlineCode:
        _applySourceInlineMarkdownCommand(_SourceInlineMarkdownCommand.code);
        break;
      case BusyMarkEditorShortcutAction.link:
        _applySourceInlineMarkdownCommand(_SourceInlineMarkdownCommand.link);
        break;
      case BusyMarkEditorShortcutAction.paragraph:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.paragraph);
        break;
      case BusyMarkEditorShortcutAction.heading1:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading1);
        break;
      case BusyMarkEditorShortcutAction.heading2:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading2);
        break;
      case BusyMarkEditorShortcutAction.heading3:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading3);
        break;
      case BusyMarkEditorShortcutAction.heading4:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading4);
        break;
      case BusyMarkEditorShortcutAction.heading5:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading5);
        break;
      case BusyMarkEditorShortcutAction.heading6:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.heading6);
        break;
      case BusyMarkEditorShortcutAction.orderedList:
        _applySourceBlockMarkdownCommand(
          _SourceBlockMarkdownCommand.orderedList,
        );
        break;
      case BusyMarkEditorShortcutAction.unorderedList:
        _applySourceBlockMarkdownCommand(
          _SourceBlockMarkdownCommand.unorderedList,
        );
        break;
      case BusyMarkEditorShortcutAction.taskList:
        _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand.taskList);
        break;
      case BusyMarkEditorShortcutAction.toggleTask:
        _toggleSourceTaskChecked();
        break;
      case BusyMarkEditorShortcutAction.indent:
        _indentSourceSelection();
        break;
      case BusyMarkEditorShortcutAction.outdent:
        _outdentSourceSelection();
        break;
      case BusyMarkEditorShortcutAction.blockquote:
        _applySourceLinePrefix('> ');
        break;
      case BusyMarkEditorShortcutAction.codeBlock:
        _insertSourceCodeBlock();
        break;
      case BusyMarkEditorShortcutAction.codeBlockLanguage:
        _insertSourceCodeBlock(language: 'language');
        break;
      case BusyMarkEditorShortcutAction.image:
        _insertSourceImage(block: true);
        break;
      case BusyMarkEditorShortcutAction.inlineImage:
        _insertSourceImage(block: false);
        break;
      case BusyMarkEditorShortcutAction.table:
        _insertSourceTable();
        break;
      case BusyMarkEditorShortcutAction.htmlBlock:
        _insertSourceHtmlBlock();
        break;
      case BusyMarkEditorShortcutAction.thematicBreak:
        _insertSourceBlock('\n---\n');
        break;
      case BusyMarkEditorShortcutAction.hardLineBreak:
        final selection = _normalizedSourceSelection();
        _replaceSourceSelection(
          '  \n',
          selectionStart: selection.start + 3,
          selectionEnd: selection.start + 3,
        );
        break;
      case BusyMarkEditorShortcutAction.pastePlainText:
        unawaited(_pastePlainTextIntoSource());
        break;
    }
  }

  void _applySourceInlineMarkdownCommand(_SourceInlineMarkdownCommand command) {
    switch (command) {
      case _SourceInlineMarkdownCommand.bold:
        _wrapSourceSelection(prefix: '**', suffix: '**');
        break;
      case _SourceInlineMarkdownCommand.italic:
        _wrapSourceSelection(prefix: '*', suffix: '*');
        break;
      case _SourceInlineMarkdownCommand.underline:
        _wrapSourceSelection(prefix: '<u>', suffix: '</u>');
        break;
      case _SourceInlineMarkdownCommand.strikethrough:
        _wrapSourceSelection(prefix: '~~', suffix: '~~');
        break;
      case _SourceInlineMarkdownCommand.code:
        _wrapSourceSelection(prefix: '`', suffix: '`');
        break;
      case _SourceInlineMarkdownCommand.link:
        _insertSourceLink();
        break;
    }
  }

  void _applySourceBlockMarkdownCommand(_SourceBlockMarkdownCommand command) {
    final range = _selectedSourceLineRange();
    final text = _controller.text;
    final markerPattern = RegExp(
      r'^(\s*)(?:#{1,6}\s+)?(?:[-*+]\s+(?:\[[ xX]\]\s+)?|\d+[.)]\s+)?(.*)$',
    );
    final replacementLines = <String>[];
    for (final (index, line) in range.lines.indexed) {
      final match = markerPattern.firstMatch(line);
      final indent = match?.group(1) ?? '';
      final content = match?.group(2) ?? line.trimLeft();
      final marker = switch (command) {
        _SourceBlockMarkdownCommand.paragraph => '',
        _SourceBlockMarkdownCommand.heading1 => '# ',
        _SourceBlockMarkdownCommand.heading2 => '## ',
        _SourceBlockMarkdownCommand.heading3 => '### ',
        _SourceBlockMarkdownCommand.heading4 => '#### ',
        _SourceBlockMarkdownCommand.heading5 => '##### ',
        _SourceBlockMarkdownCommand.heading6 => '###### ',
        _SourceBlockMarkdownCommand.orderedList => '${index + 1}. ',
        _SourceBlockMarkdownCommand.unorderedList => '- ',
        _SourceBlockMarkdownCommand.taskList => '- [ ] ',
      };
      replacementLines.add('$indent$marker$content');
    }
    final replacement = replacementLines.join('\n');
    final nextText = text.replaceRange(range.start, range.end, replacement);
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: range.start,
        extentOffset: range.start + replacement.length,
      ),
    );
    _sourceFocusNode.requestFocus();
    _handleSourceChanged(nextText);
  }

  void _toggleSourceTaskChecked() {
    final range = _selectedSourceLineRange();
    final replacement = [
      for (final line in range.lines)
        line.replaceFirstMapped(
          RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\]\s+)'),
          (match) =>
              '${match.group(1)}${match.group(2)!.trim().isEmpty ? 'x' : ' '}${match.group(3)}',
        ),
    ].join('\n');
    _replaceSourceLineRange(range, replacement);
  }

  void _indentSourceSelection() {
    final range = _selectedSourceLineRange();
    _replaceSourceLineRange(
      range,
      [
        for (final line in range.lines) line.isEmpty ? line : '  $line',
      ].join('\n'),
    );
  }

  void _outdentSourceSelection() {
    final range = _selectedSourceLineRange();
    _replaceSourceLineRange(
      range,
      [
        for (final line in range.lines)
          line.startsWith('  ')
              ? line.substring(2)
              : line.startsWith('\t')
              ? line.substring(1)
              : line,
      ].join('\n'),
    );
  }

  void _applySourceLinePrefix(String prefix) {
    final range = _selectedSourceLineRange();
    _replaceSourceLineRange(
      range,
      [
        for (final line in range.lines)
          line.isEmpty ? prefix.trimRight() : '$prefix$line',
      ].join('\n'),
    );
  }

  void _insertSourceCodeBlock({String language = ''}) {
    final selection = _normalizedSourceSelection();
    final selected = selection.textInside(_controller.text);
    final content = selected.isEmpty ? 'code' : selected;
    final languageSuffix = language.isEmpty ? '' : language;
    final replacement = '```$languageSuffix\n$content\n```';
    _replaceSourceSelection(
      replacement,
      selectionStart: selection.start + 3 + languageSuffix.length + 1,
      selectionEnd:
          selection.start + 3 + languageSuffix.length + 1 + content.length,
    );
  }

  void _insertSourceImage({required bool block}) {
    final selection = _normalizedSourceSelection();
    final selected = selection.textInside(_controller.text).trim();
    final alt = selected.isEmpty ? 'alt' : selected;
    final replacement = '![${alt.replaceAll('\n', ' ')}](url)';
    _replaceSourceSelection(
      block ? '\n$replacement\n' : replacement,
      selectionStart: selection.start + (block ? 3 : 2),
      selectionEnd: selection.start + (block ? 3 : 2) + alt.length,
    );
  }

  void _insertSourceTable() {
    _insertSourceBlock(
      '\n| Header 1 | Header 2 |\n| --- | --- |\n| Cell | Cell |\n',
    );
  }

  void _insertSourceHtmlBlock() {
    final selection = _normalizedSourceSelection();
    final selected = selection.textInside(_controller.text).trim();
    final content = selected.isEmpty ? 'HTML content' : selected;
    final replacement = '\n<div>\n  <p>$content</p>\n</div>\n';
    final contentStart = replacement.indexOf(content);
    _replaceSourceSelection(
      replacement,
      selectionStart: selection.start + contentStart,
      selectionEnd: selection.start + contentStart + content.length,
    );
  }

  void _insertSourceBlock(String markdown) {
    final selection = _normalizedSourceSelection();
    _replaceSourceSelection(
      markdown,
      selectionStart: selection.start + markdown.length,
      selectionEnd: selection.start + markdown.length,
    );
  }

  ({int start, int end, List<String> lines}) _selectedSourceLineRange() {
    final selection = _normalizedSourceSelection();
    final text = _controller.text;
    final lineStart =
        text.lastIndexOf(
          '\n',
          (selection.start - 1).clamp(0, text.length).toInt(),
        ) +
        1;
    final nextBreak = text.indexOf('\n', selection.end);
    final lineEnd = nextBreak < 0 ? text.length : nextBreak;
    return (
      start: lineStart,
      end: lineEnd,
      lines: text.substring(lineStart, lineEnd).split('\n'),
    );
  }

  void _replaceSourceLineRange(
    ({int start, int end, List<String> lines}) range,
    String replacement,
  ) {
    final nextText = _controller.text.replaceRange(
      range.start,
      range.end,
      replacement,
    );
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: range.start,
        extentOffset: range.start + replacement.length,
      ),
    );
    _sourceFocusNode.requestFocus();
    _handleSourceChanged(nextText);
  }

  void _wrapSourceSelection({
    required String prefix,
    required String suffix,
    String placeholder = 'text',
  }) {
    final selection = _normalizedSourceSelection();
    final selected = selection.textInside(_controller.text);
    final content = selected.isEmpty ? placeholder : selected;
    final replacement = '$prefix$content$suffix';
    _replaceSourceSelection(
      replacement,
      selectionStart: selection.start + prefix.length,
      selectionEnd: selection.start + prefix.length + content.length,
    );
  }

  void _insertSourceLink() {
    final selection = _normalizedSourceSelection();
    final selected = selection.textInside(_controller.text);
    final label = selected.isEmpty ? 'text' : selected;
    final replacement = '[$label](url)';
    final urlStart = selection.start + label.length + 3;
    _replaceSourceSelection(
      replacement,
      selectionStart: urlStart,
      selectionEnd: urlStart + 3,
    );
  }

  Future<void> _pastePlainTextIntoSource() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }
    final selection = _normalizedSourceSelection();
    _replaceSourceSelection(
      text,
      selectionStart: selection.start + text.length,
      selectionEnd: selection.start + text.length,
    );
  }

  void _insertSourceTab() {
    final selection = _normalizedSourceSelection();
    _replaceSourceSelection(
      '\t',
      selectionStart: selection.start + 1,
      selectionEnd: selection.start + 1,
    );
  }

  TextSelection _normalizedSourceSelection() {
    final selection = _controller.selection;
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: _controller.text.length);
    }
    final start = selection.start.clamp(0, _controller.text.length).toInt();
    final end = selection.end.clamp(0, _controller.text.length).toInt();
    return TextSelection(
      baseOffset: math.min(start, end),
      extentOffset: math.max(start, end),
    );
  }

  void _replaceSourceSelection(
    String replacement, {
    required int selectionStart,
    required int selectionEnd,
  }) {
    final selection = _normalizedSourceSelection();
    final text = _controller.text;
    final nextText =
        selection.textBefore(text) + replacement + selection.textAfter(text);
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart.clamp(0, nextText.length).toInt(),
        extentOffset: selectionEnd.clamp(0, nextText.length).toInt(),
      ),
    );
    _sourceFocusNode.requestFocus();
    _handleSourceChanged(nextText);
  }

  void _cacheWysiwygDocument(BusyDocument document) {
    _cachedWysiwygDocument = document;
    _cachedWysiwygPath = document.filePath;
    _cachedWysiwygSource = document.source;
  }

  void _clearWysiwygCache() {
    _cachedWysiwygDocument = null;
    _cachedWysiwygPath = null;
    _cachedWysiwygSource = null;
  }

  void _resetSourceUndoHistory() {
    final previous = _sourceUndoController;
    _sourceUndoController = UndoHistoryController();
    previous.dispose();
  }

  void _replaceSourceController({
    required String text,
    required SourceSyntaxLanguage language,
  }) {
    final previous = _controller;
    _controller =
        BusyMarkSourceEditingController(text: text, language: language)
          ..renderText = false
          ..visualMarkdown = false;
    _resetSourceUndoHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  String? _activeEditorPath() {
    final workspace = widget.state.workspace;
    return workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  }

  SourceSyntaxLanguage _sourceSyntaxLanguage(Workspace? workspace) {
    final kind = _activeDocumentKind(workspace);
    return switch (kind) {
      DocumentKind.markdown ||
      DocumentKind.writersideMarkdownTopic => SourceSyntaxLanguage.markdown,
      DocumentKind.writersideXmlTopic ||
      DocumentKind.tree ||
      DocumentKind.config ||
      DocumentKind.variables ||
      DocumentKind.categories => SourceSyntaxLanguage.xml,
      DocumentKind.image ||
      DocumentKind.resource ||
      DocumentKind.unknown ||
      null => SourceSyntaxLanguage.plain,
    };
  }

  DocumentKind? _activeDocumentKind(Workspace? workspace) {
    if (workspace == null) {
      return null;
    }
    final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
    if (activePath == null) {
      return null;
    }
    for (final file in workspace.files) {
      if (file.absolutePath == activePath) {
        return file.kind;
      }
    }
    return workspace.kind == WorkspaceKind.untitledMarkdown ||
            workspace.kind == WorkspaceKind.singleMarkdown
        ? DocumentKind.markdown
        : null;
  }

  void _scrollToOutlineTarget(_OutlineNavigationTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wysiwygScrollHeadingId = target.headingId;
        _wysiwygSearchQuery = null;
        _wysiwygScrollRequest += 1;
      });
      _scrollSourceToLine(target.line);
      _scrollPreviewToHeading(target.headingId);
    });
  }

  void _scrollToSearchTarget(_SearchNavigationTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final editorVisible =
          widget.viewMode == DocumentViewModePreference.editor;
      final wysiwygVisible =
          editorVisible &&
          _canUseWysiwyg(widget.state.workspace) &&
          _wysiwygDocument() != null;
      final sourceVisible =
          widget.viewMode != DocumentViewModePreference.preview &&
          !wysiwygVisible;
      final previewVisible =
          widget.viewMode != DocumentViewModePreference.source &&
          !editorVisible;

      if (wysiwygVisible) {
        setState(() {
          _wysiwygScrollHeadingId = null;
          _wysiwygSearchQuery = target.query;
          _wysiwygScrollRequest += 1;
        });
      }
      if (sourceVisible) {
        _scrollSourceToSearchRange(target);
      }
      if (previewVisible) {
        _schedulePreviewSearchScroll(target);
      }
    });
  }

  void _scrollSourceToLine(int line) {
    _unfoldSourceLine(line);
    final textOffset = _textOffsetForLine(_controller.text, line);
    _sourceFocusNode.requestFocus();
    _controller.selection = TextSelection.collapsed(offset: textOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateSourceScrollToLine(line);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpSourceScrollToLine(line);
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          _jumpSourceScrollToLine(line);
        }),
      );
    });
  }

  void _scrollSourceToSearchRange(_SearchNavigationTarget target) {
    _unfoldSourceLine(target.line);
    final start = target.startOffset.clamp(0, _controller.text.length).toInt();
    final end = target.endOffset.clamp(start, _controller.text.length).toInt();
    _sourceFocusNode.requestFocus();
    _controller.selection = TextSelection(baseOffset: start, extentOffset: end);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateSourceScrollToLine(target.line);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpSourceScrollToLine(target.line);
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          _jumpSourceScrollToLine(target.line);
        }),
      );
    });
  }

  void _unfoldSourceLine(int line) {
    final region = collapsedRegionContainingLine(
      _controller.text,
      _controller.language,
      _foldedRegionKeys,
      line,
    );
    if (region == null) {
      return;
    }
    setState(() {
      _foldedRegionKeys.remove(region.key);
      _applyFoldedRegions();
    });
  }

  TextStyle get _sourceTextStyle => TextStyle(
    fontFamily: BusyMarkTypography.monoFontFamily,
    fontSize: widget.editorFontSize,
    height: BusyMarkTypography.codeLineHeight,
    leadingDistribution: TextLeadingDistribution.even,
  );

  StrutStyle? _sourceStrutStyle({required bool folded}) {
    if (folded) {
      return null;
    }
    return StrutStyle.fromTextStyle(_sourceTextStyle);
  }

  double _sourceLineHeight(BuildContext context, StrutStyle? strutStyle) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: _sourceTextStyle),
      strutStyle: strutStyle,
      textDirection: Directionality.of(context),
      textHeightBehavior: _sourceTextHeightBehavior,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final metrics = painter.computeLineMetrics();
    painter.dispose();
    return metrics.isEmpty
        ? widget.editorFontSize * 1.45
        : metrics.first.height;
  }

  void _animateSourceScrollToLine(int line) {
    if (!mounted || !_sourceScrollController.hasClients) {
      return;
    }
    _sourceScrollController.animateTo(
      _sourceScrollOffsetForLine(line),
      duration: BusyMarkMotion.scroll,
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpSourceScrollToLine(int line) {
    if (!mounted || !_sourceScrollController.hasClients) {
      return;
    }
    _sourceScrollController.jumpTo(_sourceScrollOffsetForLine(line));
  }

  double _sourceScrollOffsetForLine(int line) {
    final textWidth = _sourceTextLayoutWidth();
    final strutStyle = _sourceStrutStyle(folded: _foldedRegionKeys.isNotEmpty);
    final lineHeight = _sourceLineHeight(context, strutStyle);
    final layouts = _sourceLineLayoutEntries(
      context,
      controller: _controller,
      foldRegions: sourceFoldRegions(_controller.text, _controller.language),
      collapsedRegionKeys: _foldedRegionKeys,
      textStyle: _sourceTextStyle,
      strutStyle: strutStyle,
      lineHeight: lineHeight,
      textWidth: textWidth,
    );
    final targetOffset = layouts
        .firstWhere(
          (entry) => entry.gutterEntry.lineNumber >= line,
          orElse: () => layouts.isEmpty
              ? const _SourceLineLayoutEntry.empty()
              : layouts.last,
        )
        .top;
    return targetOffset
        .clamp(0.0, _safeMaxScrollExtent(_sourceScrollController))
        .toDouble();
  }

  double _sourceTextLayoutWidth() {
    final renderBox =
        _sourceEditorKey.currentContext?.findRenderObject() as RenderBox?;
    final editorWidth = renderBox?.size.width ?? 800;
    return math.max(
      1,
      editorWidth -
          _SourceEditorFrame.editorPaddingLeft -
          _SourceEditorFrame.editorPaddingRight,
    );
  }

  void _scrollPreviewToHeading(String headingId) {
    final context = _previewHeadingKeys[headingId]?.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: BusyMarkMotion.scroll,
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  void _schedulePreviewSearchScroll(_SearchNavigationTarget target) {
    _previewSearchScrollRequest = target.request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentPreviewSearchScroll(target) ||
          _scrollPreviewToSearchTarget(target)) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isCurrentPreviewSearchScroll(target)) {
          _scrollPreviewToSearchTarget(target);
        }
      });
      unawaited(
        Future<void>.delayed(BusyMarkMotion.previewSearchDelay, () {
          if (_isCurrentPreviewSearchScroll(target)) {
            _scrollPreviewToSearchTarget(target);
          }
        }),
      );
      unawaited(
        Future<void>.delayed(BusyMarkMotion.scroll, () {
          if (_isCurrentPreviewSearchScroll(target)) {
            _scrollPreviewToSearchTarget(target);
          }
        }),
      );
    });
  }

  bool _isCurrentPreviewSearchScroll(_SearchNavigationTarget target) {
    return mounted && target.request == _previewSearchScrollRequest;
  }

  bool _scrollPreviewToSearchTarget(_SearchNavigationTarget target) {
    final query = target.query.trim();
    if (query.isEmpty) {
      return false;
    }
    final blocks = widget.state.preview?.blocks ?? const <PreviewBlock>[];
    final index = _previewSearchBlockIndex(
      blocks,
      target,
      widget.state.activeText,
    );
    if (index == null) {
      return _scrollPreviewToApproximateLine(target);
    }
    final context = _previewSearchKeys[index]?.currentContext;
    if (context == null) {
      _scrollPreviewToApproximateLine(target);
      return false;
    }
    _scrollPreviewToBlockOffset(context, blocks[index], target);
    return true;
  }

  void _scrollPreviewToBlockOffset(
    BuildContext blockContext,
    PreviewBlock block,
    _SearchNavigationTarget target,
  ) {
    if (!_previewScrollController.hasClients) {
      Scrollable.ensureVisible(
        blockContext,
        duration: BusyMarkMotion.scroll,
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
      return;
    }
    final renderObject = blockContext.findRenderObject();
    if (renderObject is! RenderBox) {
      Scrollable.ensureVisible(
        blockContext,
        duration: BusyMarkMotion.scroll,
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
      return;
    }

    final position = _safeScrollPosition(_previewScrollController);
    if (position == null) {
      return;
    }
    final viewportBox =
        position.context.notificationContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) {
      Scrollable.ensureVisible(
        blockContext,
        duration: BusyMarkMotion.scroll,
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
      return;
    }
    final blockHeight = renderObject.size.height;
    final targetY = renderObject
        .localToGlobal(
          Offset(
            0,
            blockHeight *
                _previewBlockTargetFraction(
                  block,
                  target,
                  widget.state.activeText,
                ),
          ),
        )
        .dy;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final targetOffset =
        position.pixels + targetY - viewportTop - BusyMarkSpacing.lg;
    _previewScrollController.jumpTo(
      targetOffset.clamp(0.0, position.maxScrollExtent).toDouble(),
    );
  }

  bool _scrollPreviewToApproximateLine(_SearchNavigationTarget target) {
    final position = _safeScrollPosition(_previewScrollController);
    if (position == null) {
      return false;
    }
    final sourceLineCount = widget.state.activeText.split('\n').length;
    final denominator = math.max(1, sourceLineCount - 1);
    final fraction = ((target.line - 1) / denominator).clamp(0.0, 1.0);
    _previewScrollController.jumpTo(
      (position.maxScrollExtent * fraction).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
    return true;
  }

  int _textOffsetForLine(String text, int line) {
    if (line <= 1) {
      return 0;
    }
    var currentLine = 1;
    for (var index = 0; index < text.length; index++) {
      if (text.codeUnitAt(index) == 10) {
        currentLine++;
        if (currentLine == line) {
          return index + 1;
        }
      }
    }
    return text.length;
  }

  bool _canUseWysiwyg(Workspace? workspace) {
    final kind = _activeDocumentKind(workspace);
    return kind == DocumentKind.markdown ||
        kind == DocumentKind.writersideMarkdownTopic;
  }

  BusyDocument? _wysiwygDocument() {
    final workspace = widget.state.workspace;
    final activePath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    if (workspace == null || activePath == null) {
      return null;
    }
    if (_cachedWysiwygPath == activePath &&
        _cachedWysiwygSource == widget.state.activeText) {
      return _cachedWysiwygDocument;
    }
    final mode = workspace.kind == WorkspaceKind.writersideModule
        ? MarkdownMode.writersideMarkdown
        : MarkdownMode.commonMark;
    try {
      final document = const MarkdownParser()
          .parse(
            filePath: activePath,
            source: widget.state.activeText,
            mode: mode,
            workspaceRoot: workspace.rootPath,
            validateLocalReferences: false,
          )
          .busyDocument;
      _cachedWysiwygDocument = document;
      _cachedWysiwygPath = activePath;
      _cachedWysiwygSource = widget.state.activeText;
      return document;
    } on Object {
      return workspace.markdown?.busyDocument;
    }
  }
}

class _SourceEditorFrame extends StatelessWidget {
  const _SourceEditorFrame({
    required this.controller,
    required this.scrollController,
    required this.lineHeight,
    required this.textStyle,
    required this.strutStyle,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.onToggleFold,
    required this.child,
  });

  static const double editorPaddingTop = BusyMarkSourceEditorMetrics.paddingTop;
  static const double editorPaddingLeft =
      BusyMarkSourceEditorMetrics.paddingLeft;
  static const double editorPaddingRight =
      BusyMarkSourceEditorMetrics.paddingRight;
  static const double _gutterWidth = BusyMarkSizes.sourceGutterWidth;

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final ValueChanged<SourceFoldRegion> onToggleFold;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final editorWidth = math
            .max(
              BusyMarkStroke.hairline,
              constraints.maxWidth - _gutterWidth - BusyMarkStroke.hairline,
            )
            .toDouble();
        final textWidth = math
            .max(1, editorWidth - editorPaddingLeft - editorPaddingRight)
            .toDouble();
        return DecoratedBox(
          decoration: BoxDecoration(color: colors.view),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _gutterWidth,
                child: _SourceLineNumberGutter(
                  controller: controller,
                  scrollController: scrollController,
                  lineHeight: lineHeight,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  textWidth: textWidth,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  onToggleFold: onToggleFold,
                ),
              ),
              VerticalDivider(
                width: BusyMarkStroke.hairline,
                color: colors.subtleBorder,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _SourceRenderedTextLayer(
                        controller: controller,
                        scrollController: scrollController,
                        textStyle: textStyle,
                        strutStyle: strutStyle,
                        textWidth: textWidth,
                      ),
                    ),
                    Positioned.fill(
                      child: _CollapsedSourceLineOverlay(
                        controller: controller,
                        scrollController: scrollController,
                        lineHeight: lineHeight,
                        textWidth: textWidth,
                        textStyle: textStyle,
                        strutStyle: strutStyle,
                        foldRegions: foldRegions,
                        collapsedRegionKeys: collapsedRegionKeys,
                      ),
                    ),
                    Positioned.fill(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceRenderedTextLayer extends StatelessWidget {
  const _SourceRenderedTextLayer({
    required this.controller,
    required this.scrollController,
    required this.textStyle,
    required this.strutStyle,
    required this.textWidth,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([controller, scrollController]),
          builder: (context, _) {
            final scrollOffset = _safeScrollOffset(scrollController);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _SourceEditorFrame.editorPaddingTop - scrollOffset,
                  left: _SourceEditorFrame.editorPaddingLeft,
                  width: textWidth,
                  child: RichText(
                    text: controller.buildSourceTextSpan(
                      context: context,
                      style: textStyle,
                      hideCollapsedStartLines: true,
                    ),
                    strutStyle: strutStyle,
                    textHeightBehavior: _sourceTextHeightBehavior,
                    textScaler: MediaQuery.textScalerOf(context),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SourceLineNumberGutter extends StatelessWidget {
  const _SourceLineNumberGutter({
    required this.controller,
    required this.scrollController,
    required this.lineHeight,
    required this.textStyle,
    required this.strutStyle,
    required this.textWidth,
    required this.foldRegions,
    required this.collapsedRegionKeys,
    required this.onToggleFold,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final double textWidth;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([controller, scrollController]),
              builder: (context, _) {
                final layouts = _sourceLineLayoutEntries(
                  context,
                  controller: controller,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  lineHeight: lineHeight,
                  textWidth: textWidth,
                );
                final activeLine = sourceLineNumberForOffset(
                  controller.text,
                  controller.selection.extentOffset,
                );
                final scrollOffset = _safeScrollOffset(scrollController);
                final children = <Widget>[];
                for (final layout in layouts) {
                  final top = layout.top - scrollOffset;
                  if (top < -lineHeight || top > constraints.maxHeight) {
                    continue;
                  }
                  final entry = layout.gutterEntry;
                  children.add(
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: lineHeight,
                      child: _SourceGutterRow(
                        entry: entry,
                        active: entry.lineNumber == activeLine,
                        lineHeight: lineHeight,
                        textStyle: textStyle,
                        onToggleFold: onToggleFold,
                      ),
                    ),
                  );
                }
                return Stack(children: children);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CollapsedSourceLineOverlay extends StatelessWidget {
  const _CollapsedSourceLineOverlay({
    required this.controller,
    required this.scrollController,
    required this.lineHeight,
    required this.textWidth,
    required this.textStyle,
    required this.strutStyle,
    required this.foldRegions,
    required this.collapsedRegionKeys,
  });

  final BusyMarkSourceEditingController controller;
  final ScrollController scrollController;
  final double lineHeight;
  final double textWidth;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final List<SourceFoldRegion> foldRegions;
  final Set<String> collapsedRegionKeys;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([controller, scrollController]),
              builder: (context, _) {
                final layouts = _sourceLineLayoutEntries(
                  context,
                  controller: controller,
                  foldRegions: foldRegions,
                  collapsedRegionKeys: collapsedRegionKeys,
                  textStyle: textStyle,
                  strutStyle: strutStyle,
                  lineHeight: lineHeight,
                  textWidth: textWidth,
                );
                final linesByNumber = {
                  for (final line in sourceLineInfos(controller.text))
                    line.number: line,
                };
                final scrollOffset = _safeScrollOffset(scrollController);
                final children = <Widget>[];
                for (final layout in layouts) {
                  final entry = layout.gutterEntry;
                  if (!entry.collapsed) {
                    continue;
                  }
                  final top = layout.top - scrollOffset;
                  if (top < -layout.height || top > constraints.maxHeight) {
                    continue;
                  }
                  final line = linesByNumber[entry.lineNumber];
                  if (line == null) {
                    continue;
                  }
                  children.add(
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: layout.height,
                      child: _CollapsedSourceLine(
                        text: _collapsedLineText(line.text),
                        height: lineHeight,
                        textStyle: textStyle,
                      ),
                    ),
                  );
                }
                return Stack(children: children);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CollapsedSourceLine extends StatelessWidget {
  const _CollapsedSourceLine({
    required this.text,
    required this.height,
    required this.textStyle,
  });

  final String text;
  final double height;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final background = Color.alphaBlend(
      colors.foreground.withValues(alpha: BusyMarkAlpha.sourceCollapsedLine),
      colors.view,
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(
              left: _SourceEditorFrame.editorPaddingLeft,
              right: _SourceEditorFrame.editorPaddingRight,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(color: colors.mutedForeground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceGutterRow extends StatelessWidget {
  const _SourceGutterRow({
    required this.entry,
    required this.active,
    required this.lineHeight,
    required this.textStyle,
    required this.onToggleFold,
  });

  static const double _foldButtonSize = BusyMarkSizes.sourceFoldButton;
  static const double _foldButtonRightInset =
      BusyMarkSizes.sourceFoldButtonRightInset;

  final SourceGutterEntry entry;
  final bool active;
  final double lineHeight;
  final TextStyle textStyle;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final region = entry.region;
    final activeColor = colors.foreground.withValues(
      alpha: BusyMarkAlpha.sourceCollapsedLine,
    );
    final numberStyle = textStyle.copyWith(
      color: active ? colors.foreground : colors.mutedForeground,
      fontSize:
          (textStyle.fontSize ?? BusyMarkTypography.defaultFontSize) *
          BusyMarkTypography.sourceLineNumberScale,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? activeColor : BusyMarkLinuxPalette.transparent,
      ),
      child: SizedBox(
        height: lineHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Text('${entry.lineNumber}', style: numberStyle),
              ),
            ),
            Positioned(
              top: 0,
              right: _foldButtonRightInset,
              width: _foldButtonSize,
              height: lineHeight,
              child: Align(
                alignment: Alignment.center,
                child: region == null
                    ? const SizedBox.shrink()
                    : _SourceFoldButton(
                        region: region,
                        collapsed: entry.collapsed,
                        onToggleFold: onToggleFold,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceFoldButton extends StatelessWidget {
  const _SourceFoldButton({
    required this.region,
    required this.collapsed,
    required this.onToggleFold,
  });

  final SourceFoldRegion region;
  final bool collapsed;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Tooltip(
      message: collapsed
          ? context.l10n.expandKind(_foldKindLabel(context, region.kind))
          : context.l10n.collapseKind(_foldKindLabel(context, region.kind)),
      waitDuration: BusyMarkMotion.tooltipWait,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onToggleFold(region),
          child: SizedBox.square(
            dimension: _SourceGutterRow._foldButtonSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
              ),
              child: Icon(
                collapsed ? YaruIcons.pan_end : YaruIcons.pan_down,
                size: 12,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<SourceGutterEntry> _sourceGutterEntriesFromRegions(
  String source,
  List<SourceFoldRegion> foldRegions,
  Set<String> collapsedRegionKeys,
) {
  final lines = sourceLineInfos(source);
  final regionByStartLine = <int, SourceFoldRegion>{};
  for (final region in foldRegions.reversed) {
    regionByStartLine.putIfAbsent(region.startLine, () => region);
  }

  final entries = <SourceGutterEntry>[];
  for (var index = 0; index < lines.length; index++) {
    final lineNumber = lines[index].number;
    final region = regionByStartLine[lineNumber];
    final collapsed =
        region != null && collapsedRegionKeys.contains(region.key);
    entries.add(
      SourceGutterEntry(
        lineNumber: lineNumber,
        region: region,
        collapsed: collapsed,
      ),
    );
    if (collapsed) {
      index += region.foldedLineCount;
    }
  }
  return entries;
}

class _SourceLineLayoutEntry {
  const _SourceLineLayoutEntry({
    required this.gutterEntry,
    required this.top,
    required this.height,
  });

  const _SourceLineLayoutEntry.empty()
    : gutterEntry = const SourceGutterEntry(
        lineNumber: 1,
        region: null,
        collapsed: false,
      ),
      top = 0,
      height = 0;

  final SourceGutterEntry gutterEntry;
  final double top;
  final double height;
}

List<_SourceLineLayoutEntry> _sourceLineLayoutEntries(
  BuildContext context, {
  required BusyMarkSourceEditingController controller,
  required List<SourceFoldRegion> foldRegions,
  required Set<String> collapsedRegionKeys,
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double lineHeight,
  required double textWidth,
}) {
  final source = controller.text;
  final linesByNumber = {
    for (final line in sourceLineInfos(source)) line.number: line,
  };
  final entries = _sourceGutterEntriesFromRegions(
    source,
    foldRegions,
    collapsedRegionKeys,
  );
  final layouts = <_SourceLineLayoutEntry>[];
  final painter = _sourceTextPainter(
    context,
    controller: controller,
    textStyle: textStyle,
    strutStyle: strutStyle,
    textWidth: textWidth,
    hideCollapsedStartLines: true,
  );
  for (final entry in entries) {
    final line = linesByNumber[entry.lineNumber];
    final top =
        _SourceEditorFrame.editorPaddingTop +
        (line == null ? 0 : _sourceTextTopForOffset(painter, line.startOffset));
    final height = line == null
        ? lineHeight
        : _sourceTextHeightForLine(
            painter,
            linesByNumber,
            entry.lineNumber,
            lineHeight,
          );
    layouts.add(
      _SourceLineLayoutEntry(gutterEntry: entry, top: top, height: height),
    );
  }
  painter.dispose();
  return layouts;
}

TextPainter _sourceTextPainter(
  BuildContext context, {
  required BusyMarkSourceEditingController controller,
  required TextStyle textStyle,
  required StrutStyle? strutStyle,
  required double textWidth,
  bool hideCollapsedStartLines = false,
}) {
  final painter = TextPainter(
    text: controller.buildSourceTextSpan(
      context: context,
      style: textStyle,
      hideCollapsedStartLines: hideCollapsedStartLines,
    ),
    strutStyle: strutStyle,
    textDirection: Directionality.of(context),
    textHeightBehavior: _sourceTextHeightBehavior,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(minWidth: math.max(1, textWidth), maxWidth: math.max(1, textWidth));
  return painter;
}

double _sourceTextTopForOffset(TextPainter painter, int offset) {
  return painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dy;
}

double _sourceTextHeightForLine(
  TextPainter painter,
  Map<int, SourceLineInfo> linesByNumber,
  int lineNumber,
  double fallback,
) {
  final line = linesByNumber[lineNumber];
  if (line == null) {
    return fallback;
  }
  final top = _sourceTextTopForOffset(painter, line.startOffset);
  final nextLine = linesByNumber[lineNumber + 1];
  if (nextLine != null) {
    final nextTop = _sourceTextTopForOffset(painter, nextLine.startOffset);
    if (nextTop > top) {
      return math.max(fallback, nextTop - top);
    }
  }
  final metrics = painter.computeLineMetrics();
  for (final metric in metrics) {
    final metricTop = metric.baseline - metric.ascent;
    if (top >= metricTop - 0.5 && top < metricTop + metric.height + 0.5) {
      return math.max(fallback, metric.height);
    }
  }
  return fallback;
}

String _collapsedLineText(String text) {
  final trimmed = text.trimRight();
  if (trimmed.isEmpty) {
    return '...';
  }
  return '$trimmed ...';
}

String _foldKindLabel(BuildContext context, SourceFoldKind kind) {
  return switch (kind) {
    SourceFoldKind.section => context.l10n.foldKindSection,
    SourceFoldKind.list => context.l10n.foldKindList,
    SourceFoldKind.blockquote => context.l10n.foldKindQuote,
    SourceFoldKind.code => context.l10n.codeBlock,
    SourceFoldKind.xml => context.l10n.foldKindTag,
  };
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.preview,
    required this.workspace,
    required this.controller,
    required this.headingKeys,
    required this.searchKeys,
  });

  final PreviewDocument? preview;
  final Workspace? workspace;
  final ScrollController controller;
  final Map<String, GlobalKey> headingKeys;
  final Map<int, GlobalKey> searchKeys;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final document = preview;
    if (document == null) {
      return _EmptyPane(
        icon: BusyMarkGlyphs.preview,
        title: context.l10n.noPreview,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: SelectionArea(
        child: ListView(
          controller: controller,
          padding: BusyMarkInsets.previewPane,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BusyMarkSizes.contentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, block) in document.blocks.indexed)
                      _keyedPreviewBlock(context, index, block),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyedPreviewBlock(
    BuildContext context,
    int index,
    PreviewBlock block,
  ) {
    final child = _PreviewBlockView(
      block,
      first: index == 0,
      listRunEnd: _isLastListBlock(index),
      workspace: workspace,
      headingKey: _keyForBlock(block),
    );
    return KeyedSubtree(
      key: searchKeys.putIfAbsent(index, () => GlobalKey()),
      child: child,
    );
  }

  bool _isLastListBlock(int index) {
    final blocks = preview?.blocks;
    if (blocks == null || blocks[index].kind != PreviewBlockKind.list) {
      return false;
    }
    return index == blocks.length - 1 ||
        blocks[index + 1].kind != PreviewBlockKind.list;
  }

  Key? _keyForBlock(PreviewBlock block) {
    if (block.kind != PreviewBlockKind.heading) {
      return null;
    }
    final id = block.attributes['id'];
    if (id == null || id.isEmpty) {
      return null;
    }
    return headingKeys.putIfAbsent(id, () => GlobalKey());
  }
}

class _PreviewBlockView extends StatelessWidget {
  const _PreviewBlockView(
    this.block, {
    required this.workspace,
    required this.first,
    required this.listRunEnd,
    required this.headingKey,
  });

  final PreviewBlock block;
  final Workspace? workspace;
  final bool first;
  final bool listRunEnd;
  final Key? headingKey;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final displayBlock = _localizedPreviewBlock(context, block);
    return switch (displayBlock.kind) {
      PreviewBlockKind.heading => Padding(
        padding: EdgeInsets.only(
          top: first ? 0 : BusyMarkSizes.previewHeadingTop,
          bottom: BusyMarkSizes.previewHeadingBottom,
        ),
        child: _PreviewInlineText(
          key: headingKey,
          block: displayBlock,
          style: _headingStyle(context, displayBlock.level),
        ),
      ),
      PreviewBlockKind.code => Container(
        margin: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.sm),
        padding: BusyMarkInsets.previewCodeBlock,
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Text(
          displayBlock.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: BusyMarkTypography.monoFontFamily,
            height: BusyMarkTypography.codeLineHeight,
          ),
        ),
      ),
      PreviewBlockKind.image => _PreviewImageBlock(
        block: displayBlock,
        workspace: workspace,
      ),
      PreviewBlockKind.admonition => _PreviewCallout(
        icon: _admonitionIcon(displayBlock.attributes['style']),
        color: switch (displayBlock.attributes['style']) {
          'warning' => colors.admonitionWarning,
          'tip' => colors.admonitionTip,
          _ => colors.admonitionNote,
        },
        child: _PreviewInlineText(block: displayBlock),
      ),
      PreviewBlockKind.tabs => _PreviewCallout(
        icon: BusyMarkGlyphs.tab,
        color: colors.panel,
        child: Text(displayBlock.text),
      ),
      PreviewBlockKind.procedure => _PreviewCallout(
        icon: BusyMarkGlyphs.orderedList,
        color: colors.panel,
        child: Text(displayBlock.text),
      ),
      PreviewBlockKind.list => Padding(
        padding: EdgeInsets.only(
          top: BusyMarkSpacing.xs,
          bottom: _listBottomSpacing(displayBlock),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: BusyMarkSizes.previewListMarkerWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: BusyMarkSizes.previewListMarkerTopInset,
                    ),
                    child: _ListMarker(block: displayBlock),
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(child: _PreviewInlineText(block: displayBlock)),
              ],
            ),
            if (displayBlock.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left:
                      BusyMarkSizes.previewListMarkerWidth + BusyMarkSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, child) in displayBlock.children.indexed)
                      _PreviewBlockView(
                        child,
                        workspace: workspace,
                        first: false,
                        listRunEnd: _isLastListBlock(
                          displayBlock.children,
                          index,
                        ),
                        headingKey: null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      PreviewBlockKind.quote => _PreviewCallout(
        icon: BusyMarkGlyphs.blockquote,
        color: colors.panel,
        child: _PreviewInlineText(block: block),
      ),
      PreviewBlockKind.thematicBreak => Padding(
        padding: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.mdPlus),
        child: const _PreviewThematicBreak(),
      ),
      PreviewBlockKind.table => _PreviewTable(block: displayBlock),
      PreviewBlockKind.container
          when displayBlock.attributes['htmlTag'] == 'figure' =>
        _PreviewFigure(block: displayBlock, workspace: workspace, first: first),
      PreviewBlockKind.container => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in displayBlock.children.indexed)
            _PreviewBlockView(
              child,
              workspace: workspace,
              first: first && index == 0,
              listRunEnd: _isLastListBlock(displayBlock.children, index),
              headingKey: null,
            ),
        ],
      ),
      PreviewBlockKind.raw => Container(
        margin: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.sm),
        padding: BusyMarkInsets.previewCodeBlock,
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Text(
          displayBlock.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: BusyMarkTypography.monoFontFamily,
            color: colors.mutedForeground,
            height: BusyMarkTypography.codeLineHeight,
          ),
        ),
      ),
      _ => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: BusyMarkSizes.previewHeadingBottom,
        ),
        child: _PreviewInlineText(block: displayBlock),
      ),
    };
  }

  double _listBottomSpacing(PreviewBlock displayBlock) {
    if (!listRunEnd) {
      return BusyMarkSpacing.xs;
    }
    if (displayBlock.children.isNotEmpty &&
        displayBlock.children.last.kind == PreviewBlockKind.list) {
      return BusyMarkSpacing.xs;
    }
    return BusyMarkSpacing.md;
  }

  bool _isLastListBlock(List<PreviewBlock> blocks, int index) {
    return blocks[index].kind == PreviewBlockKind.list &&
        (index == blocks.length - 1 ||
            blocks[index + 1].kind != PreviewBlockKind.list);
  }

  PreviewBlock _localizedPreviewBlock(
    BuildContext context,
    PreviewBlock block,
  ) {
    if (block.text.trim().isNotEmpty) {
      return block;
    }
    final element = block.attributes['element'];
    final text = switch (block.kind) {
      PreviewBlockKind.heading =>
        element == 'chapter' ? context.l10n.chapter : context.l10n.topic,
      PreviewBlockKind.code => context.l10n.codeBlock,
      PreviewBlockKind.image => context.l10n.image,
      PreviewBlockKind.admonition => switch (block.attributes['style']) {
        'warning' => context.l10n.warning,
        'tip' => context.l10n.tip,
        _ => context.l10n.note,
      },
      PreviewBlockKind.tabs =>
        element == 'tab' ? context.l10n.tab : context.l10n.tabs,
      PreviewBlockKind.procedure =>
        element == 'step' ? context.l10n.step : context.l10n.procedure,
      PreviewBlockKind.paragraph =>
        element == 'a'
            ? context.l10n.link
            : element ?? context.l10n.untitledResult,
      _ => block.text,
    };
    if (text == block.text) {
      return block;
    }
    return PreviewBlock(
      kind: block.kind,
      text: text,
      level: block.level,
      attributes: block.attributes,
      inlines: block.inlines,
      children: block.children,
      sourceStartLine: block.sourceStartLine,
      sourceEndLine: block.sourceEndLine,
      sourceStartOffset: block.sourceStartOffset,
      sourceEndOffset: block.sourceEndOffset,
    );
  }

  TextStyle? _headingStyle(BuildContext context, int? level) {
    final theme = Theme.of(context).textTheme;
    return switch (level ?? 2) {
      1 => theme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      2 => theme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      _ => theme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    };
  }

  IconData _admonitionIcon(String? style) {
    return switch (style) {
      'warning' => BusyMarkGlyphs.warning,
      'tip' => BusyMarkGlyphs.tip,
      _ => BusyMarkGlyphs.info,
    };
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.block});

  final PreviewBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final columnCount = block.children.fold<int>(
      0,
      (max, row) => math.max(max, row.children.length),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.smPlus),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        child: Table(
          border: TableBorder.symmetric(
            inside: BorderSide(color: colors.subtleBorder),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final row in block.children)
              TableRow(
                decoration: BoxDecoration(
                  color: row.attributes['header'] == 'true'
                      ? colors.control
                      : BusyMarkLinuxPalette.transparent,
                ),
                children: [
                  for (var index = 0; index < columnCount; index += 1)
                    Padding(
                      padding: BusyMarkInsets.previewTableCell,
                      child: index < row.children.length
                          ? _PreviewInlineText(
                              block: row.children[index],
                              style: row.attributes['header'] == 'true'
                                  ? Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)
                                  : null,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewThematicBreak extends StatelessWidget {
  const _PreviewThematicBreak();

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Container(
        height: BusyMarkTypography.previewThematicBreakHeight,
        decoration: BoxDecoration(
          color: colors.mutedForeground.withValues(
            alpha: BusyMarkAlpha.thematicBreak,
          ),
          borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
        ),
      ),
    );
  }
}

class _PreviewInlineText extends ConsumerWidget {
  const _PreviewInlineText({super.key, required this.block, this.style});

  final PreviewBlock block;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final searchState = ref.watch(_workspaceSearchProvider);
    final workspace = ref.watch(workspaceControllerProvider).workspace;
    final highlightQuery = searchState.active ? searchState.query.trim() : '';
    final inlines = block.inlines.isEmpty
        ? [PreviewInline(kind: PreviewInlineKind.text, text: block.text)]
        : block.inlines;
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final inline in inlines)
            _previewInlineSpan(
              context,
              inline,
              workspace: workspace,
              highlightQuery: highlightQuery,
              onLinkTap: (destination) =>
                  _openPreviewLink(context, ref, destination),
            ),
        ],
      ),
    );
  }
}

String _previewBlockSearchText(PreviewBlock block) {
  return [
    block.text,
    for (final inline in block.inlines) _previewInlineSearchText(inline),
    for (final child in block.children) _previewBlockSearchText(child),
  ].where((value) => value.isNotEmpty).join(' ');
}

int? _previewSearchBlockIndex(
  List<PreviewBlock> blocks,
  _SearchNavigationTarget target,
  String source,
) {
  int? nearestBeforeIndex;
  int? nearestAfterIndex;
  for (final (index, block) in blocks.indexed) {
    if (_previewBlockContainsSearchTarget(block, target)) {
      return index;
    }
    final startLine = block.sourceStartLine;
    if (startLine == null) {
      continue;
    }
    if (startLine <= target.line) {
      nearestBeforeIndex = index;
    } else {
      nearestAfterIndex ??= index;
    }
  }
  return _previewSearchBlockIndexForSourceLine(blocks, source, target) ??
      _previewSearchBlockIndexForOrdinal(
        blocks,
        target.query,
        _searchResultOrdinalInSource(source, target),
      ) ??
      nearestBeforeIndex ??
      nearestAfterIndex;
}

int? _previewSearchBlockIndexForSourceLine(
  List<PreviewBlock> blocks,
  String source,
  _SearchNavigationTarget target,
) {
  final rawLine = _sourceLineText(source, target.line).trim();
  if (rawLine.isEmpty) {
    return null;
  }
  final strippedLine = _stripMarkdownForSearchResult(rawLine).toLowerCase();
  final rawNeedle = rawLine.toLowerCase();
  if (strippedLine.isEmpty && rawNeedle.isEmpty) {
    return null;
  }
  for (final (index, block) in blocks.indexed) {
    final searchText = _previewBlockSearchText(block).toLowerCase();
    if ((strippedLine.isNotEmpty && searchText.contains(strippedLine)) ||
        (rawNeedle.isNotEmpty && searchText.contains(rawNeedle))) {
      return index;
    }
  }
  return null;
}

String _sourceLineText(String source, int lineNumber) {
  if (lineNumber <= 0) {
    return '';
  }
  final lines = source.split('\n');
  if (lineNumber > lines.length) {
    return '';
  }
  return lines[lineNumber - 1];
}

int _searchResultOrdinalInSource(
  String source,
  _SearchNavigationTarget target,
) {
  final normalizedQuery = target.query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return 0;
  }
  final lines = source.split('\n');
  var ordinal = 0;
  var lineStartOffset = 0;
  for (final line in lines) {
    final matchColumn = line.toLowerCase().indexOf(normalizedQuery);
    if (matchColumn >= 0) {
      final startOffset = lineStartOffset + matchColumn;
      if (startOffset == target.startOffset) {
        return ordinal;
      }
      if (startOffset > target.startOffset) {
        return ordinal;
      }
      ordinal += 1;
    }
    lineStartOffset += line.length + 1;
  }
  return ordinal;
}

int? _previewSearchBlockIndexForOrdinal(
  List<PreviewBlock> blocks,
  String query,
  int ordinal,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return null;
  }
  var matchIndex = 0;
  for (final (index, block) in blocks.indexed) {
    if (!_previewBlockSearchText(
      block,
    ).toLowerCase().contains(normalizedQuery)) {
      continue;
    }
    if (matchIndex == ordinal) {
      return index;
    }
    matchIndex += 1;
  }
  return null;
}

String _previewInlineSearchText(PreviewInline inline) {
  return [
    inline.text,
    for (final child in inline.children) _previewInlineSearchText(child),
  ].where((value) => value.isNotEmpty).join(' ');
}

bool _previewBlockContainsSearchTarget(
  PreviewBlock block,
  _SearchNavigationTarget target,
) {
  final startOffset = block.sourceStartOffset;
  final endOffset = block.sourceEndOffset;
  if (startOffset != null &&
      endOffset != null &&
      target.startOffset >= startOffset &&
      target.startOffset < endOffset) {
    return true;
  }

  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine;
  if (startLine != null &&
      endLine != null &&
      target.line >= startLine &&
      target.line <= endLine) {
    return true;
  }

  return block.children.any(
    (child) => _previewBlockContainsSearchTarget(child, target),
  );
}

double _previewBlockTargetFraction(
  PreviewBlock block,
  _SearchNavigationTarget target,
  String source,
) {
  final startOffset = block.sourceStartOffset;
  final endOffset = block.sourceEndOffset;
  if (startOffset != null && endOffset != null && endOffset > startOffset) {
    return ((target.startOffset - startOffset) / (endOffset - startOffset))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  final startLine = block.sourceStartLine;
  final endLine = block.sourceEndLine;
  if (startLine != null && endLine != null && endLine > startLine) {
    return ((target.line - startLine) / (endLine - startLine))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  final sourceLine = _sourceLineText(source, target.line).trim();
  if (sourceLine.isNotEmpty && block.text.contains('\n')) {
    final sourceNeedles = {
      sourceLine,
      _stripMarkdownForSearchResult(sourceLine),
    }.where((value) => value.isNotEmpty).map((value) => value.toLowerCase());
    final blockLines = block.text.split('\n');
    for (final (index, blockLine) in blockLines.indexed) {
      final normalizedBlockLine = blockLine.trim().toLowerCase();
      if (sourceNeedles.any(normalizedBlockLine.contains)) {
        final denominator = math.max(1, blockLines.length - 1);
        return (index / denominator).clamp(0.0, 1.0).toDouble();
      }
    }
  }

  return 0.0;
}

class _ListMarker extends StatelessWidget {
  const _ListMarker({required this.block});

  final PreviewBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final task = block.attributes['task'];
    if (task != null) {
      return Icon(
        task == 'true' ? BusyMarkGlyphs.checkedBox : BusyMarkGlyphs.task,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      );
    }
    if (block.attributes['ordered'] == 'true') {
      return Text(
        block.attributes['marker'] ?? '1.',
        textAlign: TextAlign.right,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: BusyMarkSizes.floatingEntryLabelTop),
      child: SizedBox.square(
        dimension: BusyMarkSizes.markerDot,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.mutedForeground,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PreviewFigure extends StatelessWidget {
  const _PreviewFigure({
    required this.block,
    required this.workspace,
    required this.first,
  });

  static const double _captionMinWidth = 240;

  final PreviewBlock block;
  final Workspace? workspace;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final contentBlocks = block.children.where(_isNotCaption).toList();
    final captionBlocks = block.children.where(_isCaption).toList();
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.mutedForeground,
      height: BusyMarkTypography.bodyLineHeight,
    );
    final captionWidth = _captionWidth(contentBlocks);

    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : BusyMarkSpacing.smPlus,
        bottom: BusyMarkSpacing.smPlus,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, child) in contentBlocks.indexed)
            _figureContentBlock(child, index, contentBlocks),
          if (captionBlocks.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: contentBlocks.isEmpty ? 0 : BusyMarkSpacing.xs,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: captionWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, caption) in captionBlocks.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : BusyMarkSpacing.xs,
                        ),
                        child: _PreviewInlineText(
                          block: caption,
                          style: captionStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _figureContentBlock(
    PreviewBlock child,
    int index,
    List<PreviewBlock> contentBlocks,
  ) {
    if (child.kind == PreviewBlockKind.image) {
      return _PreviewImageBlock(
        block: child,
        workspace: workspace,
        padding: EdgeInsets.zero,
      );
    }
    return _PreviewBlockView(
      child,
      workspace: workspace,
      first: index == 0,
      listRunEnd: _isLastListBlock(contentBlocks, index),
      headingKey: null,
    );
  }

  double _captionWidth(List<PreviewBlock> contentBlocks) {
    for (final child in contentBlocks) {
      if (child.kind != PreviewBlockKind.image) {
        continue;
      }
      final width = _previewImageWidth(child);
      if (width != null) {
        return math.max(width, _captionMinWidth);
      }
    }
    return BusyMarkSizes.previewImageMaxWidth;
  }

  bool _isLastListBlock(List<PreviewBlock> blocks, int index) {
    return blocks[index].kind == PreviewBlockKind.list &&
        (index == blocks.length - 1 ||
            blocks[index + 1].kind != PreviewBlockKind.list);
  }

  bool _isCaption(PreviewBlock block) {
    return block.attributes['htmlTag'] == 'figcaption';
  }

  bool _isNotCaption(PreviewBlock block) {
    return !_isCaption(block);
  }
}

class _PreviewImageBlock extends StatelessWidget {
  const _PreviewImageBlock({
    required this.block,
    required this.workspace,
    this.padding = const EdgeInsets.symmetric(vertical: BusyMarkSpacing.smPlus),
  });

  final PreviewBlock block;
  final Workspace? workspace;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = _previewImageWidth(block);
    final source = _previewImageSource(block);
    final activeFilePath =
        workspace?.activeFilePath ?? workspace?.markdown?.filePath;
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: MarkdownImageView(
          source: source,
          alt: block.text,
          activeFilePath: activeFilePath ?? '',
          workspaceRoot: _imageWorkspaceRoot(workspace),
          writersideRoot: workspace?.writersideModule?.rootPath,
          imagesDir: workspace?.writersideModule?.config.imagesDir ?? 'images',
          width: width,
          maxWidth: width ?? BusyMarkSizes.previewImageMaxWidth,
        ),
      ),
    );
  }
}

String? _imageWorkspaceRoot(Workspace? workspace) {
  if (workspace == null) {
    return null;
  }
  final module = workspace.writersideModule;
  if (module == null) {
    return workspace.rootPath;
  }
  final activeFilePath =
      workspace.activeFilePath ?? workspace.markdown?.filePath;
  if (activeFilePath == null) {
    return null;
  }
  return module.topics
      .where((topic) => topic.filePath == activeFilePath)
      .map((topic) => topic.topicRoot)
      .firstOrNull;
}

String _previewImageSource(PreviewBlock block) {
  final attributeSource = block.attributes['src'];
  if (attributeSource != null && attributeSource.trim().isNotEmpty) {
    return attributeSource.trim();
  }
  for (final inline in block.inlines) {
    final source = _previewImageSourceFromInline(inline);
    if (source != null) {
      return source;
    }
  }
  return '';
}

String? _previewImageSourceFromInline(PreviewInline inline) {
  if (inline.kind == PreviewInlineKind.image &&
      inline.destination != null &&
      inline.destination!.trim().isNotEmpty) {
    return inline.destination!.trim();
  }
  for (final child in inline.children) {
    final source = _previewImageSourceFromInline(child);
    if (source != null) {
      return source;
    }
  }
  return null;
}

double? _previewImageWidth(PreviewBlock block) {
  final value = block.attributes['width'];
  if (value == null) {
    return null;
  }
  final parsed = double.tryParse(value.replaceAll(RegExp('[^0-9.]'), ''));
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed
      .clamp(
        BusyMarkSizes.previewImageMinWidth,
        BusyMarkSizes.previewImageMaxWidth,
      )
      .toDouble();
}

InlineSpan _previewInlineSpan(
  BuildContext context,
  PreviewInline inline, {
  required Workspace? workspace,
  required String highlightQuery,
  required Future<void> Function(String destination) onLinkTap,
  String? inheritedLinkDestination,
  TextStyle? inheritedStyle,
}) {
  final colors = BusyMarkSurfaceColors.of(context);
  final theme = Theme.of(context);
  final linkDestination = inline.kind == PreviewInlineKind.link
      ? inline.destination ?? inline.text
      : inheritedLinkDestination;
  final linkStyle = linkDestination == null
      ? null
      : TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        );
  TextStyle? mergeStyle(TextStyle? style) {
    final merged = inheritedStyle?.merge(style) ?? style ?? inheritedStyle;
    return merged?.merge(linkStyle) ?? linkStyle;
  }

  TapGestureRecognizer? linkRecognizer() {
    final destination = linkDestination;
    if (destination == null || destination.trim().isEmpty) {
      return null;
    }
    return TapGestureRecognizer()
      ..onTap = () {
        unawaited(onLinkTap(destination));
      };
  }

  InlineSpan childSpan(PreviewInline child, TextStyle? style) {
    return _previewInlineSpan(
      context,
      child,
      workspace: workspace,
      highlightQuery: highlightQuery,
      onLinkTap: onLinkTap,
      inheritedLinkDestination: linkDestination,
      inheritedStyle: style,
    );
  }

  TextSpan span({
    required String? text,
    required List<InlineSpan>? children,
    TextStyle? style,
  }) {
    final clickable = linkDestination != null && text != null;
    if (text != null && highlightQuery.trim().isNotEmpty) {
      final highlighted = _highlightedPreviewTextSpans(
        context,
        text,
        highlightQuery,
        style: style,
        mouseCursor: clickable ? SystemMouseCursors.click : null,
        recognizerBuilder: clickable ? linkRecognizer : null,
      );
      if (highlighted != null) {
        return TextSpan(children: highlighted);
      }
    }
    return TextSpan(
      text: text,
      children: children,
      style: style,
      mouseCursor: clickable ? SystemMouseCursors.click : null,
      recognizer: clickable ? linkRecognizer() : null,
    );
  }

  return switch (inline.kind) {
    PreviewInlineKind.text => span(
      text: inline.text,
      children: null,
      style: mergeStyle(null),
    ),
    PreviewInlineKind.strong => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
      style: mergeStyle(const TextStyle(fontWeight: FontWeight.w700)),
    ),
    PreviewInlineKind.emphasis => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(const TextStyle(fontStyle: FontStyle.italic)),
                ),
            ],
      style: mergeStyle(const TextStyle(fontStyle: FontStyle.italic)),
    ),
    PreviewInlineKind.underline => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(
                    const TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
            ],
      style: mergeStyle(const TextStyle(decoration: TextDecoration.underline)),
    ),
    PreviewInlineKind.strikethrough => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(
                  child,
                  mergeStyle(
                    const TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                ),
            ],
      style: mergeStyle(
        const TextStyle(decoration: TextDecoration.lineThrough),
      ),
    ),
    PreviewInlineKind.code => span(
      text: inline.text,
      children: null,
      style: mergeStyle(
        TextStyle(
          fontFamily: BusyMarkTypography.monoFontFamily,
          backgroundColor: colors.control,
          color: colors.foreground,
        ),
      ),
    ),
    PreviewInlineKind.link => span(
      text: inline.children.isEmpty ? inline.text : null,
      children: inline.children.isEmpty
          ? null
          : [
              for (final child in inline.children)
                childSpan(child, mergeStyle(null)),
            ],
      style: mergeStyle(null),
    ),
    PreviewInlineKind.image => _previewInlineImageSpan(
      context,
      inline,
      workspace,
      style: mergeStyle(
        TextStyle(color: colors.mutedForeground, fontStyle: FontStyle.italic),
      ),
    ),
  };
}

InlineSpan _previewInlineImageSpan(
  BuildContext context,
  PreviewInline inline,
  Workspace? workspace, {
  required TextStyle? style,
}) {
  final activeFilePath =
      workspace?.activeFilePath ?? workspace?.markdown?.filePath;
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    style: const TextStyle(
      decoration: TextDecoration.none,
      fontStyle: FontStyle.normal,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
      child: DefaultTextStyle.merge(
        style: style,
        child: MarkdownImageView(
          source: inline.destination ?? '',
          alt: inline.text,
          activeFilePath: activeFilePath ?? '',
          workspaceRoot: _imageWorkspaceRoot(workspace),
          writersideRoot: workspace?.writersideModule?.rootPath,
          imagesDir: workspace?.writersideModule?.config.imagesDir ?? 'images',
          maxWidth: BusyMarkSizes.previewMinWidth,
          maxHeight: BusyMarkSizes.previewInlineImageMaxHeight,
          height: BusyMarkSizes.previewInlineImageHeight,
        ),
      ),
    ),
  );
}

List<InlineSpan>? _highlightedPreviewTextSpans(
  BuildContext context,
  String text,
  String query, {
  required TextStyle? style,
  MouseCursor? mouseCursor,
  GestureRecognizer? Function()? recognizerBuilder,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return null;
  }
  final normalizedText = text.toLowerCase();
  final firstMatch = normalizedText.indexOf(normalizedQuery);
  if (firstMatch < 0) {
    return null;
  }
  final highlightStyle =
      style?.merge(
        TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: BusyMarkAlpha.previewHighlight,
          ),
        ),
      ) ??
      TextStyle(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: BusyMarkAlpha.previewHighlight),
      );
  final spans = <InlineSpan>[];
  var cursor = 0;
  var match = firstMatch;
  while (match >= 0) {
    if (match > cursor) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, match),
          style: style,
          mouseCursor: mouseCursor,
          recognizer: recognizerBuilder?.call(),
        ),
      );
    }
    final end = match + normalizedQuery.length;
    spans.add(
      TextSpan(
        text: text.substring(match, end),
        style: highlightStyle,
        mouseCursor: mouseCursor,
        recognizer: recognizerBuilder?.call(),
      ),
    );
    cursor = end;
    match = normalizedText.indexOf(normalizedQuery, cursor);
  }
  if (cursor < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(cursor),
        style: style,
        mouseCursor: mouseCursor,
        recognizer: recognizerBuilder?.call(),
      ),
    );
  }
  return spans;
}

Future<void> _openPreviewLink(
  BuildContext context,
  WidgetRef ref,
  String destination,
) async {
  final target = destination.trim();
  if (target.isEmpty) {
    return;
  }
  final uri = parseSchemedUri(target);
  if (uri != null) {
    if (!isLaunchableExternalUri(uri)) {
      if (context.mounted) {
        _showPreviewLinkMessage(
          context,
          context.l10n.couldNotOpenTarget(target),
        );
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showPreviewLinkMessage(context, context.l10n.couldNotOpenTarget(target));
    }
    return;
  }

  final state = ref.read(workspaceControllerProvider);
  final workspace = state.workspace;
  final activeFilePath = workspace?.activeFilePath;
  if (workspace == null || activeFilePath == null) {
    return;
  }

  final parts = target.split('#');
  final targetPath = _decodePreviewLinkPart(parts.first);
  final anchor = parts.length > 1
      ? _decodePreviewLinkPart(parts.sublist(1).join('#'))
      : null;
  if (targetPath.isEmpty) {
    _navigatePreviewAnchor(context, ref, activeFilePath, anchor);
    return;
  }

  final resolvedPath = p.normalize(
    p.join(p.dirname(activeFilePath), targetPath),
  );
  final file = workspace.files
      .where((file) => p.normalize(file.absolutePath) == resolvedPath)
      .firstOrNull;
  if (file == null) {
    if (context.mounted) {
      _showPreviewLinkMessage(
        context,
        context.l10n.linkTargetNotFound(targetPath),
      );
    }
    return;
  }
  if (!_isOpenableTextDocument(file)) {
    if (context.mounted) {
      _showPreviewLinkMessage(context, context.l10n.cannotOpenFileTypeInEditor);
    }
    return;
  }
  if (workspace.activeFilePath != file.absolutePath) {
    if (!await saveOrConfirmSafeToChangeActiveFile(context, ref) ||
        !context.mounted) {
      return;
    }
    await ref
        .read(workspaceControllerProvider.notifier)
        .openActiveFile(file.absolutePath);
    _clearGitDetailSelection(ref);
  }
  if (!context.mounted) {
    return;
  }
  _navigatePreviewAnchor(context, ref, file.absolutePath, anchor);
}

String _decodePreviewLinkPart(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

void _navigatePreviewAnchor(
  BuildContext context,
  WidgetRef ref,
  String filePath,
  String? anchor,
) {
  if (anchor == null || anchor.isEmpty) {
    return;
  }
  final markdown = ref.read(workspaceControllerProvider).workspace?.markdown;
  if (markdown == null || markdown.filePath != filePath) {
    return;
  }
  final normalizedAnchor = anchor.startsWith('#')
      ? anchor.substring(1)
      : anchor;
  final decodedAnchor = _decodePreviewAnchor(normalizedAnchor);
  final slug = slugForHeading(decodedAnchor);
  final heading = markdown.headings
      .where(
        (heading) =>
            heading.id == normalizedAnchor ||
            heading.id == decodedAnchor ||
            heading.id == slug ||
            slugForHeading(heading.text) == slug,
      )
      .firstOrNull;
  if (heading == null) {
    _showPreviewLinkMessage(context, context.l10n.anchorNotFound(anchor));
    return;
  }
  ref
      .read(_outlineNavigationTargetProvider.notifier)
      .set(
        _OutlineNavigationTarget(
          filePath: filePath,
          headingId: heading.id,
          line: heading.span.startLine,
        ),
      );
}

void _showPreviewLinkMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _decodePreviewAnchor(String value) {
  try {
    return Uri.decodeComponent(value);
  } on FormatException {
    return value;
  }
}

class _PreviewCallout extends StatelessWidget {
  const _PreviewCallout({
    required this.icon,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.sm),
      padding: BusyMarkInsets.previewCallout,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: BusyMarkSizes.iconMd),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ProblemsList extends StatelessWidget {
  const _ProblemsList({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final diagnostics = workspace.diagnostics;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BusyMarkSurfaceColors.of(context).view,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        border: Border.all(
          color: BusyMarkSurfaceColors.of(context).subtleBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        child: diagnostics.isEmpty
            ? _EmptyPane(
                icon: BusyMarkGlyphs.check,
                title: context.l10n.noProblemsFound,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: BusyMarkSpacing.xs,
                ),
                itemCount: diagnostics.length,
                itemBuilder: (context, index) {
                  return _DiagnosticRow(diagnostic: diagnostics[index]);
                },
              ),
      ),
    );
  }
}

class _SearchSidebar extends StatelessWidget {
  const _SearchSidebar({
    required this.query,
    required this.results,
    required this.onOpenResult,
  });

  final String query;
  final List<_WorkspaceSearchResult> results;
  final Future<void> Function(_WorkspaceSearchResult result) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.search,
        title: context.l10n.search,
      );
    }
    final colors = BusyMarkSurfaceColors.of(context);
    if (results.isEmpty) {
      return _SidebarEmptyState(
        icon: BusyMarkGlyphs.searchUnavailable,
        title: context.l10n.noResults,
      );
    }
    return ListView.separated(
      padding: BusyMarkInsets.sidebarList,
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          Divider(height: BusyMarkStroke.hairline, color: colors.subtleBorder),
      itemBuilder: (context, index) {
        return _SearchResultRow(
          result: results[index],
          onOpen: () => onOpenResult(results[index]),
        );
      },
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.result, required this.onOpen});

  final _WorkspaceSearchResult result;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () => unawaited(onOpen()),
        child: Padding(
          padding: BusyMarkInsets.searchResultRow,
          child: Row(
            children: [
              Icon(
                result.icon,
                size: BusyMarkSizes.iconMd,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BusyMarkSpacing.xxs),
                    Text(
                      result.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Icon(
                BusyMarkGlyphs.rightArrow,
                size: BusyMarkSizes.iconSm,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSearchResult {
  const _WorkspaceSearchResult({
    required this.filePath,
    required this.line,
    required this.startOffset,
    required this.endOffset,
    required this.query,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String filePath;
  final int line;
  final int startOffset;
  final int endOffset;
  final String query;
  final String title;
  final String subtitle;
  final IconData icon;
}

List<_WorkspaceSearchResult> _workspaceSearchResults(
  BuildContext context,
  WorkspaceState state,
  String query,
) {
  final workspace = state.workspace;
  final trimmedQuery = query.trim();
  final normalizedQuery = trimmedQuery.toLowerCase();
  if (workspace == null || normalizedQuery.isEmpty) {
    return const [];
  }
  final results = <_WorkspaceSearchResult>[];
  final activePath = workspace.activeFilePath ?? workspace.markdown?.filePath;
  if (activePath != null) {
    final relativePath = _relativeDocumentPath(workspace, activePath);
    final lines = state.activeText.split('\n');
    var lineStartOffset = 0;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final matchColumn = line.toLowerCase().indexOf(normalizedQuery);
      if (matchColumn < 0) {
        lineStartOffset += line.length + 1;
        continue;
      }
      final lineNumber = index + 1;
      final startOffset = lineStartOffset + matchColumn;
      results.add(
        _WorkspaceSearchResult(
          filePath: activePath,
          line: lineNumber,
          startOffset: startOffset,
          endOffset: startOffset + trimmedQuery.length,
          query: trimmedQuery,
          title: _searchResultTitle(context, line),
          subtitle: context.l10n.searchResultLine(relativePath, lineNumber),
          icon: BusyMarkGlyphs.paragraph,
        ),
      );
      if (results.length >= _maxWorkspaceSearchResults) {
        return results;
      }
      lineStartOffset += line.length + 1;
    }
  }

  final sortedFiles = [...workspace.files]
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  for (final file in sortedFiles) {
    if (!_isOpenableTextDocument(file)) {
      continue;
    }
    if (!file.relativePath.toLowerCase().contains(normalizedQuery)) {
      continue;
    }
    final displayPath = file.relativePath;
    final kindLabel = _documentKindLabel(context, file.kind);
    results.add(
      _WorkspaceSearchResult(
        filePath: file.absolutePath,
        line: 1,
        startOffset: 0,
        endOffset: 0,
        query: trimmedQuery,
        title: displayPath,
        subtitle: kindLabel,
        icon: _documentKindIcon(file.kind),
      ),
    );
    if (results.length >= _maxWorkspaceSearchResults) {
      return results;
    }
  }
  return results;
}

const int _maxWorkspaceSearchResults = 80;

String _searchResultTitle(BuildContext context, String line) {
  final trimmed = _stripMarkdownForSearchResult(line, context: context);
  if (trimmed.length <= 120) {
    return trimmed;
  }
  return '${trimmed.substring(0, 117)}...';
}

String _stripMarkdownForSearchResult(String line, {BuildContext? context}) {
  var value = line.trim();
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

String _relativeDocumentPath(Workspace workspace, String path) {
  for (final file in workspace.files) {
    if (file.absolutePath == path) {
      return file.relativePath;
    }
  }
  return _fileNameFromPath(path);
}

String _fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final separator = normalized.lastIndexOf('/');
  if (separator == -1) {
    return normalized;
  }
  return normalized.substring(separator + 1);
}

IconData _documentKindIcon(DocumentKind kind) {
  return switch (kind) {
    DocumentKind.markdown ||
    DocumentKind.writersideMarkdownTopic => YaruIcons.text_editor,
    DocumentKind.writersideXmlTopic => YaruIcons.document,
    DocumentKind.tree => BusyMarkGlyphs.tree,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => BusyMarkGlyphs.symbols,
    DocumentKind.categories => BusyMarkGlyphs.category,
    DocumentKind.image => BusyMarkGlyphs.image,
    DocumentKind.resource || DocumentKind.unknown => YaruIcons.document,
  };
}

String _documentKindLabel(BuildContext context, DocumentKind kind) {
  return switch (kind) {
    DocumentKind.markdown => context.l10n.documentKindMarkdownFile,
    DocumentKind.writersideMarkdownTopic =>
      context.l10n.documentKindWritersideMarkdownTopic,
    DocumentKind.writersideXmlTopic =>
      context.l10n.documentKindWritersideXmlTopic,
    DocumentKind.tree => context.l10n.documentKindWritersideTree,
    DocumentKind.config => context.l10n.documentKindConfigurationFile,
    DocumentKind.variables => context.l10n.documentKindVariablesFile,
    DocumentKind.categories => context.l10n.documentKindCategoriesFile,
    DocumentKind.image => context.l10n.image,
    DocumentKind.resource => context.l10n.documentKindResourceFile,
    DocumentKind.unknown => context.l10n.file,
  };
}

class _DiagnosticRow extends ConsumerWidget {
  const _DiagnosticRow({required this.diagnostic});

  final Diagnostic diagnostic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: BusyMarkLinuxPalette.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () async {
          if (await saveOrConfirmSafeToChangeActiveFile(context, ref)) {
            await ref
                .read(workspaceControllerProvider.notifier)
                .openActiveFile(diagnostic.filePath);
            _clearGitDetailSelection(ref);
          }
        },
        child: Padding(
          padding: BusyMarkInsets.searchResultRow,
          child: Row(
            children: [
              Icon(
                _diagnosticIcon(diagnostic.severity),
                size: BusyMarkSizes.iconMd,
                color: _diagnosticColor(context, diagnostic.severity),
              ),
              const SizedBox(width: BusyMarkSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizeDiagnostic(context, diagnostic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: BusyMarkSpacing.xxs),
                    Text(
                      '${diagnostic.code} - ${diagnostic.filePath.split('/').last}'
                      '${diagnostic.line == null ? '' : ' ${diagnostic.line}:${diagnostic.column}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _diagnosticIcon(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.error => BusyMarkGlyphs.error,
      DiagnosticSeverity.warning => BusyMarkGlyphs.warning,
      DiagnosticSeverity.info => BusyMarkGlyphs.info,
      DiagnosticSeverity.hint => BusyMarkGlyphs.tip,
    };
  }

  Color _diagnosticColor(BuildContext context, DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.error => Theme.of(context).colorScheme.error,
      DiagnosticSeverity.warning => BusyMarkLinuxPalette.yellow,
      DiagnosticSeverity.info => Theme.of(context).colorScheme.primary,
      DiagnosticSeverity.hint => BusyMarkSurfaceColors.of(context).muted,
    };
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.mutedForeground),
          const SizedBox(height: BusyMarkSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
