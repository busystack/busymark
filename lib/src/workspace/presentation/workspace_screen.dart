import 'dart:async';
import 'dart:io';
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
import '../../core/diagnostic.dart';
import '../../core/local_image_resolver.dart';
import '../../core/path_utils.dart' show slugForHeading;
import '../../editor/source_folding.dart';
import '../../editor/source_highlighter.dart';
import '../../markdown/markdown_model.dart';
import '../../markdown/preview_export.dart';
import '../../platform/linux_header_bar_service.dart';
import '../../writerside/writerside_model.dart';
import '../workspace_controller.dart';
import '../workspace_model.dart';
import '../workspace_safety.dart';
import 'welcome_screen.dart';

final _outlineNavigationTargetProvider =
    StateProvider<_OutlineNavigationTarget?>((ref) => null);
final _sourceNavigationTargetProvider = StateProvider<_SourceNavigationTarget?>(
  (ref) => null,
);

const _sourceTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

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

    final colors = BusyMarkSurfaceColors.of(context);
    final headerBar = ref.watch(linuxHeaderBarServiceProvider);
    final useNativeHeaderBar = headerBar.usesNativeHeaderBar;
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    ref.listen(headerBarActionsProvider, (previous, next) {
      next.whenData((action) {
        _handleHeaderBarAction(context, ref, action);
      });
    });
    if (headerBar.isAvailable) {
      _configureHeaderBar(context, headerBar, workspace, state, settings);
    }

    return Scaffold(
      backgroundColor: colors.window,
      appBar: useNativeHeaderBar
          ? null
          : AppBar(
              leadingWidth: 50,
              titleSpacing: 0,
              leading: Center(
                child: BusyMarkHeaderIconButton(
                  tooltip: 'Welcome',
                  icon: Icons.home_outlined,
                  onPressed: () async {
                    if (await confirmSafeToContinue(context, ref) &&
                        context.mounted) {
                      context.go('/');
                    }
                  },
                ),
              ),
              title: _HeaderTitle(
                title: _activeFileName(workspace),
                subtitle: _workspaceKindLabel(workspace.kind),
                dirty: state.isDirty,
              ),
              actions: [
                const SizedBox(width: BusyMarkSpacing.sm),
                BusyMarkHeaderIconButton(
                  tooltip: 'Save',
                  icon: Icons.check,
                  accented: state.isDirty,
                  onPressed: () => unawaited(
                    saveActiveWithOverwriteConfirmation(context, ref),
                  ),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: 'Validate',
                  icon: Icons.fact_check_outlined,
                  onPressed: () =>
                      unawaited(_validateActiveAndShowProblems(context, ref)),
                ),
                const _HeaderSeparator(),
                BusyMarkHeaderIconButton(
                  tooltip: settings.sidebarVisible
                      ? 'Hide sidebar'
                      : 'Show sidebar',
                  icon: Icons.view_sidebar_outlined,
                  selected: settings.sidebarVisible,
                  onPressed: () => settingsController.setSidebarVisible(
                    !settings.sidebarVisible,
                  ),
                ),
                BusyMarkHeaderIconButton(
                  tooltip:
                      settings.documentViewMode ==
                          DocumentViewModePreference.source
                      ? 'Show preview'
                      : 'Hide preview',
                  icon: Icons.preview_outlined,
                  selected:
                      settings.documentViewMode !=
                      DocumentViewModePreference.source,
                  onPressed: () => settingsController.setPreviewVisible(
                    settings.documentViewMode ==
                        DocumentViewModePreference.source,
                  ),
                ),
                const _HeaderSeparator(),
                BusyMarkHeaderIconButton(
                  tooltip: 'Export',
                  icon: Icons.ios_share_outlined,
                  onPressed: () => _showExportDialog(context, ref),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: 'Settings',
                  icon: Icons.settings_outlined,
                  onPressed: () => context.go('/settings'),
                ),
                BusyMarkHeaderIconButton(
                  tooltip: 'About BusyMark',
                  icon: Icons.info_outline,
                  onPressed: () => showBusyMarkAboutDialog(context),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
              ],
            ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            _InlineMessage(
              icon: Icons.warning_amber_outlined,
              message: state.errorMessage!,
            ),
          Expanded(
            child: Row(
              children: [
                if (settings.sidebarVisible && _hasWorkspaceSidebar(workspace))
                  SizedBox(
                    width: BusyMarkSizes.sidebarWidth,
                    child: _Sidebar(workspace: workspace),
                  ),
                Expanded(
                  child: _EditorPreviewSplit(
                    state: state,
                    viewMode: settings.documentViewMode,
                    editorFontSize: settings.editorFontSize,
                    wordWrap: settings.wordWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _configureHeaderBar(
    BuildContext context,
    LinuxHeaderBarService headerBar,
    Workspace workspace,
    WorkspaceState state,
    AppSettings settings,
  ) {
    final title = state.isDirty
        ? '*${_activeFileName(workspace)}'
        : _activeFileName(workspace);
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
        await headerBar.setCanSave(state.isDirty);
        await headerBar.setSearchActive(false);
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
        unawaited(() async {
          if (await confirmSafeToContinue(context, ref) && context.mounted) {
            context.go('/');
          }
        }());
      case HeaderBarAction.sidebarToggle:
        unawaited(
          settingsController.setSidebarVisible(!settings.sidebarVisible),
        );
      case HeaderBarAction.refresh:
        unawaited(_validateActiveAndShowProblems(context, ref));
      case HeaderBarAction.save:
        unawaited(saveActiveWithOverwriteConfirmation(context, ref));
      case HeaderBarAction.settings:
        context.go('/settings');
      case HeaderBarAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
      case HeaderBarAction.exportPreview:
        _showExportDialog(context, ref);
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
        _showSearchDialog(context, ref);
      case HeaderBarAction.menu:
        break;
    }
  }

  String _activeFileName(Workspace workspace) {
    return workspace.activeFilePath?.split('/').last ?? 'Workspace';
  }

  String _workspaceKindLabel(WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.singleMarkdown => 'Single Markdown file',
      WorkspaceKind.markdownFolder => 'Markdown folder',
      WorkspaceKind.writersideModule => 'Writerside module',
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

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final controller = ref.read(workspaceControllerProvider.notifier);
    final html = controller.exportActiveHtml();
    final diagnostics = controller.exportDiagnosticsJson();
    final summary = controller.exportProjectSummaryJson();
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    unawaited(
      showBusyMarkModalDialog<void>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: 'Export Preview',
          maxWidth: 860,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
          children: [
            SizedBox(
              width: 800,
              height: 460,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'HTML'),
                        Tab(text: 'Diagnostics JSON'),
                        Tab(text: 'Project JSON'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _ReadonlyExportText(html),
                          _ReadonlyExportText(diagnostics),
                          _ReadonlyExportText(summary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(workspaceControllerProvider);
    if (state.workspace == null) {
      return;
    }
    final headerBar = ref.read(linuxHeaderBarServiceProvider);
    unawaited(() async {
      if (headerBar.isAvailable) {
        await headerBar.setSearchActive(true);
      }
      if (!context.mounted) {
        return;
      }
      try {
        await showBusyMarkModalDialog<void>(
          context,
          headerBarService: headerBar.isAvailable ? headerBar : null,
          builder: (dialogContext) => _WorkspaceSearchDialog(
            state: state,
            onOpenResult: (result) async {
              Navigator.pop(dialogContext);
              await _openSearchResult(context, ref, result);
            },
          ),
        );
      } finally {
        if (headerBar.isAvailable) {
          await headerBar.setSearchActive(false);
        }
      }
    }());
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
    if (workspace.activeFilePath != result.filePath) {
      if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
        return;
      }
      await ref
          .read(workspaceControllerProvider.notifier)
          .openActiveFile(result.filePath);
    }
    if (!context.mounted) {
      return;
    }
    ref.read(_sourceNavigationTargetProvider.notifier).state =
        _SourceNavigationTarget(filePath: result.filePath, line: result.line);
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
          title: 'Problems',
          maxWidth: 760,
          children: [
            Text(
              count == 1 ? '1 diagnostic' : '$count diagnostics',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: BusyMarkSurfaceColors.of(context).mutedForeground,
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            SizedBox(
              width: 700,
              height: 420,
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

class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
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

class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.workspace});

  final Workspace workspace;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  late int _tab;
  late String _workspaceId;
  String? _activeFilePath;

  @override
  void initState() {
    super.initState();
    _workspaceId = widget.workspace.id;
    _activeFilePath = widget.workspace.activeFilePath;
    _tab = _preferredSidebarTabIndex(widget.workspace);
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace.id != _workspaceId) {
      _workspaceId = widget.workspace.id;
      _activeFilePath = widget.workspace.activeFilePath;
      _tab = _preferredSidebarTabIndex(widget.workspace);
      return;
    }
    if (widget.workspace.activeFilePath != _activeFilePath) {
      _activeFilePath = widget.workspace.activeFilePath;
      _tab = _preferredSidebarTabIndex(widget.workspace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final tabs = _sidebarTabsFor(widget.workspace.kind);
    final selectedIndex = tabs.isEmpty
        ? 0
        : _tab.clamp(0, tabs.length - 1).toInt();
    final selectedTab = tabs.isEmpty ? null : tabs[selectedIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.sidebarBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarHeader(workspace: widget.workspace),
          if (tabs.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    BusyMarkRadius.headerButton,
                  ),
                  boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    BusyMarkRadius.headerButton,
                  ),
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (var index = 0; index < tabs.length; index++)
                        ButtonSegment(
                          value: index,
                          label: Text(_sidebarTabLabel(tabs[index])),
                        ),
                    ],
                    selected: {selectedIndex},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                ),
              ),
            ),
          Expanded(
            child: switch (selectedTab) {
              _SidebarTab.files => _FilesTab(workspace: widget.workspace),
              _SidebarTab.toc => _TocTab(workspace: widget.workspace),
              _SidebarTab.outline => _OutlineTab(workspace: widget.workspace),
              null => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

enum _SidebarTab { files, toc, outline }

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
    WorkspaceKind.singleMarkdown => const [_SidebarTab.outline],
    WorkspaceKind.markdownFolder => const [
      _SidebarTab.files,
      _SidebarTab.outline,
    ],
    WorkspaceKind.writersideModule => const [
      _SidebarTab.files,
      _SidebarTab.toc,
      _SidebarTab.outline,
    ],
  };
}

String _sidebarTabLabel(_SidebarTab tab) {
  return switch (tab) {
    _SidebarTab.files => 'Files',
    _SidebarTab.toc => 'TOC',
    _SidebarTab.outline => 'Outline',
  };
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _workspaceName(workspace.rootPath),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BusyMarkSpacing.xs),
          Text(
            '${_workspaceKindLabel(workspace.kind)} - ${workspace.files.length} files',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  String _workspaceName(String path) {
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }

  String _workspaceKindLabel(WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.singleMarkdown => 'Markdown',
      WorkspaceKind.markdownFolder => 'Folder',
      WorkspaceKind.writersideModule => 'Writerside',
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
      return const _SidebarEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No files',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
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
                  if (await confirmSafeToContinue(context, ref)) {
                    await ref
                        .read(workspaceControllerProvider.notifier)
                        .openActiveFile(file.absolutePath);
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected
            ? busyMarkSelectedBackground(context)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: clickable
              ? busyMarkRowHoverColor(context)
              : Colors.transparent,
          onTap: clickable ? onTap : null,
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                SizedBox(width: 4 + depth * 14),
                SizedBox.square(
                  dimension: 18,
                  child: hasChildren
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enabled ? onToggle ?? onTap : null,
                          child: AnimatedRotation(
                            turns: expanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 120),
                            child: Icon(
                              YaruIcons.pan_end,
                              size: 14,
                              color: foreground,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: BusyMarkSpacing.xs),
                SizedBox.square(
                  dimension: 18,
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
    DocumentKind.tree => Icons.account_tree_outlined,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => Icons.percent_outlined,
    DocumentKind.categories => Icons.category_outlined,
    DocumentKind.image => Icons.image_outlined,
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
      return const _SidebarEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'No Writerside TOC',
      );
    }
    final instance = module.instances.first;
    final entries = _visibleTocTreeEntries(
      instance.tocRoots,
      _expandedNodeKeys,
    );
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Text(
              instance.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: busyMarkSectionHeaderStyle(context),
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
            : module.topicsByFileName[node.topicFileName]?.filePath;
        final label =
            node.tocTitle ?? node.topicFileName ?? node.href ?? 'TOC section';
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
          icon: node.href != null ? Icons.open_in_new : Icons.article_outlined,
          hasChildren: hasChildren,
          expanded: expanded,
          muted: node.hidden,
          onToggle: hasChildren ? toggle : null,
          onTap: topic != null
              ? () async {
                  if (await confirmSafeToContinue(context, ref)) {
                    await ref
                        .read(workspaceControllerProvider.notifier)
                        .openActiveFile(topic);
                  }
                }
              : hasChildren
              ? toggle
              : null,
        );
      },
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
        : module.topicsByFileName[node.topicFileName]?.filePath;
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
      return const _SidebarEmptyState(
        icon: Icons.format_size_outlined,
        title: 'No outline',
      );
    }
    final activeFilePath =
        widget.workspace.activeFilePath ?? widget.workspace.markdown?.filePath;
    final tree = _buildOutlineTree(headings);
    final entries = _visibleOutlineTreeEntries(tree, _expandedNodeKeys);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
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
          icon: Icons.tag_outlined,
          leading: _HeadingBadge(level: heading.level),
          hasChildren: hasChildren,
          expanded: expanded,
          onToggle: hasChildren ? toggle : null,
          onTap: activeFilePath == null
              ? null
              : () {
                  ref
                      .read(_outlineNavigationTargetProvider.notifier)
                      .state = _OutlineNavigationTarget(
                    filePath: activeFilePath,
                    headingId: heading.id,
                    line: heading.span.startLine,
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
          'H$level',
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

class _EditorPreviewSplit extends ConsumerStatefulWidget {
  const _EditorPreviewSplit({
    required this.state,
    required this.viewMode,
    required this.editorFontSize,
    required this.wordWrap,
  });

  final WorkspaceState state;
  final DocumentViewModePreference viewMode;
  final double editorFontSize;
  final bool wordWrap;

  @override
  ConsumerState<_EditorPreviewSplit> createState() =>
      _EditorPreviewSplitState();
}

class _EditorPreviewSplitState extends ConsumerState<_EditorPreviewSplit> {
  late final BusyMarkSourceEditingController _controller;
  late final FocusNode _sourceFocusNode;
  late final ScrollController _sourceScrollController;
  late final ScrollController _previewScrollController;
  final _sourceEditorKey = GlobalKey();
  final _previewHeadingKeys = <String, GlobalKey>{};
  final _foldedRegionKeys = <String>{};
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    _controller = BusyMarkSourceEditingController(
      text: widget.state.activeText,
      language: _sourceSyntaxLanguage(widget.state.workspace),
    )..renderText = false;
    _sourceFocusNode = FocusNode();
    _sourceScrollController = ScrollController();
    _previewScrollController = ScrollController();
    _lastPath = widget.state.workspace?.activeFilePath ?? '';
  }

  @override
  void didUpdateWidget(covariant _EditorPreviewSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = widget.state.workspace?.activeFilePath ?? '';
    _controller.language = _sourceSyntaxLanguage(widget.state.workspace);
    if (path != _lastPath) {
      _lastPath = path;
      _foldedRegionKeys.clear();
      _controller.clearFoldedRegions();
      _previewHeadingKeys.clear();
      _controller.text = widget.state.activeText;
    }
  }

  @override
  void dispose() {
    _previewScrollController.dispose();
    _sourceScrollController.dispose();
    _sourceFocusNode.dispose();
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
    final colors = BusyMarkSurfaceColors.of(context);
    final editorVisible = widget.viewMode == DocumentViewModePreference.editor;
    final sourceVisible =
        widget.viewMode != DocumentViewModePreference.preview && !editorVisible;
    final previewVisible =
        widget.viewMode != DocumentViewModePreference.source && !editorVisible;
    final foldRegions = _syncSourceFoldRegions();
    final sourceStrutStyle = _sourceStrutStyle(
      folded: _foldedRegionKeys.isNotEmpty,
    );
    final visualEditorStrutStyle = StrutStyle.fromTextStyle(
      _visualEditorTextStyle,
      forceStrutHeight: true,
    );
    final sourceLineHeight = _sourceLineHeight(context, sourceStrutStyle);
    _controller
      ..renderText = editorVisible
      ..visualMarkdown = editorVisible;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Row(
        children: [
          if (editorVisible)
            Expanded(
              child: _VisualMarkdownEditorPane(
                controller: _controller,
                focusNode: _sourceFocusNode,
                scrollController: _sourceScrollController,
                textStyle: _visualEditorTextStyle,
                strutStyle: visualEditorStrutStyle,
                wordWrap: widget.wordWrap,
                dirty: widget.state.isDirty,
                onChanged: _handleSourceChanged,
              ),
            ),
          if (sourceVisible)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(color: colors.view),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PaneHeader(
                      icon: Icons.edit_note_outlined,
                      title: 'Source',
                      trailing: _StatusPill(
                        label: widget.state.isDirty ? 'Unsaved' : 'Saved',
                        active: widget.state.isDirty,
                      ),
                    ),
                    Expanded(
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
                          child: TextField(
                            controller: _controller,
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
                              alpha: 0.82,
                            ),
                            cursorHeight: widget.editorFontSize * 1.22,
                            cursorWidth: 1.4,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                _SourceEditorFrame.editorPaddingLeft,
                                _SourceEditorFrame.editorPaddingTop,
                                _SourceEditorFrame.editorPaddingRight,
                                _SourceEditorFrame.editorPaddingBottom,
                              ),
                            ),
                            onChanged: _handleSourceChanged,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (sourceVisible && previewVisible)
            VerticalDivider(width: 1, color: colors.subtleBorder),
          if (previewVisible)
            Expanded(
              child: _PreviewPane(
                preview: widget.state.preview,
                workspace: widget.state.workspace,
                controller: _previewScrollController,
                headingKeys: _previewHeadingKeys,
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

  void _handleSourceChanged(String value) {
    if (_foldedRegionKeys.isNotEmpty) {
      setState(() {
        _foldedRegionKeys.clear();
        _controller.clearFoldedRegions();
      });
    }
    ref.read(workspaceControllerProvider.notifier).updateActiveText(value);
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
    return workspace.kind == WorkspaceKind.singleMarkdown
        ? DocumentKind.markdown
        : null;
  }

  void _scrollToOutlineTarget(_OutlineNavigationTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollSourceToLine(target.line);
      _scrollPreviewToHeading(target.headingId);
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
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          _jumpSourceScrollToLine(line);
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
    fontFamily: 'Ubuntu Mono',
    fontSize: widget.editorFontSize,
    height: 1.45,
    leadingDistribution: TextLeadingDistribution.even,
  );

  TextStyle get _visualEditorTextStyle => TextStyle(
    fontFamily: 'Ubuntu',
    fontSize: widget.editorFontSize + 1,
    height: 1.55,
    leadingDistribution: TextLeadingDistribution.even,
  );

  StrutStyle? _sourceStrutStyle({required bool folded}) {
    if (folded) {
      return null;
    }
    return StrutStyle.fromTextStyle(_sourceTextStyle, forceStrutHeight: true);
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
      duration: const Duration(milliseconds: 180),
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
        .clamp(0.0, _sourceScrollController.position.maxScrollExtent)
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
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
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
}

class _VisualMarkdownEditorPane extends StatelessWidget {
  const _VisualMarkdownEditorPane({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.textStyle,
    required this.strutStyle,
    required this.wordWrap,
    required this.dirty,
    required this.onChanged,
  });

  final BusyMarkSourceEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final TextStyle textStyle;
  final StrutStyle? strutStyle;
  final bool wordWrap;
  final bool dirty;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            icon: Icons.edit_document,
            title: 'Editor',
            trailing: _StatusPill(
              label: dirty ? 'Unsaved' : 'Saved',
              active: dirty,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              keyboardType: wordWrap
                  ? TextInputType.multiline
                  : TextInputType.text,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: textStyle,
              strutStyle: strutStyle,
              selectionHeightStyle: BoxHeightStyle.max,
              selectionWidthStyle: BoxWidthStyle.tight,
              cursorColor: colors.foreground.withValues(alpha: 0.82),
              cursorHeight: (textStyle.fontSize ?? 15) * 1.22,
              cursorWidth: 1.4,
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                fillColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(28, 24, 28, 36),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
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

  static const double editorPaddingTop = 16;
  static const double editorPaddingBottom = 16;
  static const double editorPaddingLeft = 12;
  static const double editorPaddingRight = 16;
  static const double _gutterWidth = 72;

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
            .max(1, constraints.maxWidth - _gutterWidth - 1)
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
              VerticalDivider(width: 1, color: colors.subtleBorder),
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
            final scrollOffset = scrollController.hasClients
                ? scrollController.offset
                : 0.0;
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
                final scrollOffset = scrollController.hasClients
                    ? scrollController.offset
                    : 0.0;
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
                final scrollOffset = scrollController.hasClients
                    ? scrollController.offset
                    : 0.0;
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
      colors.foreground.withValues(alpha: 0.045),
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

  final SourceGutterEntry entry;
  final bool active;
  final double lineHeight;
  final TextStyle textStyle;
  final ValueChanged<SourceFoldRegion> onToggleFold;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final region = entry.region;
    final activeColor = colors.foreground.withValues(alpha: 0.045);
    final numberStyle = textStyle.copyWith(
      color: active ? colors.foreground : colors.mutedForeground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: lineHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: Text('${entry.lineNumber}', style: numberStyle),
              ),
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 22,
            height: lineHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: region == null
                  ? const SizedBox.shrink()
                  : _SourceFoldButton(
                      region: region,
                      collapsed: entry.collapsed,
                      onToggleFold: onToggleFold,
                    ),
            ),
          ),
          const SizedBox(width: 7),
        ],
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
          ? 'Expand ${_foldKindLabel(region.kind)}'
          : 'Collapse ${_foldKindLabel(region.kind)}',
      waitDuration: const Duration(milliseconds: 450),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onToggleFold(region),
          child: SizedBox.square(
            dimension: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
              ),
              child: Icon(
                collapsed ? YaruIcons.pan_end : YaruIcons.pan_down,
                size: 13,
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
}) {
  final painter = TextPainter(
    text: controller.buildSourceTextSpan(context: context, style: textStyle),
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

String _foldKindLabel(SourceFoldKind kind) {
  return switch (kind) {
    SourceFoldKind.section => 'section',
    SourceFoldKind.list => 'list',
    SourceFoldKind.blockquote => 'quote',
    SourceFoldKind.code => 'code block',
    SourceFoldKind.xml => 'tag',
  };
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.preview,
    required this.workspace,
    required this.controller,
    required this.headingKeys,
  });

  final PreviewDocument? preview;
  final Workspace? workspace;
  final ScrollController controller;
  final Map<String, GlobalKey> headingKeys;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final document = preview;
    if (document == null) {
      return const _EmptyPane(
        icon: Icons.preview_outlined,
        title: 'No preview',
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            icon: Icons.preview_outlined,
            title: document.modeLabel,
            trailing: document.compatibility.isEmpty
                ? const SizedBox.shrink()
                : Text(document.compatibility),
          ),
          Expanded(
            child: SelectionArea(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final block in document.blocks)
                            _PreviewBlockView(
                              block,
                              workspace: workspace,
                              key: _keyForBlock(block),
                            ),
                        ],
                      ),
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
  const _PreviewBlockView(this.block, {required this.workspace, super.key});

  final PreviewBlock block;
  final Workspace? workspace;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      PreviewBlockKind.heading => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: _PreviewInlineText(
          block: block,
          style: _headingStyle(context, block.level),
        ),
      ),
      PreviewBlockKind.code => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Text(
          block.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Ubuntu Mono',
            height: 1.45,
          ),
        ),
      ),
      PreviewBlockKind.image => _PreviewImageBlock(
        block: block,
        workspace: workspace,
      ),
      PreviewBlockKind.admonition => _PreviewCallout(
        icon: _admonitionIcon(block.attributes['style']),
        color: switch (block.attributes['style']) {
          'warning' => colors.admonitionWarning,
          'tip' => colors.admonitionTip,
          _ => colors.admonitionNote,
        },
        child: _PreviewInlineText(
          block: block.text.isEmpty
              ? PreviewBlock(
                  kind: block.kind,
                  text: block.attributes['style'] ?? 'Note',
                )
              : block,
        ),
      ),
      PreviewBlockKind.tabs => _PreviewCallout(
        icon: Icons.tab_outlined,
        color: colors.panel,
        child: Text(block.text),
      ),
      PreviewBlockKind.procedure => _PreviewCallout(
        icon: Icons.format_list_numbered,
        color: colors.panel,
        child: Text(block.text),
      ),
      PreviewBlockKind.list => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _ListMarker(block: block),
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(child: _PreviewInlineText(block: block)),
          ],
        ),
      ),
      PreviewBlockKind.quote => _PreviewCallout(
        icon: Icons.format_quote_outlined,
        color: colors.panel,
        child: _PreviewInlineText(block: block),
      ),
      PreviewBlockKind.thematicBreak => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: colors.subtleBorder),
      ),
      _ => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _PreviewInlineText(block: block),
      ),
    };
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
      'warning' => Icons.warning_amber_outlined,
      'tip' => Icons.lightbulb_outline,
      _ => Icons.info_outline,
    };
  }
}

class _PreviewInlineText extends ConsumerWidget {
  const _PreviewInlineText({required this.block, this.style});

  final PreviewBlock block;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
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
              onLinkTap: (destination) =>
                  _openPreviewLink(context, ref, destination),
            ),
        ],
      ),
    );
  }
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
        task == 'true'
            ? Icons.check_box_outlined
            : Icons.check_box_outline_blank,
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
      padding: const EdgeInsets.only(top: 7),
      child: Icon(Icons.circle, size: 6, color: colors.mutedForeground),
    );
  }
}

