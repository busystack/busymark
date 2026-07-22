import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/yaru.dart';

import 'busymark_glyphs.dart';

abstract final class BusyMarkSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double lgPlus = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double tooltipHorizontal = 8;
  static const double tooltipVertical = 5;
}

abstract final class BusyMarkRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double headerButton = 8;
  static const double nativeHeaderButton = 6;
  static const double window = 14;
  static const double pill = 999;
  static const double selection = 3;
}

abstract final class BusyMarkSizes {
  static const double contentWidth = 760;
  static const double documentContentWidth = contentWidth;
  static const double sidebarWidth = 300;
  static const double settingsWidth = 760;
  static const double toolbarHeight = 46;
  static const double paneHeaderHeight = 38;
  static const double iconButton = 34;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double previewMinWidth = 320;
  static const double modalMaxWidth = 860;
  static const double modalHorizontalInset = 40;
  static const double modalVerticalInset = 24;
  static const double modalMaxHeightFraction = 0.86;
  static const double dialog = 520;
  static const double dialogNarrow = 480;
  static const double dialogCompact = 460;
  static const double dialogWide = 560;
  static const double popupMenuMinWidth = 180;
  static const double popupMenuShortcutWidth = 240;
  static const double popupMenuItemHeight = 36;
  static const double languagePopupMinWidth = 220;
  static const double languagePopupMaxWidth = 280;
  static const double languageButtonMaxWidth = 256;
  static const double dialogButtonMinWidth = 72;
  static const double dialogButtonMaxWidth = 220;
  static const double floatingEntryHeight = 58;
  static const double floatingTextAreaHeight = 154;
  static const double floatingEntryInset = 12;
  static const double floatingEntryLabelTop = 7;
  static const double floatingEntryLabelRestTop = 16;
  static const double floatingEntryLabelHeight = 18;
  static const double floatingEntryLabelRestHeight = 24;
  static const double floatingEntryInputTop = 25;
  static const double floatingEntryInputBottom = 6;
  static const double aboutLogoViewport = 136;
  static const double aboutLogoAsset = 216;
  static const double sidebarSeparatorHeight = 22;
  static const double sidebarTreeRowHeight = 30;
  static const double sidebarTreeDepthBase = 4;
  static const double sidebarTreeDepthIndent = 14;
  static const double sidebarTreeControl = 18;
  static const double sidebarTreeArrow = 14;
  static const double problemsListWidth = 700;
  static const double problemsListHeight = 420;
  static const double sourceGutterWidth = 50;
  static const double sourceFoldButton = 16;
  static const double sourceFoldButtonRightInset = 1;
  static const double previewHeadingTop = 18;
  static const double previewHeadingBottom = 6;
  static const double previewListMarkerWidth = 18;
  static const double previewListMarkerTopInset = 2;
  static const double previewImageMinWidth = 80;
  static const double previewImageMaxWidth = documentContentWidth;
  static const double previewInlineImageMaxHeight = 180;
  static const double previewInlineImageHeight = 96;
  static const double wysiwygBlockIndent = 28;
  static const double wysiwygToolbarReserve =
      iconButton + BusyMarkSpacing.xs * 2;
  static const double wysiwygToolbarClearance =
      BusyMarkSpacing.sm + wysiwygToolbarReserve + BusyMarkSpacing.sm;
  static const double wysiwygPrefixWidth = 30;
  static const double imageDialogWidth = 420;
  static const double tableDialogWidth = 360;
  static const double tableColumnBaseWidth = 164;
  static const double tableMinWidth = 360;
  static const double tableMaxWidth = 980;
  static const double tableControl = 34;
  static const double markerDot = 6;
  static const double thematicBreakHandleWidth = 44;
  static const double controlRowWidth = 256;
  static const double sliderRowWidth = 260;
  static const double toolbarPlacementRowWidth = 430;
  static const double settingsControlBreakpoint = 560;
  static const double toolbarPlacementBreakpoint = 620;
  static const int tableMinColumns = 1;
  static const int tableMaxColumns = 12;
  static const int tableMinRows = 1;
  static const int tableMaxRows = 50;
}

abstract final class BusyMarkElevation {
  static const double none = 0;
  static const double surface = 2;
  static const double popover = 6;
  static const double window = 12;
}

abstract final class BusyMarkStroke {
  static const double hairline = 1;
  static const double focus = 2;
  static const double sourceCursor = 1.4;
  static const double thematicBreak = 1.6;
  static const double selectionInflate = 1.5;
}

abstract final class BusyMarkAlpha {
  static const double modalBarrier = 0.32;
  static const double focus = 0.18;
  static const double splash = 0.12;
  static const double overlayPressed = 0.14;
  static const double overlayHover = 0.08;
  static const double overlayFocus = 0.10;
  static const double textSelection = 0.32;
  static const double floatingTextSelection = 0.28;
  static const double languageMenuShadow = 0.42;
  static const double sourceCollapsedLine = 0.045;
  static const double sourceCursor = 0.82;
  static const double sourceSyntaxBackground = 0.10;
  static const double syntaxCommentDark = 0.82;
  static const double syntaxCommentLight = 0.76;
  static const double previewHighlight = 0.24;
  static const double thematicBreak = 0.34;
  static const double thematicBreakHandle = 0.24;
  static const double thematicBreakSelected = 0.72;
  static const double floatingEntryIcon = 0.72;
  static const double toolbarPressed = 0.18;
  static const double toolbarHover = 0.10;
  static const double windowShadowHigh = 0.75;
  static const double windowShadowMedium = 0.45;
  static const double windowShadowLow = 0.25;
}

abstract final class BusyMarkTypography {
  static const String fontFamily = 'Ubuntu';
  static const String monoFontFamily = 'Ubuntu Mono';
  static const List<String> fontFamilyFallback = [
    'Noto Sans Arabic',
    'Noto Sans',
    'DejaVu Sans',
  ];
  static const List<String> monoFontFamilyFallback = [
    'Noto Sans Arabic',
    'Noto Sans Mono',
    'DejaVu Sans Mono',
    'DejaVu Sans',
  ];
  static const double codeLineHeight = 1.45;
  static const double bodyLineHeight = 1.5;
  static const double defaultFontSize = 14;
  static const double previewThematicBreakHeight = BusyMarkStroke.thematicBreak;
  static const double sourceCursorHeightScale = 1.22;
  static const double sourceLineNumberScale = 0.92;
  static const double hiddenLayoutFontSize = 0.01;
  static const double hiddenLayoutHeight = 0.01;

  static double markdownHeadingScale(int level) {
    return switch (level) {
      1 => 1.55,
      2 => 1.36,
      3 => 1.22,
      4 => 1.12,
      5 => 1.04,
      _ => 0.98,
    };
  }
}

/// Keeps a known left-to-right value stable inside surrounding RTL text.
String busyMarkLtrIsolate(Object value) => '\u2066$value\u2069';

/// Isolates a machine value only when the surrounding interface is RTL.
String busyMarkLtrIsolateFor(BuildContext context, Object value) {
  return Directionality.maybeOf(context) == TextDirection.rtl
      ? busyMarkLtrIsolate(value)
      : value.toString();
}

/// Lets the first strong character choose direction without affecting neighbors.
String busyMarkBidiIsolate(Object value) => '\u2068$value\u2069';

/// Applies first-strong isolation only inside an RTL interface.
String busyMarkBidiIsolateFor(BuildContext context, Object value) {
  return Directionality.maybeOf(context) == TextDirection.rtl
      ? busyMarkBidiIsolate(value)
      : value.toString();
}

abstract final class BusyMarkMotion {
  static const Duration modalPadding = Duration(milliseconds: 100);
  static const Duration sidebarExpand = Duration(milliseconds: 120);
  static const Duration floatingEntry = Duration(milliseconds: 140);
  static const Duration scroll = Duration(milliseconds: 180);
  static const Duration previewSearchDelay = Duration(milliseconds: 80);
  static const Duration tooltipWait = Duration(milliseconds: 450);
  static const Curve modalPaddingCurve = Curves.decelerate;
  static const Curve floatingEntryCurve = Curves.easeOutCubic;
}

