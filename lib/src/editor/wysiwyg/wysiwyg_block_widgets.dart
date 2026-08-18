import 'package:flutter/material.dart';

import '../../app/busymark_design.dart';
import '../../app/busymark_glyphs.dart';
import '../../app/localization.dart';
import '../document_callout.dart';
import '../document_code_block.dart';
import '../document_list_marker.dart';
import '../document_surface.dart';
import '../document_text_geometry.dart';
import '../document_text_direction.dart';
import '../document_thematic_break.dart';
import '../markdown_image_view.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_inline_controller.dart';

TextDirection busyMarkWysiwygBlockTextDirection(
  BusyBlock block, {
  required TextDirection fallback,
}) {
  return busyMarkDocumentTextDirection(
    text: _directionalText(block),
    fallback: fallback,
    explicitDirection: block.attributes['dir'],
    technical: _isTechnicalWysiwygBlock(block),
  );
}

bool _isTechnicalWysiwygBlock(BusyBlock block) {
  return switch (block.kind) {
    BusyBlockKind.codeBlock ||
    BusyBlockKind.frontMatter ||
    BusyBlockKind.writersideTabs ||
    BusyBlockKind.writersideProcedure ||
    BusyBlockKind.writersideRawXml ||
    BusyBlockKind.unknown => true,
    BusyBlockKind.htmlBlock =>
      block.attributes['sourceFormat'] != 'html' || block.children.isEmpty,
    _ => false,
  };
}

EdgeInsets busyMarkWysiwygOuterPadding(
  BusyBlock block, {
  bool first = false,
  bool listRunEnd = false,
}) {
  final padding = switch (block.kind) {
    BusyBlockKind.heading => BusyMarkInsets.documentHeadingBlock,
    BusyBlockKind.paragraph => BusyMarkInsets.documentParagraphBlock,
    BusyBlockKind.codeBlock => BusyMarkInsets.documentCodeBlock,
    BusyBlockKind.blockquote ||
    BusyBlockKind.writersideAdmonition ||
    BusyBlockKind.writersideTabs ||
    BusyBlockKind.writersideProcedure ||
    BusyBlockKind.writersideRawXml ||
    BusyBlockKind.htmlBlock ||
    BusyBlockKind.unknown => BusyMarkInsets.wysiwygContainerBlock,
    BusyBlockKind.table => BusyMarkInsets.wysiwygTableBlock,
    BusyBlockKind.image => BusyMarkInsets.documentImageBlock,
    BusyBlockKind.thematicBreak => EdgeInsets.zero,
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => busyMarkDocumentListItemPadding(
      listRunEnd: listRunEnd,
      endsWithNestedList: _endsWithNestedList(block),
    ),
    _ => BusyMarkInsets.wysiwygDefaultBlock,
  };
  final trimFirstBlockSpacing =
      first &&
      (block.kind == BusyBlockKind.heading ||
          block.kind == BusyBlockKind.paragraph);
  return trimFirstBlockSpacing ? padding.copyWith(top: 0) : padding;
}

EdgeInsets busyMarkWysiwygContentPadding(BusyBlock block) {
  return switch (block.kind) {
    BusyBlockKind.codeBlock => BusyMarkInsets.documentCodeContent,
    BusyBlockKind.blockquote ||
    BusyBlockKind.writersideAdmonition ||
    BusyBlockKind.writersideTabs ||
    BusyBlockKind.writersideProcedure ||
    BusyBlockKind.writersideRawXml ||
    BusyBlockKind.htmlBlock ||
    BusyBlockKind.unknown => BusyMarkInsets.wysiwygContainerContent,
    BusyBlockKind.table => BusyMarkInsets.wysiwygTableContent,
    _ => EdgeInsets.zero,
  };
}

EdgeInsets busyMarkWysiwygTextLayoutInsets(BusyBlock block) {
  final contentPadding = busyMarkWysiwygContentPadding(block);
  return switch (block.kind) {
    BusyBlockKind.codeBlock ||
    BusyBlockKind.blockquote ||
    BusyBlockKind.writersideAdmonition => busyMarkDocumentSurfaceLayoutInsets(
      contentPadding,
    ),
    _ => contentPadding,
  };
}

double busyMarkWysiwygPrefixExtent(BusyBlock block) {
  return switch (block.kind) {
    BusyBlockKind.unorderedListItem ||
    BusyBlockKind.orderedListItem ||
    BusyBlockKind.taskListItem => BusyMarkSizes.documentListIndent,
    BusyBlockKind.htmlBlock =>
      BusyMarkSizes.wysiwygPrefixWidth + BusyMarkSpacing.sm,
    _ => 0,
  };
}

bool _isWysiwygListItem(BusyBlock block) => switch (block.kind) {
  BusyBlockKind.unorderedListItem ||
  BusyBlockKind.orderedListItem ||
  BusyBlockKind.taskListItem => true,
  _ => false,
};

bool _endsWithNestedList(BusyBlock block) {
  return block.children.isNotEmpty && _isWysiwygListItem(block.children.last);
}

