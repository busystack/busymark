import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_history/local_history_controller.dart';
import 'workspace_controller.dart';

/// Reveal a successfully opened document using the same view transition as
/// selecting its editor tab. Resource validation and opening happen first.
void revealOpenedDocument(WidgetRef ref) {
  final history = ref.read(localHistoryControllerProvider.notifier);
  history.clearComparison();
  final buffer = ref.read(workspaceControllerProvider).activeBuffer;
  if (buffer != null) unawaited(history.selectDocumentForBuffer(buffer));
}
