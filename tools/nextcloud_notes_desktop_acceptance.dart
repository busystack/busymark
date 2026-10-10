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
  if (args.length != 4) {
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
  final caps = await fetchNotesCapabilities(
    client: transport,
    server: server,
    loginName: login,
    appPassword: password,
  );
  final account = NextcloudAccount(
    id: const Uuid().v4(),
    server: server,
    loginName: login,
    appVersion: caps.appVersion,
    apiVersion: caps.apiVersion,
  );
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
        localHistoryStoreProvider.overrideWithValue(MemoryLocalHistoryStore()),
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

class _Transport extends http.BaseClient {
  _Transport(this.inner);
  final http.Client inner;
  bool offline = false;
  int collections = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method == 'GET' && request.url.path.endsWith('/v1/notes')) {
      collections++;
    }
    if (offline) {
      throw http.ClientException('Simulated desktop loss of connectivity.');
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
  });
  final NextcloudAccount account;
  final _Transport transport;
  final String password;
  final Directory output;
  final String containerName;
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
    field.controller!.text = value;
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
      original = await api.getSettings();
      await ref.read(nextcloudConnectionProvider.notifier).reload();
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
        () => widgets<DropdownButton<String>>().isNotEmpty,
        'category selector',
      );
      widgets<DropdownButton<String>>().first.onChanged!('Desktop');
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
      workspace.updateActiveText('# Offline desktop edit\n\nDurable content.');
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
        () =>
            widgets<TextField>().any((f) => f.controller?.text == newer.title),
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
        () => ref.read(notesSettingsProvider).phase == NotesSettingsPhase.saved,
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
      await api.update(current.copyWith(content: '# Remote idle discovery\n'));
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
      await api.update(
        repository
            .noteById(id)!
            .copyWith(content: '# Remote focus discovery\n'),
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
        filename: 'desktop.png',
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
        newPath != oldPath && (await api.get(note.serverId!)).etag == note.etag,
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
    } catch (error, stack) {
      failure = error;
      failureStack = stack;
    } finally {
      widget.transport.offline = false;
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
      await File('${widget.output.path}/report.json').writeAsString(
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