class BusyMarkWysiwygBlockField extends StatelessWidget {
  const BusyMarkWysiwygBlockField({
    super.key,
    required this.block,
    this.first = false,
    this.listRunEnd = false,
    required this.documentFilePath,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    required this.allowRemoteImages,
    this.onRemoteImageBlocked,
    required this.controller,
    required this.undoController,
    required this.focusNode,
    required this.onChanged,
    required this.onTableCellChanged,
    required this.onTableRowInserted,
    required this.onTableRowDeleted,
    required this.onTableColumnInserted,
    required this.onTableColumnDeleted,
    required this.onTableDeleted,
    required this.onImageEditRequested,
    required this.onHtmlEditRequested,
    required this.onTaskChanged,
    required this.onFocused,
    this.selected = false,
    this.selectionRange,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

  final BusyBlock block;
  final bool first;
  final bool listRunEnd;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final BusyMarkWysiwygTextController controller;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final void Function(String cellId, String text) onTableCellChanged;
  final void Function(int rowIndex, {required bool after}) onTableRowInserted;
  final ValueChanged<int> onTableRowDeleted;
  final void Function(int columnIndex, {required bool after})
  onTableColumnInserted;
  final ValueChanged<int> onTableColumnDeleted;
  final VoidCallback onTableDeleted;
  final VoidCallback onImageEditRequested;
  final VoidCallback onHtmlEditRequested;
  final ValueChanged<bool> onTaskChanged;
  final VoidCallback onFocused;
  final bool selected;
  final BusyMarkWysiwygSelectionRange? selectionRange;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerMoveEvent>? onPointerMove;
  final ValueChanged<PointerUpEvent>? onPointerUp;

  @override
  Widget build(BuildContext context) {
    final style = _textStyle(context);
    final prefix = _prefix(context);
    final readOnly = _readOnly;
    final tapHandler = block.kind == BusyBlockKind.table
        ? onFocused
        : block.kind == BusyBlockKind.image
        ? _editImageBlock
        : _isRenderedHtmlBlock
        ? _editHtmlBlock
        : readOnly
        ? onFocused
        : _focusBlock;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: _minimumHeight(context)),
      child: _blockContent(context, style, prefix, readOnly),
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: block.kind == BusyBlockKind.codeBlock
          ? Directionality(
              textDirection: busyMarkWysiwygBlockTextDirection(
                block,
                fallback: Directionality.of(context),
              ),
              child: BusyMarkDocumentCodeBlock(
                onTap: tapHandler,
                child: content,
              ),
            )
          : block.kind == BusyBlockKind.blockquote
          ? Directionality(
              textDirection: busyMarkWysiwygBlockTextDirection(
                block,
                fallback: Directionality.of(context),
              ),
              child: BusyMarkDocumentCallout(
                icon: BusyMarkGlyphs.blockquote,
                margin: _padding,
                onTap: tapHandler,
                child: content,
              ),
            )
          : block.kind == BusyBlockKind.writersideAdmonition
          ? Directionality(
              textDirection: busyMarkWysiwygBlockTextDirection(
                block,
                fallback: Directionality.of(context),
              ),
              child: BusyMarkDocumentAdmonition(
                style: block.attributes['element'] ?? block.attributes['style'],
                margin: _padding,
                onTap: tapHandler,
                child: content,
              ),
            )
          : Padding(
              padding: _padding,
              child: GestureDetector(
                key: block.kind == BusyBlockKind.image
                    ? ValueKey('wysiwyg-image-block-${block.id}')
                    : null,
                behavior: HitTestBehavior.translucent,
                onTap: tapHandler,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _background(context),
                    borderRadius: BorderRadius.circular(BusyMarkRadius.md),
                    border: _border(context),
                  ),
                  child: Padding(padding: _contentPadding, child: content),
                ),
              ),
            ),
    );
  }

  Widget _blockContent(
    BuildContext context,
    TextStyle style,
    Widget? prefix,
    bool readOnly,
  ) {
    final colors = BusyMarkSurfaceColors.of(context);
    final textDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: Directionality.of(context),
    );
    if (block.kind == BusyBlockKind.thematicBreak) {
      return BusyMarkDocumentThematicBreak(editable: true, selected: selected);
    }
    if (block.kind == BusyBlockKind.table) {
      return Directionality(
        textDirection: textDirection,
        child: _TableBlockEditor(
          block: block,
          onFocused: onFocused,
          onCellChanged: onTableCellChanged,
          onRowInserted: onTableRowInserted,
          onRowDeleted: onTableRowDeleted,
          onColumnInserted: onTableColumnInserted,
          onColumnDeleted: onTableColumnDeleted,
          onTableDeleted: onTableDeleted,
        ),
      );
    }
    if (_isRenderedHtmlBlock) {
      return _RenderedHtmlBlockEditor(
        block: block,
        documentFilePath: documentFilePath,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
        allowRemoteImages: allowRemoteImages,
        onRemoteImageBlocked: onRemoteImageBlocked,
        onEdit: _editHtmlBlock,
      );
    }
    return Directionality(
      textDirection: textDirection,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null) ...[
            prefix,
            const SizedBox(width: BusyMarkSpacing.sm),
          ],
          Expanded(
            child: block.kind == BusyBlockKind.image
                ? _ImageBlockEditor(
                    block: block,
                    documentFilePath: documentFilePath,
                    workspaceRoot: workspaceRoot,
                    writersideRoot: writersideRoot,
                    imagesDir: imagesDir,
                    allowRemoteImages: allowRemoteImages,
                    onRemoteImageBlocked: onRemoteImageBlocked,
                  )
                : readOnly
                ? SelectableText(
                    _readOnlyText,
                    textDirection: textDirection,
                    style: style.copyWith(
                      color: colors.mutedForeground,
                      fontFamily: BusyMarkTypography.monoFontFamily,
                      fontFamilyFallback:
                          BusyMarkTypography.monoFontFamilyFallback,
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _WysiwygSelectionPainter(
                              text: controller.text,
                              style: style,
                              selectionRange: selectionRange,
                              color:
                                  DefaultSelectionStyle.of(
                                    context,
                                  ).selectionColor ??
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(
                                    alpha: BusyMarkDocumentTextGeometry
                                        .fallbackSelectionAlpha,
                                  ),
                              textDirection: textDirection,
                              textScaler: MediaQuery.textScalerOf(context),
                              locale: Localizations.maybeLocaleOf(context),
                              layoutWidthInset: BusyMarkDocumentTextGeometry
                                  .editableLayoutInset,
                            ),
                          ),
                        ),
                      ),
                      TextSelectionTheme(
                        data: selectionRange == null
                            ? Theme.of(context).textSelectionTheme
                            : Theme.of(context).textSelectionTheme.copyWith(
                                selectionColor:
                                    BusyMarkLinuxPalette.transparent,
                              ),
                        child: TextField(
                          key: ValueKey(
                            'wysiwyg-field-$documentFilePath-${block.id}',
                          ),
                          controller: controller,
                          undoController: undoController,
                          focusNode: focusNode,
                          maxLines: null,
                          minLines: 1,
                          textDirection: textDirection,
                          style: style,
                          cursorWidth:
                              BusyMarkDocumentTextGeometry.editableCursorWidth,
                          selectionHeightStyle:
                              BusyMarkDocumentTextGeometry.selectionHeightStyle,
                          selectionWidthStyle:
                              BusyMarkDocumentTextGeometry.selectionWidthStyle,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hoverColor: BusyMarkLinuxPalette.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: onFocused,
                          onChanged: onChanged,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _focusBlock() {
    onFocused();
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    if (!controller.selection.isValid || controller.selection.baseOffset < 0) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  void _editImageBlock() {
    onFocused();
    onImageEditRequested();
  }

  void _editHtmlBlock() {
    onFocused();
    onHtmlEditRequested();
  }

  bool get _isRenderedHtmlBlock {
    return block.kind == BusyBlockKind.htmlBlock &&
        block.attributes['sourceFormat'] == 'html' &&
        block.children.isNotEmpty;
  }

  double _minimumHeight(BuildContext context) {
    final style = _textStyle(context);
    final fontSize =
        style.fontSize ??
        Theme.of(context).textTheme.bodyMedium?.fontSize ??
        14;
    return switch (block.kind) {
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => fontSize * 2.4,
      BusyBlockKind.table => fontSize * 5.8,
      BusyBlockKind.image => BusyMarkSizes.documentImageMinHeight,
      _ => 0,
    };
  }

  bool get _readOnly {
    return block.preserveRaw || block.kind == BusyBlockKind.thematicBreak;
  }

  String get _readOnlyText {
    return block.rawSource ?? block.plainText;
  }

  EdgeInsets get _padding =>
      busyMarkWysiwygOuterPadding(block, first: first, listRunEnd: listRunEnd);

  EdgeInsets get _contentPadding => busyMarkWysiwygContentPadding(block);

  TextStyle _textStyle(BuildContext context) {
    final level = int.tryParse(block.attributes['level'] ?? '') ?? 0;
    return switch (block.kind) {
      BusyBlockKind.heading => busyMarkDocumentHeadingTextStyle(context, level),
      BusyBlockKind.codeBlock => busyMarkDocumentCodeTextStyle(context),
      _ => busyMarkDocumentBodyTextStyle(context),
    };
  }

  Widget? _prefix(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem => const BusyMarkDocumentListMarker(),
      BusyBlockKind.orderedListItem => BusyMarkDocumentListMarker(
        ordered: true,
        marker: block.attributes['marker'],
      ),
      BusyBlockKind.taskListItem => BusyMarkDocumentListMarker(
        task: block.attributes['task'] == 'true',
        onTaskChanged: onTaskChanged,
        taskTooltip: context.l10n.toggleTaskChecked,
      ),
      BusyBlockKind.htmlBlock => SizedBox(
        width: BusyMarkSizes.wysiwygPrefixWidth,
        child: Icon(
          BusyMarkGlyphs.code,
          size: BusyMarkSizes.iconSm,
          color: colors.mutedForeground,
        ),
      ),
      _ => null,
    };
  }

  Color _background(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => colors.panel,
      _ => BusyMarkLinuxPalette.transparent,
    };
  }

  BoxBorder? _border(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => Border.all(color: colors.subtleBorder),
      _ => null,
    };
  }
}

