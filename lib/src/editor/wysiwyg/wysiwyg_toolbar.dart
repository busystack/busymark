import '../../app/busymark_shortcuts.dart' show BusyMarkShortcutDefinition;
import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/command_registry.dart';
import '../../app/localization.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_commands.dart';

String busyMarkWritersideInsertLabel(
  BuildContext context,
  BusyWritersideInsertCommand command,
) => switch (command) {
  BusyWritersideInsertCommand.procedure => context.l10n.procedure,
  BusyWritersideInsertCommand.tabs => context.l10n.tabs,
  BusyWritersideInsertCommand.definitionList => context.l10n.wsDefinitionList,
  BusyWritersideInsertCommand.include => context.l10n.wsIncludeContent,
  BusyWritersideInsertCommand.variable => context.l10n.wsVariableReference,
  BusyWritersideInsertCommand.video => context.l10n.video,
  BusyWritersideInsertCommand.tldr => context.l10n.wsTldr,
  BusyWritersideInsertCommand.convertListToProcedure =>
    context.l10n.wsConvertList,
};

String busyMarkSemanticInlineLabel(
  BuildContext context,
  BusyWysiwygInlineCommand command,
) => switch (command) {
  BusyWysiwygInlineCommand.uiControl => context.l10n.wsUiControl,
  BusyWysiwygInlineCommand.filePath => context.l10n.wsFilePath,
  BusyWysiwygInlineCommand.uiPath => context.l10n.wsUiPath,
  BusyWysiwygInlineCommand.shortcut => context.l10n.keyboardShortcuts,
  _ => throw ArgumentError.value(command),
};

class BusyMarkWysiwygToolbar extends StatelessWidget {
  const BusyMarkWysiwygToolbar({
    super.key,
    required this.onBlockCommand,
    this.onAdmonitionCommand,
    this.onWritersideInsert,
    this.isWritersideInsertEnabled,
    this.onMenuCanceled,
    required this.onInlineCommand,
    required this.onLinkCommand,
    required this.onInlineMathCommand,
    required this.onDisplayMathCommand,
    required this.onImageCommand,
    required this.onInlineImageCommand,
    required this.onTableCommand,
    required this.onHtmlCommand,
    required this.onIndentCommand,
    required this.onOutdentCommand,
    required this.onToggleTaskCommand,
    required this.onHardBreakCommand,
    required this.onBlankLineCommand,
    this.isBlockCommandEnabled,
    this.admonitionCommandsEnabled = true,
    this.inlineCommandsEnabled = true,
    this.semanticCommandsEnabled = true,
    this.lineBreakCommandsEnabled = true,
    this.admonitionsEnabled = false,
    this.alignEnd = false,
    this.axis = Axis.horizontal,
  });

