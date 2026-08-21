import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'command_registry.dart';
import 'localization.dart';
import 'window_control_service.dart';

enum BusyMarkMainMenuAction {
  exportPdf,
  generateMarkdownToc,
  fullScreen,
  settings,
  keyboardShortcuts,
  commandPalette,
  markdownAndHtml,
  reportIssue,
  aboutBusyMark,
}

class BusyMarkMainMenuButton extends ConsumerWidget {
  const BusyMarkMainMenuButton({
    super.key,
    required this.onSelected,
    this.canExportPdf = false,
    this.canGenerateMarkdownToc = false,
  });

  final ValueChanged<BusyMarkMainMenuAction> onSelected;
  final bool canExportPdf;
  final bool canGenerateMarkdownToc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final commands =
        BusyMarkCommandRegistryScope.maybeOf(context) ??
        BusyMarkCommandCatalog.metadata;
    BusyMarkCommand command(String id) => commands[id]!;
    final fullScreen = ref.watch(
      windowControlServiceProvider.select((service) => service.isFullScreen),
    );
    return BusyMarkHeaderPopupMenuButton<BusyMarkMainMenuAction>(
      tooltip: l10n.mainMenu,
      icon: BusyMarkGlyphs.menuVertical,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.exportPdf,
          label: command(BusyMarkCommandIds.exportPdf).label(context),
          icon: BusyMarkGlyphs.exportPdf,
          shortcut: command(BusyMarkCommandIds.exportPdf).shortcut?.label,
          enabled: canExportPdf,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.generateMarkdownToc,
          label: l10n.generateOrUpdateMarkdownToc,
          icon: BusyMarkGlyphs.orderedList,
          enabled: canGenerateMarkdownToc,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.fullScreen,
          label: command(BusyMarkCommandIds.fullScreen).label(context),
          icon: BusyMarkGlyphs.fullScreen,
          shortcut: command(BusyMarkCommandIds.fullScreen).shortcut?.label,
          checked: fullScreen,
          trailingCheck: true,
          mutuallyExclusive: false,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.settings,
          label: command(BusyMarkCommandIds.settings).label(context),
          icon: BusyMarkGlyphs.settings,
          shortcut: command(BusyMarkCommandIds.settings).shortcut?.label,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.keyboardShortcuts,
          label: command(BusyMarkCommandIds.keyboardShortcuts).label(context),
          icon: BusyMarkGlyphs.keyboard,
          shortcut: command(
            BusyMarkCommandIds.keyboardShortcuts,
          ).shortcut?.label,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.commandPalette,
          label: command(BusyMarkCommandIds.commandPalette).label(context),
          icon: BusyMarkGlyphs.search,
          shortcut: command(BusyMarkCommandIds.commandPalette).shortcut?.label,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.markdownAndHtml,
          label: command(BusyMarkCommandIds.markdownAndHtml).label(context),
          icon: BusyMarkGlyphs.markdownFile,
          shortcut: command(BusyMarkCommandIds.markdownAndHtml).shortcut?.label,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.reportIssue,
          label: l10n.reportIssue,
          icon: BusyMarkGlyphs.feedback,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.aboutBusyMark,
          label: l10n.aboutBusyMark,
          icon: BusyMarkGlyphs.info,
        ),
      ],
      onSelected: (action) {
        final commandId = switch (action) {
          BusyMarkMainMenuAction.exportPdf => BusyMarkCommandIds.exportPdf,
          BusyMarkMainMenuAction.fullScreen => BusyMarkCommandIds.fullScreen,
          BusyMarkMainMenuAction.settings => BusyMarkCommandIds.settings,
          BusyMarkMainMenuAction.keyboardShortcuts =>
            BusyMarkCommandIds.keyboardShortcuts,
          BusyMarkMainMenuAction.commandPalette =>
            BusyMarkCommandIds.commandPalette,
          BusyMarkMainMenuAction.markdownAndHtml =>
            BusyMarkCommandIds.markdownAndHtml,
          BusyMarkMainMenuAction.generateMarkdownToc ||
          BusyMarkMainMenuAction.reportIssue ||
          BusyMarkMainMenuAction.aboutBusyMark => null,
        };
        if (commandId != null && commands[commandId]?.execute != null) {
          unawaited(commands.execute(commandId));
        } else {
          onSelected(action);
        }
      },
    );
  }
}
