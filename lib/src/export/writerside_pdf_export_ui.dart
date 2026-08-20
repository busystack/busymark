import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/app_settings.dart';
import '../app/busymark_dialogs.dart';
import '../app/busymark_design.dart';
import '../app/localization.dart';
import '../platform/linux_header_bar_service.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../workspace/workspace_safety.dart';
import '../writerside/writerside_model.dart';
import 'markdown_pdf_models.dart';
import 'writerside_pdf_export_service.dart';
import 'writerside_pdf_models.dart';

final writersidePdfExportServiceProvider = Provider<WritersidePdfExportService>(
  (ref) => const WritersidePdfExportService(),
);

bool canExportWritersidePdf(WorkspaceState state) {
  final workspace = state.workspace;
  final module = workspace?.writersideModule;
  return workspace?.kind == WorkspaceKind.writersideModule &&
      module != null &&
      module.instances.any((instance) => !instance.isLibrary);
}

String defaultWritersideBuilderModuleName(WritersideModule module) {
  final configured = module.config.moduleName?.trim();
  return configured == null || configured.isEmpty
      ? p.basename(p.normalize(module.rootPath))
      : configured;
}

Future<void> exportWritersideModuleToPdf(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!canExportWritersidePdf(ref.read(workspaceControllerProvider))) {
    return;
  }
  if (!await confirmSafeToContinue(context, ref) || !context.mounted) {
    return;
  }
  final snapshot = ref.read(workspaceControllerProvider);
  final workspace = snapshot.workspace;
  final module = workspace?.writersideModule;
  if (workspace == null || module == null) {
    return;
  }
  final service = ref.read(writersidePdfExportServiceProvider);
  final regularInstances = module.instances
      .where((instance) => !instance.isLibrary)
      .toList(growable: false);
  final projectConfigurations = await service.discoverProjectConfigurations(
    moduleRoot: module.rootPath,
    buildConfigDirectory: module.config.buildConfigDir,
  );
  final layouts = <String, List<WritersidePdfKeymapLayout>>{};
  for (final instance in regularInstances) {
    layouts[instance.id] = await service.discoverLayouts(
      moduleRoot: module.rootPath,
      buildConfigDirectory: module.config.buildConfigDir,
      instanceId: instance.id,
    );
  }
  if (!context.mounted) {
    return;
  }
  final storedInstanceId = ref
      .read(appSettingsControllerProvider)
      .selectedWritersideInstanceId(workspace.rootPath);
  final initialInstance = regularInstances
      .where((instance) => instance.id == storedInstanceId)
      .firstOrNull;
  final headerBar = ref.read(linuxHeaderBarServiceProvider);
  final selection =
      await showBusyMarkModalEditorDialog<_WritersidePdfSelection>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        maxWidth: BusyMarkSizes.dialogWide,
        maxHeight: 820,
        builder: (context) => _WritersidePdfOptionsDialog(
          module: module,
          instances: regularInstances,
          initialInstance: initialInstance ?? regularInstances.first,
          projectConfigurations: projectConfigurations,
          layouts: layouts,
        ),
      );
  if (selection == null || !context.mounted) {
    return;
  }
  unawaited(
    ref
        .read(appSettingsControllerProvider.notifier)
        .selectWritersideInstance(workspace.rootPath, selection.instance.id),
  );

  final builderReady = await _ensureBuilder(
    context,
    headerBar,
    service,
    selection.builderVersion,
  );
  if (!builderReady || !context.mounted) {
    return;
  }
  final location = await getSaveLocation(
    acceptedTypeGroups: [
      XTypeGroup(
        label: context.l10n.fileTypePdf,
        extensions: const ['pdf'],
        mimeTypes: const ['application/pdf'],
      ),
    ],
    suggestedName: '${selection.instance.id}.pdf',
    initialDirectory: module.rootPath,
    confirmButtonText: context.l10n.export,
  );
  if (location == null || !context.mounted) {
    return;
  }
  final destination = _withPdfExtension(location.path);
  var overwrite = false;
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    if (!context.mounted ||
        !await _confirmOverwrite(context, headerBar, destination)) {
      return;
    }
    overwrite = true;
  }
  if (!context.mounted) {
    return;
  }
  final request = WritersidePdfExportRequest(
    moduleRoot: module.rootPath,
    sourceRoot: selection.sourceRoot,
    moduleName: selection.moduleName,
    buildConfigDirectory: module.config.buildConfigDir,
    instanceId: selection.instance.id,
    destinationPath: destination,
    overwrite: overwrite,
    builderVersion: selection.builderVersion,
    configurationMode: selection.configurationMode,
    options: selection.options,
    projectConfigurationPath: selection.projectConfigurationPath,
    allowNetwork: selection.allowNetwork,
  );
  final cancellationToken = WritersidePdfCancellationToken();
  final outcome = await showBusyMarkModalDialog<_WritersidePdfOutcome>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    barrierDismissible: false,
    builder: (context) => _WritersidePdfProgressDialog(
      cancellationToken: cancellationToken,
      operation: () =>
          service.export(request, cancellationToken: cancellationToken),
    ),
  );
  if (outcome == null || !context.mounted) {
    return;
  }
  if (outcome.failure case final failure?) {
    if (failure.code != WritersidePdfFailureCode.cancelled) {
      await _showWritersidePdfError(context, headerBar, failure);
    }
    return;
  }
  final result = outcome.result!;
  final fileName = p.basename(result.destinationPath);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.pdfExported(fileName)),
      action: SnackBarAction(
        label: context.l10n.open,
        onPressed: () => unawaited(
          launchUrl(
            Uri.file(result.destinationPath),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    ),
  );
}

