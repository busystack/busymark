import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_search_field.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import 'clipboard_history_controller.dart';
import 'clipboard_insertion.dart';
import 'clipboard_models.dart';

class ClipboardHistoryPanel extends ConsumerStatefulWidget {
  const ClipboardHistoryPanel({this.onEscape, super.key});

  final VoidCallback? onEscape;

  @override
  ConsumerState<ClipboardHistoryPanel> createState() =>
      _ClipboardHistoryPanelState();
}

class _ClipboardHistoryPanelState extends ConsumerState<ClipboardHistoryPanel> {
  final _searchController = TextEditingController();
  final _listScrollController = ScrollController();
  final _listFocusNode = FocusNode(debugLabel: 'Clipboard History list');
  final _entryKeys = <String, GlobalKey>{};
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref
              .read(clipboardHistoryControllerProvider.notifier)
              .refreshCurrentClipboard(),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clipboardHistoryControllerProvider);
    final controller = ref.read(clipboardHistoryControllerProvider.notifier);
    final registry = ref.watch(clipboardInsertionRegistryProvider);
    final query = _searchController.text.toLowerCase();
    final current = state.currentClipboard;
    final visible = <BusyMarkClipboardPayload>[
      if (current != null && _matches(current, query)) current,
      for (final entry in state.entries)
        if ((current == null || !current.equivalentTo(entry)) &&
            _matches(entry, query))
          entry,
    ];
    if (_selectedId != null &&
        !visible.any((entry) => entry.id == _selectedId)) {
      _selectedId = null;
    }
    final visibleIds = visible.map((entry) => entry.id).toSet();
    _entryKeys.removeWhere((id, _) => !visibleIds.contains(id));
    return Focus(
      focusNode: _listFocusNode,
      onKeyEvent: (_, event) => _handleKey(event, visible, registry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BusyMarkSpacing.md,
              BusyMarkSpacing.sm,
              BusyMarkSpacing.md,
              BusyMarkSpacing.sm,
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Expanded(
                  child: BusyMarkSearchField(
                    controller: _searchController,
                    hintText: context.l10n.search,
                    onChanged: (_) => setState(() {}),
                    onEscape: widget.onEscape,
                  ),
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                BusyMarkHeaderPopupMenuButton<_ClipboardHistoryAction>(
                  key: const ValueKey('clipboard-history-actions-menu'),
                  tooltip: context.l10n.actions,
                  icon: BusyMarkGlyphs.menuVertical,
                  transparent: true,
                  borderRadius: BusyMarkRadius.nativeHeaderButton,
                  highlightWhenOpen: false,
                  itemBuilder: (context) => [
                    BusyMarkPopupMenuItem(
                      value: _ClipboardHistoryAction.refresh,
                      label: MaterialLocalizations.of(
                        context,
                      ).refreshIndicatorSemanticLabel,
                      icon: BusyMarkGlyphs.refresh,
                      enabled: !state.refreshing,
                    ),
                    const PopupMenuDivider(height: BusyMarkSpacing.sm),
                    BusyMarkPopupMenuItem(
                      value: _ClipboardHistoryAction.clear,
                      label: context.l10n.clipboardClearAll,
                      icon: BusyMarkGlyphs.clearAll,
                      enabled: state.entries.isNotEmpty,
                    ),
                  ],
                  onSelected: (action) {
                    switch (action) {
                      case _ClipboardHistoryAction.refresh:
                        unawaited(controller.refreshCurrentClipboard());
                      case _ClipboardHistoryAction.clear:
                        controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          if (!controller.collectionEnabled)
            _PanelNotice(
              icon: BusyMarkGlyphs.info,
              text: context.l10n.clipboardDisabled,
            )
          else if (state.lastRetentionResult ==
              ClipboardRetentionResult.oversized)
            _PanelNotice(
              icon: BusyMarkGlyphs.warning,
              text: context.l10n.clipboardTooLarge,
            ),
          Expanded(
            child: visible.isEmpty
                ? _PanelEmpty(
                    text: query.isNotEmpty
                        ? context.l10n.clipboardNoMatches
                        : state.clipboardAvailable
                        ? context.l10n.clipboardNoItems
                        : context.l10n.clipboardUnavailable,
                  )
                : ListView(
                    key: const ValueKey('clipboard-history-list'),
                    controller: _listScrollController,
                    padding: BusyMarkInsets.sidebarList,
                    children: [
                      for (final payload in visible)
                        _ClipboardEntryTile(
                          key: _entryKeys.putIfAbsent(
                            payload.id,
                            () => GlobalKey(
                              debugLabel: 'Clipboard entry ${payload.id}',
                            ),
                          ),
                          payload: payload,
                          current: identical(payload, current),
                          selected: payload.id == _selectedId,
                          canPaste: registry.canPaste(payload),
                          onSelect: () {
                            setState(() => _selectedId = payload.id);
                            _listFocusNode.requestFocus();
                          },
                          onPaste: () => _paste(payload, plainText: false),
                          onPastePlain:
                              payload.hasMeaningfulTextRepresentation &&
                                  registry.canPaste(payload, plainText: true)
                              ? () => _paste(payload, plainText: true)
                              : null,
                          onRemove: identical(payload, current)
                              ? null
                              : () => controller.remove(payload.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _matches(BusyMarkClipboardPayload payload, String query) {
    if (query.isEmpty) return true;
    return [
      payload.text,
      payload.sourceText,
      payload.imageDisplayName,
      payload.origin?.documentName,
      payload.origin?.documentPath,
    ].whereType<String>().any((value) => value.toLowerCase().contains(query));
  }

  KeyEventResult _handleKey(
    KeyEvent event,
    List<BusyMarkClipboardPayload> visible,
    BusyMarkClipboardInsertionRegistry registry,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onEscape?.call();
      return KeyEventResult.handled;
    }
    if (visible.isEmpty) return KeyEventResult.ignored;
    final index = visible.indexWhere((entry) => entry.id == _selectedId);
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final delta = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
      final nextIndex = (index < 0 ? 0 : index + delta).clamp(
        0,
        visible.length - 1,
      );
      final nextId = visible[nextIndex].id;
      setState(() {
        _selectedId = nextId;
      });
      _ensureSelectionVisible(nextId);
      return KeyEventResult.handled;
    }
    final selected = index < 0 ? visible.first : visible[index];
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        registry.canPaste(selected)) {
      unawaited(_paste(selected, plainText: false));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete &&
        ref
            .read(clipboardHistoryControllerProvider)
            .entries
            .any((entry) => entry.id == selected.id)) {
      ref.read(clipboardHistoryControllerProvider.notifier).remove(selected.id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _ensureSelectionVisible(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entryContext = _entryKeys[id]?.currentContext;
      if (!mounted || entryContext == null || !entryContext.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          entryContext,
          duration: const Duration(milliseconds: 120),
          alignment: 0,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        ),
      );
    });
  }

  Future<void> _paste(
    BusyMarkClipboardPayload payload, {
    required bool plainText,
  }) async {
    final result = await ref
        .read(clipboardInsertionRegistryProvider)
        .paste(payload, plainText: plainText);
    if (result == ClipboardPasteResult.inserted && payload.external) {
      ref
          .read(clipboardHistoryControllerProvider.notifier)
          .retainCurrentAfterPaste(payload);
    } else if (result != ClipboardPasteResult.inserted && mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.clipboardUnavailable,
        priority: BusyMarkToastPriority.high,
      );
    }
  }
}

enum _ClipboardHistoryAction { refresh, clear }

enum _ClipboardEntryAction { paste, pastePlain, remove }

class _ClipboardEntryTile extends StatelessWidget {
  const _ClipboardEntryTile({
    super.key,
    required this.payload,
    required this.current,
    required this.selected,
    required this.canPaste,
    required this.onSelect,
    required this.onPaste,
    required this.onPastePlain,
    required this.onRemove,
  });

  final BusyMarkClipboardPayload payload;
  final bool current;
  final bool selected;
  final bool canPaste;
  final VoidCallback onSelect;
  final VoidCallback onPaste;
  final VoidCallback? onPastePlain;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kindLabel = switch (payload.kind) {
      BusyMarkClipboardContentKind.text => l10n.clipboardEntryText,
      BusyMarkClipboardContentKind.richText => l10n.clipboardEntryRichText,
      BusyMarkClipboardContentKind.image => l10n.clipboardEntryImage,
    };
    final status = current && payload.external
        ? l10n.clipboardCurrentExternal
        : current
        ? l10n.clipboardCurrent
        : kindLabel;
    final preview = _clipboardEntryPreview(payload, kindLabel);
    final metadata = '$status · ${_timestamp(context, payload.acquiredAt)}';
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkSidebarRecordRow<_ClipboardEntryAction>(
      icon: payload.kind == BusyMarkClipboardContentKind.image
          ? BusyMarkGlyphs.image
          : BusyMarkGlyphs.copy,
      content: Text(
        preview,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.foreground),
      ),
      selected: selected,
      semanticsLabel: '$preview\n$metadata',
      tooltip: _clipboardEntryTooltip(payload, l10n, metadata),
      onTap: onSelect,
      onDoubleTap: canPaste ? onPaste : null,
      menuTooltip: l10n.actions,
      menuItemsBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: _ClipboardEntryAction.paste,
          label: context.l10n.paste,
          icon: BusyMarkGlyphs.paste,
          enabled: canPaste,
        ),
        if (onPastePlain != null)
          BusyMarkPopupMenuItem(
            value: _ClipboardEntryAction.pastePlain,
            label: context.l10n.clipboardPastePlainText,
            icon: BusyMarkGlyphs.text,
          ),
        if (onRemove != null) ...[
          const PopupMenuDivider(height: BusyMarkSpacing.sm),
          BusyMarkPopupMenuItem(
            value: _ClipboardEntryAction.remove,
            label: context.l10n.removeAction,
            icon: BusyMarkGlyphs.delete,
          ),
        ],
      ],
      onMenuOpening: onSelect,
      onMenuSelected: (action) {
        switch (action) {
          case _ClipboardEntryAction.paste:
            onPaste();
          case _ClipboardEntryAction.pastePlain:
            onPastePlain?.call();
          case _ClipboardEntryAction.remove:
            onRemove?.call();
        }
      },
    );
  }
}

String _clipboardEntryPreview(
  BusyMarkClipboardPayload payload,
  String fallback,
) {
  final value =
      payload.imageDisplayName ??
      payload.preferredSourceText ??
      payload.text ??
      fallback;
  final preview = value.trim();
  return preview.isEmpty ? fallback : preview;
}

String _clipboardEntryTooltip(
  BusyMarkClipboardPayload payload,
  AppLocalizations l10n,
  String metadata,
) {
  final origin = payload.origin;
  final originPath = origin?.documentPath;
  final parts = <String>[
    metadata,
    if (origin != null) l10n.clipboardOrigin(origin.documentName),
    if (originPath != null && originPath.trim().isNotEmpty) originPath.trim(),
  ];
  return parts.join('\n');
}

class _PanelNotice extends StatelessWidget {
  const _PanelNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BusyMarkSpacing.md),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: BusyMarkSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(BusyMarkSpacing.lg),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}

String _timestamp(BuildContext context, DateTime timestamp) {
  final local = timestamp.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
