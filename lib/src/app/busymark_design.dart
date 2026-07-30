import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  static const double lg = kYaruContainerRadius;
  static const double headerButton = kYaruButtonRadius;
  // Compatibility name for sidebar callers; geometry remains Yaru-owned.
  static const double nativeHeaderButton = kYaruButtonRadius;
  static const double window = kYaruWindowRadius;
  static const double pill = 999;
  static const double selection = 3;
}

abstract final class BusyMarkSizes {
  static const double contentWidth = 760;
  static const double documentContentWidth = contentWidth;
  static const double sidebarWidth = 300;
  static const double settingsWidth = 760;
  static const double toolbarHeight = kYaruTitleBarHeight;
  static const double paneHeaderHeight = 38;
  static const double iconButton = kYaruTitleBarItemHeight;
  static const double compactIconButton = 24;
  static const double compactIcon = 13;
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
  static const double languagePopupMinWidth = 220;
  static const double languagePopupMaxWidth = 280;
  static const double languageButtonMaxWidth = 256;
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
  static const double tableDialogWidth = 360;
  static const double tableColumnBaseWidth = 164;
  static const double tableMinWidth = 360;
  static const double tableMaxWidth = 980;
  static const double tableControl = 34;
  static const double markerDot = 6;
  static const double listMarkerTopInset = 7;
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
}

abstract final class BusyMarkStroke {
  static const double hairline = 1;
  static const double focus = kYaruFocusBorderWidth;
  static const double sourceCursor = 1.4;
  static const double thematicBreak = 1.6;
  static const double selectionInflate = 1.5;
}

abstract final class BusyMarkAlpha {
  static const double groupedRowLightHoverStrength = 0.50;
  static const double textSelection = 0.32;
  static const double sourceCollapsedLine = 0.045;
  static const double sourceCursor = 0.82;
  static const double sourceSyntaxBackground = 0.10;
  static const double syntaxCommentDark = 0.82;
  static const double syntaxCommentLight = 0.76;
  static const double previewHighlight = 0.24;
  static const double thematicBreak = 0.34;
  static const double thematicBreakHandle = 0.24;
  static const double thematicBreakSelected = 0.72;
}

/// Native libadwaita/Yaru shadow layers shared by grouped card surfaces.
abstract final class BusyMarkShadow {
  static List<BoxShadow> nativeCardShadows(Color semanticShadow) {
    Color layer(double opacity) {
      return semanticShadow.withValues(alpha: semanticShadow.a * opacity);
    }

    // ShapeDecoration paints later shadows over earlier ones. Keep the
    // perimeter last so the compact native edge remains above the broad layer.
    return [
      BoxShadow(
        color: layer(0.03),
        blurRadius: 6,
        spreadRadius: 2,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: layer(0.07),
        blurRadius: 3,
        spreadRadius: 1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(color: layer(0.03), spreadRadius: 1),
    ];
  }

  static List<BoxShadow> nativeCardShadowsFor(BuildContext context) {
    final theme = Theme.of(context);
    return nativeCardShadows(
      CardTheme.of(context).shadowColor ?? theme.colorScheme.shadow,
    );
  }
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
  static const Duration dialogInsets = Duration(milliseconds: 160);
  static const Duration sidebarExpand = Duration(milliseconds: 120);
  static const Duration scroll = Duration(milliseconds: 180);
  static const Duration previewSearchDelay = Duration(milliseconds: 80);
  static const Duration tooltipWait = Duration(milliseconds: 450);
  static const Curve dialogInsetsCurve = Curves.easeOutCubic;
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
  static const documentCodeBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.sm,
  );
  static const documentCodeContent = EdgeInsets.all(BusyMarkSpacing.mdPlus);
  static const documentCalloutBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.sm,
  );
  static const documentCalloutContent = EdgeInsets.all(BusyMarkSpacing.md);
  static const previewTableCell = EdgeInsets.symmetric(
    horizontal: BusyMarkSpacing.sm,
    vertical: BusyMarkSpacing.xs,
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
  static const wysiwygContainerBlock = documentCalloutBlock;
  static const wysiwygTableBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.smPlus,
  );
  static const wysiwygThematicBreakBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.md,
  );
  static const wysiwygDefaultBlock = EdgeInsets.symmetric(
    vertical: BusyMarkSpacing.xs,
  );
  static const wysiwygContainerContent = documentCalloutContent;
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
  return Theme.of(context).colorScheme.error;
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

