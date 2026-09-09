import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_search_field.dart';
import '../app/localization.dart';
import 'clipboard_history_controller.dart';
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
  final _listFocusNode = FocusNode(debugLabel: 'Clipboard History list');
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
    if (visible.isNotEmpty &&
        !visible.any((entry) => entry.id == _selectedId)) {
      _selectedId = visible.first.id;
    }
    final target = registry.target;
    final canPaste = target != null && target.editable;

    return Focus(
      focusNode: _listFocusNode,
      onKeyEvent: (_, event) => _handleKey(event, visible, canPaste),
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
            child: BusyMarkSearchField(
              controller: _searchController,
              hintText: context.l10n.search,
              onChanged: (_) => setState(() {}),
              onEscape: widget.onEscape,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.md,
              vertical: BusyMarkSpacing.xs,
            ),
            child: Text(
              target == null
                  ? context.l10n.clipboardSessionOnly
                  : context.l10n.clipboardDestination(target.documentName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).refreshIndicatorSemanticLabel,
                  onPressed: state.refreshing
                      ? null
                      : controller.refreshCurrentClipboard,
                  icon: state.refreshing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(BusyMarkGlyphs.refresh),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.clipboardClearAll,
                  onPressed: state.entries.isEmpty ? null : controller.clear,
                  icon: const Icon(BusyMarkGlyphs.clearAll),
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
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final payload = visible[index];
                      final isCurrent = identical(payload, current);
                      return _ClipboardEntryTile(
                        payload: payload,
                        current: isCurrent,
                        selected: payload.id == _selectedId,
                        canPaste: canPaste,
                        onSelect: () {
                          setState(() => _selectedId = payload.id);
                          _listFocusNode.requestFocus();
                        },
                        onPaste: () => _paste(payload, plainText: false),
                        onPastePlain: payload.hasMeaningfulTextRepresentation
                            ? () => _paste(payload, plainText: true)
                            : null,
                        onRemove: isCurrent
                            ? null
                            : () => controller.remove(payload.id),
                      );
                    },
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
    bool canPaste,
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
      setState(() {
        _selectedId =
            visible[(index < 0 ? 0 : index + delta).clamp(
                  0,
                  visible.length - 1,
                )]
                .id;
      });
      return KeyEventResult.handled;
    }
    final selected = index < 0 ? visible.first : visible[index];
    if (event.logicalKey == LogicalKeyboardKey.enter && canPaste) {
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
    }
  }
}

class _ClipboardEntryTile extends StatelessWidget {
  const _ClipboardEntryTile({
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
    final origin = payload.origin;
    final tooltip = origin == null
        ? null
        : '${l10n.clipboardOrigin(origin.documentName)}\n'
              '${origin.documentPath ?? ''}';
    return Semantics(
      selected: selected,
      button: true,
      label: '$kindLabel ${_timestamp(context, payload.acquiredAt)}',
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: canPaste ? onPaste : null,
        child: Container(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          padding: const EdgeInsets.fromLTRB(
            BusyMarkSpacing.md,
            BusyMarkSpacing.sm,
            BusyMarkSpacing.xs,
            BusyMarkSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    payload.kind == BusyMarkClipboardContentKind.image
                        ? BusyMarkGlyphs.image
                        : BusyMarkGlyphs.copy,
                    size: 16,
                  ),
                  const SizedBox(width: BusyMarkSpacing.xs),
                  Expanded(
                    child: Text(
                      current && payload.external
                          ? l10n.clipboardCurrentExternal
                          : current
                          ? l10n.clipboardCurrent
                          : kindLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    _timestamp(context, payload.acquiredAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: BusyMarkSpacing.xs),
              Tooltip(
                message: tooltip ?? '',
                child: _ClipboardPreview(payload, expanded: selected),
              ),
              if (origin != null) ...[
                const SizedBox(height: BusyMarkSpacing.xs),
                Text(
                  l10n.clipboardOrigin(origin.documentName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l10n.paste,
                    onPressed: canPaste ? onPaste : null,
                    icon: const Icon(BusyMarkGlyphs.paste, size: 18),
                  ),
                  if (onPastePlain != null)
                    IconButton(
                      tooltip: l10n.clipboardPastePlainText,
                      onPressed: canPaste ? onPastePlain : null,
                      icon: const Icon(BusyMarkGlyphs.text, size: 18),
                    ),
                  if (onRemove != null)
                    IconButton(
                      tooltip: l10n.removeAction,
                      onPressed: onRemove,
                      icon: const Icon(BusyMarkGlyphs.delete, size: 18),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipboardPreview extends StatefulWidget {
  const _ClipboardPreview(this.payload, {required this.expanded});

  final BusyMarkClipboardPayload payload;
  final bool expanded;

  @override
  State<_ClipboardPreview> createState() => _ClipboardPreviewState();
}

class _ClipboardPreviewState extends State<_ClipboardPreview> {
  ImageProvider<Object>? _image;

  @override
  void didUpdateWidget(covariant _ClipboardPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload.id != widget.payload.id) {
      _image?.evict();
      _image = null;
    }
  }

  @override
  void dispose() {
    _image?.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    final bytes = payload.imageBytes;
    if (bytes != null && widget.expanded) {
      final image = _image ??= ResizeImage.resizeIfNeeded(
        512,
        512,
        MemoryImage(bytes),
      );
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 128),
        child: Image(
          // At most one selected preview is decoded, and both dimensions are
          // bounded. RGBA decoding therefore stays well below the policy's
          // separate 8 MiB thumbnail-cache budget.
          image: image,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) {
            return const Center(child: Icon(BusyMarkGlyphs.imageMissing));
          },
        ),
      );
    }
    if (bytes != null) {
      final prior = _image;
      _image = null;
      if (prior != null) unawaited(prior.evict());
      return Text(
        payload.imageDisplayName ?? context.l10n.clipboardEntryImage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      payload.preferredSourceText ?? payload.text ?? '',
      maxLines: widget.expanded ? 6 : 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
    );
  }
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
