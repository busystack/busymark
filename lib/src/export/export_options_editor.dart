import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/app_settings.dart';
import '../app/busymark_design.dart';
import '../app/busymark_dialogs.dart';
import '../app/localization.dart';
import '../platform/linux_header_bar_service.dart';
import '../writerside/writerside_model.dart';
import 'export_options.dart';
import 'html_export_styles.dart';

class ExportOptionsSelection {
  const ExportOptionsSelection({this.pdf, this.html, this.instance});
  final PdfExportOptions? pdf;
  final HtmlExportOptions? html;
  final WritersideInstance? instance;
}

Future<ExportOptionsSelection?> showExportOptions(
  BuildContext context,
  WidgetRef ref, {
  required bool pdf,
  List<WritersideInstance> instances = const [],
  String? workspaceRoot,
}) async {
  final controller = ref.read(appSettingsControllerProvider.notifier);
  await controller.waitUntilLoaded();
  if (!context.mounted) return null;
  final settings = ref.read(appSettingsControllerProvider);
  final bar = ref.read(linuxHeaderBarServiceProvider);
  final selection = await showBusyMarkModalEditorDialog<ExportOptionsSelection>(
    context,
    headerBarService: bar.isAvailable ? bar : null,
    maxWidth: 720,
    builder: (context) => ExportOptionsDialog(
      pdf: pdf ? settings.pdfExportOptions : null,
      html: pdf ? null : settings.htmlExportOptions,
      instances: instances,
      instanceId: workspaceRoot == null
          ? null
          : settings.selectedWritersideInstanceId(workspaceRoot),
    ),
  );
  if (selection == null) return null;
  if (selection.pdf case final options?) {
    await controller.setPdfExportOptions(options);
  }
  if (selection.html case final options?) {
    await controller.setHtmlExportOptions(options);
  }
  if (workspaceRoot != null && selection.instance != null) {
    await controller.selectWritersideInstance(
      workspaceRoot,
      selection.instance!.id,
    );
  }
  return selection;
}

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({
    super.key,
    this.pdf,
    this.html,
    this.instances = const [],
    this.instanceId,
  }) : assert((pdf == null) != (html == null));
  final PdfExportOptions? pdf;
  final HtmlExportOptions? html;
  final List<WritersideInstance> instances;
  final String? instanceId;
  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late PdfExportOptions? _pdf = widget.pdf;
  late HtmlExportOptions? _html = widget.html;
  late WritersideInstance? _instance =
      widget.instances.where((i) => i.id == widget.instanceId).firstOrNull ??
      widget.instances.firstOrNull;
  var _revision = 0;
  var _saving = false;
  List<ExportOptionIssue> _fileErrors = [];
  List<ExportOptionIssue> get _issues => [
    ...?_pdf?.validate(),
    ...?_html?.validate(),
    ..._fileErrors,
  ];

  Future<void> _submit() async {
    if (_issues.isNotEmpty) return;
    final selection = ExportOptionsSelection(
      pdf: _pdf,
      html: _html,
      instance: _instance,
    );
    setState(() => _saving = true);
    try {
      if (selection.html case final html?) {
        await HtmlExportStyles.readCustomCss(html);
      }
      if (mounted) {
        Navigator.pop(context, selection);
      }
    } on ExportOptionsException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _fileErrors = error.issues;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => BusyMarkModalEditorScaffold(
    title: _pdf == null ? context.l10n.exportAsHtml : context.l10n.exportAsPdf,
    cancelLabel: context.l10n.cancel,
    saveLabel: context.l10n.export,
    onCancel: () => Navigator.pop(context),
    onSave: _issues.isEmpty && !_saving ? _submit : null,
    saving: _saving,
    children: [
      BusyMarkDialogButton(
        label: context.l10n.exportReset,
        onPressed: _saving
            ? null
            : () => setState(() {
                if (_pdf != null) _pdf = const PdfExportOptions();
                if (_html != null) _html = const HtmlExportOptions();
                _revision++;
                _fileErrors = [];
              }),
      ),
      const SizedBox(height: BusyMarkSpacing.md),
      if (_issues.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: BusyMarkSpacing.md),
          child: Text(
            _issues.map((i) => exportOptionError(context, i)).join('\n'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_pdf != null)
        PdfExportOptionsEditor(
          key: ValueKey(_revision),
          value: _pdf!,
          instance: _instanceRow(context),
          onChanged: (value) => setState(() => _pdf = value),
        )
      else
        HtmlExportOptionsEditor(
          key: ValueKey(_revision),
          value: _html!,
          instance: _instanceRow(context),
          onChanged: (value) => setState(() {
            _html = value;
            _fileErrors = [];
          }),
        ),
    ],
  );

  Widget? _instanceRow(BuildContext context) => _instance == null
      ? null
      : BusyMarkComboRow<WritersideInstance>(
          title: context.l10n.htmlInstance,
          selected: _instance!,
          values: widget.instances,
          labelFor: (i) => '${i.name} (${i.id})',
          onSelected: (i) => setState(() => _instance = i),
        );
}

String exportOptionError(BuildContext context, ExportOptionIssue issue) {
  final l = context.l10n;
  if (issue.field == 'pageGeometry') return l.exportInvalidGeometry;
  if (issue.field == 'accentColor') return l.exportInvalidColor;
  if (issue.field.startsWith('customCss')) return l.exportInvalidCss;
  final name = switch (issue.field) {
    'customWidthMm' => l.exportPageWidth,
    'customHeightMm' => l.exportPageHeight,
    'bodyFontSize' || 'baseFontSize' => l.exportBodySize,
    'codeFontSize' => l.exportCodeSize,
    'contentMaxWidth' => l.exportContentWidth,
    'tocDepth' => l.exportTocDepth,
    _ => l.pdfMargins,
  };
  return l.exportInvalidRange(
    name,
    '${issue.minimum ?? 0}',
    '${issue.maximum ?? 500}',
  );
}

class ExportContentOptionsEditor extends StatelessWidget {
  const ExportContentOptionsEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.instance,
  });
  final ExportContentOptions value;
  final ValueChanged<ExportContentOptions> onChanged;
  final Widget? instance;
  @override
  Widget build(BuildContext context) => BusyMarkGroupedList(
    title: context.l10n.writersidePdfContent,
    filled: true,
    children: [
      if (instance != null) instance!,
      BusyMarkSwitchRow(
        title: context.l10n.exportToc,
        value: value.includeToc,
        onChanged: (v) => onChanged(value.copyWith(includeToc: v)),
      ),
      BusyMarkComboRow<int>(
        title: context.l10n.exportTocDepth,
        values: const [1, 2, 3, 4, 5, 6],
        selected: value.tocDepth.clamp(1, 6),
        enabled: value.includeToc,
        labelFor: (v) => '$v',
        onSelected: (v) => onChanged(value.copyWith(tocDepth: v)),
      ),
      BusyMarkSwitchRow(
        title: context.l10n.exportNumberHeadings,
        value: value.numberHeadings,
        onChanged: (v) => onChanged(value.copyWith(numberHeadings: v)),
      ),
    ],
  );
}

