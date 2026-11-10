import '../platform/native_menu_service.dart';
import 'package:yaru/yaru.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../app/busymark_native_controls.dart';
import '../editor/link_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../app/app_settings.dart';
import '../nextcloud_notes/data/server_uri.dart';
import '../nextcloud_notes/presentation/notes_workspace_ui.dart';
import '../workspace/workspace_controller.dart';
import 'reference_controller.dart';
import 'reference_index.dart';
import 'markdown_move_ui.dart';
import 'dart:io';
import 'dart:async';

double referenceSidebarMinimumWidth(BuildContext context) {
  var width = BusyMarkSizes.sidebarWidth;
  for (final label in [
    context.l10n.referenceIncoming,
    context.l10n.referenceOutgoing,
  ]) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$label (9999)',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
      maxLines: 1,
    )..layout();
    final requiredWidth = painter.width + BusyMarkSpacing.md * 4;
    if (requiredWidth > width) width = requiredWidth;
    painter.dispose();
  }
  return width;
}

Future<LinkDestination?> showReferenceLinkChooser(
  BuildContext context, {
  String initialDestination = '',
}) async {
  final focus = FocusManager.instance.primaryFocus;
  final value = await showBusyMarkModalDialog<LinkDestination>(
    context,
    builder: (_) =>
        ReferenceLinkChooser(initialDestination: initialDestination),
  );
  if (focus?.context?.mounted == true) focus!.requestFocus();
  return value;
}

class ReferenceLinkChooser extends ConsumerStatefulWidget {
  const ReferenceLinkChooser({super.key, this.initialDestination = ''});
  final String initialDestination;
  @override
  ConsumerState<ReferenceLinkChooser> createState() =>
      _ReferenceLinkChooserState();
}

class _ReferenceLinkChooserState extends ConsumerState<ReferenceLinkChooser> {
  late final _url = TextEditingController(text: widget.initialDestination);
  String _query = '';
  int _limit = 100;
  late final String? _workspaceId;
  late final String? _bufferId;
  bool? _prettyUrls;
  String? _routeFailure;
  @override
  void initState() {
    super.initState();
    final state = ref.read(workspaceControllerProvider);
    _workspaceId = state.workspace?.id;
    _bufferId = state.activeBufferId;
    if (state.workspace?.nextcloudAccountId case final id?) {
      unawaited(_confirmRoute(id));
    }
  }

