import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/linux_header_bar_service.dart';
import 'app_metadata.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'localization.dart';

const _busyMarkRepositoryUrl = 'https://github.com/busystack/busymark';
const _busyMarkIssueUrl = 'https://github.com/busystack/busymark/issues';
const _apacheLicenseUrl = 'https://www.apache.org/licenses/LICENSE-2.0';
const _busyMarkLogoAsset = 'assets/branding/busymark_logo.svg';
final _busyMarkRepositoryUri = Uri.parse(_busyMarkRepositoryUrl);
final _busyMarkIssueUri = Uri.parse(_busyMarkIssueUrl);
final _apacheLicenseUri = Uri.parse(_apacheLicenseUrl);

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
      builder: (dialogContext) {
        final viewInsets = MediaQuery.viewInsetsOf(dialogContext);
        final padding = EdgeInsets.fromLTRB(
          viewInsets.left + 40,
          viewInsets.top + 24,
          viewInsets.right + 40,
          viewInsets.bottom + 24,
        );
        return AnimatedPadding(
          padding: padding,
          duration: const Duration(milliseconds: 100),
          curve: Curves.decelerate,
          child: Center(
            child: BusyMarkModalEditorSurface(child: builder(dialogContext)),
          ),
        );
      },
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
          side: BorderSide.none,
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
      builder: (context) => const _BusyMarkAboutDialog(),
    ),
  );
}

Future<void> _openBusyMarkRepository() async {
  await launchUrl(_busyMarkRepositoryUri, mode: LaunchMode.externalApplication);
}

Future<void> _openBusyMarkIssues() async {
  await launchUrl(_busyMarkIssueUri, mode: LaunchMode.externalApplication);
}

Future<void> _openApacheLicense() async {
  await launchUrl(_apacheLicenseUri, mode: LaunchMode.externalApplication);
}

void showBusyMarkKeyboardShortcutsDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => _BusyMarkInfoDialog(
        title: context.l10n.keyboardShortcuts,
        maxWidth: 480,
        children: [
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupFile,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.shortcutNewDocument,
                subtitle: context.l10n.shortcutNewDocumentDescription,
                leading: const Icon(BusyMarkGlyphs.newDocument),
                trailing: const _KeyboardShortcutBadge('Ctrl+N'),
              ),
              BusyMarkActionRow(
                title: context.l10n.open,
                subtitle: context.l10n.shortcutOpenDescription,
                leading: const Icon(BusyMarkGlyphs.folderOpen),
                trailing: const _KeyboardShortcutBadge('Ctrl+O'),
              ),
              BusyMarkActionRow(
                title: context.l10n.save,
                subtitle: context.l10n.shortcutSaveDescription,
                leading: const Icon(BusyMarkGlyphs.save),
                trailing: const _KeyboardShortcutBadge('Ctrl+S'),
              ),
              BusyMarkActionRow(
                title: context.l10n.find,
                subtitle: context.l10n.shortcutFindDescription,
                leading: const Icon(BusyMarkGlyphs.search),
                trailing: const _KeyboardShortcutBadge('Ctrl+F'),
              ),
              BusyMarkActionRow(
                title: context.l10n.keyboardShortcuts,
                subtitle: context.l10n.shortcutKeyboardShortcutsDescription,
                leading: const Icon(BusyMarkGlyphs.keyboard),
                trailing: const _KeyboardShortcutBadge('Ctrl+/'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupTextEditing,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.selectAll,
                subtitle: context.l10n.shortcutSelectAllDescription,
                leading: const Icon(BusyMarkGlyphs.selectAll),
                trailing: const _KeyboardShortcutBadge('Ctrl+A'),
              ),
              BusyMarkActionRow(
                title: context.l10n.cut,
                subtitle: context.l10n.shortcutCutDescription,
                leading: const Icon(BusyMarkGlyphs.cut),
                trailing: const _KeyboardShortcutBadge('Ctrl+X'),
              ),
              BusyMarkActionRow(
                title: context.l10n.copy,
                subtitle: context.l10n.shortcutCopyDescription,
                leading: const Icon(BusyMarkGlyphs.copy),
                trailing: const _KeyboardShortcutBadge('Ctrl+C'),
              ),
              BusyMarkActionRow(
                title: context.l10n.paste,
                subtitle: context.l10n.shortcutPasteDescription,
                leading: const Icon(BusyMarkGlyphs.paste),
                trailing: const _KeyboardShortcutBadge('Ctrl+V'),
              ),
              BusyMarkActionRow(
                title: context.l10n.pasteWithoutFormatting,
                subtitle: context.l10n.shortcutPastePlainTextDescription,
                leading: const Icon(BusyMarkGlyphs.paste),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+V'),
              ),
              BusyMarkActionRow(
                title: context.l10n.undo,
                subtitle: context.l10n.shortcutUndoDescription,
                leading: const Icon(BusyMarkGlyphs.undo),
                trailing: const _KeyboardShortcutBadge('Ctrl+Z'),
              ),
              BusyMarkActionRow(
                title: context.l10n.redo,
                subtitle: context.l10n.shortcutRedoDescription,
                leading: const Icon(BusyMarkGlyphs.redo),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+Z'),
              ),
              BusyMarkActionRow(
                title: context.l10n.clearEditorSelection,
                subtitle: context.l10n.shortcutClearEditorSelectionDescription,
                leading: const Icon(BusyMarkGlyphs.clear),
                trailing: const _KeyboardShortcutBadge('Esc'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupFormatting,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.bold,
                subtitle: context.l10n.shortcutBoldDescription,
                leading: const Icon(BusyMarkGlyphs.bold),
                trailing: const _KeyboardShortcutBadge('Ctrl+B'),
              ),
              BusyMarkActionRow(
                title: context.l10n.italic,
                subtitle: context.l10n.shortcutItalicDescription,
                leading: const Icon(BusyMarkGlyphs.italic),
                trailing: const _KeyboardShortcutBadge('Ctrl+I'),
              ),
              BusyMarkActionRow(
                title: context.l10n.underline,
                subtitle: context.l10n.shortcutUnderlineDescription,
                leading: const Icon(BusyMarkGlyphs.underline),
                trailing: const _KeyboardShortcutBadge('Ctrl+U'),
              ),
              BusyMarkActionRow(
                title: context.l10n.link,
                subtitle: context.l10n.shortcutLinkDescription,
                leading: const Icon(BusyMarkGlyphs.link),
                trailing: const _KeyboardShortcutBadge('Ctrl+K'),
              ),
              BusyMarkActionRow(
                title: context.l10n.inlineCode,
                subtitle: context.l10n.shortcutInlineCodeDescription,
                leading: const Icon(BusyMarkGlyphs.code),
                trailing: const _KeyboardShortcutBadge('Ctrl+E'),
              ),
              BusyMarkActionRow(
                title: context.l10n.strikethrough,
                subtitle: context.l10n.shortcutStrikethroughDescription,
                leading: const Icon(BusyMarkGlyphs.strikethrough),
                trailing: const _KeyboardShortcutBadge('Alt+Shift+5'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupBlocks,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.paragraph,
                subtitle: context.l10n.shortcutParagraphDescription,
                leading: const Icon(BusyMarkGlyphs.paragraph),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+0'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading1,
                subtitle: context.l10n.shortcutHeading1Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+1'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading2,
                subtitle: context.l10n.shortcutHeading2Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+2'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading3,
                subtitle: context.l10n.shortcutHeading3Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+3'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading4,
                subtitle: context.l10n.shortcutHeading4Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+4'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading5,
                subtitle: context.l10n.shortcutHeading5Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+5'),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading6,
                subtitle: context.l10n.shortcutHeading6Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+6'),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupLists,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.numberedList,
                subtitle: context.l10n.shortcutNumberedListDescription,
                leading: const Icon(BusyMarkGlyphs.orderedList),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+7'),
              ),
              BusyMarkActionRow(
                title: context.l10n.bulletedList,
                subtitle: context.l10n.shortcutBulletedListDescription,
                leading: const Icon(BusyMarkGlyphs.unorderedList),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+8'),
              ),
              BusyMarkActionRow(
                title: context.l10n.checklist,
                subtitle: context.l10n.shortcutChecklistDescription,
                leading: const Icon(BusyMarkGlyphs.checklist),
                trailing: const _KeyboardShortcutBadge('Ctrl+Shift+9'),
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
    this.maxWidth = 420,
  });

  final String title;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return BusyMarkDialogShell(
      title: title,
      maxWidth: maxWidth,
      children: children,
    );
  }
}

class _BusyMarkAboutDialog extends StatelessWidget {
  const _BusyMarkAboutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return BusyMarkDialogShell(
      title: context.l10n.aboutBusyMark,
      maxWidth: 460,
      children: [
        _BusyMarkAboutLogo(label: context.l10n.appTitle),
        const SizedBox(height: BusyMarkSpacing.xs),
        Text(
          context.l10n.appTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.xs),
        Text(
          context.l10n.aboutTagline,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: BusyMarkSpacing.xxs),
        Text(
          context.l10n.aboutVersion(busyMarkAppVersion),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkActionRow(
              title: context.l10n.aboutLicenseLabel,
              subtitle: context.l10n.aboutLicenseName,
              leading: const Icon(BusyMarkGlyphs.info),
              trailing: const Icon(BusyMarkGlyphs.externalLink),
              onTap: () => unawaited(_openApacheLicense()),
            ),
            BusyMarkActionRow(
              title: context.l10n.aboutWebsite,
              subtitle: _busyMarkRepositoryUrl,
              leading: const Icon(BusyMarkGlyphs.home),
              trailing: const Icon(BusyMarkGlyphs.externalLink),
              onTap: () => unawaited(_openBusyMarkRepository()),
            ),
            BusyMarkActionRow(
              title: context.l10n.aboutReportIssue,
              subtitle: _busyMarkIssueUrl,
              leading: const Icon(BusyMarkGlyphs.warning),
              trailing: const Icon(BusyMarkGlyphs.externalLink),
              onTap: () => unawaited(_openBusyMarkIssues()),
            ),
          ],
        ),
      ],
    );
  }
}

class _BusyMarkAboutLogo extends StatelessWidget {
  const _BusyMarkAboutLogo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        image: true,
        label: label,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 136,
            child: ClipRect(
              child: OverflowBox(
                maxWidth: 216,
                maxHeight: 216,
                child: SvgPicture.asset(
                  _busyMarkLogoAsset,
                  width: 216,
                  height: 216,
                ),
              ),
            ),
          ),
        ),
      ),
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
