import 'dart:async';

import 'package:flutter/material.dart';

import '../platform/linux_header_bar_service.dart';
import 'busymark_design.dart';
import 'busymark_dialogs.dart';
import 'busymark_glyphs.dart';
import 'command_registry.dart';
import 'localization.dart';

Future<void> showBusyMarkCommandPalette(
  BuildContext context,
  BusyMarkCommandRegistry registry,
) async {
  final headerBar = LinuxHeaderBarService.instance;
  await showBusyMarkModalDialog<void>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => _BusyMarkCommandPalette(registry: registry),
  );
}

class _BusyMarkCommandPalette extends StatefulWidget {
  const _BusyMarkCommandPalette({required this.registry});

  final BusyMarkCommandRegistry registry;

  @override
  State<_BusyMarkCommandPalette> createState() =>
      _BusyMarkCommandPaletteState();
}

class _BusyMarkCommandPaletteState extends State<_BusyMarkCommandPalette> {
  var _query = '';

  List<BusyMarkCommand> get _commands {
    final query = _query.trim().toLowerCase();
    return widget.registry.visibleCommands().where((command) {
      if (command.execute == null) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return command.label(context).toLowerCase().contains(query) ||
          command.category(context).toLowerCase().contains(query) ||
          command.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final commands = _commands;
    return BusyMarkDialogShell(
      title: context.l10n.commandPalette,
      maxWidth: BusyMarkSizes.dialogCompact,
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.commandPaletteHint,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) {
                if (commands.isNotEmpty && commands.first.canExecute) {
                  _execute(commands.first);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        if (commands.isEmpty)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.lg),
            child: Text(
              context.l10n.commandPaletteEmpty,
              textAlign: TextAlign.center,
            ),
          )
        else
          BusyMarkGroupedList(
            filled: true,
            children: [
              for (final command in commands)
                BusyMarkActionRow(
                  title: command.label(context),
                  subtitle: command.category(context),
                  leading: const Icon(BusyMarkGlyphs.search),
                  trailing: command.shortcut == null
                      ? null
                      : Text(command.shortcut!.label),
                  enabled: command.enabled(),
                  onTap: command.enabled() ? () => _execute(command) : null,
                ),
            ],
          ),
      ],
    );
  }

  void _execute(BusyMarkCommand command) {
    Navigator.pop(context);
    unawaited(
      Future<void>.microtask(() => widget.registry.execute(command.id)),
    );
  }
}