class PdfExportOptionsEditor extends StatelessWidget {
  const PdfExportOptionsEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.instance,
  });
  final PdfExportOptions value;
  final ValueChanged<PdfExportOptions> onChanged;
  final Widget? instance;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = value;
    final errors = o.validate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExportContentOptionsEditor(
          value: o.content,
          onChanged: (v) => onChanged(o.copyWith(content: v)),
          instance: instance,
        ),
        _group(l.writersidePdfPage, [
          BusyMarkComboRow<PdfPageSize>(
            title: l.pdfPageSize,
            values: PdfPageSize.values,
            selected: o.pageSize,
            labelFor: (v) => switch (v) {
              PdfPageSize.a4 => l.pdfPageSizeA4,
              PdfPageSize.letter => l.pdfPageSizeLetter,
              PdfPageSize.legal => l.exportLegal,
              PdfPageSize.custom => l.exportCustom,
            },
            onSelected: (v) => onChanged(o.copyWith(pageSize: v)),
          ),
          if (o.pageSize == PdfPageSize.custom) ...[
            _number(
              context,
              l.exportPageWidth,
              'customWidthMm',
              o.customWidthMm,
              errors,
              (v) => onChanged(o.copyWith(customWidthMm: v)),
            ),
            _number(
              context,
              l.exportPageHeight,
              'customHeightMm',
              o.customHeightMm,
              errors,
              (v) => onChanged(o.copyWith(customHeightMm: v)),
            ),
          ],
          BusyMarkComboRow<PdfOrientation>(
            title: l.pdfOrientation,
            values: PdfOrientation.values,
            selected: o.orientation,
            labelFor: (v) =>
                v == PdfOrientation.portrait ? l.pdfPortrait : l.pdfLandscape,
            onSelected: (v) => onChanged(o.copyWith(orientation: v)),
          ),
          BusyMarkComboRow<PdfMarginPreset>(
            title: l.pdfMargins,
            values: PdfMarginPreset.values,
            selected: o.margin,
            labelFor: (v) => switch (v) {
              PdfMarginPreset.narrow => l.pdfMarginNarrow,
              PdfMarginPreset.normal => l.pdfMarginNormal,
              PdfMarginPreset.wide => l.pdfMarginWide,
              PdfMarginPreset.custom => l.exportCustom,
            },
            onSelected: (v) => onChanged(o.copyWith(margin: v)),
          ),
          if (o.margin == PdfMarginPreset.custom) ...[
            _number(
              context,
              l.exportMarginTop,
              'margin.top',
              o.customMargins.top,
              errors,
              (v) => onChanged(
                o.copyWith(customMargins: o.customMargins.copyWith(top: v)),
              ),
            ),
            _number(
              context,
              l.exportMarginRight,
              'margin.right',
              o.customMargins.right,
              errors,
              (v) => onChanged(
                o.copyWith(customMargins: o.customMargins.copyWith(right: v)),
              ),
            ),
            _number(
              context,
              l.exportMarginBottom,
              'margin.bottom',
              o.customMargins.bottom,
              errors,
              (v) => onChanged(
                o.copyWith(customMargins: o.customMargins.copyWith(bottom: v)),
              ),
            ),
            _number(
              context,
              l.exportMarginLeft,
              'margin.left',
              o.customMargins.left,
              errors,
              (v) => onChanged(
                o.copyWith(customMargins: o.customMargins.copyWith(left: v)),
              ),
            ),
          ],
        ]),
        _group(l.exportTypography, [
          _typography(
            context,
            o.bodyTypography,
            (v) => onChanged(o.copyWith(bodyTypography: v)),
          ),
          _number(
            context,
            '${l.exportBodySize} (pt)',
            'bodyFontSize',
            o.bodyFontSize,
            errors,
            (v) => onChanged(o.copyWith(bodyFontSize: v)),
          ),
          _number(
            context,
            '${l.exportCodeSize} (pt)',
            'codeFontSize',
            o.codeFontSize,
            errors,
            (v) => onChanged(o.copyWith(codeFontSize: v)),
          ),
        ]),
        _group(l.exportRunningText, [
          for (final header in [true, false])
            BusyMarkComboRow<PdfRunningText>(
              title: header ? l.exportHeader : l.exportFooter,
              values: PdfRunningText.values,
              selected: header ? o.header : o.footer,
              labelFor: (v) => v == PdfRunningText.none
                  ? l.exportNone
                  : l.exportDocumentTitle,
              onSelected: (v) => onChanged(
                header ? o.copyWith(header: v) : o.copyWith(footer: v),
              ),
            ),
          BusyMarkComboRow<PdfPageNumberPosition>(
            title: l.pdfIncludePageNumbers,
            values: PdfPageNumberPosition.values,
            selected: o.pageNumbers,
            labelFor: (v) => switch (v) {
              PdfPageNumberPosition.off => l.exportNone,
              PdfPageNumberPosition.bottomLeft => l.exportBottomLeft,
              PdfPageNumberPosition.bottomCenter => l.exportBottomCenter,
              PdfPageNumberPosition.bottomRight => l.exportBottomRight,
            },
            onSelected: (v) => onChanged(o.copyWith(pageNumbers: v)),
          ),
          BusyMarkSwitchRow(
            title: l.exportFirstPage,
            value: o.showHeaderFooterOnFirstPage,
            enabled:
                o.header != PdfRunningText.none ||
                o.footer != PdfRunningText.none ||
                o.pageNumbers != PdfPageNumberPosition.off,
            onChanged: (v) =>
                onChanged(o.copyWith(showHeaderFooterOnFirstPage: v)),
          ),
        ]),
        _group(l.appearance, [
          _AccentEditor(
            value: o.accentColor,
            onChanged: (v) => onChanged(o.copyWith(accentColor: v)),
          ),
        ]),
        const SizedBox(height: BusyMarkSpacing.md),
        Text(l.pdfRemoteImagesNote),
      ],
    );
  }
}

