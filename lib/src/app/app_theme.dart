import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaru/theme.dart';

import 'busymark_design.dart';

ThemeData buildBusyMarkTheme({
  required Brightness brightness,
  required Color accentColor,
}) {
  final base = switch (brightness) {
    Brightness.light => createYaruLightTheme(
      primaryColor: BusyMarkLinuxPalette.light4,
    ),
    Brightness.dark => createYaruDarkTheme(
      primaryColor: BusyMarkLinuxPalette.light2,
    ),
  };
  final colors = BusyMarkSurfaceColors.fromBrightness(brightness);
  final onAccent = contrastColor(accentColor);
  final selectedContainer = colors.controlActive;
  final colorScheme = base.colorScheme.copyWith(
    brightness: brightness,
    primary: accentColor,
    onPrimary: onAccent,
    primaryContainer: selectedContainer,
    onPrimaryContainer: colors.foreground,
    secondary: BusyMarkLinuxPalette.blueAccent,
    error: BusyMarkLinuxPalette.red,
    surface: colors.view,
    onSurface: colors.foreground,
    onSurfaceVariant: colors.mutedForeground,
    surfaceContainerLowest: colors.window,
    surfaceContainerLow: colors.view,
    surfaceContainer: colors.card,
    surfaceContainerHigh: colors.control,
    surfaceContainerHighest: colors.controlHover,
    outline: colors.border,
    outlineVariant: colors.subtleBorder,
    scrim: BusyMarkLinuxPalette.black,
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
  );
  final inputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: colors.border),
    borderRadius: BorderRadius.circular(BusyMarkRadius.sm + 2),
  );
  final focusedInputBorder = inputBorder.copyWith(
    borderSide: BorderSide(color: accentColor, width: 2),
  );
  final textTheme = _busyMarkTextTheme(base.textTheme, colors);
  final buttonText = WidgetStatePropertyAll(textTheme.labelLarge);
  final inputDecorationTheme = base.inputDecorationTheme.copyWith(
    filled: true,
    fillColor: colors.control,
    border: inputBorder,
    enabledBorder: inputBorder,
    focusedBorder: focusedInputBorder,
    focusedErrorBorder: inputBorder.copyWith(
      borderSide: BorderSide(color: colorScheme.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    hintStyle: textTheme.bodyMedium?.copyWith(color: colors.mutedForeground),
  );

  return base.copyWith(
    brightness: brightness,
    colorScheme: colorScheme,
    primaryColor: accentColor,
    shadowColor: colors.shade,
    scaffoldBackgroundColor: colors.window,
    canvasColor: colors.window,
    cardColor: colors.card,
    extensions: [
      for (final extension in base.extensions.values)
        if (extension is! BusyMarkSurfaceColors) extension,
      colors,
    ],
    dividerColor: colors.subtleBorder,
    visualDensity: VisualDensity.compact,
    splashFactory: NoSplash.splashFactory,
    focusColor: accentColor.withValues(alpha: 0.18),
    hoverColor: colors.controlHover,
    splashColor: accentColor.withValues(alpha: 0.12),
    appBarTheme: base.appBarTheme.copyWith(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.headerbar,
      foregroundColor: colors.foreground,
      surfaceTintColor: colors.headerbar,
      shape: Border(bottom: BorderSide(color: colors.subtleBorder)),
      toolbarHeight: BusyMarkSizes.toolbarHeight,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: textTheme.titleMedium,
    ),
    textTheme: textTheme,
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: colors.dialog,
      surfaceTintColor: colors.dialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BusyMarkRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    listTileTheme: base.listTileTheme.copyWith(
      selectedColor: colors.foreground,
      selectedTileColor: selectedContainer,
      iconColor: colors.mutedForeground,
      textColor: colors.foreground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      titleTextStyle: textTheme.bodyMedium,
      subtitleTextStyle: textTheme.bodySmall,
      leadingAndTrailingTextStyle: textTheme.labelSmall,
    ),
    inputDecorationTheme: inputDecorationTheme,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle(
        base.outlinedButtonTheme.style,
        shape: buttonShape,
        foreground: colors.foreground,
        background: colors.control,
        disabledForeground: colors.disabledForeground,
        disabledBackground: colors.disabledControl,
        textStyle: buttonText,
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: accentColor);
          }
          return BorderSide.none;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _buttonStyle(
        base.filledButtonTheme.style,
        shape: buttonShape,
        foreground: onAccent,
        background: accentColor,
        disabledForeground: colors.disabledForeground,
        disabledBackground: colors.disabledControl,
        overlayColor: _controlOverlay(onAccent),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _buttonStyle(
        base.textButtonTheme.style,
        shape: buttonShape,
        foreground: accentColor,
        background: Colors.transparent,
        disabledForeground: colors.disabledForeground,
        disabledBackground: Colors.transparent,
        overlayColor: _controlOverlay(accentColor),
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: _buttonStyle(
        base.iconButtonTheme.style,
        shape: buttonShape,
        foreground: colors.mutedForeground,
        background: Colors.transparent,
        disabledForeground: colors.disabledForeground,
        disabledBackground: Colors.transparent,
        overlayColor: _controlOverlay(accentColor),
        textStyle: buttonText,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style:
          _buttonStyle(
            base.segmentedButtonTheme.style,
            shape: buttonShape,
            foreground: colors.foreground,
            background: colors.control,
            disabledForeground: colors.disabledForeground,
            disabledBackground: colors.disabledControl,
            overlayColor: _controlOverlay(accentColor),
            textStyle: buttonText,
            side: const WidgetStatePropertyAll(BorderSide.none),
          ).copyWith(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colors.disabledForeground;
              }
              if (states.contains(WidgetState.selected)) {
                return colors.foreground;
              }
              return colors.foreground;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return selectedContainer;
              }
              return colors.control;
            }),
          ),
    ),
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
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: colors.popover,
      surfaceTintColor: colors.popover,
      elevation: BusyMarkElevation.popover,
      shadowColor: colors.shade,
      iconColor: colors.mutedForeground,
      iconSize: BusyMarkSizes.iconSm,
      textStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      dividerColor: colors.subtleBorder,
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        color: colors.popover,
        borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
        boxShadow: BusyMarkShadow.floatingShadows(colors.shade),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BusyMarkSpacing.tooltipHorizontal,
        vertical: BusyMarkSpacing.tooltipVertical,
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: colors.foreground),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      circularTrackColor: colors.control,
      linearTrackColor: colors.control,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: accentColor,
      selectionColor: accentColor.withValues(alpha: 0.32),
      selectionHandleColor: accentColor,
    ),
    cardTheme: CardThemeData(
      color: colors.card,
      elevation: BusyMarkElevation.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: colors.shade,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BusyMarkRadius.md),
      ),
    ),
  );
}

