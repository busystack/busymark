import 'package:busymark/src/nextcloud_notes/data/notes_store.dart';
import 'package:busymark/src/app/busymark_dialogs.dart';
import 'package:busymark/src/nextcloud_notes/presentation/notes_workspace_ui.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_transfer_service.dart';
import 'package:busymark/src/app/quick_open.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_navigation.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_search_controller.dart';
// Disposable native acceptance target. Production widgets/controllers, private
// profile, one explicitly trusted test CA, and only test-owned server resources.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_router.dart';
import 'package:busymark/src/app/busymark_app.dart';
import 'package:busymark/src/app/startup_path.dart';
import 'package:busymark/src/app/system_accent.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_repository.dart';
import 'package:busymark/src/nextcloud_notes/application/notes_settings_controller.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_api_client.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_capabilities.dart';
import 'package:busymark/src/nextcloud_notes/data/notes_secret_store.dart';
import 'package:busymark/src/nextcloud_notes/domain/notes_models.dart';
import 'package:busymark/src/platform/linux_header_bar_service.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.length < 4 || args.length > 5) {
    stderr.writeln(
      'Usage: PRIVATE_CREDENTIALS TEST_CA PRIVATE_OUTPUT DISPOSABLE_CONTAINER',
    );
    exit(64);
  }
  final credentials = jsonDecode(await File(args[0]).readAsString()) as Map;
  final output = Directory(args[2]);
  await output.create(recursive: true);
  final tls = SecurityContext(withTrustedRoots: true)
    ..setTrustedCertificates(args[1]);
  final transport = _Transport(IOClient(HttpClient(context: tls)));
  final server = Uri.parse(credentials['server'] as String);
  final login = credentials['loginName'] as String;
  final password = credentials['appPassword'] as String;
  final performance = args.length == 5 && args[4] == '--performance-m2';
  final restarting = args.length == 5 && args[4] == '--restart-m2';
  NextcloudAccount account;
  if (restarting || performance) {
    final persisted = await NotesStore.open(
      path: '${output.path}/notes.sqlite3',
    );
    account = (await persisted.accounts()).singleWhere(
      (a) => a.server == server && a.loginName == login,
    );
    await persisted.close();
    transport.offline = true;
  } else {
    final caps = await fetchNotesCapabilities(
      client: transport,
      server: server,
      loginName: login,
      appPassword: password,
    );
    account = NextcloudAccount(
      id: const Uuid().v4(),
      server: server,
      loginName: login,
      appVersion: caps.appVersion,
      apiVersion: caps.apiVersion,
    );
  }
  await windowManager.ensureInitialized();
  await LinuxHeaderBarService.instance.initialize();
  final settings = AppSettings.defaults().copyWith(
    localeTag: 'en',
    automaticSpelling: false,
    autoSave: false,
    sidebarVisible: true,
    documentViewMode: DocumentViewModePreference.editor,
    reopenPreviousWorkspaceOnStartup: false,
    confirmCloseWithUnsavedChanges: false,
  );
  runApp(
    ProviderScope(
      overrides: [
        startupPathProvider.overrideWithValue(null),
        initialSystemAccentColorProvider.overrideWithValue(
          busyMarkDefaultAccentColor,
        ),
        localSettingsStoreProvider.overrideWithValue(
          _Settings(settings.toJson()),
        ),
        documentSessionStoreProvider.overrideWithValue(
          MemoryDocumentSessionStore(),
        ),
        documentRecoveryStoreProvider.overrideWithValue(
          MemoryDocumentRecoveryStore(),
        ),
        localHistoryStoreProvider.overrideWithValue(
          FileLocalHistoryStore(
            rootDirectory: () async => Directory('${output.path}/history'),
          ),
        ),
        nextcloudHttpClientProvider.overrideWithValue(transport),
        nextcloudSecretStoreProvider.overrideWithValue(
          _Secrets(account.id, password),
        ),
        nextcloudNotesDatabasePathProvider.overrideWith(
          (_) async => '${output.path}/notes.sqlite3',
        ),
      ],
      child: _Harness(
        account: account,
        transport: transport,
        password: password,
        output: output,
        containerName: args[3],
        restart: restarting,
        performance: performance,
        m2Only: args.length == 5,
      ),
    ),
  );
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1360, 900), center: true),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

class _HeldWrite {
  _HeldWrite(this.status);
  final int status;
  final started = Completer<void>();
  final release = Completer<void>();
}

class _Transport extends http.BaseClient {
  _Transport(this.inner);
  final http.Client inner;
  bool offline = false;
  bool rejectNextWriteCredentials = false;
  bool throttleNextWrite = false;
  _HeldWrite? holdNextWrite;
  int writes = 0;
  int creates = 0;
  int collections = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'GET' && request.url.path.endsWith('/v1/notes')) {
      collections++;
    }
    if (offline) {
      throw http.ClientException('Simulated desktop loss of connectivity.');
    }
    final creation =
        request.method == 'POST' && request.url.path.endsWith('/v1/notes');
    if (creation) creates++;
    if (request.method == 'PUT' && request.url.path.contains('/v1/notes/')) {
      writes++;
      if (rejectNextWriteCredentials) {
        rejectNextWriteCredentials = false;
        request.headers['Authorization'] = nextcloudAuthorization(
          'invalid-desktop-fixture',
          'invalid-desktop-password',
        );
      }
      if (throttleNextWrite) {
        throttleNextWrite = false;
        return Future.value(
          http.StreamedResponse(
            Stream.value(utf8.encode('{}')),
            429,
            headers: {'Retry-After': '5'},
            request: request,
          ),
        );
      }
    }
    final held =
        creation ||
            (request.method == 'PUT' && request.url.path.contains('/v1/notes/'))
        ? holdNextWrite
        : null;
    if (held != null) {
      holdNextWrite = null;
      held.started.complete();
      await held.release.future;
      if (held.status == 429) {
        // A simulated rejection prevents execution; successful writes use HTTPS.
        return http.StreamedResponse(
          Stream.value(utf8.encode('{}')),
          429,
          headers: {'Retry-After': '5'},
          request: request,
        );
      }
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}

class _Settings implements LocalSettingsStore {
  _Settings(this.value);
  Map<String, Object?> value;
  @override
  Future<Map<String, Object?>> load() async => value;
  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}

