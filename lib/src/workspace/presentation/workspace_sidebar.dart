import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/command_registry.dart';
import '../../app/localization.dart';
import '../../core/debug_log.dart';
import '../../search/search_session.dart';
import '../../search/search_sidebar.dart';
import '../recent_navigation.dart';
import '../workspace_controller.dart';

final _sidebarViewMenuControllerProvider =
    Provider<BusyMarkHeaderMenuController>((ref) {
      final controller = BusyMarkHeaderMenuController(
        debugLabel: BusyMarkCommandIds.sidebarViewSelector,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

typedef _SidebarContext = ({String? workspaceId});

final _sidebarRevealProvider =
    NotifierProvider<_SidebarReveal, _SidebarContext?>(_SidebarReveal.new);

class _SidebarReveal extends Notifier<_SidebarContext?> {
  @override
  _SidebarContext? build() => null;

  void reveal(_SidebarContext context) => state = context;
}

/// Both pages own a sidebar, including when there is no workspace on Welcome.
bool watchSidebarSelectorReveal(
  BuildContext context,
  WidgetRef ref, {
  required String? workspaceId,
}) {
  final sidebarContext = (workspaceId: workspaceId);
  ref.listen(workspaceNavigationCommandProvider, (_, request) {
    if (request?.$1 != BusyMarkCommandIds.sidebarViewSelector) return;
    busyMarkViewSelectorTrace('workspace-received', {'command': request!.$1});
    final menu = ref.read(_sidebarViewMenuControllerProvider);
    ref.read(_sidebarRevealProvider.notifier).reveal(sidebarContext);
    ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
    final settings = ref.read(appSettingsControllerProvider);
    if (!settings.sidebarVisible) {
      unawaited(
        ref
            .read(appSettingsControllerProvider.notifier)
            .setSidebarVisible(true, animate: false),
      );
    }
    // The overlay/expanded sidebar must be laid out before reading its anchor.
    unawaited(() async {
      await WidgetsBinding.instance.endOfFrame;
      if (context.mounted) menu.open();
    }());
  });
  return ref.watch(_sidebarRevealProvider) == sidebarContext;
}

class WorkspaceSidebar<T> extends ConsumerWidget {
  const WorkspaceSidebar({
    super.key,
    required this.contextLabel,
    required this.items,
    required this.onSelected,
    required this.content,
    this.viewHeader,
    this.onReviewReplacement,
  });

  final Widget contextLabel;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final Widget? viewHeader;
  final Widget content;
  final Future<void> Function()? onReviewReplacement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searching = ref.watch(searchSessionProvider.select((s) => s.active));
    final commands =
        BusyMarkCommandRegistryScope.maybeOf(context) ??
        BusyMarkCommandCatalog.metadata;
    return BusyMarkSidebarSurface(
      showEndBorder: false,
      child: IndexedStack(
        index: searching ? 1 : 0,
        children: [
          ExcludeFocus(
            excluding: searching,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: BusyMarkInsets.sidebarHeader,
                  child: WorkspaceSidebarHeaderRow(
                    key: const ValueKey('workspace-sidebar-primary-row'),
                    child: Row(
                      children: [
                        Expanded(child: contextLabel),
                        const SizedBox(width: BusyMarkSpacing.sm),
                        BusyMarkHeaderPopupMenuButton<T>.native(
                          key: const ValueKey('workspace-sidebar-view-menu'),
                          controller: ref.watch(
                            _sidebarViewMenuControllerProvider,
                          ),
                          tooltip: context.l10n.sidebarViewMenu,
                          shortcut:
                              commands[BusyMarkCommandIds.sidebarViewSelector]
                                  ?.shortcut
                                  ?.label,
                          icon: BusyMarkGlyphs.sidebarViews,
                          transparent: true,
                          borderRadius: BusyMarkRadius.nativeHeaderButton,
                          highlightWhenOpen: false,
                          itemBuilder: (_) => items,
                          onSelected: onSelected,
                        ),
                      ],
                    ),
                  ),
                ),
                if (viewHeader != null) viewHeader!,
                Expanded(child: content),
              ],
            ),
          ),
          ExcludeFocus(
            excluding: !searching,
            child: SearchSidebar(onReviewReplacement: onReviewReplacement),
          ),
        ],
      ),
    );
  }
}

class WorkspaceSidebarHeaderRow extends StatelessWidget {
  const WorkspaceSidebarHeaderRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: BusyMarkSizes.iconButton),
    child: child,
  );
}

class RecentSidebarPanel extends ConsumerWidget {
  const RecentSidebarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(
      appSettingsControllerProvider.select(
        (settings) => settings.recentWorkspaces,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkSidebarHeader(
          key: const ValueKey('workspace-sidebar-first-content'),
          title: context.l10n.recent,
          leading: const Icon(BusyMarkGlyphs.history),
        ),
        Expanded(
          child: SearchResultList(
            recordDensity: BusyMarkRecordDensity.comfortable,
            results: [
              for (final resource in recent) RecentSearchResult(resource),
            ],
            onActivate: (result) => openRecentResource(
              ref,
              (result as RecentSearchResult).resource,
            ),
          ),
        ),
      ],
    );
  }
}
