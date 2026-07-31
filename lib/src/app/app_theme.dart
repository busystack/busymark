import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/theme.dart';

import 'busymark_design.dart';

ThemeData buildBusyMarkTheme({
  required Brightness brightness,
  required Color accentColor,
}) {
  final base = switch (brightness) {
    Brightness.light => createYaruLightTheme(primaryColor: accentColor),
    Brightness.dark => createYaruDarkTheme(primaryColor: accentColor),
  };
  final colors = BusyMarkSurfaceColors.fromTheme(base);
  final syntaxColors = BusyMarkSyntaxColors.fromSurfaceColors(
    brightness,
    colors,
  );
  // Match Yaru/GTK suggested-action buttons. The native toolkit classifies
  // mid-tone Ubuntu accents such as magenta as dark and uses white content;
  // choosing whichever of black or white has a fractionally higher WCAG ratio
  // makes those buttons look unlike their native counterparts.
  final onAccent = contrastColor(accentColor);
  final colorScheme = base.colorScheme.copyWith(
    brightness: brightness,
    primary: accentColor,
    onPrimary: onAccent,
    secondary: accentColor,
    onError: _accessibleForeground(base.colorScheme.error),
    surface: colors.view,
    onSurface: colors.foreground,
    onSurfaceVariant: colors.mutedForeground,
    // Keep Material fallbacks on the same opaque, neutral elevation ladder as
    // BusyMark's native Linux surfaces. Control fills remain translucent state
    // layers and must not leak into generic surface-container backgrounds.
    surfaceContainerLowest: colors.view,
    surfaceContainerLow: colors.window,
    surfaceContainer: colors.panel,
    surfaceContainerHigh: colors.secondarySidebar,
    surfaceContainerHighest: colors.sidebar,
    outline: colors.border,
    outlineVariant: colors.divider,
    scrim: BusyMarkLinuxPalette.black,
  );
  final textTheme = _busyMarkTextTheme(base.textTheme, colors);
  final inputDecorationTheme = base.inputDecorationTheme;
  final outlinedButtonStyle = _semanticButtonStyle(
    base.outlinedButtonTheme.style,
    foreground: colors.foreground,
    background: BusyMarkLinuxPalette.transparent,
    disabledForeground: colors.disabledForeground,
    disabledBackground: BusyMarkLinuxPalette.transparent,
  );
  final filledButtonStyle = _semanticButtonStyle(
    base.filledButtonTheme.style,
    foreground: colors.foreground,
    background: colors.control,
    selectedBackground: colors.controlActive,
    disabledForeground: colors.disabledForeground,
    disabledBackground: colors.disabledControl,
  );
  final elevatedButtonStyle = _semanticButtonStyle(
    base.elevatedButtonTheme.style,
    foreground: onAccent,
    background: accentColor,
    disabledForeground: colors.disabledForeground,
    disabledBackground: colors.disabledControl,
  );
  final textButtonStyle = _semanticButtonStyle(
    base.textButtonTheme.style,
    foreground: accentColor,
    background: BusyMarkLinuxPalette.transparent,
    disabledForeground: colors.disabledForeground,
    disabledBackground: BusyMarkLinuxPalette.transparent,
  );
  final yaruButtonGeometry = base.filledButtonTheme.style;
  final toggleConstraints = base.toggleButtonsTheme.constraints;
  final segmentedShape =
      yaruButtonGeometry?.shape ??
      switch (base.toggleButtonsTheme.borderRadius) {
        final BorderRadius borderRadius =>
          WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: borderRadius),
          ),
        _ => null,
      };
  final segmentedMinimumSize =
      yaruButtonGeometry?.minimumSize ??
      (toggleConstraints == null
          ? null
          : WidgetStatePropertyAll(
              Size(toggleConstraints.minWidth, toggleConstraints.minHeight),
            ));
  final segmentedButtonStyle =
      (base.segmentedButtonTheme.style ?? const ButtonStyle()).copyWith(
        shape: segmentedShape,
        padding: yaruButtonGeometry?.padding,
        minimumSize: segmentedMinimumSize,
        visualDensity: yaruButtonGeometry?.visualDensity,
        tapTargetSize: yaruButtonGeometry?.tapTargetSize,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabledForeground;
          }
          return colors.foreground;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabledControl;
          }
          if (states.contains(WidgetState.selected)) {
            return colors.controlActive;
          }
          return colors.control;
        }),
        side: const WidgetStatePropertyAll(BorderSide.none),
      );
  final popoverSurfaceSide = BorderSide(color: colors.floatingBorder);
  final dialogSurfaceSide = BorderSide(color: colors.dialogOutline);
  final menuStyle = _semanticMenuSurfaceStyle(
    base.menuTheme.style,
    color: colors.popover,
    shadowColor: colorScheme.shadow,
    side: popoverSurfaceSide,
  );
  final dropdownMenuStyle = _semanticMenuSurfaceStyle(
    base.dropdownMenuTheme.menuStyle,
    color: colors.popover,
    shadowColor: colorScheme.shadow,
    side: popoverSurfaceSide,
  );

  return base.copyWith(
    brightness: brightness,
    colorScheme: colorScheme,
    primaryColor: accentColor,
    shadowColor: colorScheme.shadow,
    scaffoldBackgroundColor: colors.window,
    canvasColor: colors.window,
    cardColor: colors.card,
    extensions: [
      for (final extension in base.extensions.values)
        if (extension is! BusyMarkSurfaceColors &&
            extension is! BusyMarkSyntaxColors)
          extension,
      colors,
      syntaxColors,
    ],
    dividerColor: colors.divider,
    appBarTheme: base.appBarTheme.copyWith(
      elevation: BusyMarkElevation.none,
      scrolledUnderElevation: BusyMarkElevation.none,
      backgroundColor: colors.headerbar,
      foregroundColor: colors.foreground,
      surfaceTintColor: colors.headerbar,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: textTheme.titleMedium,
    ),
    textTheme: textTheme,
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: colors.dialog,
      surfaceTintColor: colors.dialog,
      shadowColor: colorScheme.shadow,
      shape: _withOutlineSide(base.dialogTheme.shape, dialogSurfaceSide),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      iconColor: colors.mutedForeground,
      textColor: colors.foreground,
    ),
    inputDecorationTheme: inputDecorationTheme,
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(style: segmentedButtonStyle),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledForeground;
        }
        if (states.contains(WidgetState.selected)) {
          return onAccent;
        }
        return colors.view;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledControl;
        }
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return colors.controlHover;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return colors.border;
      }),
    ),
    checkboxTheme: base.checkboxTheme.copyWith(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledControl;
        }
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return colors.control;
      }),
      // The mark is content on an accent surface, not ordinary foreground.
      checkColor: WidgetStatePropertyAll(onAccent),
      side: BorderSide(color: colors.border),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledForeground;
        }
        if (states.contains(WidgetState.selected)) {
          return accentColor;
        }
        return colors.mutedForeground;
      }),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: colors.popover,
      surfaceTintColor: colors.popover,
      shadowColor: colorScheme.shadow,
      shape: _withOutlineSide(base.popupMenuTheme.shape, popoverSurfaceSide),
      iconColor: colors.mutedForeground,
      textStyle: textTheme.bodyMedium,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return textTheme.bodyMedium?.copyWith(
          color: states.contains(WidgetState.disabled)
              ? colors.disabledForeground
              : colors.foreground,
        );
      }),
    ),
    menuTheme: MenuThemeData(
      style: menuStyle,
      submenuIcon: base.menuTheme.submenuIcon,
    ),
    dropdownMenuTheme: base.dropdownMenuTheme.copyWith(
      textStyle: textTheme.bodyMedium,
      menuStyle: dropdownMenuStyle,
    ),
    // Keep Yaru's native desktop tooltip palette. Re-deriving Material's
    // tooltip defaults from BusyMark's remapped surface ColorScheme gives
    // dropdown triggers a different floating color than native GTK.
    tooltipTheme: base.tooltipTheme,
    tabBarTheme: base.tabBarTheme.copyWith(
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      dividerColor: colors.divider,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      circularTrackColor: colors.control,
      linearTrackColor: colors.control,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accentColor,
      selectionColor: accentColor.withValues(
        alpha: BusyMarkAlpha.textSelection,
      ),
      selectionHandleColor: accentColor,
    ),
    cardTheme: base.cardTheme.copyWith(
      color: colors.card,
      elevation: BusyMarkElevation.surface,
      surfaceTintColor: BusyMarkLinuxPalette.transparent,
      shadowColor: colorScheme.shadow,
      shape:
          base.cardTheme.shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
          ),
    ),
  );
}

