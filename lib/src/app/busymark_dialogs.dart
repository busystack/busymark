import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/linux_header_bar_service.dart';
import 'app_metadata.dart';
import 'busymark_dialog_identity.dart';
import 'busymark_shortcuts.dart';
import 'command_registry.dart';
import 'busymark_design.dart';
import 'busymark_glyphs.dart';
import 'localization.dart';

const _busyMarkWebsiteUrl = 'https://busystack.org';
const _busyMarkRepositoryUrl = 'https://github.com/busystack/busymark/';
const _apacheLicenseUrl = 'https://www.apache.org/licenses/LICENSE-2.0';
const _commonMarkDocumentationUrl = 'https://spec.commonmark.org/current/';
const _githubMarkdownDocumentationUrl = 'https://github.github.com/gfm/';
const _htmlDocumentationUrl = 'https://html.spec.whatwg.org/multipage/';
const _mermaidDocumentationUrl =
    'https://mermaid.js.org/intro/syntax-reference.html';
const _plantUmlDocumentationUrl = 'https://plantuml.com/guide';
const _d2DocumentationUrl = 'https://d2lang.com/tour/intro/';
const _openApiDocumentationUrl = 'https://spec.openapis.org/oas/latest.html';
const _writersideAdmonitionDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/admonitions.html';
const _writersideCollapsibleDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/collapsible-elements.html';
const _writersideMathDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/math-support.html';
const _writersideMermaidDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/mermaid-diagrams.html';
const _writersideVideoDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/videos.html';
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
final _busyMarkRepositoryUri = Uri.parse(_busyMarkRepositoryUrl);
final _apacheLicenseUri = Uri.parse(_apacheLicenseUrl);
final _commonMarkDocumentationUri = Uri.parse(_commonMarkDocumentationUrl);
final _githubMarkdownDocumentationUri = Uri.parse(
  _githubMarkdownDocumentationUrl,
);
final _htmlDocumentationUri = Uri.parse(_htmlDocumentationUrl);
final _mermaidDocumentationUri = Uri.parse(_mermaidDocumentationUrl);
final _plantUmlDocumentationUri = Uri.parse(_plantUmlDocumentationUrl);
final _d2DocumentationUri = Uri.parse(_d2DocumentationUrl);
final _openApiDocumentationUri = Uri.parse(_openApiDocumentationUrl);
final _writersideAdmonitionDocumentationUri = Uri.parse(
  _writersideAdmonitionDocumentationUrl,
);
final _writersideCollapsibleDocumentationUri = Uri.parse(
  _writersideCollapsibleDocumentationUrl,
);
final _writersideMathDocumentationUri = Uri.parse(
  _writersideMathDocumentationUrl,
);
final _writersideMermaidDocumentationUri = Uri.parse(
  _writersideMermaidDocumentationUrl,
);
final _writersideVideoDocumentationUri = Uri.parse(
  _writersideVideoDocumentationUrl,
);

class _DismissBusyMarkModalIntent extends Intent {
  const _DismissBusyMarkModalIntent();
}

final _busyMarkModalShortcuts = <ShortcutActivator, Intent>{
  for (final command in BusyMarkCommandCatalog.metadata.commands)
    if (command.shortcut != null &&
        command.id != BusyMarkCommandIds.textPastePlainText &&
        command.scope != BusyMarkCommandScope.tree &&
        command.scope != BusyMarkCommandScope.textEditing)
      command.shortcut!.activator: const DoNothingAndStopPropagationIntent(),
  BusyMarkCommandCatalog
          .metadata[BusyMarkCommandIds.textEscape]!
          .shortcut!
          .activator:
      const _DismissBusyMarkModalIntent(),
};

/// Prevents application and workspace shortcuts from escaping a modal surface.
///
/// Use this around modal UI that is not presented by
/// [showBusyMarkModalDialog], such as an in-page editor overlay.
class BusyMarkModalShortcutBoundary extends StatelessWidget {
  const BusyMarkModalShortcutBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _busyMarkModalShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DismissBusyMarkModalIntent:
              CallbackAction<_DismissBusyMarkModalIntent>(
                onInvoke: (_) {
                  unawaited(Navigator.maybePop(context));
                  return null;
                },
              ),
        },
        child: child,
      ),
    );
  }
}

final _busyMarkModalDepths = Map<LinuxHeaderBarService, int>.identity();
final _busyMarkModalBarrierUpdateTails =
    Map<LinuxHeaderBarService, Future<void>>.identity();