class HtmlExportOptionsEditor extends StatelessWidget {
  const HtmlExportOptionsEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.instance,
  });
  final HtmlExportOptions value;
  final ValueChanged<HtmlExportOptions> onChanged;
  final Widget? instance;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, o = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExportContentOptionsEditor(
          value: o.content,
          onChanged: (v) => onChanged(o.copyWith(content: v)),
          instance: instance,
        ),
        _group(l.appearance, [
          BusyMarkComboRow<HtmlExportTheme>(
            title: l.exportTheme,
            values: HtmlExportTheme.values,
            selected: o.theme,
            labelFor: (v) => switch (v) {
              HtmlExportTheme.light => l.lightTheme,
              HtmlExportTheme.dark => l.darkTheme,
              HtmlExportTheme.automatic => l.exportAutomatic,
            },
            onSelected: (v) => onChanged(o.copyWith(theme: v)),
          ),
          _typography(
            context,
            o.bodyTypography,
            (v) => onChanged(o.copyWith(bodyTypography: v)),
          ),
          _number(
            context,
            '${l.exportBodySize} (px)',
            'baseFontSize',
            o.baseFontSize,
            o.validate(),
            (v) => onChanged(o.copyWith(baseFontSize: v)),
          ),
          _AccentEditor(
            value: o.accentColor,
            onChanged: (v) => onChanged(o.copyWith(accentColor: v)),
          ),
        ]),
        _group(l.exportLayout, [
          _number(
            context,
            '${l.exportContentWidth} (px)',
            'contentMaxWidth',
            o.contentMaxWidth,
            o.validate(),
            (v) => onChanged(o.copyWith(contentMaxWidth: v)),
          ),
        ]),
        _group(l.exportOutput, [
          BusyMarkComboRow<HtmlPackaging>(
            title: l.exportPackaging,
            values: HtmlPackaging.values,
            selected: o.packaging,
            labelFor: (v) => v == HtmlPackaging.singleFile
                ? l.exportSingleFile
                : l.exportAssetsDirectory,
            onSelected: (v) => onChanged(o.copyWith(packaging: v)),
          ),
          BusyMarkActionRow(
            title: l.exportCustomCss,
            subtitle: o.customCssPath ?? l.exportNone,
            onTap: () async {
              final file = await openFile(
                acceptedTypeGroups: [
                  XTypeGroup(
                    label: l.exportCustomCss,
                    extensions: const ['css'],
                  ),
                ],
              );
              if (file != null && context.mounted) {
                onChanged(o.copyWith(customCssPath: file.path));
              }
            },
          ),
          if (o.customCssPath != null)
            BusyMarkActionRow(
              title: l.exportRemoveCss,
              onTap: () => onChanged(o.copyWith(customCssPath: null)),
            ),
        ]),
        const SizedBox(height: BusyMarkSpacing.md),
        Text(l.exportCssNote),
        if (instance != null) Text(l.exportSitePackagingNote),
      ],
    );
  }
}

