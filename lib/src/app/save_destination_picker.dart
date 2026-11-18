import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/save_destination.dart';
import 'busymark_design.dart';
import 'busymark_dialogs.dart';
import 'busymark_native_controls.dart';
import 'busymark_toast.dart';
import 'localization.dart';

/// The native folder chooser works through the desktop portal and GTK.
/// SaveFile responses provide neither the chosen entry's identity nor a
/// portable indication of overwrite consent. BusyMark owns the name and the
/// single confirmation, so both backends use the same authorization contract.
Future<SaveDestination?> pickSaveDestination(
  BuildContext context, {
  required String suggestedName,
  required String actionLabel,
  String? initialDirectory,
  String? suffix,
  bool suffixOnlyWhenMissing = false,
  SaveDestinationKind kind = SaveDestinationKind.file,
  bool Function()? isCurrent,
  Future<void> Function(String path)? validateReplacement,
  String? replacementDetails,
}) async {
  final path = await chooseSaveDestinationPath(
    context,
    suggestedName: suggestedName,
    actionLabel: actionLabel,
    initialDirectory: initialDirectory,
    suffix: suffix,
    suffixOnlyWhenMissing: suffixOnlyWhenMissing,
    isCurrent: isCurrent,
  );
  if (path == null || !context.mounted) return null;
  return confirmSaveDestination(
    context,
    path,
    kind: kind,
    isCurrent: isCurrent,
    validateReplacement: validateReplacement,
    replacementDetails: replacementDetails,
  );
}

Future<String?> chooseSaveDestinationPath(
  BuildContext context, {
  required String suggestedName,
  required String actionLabel,
  String? initialDirectory,
  String? suffix,
  bool suffixOnlyWhenMissing = false,
  bool Function()? isCurrent,
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
  if (folder == null || !context.mounted || isCurrent?.call() == false) {
    return null;
  }
  final name = await showBusyMarkModalDialog<String>(
    context,
    builder: (context) => _SaveDestinationName(
      folder: folder,
      suggestedName: suggestedName,
      actionLabel: actionLabel,
      suffix: suffix,
      suffixOnlyWhenMissing: suffixOnlyWhenMissing,
    ),
  );
  if (name == null || !context.mounted || isCurrent?.call() == false) {
    return null;
  }
  return p.join(folder, name);
}

Future<SaveDestination?> confirmSaveDestination(
  BuildContext context,
  String path, {
  SaveDestinationKind kind = SaveDestinationKind.file,
  bool Function()? isCurrent,
  Future<void> Function(String path)? validateReplacement,
  String? replacementDetails,
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
        heading: context.l10n.errorPathAlreadyExists(
          p.basename(destination.path),
        ),
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
          Text(destination.path),
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

class _SaveDestinationName extends StatefulWidget {
  const _SaveDestinationName({
    required this.folder,
    required this.suggestedName,
    required this.actionLabel,
    required this.suffix,
    required this.suffixOnlyWhenMissing,
  });

  final String folder;
  final String suggestedName;
  final String actionLabel;
  final String? suffix;
  final bool suffixOnlyWhenMissing;

  @override
  State<_SaveDestinationName> createState() => _SaveDestinationNameState();
}

class _SaveDestinationNameState extends State<_SaveDestinationName> {
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
    return SaveDestination.withSuffix(
      name,
      widget.suffix,
      onlyWhenMissing: widget.suffixOnlyWhenMissing,
    );
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
    title: widget.actionLabel,
    actions: [
      BusyMarkNativeDialogButton(
        label: context.l10n.cancel,
        onPressed: () => Navigator.pop(context),
      ),
      BusyMarkNativeDialogButton(
        label: widget.actionLabel,
        suggested: true,
        onPressed: _destinationName == null ? null : _accept,
      ),
    ],
    children: [
      Text(widget.folder),
      const SizedBox(height: BusyMarkSpacing.md),
      BusyMarkNativeTextEntry(
        label: context.l10n.fileName,
        autofocus: true,
        controller: _name,
        textDirection: TextDirection.ltr,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _accept(),
      ),
      if (_destinationName case final name? when name != _name.text) Text(name),
    ],
  );
}
