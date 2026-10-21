import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../domain/notes_models.dart';
import '../data/server_uri.dart';
import '../data/login_flow.dart';
import '../data/notes_secret_store.dart';

/// Presentation is selected by typed failures, never by persisted English text.
String localizeNotesFailure(BuildContext context, Object? error) {
  final l10n = context.l10n;
  return switch (error) {
    NextcloudServerUrlException() =>
      '${l10n.nextcloudServer} · HTTPS · ${l10n.notesFailed}',
    NextcloudLoginException(
      code: NextcloudLoginFailure.network || NextcloudLoginFailure.server,
    ) =>
      l10n.notesUnavailable,
    NextcloudLoginException(code: NextcloudLoginFailure.browserUnavailable) =>
      '${l10n.nextcloudSignInBrowser} ${l10n.visualizationRetry}',
    NextcloudCredentialException(
      code: NextcloudCredentialFailure.identityMismatch ||
          NextcloudCredentialFailure.alreadyConnected,
    ) =>
      l10n.notesAccountMismatch,
    NextcloudCredentialException() => l10n.notesKeyringUnavailable,
    NotesException(code: NotesFailureCode.authentication) =>
      l10n.nextcloudReconnectRequired,
    NotesException(code: NotesFailureCode.forbidden) => l10n.nextcloudReadOnly,
    NotesException(code: NotesFailureCode.conflict) =>
      l10n.notesRecoveryRequired,
    NotesException(code: NotesFailureCode.locked) => l10n.nextcloudLocked,
    NotesException(code: NotesFailureCode.storageFull) => l10n.notesStorageFull,
    NotesException(code: NotesFailureCode.throttled) => l10n.notesThrottled,
    NotesException(code: NotesFailureCode.network || NotesFailureCode.server) =>
      l10n.notesUnavailable,
    NotesException(code: NotesFailureCode.rejected) => l10n.notesRejected,
    _ => l10n.notesOperationFailed,
  };
}

String notesLocalDate(BuildContext context, DateTime value) {
  final date = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatShortDate(date)} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}

String localizeNotesConnectionFailure(BuildContext context, Object? error) =>
    switch (error) {
      NextcloudCredentialException() ||
      NextcloudServerUrlException() ||
      NextcloudLoginException() => localizeNotesFailure(context, error),
      _ => context.l10n.notesConnectFailed,
    };