abstract final class BusyMarkInsets {
  static const input = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.md,
    vertical: BusyMarkSpacing.smPlus,
  );
  static const listTile = EdgeInsets.symmetric(horizontal: BusyMarkSpacing.md);
  static const settingsPage = EdgeInsets.fromLTRB(
    BusyMarkSpacing.xl,
    BusyMarkSpacing.mdPlus,
    BusyMarkSpacing.xl,
    BusyMarkSpacing.xxl,
  );
  static const welcomePage = EdgeInsets.fromLTRB(
    BusyMarkSpacing.xl,
    BusyMarkSpacing.lgPlus,
    BusyMarkSpacing.xl,
    BusyMarkSpacing.xxl,
  );
  static const sidebarTabs = EdgeInsets.fromLTRB(
    BusyMarkSpacing.smPlus,
    0,
    BusyMarkSpacing.smPlus,
    BusyMarkSpacing.sm,
  );
  static const sidebarHeader = EdgeInsetsDirectional.fromSTEB(
    BusyMarkSpacing.mdPlus,
    BusyMarkSpacing.mdPlus,
    BusyMarkSpacing.sm,
    BusyMarkSpacing.sm - BusyMarkSpacing.xxs,
  );
  static const sidebarList = EdgeInsets.fromLTRB(
    BusyMarkSpacing.sm,
    BusyMarkSpacing.xxs,
    BusyMarkSpacing.sm,
    BusyMarkSpacing.smPlus,
  );
  static const tocHeader = EdgeInsetsDirectional.fromSTEB(
    BusyMarkSpacing.sm,
    0,
    0,
    BusyMarkSpacing.sm,
  );
  static const previewCodeBlock = EdgeInsets.all(BusyMarkSpacing.mdPlus);
  static const previewCallout = EdgeInsets.all(BusyMarkSpacing.md);
  static const previewTableCell = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.sm,
    vertical: BusyMarkSpacing.xs,
  );
  static const dialogButton = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.mdPlus,
    vertical: 7,
  );
  static const sectionLabel = EdgeInsets.fromLTRB(
    BusyMarkSpacing.md,
    BusyMarkSpacing.mdPlus,
    BusyMarkSpacing.md,
    6,
  );
  static const documentHeadingBlock = EdgeInsets.only(
    top: BusyMarkSizes.previewHeadingTop,
    bottom: BusyMarkSizes.previewHeadingBottom,
  );
  static const documentParagraphBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSizes.previewHeadingBottom,
  );
  static const wysiwygContainerBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.sm,
  );
  static const wysiwygTableBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.smPlus,
  );
  static const wysiwygThematicBreakBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.md,
  );
  static const wysiwygDefaultBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.xs,
  );
  static const wysiwygContainerContent = EdgeInsets.all(BusyMarkSpacing.md);
  static const wysiwygTableContent = EdgeInsets.all(BusyMarkSpacing.smPlus);
  static const wysiwygThematicBreakContent = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.md,
  );
  static const wysiwygTableCell = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.smPlus,
    vertical: BusyMarkSpacing.sm,
  );
  static const sourceEditor = EdgeInsets.fromLTRB(
    BusyMarkSourceEditorMetrics.paddingLeft,
    BusyMarkSourceEditorMetrics.paddingTop,
    BusyMarkSourceEditorMetrics.paddingRight,
    BusyMarkSourceEditorMetrics.paddingBottom,
  );
  static const searchResultRow = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.lg,
    vertical: BusyMarkSpacing.sm,
  );
}

abstract final class BusyMarkSourceEditorMetrics {
  static const double paddingTop = BusyMarkSpacing.lg;
  static const double paddingBottom = BusyMarkSpacing.lg;
  static const double paddingLeft = BusyMarkSpacing.md;
  static const double paddingRight = BusyMarkSpacing.lg;
}

abstract final class BusyMarkShadow {
  static const double floatingBlur = 24;
  static const Offset floatingOffset = Offset(0, 8);
  static const double windowMargin = 32;

  static Color _scaleAlpha(Color color, double scale) {
    return color.withValues(
      alpha: (color.a * scale).clamp(0.0, 1.0).toDouble(),
    );
  }

  static Color floatingColor(BuildContext context) {
    return BusyMarkSurfaceColors.of(context).shade;
  }

  static List<BoxShadow> surfaceShadows(Color color) {
    return [
      BoxShadow(
        color: _scaleAlpha(color, 0.28),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: _scaleAlpha(color, 0.18),
        blurRadius: 3,
        offset: const Offset(0, -1),
      ),
      BoxShadow(
        color: _scaleAlpha(color, 0.16),
        blurRadius: 1,
        offset: Offset.zero,
      ),
    ];
  }

  static List<BoxShadow> surfaceShadowsFor(BuildContext context) {
    return surfaceShadows(floatingColor(context));
  }

  static List<BoxShadow> floatingShadows(Color color) {
    return [
      BoxShadow(color: color, blurRadius: floatingBlur, offset: floatingOffset),
    ];
  }

  static List<BoxShadow> floatingShadowsFor(BuildContext context) {
    return floatingShadows(floatingColor(context));
  }

