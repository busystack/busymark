import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

abstract final class BusyMarkSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double tooltipHorizontal = 8;
  static const double tooltipVertical = 5;
}

abstract final class BusyMarkRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double headerButton = 8;
  static const double window = 8;
}

abstract final class BusyMarkSizes {
  static const double sidebarWidth = 300;
  static const double settingsWidth = 760;
  static const double toolbarHeight = 46;
  static const double paneHeaderHeight = 38;
  static const double iconButton = 34;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double previewMinWidth = 320;
}

abstract final class BusyMarkElevation {
  static const double surface = 1;
  static const double popover = 6;
  static const double window = 12;
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
        color: _scaleAlpha(color, 0.34),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: _scaleAlpha(color, 0.16),
        blurRadius: 1,
        offset: const Offset(0, 1),
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
        color: color.withValues(alpha: color.a * 0.75),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: color.withValues(alpha: color.a * 0.45),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: color.withValues(alpha: color.a * 0.25),
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

abstract final class BusyMarkLinuxPalette {
  static const blueAccent = Color(0xFF3584E4);
  static const red = Color(0xFFC01C28);
  static const yellow = Color(0xFFE5A50A);
  static const green = Color(0xFF2EC27E);
  static const light2 = Color(0xFFF6F5F4);
  static const light4 = Color(0xFFC0BFBC);
  static const dark4 = Color(0xFF242424);
  static const black = Color(0xFF000000);
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
        dialog: Color(0xFFFAFAFA),
        popover: Color(0xFFFFFFFF),
        control: Color.fromRGBO(0, 0, 0, 0.06),
        controlHover: Color.fromRGBO(0, 0, 0, 0.10),
        controlActive: Color.fromRGBO(0, 0, 0, 0.16),
        activeToggle: Color(0xFFFFFFFF),
        foreground: Color.fromRGBO(0, 0, 0, 0.82),
        mutedForeground: Color.fromRGBO(0, 0, 0, 0.58),
        disabledForeground: Color.fromRGBO(0, 0, 0, 0.38),
        disabledControl: Color.fromRGBO(0, 0, 0, 0.04),
        border: Color.fromRGBO(0, 0, 0, 0.18),
        subtleBorder: Color.fromRGBO(0, 0, 0, 0.10),
        sidebarBorder: Color.fromRGBO(0, 0, 0, 0.08),
        shade: Color.fromRGBO(0, 0, 0, 0.08),
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
        dialog: Color(0xFF2A2A2A),
        popover: Color(0xFF383838),
        control: Color.fromRGBO(255, 255, 255, 0.10),
        controlHover: Color.fromRGBO(255, 255, 255, 0.14),
        controlActive: Color.fromRGBO(255, 255, 255, 0.18),
        activeToggle: Color.fromRGBO(255, 255, 255, 0.20),
        foreground: Color(0xFFFFFFFF),
        mutedForeground: Color.fromRGBO(255, 255, 255, 0.70),
        disabledForeground: Color.fromRGBO(255, 255, 255, 0.38),
        disabledControl: Color.fromRGBO(255, 255, 255, 0.06),
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
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BusyMarkRadius.headerButton),
      ),
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

Color busyMarkSelectedBackground(BuildContext context) {
  return BusyMarkSurfaceColors.of(context).controlActive;
}

Color busyMarkRowHoverColor(BuildContext context) {
  final colors = BusyMarkSurfaceColors.of(context);
  return colors.foreground.withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? 0.045 : 0.055,
  );
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
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    final colors = BusyMarkSurfaceColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      style: busyMarkHeaderIconButtonStyle(
        foregroundColor: accented
            ? colorScheme.onPrimary
            : selected
            ? colorScheme.primary
            : colors.mutedForeground,
        backgroundColor: accented
            ? WidgetStatePropertyAll(colorScheme.primary)
            : selected
            ? WidgetStatePropertyAll(colors.controlActive)
            : busyMarkHeaderButtonBackground(context),
      ),
      tooltip: tooltip,
      icon: Icon(icon, size: BusyMarkSizes.iconSm),
      onPressed: onPressed,
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
  });

  final String tooltip;
  final IconData icon;
  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BusyMarkSurfaceColors.of(context);
    final popupTheme = theme.popupMenuTheme;
    return Theme(
      data: theme.copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: busyMarkHeaderIconButtonStyle(
            foregroundColor: colors.mutedForeground,
            backgroundColor: busyMarkHeaderButtonBackground(context),
          ),
        ),
      ),
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        icon: Icon(icon, size: BusyMarkSizes.iconSm),
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        color: popupTheme.color ?? colors.popover,
        surfaceTintColor: Colors.transparent,
        elevation: BusyMarkElevation.popover,
        shadowColor: colors.shade,
        shape:
            popupTheme.shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BusyMarkRadius.md),
            ),
        constraints: const BoxConstraints(minWidth: 180),
        itemBuilder: itemBuilder,
        onSelected: onSelected,
      ),
    );
  }
}

class BusyMarkPopupMenuItem<T> extends PopupMenuItem<T> {
  BusyMarkPopupMenuItem({
    super.key,
    required T value,
    required String label,
    IconData? icon,
  }) : super(
         value: value,
         height: 36,
         padding: EdgeInsets.zero,
         child: Builder(
           builder: (context) {
             final colors = BusyMarkSurfaceColors.of(context);
             return Padding(
               padding: const EdgeInsets.symmetric(
                 horizontal: BusyMarkSpacing.md,
               ),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   SizedBox(
                     width: 24,
                     child: icon == null
                         ? const SizedBox.shrink()
                         : Icon(
                             icon,
                             size: BusyMarkSizes.iconSm,
                             color: colors.mutedForeground,
                           ),
                   ),
                   const SizedBox(width: BusyMarkSpacing.sm),
                   Flexible(
                     child: Text(label, overflow: TextOverflow.ellipsis),
                   ),
                 ],
               ),
             );
           },
         ),
       );
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
    final colors = BusyMarkSurfaceColors.of(context);
    final surface = Material(
      color: filled ? colors.card : Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: clipBehavior,
      child: child,
    );
    if (!filled) {
      return surface;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
      ),
      child: surface,
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
            Divider(height: 1, thickness: 1, color: colors.subtleBorder),
        ],
      ],
    );

    if (!filled) {
      return list;
    }

    final borderRadius = BorderRadius.circular(BusyMarkRadius.md);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: BusyMarkShadow.surfaceShadows(colors.shade),
      ),
      child: Material(
        color: colors.control,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: list,
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = destructive ? TextStyle(color: colorScheme.error) : null;
    return YaruListTile.square(
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
      hoverColor: busyMarkRowHoverColor(context),
      onTap: enabled ? onTap : null,
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
    return YaruSwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      secondary: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      hoverColor: busyMarkRowHoverColor(context),
    );
  }
}

class BusyMarkDialogShell extends StatelessWidget {
  const BusyMarkDialogShell({
    super.key,
    required this.title,
    required this.children,
    this.maxWidth = 520,
    this.actions = const [],
  });

  final String title;
  final List<Widget> children;
  final double maxWidth;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YaruDialogTitleBar(title: Text(title), centerTitle: true),
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
                    action,
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

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Text(text, style: busyMarkSectionHeaderStyle(context)),
    );
  }
}
