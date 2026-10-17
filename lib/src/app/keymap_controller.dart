import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import 'command_registry.dart';
import 'shortcut_binding.dart';

enum KeymapUpdateStatus { saved, failed, changed, conflict, invalid }

class KeymapUpdate {
  const KeymapUpdate(this.status, [this.conflicts = const []]);
  final KeymapUpdateStatus status;
  final List<BusyMarkCommand> conflicts;
}

/// Validation and publication are synchronous after hydration. A stale editor
/// can never publish its old copy of the entire map over a newer assignment.
class KeymapController extends Notifier<KeymapUpdateStatus> {
  @override
  KeymapUpdateStatus build() {
    ref.listen(shortcutPersistenceOutcomeProvider, (_, saved) {
      if (saved != null) {
        state = saved ? KeymapUpdateStatus.saved : KeymapUpdateStatus.failed;
      }
    });
    return KeymapUpdateStatus.saved;
  }

  int _generation = 0;

  Future<KeymapUpdate> update(
    String commandId,
    BusyMarkKeyBinding? binding, {
    required Map<String, BusyMarkKeyBinding?> expected,
    bool reset = false,
    Set<String> reassign = const {},
  }) async {
    final settings = ref.read(appSettingsControllerProvider.notifier);
    await settings.waitUntilLoaded();
    if (!ref.mounted) return const KeymapUpdate(KeymapUpdateStatus.changed);
    final current = ref.read(appSettingsControllerProvider).shortcutOverrides;
    if (!mapEquals(current, expected)) {
      return const KeymapUpdate(KeymapUpdateStatus.changed);
    }
    final defaults = BusyMarkCommandCatalog.metadata;
    final command = defaults[commandId];
    if (command == null || !shortcutConfigurable(command)) {
      return const KeymapUpdate(KeymapUpdateStatus.invalid);
    }
    final candidate = reset ? defaultBinding(command) : binding;
    if (!reset &&
        candidate != null &&
        !shortcutAssignmentAllowed(command, candidate)) {
      return const KeymapUpdate(KeymapUpdateStatus.invalid);
    }
    final effective = effectiveCommandRegistry(defaults, current);
    final candidates = reset
        ? defaults
              .activators(commandId)
              .whereType<SingleActivator>()
              .map(BusyMarkKeyBinding.fromActivator)
        : [if (candidate != null) candidate];
    final conflicts = {
      for (final value in candidates)
        for (final other in effective.conflicts(commandId, value))
          other.id: other,
    }.values.toList(growable: false);
    if (!setEquals(conflicts.map((c) => c.id).toSet(), reassign) &&
        conflicts.isNotEmpty) {
      return KeymapUpdate(KeymapUpdateStatus.conflict, conflicts);
    }
    final next = validatedShortcutOverrides(defaults, current);
    for (final c in conflicts) {
      next[c.id] = null;
    }
    if (reset) {
      next.remove(commandId);
    } else {
      next[commandId] = binding;
    }
    final generation = ++_generation;
    final saved = await settings.saveShortcutOverrides(next);
    if (ref.mounted && generation == _generation) {
      state = saved ? KeymapUpdateStatus.saved : KeymapUpdateStatus.failed;
    }
    return KeymapUpdate(
      saved ? KeymapUpdateStatus.saved : KeymapUpdateStatus.failed,
    );
  }

  Future<bool> resetAll() async {
    final settings = ref.read(appSettingsControllerProvider.notifier);
    await settings.waitUntilLoaded();
    final generation = ++_generation;
    final saved = await settings.saveShortcutOverrides(const {});
    if (ref.mounted && generation == _generation) {
      state = saved ? KeymapUpdateStatus.saved : KeymapUpdateStatus.failed;
    }
    return saved;
  }

  Future<void> retry() async {
    final generation = ++_generation;
    final saved = await ref
        .read(appSettingsControllerProvider.notifier)
        .retryShortcutSave();
    if (ref.mounted && generation == _generation) {
      state = saved ? KeymapUpdateStatus.saved : KeymapUpdateStatus.failed;
    }
  }
}

final keymapControllerProvider =
    NotifierProvider<KeymapController, KeymapUpdateStatus>(
      KeymapController.new,
    );

BusyMarkKeyBinding? defaultBinding(BusyMarkCommand command) =>
    switch (command.shortcut?.activator) {
      final SingleActivator a => BusyMarkKeyBinding.fromActivator(a),
      _ => null,
    };

/// These are local input/traversal operations, not global assignments. Their
/// existing context-specific behavior remains local to each editor/widget.
bool shortcutConfigurable(BusyMarkCommand command) => !const {
  BusyMarkCommandIds.textInsertIndentation,
  BusyMarkCommandIds.textOutdentSource,
  BusyMarkCommandIds.textEscape,
}.contains(command.id);

