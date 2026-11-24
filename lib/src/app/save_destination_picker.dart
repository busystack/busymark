import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/save_destination.dart';
import 'busymark_design.dart';
import 'busymark_dialogs.dart';
import 'busymark_native_controls.dart';
import 'busymark_toast.dart';
import 'localization.dart';

const _saveChooser = MethodChannel('busymark/save_chooser');

/// Use GTK's save dialog for a single file. GtkFileChooserNative and the
/// FileChooser portal return a pathname without the pre-confirmation review.
Future<SaveDestination?> pickSaveDestination(
  BuildContext context, {
  required String suggestedName,
  required String actionLabel,
  required String filterLabel,
  required List<String> patterns,
  String? initialDirectory,
  String? suffix,
  bool suffixOnlyWhenMissing = false,
  SaveDestinationKind kind = SaveDestinationKind.file,
  bool Function()? isCurrent,
}) async {
  try {
    final review = await _saveChooser
        .invokeMapMethod<Object?, Object?>('save', {
          'suggestedName': SaveDestination.withSuffix(
            suggestedName,
            suffix,
            onlyWhenMissing: suffixOnlyWhenMissing,
          ),
          'actionLabel': actionLabel,
          'cancelLabel': context.l10n.cancel,
          'filterLabel': filterLabel,
          'patterns': patterns,
          'initialDirectory': initialDirectory,
          'suffix': suffix,
          'suffixOnlyWhenMissing': suffixOnlyWhenMissing,
          'allowLink': kind == SaveDestinationKind.fileOrSymbolicLink,
        });
    if (review == null || !context.mounted || isCurrent?.call() == false) {
      return null;
    }
    final destination = SaveDestination.fromChooserReview(review, kind: kind);
    if (SaveDestination.withSuffix(
          destination.path,
          suffix,
          onlyWhenMissing: suffixOnlyWhenMissing,
        ) !=
        destination.path) {
      throw const FormatException('Unexpected native save filename extension');
    }
    return destination;
  } on Object catch (error) {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message:
            error is PlatformException ||
                error is FileSystemException ||
                error is FormatException
            ? context.l10n.errorFileOperationInvalidTarget
            : error.toString(),
        priority: BusyMarkToastPriority.high,
      );
    }
    return null;
  }
}

Future<SaveDestination?> pickHtmlSiteDestination(
  BuildContext context, {
  required String suggestedName,
  String? initialDirectory,
  required Future<void> Function(String path) validateReplacement,
}) async {
  String? selectedFolder;
  try {
    selectedFolder = await getDirectoryPath(
      initialDirectory: initialDirectory,
      confirmButtonText: context.l10n.chooseLocation,
    );
  } on PlatformException catch (error) {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: error.message ?? context.l10n.errorFileOperationInvalidTarget,
        priority: BusyMarkToastPriority.high,
      );
    }
    return null;
  }
  final folder = selectedFolder;
  if (folder == null || !context.mounted) return null;
  final name = await showBusyMarkModalDialog<String>(
    context,
    builder: (context) =>
        _SiteDirectoryName(folder: folder, suggestedName: suggestedName),
  );
  if (name == null || !context.mounted) return null;
  return confirmSaveDestination(
    context,
    p.join(folder, name),
    kind: SaveDestinationKind.directory,
    replacementDetails: context.l10n.htmlOwnedDirectoryOnly,
    validateReplacement: validateReplacement,
  );
}

Future<SaveDestination?> confirmSaveDestination(
  BuildContext context,
  String path, {
  SaveDestinationKind kind = SaveDestinationKind.file,
  bool Function()? isCurrent,
  Future<void> Function(String path)? validateReplacement,
  String? replacementDetails,
  String? operation,
}) async {
  if (!context.mounted || isCurrent?.call() == false) return null;
  try {
    final destination = SaveDestination.inspect(path, kind: kind);
    if (!destination.replacesExisting) return destination;
    if (validateReplacement != null) {
      await validateReplacement(destination.path);
    }
    if (!context.mounted || isCurrent?.call() == false) return null;
    final accepted = await showBusyMarkModalDialog<bool>(
      context,
      builder: (context) => BusyMarkAlert(
        heading:
            operation ??
            context.l10n.errorPathAlreadyExists(p.basename(destination.path)),
        responses: [
          BusyMarkAlertResponse(
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          BusyMarkAlertResponse(
            label: context.l10n.overwrite,
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        children: [
          if (operation != null)
            Text(
              context.l10n.errorPathAlreadyExists(p.basename(destination.path)),
            ),
          Text(destination.path, textDirection: TextDirection.ltr),
          if (replacementDetails != null) Text(replacementDetails),
        ],
      ),
    );
    if (accepted != true || !context.mounted || isCurrent?.call() == false) {
      return null;
    }
    destination.requireCurrent(destination.path);
    return destination;
  } on Object catch (error) {
    if (context.mounted) {
      BusyMarkToastOverlay.show(
        context,
        message: error is FileSystemException
            ? context.l10n.errorFileOperationInvalidTarget
            : error.toString(),
        priority: BusyMarkToastPriority.high,
      );
    }
    return null;
  }
}

class _SiteDirectoryName extends StatefulWidget {
  const _SiteDirectoryName({required this.folder, required this.suggestedName});

  final String folder;
  final String suggestedName;

  @override
  State<_SiteDirectoryName> createState() => _SiteDirectoryNameState();
}

class _SiteDirectoryNameState extends State<_SiteDirectoryName> {
  late final _name = TextEditingController(text: widget.suggestedName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: p.basenameWithoutExtension(widget.suggestedName).length,
    );

  String? get _destinationName {
    final name = _name.text;
    if (name.trim().isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\u0000')) {
      return null;
    }
    return name;
  }

  void _accept() {
    if (_destinationName case final name?) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BusyMarkNativeDialogShell(
    title: context.l10n.export,
    actions: [
      BusyMarkNativeDialogButton(
        label: context.l10n.cancel,
        onPressed: () => Navigator.pop(context),
      ),
      BusyMarkNativeDialogButton(
        label: context.l10n.export,
        suggested: true,
        onPressed: _destinationName == null ? null : _accept,
      ),
    ],
    children: [
      Text(widget.folder),
      const SizedBox(height: BusyMarkSpacing.md),
      BusyMarkNativeTextEntry(
        label: context.l10n.folder,
        autofocus: true,
        controller: _name,
        textDirection: TextDirection.ltr,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _accept(),
      ),
    ],
  );
}