class BusyMarkWysiwygSelectionRange {
  const BusyMarkWysiwygSelectionRange({required this.start, required this.end});

  final int start;
  final int end;
}

class _RenderedHtmlBlockEditor extends StatelessWidget {
  const _RenderedHtmlBlockEditor({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
    required this.onEdit,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Tooltip(
      message: context.l10n.editHtml,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.controlHover,
                  borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
                  border: Border.all(color: colors.subtleBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BusyMarkSpacing.sm,
                    vertical: BusyMarkSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        BusyMarkGlyphs.code,
                        size: BusyMarkSizes.iconSm,
                      ),
                      const SizedBox(width: BusyMarkSpacing.xs),
                      Text(
                        context.l10n.renderedHtml,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              BusyMarkHeaderIconButton(
                tooltip: context.l10n.editHtml,
                icon: BusyMarkGlyphs.edit,
                foregroundColor: colors.mutedForeground,
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.sm),
          _RenderedHtmlBlocks(
            blocks: block.children,
            documentFilePath: documentFilePath,
            workspaceRoot: workspaceRoot,
            writersideRoot: writersideRoot,
            imagesDir: imagesDir,
            allowRemoteImages: allowRemoteImages,
            onRemoteImageBlocked: onRemoteImageBlocked,
          ),
        ],
      ),
    );
  }
}

