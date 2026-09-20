import 'dart:async';

import 'package:flutter/material.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/command_registry.dart';

@immutable
class BusyMarkEditorTextPasteAvailability {
  const BusyMarkEditorTextPasteAvailability({
    required this.normal,
    required this.plainText,
  });

  static const unavailable = BusyMarkEditorTextPasteAvailability(
    normal: false,
    plainText: false,
  );

  final bool normal;
  final bool plainText;
}

typedef BusyMarkEditorTextPasteAvailabilityReader =
    Future<BusyMarkEditorTextPasteAvailability> Function();

@immutable
class BusyMarkEditorSpellingMenuItem {
  const BusyMarkEditorSpellingMenuItem({
    required this.label,
    required this.onSelected,
    this.enabled = true,
    this.suggestion = false,
  });

  final String label;
  final VoidCallback onSelected;
  final bool enabled;
  final bool suggestion;
}

typedef BusyMarkEditorSpellingMenuReader =
    Future<List<BusyMarkEditorSpellingMenuItem>> Function(int offset);

Widget buildBusyMarkEditorTextContextMenu(
  BuildContext context,
  EditableTextState editableTextState, {
  required String refineWithAiLabel,
  VoidCallback? onRefineWithAi,
  VoidCallback? onCut,
  VoidCallback? onCopy,
  VoidCallback? onPaste,
  VoidCallback? onPastePlainText,
  BusyMarkEditorTextPasteAvailabilityReader? readPasteAvailability,
  VoidCallback? onCopyPlainText,
  List<PopupMenuEntry<VoidCallback>> additionalItems = const [],
  BusyMarkEditorSpellingMenuReader? readSpellingItems,
  VoidCallback? onCheckSpelling,
}) {
  return _BusyMarkEditorTextContextMenu(
    editableTextState: editableTextState,
    refineWithAiLabel: refineWithAiLabel,
    onRefineWithAi: onRefineWithAi,
    onCut: onCut,
    onCopy: onCopy,
    onPaste: onPaste,
    onPastePlainText: onPastePlainText,
    readPasteAvailability: readPasteAvailability,
    onCopyPlainText: onCopyPlainText,
    additionalItems: additionalItems,
    readSpellingItems: readSpellingItems,
    onCheckSpelling: onCheckSpelling,
  );
}

class _BusyMarkEditorTextContextMenu extends StatefulWidget {
  const _BusyMarkEditorTextContextMenu({
    required this.editableTextState,
    required this.refineWithAiLabel,
    required this.onRefineWithAi,
    required this.onCut,
    required this.onCopy,
    required this.onPaste,
    required this.onPastePlainText,
    required this.readPasteAvailability,
    required this.onCopyPlainText,
    required this.additionalItems,
    required this.readSpellingItems,
    required this.onCheckSpelling,
  });

  final EditableTextState editableTextState;
  final String refineWithAiLabel;
  final VoidCallback? onRefineWithAi;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onPastePlainText;
  final BusyMarkEditorTextPasteAvailabilityReader? readPasteAvailability;
  final VoidCallback? onCopyPlainText;
  final List<PopupMenuEntry<VoidCallback>> additionalItems;
  final BusyMarkEditorSpellingMenuReader? readSpellingItems;
  final VoidCallback? onCheckSpelling;

  @override
  State<_BusyMarkEditorTextContextMenu> createState() =>
      _BusyMarkEditorTextContextMenuState();
}

