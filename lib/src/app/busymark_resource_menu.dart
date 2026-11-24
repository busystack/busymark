import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace/workspace_resource_actions.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'command_registry.dart';
import 'localization.dart';

final resourceMenuControllerProvider =
    Provider.family<BusyMarkHeaderMenuController, String>((ref, id) {
      final controller = BusyMarkHeaderMenuController();
      ref.onDispose(controller.dispose);
      return controller;
    });

class BusyMarkResourceMenuButton extends ConsumerWidget {
  const BusyMarkResourceMenuButton._(this.commandId);

  static const commandIds = [
    BusyMarkCommandIds.open,
    BusyMarkCommandIds.newDocument,
  ];
  static const buttons = [
    BusyMarkResourceMenuButton._(BusyMarkCommandIds.open),
    BusyMarkResourceMenuButton._(BusyMarkCommandIds.newDocument),
  ];

  final String commandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry =
        BusyMarkCommandRegistryScope.maybeOf(context) ??
        BusyMarkCommandCatalog.metadata;
    final command = registry[commandId]!;
    final l10n = context.l10n;
    final isNew = commandId == BusyMarkCommandIds.newDocument;
    final entries = isNew
        ? [
            (
              WorkspaceResourceAction.newMarkdown,
              l10n.createMarkdownFile,
              BusyMarkGlyphs.markdownFile,
              'M',
            ),
            (
              WorkspaceResourceAction.newNote,
              l10n.newNextcloudNote,
              BusyMarkGlyphs.newDocument,
              'N',
            ),
            (
              WorkspaceResourceAction.newWriterside,
              l10n.createWritersideProject,
              BusyMarkGlyphs.writersideProject,
              'W',
            ),
          ]
        : [
            (
              WorkspaceResourceAction.openMarkdown,
              l10n.openMarkdownFile,
              BusyMarkGlyphs.markdownFile,
              'M',
            ),
            (
              WorkspaceResourceAction.openFolder,
              l10n.openFolderOrWritersideProject,
              BusyMarkGlyphs.folder,
              'F',
            ),
            (
              WorkspaceResourceAction.browseNotes,
              l10n.browseNotes,
              BusyMarkGlyphs.documentHistory,
              'N',
            ),
          ];
    return BusyMarkHeaderPopupMenuButton<WorkspaceResourceAction>(
      key: ValueKey(isNew ? 'header-new-menu' : 'header-open-menu'),
      controller: ref.watch(resourceMenuControllerProvider(commandId)),
      tooltip: isNew ? l10n.newResource : l10n.open,
      shortcut: command.shortcut?.label,
      icon: isNew ? BusyMarkGlyphs.add : BusyMarkGlyphs.folder,
      itemBuilder: (_) => [
        for (final (action, label, icon, mnemonic) in entries)
          BusyMarkPopupMenuItem(
            value: action,
            label: label,
            icon: icon,
            mnemonic: mnemonic,
            shortcut: mnemonic,
            gtkAccelerator: mnemonic.toLowerCase(),
          ),
      ],
      onSelected: (action) =>
          unawaited(performWorkspaceResourceAction(ref, action)),
    );
  }
}