class _RenderedHtmlBlocks extends StatelessWidget {
  const _RenderedHtmlBlocks({
    required this.blocks,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
  });

  final List<BusyBlock> blocks;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, block) in blocks.indexed)
          _RenderedHtmlBlock(
            block: block,
            documentFilePath: documentFilePath,
            workspaceRoot: workspaceRoot,
            writersideRoot: writersideRoot,
            imagesDir: imagesDir,
            allowRemoteImages: allowRemoteImages,
            onRemoteImageBlocked: onRemoteImageBlocked,
            first: index == 0,
          ),
      ],
    );
  }
}

class _RenderedHtmlBlock extends StatelessWidget {
  const _RenderedHtmlBlock({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
    required this.first,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final content = switch (block.kind) {
      BusyBlockKind.heading => Padding(
        padding: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.smPlus,
          bottom: BusyMarkSpacing.xs,
        ),
        child: _RenderedHtmlInlineText(
          block: block,
          style: busyMarkDocumentHeadingTextStyle(
            context,
            int.tryParse(block.attributes['level'] ?? ''),
          ),
        ),
      ),
      BusyBlockKind.paragraph => Padding(
        padding: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.xs,
          bottom: BusyMarkSpacing.xs,
        ),
        child: _RenderedHtmlInlineText(
          block: block,
          style: textTheme.bodyMedium?.copyWith(
            height: BusyMarkTypography.bodyLineHeight,
          ),
        ),
      ),
      BusyBlockKind.image => Padding(
        padding: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.xs,
          bottom: BusyMarkSpacing.xs,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MarkdownImageView(
            source: _imageSource(block),
            alt: block.plainText,
            activeFilePath: documentFilePath,
            workspaceRoot: workspaceRoot,
            writersideRoot: writersideRoot,
            imagesDir: imagesDir,
            allowRemoteImages: allowRemoteImages,
            onRemoteImageBlocked: onRemoteImageBlocked,
          ),
        ),
      ),
      BusyBlockKind.codeBlock => BusyMarkDocumentCodeBlock(
        variant: BusyMarkDocumentCodeBlockVariant.embedded,
        margin: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.xs,
          bottom: BusyMarkSpacing.xs,
        ),
        backgroundColor: colors.view,
        child: Text(
          block.plainText,
          style: busyMarkDocumentCodeTextStyle(context),
        ),
      ),
      BusyBlockKind.blockquote => BusyMarkDocumentCallout(
        icon: BusyMarkGlyphs.blockquote,
        margin: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.xs,
          bottom: BusyMarkSpacing.xs,
        ),
        backgroundColor: colors.view,
        child: block.children.isEmpty
            ? _RenderedHtmlInlineText(block: block)
            : _RenderedHtmlBlocks(
                blocks: block.children,
                documentFilePath: documentFilePath,
                workspaceRoot: workspaceRoot,
                writersideRoot: writersideRoot,
                imagesDir: imagesDir,
                allowRemoteImages: allowRemoteImages,
                onRemoteImageBlocked: onRemoteImageBlocked,
              ),
      ),
      BusyBlockKind.table => _RenderedHtmlTable(block: block, first: first),
      BusyBlockKind.unorderedListItem ||
      BusyBlockKind.orderedListItem ||
      BusyBlockKind.taskListItem => _RenderedHtmlListItem(
        block: block,
        documentFilePath: documentFilePath,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
        allowRemoteImages: allowRemoteImages,
        onRemoteImageBlocked: onRemoteImageBlocked,
        first: first,
      ),
      BusyBlockKind.thematicBreak => const BusyMarkDocumentThematicBreak(),
      BusyBlockKind.htmlBlock when block.attributes['htmlTag'] == 'figure' =>
        _RenderedHtmlFigure(
          block: block,
          documentFilePath: documentFilePath,
          workspaceRoot: workspaceRoot,
          writersideRoot: writersideRoot,
          imagesDir: imagesDir,
          allowRemoteImages: allowRemoteImages,
          onRemoteImageBlocked: onRemoteImageBlocked,
          first: first,
        ),
      BusyBlockKind.htmlBlock => _RenderedHtmlBlocks(
        blocks: block.children,
        documentFilePath: documentFilePath,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
        allowRemoteImages: allowRemoteImages,
        onRemoteImageBlocked: onRemoteImageBlocked,
      ),
      _ => Padding(
        padding: EdgeInsets.only(
          top: first ? 0 : BusyMarkSpacing.xs,
          bottom: BusyMarkSpacing.xs,
        ),
        child: _RenderedHtmlInlineText(block: block),
      ),
    };
    final inheritedDirection = Directionality.of(context);
    final blockDirection = busyMarkWysiwygBlockTextDirection(
      block,
      fallback: inheritedDirection,
    );
    return blockDirection == inheritedDirection
        ? content
        : Directionality(textDirection: blockDirection, child: content);
  }
}

