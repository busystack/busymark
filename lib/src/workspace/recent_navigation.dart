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
import '../search/search_session.dart';
import 'document_navigation.dart';
import 'workspace_controller.dart';
import 'workspace_safety.dart';

final _recentNavigationProvider = Provider((ref) => _RecentNavigation());

class _RecentNavigation {
  bool opening = false;
}

Future<void> openRecentResource(
  BuildContext context,
  WidgetRef ref,
  RecentResource resource,
) async {
  final navigation = ref.read(_recentNavigationProvider);
  if (navigation.opening) return;
  navigation.opening = true;
  try {
    await _openRecentResource(context, ref, resource);
  } finally {
    navigation.opening = false;
  }
}

Future<void> _openRecentResource(
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
  void unavailable() {
    if (currentRequest()) {
      BusyMarkToastOverlay.show(
        context,
        message: context.l10n.searchResourceUnavailable,
      );
    }
  }

  late final bool opened;
  if (resource.accountId case final accountId?) {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    if (!currentRequest()) return;
    bool available() {
      if (repository.accountById(accountId) == null) return false;
      if (!resource.isDocument) return true;
      final localId = resource.localId;
      return localId != null &&
          repository.availableRecentNote(accountId, localId) != null;
    }

    if (!available()) {
      unavailable();
      return;
    }
    if (current?.nextcloudAccountId == accountId) {
      opened =
          resource.localId == null ||
          await controller.openNextcloudNote(
            resource.localId!,
            acceptNavigation: () => currentRequest() && available(),
          );
    } else {
      if (!context.mounted) return;
      if (!await confirmSafeToContinue(
            context,
            ref,
            canContinue: () => currentRequest() && available(),
          ) ||
          !currentRequest()) {
        if (!available()) unavailable();
        return;
      }
      opened = await controller.openNextcloudWorkspace(
        accountId,
        noteLocalId: resource.localId,
        acceptNavigation: currentRequest,
      );
    }
  } else {
    bool available() {
      final type = FileSystemEntity.typeSync(resource.path);
      return (resource.isDocument
              ? type == FileSystemEntityType.file
              : type == FileSystemEntityType.file ||
                    type == FileSystemEntityType.directory) &&
          (resource.ownerRoot == null ||
              Directory(resource.ownerRoot!).existsSync());
    }

    if (!available()) {
      unavailable();
      return;
    }
    final currentRoot = current?.filesystemRootPath;
    final sameOwner =
        currentRoot != null &&
        (resource.ownerRoot != null
            ? (current!.writersideProject != null ||
                      current.writersideModule != null) &&
                  p.equals(currentRoot, resource.ownerRoot!)
            : current!.files.any(
                (file) => p.equals(file.absolutePath, resource.path),
              ));
    if (resource.isDocument && sameOwner) {
      opened = await controller.openActiveFile(
        resource.path,
        acceptNavigation: currentRequest,
      );
    } else {
      if (!await confirmSafeToContinue(
            context,
            ref,
            canContinue: () => currentRequest() && available(),
          ) ||
          !currentRequest()) {
        if (!available()) unavailable();
        return;
      }
      var published = false;
      await controller.openPath(
        resource.ownerRoot ?? resource.path,
        documentPath: resource.ownerRoot == null ? null : resource.path,
        acceptNavigation: currentRequest,
        onOpened: () => published = true,
      );
      opened = published;
    }
  }
  if (!opened) {
    unavailable();
    return;
  }
  if (currentRequest()) {
    await controller.recordRecentResource(
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
