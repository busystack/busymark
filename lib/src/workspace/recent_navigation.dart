import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_router.dart';
import '../app/app_settings.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../search/search_session.dart';
import 'document_navigation.dart';
import 'workspace_controller.dart';
import 'workspace_safety.dart';

Future<void> openRecentResource(
  BuildContext context,
  WidgetRef ref,
  RecentResource resource,
) async {
  final controller = ref.read(workspaceControllerProvider.notifier);
  final origin = ref.read(appRouterProvider).routeInformationProvider.value.uri;
  final search = ref.read(searchSessionProvider);
  bool currentRequest() =>
      context.mounted &&
      ref.read(appRouterProvider).routeInformationProvider.value.uri ==
          origin &&
      ref.read(searchSessionProvider).requestRevision ==
          search.requestRevision &&
      (!search.active ||
          ref.read(searchSessionProvider).active &&
              ref.read(searchSessionProvider).focusRequest ==
                  search.focusRequest &&
              ref.read(searchSessionProvider).category == search.category &&
              ref.read(searchSessionProvider).query == search.query);
  final current = ref.read(workspaceControllerProvider).workspace;
  bool opened = false;
  if (resource.accountId != null) {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!context.mounted || !currentRequest()) return;
    final account = repository.accounts
        .where((a) => a.id == resource.accountId)
        .firstOrNull;
    final note = resource.localId == null
        ? null
        : repository.noteById(resource.localId!);
    if (account == null ||
        resource.isDocument &&
            (note?.accountId != resource.accountId ||
                isNotesRecovery(note!) ||
                repository.isCreationCandidateBinding(note.localId))) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.searchResourceUnavailable,
      );
      return;
    }
    if (current?.nextcloudAccountId != resource.accountId) {
      if (!await confirmSafeToContinue(context, ref) ||
          !context.mounted ||
          !currentRequest()) {
        return;
      }
      if (!await controller.openNextcloudWorkspace(
        resource.accountId!,
        acceptNavigation: currentRequest,
      )) {
        return;
      }
    }
    opened =
        resource.localId == null ||
        await controller.openNextcloudNote(
          resource.localId!,
          acceptNavigation: currentRequest,
        );
  } else {
    if (!await FileSystemEntity.isFile(resource.path) &&
        !await Directory(resource.path).exists()) {
      if (context.mounted) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
      }
      return;
    }
    if (!context.mounted || !currentRequest()) return;
    final sameOwner =
        current != null &&
        (resource.ownerRoot != null
            ? p.equals(current.rootPath, resource.ownerRoot!)
            : current.files.any(
                (f) => p.equals(f.absolutePath, resource.path),
              ));
    if (resource.isDocument && sameOwner) {
      opened = await controller.openActiveFile(
        resource.path,
        acceptNavigation: currentRequest,
      );
    } else {
      if (!await confirmSafeToContinue(context, ref) ||
          !context.mounted ||
          !currentRequest()) {
        return;
      }
      await controller.openPath(
        resource.ownerRoot ?? resource.path,
        acceptNavigation: currentRequest,
      );
      if (!context.mounted || !currentRequest()) return;
      final workspace = ref.read(workspaceControllerProvider).workspace;
      if (workspace == null) return;
      if (resource.ownerRoot != null &&
          workspace.writersideProject == null &&
          workspace.writersideModule == null) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
        return;
      }
      opened =
          resource.ownerRoot == null ||
          await controller.openActiveFile(
            resource.path,
            acceptNavigation: currentRequest,
          );
    }
  }
  if (opened && context.mounted) {
    await ref
        .read(appSettingsControllerProvider.notifier)
        .recordRecent(
          RecentResource(
            path: resource.path,
            kind: resource.kind,
            accountId: resource.accountId,
            accountLabel: resource.accountLabel,
            localId: resource.localId,
            title: resource.title,
            ownerRoot: resource.ownerRoot,
            document: resource.isDocument,
            lastOpenedAt: DateTime.now(),
          ),
        );
    if (!context.mounted || !currentRequest()) return;
    revealOpenedDocument(ref);
    ref.read(searchSessionProvider.notifier).close(restoreFocus: false);
    context.go('/workspace');
  }
}

enum RecentNavigationAction { openInFiles, copyPath, removeFromRecent }

Future<void> runRecentNavigationAction(
  BuildContext context,
  WidgetRef ref,
  RecentResource resource,
  RecentNavigationAction action,
) async {
  switch (action) {
    case RecentNavigationAction.removeFromRecent:
      await ref
          .read(appSettingsControllerProvider.notifier)
          .removeRecentWorkspace(resource.identity);
    case RecentNavigationAction.copyPath:
      await Clipboard.setData(ClipboardData(text: resource.path));
    case RecentNavigationAction.openInFiles:
      final type = await FileSystemEntity.type(resource.path);
      if (!context.mounted) return;
      if (type == FileSystemEntityType.notFound) {
        BusyMarkToastOverlay.show(
          context,
          message: context.l10n.searchResourceUnavailable,
        );
        return;
      }
      await launchUrl(
        Uri.directory(
          type == FileSystemEntityType.directory
              ? resource.path
              : p.dirname(resource.path),
        ),
      );
  }
}
