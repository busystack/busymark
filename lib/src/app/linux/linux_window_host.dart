import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../localization.dart';
import '../../platform/gtk_window_preferences_service.dart';
import '../busymark_design.dart';
import '../window_control_service.dart';

/// Shared dimensions for Flutter-owned Linux chrome.
abstract final class BusyMarkLinuxWindowMetrics {
  static const double headerHeight = BusyMarkSizes.toolbarHeight;
  static const double controlSize = kYaruWindowControlSize;
  static const double controlSpacing = 14;
  static const double controlHorizontalPadding = 10;

  static double decorationWidth(GtkWindowDecorationElement decoration) =>
      switch (decoration) {
        GtkWindowDecorationElement.fallbackApplicationMenu => 0,
        GtkWindowDecorationElement.windowIcon ||
        GtkWindowDecorationElement.minimize ||
        GtkWindowDecorationElement.maximize ||
        GtkWindowDecorationElement.close => controlSize,
      };

  static double clusterWidth(List<GtkWindowDecorationElement> decorations) =>
      decorations.isEmpty
      ? 0
      : controlHorizontalPadding * 2 +
            decorations.fold(0, (width, item) {
              return width + decorationWidth(item);
            }) +
            controlSpacing * (decorations.length - 1);
}

class LinuxWindowMetricsScope extends InheritedWidget {
  const LinuxWindowMetricsScope({
    super.key,
    required this.leftControlInset,
    required this.rightControlInset,
    required this.windowActive,
    required this.preferences,
    required super.child,
  });

  final double leftControlInset;
  final double rightControlInset;
  final bool windowActive;
  final GtkWindowPreferences preferences;

  static final LinuxWindowMetricsScope _fallback = LinuxWindowMetricsScope(
    leftControlInset: 0,
    rightControlInset: 0,
    windowActive: true,
    preferences: GtkWindowPreferences.defaults(),
    child: const SizedBox.shrink(),
  );

  static LinuxWindowMetricsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LinuxWindowMetricsScope>() ??
      _fallback;

  @override
  bool updateShouldNotify(LinuxWindowMetricsScope oldWidget) =>
      leftControlInset != oldWidget.leftControlInset ||
      rightControlInset != oldWidget.rightControlInset ||
      windowActive != oldWidget.windowActive ||
      preferences != oldWidget.preferences;
}

/// Owns the stable, window-level system controls above the route navigator.
///
/// The overlay contains only the configured control clusters. Application
/// header content remains inside page routes and is therefore covered by
/// ordinary dialog barriers.
class LinuxWindowHost extends ConsumerStatefulWidget {
  const LinuxWindowHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LinuxWindowHost> createState() => _LinuxWindowHostState();
}

class _LinuxWindowHostState extends ConsumerState<LinuxWindowHost> {
  YaruWindowInstance? _window;
  Stream<YaruWindowState>? _windowStates;
  Brightness? _nativeBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_nativeBrightness != brightness) {
      _nativeBrightness = brightness;
      unawaited(
        const GtkWindowPreferencesService().setPreferDark(
          brightness == Brightness.dark,
        ),
      );
    }
    final window = YaruWindow.of(context);
    if (identical(window, _window)) return;
    _window = window;
    _windowStates = window.states();
  }

  @override
  Widget build(BuildContext context) {
    final preferences =
        ref.watch(gtkWindowPreferencesProvider).asData?.value ??
        ref.watch(initialGtkWindowPreferencesProvider) ??
        GtkWindowPreferences.defaults();
    return StreamBuilder<YaruWindowState>(
      stream: _windowStates,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const YaruWindowState();
        final leftDecorations = _meaningfulDecorations(
          preferences.decorationLayout.left,
          state,
        );
        final rightDecorations = _meaningfulDecorations(
          preferences.decorationLayout.right,
          state,
        );
        final leftInset = BusyMarkLinuxWindowMetrics.clusterWidth(
          leftDecorations,
        );
        final rightInset = BusyMarkLinuxWindowMetrics.clusterWidth(
          rightDecorations,
        );
        return LinuxWindowMetricsScope(
          leftControlInset: leftInset,
          rightControlInset: rightInset,
          windowActive: state.isActive != false,
          preferences: preferences,
          child: _LinuxWindowOverlay(
            leftDecorations: leftDecorations,
            rightDecorations: rightDecorations,
            state: state,
            child: widget.child,
          ),
        );
      },
    );
  }
}