class _RenderedHtmlFigure extends StatelessWidget {
  const _RenderedHtmlFigure({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
    required this.first,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final contentBlocks = block.children
        .where((child) => child.attributes['htmlTag'] != 'figcaption')
        .toList();
    final captionBlocks = block.children
        .where((child) => child.attributes['htmlTag'] == 'figcaption')
        .toList();
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.mutedForeground,
      height: BusyMarkTypography.bodyLineHeight,
    );
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : BusyMarkSpacing.xs,
        bottom: BusyMarkSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RenderedHtmlBlocks(
            blocks: contentBlocks,
            documentFilePath: documentFilePath,
            workspaceRoot: workspaceRoot,
            writersideRoot: writersideRoot,
            imagesDir: imagesDir,
            allowRemoteImages: allowRemoteImages,
            onRemoteImageBlocked: onRemoteImageBlocked,
          ),
          if (captionBlocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: BusyMarkSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final caption in captionBlocks)
                    _RenderedHtmlInlineText(
                      block: caption,
                      style: captionStyle,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RenderedHtmlListItem extends StatelessWidget {
  const _RenderedHtmlListItem({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
    required this.first,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : BusyMarkSpacing.xs,
        bottom: block.children.isEmpty ? BusyMarkSpacing.xs : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BusyMarkDocumentListMarker(
                ordered: block.kind == BusyBlockKind.orderedListItem,
                marker: block.attributes['marker'],
                task: block.kind == BusyBlockKind.taskListItem
                    ? block.attributes['task'] == 'true'
                    : null,
              ),
              const SizedBox(width: BusyMarkSpacing.sm),
              Expanded(child: _RenderedHtmlInlineText(block: block)),
            ],
          ),
          if (block.children.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: BusyMarkSizes.documentListIndent,
              ),
              child: _RenderedHtmlBlocks(
                blocks: block.children,
                documentFilePath: documentFilePath,
                workspaceRoot: workspaceRoot,
                writersideRoot: writersideRoot,
                imagesDir: imagesDir,
                allowRemoteImages: allowRemoteImages,
                onRemoteImageBlocked: onRemoteImageBlocked,
              ),
            ),
        ],
      ),
    );
  }
}

class _RenderedHtmlTable extends StatelessWidget {
  const _RenderedHtmlTable({required this.block, required this.first});

