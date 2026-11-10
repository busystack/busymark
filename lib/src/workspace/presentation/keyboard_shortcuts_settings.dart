import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/command_presentation.dart';
import '../../app/command_registry.dart';
import '../../app/keymap_controller.dart';
import '../../app/keyboard_shortcut_badge.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../../app/shortcut_binding.dart';
import '../../app/shortcut_capture.dart';

class KeyboardShortcutsSettings extends ConsumerStatefulWidget {
  const KeyboardShortcutsSettings({super.key});
  @override
  ConsumerState<KeyboardShortcutsSettings> createState() =>
      _KeyboardShortcutsSettingsState();
}

class _KeyboardShortcutsSettingsState
    extends ConsumerState<KeyboardShortcutsSettings> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsControllerProvider);
    final registry = effectiveCommandRegistry(
      BusyMarkCommandCatalog.metadata,
      settings.shortcutOverrides,
    );
    final l10n = context.l10n;
    final categories = commandCategoryOrder(context);
    final commands = registry.commands.toList()
      ..sort((a, b) {
        final group = categories
            .indexOf(a.category(context))
            .compareTo(categories.indexOf(b.category(context)));
        if (group != 0) return group;
        final name = a.label(context).compareTo(b.label(context));
        return name != 0 ? name : a.id.compareTo(b.id);
      });
    final groups = <String, List<BusyMarkCommand>>{
      for (final category in categories)
        if (commands.any((c) => c.category(context) == category))
          category: commands
              .where((c) => c.category(context) == category)
              .toList(),
    };
    final deferred = deferredDefaultConflicts(
      BusyMarkCommandCatalog.metadata,
      validatedShortcutOverrides(
        BusyMarkCommandCatalog.metadata,
        settings.shortcutOverrides,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ref.watch(keymapControllerProvider) == KeymapUpdateStatus.failed)
          BusyMarkBanner(
            title: l10n.shortcutSaveFailed,
            actionLabel: l10n.shortcutRetry,
            onAction: () =>
                unawaited(ref.read(keymapControllerProvider.notifier).retry()),
          ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('settings-shortcut-list'),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups.entries.elementAt(i);
              return BusyMarkGroupedList(
                title: group.key,
                filled: true,
                children: [
                  for (final command in group.value)
                    _commandRow(
                      context,
                      registry,
                      command,
                      deferred[command.id],
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: BusyMarkPushButton.standard(
            key: const ValueKey('reset-all-shortcuts'),
            onPressed: _restoring ? null : _restoreAll,
            child: Text(l10n.shortcutRestoreAll),
          ),
        ),
      ],
    );
  }

  Widget _commandRow(
    BuildContext context,
    BusyMarkCommandRegistry registry,
    BusyMarkCommand command,
    List<BusyMarkCommand>? conflicts,
  ) {
    final configurable = shortcutConfigurable(command);
    final description = [
      commandContextLabel(context, command),
      if (!configurable) context.l10n.shortcutFixed,
      if (conflicts != null) context.l10n.shortcutDefaultConflict,
      for (final a
          in registry
              .activators(command.id)
              .skip(1)
              .whereType<SingleActivator>())
        '\u2066${BusyMarkKeyBinding.fromActivator(a).label}\u2069',
    ].join(' · ');
    return BusyMarkActionRow(
      key: ValueKey('shortcut-edit-${command.id}'),
      title: command.label(context),
      subtitle: description,
      tooltip: '${command.label(context)}\n$description',
      enabled: configurable,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: BusyMarkKeyboardShortcutBadge(
          command.shortcut?.label ?? context.l10n.shortcutUnassigned,
        ),
      ),
      onTap: configurable
          ? () => showBusyMarkModalDialog<void>(
              context,
              builder: (_) => _ShortcutEditor(command: command),
            )
          : null,
    );
  }

  Future<void> _restoreAll() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      final confirmed = await showBusyMarkModalDialog<bool>(
        context,
        builder: (c) => BusyMarkDialogShell(
          title: context.l10n.shortcutRestoreAll,
          actions: [
            BusyMarkPushButton.standard(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.l10n.cancel),
            ),
            BusyMarkPushButton.suggested(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.l10n.shortcutRestoreAll),
            ),
          ],
          children: [Text(context.l10n.shortcutRestoreAllQuestion)],
        ),
      );
      if (confirmed == true && mounted) {
        await ref.read(keymapControllerProvider.notifier).resetAll();
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

class _ShortcutEditor extends ConsumerStatefulWidget {
  const _ShortcutEditor({required this.command});
  final BusyMarkCommand command;
  @override
  ConsumerState<_ShortcutEditor> createState() => _ShortcutEditorState();
}

class _ShortcutEditorState extends ConsumerState<_ShortcutEditor> {
  late Map<String, BusyMarkKeyBinding?> _expected;
  BusyMarkKeyBinding? _candidate;
  bool _recording = false, _saving = false;
  bool _reset = false;
  List<BusyMarkCommand> _conflicts = const [];
  String? _message;
  final _assignFocus = FocusNode();
  final _captureFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _expected = ref.read(appSettingsControllerProvider).shortcutOverrides;
    _conflicts =
        deferredDefaultConflicts(
          BusyMarkCommandCatalog.metadata,
          validatedShortcutOverrides(
            BusyMarkCommandCatalog.metadata,
            _expected,
          ),
        )[widget.command.id] ??
        const [];
    if (_conflicts.isNotEmpty) {
      _candidate = defaultBinding(
        BusyMarkCommandCatalog.metadata[widget.command.id]!,
      );
      _reset = true;
    }

    _captureFocus.addListener(() {
      if (!_captureFocus.hasFocus && _recording) {
        _cancelCapture();
      }
    });
  }

  @override
  void dispose() {
    BusyMarkShortcutCapture.end(this);
    _assignFocus.dispose();
    _captureFocus.dispose();
    super.dispose();
  }

  void _cancelCapture() {
    BusyMarkShortcutCapture.end(this);
    if (mounted) {
      setState(() {
        _recording = false;
      });
    }
  }

  void _record() {
    _captureFocus.requestFocus();
    setState(() {
      _recording = true;
      _conflicts = const [];
      _message = null;
    });
    BusyMarkShortcutCapture.begin(
      this,
      onCandidate: (binding) {
        BusyMarkShortcutCapture.end(this);
        if (!mounted) return;
        setState(() {
          _candidate = binding;
          _recording = false;
          _reset = false;
          _expected = ref.read(appSettingsControllerProvider).shortcutOverrides;
          _conflicts = effectiveCommandRegistry(
            BusyMarkCommandCatalog.metadata,
            _expected,
          ).conflicts(widget.command.id, binding);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _assignFocus.requestFocus();
        });
      },
      onCancel: _cancelCapture,
    );
  }

  Future<void> _save({
    bool reset = false,
    bool remove = false,
    bool reassign = false,
  }) async {
    if (_saving) return;
    _cancelCapture();
    setState(() {
      _saving = true;
      _reset = reset;
    });
    final result = await ref
        .read(keymapControllerProvider.notifier)
        .update(
          widget.command.id,
          remove ? null : _candidate,
          expected: _expected,
          reset: reset,
          reassign: reassign ? _conflicts.map((c) => c.id).toSet() : const {},
        );
    if (!mounted) return;
    if (result.status == KeymapUpdateStatus.saved) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _conflicts = result.conflicts;
      _expected = ref.read(appSettingsControllerProvider).shortcutOverrides;
      _message = switch (result.status) {
        KeymapUpdateStatus.failed => context.l10n.shortcutSaveFailed,
        KeymapUpdateStatus.changed => context.l10n.shortcutChanged,
        KeymapUpdateStatus.invalid => context.l10n.shortcutInvalid,
        _ => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = effectiveCommandRegistry(
      BusyMarkCommandCatalog.metadata,
      ref.watch(appSettingsControllerProvider).shortcutOverrides,
    )[widget.command.id]!;
    return BusyMarkDialogShell(
      title: widget.command.label(context),
      actions: [
        BusyMarkPushButton.standard(
          onPressed: _saving
              ? null
              : () {
                  _cancelCapture();
                  Navigator.pop(context);
                },
          child: Text(l10n.cancel),
        ),
        BusyMarkPushButton.suggested(
          key: const ValueKey('assign-shortcut'),
          focusNode: _assignFocus,
          onPressed:
              _saving || _recording || _candidate == null && _conflicts.isEmpty
              ? null
              : () => _save(reset: _reset, reassign: _conflicts.isNotEmpty),
          child: Text(
            _conflicts.isEmpty ? l10n.shortcutAssign : l10n.shortcutReassign,
          ),
        ),
      ],
      children: [
        if (_saving)
          Semantics(
            label: l10n.save,
            liveRegion: true,
            child: const LinearProgressIndicator(
              key: ValueKey('shortcut-saving'),
            ),
          ),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkActionRow(
              title: l10n.shortcutCurrentBinding,
              subtitle: commandContextLabel(context, widget.command),
              trailing: BusyMarkKeyboardShortcutBadge(
                current.shortcut?.label ?? l10n.shortcutUnassigned,
              ),
            ),
            BusyMarkActionRow(
              key: const ValueKey('record-shortcut'),
              title: _recording ? l10n.shortcutPressKeys : l10n.shortcutRecord,
              enabled: !_saving,
              leading: const Icon(BusyMarkGlyphs.keyboard),
              onTap: _recording ? _cancelCapture : _record,
              // Focus remains on the explicit recording control, never an editor.
              trailing: Focus(
                focusNode: _captureFocus,
                skipTraversal: true,
                includeSemantics: false,
                child: const SizedBox.shrink(),
              ),
            ),
            if (_candidate != null)
              BusyMarkActionRow(
                title: l10n.shortcutProposedBinding,
                trailing: BusyMarkKeyboardShortcutBadge(_candidate!.label),
              ),
          ],
        ),
        if (_candidate?.hasKnownSystemConflict == true)
          Text(l10n.shortcutSystemWarning),
        if (_conflicts.isNotEmpty)
          BusyMarkGroupedList(
            title: l10n.shortcutConflicts,
            filled: true,
            children: [
              for (final c in _conflicts)
                BusyMarkActionRow(
                  title: c.label(context),
                  subtitle: commandContextLabel(context, c),
                  trailing: BusyMarkKeyboardShortcutBadge(
                    effectiveCommandRegistry(
                          BusyMarkCommandCatalog.metadata,
                          ref
                              .read(appSettingsControllerProvider)
                              .shortcutOverrides,
                        )[c.id]?.shortcut?.label ??
                        l10n.shortcutUnassigned,
                  ),
                ),
            ],
          ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(_message!, key: const ValueKey('shortcut-feedback')),
          ),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkActionRow(
              key: const ValueKey('remove-shortcut'),
              title: l10n.shortcutRemove,
              enabled: !_saving,
              onTap: () => _save(remove: true),
            ),
            BusyMarkActionRow(
              key: const ValueKey('restore-shortcut-default'),
              title: l10n.shortcutRestoreDefault,
              enabled: !_saving,
              onTap: () => _save(reset: true),
            ),
          ],
        ),
      ],
    );
  }
}

String commandContextLabel(BuildContext context, BusyMarkCommand command) =>
    switch (command.scope) {
      BusyMarkCommandScope.application =>
        context.l10n.shortcutContextApplication,
      BusyMarkCommandScope.documentView => context.l10n.shortcutContextDocument,
      BusyMarkCommandScope.editor ||
      BusyMarkCommandScope.textEditing => context.l10n.shortcutContextEditor,
      BusyMarkCommandScope.wysiwyg => context.l10n.editor,
      BusyMarkCommandScope.sourceSymbol =>
        context.l10n.shortcutContextWritersideSource,
      BusyMarkCommandScope.sidebar => context.l10n.shortcutContextWorkspace,
      BusyMarkCommandScope.tree => context.l10n.shortcutContextTree,
      BusyMarkCommandScope.git => context.l10n.git,
    };
