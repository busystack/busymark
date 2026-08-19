import 'dart:math' as math;

import 'visualization_models.dart';

class VisualizationRasterSize {
  const VisualizationRasterSize({
    required this.scale,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final double scale;
  final int pixelWidth;
  final int pixelHeight;
}

/// Selects raster dimensions that fit the limits enforced by the WebKit host.
///
/// WebKit calculates each pixel dimension with `ceil`, so the returned pixel
/// dimensions use the same operation instead of deriving metadata with
/// `round`.
class VisualizationRasterSizingPolicy {
  const VisualizationRasterSizingPolicy({
    this.previewScale = 2,
    this.pdfScale = 3,
    this.maximumDimension = 8192,
    this.maximumPixels = 64000000,
  });

  final double previewScale;
  final double pdfScale;
  final int maximumDimension;
  final int maximumPixels;

  VisualizationRasterSize fit({
    required double width,
    required double height,
    required VisualizationRenderProfile profile,
  }) {
    if (!width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        maximumDimension < 1 ||
        maximumPixels < 1) {
      throw ArgumentError('Raster dimensions and limits must be positive.');
    }
    final preferredScale = switch (profile) {
      VisualizationRenderProfile.preview => previewScale,
      VisualizationRenderProfile.pdf => pdfScale,
    };
    if (!preferredScale.isFinite || preferredScale <= 0) {
      throw ArgumentError.value(
        preferredScale,
        'preferredScale',
        'Raster scale must be positive.',
      );
    }

    var scale = math.min(preferredScale, maximumDimension / width);
    scale = math.min(scale, maximumDimension / height);
    scale = math.min(scale, math.sqrt(maximumPixels / (width * height)));
    var size = _atScale(width, height, scale);
    if (!_fits(size)) {
      // Independent ceil operations can put an otherwise valid continuous
      // area calculation a few pixels over the integer-area limit. Find the
      // greatest representable safe scale below the calculated upper bound.
      var safeScale = 0.0;
      var unsafeScale = scale;
      for (var iteration = 0; iteration < 80; iteration += 1) {
        final candidate = (safeScale + unsafeScale) / 2;
        final candidateSize = _atScale(width, height, candidate);
        if (_fits(candidateSize)) {
          safeScale = candidate;
        } else {
          unsafeScale = candidate;
        }
      }
      scale = safeScale;
      size = _atScale(width, height, scale);
    }
    if (scale <= 0 || !_fits(size)) {
      throw StateError('No valid WebKit raster size is available.');
    }
    return VisualizationRasterSize(
      scale: scale,
      pixelWidth: size.width,
      pixelHeight: size.height,
    );
  }

  ({int width, int height}) _atScale(
    double width,
    double height,
    double scale,
  ) {
    return (
      width: math.max(1, (width * scale).ceil()),
      height: math.max(1, (height * scale).ceil()),
    );
  }

  bool _fits(({int width, int height}) size) {
    return size.width <= maximumDimension &&
        size.height <= maximumDimension &&
        size.width * size.height <= maximumPixels;
  }
}
