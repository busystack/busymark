import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/linux_header_bar_service.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';

const _busyMarkRepositoryUrl = 'https://github.com/busystack/busymark';
final _busyMarkRepositoryUri = Uri.parse(_busyMarkRepositoryUrl);

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
      builder: (context) => _BusyMarkInfoDialog(
        title: 'BusyMark',
        subtitle: 'Version 0.1.1',
        children: [
          const Text(
            'BusyMark is an open-source application for reading and editing Markdown files and Writerside-compatible projects.',
          ),
          const SizedBox(height: BusyMarkSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => unawaited(_openBusyMarkRepository()),
              icon: const Icon(BusyMarkGlyphs.externalLink),
              label: const Text(_busyMarkRepositoryUrl),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _openBusyMarkRepository() async {
  await launchUrl(_busyMarkRepositoryUri, mode: LaunchMode.externalApplication);
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
                leading: Icon(BusyMarkGlyphs.newDocument),
                trailing: _KeyboardShortcutBadge('Ctrl+N'),
              ),
              BusyMarkActionRow(
                title: 'Open',
                subtitle:
                    'Choose a Markdown file, folder, or Writerside project',
                leading: Icon(BusyMarkGlyphs.folderOpen),
                trailing: _KeyboardShortcutBadge('Ctrl+O'),
              ),
              BusyMarkActionRow(
                title: 'Save',
                subtitle: 'Save the current Markdown file',
                leading: Icon(BusyMarkGlyphs.save),
                trailing: _KeyboardShortcutBadge('Ctrl+S'),
              ),
              BusyMarkActionRow(
                title: 'Find',
                subtitle: 'Open workspace search',
                leading: Icon(BusyMarkGlyphs.search),
                trailing: _KeyboardShortcutBadge('Ctrl+F'),
              ),
              BusyMarkActionRow(
                title: 'Keyboard shortcuts',
                subtitle: 'Show this popup',
                leading: Icon(BusyMarkGlyphs.keyboard),
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
                leading: Icon(BusyMarkGlyphs.selectAll),
                trailing: _KeyboardShortcutBadge('Ctrl+A'),
              ),
              BusyMarkActionRow(
                title: 'Cut',
                subtitle: 'Cut selected text',
                leading: Icon(BusyMarkGlyphs.cut),
                trailing: _KeyboardShortcutBadge('Ctrl+X'),
              ),
              BusyMarkActionRow(
                title: 'Copy',
                subtitle: 'Copy selected text or selected editor blocks',
                leading: Icon(BusyMarkGlyphs.copy),
                trailing: _KeyboardShortcutBadge('Ctrl+C'),
              ),
              BusyMarkActionRow(
                title: 'Paste',
                subtitle: 'Paste from clipboard',
                leading: Icon(BusyMarkGlyphs.paste),
                trailing: _KeyboardShortcutBadge('Ctrl+V'),
              ),
              BusyMarkActionRow(
                title: 'Paste without formatting',
                subtitle: 'Paste clipboard text as plain text',
                leading: Icon(BusyMarkGlyphs.paste),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+V'),
              ),
              BusyMarkActionRow(
                title: 'Undo',
                subtitle: 'Undo the last edit',
                leading: Icon(BusyMarkGlyphs.undo),
                trailing: _KeyboardShortcutBadge('Ctrl+Z'),
              ),
              BusyMarkActionRow(
                title: 'Redo',
                subtitle: 'Redo the last undone edit',
                leading: Icon(BusyMarkGlyphs.redo),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+Z'),
              ),
              BusyMarkActionRow(
                title: 'Clear editor selection',
                subtitle: 'Clear multi-block selection in Editor view',
                leading: Icon(BusyMarkGlyphs.clear),
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
                leading: Icon(BusyMarkGlyphs.bold),
                trailing: _KeyboardShortcutBadge('Ctrl+B'),
              ),
              BusyMarkActionRow(
                title: 'Italic',
                subtitle: 'Apply italic formatting',
                leading: Icon(BusyMarkGlyphs.italic),
                trailing: _KeyboardShortcutBadge('Ctrl+I'),
              ),
              BusyMarkActionRow(
                title: 'Underline',
                subtitle: 'Apply underline formatting',
                leading: Icon(BusyMarkGlyphs.underline),
                trailing: _KeyboardShortcutBadge('Ctrl+U'),
              ),
              BusyMarkActionRow(
                title: 'Link',
                subtitle: 'Create or edit a link',
                leading: Icon(BusyMarkGlyphs.link),
                trailing: _KeyboardShortcutBadge('Ctrl+K'),
              ),
              BusyMarkActionRow(
                title: 'Inline code',
                subtitle: 'Apply inline code formatting',
                leading: Icon(BusyMarkGlyphs.code),
                trailing: _KeyboardShortcutBadge('Ctrl+E'),
              ),
              BusyMarkActionRow(
                title: 'Strikethrough',
                subtitle: 'Apply strikethrough formatting',
                leading: Icon(BusyMarkGlyphs.strikethrough),
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
                leading: Icon(BusyMarkGlyphs.paragraph),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+0'),
              ),
              BusyMarkActionRow(
                title: 'Heading 1',
                subtitle: 'Apply level 1 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+1'),
              ),
              BusyMarkActionRow(
                title: 'Heading 2',
                subtitle: 'Apply level 2 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+2'),
              ),
              BusyMarkActionRow(
                title: 'Heading 3',
                subtitle: 'Apply level 3 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+3'),
              ),
              BusyMarkActionRow(
                title: 'Heading 4',
                subtitle: 'Apply level 4 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+4'),
              ),
              BusyMarkActionRow(
                title: 'Heading 5',
                subtitle: 'Apply level 5 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+5'),
              ),
              BusyMarkActionRow(
                title: 'Heading 6',
                subtitle: 'Apply level 6 heading style',
                leading: Icon(BusyMarkGlyphs.heading),
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
                leading: Icon(BusyMarkGlyphs.orderedList),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+7'),
              ),
              BusyMarkActionRow(
                title: 'Bulleted list',
                subtitle: 'Apply bulleted list formatting',
                leading: Icon(BusyMarkGlyphs.unorderedList),
                trailing: _KeyboardShortcutBadge('Ctrl+Shift+8'),
              ),
              BusyMarkActionRow(
                title: 'Checklist',
                subtitle: 'Apply task list formatting',
                leading: Icon(BusyMarkGlyphs.checklist),
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
