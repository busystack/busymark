import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'd2_renderer.dart';
import 'visualization_coordinator.dart';
import 'web_render_host.dart';
import 'web_visualization_renderer.dart';

final webRenderHostProvider = Provider<WebRenderHost>(
  (ref) => const PlatformWebRenderHost(),
);

final visualizationCoordinatorProvider = Provider<VisualizationCoordinator>((
  ref,
) {
  final host = ref.watch(webRenderHostProvider);
  final coordinator = VisualizationCoordinator(
    renderers: [
      WebVisualizationRenderer(host: host),
      D2VisualizationRenderer(webRenderHost: host),
    ],
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
