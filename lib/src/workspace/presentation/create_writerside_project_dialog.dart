import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../app/busymark_design.dart';
import '../../app/localization.dart';
import '../../core/path_utils.dart';
import '../../writerside/writerside_project_creator.dart';
import '../workspace_message.dart';

class BusyMarkCreateWritersideProjectDialog extends StatefulWidget {
  const BusyMarkCreateWritersideProjectDialog({
    super.key,
    required this.parentDirectoryPath,
    required this.onCreate,
    required this.message,
  });

  final String parentDirectoryPath;
  final Future<bool> Function(WritersideProjectCreateRequest request) onCreate;
  final WorkspaceMessage? Function() message;

  @override
  State<BusyMarkCreateWritersideProjectDialog> createState() =>
      _BusyMarkCreateWritersideProjectDialogState();
}

class _BusyMarkCreateWritersideProjectDialogState
    extends State<BusyMarkCreateWritersideProjectDialog> {
  static final _directorySlugCharacterPattern = RegExp(
    r'[\p{L}\p{M}\p{N}_-]',
    unicode: true,
  );

  late final TextEditingController _projectNameController;
  late final TextEditingController _directoryNameController;
  late final TextEditingController _instanceNameController;
  late final TextEditingController _instanceIdController;
  late final TextEditingController _topicTitleController;
  late String _lastGeneratedDirectoryName;
  late String _lastGeneratedInstanceId;
  var _directoryEdited = false;
  var _syncingDirectory = false;
  var _instanceIdEdited = false;
  var _syncingInstanceId = false;
  var _creating = false;
  String? _creationError;
  var _localizedDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController()
      ..addListener(_handleProjectNameChanged);
    _lastGeneratedDirectoryName = _slugDirectoryName('');
    _directoryNameController = TextEditingController(
      text: _lastGeneratedDirectoryName,
    )..addListener(_handleDirectoryNameChanged);
    _instanceNameController = TextEditingController()
      ..addListener(_handleInstanceNameChanged);
    _lastGeneratedInstanceId = 'user-guide';
    _instanceIdController = TextEditingController(
      text: _lastGeneratedInstanceId,
    )..addListener(_handleInstanceIdChanged);
    _topicTitleController = TextEditingController()
      ..addListener(_handleFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) {
      return;
    }
    _localizedDefaultsApplied = true;
    _instanceNameController.text = context.l10n.defaultInstanceName;
    _topicTitleController.text = context.l10n.defaultStartTopicTitle;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _directoryNameController.dispose();
    _instanceNameController.dispose();
    _instanceIdController.dispose();
    _topicTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final projectError = _projectNameError(context);
    final directoryError = _directoryNameError(context);
    final instanceIdError = _instanceIdError(context);
    final topicTitleError = _topicTitleError(context);
    final canCreate =
        !_creating &&
        projectError == null &&
        directoryError == null &&
        instanceIdError == null &&
        topicTitleError == null;
    return PopScope(
      canPop: !_creating,
      child: BusyMarkModalEditorScaffold(
        title: context.l10n.createWritersideProject,
        cancelLabel: context.l10n.cancel,
        saveLabel: context.l10n.create,
        onCancel: () => Navigator.pop(context),
        cancelEnabled: !_creating,
        onSave: canCreate ? _submit : null,
        saving: _creating,
        children: [
          BusyMarkGroupedList(
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                label: context.l10n.projectName,
                controller: _projectNameController,
                textInputAction: TextInputAction.next,
                errorText: projectError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.directoryName,
                controller: _directoryNameController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                errorText: directoryError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.instanceName,
                controller: _instanceNameController,
                textInputAction: TextInputAction.next,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.instanceId,
                controller: _instanceIdController,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                errorText: instanceIdError,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.startTopicTitle,
                controller: _topicTitleController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (canCreate) {
                    _submit();
                  }
                },
                errorText: topicTitleError,
              ),
            ],
          ),
          if (_creationError != null) ...[
            const SizedBox(height: BusyMarkSpacing.md),
            BusyMarkStatusBox(
              message: _creationError!,
              kind: BusyMarkStatusKind.error,
            ),
          ],
          BusyMarkGroupedList(
            title: context.l10n.location,
            filled: true,
            children: [
              BusyMarkListTile.square(
                title: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    _targetPath,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.foreground),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BusyMarkSpacing.lg),
        ],
      ),
    );
  }

  String? _projectNameError(BuildContext context) {
    if (_projectNameController.text.trim().isEmpty) {
      return context.l10n.projectNameRequired;
    }
    return null;
  }

  String? _directoryNameError(BuildContext context) {
    final value = _directoryNameController.text.trim();
    if (value.isEmpty) {
      return context.l10n.directoryNameRequired;
    }
    if (value == '.' ||
        value == '..' ||
        p.isAbsolute(value) ||
        value.contains('..') ||
        value.contains('/') ||
        value.contains(r'\')) {
      return context.l10n.useSingleSafeDirectoryName;
    }
    return null;
  }

  String? _instanceIdError(BuildContext context) {
    final value = _instanceIdController.text.trim();
    if (!WritersideProjectCreator.isValidInstanceId(value)) {
      return context.l10n.useLowercaseIdentifier;
    }
    return null;
  }

  String? _topicTitleError(BuildContext context) {
    if (_topicTitleController.text.trim().isEmpty) {
      return context.l10n.startTopicTitleRequired;
    }
    return null;
  }

  String get _targetPath {
    final directoryName = _directoryNameController.text.trim();
    final safeDirectoryName = directoryName.isEmpty
        ? _slugDirectoryName(_projectNameController.text)
        : directoryName;
    return p.join(normalizePath(widget.parentDirectoryPath), safeDirectoryName);
  }

  void _handleProjectNameChanged() {
    _creationError = null;
    final nextDirectoryName = _slugDirectoryName(_projectNameController.text);
    if (!_directoryEdited ||
        _directoryNameController.text == _lastGeneratedDirectoryName) {
      _syncingDirectory = true;
      _lastGeneratedDirectoryName = nextDirectoryName;
      _directoryNameController.text = nextDirectoryName;
      _syncingDirectory = false;
      _directoryEdited = false;
    }
    setState(() {});
  }

  void _handleDirectoryNameChanged() {
    _creationError = null;
    if (!_syncingDirectory) {
      _directoryEdited =
          _directoryNameController.text != _lastGeneratedDirectoryName;
    }
    setState(() {});
  }

  void _handleInstanceNameChanged() {
    _creationError = null;
    final nextInstanceId = _slugInstanceId(_instanceNameController.text);
    if (!_instanceIdEdited ||
        _instanceIdController.text == _lastGeneratedInstanceId) {
      _syncingInstanceId = true;
      _lastGeneratedInstanceId = nextInstanceId;
      _instanceIdController.text = nextInstanceId;
      _syncingInstanceId = false;
      _instanceIdEdited = false;
    }
    setState(() {});
  }

  void _handleInstanceIdChanged() {
    _creationError = null;
    if (!_syncingInstanceId) {
      _instanceIdEdited =
          _instanceIdController.text != _lastGeneratedInstanceId;
    }
    setState(() {});
  }

  void _handleFieldChanged() {
    _creationError = null;
    setState(() {});
  }

  Future<void> _submit() async {
    if (_creating ||
        _projectNameError(context) != null ||
        _directoryNameError(context) != null ||
        _instanceIdError(context) != null ||
        _topicTitleError(context) != null) {
      return;
    }
    setState(() {
      _creating = true;
      _creationError = null;
    });
    final created = await widget.onCreate(
      WritersideProjectCreateRequest(
        parentDirectoryPath: normalizePath(widget.parentDirectoryPath),
        projectName: _projectNameController.text.trim(),
        directoryName: _directoryNameController.text.trim(),
        instanceName: _instanceNameController.text.trim().isEmpty
            ? context.l10n.defaultInstanceName
            : _instanceNameController.text.trim(),
        instanceId: _instanceIdController.text.trim(),
        topicTitle: _topicTitleController.text.trim(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (created) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _creating = false;
      final message = widget.message();
      _creationError = message == null
          ? context.l10n.createWritersideProjectFailed
          : localizeWorkspaceMessage(context, message);
    });
  }

  String _slugDirectoryName(String value) {
    final buffer = StringBuffer();
    var pendingSeparator = false;
    for (final rune in value.toLowerCase().trim().runes) {
      final character = String.fromCharCode(rune);
      if (_directorySlugCharacterPattern.hasMatch(character)) {
        if (pendingSeparator && buffer.isNotEmpty) {
          buffer.write('-');
        }
        buffer.write(character);
        pendingSeparator = false;
      } else {
        pendingSeparator = true;
      }
    }
    final slug = buffer.toString().replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    return slug.isEmpty ? 'writerside-project' : slug;
  }

  String _slugInstanceId(String value) {
    return WritersideProjectCreator.slugInstanceId(value);
  }
}