class _Secrets implements NextcloudSecretStore {
  _Secrets(this.id, this.password);
  final String id;
  String? password;
  @override
  Future<String?> read(String accountId) async =>
      accountId == id ? password : null;
  @override
  Future<void> write(String accountId, String value) async {
    password = value;
  }

  @override
  Future<void> delete(String accountId) async {
    password = null;
  }
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.account,
    required this.transport,
    required this.password,
    required this.output,
    required this.containerName,
    this.restart = false,
    this.performance = false,
    this.m2Only = false,
  });
  final NextcloudAccount account;
  final _Transport transport;
  final String password;
  final Directory output;
  final String containerName;
  final bool restart, m2Only, performance;
  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  final boundary = GlobalKey();
  final checks = <String, bool>{};
  final created = <int>{};
  NotesSettings? original;
  late NotesRepository repository;
  late NotesApiClient api;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(run()));
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: boundary, child: const BusyMarkApp());
  void check(bool result, String name) {
    checks[name] = result;
    if (!result) throw StateError(name);
  }

  Future<void> wait(
    bool Function() test,
    String name, {
    int seconds = 30,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!test()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Timed out: $name');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  List<T> widgets<T extends Widget>() {
    final result = <T>[];
    void visit(Element e) {
      if (e.widget is T) result.add(e.widget as T);
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return result;
  }

  Future<void> label(String label) async {
    VoidCallback? action;
    await wait(() {
      void visit(Element e) {
        if (e.widget is Text && (e.widget as Text).data == label) {
          e.visitAncestorElements((a) {
            if (a.widget is ButtonStyleButton &&
                (a.widget as ButtonStyleButton).onPressed != null) {
              action = (a.widget as ButtonStyleButton).onPressed;
              return false;
            }
            return true;
          });
        }
        e.visitChildren(visit);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(visit);
      return action != null;
    }, 'action $label');
    action!();
  }

  void edit(TextField field, String value) {
    final controller =
        field.controller ??
        widgets<EditableText>()
            .firstWhere((editable) => editable.focusNode == field.focusNode)
            .controller;
    controller.text = value;
    field.onChanged!(value);
  }

  Future<void> capture(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await WidgetsBinding.instance.endOfFrame;
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      '${widget.output.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  }

  Future<Uint8List> png(Color color) async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = color);
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> metadataRaces(WorkspaceController workspace) async {
    for (final draft in [false, true]) {
      for (final status in [200, 429]) {
        for (final previous in [true, false]) {
          final suffix = '$draft-$status-$previous';
          final a = 'Native race A-$suffix';
          final b = 'Native race B-$suffix';
          final c = 'Native race C-$suffix';
          widget.transport.offline = draft;
          final note = await repository.create(
            widget.account.id,
            title: a,
            category: 'Desktop/Remote',
            content: 'native race body',
          );
          if (!draft) {
            await workspace.refreshNextcloudNotes();
            created.add(repository.noteById(note.localId)!.serverId!);
          }
          widget.transport.offline = true;
          await workspace.openNextcloudNote(note.localId);
          await wait(
            () => widgets<ListTile>().any(
              (t) => t.key == ValueKey('nextcloud-note-${note.localId}'),
            ),
            'held metadata row',
          );
          widgets<ListTile>()
              .firstWhere(
                (t) => t.key == ValueKey('nextcloud-note-${note.localId}'),
              )
              .onLongPress!();
          await wait(
            () => widgets<TextField>().any((f) => f.controller?.text == a),
            'held properties dialog',
          );
          final snapshot = repository.metadataSnapshot(note.localId);
          await repository.patchMetadata(snapshot, title: b);
          edit(
            widgets<TextField>().firstWhere((f) => f.controller?.text == a),
            c,
          );
          final held = _HeldWrite(status);
          widget.transport.holdNextWrite = held;
          widget.transport.offline = false;
          final sending = workspace.refreshNextcloudNotes();
          late int requests;
          try {
            await Future.any([
              held.started.future,
              sending.then<void>((_) => throw StateError('No held UI write.')),
            ]);
            await label('Save');
            await wait(
              () => repository.noteById(note.localId)!.metadataConflict != null,
              'held properties conflict',
            );
            requests = widget.transport.writes + widget.transport.creates;
          } finally {
            held.release.complete();
          }
          await sending;
          var current = repository.noteById(note.localId)!;
          if (current.serverId != null) created.add(current.serverId!);
          await workspace.refreshNextcloudNotes();
          check(
            current.title == c &&
                current.metadataConflict?.alternative.title == b &&
                current.syncState == NoteSyncState.conflict &&
                widget.transport.writes + widget.transport.creates == requests,
            'nativeHeldResponseBlocksPublication$suffix',
          );
          await wait(
            () => widgets<Text>().any((t) => t.data == 'Conflicts'),
            'held conflict status',
          );
          await label('Compare');
          await wait(
            () => widgets<DropdownButton>().any(
              (d) =>
                  d.items?.any(
                    (i) =>
                        i.child is Text &&
                        (i.child as Text).data == 'Previous local edit: $b',
                  ) ==
                  true,
            ),
            'held B/C review',
          );
          if (draft && status == 200 && previous) {
            await capture('held-post-metadata-review');
          }
          await label(previous ? 'Use previous edit' : 'Keep Mine');
          await wait(
            () => repository.noteById(note.localId)!.metadataConflict == null,
            'held metadata choice',
          );
          final deadline = repository.noteById(note.localId)!.retryNotBefore;
          if (deadline != null && DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(
              deadline.difference(DateTime.now()) + const Duration(seconds: 1),
            );
          }
          await workspace.refreshNextcloudNotes();
          current = repository.noteById(note.localId)!;
          created.add(current.serverId!);
          check(
            current.title == (previous ? b : c) &&
                current.syncState == NoteSyncState.synced &&
                (await api.get(current.serverId!)).title == current.title,
            'nativeHeldReviewedChoiceSynchronizes$suffix',
          );
        }
      }
    }
  }

  Future<void> everydayJourney(WorkspaceController workspace) async {
    // Actual production widgets are used for navigation, search, batch review,
    // offline status, recovery and import review. Provider calls supply fixtures
    // or selected paths where an OS file chooser is otherwise interactive.
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.title is Text && (t.title as Text).data == 'All notes',
      ),
      'all notes destination',
    );
    widgets<ListTile>()
        .firstWhere(
          (t) => t.title is Text && (t.title as Text).data == 'All notes',
        )
        .onTap!();
    widget.transport.offline = false;
    final categoryFixture = await repository.create(
      widget.account.id,
      title: 'M2 category fixture',
      category: 'M2/子/Sub',
    );
    await repository.synchronize(widget.account.id);
    created.add(repository.noteById(categoryFixture.localId)!.serverId!);
    final navigation = NotesNavigationController()
      ..update(repository.notes, widget.account.id);
    final categoryIndex = navigation.categoryPaths.indexOf('M2/子/Sub') + 4;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    void scrollCategory(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (position.axis == Axis.vertical &&
            position.viewportDimension == 240) {
          position.jumpTo(
            (categoryIndex * 36.0).clamp(0, position.maxScrollExtent),
          );
        }
      }
      element.visitChildren(scrollCategory);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(scrollCategory);
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.title is Text && (t.title as Text).data == 'Sub',
      ),
      'nested category navigation',
    );
    widgets<ListTile>()
        .firstWhere((t) => t.title is Text && (t.title as Text).data == 'Sub')
        .onTap!();
    final previousId = ref
        .read(workspaceControllerProvider)
        .activeBuffer
        ?.remoteNote
        ?.localId;
    await label('New note');
    await wait(
      () =>
          ref
              .read(workspaceControllerProvider)
              .activeBuffer
              ?.remoteNote
              ?.localId !=
          previousId,
      'nested filtered creation',
    );
    final draftId = ref
        .read(workspaceControllerProvider)
        .activeBuffer!
        .remoteNote!
        .localId;
    check(
      repository.noteById(draftId)!.category == 'M2/子/Sub',
      'm2NativeNestedFilteredCreation',
    );
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.key == ValueKey('nextcloud-note-$draftId'),
      ),
      'new note row',
    );
    widgets<ListTile>()
        .firstWhere((t) => t.key == ValueKey('nextcloud-note-$draftId'))
        .onLongPress!();
    await wait(
      () => widgets<TextField>().any((f) => f.decoration?.labelText == 'Title'),
      'new note properties',
    );
    edit(
      widgets<TextField>().firstWhere(
        (f) => f.decoration?.labelText == 'Title',
      ),
      'M2 desktop café',
    );
    await label('Save');
    await wait(
      () => repository.noteById(draftId)!.title == 'M2 desktop café',
      'reviewed title',
    );
    await workspace.refreshNextcloudNotes();
    final draft = repository.noteById(draftId)!;
    created.add(draft.serverId!);
    widget.transport.offline = true;
    await workspace.openNextcloudNote(draft.localId);
    workspace.updateActiveText(
      '# Everyday workspace\n\nalpha beta café 中文 foo_bar\n',
    );
    final attachment = await repository.addAttachment(
      draft.localId,
      filename: 'café%20.png',
      bytes: await png(Colors.green),
    );
    workspace.updateActiveText(
      '${ref.read(workspaceControllerProvider).activeText}\n\n![image](${attachment.reference})\n\n<img src="${attachment.reference}">',
    );
    check(await workspace.saveActive(), 'm2OfflineEditorMediaSave');
    final freshStore = await NotesStore.open(path: repository.store.path);
    final persisted = (await freshStore.notes()).firstWhere(
      (n) => n.localId == draft.localId,
    );
    check(
      persisted.content.contains(attachment.reference) &&
          (await freshStore.attachments(draft.localId)).isNotEmpty,
      'm2RestartDurableTextAndMedia',
    );
    await freshStore.close();
    await capture('m2-sidebar');
    final quick = showQuickOpen(rootNavigatorKey.currentContext!, ref);
    await wait(
      () => widgets<QuickOpenDialog>().isNotEmpty,
      'quick open dialog',
    );
    widgets<TextField>()
        .firstWhere((f) => f.decoration?.labelText == 'Quick Open')
        .onChanged!('M2 desktop');
    await wait(
      () => widgets<ListTile>().any(
        (t) =>
            t.title is Text &&
            (t.title as Text).data == draft.title &&
            t.onTap != null,
      ),
      'quick open results',
    );
    await capture('m2-quick-open');
    final quickTile = widgets<ListTile>().lastWhere(
      (t) =>
          t.title is Text &&
          (t.title as Text).data == draft.title &&
          t.onTap != null,
    );
    quickTile.onTap!();
    await quick;
    check(
      ref.read(workspaceControllerProvider).activeBuffer?.remoteNote?.localId ==
          draft.localId,
      'm2QuickOpenStableIdentity',
    );
    final search = showNotesSearch(
      rootNavigatorKey.currentContext!,
      ref,
      query: '"alpha beta" category:M2',
    );
    await wait(
      () => widgets<NotesSearchDialog>().isNotEmpty,
      'notes search dialog',
    );
    await wait(
      () => widgets<ListTile>().any(
        (t) =>
            t.title is Text &&
            (t.title as Text).data == draft.title &&
            t.trailing is IconButton,
      ),
      'indexed result',
    );
    await capture('m2-search');
    final result = widgets<ListTile>().lastWhere(
      (t) =>
          t.title is Text &&
          (t.title as Text).data == draft.title &&
          t.trailing is IconButton,
    );
    (result.trailing! as IconButton).onPressed!();
    await search;
    check(
      ref.read(appSettingsControllerProvider).documentViewMode ==
          DocumentViewModePreference.source,
      'm2ExplicitSourceLocation',
    );
    final seed = await repository.create(
      widget.account.id,
      title: 'M2 second',
      category: 'M2/子/Sub',
      content: 'alpha beta second',
    );
    final batch = showNotesBatch(rootNavigatorKey.currentContext!, ref, [
      draft.localId,
      seed.localId,
    ], initialAction: 'move');
    await wait(
      () => widgets<TextField>().any(
        (f) => f.decoration?.labelText == 'Category',
      ),
      'batch category input',
    );
    widgets<TextField>()
        .firstWhere((f) => f.decoration?.labelText == 'Category')
        .onChanged!('M2/Moved/子');
    await capture('m2-batch-review');
    await label('Save');
    await wait(
      () =>
          repository.noteById(draft.localId)!.category == 'M2/Moved/子' &&
          repository.noteById(seed.localId)!.category == 'M2/Moved/子',
      'batch durability',
    );
    Navigator.of(rootNavigatorKey.currentContext!).pop();
    await batch;
    check(true, 'm2ReviewedBatchOrganize');
    widget.transport.offline = false;
    await workspace.refreshNextcloudNotes();
    for (final id in [draft.localId, seed.localId]) {
      created.add(repository.noteById(id)!.serverId!);
    }
    final offline = await ref.read(
      notesOfflineProvider(widget.account.id).future,
    );
    await offline.setRequirement('category', 'M2');
    await offline.reconcile();
    check(
      (await offline.inspect(repository.noteById(draft.localId)!)).available,
      'm2CategoryOfflineCompleteness',
    );
    final status = showNotesOffline(
      rootNavigatorKey.currentContext!,
      ref,
      repository.noteById(draft.localId)!,
    );
    await wait(
      () => widgets<Text>().any((t) => t.data == 'Make available offline'),
      'offline status dialog',
    );
    await capture('m2-offline-status');
    Navigator.of(rootNavigatorKey.currentContext!).pop();
    await status;
    widget.transport.offline = true;
    for (final mode in DocumentViewModePreference.values) {
      workspace.updateActiveEditorMode(mode);
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(mode);
      await workspace.openNextcloudNote(draft.localId);
      if (mode != DocumentViewModePreference.source) {
        await wait(
          () => widgets<Image>().any((i) => i.image is FileImage),
          'offline retained image ${mode.name}',
        );
      }
    }
    check(true, 'm2DisconnectReopenRetainedMediaAllViews');
    widget.transport.offline = false;
    await workspace.deleteNextcloudNote(draft.localId);
    created.remove(repository.noteById(draft.localId)!.serverId);
    final recover = showNotesRecovery(
      rootNavigatorKey.currentContext!,
      ref,
      repository.noteById(draft.localId)!,
    );
    await wait(
      () => widgets<NotesRecoveryDialog>().isNotEmpty,
      'recovery preview',
    );
    await capture('m2-recovery');
    await label('Recovery: New note');
    await recover;
    final recoveredId = ref
        .read(workspaceControllerProvider)
        .activeBuffer!
        .remoteNote!
        .localId;
    check(recoveredId != draft.localId, 'm2RecoveryNewIdentity');
    await workspace.refreshNextcloudNotes();
    created.add(repository.noteById(recoveredId)!.serverId!);
    final snapshot = await workspace.captureNextcloudExport({
      recoveredId,
      seed.localId,
    });
    final cancellation = NotesTransferCancellation();
    final exportDialog = showBusyMarkModalDialog<void>(
      rootNavigatorKey.currentContext!,
      builder: (_) => NotesTransferProgressDialog(
        title: 'Export notes',
        operation: (cancel, progress) async {
          final exported = await NotesTransferService(repository)
              .exportSnapshot(
                notes: snapshot!,
                destination: widget.output.path,
                cancellation: cancel,
                onProgress: progress,
              );
          check(exported.complete, 'm2PortableExportComplete');
          return [exported.path];
        },
      ),
    );
    await wait(
      () => widgets<NotesTransferProgressDialog>().isNotEmpty,
      'export progress',
    );
    await wait(
      () => widgets<LinearProgressIndicator>().isEmpty,
      'export complete',
    );
    await capture('m2-export');
    await label('Close');
    await exportDialog;
    final exported = widget.output.listSync().whereType<Directory>().firstWhere(
      (d) => d.path.contains('BusyMark-notes-'),
    );
    final review = await NotesTransferService(
      repository,
    ).review(exported.path, widget.account.id);
    final importReview = showBusyMarkModalDialog<bool>(
      rootNavigatorKey.currentContext!,
      builder: (_) => NotesImportReviewDialog(review: review),
    );
    await wait(
      () => widgets<NotesImportReviewDialog>().isNotEmpty,
      'import review',
    );
    await capture('m2-import-review');
    await label('Import notes');
    check(await importReview == true, 'm2ImportReviewAccepted');
    final imported = await NotesTransferService(
      repository,
    ).importReviewed(review, widget.account.id, cancellation: cancellation);
    check(
      imported.every((i) => i.noteId != null),
      'm2ImportDurableDistinctIdentities',
    );
    await workspace.refreshNextcloudNotes();
    for (final item in imported) {
      created.add(repository.noteById(item.noteId!)!.serverId!);
    }
    check(
      imported.every(
        (i) =>
            repository.noteById(i.noteId!)!.syncState == NoteSyncState.synced,
      ),
      'm2ImportedMediaSynced',
    );
  }

  Future<void> performanceJourney(WorkspaceController workspace) async {
    check(repository.notes.length == 10020, 'm2Real10000NoteLibrary');
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.title is Text && (t.title as Text).data == 'All notes',
      ),
      'large sidebar',
    );
    await capture('m2-10000-sidebar');
    final watch = Stopwatch()..start();
    final quick = showQuickOpen(rootNavigatorKey.currentContext!, ref);
    await wait(
      () =>
          widgets<QuickOpenDialog>().isNotEmpty &&
          widgets<ListTile>().any(
            (t) => t.title is Text && (t.title as Text).data == 'Duplicate 0',
          ),
      'large quick open',
    );
    watch.stop();
    await capture('m2-10000-quick-open');
    Navigator.of(rootNavigatorKey.currentContext!).pop();
    await quick;
    final search = NotesSearchController(repository.store, widget.account.id);
    final querying = search.search('é', limit: 2000);
    final saved = Stopwatch()..start();
    final original = repository.notes.first;
    await repository.save(
      original.localId,
      content: '${original.content}\nlarge UI durable edit',
    );
    saved.stop();
    await querying;
    check(search.state.hits.isNotEmpty, 'm2LargeUiSearchDuringEdit');
    await search.dispose();
    final dialog = showNotesSearch(
      rootNavigatorKey.currentContext!,
      ref,
      query: 'token42',
    );
    await wait(
      () =>
          widgets<NotesSearchDialog>().isNotEmpty &&
          widgets<IconButton>().any((b) => b.tooltip == 'Source location'),
      'large indexed search UI',
    );
    await capture('m2-10000-search');
    Navigator.of(rootNavigatorKey.currentContext!).pop();
    await dialog;
    await File('${widget.output.path}/ui-performance.json').writeAsString(
      jsonEncode({
        'notes': repository.notes.length,
        'quickOpenToResultsMs': watch.elapsedMilliseconds,
        'durableSaveDuringSearchMs': saved.elapsedMilliseconds,
        'rssBytes': ProcessInfo.currentRss,
        'maximumRssBytes': ProcessInfo.maxRss,
      }),
    );
  }

  Future<void> restartJourney(WorkspaceController workspace) async {
    final note = repository.notes.firstWhere(
      (n) =>
          n.title == 'M2 desktop café' &&
          n.syncState != NoteSyncState.deletedRemotely,
    );
    final offline = await ref.read(
      notesOfflineProvider(widget.account.id).future,
    );
    check(
      offline.categoryRetained('M2'),
      'm2ProcessRestartCategoryRequirement',
    );
    check(
      (await offline.inspect(note)).available,
      'm2ProcessRestartCachedBytes',
    );
    await workspace.openNextcloudNote(note.localId);
    for (final mode in DocumentViewModePreference.values) {
      workspace.updateActiveEditorMode(mode);
      await ref
          .read(appSettingsControllerProvider.notifier)
          .setDocumentViewMode(mode);
      if (mode != DocumentViewModePreference.source) {
        await wait(
          () => widgets<Image>().any((i) => i.image is FileImage),
          'restart media ${mode.name}',
        );
      }
      await capture('m2-restart-${mode.name}');
    }
    await nativeShortcut('ctrl+p');
    await wait(() => widgets<QuickOpenDialog>().isNotEmpty, 'native Ctrl+P');
    edit(
      widgets<TextField>().firstWhere(
        (f) => f.decoration?.labelText == 'Quick Open',
      ),
      note.title,
    );
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.title is Text && (t.title as Text).data == note.title,
      ),
      'native Quick Open result',
    );
    // The imported copy has the same title/category. Capture the selected
    // document identity before Enter instead of guessing from duplicate titles.
    final selectedIdentity = rankQuickOpen(
      widgets<QuickOpenDialog>().single.documents,
      note.title,
    ).first.localId;
    await capture('m2-restart-native-quick-open');
    await nativeShortcut('enter');
    await wait(
      () =>
          widgets<QuickOpenDialog>().isEmpty &&
          ref
                  .read(workspaceControllerProvider)
                  .activeBuffer
                  ?.remoteNote
                  ?.localId ==
              selectedIdentity,
      'native Quick Open Enter',
    );
    check(true, 'm2NativeCtrlPEnterStableIdentity');
    await nativeShortcut('ctrl+p');
    await wait(
      () => widgets<QuickOpenDialog>().isNotEmpty,
      'Quick Open reopened',
    );
    await nativeShortcut('escape');
    await wait(() => widgets<QuickOpenDialog>().isEmpty, 'Quick Open Escape');
    check(true, 'm2NativeQuickOpenEscape');
    await nativeShortcut('ctrl+shift+p');
    await wait(
      () =>
          widgets<Text>().any((t) => t.data == 'Command Palette') &&
          widgets<QuickOpenDialog>().isEmpty,
      'native Ctrl+Shift+P',
    );
    await nativeShortcut('escape');
    await wait(
      () => !widgets<Text>().any((t) => t.data == 'Command Palette'),
      'command palette Escape',
    );
    check(true, 'm2NativeCtrlShiftPCommandPalette');
    final search = showNotesSearch(
      rootNavigatorKey.currentContext!,
      ref,
      query: '"alpha beta"',
    );
    await wait(
      () => widgets<NotesSearchDialog>().isNotEmpty,
      'restart search dialog',
    );
    await wait(
      () => widgets<ListTile>().any(
        (t) =>
            t.title is Text &&
            (t.title as Text).data == note.title &&
            t.trailing is IconButton,
      ),
      'restart indexed results',
    );
    await capture('m2-restart-search');
    Navigator.of(rootNavigatorKey.currentContext!).pop();
    await search;
    check(true, 'm2ProcessRestartIndexedSearch');
    await ref.read(localHistoryControllerProvider.notifier).refresh();
    check(
      ref.read(localHistoryControllerProvider).snapshot.documents.isNotEmpty,
      'm2ProcessRestartRetainedHistory',
    );
    // Local Markdown navigation/Quick Open remains available after changing workspace.
    final folder = await Directory(
      '${widget.output.path}/local-smoke',
    ).create();
    final file = File('${folder.path}/local.md');
    await file.writeAsString('# Local Markdown\nlocal search smoke');
    await workspace.openFolder(folder.path);
    await workspace.openActiveFile(file.path);
    final quick = showQuickOpen(rootNavigatorKey.currentContext!, ref);
    await wait(() => widgets<QuickOpenDialog>().isNotEmpty, 'local Quick Open');
    await wait(
      () => widgets<ListTile>().any(
        (t) => t.title is Text && (t.title as Text).data == 'local',
      ),
      'local file result',
    );
    widgets<ListTile>()
        .lastWhere((t) => t.title is Text && (t.title as Text).data == 'local')
        .onTap!();
    await quick;
    check(
      ref.read(workspaceControllerProvider).activeBuffer?.filePath == file.path,
      'm2LocalMarkdownQuickOpen',
    );
    await localSearchSmoke('local search smoke', 'm2-local-markdown-search');
    final writerside = Directory('${widget.output.path}/writerside-smoke');
    if (await writerside.exists()) await writerside.delete(recursive: true);
    await writerside.create();
    final copied = await Process.run('cp', [
      '-a',
      'test/fixtures/writerside/basic_project/.',
      writerside.path,
    ]);
    check(copied.exitCode == 0, 'writersideFixtureCopy');
    await workspace.openFolder(writerside.path);
    await workspace.openActiveFile('${writerside.path}/topics/intro.md');
    await localSearchSmoke('Introduction', 'm2-writerside-search');
    final writerQuick = showQuickOpen(rootNavigatorKey.currentContext!, ref);
    await wait(
      () =>
          widgets<QuickOpenDialog>().isNotEmpty &&
          widgets<ListTile>().any(
            (t) => t.title is Text && (t.title as Text).data == 'install',
          ),
      'writerside Quick Open',
    );
    widgets<ListTile>()
        .lastWhere(
          (t) => t.title is Text && (t.title as Text).data == 'install',
        )
        .onTap!();
    await writerQuick;
    check(
      ref.read(workspaceControllerProvider).activeBuffer?.filePath ==
          '${writerside.path}/topics/install.topic',
      'm2WritersideQuickOpen',
    );
  }

  Future<void> localSearchSmoke(String query, String screenshot) async {
    await windowManager.focus();
    final key = await Process.run(
      'python3',
      ['tools/nextcloud_notes_native_key.py', 'ctrl+f'],
      environment: {'BUSYMARK_NATIVE_ACCEPTANCE': '1'},
    );
    check(key.exitCode == 0, 'nativeSearchShortcut$screenshot');
    await wait(
      () => widgets<TextField>().any(
        (f) =>
            f.decoration?.hintText == 'Search' &&
            f.onChanged != null &&
            f.controller != null,
      ),
      'local search field',
    );
    edit(
      widgets<TextField>().lastWhere(
        (f) =>
            f.decoration?.hintText == 'Search' &&
            f.onChanged != null &&
            f.controller != null,
      ),
      query,
    );
    await wait(
      () => widgets<Text>().any((t) => t.data?.contains(query) == true),
      'local indexed result $query',
    );
    await capture(screenshot);
    ref.read(workspaceSearchCloseRequestProvider.notifier).request();
    check(true, screenshot);
  }

  Future<void> nativeShortcut(String key) async {
    await windowManager.focus();
    final result = await Process.run(
      'python3',
      ['tools/nextcloud_notes_native_key.py', key],
      environment: {'BUSYMARK_NATIVE_ACCEPTANCE': '1'},
    );
    if (result.exitCode != 0) {
      throw StateError('Native acceptance key failed: $key');
    }
  }

  Future<void> run() async {
    Object? failure;
    StackTrace? failureStack;
    try {
      repository = await ref.read(nextcloudNotesRepositoryProvider.future);
      await repository.upsertAccount(widget.account);
      api = NotesApiClient(
        client: widget.transport,
        account: widget.account,
        appPassword: widget.password,
      );
      if (!widget.restart && !widget.performance) {
        original = await api.getSettings();
      }
      await ref.read(nextcloudConnectionProvider.notifier).reload();
      if (widget.restart || widget.m2Only || widget.performance) {
        final workspace = ref.read(workspaceControllerProvider.notifier);
        await workspace.openNextcloudWorkspace(widget.account.id);
        ref.read(appRouterProvider).go('/workspace');
        if (widget.performance) {
          await performanceJourney(workspace);
        } else if (widget.restart) {
          await restartJourney(workspace);
        } else {
          await everydayJourney(workspace);
        }
      } else {
        final seed = await repository.create(
          widget.account.id,
          title: 'Desktop category fixture',
          category: 'Desktop/Child',
          content: '# Desktop fixture',
        );
        await repository.synchronize(widget.account.id);
        created.add(repository.noteById(seed.localId)!.serverId!);
        final workspace = ref.read(workspaceControllerProvider.notifier);
        check(
          await workspace.openNextcloudWorkspace(widget.account.id),
          'openNativeWorkspace',
        );
        ref.read(appRouterProvider).go('/workspace');
        await wait(
          () => widgets<ListTile>().any(
            (t) => t.title is Text && (t.title as Text).data == 'Desktop',
          ),
          'category hierarchy',
        );
        widgets<ListTile>()
            .firstWhere(
              (t) => t.title is Text && (t.title as Text).data == 'Desktop',
            )
            .onTap!();
        final priorIds = repository.notes.map((n) => n.localId).toSet();
        widget.transport.offline = true;
        await label('New note');
        await wait(() {
          final active = ref
              .read(workspaceControllerProvider)
              .activeBuffer
              ?.remoteNote
              ?.localId;
          return active != null && !priorIds.contains(active);
        }, 'category creation');
        final id = ref
            .read(workspaceControllerProvider)
            .activeBuffer!
            .remoteNote!
            .localId;
        check(
          repository.noteById(id)!.category == 'Desktop',
          'selectedParentCategoryCreation',
        );
        workspace.updateActiveText(
          '# Offline desktop edit\n\nDurable content.',
        );
        check(await workspace.saveActive(), 'offlineSaveDurability');
        final newer = repository.noteById(id)!;
        await wait(
          () =>
              widgets<ListTile>()
                  .where(
                    (t) =>
                        t.key is ValueKey<String> &&
                        (t.key! as ValueKey<String>).value.startsWith(
                          'nextcloud-note-',
                        ),
                  )
                  .firstOrNull
                  ?.key ==
              ValueKey('nextcloud-note-$id'),
          'offline activity reordered sidebar',
        );
        final rows = widgets<ListTile>()
            .where(
              (t) =>
                  t.key is ValueKey<String> &&
                  (t.key! as ValueKey<String>).value.startsWith(
                    'nextcloud-note-',
                  ),
            )
            .toList();
        check(
          rows.first.key == ValueKey('nextcloud-note-$id') &&
              newer.localActivityMicros != null,
          'offlineActivityOrdering',
        );
        await capture('offline-category');
        widget.transport.offline = false;
        await workspace.refreshNextcloudNotes();
        created.add(repository.noteById(id)!.serverId!);
        // Keep the dialog open across a real independent remote metadata write.
        await wait(
          () => widgets<ListTile>().any(
            (t) => t.key == ValueKey('nextcloud-note-$id'),
          ),
          'note row',
        );
        widgets<ListTile>()
            .firstWhere((t) => t.key == ValueKey('nextcloud-note-$id'))
            .onLongPress!();
        await wait(
          () => widgets<TextField>().any(
            (f) => f.controller?.text == newer.title,
          ),
          'properties dialog',
        );
        edit(
          widgets<TextField>().firstWhere(
            (f) => f.controller?.text == newer.title,
          ),
          'Desktop edited title',
        );
        final before = repository.noteById(id)!;
        await api.update(before.copyWith(category: 'Desktop/Remote'));
        await repository.synchronize(widget.account.id, allowWrites: false);
        workspace.updateActiveText('# Dirty while properties are open\n');
        await label('Save');
        await wait(
          () => repository.noteById(id)!.title == 'Desktop edited title',
          'metadata save',
        );
        check(
          repository.noteById(id)!.category == 'Desktop/Remote' &&
              repository.noteById(id)!.content.contains('Dirty while'),
          'propertiesConcurrencyAndDirtyBuffer',
        );
        await workspace.refreshNextcloudNotes();
        for (final draft in [false, true]) {
          widget.transport.offline = true;
          final reviewId = draft
              ? (await repository.create(
                  widget.account.id,
                  title: 'Desktop A draft',
                  category: 'Desktop/Remote',
                  content: 'draft body',
                )).localId
              : id;
          await workspace.openNextcloudNote(reviewId);
          final title = repository.noteById(reviewId)!.title;
          await wait(
            () => widgets<ListTile>().any(
              (t) => t.key == ValueKey('nextcloud-note-$reviewId'),
            ),
            'metadata review row',
          );
          widgets<ListTile>()
              .firstWhere((t) => t.key == ValueKey('nextcloud-note-$reviewId'))
              .onLongPress!();
          await wait(
            () => widgets<TextField>().any((f) => f.controller?.text == title),
            'stale metadata dialog',
          );
          final snapshot = repository.metadataSnapshot(reviewId);
          await repository.patchMetadata(snapshot, title: 'Desktop B $draft');
          edit(
            widgets<TextField>().firstWhere((f) => f.controller?.text == title),
            'Desktop C $draft',
          );
          await label('Save');
          await wait(
            () => repository.noteById(reviewId)!.metadataConflict != null,
            'local metadata conflict',
          );
          widget.transport.offline = false;
          await label('Compare');
          await wait(
            () => widgets<DropdownButton>().any(
              (d) =>
                  d.items?.any(
                    (i) =>
                        i.child is Text &&
                        (i.child as Text).data ==
                            'Previous local edit: Desktop B $draft',
                  ) ==
                  true,
            ),
            'reviewed B/C choices',
          );
          await capture('local-metadata-conflict-$draft');
          await label('Use previous edit');
          await wait(
            () => repository.noteById(reviewId)!.metadataConflict == null,
            'previous local choice applied',
          );
          await workspace.refreshNextcloudNotes();
          final selected = repository.noteById(reviewId)!;
          created.add(selected.serverId!);
          check(
            selected.title == 'Desktop B $draft' &&
                (await api.get(selected.serverId!)).title == selected.title,
            'nativeReviewedBPreservedDraft$draft',
          );
        }
        await metadataRaces(workspace);
        await workspace.openNextcloudNote(id);
        workspace.updateActiveText('# Native authenticated edit');
        await workspace.saveActive();
        widget.transport.rejectNextWriteCredentials = true;
        await workspace.refreshNextcloudNotes();
        check(
          repository.noteById(id)!.syncState == NoteSyncState.reconnectRequired,
          'nativeReal401BlocksWrite',
        );
        final verified = await fetchNotesCapabilities(
          client: widget.transport,
          server: widget.account.server,
          loginName: widget.account.loginName,
          appPassword: widget.password,
        );
        await repository.upsertAccount(
          widget.account.copyWith(
            appVersion: verified.appVersion,
            apiVersion: verified.apiVersion,
          ),
          reconnect: true,
        );
        await ref.read(nextcloudConnectionProvider.notifier).reload();
        await workspace.refreshNextcloudNotes();
        check(
          repository.noteById(id)!.syncState == NoteSyncState.synced &&
              (await api.get(repository.noteById(id)!.serverId!)).content ==
                  '# Native authenticated edit',
          'nativeVerifiedReconnectResumesWrite',
        );
        workspace.updateActiveText('# First throttled edit');
        await workspace.saveActive();
        widget.transport.throttleNextWrite = true;
        await workspace.refreshNextcloudNotes();
        final deadline = repository.noteById(id)!.retryNotBefore!;
        final writes = widget.transport.writes;
        workspace.updateActiveText('# Edited during throttling');
        await workspace.saveActive();
        await repository.patchMetadata(
          repository.metadataSnapshot(id),
          favorite: !repository.noteById(id)!.favorite,
        );
        await workspace.refreshNextcloudNotes();
        check(
          widget.transport.writes == writes &&
              repository.noteById(id)!.retryNotBefore == deadline,
          'nativeEditsKeepRetryAfter',
        );
        await Future<void>.delayed(
          deadline.difference(DateTime.now()) + const Duration(seconds: 1),
        );
        await workspace.refreshNextcloudNotes();
        check(
          repository.noteById(id)!.syncState == NoteSyncState.synced,
          'nativeDeadlinePublishesEditedRevision',
        );
        // Open and save the actual server settings controls.
        ref
            .read(appRouterProvider)
            .go('/settings?page=nextcloudNotes&returnTo=workspace');
        await wait(
          () =>
              ref.read(notesSettingsProvider).draft != null &&
              !ref.read(notesSettingsProvider).busy,
          'settings load',
        );
        await wait(
          () => widgets<TextField>().any(
            (f) => f.controller?.text == original!.fileSuffix,
          ),
          'rendered settings suffix',
        );
        final formSuffix = widgets<TextField>().firstWhere(
          (f) => f.controller?.text == original!.fileSuffix,
        );
        edit(formSuffix, ' .desktop ');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await label('Save');
        await wait(
          () =>
              ref.read(notesSettingsProvider).phase == NotesSettingsPhase.saved,
          'settings save',
        );
        check(
          ref.read(notesSettingsProvider).draft!.fileSuffix == '.desktop' &&
              ref.read(notesSettingsProvider).normalized,
          'settingsCustomSuffixNormalization',
        );
        await capture('server-settings');
        await api.updateSettings({'fileSuffix': original!.fileSuffix});
        await repository.synchronize(widget.account.id, allowWrites: false);
        ref.read(appRouterProvider).go('/workspace');
        await workspace.openNextcloudNote(id);
        // The transport loss is simulated; the recovery probe and subsequent PUT
        // use actual authenticated HTTPS requests and the production 60s timer.
        widget.transport.offline = true;
        workspace.updateActiveText('# Connectivity recovery desktop\n');
        await workspace.saveActive();
        await workspace.refreshNextcloudNotes();
        check(
          repository.accountError(widget.account.id)?.code ==
              NotesFailureCode.network,
          'offlineFailurePresented',
        );
        widget.transport.offline = false;
        await wait(
          () => repository.noteById(id)!.syncState == NoteSyncState.synced,
          'bounded connectivity recovery',
          seconds: 75,
        );
        check(
          (await api.get(
            repository.noteById(id)!.serverId!,
          )).content.contains('Connectivity recovery'),
          'authenticatedConnectivityRecovery',
        );
        // Idle discovery uses the unmodified production polling interval.
        final current = repository.noteById(id)!;
        await api.update(
          current.copyWith(content: '# Remote idle discovery\n'),
        );
        await wait(
          () =>
              ref
                  .read(workspaceControllerProvider)
                  .activeBuffer
                  ?.text
                  .contains('Remote idle discovery') ==
              true,
          'idle discovery',
          seconds: 75,
        );
        check(true, 'healthyIdleRemoteDiscovery');
        // A hidden window suspends reads; restoring/focusing triggers a check.
        await windowManager.hide();
        await Future<void>.delayed(const Duration(seconds: 1));
        final count = widget.transport.collections;
        final focusRemote = await api.get(repository.noteById(id)!.serverId!);
        await api.update(
          repository
              .noteById(id)!
              .copyWith(
                etag: focusRemote.etag,
                content: '# Remote focus discovery\n',
              ),
        );
        await Future<void>.delayed(const Duration(seconds: 11));
        check(widget.transport.collections == count, 'hiddenSuspension');
        await windowManager.show();
        await windowManager.focus();
        await wait(
          () =>
              ref
                  .read(workspaceControllerProvider)
                  .activeBuffer
                  ?.text
                  .contains('Remote focus discovery') ==
              true,
          'native focus refresh',
        );
        check(true, 'nativeFocusResumeRefresh');
        // Publish a small managed image, then replace its server file in this
        // disposable fixture without changing its path or the note ETag.
        final attachment = await repository.addAttachment(
          id,
          filename: 'café.png',
          bytes: await png(Colors.red),
        );
        workspace.updateActiveText(
          '# Desktop media\n\n![image](${attachment.reference})\n',
        );
        await workspace.saveActive();
        await workspace.refreshNextcloudNotes();
        var note = repository.noteById(id)!;
        final remoteAttachment = (await repository.store.attachments(
          id,
        )).firstWhere((a) => a.id == attachment.id);
        final rawPath = remoteAttachment.remotePath!;
        final destination = attachmentMarkdownReference(rawPath);
        workspace.updateActiveText('<img src="$rawPath">\n');
        await workspace.saveActive();
        await workspace.refreshNextcloudNotes();
        note = repository.noteById(id)!;
        check(
          note.content.contains('café.png'),
          'nativeLiteralUnicodeHtmlDestination',
        );
        final oldPath = await repository.resolveMedia(
          widget.account.id,
          id,
          destination,
        );
        for (final mode in DocumentViewModePreference.values) {
          workspace.updateActiveEditorMode(mode);
          await ref
              .read(appSettingsControllerProvider.notifier)
              .setDocumentViewMode(mode);
          workspace.updateActiveText(
            '${note.content}\nView flow: ${mode.name}\n',
          );
          check(await workspace.saveActive(), '${mode.name}LocalSave');
          await workspace.refreshNextcloudNotes();
          note = repository.noteById(id)!;
          await wait(
            () =>
                ref
                        .read(workspaceControllerProvider)
                        .activeBuffer!
                        .editorState
                        .mode ==
                    mode &&
                (mode == DocumentViewModePreference.editor ||
                    mode == DocumentViewModePreference.source ||
                    ref.read(workspaceControllerProvider).preview != null),
            'rendered ${mode.name} mode',
          );
          await capture('media-${mode.name}-before');
          check(
            ref.read(workspaceControllerProvider).activeBuffer!.text ==
                note.content,
            '${mode.name}MediaSaveFlow',
          );
        }
        final replacement = File('${widget.output.path}/replacement.png');
        await replacement.writeAsBytes(await png(Colors.blue));
        final serverFile =
            '/var/www/html/data/${widget.account.loginName}/files/${original!.notesPath}/${note.category}/$rawPath';
        final copied = await Process.run('docker', [
          'cp',
          replacement.path,
          '${widget.containerName}:$serverFile',
        ]);
        check(copied.exitCode == 0, 'replaceTestOwnedAttachment');
        final permissions = await Process.run('docker', [
          'exec',
          widget.containerName,
          'chown',
          'www-data:www-data',
          serverFile,
        ]);
        check(permissions.exitCode == 0, 'replacementPermissions');
        await workspace.refreshNextcloudNotes();
        final newPath = await repository.resolveMedia(
          widget.account.id,
          id,
          destination,
        );
        check(
          newPath != oldPath &&
              (await api.get(note.serverId!)).etag == note.etag,
          'samePathReplacementUnchangedNoteEtag',
        );
        await wait(
          () => widgets<Image>().any(
            (i) =>
                i.image is FileImage &&
                (i.image as FileImage).file.path == newPath,
          ),
          'actual displayed refreshed image',
        );
        check(true, 'alreadyOpenPreviewUsesReplacement');
        await capture('media-split-after');
        workspace.updateActiveEditorMode(DocumentViewModePreference.editor);
        await ref
            .read(appSettingsControllerProvider.notifier)
            .setDocumentViewMode(DocumentViewModePreference.editor);
        await wait(
          () => widgets<Image>().any(
            (i) =>
                i.image is FileImage &&
                (i.image as FileImage).file.path == newPath,
          ),
          'actual editor refreshed image',
        );
        check(true, 'alreadyOpenEditorUsesReplacement');
        await capture('media-editor-after');
        await everydayJourney(workspace);
      }
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
    } finally {
      widget.transport.offline = widget.restart || widget.performance;
      if (original != null) {
        try {
          await api.updateSettings(original!.toJson());
        } catch (_) {}
      }
      for (final id in created) {
        try {
          await api.delete(id);
        } catch (_) {}
      }
      await File(
        '${widget.output.path}/${widget.restart ? 'report-restart' : 'report'}.json',
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'passed': failure == null,
          'notesVersion': widget.account.appVersion,
          'apiVersion': widget.account.apiVersion,
          'checks': checks,
          if (failure != null) 'failure': '$failure',
          if (failureStack != null) 'stack': '$failureStack',
        }),
      );
      if (failure != null) {
        stderr.writeln('Desktop acceptance failed: $failure');
        exit(1);
      }
      await ref
          .read(workspaceControllerProvider.notifier)
          .discardRecoveryForShutdown();
      await SystemNavigator.pop();
    }
  }
}