BusyMarkSurfaceColors _busyMarkSemanticSurfaceColors(Brightness brightness) {
  final window = switch (brightness) {
    Brightness.light => const Color(0xFFFAFAFA),
    Brightness.dark => const Color(0xFF2C2C2C),
  };
  final view = switch (brightness) {
    Brightness.light => const Color(0xFFFFFFFF),
    Brightness.dark => const Color(0xFF272727),
  };
  final floatingSurface = switch (brightness) {
    // Installed Yaru/libadwaita owns this neutral role independently from the
    // window and content-view elevation ladder.
    Brightness.light => const Color(0xFFFAFAFA),
    Brightness.dark => const Color(0xFF3E3E3E),
  };
  final foreground = switch (brightness) {
    Brightness.light => const Color(0xFF3D3D3D),
    Brightness.dark => const Color(0xFFF7F7F7),
  };
  // These colors are used by non-disabled 10–14 px labels. Keep them opaque so
  // their contrast is stable across every neutral surface instead of stacking
  // a dim-label alpha on whichever view happens to be underneath.
  final mutedForeground = switch (brightness) {
    Brightness.light => const Color(0xFF666666),
    Brightness.dark => const Color(0xFFB5B5B5),
  };
  final card = switch (brightness) {
    Brightness.light => const Color(0xFFFFFFFF),
    Brightness.dark => const Color(0xFF3D3D3D),
  };
  final groupedSurface = switch (brightness) {
    Brightness.light => const Color(0xFFFFFFFF),
    Brightness.dark => const Color.fromRGBO(255, 255, 255, 0.08),
  };
  // Yaru renders the split-view boundary as a recessed divider in both
  // brightness modes. A foreground tint in dark mode produces a light seam.
  final sidebarBorder = switch (brightness) {
    Brightness.light => const Color.fromRGBO(24, 24, 24, 0.08),
    Brightness.dark => const Color.fromRGBO(16, 16, 16, 0.35),
  };

  Color tintedSurface(Color tint) {
    final alpha = brightness == Brightness.dark ? 0.16 : 0.08;
    return Color.alphaBlend(tint.withValues(alpha: alpha), card);
  }

  return switch (brightness) {
    Brightness.light => BusyMarkSurfaceColors(
      // Modern Yaru/libadwaita semantic roles. Flutter's Yaru theme exposes
      // geometry and interaction behavior, but not every contemporary
      // surface role, so these neutral fallbacks live in one resolver.
      window: window,
      view: view,
      sidebar: const Color(0xFFEBEBEB),
      secondarySidebar: const Color(0xFFF0F0F0),
      headerbar: const Color(0xFFFAFAFA),
      headerbarFlat: const Color(0xFFFFFFFF),
      panel: const Color(0xFFF0F0F0),
      card: card,
      groupedSurface: groupedSurface,
      dialog: floatingSurface,
      popover: floatingSurface,
      control: const Color.fromRGBO(0, 0, 0, 0.10),
      controlHover: const Color.fromRGBO(0, 0, 0, 0.14),
      controlActive: const Color.fromRGBO(0, 0, 0, 0.18),
      foreground: foreground,
      mutedForeground: mutedForeground,
      disabledForeground: foreground.withValues(alpha: 0.38),
      disabledControl: const Color.fromRGBO(0, 0, 0, 0.04),
      border: const Color.fromRGBO(0, 0, 0, 0.18),
      subtleBorder: const Color.fromRGBO(0, 0, 0, 0.10),
      divider: const Color.fromRGBO(0, 0, 0, 0.10),
      cardShade: const Color.fromRGBO(24, 24, 24, 0.08),
      // Dialogs use libadwaita's restrained inside highlight. This is
      // intentionally distinct from the darker popover perimeter.
      dialogOutline: const Color.fromRGBO(255, 255, 255, 0.07),
      floatingBorder: const Color.fromRGBO(0, 0, 0, 0.14),
      sidebarBorder: sidebarBorder,
      shade: const Color.fromRGBO(0, 0, 0, 0.07),
      muted: mutedForeground,
      admonitionNote: tintedSurface(BusyMarkLinuxPalette.ubuntuBlueAccent),
      admonitionTip: tintedSurface(BusyMarkLinuxPalette.ubuntuGreenAccent),
      admonitionWarning: tintedSurface(BusyMarkLinuxPalette.ubuntuYellowAccent),
    ),
    Brightness.dark => BusyMarkSurfaceColors(
      window: window,
      view: view,
      sidebar: const Color(0xFF393939),
      secondarySidebar: const Color(0xFF323232),
      headerbar: const Color(0xFF393939),
      headerbarFlat: const Color(0xFF272727),
      panel: const Color(0xFF323232),
      card: card,
      groupedSurface: groupedSurface,
      dialog: floatingSurface,
      popover: floatingSurface,
      control: const Color.fromRGBO(255, 255, 255, 0.10),
      controlHover: const Color.fromRGBO(255, 255, 255, 0.14),
      controlActive: const Color.fromRGBO(255, 255, 255, 0.18),
      foreground: foreground,
      mutedForeground: mutedForeground,
      disabledForeground: foreground.withValues(alpha: 0.38),
      disabledControl: const Color.fromRGBO(255, 255, 255, 0.06),
      border: const Color.fromRGBO(0, 0, 0, 0.75),
      subtleBorder: const Color.fromRGBO(255, 255, 255, 0.10),
      divider: const Color.fromRGBO(255, 255, 255, 0.10),
      cardShade: const Color.fromRGBO(0, 0, 0, 0.36),
      dialogOutline: const Color.fromRGBO(255, 255, 255, 0.07),
      floatingBorder: const Color.fromRGBO(0, 0, 0, 0.14),
      sidebarBorder: sidebarBorder,
      shade: const Color.fromRGBO(0, 0, 0, 0.25),
      muted: mutedForeground,
      admonitionNote: tintedSurface(BusyMarkLinuxPalette.ubuntuBlueAccent),
      admonitionTip: tintedSurface(BusyMarkLinuxPalette.ubuntuGreenAccent),
      admonitionWarning: tintedSurface(BusyMarkLinuxPalette.ubuntuYellowAccent),
    ),
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
    required this.groupedSurface,
    required this.dialog,
    required this.popover,
    required this.control,
    required this.controlHover,
    required this.controlActive,
    required this.foreground,
    required this.mutedForeground,
    required this.disabledForeground,
    required this.disabledControl,
    required this.border,
    required this.subtleBorder,
    required this.divider,
    required this.cardShade,
    required this.dialogOutline,
    required this.floatingBorder,
    required this.sidebarBorder,
    required this.shade,
    required this.muted,
    required this.admonitionNote,
    required this.admonitionTip,
    required this.admonitionWarning,
  });

  factory BusyMarkSurfaceColors.fromTheme(ThemeData theme) {
    return _busyMarkSemanticSurfaceColors(theme.brightness);
  }

  static BusyMarkSurfaceColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BusyMarkSurfaceColors>() ??
        BusyMarkSurfaceColors.fromTheme(theme);
  }

  final Color window;
  final Color view;
  final Color sidebar;
  final Color secondarySidebar;
  final Color headerbar;
  final Color headerbarFlat;
  final Color panel;
  final Color card;
  final Color groupedSurface;
  final Color dialog;
  final Color popover;
  final Color control;
  final Color controlHover;
  final Color controlActive;
  final Color foreground;
  final Color mutedForeground;
  final Color disabledForeground;
  final Color disabledControl;
  final Color border;
  final Color subtleBorder;
  final Color divider;
  final Color cardShade;
  final Color dialogOutline;
  final Color floatingBorder;
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
    Color? groupedSurface,
    Color? dialog,
    Color? popover,
    Color? control,
    Color? controlHover,
    Color? controlActive,
    Color? foreground,
    Color? mutedForeground,
    Color? disabledForeground,
    Color? disabledControl,
    Color? border,
    Color? subtleBorder,
    Color? divider,
    Color? cardShade,
    Color? dialogOutline,
    Color? floatingBorder,
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
      groupedSurface: groupedSurface ?? this.groupedSurface,
      dialog: dialog ?? this.dialog,
      popover: popover ?? this.popover,
      control: control ?? this.control,
      controlHover: controlHover ?? this.controlHover,
      controlActive: controlActive ?? this.controlActive,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledControl: disabledControl ?? this.disabledControl,
      border: border ?? this.border,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      divider: divider ?? this.divider,
      cardShade: cardShade ?? this.cardShade,
      dialogOutline: dialogOutline ?? this.dialogOutline,
      floatingBorder: floatingBorder ?? this.floatingBorder,
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
      groupedSurface: Color.lerp(groupedSurface, other.groupedSurface, t)!,
      dialog: Color.lerp(dialog, other.dialog, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      control: Color.lerp(control, other.control, t)!,
      controlHover: Color.lerp(controlHover, other.controlHover, t)!,
      controlActive: Color.lerp(controlActive, other.controlActive, t)!,
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
      divider: Color.lerp(divider, other.divider, t)!,
      cardShade: Color.lerp(cardShade, other.cardShade, t)!,
      dialogOutline: Color.lerp(dialogOutline, other.dialogOutline, t)!,
      floatingBorder: Color.lerp(floatingBorder, other.floatingBorder, t)!,
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
  Color? disabledForegroundColor,
  WidgetStateProperty<Color?>? backgroundColor,
  WidgetStateProperty<Color?>? overlayColor,
  double borderRadius = BusyMarkRadius.headerButton,
}) {
  return ButtonStyle(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: foregroundColor == null
        ? null
        : WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled) &&
                disabledForegroundColor != null) {
              return disabledForegroundColor;
            }
            return foregroundColor;
          }),
    backgroundColor: backgroundColor,
    overlayColor: overlayColor,
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
    ),
  );
}