Future<bool> _ensureBuilder(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  WritersidePdfExportService service,
  String version,
) async {
  try {
    if (await service.isBuilderAvailable(version)) {
      return true;
    }
  } on WritersidePdfExportException catch (failure) {
    if (!context.mounted) {
      return false;
    }
    await _showWritersidePdfError(context, headerBar, failure);
    return false;
  }
  if (!context.mounted) {
    return false;
  }
  final image = '$writersideBuilderRepository:$version';
  final download =
      await showBusyMarkModalDialog<bool>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.writersidePdfBuilderRequired,
          maxWidth: BusyMarkSizes.dialog,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            BusyMarkDialogButton(
              label: context.l10n.download,
              suggested: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          children: [
            Text(context.l10n.writersidePdfBuilderDownloadDescription(image)),
          ],
        ),
      ) ??
      false;
  if (!download || !context.mounted) {
    return false;
  }
  final token = WritersidePdfCancellationToken();
  final outcome = await showBusyMarkModalDialog<_WritersideDownloadOutcome>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    barrierDismissible: false,
    builder: (context) => _WritersideDownloadProgressDialog(
      cancellationToken: token,
      operation: () =>
          service.downloadBuilder(version, cancellationToken: token),
    ),
  );
  if (outcome?.failure case final failure?) {
    if (context.mounted && failure.code != WritersidePdfFailureCode.cancelled) {
      await _showWritersidePdfError(context, headerBar, failure);
    }
    return false;
  }
  return outcome?.succeeded == true;
}

class _WritersidePdfOptionsDialog extends StatefulWidget {
  const _WritersidePdfOptionsDialog({
    required this.module,
    required this.instances,
    required this.initialInstance,
    required this.projectConfigurations,
    required this.layouts,
  });

  final WritersideModule module;
  final List<WritersideInstance> instances;
  final WritersideInstance initialInstance;
  final List<String> projectConfigurations;
  final Map<String, List<WritersidePdfKeymapLayout>> layouts;

  @override
  State<_WritersidePdfOptionsDialog> createState() =>
      _WritersidePdfOptionsDialogState();
}

