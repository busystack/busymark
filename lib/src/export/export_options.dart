import 'package:flutter/foundation.dart';

/// Content choices whose meaning is the same in every output format.
@immutable
class ExportContentOptions {
  const ExportContentOptions({
    this.includeToc = false,
    this.tocDepth = 6,
    this.numberHeadings = false,
  });
  final bool includeToc, numberHeadings;
  final int tocDepth;
  ExportContentOptions copyWith({
    bool? includeToc,
    int? tocDepth,
    bool? numberHeadings,
  }) => ExportContentOptions(
    includeToc: includeToc ?? this.includeToc,
    tocDepth: tocDepth ?? this.tocDepth,
    numberHeadings: numberHeadings ?? this.numberHeadings,
  );
  Map<String, Object> toJson() => {
    'includeToc': includeToc,
    'tocDepth': tocDepth,
    'numberHeadings': numberHeadings,
  };
  factory ExportContentOptions.fromJson(
    Object? source, {
    ExportContentOptions defaults = const ExportContentOptions(),
  }) {
    final json = _map(source);
    return ExportContentOptions(
      includeToc: _bool(json['includeToc'], defaults.includeToc),
      tocDepth: _number(
        json['tocDepth'],
        defaults.tocDepth.toDouble(),
        1,
        6,
        integer: true,
      ).toInt(),
      numberHeadings: _bool(json['numberHeadings'], defaults.numberHeadings),
    );
  }
  List<ExportOptionIssue> validate() => [
    if (tocDepth < 1 || tocDepth > 6)
      const ExportOptionIssue('tocDepth', minimum: 1, maximum: 6),
  ];
}

enum ExportBodyTypography { sansSerif, serif }

enum PdfPageSize { a4, letter, legal, custom }

enum PdfOrientation { portrait, landscape }

enum PdfMarginPreset { narrow, normal, wide, custom }

enum PdfRunningText { none, documentTitle }

enum PdfPageNumberPosition { off, bottomLeft, bottomCenter, bottomRight }

enum HtmlExportTheme { light, dark, automatic }

enum HtmlPackaging { singleFile, assetsDirectory }

@immutable
class ExportOptionIssue {
  const ExportOptionIssue(this.field, {this.minimum, this.maximum});
  final String field;
  final double? minimum, maximum;
}

class ExportOptionsException implements Exception {
  const ExportOptionsException(this.issues);
  final List<ExportOptionIssue> issues;
  @override
  String toString() =>
      'Invalid export options: ${issues.map((issue) => issue.field).join(', ')}';
}

@immutable
class PdfMargins {
  const PdfMargins({
    this.top = normalMm,
    this.right = normalMm,
    this.bottom = normalMm,
    this.left = normalMm,
  });
  static const normalMm = 57 * 25.4 / 72;
  final double top, right, bottom, left;
  PdfMargins copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) => PdfMargins(
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
    left: left ?? this.left,
  );
  Map<String, Object> toJson() => {
    'top': top,
    'right': right,
    'bottom': bottom,
    'left': left,
  };
  factory PdfMargins.fromJson(Object? source) {
    final json = _map(source);
    return PdfMargins(
      top: _number(json['top'], normalMm, 0, 500),
      right: _number(json['right'], normalMm, 0, 500),
      bottom: _number(json['bottom'], normalMm, 0, 500),
      left: _number(json['left'], normalMm, 0, 500),
    );
  }
}

@immutable
class PdfPageGeometry {
  const PdfPageGeometry({
    required this.widthMm,
    required this.heightMm,
    required this.margins,
  });
  static const pointsPerMm = 72 / 25.4;
  final double widthMm, heightMm;
  final PdfMargins margins;
  double get widthPt => widthMm * pointsPerMm;
  double get heightPt => heightMm * pointsPerMm;
  double get contentWidthPt =>
      (widthMm - margins.left - margins.right) * pointsPerMm;
  double get contentHeightPt =>
      (heightMm - margins.top - margins.bottom) * pointsPerMm;
  Map<String, Object> toJson() => {
    'widthPt': widthPt,
    'heightPt': heightPt,
    'marginsPt': {
      for (final e in margins.toJson().entries)
        e.key: (e.value as double) * pointsPerMm,
    },
  };
}