  static List<BoxShadow> windowShadows(Color color) {
    return [
      BoxShadow(
        color: color.withValues(
          alpha: color.a * BusyMarkAlpha.windowShadowHigh,
        ),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: color.withValues(
          alpha: color.a * BusyMarkAlpha.windowShadowMedium,
        ),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: color.withValues(alpha: color.a * BusyMarkAlpha.windowShadowLow),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> windowShadowsFor(BuildContext context) {
    return windowShadows(floatingColor(context));
  }

  static List<BoxShadow> edgeShadows(Color color, {required bool below}) {
    return [
      BoxShadow(
        color: color,
        blurRadius: floatingBlur / 2,
        offset: Offset(
          0,
          below ? floatingOffset.dy / 2 : -floatingOffset.dy / 2,
        ),
      ),
    ];
  }

  static List<BoxShadow> edgeShadowsFor(
    BuildContext context, {
    required bool below,
  }) {
    return edgeShadows(floatingColor(context), below: below);
  }
}

BoxDecoration busyMarkSurfaceDecoration(
  BuildContext context, {
  required Color color,
  required BorderRadius borderRadius,
  Border? border,
  bool elevated = true,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
    boxShadow: elevated ? BusyMarkShadow.surfaceShadowsFor(context) : null,
  );
}

abstract final class BusyMarkLinuxPalette {
  static Color fromArgb(int value) => Color(value);

  static const transparent = Color(0x00000000);
  static const white = Color(0xFFFFFFFF);
  static const blueAccent = Color(0xFF3584E4);
  static const ubuntuBlueAccent = Color(0xFF0073E5);
  static const ubuntuTealAccent = Color(0xFF2190A4);
  static const ubuntuGreenAccent = Color(0xFF3A944A);
  static const ubuntuYellowAccent = Color(0xFFC88800);
  static const ubuntuOrangeAccent = Color(0xFFED5B00);
  static const ubuntuRedAccent = Color(0xFFDA3450);
  static const ubuntuPinkAccent = Color(0xFFD56199);
  static const ubuntuPurpleAccent = Color(0xFF7764D8);
  static const ubuntuSlateAccent = Color(0xFF6F8396);
  static const ubuntuBrownAccent = Color(0xFF986A44);
  static const ubuntuMagentaAccent = Color(0xFFB34CB3);
  static const ubuntuOliveAccent = Color(0xFF4B8501);
  static const ubuntuPrussianGreenAccent = Color(0xFF308280);
  static const ubuntuSageAccent = Color(0xFF657B69);
  static const ubuntuWartyBrownAccent = Color(0xFFB39169);
  static const red = Color(0xFFC01C28);
  static const yellow = Color(0xFFE5A50A);
  static const green = Color(0xFF2EC27E);
  static const light2 = Color(0xFFF6F5F4);
  static const light4 = Color(0xFFC0BFBC);
  static const dark4 = Color(0xFF242424);
  static const black = Color(0xFF000000);
}

@immutable
class BusyMarkSyntaxColors extends ThemeExtension<BusyMarkSyntaxColors> {
  const BusyMarkSyntaxColors({
    required this.heading,
    required this.keyword,
    required this.tag,
    required this.attribute,
    required this.string,
    required this.literal,
    required this.link,
    required this.comment,
    required this.punctuation,
  });

  factory BusyMarkSyntaxColors.fromSurfaceColors(
    Brightness brightness,
    BusyMarkSurfaceColors colors,
  ) {
    final dark = brightness == Brightness.dark;
    return BusyMarkSyntaxColors(
      heading: dark ? _darkHeading : _lightHeading,
      keyword: dark ? _darkKeyword : _lightKeyword,
      tag: dark ? _darkTag : _lightTag,
      attribute: dark ? _darkAttribute : _lightAttribute,
      string: dark ? _darkString : _lightString,
      literal: dark ? _darkLiteral : _lightLiteral,
      link: dark ? _darkLink : _lightLink,
      comment: colors.mutedForeground.withValues(
        alpha: dark
            ? BusyMarkAlpha.syntaxCommentDark
            : BusyMarkAlpha.syntaxCommentLight,
      ),
      punctuation: colors.mutedForeground,
    );
  }

  static BusyMarkSyntaxColors of(BuildContext context) {
    return Theme.of(context).extension<BusyMarkSyntaxColors>() ??
        BusyMarkSyntaxColors.fromSurfaceColors(
          Theme.of(context).brightness,
          BusyMarkSurfaceColors.of(context),
        );
  }

  static const _darkHeading = Color(0xFF99C1F1);
  static const _lightHeading = Color(0xFF1A5FB4);
  static const _darkKeyword = Color(0xFFFFBE6F);
  static const _lightKeyword = Color(0xFF9C6B00);
  static const _darkTag = Color(0xFF8FF0A4);
  static const _lightTag = Color(0xFF2A7B43);
  static const _darkAttribute = Color(0xFFF9F06B);
  static const _lightAttribute = Color(0xFF865E00);
  static const _darkString = Color(0xFFF66151);
  static const _lightString = Color(0xFFC01C28);
  static const _darkLiteral = Color(0xFFDC8ADD);
  static const _lightLiteral = Color(0xFF813D9C);
  static const _darkLink = Color(0xFF62A0EA);
  static const _lightLink = Color(0xFF1C71D8);

  final Color heading;
  final Color keyword;
  final Color tag;
  final Color attribute;
  final Color string;
  final Color literal;
  final Color link;
  final Color comment;
  final Color punctuation;

  @override
  BusyMarkSyntaxColors copyWith({
    Color? heading,
    Color? keyword,
    Color? tag,
    Color? attribute,
    Color? string,
    Color? literal,
    Color? link,
    Color? comment,
    Color? punctuation,
  }) {
    return BusyMarkSyntaxColors(
      heading: heading ?? this.heading,
      keyword: keyword ?? this.keyword,
      tag: tag ?? this.tag,
      attribute: attribute ?? this.attribute,
      string: string ?? this.string,
      literal: literal ?? this.literal,
      link: link ?? this.link,
      comment: comment ?? this.comment,
      punctuation: punctuation ?? this.punctuation,
    );
  }

  @override
  BusyMarkSyntaxColors lerp(covariant BusyMarkSyntaxColors? other, double t) {
    if (other == null) {
      return this;
    }
    return BusyMarkSyntaxColors(
      heading: Color.lerp(heading, other.heading, t)!,
      keyword: Color.lerp(keyword, other.keyword, t)!,
      tag: Color.lerp(tag, other.tag, t)!,
      attribute: Color.lerp(attribute, other.attribute, t)!,
      string: Color.lerp(string, other.string, t)!,
      literal: Color.lerp(literal, other.literal, t)!,
      link: Color.lerp(link, other.link, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      punctuation: Color.lerp(punctuation, other.punctuation, t)!,
    );
  }
}

enum BusyMarkVcsFileColor {
  modified,
  added,
  deleted,
  untracked,
  conflicted,
  copied,
  renamed,
}

Color busyMarkDestructiveForeground(BuildContext context) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) {
    return const Color(0xFFFFA99B);
  }
  return theme.colorScheme.error;
}

Color busyMarkVcsFileStatusColor(
  BuildContext context,
  BusyMarkVcsFileColor status,
) {
  final brightness = Theme.of(context).brightness;
  final dark = brightness == Brightness.dark;
  return switch (status) {
    BusyMarkVcsFileColor.modified =>
      dark ? const Color(0xFF99C1F1) : BusyMarkLinuxPalette.ubuntuBlueAccent,
    BusyMarkVcsFileColor.added =>
      dark ? const Color(0xFF8FF0A4) : BusyMarkLinuxPalette.ubuntuGreenAccent,
    BusyMarkVcsFileColor.deleted =>
      dark ? const Color(0xFFFF7B63) : BusyMarkLinuxPalette.red,
    BusyMarkVcsFileColor.untracked =>
      dark ? const Color(0xFFFFBE6F) : BusyMarkLinuxPalette.ubuntuBrownAccent,
    BusyMarkVcsFileColor.conflicted =>
      dark ? const Color(0xFFFF7B63) : BusyMarkLinuxPalette.ubuntuRedAccent,
    BusyMarkVcsFileColor.copied =>
      dark ? const Color(0xFF8FF0A4) : BusyMarkLinuxPalette.ubuntuOliveAccent,
    BusyMarkVcsFileColor.renamed =>
      dark ? const Color(0xFFDC8ADD) : BusyMarkLinuxPalette.ubuntuPurpleAccent,
  };
}

@immutable
class BusyMarkSurfaceColors extends ThemeExtension<BusyMarkSurfaceColors> {
  const BusyMarkSurfaceColors({
    required this.window,
    required this.view,
    required this.sidebar,
    required this.secondarySidebar,
    required this.headerbar,
    required this.headerbarFlat,
    required this.panel,
    required this.card,
    required this.groupedList,
    required this.dialog,
    required this.popover,
    required this.control,
    required this.controlHover,
    required this.controlActive,
    required this.activeToggle,
    required this.foreground,
    required this.mutedForeground,
    required this.disabledForeground,
    required this.disabledControl,
    required this.border,
    required this.subtleBorder,
    required this.sidebarBorder,
    required this.shade,
    required this.muted,
    required this.admonitionNote,
    required this.admonitionTip,
    required this.admonitionWarning,
  });

  factory BusyMarkSurfaceColors.fromBrightness(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => const BusyMarkSurfaceColors(
        window: Color(0xFFFAFAFA),
        view: Color(0xFFFFFFFF),
        sidebar: Color(0xFFEFEFEF),
        secondarySidebar: Color(0xFFF6F6F6),
        headerbar: Color(0xFFFFFFFF),
        headerbarFlat: Color(0xFFFFFFFF),
        panel: Color(0xFFF6F5F4),
        card: Color(0xFFFFFFFF),
        groupedList: Color(0xFFFFFFFF),
        dialog: Color(0xFFFAFAFA),
        popover: Color(0xFFFFFFFF),
        control: Color(0xFFFFFFFF),
        controlHover: Color(0xFFF6F6F6),
        controlActive: Color(0xFFEDEDED),
        activeToggle: Color(0xFFFFFFFF),
        foreground: Color.fromRGBO(0, 0, 0, 0.82),
        mutedForeground: Color.fromRGBO(0, 0, 0, 0.58),
        disabledForeground: Color.fromRGBO(0, 0, 0, 0.38),
        disabledControl: Color(0xFFF3F3F3),
        border: Color.fromRGBO(0, 0, 0, 0.18),
        subtleBorder: Color.fromRGBO(0, 0, 0, 0.10),
        sidebarBorder: Color.fromRGBO(0, 0, 0, 0.08),
        shade: Color.fromRGBO(0, 0, 0, 0.22),
        muted: Color.fromRGBO(0, 0, 0, 0.58),
        admonitionNote: Color(0xFFF0F4F8),
        admonitionTip: Color(0xFFEAF8EF),
        admonitionWarning: Color(0xFFFFF3D6),
      ),
      Brightness.dark => const BusyMarkSurfaceColors(
        window: Color(0xFF1E1E1E),
        view: Color(0xFF242424),
        sidebar: Color(0xFF303030),
        secondarySidebar: Color(0xFF2A2A2A),
        headerbar: Color(0xFF303030),
        headerbarFlat: Color(0xFF242424),
        panel: Color(0xFF2A2A2A),
        card: Color(0xFF2A2A2A),
        groupedList: Color(0xFF383838),
        dialog: Color(0xFF2A2A2A),
        popover: Color(0xFF383838),
        control: Color(0xFF383838),
        controlHover: Color(0xFF424242),
        controlActive: Color(0xFF4A4A4A),
        activeToggle: Color(0xFF4A4A4A),
        foreground: Color(0xFFFFFFFF),
        mutedForeground: Color.fromRGBO(255, 255, 255, 0.70),
        disabledForeground: Color.fromRGBO(255, 255, 255, 0.38),
        disabledControl: Color(0xFF303030),
        border: Color.fromRGBO(0, 0, 0, 0.70),
        subtleBorder: Color.fromRGBO(255, 255, 255, 0.10),
        sidebarBorder: Color.fromRGBO(0, 0, 0, 0.36),
        shade: Color.fromRGBO(0, 0, 0, 0.25),
        muted: Color.fromRGBO(255, 255, 255, 0.70),
        admonitionNote: Color(0xFF333333),
        admonitionTip: Color(0xFF26352C),
        admonitionWarning: Color(0xFF3B321F),
      ),
    };
  }

  static BusyMarkSurfaceColors of(BuildContext context) {
    return Theme.of(context).extension<BusyMarkSurfaceColors>() ??
        BusyMarkSurfaceColors.fromBrightness(Theme.of(context).brightness);
  }

  final Color window;
  final Color view;
  final Color sidebar;
  final Color secondarySidebar;
  final Color headerbar;
  final Color headerbarFlat;
  final Color panel;
  final Color card;
  final Color groupedList;
  final Color dialog;
  final Color popover;
  final Color control;
  final Color controlHover;
  final Color controlActive;
  final Color activeToggle;
  final Color foreground;
  final Color mutedForeground;
  final Color disabledForeground;
  final Color disabledControl;
  final Color border;
  final Color subtleBorder;
  final Color sidebarBorder;
  final Color shade;
  final Color muted;
  final Color admonitionNote;
  final Color admonitionTip;
  final Color admonitionWarning;

  @override
  BusyMarkSurfaceColors copyWith({
    Color? window,
    Color? view,
    Color? sidebar,
    Color? secondarySidebar,
    Color? headerbar,
    Color? headerbarFlat,
    Color? panel,
    Color? card,
    Color? groupedList,
    Color? dialog,
    Color? popover,
    Color? control,
    Color? controlHover,
    Color? controlActive,
    Color? activeToggle,
    Color? foreground,
    Color? mutedForeground,
    Color? disabledForeground,
    Color? disabledControl,
    Color? border,
    Color? subtleBorder,
    Color? sidebarBorder,
    Color? shade,
    Color? muted,
    Color? admonitionNote,
    Color? admonitionTip,
    Color? admonitionWarning,
  }) {
    return BusyMarkSurfaceColors(
      window: window ?? this.window,
      view: view ?? this.view,
      sidebar: sidebar ?? this.sidebar,
      secondarySidebar: secondarySidebar ?? this.secondarySidebar,
      headerbar: headerbar ?? this.headerbar,
      headerbarFlat: headerbarFlat ?? this.headerbarFlat,
      panel: panel ?? this.panel,
      card: card ?? this.card,
      groupedList: groupedList ?? this.groupedList,
      dialog: dialog ?? this.dialog,
      popover: popover ?? this.popover,
      control: control ?? this.control,
      controlHover: controlHover ?? this.controlHover,
      controlActive: controlActive ?? this.controlActive,
      activeToggle: activeToggle ?? this.activeToggle,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledControl: disabledControl ?? this.disabledControl,
      border: border ?? this.border,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      shade: shade ?? this.shade,
      muted: muted ?? this.muted,
      admonitionNote: admonitionNote ?? this.admonitionNote,
      admonitionTip: admonitionTip ?? this.admonitionTip,
      admonitionWarning: admonitionWarning ?? this.admonitionWarning,
    );
  }

  @override
  BusyMarkSurfaceColors lerp(covariant BusyMarkSurfaceColors? other, double t) {
    if (other == null) {
      return this;
    }
    return BusyMarkSurfaceColors(
      window: Color.lerp(window, other.window, t)!,
      view: Color.lerp(view, other.view, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      secondarySidebar: Color.lerp(
        secondarySidebar,
        other.secondarySidebar,
        t,
      )!,
      headerbar: Color.lerp(headerbar, other.headerbar, t)!,
      headerbarFlat: Color.lerp(headerbarFlat, other.headerbarFlat, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      card: Color.lerp(card, other.card, t)!,
      groupedList: Color.lerp(groupedList, other.groupedList, t)!,
      dialog: Color.lerp(dialog, other.dialog, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      control: Color.lerp(control, other.control, t)!,
      controlHover: Color.lerp(controlHover, other.controlHover, t)!,
      controlActive: Color.lerp(controlActive, other.controlActive, t)!,
      activeToggle: Color.lerp(activeToggle, other.activeToggle, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      disabledForeground: Color.lerp(
        disabledForeground,
        other.disabledForeground,
        t,
      )!,
      disabledControl: Color.lerp(disabledControl, other.disabledControl, t)!,
      border: Color.lerp(border, other.border, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      shade: Color.lerp(shade, other.shade, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      admonitionNote: Color.lerp(admonitionNote, other.admonitionNote, t)!,
      admonitionTip: Color.lerp(admonitionTip, other.admonitionTip, t)!,
      admonitionWarning: Color.lerp(
        admonitionWarning,
        other.admonitionWarning,
        t,
      )!,
    );
  }
}

ButtonStyle busyMarkHeaderIconButtonStyle({
  Color? foregroundColor,
  WidgetStateProperty<Color?>? backgroundColor,
  WidgetStateProperty<Color?>? overlayColor,
  double borderRadius = BusyMarkRadius.headerButton,
}) {
  return ButtonStyle(
    fixedSize: const WidgetStatePropertyAll(
      Size.square(BusyMarkSizes.iconButton),
    ),
    minimumSize: const WidgetStatePropertyAll(
      Size.square(BusyMarkSizes.iconButton),
    ),
    maximumSize: const WidgetStatePropertyAll(
      Size.square(BusyMarkSizes.iconButton),
    ),
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: foregroundColor == null
        ? null
        : WidgetStatePropertyAll(foregroundColor),
    backgroundColor: backgroundColor,
    overlayColor: overlayColor,
    side: const WidgetStatePropertyAll(BorderSide.none),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
    ),
  );
}

WidgetStateProperty<Color?> busyMarkHeaderButtonBackground(
  BuildContext context,
) {
  final colors = BusyMarkSurfaceColors.of(context);
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return colors.disabledControl;
    }
    if (states.contains(WidgetState.pressed)) {
      return colors.controlActive;
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return colors.controlHover;
    }
    return colors.control;
  });
}

WidgetStateProperty<Color?> busyMarkTransparentHeaderButtonBackground(
  BuildContext context,
) {
  final colors = BusyMarkSurfaceColors.of(context);
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return colors.controlActive;
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return colors.controlHover;
    }
    return BusyMarkLinuxPalette.transparent;
  });
}