Widget _group(String title, List<Widget> children) => Padding(
  padding: const EdgeInsets.only(top: BusyMarkSpacing.lg),
  child: BusyMarkGroupedList(title: title, filled: true, children: children),
);
Widget _typography(
  BuildContext context,
  ExportBodyTypography value,
  ValueChanged<ExportBodyTypography> onChanged,
) => BusyMarkComboRow<ExportBodyTypography>(
  title: context.l10n.exportTypography,
  values: ExportBodyTypography.values,
  selected: value,
  labelFor: (v) => v == ExportBodyTypography.sansSerif
      ? context.l10n.exportSans
      : context.l10n.exportSerif,
  onSelected: onChanged,
);
Widget _number(
  BuildContext context,
  String title,
  String field,
  double value,
  List<ExportOptionIssue> errors,
  ValueChanged<double> onChanged,
) => BusyMarkGroupedTextEntry(
  key: ValueKey(field),
  label: title,
  initialValue: value.isFinite
      ? value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')
      : '',
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  errorText: errors.any((i) => i.field == field)
      ? exportOptionError(context, errors.firstWhere((i) => i.field == field))
      : null,
  onChanged: (v) =>
      onChanged(double.tryParse(v.replaceAll(',', '.')) ?? double.nan),
);

class _AccentEditor extends StatefulWidget {
  const _AccentEditor({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  State<_AccentEditor> createState() => _AccentEditorState();
}

class _AccentEditorState extends State<_AccentEditor> {
  static const palette = [
    '#2563a5',
    '#1559aa',
    '#247550',
    '#a34200',
    '#7651a8',
    '#b3261e',
  ];
  late bool _custom = !palette.contains(widget.value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      BusyMarkComboRow<String>(
        title: context.l10n.exportAccent,
        values: [...palette, 'custom'],
        selected: _custom ? 'custom' : widget.value,
        leading: validExportColor(widget.value)
            ? Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: busyMarkRgbHexColor(widget.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        labelFor: (v) => v == 'custom' ? context.l10n.exportCustom : v,
        onSelected: (v) {
          setState(() => _custom = v == 'custom');
          if (!_custom) widget.onChanged(v);
        },
      ),
      if (_custom)
        BusyMarkGroupedTextEntry(
          label: context.l10n.exportAccent,
          initialValue: widget.value,
          hintText: '#2563a5',
          errorText: validExportColor(widget.value)
              ? null
              : context.l10n.exportInvalidColor,
          onChanged: widget.onChanged,
        ),
    ],
  );
}
