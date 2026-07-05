import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

import '../app/app_settings.dart';
import '../app/busymark_glyphs.dart';
import 'workspace_model.dart';

abstract final class WorkspaceGlyphs {
  const WorkspaceGlyphs._();

  static IconData forKind(WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown ||
      WorkspaceKind.singleMarkdown => BusyMarkGlyphs.markdownFile,
      WorkspaceKind.markdownFolder => BusyMarkGlyphs.folder,
      WorkspaceKind.writersideModule => BusyMarkGlyphs.writersideProject,
    };
  }

  static IconData forRecent(RecentWorkspace recent) {
    return forKindName(recent.kind, fallbackPath: recent.path);
  }

  static IconData pathForKind(WorkspaceKind kind) {
    return switch (kind) {
      WorkspaceKind.untitledMarkdown ||
      WorkspaceKind.singleMarkdown => BusyMarkGlyphs.markdownFile,
      WorkspaceKind.markdownFolder ||
      WorkspaceKind.writersideModule => BusyMarkGlyphs.folder,
    };
  }

  static IconData get branch => BusyMarkGlyphs.branch;

  static IconData forKindName(String kind, {required String fallbackPath}) {
    return switch (kind) {
      'singleMarkdown' || 'untitledMarkdown' => BusyMarkGlyphs.markdownFile,
      'markdownFolder' => BusyMarkGlyphs.folder,
      'writersideModule' => BusyMarkGlyphs.writersideProject,
      _ => forPath(fallbackPath),
    };
  }

  static IconData forPath(String path) {
    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.md' || '.markdown' => BusyMarkGlyphs.markdownFile,
      _ => BusyMarkGlyphs.folder,
    };
  }
}