/// Shared by Markdown and Writerside PDF. No editor preferences enter this model.
@immutable
class PdfExportOptions {
  const PdfExportOptions({
    this.content = const ExportContentOptions(),
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.margin = PdfMarginPreset.normal,
    this.customWidthMm = 210,
    this.customHeightMm = 297,
    this.customMargins = const PdfMargins(),
    this.bodyTypography = ExportBodyTypography.serif,
    this.bodyFontSize = 10.5,
    this.codeFontSize = 8.4,
    this.accentColor = '#2563a5',
    this.header = PdfRunningText.none,
    this.footer = PdfRunningText.none,
    this.pageNumbers = PdfPageNumberPosition.bottomCenter,
    this.showHeaderFooterOnFirstPage = true,
  });
  final ExportContentOptions content;
  final PdfPageSize pageSize;
  final PdfOrientation orientation;
  final PdfMarginPreset margin;
  final double customWidthMm, customHeightMm;
  final PdfMargins customMargins;
  final ExportBodyTypography bodyTypography;
  final double bodyFontSize, codeFontSize;
  final String accentColor;
  final PdfRunningText header, footer;
  final PdfPageNumberPosition pageNumbers;
  final bool showHeaderFooterOnFirstPage;

  String get bodyFont => bodyTypography == ExportBodyTypography.sansSerif
      ? 'Noto Sans'
      : 'Noto Serif';
  String get codeFont => 'Noto Sans Mono';
  // Ratios preserve BusyMark's original heading scale at the default 10.5pt.
  double headingFontSize(int level) =>
      bodyFontSize *
      const [
        22 / 10.5,
        17 / 10.5,
        13.5 / 10.5,
        11.5 / 10.5,
        1.0,
        1.0,
      ][level.clamp(1, 6) - 1];
  PdfPageGeometry get geometry {
    final (width, height) = switch (pageSize) {
      PdfPageSize.a4 => (210.0, 297.0),
      PdfPageSize.letter => (215.9, 279.4),
      PdfPageSize.legal => (215.9, 355.6),
      PdfPageSize.custom => (customWidthMm, customHeightMm),
    };
    final (horizontal, vertical) = switch (margin) {
      PdfMarginPreset.narrow => (36.0, 36.0),
      PdfMarginPreset.normal => (57.0, 57.0),
      PdfMarginPreset.wide => (78.0, 72.0),
      PdfMarginPreset.custom => (0.0, 0.0),
    };
    final margins = margin == PdfMarginPreset.custom
        ? customMargins
        : PdfMargins(
            top: vertical / PdfPageGeometry.pointsPerMm,
            bottom: vertical / PdfPageGeometry.pointsPerMm,
            left: horizontal / PdfPageGeometry.pointsPerMm,
            right: horizontal / PdfPageGeometry.pointsPerMm,
          );
    return PdfPageGeometry(
      widthMm: orientation == PdfOrientation.landscape ? height : width,
      heightMm: orientation == PdfOrientation.landscape ? width : height,
      margins: margins,
    );
  }

  List<ExportOptionIssue> validate() => [
    ...content.validate(),
    // Validate inactive custom fields too: confirmed options must always be
    // JSON-serializable and remain valid when their controls are re-enabled.
    if (!_between(customWidthMm, 50, 1200))
      const ExportOptionIssue('customWidthMm', minimum: 50, maximum: 1200),
    if (!_between(customHeightMm, 50, 1200))
      const ExportOptionIssue('customHeightMm', minimum: 50, maximum: 1200),
    for (final e in customMargins.toJson().entries)
      if (!_between(e.value as double, 0, 500))
        ExportOptionIssue('margin.${e.key}', minimum: 0, maximum: 500),
    if (!geometry.contentWidthPt.isFinite ||
        !geometry.contentHeightPt.isFinite ||
        geometry.contentWidthPt < 20 * PdfPageGeometry.pointsPerMm ||
        geometry.contentHeightPt < 20 * PdfPageGeometry.pointsPerMm)
      const ExportOptionIssue('pageGeometry'),
    if (!_between(bodyFontSize, 8, 24))
      const ExportOptionIssue('bodyFontSize', minimum: 8, maximum: 24),
    if (!_between(codeFontSize, 6, 20))
      const ExportOptionIssue('codeFontSize', minimum: 6, maximum: 20),
    if (!validExportColor(accentColor)) const ExportOptionIssue('accentColor'),
  ];
  void validateOrThrow() {
    final issues = validate();
    if (issues.isNotEmpty) throw ExportOptionsException(issues);
  }