Color busyMarkSelectedBackground(BuildContext context) {
  return BusyMarkSurfaceColors.of(context).controlActive;
}

Color busyMarkRowHoverColor(BuildContext context) {
  return BusyMarkSurfaceColors.of(context).controlHover;
}

TextStyle? busyMarkSectionHeaderStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.titleSmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class BusyMarkHeaderIconButton extends StatelessWidget {
  const BusyMarkHeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.accented = false,
    this.transparent = false,
    this.elevated = false,
    this.shortcut,
    this.foregroundColor,
    this.backgroundColor,
    this.borderRadius = BusyMarkRadius.headerButton,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final bool accented;
  final bool transparent;

  /// Paints the shared theme-aware surface shadow behind this control.
  final bool elevated;
  final String? shortcut;
  final Color? foregroundColor;
  final WidgetStateProperty<Color?>? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final button = IconButton(
      style: busyMarkHeaderIconButtonStyle(
        foregroundColor:
            foregroundColor ??
            (accented
                ? colorScheme.onPrimary
                : selected
                ? colorScheme.primary
                : colors.mutedForeground),
        backgroundColor:
            backgroundColor ??
            (accented
                ? WidgetStatePropertyAll(colorScheme.primary)
                : selected
                ? WidgetStatePropertyAll(colors.controlActive)
                : transparent
                ? busyMarkTransparentHeaderButtonBackground(context)
                : busyMarkHeaderButtonBackground(context)),
        borderRadius: borderRadius,
      ),
      tooltip: shortcut == null ? tooltip : '$tooltip ($shortcut)',
      icon: Icon(icon, size: BusyMarkSizes.iconSm),
      onPressed: onPressed,
    );
    final shadows = elevated ? BusyMarkShadow.surfaceShadowsFor(context) : null;
    if (shadows == null || shadows.isEmpty) {
      return button;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: button,
    );
  }
}