/// Invalid, unknown or conflicting persisted records are ignored individually.
/// Defaults are never mutated. No unvalidated entry becomes executable.
BusyMarkCommandRegistry effectiveCommandRegistry(
  BusyMarkCommandRegistry defaults,
  Map<String, BusyMarkKeyBinding?> overrides,
) {
  final valid = validatedShortcutOverrides(defaults, overrides);
  final deferred = deferredDefaultConflicts(defaults, valid);
  return valid.isEmpty && deferred.isEmpty
      ? defaults
      : defaults.withOverrides({
          ...valid,
          for (final id in deferred.keys) id: null,
        });
}

/// Newly supplied defaults must not take a previously saved user binding.
/// This is derived runtime state, never an extra persisted override. Settings
/// exposes these conflicts and resolves them through the usual transaction.
Map<String, List<BusyMarkCommand>> deferredDefaultConflicts(
  BusyMarkCommandRegistry defaults,
  Map<String, BusyMarkKeyBinding?> overrides,
) {
  final result = <String, List<BusyMarkCommand>>{};
  for (final command in defaults.commands) {
    final binding = defaultBinding(command);
    if (!command.defaultYieldsToOverrides ||
        overrides.containsKey(command.id) ||
        binding == null) {
      continue;
    }
    final conflicts = <BusyMarkCommand>[];
    for (final entry in overrides.entries) {
      final other = defaults[entry.key];
      if (other != null &&
          entry.value == binding &&
          shortcutAssignmentAllowed(other, binding) &&
          BusyMarkCommandRegistry.contextsOverlap(command, other)) {
        conflicts.add(other);
      }
    }
    if (conflicts.isNotEmpty) result[command.id] = conflicts;
  }
  return result;
}

/// Resolve all assignments together: a later override may free an earlier
/// command's default. Conflicting loaded custom records are rejected together,
/// then checked again against any defaults restored by that rejection.
Map<String, BusyMarkKeyBinding?> validatedShortcutOverrides(
  BusyMarkCommandRegistry defaults,
  Map<String, BusyMarkKeyBinding?> overrides,
) {
  final valid = <String, BusyMarkKeyBinding?>{};
  for (final e in overrides.entries) {
    final command = defaults[e.key];
    if (command != null &&
        shortcutConfigurable(command) &&
        (e.value == null || shortcutAssignmentAllowed(command, e.value!))) {
      valid[e.key] = e.value;
    }
  }
  while (true) {
    final deferred = deferredDefaultConflicts(defaults, valid);
    final bindings = <BusyMarkKeyBinding, List<BusyMarkCommand>>{};
    for (final command in defaults.commands) {
      final effective = valid.containsKey(command.id)
          ? [if (valid[command.id] case final value?) value]
          : [
              if (!deferred.containsKey(command.id))
                for (final a
                    in defaults
                        .activators(command.id)
                        .whereType<SingleActivator>())
                  BusyMarkKeyBinding.fromActivator(a),
            ];
      for (final binding in effective) {
        (bindings[binding] ??= []).add(command);
      }
    }
    final rejected = <String>{};
    for (final commands in bindings.values) {
      for (var i = 0; i < commands.length; i++) {
        for (var j = i + 1; j < commands.length; j++) {
          final a = commands[i], b = commands[j];
          if (a.id == b.id || !BusyMarkCommandRegistry.contextsOverlap(a, b)) {
            continue;
          }
          if (valid[a.id] != null) rejected.add(a.id);
          if (valid[b.id] != null) rejected.add(b.id);
        }
      }
    }
    if (rejected.isEmpty) return valid;
    for (final id in rejected) {
      valid.remove(id);
    }
  }
}

bool shortcutAssignmentAllowed(
  BusyMarkCommand command,
  BusyMarkKeyBinding binding,
) {
  if (BusyMarkKeyBinding.fromJson(binding.toJson()) != binding) return false;
  if (BusyMarkKeyBinding.modifierKeys.contains(binding.key)) return false;
  if (binding == defaultBinding(command)) return true;
  final key = binding.key;
  if (key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.contextMenu ||
      key == LogicalKeyboardKey.f10 &&
          binding.shift &&
          !binding.control &&
          !binding.alt &&
          !binding.meta ||
      binding.control &&
          !binding.alt &&
          !binding.meta &&
          {
            LogicalKeyboardKey.space,
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.arrowLeft,
            LogicalKeyboardKey.arrowRight,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowDown,
          }.contains(key)) {
    return false;
  }
  if (binding.control || binding.alt || binding.meta) return true;
  // Preserve local tree deletion; ordinary typing, traversal and dismissal
  // cannot become application-wide assignments.
  return (command.scope == BusyMarkCommandScope.tree &&
          binding.key == LogicalKeyboardKey.delete) ||
      binding.key.keyId >= LogicalKeyboardKey.f1.keyId &&
          binding.key.keyId <= LogicalKeyboardKey.f24.keyId;
}