class _WritersidePdfOptionsDialogState
    extends State<_WritersidePdfOptionsDialog> {
  late WritersideInstance _instance;
  var _configurationMode = WritersidePdfConfigurationMode.generated;
  String? _projectConfiguration;
  var _orientation = MarkdownPdfOrientation.portrait;
  var _coverEnabled = true;
  var _layout = '';
  var _allowNetwork = false;
  late final TextEditingController _moduleNameController;
  late final TextEditingController _sourceRootController;
  late final TextEditingController _builderVersionController;
  late final TextEditingController _coverTitleController;
  late final TextEditingController _coverLogoController;
  late final TextEditingController _coverDescriptionController;
  late final TextEditingController _coverCopyrightController;
  late final TextEditingController _headerController;
  late final TextEditingController _footerController;
  late final TextEditingController _tocTitleController;

  @override
  void initState() {
    super.initState();
    _instance = widget.initialInstance;
    _projectConfiguration = widget.projectConfigurations.firstOrNull;
    _moduleNameController = TextEditingController(
      text: defaultWritersideBuilderModuleName(widget.module),
    );
    _sourceRootController = TextEditingController(
      text: p.dirname(widget.module.rootPath),
    );
    _builderVersionController = TextEditingController(
      text: _configuredBuilderVersion(widget.module),
    );
    _coverTitleController = TextEditingController(text: _instance.name);
    _coverLogoController = TextEditingController();
    _coverDescriptionController = TextEditingController();
    _coverCopyrightController = TextEditingController();
    _headerController = TextEditingController();
    _footerController = TextEditingController();
    _tocTitleController = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in [
      _moduleNameController,
      _sourceRootController,
      _builderVersionController,
      _coverTitleController,
      _coverLogoController,
      _coverDescriptionController,
      _coverCopyrightController,
      _headerController,
      _footerController,
      _tocTitleController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modes = <WritersidePdfConfigurationMode>[
      WritersidePdfConfigurationMode.generated,
      if (widget.projectConfigurations.isNotEmpty)
        WritersidePdfConfigurationMode.projectFile,
    ];
    final availableLayouts = widget.layouts[_instance.id] ?? const [];
    final layoutValues = <String>[
      '',
      ...availableLayouts.map((item) => item.name),
    ];
    if (!layoutValues.contains(_layout)) {
      _layout = '';
    }
    final moduleNameError = _moduleNameController.text.trim().isEmpty
        ? context.l10n.writersidePdfModuleNameRequired
        : null;
    final sourceRootError = _sourceRootController.text.trim().isEmpty
        ? context.l10n.writersidePdfSourceRootRequired
        : null;
    final versionError =
        !RegExp(
          r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$',
        ).hasMatch(_builderVersionController.text.trim())
        ? context.l10n.writersidePdfBuilderVersionInvalid
        : null;
    final canExport =
        moduleNameError == null &&
        sourceRootError == null &&
        versionError == null &&
        (_configurationMode == WritersidePdfConfigurationMode.generated ||
            _projectConfiguration != null);
    return BusyMarkModalEditorScaffold(
      title: context.l10n.exportWritersideAsPdf,
      cancelLabel: context.l10n.cancel,
      saveLabel: context.l10n.export,
      onCancel: () => Navigator.pop(context),
      onSave: canExport ? _submit : null,
      children: [
        Text(context.l10n.writersidePdfExportDescription),
        BusyMarkGroupedList(
          title: context.l10n.writersidePdfContent,
          filled: true,
          children: [
            BusyMarkComboRow<WritersideInstance>(
              title: context.l10n.instanceName,
              values: widget.instances,
              selected: _instance,
              labelFor: (instance) => '${instance.name} (${instance.id})',
              onSelected: (instance) => setState(() {
                _instance = instance;
                _layout = '';
                _coverTitleController.text = instance.name;
              }),
            ),
            BusyMarkComboRow<WritersidePdfConfigurationMode>(
              title: context.l10n.writersidePdfSettings,
              values: modes,
              selected: _configurationMode,
              labelFor: (mode) => switch (mode) {
                WritersidePdfConfigurationMode.generated =>
                  context.l10n.writersidePdfConfigureHere,
                WritersidePdfConfigurationMode.projectFile =>
                  context.l10n.writersidePdfProjectConfiguration,
              },
              onSelected: (mode) => setState(() => _configurationMode = mode),
            ),
            if (_configurationMode ==
                WritersidePdfConfigurationMode.projectFile)
              BusyMarkComboRow<String>(
                title: context.l10n.writersidePdfConfigurationFile,
                values: widget.projectConfigurations,
                selected: _projectConfiguration!,
                labelFor: p.basename,
                onSelected: (value) =>
                    setState(() => _projectConfiguration = value),
              ),
          ],
        ),
        if (_configurationMode == WritersidePdfConfigurationMode.generated) ...[
          BusyMarkGroupedList(
            title: context.l10n.writersidePdfPage,
            filled: true,
            children: [
              BusyMarkComboRow<MarkdownPdfOrientation>(
                title: context.l10n.pdfOrientation,
                values: MarkdownPdfOrientation.values,
                selected: _orientation,
                labelFor: (value) => switch (value) {
                  MarkdownPdfOrientation.portrait => context.l10n.pdfPortrait,
                  MarkdownPdfOrientation.landscape => context.l10n.pdfLandscape,
                },
                onSelected: (value) => setState(() => _orientation = value),
              ),
              if (layoutValues.length > 1)
                BusyMarkComboRow<String>(
                  title: context.l10n.writersidePdfKeymap,
                  values: layoutValues,
                  selected: _layout,
                  labelFor: (value) => value.isEmpty
                      ? context.l10n.writersidePdfNoKeymap
                      : availableLayouts
                            .where((item) => item.name == value)
                            .first
                            .displayName,
                  onSelected: (value) => setState(() => _layout = value),
                ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.writersidePdfTocTitle,
                controller: _tocTitleController,
              ),
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.writersidePdfCover,
            filled: true,
            children: [
              BusyMarkSwitchRow(
                title: context.l10n.writersidePdfIncludeCover,
                value: _coverEnabled,
                onChanged: (value) => setState(() => _coverEnabled = value),
              ),
              if (_coverEnabled) ...[
                BusyMarkGroupedTextEntry(
                  label: context.l10n.writersidePdfCoverTitle,
                  controller: _coverTitleController,
                ),
                BusyMarkGroupedTextEntry(
                  label: context.l10n.writersidePdfCoverDescription,
                  controller: _coverDescriptionController,
                  maxLines: 3,
                ),
                BusyMarkGroupedTextEntry(
                  label: context.l10n.writersidePdfCopyright,
                  controller: _coverCopyrightController,
                ),
                BusyMarkGroupedTextEntry(
                  label: context.l10n.writersidePdfCoverLogo,
                  controller: _coverLogoController,
                  textDirection: TextDirection.ltr,
                ),
                BusyMarkActionRow(
                  title: context.l10n.writersidePdfChooseCoverLogo,
                  onTap: _chooseLogo,
                ),
              ],
            ],
          ),
          BusyMarkGroupedList(
            title: context.l10n.writersidePdfHeaderAndFooter,
            filled: true,
            children: [
              BusyMarkGroupedTextEntry(
                label: context.l10n.writersidePdfHeader,
                controller: _headerController,
              ),
              BusyMarkGroupedTextEntry(
                label: context.l10n.writersidePdfFooter,
                controller: _footerController,
              ),
            ],
          ),
        ],
        BusyMarkGroupedList(
          title: context.l10n.advanced,
          description: context.l10n.writersidePdfAdvancedDescription,
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: context.l10n.writersidePdfModuleName,
              controller: _moduleNameController,
              errorText: moduleNameError,
              onChanged: (_) => setState(() {}),
            ),
            BusyMarkGroupedTextEntry(
              label: context.l10n.writersidePdfSourceRoot,
              controller: _sourceRootController,
              textDirection: TextDirection.ltr,
              errorText: sourceRootError,
              onChanged: (_) => setState(() {}),
            ),
            BusyMarkActionRow(
              title: context.l10n.writersidePdfChooseSourceRoot,
              onTap: _chooseSourceRoot,
            ),
            BusyMarkGroupedTextEntry(
              label: context.l10n.writersidePdfBuilderVersion,
              controller: _builderVersionController,
              textDirection: TextDirection.ltr,
              errorText: versionError,
              onChanged: (_) => setState(() {}),
            ),
            BusyMarkSwitchRow(
              title: context.l10n.writersidePdfAllowNetwork,
              subtitle: context.l10n.writersidePdfAllowNetworkDescription,
              value: _allowNetwork,
              onChanged: (value) => setState(() => _allowNetwork = value),
            ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.lg),
      ],
    );
  }

  Future<void> _chooseLogo() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.fileTypeImages,
          extensions: const ['png', 'jpg', 'jpeg', 'svg'],
        ),
      ],
      initialDirectory: widget.module.rootPath,
      confirmButtonText: context.l10n.choose,
    );
    if (file != null && mounted) {
      setState(() => _coverLogoController.text = file.path);
    }
  }

  Future<void> _chooseSourceRoot() async {
    final path = await getDirectoryPath(
      initialDirectory: _sourceRootController.text,
      confirmButtonText: context.l10n.chooseLocation,
      canCreateDirectories: false,
    );
    if (path != null && mounted) {
      setState(() => _sourceRootController.text = path);
    }
  }

  void _submit() {
    Navigator.pop(
      context,
      _WritersidePdfSelection(
        instance: _instance,
        moduleName: _moduleNameController.text.trim(),
        sourceRoot: _sourceRootController.text.trim(),
        builderVersion: _builderVersionController.text.trim(),
        configurationMode: _configurationMode,
        projectConfigurationPath:
            _configurationMode == WritersidePdfConfigurationMode.projectFile
            ? _projectConfiguration
            : null,
        allowNetwork: _allowNetwork,
        options: WritersidePdfOptions(
          orientation: _orientation,
          layout: _layout,
          cover: WritersidePdfCoverOptions(
            enabled: _coverEnabled,
            title: _coverTitleController.text,
            logoPath: _coverLogoController.text,
            description: _coverDescriptionController.text,
            copyright: _coverCopyrightController.text,
          ),
          header: _headerController.text,
          footer: _footerController.text,
          tocTitle: _tocTitleController.text,
        ),
      ),
    );
  }
}

