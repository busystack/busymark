import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

// Only real application mounting/lifetime sites may consume Git UI contracts.
// These are exact symbol identities, not a prefix/name exemption for wrappers.
const mounts = <String, Set<String>>{
  'src/workspace/workspace_tabs.dart': {'GitReviewTabs', 'GitReview'},
  'src/workspace/workspace_tab_actions.dart': {
    'GitReviewTabs',
    'GitDismissalRegistry',
  },
  'src/workspace/workspace_safety.dart': {'GitDismissalRegistry'},
  'src/workspace/presentation/workspace_screen.dart': {
    'GitSidebarView',
    'GitReviewTabs',
    'GitReview',
  },
  'src/app/busymark_app.dart': {
    'gitMayDismissMessageDrafts',
    'GitDraftStore',
    'GitReviewTabs',
    'GitDismissalRegistry',
    'GitSession',
    'GitHost',
  },
  'src/app/git_dismissal.dart': {
    'GitDismissalRegistry',
    'GitSession',
    'GitFlushableDraftStore',
    'GitHost',
  },
};
const presentationMounts = <String, Set<String>>{
  'src/app/busymark_app.dart': {'sharedGitReviewProvider', 'SharedGitReviews'},
  'src/workspace/workspace_tab_actions.dart': {
    'sharedGitReviewProvider',
    'SharedGitReviews',
  },
  'src/workspace/presentation/workspace_screen.dart': {
    'busyMarkGitSidebarMinimumWidth',
    'sharedGitReviewProvider',
    'SharedGitReviews',
    'BusyMarkGitWorkspaceScope',
    'BusyMarkSharedGitReview',
    'BusyMarkSharedGitSidebar',
    'showBusyMarkSharedGitAction',
    'busyMarkPresentGitTabMenu',
    'stageBusyMarkFiles',
    // Document-versus-disk recovery and Files VCS decoration are host duties.
    'GitDiffViewer',
    'busyMarkVcsFileColorForGitStatus',
    'busyMarkVcsFileColorForChangeStatus',
  },
};

bool isGitPresentationLibrary(String relative) =>
    relative.startsWith('src/git/presentation/') ||
    relative.startsWith('src/git/application/shared_git_');