  final BusyBlock block;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final rows = block.children;
    final columnCount = _columnCount(rows);
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : BusyMarkSpacing.xs,
        bottom: BusyMarkSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: BusyMarkSizes.tableMinWidth,
          ),
          child: Table(
            border: TableBorder.all(
              color: colors.subtleBorder,
              borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              for (final (rowIndex, row) in rows.indexed)
                TableRow(
                  decoration: BoxDecoration(
                    color: _isHeaderRow(row, rowIndex)
                        ? colors.controlHover
                        : BusyMarkLinuxPalette.transparent,
                  ),
                  children: [
                    for (var column = 0; column < columnCount; column++)
                      _RenderedHtmlTableCell(
                        cell: column < row.children.length
                            ? row.children[column]
                            : null,
                        header: _isHeaderRow(row, rowIndex),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _columnCount(List<BusyBlock> rows) {
    var count = 1;
    for (final row in rows) {
      if (row.children.length > count) {
        count = row.children.length;
      }
    }
    return count;
  }

  bool _isHeaderRow(BusyBlock row, int index) {
    return index == 0 || row.attributes['header'] == 'true';
  }
}

class _RenderedHtmlTableCell extends StatelessWidget {
  const _RenderedHtmlTableCell({required this.cell, required this.header});

  final BusyBlock? cell;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = busyMarkDocumentBodyTextStyle(
      context,
    ).copyWith(fontWeight: header ? FontWeight.w700 : FontWeight.w400);
    return Padding(
      padding: BusyMarkInsets.documentTableCell,
      child: cell == null
          ? const SizedBox.shrink()
          : _RenderedHtmlInlineText(block: cell!, style: style),
    );
  }
}

class _RenderedHtmlInlineText extends StatelessWidget {
  const _RenderedHtmlInlineText({required this.block, this.style});

  final BusyBlock block;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: BusyMarkTypography.bodyLineHeight,
        );
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: [
          for (final inline in block.inlines)
            _spanForInline(context, inline, effectiveStyle),
        ],
      ),
      textDirection: busyMarkWysiwygBlockTextDirection(
        block,
        fallback: Directionality.of(context),
      ),
    );
  }

  InlineSpan _spanForInline(
    BuildContext context,
    BusyInline inline,
    TextStyle? baseStyle,
  ) {
    final colors = BusyMarkSurfaceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final childBaseStyle = _styleForInline(context, inline, baseStyle);
    if (inline.kind == BusyInlineKind.image) {
      final alt = inline.text.trim().isEmpty ? context.l10n.image : inline.text;
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                BusyMarkGlyphs.image,
                size: BusyMarkSizes.iconSm,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: BusyMarkSpacing.xs),
              Text(alt, style: childBaseStyle),
            ],
          ),
        ),
      );
    }
    if (inline.kind == BusyInlineKind.hardBreak) {
      return const TextSpan(text: '\n');
    }
    if (inline.kind == BusyInlineKind.softBreak) {
      return const TextSpan(text: ' ');
    }
    if (inline.children.isNotEmpty) {
      return TextSpan(
        style: childBaseStyle,
        children: [
          for (final child in inline.children)
            _spanForInline(context, child, childBaseStyle),
        ],
      );
    }
    return TextSpan(
      text: inline.text,
      style: inline.kind == BusyInlineKind.link
          ? childBaseStyle?.copyWith(color: scheme.primary)
          : childBaseStyle,
    );
  }

  TextStyle? _styleForInline(
    BuildContext context,
    BusyInline inline,
    TextStyle? baseStyle,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return switch (inline.kind) {
      BusyInlineKind.strong => baseStyle?.copyWith(fontWeight: FontWeight.w700),
      BusyInlineKind.emphasis => baseStyle?.copyWith(
        fontStyle: FontStyle.italic,
      ),
      BusyInlineKind.underline => baseStyle?.copyWith(
        decoration: TextDecoration.underline,
      ),
      BusyInlineKind.strikethrough => baseStyle?.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      BusyInlineKind.code => baseStyle?.copyWith(
        fontFamily: BusyMarkTypography.monoFontFamily,
        fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
        backgroundColor: BusyMarkSurfaceColors.of(context).controlHover,
      ),
      BusyInlineKind.link => baseStyle?.copyWith(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
      _ => baseStyle,
    };
  }
}

String _directionalText(BusyBlock block) {
  return [
    block.plainText,
    for (final child in block.children) _directionalText(child),
  ].join(' ');
}

class _TableBlockEditor extends StatelessWidget {
  const _TableBlockEditor({
    required this.block,
    required this.onFocused,
    required this.onCellChanged,
    required this.onRowInserted,
    required this.onRowDeleted,
    required this.onColumnInserted,
    required this.onColumnDeleted,
    required this.onTableDeleted,
  });

  static const double _controlSize = BusyMarkSizes.tableControl;