class _PreviewImageBlock extends StatelessWidget {
  const _PreviewImageBlock({required this.block, required this.workspace});

  final PreviewBlock block;
  final Workspace? workspace;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final imagePath = _resolvePreviewImagePath(workspace, block);
    if (imagePath == null) {
      return _PreviewCallout(
        icon: Icons.image_not_supported_outlined,
        color: colors.panel,
        child: Text(block.text),
      );
    }
    final width = _previewImageWidth(block);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width ?? 760),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.panel,
                border: Border.all(color: colors.subtleBorder),
                borderRadius: BorderRadius.circular(BusyMarkRadius.md),
              ),
              child: Image.file(
                File(imagePath),
                width: width,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(BusyMarkSpacing.md),
                  child: Text(block.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _resolvePreviewImagePath(Workspace? workspace, PreviewBlock block) {
  final source = block.attributes['src'];
  final activeFilePath = workspace?.activeFilePath;
  if (workspace == null || activeFilePath == null || source == null) {
    return null;
  }
  final uri = Uri.tryParse(source);
  if (_isExternalPreviewUri(uri)) {
    return null;
  }
  final module = workspace.writersideModule;
  return resolveLocalImagePath(
    activeFilePath: activeFilePath,
    destination: source,
    workspaceRoot: workspace.rootPath,
    writersideRoot: module?.rootPath,
    imagesDir: module?.config.imagesDir ?? 'images',
  );
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
  return parsed.clamp(80, 760).toDouble();
}

InlineSpan _previewInlineSpan(
  BuildContext context,
  PreviewInline inline, {
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
          fontFamily: 'Ubuntu Mono',
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
    PreviewInlineKind.image => span(
      text: inline.text,
      children: null,
      style: mergeStyle(
        TextStyle(color: colors.mutedForeground, fontStyle: FontStyle.italic),
      ),
    ),
  };
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
  final uri = Uri.tryParse(target);
  if (_isExternalPreviewUri(uri)) {
    final launched = await launchUrl(
      uri!,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showPreviewLinkMessage(context, 'Could not open $target');
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
      _showPreviewLinkMessage(context, 'Link target not found: $targetPath');
    }
    return;
  }
  if (!_isOpenableTextDocument(file)) {
    if (context.mounted) {
      _showPreviewLinkMessage(context, 'Cannot open this file type in editor');
    }
    return;
  }
  if (workspace.activeFilePath != file.absolutePath) {
    if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
      return;
    }
    await ref
        .read(workspaceControllerProvider.notifier)
        .openActiveFile(file.absolutePath);
  }
  if (!context.mounted) {
    return;
  }
  _navigatePreviewAnchor(context, ref, file.absolutePath, anchor);
}

bool _isExternalPreviewUri(Uri? uri) {
  if (uri == null) {
    return false;
  }
  return uri.scheme == 'http' ||
      uri.scheme == 'https' ||
      uri.scheme == 'mailto';
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
  final slug = slugForHeading(normalizedAnchor);
  final heading = markdown.headings
      .where(
        (heading) =>
            heading.id == normalizedAnchor ||
            heading.id == slug ||
            slugForHeading(heading.text) == slug,
      )
      .firstOrNull;
  if (heading == null) {
    _showPreviewLinkMessage(context, 'Anchor not found: $anchor');
    return;
  }
  ref
      .read(_outlineNavigationTargetProvider.notifier)
      .state = _OutlineNavigationTarget(
    filePath: filePath,
    headingId: heading.id,
    line: heading.span.startLine,
  );
}

void _showPreviewLinkMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
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
            ? const _EmptyPane(
                icon: Icons.check_circle_outline,
                title: 'No problems found',
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: diagnostics.length,
                itemBuilder: (context, index) {
                  return _DiagnosticRow(diagnostic: diagnostics[index]);
                },
              ),
      ),
    );
  }
}

