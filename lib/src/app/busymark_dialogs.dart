import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/linux_header_bar_service.dart';
import 'app_metadata.dart';
import 'busymark_shortcuts.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'localization.dart';

const _busyMarkWebsiteUrl = 'https://busystack.org';
const _busyMarkIssueUrl = 'https://github.com/busystack/busymark/issues';
const _apacheLicenseUrl = 'https://www.apache.org/licenses/LICENSE-2.0';
const _busyMarkLogoAsset = 'assets/branding/busymark_logo.svg';
const _supportedRawHtmlBlockTags =
    'article, aside, div, section, header, footer, main, nav, h1-h6, p, '
    'blockquote, address, hr, ul, ol, li, dl, dt, dd, table, caption, '
    'colgroup, col, thead, tbody, tfoot, tr, th, td, pre, details, summary, '
    'figure, figcaption';
const _supportedRawHtmlInlineTags =
    'span, strong, em, b, i, u, s, small, mark, sub, sup, code, kbd, samp, '
    'var, abbr, cite, q, dfn, time, data, bdi, bdo, wbr, ins, del, ruby, '
    'rt, rp, a, img, br';
final _busyMarkWebsiteUri = Uri.parse(_busyMarkWebsiteUrl);
final _busyMarkIssueUri = Uri.parse(_busyMarkIssueUrl);
final _apacheLicenseUri = Uri.parse(_apacheLicenseUrl);