WidgetStateProperty<Color?> busyMarkHeaderButtonBackground(
  BuildContext context,
) {
  return Theme.of(context).filledButtonTheme.style?.backgroundColor ??
      WidgetStatePropertyAll(BusyMarkSurfaceColors.of(context).control);
}

/// Resolves a contained control state against its semantic host surface.
///
/// Yaru control fills are translucent state layers, which is appropriate when
/// a parent control surface owns the background. Free-floating controls, such
/// as the editing toolbar over a document, have no such parent and must resolve
/// that layer once so document content cannot show through the button.
WidgetStateProperty<Color?> busyMarkContainedControlBackground(
  BuildContext context, {
  required Color surface,
}) {
  final background = busyMarkHeaderButtonBackground(context);
  return WidgetStateProperty.resolveWith((states) {
    final stateColor = background.resolve(states);
    return stateColor == null ? null : Color.alphaBlend(stateColor, surface);
  });
}

WidgetStateProperty<Color?> busyMarkTransparentHeaderButtonBackground(
  BuildContext _,
) {
  return const WidgetStatePropertyAll(BusyMarkLinuxPalette.transparent);
}

Color busyMarkSelectedBackground(BuildContext context) {
  return BusyMarkSurfaceColors.of(context).controlActive;
}

Color busyMarkRowHoverColor(BuildContext context) {
  final theme = Theme.of(context);
  final hover = theme.hoverColor;
  if (theme.colorScheme.isHighContrast ||
      theme.colorScheme.brightness == Brightness.dark) {
    return hover;
  }
  return hover.withValues(
    alpha: hover.a * BusyMarkAlpha.groupedRowLightHoverStrength,
  );
}

TextStyle? busyMarkSectionHeaderStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.titleSmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

Widget _busyMarkGroupedRowSubtitle(
  BuildContext context,
  Widget child, {
  bool enabled = true,
}) {
  final colors = BusyMarkSurfaceColors.of(context);
  return DefaultTextStyle.merge(
    style: TextStyle(
      color: enabled ? colors.mutedForeground : colors.disabledForeground,
    ),
    child: child,
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
    this.transparent = true,
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

  /// Uses the theme's physical button elevation without drawing a custom
  /// shadow surface around the control.
  final bool elevated;
  final String? shortcut;
  final Color? foregroundColor;
  final WidgetStateProperty<Color?>? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    final semanticStyle = busyMarkHeaderIconButtonStyle(
      foregroundColor:
          foregroundColor ?? (accented ? colorScheme.onPrimary : null),
      disabledForegroundColor: colors.disabledForeground,
      backgroundColor:
          backgroundColor ??
          (accented
              ? WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return colors.disabledControl;
                  }
                  return colorScheme.primary;
                })
              : elevated || !transparent
              ? busyMarkHeaderButtonBackground(context)
              : null),
      borderRadius: borderRadius,
    );
    final style = elevated
        ? semanticStyle.copyWith(
            elevation: WidgetStatePropertyAll(
              theme.cardTheme.elevation ?? BusyMarkElevation.surface,
            ),
            shadowColor: WidgetStatePropertyAll(colorScheme.shadow),
            surfaceTintColor: const WidgetStatePropertyAll(
              BusyMarkLinuxPalette.transparent,
            ),
          )
        : semanticStyle;
    // YaruIconButton merges its defaults as the receiver, so non-null default
    // colors win over caller-supplied semantic colors. Compose the styles in
    // the opposite direction and give the result directly to IconButton.
    final yaruDefaults = YaruIconButton(
      icon: const SizedBox.shrink(),
      iconSize: BusyMarkSizes.iconButton,
    ).defaultStyleOf(context);
    final button = IconButton(
      isSelected: selected,
      tooltip: shortcut == null ? tooltip : '$tooltip ($shortcut)',
      icon: Icon(icon, size: BusyMarkSizes.iconSm),
      padding: EdgeInsets.zero,
      style: style.merge(yaruDefaults),
      onPressed: onPressed,
    );
    return YaruTheme.maybeOf(context)?.focusBorders == true
        ? YaruFocusBorder.primary(
            borderRadius: BorderRadius.circular(BusyMarkRadius.pill),
            child: button,
          )
        : button;
  }
}