Color _accessibleForeground(Color background) {
  final backgroundLuminance = background.computeLuminance();
  final blackContrast = (backgroundLuminance + 0.05) / 0.05;
  final whiteContrast = 1.05 / (backgroundLuminance + 0.05);
  return blackContrast >= whiteContrast
      ? BusyMarkLinuxPalette.black
      : BusyMarkLinuxPalette.white;
}

TextTheme _busyMarkTextTheme(TextTheme base, BusyMarkSurfaceColors colors) {
  TextStyle? apply(TextStyle? style, {Color? color}) =>
      style?.copyWith(color: color);

  return base.copyWith(
    displayLarge: apply(base.displayLarge, color: colors.foreground),
    displayMedium: apply(base.displayMedium, color: colors.foreground),
    displaySmall: apply(base.displaySmall, color: colors.foreground),
    headlineLarge: apply(base.headlineLarge, color: colors.foreground),
    headlineMedium: apply(base.headlineMedium, color: colors.foreground),
    headlineSmall: apply(base.headlineSmall, color: colors.foreground),
    titleLarge: apply(base.titleLarge, color: colors.foreground),
    titleMedium: apply(base.titleMedium, color: colors.foreground),
    titleSmall: apply(base.titleSmall, color: colors.mutedForeground),
    bodyLarge: apply(base.bodyLarge, color: colors.foreground),
    bodyMedium: apply(base.bodyMedium, color: colors.foreground),
    bodySmall: apply(base.bodySmall, color: colors.mutedForeground),
    labelLarge: apply(base.labelLarge, color: colors.foreground),
    labelMedium: apply(base.labelMedium, color: colors.mutedForeground),
    labelSmall: apply(base.labelSmall, color: colors.mutedForeground),
  );
}