TextTheme _busyMarkTextTheme(TextTheme base, BusyMarkSurfaceColors colors) {
  TextStyle? apply(TextStyle? style, {Color? color}) {
    return style?.copyWith(
      color: color,
      fontFamily: 'Ubuntu',
      letterSpacing: 0,
    );
  }

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

ButtonStyle _buttonStyle(
  ButtonStyle? base, {
  required OutlinedBorder shape,
  required Color foreground,
  required Color background,
  required Color disabledForeground,
  required Color disabledBackground,
  WidgetStateProperty<Color?>? overlayColor,
  WidgetStateProperty<BorderSide?>? side,
  WidgetStateProperty<TextStyle?>? textStyle,
}) {
  return (base ?? const ButtonStyle()).copyWith(
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textStyle: textStyle,
    shape: WidgetStatePropertyAll(shape),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledForeground;
      }
      return foreground;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return disabledBackground;
      }
      return background;
    }),
    overlayColor: overlayColor ?? _controlOverlay(foreground),
    side: side ?? const WidgetStatePropertyAll(BorderSide.none),
    elevation: const WidgetStatePropertyAll(0),
  );
}

WidgetStateProperty<Color?> _controlOverlay(Color foreground) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return foreground.withValues(alpha: 0.14);
    }
    if (states.contains(WidgetState.hovered)) {
      return foreground.withValues(alpha: 0.08);
    }
    if (states.contains(WidgetState.focused)) {
      return foreground.withValues(alpha: 0.10);
    }
    return null;
  });
}