/// A compact icon action that keeps Yaru's interaction and focus behavior.
///
/// Compact controls are appropriate inside dense editor affordances, where a
/// full title-bar item would consume too much document space.
class BusyMarkCompactIconButton extends StatelessWidget {
  const BusyMarkCompactIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = BusyMarkSizes.compactIconButton,
    this.glyphSize = BusyMarkSizes.compactIcon,
    this.foregroundColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double glyphSize;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return YaruIconButton(
      iconSize: size,
      tooltip: tooltip,
      style: foregroundColor == null
          ? null
          : ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return colors.disabledForeground;
                }
                return foregroundColor;
              }),
            ),
      icon: Icon(icon, size: glyphSize),
      onPressed: onPressed,
    );
  }
}

class BusyMarkHeaderPopupMenuButton<T> extends StatefulWidget {
  const BusyMarkHeaderPopupMenuButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.itemBuilder,
    required this.onSelected,
    this.transparent = true,
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

  /// Uses the theme's physical button elevation.
  final bool elevated;
  final String? shortcut;
  final Color? foregroundColor;
  final WidgetStateProperty<Color?>? backgroundColor;
  final double borderRadius;

  @override
  State<BusyMarkHeaderPopupMenuButton<T>> createState() =>
      _BusyMarkHeaderPopupMenuButtonState<T>();
}

class _BusyMarkHeaderPopupMenuButtonState<T>
    extends State<BusyMarkHeaderPopupMenuButton<T>> {
  final _menuKey = GlobalKey<PopupMenuButtonState<T>>();
  List<PopupMenuEntry<T>> _items = const [];
  var _loading = false;
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // PopupMenuButton owns route placement, RTL growth, focus, Escape, and
        // menu semantics. The visible Yaru button only performs the async load
        // before asking that framework control to open.
        ExcludeSemantics(
          child: PopupMenuButton<T>(
            key: _menuKey,
            enabled: false,
            tooltip: '',
            useRootNavigator: true,
            position: PopupMenuPosition.under,
            requestFocus: true,
            itemBuilder: (_) => _items,
            onOpened: () => _setOpen(true),
            onCanceled: () => _setOpen(false),
            onSelected: (selection) {
              _setOpen(false);
              widget.onSelected(selection);
            },
            child: const SizedBox.square(dimension: BusyMarkSizes.iconButton),
          ),
        ),
        BusyMarkHeaderIconButton(
          tooltip: widget.tooltip,
          icon: widget.icon,
          shortcut: widget.shortcut,
          selected: _loading || _open,
          transparent: widget.transparent,
          elevated: widget.elevated,
          foregroundColor: widget.foregroundColor,
          backgroundColor: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          onPressed: _loadAndShowMenu,
        ),
      ],
    );
  }

  Future<void> _loadAndShowMenu() async {
    if (_loading || _open) {
      return;
    }
    setState(() => _loading = true);
    try {
      final items = await widget.itemBuilder(context);
      if (!mounted || items.isEmpty) {
        return;
      }
      _items = List.unmodifiable(items);
      _menuKey.currentState?.showButtonMenu();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setOpen(bool value) {
    if (mounted && _open != value) {
      setState(() => _open = value);
    }
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
    constraints: BoxConstraints.tightFor(width: width),
    requestFocus: true,
  );
}

class BusyMarkPopupMenuItem<T> extends PopupMenuItem<T> {
  BusyMarkPopupMenuItem({
    super.key,
    required T value,
    required String label,
    IconData? icon,
    String? shortcut,
    super.enabled = true,
    bool checked = false,
    bool trailingCheck = false,
  }) : label = label,
       icon = icon,
       shortcut = shortcut,
       checked = checked,
       trailingCheck = trailingCheck,
       super(
         value: value,
         child: _BusyMarkPopupMenuItemContent(
           label: label,
           icon: icon,
           shortcut: shortcut,
           checked: checked,
           trailingCheck: trailingCheck,
         ),
       );

  final String label;
  final IconData? icon;
  final String? shortcut;
  final bool checked;
  final bool trailingCheck;
}

class _BusyMarkPopupMenuItemContent extends StatelessWidget {
  const _BusyMarkPopupMenuItemContent({
    required this.label,
    required this.icon,
    required this.shortcut,
    required this.checked,
    required this.trailingCheck,
  });

  final String label;
  final IconData? icon;
  final String? shortcut;
  final bool checked;
  final bool trailingCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final shortcutText = shortcut == null || shortcut!.isEmpty
        ? null
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              shortcut!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          );
    return Semantics(
      checked: trailingCheck ? checked : null,
      inMutuallyExclusiveGroup: trailingCheck,
      child: IconTheme.merge(
        data: const IconThemeData(size: BusyMarkSizes.iconSm),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: BusyMarkSpacing.sm),
            ],
            Expanded(child: labelText),
            if (shortcutText != null) ...[
              const SizedBox(width: BusyMarkSpacing.sm),
              shortcutText,
            ],
            if (trailingCheck) ...[
              const SizedBox(width: BusyMarkSpacing.sm),
              Visibility.maintain(
                visible: checked,
                child: const Icon(BusyMarkGlyphs.check),
              ),
            ],
          ],
        ),
      ),
    );
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
    final selectorEnabled = enabled && options.isNotEmpty;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: buttonMaxWidth),
        child: YaruPopupMenuButton<T>(
          initialValue: value,
          enabled: selectorEnabled,
          tooltip: tooltip,
          semanticLabel: tooltip,
          // Preserve Yaru's selector geometry and interaction states, while
          // matching libadwaita's inline grouped-row value affordance.
          style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
            side: const WidgetStatePropertyAll(BorderSide.none),
          ),
          constraints: BoxConstraints(
            minWidth: popupMinWidth,
            maxWidth: popupMaxWidth,
          ),
          onSelected: onSelected,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(
                0,
                buttonMaxWidth -
                    BusyMarkSizes.iconButton -
                    BusyMarkSpacing.smPlus,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
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

/// Semantic parent surfaces that can contain a grouped card.
enum BusyMarkSurfaceRole { window, view, sidebar, dialog, popover }

class BusyMarkSurfaceScope extends InheritedWidget {
  const BusyMarkSurfaceScope({
    super.key,
    required this.role,
    required super.child,
  });

  final BusyMarkSurfaceRole role;

  static BusyMarkSurfaceRole roleOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<BusyMarkSurfaceScope>()
            ?.role ??
        BusyMarkSurfaceRole.window;
  }

  @override
  bool updateShouldNotify(BusyMarkSurfaceScope oldWidget) {
    return role != oldWidget.role;
  }
}

