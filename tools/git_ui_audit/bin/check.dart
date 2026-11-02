import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../../../../busystack_git_flutter/tool/check_native_presentation.dart'
    as shared;

// Only this mixed authoring/workspace file needs scope selection. Entire Git
// feature files are audited without exclusions by the shared resolved gate.
// The selectors use resolved enum symbols, not import spelling or text matches.
bool _gitConstant(AstNode node) {
  final visitor = _GitConstant();
  node.accept(visitor);
  return visitor.found;
}

class _GitConstant extends RecursiveAstVisitor<void> {
  bool found = false;
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    final owner = element?.enclosingElement?.name;
    if (owner == '_SidebarTab' &&
            const {'git', 'gitLog'}.contains(element?.name) ||
        owner == 'WorkspaceTabKind' && element?.name == 'gitDiff') {
      found = true;
    }
    super.visitSimpleIdentifier(node);
  }
}

bool _gitCondition(Expression expression) => switch (expression) {
  ParenthesizedExpression(:final expression) => _gitCondition(expression),
  BinaryExpression(:final leftOperand, :final operator, :final rightOperand) =>
    operator.lexeme == '=='
        ? _gitConstant(expression)
        : const {'&&', '||'}.contains(operator.lexeme) &&
              (_gitCondition(leftOperand) || _gitCondition(rightOperand)),
  _ => false,
};

class _GitScopes extends RecursiveAstVisitor<void> {
  final roots = <AstNode>[];
  final functions = <String>{};
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme.toLowerCase().contains('git')) {
      roots.add(node);
      functions.add(node.name.lexeme);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme.toLowerCase().contains('git')) roots.add(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitIfElement(IfElement node) {
    if (_gitCondition(node.expression)) roots.add(node.thenElement);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_gitCondition(node.expression)) roots.add(node.thenStatement);
    super.visitIfStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_gitCondition(node.condition)) roots.add(node.thenExpression);
    super.visitConditionalExpression(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (_gitConstant(node.guardedPattern)) roots.add(node.expression);
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    if (_gitConstant(node.expression)) roots.addAll(node.statements);
    super.visitSwitchCase(node);
  }
}

