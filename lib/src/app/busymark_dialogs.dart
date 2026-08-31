import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
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
const _writersidePlantUmlDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/plantuml-diagrams.html';
const _writersideD2DocumentationUrl =
    'https://www.jetbrains.com/help/writerside/d2-diagrams.html';
const _writersideVideoDocumentationUrl =
    'https://www.jetbrains.com/help/writerside/videos.html';
const _busyMarkLogoAsset = 'assets/branding/busymark_logo.svg';
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
final _writersidePlantUmlDocumentationUri = Uri.parse(
  _writersidePlantUmlDocumentationUrl,
);
final _writersideD2DocumentationUri = Uri.parse(_writersideD2DocumentationUrl);
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
    final dialogSurface = busyMarkDialogSurfaceColor(context);
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
      role: BusyMarkSurfaceRole.dialog,
      child: Dialog(
        backgroundColor: dialogSurface,
        surfaceTintColor: dialogSurface,
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

class _SyntaxReferenceTopic {
  const _SyntaxReferenceTopic({required this.label, required this.targetTitle});

  final String label;
  final String targetTitle;
}

class _SyntaxReferenceDocumentationLink {
  const _SyntaxReferenceDocumentationLink({
    required this.label,
    required this.uri,
  });

  final String label;
  final Uri uri;
}

List<_SyntaxReferenceDocumentationLink> _writersideDiagramDocumentationLinks(
  AppLocalizations l10n,
) => [
  _SyntaxReferenceDocumentationLink(
    label: l10n.syntaxReferenceMermaid,
    uri: _writersideMermaidDocumentationUri,
  ),
  _SyntaxReferenceDocumentationLink(
    label: l10n.syntaxReferencePlantUml,
    uri: _writersidePlantUmlDocumentationUri,
  ),
  _SyntaxReferenceDocumentationLink(
    label: l10n.syntaxReferenceD2,
    uri: _writersideD2DocumentationUri,
  ),
];

GlobalKey<State<StatefulWidget>> _syntaxReferenceEntryKey(
  _SyntaxReferenceCategory category,
  String title,
) => GlobalObjectKey<State<StatefulWidget>>(
  'syntax-reference-entry-${category.name}-$title',
);

class _SyntaxReferenceDialog extends StatefulWidget {
  const _SyntaxReferenceDialog();

  @override
  State<_SyntaxReferenceDialog> createState() => _SyntaxReferenceDialogState();
}

class _SyntaxReferenceDialogState extends State<_SyntaxReferenceDialog> {
  static const _sidebarBreakpoint = 700.0;
  static const _sidebarWidth = 200.0;

  final _scrollController = ScrollController();
  var _category = _SyntaxReferenceCategory.markdown;
  String? _selectedTopic;

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
      title: Text(context.l10n.syntaxReference),
      maxWidth: BusyMarkSizes.modalMaxWidth,
      maxHeight:
          (MediaQuery.sizeOf(context).height *
                  BusyMarkSizes.modalMaxHeightFraction)
              .clamp(0, 720),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topics = _categoryTopics(context, _category);
                if (constraints.maxWidth >= _sidebarBreakpoint) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _sidebarWidth,
                        child: _SyntaxReferenceSidebar(
                          selected: _category,
                          labelFor: (category) =>
                              _categoryLabel(context, category),
                          iconFor: _categoryIcon,
                          topics: topics,
                          selectedTopic: _selectedTopic,
                          onSelected: _selectCategory,
                          onTopicSelected: _selectTopic,
                        ),
                      ),
                      Expanded(child: _referenceViewport(context)),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        BusyMarkSpacing.lg,
                        BusyMarkSpacing.md,
                        BusyMarkSpacing.lg,
                        BusyMarkSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SyntaxReferenceCategoryMenu(
                            selected: _category,
                            labelFor: (category) =>
                                _categoryLabel(context, category),
                            iconFor: _categoryIcon,
                            onSelected: _selectCategory,
                          ),
                          const SizedBox(height: BusyMarkSpacing.sm),
                          _SyntaxReferenceTopicMenu(
                            topics: topics,
                            selected: _selectedTopic,
                            onSelected: _selectTopic,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    Expanded(child: _referenceViewport(context)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceViewport(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        key: ValueKey('syntax-reference-category-${_category.name}'),
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsetsDirectional.fromSTEB(
          BusyMarkSpacing.xl,
          BusyMarkSpacing.lg,
          BusyMarkSpacing.xl,
          BusyMarkSpacing.xxl,
        ),
        child: _categoryContent(context, _category),
      ),
    );
  }

  void _selectCategory(_SyntaxReferenceCategory category) {
    if (category == _category) {
      setState(() => _selectedTopic = null);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: BusyMarkMotion.scroll,
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() {
      _category = category;
      _selectedTopic = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _selectTopic(String topic) {
    setState(() => _selectedTopic = topic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetContext = _syntaxReferenceEntryKey(
        _category,
        topic,
      ).currentContext;
      if (targetContext == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: BusyMarkMotion.scroll,
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        ),
      );
    });
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

  IconData _categoryIcon(_SyntaxReferenceCategory category) =>
      switch (category) {
        _SyntaxReferenceCategory.markdown => BusyMarkGlyphs.markdownFile,
        _SyntaxReferenceCategory.html => BusyMarkGlyphs.htmlBlock,
        _SyntaxReferenceCategory.diagramsAndApi => BusyMarkGlyphs.symbols,
        _SyntaxReferenceCategory.mathematics => BusyMarkGlyphs.math,
        _SyntaxReferenceCategory.writerside => BusyMarkGlyphs.writersideProject,
      };

  List<_SyntaxReferenceTopic> _categoryTopics(
    BuildContext context,
    _SyntaxReferenceCategory category,
  ) {
    final l10n = context.l10n;
    return switch (category) {
      _SyntaxReferenceCategory.markdown => [
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceMarkdownBlocks,
          targetTitle: l10n.syntaxReferenceHeadings,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceInlineFormatting,
          targetTitle: l10n.bold,
        ),
      ],
      _SyntaxReferenceCategory.html => [
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceRawHtmlBlocks,
          targetTitle: l10n.syntaxReferenceHtmlContainers,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceRawHtmlInline,
          targetTitle: l10n.syntaxReferenceHtmlFormattingTags,
        ),
      ],
      _SyntaxReferenceCategory.diagramsAndApi => [
        _SyntaxReferenceTopic(
          label: l10n.codeBlock,
          targetTitle: l10n.syntaxReferenceMermaid,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceSemanticDiagramBlocks,
          targetTitle: l10n.syntaxReferenceSemanticDiagramBlocks,
        ),
      ],
      _SyntaxReferenceCategory.mathematics => [
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceInlineMath,
          targetTitle: l10n.syntaxReferenceInlineMath,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceDisplayMath,
          targetTitle: l10n.syntaxReferenceDisplayMath,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceTexFence,
          targetTitle: l10n.syntaxReferenceTexFence,
        ),
      ],
      _SyntaxReferenceCategory.writerside => [
        _SyntaxReferenceTopic(
          label: l10n.admonition,
          targetTitle: l10n.syntaxReferenceAdmonitionBlockquote,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceSemanticCollapsibles,
          targetTitle: l10n.syntaxReferenceCollapsibleHeading,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceSemanticCodeBlocks,
          targetTitle: l10n.syntaxReferenceSemanticCodeBlocks,
        ),
        _SyntaxReferenceTopic(
          label: l10n.syntaxReferenceVideo,
          targetTitle: l10n.syntaxReferenceVideo,
        ),
      ],
    };
  }

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
    final scope = l10n.markdown;
    return _SyntaxReferenceCategoryContent(
      category: _SyntaxReferenceCategory.markdown,
      title: l10n.markdown,
      description: l10n.syntaxReferenceMarkdownDescription,
      entries: [
        _SyntaxReferenceEntry(
          sectionTitle: l10n.syntaxReferenceMarkdownBlocks,
          sectionDescription: l10n.syntaxReferenceMarkdownBlocksDescription,
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
          title: l10n.image,
          example: '![Alternative text](image.png)',
          identifiers: '![alt](src), ![alt][label]',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.thematicBreak,
          example: '---',
          identifiers: '---, ***, ___',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          sectionTitle: l10n.syntaxReferenceInlineFormatting,
          sectionDescription: l10n.syntaxReferenceInlineFormattingDescription,
          title: l10n.bold,
          example: '**bold**',
          identifiers: '**...**, __...__',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.italic,
          example: '*italic*',
          identifiers: '*...*, _..._',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.underline,
          example: '<u>underlined</u>',
          identifiers: '<u>...</u>',
          scope: scope,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.strikethrough,
          example: '~~removed~~',
          identifiers: '~~...~~',
          scope: scope,
          documentationUri: _githubMarkdownDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.inlineCode,
          example: '`code`',
          identifiers: '`...`',
          scope: scope,
          documentationUri: _commonMarkDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.link,
          example: '[BusyMark](https://busystack.org)',
          identifiers: '[text](url), [text][label]',
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
      category: _SyntaxReferenceCategory.html,
      title: l10n.syntaxReferenceCategoryHtml,
      description: l10n.syntaxReferenceHtmlDescription,
      entries: [
        _SyntaxReferenceEntry(
          sectionTitle: l10n.syntaxReferenceRawHtmlBlocks,
          sectionDescription: l10n.syntaxReferenceRawHtmlBlocksDescription,
          title: l10n.syntaxReferenceHtmlContainers,
          example: '<section>\n  <p>Text</p>\n</section>',
          identifiers:
              'article, aside, div, section, header, footer, main, nav',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlTextBlocks,
          example: '<h2>Heading</h2>\n<p>Text</p>',
          identifiers: 'h1-h6, p, blockquote, address, hr',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceLists,
          example: '<ul>\n  <li>One</li>\n  <li>Two</li>\n</ul>',
          identifiers: 'ul, ol, li',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.table,
          example:
              '<table>\n  <tr><th>Name</th></tr>\n'
              '  <tr><td>BusyMark</td></tr>\n</table>',
          identifiers:
              'table, caption, colgroup, col, thead, tbody, tfoot, tr, th, td',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlFigures,
          example:
              '<figure>\n  <img src="image.png" alt="Diagram">\n'
              '  <figcaption>Diagram</figcaption>\n</figure>',
          identifiers: 'figure, figcaption, img',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlPreformatted,
          example: '<pre><code>const answer = 42;</code></pre>',
          identifiers: 'pre, code',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlDisclosure,
          example:
              '<details>\n  <summary>Details</summary>\n  Text\n</details>',
          identifiers: 'details, summary',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlDescriptionLists,
          example: '<dl>\n  <dt>Term</dt>\n  <dd>Meaning</dd>\n</dl>',
          identifiers: 'dl, dt, dd',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          sectionTitle: l10n.syntaxReferenceRawHtmlInline,
          sectionDescription: l10n.syntaxReferenceRawHtmlInlineDescription,
          title: l10n.syntaxReferenceHtmlFormattingTags,
          example: '<strong>Important</strong> and <u>underlined</u>',
          identifiers:
              'strong, em, b, i, u, s, small, mark, sub, sup, ins, del',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlInlineCodeTags,
          example: '<kbd>Ctrl</kbd> + <code>M</code>',
          identifiers: 'code, kbd, samp, var',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.link,
          example: '<a href="https://busystack.org">BusyMark</a>',
          identifiers: 'a, href',
          scope: l10n.markdown,
          limitation: l10n.syntaxReferenceSafeUrlsDescription,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.inlineImage,
          example: '<img src="image.png" alt="Diagram">',
          identifiers: 'img, src, alt',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceHtmlNeutralInlineTags,
          example: '<abbr title="Application Programming Interface">API</abbr>',
          identifiers:
              'span, abbr, cite, q, dfn, time, data, bdi, bdo, ruby, rt, rp',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
        _SyntaxReferenceEntry(
          title: l10n.hardLineBreak,
          example: 'First line<br>\nSecond line',
          identifiers: 'br, wbr',
          scope: l10n.markdown,
          documentationUri: _htmlDocumentationUri,
        ),
      ],
      footer: _SyntaxReferenceNote(
        items: [
          l10n.syntaxReferenceSanitizedPreviewDescription,
          l10n.syntaxReferenceSourcePreservedDescription,
          l10n.syntaxReferenceMarkdownInsideHtmlDescription,
          l10n.syntaxReferenceBlockedContentDescription,
        ],
      ),
    );
  }

  Widget _diagramsAndApiReference(BuildContext context) {
    final l10n = context.l10n;
    final scope = l10n.markdown;
    return _SyntaxReferenceCategoryContent(
      category: _SyntaxReferenceCategory.diagramsAndApi,
      title: l10n.syntaxReferenceCategoryDiagramsAndApi,
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
          documentationLinks: _writersideDiagramDocumentationLinks(l10n),
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceReferencedDiagramSource,
          example:
              '<code-block lang="d2" src="../codeSnippets/graph.d2"/>\n\n'
              '```mermaid\n```\n{src="../codeSnippets/flow.mmd"}',
          identifiers: 'src',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceReferencedDiagramLimitation,
          documentationLinks: _writersideDiagramDocumentationLinks(l10n),
        ),
      ],
    );
  }

  Widget _mathematicsReference(BuildContext context) {
    final l10n = context.l10n;
    final markdownScope = l10n.markdown;
    return _SyntaxReferenceCategoryContent(
      category: _SyntaxReferenceCategory.mathematics,
      title: l10n.syntaxReferenceCategoryMathematics,
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
      category: _SyntaxReferenceCategory.writerside,
      title: l10n.writerside,
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
          documentationLinks: [
            _SyntaxReferenceDocumentationLink(
              label: l10n.syntaxReferenceCategoryMathematics,
              uri: _writersideMathDocumentationUri,
            ),
            ..._writersideDiagramDocumentationLinks(l10n),
          ],
        ),
        _SyntaxReferenceEntry(
          title: l10n.syntaxReferenceReferencedDiagramSource,
          example: '<code-block lang="plantuml" src="../diagrams/model.puml"/>',
          identifiers: 'src',
          scope: l10n.syntaxReferenceScopeWritersideMarkdownAndXml,
          limitation: l10n.syntaxReferenceReferencedDiagramLimitation,
          documentationLinks: _writersideDiagramDocumentationLinks(l10n),
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

class _SyntaxReferenceSidebar extends StatelessWidget {
  const _SyntaxReferenceSidebar({
    required this.selected,
    required this.labelFor,
    required this.iconFor,
    required this.topics,
    required this.selectedTopic,
    required this.onSelected,
    required this.onTopicSelected,
  });

  final _SyntaxReferenceCategory selected;
  final String Function(_SyntaxReferenceCategory category) labelFor;
  final IconData Function(_SyntaxReferenceCategory category) iconFor;
  final List<_SyntaxReferenceTopic> topics;
  final String? selectedTopic;
  final ValueChanged<_SyntaxReferenceCategory> onSelected;
  final ValueChanged<String> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final dialogSurface = busyMarkDialogSurfaceColor(context);
    return KeyedSubtree(
      key: const ValueKey('syntax-reference-category-selector'),
      child: Material(
        key: const ValueKey('syntax-reference-sidebar-surface'),
        color: dialogSurface,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(
                color: colors.divider,
                width: BusyMarkStroke.hairline,
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 216,
                child: BusyMarkSidebarNavigation(
                  surfaceColor: dialogSurface,
                  children: [
                    for (final category in _SyntaxReferenceCategory.values)
                      BusyMarkSidebarNavigationTile(
                        key: ValueKey(
                          'syntax-reference-category-navigation-${category.name}',
                        ),
                        selected: category == selected,
                        leading: Icon(iconFor(category)),
                        title: Text(
                          labelFor(category),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(category),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: BusyMarkSidebarNavigation(
                  surfaceColor: dialogSurface,
                  children: [
                    for (var index = 0; index < topics.length; index++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: BusyMarkSpacing.md,
                        ),
                        child: BusyMarkSidebarNavigationTile(
                          key: ValueKey(
                            'syntax-reference-topic-navigation-'
                            '${selected.name}-$index',
                          ),
                          selected: topics[index].targetTitle == selectedTopic,
                          leading: const Icon(BusyMarkGlyphs.tag),
                          title: Text(
                            topics[index].label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () =>
                              onTopicSelected(topics[index].targetTitle),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyntaxReferenceCategoryMenu extends StatelessWidget {
  const _SyntaxReferenceCategoryMenu({
    required this.selected,
    required this.labelFor,
    required this.iconFor,
    required this.onSelected,
  });

  final _SyntaxReferenceCategory selected;
  final String Function(_SyntaxReferenceCategory category) labelFor;
  final IconData Function(_SyntaxReferenceCategory category) iconFor;
  final ValueChanged<_SyntaxReferenceCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return BusyMarkMenuButton<_SyntaxReferenceCategory>(
      key: const ValueKey('syntax-reference-category-selector'),
      tooltip: context.l10n.syntaxReferenceCategory,
      fallbackMenuWidth: BusyMarkSizes.languagePopupMaxWidth,
      items: [
        for (final category in _SyntaxReferenceCategory.values)
          BusyMarkPopupMenuItem<_SyntaxReferenceCategory>(
            value: category,
            label: labelFor(category),
            icon: iconFor(category),
            checked: category == selected,
            trailingCheck: true,
          ),
      ],
      onSelected: onSelected,
      triggerBuilder: (context, trigger) {
        return trigger.anchor(
          child: Tooltip(
            message: context.l10n.syntaxReferenceCategory,
            child: Semantics(
              expanded: trigger.isOpen,
              child: BusyMarkPushButton.standard(
                onPressed: trigger.onPressed,
                focusNode: trigger.focusNode,
                child: Row(
                  children: [
                    Icon(iconFor(selected)),
                    const SizedBox(width: BusyMarkSpacing.sm),
                    Expanded(
                      child: Text(
                        labelFor(selected),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(BusyMarkGlyphs.downArrow),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyntaxReferenceTopicMenu extends StatelessWidget {
  const _SyntaxReferenceTopicMenu({
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  final List<_SyntaxReferenceTopic> topics;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final effectiveSelection = topics.firstWhere(
      (topic) => topic.targetTitle == selected,
      orElse: () => topics.first,
    );
    return BusyMarkMenuButton<String>(
      key: const ValueKey('syntax-reference-topic-selector'),
      tooltip: effectiveSelection.label,
      fallbackMenuWidth: BusyMarkSizes.languagePopupMaxWidth,
      items: [
        for (final topic in topics)
          BusyMarkPopupMenuItem<String>(
            value: topic.targetTitle,
            label: topic.label,
            icon: BusyMarkGlyphs.tag,
            checked: topic.targetTitle == effectiveSelection.targetTitle,
            trailingCheck: true,
          ),
      ],
      onSelected: onSelected,
      triggerBuilder: (context, trigger) {
        return trigger.anchor(
          child: Tooltip(
            message: effectiveSelection.label,
            child: Semantics(
              expanded: trigger.isOpen,
              child: BusyMarkPushButton.standard(
                onPressed: trigger.onPressed,
                focusNode: trigger.focusNode,
                child: Row(
                  children: [
                    const Icon(BusyMarkGlyphs.tag),
                    const SizedBox(width: BusyMarkSpacing.sm),
                    Expanded(
                      child: Text(
                        effectiveSelection.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(BusyMarkGlyphs.downArrow),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyntaxReferenceNote extends StatelessWidget {
  const _SyntaxReferenceNote({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BusyMarkSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.control,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BusyMarkSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: BusyMarkSpacing.xxs),
                      child: Icon(
                        BusyMarkGlyphs.info,
                        size: BusyMarkSizes.iconSm,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: BusyMarkSpacing.sm),
                    Expanded(
                      child: Text(
                        items[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                          height: BusyMarkTypography.bodyLineHeight,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index != items.length - 1)
                  const SizedBox(height: BusyMarkSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyntaxReferenceSectionHeading extends StatelessWidget {
  const _SyntaxReferenceSectionHeading({
    required this.title,
    required this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (description case final description?) ...[
          const SizedBox(height: BusyMarkSpacing.xxs),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: BusyMarkTypography.bodyLineHeight,
            ),
          ),
        ],
      ],
    );
  }
}

class _SyntaxReferenceCategoryContent extends StatelessWidget {
  const _SyntaxReferenceCategoryContent({
    required this.category,
    required this.title,
    required this.description,
    required this.entries,
    this.footer,
  });

  final _SyntaxReferenceCategory category;
  final String title;
  final String description;
  final List<_SyntaxReferenceEntry> entries;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final dividerColor = BusyMarkSurfaceColors.of(context).divider;
    final groupedEntries = <Widget>[];
    final showScopeHeadings =
        entries.map((entry) => entry.scope).toSet().length > 1;
    String? currentScope;
    for (final entry in entries) {
      if (entry.sectionTitle case final sectionTitle?) {
        if (groupedEntries.isNotEmpty) {
          groupedEntries.add(const SizedBox(height: BusyMarkSpacing.xxl));
        }
        groupedEntries.add(
          _SyntaxReferenceSectionHeading(
            title: sectionTitle,
            description: entry.sectionDescription,
          ),
        );
        groupedEntries.add(const SizedBox(height: BusyMarkSpacing.xs));
        currentScope = null;
      }
      if (entry.scope != currentScope) {
        final isFirstGroup = currentScope == null;
        if (showScopeHeadings && !isFirstGroup) {
          groupedEntries.add(const SizedBox(height: BusyMarkSpacing.lg));
        }
        currentScope = entry.scope;
        if (showScopeHeadings && !isFirstGroup) {
          groupedEntries.add(_SyntaxReferenceScopeHeading(value: entry.scope));
          groupedEntries.add(const SizedBox(height: BusyMarkSpacing.xs));
        }
      } else {
        groupedEntries.add(Divider(height: 1, color: dividerColor));
      }
      groupedEntries.add(
        KeyedSubtree(
          key: _syntaxReferenceEntryKey(category, entry.title),
          child: entry,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: BusyMarkSpacing.xs),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
        ...groupedEntries,
        if (footer case final footer?) footer,
      ],
    );
  }
}

class _SyntaxReferenceScopeHeading extends StatelessWidget {
  const _SyntaxReferenceScopeHeading({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: ValueKey('syntax-reference-scope-heading-$value'),
      child: Semantics(
        label: '${context.l10n.syntaxReferenceScope}: $value',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: BusyMarkSpacing.xxs),
              child: Icon(
                BusyMarkGlyphs.document,
                size: BusyMarkSizes.iconSm,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyntaxReferenceEntry extends StatelessWidget {
  _SyntaxReferenceEntry({
    required this.title,
    required this.example,
    required this.scope,
    this.documentationUri,
    this.documentationLinks = const [],
    this.sectionTitle,
    this.sectionDescription,
    this.identifiers,
    this.limitation,
  }) : assert(
         (documentationUri != null) != documentationLinks.isNotEmpty,
         'Provide either documentationUri or documentationLinks.',
       );

  final String? sectionTitle;
  final String? sectionDescription;
  final String title;
  final String example;
  final String? identifiers;
  final String scope;
  final String? limitation;
  final Uri? documentationUri;
  final List<_SyntaxReferenceDocumentationLink> documentationLinks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BusyMarkSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = _SyntaxReferenceEntryDetails(
            title: title,
            identifiers: identifiers,
            limitation: limitation,
            documentationUri: documentationUri,
            documentationLinks: documentationLinks,
          );
          final exampleWidget = _SyntaxReferenceCode(
            label: context.l10n.syntaxReferenceExample,
            value: example,
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: BusyMarkSpacing.sm),
                exampleWidget,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: details),
              const SizedBox(width: BusyMarkSpacing.lg),
              Expanded(flex: 5, child: exampleWidget),
            ],
          );
        },
      ),
    );
  }
}

class _SyntaxReferenceEntryDetails extends StatelessWidget {
  const _SyntaxReferenceEntryDetails({
    required this.title,
    required this.identifiers,
    required this.limitation,
    required this.documentationUri,
    required this.documentationLinks,
  });

  final String title;
  final String? identifiers;
  final String? limitation;
  final Uri? documentationUri;
  final List<_SyntaxReferenceDocumentationLink> documentationLinks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: BusyMarkSpacing.xs),
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _SyntaxReferenceDocumentationAction(
              featureTitle: title,
              documentationUri: documentationUri,
              documentationLinks: documentationLinks,
            ),
          ],
        ),
        if (identifiers case final identifiers?) ...[
          const SizedBox(height: BusyMarkSpacing.xs),
          _SyntaxReferenceValue(
            label: l10n.syntaxReferenceIdentifiers,
            value: identifiers,
            icon: BusyMarkGlyphs.tag,
            monospace: true,
          ),
        ],
        if (limitation case final limitation?) ...[
          const SizedBox(height: BusyMarkSpacing.xs),
          _SyntaxReferenceValue(
            label: l10n.syntaxReferenceLimitation,
            value: limitation,
            icon: BusyMarkGlyphs.info,
          ),
        ],
      ],
    );
  }
}

class _SyntaxReferenceDocumentationAction extends StatelessWidget {
  const _SyntaxReferenceDocumentationAction({
    required this.featureTitle,
    required this.documentationUri,
    required this.documentationLinks,
  });

  final String featureTitle;
  final Uri? documentationUri;
  final List<_SyntaxReferenceDocumentationLink> documentationLinks;

  @override
  Widget build(BuildContext context) {
    final tooltip = context.l10n.syntaxReferenceOfficialDocumentation;
    final key = ValueKey('syntax-reference-documentation-$featureTitle');
    if (documentationLinks.isEmpty) {
      return IconButton(
        key: key,
        onPressed: () => _openDocumentation(documentationUri!),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        iconSize: BusyMarkSizes.iconSm,
        icon: const Icon(BusyMarkGlyphs.externalLink),
      );
    }
    return BusyMarkMenuButton<Uri>(
      key: key,
      tooltip: tooltip,
      fallbackMenuWidth: BusyMarkSizes.languagePopupMaxWidth,
      items: [
        for (final link in documentationLinks)
          BusyMarkPopupMenuItem<Uri>(
            value: link.uri,
            label: link.label,
            icon: BusyMarkGlyphs.externalLink,
          ),
      ],
      onSelected: _openDocumentation,
      triggerBuilder: (context, trigger) {
        return trigger.anchor(
          child: IconButton(
            onPressed: trigger.onPressed,
            focusNode: trigger.focusNode,
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            iconSize: BusyMarkSizes.iconSm,
            icon: const Icon(BusyMarkGlyphs.externalLink),
          ),
        );
      },
    );
  }

  void _openDocumentation(Uri uri) {
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}

class _SyntaxReferenceCode extends StatelessWidget {
  const _SyntaxReferenceCode({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.control,
          borderRadius: BorderRadius.circular(BusyMarkRadius.md),
          border: Border.all(color: colors.subtleBorder),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: BusyMarkSpacing.md,
              vertical: BusyMarkSpacing.xs,
            ),
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: BusyMarkTypography.codeLineHeight,
                fontFamily: BusyMarkTypography.monoFontFamily,
                fontFamilyFallback: BusyMarkTypography.monoFontFamilyFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyntaxReferenceValue extends StatelessWidget {
  const _SyntaxReferenceValue({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final valueWidget = SelectableText(
      value,
      style: textTheme.bodySmall?.copyWith(
        height: BusyMarkTypography.bodyLineHeight,
        fontFamily: monospace ? BusyMarkTypography.monoFontFamily : null,
        fontFamilyFallback: monospace
            ? BusyMarkTypography.monoFontFamilyFallback
            : null,
      ),
    );
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: label,
            child: Padding(
              padding: const EdgeInsets.only(top: BusyMarkSpacing.xxs),
              child: Icon(
                icon,
                size: BusyMarkSizes.iconSm,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: BusyMarkSpacing.sm),
          Expanded(
            child: monospace
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: valueWidget,
                  )
                : valueWidget,
          ),
        ],
      ),
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