Color busyMarkGroupedSurfaceColor(
  BuildContext context, {
  BusyMarkSurfaceRole? parentRole,
}) {
  final colors = BusyMarkSurfaceColors.of(context);
  final role = parentRole ?? BusyMarkSurfaceScope.roleOf(context);
  if (role == BusyMarkSurfaceRole.window) {
    return colors.card;
  }
  final parent = switch (role) {
    BusyMarkSurfaceRole.window => colors.window,
    BusyMarkSurfaceRole.view => colors.view,
    BusyMarkSurfaceRole.sidebar => colors.sidebar,
    BusyMarkSurfaceRole.dialog => colors.dialog,
    BusyMarkSurfaceRole.popover => colors.popover,
  };
  return Color.alphaBlend(colors.groupedSurface, parent);
}

class BusyMarkSurface extends StatelessWidget {
  const BusyMarkSurface({
    super.key,
    required this.child,
    this.filled = true,
    this.color,
    this.side,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final bool filled;
  final Color? color;
  final BorderSide? side;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final cardTheme = CardTheme.of(context);
    final surfaceColors = BusyMarkSurfaceColors.of(context);
    final fallbackShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
    );
    final themedShape = cardTheme.shape;
    final ShapeBorder shape;
    if (themedShape is OutlinedBorder) {
      shape = side == null ? themedShape : themedShape.copyWith(side: side);
    } else if (themedShape != null && side == null) {
      shape = themedShape;
    } else {
      shape = fallbackShape.copyWith(side: side ?? BorderSide.none);
    }
    final surfaceColor = filled
        ? color ?? cardTheme.color ?? surfaceColors.card
        : Colors.transparent;
    if (filled) {
      final shadowShape = shape is OutlinedBorder
          ? shape.copyWith(side: BorderSide.none)
          : shape;
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: shadowShape,
          shadows: BusyMarkShadow.nativeCardShadowsFor(context),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          semanticContainer: false,
          color: surfaceColor,
          shadowColor: Colors.transparent,
          shape: shape,
          clipBehavior: clipBehavior,
          child: child,
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      elevation: 0,
      surfaceTintColor: cardTheme.surfaceTintColor ?? Colors.transparent,
      shape: shape,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// The single semantic raised surface for grouped rows and cards.
class BusyMarkGroupedSurface extends StatelessWidget {
  const BusyMarkGroupedSurface({
    super.key,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return BusyMarkSurface(
      color: busyMarkGroupedSurfaceColor(context),
      side: highContrast
          ? BorderSide(color: Theme.of(context).colorScheme.outline)
          : null,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// Shared split-view sidebar surface and reading-direction boundary.
class BusyMarkSidebarSurface extends StatelessWidget {
  const BusyMarkSidebarSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: BorderDirectional(
          end: BorderSide(
            color: colors.sidebarBorder,
            width: BusyMarkStroke.hairline,
          ),
        ),
      ),
      child: child,
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
    final list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            Divider(height: 1, thickness: 1, color: colors.cardShade),
        ],
      ],
    );

    if (!filled) {
      return list;
    }

    return BusyMarkGroupedSurface(child: list);
  }
}

typedef BusyMarkRowActivationCallback =
    void Function(BuildContext context, Offset? globalPosition);

class BusyMarkActionRow extends StatefulWidget {
  const BusyMarkActionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.titleWidget,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.onActivated,
    this.enabled = true,
    this.tooltip,
    this.destructive = false,
    this.autofocus = false,
    this.hoverColor,
  }) : assert(onTap == null || onActivated == null);

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final BusyMarkRowActivationCallback? onActivated;
  final bool enabled;
  final String? tooltip;
  final bool destructive;
  final bool autofocus;
  final Color? hoverColor;

