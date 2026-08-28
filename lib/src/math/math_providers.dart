import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../visualization/visualization_providers.dart';
import 'math_coordinator.dart';
import 'math_renderer.dart';

final mathCoordinatorProvider = Provider<MathCoordinator>((ref) {
  final coordinator = MathCoordinator(
    renderer: MathRenderer(host: ref.watch(webRenderHostProvider)),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
