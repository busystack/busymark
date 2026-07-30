import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:busymark/src/app/app_theme.dart';
import 'package:busymark/src/app/busymark_design.dart';
import 'package:busymark/src/app/busymark_glyphs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final baseline in const [
    _SurfaceBaseline(
      brightness: Brightness.light,
      view: Color(0xFFFFFFFF),
      window: Color(0xFFFAFAFA),
      dialog: Color(0xFFFAFAFA),
      sidebar: Color(0xFFEBEBEB),
      card: Color(0xFFFFFFFF),
      popover: Color(0xFFFAFAFA),
      dialogOutline: Color.fromRGBO(255, 255, 255, 0.07),
      floatingBorder: Color.fromRGBO(0, 0, 0, 0.14),
    ),
    _SurfaceBaseline(
      brightness: Brightness.dark,
      view: Color(0xFF272727),
      window: Color(0xFF2C2C2C),
      dialog: Color(0xFF3E3E3E),
      sidebar: Color(0xFF393939),
      card: Color(0xFF3D3D3D),
      popover: Color(0xFF3E3E3E),
      dialogOutline: Color.fromRGBO(255, 255, 255, 0.07),
      floatingBorder: Color.fromRGBO(0, 0, 0, 0.14),
    ),
  ]) {
    testWidgets(
      'renders the reviewed ${baseline.brightness.name} surface palette',
      (tester) async {
        tester.view
          ..physicalSize = const Size(800, 600)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final boundaryKey = GlobalKey();
        final viewProbe = GlobalKey();
        final windowProbe = GlobalKey();
        final sidebarProbe = GlobalKey();
        final dialogProbe = GlobalKey();
        final cardProbe = GlobalKey();
        final popupButtonKey = GlobalKey();
        final popoverProbe = GlobalKey();
        final theme = buildBusyMarkTheme(
          brightness: baseline.brightness,
          accentColor: const Color(0xFFE95464),
        );

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) {
                  final colors = BusyMarkSurfaceColors.of(context);
                  return Scaffold(
                    backgroundColor: colors.window,
                    body: Stack(
                      children: [
                        Positioned(
                          left: 120,
                          top: 0,
                          right: 0,
                          bottom: 80,
                          child: ColoredBox(
                            color: colors.view,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: SizedBox.square(
                                  key: viewProbe,
                                  dimension: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 80,
                          width: 120,
                          child: BusyMarkSidebarSurface(
                            child: Center(
                              child: SizedBox.square(
                                key: sidebarProbe,
                                dimension: 16,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SizedBox.square(
                              key: windowProbe,
                              dimension: 16,
                            ),
                          ),
                        ),
                        BusyMarkDialogShell(
                          title: 'Palette',
                          maxWidth: 320,
                          children: [
                            Center(
                              child: SizedBox.square(
                                key: dialogProbe,
                                dimension: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            BusyMarkGroupedSurface(
                              child: SizedBox(
                                key: cardProbe,
                                width: 180,
                                height: 72,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 24,
                          bottom: 24,
                          child: PopupMenuButton<int>(
                            key: popupButtonKey,
                            tooltip: 'Open palette probe',
                            itemBuilder: (context) => [
                              PopupMenuItem<int>(
                                enabled: false,
                                value: 1,
                                child: SizedBox(
                                  key: popoverProbe,
                                  width: 96,
                                  height: 24,
                                ),
                              ),
                            ],
                            child: const SizedBox.square(
                              dimension: 32,
                              child: Icon(BusyMarkGlyphs.menuVertical),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        final dialogMaterial = find.ancestor(
          of: find.byKey(dialogProbe),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Material && widget.shape == theme.dialogTheme.shape,
          ),
        );
        expect(dialogMaterial, findsOneWidget);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(popupButtonKey));
        await tester.pumpAndSettle();
        expect(find.byKey(popoverProbe), findsOneWidget);
        final popupMaterial = find.ancestor(
          of: find.byKey(popoverProbe),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Material &&
                widget.shape == theme.popupMenuTheme.shape,
          ),
        );
        expect(popupMaterial, findsOneWidget);

        final pixels = await _capturePixels(tester, boundaryKey);
        expect(_pixelAtProbe(tester, pixels, viewProbe), baseline.view);
        expect(_pixelAtProbe(tester, pixels, windowProbe), baseline.window);
        expect(_pixelAtProbe(tester, pixels, sidebarProbe), baseline.sidebar);
        expect(_pixelAtProbe(tester, pixels, dialogProbe), baseline.dialog);
        expect(_pixelAtProbe(tester, pixels, cardProbe), baseline.card);
        expect(_pixelAtProbe(tester, pixels, popoverProbe), baseline.popover);
        final dialogSize = tester.getSize(dialogMaterial);
        final dialogEdge = _pixelAtLocal(
          tester,
          pixels,
          dialogMaterial,
          Offset(0.5, dialogSize.height / 2),
        );
        final expectedDialogEdge = Color.alphaBlend(
          baseline.dialogOutline,
          baseline.dialog,
        );
        _expectColorNear(dialogEdge, expectedDialogEdge, tolerance: 3);
        final popupSize = tester.getSize(popupMaterial);
        final popupEdge = _pixelAtLocal(
          tester,
          pixels,
          popupMaterial,
          Offset(0.5, popupSize.height / 2),
        );
        final expectedEdge = Color.alphaBlend(
          baseline.floatingBorder,
          baseline.popover,
        );
        _expectColorNear(popupEdge, expectedEdge, tolerance: 3);
        expect(
          popupEdge.computeLuminance(),
          lessThan(baseline.popover.computeLuminance()),
        );
      },
    );
  }
}

class _SurfaceBaseline {
  const _SurfaceBaseline({
    required this.brightness,
    required this.view,
    required this.window,
    required this.dialog,
    required this.sidebar,
    required this.card,
    required this.popover,
    required this.dialogOutline,
    required this.floatingBorder,
  });

  final Brightness brightness;
  final Color view;
  final Color window;
  final Color dialog;
  final Color sidebar;
  final Color card;
  final Color popover;
  final Color dialogOutline;
  final Color floatingBorder;
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

Color _pixelAtProbe(
  WidgetTester tester,
  _CapturedPixels pixels,
  GlobalKey probeKey,
) {
  final globalCenter = tester.getCenter(find.byKey(probeKey));
  final localCenter = pixels.boundary.globalToLocal(globalCenter);
  final x = localCenter.dx.round();
  final y = localCenter.dy.round();
  final offset = (y * pixels.width + x) * 4;
  return Color.fromARGB(
    pixels.bytes[offset + 3],
    pixels.bytes[offset],
    pixels.bytes[offset + 1],
    pixels.bytes[offset + 2],
  );
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

void _expectColorNear(Color actual, Color expected, {required int tolerance}) {
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