Color busyMarkModalBarrierColor(BuildContext context) {
  return BusyMarkSurfaceColors.of(context).shade;
}

Future<T?> showBusyMarkModalDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  LinuxHeaderBarService? headerBarService,
  Color? barrierColor,
  bool barrierDismissible = true,
}) async {
  final effectiveHeaderBarService =
      headerBarService ?? _busyMarkHeaderBarServiceFrom(context);
  return _coordinateBusyMarkModal<T>(
    context,
    headerBarService: effectiveHeaderBarService,
    showSurface: () => _showBusyMarkFlutterDialog<T>(
      context,
      builder: builder,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
    ),
  );
}

Future<T?> _coordinateBusyMarkModal<T>(
  BuildContext context, {
  required LinuxHeaderBarService? headerBarService,
  required Future<T?> Function() showSurface,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  await acquireBusyMarkModalBarrier(headerBarService);
  if (!context.mounted) {
    await releaseBusyMarkModalBarrier(headerBarService);
    return null;
  }
  try {
    return await showSurface();
  } finally {
    await releaseBusyMarkModalBarrier(headerBarService);
    if (previousFocus?.context != null && previousFocus!.canRequestFocus) {
      previousFocus.requestFocus();
    }
  }
}

Future<T?> _showBusyMarkFlutterDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? barrierColor,
  bool barrierDismissible = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _BusyMarkDialogRoute<T>(
      context: context,
      builder: builder,
      themes: themes,
      fixedBarrierColor: barrierColor,
      initialBarrierColor: barrierColor ?? busyMarkModalBarrierColor(context),
      barrierDismissible: barrierDismissible,
    ),
  );
}

class _BusyMarkDialogRoute<T> extends DialogRoute<T> {
  _BusyMarkDialogRoute({
    required super.context,
    required WidgetBuilder builder,
    required CapturedThemes themes,
    required Color? fixedBarrierColor,
    required Color initialBarrierColor,
    required super.barrierDismissible,
  }) : _fixedBarrierColor = fixedBarrierColor,
       _initialBarrierColor = initialBarrierColor,
       super(
         builder: (dialogContext) =>
             BusyMarkModalShortcutBoundary(child: builder(dialogContext)),
         themes: themes,
         barrierColor: initialBarrierColor,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );

  final Color? _fixedBarrierColor;
  final Color _initialBarrierColor;

  /// Unlike [DialogRoute]'s constructor value, this getter is reevaluated
  /// when the Navigator's inherited theme changes.
  @override
  Color? get barrierColor {
    final fixedColor = _fixedBarrierColor;
    if (fixedColor != null) {
      return fixedColor;
    }
    final navigatorContext = navigator?.context;
    return navigatorContext == null
        ? _initialBarrierColor
        : busyMarkModalBarrierColor(navigatorContext);
  }
}

Future<T?> showBusyMarkModalEditorDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  LinuxHeaderBarService? headerBarService,
  double maxWidth = 700,
  double? maxHeight = 760,
}) {
  return showBusyMarkModalDialog<T>(
    context,
    headerBarService: headerBarService,
    barrierDismissible: false,
    builder: (dialogContext) => BusyMarkModalEditorSurface(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      insetPadding: const EdgeInsets.all(BusyMarkSpacing.lg),
      child: builder(dialogContext),
    ),
  );
}

