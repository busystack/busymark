import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'busymark_shortcuts.dart';
import 'localization.dart';
import 'window_control_service.dart';

enum BusyMarkMainMenuAction {
  exportPdf,
  generateMarkdownToc,
  fullScreen,
  settings,
  keyboardShortcuts,
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
    final fullScreen = ref.watch(
      windowControlServiceProvider.select((service) => service.isFullScreen),
    );
    return BusyMarkHeaderPopupMenuButton<BusyMarkMainMenuAction>(
      tooltip: l10n.mainMenu,
      icon: BusyMarkGlyphs.menuVertical,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.exportPdf,
          label: l10n.exportAsPdf,
          icon: BusyMarkGlyphs.exportPdf,
          shortcut: BusyMarkAppShortcutLabels.exportPdf,
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
          label: l10n.fullScreen,
          icon: BusyMarkGlyphs.fullScreen,
          shortcut: BusyMarkAppShortcutLabels.fullScreen,
          checked: fullScreen,
          trailingCheck: true,
          mutuallyExclusive: false,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.settings,
          label: l10n.settings,
          icon: BusyMarkGlyphs.settings,
          shortcut: BusyMarkAppShortcutLabels.settings,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.keyboardShortcuts,
          label: l10n.keyboardShortcuts,
          icon: BusyMarkGlyphs.keyboard,
          shortcut: BusyMarkAppShortcutLabels.keyboardShortcuts,
        ),
        BusyMarkPopupMenuItem(
          value: BusyMarkMainMenuAction.markdownAndHtml,
          label: l10n.markdownAndHtml,
          icon: BusyMarkGlyphs.markdownFile,
          shortcut: BusyMarkAppShortcutLabels.markdownAndHtml,
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
      onSelected: onSelected,
    );
  }
}