class _BusyMarkEditorTextContextMenuState
    extends State<_BusyMarkEditorTextContextMenu> {
  final _menuSession = BusyMarkMenuSession();
  var _presented = false;
  var _pasteAvailability = BusyMarkEditorTextPasteAvailability.unavailable;
  List<BusyMarkEditorSpellingMenuItem> _spellingItems = const [];
  var _spellingPreparationTimedOut = false;

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
    final selection = widget.editableTextState.textEditingValue.selection;
    final offset = selection.isValid ? selection.extentOffset : 0;
    await Future.wait([_preparePaste(), _prepareSpelling(offset)]);
    if (!mounted) {
      return;
    }
    final action = await showBusyMarkMenu<VoidCallback>(
      context: context,
      anchorPoint: widget.editableTextState.contextMenuAnchors.primaryAnchor,
      items: _menuItems(context),
      session: _menuSession,
      width: widget.onCopyPlainText == null && widget.onPastePlainText == null
          ? BusyMarkSizes.popupMenuMinWidth
          : BusyMarkSizes.editorContextMenuWidth,
    );
    if (!mounted || _menuSession.dismissed) {
      return;
    }
    widget.editableTextState.hideToolbar();
    action?.call();
  }

  Future<void> _preparePaste() async {
    final availabilityReader = widget.readPasteAvailability;
    if (availabilityReader != null) {
      try {
        _pasteAvailability = await availabilityReader();
      } on Object {
        _pasteAvailability = BusyMarkEditorTextPasteAvailability.unavailable;
      }
      return;
    }
    final clipboardStatus = widget.editableTextState.clipboardStatus;
    if (clipboardStatus.value == ClipboardStatus.unknown) {
      await clipboardStatus.update().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
    }
    final textAvailable = clipboardStatus.value == ClipboardStatus.pasteable;
    _pasteAvailability = BusyMarkEditorTextPasteAvailability(
      normal: textAvailable,
      plainText: textAvailable,
    );
  }

  Future<void> _prepareSpelling(int offset) async {
    final reader = widget.readSpellingItems;
    if (reader == null) return;
    try {
      _spellingItems = await reader(offset).timeout(
        const Duration(milliseconds: 350),
        onTimeout: () {
          _spellingPreparationTimedOut = true;
          return const [];
        },
      );
    } on Object {
      _spellingItems = const [];
    }
  }

  List<PopupMenuEntry<VoidCallback>> _menuItems(BuildContext context) {
    final editable = widget.editableTextState;
    final commands =
        BusyMarkCommandRegistryScope.maybeOf(context) ??
        BusyMarkCommandCatalog.metadata;
    final selection = editable.textEditingValue.selection;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final items = <PopupMenuEntry<VoidCallback>>[];
    var addedBusyMarkPaste = false;
    final spellingFallback = widget.onCheckSpelling;

    if (_spellingItems.isNotEmpty) {
      for (final item in _spellingItems) {
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: item.onSelected,
            label: item.label,
            enabled: item.enabled,
          ),
        );
      }
      items.add(const PopupMenuDivider(height: BusyMarkSpacing.sm));
    } else if (_spellingPreparationTimedOut && spellingFallback != null) {
      final command = commands[BusyMarkCommandIds.checkSpelling];
      items.add(
        BusyMarkPopupMenuItem<VoidCallback>(
          value: spellingFallback,
          label: command?.label(context) ?? '',
          shortcut: command?.shortcut?.label,
        ),
      );
      items.add(const PopupMenuDivider(height: BusyMarkSpacing.sm));
    }

    void addBusyMarkPasteItems() {
      if (addedBusyMarkPaste) return;
      addedBusyMarkPaste = true;
      final paste = widget.onPaste;
      if (paste != null && _pasteAvailability.normal) {
        final command = commands[BusyMarkCommandIds.textPaste]!;
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: paste,
            label: command.label(context),
            icon: BusyMarkGlyphs.paste,
            shortcut: command.shortcut?.label,
          ),
        );
      }
      final pastePlainText = widget.onPastePlainText;
      if (pastePlainText != null && _pasteAvailability.plainText) {
        final command = commands[BusyMarkCommandIds.textPastePlainText]!;
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: pastePlainText,
            label: command.label(context),
            icon: BusyMarkGlyphs.paste,
            shortcut: command.shortcut?.label,
          ),
        );
      }
    }

    for (final item in editable.contextMenuButtonItems) {
      if (widget.onPaste != null && item.type == ContextMenuButtonType.paste) {
        addBusyMarkPasteItems();
        continue;
      }
      if (widget.onPaste != null &&
          item.type == ContextMenuButtonType.selectAll) {
        addBusyMarkPasteItems();
      }
      final callback = switch (item.type) {
        ContextMenuButtonType.cut => widget.onCut ?? item.onPressed,
        ContextMenuButtonType.copy => widget.onCopy ?? item.onPressed,
        ContextMenuButtonType.paste => widget.onPaste ?? item.onPressed,
        _ => item.onPressed,
      };
      if (_commandIdFor(item.type) case final commandId?) {
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: callback ?? () {},
            label: commands[commandId]!.label(context),
            icon: _iconFor(item.type),
            shortcut: commands[commandId]!.shortcut?.label,
            enabled: callback != null,
          ),
        );
      } else {
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: callback ?? () {},
            label: AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
            icon: _iconFor(item.type),
            enabled: callback != null,
          ),
        );
      }
      final copyPlainText = widget.onCopyPlainText;
      if (item.type == ContextMenuButtonType.copy &&
          copyPlainText != null &&
          hasSelection) {
        final command = commands[BusyMarkCommandIds.editorCopyPlainText]!;
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: copyPlainText,
            label: command.label(context),
            icon: BusyMarkGlyphs.copy,
            shortcut: command.shortcut?.label,
          ),
        );
      }
    }
    if (widget.onPaste != null) addBusyMarkPasteItems();
    final refineWithAi = widget.onRefineWithAi;
    if (refineWithAi != null && hasSelection) {
      items.add(
        BusyMarkPopupMenuItem<VoidCallback>(
          value: refineWithAi,
          label:
              commands[BusyMarkCommandIds.editorRefineWithAi]?.label(context) ??
              widget.refineWithAiLabel,
          icon: BusyMarkGlyphs.ai,
          shortcut:
              commands[BusyMarkCommandIds.editorRefineWithAi]?.shortcut?.label,
        ),
      );
    }
    items.add(const PopupMenuDivider(height: BusyMarkSpacing.sm));
    for (final entry in [
      (BusyMarkCommandIds.clipboardHistory, BusyMarkGlyphs.copy),
      (BusyMarkCommandIds.localHistory, BusyMarkGlyphs.documentHistory),
    ]) {
      final command = commands[entry.$1];
      if (command != null) {
        items.add(
          BusyMarkPopupMenuItem<VoidCallback>(
            value: () => unawaited(commands.execute(entry.$1)),
            label: command.label(context),
            icon: entry.$2,
            shortcut: command.shortcut?.label,
            enabled: command.enabled(),
          ),
        );
      }
    }
    items.addAll(widget.additionalItems);
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

String? _commandIdFor(ContextMenuButtonType type) {
  return switch (type) {
    ContextMenuButtonType.cut => BusyMarkCommandIds.textCut,
    ContextMenuButtonType.copy => BusyMarkCommandIds.textCopy,
    ContextMenuButtonType.paste => BusyMarkCommandIds.textPaste,
    ContextMenuButtonType.selectAll => BusyMarkCommandIds.textSelectAll,
    ContextMenuButtonType.delete => null,
    ContextMenuButtonType.lookUp ||
    ContextMenuButtonType.searchWeb ||
    ContextMenuButtonType.share ||
    ContextMenuButtonType.liveTextInput ||
    ContextMenuButtonType.custom => null,
  };
}