class _WorkspaceSearchDialog extends StatefulWidget {
  const _WorkspaceSearchDialog({
    required this.state,
    required this.onOpenResult,
  });

  final WorkspaceState state;
  final Future<void> Function(_WorkspaceSearchResult result) onOpenResult;

  @override
  State<_WorkspaceSearchDialog> createState() => _WorkspaceSearchDialogState();
}

class _WorkspaceSearchDialogState extends State<_WorkspaceSearchDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = _workspaceSearchResults(widget.state, query);
    return BusyMarkDialogShell(
      title: 'Search',
      maxWidth: 700,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search',
          ),
          onSubmitted: (_) {
            if (results.isNotEmpty) {
              unawaited(widget.onOpenResult(results.first));
            }
          },
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        _SearchResultsList(
          query: query,
          results: results,
          onOpenResult: widget.onOpenResult,
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
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
      return const SizedBox(width: 640, height: 280);
    }
    final colors = BusyMarkSurfaceColors.of(context);
    return SizedBox(
      width: 640,
      height: 360,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.control,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          child: results.isEmpty
              ? const _EmptyPane(icon: Icons.search_off, title: 'No results')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: results.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: colors.subtleBorder),
                  itemBuilder: (context, index) {
                    return _SearchResultRow(
                      result: results[index],
                      onOpen: () => onOpenResult(results[index]),
                    );
                  },
                ),
        ),
      ),
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
      color: Colors.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () => unawaited(onOpen()),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.lg,
            vertical: BusyMarkSpacing.sm,
          ),
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
                Icons.chevron_right,
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
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String filePath;
  final int line;
  final String title;
  final String subtitle;
  final IconData icon;
}

