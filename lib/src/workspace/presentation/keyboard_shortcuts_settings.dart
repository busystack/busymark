import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_settings.dart';
import '../../app/busymark_design.dart';
import '../../app/busymark_dialogs.dart';
import '../../app/busymark_search_field.dart';
import '../../app/command_presentation.dart';
import '../../app/command_registry.dart';
import '../../app/keymap_controller.dart';
import '../../app/keyboard_shortcut_badge.dart';
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
  final _query = TextEditingController();
  BusyMarkKeyBinding? _findBinding;
  bool _recording = false;
  final _captureFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _captureFocus.addListener(() {
      if (!_captureFocus.hasFocus && _recording) {
        _cancelRecording();
      }
    });
  }

  @override
  void dispose() {
    BusyMarkShortcutCapture.end(this);
    _captureFocus.dispose();
    _query.dispose();
    super.dispose();
  }

  void _record() {
    _captureFocus.requestFocus();
    setState(() => _recording = true);
    BusyMarkShortcutCapture.begin(
      this,
      onCandidate: (binding) {
        BusyMarkShortcutCapture.end(this);
        if (mounted) {
          setState(() {
            _recording = false;
            _findBinding = binding;
          });
        }
      },
      onCancel: _cancelRecording,
    );
  }

  void _cancelRecording() {
    BusyMarkShortcutCapture.end(this);
    if (mounted) setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsControllerProvider);
    final registry = effectiveCommandRegistry(
      BusyMarkCommandCatalog.metadata,
      settings.shortcutOverrides,
    );
    final l10n = context.l10n;
    final query = _query.text.trim().toLowerCase();
    final categories = commandCategoryOrder(context);
    final commands =
        registry.commands
            .where(
              (c) =>
                  (query.isEmpty ||
                      '${c.label(context)} ${c.category(context)} ${c.shortcut?.label ?? l10n.shortcutUnassigned} ${registry.activators(c.id).whereType<SingleActivator>().map((a) => BusyMarkKeyBinding.fromActivator(a).label).join(' ')}'
                          .toLowerCase()
                          .contains(query)) &&
                  (_findBinding == null ||
                      registry
                          .activators(c.id)
                          .any(
                            (a) =>
                                a is SingleActivator &&
                                BusyMarkKeyBinding.fromActivator(a) ==
                                    _findBinding,
                          )),
            )
            .toList()
          ..sort((a, b) {
            final group = categories
                .indexOf(a.category(context))
                .compareTo(categories.indexOf(b.category(context)));
            if (group != 0) return group;
            final name = a.label(context).compareTo(b.label(context));
            return name != 0 ? name : a.id.compareTo(b.id);
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkSearchField(
          key: const ValueKey('settings-shortcut-search'),
          controller: _query,
          hintText: l10n.shortcutSearchHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        Wrap(
          spacing: BusyMarkSpacing.sm,
          runSpacing: BusyMarkSpacing.xs,
          children: [
            BusyMarkPushButton.standard(
              key: const ValueKey('find-by-shortcut'),
              focusNode: _captureFocus,
              onPressed: _recording ? _cancelRecording : _record,
              child: Text(
                _recording ? l10n.shortcutPressKeys : l10n.shortcutFindBy,
              ),
            ),
            if (_findBinding != null)
              BusyMarkPushButton.standard(
                onPressed: () => setState(() => _findBinding = null),
                child: Text('${_findBinding!.label} ×'),
              ),
            BusyMarkPushButton.standard(
              key: const ValueKey('reset-all-shortcuts'),
              onPressed: () async {
                final confirmed = await showBusyMarkModalDialog<bool>(
                  context,
                  builder: (c) => BusyMarkDialogShell(
                    title: l10n.shortcutRestoreAll,
                    actions: [
                      BusyMarkPushButton.standard(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text(l10n.cancel),
                      ),
                      BusyMarkPushButton.suggested(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(l10n.shortcutRestoreAll),
                      ),
                    ],
                    children: [Text(l10n.shortcutRestoreAllQuestion)],
                  ),
                );
                if (confirmed == true && mounted) {
                  await ref.read(keymapControllerProvider.notifier).resetAll();
                }
              },
              child: Text(l10n.shortcutRestoreAll),
            ),
          ],
        ),
        if (ref.watch(keymapControllerProvider) == KeymapUpdateStatus.failed)
          BusyMarkActionRow(
            title: l10n.shortcutSaveFailed,
            onTap: () =>
                unawaited(ref.read(keymapControllerProvider.notifier).retry()),
            trailing: Text(l10n.shortcutRetry),
          ),
        const SizedBox(height: BusyMarkSpacing.sm),
        Expanded(
          child: commands.isEmpty
              ? Center(child: Text(l10n.noResults))
              : ListView.builder(
                  key: const ValueKey('settings-shortcut-list'),
                  itemCount: commands.length,
                  itemBuilder: (context, i) {
                    final command = commands[i];
                    final row = BusyMarkActionRow(
                      key: ValueKey('shortcut-edit-${command.id}'),
                      title: command.label(context),
                      subtitle: [
                        commandContextLabel(context, command),
                        for (final a
                            in registry
                                .activators(command.id)
                                .skip(1)
                                .whereType<SingleActivator>())
                          '\u2066${BusyMarkKeyBinding.fromActivator(a).label}\u2069',
                      ].join(' · '),
                      trailing: BusyMarkKeyboardShortcutBadge(
                        command.shortcut?.label ?? l10n.shortcutUnassigned,
                      ),
                      onTap: shortcutConfigurable(command)
                          ? () => showBusyMarkModalDialog<void>(
                              context,
                              builder: (_) => _ShortcutEditor(command: command),
                            )
                          : null,
                    );
                    final category = command.category(context);
                    if (i > 0 &&
                        commands[i - 1].category(context) == category) {
                      return row;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: BusyMarkSpacing.sm,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(
                              category,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                        row,
                      ],
                    );
                  },
                ),
        ),
      ],
    );
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
        _assignFocus.requestFocus();
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
        BusyMarkPushButton.standard(
          key: const ValueKey('remove-shortcut'),
          onPressed: _saving ? null : () => _save(remove: true),
          child: Text(l10n.shortcutRemove),
        ),
        BusyMarkPushButton.standard(
          key: const ValueKey('restore-shortcut-default'),
          onPressed: _saving ? null : () => _save(reset: true),
          child: Text(l10n.shortcutRestoreDefault),
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
        Text(commandContextLabel(context, widget.command)),
        const SizedBox(height: BusyMarkSpacing.sm),
        Text(current.shortcut?.label ?? l10n.shortcutUnassigned),
        BusyMarkPushButton.standard(
          key: const ValueKey('record-shortcut'),
          focusNode: _captureFocus,
          onPressed: _saving
              ? null
              : _recording
              ? _cancelCapture
              : _record,
          child: Text(
            _recording ? l10n.shortcutPressKeys : l10n.shortcutRecord,
          ),
        ),
        if (_candidate != null)
          Padding(
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: BusyMarkKeyboardShortcutBadge(_candidate!.label),
          ),
        if (_candidate?.hasKnownSystemConflict == true)
          Text(l10n.shortcutSystemWarning),
        if (_conflicts.isNotEmpty) ...[
          Text(l10n.shortcutConflicts),
          for (final c in _conflicts)
            Text('${c.label(context)} · ${commandContextLabel(context, c)}'),
        ],
        if (_message != null)
          Text(_message!, key: const ValueKey('shortcut-feedback')),
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
    };
