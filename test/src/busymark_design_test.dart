import 'dart:async';
import 'dart:ui' as ui;

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:busymark/src/editor/document_layout.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_toolbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaru/yaru.dart';

void main() {
  test('Split Preview stays fluid without copying Source-only chrome', () {
    const layout = BusyMarkDocumentLayoutSpec.splitPreview;

    expect(
      layout.minimumInsets,
      const EdgeInsets.fromLTRB(
        BusyMarkSpacing.xl,
        BusyMarkSourceEditorMetrics.paddingTop,
        BusyMarkSpacing.xl,
        BusyMarkSizes.iconButton,
      ),
    );
    expect(
      layout.minimumInsets.left,
      lessThan(BusyMarkSizes.sourceGutterWidth),
    );
    expect(layout.maxContentWidth, isNull);
  });

  testWidgets(
    'document frame centers wide content and honors physical safe edges',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Future<Rect> contentRect({
        required double width,
        required TextDirection textDirection,
        required BusyMarkDocumentLayoutSpec layout,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: textDirection,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 100,
                  child: BusyMarkDocumentContentFrame(
                    layout: layout,
                    contentKey: const ValueKey('document-content'),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        return tester.getRect(find.byKey(const ValueKey('document-content')));
      }

      for (final textDirection in TextDirection.values) {
        final wideRect = await contentRect(
          width: 1000,
          textDirection: textDirection,
          layout: BusyMarkDocumentLayoutSpec.standalone,
        );
        expect(wideRect.left, 120);
        expect(wideRect.width, BusyMarkSizes.documentContentWidth);
        expect(wideRect.right, 880);

        final leftToolbarLayout = BusyMarkDocumentLayoutSpec.standalone
            .withEditingToolbar(
              placement: EditorToolbarPlacement.topLeft,
              direction: EditorToolbarDirection.vertical,
            );
        final narrowRect = await contentRect(
          width: 840,
          textDirection: textDirection,
          layout: leftToolbarLayout,
        );
        expect(narrowRect.left, BusyMarkSizes.wysiwygToolbarClearance);
        expect(narrowRect.right, 840 - BusyMarkSpacing.xl);

        final splitPreviewRect = await contentRect(
          width: 500,
          textDirection: textDirection,
          layout: BusyMarkDocumentLayoutSpec.splitPreview,
        );
        expect(splitPreviewRect.left, BusyMarkSpacing.xl);
        expect(splitPreviewRect.right, 500 - BusyMarkSpacing.xl);
      }
    },
  );

  test('toolbar clearance is applied only to the toolbar edge', () {
    const base = BusyMarkDocumentLayoutSpec.standalone;

    final top = base.withEditingToolbar(
      placement: EditorToolbarPlacement.topRight,
      direction: EditorToolbarDirection.horizontal,
    );
    expect(top.minimumInsets.top, BusyMarkSizes.wysiwygToolbarClearance);
    expect(top.minimumInsets.bottom, base.minimumInsets.bottom);

    final bottom = base.withEditingToolbar(
      placement: EditorToolbarPlacement.bottomLeft,
      direction: EditorToolbarDirection.horizontal,
    );
    expect(bottom.minimumInsets.top, base.minimumInsets.top);
    expect(bottom.minimumInsets.bottom, BusyMarkSizes.wysiwygToolbarClearance);

    final right = base.withEditingToolbar(
      placement: EditorToolbarPlacement.bottomRight,
      direction: EditorToolbarDirection.vertical,
    );
    expect(right.minimumInsets.left, base.minimumInsets.left);
    expect(right.minimumInsets.right, BusyMarkSizes.wysiwygToolbarClearance);
  });

  test('sidebar header and list compose the shared vertical gap', () {
    final header = BusyMarkInsets.sidebarHeader.resolve(TextDirection.ltr);
    final tocLtr = BusyMarkInsets.tocHeader.resolve(TextDirection.ltr);
    final tocRtl = BusyMarkInsets.tocHeader.resolve(TextDirection.rtl);

    expect(header.bottom + BusyMarkInsets.sidebarList.top, BusyMarkSpacing.sm);
    expect(tocLtr.top, 0);
    expect(tocLtr.left, BusyMarkSpacing.sm);
    expect(tocLtr.right, 0);
    expect(tocRtl.left, 0);
    expect(tocRtl.right, BusyMarkSpacing.sm);
  });

  testWidgets('header controls delegate geometry and elevation to Yaru', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: const Color(0xFF3584E4),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Row(
            children: [
              BusyMarkHeaderIconButton(
                key: const ValueKey('elevated-icon-button'),
                tooltip: 'Elevated action',
                icon: BusyMarkGlyphs.edit,
                elevated: true,
                borderRadius: BusyMarkRadius.lg,
                onPressed: () {},
              ),
              BusyMarkHeaderIconButton(
                key: const ValueKey('flat-icon-button'),
                tooltip: 'Flat action',
                icon: BusyMarkGlyphs.edit,
                onPressed: () {},
              ),
              const BusyMarkHeaderIconButton(
                key: ValueKey('disabled-accented-icon-button'),
                tooltip: 'Disabled accented action',
                icon: BusyMarkGlyphs.edit,
                accented: true,
                onPressed: null,
              ),
              BusyMarkHeaderIconButton(
                key: const ValueKey('custom-icon-button'),
                tooltip: 'Custom action',
                icon: BusyMarkGlyphs.clear,
                foregroundColor: const Color(0xFF7764D8),
                transparent: false,
                onPressed: () {},
              ),
              BusyMarkHeaderPopupMenuButton<String>(
                key: const ValueKey('elevated-popup-button'),
                tooltip: 'Elevated menu',
                icon: BusyMarkGlyphs.menuVertical,
                elevated: true,
                itemBuilder: (_) => [
                  BusyMarkPopupMenuItem(value: 'action', label: 'Action'),
                ],
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    IconButton iconButton(String key) {
      return tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(IconButton),
        ),
      );
    }

    final elevatedIcon = iconButton('elevated-icon-button');
    final flatIcon = iconButton('flat-icon-button');
    final disabledAccentedIcon = iconButton('disabled-accented-icon-button');
    final customIcon = iconButton('custom-icon-button');
    final elevatedPopup = iconButton('elevated-popup-button');
    final expectedElevation =
        theme.cardTheme.elevation ?? BusyMarkElevation.surface;
    final colors = theme.extension<BusyMarkSurfaceColors>()!;

    expect(
      elevatedIcon.style?.fixedSize?.resolve({}),
      const Size.square(BusyMarkSizes.iconButton),
    );
    expect(elevatedIcon.isSelected, isFalse);
    expect(elevatedIcon.style?.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('elevated-icon-button')),
          matching: find.byType(IconButton),
        ),
      ),
      const Size.square(BusyMarkSizes.iconButton),
    );
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('elevated-popup-button')),
          matching: find.byType(IconButton),
        ),
      ),
      const Size.square(BusyMarkSizes.iconButton),
    );
    expect(elevatedIcon.style?.elevation?.resolve({}), expectedElevation);
    expect(
      elevatedIcon.style?.shadowColor?.resolve({}),
      theme.colorScheme.shadow,
    );
    expect(
      elevatedIcon.style?.surfaceTintColor?.resolve({}),
      BusyMarkLinuxPalette.transparent,
    );
    expect(elevatedPopup.style?.elevation?.resolve({}), expectedElevation);
    expect(flatIcon.style?.elevation, isNull);
    expect(flatIcon.style?.backgroundColor?.resolve({}), isNull);
    expect(elevatedIcon.style?.backgroundColor?.resolve({}), colors.control);
    expect(elevatedPopup.style?.backgroundColor?.resolve({}), colors.control);
    expect(
      disabledAccentedIcon.style?.foregroundColor?.resolve({
        WidgetState.disabled,
      }),
      colors.disabledForeground,
    );
    expect(
      disabledAccentedIcon.style?.backgroundColor?.resolve({
        WidgetState.disabled,
      }),
      colors.disabledControl,
    );
    expect(
      customIcon.style?.foregroundColor?.resolve({}),
      const Color(0xFF7764D8),
    );
    expect(customIcon.style?.backgroundColor?.resolve({}), colors.control);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('elevated-icon-button')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ??
                  false),
        ),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'popup menu rows show shortcuts without redundant hover tooltips',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusyMarkHeaderPopupMenuButton<String>(
              tooltip: 'Main menu',
              icon: BusyMarkGlyphs.menuVertical,
              itemBuilder: (_) => [
                BusyMarkPopupMenuItem<String>(
                  value: 'editor',
                  label: 'Editor',
                  shortcut: 'Ctrl+1',
                ),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Main menu'));
      await tester.pumpAndSettle();
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Ctrl+1'), findsOneWidget);
      expect(find.byTooltip('Editor (Ctrl+1)'), findsNothing);
      expect(find.byTooltip('Main menu'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        isA<FocusScopeNode>(),
        reason:
            'The popup route, rather than its first row, should own initial '
            'focus so Escape works without an unwanted row focus ring.',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Editor'), findsNothing);
    },
  );

  testWidgets('header popup preserves asynchronous menu loading', (
    tester,
  ) async {
    final items = Completer<List<PopupMenuEntry<String>>>();
    String? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusyMarkHeaderPopupMenuButton<String>(
            tooltip: 'Async menu',
            icon: BusyMarkGlyphs.menuVertical,
            itemBuilder: (_) => items.future,
            onSelected: (value) => selection = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Async menu'));
    await tester.pump();
    expect(find.text('Loaded action'), findsNothing);

    items.complete([
      BusyMarkPopupMenuItem(value: 'loaded', label: 'Loaded action'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Loaded action'), findsOneWidget);

    await tester.tap(find.text('Loaded action'));
    await tester.pumpAndSettle();
    expect(selection, 'loaded');
  });

  test('semantic theme retains Yaru geometry, typography, and interaction', () {
    const accent = Color(0xFF7764D8);

    for (final brightness in Brightness.values) {
      final base = switch (brightness) {
        Brightness.light => createYaruLightTheme(primaryColor: accent),
        Brightness.dark => createYaruDarkTheme(primaryColor: accent),
      };
      final theme = buildBusyMarkTheme(
        brightness: brightness,
        accentColor: accent,
      );

      expect(theme.colorScheme.primary, accent);
      expect(theme.colorScheme.secondary, accent);
      expect(
        theme.colorScheme.primaryContainer,
        base.colorScheme.primaryContainer,
      );
      expect(
        theme.colorScheme.onPrimaryContainer,
        base.colorScheme.onPrimaryContainer,
      );
      expect(
        _contrastRatio(theme.colorScheme.onPrimary, theme.colorScheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(
          theme.colorScheme.onPrimaryContainer,
          theme.colorScheme.primaryContainer,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(theme.colorScheme.onError, theme.colorScheme.error),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.visualDensity, base.visualDensity);
      expect(theme.splashFactory.runtimeType, base.splashFactory.runtimeType);
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        base.textTheme.bodyMedium?.fontFamily,
      );
      expect(
        theme.textTheme.bodyMedium?.letterSpacing,
        base.textTheme.bodyMedium?.letterSpacing,
      );
      final colors = theme.extension<BusyMarkSurfaceColors>()!;
      final floatingSide = BorderSide(color: colors.floatingBorder);
      expect(theme.dialogTheme.shape, base.dialogTheme.shape);
      _expectSameGeometryWithSide(
        theme.popupMenuTheme.shape,
        base.popupMenuTheme.shape,
        floatingSide,
      );
      expect(
        theme.menuTheme.style?.shape?.resolve({}),
        base.menuTheme.style?.shape?.resolve({}),
      );
      expect(theme.menuTheme.style?.side?.resolve({}), floatingSide);
      expect(
        theme.dropdownMenuTheme.menuStyle?.shape?.resolve({}),
        base.dropdownMenuTheme.menuStyle?.shape?.resolve({}),
      );
      expect(
        theme.dropdownMenuTheme.menuStyle?.side?.resolve({}),
        floatingSide,
      );
      expect(
        theme.listTileTheme.selectedColor,
        base.listTileTheme.selectedColor,
      );
      expect(
        theme.listTileTheme.selectedTileColor,
        base.listTileTheme.selectedTileColor,
      );
      expect(theme.colorScheme.surface, colors.view);
      expect(theme.colorScheme.onSurface, colors.foreground);
      expect(theme.colorScheme.onSurfaceVariant, colors.mutedForeground);
      expect(theme.colorScheme.surfaceContainerLowest, colors.view);
      expect(theme.colorScheme.surfaceContainerLow, colors.window);
      expect(theme.colorScheme.surfaceContainer, colors.panel);
      expect(theme.colorScheme.surfaceContainerHigh, colors.secondarySidebar);
      expect(theme.colorScheme.surfaceContainerHighest, colors.sidebar);
      final containers = [
        theme.colorScheme.surfaceContainerLowest,
        theme.colorScheme.surfaceContainerLow,
        theme.colorScheme.surfaceContainer,
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.surfaceContainerHighest,
      ];
      for (final color in containers) {
        expect(color.a, 1, reason: '$brightness surface containers are opaque');
      }
      final containerLuminances = [
        for (final color in containers) color.computeLuminance(),
      ];
      for (var index = 0; index < containerLuminances.length - 1; index++) {
        final current = containerLuminances[index];
        final next = containerLuminances[index + 1];
        expect(
          brightness == Brightness.light ? current >= next : current <= next,
          isTrue,
          reason: '$brightness surface containers follow elevation order',
        );
      }
      expect(theme.colorScheme.outline, colors.border);
      expect(theme.colorScheme.outlineVariant, colors.divider);
      expect(theme.colorScheme.scrim, BusyMarkLinuxPalette.black);
      expect(
        theme.inputDecorationTheme.filled,
        base.inputDecorationTheme.filled,
      );
      expect(
        theme.inputDecorationTheme.fillColor,
        base.inputDecorationTheme.fillColor,
      );
      expect(
        theme.inputDecorationTheme.border,
        base.inputDecorationTheme.border,
      );
      expect(
        theme.inputDecorationTheme.enabledBorder,
        base.inputDecorationTheme.enabledBorder,
      );
      expect(
        theme.inputDecorationTheme.focusedBorder,
        base.inputDecorationTheme.focusedBorder,
      );
      expect(
        theme.inputDecorationTheme.contentPadding,
        base.inputDecorationTheme.contentPadding,
      );
      expect(
        theme.dropdownMenuTheme.inputDecorationTheme,
        base.dropdownMenuTheme.inputDecorationTheme,
      );
      expect(
        theme.filledButtonTheme.style?.minimumSize?.resolve({}),
        base.filledButtonTheme.style?.minimumSize?.resolve({}),
      );
      expect(
        theme.filledButtonTheme.style?.padding?.resolve({}),
        base.filledButtonTheme.style?.padding?.resolve({}),
      );
      expect(
        theme.filledButtonTheme.style?.shape?.resolve({}),
        base.filledButtonTheme.style?.shape?.resolve({}),
      );
      expect(
        theme.filledButtonTheme.style?.overlayColor?.resolve({
          WidgetState.hovered,
        }),
        base.filledButtonTheme.style?.overlayColor?.resolve({
          WidgetState.hovered,
        }),
      );
      final segmentedShape = theme.segmentedButtonTheme.style?.shape?.resolve(
        const <WidgetState>{},
      );
      expect(segmentedShape, isA<RoundedRectangleBorder>());
      expect(segmentedShape, isNot(isA<StadiumBorder>()));
      expect(
        (segmentedShape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(kYaruButtonRadius),
      );
      expect(
        theme.segmentedButtonTheme.style?.padding?.resolve({}),
        base.filledButtonTheme.style?.padding?.resolve({}),
      );
      expect(
        theme.segmentedButtonTheme.style?.minimumSize?.resolve({}),
        base.filledButtonTheme.style?.minimumSize?.resolve({}),
      );
    }
  });

  test('semantic surfaces use one modern neutral Linux role ladder', () {
    const blue = Color(0xFF3584E4);
    const orange = Color(0xFFE95420);

    BusyMarkSurfaceColors colors(Brightness brightness, Color accent) {
      final base = switch (brightness) {
        Brightness.light => createYaruLightTheme(primaryColor: accent),
        Brightness.dark => createYaruDarkTheme(primaryColor: accent),
      };
      return BusyMarkSurfaceColors.fromTheme(base);
    }

    final light = colors(Brightness.light, blue);
    expect(light.window, const Color(0xFFFAFAFA));
    expect(light.view, const Color(0xFFFFFFFF));
    expect(light.sidebar, const Color(0xFFEBEBEB));
    expect(light.secondarySidebar, const Color(0xFFF0F0F0));
    expect(light.sidebarBorder, const Color.fromRGBO(24, 24, 24, 0.08));
    expect(light.headerbar, const Color(0xFFFAFAFA));
    expect(light.card, const Color(0xFFFFFFFF));
    expect(light.groupedList, light.card);
    expect(light.dialog, const Color(0xFFFAFAFA));
    expect(light.popover, const Color(0xFFFAFAFA));
    expect(light.card, isNot(light.dialog));
    expect(light.groupedList, isNot(light.dialog));
    expect(light.control, const Color.fromRGBO(0, 0, 0, 0.10));
    expect(light.floatingBorder, const Color.fromRGBO(0, 0, 0, 0.14));
    expect(light.controlHover, const Color.fromRGBO(0, 0, 0, 0.14));
    expect(light.controlActive, const Color.fromRGBO(0, 0, 0, 0.18));

    final dark = colors(Brightness.dark, blue);
    expect(dark.window, const Color(0xFF2C2C2C));
    expect(dark.view, const Color(0xFF272727));
    expect(dark.sidebar, const Color(0xFF393939));
    expect(dark.secondarySidebar, const Color(0xFF323232));
    expect(dark.sidebarBorder, const Color.fromRGBO(16, 16, 16, 0.35));
    expect(dark.headerbar, const Color(0xFF393939));
    expect(dark.card, const Color(0xFF3D3D3D));
    expect(dark.groupedList, dark.card);
    expect(dark.dialog, const Color(0xFF3E3E3E));
    expect(dark.popover, const Color(0xFF3E3E3E));
    expect(dark.card, isNot(dark.dialog));
    expect(dark.groupedList, isNot(dark.dialog));
    expect(dark.control, const Color.fromRGBO(255, 255, 255, 0.10));
    expect(dark.floatingBorder, const Color.fromRGBO(0, 0, 0, 0.14));
    expect(dark.controlHover, const Color.fromRGBO(255, 255, 255, 0.14));
    expect(dark.controlActive, const Color.fromRGBO(255, 255, 255, 0.18));

    final orangeLight = colors(Brightness.light, orange);
    final orangeDark = colors(Brightness.dark, orange);
    expect(orangeLight.window, light.window);
    expect(orangeLight.sidebar, light.sidebar);
    expect(orangeLight.groupedList, light.groupedList);
    expect(orangeDark.window, dark.window);
    expect(orangeDark.sidebar, dark.sidebar);
    expect(orangeDark.groupedList, dark.groupedList);
    for (final palette in [light, dark]) {
      expect(palette.mutedForeground.a, 1);
      for (final background in [
        palette.view,
        palette.window,
        palette.sidebar,
        palette.secondarySidebar,
        palette.headerbar,
        palette.headerbarFlat,
        palette.panel,
        palette.card,
        palette.groupedList,
        palette.dialog,
        palette.popover,
      ]) {
        expect(
          _contrastRatio(palette.mutedForeground, background),
          greaterThanOrEqualTo(4.5),
          reason: 'Muted text must remain legible on $background',
        );
      }
      expect(palette.admonitionNote, isNot(palette.groupedList));
      expect(palette.admonitionTip, isNot(palette.groupedList));
      expect(palette.admonitionWarning, isNot(palette.groupedList));
    }
  });

  test('equal-choice segmented selection stays neutral', () {
    const accent = Color(0xFFED5B00);
    final theme = buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: accent,
    );
    final colors = theme.extension<BusyMarkSurfaceColors>()!;
    final style = theme.segmentedButtonTheme.style!;

    expect(style.backgroundColor?.resolve({}), colors.control);
    expect(
      style.backgroundColor?.resolve({WidgetState.selected}),
      colors.controlActive,
    );
    expect(
      style.foregroundColor?.resolve({WidgetState.selected}),
      colors.foreground,
    );
    expect(
      style.backgroundColor?.resolve({WidgetState.selected}),
      isNot(accent),
    );
    expect(style.side?.resolve({WidgetState.selected}), BorderSide.none);
  });

  testWidgets('grouped cards use one semantic raised-surface token', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: const Color(0xFF3584E4),
    );
    final colors = theme.extension<BusyMarkSurfaceColors>()!;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          backgroundColor: colors.dialog,
          body: Column(
            children: [
              const BusyMarkSurface(child: SizedBox(height: 20)),
              BusyMarkGroupedList(
                filled: true,
                children: [
                  BusyMarkActionRow(title: 'One', onTap: () {}),
                  BusyMarkActionRow(title: 'Two', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final groupedMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(BusyMarkGroupedSurface),
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.color == colors.groupedList,
        ),
      ),
    );
    expect(groupedMaterial.elevation, BusyMarkElevation.surface);
    expect(groupedMaterial.shadowColor, theme.colorScheme.shadow);
    expect(
      (groupedMaterial.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(BusyMarkRadius.lg),
    );

    final cardMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(BusyMarkSurface).first,
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.color == colors.card,
        ),
      ),
    );
    expect(cardMaterial.elevation, BusyMarkElevation.surface);
    expect(cardMaterial.shadowColor, theme.colorScheme.shadow);
    expect(
      (cardMaterial.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(BusyMarkRadius.lg),
    );
    expect(tester.widget<Divider>(find.byType(Divider)).color, colors.divider);
  });

  testWidgets('dialog roles and popup selectors use real themed buttons', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: const Color(0xFF3584E4),
    );
    String? selectedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              BusyMarkDialogButton(label: 'Cancel', onPressed: () {}),
              BusyMarkDialogButton(
                label: 'Save',
                suggested: true,
                onPressed: () {},
              ),
              BusyMarkDialogButton(
                label: 'Delete',
                destructive: true,
                onPressed: () {},
              ),
              BusyMarkPopupSelector<String>(
                value: 'system',
                label: 'System',
                tooltip: 'Theme',
                options: const [
                  BusyMarkPopupSelectorOption(value: 'system', label: 'System'),
                  BusyMarkPopupSelectorOption(value: 'light', label: 'Light'),
                ],
                onSelected: (value) => selectedTheme = value,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(BusyMarkDialogButton, 'Cancel'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(BusyMarkDialogButton, 'Save'),
        matching: find.byType(ElevatedButton),
      ),
      findsOneWidget,
    );
    final destructive = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.widgetWithText(BusyMarkDialogButton, 'Delete'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(
      destructive.style?.foregroundColor?.resolve({}),
      theme.colorScheme.onError,
    );
    expect(
      destructive.style?.backgroundColor?.resolve({}),
      theme.colorScheme.error,
    );

    final selectorFinder = find.descendant(
      of: find.byType(BusyMarkPopupSelector<String>),
      matching: find.byType(YaruPopupMenuButton<String>),
    );
    final selector = tester.widget<YaruPopupMenuButton<String>>(selectorFinder);
    expect(
      selector.style?.backgroundColor?.resolve({}),
      BusyMarkLinuxPalette.transparent,
    );
    expect(selector.style?.side?.resolve({}), BorderSide.none);
    expect(
      selector.style?.minimumSize?.resolve({}),
      theme.outlinedButtonTheme.style?.minimumSize?.resolve({}),
    );
    expect(
      selector.style?.padding?.resolve({}),
      theme.outlinedButtonTheme.style?.padding?.resolve({}),
    );
    expect(
      selector.style?.shape?.resolve({}),
      theme.outlinedButtonTheme.style?.shape?.resolve({}),
    );
    expect(selector.initialValue, 'system');
    expect(selector.enabled, isTrue);

    await tester.tap(selectorFinder);
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(selectedTheme, 'light');
  });

  for (final brightness in Brightness.values) {
    testWidgets('WYSIWYG toolbar uses accent controls in ${brightness.name}', (
      tester,
    ) async {
      const accent = Color(0xFFE95420);
      final theme = buildBusyMarkTheme(
        brightness: brightness,
        accentColor: accent,
      );
      final colors = theme.extension<BusyMarkSurfaceColors>()!;
      final boundaryKey = GlobalKey();
      tester.view
        ..physicalSize = const Size(900, 240)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              body: ColoredBox(
                color: colors.view,
                child: BusyMarkWysiwygToolbar(
                  onBlockCommand: (_) {},
                  onInlineCommand: (_) {},
                  onLinkCommand: () {},
                  onImageCommand: () {},
                  onInlineImageCommand: () {},
                  onTableCommand: () {},
                  onHtmlCommand: () {},
                  onIndentCommand: () {},
                  onOutdentCommand: () {},
                  onToggleTaskCommand: () {},
                  onHardBreakCommand: () {},
                  onCodeLanguageCommand: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final toolbar = find.byType(BusyMarkWysiwygToolbar);
      final popup = tester.widget<BusyMarkHeaderPopupMenuButton>(
        find.descendant(
          of: toolbar,
          matching: find.byWidgetPredicate(
            (widget) => widget is BusyMarkHeaderPopupMenuButton,
          ),
        ),
      );
      expect(popup.transparent, isFalse);
      expect(popup.elevated, isTrue);
      expect(popup.foregroundColor, BusyMarkLinuxPalette.white);
      expect(popup.backgroundColor?.resolve({}), accent);
      expect(
        popup.backgroundColor?.resolve({WidgetState.disabled}),
        colors.disabledControl,
      );

      final actions = tester.widgetList<BusyMarkHeaderIconButton>(
        find.descendant(
          of: toolbar,
          matching: find.byType(BusyMarkHeaderIconButton),
        ),
      );
      expect(actions, isNotEmpty);
      expect(actions.every((button) => !button.transparent), isTrue);
      expect(actions.every((button) => button.elevated), isTrue);
      expect(
        actions.every(
          (button) => button.foregroundColor == BusyMarkLinuxPalette.white,
        ),
        isTrue,
      );
      expect(
        actions.every(
          (button) => button.backgroundColor?.resolve({}) == accent,
        ),
        isTrue,
      );
      expect(
        actions.every(
          (button) =>
              button.backgroundColor?.resolve({WidgetState.disabled}) ==
              colors.disabledControl,
        ),
        isTrue,
      );

      final renderedButtons = tester.widgetList<IconButton>(
        find.descendant(of: toolbar, matching: find.byType(IconButton)),
      );
      expect(renderedButtons, isNotEmpty);
      final expectedElevation =
          theme.cardTheme.elevation ?? BusyMarkElevation.surface;
      for (final button in renderedButtons) {
        expect(button.style?.backgroundColor?.resolve({}), accent);
        expect(button.style?.elevation?.resolve({}), expectedElevation);
        expect(
          button.style?.shadowColor?.resolve({}),
          theme.colorScheme.shadow,
        );
        expect(
          button.style?.surfaceTintColor?.resolve({}),
          BusyMarkLinuxPalette.transparent,
        );
        expect(
          button.style?.foregroundColor?.resolve({}),
          BusyMarkLinuxPalette.white,
        );
        expect(
          button.style?.backgroundColor?.resolve({WidgetState.disabled}),
          colors.disabledControl,
        );
      }

      final actionButton = find.ancestor(
        of: find.byIcon(BusyMarkGlyphs.unorderedList),
        matching: find.byType(IconButton),
      );
      expect(actionButton, findsOneWidget);
      final buttonSize = tester.getSize(actionButton);
      expect(buttonSize, const Size.square(BusyMarkSizes.iconButton));
      final probe = Offset(5, buttonSize.height / 2);
      final restPixels = await _capturePixels(tester, boundaryKey);
      final rest = _pixelAtLocal(tester, restPixels, actionButton, probe);
      _expectColorNear(rest, accent);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(actionButton));
      await tester.pumpAndSettle();
      final hoverPixels = await _capturePixels(tester, boundaryKey);
      final hover = _pixelAtLocal(tester, hoverPixels, actionButton, probe);
      final expectedHover = Color.alphaBlend(
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
        accent,
      );
      _expectColorNear(hover, expectedHover);
      expect(hover, isNot(rest));
    });
  }

  testWidgets('dialog actions wrap at narrow localized text widths', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.light,
      accentColor: const Color(0xFFE95420),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: SizedBox(
                width: 320,
                height: 520,
                child: BusyMarkDialogShell(
                  title: 'Unsaved changes',
                  actions: [
                    BusyMarkDialogButton(
                      label: 'Keep editing',
                      onPressed: () {},
                    ),
                    BusyMarkDialogButton(
                      label: 'Discard changes',
                      destructive: true,
                      onPressed: () {},
                    ),
                    BusyMarkDialogButton(
                      label: 'Save changes',
                      suggested: true,
                      onPressed: () {},
                    ),
                  ],
                  children: const [Text('Choose how to continue.')],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(OverflowBar), findsOneWidget);
    final actionRows = {
      for (final label in ['Keep editing', 'Discard changes', 'Save changes'])
        tester.getCenter(find.text(label)).dy,
    };
    expect(actionRows.length, greaterThan(1));
  });

  testWidgets('disabled destructive rows use the disabled semantic color', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: const Color(0xFFE95420),
    );
    final colors = theme.extension<BusyMarkSurfaceColors>()!;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              BusyMarkActionRow(
                title: 'Enabled delete',
                destructive: true,
                onTap: () {},
              ),
              const BusyMarkActionRow(
                title: 'Disabled delete',
                destructive: true,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Enabled delete')).style?.color,
      theme.colorScheme.error,
    );
    expect(
      tester.widget<Text>(find.text('Disabled delete')).style?.color,
      colors.disabledForeground,
    );
  });

  testWidgets('shared text-entry group delegates fields to the framework', (
    tester,
  ) async {
    final first = TextEditingController();
    final second = TextEditingController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: const Color(0xFF3584E4),
        ),
        home: Scaffold(
          body: BusyMarkFloatingTextEntryGroup(
            children: [
              BusyMarkFloatingTextEntry(label: 'Name', controller: first),
              BusyMarkFloatingTextEntry(
                label: 'Description',
                controller: second,
                errorText: 'Required',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('semantic standard icon button delegates to FilledButton.icon', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildBusyMarkTheme(
          brightness: Brightness.light,
          accentColor: const Color(0xFF3584E4),
        ),
        home: Scaffold(
          body: BusyMarkPushButton.standardIcon(
            key: const ValueKey('semantic-standard-icon-button'),
            icon: const Icon(BusyMarkGlyphs.edit),
            label: const Text('Refactor'),
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('semantic-standard-icon-button'));
    expect(button, findsOneWidget);
    expect(find.descendant(of: button, matching: find.byType(Icon)), findsOne);
    expect(
      find.descendant(of: button, matching: find.text('Refactor')),
      findsOne,
    );

    await tester.tap(button);
    expect(pressed, isTrue);
  });

  testWidgets('sidebar surface owns one directional semantic boundary', (
    tester,
  ) async {
    final theme = buildBusyMarkTheme(
      brightness: Brightness.dark,
      accentColor: const Color(0xFF3584E4),
    );
    final colors = theme.extension<BusyMarkSurfaceColors>()!;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: BusyMarkSidebarSurface(child: SizedBox(width: 100)),
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(BusyMarkSidebarSurface),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, colors.sidebar);
    expect(
      (decoration.border! as BorderDirectional).end.color,
      colors.sidebarBorder,
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectSameGeometryWithSide(
  ShapeBorder? actual,
  ShapeBorder? base,
  BorderSide expectedSide,
) {
  expect(actual.runtimeType, base.runtimeType);
  expect(_shapeSide(actual), expectedSide);
  expect(
    _shapeWithSide(actual, BorderSide.none),
    _shapeWithSide(base, BorderSide.none),
  );
}

BorderSide? _shapeSide(ShapeBorder? shape) {
  return switch (shape) {
    final InputBorder input => input.borderSide,
    final OutlinedBorder outlined => outlined.side,
    _ => null,
  };
}

ShapeBorder? _shapeWithSide(ShapeBorder? shape, BorderSide side) {
  return switch (shape) {
    final InputBorder input => input.copyWith(borderSide: side),
    final OutlinedBorder outlined => outlined.copyWith(side: side),
    _ => shape,
  };
}

Future<_CapturedPixels> _capturePixels(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.binding.runAsync<ui.Image>(
    () => boundary.toImage(pixelRatio: 1),
  ))!;
  try {
    final data = (await tester.binding.runAsync<ByteData?>(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
    return _CapturedPixels(
      bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      width: image.width,
      boundary: boundary,
    );
  } finally {
    image.dispose();
  }
}

Color _pixelAtLocal(
  WidgetTester tester,
  _CapturedPixels pixels,
  Finder finder,
  Offset localOffset,
) {
  final box = tester.renderObject<RenderBox>(finder);
  final globalPoint = box.localToGlobal(localOffset);
  final point = pixels.boundary.globalToLocal(globalPoint);
  final x = point.dx.floor();
  final y = point.dy.floor();
  final offset = (y * pixels.width + x) * 4;
  return Color.fromARGB(
    pixels.bytes[offset + 3],
    pixels.bytes[offset],
    pixels.bytes[offset + 1],
    pixels.bytes[offset + 2],
  );
}

void _expectColorNear(Color actual, Color expected, {int tolerance = 4}) {
  expect(
    (actual.r * 255 - expected.r * 255).abs(),
    lessThanOrEqualTo(tolerance),
  );
  expect(
    (actual.g * 255 - expected.g * 255).abs(),
    lessThanOrEqualTo(tolerance),
  );
  expect(
    (actual.b * 255 - expected.b * 255).abs(),
    lessThanOrEqualTo(tolerance),
  );
  expect(
    (actual.a * 255 - expected.a * 255).abs(),
    lessThanOrEqualTo(tolerance),
  );
}

class _CapturedPixels {
  const _CapturedPixels({
    required this.bytes,
    required this.width,
    required this.boundary,
  });

  final Uint8List bytes;
  final int width;
  final RenderRepaintBoundary boundary;
}