/// Acquires a reference-counted native header-bar modal barrier.
///
/// Every call must be paired with [releaseBusyMarkModalBarrier]. Route
/// dialogs acquire it automatically.
Future<void> acquireBusyMarkModalBarrier(LinuxHeaderBarService? service) async {
  if (service == null) {
    return;
  }
  final depth = _busyMarkModalDepths[service] ?? 0;
  final nextDepth = depth + 1;
  _busyMarkModalDepths[service] = nextDepth;
  final depthUpdate = _enqueueBusyMarkModalBarrierUpdate(
    service,
    depth: nextDepth,
  );
  try {
    await depthUpdate;
  } on Object catch (error, stackTrace) {
    final remainingDepth = (_busyMarkModalDepths[service] ?? 0) - 1;
    if (remainingDepth > 0) {
      _busyMarkModalDepths[service] = remainingDepth;
    } else {
      _busyMarkModalDepths.remove(service);
      try {
        await _enqueueBusyMarkModalBarrierUpdate(service, depth: 0);
      } on Object {
        // Preserve the acquisition failure if its best-effort rollback fails.
      }
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

/// Releases a barrier acquired by [acquireBusyMarkModalBarrier].
Future<void> releaseBusyMarkModalBarrier(LinuxHeaderBarService? service) async {
  if (service == null) {
    return;
  }
  final depth = _busyMarkModalDepths[service] ?? 0;
  if (depth <= 1) {
    _busyMarkModalDepths.remove(service);
    await _enqueueBusyMarkModalBarrierUpdate(service, depth: 0);
    return;
  }
  final nextDepth = depth - 1;
  _busyMarkModalDepths[service] = nextDepth;
  await _enqueueBusyMarkModalBarrierUpdate(service, depth: nextDepth);
}

Future<void> _enqueueBusyMarkModalBarrierUpdate(
  LinuxHeaderBarService service, {
  required int depth,
}) {
  final previous =
      _busyMarkModalBarrierUpdateTails[service] ?? Future<void>.value();
  final ready = previous.then<void>(
    (_) {},
    onError: (Object _, StackTrace _) {},
  );
  late final Future<void> update;
  update = ready.then((_) => service.setModalBarrierDepth(depth)).whenComplete(
    () {
      if (identical(_busyMarkModalBarrierUpdateTails[service], update)) {
        _busyMarkModalBarrierUpdateTails.remove(service);
      }
    },
  );
  _busyMarkModalBarrierUpdateTails[service] = update;
  return update;
}

LinuxHeaderBarService? _busyMarkHeaderBarServiceFrom(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(linuxHeaderBarServiceProvider);
  } on StateError {
    // Standalone widget hosts may not install Riverpod. Explicit injection
    // remains available for those hosts.
    return null;
  }
}

class BusyMarkModalEditorSurface extends StatelessWidget {
  const BusyMarkModalEditorSurface({
    super.key,
    required this.child,
    this.minWidth = 0,
    this.maxWidth = 700,
    this.maxHeight,
    this.insetPadding = EdgeInsets.zero,
  });

  final Widget child;
  final double minWidth;
  final double maxWidth;
  final double? maxHeight;
  final EdgeInsets insetPadding;

  @override
  Widget build(BuildContext context) {
    final editorSurface = Theme.of(context).scaffoldBackgroundColor;
    final effectiveMaxWidth = maxWidth.isFinite
        ? maxWidth.clamp(0.0, double.infinity).toDouble()
        : maxWidth;
    final effectiveMinWidth = minWidth
        .clamp(
          0.0,
          effectiveMaxWidth.isFinite ? effectiveMaxWidth : double.infinity,
        )
        .toDouble();
    final effectiveMaxHeight = maxHeight == null
        ? double.infinity
        : maxHeight!.clamp(0.0, double.infinity).toDouble();

    return BusyMarkSurfaceScope(
      role: BusyMarkSurfaceRole.window,
      child: Dialog(
        backgroundColor: editorSurface,
        surfaceTintColor: editorSurface,
        insetPadding: insetPadding,
        insetAnimationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : BusyMarkMotion.dialogInsets,
        insetAnimationCurve: BusyMarkMotion.dialogInsetsCurve,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: effectiveMinWidth,
            maxWidth: effectiveMaxWidth,
            maxHeight: effectiveMaxHeight,
          ),
          child: child,
        ),
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

Future<void> _openBusyMarkWebsite() async {
  await launchUrl(_busyMarkWebsiteUri, mode: LaunchMode.externalApplication);
}

Future<void> _openBusyMarkRepository() async {
  await launchUrl(_busyMarkRepositoryUri, mode: LaunchMode.externalApplication);
}

Future<void> _openApacheLicense() async {
  await launchUrl(_apacheLicenseUri, mode: LaunchMode.externalApplication);
}

void showBusyMarkKeyboardShortcutsDialog(BuildContext context) {
  final registry =
      BusyMarkCommandRegistryScope.maybeOf(context) ??
      BusyMarkCommandCatalog.metadata;
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) {
        final grouped = <String, List<BusyMarkCommand>>{};
        final shortcutLabels = <String>{};
        for (final command in registry.commands) {
          final shortcut = command.shortcut;
          if (shortcut == null || !shortcutLabels.add(shortcut.label)) {
            continue;
          }
          grouped.putIfAbsent(command.category(context), () => []).add(command);
        }
        return _BusyMarkInfoDialog(
          title: context.l10n.keyboardShortcuts,
          icon: BusyMarkGlyphs.keyboard,
          maxWidth: 460,
          children: [
            for (final entry in grouped.entries)
              BusyMarkGroupedList(
                title: entry.key,
                filled: true,
                children: [
                  for (final command in entry.value)
                    BusyMarkActionRow(
                      title: command.label(context),
                      subtitle: command.description?.call(context),
                      leading: const Icon(BusyMarkGlyphs.keyboard),
                      trailing: _KeyboardShortcutBadge(command.shortcut!.label),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}

// Retained temporarily as a layout reference while every shortcut consumer is
// migrated to the registry-backed presentation above.
void showLegacyBusyMarkKeyboardShortcutsDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => _BusyMarkInfoDialog(
        title: context.l10n.keyboardShortcuts,
        icon: BusyMarkGlyphs.keyboard,
        maxWidth: 460,
        children: [
          BusyMarkGroupedList(
            title: context.l10n.shortcutGroupGeneral,
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
                title: context.l10n.exportAsPdf,
                subtitle: context.l10n.shortcutExportPdfDescription,
                leading: const Icon(BusyMarkGlyphs.exportPdf),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.exportPdf,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.fullScreen,
                leading: const Icon(BusyMarkGlyphs.fullScreen),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.fullScreen,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.back,
                leading: Icon(
                  BusyMarkGlyphs.backFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.back,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.search,
                subtitle: context.l10n.shortcutSearchDescription,
                leading: const Icon(BusyMarkGlyphs.search),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.search,
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
                title: context.l10n.syntaxReference,
                subtitle: context.l10n.shortcutSyntaxReferenceDescription,
                leading: const Icon(BusyMarkGlyphs.markdownFile),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkAppShortcutLabels.syntaxReference,
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
            title: context.l10n.viewMode,
            filled: true,
            children: [
              BusyMarkActionRow(
                title: context.l10n.editor,
                leading: const Icon(BusyMarkGlyphs.editorView),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkDocumentViewShortcutLabels.editor,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.source,
                leading: const Icon(BusyMarkGlyphs.sourceView),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkDocumentViewShortcutLabels.source,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.reading,
                leading: const Icon(BusyMarkGlyphs.previewView),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkDocumentViewShortcutLabels.reading,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.split,
                leading: const Icon(BusyMarkGlyphs.splitView),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkDocumentViewShortcutLabels.split,
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
                leading: Icon(
                  BusyMarkGlyphs.undoFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.undo,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.redo,
                subtitle: context.l10n.shortcutRedoDescription,
                leading: Icon(
                  BusyMarkGlyphs.redoFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.redo,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutInsertIndentation,
                subtitle: context.l10n.shortcutInsertIndentationDescription,
                leading: Icon(
                  BusyMarkGlyphs.indentFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.insertIndentation,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutOutdentSource,
                subtitle: context.l10n.shortcutOutdentSourceDescription,
                leading: Icon(
                  BusyMarkGlyphs.outdentFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.outdentSource,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.shortcutEscape,
                subtitle: context.l10n.shortcutEscapeDescription,
                leading: const Icon(BusyMarkGlyphs.clear),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTextEditingShortcutLabels.escape,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.aiRefineWithAi,
                leading: const Icon(BusyMarkGlyphs.ai),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.refineWithAi,
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
                title: context.l10n.indentListItem,
                leading: Icon(
                  BusyMarkGlyphs.indentFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkEditorShortcutLabels.indent,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.outdentListItem,
                leading: Icon(
                  BusyMarkGlyphs.outdentFor(Directionality.of(context)),
                ),
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
                leading: Icon(
                  BusyMarkGlyphs.indentFor(Directionality.of(context)),
                ),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.outline,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.git,
                leading: const Icon(BusyMarkGlyphs.branch),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkSidebarShortcutLabels.git,
                ),
              ),
              BusyMarkActionRow(
                title: context.l10n.delete,
                subtitle: context.l10n.shortcutDeleteTreeItemDescription,
                leading: const Icon(BusyMarkGlyphs.delete),
                trailing: const _KeyboardShortcutBadge(
                  BusyMarkTreeShortcutLabels.deleteSelection,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showBusyMarkSyntaxReferenceDialog(BuildContext context) {
  final headerBar = LinuxHeaderBarService.instance;
  unawaited(
    showBusyMarkModalDialog<void>(
      context,
      headerBarService: headerBar.isAvailable ? headerBar : null,
      builder: (context) => const _SyntaxReferenceDialog(),
    ),
  );
}

enum _SyntaxReferenceCategory {
  markdown,
  html,
  diagramsAndApi,
  mathematics,
  writerside,
}

class _SyntaxReferenceDialog extends StatefulWidget {
  const _SyntaxReferenceDialog();

  @override
  State<_SyntaxReferenceDialog> createState() => _SyntaxReferenceDialogState();
}

class _SyntaxReferenceDialogState extends State<_SyntaxReferenceDialog> {
  final _scrollController = ScrollController();
  var _category = _SyntaxReferenceCategory.markdown;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BusyMarkInformationalDialog(
      key: const ValueKey('syntax-reference-dialog'),
      closeLabel: context.l10n.close,
      maxWidth: BusyMarkSizes.dialogWide,
      maxHeight: 680,
      scrollable: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          BusyMarkSpacing.lg,
          BusyMarkSpacing.md,
          BusyMarkSpacing.lg,
          BusyMarkSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  BusyMarkGlyphs.markdownFile,
                  size: BusyMarkSizes.iconButton,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: BusyMarkSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.syntaxReference,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            InputDecorator(
              decoration: InputDecoration(
                labelText: context.l10n.syntaxReferenceCategory,
                prefixIcon: const Icon(BusyMarkGlyphs.category),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_SyntaxReferenceCategory>(
                  key: const ValueKey('syntax-reference-category-selector'),
                  value: _category,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    for (final category in _SyntaxReferenceCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(_categoryLabel(context, category)),
                      ),
                  ],
                  onChanged: (category) {
                    if (category == null || category == _category) {
                      return;
                    }
                    setState(() => _category = category);
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.md),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  key: ValueKey('syntax-reference-category-${_category.name}'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _categoryContent(context, _category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(
    BuildContext context,
    _SyntaxReferenceCategory category,
  ) => switch (category) {
    _SyntaxReferenceCategory.markdown => context.l10n.markdown,
    _SyntaxReferenceCategory.html => context.l10n.syntaxReferenceCategoryHtml,
    _SyntaxReferenceCategory.diagramsAndApi =>
      context.l10n.syntaxReferenceCategoryDiagramsAndApi,
    _SyntaxReferenceCategory.mathematics =>
      context.l10n.syntaxReferenceCategoryMathematics,
    _SyntaxReferenceCategory.writerside => context.l10n.writerside,
  };

  Widget _categoryContent(
    BuildContext context,
    _SyntaxReferenceCategory category,
  ) => switch (category) {
    _SyntaxReferenceCategory.markdown => _markdownReference(context),
    _SyntaxReferenceCategory.html => _htmlReference(context),
    _SyntaxReferenceCategory.diagramsAndApi => _diagramsAndApiReference(
      context,
    ),
    _SyntaxReferenceCategory.mathematics => _mathematicsReference(context),
    _SyntaxReferenceCategory.writerside => _writersideReference(context),
  };

  Widget _markdownReference(BuildContext context) {
    final l10n = context.l10n;
    final scope = l10n.syntaxReferenceScopeMarkdownAndWritersideMarkdown;
    return _SyntaxReferenceCategoryContent(
      description: l10n.syntaxReferenceMarkdownDescription,
      entries: [
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHeadings,
          example: '# Heading',
          identifiers: '#, ##, ###, ####, #####, ######',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceParagraphs,
          example: l10n.syntaxReferenceParagraphExample,
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.blockquote,
          example: '> Quoted text',
          identifiers: '>',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.codeBlock,
          example: '```dart\nprint("Hello");\n```',
          identifiers: '```, ~~~',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceLists,
          example: '- Item\n1. First',
          identifiers: '-, *, +, 1., 1)',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.checklist,
          example: '- [ ] Draft\n- [x] Published',
          identifiers: '- [ ], - [x], - [X]',
          scope: scope,
          documentationUri: _githubMarkdownDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.table,
          example: '| Name | Value |\n| --- | --- |\n| A | 1 |',
          identifiers: '| --- |',
          scope: scope,
          limitation: l10n.syntaxReferenceTableLimitation,
          documentationUri: _githubMarkdownDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.link,
          example: '[BusyMark](https://busystack.org)',
          identifiers: '[text](url), [text][label]',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.image,
          example: '![Alternative text](image.png)',
          identifiers: '![alt](src), ![alt][label]',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceInlineFormatting,
          example: '**bold** *italic* ~~removed~~ `code`',
          identifiers: '**, __, *, _, ~~, `',
          scope: scope,
          documentationUri: _githubMarkdownDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.thematicBreak,
          example: '---',
          identifiers: '---, ***, ___',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.hardLineBreak,
          example: 'First line  \nSecond line',
          identifiers: l10n.syntaxReferenceHardBreakIdentifiers,
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
      ],
    );
  }

  Widget _htmlReference(BuildContext context) {
    final l10n = context.l10n;
    return _SyntaxReferenceCategoryContent(
      description: l10n.syntaxReferenceHtmlDescription,
      entries: [
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceRawHtmlBlocks,
          example: '<section>\n  <p>Text</p>\n</section>',
          identifiers: _supportedRawHtmlBlockTags,
          scope: l10n.syntaxReferenceScopeMarkdownAndWritersideMarkdown,
          limitation: l10n.syntaxReferenceMarkdownInsideHtmlDescription,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceRawHtmlInline,
          example: '<strong>Important</strong>',
          identifiers: _supportedRawHtmlInlineTags,
          scope: l10n.syntaxReferenceScopeMarkdownAndWritersideMarkdown,
          documentationUri: _htmlDocumentationUri,
        ),
      ],
      footer: BusyMarkGroupedList(
        title: l10n.syntaxReferenceSafety,
        description: l10n.syntaxReferenceSafetyDescription,
        filled: true,
        children: [
          BusyMarkActionRow(
            title: l10n.syntaxReferenceSanitizedPreview,
            subtitle: l10n.syntaxReferenceSanitizedPreviewDescription,
            leading: const Icon(BusyMarkGlyphs.check),
          ),
          BusyMarkActionRow(
            title: l10n.syntaxReferenceSourcePreserved,
            subtitle: l10n.syntaxReferenceSourcePreservedDescription,
            leading: const Icon(BusyMarkGlyphs.document),
          ),
          BusyMarkActionRow(
            title: l10n.syntaxReferenceMarkdownInsideHtml,
            subtitle: l10n.syntaxReferenceMarkdownInsideHtmlDescription,
            leading: const Icon(BusyMarkGlyphs.markdownFile),
          ),
          BusyMarkActionRow(
            title: l10n.syntaxReferenceBlockedContent,
            subtitle: l10n.syntaxReferenceBlockedContentDescription,
            leading: const Icon(BusyMarkGlyphs.warning),
          ),
          BusyMarkActionRow(
            title: l10n.syntaxReferenceSafeUrls,
            subtitle: l10n.syntaxReferenceSafeUrlsDescription,
            leading: const Icon(BusyMarkGlyphs.link),
          ),
        ],
      ),
    );
  }

  Widget _diagramsAndApiReference(BuildContext context) {
    final l10n = context.l10n;
    final scope = l10n.syntaxReferenceScopeMarkdownAndWritersideMarkdown;
    return _SyntaxReferenceCategoryContent(
      description: l10n.syntaxReferenceDiagramsDescription,
      entries: [
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceMermaid,
          example: '```mermaid\nflowchart LR\n  A --> B\n```',
          identifiers: 'mermaid',
          scope: scope,
          documentationUri: _mermaidDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferencePlantUml,
          example: '```plantuml\n@startuml\nAlice -> Bob: Hello\n@enduml\n```',
          identifiers: 'plantuml, puml',
          scope: scope,
          documentationUri: _plantUmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceD2,
          example: '```d2\nclient -> server\n```',
          identifiers: 'd2',
          scope: scope,
          documentationUri: _d2DocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceOpenApi,
          example:
              '```openapi\nopenapi: 3.0.3\ninfo:\n  title: Sample API\n'
              '  version: 1.0.0\npaths: {}\n```',
          identifiers: 'openapi, oas, swagger',
          scope: scope,
          limitation: l10n.syntaxReferenceOpenApiLimitation,
          documentationUri: _openApiDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceSemanticDiagramBlocks,
          example:
              '<code-block lang="mermaid">flowchart LR\n'
              '  A --&gt; B</code-block>',
          identifiers: 'mermaid, plantuml, puml, d2',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceSemanticDiagramLimitation,
          documentationUri: _writersideMermaidDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceReferencedDiagramSource,
          example:
              '<code-block lang="d2" src="../codeSnippets/graph.d2"/>\n\n'
              '```mermaid\n```\n{src="../codeSnippets/flow.mmd"}',
          identifiers: 'src',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceReferencedDiagramLimitation,
          documentationUri: _writersideMermaidDocumentationUri,
        ),
      ],
    );
  }

  Widget _mathematicsReference(BuildContext context) {
    final l10n = context.l10n;
    final markdownScope =
        l10n.syntaxReferenceScopeMarkdownAndWritersideMarkdown;
    return _SyntaxReferenceCategoryContent(
      description: l10n.syntaxReferenceMathematicsDescription,
      entries: [
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceInlineMath,
          example: r'Euler: $e^{i\pi}+1=0$',
          identifiers: r'$...$',
          scope: markdownScope,
          limitation: l10n.syntaxReferenceMathDelimitersLimitation,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceGithubMath,
          example: r'The value is $`\sqrt{x^2+y^2}`$.',
          identifiers: r'$`...`$',
          scope: markdownScope,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceDisplayMath,
          example: r'''$$
\int_0^1 x^2\,dx = \frac{1}{3}
$$''',
          identifiers: r'$$...$$',
          scope: markdownScope,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceMathFence,
          example: '```math\nE = mc^2\n```',
          identifiers: 'math',
          scope: markdownScope,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceTexFence,
          example: '```tex\n\\sum_{i=1}^n i\n```',
          identifiers: 'tex',
          scope: l10n.syntaxReferenceScopeWritersideMarkdown,
          limitation: l10n.syntaxReferenceTexFenceLimitation,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceWritersideMathElement,
          example: r'The domain is <math>\mathbb{R}</math>.',
          identifiers: '<math>...</math>',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceWritersideMathElementLimitation,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceSemanticTexBlock,
          example:
              '<code-block lang="tex">\n'
              '<![CDATA[\\sum_{i=1}^n i < n^2]]>\n'
              '</code-block>',
          identifiers: 'tex',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          documentationUri: _writersideMathDocumentationUri,
        ),
      ],
    );
  }

  Widget _writersideReference(BuildContext context) {
    final l10n = context.l10n;
    return _SyntaxReferenceCategoryContent(
      description: l10n.syntaxReferenceWritersideDescription,
      entries: [
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceAdmonitionBlockquote,
          example: '> Check this setting.\n{style="warning"}',
          identifiers: '>, style="note", style="warning", style="quote"',
          scope: l10n.syntaxReferenceScopeWritersideMarkdown,
          limitation: l10n.syntaxReferenceAdmonitionLimitation,
          documentationUri: _writersideAdmonitionDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceSemanticAdmonitions,
          example:
              '<tip>Try this first.</tip>\n'
              '<note>Remember this.</note>\n'
              '<warning>Use care.</warning>\n'
              '<quote>Quoted text.</quote>',
          identifiers: 'tip, note, warning, quote',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceSemanticMarkupLimitation,
          documentationUri: _writersideAdmonitionDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceCollapsibleHeading,
          example:
              '## Advanced details {collapsible="true"}\n\nHidden content.',
          identifiers: 'collapsible="true"',
          scope: l10n.syntaxReferenceScopeWritersideMarkdown,
          documentationUri: _writersideCollapsibleDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceCollapsibleCode,
          example:
              '```kotlin\nval answer = 42\n```\n'
              '{collapsible="true" collapsed-title="Example.kt"}',
          identifiers: 'collapsible, collapsed-title',
          scope: l10n.syntaxReferenceScopeWritersideMarkdown,
          documentationUri: _writersideCollapsibleDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceSemanticCollapsibles,
          example:
              '<chapter title="Details" collapsible="true">\n'
              '  <p>Hidden content.</p>\n'
              '</chapter>',
          identifiers: 'chapter, procedure, code-block, deflist',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceSemanticCollapsiblesLimitation,
          documentationUri: _writersideCollapsibleDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceSemanticCodeBlocks,
          example:
              '<code-block lang="tex">E = mc^2</code-block>\n'
              '<code-block lang="d2">a -> b</code-block>',
          identifiers: 'tex, mermaid, plantuml, puml, d2',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceSemanticDiagramLimitation,
          documentationUri: _writersideMathDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceReferencedDiagramSource,
          example: '<code-block lang="plantuml" src="../diagrams/model.puml"/>',
          identifiers: 'src',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceReferencedDiagramLimitation,
          documentationUri: _writersideMermaidDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceVideo,
          example:
              '<video src="sample.mp4" preview-src="sample.png"/>\n'
              '<video src="https://youtu.be/BeJu9bMPLGU"/>\n'
              '<video src="https://vimeo.com/76979871"/>',
          identifiers:
              'video, preview-src, youtu.be, youtube.com, '
              'youtube-nocookie.com, vimeo.com',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceVideoLimitation,
          documentationUri: _writersideVideoDocumentationUri,
        ),
      ],
    );
  }
}

class _SyntaxReferenceCategoryContent extends StatelessWidget {
  const _SyntaxReferenceCategoryContent({
    required this.description,
    required this.entries,
    this.footer,
  });

  final String description;
  final List<Widget> entries;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        for (final (index, entry) in entries.indexed) ...[
          entry,
          if (index < entries.length - 1)
            const SizedBox(height: BusyMarkSpacing.sm),
        ],
        if (footer case final footer?) footer,
      ],
    );
  }
}

class _SyntaxReferenceEntry extends StatelessWidget {
  const _SyntaxReferenceEntry({
    required this.title,
    required this.example,
    required this.scope,
    required this.documentationUri,
    this.identifiers,
    this.limitation,
  });

  final String title;
  final String example;
  final String? identifiers;
  final String scope;
  final String? limitation;
  final Uri documentationUri;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return BusyMarkGroupedSurface(
      child: Padding(
        padding: const EdgeInsets.all(BusyMarkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: BusyMarkSpacing.sm),
            _SyntaxReferenceCode(
              label: l10n.syntaxReferenceExample,
              value: example,
            ),
            if (identifiers case final identifiers?) ...[
              const SizedBox(height: BusyMarkSpacing.sm),
              _SyntaxReferenceValue(
                label: l10n.syntaxReferenceIdentifiers,
                value: identifiers,
                monospace: true,
              ),
            ],
            const SizedBox(height: BusyMarkSpacing.sm),
            _SyntaxReferenceValue(
              label: l10n.syntaxReferenceScope,
              value: scope,
            ),
            if (limitation case final limitation?) ...[
              const SizedBox(height: BusyMarkSpacing.sm),
              _SyntaxReferenceValue(
                label: l10n.syntaxReferenceLimitation,
                value: limitation,
              ),
            ],
            const SizedBox(height: BusyMarkSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => unawaited(
                  launchUrl(
                    documentationUri,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                icon: const Icon(BusyMarkGlyphs.externalLink),
                label: Text(l10n.syntaxReferenceOfficialDocumentation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyntaxReferenceCode extends StatelessWidget {
  const _SyntaxReferenceCode({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: BusyMarkSpacing.xxs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.control,
            borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
            border: Border.all(color: colors.subtleBorder),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(BusyMarkSpacing.sm),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: BusyMarkTypography.monoFontFamily,
                  fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SyntaxReferenceValue extends StatelessWidget {
  const _SyntaxReferenceValue({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueWidget = SelectableText(
      value,
      style: textTheme.bodySmall?.copyWith(
        fontFamily: monospace ? BusyMarkTypography.monoFontFamily : null,
        fontFamilyFallback: monospace
            ? BusyMarkTypography.monoFontFamilyFallback
            : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: BusyMarkSpacing.xxs),
        if (monospace)
          Directionality(textDirection: TextDirection.ltr, child: valueWidget)
        else
          valueWidget,
      ],
    );
  }
}

class _BusyMarkInfoDialog extends StatelessWidget {
  const _BusyMarkInfoDialog({
    required this.title,
    required this.icon,
    required this.children,
    this.maxWidth = 460,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BusyMarkInformationalDialog(
      closeLabel: context.l10n.close,
      maxWidth: maxWidth,
      maxHeight: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BusyMarkDialogIdentity(
            visual: Icon(
              icon,
              size: BusyMarkDialogIdentity.visualExtent,
              color: colorScheme.primary,
            ),
            title: title,
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _BusyMarkAboutDialog extends StatelessWidget {
  const _BusyMarkAboutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return BusyMarkInformationalDialog(
      closeLabel: context.l10n.close,
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BusyMarkDialogIdentity(
            visual: _BusyMarkAboutLogo(label: context.l10n.appTitle),
            title: context.l10n.appTitle,
          ),
          const SizedBox(height: BusyMarkSpacing.xs),
          Text(
            context.l10n.aboutTagline,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
            ),
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
                onTap: () => unawaited(_openBusyMarkWebsite()),
              ),
              BusyMarkActionRow(
                title: context.l10n.aboutSourceCode,
                subtitle: _busyMarkRepositoryUrl,
                leading: const Icon(BusyMarkGlyphs.code),
                trailing: const Icon(BusyMarkGlyphs.externalLink),
                onTap: () => unawaited(_openBusyMarkRepository()),
              ),
            ],
          ),
        ],
      ),
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
            dimension: BusyMarkDialogIdentity.visualExtent,
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
          child: Directionality(
            textDirection: TextDirection.ltr,
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
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontFamily: BusyMarkTypography.monoFontFamily,
              fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
