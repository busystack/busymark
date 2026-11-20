import '../../app/busymark_resource_menu.dart';
import '../workspace_resource_actions.dart';
import '../../app/command_registry.dart';
import 'workspace_sidebar.dart';
import '../../search/search_session.dart';
import '../../search/search_sidebar.dart';
import '../../search/welcome_notes_action.dart';
import '../../nextcloud_notes/application/nextcloud_connection.dart';
import 'dart:async';

import 'package:busymark/src/app/startup_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/app_router.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_design.dart';
import '../../app/linux/linux_page_frame.dart';
import '../../app/linux/linux_header_style.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/busymark_main_menu.dart';
import '../../app/localization.dart';
import '../../app/window_control_service.dart';
import '../../feedback/presentation/feedback_dialog.dart';
import '../../platform/gtk_header_icon_service.dart';
import '../workspace_controller.dart';
import '../workspace_message.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final settings = ref.watch(appSettingsControllerProvider);
    final colors = BusyMarkSurfaceColors.of(context);
    final search = ref.watch(searchSessionProvider);
    final sidebarVisible = settings.sidebarVisible || search.active;
    final connection =
        ProviderScope.containerOf(
          context,
          listen: false,
        ).exists(nextcloudConnectionProvider)
        ? ref.watch(nextcloudConnectionProvider)
        : const NextcloudConnectionState();
    final pending = ref.watch(welcomeNotesActionProvider);
    if (pending != null && connection.account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(welcomeNotesActionProvider) == pending &&
            ref
                    .read(appRouterProvider)
                    .routeInformationProvider
                    .value
                    .uri
                    .path ==
                '/') {
          unawaited(
            performWorkspaceResourceAction(
              ref,
              WorkspaceResourceAction.forNotes(pending),
            ),
          );
        }
      });
    }
    final startupPath = ref.watch(startupPathProvider);
    final startupNavigation = ref.read(startupNavigationGuardProvider);
    if (startupNavigation.claimStartupPath(startupPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(openWorkspaceResourcePath(ref, startupPath!));
        }
      });
    } else if (startupNavigation.claimSessionRestore(startupPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        // Register startup restoration before awaiting settings so an early
        // close also waits for recovery publication and sees its dirty state.
        final restored = await ref
            .read(workspaceControllerProvider.notifier)
            .restoreStartupSession();
        if (restored && mounted) {
          this.context.go('/workspace');
        }
      });
    }

    final welcomeMainColor = colors.view;
    final sidebarRevealed = watchSidebarSelectorReveal(
      context,
      ref,
      workspaceId: null,
    );
    final welcomeSidebar = WorkspaceSidebar<bool>(
      contextLabel: Row(
        children: [
          const Icon(BusyMarkGlyphs.home, size: BusyMarkSizes.iconSm),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.home,
              key: const ValueKey('workspace-sidebar-primary-label'),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      items: [
        BusyMarkPopupMenuItem(
          value: true,
          label: context.l10n.recent,
          icon: BusyMarkGlyphs.history,
          mnemonic: 'E',
          shortcut: 'E',
          gtkAccelerator: 'e',
          checked: true,
          trailingCheck: true,
        ),
      ],
      onSelected: (_) {},
      content: const RecentSidebarPanel(),
    );
    final welcomeContent = ColoredBox(
      color: welcomeMainColor,
      child: BusyMarkClamp(
        maxWidth: BusyMarkSizes.contentWidth,
        margin: EdgeInsets.zero,
        padding: BusyMarkInsets.welcomePage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (connection.removedWithWarning)
              BusyMarkStatusBox(
                message: context.l10n.notesRemovedWarning,
                kind: BusyMarkStatusKind.warning,
              ),
            BusyMarkGroupedList(
              title: context.l10n.create,
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: context.l10n.createMarkdownFile,
                  subtitle: context.l10n.createMarkdownFileDescription,
                  leading: const Icon(BusyMarkGlyphs.newDocument),
                  trailing: Icon(
                    BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                  ),
                  onTap: () => _run(WorkspaceResourceAction.newMarkdown),
                ),
                BusyMarkActionRow(
                  key: const ValueKey('welcome-new-nextcloud-note'),
                  title: context.l10n.newNextcloudNote,
                  subtitle: connection.account == null
                      ? context.l10n.nextcloudNotes
                      : 'Nextcloud · ${connection.account!.server}',
                  leading: const Icon(BusyMarkGlyphs.newDocument),
                  onTap: () => _run(WorkspaceResourceAction.newNote),
                ),
                BusyMarkActionRow(
                  title: context.l10n.createWritersideProject,
                  subtitle: context.l10n.createWritersideProjectDescription,
                  leading: const Icon(BusyMarkGlyphs.writersideProject),
                  trailing: Icon(
                    BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                  ),
                  onTap: () => _run(WorkspaceResourceAction.newWriterside),
                ),
              ],
            ),
            BusyMarkGroupedList(
              title: context.l10n.open,
              filled: true,
              children: [
                BusyMarkActionRow(
                  title: context.l10n.openMarkdownFile,
                  subtitle: context.l10n.markdownFileExtensions,
                  leading: const Icon(BusyMarkGlyphs.markdownFile),
                  trailing: Icon(
                    BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                  ),
                  onTap: () => _run(WorkspaceResourceAction.openMarkdown),
                ),
                BusyMarkActionRow(
                  title: context.l10n.openFolderOrWritersideProject,
                  subtitle: context.l10n.markdownFolderOrWritersideProject,
                  leading: const Icon(BusyMarkGlyphs.folder),
                  trailing: Icon(
                    BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                  ),
                  onTap: () => _run(WorkspaceResourceAction.openFolder),
                ),
                BusyMarkActionRow(
                  key: const ValueKey('welcome-nextcloud-notes'),
                  title: context.l10n.browseNotes,
                  subtitle: connection.account == null
                      ? context.l10n.nextcloudNotes
                      : 'Nextcloud · ${connection.account!.server}',
                  leading: const Icon(BusyMarkGlyphs.documentHistory),
                  trailing: Icon(
                    BusyMarkGlyphs.forwardFor(Directionality.of(context)),
                  ),
                  onTap: () => _run(WorkspaceResourceAction.browseNotes),
                ),
              ],
            ),
            if (state.isLoading) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              const LinearProgressIndicator(),
            ],
            if (state.message != null) ...[
              const SizedBox(height: BusyMarkSpacing.lg),
              BusyMarkStatusBox(
                message: localizeWorkspaceMessage(context, state.message!),
                kind: busyMarkWorkspaceMessageStatusKind(state.message!.code),
              ),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: welcomeMainColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow =
              constraints.maxWidth <
              BusyMarkSizes.sidebarWidth + BusyMarkSizes.previewMinWidth;
          return LinuxPageFrame(
            sidebarHeader: const BusyMarkLinuxBrandHeader(),
            sidebarBody: welcomeSidebar,
            sidebarAvailable: !narrow || search.active || sidebarRevealed,
            sidebarOverlay: narrow && (search.active || sidebarRevealed),
            sidebarExpanded: sidebarVisible,
            sidebarTransitionGeneration: ref.watch(
              sidebarTransitionGenerationProvider,
            ),
            header: BusyMarkLinuxHeaderLayout(
              leading: BusyMarkLinuxHeaderControlGroup(
                children: [
                  BusyMarkLinuxHeaderIconButton(
                    tooltip: sidebarVisible
                        ? context.l10n.hideSidebar
                        : context.l10n.showSidebar,
                    icon: BusyMarkGlyphs.sidebar,
                    nativeIcon: BusyMarkLinuxHeaderIcon.sidebar,
                    selected: sidebarVisible,
                    shortcut:
                        (BusyMarkCommandRegistryScope.maybeOf(context) ??
                                BusyMarkCommandCatalog
                                    .metadata)[BusyMarkCommandIds.toggleSidebar]
                            ?.shortcut
                            ?.label,
                    onPressed: _toggleSidebar,
                  ),
                ],
              ),
              centerAllocation: search.active
                  ? BusyMarkLinuxHeaderCenterAllocation.fillBetweenControls
                  : BusyMarkLinuxHeaderCenterAllocation.centeredBetweenControls,
              title: search.active
                  ? const SearchHeaderField()
                  : BusyMarkLinuxHeaderTitle(context.l10n.appTitle),
              trailing: BusyMarkLinuxHeaderControlGroup(
                children: [
                  BusyMarkHeaderIconButton(
                    tooltip: context.l10n.search,
                    icon: BusyMarkGlyphs.search,
                    selected: search.active,
                    onPressed: () =>
                        ref.read(searchSessionProvider.notifier).toggle(),
                  ),
                  ...BusyMarkResourceMenuButton.buttons,
                  BusyMarkMainMenuButton(
                    onSelected: (action) =>
                        _handleMainMenuAction(context, action),
                  ),
                ],
              ),
            ),
            body: welcomeContent,
          );
        },
      ),
    );
  }

  void _run(WorkspaceResourceAction action) =>
      unawaited(performWorkspaceResourceAction(ref, action));

  void _toggleSidebar() {
    final settings = ref.read(appSettingsControllerProvider);
    unawaited(
      ref
          .read(appSettingsControllerProvider.notifier)
          .setSidebarVisible(!settings.sidebarVisible),
    );
  }

  void _handleMainMenuAction(
    BuildContext context,
    BusyMarkMainMenuAction action,
  ) {
    switch (action) {
      case BusyMarkMainMenuAction.export:
        return;
      case BusyMarkMainMenuAction.fullScreen:
        unawaited(ref.read(windowControlServiceProvider).toggleFullScreen());
      case BusyMarkMainMenuAction.settings:
        context.go(settingsLocation(SettingsReturnTarget.welcome));
      case BusyMarkMainMenuAction.syntaxReference:
        showBusyMarkSyntaxReferenceDialog(context);
      case BusyMarkMainMenuAction.reportIssue:
        showBusyMarkFeedbackDialog(context);
      case BusyMarkMainMenuAction.aboutBusyMark:
        showBusyMarkAboutDialog(context);
    }
  }
}

BusyMarkStatusKind busyMarkWorkspaceMessageStatusKind(
  WorkspaceMessageCode code,
) {
  return switch (code) {
    WorkspaceMessageCode.chooseWhereToSaveMarkdown =>
      BusyMarkStatusKind.information,
    WorkspaceMessageCode.recoveryRestored => BusyMarkStatusKind.information,
    WorkspaceMessageCode.saveBlockedFileChangedOnDisk ||
    WorkspaceMessageCode.recentWorkspaceUpdateFailed ||
    WorkspaceMessageCode.recoveryDamaged => BusyMarkStatusKind.warning,
    WorkspaceMessageCode.openFailed ||
    WorkspaceMessageCode.createWritersideProjectFailed ||
    WorkspaceMessageCode.createWritersideTopicFailed ||
    WorkspaceMessageCode.couldNotOpenFile ||
    WorkspaceMessageCode.saveFailed ||
    WorkspaceMessageCode.fileOperationFailed ||
    WorkspaceMessageCode.validationFailed => BusyMarkStatusKind.error,
  };
}