class BusyMarkHeaderPopupMenuButton<T> extends StatelessWidget {
  const BusyMarkHeaderPopupMenuButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.itemBuilder,
    required this.onSelected,
    this.transparent = false,
    this.elevated = false,
    this.shortcut,
    this.foregroundColor,
    this.backgroundColor,
    this.borderRadius = BusyMarkRadius.headerButton,
  });

  final String tooltip;
  final IconData icon;
  final FutureOr<List<PopupMenuEntry<T>>> Function(BuildContext context)
  itemBuilder;
  final ValueChanged<T> onSelected;
  final bool transparent;

  /// Paints the shared theme-aware surface shadow behind this control.
  final bool elevated;
  final String? shortcut;
  final Color? foregroundColor;
  final WidgetStateProperty<Color?>? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final effectiveForeground = foregroundColor ?? colors.mutedForeground;
    final button = Theme(
      data: theme.copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: busyMarkHeaderIconButtonStyle(
            foregroundColor: effectiveForeground,
            backgroundColor:
                backgroundColor ??
                (transparent
                    ? busyMarkTransparentHeaderButtonBackground(context)
                    : busyMarkHeaderButtonBackground(context)),
            borderRadius: borderRadius,
          ),
        ),
      ),
      child: Builder(
        builder: (buttonContext) => IconButton(
          tooltip: shortcut == null ? tooltip : '$tooltip ($shortcut)',
          onPressed: () => _showMenu(buttonContext),
          icon: Icon(
            icon,
            size: BusyMarkSizes.iconSm,
            color: effectiveForeground,
          ),
        ),
      ),
    );
    final shadows = elevated ? BusyMarkShadow.surfaceShadowsFor(context) : null;
    if (shadows == null || shadows.isEmpty) {
      return button;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: button,
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final button = context.findRenderObject();
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay?.context.findRenderObject();
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final popupTheme = theme.popupMenuTheme;
    final items = await itemBuilder(context);
    if (!context.mounted || items.isEmpty) {
      return;
    }
    if (button is! RenderBox || overlay is! RenderBox) {
      return;
    }

    final escapeDismiss = BusyMarkPopupEscapeDismissBinding(navigator);
    final buttonRect =
        button.localToGlobal(Offset.zero, ancestor: overlay) & button.size;
    final hasShortcutItems = items.whereType<BusyMarkPopupMenuItem<T>>().any((
      item,
    ) {
      final shortcut = item.shortcut;
      return shortcut != null && shortcut.isNotEmpty;
    });
    final menuWidth = hasShortcutItems
        ? BusyMarkSizes.popupMenuShortcutWidth
        : BusyMarkSizes.popupMenuMinWidth;
    final minLeft = BusyMarkSpacing.sm;
    final maxLeft = overlay.size.width - menuWidth - BusyMarkSpacing.sm;
    final rawLeft = buttonRect.center.dx - menuWidth / 2;
    final left = maxLeft <= minLeft
        ? minLeft
        : rawLeft.clamp(minLeft, maxLeft).toDouble();
    final top = buttonRect.bottom + BusyMarkSpacing.xs + BusyMarkSpacing.xxs;
    T? result;
    escapeDismiss.attach();
    try {
      result = await showMenu<T>(
        context: context,
        useRootNavigator: true,
        items: items,
        position: RelativeRect.fromLTRB(
          left,
          top,
          math.max(minLeft, overlay.size.width - left - menuWidth),
          math.max(BusyMarkSpacing.sm, overlay.size.height - top),
        ),
        color: popupTheme.color ?? colors.popover,
        surfaceTintColor: BusyMarkLinuxPalette.transparent,
        elevation: BusyMarkElevation.popover,
        shadowColor: colors.shade,
        shape: _BusyMarkHeaderPopoverShape(
          borderRadius: BorderRadius.circular(BusyMarkRadius.window),
          side: BorderSide(
            color: colors.subtleBorder,
            width: BusyMarkStroke.hairline,
          ),
        ),
        menuPadding: const EdgeInsets.only(
          top: _busyMarkHeaderPopoverArrowHeight + BusyMarkSpacing.sm,
          bottom: BusyMarkSpacing.sm,
        ),
        constraints: BoxConstraints.tightFor(width: menuWidth),
        clipBehavior: Clip.antiAlias,
        popUpAnimationStyle: AnimationStyle.noAnimation,
        requestFocus: true,
      );
    } finally {
      escapeDismiss.detach();
    }
    if (result != null) {
      onSelected(result);
    }
  }
}

class BusyMarkPopupEscapeDismissBinding {
  BusyMarkPopupEscapeDismissBinding(this.navigator);

  final NavigatorState navigator;
  bool _attached = false;

  void attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void detach() {
    if (!_attached) {
      return;
    }
    _attached = false;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_attached ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    detach();
    if (navigator.canPop()) {
      navigator.pop();
    }
    return true;
  }
}