/// Applies BusyMark's semantic roles without replacing Yaru's geometry,
/// typography, hover/press overlays, focus treatment, or motion.
ButtonStyle _semanticButtonStyle(
  ButtonStyle? base, {
  required Color foreground,
  required Color background,
  Color? selectedBackground,
  required Color disabledForeground,
  required Color disabledBackground,
}) {
  return (base ?? const ButtonStyle()).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledForeground;
      }
      return foreground;
    }),
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledForeground;
      }
      return foreground;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledBackground;
      }
      if (selectedBackground != null && states.contains(WidgetState.selected)) {
        return selectedBackground;
      }
      return background;
    }),
  );
}

/// Changes only the floating-surface roles and keeps Yaru's menu geometry,
/// item states, padding, focus behavior, and animation.
MenuStyle _semanticMenuSurfaceStyle(
  MenuStyle? base, {
  required Color color,
  required Color shadowColor,
  required BorderSide side,
}) {
  return (base ?? const MenuStyle()).copyWith(
    backgroundColor: WidgetStatePropertyAll(color),
    surfaceTintColor: WidgetStatePropertyAll(color),
    shadowColor: WidgetStatePropertyAll(shadowColor),
    side: WidgetStatePropertyAll(side),
  );
}

ShapeBorder? _withOutlineSide(ShapeBorder? shape, BorderSide side) {
  return switch (shape) {
    final InputBorder input => input.copyWith(borderSide: side),
    final OutlinedBorder outlined => outlined.copyWith(side: side),
    _ => shape,
  };
}
