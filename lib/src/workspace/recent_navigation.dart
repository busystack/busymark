import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_settings.dart';
import '../app/busymark_toast.dart';
import '../app/localization.dart';
import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../search/search_session.dart';
import 'workspace_navigation.dart';
import 'workspace_controller.dart';

Future<void> openRecentResource(WidgetRef ref, RecentResource resource) {
  final navigation = ref.read(workspaceNavigationProvider);
  return navigation.run(
    (recent: resource.identity),
    (_, currentRequest) =>
        _openRecentResource(navigation, resource, currentRequest),
  );
}

Future<void> _openRecentResource(
  WorkspaceNavigation navigation,
  RecentResource resource,
  bool Function() currentNavigation,
) async {
  final container = navigation.container;
  final controller = container.read(workspaceControllerProvider.notifier);
  final search = container.read(searchSessionProvider);
  bool currentRequest() {
    if (!currentNavigation()) return false;
    final live = container.read(searchSessionProvider);
    return live.requestRevision == search.requestRevision &&
        (!search.active ||
            live.active &&
                live.focusRequest == search.focusRequest &&
                live.category == search.category &&
                live.query == search.query);
  }

  final current = container.read(workspaceControllerProvider).workspace;
  void unavailable() {
    if (currentRequest()) {
      navigation.showUnavailable();
    }
  }

  late final bool opened;
  if (resource.accountId case final accountId?) {
    final repository = await container.read(
      nextcloudNotesRepositoryProvider.future,
    );
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
      if (!await navigation.confirmDeparture(
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
      if (!await navigation.confirmDeparture(
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
    navigation.reveal();
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