/// Shows a BusyMark-styled context menu at a global pointer position.
///
/// The menu opens away from the pointer's reading-direction edge and stays
/// inside the root overlay. Use [BusyMarkPopupMenuItem] entries to keep menu
/// rows consistent with the rest of the application.
Future<T?> showBusyMarkContextMenu<T>(
  BuildContext context,
  Offset globalPosition, {
  required List<PopupMenuEntry<T>> items,
  double width = BusyMarkSizes.popupMenuMinWidth,
}) {
  if (items.isEmpty) {
    return Future<T?>.value();
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay?.context.findRenderObject();
  if (overlay is! RenderBox) {
    return Future<T?>.value();
  }
  final theme = Theme.of(context);
  final colors = BusyMarkSurfaceColors.of(context);
  final popupTheme = theme.popupMenuTheme;
  final localPosition = overlay.globalToLocal(globalPosition);
  final minLeft = BusyMarkSpacing.sm;
  final maxLeft = overlay.size.width - width - BusyMarkSpacing.sm;
  final preferredLeft = Directionality.of(context) == TextDirection.rtl
      ? localPosition.dx - width
      : localPosition.dx;
  final left = maxLeft <= minLeft
      ? minLeft
      : preferredLeft.clamp(minLeft, maxLeft).toDouble();
  final maxTop = math.max(
    BusyMarkSpacing.sm,
    overlay.size.height - BusyMarkSpacing.sm,
  );
  final top = localPosition.dy.clamp(BusyMarkSpacing.sm, maxTop).toDouble();
  return showMenu<T>(
    context: context,
    useRootNavigator: true,
    position: RelativeRect.fromLTRB(
      left,
      top,
      math.max(minLeft, overlay.size.width - left - width),
      math.max(BusyMarkSpacing.sm, overlay.size.height - top),
    ),
    items: items,
    color: popupTheme.color ?? colors.popover,
    surfaceTintColor: BusyMarkLinuxPalette.transparent,
    elevation: BusyMarkElevation.popover,
    shadowColor: colors.shade,
    constraints: BoxConstraints.tightFor(width: width),
    clipBehavior: Clip.antiAlias,
    popUpAnimationStyle: AnimationStyle.noAnimation,
    requestFocus: true,
  );
}

const double _busyMarkHeaderPopoverArrowWidth = 16;
const double _busyMarkHeaderPopoverArrowHeight = 8;

class _BusyMarkHeaderPopoverShape extends ShapeBorder {
  const _BusyMarkHeaderPopoverShape({
    required this.borderRadius,
    required this.side,
  });

  final BorderRadius borderRadius;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final resolved = borderRadius.resolve(textDirection);
    final body = Rect.fromLTWH(
      rect.left,
      rect.top + _busyMarkHeaderPopoverArrowHeight,
      rect.width,
      math.max(0, rect.height - _busyMarkHeaderPopoverArrowHeight),
    );
    final maxRadius = math.min(body.width, body.height) / 2;
    final topLeft = math.min(resolved.topLeft.x, maxRadius);
    final topRight = math.min(resolved.topRight.x, maxRadius);
    final bottomRight = math.min(resolved.bottomRight.x, maxRadius);
    final bottomLeft = math.min(resolved.bottomLeft.x, maxRadius);
    const arrowHalf = _busyMarkHeaderPopoverArrowWidth / 2;
    final arrowCenter = body.center.dx.clamp(
      body.left + topLeft + arrowHalf,
      body.right - topRight - arrowHalf,
    );

    return Path()
      ..moveTo(body.left + topLeft, body.top)
      ..lineTo(arrowCenter - arrowHalf, body.top)
      ..lineTo(arrowCenter, rect.top)
      ..lineTo(arrowCenter + arrowHalf, body.top)
      ..lineTo(body.right - topRight, body.top)
      ..quadraticBezierTo(body.right, body.top, body.right, body.top + topRight)
      ..lineTo(body.right, body.bottom - bottomRight)
      ..quadraticBezierTo(
        body.right,
        body.bottom,
        body.right - bottomRight,
        body.bottom,
      )
      ..lineTo(body.left + bottomLeft, body.bottom)
      ..quadraticBezierTo(
        body.left,
        body.bottom,
        body.left,
        body.bottom - bottomLeft,
      )
      ..lineTo(body.left, body.top + topLeft)
      ..quadraticBezierTo(body.left, body.top, body.left + topLeft, body.top)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side == BorderSide.none || side.width == 0) {
      return;
    }
    canvas.drawPath(
      getOuterPath(rect.deflate(side.width / 2), textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) {
    return _BusyMarkHeaderPopoverShape(
      borderRadius: borderRadius * t,
      side: side.scale(t),
    );
  }
}

class BusyMarkPopupMenuItem<T> extends PopupMenuEntry<T> {
  const BusyMarkPopupMenuItem({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.shortcut,
    this.enabled = true,
    this.checked = false,
    this.trailingCheck = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? shortcut;
  final bool enabled;
  final bool checked;
  final bool trailingCheck;

  @override
  double get height => BusyMarkSizes.popupMenuItemHeight;

  @override
  bool represents(T? value) => value == this.value;

  @override
  State<BusyMarkPopupMenuItem<T>> createState() =>
      _BusyMarkPopupMenuItemState<T>();
}

class _BusyMarkPopupMenuItemState<T> extends State<BusyMarkPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final popupTheme = theme.popupMenuTheme;
    final textStyle =
        popupTheme.textStyle ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final foreground = widget.enabled
        ? colors.foreground
        : colors.disabledForeground;
    final iconColor = widget.enabled
        ? colors.mutedForeground
        : colors.disabledForeground;
    final labelText = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final shortcut = widget.shortcut;
    final shortcutText = shortcut == null || shortcut.isEmpty
        ? null
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              shortcut,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(color: colors.mutedForeground),
            ),
          );
    final item = Semantics(
      checked: widget.trailingCheck ? widget.checked : null,
      button: true,
      enabled: widget.enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.sm),
        child: InkWell(
          onTap: widget.enabled
              ? () => Navigator.pop<T>(context, widget.value)
              : null,
          borderRadius: BorderRadius.circular(BusyMarkRadius.sm),
          hoverColor: colors.controlHover,
          focusColor: colors.controlHover,
          highlightColor: colors.controlActive,
          splashColor: BusyMarkLinuxPalette.transparent,
          child: SizedBox(
            height: BusyMarkSizes.popupMenuItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BusyMarkSpacing.sm,
              ),
              child: DefaultTextStyle(
                style: textStyle.copyWith(color: foreground),
                child: IconTheme(
                  data: IconThemeData(
                    size: BusyMarkSizes.iconSm,
                    color: iconColor,
                  ),
                  child: widget.trailingCheck
                      ? Row(
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon),
                              const SizedBox(width: BusyMarkSpacing.sm),
                            ],
                            Expanded(child: labelText),
                            const SizedBox(width: BusyMarkSpacing.sm),
                            if (shortcutText != null) ...[
                              shortcutText,
                              const SizedBox(width: BusyMarkSpacing.sm),
                            ],
                            Opacity(
                              opacity: widget.checked ? 1 : 0,
                              child: const Icon(BusyMarkGlyphs.check),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon),
                              const SizedBox(width: BusyMarkSpacing.sm),
                            ],
                            Expanded(child: labelText),
                            if (shortcutText != null) ...[
                              const SizedBox(width: BusyMarkSpacing.sm),
                              shortcutText,
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return item;
  }
}

class BusyMarkPopupSelectorOption<T> {
  const BusyMarkPopupSelectorOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// The shared desktop selector used by Settings-style control rows.
class BusyMarkPopupSelector<T> extends StatelessWidget {
  const BusyMarkPopupSelector({
    super.key,
    required this.value,
    required this.label,
    required this.tooltip,
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.popupMinWidth = BusyMarkSizes.languagePopupMinWidth,
    this.popupMaxWidth = BusyMarkSizes.languagePopupMaxWidth,
    this.buttonMaxWidth = BusyMarkSizes.languageButtonMaxWidth,
  });

  final T? value;
  final String label;
  final String tooltip;
  final List<BusyMarkPopupSelectorOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final double popupMinWidth;
  final double popupMaxWidth;
  final double buttonMaxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final popupTheme = Theme.of(context).popupMenuTheme;
    final navigator = Navigator.of(context, rootNavigator: true);
    final escapeDismiss = BusyMarkPopupEscapeDismissBinding(navigator);
    final selectorEnabled = enabled && options.isNotEmpty;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: PopupMenuButton<T>(
        enabled: selectorEnabled,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        offset: const Offset(0, BusyMarkSpacing.xs + BusyMarkSpacing.xxs),
        color: popupTheme.color ?? colors.popover,
        surfaceTintColor: BusyMarkLinuxPalette.transparent,
        elevation: BusyMarkElevation.window,
        shadowColor: colors.shade.withValues(
          alpha: BusyMarkAlpha.languageMenuShadow,
        ),
        shape:
            popupTheme.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            ),
        constraints: BoxConstraints(
          minWidth: popupMinWidth,
          maxWidth: popupMaxWidth,
        ),
        useRootNavigator: true,
        requestFocus: true,
        onOpened: escapeDismiss.attach,
        onCanceled: escapeDismiss.detach,
        onSelected: (selection) {
          escapeDismiss.detach();
          onSelected(selection);
        },
        itemBuilder: (context) => [
          for (final option in options)
            BusyMarkPopupMenuItem<T>(
              value: option.value,
              label: option.label,
              icon: option.icon,
              checked: option.value == value,
              trailingCheck: true,
            ),
        ],
        child: _BusyMarkPopupSelectorButton(
          label: label,
          enabled: selectorEnabled,
          maxWidth: buttonMaxWidth,
        ),
      ),
    );
  }
}

class _BusyMarkPopupSelectorButton extends StatefulWidget {
  const _BusyMarkPopupSelectorButton({
    required this.label,
    required this.enabled,
    required this.maxWidth,
  });

  final String label;
  final bool enabled;
  final double maxWidth;

  @override
  State<_BusyMarkPopupSelectorButton> createState() =>
      _BusyMarkPopupSelectorButtonState();
}

