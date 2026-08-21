import 'dart:async';

import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/busymark_shortcuts.dart';

Widget buildBusyMarkEditorTextContextMenu(
  BuildContext context,
  EditableTextState editableTextState, {
  required String refineWithAiLabel,
  VoidCallback? onRefineWithAi,
}) {
  return _BusyMarkEditorTextContextMenu(
    editableTextState: editableTextState,
    refineWithAiLabel: refineWithAiLabel,
    onRefineWithAi: onRefineWithAi,
  );
}

class _BusyMarkEditorTextContextMenu extends StatefulWidget {
  const _BusyMarkEditorTextContextMenu({
    required this.editableTextState,
    required this.refineWithAiLabel,
    required this.onRefineWithAi,
  });

  final EditableTextState editableTextState;
  final String refineWithAiLabel;
  final VoidCallback? onRefineWithAi;

  @override
  State<_BusyMarkEditorTextContextMenu> createState() =>
      _BusyMarkEditorTextContextMenuState();
}

class _BusyMarkEditorTextContextMenuState
    extends State<_BusyMarkEditorTextContextMenu> {
  final _menuSession = BusyMarkMenuSession();
  var _presented = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _present());
  }

  @override
  void dispose() {
    unawaited(_menuSession.dismiss());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  Future<void> _present() async {
    if (!mounted || _presented) {
      return;
    }
    _presented = true;
    final clipboardStatus = widget.editableTextState.clipboardStatus;
    if (clipboardStatus.value == ClipboardStatus.unknown) {
      await clipboardStatus.update().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
      if (!mounted) {
        return;
      }
    }
    final action = await showBusyMarkMenu<VoidCallback>(
      context: context,
      anchorPoint: widget.editableTextState.contextMenuAnchors.primaryAnchor,
      items: _menuItems(context),
      session: _menuSession,
      width: BusyMarkSizes.popupMenuMinWidth,
    );
    if (!mounted || _menuSession.dismissed) {
      return;
    }
    widget.editableTextState.hideToolbar();
    action?.call();
  }

  List<PopupMenuEntry<VoidCallback>> _menuItems(BuildContext context) {
    final editable = widget.editableTextState;
    final items = <PopupMenuEntry<VoidCallback>>[
      for (final item in editable.contextMenuButtonItems)
        BusyMarkPopupMenuItem<VoidCallback>(
          value: item.onPressed ?? () {},
          label: AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
          icon: _iconFor(item.type),
          shortcut: _shortcutFor(item.type),
          enabled: item.onPressed != null,
        ),
    ];
    final selection = editable.textEditingValue.selection;
    final refineWithAi = widget.onRefineWithAi;
    if (refineWithAi != null && selection.isValid && !selection.isCollapsed) {
      items.add(
        BusyMarkPopupMenuItem<VoidCallback>(
          value: refineWithAi,
          label: widget.refineWithAiLabel,
          icon: BusyMarkGlyphs.ai,
          shortcut: BusyMarkEditorShortcutLabels.refineWithAi,
        ),
      );
    }
    return items;
  }
}

IconData? _iconFor(ContextMenuButtonType type) {
  return switch (type) {
    ContextMenuButtonType.cut => BusyMarkGlyphs.cut,
    ContextMenuButtonType.copy => BusyMarkGlyphs.copy,
    ContextMenuButtonType.paste => BusyMarkGlyphs.paste,
    ContextMenuButtonType.selectAll => BusyMarkGlyphs.selectAll,
    ContextMenuButtonType.delete => BusyMarkGlyphs.delete,
    ContextMenuButtonType.lookUp ||
    ContextMenuButtonType.searchWeb => BusyMarkGlyphs.search,
    ContextMenuButtonType.share => BusyMarkGlyphs.externalLink,
    ContextMenuButtonType.liveTextInput => BusyMarkGlyphs.text,
    ContextMenuButtonType.custom => null,
  };
}

String? _shortcutFor(ContextMenuButtonType type) {
  return switch (type) {
    ContextMenuButtonType.cut => BusyMarkTextEditingShortcutLabels.cut,
    ContextMenuButtonType.copy => BusyMarkTextEditingShortcutLabels.copy,
    ContextMenuButtonType.paste => BusyMarkTextEditingShortcutLabels.paste,
    ContextMenuButtonType.selectAll =>
      BusyMarkTextEditingShortcutLabels.selectAll,
    ContextMenuButtonType.delete => 'Delete',
    ContextMenuButtonType.lookUp ||
    ContextMenuButtonType.searchWeb ||
    ContextMenuButtonType.share ||
    ContextMenuButtonType.liveTextInput ||
    ContextMenuButtonType.custom => null,
  };
}
