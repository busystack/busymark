import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'command_registry.dart';
import 'localization.dart';
import 'window_control_service.dart';

enum BusyMarkMainMenuAction {
  export,
  fullScreen,
  settings,
  syntaxReference,
  reportIssue,
  aboutBusyMark,
}

class BusyMarkMainMenuButton extends ConsumerWidget {
  const BusyMarkMainMenuButton({
    super.key,
    required this.onSelected,
    this.canExport = false,
  });

  final ValueChanged<BusyMarkMainMenuAction> onSelected;
  final bool canExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final boundCommands = BusyMarkCommandRegistryScope.maybeOf(context);
    final commands = boundCommands ?? BusyMarkCommandCatalog.metadata;
    BusyMarkCommand command(String id) => commands[id]!;
    final fullScreen = ref.watch(
      windowControlServiceProvider.select((service) => service.isFullScreen),
    );
    return BusyMarkHeaderPopupMenuButton<BusyMarkMainMenuAction>(
      tooltip: l10n.mainMenu,
      icon: BusyMarkGlyphs.menuVertical,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.export,
          label: command(BusyMarkCommandIds.export).label(context),
          icon: BusyMarkGlyphs.exportPdf,
          shortcut: command(BusyMarkCommandIds.export).shortcut?.label,
          gtkAccelerator: command(
            BusyMarkCommandIds.export,
          ).shortcut?.gtkAccelerator,
          enabled: canExport,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.fullScreen,
          label: command(BusyMarkCommandIds.fullScreen).label(context),
          icon: BusyMarkGlyphs.fullScreen,
          shortcut: command(BusyMarkCommandIds.fullScreen).shortcut?.label,
          gtkAccelerator: command(
            BusyMarkCommandIds.fullScreen,
          ).shortcut?.gtkAccelerator,
          checked: fullScreen,
          trailingCheck: true,
          mutuallyExclusive: false,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.settings,
          label: command(BusyMarkCommandIds.settings).label(context),
          icon: BusyMarkGlyphs.settings,
          shortcut: command(BusyMarkCommandIds.settings).shortcut?.label,
          gtkAccelerator: command(
            BusyMarkCommandIds.settings,
          ).shortcut?.gtkAccelerator,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.syntaxReference,
          label: command(BusyMarkCommandIds.syntaxReference).label(context),
          icon: BusyMarkGlyphs.markdownFile,
          shortcut: command(BusyMarkCommandIds.syntaxReference).shortcut?.label,
          gtkAccelerator: command(
            BusyMarkCommandIds.syntaxReference,
          ).shortcut?.gtkAccelerator,
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
          BusyMarkMainMenuAction.export => BusyMarkCommandIds.export,
          BusyMarkMainMenuAction.fullScreen => BusyMarkCommandIds.fullScreen,
          BusyMarkMainMenuAction.settings => BusyMarkCommandIds.settings,
          BusyMarkMainMenuAction.syntaxReference =>
            BusyMarkCommandIds.syntaxReference,
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