class _BusyMarkPopupSelectorButtonState
    extends State<_BusyMarkPopupSelectorButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final theme = Theme.of(context);
    final foreground = widget.enabled
        ? colors.foreground
        : colors.disabledForeground;
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: widget.enabled
          ? (_) {
              if (!_hovered) {
                setState(() => _hovered = true);
              }
            }
          : null,
      onExit: widget.enabled
          ? (_) {
              if (_hovered) {
                setState(() => _hovered = false);
              }
            }
          : null,
      child: Container(
        constraints: BoxConstraints(
          minHeight: BusyMarkSizes.iconButton,
          maxWidth: widget.maxWidth,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: BusyMarkSpacing.sm,
          vertical: BusyMarkSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.controlHover
              : BusyMarkLinuxPalette.transparent,
          borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
          border: Border.all(
            color: _hovered
                ? colors.subtleBorder
                : BusyMarkLinuxPalette.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
            const SizedBox(width: BusyMarkSpacing.sm),
            Icon(
              BusyMarkGlyphs.downArrow,
              size: BusyMarkSizes.iconSm,
              color: widget.enabled
                  ? colors.mutedForeground
                  : colors.disabledForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class BusyMarkClamp extends StatelessWidget {
  const BusyMarkClamp({
    super.key,
    required this.child,
    this.maxWidth = 680,
    this.scrollable = true,
    this.center = true,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.all(BusyMarkSpacing.lg),
    this.controller,
  });

  final Widget child;
  final double maxWidth;
  final bool scrollable;
  final bool center;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final clamped = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: margin,
      padding: padding,
      child: child,
    );

    final body = center
        ? Align(alignment: Alignment.topCenter, child: clamped)
        : clamped;

    return scrollable
        ? SingleChildScrollView(controller: controller, child: body)
        : body;
  }
}

class BusyMarkSurface extends StatelessWidget {
  const BusyMarkSurface({
    super.key,
    required this.child,
    this.filled = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final bool filled;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(BusyMarkRadius.md);
    final cardTheme = Theme.of(context).cardTheme;
    final colors = BusyMarkSurfaceColors.of(context);
    final borderColor = colors.subtleBorder;
    final color = filled
        ? cardTheme.color ?? colors.card
        : BusyMarkLinuxPalette.transparent;
    final shape =
        cardTheme.shape ?? RoundedRectangleBorder(borderRadius: borderRadius);
    final material = Material(
      color: color,
      elevation: BusyMarkElevation.none,
      surfaceTintColor: BusyMarkLinuxPalette.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      child: child,
    );
    if (!filled) {
      return material;
    }
    return DecoratedBox(
      decoration: busyMarkSurfaceDecoration(
        context,
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: material,
    );
  }
}

class BusyMarkGroupedList extends StatelessWidget {
  const BusyMarkGroupedList({
    super.key,
    this.title,
    this.description,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: BusyMarkSpacing.xs),
    this.filled = false,
  });

  final String? title;
  final String? description;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: title == null && (description == null || description!.isEmpty)
            ? BusyMarkSpacing.md
            : BusyMarkSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: padding,
              child: Text(title!, style: busyMarkSectionHeaderStyle(context)),
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: BusyMarkSpacing.xs),
              Padding(
                padding: padding,
                child: Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: BusyMarkSpacing.sm),
          ],
          _BusyMarkGroupedListSurface(filled: filled, children: children),
        ],
      ),
    );
  }
}

class _BusyMarkGroupedListSurface extends StatelessWidget {
  const _BusyMarkGroupedListSurface({
    required this.filled,
    required this.children,
  });

  final bool filled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final dividerColor = colors.view;
    final list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            Divider(
              height: BusyMarkStroke.hairline,
              thickness: BusyMarkStroke.hairline,
              color: dividerColor,
            ),
        ],
      ],
    );

    if (!filled) {
      return list;
    }

    final borderRadius = BorderRadius.circular(BusyMarkRadius.md);
    final color = colors.groupedList;
    return DecoratedBox(
      decoration: busyMarkSurfaceDecoration(
        context,
        color: color,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: BusyMarkLinuxPalette.transparent,
          elevation: BusyMarkElevation.none,
          surfaceTintColor: BusyMarkLinuxPalette.transparent,
          child: list,
        ),
      ),
    );
  }
}

class _BusyMarkHoverBackground extends StatefulWidget {
  const _BusyMarkHoverBackground({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_BusyMarkHoverBackground> createState() =>
      _BusyMarkHoverBackgroundState();
}

class _BusyMarkHoverBackgroundState extends State<_BusyMarkHoverBackground> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled && _hovered
        ? busyMarkRowHoverColor(context)
        : BusyMarkLinuxPalette.transparent;
    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: ColoredBox(color: color, child: widget.child),
    );
  }
}

class BusyMarkActionRow extends StatelessWidget {
  const BusyMarkActionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleStyle = destructive
        ? TextStyle(color: busyMarkDestructiveForeground(context))
        : null;
    return _BusyMarkHoverBackground(
      enabled: enabled,
      child: YaruListTile.square(
        leading: leading,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        enabled: enabled,
        hoverColor: BusyMarkLinuxPalette.transparent,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class BusyMarkSwitchRow extends StatelessWidget {
  const BusyMarkSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _BusyMarkHoverBackground(
      enabled: enabled,
      child: YaruSwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: leading,
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        hoverColor: BusyMarkLinuxPalette.transparent,
      ),
    );
  }
}

class BusyMarkCheckbox extends StatelessWidget {
  const BusyMarkCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tooltip,
    this.tristate = false,
  });

  final bool? value;
  final bool tristate;
  final String? tooltip;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final checkbox = YaruCheckbox(
      value: value,
      tristate: tristate,
      onChanged: onChanged,
    );
    final message = tooltip;
    if (message == null || message.isEmpty) {
      return checkbox;
    }
    return Tooltip(message: message, child: checkbox);
  }
}

enum BusyMarkStatusKind { information, success, warning, error }

class BusyMarkStatusBox extends StatelessWidget {
  const BusyMarkStatusBox({
    super.key,
    required this.message,
    this.kind = BusyMarkStatusKind.information,
  });

  final String message;
  final BusyMarkStatusKind kind;

  @override
  Widget build(BuildContext context) {
    return YaruInfoBox(
      yaruInfoType: switch (kind) {
        BusyMarkStatusKind.information => YaruInfoType.information,
        BusyMarkStatusKind.success => YaruInfoType.success,
        BusyMarkStatusKind.warning => YaruInfoType.warning,
        BusyMarkStatusKind.error => YaruInfoType.danger,
      },
      subtitle: Text(message),
    );
  }
}

class BusyMarkDialogShell extends StatelessWidget {
  const BusyMarkDialogShell({
    super.key,
    required this.title,
    required this.children,
    this.maxWidth = BusyMarkSizes.dialog,
    this.actions = const [],
    this.closable = true,
  });

  final String title;
  final List<Widget> children;
  final double maxWidth;
  final List<Widget> actions;
  final bool closable;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YaruDialogTitleBar(
            title: Text(title),
            isClosable: closable,
            centerTitle: true,
            backgroundColor: colors.dialog,
            border: BorderSide.none,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(BusyMarkSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(BusyMarkSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions) ...[
                    Flexible(child: action),
                    if (action != actions.last)
                      const SizedBox(width: BusyMarkSpacing.sm),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BusyMarkDialogButton extends StatefulWidget {
  const BusyMarkDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suggested = false,
    this.destructive = false,
  }) : assert(!suggested || !destructive);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool suggested;
  final bool destructive;

  @override
  State<BusyMarkDialogButton> createState() => _BusyMarkDialogButtonState();
}

class _BusyMarkDialogButtonState extends State<BusyMarkDialogButton> {
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final colorScheme = theme.colorScheme;
    final background = _buttonBackground(context, colors, colorScheme);
    final foreground = !_enabled
        ? colors.disabledForeground
        : widget.suggested
        ? colorScheme.onPrimary
        : widget.destructive
        ? busyMarkDestructiveForeground(context)
        : colors.foreground;
    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) {
          if (_hovered != value) {
            setState(() => _hovered = value);
          }
        },
        onShowFocusHighlight: (value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BusyMarkSizes.iconButton,
              minWidth: BusyMarkSizes.dialogButtonMinWidth,
              maxWidth: BusyMarkSizes.dialogButtonMaxWidth,
            ),
            padding: BusyMarkInsets.dialogButton,
            decoration: busyMarkSurfaceDecoration(
              context,
              color: background,
              borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
              elevated: _enabled,
            ),
            child: _BusyMarkDialogButtonContent(
              label: widget.label,
              icon: widget.icon,
              foreground: foreground,
            ),
          ),
        ),
      ),
    );
    return button;
  }

  Color _buttonBackground(
    BuildContext context,
    BusyMarkSurfaceColors colors,
    ColorScheme colorScheme,
  ) {
    if (!_enabled) {
      return colors.disabledControl;
    }
    if (!widget.suggested) {
      if (_pressed) {
        return colors.controlActive;
      }
      if (_hovered || _focused) {
        return colors.controlHover;
      }
      return colors.control;
    }
    if (_pressed) {
      return _mixForState(
        context,
        colorScheme.primary,
        BusyMarkAlpha.overlayPressed,
      );
    }
    if (_hovered || _focused) {
      return _mixForState(
        context,
        colorScheme.primary,
        BusyMarkAlpha.overlayHover,
      );
    }
    return colorScheme.primary;
  }

  Color _mixForState(BuildContext context, Color color, double amount) {
    final target = Theme.of(context).brightness == Brightness.dark
        ? BusyMarkLinuxPalette.white
        : BusyMarkLinuxPalette.black;
    return Color.lerp(color, target, amount)!;
  }
}