Color busyMarkModalBarrierColor(BuildContext context) {
  return Theme.of(
    context,
  ).colorScheme.scrim.withValues(alpha: BusyMarkAlpha.modalBarrier);
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
          viewInsets.left + BusyMarkSizes.modalHorizontalInset,
          viewInsets.top + BusyMarkSizes.modalVerticalInset,
          viewInsets.right + BusyMarkSizes.modalHorizontalInset,
          viewInsets.bottom + BusyMarkSizes.modalVerticalInset,
        );
        return AnimatedPadding(
          padding: padding,
          duration: BusyMarkMotion.modalPadding,
          curve: BusyMarkMotion.modalPaddingCurve,
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
    this.maxWidth = BusyMarkSizes.modalMaxWidth,
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
        maxHeight:
            maxHeight ??
            MediaQuery.sizeOf(context).height *
                BusyMarkSizes.modalMaxHeightFraction,
      ),
      child: Material(
        color: colors.dialog,
        elevation: BusyMarkElevation.popover,
        shadowColor: BusyMarkShadow.floatingColor(context),
        surfaceTintColor: BusyMarkLinuxPalette.transparent,
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
  await launchUrl(_busyMarkWebsiteUri, mode: LaunchMode.externalApplication);
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
        maxWidth: BusyMarkSizes.dialogNarrow,
        children: [
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupFile,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.shortcutNewDocument,
                subtitle: context.l10n.shortcutNewDocumentDescription,
                leading: const Icon(BusyMarkGlyphs.newDocument),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.newDocument,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.open,
                subtitle: context.l10n.shortcutOpenDescription,
                leading: const Icon(BusyMarkGlyphs.folderOpen),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.open,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.save,
                subtitle: context.l10n.shortcutSaveDescription,
                leading: const Icon(BusyMarkGlyphs.save),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.save,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.find,
                subtitle: context.l10n.shortcutFindDescription,
                leading: const Icon(BusyMarkGlyphs.search),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.find,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.keyboardShortcuts,
                subtitle: context.l10n.shortcutKeyboardShortcutsDescription,
                leading: const Icon(BusyMarkGlyphs.keyboard),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.keyboardShortcuts,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.markdownAndHtml,
                subtitle: context.l10n.shortcutMarkdownAndHtmlDescription,
                leading: const Icon(BusyMarkGlyphs.markdownFile),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.markdownAndHtml,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.settings,
                subtitle: context.l10n.shortcutSettingsDescription,
                leading: const Icon(BusyMarkGlyphs.settings),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.settings,
                ),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.tabs,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.shortcutNextTab,
                subtitle: context.l10n.shortcutNextTabDescription,
                leading: const Icon(BusyMarkGlyphs.tab),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.nextTab,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutPreviousTab,
                subtitle: context.l10n.shortcutPreviousTabDescription,
                leading: const Icon(BusyMarkGlyphs.tab),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.previousTab,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutCloseTab,
                subtitle: context.l10n.shortcutCloseTabDescription,
                leading: const Icon(BusyMarkGlyphs.clear),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.closeTab,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutCloseAllTabs,
                subtitle: context.l10n.shortcutCloseAllTabsDescription,
                leading: const Icon(BusyMarkGlyphs.clearAll),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.closeAllTabs,
                ),
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
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.selectAll,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.cut,
                subtitle: context.l10n.shortcutCutDescription,
                leading: const Icon(BusyMarkGlyphs.cut),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.cut,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.copy,
                subtitle: context.l10n.shortcutCopyDescription,
                leading: const Icon(BusyMarkGlyphs.copy),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.copy,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.paste,
                subtitle: context.l10n.shortcutPasteDescription,
                leading: const Icon(BusyMarkGlyphs.paste),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.paste,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.pasteWithoutFormatting,
                subtitle: context.l10n.shortcutPastePlainTextDescription,
                leading: const Icon(BusyMarkGlyphs.paste),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.pastePlainText,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.undo,
                subtitle: context.l10n.shortcutUndoDescription,
                leading: const Icon(BusyMarkGlyphs.undo),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.undo,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.redo,
                subtitle: context.l10n.shortcutRedoDescription,
                leading: const Icon(BusyMarkGlyphs.redo),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.redo,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.clearEditorSelection,
                subtitle: context.l10n.shortcutClearEditorSelectionDescription,
                leading: const Icon(BusyMarkGlyphs.clear),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.clearSelection,
                ),
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
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.bold,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.italic,
                subtitle: context.l10n.shortcutItalicDescription,
                leading: const Icon(BusyMarkGlyphs.italic),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.italic,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.underline,
                subtitle: context.l10n.shortcutUnderlineDescription,
                leading: const Icon(BusyMarkGlyphs.underline),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.underline,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.link,
                subtitle: context.l10n.shortcutLinkDescription,
                leading: const Icon(BusyMarkGlyphs.link),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.link,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.inlineCode,
                subtitle: context.l10n.shortcutInlineCodeDescription,
                leading: const Icon(BusyMarkGlyphs.code),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.inlineCode,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.strikethrough,
                subtitle: context.l10n.shortcutStrikethroughDescription,
                leading: const Icon(BusyMarkGlyphs.strikethrough),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.strikethrough,
                ),
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
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.paragraph,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading1,
                subtitle: context.l10n.shortcutHeading1Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading1,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading2,
                subtitle: context.l10n.shortcutHeading2Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading2,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading3,
                subtitle: context.l10n.shortcutHeading3Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading3,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading4,
                subtitle: context.l10n.shortcutHeading4Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading4,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading5,
                subtitle: context.l10n.shortcutHeading5Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading5,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.heading6,
                subtitle: context.l10n.shortcutHeading6Description,
                leading: const Icon(BusyMarkGlyphs.heading),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.heading6,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.blockquote,
                leading: const Icon(BusyMarkGlyphs.blockquote),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.blockquote,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.codeBlock,
                leading: const Icon(BusyMarkGlyphs.code),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.codeBlock,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.codeBlockLanguage,
                leading: const Icon(BusyMarkGlyphs.insertObject),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.codeBlockLanguage,
                ),
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
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.orderedList,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.bulletedList,
                subtitle: context.l10n.shortcutBulletedListDescription,
                leading: const Icon(BusyMarkGlyphs.unorderedList),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.unorderedList,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.checklist,
                subtitle: context.l10n.shortcutChecklistDescription,
                leading: const Icon(BusyMarkGlyphs.checklist),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.taskList,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.toggleTaskChecked,
                leading: const Icon(BusyMarkGlyphs.checkedBox),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.toggleTask,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.indentListItem,
                leading: const Icon(BusyMarkGlyphs.indent),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.indent,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.outdentListItem,
                leading: const Icon(BusyMarkGlyphs.outdent),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.outdent,
                ),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.insert,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.image,
                leading: const Icon(BusyMarkGlyphs.image),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.image,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.inlineImage,
                leading: const Icon(BusyMarkGlyphs.inlineImage),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.inlineImage,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.table,
                leading: const Icon(BusyMarkGlyphs.table),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.table,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.htmlBlock,
                subtitle: context.l10n.shortcutHtmlBlockDescription,
                leading: const Icon(BusyMarkGlyphs.code),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.htmlBlock,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.thematicBreak,
                leading: const Icon(BusyMarkGlyphs.thematicBreak),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.thematicBreak,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.hardLineBreak,
                leading: const Icon(BusyMarkGlyphs.hardBreak),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.hardLineBreak,
                ),
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupSidebar,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.toggleSidebar,
                leading: const Icon(BusyMarkGlyphs.sidebar),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.toggleSidebar,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.files,
                leading: const Icon(BusyMarkGlyphs.documentOpen),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.files,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.toc,
                leading: const Icon(BusyMarkGlyphs.orderedList),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.toc,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.outline,
                leading: const Icon(BusyMarkGlyphs.indent),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.outline,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.gitCommit,
                leading: const Icon(BusyMarkGlyphs.checklist),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.git,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.gitHistory,
                leading: const Icon(BusyMarkGlyphs.history),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.history,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showBusyMarkMarkdownHtmlDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => _BusyMarkInfoDialog(
        title: context.l10n.markdownAndHtml,
        maxWidth: BusyMarkSizes.dialogWide,
        children: [
          BusyMarkGroupedList(
            title: context.l10n.markdownHtmlMarkdownBlocks,
            description: context.l10n.markdownHtmlMarkdownBlocksDescription,
            filled: true,
            children: [
              _ReferenceRow(
                title: context.l10n.markdownHtmlHeadings,
                syntax: '#, ##, ###',
                icon: BusyMarkGlyphs.heading,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlParagraphs,
                syntax: 'text',
                icon: BusyMarkGlyphs.paragraph,
              ),
              _ReferenceRow(
                title: context.l10n.blockquote,
                syntax: '> quote',
                icon: BusyMarkGlyphs.blockquote,
              ),
              _ReferenceRow(
                title: context.l10n.codeBlock,
                syntax: '```',
                icon: BusyMarkGlyphs.code,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlLists,
                syntax: '-, *, 1.',
                icon: BusyMarkGlyphs.unorderedList,
              ),
              _ReferenceRow(
                title: context.l10n.checklist,
                syntax: '- [ ]',
                icon: BusyMarkGlyphs.checklist,
              ),
              _ReferenceRow(
                title: context.l10n.table,
                syntax: '| --- |',
                icon: BusyMarkGlyphs.table,
              ),
              _ReferenceRow(
                title: context.l10n.image,
                syntax: '![alt](src)',
                icon: BusyMarkGlyphs.image,
              ),
              _ReferenceRow(
                title: context.l10n.thematicBreak,
                syntax: '---',
                icon: BusyMarkGlyphs.thematicBreak,
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.markdownHtmlInlineFormatting,
            description: context.l10n.markdownHtmlInlineFormattingDescription,
            filled: true,
            children: [
              _ReferenceRow(
                title: context.l10n.bold,
                syntax: '**text**',
                icon: BusyMarkGlyphs.bold,
              ),
              _ReferenceRow(
                title: context.l10n.italic,
                syntax: '*text*',
                icon: BusyMarkGlyphs.italic,
              ),
              _ReferenceRow(
                title: context.l10n.underline,
                syntax: '<u>text</u>',
                icon: BusyMarkGlyphs.underline,
              ),
              _ReferenceRow(
                title: context.l10n.strikethrough,
                syntax: '~~text~~',
                icon: BusyMarkGlyphs.strikethrough,
              ),
              _ReferenceRow(
                title: context.l10n.inlineCode,
                syntax: '`code`',
                icon: BusyMarkGlyphs.code,
              ),
              _ReferenceRow(
                title: context.l10n.link,
                syntax: '[text](url)',
                icon: BusyMarkGlyphs.link,
              ),
              _ReferenceRow(
                title: context.l10n.hardLineBreak,
                syntax: '<br>',
                icon: BusyMarkGlyphs.hardBreak,
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.markdownHtmlRawHtmlBlocks,
            description:
                '${context.l10n.markdownHtmlRawHtmlBlocksDescription}\n'
                '$_supportedRawHtmlBlockTags.',
            filled: true,
            children: [
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlContainers,
                syntax: 'div, section',
                icon: BusyMarkGlyphs.insertObject,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlTextBlocks,
                syntax: 'p, h1-h6',
                icon: BusyMarkGlyphs.text,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlLists,
                syntax: 'ul, ol, li',
                icon: BusyMarkGlyphs.orderedList,
              ),
              _ReferenceRow(
                title: context.l10n.table,
                syntax: 'table, tr, td',
                icon: BusyMarkGlyphs.table,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlFigures,
                syntax: 'figure, img',
                icon: BusyMarkGlyphs.image,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlPreformatted,
                syntax: 'pre, code',
                icon: BusyMarkGlyphs.code,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlDisclosure,
                syntax: 'details',
                icon: BusyMarkGlyphs.info,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlDescriptionLists,
                syntax: 'dl, dt, dd',
                icon: BusyMarkGlyphs.unorderedList,
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.markdownHtmlRawHtmlInline,
            description:
                '${context.l10n.markdownHtmlRawHtmlInlineDescription}\n'
                '$_supportedRawHtmlInlineTags.',
            filled: true,
            children: [
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlFormattingTags,
                syntax: 'strong, em, u',
                icon: BusyMarkGlyphs.bold,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlInlineCodeTags,
                syntax: 'kbd, samp, var',
                icon: BusyMarkGlyphs.code,
              ),
              _ReferenceRow(
                title: context.l10n.link,
                syntax: 'a[href]',
                icon: BusyMarkGlyphs.link,
              ),
              _ReferenceRow(
                title: context.l10n.inlineImage,
                syntax: 'img[src]',
                icon: BusyMarkGlyphs.inlineImage,
              ),
              _ReferenceRow(
                title: context.l10n.markdownHtmlHtmlNeutralInlineTags,
                syntax: 'span, time',
                icon: BusyMarkGlyphs.symbols,
              ),
              _ReferenceRow(
                title: context.l10n.hardLineBreak,
                syntax: 'br, wbr',
                icon: BusyMarkGlyphs.hardBreak,
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.markdownHtmlSafety,
            description: context.l10n.markdownHtmlSafetyDescription,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.markdownHtmlSanitizedPreview,
                subtitle: context.l10n.markdownHtmlSanitizedPreviewDescription,
                leading: const Icon(BusyMarkGlyphs.check),
              ),
              BusyMarkActionRow(
                title: context.l10n.markdownHtmlSourcePreserved,
                subtitle: context.l10n.markdownHtmlSourcePreservedDescription,
                leading: const Icon(BusyMarkGlyphs.document),
              ),
              BusyMarkActionRow(
                title: context.l10n.markdownHtmlMarkdownInsideHtml,
                subtitle:
                    context.l10n.markdownHtmlMarkdownInsideHtmlDescription,
                leading: const Icon(BusyMarkGlyphs.markdownFile),
              ),
              BusyMarkActionRow(
                title: context.l10n.markdownHtmlBlockedContent,
                subtitle: context.l10n.markdownHtmlBlockedContentDescription,
                leading: const Icon(BusyMarkGlyphs.warning),
              ),
              BusyMarkActionRow(
                title: context.l10n.markdownHtmlSafeUrls,
                subtitle: context.l10n.markdownHtmlSafeUrlsDescription,
                leading: const Icon(BusyMarkGlyphs.link),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.title,
    required this.syntax,
    required this.icon,
  });

  final String title;
  final String syntax;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BusyMarkActionRow(
      title: title,
      leading: Icon(icon),
      trailing: _KeyboardShortcutBadge(syntax),
    );
  }
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
      maxWidth: BusyMarkSizes.dialogCompact,
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
        const SizedBox(height: BusyMarkSpacing.sm),
        const _AboutVersionTag(version: busyMarkAppVersion),
        const SizedBox(height: BusyMarkSpacing.md),
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
              subtitle: _busyMarkWebsiteUrl,
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
            dimension: BusyMarkSizes.aboutLogoViewport,
            child: SvgPicture.asset(_busyMarkLogoAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _AboutVersionTag extends StatelessWidget {
  const _AboutVersionTag({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.control,
          borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkSpacing.md,
            vertical: BusyMarkSpacing.xs,
          ),
          child: Text(
            version,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
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
            fontFamily: BusyMarkTypography.monoFontFamily,
            color: colors.foreground,
          ),
        ),
      ),
    );
  }
}