class _WritersidePdfSelection {
  const _WritersidePdfSelection({
    required this.instance,
    required this.moduleName,
    required this.sourceRoot,
    required this.builderVersion,
    required this.configurationMode,
    required this.projectConfigurationPath,
    required this.options,
    required this.allowNetwork,
  });

  final WritersideInstance instance;
  final String moduleName;
  final String sourceRoot;
  final String builderVersion;
  final WritersidePdfConfigurationMode configurationMode;
  final String? projectConfigurationPath;
  final WritersidePdfOptions options;
  final bool allowNetwork;
}

class _WritersidePdfProgressDialog extends StatefulWidget {
  const _WritersidePdfProgressDialog({
    required this.operation,
    required this.cancellationToken,
  });

  final Future<WritersidePdfExportResult> Function() operation;
  final WritersidePdfCancellationToken cancellationToken;

  @override
  State<_WritersidePdfProgressDialog> createState() =>
      _WritersidePdfProgressDialogState();
}

class _WritersidePdfProgressDialogState
    extends State<_WritersidePdfProgressDialog> {
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final result = await widget.operation();
      if (mounted) {
        Navigator.pop(context, _WritersidePdfOutcome.success(result));
      }
    } on WritersidePdfExportException catch (failure) {
      if (mounted) {
        Navigator.pop(context, _WritersidePdfOutcome.failure(failure));
      }
    } on Object catch (error) {
      if (mounted) {
        Navigator.pop(
          context,
          _WritersidePdfOutcome.failure(
            WritersidePdfExportException(
              WritersidePdfFailureCode.fileSystem,
              detail: error.toString(),
              cause: error,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BusyMarkDialogShell(
        title: context.l10n.exportingWritersidePdf,
        closable: false,
        maxWidth: 440,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: _cancelling
                ? null
                : () {
                    setState(() => _cancelling = true);
                    widget.cancellationToken.cancel();
                  },
          ),
        ],
        children: const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: BusyMarkSpacing.md),
        ],
      ),
    );
  }
}