class _BusyMarkDialogButtonContent extends StatelessWidget {
  const _BusyMarkDialogButtonContent({
    required this.label,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: foreground),
    );
    final icon = this.icon;
    if (icon == null) {
      return Center(widthFactor: 1, child: text);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: BusyMarkSizes.iconSm, color: foreground),
        const SizedBox(width: BusyMarkSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

enum BusyMarkFloatingTextEntryPosition { single, first, middle, last }

class BusyMarkFloatingTextEntryGroup extends StatelessWidget {
  const BusyMarkFloatingTextEntryGroup({super.key, required this.children})
    : assert(children.length > 1);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final borderRadius = BorderRadius.circular(BusyMarkRadius.headerButton);
    return DecoratedBox(
      decoration: busyMarkSurfaceDecoration(
        context,
        color: colors.control,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final child in children) ...[
              child,
              if (child != children.last)
                Divider(
                  height: BusyMarkStroke.hairline,
                  thickness: BusyMarkStroke.hairline,
                  color: colors.view,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class BusyMarkFloatingTextEntry extends StatefulWidget {
  const BusyMarkFloatingTextEntry({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
    this.textDirection,
    this.onSubmitted,
    this.groupPosition = BusyMarkFloatingTextEntryPosition.single,
  }) : assert(minLines > 0),
       assert(maxLines >= minLines);

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final ValueChanged<String>? onSubmitted;
  final BusyMarkFloatingTextEntryPosition groupPosition;

  @override
  State<BusyMarkFloatingTextEntry> createState() =>
      _BusyMarkFloatingTextEntryState();
}

class _BusyMarkFloatingTextEntryState extends State<BusyMarkFloatingTextEntry> {
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  var _hovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(canRequestFocus: widget.enabled);
    _scrollController = ScrollController();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant BusyMarkFloatingTextEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    if (oldWidget.enabled != widget.enabled) {
      _focusNode.canRequestFocus = widget.enabled;
      if (!widget.enabled) {
        _focusNode.unfocus();
        _hovered = false;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = widget.errorText != null;
    final focused = _focusNode.hasFocus;
    final floating = focused || widget.controller.text.isNotEmpty;
    final grouped =
        widget.groupPosition != BusyMarkFloatingTextEntryPosition.single;
    final activeBorder = focused || hasError;
    final radius = _borderRadius();
    final borderColor = focused
        ? colorScheme.primary
        : hasError
        ? colorScheme.error
        : colors.border;
    final labelColor = widget.enabled
        ? colors.mutedForeground
        : colors.disabledForeground;
    final entryHeight = widget.maxLines == 1
        ? BusyMarkSizes.floatingEntryHeight
        : BusyMarkSizes.floatingTextAreaHeight;
    final foreground = widget.enabled
        ? colors.foreground
        : colors.disabledForeground;
    return Semantics(
      enabled: widget.enabled,
      textField: true,
      label: widget.label,
      hint: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            onEnter: widget.enabled
                ? (_) => setState(() => _hovered = true)
                : null,
            onExit: widget.enabled
                ? (_) => setState(() => _hovered = false)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _focusNode.requestFocus : null,
              child: Container(
                height: entryHeight,
                decoration: busyMarkSurfaceDecoration(
                  context,
                  color: !widget.enabled
                      ? colors.disabledControl
                      : _hovered || focused
                      ? colors.controlHover
                      : colors.control,
                  borderRadius: radius,
                  border: activeBorder
                      ? _border(
                          color: borderColor,
                          width: focused
                              ? BusyMarkStroke.focus
                              : BusyMarkStroke.hairline,
                        )
                      : null,
                  elevated: !grouped,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositionedDirectional(
                      duration: BusyMarkMotion.floatingEntry,
                      curve: BusyMarkMotion.floatingEntryCurve,
                      start: BusyMarkSizes.floatingEntryInset,
                      end: BusyMarkSizes.iconButton,
                      top: floating
                          ? BusyMarkSizes.floatingEntryLabelTop
                          : BusyMarkSizes.floatingEntryLabelRestTop,
                      height: floating
                          ? BusyMarkSizes.floatingEntryLabelHeight
                          : BusyMarkSizes.floatingEntryLabelRestHeight,
                      child: IgnorePointer(
                        child: AnimatedDefaultTextStyle(
                          duration: BusyMarkMotion.floatingEntry,
                          curve: BusyMarkMotion.floatingEntryCurve,
                          style:
                              (floating
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.bodyMedium)
                                  ?.copyWith(color: labelColor) ??
                              TextStyle(color: labelColor),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: BusyMarkSizes.floatingEntryInset,
                      end: BusyMarkSizes.iconButton,
                      top: BusyMarkSizes.floatingEntryInputTop,
                      bottom: BusyMarkSizes.floatingEntryInputBottom,
                      child: AnimatedOpacity(
                        duration: BusyMarkMotion.floatingEntry,
                        curve: BusyMarkMotion.floatingEntryCurve,
                        opacity: floating ? 1 : 0,
                        child: EditableText(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          autofocus: widget.enabled && widget.autofocus,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          textDirection: widget.textDirection,
                          onSubmitted: widget.enabled
                              ? widget.onSubmitted
                              : null,
                          readOnly: !widget.enabled,
                          showCursor: widget.enabled,
                          enableInteractiveSelection: widget.enabled,
                          minLines: widget.minLines,
                          maxLines: widget.maxLines,
                          forceLine: true,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                                color: foreground,
                              ) ??
                              TextStyle(color: foreground),
                          cursorColor: colorScheme.primary,
                          backgroundCursorColor: colors.controlActive,
                          selectionColor: colorScheme.primary.withValues(
                            alpha: BusyMarkAlpha.floatingTextSelection,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: BusyMarkSpacing.md,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: BusyMarkMotion.floatingEntry,
                          curve: BusyMarkMotion.floatingEntryCurve,
                          opacity: focused || !widget.enabled ? 0 : 1,
                          child: Center(
                            child: Icon(
                              BusyMarkGlyphs.edit,
                              size: BusyMarkSizes.iconSm,
                              color: colors.mutedForeground.withValues(
                                alpha: BusyMarkAlpha.floatingEntryIcon,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                BusyMarkSpacing.md,
                BusyMarkSpacing.xs,
                BusyMarkSpacing.md,
                BusyMarkSpacing.sm,
              ),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  BorderRadius _borderRadius() {
    const radius = Radius.circular(BusyMarkRadius.headerButton);
    return switch (widget.groupPosition) {
      BusyMarkFloatingTextEntryPosition.single => const BorderRadius.all(
        radius,
      ),
      BusyMarkFloatingTextEntryPosition.first => const BorderRadius.vertical(
        top: radius,
      ),
      BusyMarkFloatingTextEntryPosition.middle => BorderRadius.zero,
      BusyMarkFloatingTextEntryPosition.last => const BorderRadius.vertical(
        bottom: radius,
      ),
    };
  }

  Border _border({required Color color, required double width}) {
    final side = BorderSide(color: color, width: width);
    return switch (widget.groupPosition) {
      BusyMarkFloatingTextEntryPosition.single => Border.all(
        color: color,
        width: width,
      ),
      BusyMarkFloatingTextEntryPosition.first => Border(
        top: side,
        right: side,
        bottom: side,
        left: side,
      ),
      BusyMarkFloatingTextEntryPosition.middle => Border(
        top: side,
        right: side,
        bottom: side,
        left: side,
      ),
      BusyMarkFloatingTextEntryPosition.last => Border(
        top: side,
        right: side,
        bottom: side,
        left: side,
      ),
    };
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BusyMarkInsets.sectionLabel,
      child: Text(text, style: busyMarkSectionHeaderStyle(context)),
    );
  }
}