  final BusyBlock block;
  final VoidCallback onFocused;
  final void Function(String cellId, String text) onCellChanged;
  final void Function(int rowIndex, {required bool after}) onRowInserted;
  final ValueChanged<int> onRowDeleted;
  final void Function(int columnIndex, {required bool after}) onColumnInserted;
  final ValueChanged<int> onColumnDeleted;
  final VoidCallback onTableDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final rows = block.children;
    final columnCount = _columnCount(rows);
    final dataWidth = (columnCount * BusyMarkSizes.tableColumnBaseWidth)
        .clamp(BusyMarkSizes.tableMinWidth, BusyMarkSizes.tableMaxWidth)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: BusyMarkHeaderIconButton(
            tooltip: context.l10n.deleteTable,
            icon: BusyMarkGlyphs.delete,
            foregroundColor: colors.mutedForeground,
            onPressed: onTableDeleted,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: dataWidth + _controlSize),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: colors.subtleBorder),
                verticalInside: BorderSide(color: colors.subtleBorder),
                top: BorderSide(color: colors.subtleBorder),
                right: BorderSide(color: colors.subtleBorder),
                bottom: BorderSide(color: colors.subtleBorder),
                left: BorderSide(color: colors.subtleBorder),
                borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(_controlSize),
                for (var index = 0; index < columnCount; index++)
                  index + 1: const FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.controlHover),
                  children: [
                    const _TableCornerCell(),
                    for (var column = 0; column < columnCount; column++)
                      _TableColumnControlCell(
                        columnIndex: column,
                        onInserted: onColumnInserted,
                        onDeleted: onColumnDeleted,
                      ),
                  ],
                ),
                for (final (rowIndex, row) in rows.indexed)
                  TableRow(
                    decoration: BoxDecoration(
                      color: _isHeaderRow(row, rowIndex)
                          ? colors.control
                          : BusyMarkLinuxPalette.transparent,
                    ),
                    children: [
                      _TableRowControlCell(
                        rowIndex: rowIndex,
                        onInserted: onRowInserted,
                        onDeleted: onRowDeleted,
                      ),
                      for (var column = 0; column < columnCount; column++)
                        _TableCellEditor(
                          cell: column < row.children.length
                              ? row.children[column]
                              : null,
                          header: _isHeaderRow(row, rowIndex),
                          style: busyMarkDocumentBodyTextStyle(context),
                          onFocused: onFocused,
                          onChanged: onCellChanged,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _columnCount(List<BusyBlock> rows) {
    var count = 1;
    for (final row in rows) {
      if (row.children.length > count) {
        count = row.children.length;
      }
    }
    return count;
  }

  bool _isHeaderRow(BusyBlock row, int index) {
    return index == 0 || row.attributes['header'] == 'true';
  }
}

enum _TableControlAction { insertBefore, insertAfter, delete }

class _TableCornerCell extends StatelessWidget {
  const _TableCornerCell();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(dimension: _TableBlockEditor._controlSize);
  }
}

class _TableColumnControlCell extends StatelessWidget {
  const _TableColumnControlCell({
    required this.columnIndex,
    required this.onInserted,
    required this.onDeleted,
  });

  final int columnIndex;
  final void Function(int columnIndex, {required bool after}) onInserted;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    return _TableControlMenuButton(
      tooltip: context.l10n.tableColumnNumber(columnIndex + 1),
      icon: BusyMarkGlyphs.menuHorizontal,
      beforeLabel: context.l10n.insertColumnLeft,
      afterLabel: context.l10n.insertColumnRight,
      deleteLabel: context.l10n.deleteColumn,
      onSelected: (action) {
        switch (action) {
          case _TableControlAction.insertBefore:
            onInserted(columnIndex, after: false);
          case _TableControlAction.insertAfter:
            onInserted(columnIndex, after: true);
          case _TableControlAction.delete:
            onDeleted(columnIndex);
        }
      },
    );
  }
}

class _TableRowControlCell extends StatelessWidget {
  const _TableRowControlCell({
    required this.rowIndex,
    required this.onInserted,
    required this.onDeleted,
  });

  final int rowIndex;
  final void Function(int rowIndex, {required bool after}) onInserted;
  final ValueChanged<int> onDeleted;

  @override
  Widget build(BuildContext context) {
    return _TableControlMenuButton(
      tooltip: context.l10n.tableRowNumber(rowIndex + 1),
      icon: BusyMarkGlyphs.menuVertical,
      beforeLabel: context.l10n.insertRowAbove,
      afterLabel: context.l10n.insertRowBelow,
      deleteLabel: context.l10n.deleteRow,
      onSelected: (action) {
        switch (action) {
          case _TableControlAction.insertBefore:
            onInserted(rowIndex, after: false);
          case _TableControlAction.insertAfter:
            onInserted(rowIndex, after: true);
          case _TableControlAction.delete:
            onDeleted(rowIndex);
        }
      },
    );
  }
}

class _TableControlMenuButton extends StatelessWidget {
  const _TableControlMenuButton({
    required this.tooltip,
    required this.icon,
    required this.beforeLabel,
    required this.afterLabel,
    required this.deleteLabel,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final String beforeLabel;
  final String afterLabel;
  final String deleteLabel;
  final ValueChanged<_TableControlAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return BusyMarkHeaderPopupMenuButton<_TableControlAction>(
      tooltip: tooltip,
      icon: icon,
      itemBuilder: (context) => [
        BusyMarkPopupMenuItem(
          value: _TableControlAction.insertBefore,
          label: beforeLabel,
        ),
        BusyMarkPopupMenuItem(
          value: _TableControlAction.insertAfter,
          label: afterLabel,
        ),
        BusyMarkPopupMenuItem(
          value: _TableControlAction.delete,
          label: deleteLabel,
        ),
      ],
      onSelected: onSelected,
    );
  }
}

class _TableCellEditor extends StatefulWidget {
  const _TableCellEditor({
    required this.cell,
    required this.header,
    required this.style,
    required this.onFocused,
    required this.onChanged,
  });