List<_WorkspaceSearchResult> _workspaceSearchResults(
  WorkspaceState state,
  String query,
) {
  final workspace = state.workspace;
  final normalizedQuery = query.trim().toLowerCase();
  if (workspace == null || normalizedQuery.isEmpty) {
    return const [];
  }
  final results = <_WorkspaceSearchResult>[];
  final activePath = workspace.activeFilePath;
  if (activePath != null) {
    final relativePath = _relativeDocumentPath(workspace, activePath);
    final lines = state.activeText.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!line.toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      final lineNumber = index + 1;
      results.add(
        _WorkspaceSearchResult(
          filePath: activePath,
          line: lineNumber,
          title: _searchExcerpt(line),
          subtitle: '$relativePath - Line $lineNumber',
          icon: Icons.subject,
        ),
      );
      if (results.length >= _maxWorkspaceSearchResults) {
        return results;
      }
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
    final kindLabel = _documentKindLabel(file.kind);
    results.add(
      _WorkspaceSearchResult(
        filePath: file.absolutePath,
        line: 1,
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

String _searchExcerpt(String line) {
  final trimmed = line.trim();
  if (trimmed.length <= 120) {
    return trimmed;
  }
  return '${trimmed.substring(0, 117)}...';
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
    DocumentKind.tree => Icons.account_tree_outlined,
    DocumentKind.config => YaruIcons.gear,
    DocumentKind.variables => Icons.percent_outlined,
    DocumentKind.categories => Icons.category_outlined,
    DocumentKind.image => Icons.image_outlined,
    DocumentKind.resource || DocumentKind.unknown => YaruIcons.document,
  };
}

String _documentKindLabel(DocumentKind kind) {
  return switch (kind) {
    DocumentKind.markdown => 'Markdown file',
    DocumentKind.writersideMarkdownTopic => 'Writerside Markdown topic',
    DocumentKind.writersideXmlTopic => 'Writerside XML topic',
    DocumentKind.tree => 'Writerside tree',
    DocumentKind.config => 'Configuration file',
    DocumentKind.variables => 'Variables file',
    DocumentKind.categories => 'Categories file',
    DocumentKind.image => 'Image',
    DocumentKind.resource => 'Resource file',
    DocumentKind.unknown => 'File',
  };
}

class _DiagnosticRow extends ConsumerWidget {
  const _DiagnosticRow({required this.diagnostic});

  final Diagnostic diagnostic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: busyMarkRowHoverColor(context),
        onTap: () async {
          if (await confirmSafeToContinue(context, ref)) {
            await ref
                .read(workspaceControllerProvider.notifier)
                .openActiveFile(diagnostic.filePath);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.lg,
            vertical: BusyMarkSpacing.sm,
          ),
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
                      diagnostic.message,
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
      DiagnosticSeverity.error => Icons.error_outline,
      DiagnosticSeverity.warning => Icons.warning_amber_outlined,
      DiagnosticSeverity.info => Icons.info_outline,
      DiagnosticSeverity.hint => Icons.tips_and_updates_outlined,
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

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Container(
      height: BusyMarkSizes.paneHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.md),
      decoration: BoxDecoration(
        color: colors.headerbarFlat,
        border: Border(bottom: BorderSide(color: colors.subtleBorder)),
      ),
      child: Row(
        children: [
          Icon(icon, size: BusyMarkSizes.iconSm, color: colors.mutedForeground),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: BusyMarkSpacing.sm),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.labelSmall!.copyWith(color: colors.mutedForeground),
                child: trailing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primaryContainer
            : colors.control,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
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

class _ReadonlyExportText extends StatelessWidget {
  const _ReadonlyExportText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
                icon: const Icon(Icons.copy, size: BusyMarkSizes.iconSm),
                label: const Text('Copy'),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BusyMarkSpacing.md),
              child: SelectableText(
                value,
                style: const TextStyle(fontFamily: 'Ubuntu Mono', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