class Boundary extends RecursiveAstVisitor<void> {
  Boundary(this.path);
  final String path;
  final errors = <String>[];
  void check(AstNode node, Element? element) {
    if (element == null) return;
    final uri = element.library?.uri.toString() ?? '';
    final declaration = element is FormalParameterElement
        ? element.enclosingElement
        : element;
    final owner = declaration is ConstructorElement
        ? declaration.enclosingElement
        : declaration;
    final enclosing = owner?.enclosingElement;
    final symbol = enclosing is InterfaceElement ? enclosing.name : owner?.name;
    final shared = uri.startsWith('package:busystack_git_flutter/');
    final adapter =
        uri.startsWith('package:busymark/src/git/application/shared_git_') ||
        uri.startsWith('package:busymark/src/git/presentation/');
    if (shared && !(mounts[path]?.contains(symbol) ?? false) ||
        adapter && !(presentationMounts[path]?.contains(symbol) ?? false)) {
      errors.add(
        '$path:${node.offset}: general presentation depends on $uri ($symbol)',
      );
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    check(node, node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    check(node, node.element);
    super.visitConstructorName(node);
  }
}

Future<List<String>> audit(Directory root, {List<File>? only}) async {
  // Scan every ordinary library. A wrapper/re-export cannot hide its import
  // in a helper file, and resolved identities survive prefixes and typedefs.
  final files =
      only ??
      Directory('${root.path}/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !isGitPresentationLibrary(
                  f.path.substring('${root.path}/lib/'.length),
                ) &&
                !f.path.contains('/l10n/generated/'),
          )
          .toList();
  final collection = AnalysisContextCollection(
    includedPaths: files.map((f) => f.absolute.path).toList(),
  );
  final errors = <String>[];
  try {
    for (final file in files) {
      final path = file.absolute.path;
      final result = await collection
          .contextFor(path)
          .currentSession
          .getResolvedUnit(path);
      if (result is! ResolvedUnitResult ||
          result.diagnostics.any(
            (d) => d.diagnosticCode.severity == DiagnosticSeverity.ERROR,
          )) {
        errors.add('Cannot resolve architecture input: $path');
        continue;
      }
      final relative = path.substring('${root.path}/lib/'.length);
      final visitor = Boundary(relative);
      result.unit.accept(visitor);
      errors.addAll(visitor.errors);
      // Imports and re-exports with no use must also fail. A selective show
      // list cannot authorize a generic primitive at a legitimate mount.
      for (final directive
          in result.unit.directives.whereType<UriBasedDirective>()) {
        final target = switch (directive) {
          ImportDirective() =>
            directive.libraryImport?.importedLibrary?.uri.toString(),
          ExportDirective() =>
            directive.libraryExport?.exportedLibrary?.uri.toString(),
          _ => null,
        };
        if (target?.startsWith('package:busystack_git_flutter/') == true &&
                !mounts.containsKey(relative) ||
            target ==
                    'package:busymark/src/git/application/shared_git_presentation.dart' &&
                !presentationMounts.containsKey(relative)) {
          errors.add(
            '$relative:${directive.offset}: unauthorized Git UI import/export',
          );
        }
      }
    }
  } finally {
    await collection.dispose();
  }
  return errors;
}

Future<void> main(List<String> args) async {
  final root = Directory(
    Directory.fromUri(Platform.script.resolve('../../../'))
        .resolveSymbolicLinksSync(),
  );
  if (args.contains('--self-test')) {
    // An engine/service helper cannot hide general UI simply by living under
    // src/git. Only the actual presentation boundary has that ownership.
    if (isGitPresentationLibrary('src/git/application/engine_helper.dart') ||
        isGitPresentationLibrary('src/git/renamed_wrapper.dart') ||
        !isGitPresentationLibrary(
          'src/git/application/shared_git_presentation.dart',
        ) ||
        !isGitPresentationLibrary(
          'src/git/presentation/git_diff_viewer.dart',
        )) {
      throw StateError('Git presentation boundary changed');
    }
    final folder = Directory('${root.path}/test/design_boundary_fixture');
    if (folder.existsSync()) {
      throw StateError('Fixture destination already exists');
    }
    folder.createSync();
    try {
      final fixtures = <String, String>{
        'direct': "import 'package:busystack_git_flutter/busystack_git_flutter.dart' as g; final bad = g.NativeFocusStyle.color;",
        'alias': "import 'package:busystack_git_flutter/busystack_git_flutter.dart' as g; typedef Renamed = g.NativeSidebarHeader;",
        'export': "export 'package:busystack_git_flutter/busystack_git_flutter.dart' show NativeFocusIndicator;",
        'helper': "import 'package:busystack_git_flutter/busystack_git_flutter.dart' as g; Object wrapper() => g.GitContextMenuKeys();",
        'indirect': "import 'helper.dart'; final hidden = wrapper;",
        'adapter': "import 'package:busymark/src/git/application/shared_git_presentation.dart' as g; const hidden = g.BusyMarkGitPresentation();",
        'good': "import 'package:busymark/src/app/busymark_design.dart'; const good = BusyMarkSidebarHeader(title: 'Files');",
      };
      final files = <String, File>{};
      for (final entry in fixtures.entries) {
        files[entry.key] = File('${folder.path}/${entry.key}.dart')
          ..writeAsStringSync(entry.value);
      }
      final errors = await audit(root, only: files.values.toList());
      for (final key in ['direct', 'alias', 'export', 'helper', 'adapter']) {
        if (!errors.any((e) => e.contains('/$key.dart:'))) {
          throw StateError('Violation escaped: $key');
        }
      }
      if (errors.any((e) => e.contains('/good.dart:'))) {
        throw StateError('BusyMark design rejected');
      }
      if (errors.any((e) => e.startsWith('Cannot resolve'))) {
        throw StateError('Adversarial fixture failed to resolve: $errors');
      }
      stdout.writeln('Design dependency adversarial fixtures passed.');
    } finally {
      folder.deleteSync(recursive: true);
    }
    return;
  }
  final errors = await audit(root);
  for (final error in errors) {
    stderr.writeln(error);
  }
  if (errors.isNotEmpty) {
    exitCode = 1;
  } else {
    stdout.writeln('BusyMark general design dependency boundary passed.');
  }
}