  final BusyBlock? cell;
  final bool header;
  final TextStyle style;
  final VoidCallback onFocused;
  final void Function(String cellId, String text) onChanged;

  @override
  State<_TableCellEditor> createState() => _TableCellEditorState();
}

class _TableCellEditorState extends State<_TableCellEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _cellId;

  @override
  void initState() {
    super.initState();
    _cellId = widget.cell?.id;
    _controller = TextEditingController(text: widget.cell?.plainText ?? '');
    _focusNode = FocusNode(debugLabel: 'BusyMark table cell $_cellId');
  }

  @override
  void didUpdateWidget(covariant _TableCellEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cell = widget.cell;
    if (cell?.id != _cellId) {
      _cellId = cell?.id;
      _controller.text = cell?.plainText ?? '';
      return;
    }
    if (!_focusNode.hasFocus &&
        cell != null &&
        cell.plainText != _controller.text) {
      _controller.text = cell.plainText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final cell = widget.cell;
    final textStyle = widget.style.copyWith(
      fontWeight: widget.header ? FontWeight.w700 : FontWeight.w400,
    );
    if (cell == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: BusyMarkInsets.documentTableCell,
      child: TextField(
        key: ValueKey(cell.id),
        controller: _controller,
        focusNode: _focusNode,
        minLines: 1,
        maxLines: null,
        style: textStyle,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hoverColor: BusyMarkLinuxPalette.transparent,
          hintText: widget.header
              ? context.l10n.tableHeaderHint
              : context.l10n.tableCellHint,
          hintStyle: textStyle.copyWith(color: colors.mutedForeground),
          contentPadding: EdgeInsets.zero,
        ),
        onTap: widget.onFocused,
        onChanged: (value) => widget.onChanged(cell.id, value),
      ),
    );
  }
}

class _WysiwygSelectionPainter extends CustomPainter {
  const _WysiwygSelectionPainter({
    required this.text,
    required this.style,
    required this.selectionRange,
    required this.color,
    required this.textDirection,
    required this.textScaler,
    required this.locale,
    required this.layoutWidthInset,
  });

  final String text;
  final TextStyle style;
  final BusyMarkWysiwygSelectionRange? selectionRange;
  final Color color;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final double layoutWidthInset;

  @override
  void paint(Canvas canvas, Size size) {
    final range = selectionRange;
    if (range == null || text.isEmpty || size.width <= 0) {
      return;
    }
    final start = range.start.clamp(0, text.length).toInt();
    final end = range.end.clamp(0, text.length).toInt();
    if (end <= start) {
      return;
    }
    final maxWidth = size.width - layoutWidthInset;
    if (maxWidth <= 0) {
      return;
    }
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout(maxWidth: maxWidth);
    final boxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
      boxHeightStyle: BusyMarkDocumentTextGeometry.selectionHeightStyle,
      boxWidthStyle: BusyMarkDocumentTextGeometry.selectionWidthStyle,
    );
    final paint = Paint()..color = color;
    for (final box in boxes) {
      canvas.drawRect(box.toRect(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WysiwygSelectionPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.selectionRange?.start != selectionRange?.start ||
        oldDelegate.selectionRange?.end != selectionRange?.end ||
        oldDelegate.color != color ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.locale != locale ||
        oldDelegate.layoutWidthInset != layoutWidthInset;
  }
}

class _ImageBlockEditor extends StatelessWidget {
  const _ImageBlockEditor({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.allowRemoteImages,
    required this.onRemoteImageBlocked,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final bool allowRemoteImages;
  final VoidCallback? onRemoteImageBlocked;

  @override
  Widget build(BuildContext context) {
    final source = _imageSource(block);
    final width = busyMarkDocumentImageWidth(block.attributes);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MarkdownImageView(
        source: source,
        alt: block.plainText,
        activeFilePath: documentFilePath,
        workspaceRoot: workspaceRoot,
        writersideRoot: writersideRoot,
        imagesDir: imagesDir,
        allowRemoteImages: allowRemoteImages,
        onRemoteImageBlocked: onRemoteImageBlocked,
        width: width,
        maxWidth: width ?? BusyMarkSizes.documentImageMaxWidth,
      ),
    );
  }
}

String _imageSource(BusyBlock block) {
  final attributeSource = block.attributes['src'];
  if (attributeSource != null && attributeSource.trim().isNotEmpty) {
    return attributeSource.trim();
  }
  for (final inline in block.inlines) {
    final source = _imageSourceFromInline(inline);
    if (source != null) {
      return source;
    }
  }
  return '';
}

String? _imageSourceFromInline(BusyInline inline) {
  if (inline.kind == BusyInlineKind.image &&
      inline.destination != null &&
      inline.destination!.trim().isNotEmpty) {
    return inline.destination!.trim();
  }
  for (final child in inline.children) {
    final source = _imageSourceFromInline(child);
    if (source != null) {
      return source;
    }
  }
  return null;
}