class _WritersideDownloadProgressDialog extends StatefulWidget {
  const _WritersideDownloadProgressDialog({
    required this.operation,
    required this.cancellationToken,
  });

  final Future<void> Function() operation;
  final WritersidePdfCancellationToken cancellationToken;

  @override
  State<_WritersideDownloadProgressDialog> createState() =>
      _WritersideDownloadProgressDialogState();
}

class _WritersideDownloadProgressDialogState
    extends State<_WritersideDownloadProgressDialog> {
  var _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await widget.operation();
      if (mounted) {
        Navigator.pop(context, const _WritersideDownloadOutcome.success());
      }
    } on WritersidePdfExportException catch (failure) {
      if (mounted) {
        Navigator.pop(context, _WritersideDownloadOutcome.failure(failure));
      }
    } on Object catch (error) {
      if (mounted) {
        Navigator.pop(
          context,
          _WritersideDownloadOutcome.failure(
            WritersidePdfExportException(
              WritersidePdfFailureCode.fileSystem,
              detail: error.toString(),
              cause: error,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BusyMarkDialogShell(
        title: context.l10n.writersidePdfDownloadingBuilder,
        closable: false,
        maxWidth: 440,
        actions: [
          BusyMarkDialogButton(
            label: context.l10n.cancel,
            onPressed: _cancelling
                ? null
                : () {
                    setState(() => _cancelling = true);
                    widget.cancellationToken.cancel();
                  },
          ),
        ],
        children: const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: BusyMarkSpacing.md),
        ],
      ),
    );
  }
}

