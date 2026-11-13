import '../workspace/document_buffer.dart';
import '../workspace/workspace_model.dart';
import 'app_settings.dart';

/// Reuse the renderer's document capabilities for menu and command availability.
bool busyMarkDocumentViewAvailable(
  Workspace? workspace,
  DocumentBuffer? buffer,
  DocumentViewModePreference mode,
) =>
    workspace != null &&
    buffer != null &&
    (mode == DocumentViewModePreference.source ||
        resolveWorkspaceDocumentContext(
          workspace,
          buffer,
        ).kind.supportsVisualEditing);
