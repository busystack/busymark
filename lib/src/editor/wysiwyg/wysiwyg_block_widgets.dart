import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/busymark_design.dart';
import '../../core/local_image_resolver.dart';
import '../../markdown/busymark_document.dart';
import 'wysiwyg_inline_controller.dart';

class BusyMarkWysiwygBlockField extends StatelessWidget {
  const BusyMarkWysiwygBlockField({
    super.key,
    required this.block,
    required this.documentFilePath,
    this.workspaceRoot,
    this.writersideRoot,
    this.imagesDir = 'images',
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onFocused,
    this.selected = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final BusyMarkWysiwygTextController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocused;
  final bool selected;
  final ValueChanged<PointerDownEvent>? onPointerDown;
  final ValueChanged<PointerMoveEvent>? onPointerMove;
  final ValueChanged<PointerUpEvent>? onPointerUp;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final style = _textStyle(context);
    final prefix = _prefix(context);
    final readOnly = _readOnly;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      child: Padding(
        padding: _padding,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: readOnly ? null : _focusBlock,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _background(context),
              borderRadius: BorderRadius.circular(BusyMarkRadius.md),
              border: _border(context),
            ),
            child: Padding(
              padding: _contentPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: _minimumHeight(context)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prefix != null) ...[
                      SizedBox(width: 30, child: prefix),
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
                              controller: controller,
                              focusNode: focusNode,
                              style: style,
                              onFocused: onFocused,
                              onChanged: onChanged,
                            )
                          : readOnly
                          ? SelectableText(
                              block.rawSource ?? block.plainText,
                              style: style.copyWith(
                                color: colors.mutedForeground,
                                fontFamily: 'Ubuntu Mono',
                              ),
                            )
                          : TextField(
                              controller: controller,
                              focusNode: focusNode,
                              maxLines: null,
                              minLines: 1,
                              style: style,
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hoverColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: onFocused,
                              onChanged: onChanged,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

  double _minimumHeight(BuildContext context) {
    final style = _textStyle(context);
    final fontSize =
        style.fontSize ??
        Theme.of(context).textTheme.bodyMedium?.fontSize ??
        14;
    return switch (block.kind) {
      BusyBlockKind.heading => fontSize * 1.8,
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => fontSize * 2.4,
      _ => fontSize * 1.7,
    };
  }

  bool get _readOnly {
    return block.preserveRaw ||
        block.kind == BusyBlockKind.thematicBreak ||
        block.kind == BusyBlockKind.table;
  }

  EdgeInsets get _padding {
    return switch (block.kind) {
      BusyBlockKind.heading => const EdgeInsets.only(top: 16, bottom: 6),
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.symmetric(vertical: 8),
      _ => const EdgeInsets.symmetric(vertical: 4),
    };
  }

  EdgeInsets get _contentPadding {
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => const EdgeInsets.all(12),
      _ => EdgeInsets.zero,
    };
  }

  TextStyle _textStyle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final level = int.tryParse(block.attributes['level'] ?? '') ?? 0;
    return switch (block.kind) {
      BusyBlockKind.heading when level == 1 => theme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading when level == 2 => theme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.heading => theme.titleMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      BusyBlockKind.codeBlock => theme.bodyMedium!.copyWith(
        fontFamily: 'Ubuntu Mono',
        height: 1.45,
      ),
      _ => theme.bodyMedium!.copyWith(height: 1.5),
    };
  }

  Widget? _prefix(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final markerStyle = _textStyle(context).copyWith(
      color: colors.mutedForeground,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return switch (block.kind) {
      BusyBlockKind.unorderedListItem => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Icon(Icons.circle, size: 6, color: colors.mutedForeground),
      ),
      BusyBlockKind.orderedListItem => Text(
        block.attributes['marker'] ?? '1.',
        textAlign: TextAlign.right,
        style: markerStyle,
      ),
      BusyBlockKind.taskListItem => Icon(
        block.attributes['task'] == 'true'
            ? Icons.check_box_outlined
            : Icons.check_box_outline_blank,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.image => Icon(
        Icons.image_outlined,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.blockquote => Icon(
        Icons.format_quote_outlined,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.codeBlock => Icon(
        Icons.code,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.writersideAdmonition => Icon(
        Icons.info_outline,
        size: BusyMarkSizes.iconSm,
        color: colors.mutedForeground,
      ),
      BusyBlockKind.thematicBreak => Divider(
        height: 20,
        color: colors.subtleBorder,
      ),
      _ => null,
    };
  }

  Color _background(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    if (selected) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.20);
    }
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
      BusyBlockKind.writersideAdmonition ||
      BusyBlockKind.writersideTabs ||
      BusyBlockKind.writersideProcedure ||
      BusyBlockKind.writersideRawXml ||
      BusyBlockKind.table ||
      BusyBlockKind.htmlBlock ||
      BusyBlockKind.unknown => colors.panel,
      _ => Colors.transparent,
    };
  }

  BoxBorder? _border(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return switch (block.kind) {
      BusyBlockKind.codeBlock ||
      BusyBlockKind.blockquote ||
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

class _ImageBlockEditor extends StatelessWidget {
  const _ImageBlockEditor({
    required this.block,
    required this.documentFilePath,
    required this.workspaceRoot,
    required this.writersideRoot,
    required this.imagesDir,
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.onFocused,
    required this.onChanged,
  });

  final BusyBlock block;
  final String documentFilePath;
  final String? workspaceRoot;
  final String? writersideRoot;
  final String imagesDir;
  final BusyMarkWysiwygTextController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final VoidCallback onFocused;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final source = _imageSource(block);
    final file = _resolveLocalImageFile(
      source,
      documentFilePath,
      workspaceRoot: workspaceRoot,
      writersideRoot: writersideRoot,
      imagesDir: imagesDir,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            border: Border.all(color: colors.subtleBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            child: _LocalImagePreview(file: file, source: source),
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          minLines: 1,
          style: style,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hoverColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            hintText: 'Alt text',
            hintStyle: style.copyWith(color: colors.mutedForeground),
          ),
          onTap: onFocused,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _LocalImagePreview extends StatelessWidget {
  const _LocalImagePreview({required this.file, required this.source});

  final File? file;
  final String source;

  @override
  Widget build(BuildContext context) {
    if (file == null || !file!.existsSync()) {
      return _ImagePlaceholder(source: source);
    }
    return Image.file(
      file!,
      height: 240,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) =>
          _ImagePlaceholder(source: source),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: BusyMarkSizes.iconMd,
              color: colors.mutedForeground,
            ),
            const SizedBox(height: BusyMarkSpacing.xs),
            Text(
              source.isEmpty ? 'No image source' : source,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
          ],
        ),
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
    if (inline.kind == BusyInlineKind.image &&
        inline.destination != null &&
        inline.destination!.trim().isNotEmpty) {
      return inline.destination!.trim();
    }
  }
  return '';
}

File? _resolveLocalImageFile(
  String source,
  String documentFilePath, {
  required String? workspaceRoot,
  required String? writersideRoot,
  required String imagesDir,
}) {
  if (source.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(source);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme == 'file') {
      return File.fromUri(uri);
    }
    return null;
  }
  final pathWithoutFragment = source.split('#').first.split('?').first.trim();
  if (pathWithoutFragment.isEmpty ||
      p.extension(pathWithoutFragment).toLowerCase() == '.svg') {
    return null;
  }
  final resolvedPath = resolveLocalImagePath(
    activeFilePath: documentFilePath,
    destination: source,
    workspaceRoot: workspaceRoot,
    writersideRoot: writersideRoot,
    imagesDir: imagesDir,
  );
  return resolvedPath == null ? null : File(resolvedPath);
}
