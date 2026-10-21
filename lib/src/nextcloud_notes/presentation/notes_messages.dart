import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../domain/notes_models.dart';
import '../data/server_uri.dart';
import '../data/login_flow.dart';
import '../data/notes_secret_store.dart';
import '../data/notes_capabilities.dart';
import '../application/notes_transfer_service.dart';
import '../application/notes_navigation.dart';

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

String localizeNotesTransferFailure(
  BuildContext context,
  NotesTransferFailureReason reason, {
  bool exporting = false,
}) => switch (reason) {
  NotesTransferFailureReason.sourceChanged ||
  NotesTransferFailureReason.exportChanged =>
    context.l10n.notesTransferSourceChanged,
  NotesTransferFailureReason.sourceUnreadable =>
    context.l10n.notesTransferUnreadable,
  NotesTransferFailureReason.invalidSnapshot =>
    context.l10n.notesTransferInvalidSnapshot,
  NotesTransferFailureReason.mediaTooLarge =>
    context.l10n.notesTransferMediaLimit,
  NotesTransferFailureReason.unsafeSource =>
    context.l10n.notesTransferUnsafeSource,
  NotesTransferFailureReason.destinationUnavailable =>
    context.l10n.notesTransferDestination,
  NotesTransferFailureReason.operation =>
    exporting
        ? context.l10n.notesExportOperationFailed
        : context.l10n.notesTransferOperationFailed,
};

String localizeNotesBatchReason(
  BuildContext context,
  NotesBatchOutcome outcome,
) => switch (outcome.reason) {
  NotesBatchReason.unchanged => context.l10n.notesBatchUnchanged,
  NotesBatchReason.readOnly => context.l10n.notesBatchReadOnly,
  NotesBatchReason.reviewChanged => context.l10n.notesBatchReviewChanged,
  NotesBatchReason.needsReview => context.l10n.notesRecoveryRequired,
  NotesBatchReason.missing => context.l10n.notesBatchMissing,
  NotesBatchReason.storage => context.l10n.notesBatchStorage,
  NotesBatchReason.editorNotSaved => context.l10n.notesBuffersNotSaved,
  NotesBatchReason.unavailable => localizeNotesFailure(context, outcome.cause),
  null => '',
};

String localizeNotesConnectionFailure(
  BuildContext context,
  Object? error,
) => switch (error) {
  NextcloudCredentialException() => localizeNotesFailure(context, error),
  NextcloudServerUrlException() => context.l10n.notesAccountServerAddress,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.unsupported) =>
    context.l10n.notesAccountUnsupported,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.unauthorized) ||
  NotesException(
    code: NotesFailureCode.authentication,
  ) => context.l10n.notesAccountAuthorizeAgain,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.forbidden) ||
  NotesException(
    code: NotesFailureCode.forbidden,
  ) => context.l10n.notesAccountCheckForbidden,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.throttled) ||
  NotesException(
    code: NotesFailureCode.throttled,
  ) => context.l10n.notesAccountThrottled,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.malformed) ||
  NextcloudLoginException(code: NextcloudLoginFailure.malformedResponse) ||
  NotesException(
    code: NotesFailureCode.invalidResponse,
  ) => context.l10n.notesAccountMalformed,
  NextcloudLoginException(code: NextcloudLoginFailure.unsafeRedirect) =>
    context.l10n.notesAccountServerAddress,
  NextcloudLoginException(code: NextcloudLoginFailure.timedOut) =>
    context.l10n.notesAccountTimedOut,
  NextcloudLoginException(code: NextcloudLoginFailure.browserUnavailable) =>
    context.l10n.notesAccountBrowserUnavailable,
  NextcloudLoginException(code: NextcloudLoginFailure.cancelled) =>
    context.l10n.notesCancelled,
  NextcloudLoginException(
    code: NextcloudLoginFailure.network || NextcloudLoginFailure.server,
  ) ||
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.network) ||
  NotesException(
    code: NotesFailureCode.network || NotesFailureCode.server,
  ) => context.l10n.notesAccountNetwork,
  NextcloudCapabilityException(code: NextcloudCapabilityFailure.rejected) =>
    context.l10n.notesAccountRejected,
  _ => context.l10n.notesAccountFailed,
};
