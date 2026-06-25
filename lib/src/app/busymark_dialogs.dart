import 'dart:async';

import 'package:flutter/material.dart';

import '../platform/linux_header_bar_service.dart';
import 'busymark_design.dart';

Color busyMarkModalBarrierColor(BuildContext context) {
  return Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32);
}

Future<T?> showBusyMarkModalDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  LinuxHeaderBarService? headerBarService,
}) async {
  final barrierColor = busyMarkModalBarrierColor(context);
  await headerBarService?.setModalBarrierVisible(true);
  if (!context.mounted) {
    await headerBarService?.setModalBarrierVisible(false);
    return null;
  }
  try {
    return await showDialog<T>(
      context: context,
      barrierColor: barrierColor,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: BusyMarkModalEditorSurface(child: builder(dialogContext)),
      ),
    );
  } finally {
    await headerBarService?.setModalBarrierVisible(false);
  }
}

class BusyMarkModalEditorSurface extends StatelessWidget {
  const BusyMarkModalEditorSurface({
    super.key,
    required this.child,
    this.maxWidth = 860,
    this.maxHeight,
  });

  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Material(
        color: colors.dialog,
        elevation: BusyMarkElevation.popover,
        shadowColor: BusyMarkShadow.floatingColor(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

void showBusyMarkAboutDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => const _BusyMarkInfoDialog(
        title: 'BusyMark',
        subtitle: 'Version 0.1.0',
        children: [
          Text(
            'BusyMark is an open-source application for reading, editing, and exporting Markdown files and Writerside-compatible projects.',
          ),
        ],
      ),
    ),
  );
}

void showBusyMarkKeyboardShortcutsDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => const _BusyMarkInfoDialog(
        title: 'Keyboard Shortcuts',
        maxWidth: 480,
        children: [
          BusyMarkGroupedList(
            title: 'File',
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'New document',
                subtitle: 'Create a new unsaved Markdown document',
                leading: Icon(Icons.note_add_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+N'),
              ),
              BusyMarkActionRow(
                title: 'Open',
                subtitle:
                    'Choose a Markdown file, folder, or Writerside project',
                leading: Icon(Icons.folder_open_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+O'),
              ),
              BusyMarkActionRow(
                title: 'Save',
                subtitle: 'Save the current Markdown file',
                leading: Icon(Icons.save_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+S'),
              ),
              BusyMarkActionRow(
                title: 'Print',
                subtitle: 'Open the active preview in the system print flow',
                leading: Icon(Icons.print_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+P'),
              ),
              BusyMarkActionRow(
                title: 'Find',
                subtitle: 'Open workspace search',
                leading: Icon(Icons.search),
                trailing: _KeyboardShortcutBadge('Ctrl+F'),
              ),
              BusyMarkActionRow(
                title: 'Keyboard shortcuts',
                subtitle: 'Show this popup',
                leading: Icon(Icons.keyboard_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+/'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: 'Text editing',
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'Select all',
                subtitle: 'Select all text in the active field',
                leading: Icon(Icons.select_all),
                trailing: _KeyboardShortcutBadge('Ctrl+A'),
              ),
              BusyMarkActionRow(
                title: 'Cut',
                subtitle: 'Cut selected text',
                leading: Icon(Icons.content_cut),
                trailing: _KeyboardShortcutBadge('Ctrl+X'),
              ),
              BusyMarkActionRow(
                title: 'Copy',
                subtitle: 'Copy selected text or selected editor blocks',
                leading: Icon(Icons.content_copy),
                trailing: _KeyboardShortcutBadge('Ctrl+C'),
              ),
              BusyMarkActionRow(
                title: 'Paste',
                subtitle: 'Paste from clipboard',
                leading: Icon(Icons.content_paste),
                trailing: _KeyboardShortcutBadge('Ctrl+V'),
              ),
              BusyMarkActionRow(
                title: 'Paste without formatting',
                subtitle: 'Paste clipboard text as plain text',
                leading: Icon(Icons.content_paste_go_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+V'),
              ),
              BusyMarkActionRow(
                title: 'Undo',
                subtitle: 'Undo the last edit',
                leading: Icon(Icons.undo),
                trailing: _KeyboardShortcutBadge('Ctrl+Z'),
              ),
              BusyMarkActionRow(
                title: 'Redo',
                subtitle: 'Redo the last undone edit',
                leading: Icon(Icons.redo),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+Z'),
              ),
              BusyMarkActionRow(
                title: 'Clear editor selection',
                subtitle: 'Clear multi-block selection in Editor view',
                leading: Icon(Icons.clear),
                trailing: _KeyboardShortcutBadge('Esc'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: 'Formatting',
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'Bold',
                subtitle: 'Apply bold formatting',
                leading: Icon(Icons.format_bold),
                trailing: _KeyboardShortcutBadge('Ctrl+B'),
              ),
              BusyMarkActionRow(
                title: 'Italic',
                subtitle: 'Apply italic formatting',
                leading: Icon(Icons.format_italic),
                trailing: _KeyboardShortcutBadge('Ctrl+I'),
              ),
              BusyMarkActionRow(
                title: 'Underline',
                subtitle: 'Apply underline formatting',
                leading: Icon(Icons.format_underlined),
                trailing: _KeyboardShortcutBadge('Ctrl+U'),
              ),
              BusyMarkActionRow(
                title: 'Link',
                subtitle: 'Create or edit a link',
                leading: Icon(Icons.link),
                trailing: _KeyboardShortcutBadge('Ctrl+K'),
              ),
              BusyMarkActionRow(
                title: 'Inline code',
                subtitle: 'Apply inline code formatting',
                leading: Icon(Icons.code_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+E'),
              ),
              BusyMarkActionRow(
                title: 'Strikethrough',
                subtitle: 'Apply strikethrough formatting',
                leading: Icon(Icons.format_strikethrough),
                trailing: _KeyboardShortcutBadge('Alt+Shift+5'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: 'Blocks',
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'Paragraph',
                subtitle: 'Apply paragraph style',
                leading: Icon(Icons.notes_outlined),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+0'),
              ),
              BusyMarkActionRow(
                title: 'Heading 1',
                subtitle: 'Apply level 1 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+1'),
              ),
              BusyMarkActionRow(
                title: 'Heading 2',
                subtitle: 'Apply level 2 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+2'),
              ),
              BusyMarkActionRow(
                title: 'Heading 3',
                subtitle: 'Apply level 3 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+3'),
              ),
              BusyMarkActionRow(
                title: 'Heading 4',
                subtitle: 'Apply level 4 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+4'),
              ),
              BusyMarkActionRow(
                title: 'Heading 5',
                subtitle: 'Apply level 5 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+5'),
              ),
              BusyMarkActionRow(
                title: 'Heading 6',
                subtitle: 'Apply level 6 heading style',
                leading: Icon(Icons.title),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+6'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: 'Lists',
            filled: true,
            children: [
              BusyMarkActionRow(
                title: 'Numbered list',
                subtitle: 'Apply ordered list formatting',
                leading: Icon(Icons.format_list_numbered),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+7'),
              ),
              BusyMarkActionRow(
                title: 'Bulleted list',
                subtitle: 'Apply bulleted list formatting',
                leading: Icon(Icons.format_list_bulleted),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+8'),
              ),
              BusyMarkActionRow(
                title: 'Checklist',
                subtitle: 'Apply task list formatting',
                leading: Icon(Icons.checklist),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+9'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BusyMarkInfoDialog extends StatelessWidget {
  const _BusyMarkInfoDialog({
    required this.title,
    required this.children,
    this.subtitle,
    this.maxWidth = 420,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return BusyMarkDialogShell(
      title: title,
      maxWidth: maxWidth,
      children: [
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: BusyMarkSpacing.md),
        ],
        ...children,
      ],
    );
  }
}

class _KeyboardShortcutBadge extends StatelessWidget {
  const _KeyboardShortcutBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.control,
        borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
        border: Border.all(color: colors.subtleBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontFamily: 'Ubuntu Mono',
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
