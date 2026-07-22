import 'package:flutter/material.dart';

import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'busymark_shortcuts.dart';
import 'localization.dart';

enum BusyMarkMainMenuAction {
  settings,
  keyboardShortcuts,
  markdownAndHtml,
  reportIssue,
  aboutBusyMark,
}

class BusyMarkMainMenuButton extends StatelessWidget {
  const BusyMarkMainMenuButton({super.key, required this.onSelected});

  final ValueChanged<BusyMarkMainMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BusyMarkHeaderPopupMenuButton<BusyMarkMainMenuAction>(
      tooltip: l10n.mainMenu,
      icon: BusyMarkGlyphs.menuVertical,
      itemBuilder: (context) => [
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