  @override
  State<BusyMarkActionRow> createState() => _BusyMarkActionRowState();
}

class _BusyMarkActionRowState extends State<BusyMarkActionRow> {
  int? _primaryPointer;
  Offset? _pointerDownPosition;

  @override
  void didUpdateWidget(covariant BusyMarkActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || widget.onActivated == null) {
      _clearPointer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = BusyMarkSurfaceColors.of(context);
    final titleStyle = widget.destructive
        ? TextStyle(
            color: widget.enabled
                ? colorScheme.error
                : colors.disabledForeground,
          )
        : null;
    final subtitle =
        widget.subtitleWidget ??
        (widget.subtitle == null || widget.subtitle!.isEmpty
            ? null
            : Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ));
    final interactive =
        widget.enabled && (widget.onTap != null || widget.onActivated != null);
    final row = YaruListTile.square(
      leading: widget.leading,
      title:
          widget.titleWidget ??
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
      subtitle: subtitle == null
          ? null
          : _busyMarkGroupedRowSubtitle(
              context,
              subtitle,
              enabled: widget.enabled,
            ),
      trailing: widget.trailing,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      hoverColor: widget.hoverColor ?? busyMarkRowHoverColor(context),
      onTap: interactive ? _activate : null,
    );

    final trackedRow = widget.onActivated == null
        ? row
        : Listener(
            onPointerDown: widget.enabled ? _handlePointerDown : null,
            onPointerUp: widget.enabled ? _handlePointerUp : null,
            onPointerCancel: widget.enabled ? _handlePointerCancel : null,
            child: row,
          );

    if (widget.enabled || widget.tooltip == null) {
      return trackedRow;
    }

    return Tooltip(
      message: widget.tooltip!,
      child: Opacity(opacity: 0.6, child: IgnorePointer(child: trackedRow)),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) {
      return;
    }
    _primaryPointer = event.pointer;
    _pointerDownPosition = event.position;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_primaryPointer != event.pointer) {
      return;
    }
    final pointer = event.pointer;
    scheduleMicrotask(() {
      if (mounted && _primaryPointer == pointer) {
        _clearPointer();
      }
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_primaryPointer == event.pointer) {
      _clearPointer();
    }
  }

  void _activate() {
    final onActivated = widget.onActivated;
    if (onActivated == null) {
      widget.onTap?.call();
      return;
    }
    final globalPosition = _pointerDownPosition;
    _clearPointer();
    onActivated(context, globalPosition);
  }

  void _clearPointer() {
    _primaryPointer = null;
    _pointerDownPosition = null;
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
    return YaruSwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      secondary: leading,
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : _busyMarkGroupedRowSubtitle(
              context,
              Text(subtitle!),
              enabled: enabled,
            ),
      shape: const RoundedRectangleBorder(),
      hoverColor: busyMarkRowHoverColor(context),
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

Color busyMarkStatusColor(BuildContext context, BusyMarkStatusKind kind) {
  final colors = YaruColors.of(context);
  return switch (kind) {
    BusyMarkStatusKind.information => colors.link,
    BusyMarkStatusKind.success => colors.success,
    BusyMarkStatusKind.warning => colors.warning,
    BusyMarkStatusKind.error => colors.error,
  };
}

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

Color busyMarkDialogSurfaceColor(BuildContext context) {
  return DialogTheme.of(context).backgroundColor ??
      BusyMarkSurfaceColors.of(context).dialog;
}

class BusyMarkDialogTitleBar extends StatelessWidget {
  const BusyMarkDialogTitleBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.closeSemanticLabel,
    this.closable = true,
    this.showDividerInHighContrast = true,
  });

  final Widget? title;
  final bool centerTitle;
  final String? closeSemanticLabel;
  final bool closable;
  final bool showDividerInHighContrast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final dialogSurface = busyMarkDialogSurfaceColor(context);
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: dialogSurface,
          surfaceTintColor: dialogSurface,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      child: YaruDialogTitleBar(
        title: title,
        centerTitle: centerTitle,
        isClosable: closable,
        isActive: true,
        backgroundColor: dialogSurface,
        border: showDividerInHighContrast && theme.colorScheme.isHighContrast
            ? BorderSide(color: colors.divider)
            : BorderSide.none,
        closeSemanticLabel: closeSemanticLabel,
        heroTag: null,
      ),
    );
  }
}