  final ValueChanged<BusyWysiwygBlockCommand> onBlockCommand;
  final ValueChanged<BusyAdmonitionStyle>? onAdmonitionCommand;
  final ValueChanged<BusyWritersideInsertCommand>? onWritersideInsert;
  final bool Function(BusyWritersideInsertCommand)? isWritersideInsertEnabled;
  final VoidCallback? onMenuCanceled;
  final ValueChanged<BusyWysiwygInlineCommand> onInlineCommand;
  final VoidCallback onLinkCommand;
  final VoidCallback? onInlineMathCommand;
  final VoidCallback? onDisplayMathCommand;
  final VoidCallback onImageCommand;
  final VoidCallback onInlineImageCommand;
  final VoidCallback? onTableCommand;
  final VoidCallback? onHtmlCommand;
  final VoidCallback onIndentCommand;
  final VoidCallback onOutdentCommand;
  final VoidCallback onToggleTaskCommand;
  final VoidCallback onHardBreakCommand;
  final VoidCallback onBlankLineCommand;
  final bool Function(BusyWysiwygBlockCommand command)? isBlockCommandEnabled;
  final bool admonitionCommandsEnabled;
  final bool inlineCommandsEnabled;
  final bool semanticCommandsEnabled;
  final bool lineBreakCommandsEnabled;
  final bool admonitionsEnabled;
  final bool alignEnd;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    return SingleChildScrollView(
      scrollDirection: axis,
      reverse: alignEnd,
      clipBehavior: Clip.hardEdge,
      hitTestBehavior: HitTestBehavior.deferToChild,
      padding: axis == Axis.horizontal
          ? const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.sm,
              vertical: BusyMarkSpacing.xs,
            )
          : const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.xs,
              vertical: BusyMarkSpacing.sm,
            ),
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        spacing: BusyMarkSpacing.xs,
        children: _groups(axis, [
          [
            _blockStyleMenu(context),
            _button(
              context,
              tooltip: context.l10n.bold,
              icon: BusyMarkGlyphs.bold,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.bold']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.bold)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.italic,
              icon: BusyMarkGlyphs.italic,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.italic']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.italic)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.underline,
              icon: BusyMarkGlyphs.underline,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.underline']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.underline)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.strikethrough,
              icon: BusyMarkGlyphs.strikethrough,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog
                              .metadata)['editor.strikethrough']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled
                  ? () =>
                        onInlineCommand(BusyWysiwygInlineCommand.strikethrough)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineCode,
              icon: BusyMarkGlyphs.code,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.inlineCode']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled
                  ? () => onInlineCommand(BusyWysiwygInlineCommand.code)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.link,
              icon: BusyMarkGlyphs.link,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.link']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled ? onLinkCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineMath,
              icon: BusyMarkGlyphs.math,
              onPressed: inlineCommandsEnabled ? onInlineMathCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.hardLineBreak,
              icon: BusyMarkGlyphs.hardBreak,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog
                              .metadata)['editor.hardLineBreak']
                      ?.shortcut
                      ?.label,
              onPressed: inlineCommandsEnabled && lineBreakCommandsEnabled
                  ? onHardBreakCommand
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.insertBlankLine,
              icon: BusyMarkGlyphs.blankLine,
              onPressed: inlineCommandsEnabled && lineBreakCommandsEnabled
                  ? onBlankLineCommand
                  : null,
            ),
          ],
          if (admonitionsEnabled) [_writersideMenu(context)],
          [
            _button(
              context,
              tooltip: context.l10n.blockquote,
              icon: BusyMarkGlyphs.blockquote,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.blockquote']
                      ?.shortcut
                      ?.label,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.blockquote)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.blockquote)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.codeBlock,
              icon: BusyMarkGlyphs.codeBlock,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.codeBlock']
                      ?.shortcut
                      ?.label,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.codeBlock)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.codeBlock)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.displayMath,
              icon: BusyMarkGlyphs.math,
              onPressed: onDisplayMathCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.htmlBlock,
              icon: BusyMarkGlyphs.htmlBlock,
              onPressed: onHtmlCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.thematicBreak,
              icon: BusyMarkGlyphs.thematicBreak,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog
                              .metadata)['editor.thematicBreak']
                      ?.shortcut
                      ?.label,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.thematicBreak)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.thematicBreak)
                  : null,
            ),
          ],
          [
            _button(
              context,
              tooltip: context.l10n.unorderedList,
              icon: BusyMarkGlyphs.unorderedList,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog
                              .metadata)['editor.unorderedList']
                      ?.shortcut
                      ?.label,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.unorderedList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.unorderedList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.orderedList,
              icon: BusyMarkGlyphs.orderedList,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.orderedList']
                      ?.shortcut
                      ?.label,
              onPressed:
                  _blockCommandEnabled(BusyWysiwygBlockCommand.orderedList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.orderedList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.taskList,
              icon: BusyMarkGlyphs.checkedBox,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.taskList']
                      ?.shortcut
                      ?.label,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.taskList)
                  ? () => onBlockCommand(BusyWysiwygBlockCommand.taskList)
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.toggleTaskChecked,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.toggleTask']
                      ?.shortcut
                      ?.label,
              icon: BusyMarkGlyphs.checkedBox,
              onPressed: onToggleTaskCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.indentListItem,
              icon: BusyMarkGlyphs.indentFor(direction),
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.indent']
                      ?.shortcut
                      ?.label,
              onPressed: onIndentCommand,
            ),
            _button(
              context,
              tooltip: context.l10n.outdentListItem,
              icon: BusyMarkGlyphs.outdentFor(direction),
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.outdent']
                      ?.shortcut
                      ?.label,
              onPressed: onOutdentCommand,
            ),
          ],
          [
            _button(
              context,
              tooltip: context.l10n.image,
              icon: BusyMarkGlyphs.image,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.image']
                      ?.shortcut
                      ?.label,
              onPressed: _blockCommandEnabled(BusyWysiwygBlockCommand.image)
                  ? onImageCommand
                  : null,
            ),
            _button(
              context,
              tooltip: context.l10n.inlineImage,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.inlineImage']
                      ?.shortcut
                      ?.label,
              icon: BusyMarkGlyphs.inlineImage,
              onPressed: inlineCommandsEnabled ? onInlineImageCommand : null,
            ),
            _button(
              context,
              tooltip: context.l10n.table,
              shortcut:
                  (BusyMarkCommandRegistryScope.maybeOf(context) ??
                          BusyMarkCommandCatalog.metadata)['editor.table']
                      ?.shortcut
                      ?.label,
              icon: BusyMarkGlyphs.table,
              onPressed: onTableCommand,
            ),
          ],
        ]),
      ),
    );
  }

  bool _blockCommandEnabled(BusyWysiwygBlockCommand command) {
    return isBlockCommandEnabled?.call(command) ?? true;
  }

  Widget _writersideMenu(BuildContext context) =>
      BusyMarkHeaderPopupMenuButton<BusyWritersideToolbarCommand>(
        onCanceled: onMenuCanceled,
        key: const ValueKey('wysiwyg-writerside'),
        tooltip: context.l10n.writerside,
        icon: BusyMarkGlyphs.insertObject,
        transparent: false,
        elevated: true,
        foregroundColor: BusyMarkLinuxPalette.white,
        backgroundColor: _editorToolbarButtonBackground(context),
        itemBuilder: (context) => [
          if (onWritersideInsert != null)
            BusyMarkSubmenuItem(
              label: context.l10n.wsInsertElements,
              items: [
                for (final command in BusyWritersideInsertCommand.values)
                  BusyMarkPopupMenuItem(
                    value: BusyWritersideToolbarInsert(command),
                    shortcut: _writersideShortcut(
                      context,
                      BusyWritersideToolbarInsert(command),
                    )?.label,
                    gtkAccelerator: _writersideShortcut(
                      context,
                      BusyWritersideToolbarInsert(command),
                    )?.gtkAccelerator,
                    label: busyMarkWritersideInsertLabel(context, command),
                    enabled: isWritersideInsertEnabled?.call(command) ?? true,
                  ),
              ],
            ),
          if (onAdmonitionCommand != null)
            BusyMarkSubmenuItem(
              label: context.l10n.wsAdmonitionsAndQuotes,
              items: [
                for (final style in BusyAdmonitionStyle.values)
                  BusyMarkPopupMenuItem(
                    value: BusyWritersideToolbarAdmonition(style),
                    shortcut: _writersideShortcut(
                      context,
                      BusyWritersideToolbarAdmonition(style),
                    )?.label,
                    gtkAccelerator: _writersideShortcut(
                      context,
                      BusyWritersideToolbarAdmonition(style),
                    )?.gtkAccelerator,
                    label: switch (style) {
                      BusyAdmonitionStyle.tip => context.l10n.tip,
                      BusyAdmonitionStyle.note => context.l10n.note,
                      BusyAdmonitionStyle.warning => context.l10n.warning,
                      BusyAdmonitionStyle.quote => context.l10n.quote,
                    },
                    enabled: admonitionCommandsEnabled,
                  ),
              ],
            ),
          BusyMarkSubmenuItem(
            label: context.l10n.wsSemanticText,
            items: [
              for (final command in const [
                BusyWysiwygInlineCommand.uiControl,
                BusyWysiwygInlineCommand.filePath,
                BusyWysiwygInlineCommand.uiPath,
                BusyWysiwygInlineCommand.shortcut,
              ])
                BusyMarkPopupMenuItem(
                  value: BusyWritersideToolbarSemantic(command),
                  shortcut: _writersideShortcut(
                    context,
                    BusyWritersideToolbarSemantic(command),
                  )?.label,
                  gtkAccelerator: _writersideShortcut(
                    context,
                    BusyWritersideToolbarSemantic(command),
                  )?.gtkAccelerator,
                  enabled: inlineCommandsEnabled && semanticCommandsEnabled,
                  label: busyMarkSemanticInlineLabel(context, command),
                ),
            ],
          ),
        ],
        onSelected: (selection) {
          switch (selection) {
            case BusyWritersideToolbarInsert(:final command):
              onWritersideInsert!(command);
            case BusyWritersideToolbarAdmonition(:final style):
              onAdmonitionCommand!(style);
            case BusyWritersideToolbarSemantic(:final command):
              onInlineCommand(command);
          }
        },
      );

  List<Widget> _groups(Axis axis, List<List<Widget>> groups) {
    final widgets = <Widget>[];
    for (final (groupIndex, group)
        in groups.where((items) => items.isNotEmpty).indexed) {
      if (widgets.isNotEmpty) {
        widgets.add(
          SizedBox(
            key: ValueKey('wysiwyg-toolbar-group-separator-$groupIndex'),
            width: axis == Axis.horizontal ? BusyMarkSpacing.sm : null,
            height: axis == Axis.vertical ? BusyMarkSpacing.sm : null,
          ),
        );
      }
      widgets.addAll(group);
    }
    return widgets;
  }

  Widget _blockStyleMenu(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<BusyWysiwygBlockCommand>(
      onCanceled: onMenuCanceled,
      tooltip: context.l10n.textStyle,
      icon: BusyMarkGlyphs.font,
      shortcut: null,
      transparent: false,
      elevated: true,
      foregroundColor: BusyMarkLinuxPalette.white,
      backgroundColor: _editorToolbarButtonBackground(context),
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.paragraph,
          label: context.l10n.paragraph,
          icon: BusyMarkGlyphs.paragraph,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.paragraph']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.paragraph),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading1,
          label: context.l10n.heading1,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading1']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading1),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading2,
          label: context.l10n.heading2,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading2']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading2),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading3,
          label: context.l10n.heading3,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading3']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading3),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading4,
          label: context.l10n.heading4,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading4']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading4),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading5,
          label: context.l10n.heading5,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading5']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading5),
        ),
        BusyMarkPopupMenuItem(
          value: BusyWysiwygBlockCommand.heading6,
          label: context.l10n.heading6,
          icon: BusyMarkGlyphs.heading,
          shortcut:
              (BusyMarkCommandRegistryScope.maybeOf(context) ??
                      BusyMarkCommandCatalog.metadata)['editor.heading6']
                  ?.shortcut
                  ?.label,
          enabled: _blockCommandEnabled(BusyWysiwygBlockCommand.heading6),
        ),
      ],
      onSelected: onBlockCommand,
    );
  }

  Widget _button(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    String? shortcut,
    Key? key,
  }) {
    return BusyMarkHeaderIconButton(
      key: key,
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      shortcut: shortcut,
      transparent: false,
      elevated: true,
      foregroundColor: BusyMarkLinuxPalette.white,
      backgroundColor: _editorToolbarButtonBackground(context),
    );
  }

  WidgetStateProperty<Color?> _editorToolbarButtonBackground(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        // The floating toolbar has no surface beneath its translucent fills.
        return Color.alphaBlend(colors.disabledControl, colors.view);
      }
      return theme.colorScheme.primary;
    });
  }
}

BusyMarkShortcutDefinition? _writersideShortcut(
  BuildContext context,
  BusyWritersideToolbarCommand command,
) =>
    (BusyMarkCommandRegistryScope.maybeOf(context) ??
            BusyMarkCommandCatalog.metadata)[writersideToolbarCommandId(
          command,
        )]
        ?.shortcut;