  PdfExportOptions copyWith({
    ExportContentOptions? content,
    PdfPageSize? pageSize,
    PdfOrientation? orientation,
    PdfMarginPreset? margin,
    double? customWidthMm,
    double? customHeightMm,
    PdfMargins? customMargins,
    ExportBodyTypography? bodyTypography,
    double? bodyFontSize,
    double? codeFontSize,
    String? accentColor,
    PdfRunningText? header,
    PdfRunningText? footer,
    PdfPageNumberPosition? pageNumbers,
    bool? showHeaderFooterOnFirstPage,
  }) => PdfExportOptions(
    content: content ?? this.content,
    pageSize: pageSize ?? this.pageSize,
    orientation: orientation ?? this.orientation,
    margin: margin ?? this.margin,
    customWidthMm: customWidthMm ?? this.customWidthMm,
    customHeightMm: customHeightMm ?? this.customHeightMm,
    customMargins: customMargins ?? this.customMargins,
    bodyTypography: bodyTypography ?? this.bodyTypography,
    bodyFontSize: bodyFontSize ?? this.bodyFontSize,
    codeFontSize: codeFontSize ?? this.codeFontSize,
    accentColor: accentColor ?? this.accentColor,
    header: header ?? this.header,
    footer: footer ?? this.footer,
    pageNumbers: pageNumbers ?? this.pageNumbers,
    showHeaderFooterOnFirstPage:
        showHeaderFooterOnFirstPage ?? this.showHeaderFooterOnFirstPage,
  );
  Map<String, Object> toJson() => {
    'content': content.toJson(),
    'pageSize': pageSize.name,
    'orientation': orientation.name,
    'margin': margin.name,
    'customWidthMm': customWidthMm,
    'customHeightMm': customHeightMm,
    'customMargins': customMargins.toJson(),
    'bodyTypography': bodyTypography.name,
    'bodyFontSize': bodyFontSize,
    'codeFontSize': codeFontSize,
    'accentColor': accentColor,
    'header': header.name,
    'footer': footer.name,
    'pageNumbers': pageNumbers.name,
    'showHeaderFooterOnFirstPage': showHeaderFooterOnFirstPage,
  };
  factory PdfExportOptions.fromJson(Object? source) {
    final j = _map(source);
    const d = PdfExportOptions();
    var result = PdfExportOptions(
      content: ExportContentOptions.fromJson(j['content']),
      pageSize: _enum(PdfPageSize.values, j['pageSize'], d.pageSize),
      orientation: _enum(
        PdfOrientation.values,
        j['orientation'],
        d.orientation,
      ),
      margin: _enum(PdfMarginPreset.values, j['margin'], d.margin),
      customWidthMm: _number(j['customWidthMm'], d.customWidthMm, 50, 1200),
      customHeightMm: _number(j['customHeightMm'], d.customHeightMm, 50, 1200),
      customMargins: PdfMargins.fromJson(j['customMargins']),
      bodyTypography: _enum(
        ExportBodyTypography.values,
        j['bodyTypography'],
        d.bodyTypography,
      ),
      bodyFontSize: _number(j['bodyFontSize'], d.bodyFontSize, 8, 24),
      codeFontSize: _number(j['codeFontSize'], d.codeFontSize, 6, 20),
      accentColor:
          j['accentColor'] is String &&
              validExportColor(j['accentColor'] as String)
          ? (j['accentColor'] as String).toLowerCase()
          : d.accentColor,
      header: _enum(PdfRunningText.values, j['header'], d.header),
      footer: _enum(PdfRunningText.values, j['footer'], d.footer),
      pageNumbers: _enum(
        PdfPageNumberPosition.values,
        j['pageNumbers'],
        d.pageNumbers,
      ),
      showHeaderFooterOnFirstPage: _bool(
        j['showHeaderFooterOnFirstPage'],
        d.showHeaderFooterOnFirstPage,
      ),
    );
    // Restore only incompatible geometry, preserving independent valid fields.
    if (result.validate().any((i) => i.field == 'pageGeometry')) {
      result = result.copyWith(customMargins: d.customMargins);
      if (result.validate().any((i) => i.field == 'pageGeometry')) {
        result = result.copyWith(
          customWidthMm: d.customWidthMm,
          customHeightMm: d.customHeightMm,
        );
      }
    }
    return result;
  }
}