class BusyMarkDialogShell extends StatelessWidget {
  const BusyMarkDialogShell({
    super.key,
    required this.title,
    required this.children,
    this.maxWidth = BusyMarkSizes.dialog,
    this.header,
    this.actions = const [],
    this.closable = true,
  });

  final String title;
  final List<Widget> children;
  final double maxWidth;
  final Widget? header;
  final List<Widget> actions;
  final bool closable;

  @override
  Widget build(BuildContext context) {
    final dialogSurface = busyMarkDialogSurfaceColor(context);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: BusyMarkSurfaceScope(
        role: BusyMarkSurfaceRole.dialog,
        child: Dialog(
          backgroundColor: dialogSurface,
          surfaceTintColor: dialogSurface,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header ??
                    BusyMarkDialogTitleBar(
                      title: Text(title),
                      closable: closable,
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
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: BusyMarkSpacing.sm,
                      overflowSpacing: BusyMarkSpacing.sm,
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Semantic desktop push-button roles backed by real Yaru-themed controls.
abstract final class BusyMarkPushButton {
  static FilledButton standard({
    required Widget child,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    WidgetStatesController? statesController,
    Key? key,
  }) {
    return FilledButton(
      key: key,
      onPressed: onPressed,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      child: child,
    );
  }

  static FilledButton standardIcon({
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    WidgetStatesController? statesController,
    Key? key,
  }) {
    return FilledButton.icon(
      key: key,
      onPressed: onPressed,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      icon: icon,
      label: label,
    );
  }

  static ElevatedButton suggested({
    required Widget child,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    WidgetStatesController? statesController,
    Key? key,
  }) {
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      child: child,
    );
  }

  static ElevatedButton destructive({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onPressed,
    ButtonStyle? style,
    FocusNode? focusNode,
    bool autofocus = false,
    WidgetStatesController? statesController,
    Key? key,
  }) {
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: _destructiveButtonStyle(context).merge(style),
      focusNode: focusNode,
      autofocus: autofocus,
      statesController: statesController,
      child: child,
    );
  }
}

class BusyMarkDialogButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final child = _BusyMarkDialogButtonContent(label: label, icon: icon);
    if (destructive) {
      return BusyMarkPushButton.destructive(
        context: context,
        onPressed: onPressed,
        child: child,
      );
    }
    if (suggested) {
      return BusyMarkPushButton.suggested(onPressed: onPressed, child: child);
    }
    return BusyMarkPushButton.standard(onPressed: onPressed, child: child);
  }
}

ButtonStyle _destructiveButtonStyle(BuildContext context) {
  final theme = Theme.of(context);
  final colors = BusyMarkSurfaceColors.of(context);
  Color? background(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? colors.disabledControl
      : theme.colorScheme.error;
  Color? foreground(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? colors.disabledForeground
      : theme.colorScheme.onError;
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith(background),
    foregroundColor: WidgetStateProperty.resolveWith(foreground),
    iconColor: WidgetStateProperty.resolveWith(foreground),
  );
}

class _BusyMarkDialogButtonContent extends StatelessWidget {
  const _BusyMarkDialogButtonContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final icon = this.icon;
    if (icon == null) {
      return Center(widthFactor: 1, child: text);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: BusyMarkSizes.iconSm),
        const SizedBox(width: BusyMarkSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

class BusyMarkFloatingTextEntryGroup extends StatelessWidget {
  const BusyMarkFloatingTextEntryGroup({super.key, required this.children})
    : assert(children.length > 1);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: BusyMarkSpacing.sm),
            children[index],
          ],
        ],
      ),
    );
  }
}

class BusyMarkFloatingTextEntry extends StatelessWidget {
  const BusyMarkFloatingTextEntry({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
    this.textDirection,
    this.textStyle,
    this.onSubmitted,
  }) : assert(minLines > 0),
       assert(maxLines >= minLines);

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;
  final TextStyle? textStyle;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textDirection: textDirection,
      style: textStyle,
      onFieldSubmitted: enabled ? onSubmitted : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
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
