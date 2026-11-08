import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';
import '../platform/native_menu_service.dart';
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

class _ReferencesPanelState extends ConsumerState<ReferencesPanel>
    with SingleTickerProviderStateMixin {
  late final _direction = TabController(
    length: 2,
    initialIndex: 1,
    vsync: this,
  );
  @override
  void dispose() {
    _direction.dispose();
    super.dispose();
  }

  bool _incoming = false;
  String? _anchor;
  int _limit = 100;
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
    final identity =
        state.activeBuffer?.remoteNote?.localId ?? state.activeBuffer?.filePath;
    if (identity != _identity) {
      _identity = identity;
      _anchor = null;
      _limit = 100;
    }
    final data = ref.watch(
      referencePanelResultsProvider((
        identity: identity ?? '',
        incoming: _incoming,
        anchor: _anchor,
        count: _limit,
      )),
    );
    final recovery =
        ref.watch(refactoringRecoveryProvider).value ?? const <String>[];
    final buffer = state.activeBuffer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyMarkSidebarHeader(
          title: context.l10n.references,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.md),
          child: YaruTabBar(
            tabController: _direction,
            tabs: [
              YaruTab(label: context.l10n.referenceIncoming),
              YaruTab(label: context.l10n.referenceOutgoing),
            ],
            onTap: (index) => setState(() {
              _incoming = index == 0;
              _limit = 100;
            }),
          ),
        ),
        Expanded(
          child: data.when(
            loading: () => const Center(child: YaruCircularProgressIndicator()),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(BusyMarkSpacing.md),
              child: Column(
                children: [
                  BusyMarkStatusBox(message: error.toString()),
                  BusyMarkNativeDialogButton(
                    onPressed: () =>
                        ref.read(referenceIndexProvider.notifier).refresh(),
                    label: context.l10n.tocTemplateRetry,
                  ),
                ],
              ),
            ),
            data: (page) {
              final headings = page.headings;
              final selected = page.references;
              if (_anchor != null &&
                  !headings.any((h) => h.anchor == _anchor)) {
                final staleIdentity = identity;
                final staleAnchor = _anchor;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted &&
                      _identity == staleIdentity &&
                      _anchor == staleAnchor) {
                    setState(() {
                      _anchor = null;
                      _limit = 100;
                    });
                  }
                });
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      BusyMarkSpacing.md,
                      BusyMarkSpacing.xs,
                      BusyMarkSpacing.md,
                      BusyMarkSpacing.sm,
                    ),
                    child: _ReferenceScopeSelector(
                      key: const ValueKey('references-scope'),

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
                        _limit = 100;
                      }),
                      label:
                          '${context.l10n.referenceScope}: ${headings.where((h) => h.anchor == _anchor).firstOrNull?.label ?? _anchor ?? context.l10n.referenceWholeDocument}',
                    ),
                  ),
                  if (selected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(BusyMarkSpacing.md),
                      child: Text(
                        buffer == null
                            ? context.l10n.referenceNoActiveDocument
                            : context.l10n.referenceNoResults,
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          selected.length +
                          (page.total > selected.length ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _limit) {
                          return BusyMarkNativeDialogButton(
                            onPressed: () => setState(() => _limit += 100),
                            label: context.l10n.workspaceSearchShowMore,
                          );
                        }
                        final result = selected[i];
                        final title = _incoming
                            ? result.source.title
                            : result.target?.document.title ??
                                  result.authored.destination;
                        final origin =
                            [result.authored.moduleId, result.authored.origin]
                                .whereType<String>()
                                .where((value) => value.trim().isNotEmpty)
                                .join(' / ');
                        final details = [
                          result.authored.label,
                          _resolutionLabel(context, result.resolution),
                          if (origin.isNotEmpty) origin,
                        ].where((text) => text.isNotEmpty).join(' · ');
                        return BusyMarkSidebarRecordRow<bool>(
                          icon:
                              result.resolution == ReferenceResolution.resolved
                              ? BusyMarkGlyphs.link
                              : BusyMarkGlyphs.error,
                          title: title,
                          subtitle: details,
                          tooltip: '$title\n$details',
                          semanticsLabel: '$title, $details',
                          onTap: () => _navigate(result, !_incoming),
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
                          onMenuSelected: (target) =>
                              _navigate(result, target, source: true),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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

class _ReferenceScopeSelector extends StatefulWidget {
  const _ReferenceScopeSelector({
    super.key,
    required this.label,
    required this.items,
    required this.onSelected,
  });
  final String label;
  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String> onSelected;
  @override
  State<_ReferenceScopeSelector> createState() =>
      _ReferenceScopeSelectorState();
}

class _ReferenceScopeSelectorState extends State<_ReferenceScopeSelector> {
  NativeMenuSession? _session;
  final _keys = BusyMarkContextMenuKeys();
  @override
  void dispose() {
    final session = _session;
    if (session != null) unawaited(const NativeMenuService().dismiss(session));
    _keys.clear();
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: true,
    expanded: _session != null,
    child: BusyMarkSidebarRowSurface(
      enabled: true,
      clickable: true,
      onTap: _open,
      onFocusChange: (focused) {
        if (!focused) _keys.clear();
      },
      onKeyEvent: (_, event) {
        if (_keys.handle(event, _open)) return KeyEventResult.handled;
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          unawaited(_open());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BusyMarkSpacing.xs),
          const Icon(BusyMarkGlyphs.downArrow, size: BusyMarkSizes.iconSm),
        ],
      ),
    ),
  );
}