class _WritersidePdfOutcome {
  const _WritersidePdfOutcome._({this.result, this.failure});

  factory _WritersidePdfOutcome.success(WritersidePdfExportResult result) =>
      _WritersidePdfOutcome._(result: result);

  factory _WritersidePdfOutcome.failure(WritersidePdfExportException failure) =>
      _WritersidePdfOutcome._(failure: failure);

  final WritersidePdfExportResult? result;
  final WritersidePdfExportException? failure;
}

class _WritersideDownloadOutcome {
  const _WritersideDownloadOutcome.success() : succeeded = true, failure = null;

  const _WritersideDownloadOutcome.failure(this.failure) : succeeded = false;

  final bool succeeded;
  final WritersidePdfExportException? failure;
}

Future<bool> _confirmOverwrite(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  String path,
) async {
  return await showBusyMarkModalDialog<bool>(
        context,
        headerBarService: headerBar.isAvailable ? headerBar : null,
        builder: (context) => BusyMarkDialogShell(
          title: context.l10n.warning,
          actions: [
            BusyMarkDialogButton(
              label: context.l10n.cancel,
              onPressed: () => Navigator.pop(context, false),
            ),
            BusyMarkDialogButton(
              label: context.l10n.overwrite,
              destructive: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
          children: [Text(context.l10n.errorPathAlreadyExists(path))],
        ),
      ) ??
      false;
}

Future<void> _showWritersidePdfError(
  BuildContext context,
  LinuxHeaderBarService headerBar,
  WritersidePdfExportException failure,
) {
  final message = switch (failure.code) {
    WritersidePdfFailureCode.dockerUnavailable =>
      context.l10n.writersidePdfDockerUnavailable,
    WritersidePdfFailureCode.builderImageUnavailable =>
      context.l10n.writersidePdfBuilderUnavailable,
    WritersidePdfFailureCode.timedOut => context.l10n.pdfExportTimedOut,
    WritersidePdfFailureCode.destinationExists =>
      context.l10n.errorPathAlreadyExists(failure.detail),
    WritersidePdfFailureCode.invalidRequest ||
    WritersidePdfFailureCode.invalidConfiguration =>
      context.l10n.writersidePdfConfigurationInvalid,
    WritersidePdfFailureCode.buildFailed =>
      context.l10n.writersidePdfBuildFailed,
    WritersidePdfFailureCode.invalidOutput =>
      context.l10n.writersidePdfInvalidOutput,
    WritersidePdfFailureCode.fileSystem => context.l10n.pdfExportFailed,
    WritersidePdfFailureCode.cancelled => context.l10n.pdfExportFailed,
  };
  return showBusyMarkModalDialog<void>(
    context,
    headerBarService: headerBar.isAvailable ? headerBar : null,
    builder: (context) => BusyMarkDialogShell(
      title: context.l10n.exportWritersideAsPdf,
      maxWidth: BusyMarkSizes.dialog,
      actions: [
        BusyMarkDialogButton(
          label: MaterialLocalizations.of(context).okButtonLabel,
          suggested: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        Text(message),
        if (failure.detail.trim().isNotEmpty) ...[
          const SizedBox(height: BusyMarkSpacing.md),
          SelectionArea(
            child: Text(
              failure.detail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

String _withPdfExtension(String path) {
  final normalized = p.normalize(path);
  return p.extension(normalized).toLowerCase() == '.pdf'
      ? normalized
      : '$normalized.pdf';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

String _configuredBuilderVersion(WritersideModule module) {
  final configured = module.config.settings.wrsSupernovaUseVersion?.trim();
  return configured != null &&
          RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$').hasMatch(configured)
      ? configured
      : writersideBuilderDefaultVersion;
}