@immutable
class HtmlExportOptions {
  const HtmlExportOptions({
    this.content = const ExportContentOptions(includeToc: true),
    this.theme = HtmlExportTheme.light,
    this.bodyTypography = ExportBodyTypography.sansSerif,
    this.baseFontSize = 17,
    this.contentMaxWidth = 918,
    this.accentColor = '#1559aa',
    this.customCssPath,
    this.packaging = HtmlPackaging.assetsDirectory,
  });
  final ExportContentOptions content;
  final HtmlExportTheme theme;
  final ExportBodyTypography bodyTypography;
  final double baseFontSize, contentMaxWidth;
  final String accentColor;
  final String? customCssPath;
  final HtmlPackaging packaging;
  static const maximumCssBytes = 256 * 1024;
  double headingFontSize(int level) =>
      baseFontSize *
      const [2.3, 1.75, 1.3, 1.0, 1.0, 1.0][level.clamp(1, 6) - 1];
  double get mathContainerWidth =>
      (contentMaxWidth - baseFontSize * 6).clamp(160, 1800).toDouble();
  HtmlExportOptions copyWith({
    ExportContentOptions? content,
    HtmlExportTheme? theme,
    ExportBodyTypography? bodyTypography,
    double? baseFontSize,
    double? contentMaxWidth,
    String? accentColor,
    Object? customCssPath = _unset,
    HtmlPackaging? packaging,
  }) => HtmlExportOptions(
    content: content ?? this.content,
    theme: theme ?? this.theme,
    bodyTypography: bodyTypography ?? this.bodyTypography,
    baseFontSize: baseFontSize ?? this.baseFontSize,
    contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
    accentColor: accentColor ?? this.accentColor,
    customCssPath: identical(customCssPath, _unset)
        ? this.customCssPath
        : customCssPath as String?,
    packaging: packaging ?? this.packaging,
  );
  List<ExportOptionIssue> validate() => [
    ...content.validate(),
    if (!_between(baseFontSize, 12, 28))
      const ExportOptionIssue('baseFontSize', minimum: 12, maximum: 28),
    if (!_between(contentMaxWidth, 320, 1920))
      const ExportOptionIssue('contentMaxWidth', minimum: 320, maximum: 1920),
    if (!validExportColor(accentColor)) const ExportOptionIssue('accentColor'),
    if (customCssPath != null && !validCssPath(customCssPath!))
      const ExportOptionIssue('customCssPath'),
  ];
  void validateOrThrow() {
    final issues = validate();
    if (issues.isNotEmpty) throw ExportOptionsException(issues);
  }

  static bool validCssPath(String value) =>
      value.startsWith('/') &&
      value.toLowerCase().endsWith('.css') &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) &&
      value.length <= 4096;
  Map<String, Object?> toJson() => {
    'content': content.toJson(),
    'theme': theme.name,
    'bodyTypography': bodyTypography.name,
    'baseFontSize': baseFontSize,
    'contentMaxWidth': contentMaxWidth,
    'accentColor': accentColor,
    'customCssPath': customCssPath,
    'packaging': packaging.name,
  };
  factory HtmlExportOptions.fromJson(Object? source) {
    final j = _map(source);
    const d = HtmlExportOptions();
    return HtmlExportOptions(
      content: ExportContentOptions.fromJson(j['content'], defaults: d.content),
      theme: _enum(HtmlExportTheme.values, j['theme'], d.theme),
      bodyTypography: _enum(
        ExportBodyTypography.values,
        j['bodyTypography'],
        d.bodyTypography,
      ),
      baseFontSize: _number(j['baseFontSize'], d.baseFontSize, 12, 28),
      contentMaxWidth: _number(
        j['contentMaxWidth'],
        d.contentMaxWidth,
        320,
        1920,
      ),
      accentColor:
          j['accentColor'] is String &&
              validExportColor(j['accentColor'] as String)
          ? (j['accentColor'] as String).toLowerCase()
          : d.accentColor,
      customCssPath:
          j['customCssPath'] is String &&
              validCssPath(j['customCssPath'] as String)
          ? j['customCssPath'] as String
          : null,
      packaging: _enum(HtmlPackaging.values, j['packaging'], d.packaging),
    );
  }
}

bool validExportColor(String value) =>
    RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value);
const _unset = Object();
Map<Object?, Object?> _map(Object? value) => value is Map ? value : const {};
T _enum<T extends Enum>(List<T> values, Object? value, T fallback) =>
    values.where((e) => e.name == value).firstOrNull ?? fallback;
bool _bool(Object? value, bool fallback) => value is bool ? value : fallback;
bool _between(double value, double minimum, double maximum) =>
    value.isFinite && value >= minimum && value <= maximum;
double _number(
  Object? value,
  double fallback,
  double minimum,
  double maximum, {
  bool integer = false,
}) =>
    value is num &&
        _between(value.toDouble(), minimum, maximum) &&
        (!integer || value == value.truncateToDouble())
    ? value.toDouble()
    : fallback;