List<GtkWindowDecorationElement> _meaningfulDecorations(
  List<GtkWindowDecorationElement> decorations,
  YaruWindowState state,
) => decorations
    .where((decoration) {
      return switch (decoration) {
        // BusyMark does not register GTK's fallback application-menu model.
        GtkWindowDecorationElement.fallbackApplicationMenu => false,
        GtkWindowDecorationElement.windowIcon => true,
        GtkWindowDecorationElement.minimize => state.isMinimizable != false,
        GtkWindowDecorationElement.maximize =>
          state.isMaximizable != false ||
              state.isRestorable == true ||
              state.isMaximized == true ||
              state.isFullscreen == true,
        GtkWindowDecorationElement.close => state.isClosable != false,
      };
    })
    .toList(growable: false);

class _LinuxWindowOverlay extends StatefulWidget {
  const _LinuxWindowOverlay({
    required this.leftDecorations,
    required this.rightDecorations,
    required this.state,
    required this.child,
  });

  final List<GtkWindowDecorationElement> leftDecorations;
  final List<GtkWindowDecorationElement> rightDecorations;
  final YaruWindowState state;
  final Widget child;

  @override
  State<_LinuxWindowOverlay> createState() => _LinuxWindowOverlayState();
}

class _LinuxWindowOverlayState extends State<_LinuxWindowOverlay> {
  late final OverlayEntry _entry = OverlayEntry(builder: _buildOverlay);

  @override
  void didUpdateWidget(covariant _LinuxWindowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (widget.leftDecorations.isNotEmpty)
          Positioned(
            key: const ValueKey('linux-window-controls-left'),
            left: 0,
            top: 0,
            height: BusyMarkLinuxWindowMetrics.headerHeight,
            child: _LinuxWindowControlCluster(
              decorations: widget.leftDecorations,
              state: widget.state,
            ),
          ),
        if (widget.rightDecorations.isNotEmpty)
          Positioned(
            key: const ValueKey('linux-window-controls-right'),
            right: 0,
            top: 0,
            height: BusyMarkLinuxWindowMetrics.headerHeight,
            child: _LinuxWindowControlCluster(
              decorations: widget.rightDecorations,
              state: widget.state,
            ),
          ),
      ],
    );
  }
}

class _LinuxWindowControlCluster extends ConsumerWidget {
  const _LinuxWindowControlCluster({
    required this.decorations,
    required this.state,
  });