class _NativeReferences extends RecursiveAstVisitor<void> {
  final violations = <int, String>{};
  void check(AstNode node, Element? element, {bool construction = false}) {
    if (element == null) return;
    final library = element.library?.uri.toString() ?? '';
    final owner = element is ConstructorElement
        ? element.enclosingElement
        : element;
    final name = owner.name;
    final host = library.endsWith('/src/app/busymark_design.dart');
    if (host &&
        (const {
              'showBusyMarkMenu',
              'showBusyMarkContextMenu',
              'BusyMarkCompactIconButton',
            }.contains(name) ||
            element is ConstructorElement &&
                (name == 'BusyMarkMenuButton' ||
                    name == 'BusyMarkHeaderPopupMenuButton' &&
                        element.name != 'native'))) {
      violations[node.offset] = 'Git requires the native menu path: $name';
    }
    if (!library.startsWith('package:flutter/') && library != 'dart:ui') return;
    final materialWidget =
        library.startsWith('package:flutter/src/material/') &&
        owner is InterfaceElement &&
        owner.allSupertypes.any(
          (type) =>
              type.element.name == 'Widget' &&
              type.element.library.uri.toString() ==
                  'package:flutter/src/widgets/framework.dart',
        );
    if (construction && materialWidget ||
        shared.forbiddenMaterial.contains(name) &&
            element is! InterfaceElement ||
        const {'Colors', 'Icons'}.contains(name) ||
        construction && shared.forbiddenConstructors.contains(name)) {
      violations[node.offset] = 'Prohibited Git presentation: $name';
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    check(node, node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    check(node, node.constructorName.element, construction: true);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitConstructorReference(ConstructorReference node) {
    check(node, node.constructorName.element, construction: true);
    super.visitConstructorReference(node);
  }
}

Future<Map<int, String>> audit(File file, {bool production = false}) async {
  final path = file.resolveSymbolicLinksSync();
  final collection = AnalysisContextCollection(includedPaths: [path]);
  try {
    final unit = await collection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path);
    if (unit is! ResolvedUnitResult ||
        unit.diagnostics.any(
          (d) => d.diagnosticCode.severity == DiagnosticSeverity.ERROR,
        )) {
      throw StateError('Cannot resolve Git workspace source: $path');
    }
    final scopes = _GitScopes();
    unit.unit.accept(scopes);
    if (scopes.roots.isEmpty ||
        production &&
            !scopes.functions.containsAll({
              '_loadWorkspaceGitMenuItems',
              '_sidebarGitMenuItems',
              '_performWorkspaceGitAction',
            })) {
      throw StateError('Git workspace scopes moved; update the required audit');
    }
    final visitor = _NativeReferences();
    for (final root in scopes.roots) {
      root.accept(visitor);
    }
    return visitor.violations;
  } finally {
    await collection.dispose();
  }
}

Future<void> selfTest(Directory mark) async {
  final configFile = File(
    '${mark.parent.path}/busystack_git_flutter/.dart_tool/package_config.json',
  );
  final config = jsonDecode(configFile.readAsStringSync()) as Map;
  for (final package in config['packages'] as List) {
    package['rootUri'] = configFile.uri.resolve(package['rootUri']).toString();
  }
  final temp = Directory.systemTemp.createTempSync('git-workspace-audit-');
  try {
    Directory('${temp.path}/.dart_tool').createSync();
    File('${temp.path}/.dart_tool/package_config.json')
        .writeAsStringSync(jsonEncode(config));
    final design = File('${temp.path}/lib/src/app/busymark_design.dart');
    design.parent.createSync(recursive: true);
    design.writeAsStringSync('''
class BusyMarkHeaderPopupMenuButton {
  const BusyMarkHeaderPopupMenuButton();
  const BusyMarkHeaderPopupMenuButton.native();
}
void showBusyMarkContextMenu() {}
class BusyMarkCompactIconButton { const BusyMarkCompactIconButton(); }
''');
    final examples = <(String, bool)>[
      (
        "import 'lib/src/app/busymark_design.dart' as native; typedef Hidden = native.BusyMarkCompactIconButton; Object makeGit() => Hidden.new;",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; Object makeGit() => m.showDialog;",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; Object makeGit() => m.TextField();",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; typedef Hidden = m.FilledButton; Object makeGit() => Hidden.new;",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; Object makeGit() => m.Colors.purple;",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; enum _SidebarTab {git, files} Object mixed(_SidebarTab t) => t == _SidebarTab.git ? m.Checkbox(value:false,onChanged:(_){}) : m.Text('legacy');",
        false,
      ),
      (
        "import 'package:flutter/material.dart' as m; enum WorkspaceTabKind {gitDiff, file} Object mixed(WorkspaceTabKind t) { return switch(t) {WorkspaceTabKind.gitDiff => m.SearchBar(), _=>m.Text('legacy')}; }",
        false,
      ),
      (
        "import 'lib/src/app/busymark_design.dart' as native; void makeGit() => native.showBusyMarkContextMenu();",
        false,
      ),
      (
        "import 'lib/src/app/busymark_design.dart' as native; Object makeGit() => const native.BusyMarkHeaderPopupMenuButton();",
        false,
      ),
      (
        "import 'lib/src/app/busymark_design.dart' as native; Object makeGit() => const native.BusyMarkHeaderPopupMenuButton.native();",
        true,
      ),
      (
        "import 'package:flutter/material.dart' as m; enum _SidebarTab {git, files} Object mixed(_SidebarTab t) => t == _SidebarTab.git ? m.Text('native text') : m.TextField();",
        true,
      ),
    ];
    for (var i = 0; i < examples.length; i++) {
      final (source, allowed) = examples[i];
      final file = File('${temp.path}/case_$i.dart')..writeAsStringSync(source);
      if ((await audit(file)).isEmpty != allowed) {
        throw StateError('Workspace audit misclassified fixture $i');
      }
    }
    for (final source in [
      'void unrelated() {}',
      'Object makeGit() => Missing();',
    ]) {
      final file = File('${temp.path}/missing.dart')..writeAsStringSync(source);
      var rejected = false;
      try {
        await audit(file);
      } on StateError {
        rejected = true;
      }
      if (!rejected) {
        throw StateError('Empty/unresolved workspace audit passed');
      }
    }
    final adapterFile = File('${temp.path}/adapter.dart');
    for (final forbidden in [true, false]) {
      adapterFile.writeAsStringSync('''
import 'lib/src/app/busymark_design.dart' as native;
typedef Hidden = native.BusyMarkCompactIconButton;
class BusyMarkGitPresentation {
  Object iconAction() => Object();
  Object button() => ${forbidden ? 'Hidden.new' : 'Object()'};
  Object checkbox() => Object();
  Object changeRow() => Object();
}
''');
      final errors = await auditNativeAdapter(adapterFile);
      if (errors.isNotEmpty != forbidden) {
        throw StateError('Native adapter alias enforcement failed');
      }
    }
    stdout.writeln('Resolved workspace Git scope audit self-tests passed.');
  } finally {
    temp.deleteSync(recursive: true);
  }
}

Future<Map<int, String>> auditNativeAdapter(File file) async {
  final path = file.resolveSymbolicLinksSync();
  final collection = AnalysisContextCollection(includedPaths: [path]);
  try {
    final result = await collection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path);
    if (result is! ResolvedUnitResult ||
        result.diagnostics.any(
          (d) => d.diagnosticCode.severity == DiagnosticSeverity.ERROR,
        )) {
      throw StateError('Cannot resolve the native Git adapter');
    }
    final adapter = result.unit.declarations
        .whereType<ClassDeclaration>()
        .where((c) => c.namePart.typeName.lexeme == 'BusyMarkGitPresentation')
        .single;
    const requiredMethods = {'iconAction', 'button', 'checkbox', 'changeRow'};
    final methods = adapter.body.members
        .whereType<MethodDeclaration>()
        .where((m) => requiredMethods.contains(m.name.lexeme))
        .toList();
    if (methods.length != requiredMethods.length) {
      throw StateError(
        'Native Git control mappings moved; update the adapter audit',
      );
    }
    final visitor = _NativeReferences();
    for (final method in methods) {
      method.accept(visitor);
    }
    return visitor.violations;
  } finally {
    await collection.dispose();
  }
}

Future<void> main(List<String> args) async {
  final mark = Directory.fromUri(Platform.script.resolve('../../../'));
  if (args.contains('--self-test')) return selfTest(mark);
  final file = File(
    '${mark.path}/lib/src/workspace/presentation/workspace_screen.dart',
  );
  final violations = await audit(file, production: true);
  final adapter = File('${mark.path}/lib/src/app/busymark_design.dart');
  final adapterViolations = await auditNativeAdapter(adapter);
  for (final entry in adapterViolations.entries) {
    stderr.writeln('${adapter.path}:${entry.key}: ${entry.value}');
  }
  for (final entry in violations.entries) {
    stderr.writeln('${file.path}:${entry.key}: ${entry.value}');
  }
  if (violations.isNotEmpty || adapterViolations.isNotEmpty) {
    exitCode = 1;
  } else {
    stdout.writeln('Resolved workspace Git presentation boundary passed.');
  }
}