  Future<void> _confirmRoute(String id) async {
    try {
      final repository = await ref.read(
        nextcloudNotesRepositoryProvider.future,
      );
      final pretty = await repository.confirmNoteWebRoute(id);
      if (mounted) setState(() => _prettyUrls = pretty);
    } on Object catch (error) {
      if (mounted) setState(() => _routeFailure = error.toString());
    }
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _complete(LinkDestination destination) {
    final state = ref.read(workspaceControllerProvider);
    Navigator.pop(
      context,
      state.workspace?.id == _workspaceId && state.activeBufferId == _bufferId
          ? destination
          : null,
    );
  }

  LinkDestination? _destination(ReferenceTarget target, ReferenceIndex index) {
    final state = ref.read(workspaceControllerProvider);
    if (!target.document.available ||
        index.missingNoteIds.contains(target.document.serverId) ||
        state.workspace?.id != _workspaceId ||
        state.activeBufferId != _bufferId) {
      return null;
    }
    if (index.server != null) {
      if (target.document.serverId == null || _prettyUrls == null) return null;
      // Nextcloud browser heading fragments are not a verified portable route.
      if (target.anchor != null) return null;
      return LinkDestination(
        nextcloudNoteUrl(
          index.server!,
          target.document.serverId!,
          pretty: _prettyUrls!,
        ).toString(),
      );
    }
    final source = state.activeBuffer?.filePath;
    final path = target.document.path;
    if (source == null || path == null) return null;
    final relative = p.equals(source, path) && target.anchor != null
        ? ''
        : p.relative(path, from: p.dirname(source));
    final project = state.workspace?.writersideProject;
    final sourceModule = project?.topicOwnerForPath(source);
    final origin =
        sourceModule != null &&
            target.moduleId != null &&
            sourceModule.config.moduleName != target.moduleId
        ? target.moduleId
        : null;
    final href = (sourceModule == null
        ? relative
        : p.equals(source, path) && target.anchor != null
        ? ''
        : origin == null
        ? relative
        : project?.modules
                  .expand((m) => m.topics)
                  .where((t) => p.equals(t.filePath, path))
                  .firstOrNull
                  ?.fileName ??
              relative);
    return LinkDestination(
      href
              .split('/')
              .map(
                (part) => Uri.encodeComponent(
                  part,
                ).replaceAll('(', '%28').replaceAll(')', '%29'),
              )
              .join('/') +
          (target.anchor == null
              ? ''
              : '#${Uri.encodeComponent(target.anchor!)}'),
      origin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      referenceTargetResultsProvider((text: _query, count: _limit)),
    );
    final index = ref.watch(referenceIndexProvider).value;
    ref.watch(
      workspaceControllerProvider.select(
        (s) => (s.workspace?.id, s.activeBufferId),
      ),
    );
    return BusyMarkNativeDialogShell(
      title: context.l10n.referenceChooseTarget,
      maxWidth: 650,
      actions: [
        BusyMarkNativeDialogButton(
          onPressed: () => Navigator.pop(context),
          label: context.l10n.cancel,
        ),
        BusyMarkNativeDialogButton(
          onPressed: () => _complete(LinkDestination(_url.text)),
          label: context.l10n.apply,
        ),
      ],
      children: [
        if (_routeFailure != null)
          BusyMarkStatusBox(
            message: _routeFailure!,
            kind: BusyMarkStatusKind.error,
          ),
        BusyMarkNativeTextEntry(
          controller: _url,
          autofocus: true,
          label: context.l10n.source,
          onSubmitted: (value) => _complete(LinkDestination(value)),
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        BusyMarkNativeTextEntry(
          label: context.l10n.quickOpen,
          onChanged: (query) => setState(() {
            _query = query.toLowerCase();
            _limit = 100;
          }),
        ),
        SizedBox(
          height: 320,
          child: data.when(
            loading: () => const Center(child: YaruCircularProgressIndicator()),
            error: (error, stack) => Column(
              children: [
                BusyMarkStatusBox(
                  message: error.toString(),
                  kind: BusyMarkStatusKind.error,
                ),
                BusyMarkNativeDialogButton(
                  label: context.l10n.tocTemplateRetry,
                  onPressed: () =>
                      ref.read(referenceIndexProvider.notifier).refresh(),
                ),
              ],
            ),
            data: (page) {
              final targets = page.values;
              if (targets.isEmpty) {
                return Center(child: Text(context.l10n.referenceNoResults));
              }
              return ListView.builder(
                itemCount:
                    targets.length + (page.total > targets.length ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _limit) {
                    return BusyMarkNativeDialogButton(
                      onPressed: () => setState(() => _limit += 100),
                      label: context.l10n.workspaceSearchShowMore,
                    );
                  }
                  final target = targets[i];
                  final destination = index == null
                      ? null
                      : _destination(target, index);
                  return BusyMarkSidebarRecordRow<void>(
                    icon: BusyMarkGlyphs.link,
                    title: target.label ?? target.document.title,
                    subtitle: destination == null
                        ? index?.missingNoteIds.contains(
                                    target.document.serverId,
                                  ) ==
                                  true
                              ? context.l10n.referenceMissing
                              : index?.server == null ||
                                    !target.document.available
                              ? context.l10n.referenceUnavailable
                              : context.l10n.referenceNoPortableId
                        : '${destination.href}${destination.origin == null ? '' : ' / ${destination.origin}'}',
                    onTap: destination == null
                        ? null
                        : () => _complete(destination),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReferencesPanel extends ConsumerStatefulWidget {
  const ReferencesPanel({super.key});
  @override
  ConsumerState<ReferencesPanel> createState() => _ReferencesPanelState();
}

class _ReferencesPanelState extends ConsumerState<ReferencesPanel> {
  final _limits = <bool, int>{true: 100, false: 100};
  String? _anchor;
  String? _identity;
  Future<void> _navigate(
    IndexedReference result,
    bool target, {
    bool source = false,
  }) async {
    final workspace = ref.read(workspaceControllerProvider).workspace;
    final document = target ? result.target?.document : result.source;
    if (document == null || workspace == null) return;
    final controller = ref.read(workspaceControllerProvider.notifier);
    final opened = document.localId != null
        ? await controller.openNextcloudNote(document.localId!)
        : await controller.openActiveFile(document.path!);
    if (!mounted ||
        !opened ||
        ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
      return;
    }
    final buffer = ref.read(workspaceControllerProvider).activeBuffer;
    if (buffer == null ||
        (buffer.remoteNote?.localId ?? buffer.filePath) != document.identity) {
      return;
    }
    var span = target ? result.target?.span : result.authored.occurrence;
    if (referenceRevision(buffer.text) != document.revision) {
      ref.read(referenceIndexProvider.notifier).refresh();
      // Refresh stale positions instead of selecting unrelated text. The user
      // can navigate again when the refreshed occurrence is visible.
      return;
    }
    if (span == null) return;
    if (source) {
      controller.updateActiveEditorMode(DocumentViewModePreference.source);
    }
    ref
        .read(notesMatchNavigationProvider.notifier)
        .navigate(
          document.identity,
          span.startOffset,
          span.endOffset,
          document.revision,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceControllerProvider);
    final expanded = ref.watch(referenceSectionExpansionProvider);
    final identity =
        state.activeBuffer?.remoteNote?.localId ?? state.activeBuffer?.filePath;
    if (identity != _identity) {
      _identity = identity;
      _anchor = null;
      _limits.updateAll((_, _) => 100);
    }
    final results = {
      for (final incoming in [true, false])
        incoming: ref.watch(
          referencePanelResultsProvider((
            identity: identity ?? '',
            incoming: incoming,
            anchor: _anchor,
            count: _limits[incoming]!,
          )),
        ),
    };
    final headings =
        results.values
            .map((value) => value.value?.headings)
            .whereType<List<ReferenceTarget>>()
            .firstOrNull ??
        const <ReferenceTarget>[];
    if (_anchor != null &&
        results.values.every((value) => value.hasValue) &&
        !headings.any((h) => h.anchor == _anchor)) {
      final staleIdentity = identity;
      final staleAnchor = _anchor;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _identity == staleIdentity && _anchor == staleAnchor) {
          setState(() {
            _anchor = null;
            _limits.updateAll((_, _) => 100);
          });
        }
      });
    }
    final recovery =
        ref.watch(refactoringRecoveryProvider).value ?? const <String>[];
    final buffer = state.activeBuffer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkSidebarHeader(
          title: context.l10n.references,
          actions: [
            _ReferenceActions(
              key: const ValueKey('references-actions'),
              items: [
                BusyMarkPopupMenuItem(
                  value: '',
                  label: context.l10n.referenceWholeDocument,
                  checked: _anchor == null,
                  trailingCheck: true,
                ),
                for (final h in headings)
                  BusyMarkPopupMenuItem(
                    value: h.anchor!,
                    label: h.label ?? h.anchor!,
                    checked: h.anchor == _anchor,
                    trailingCheck: true,
                  ),
              ],
              onSelected: (value) => setState(() {
                _anchor = value.isEmpty ? null : value;
                _limits.updateAll((_, _) => 100);
              }),
            ),
          ],
          leading: const Icon(BusyMarkGlyphs.link),
          contextLine: buffer == null
              ? null
              : BusyMarkTooltipStyle.wrap(
                  context,
                  message: [
                    buffer.filePath ?? buffer.displayName,
                    if (state.workspace?.writersideProject case final project?)
                      '${project.activeModule?.config.moduleName ?? ''} / ${project.activeInstanceId ?? ''}',
                  ].join('\n'),
                  child: Text(buffer.displayName),
                ),
        ),
        for (final journal in recovery)
          BusyMarkNativeDialogButton(
            onPressed: () async {
              await reviewMarkdownRecovery(context, ref, journal);
              if (mounted) ref.invalidate(refactoringRecoveryProvider);
            },
            label: context.l10n.notesRecovery,
          ),
        if (_anchor != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.md),
            child: Text(
              '${context.l10n.referenceScope}: ${headings.where((h) => h.anchor == _anchor).firstOrNull?.label ?? _anchor}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              for (final incoming in [true, false]) ...[
                BusyMarkSidebarTreeRow(
                  key: ValueKey('references-section-$incoming'),
                  title:
                      '${incoming ? context.l10n.referenceIncoming : context.l10n.referenceOutgoing}${results[incoming]!.value == null ? '' : ' (${results[incoming]!.value!.total})'}',
                  depth: 0,
                  hasChildren: true,
                  expanded: expanded[incoming]!,
                  traverseWithArrows: true,
                  onToggle: () => ref
                      .read(referenceSectionExpansionProvider.notifier)
                      .toggle(incoming),
                  onTap: () => ref
                      .read(referenceSectionExpansionProvider.notifier)
                      .toggle(incoming),
                ),
                if (expanded[incoming]!)
                  results[incoming]!.when(
                    loading: () =>
                        const Center(child: YaruCircularProgressIndicator()),
                    error: (error, stack) => Column(
                      children: [
                        BusyMarkStatusBox(
                          message: error.toString(),
                          kind: BusyMarkStatusKind.error,
                        ),
                        BusyMarkNativeDialogButton(
                          label: context.l10n.tocTemplateRetry,
                          onPressed: () => ref
                              .read(referenceIndexProvider.notifier)
                              .refresh(),
                        ),
                      ],
                    ),
                    data: (page) => Column(
                      children: [
                        if (page.references.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(BusyMarkSpacing.md),
                            child: Text(
                              buffer == null
                                  ? context.l10n.referenceNoActiveDocument
                                  : context.l10n.referenceNoResults,
                            ),
                          ),
                        for (final result in page.references)
                          _entry(context, result, incoming),
                        if (page.total > page.references.length)
                          BusyMarkNativeDialogButton(
                            label: context.l10n.workspaceSearchShowMore,
                            onPressed: () => setState(
                              () =>
                                  _limits[incoming] = _limits[incoming]! + 100,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _entry(BuildContext context, IndexedReference result, bool incoming) {
    final title = incoming
        ? result.source.title
        : result.target?.document.title ?? result.authored.destination;
    final origin = [
      result.authored.moduleId,
      result.authored.origin,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' / ');
    final details = [
      result.authored.label,
      _resolutionLabel(context, result.resolution),
      if (origin.isNotEmpty) origin,
    ].where((text) => text.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: BusyMarkSpacing.md),
      child: BusyMarkSidebarRecordRow<bool>(
        compact: true,
        icon: result.resolution == ReferenceResolution.resolved
            ? BusyMarkGlyphs.link
            : BusyMarkGlyphs.error,
        title: title,
        subtitle: details,
        tooltip: '$title\n$details',
        semanticsLabel: '$title, $details',
        onTap: () => _navigate(result, !incoming),
        menuTooltip: context.l10n.actions,
        menuItemsBuilder: (context) => [
          BusyMarkPopupMenuItem(
            value: false,
            label: context.l10n.referenceSourceLocation,
          ),
          if (result.target != null)
            BusyMarkPopupMenuItem(
              value: true,
              label: context.l10n.referenceTargetLocation,
            ),
        ],
        onMenuSelected: (target) => _navigate(result, target, source: true),
      ),
    );
  }
}

String _resolutionLabel(BuildContext context, ReferenceResolution status) =>
    switch (status) {
      ReferenceResolution.resolved => context.l10n.referenceResolved,
      ReferenceResolution.missing => context.l10n.referenceMissing,
      ReferenceResolution.ambiguous => context.l10n.referenceAmbiguous,
      ReferenceResolution.unavailable => context.l10n.referenceUnavailable,
      ReferenceResolution.unsupported => context.l10n.referenceUnsupported,
    };

final refactoringRecoveryProvider = FutureProvider<List<String>>((ref) async {
  final workspace = ref.watch(workspaceControllerProvider).workspace;
  if (workspace?.filesystemRootPath == null) return const [];
  final folder = Directory(
    p.join(workspace!.rootPath, '.busymark-refactoring'),
  );
  if (!await folder.exists()) return const [];
  if (await FileSystemEntity.isLink(folder.path)) return const [];
  return (await folder.list(followLinks: false).toList())
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.json')
      .map((f) => f.path)
      .toList();
});

class _ReferenceActions extends StatefulWidget {
  const _ReferenceActions({
    super.key,
    required this.items,
    required this.onSelected,
  });
  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String> onSelected;
  @override
  State<_ReferenceActions> createState() => _ReferenceActionsState();
}

class _ReferenceActionsState extends State<_ReferenceActions> {
  NativeMenuSession? _session;
  @override
  void dispose() {
    final session = _session;
    if (session != null) unawaited(const NativeMenuService().dismiss(session));
    super.dispose();
  }

  Future<void> _open() async {
    if (_session != null) return;
    final session = NativeMenuSession();
    setState(() => _session = session);
    final selected = await showBusyMarkNativeContextMenu<String>(
      context,
      null,
      items: widget.items,
      session: session,
    );
    if (!mounted || !identical(_session, session)) return;
    setState(() => _session = null);
    if (selected != null) widget.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      expanded: _session != null,
      child: BusyMarkHeaderIconButton(
        tooltip: context.l10n.actions,
        icon: BusyMarkGlyphs.menuHorizontal,
        transparent: true,
        onPressed: _open,
      ),
    ),
  );
}