  final List<GtkWindowDecorationElement> decorations;
  final YaruWindowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foreground = BusyMarkSurfaceColors.of(context).foreground;
    return Material(
      type: MaterialType.transparency,
      child: _LinuxWindowActivationOpacity(
        opacity: state.isActive == false ? .5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BusyMarkLinuxWindowMetrics.controlHorizontalPadding,
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < decorations.length; index++) ...[
                if (index > 0)
                  const SizedBox(
                    width: BusyMarkLinuxWindowMetrics.controlSpacing,
                  ),
                KeyedSubtree(
                  key: ValueKey(decorations[index]),
                  child: _buildDecoration(
                    context,
                    ref,
                    decorations[index],
                    foreground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecoration(
    BuildContext context,
    WidgetRef ref,
    GtkWindowDecorationElement decoration,
    Color foreground,
  ) {
    final window = YaruWindow.of(context);
    final material = MaterialLocalizations.of(context);
    final iconColor = WidgetStatePropertyAll(foreground);
    final restorePresentation =
        state.isMaximized == true || state.isFullscreen == true;
    return switch (decoration) {
      GtkWindowDecorationElement.fallbackApplicationMenu =>
        const SizedBox.shrink(),
      GtkWindowDecorationElement.windowIcon => SizedBox.square(
        dimension: BusyMarkLinuxWindowMetrics.controlSize,
        child: Center(
          child: SvgPicture.asset(
            'assets/branding/busymark_logo.svg',
            width: BusyMarkSizes.iconSm,
            height: BusyMarkSizes.iconSm,
            excludeFromSemantics: true,
          ),
        ),
      ),
      GtkWindowDecorationElement.minimize => Tooltip(
        message: context.l10n.windowMinimize,
        child: _LinuxWindowControl(
          iconColor: iconColor,
          semanticLabel: context.l10n.windowMinimize,
          type: YaruWindowControlType.minimize,
          onTap: state.isMinimizable == false ? null : window.minimize,
        ),
      ),
      GtkWindowDecorationElement.maximize => Tooltip(
        message: restorePresentation
            ? context.l10n.windowRestore
            : context.l10n.windowMaximize,
        child: _LinuxWindowControl(
          iconColor: iconColor,
          semanticLabel: restorePresentation
              ? context.l10n.windowRestore
              : context.l10n.windowMaximize,
          type: restorePresentation
              ? YaruWindowControlType.restore
              : YaruWindowControlType.maximize,
          onTap: restorePresentation
              ? window.restore
              : state.isMaximizable == false
              ? null
              : window.maximize,
        ),
      ),
      GtkWindowDecorationElement.close => Tooltip(
        message: material.closeButtonTooltip,
        child: _LinuxWindowControl(
          iconColor: iconColor,
          semanticLabel: material.closeButtonLabel,
          type: YaruWindowControlType.close,
          onTap: state.isClosable == false
              ? null
              : ref.read(windowControlServiceProvider).requestClose,
        ),
      ),
    };
  }
}

/// Yaru's controls do not consume MediaQuery.disableAnimations. Under reduced
/// motion, remount each icon at its final type and render feedback outside its
/// animated background, keeping the native control's artwork and interaction.
class _LinuxWindowControl extends StatefulWidget {
  const _LinuxWindowControl({
    required this.type,
    required this.iconColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final YaruWindowControlType type;
  final WidgetStateProperty<Color?> iconColor;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<_LinuxWindowControl> createState() => _LinuxWindowControlState();
}

class _LinuxWindowControlState extends State<_LinuxWindowControl> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final control = YaruWindowControl(
      key: reducedMotion ? ValueKey(widget.type) : null,
      type: widget.type,
      iconColor: widget.iconColor,
      semanticLabel: widget.semanticLabel,
      onTap: widget.onTap,
      backgroundColor: reducedMotion
          ? const WidgetStatePropertyAll(BusyMarkLinuxPalette.transparent)
          : null,
    );
    if (!reducedMotion) return control;
    final alpha = widget.onTap == null
        ? .05
        : _pressed
        ? .2
        : _hovered
        ? .15
        : .1;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: alpha),
          ),
          child: control,
        ),
      ),
    );
  }
}

class _LinuxWindowActivationOpacity extends StatelessWidget {
  const _LinuxWindowActivationOpacity({
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const key = ValueKey('linux-window-controls-opacity');
    if (MediaQuery.disableAnimationsOf(context)) {
      return Opacity(key: key, opacity: opacity, child: child);
    }
    return AnimatedOpacity(
      key: key,
      opacity: opacity,
      duration: BusyMarkMotion.fast,
      child: child,
    );
  }
}

/// Adds native titlebar gestures only to a page-selected empty header region.
class LinuxTitlebarGestureRegion extends StatelessWidget {
  const LinuxTitlebarGestureRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preferences = LinuxWindowMetricsScope.of(context).preferences;
    final window = YaruWindow.of(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kMiddleMouseButton) {
          unawaited(
            _performTitlebarAction(context, preferences.middleClick, window),
          );
        }
      },
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => unawaited(window.drag()),
        onDoubleTap: () => unawaited(
          _performTitlebarAction(context, preferences.doubleClick, window),
        ),
        onSecondaryTap: () => unawaited(
          _performTitlebarAction(context, preferences.rightClick, window),
        ),
        child: child,
      ),
    );
  }
}

Future<void> _performTitlebarAction(
  BuildContext context,
  GtkTitlebarAction action,
  YaruWindowInstance window,
) async {
  switch (action) {
    case GtkTitlebarAction.none:
      return;
    case GtkTitlebarAction.minimize:
      await window.minimize();
    case GtkTitlebarAction.toggleMaximize:
      final state = await window.state();
      if (!context.mounted) return;
      if (state.isMaximized == true || state.isFullscreen == true) {
        await window.restore();
      } else if (state.isMaximizable != false) {
        await window.maximize();
      }
    case GtkTitlebarAction.menu:
      await window.showMenu();
    case GtkTitlebarAction.lower:
      await const GtkWindowPreferencesService().lowerWindow();
  }
}
