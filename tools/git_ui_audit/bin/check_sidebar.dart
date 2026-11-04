import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../../../../busystack_git_flutter/tool/check_native_presentation.dart'
    as native;

String? constructed(InstanceCreationExpression node) =>
    node.constructorName.element?.enclosingElement.name;
Map<String, Expression> arguments(InstanceCreationExpression node) => {
  for (final argument
      in node.argumentList.arguments.whereType<NamedExpression>())
    argument.name.label.name: argument.expression,
};
String? enclosingClass(AstNode node) =>
    node.thisOrAncestorOfType<ClassDeclaration>()?.namePart.typeName.lexeme;

/// Resolve the real entry construction, including import prefixes and typedefs.
/// View-level actions and status/heading metadata remain legitimate controls.
class EntryAudit extends RecursiveAstVisitor<void> {
  EntryAudit({required this.treeMenus});
  final bool treeMenus;
  final errors = <String>[];
  final rows = <String, int>{};
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = constructed(node);
    final values = arguments(node);
    if (const {
          '_BusyMarkSidebarRecordRowState',
          'BusyMarkSidebarTreeRowState',
        }.contains(enclosingClass(node)) &&
        const {
          'BusyMarkMenuButton',
          'BusyMarkHeaderPopupMenuButton',
          'BusyMarkHeaderIconButton',
          'BusyMarkCompactIconButton',
          'GitIconButton',
          'GitMenuButton',
        }.contains(name)) {
      errors.add(
        '${node.offset}: automatic entry action trigger in row foundation',
      );
    }
    if (const {
      'BusyMarkSidebarTreeRow',
      'BusyMarkSidebarRecordRow',
      'GitChangeRow',
      'GitActionRow',
    }.contains(name)) {
      rows.update(name!, (n) => n + 1, ifAbsent: () => 1);
      final trailing = values['trailing'];
      if (trailing != null && trailing is! NullLiteral) {
        if (name.startsWith('BusyMarkSidebar')) {
          final actions = _ActionControls();
          trailing.accept(actions);
          if (actions.found) {
            errors.add('${node.offset}: entry action control in $name');
          }
        } else if ((name == 'GitChangeRow' || name == 'GitActionRow') &&
            !guardedTrailing(trailing)) {
          errors.add(
            '${node.offset}: Git entry actions lack the required native placement policy',
          );
        }
      }
      if (treeMenus &&
          name == 'BusyMarkSidebarTreeRow' &&
          (values['onMenuRequested'] == null ||
              values['onMenuRequested'] is NullLiteral)) {
        errors.add(
          '${node.offset}: sidebar tree lost its contextual action callback',
        );
      }
      if (values.containsKey('compactHierarchyIndent')) {
        errors.add(
          '${node.offset}: sidebar bypasses the Files disclosure geometry',
        );
      }
    }
    if (name == 'YaruListTile' &&
        enclosingClass(node) == '_BusyMarkSidebarRecordRowState') {
      errors.add(
        '${node.offset}: record row bypasses the approved native row surface',
      );
    }
    super.visitInstanceCreationExpression(node);
  }
}

class _ActionControls extends RecursiveAstVisitor<void> {
  bool found = false;
  static const metadata = {
    'Row',
    'Column',
    'Text',
    'Icon',
    'SizedBox',
    'Padding',
    'Align',
    'Flexible',
    'Expanded',
    'DefaultTextStyle',
    'TextSpan',
    'RichText',
  };
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!metadata.contains(constructed(node))) found = true;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final type = node.staticType;
    final element = node.element;
    if ((element is VariableElement || element is PropertyAccessorElement) &&
        type is InterfaceType &&
        (type.element.name == 'Widget' ||
            type.allSupertypes.any(
              (parent) => parent.element.name == 'Widget',
            ))) {
      found = true;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // No renderer factory or callback is accepted inside the metadata slot.
    final type = node.staticType?.getDisplayString() ?? '';
    if (type == 'Widget' || type == 'Widget?' || metadata.contains(type)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }
}

bool guardedTrailing(Expression expression) =>
    expression is ConditionalExpression &&
    (expression.elseExpression is NullLiteral &&
            policyCondition(expression.condition, 'trailing', '&&') ||
        expression.thenExpression is NullLiteral &&
            policyCondition(expression.condition, 'contextMenu', '||'));

bool policyCondition(Expression expression, String value, String connective) {
  if (expression is ParenthesizedExpression) {
    return policyCondition(expression.expression, value, connective);
  }
  if (expression is! BinaryExpression) return false;
  if (expression.operator.lexeme == connective) {
    return policyCondition(expression.leftOperand, value, connective) ||
        policyCondition(expression.rightOperand, value, connective);
  }
  if (expression.operator.lexeme != '==') return false;
  final reference = _PolicyValue(value);
  expression.rightOperand.accept(reference);
  final getter = _PlacementGetter();
  expression.leftOperand.accept(getter);
  return reference.found && getter.found;
}

class _PolicyValue extends RecursiveAstVisitor<void> {
  _PolicyValue(this.value);
  final String value;
  bool found = false;
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    found |=
        node.element?.enclosingElement?.name == 'GitEntryActionPlacement' &&
        node.element?.name == value;
    super.visitSimpleIdentifier(node);
  }
}

class _PlacementGetter extends RecursiveAstVisitor<void> {
  bool found = false;
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    found |= node.element?.name == 'entryActionPlacement';
    super.visitSimpleIdentifier(node);
  }
}

Future<ResolvedUnitResult> resolve(
  AnalysisContextCollection collection,
  String path,
) async {
  final result = await collection
      .contextFor(path)
      .currentSession
      .getResolvedUnit(path);
  if (result is! ResolvedUnitResult) {
    throw StateError('Cannot resolve sidebar source: $path');
  }
  final errors = result.diagnostics.where(
    (e) => e.diagnosticCode.severity == DiagnosticSeverity.ERROR,
  );
  if (errors.isNotEmpty) {
    throw StateError('Unresolved sidebar source: ${errors.join('; ')}');
  }
  return result;
}

Future<void> selfTest(Directory mark) async {
  final directory = Directory('${mark.path}/build/sidebar-audit-fixtures')
    ..createSync(recursive: true);
  final fixtures = <String, (String, bool)>{
    'native': (
      "native.BusyMarkSidebarTreeRow(title:'entry', depth:0, onTap:(){}, onMenuRequested:(_,__) {})",
      false,
    ),
    'metadata': (
      "native.BusyMarkSidebarTreeRow(title:'entry', depth:0, onMenuRequested:(_,__) {}, trailing: const Text('status'))",
      false,
    ),
    'aliased_action': (
      "native.BusyMarkSidebarTreeRow(title:'entry', depth:0, onMenuRequested:(_,__) {}, trailing: Action(tooltip:'bad', icon: nativeIcon, onPressed:(){}))",
      true,
    ),
    'missing_context': (
      "native.BusyMarkSidebarTreeRow(title:'entry', depth:0)",
      true,
    ),
    'git_action': (
      "git.GitChangeRow(title:'entry',depth:0,onTap:(){},onPointerDown:(_){},trailing:git.GitIconButton(tooltip:'bad',onPressed:(){},icon:const git.GitIcon(git.GitGlyph.add)))",
      true,
    ),
    'git_native_policy': (
      "git.GitChangeRow(title:'entry',depth:0,onTap:(){},onPointerDown:(_){},trailing: git.gitPresentation(context).entryActionPlacement == git.GitEntryActionPlacement.trailing ? git.GitIconButton(tooltip:'native action',onPressed:(){},icon:const git.GitIcon(git.GitGlyph.add)) : null)",
      false,
    ),
    'automatic_record_menu': (
      "native.BusyMarkMenuButton<int>.native(tooltip:'bad', items:<PopupMenuEntry<int>>[], triggerBuilder:(_,details)=>const Text('entry'), onSelected:(_){})",
      true,
    ),
  };
  final files = <File>[];
  try {
    for (final entry in fixtures.entries) {
      final file = File('${directory.path}/${entry.key}.dart');
      final declaration = entry.key == 'automatic_record_menu'
          ? 'class _BusyMarkSidebarRecordRowState extends StatelessWidget { @override Widget build(BuildContext context) => ${entry.value.$1}; }'
          : 'Widget probe(BuildContext context) => ${entry.value.$1};';
      file.writeAsStringSync(
        "import 'package:flutter/material.dart' show PopupMenuEntry; import 'package:flutter/widgets.dart'; import 'package:busymark/src/app/busymark_design.dart' as native; import 'package:busystack_git_flutter/busystack_git_flutter.dart' as git; typedef Action = native.BusyMarkCompactIconButton; const nativeIcon = IconData(1,fontFamily:'YaruIcons'); $declaration",
      );
      files.add(file);
    }
    final collection = AnalysisContextCollection(
      includedPaths: [directory.absolute.path],
    );
    try {
      for (final file in files) {
        final unit = await resolve(collection, file.absolute.path);
        final audit = EntryAudit(treeMenus: true);
        unit.unit.accept(audit);
        if (audit.errors.isNotEmpty !=
            fixtures[file.uri.pathSegments.last.replaceAll('.dart', '')]!.$2) {
          throw StateError(
            'Sidebar audit fixture failed: ${file.path}: ${audit.errors}',
          );
        }
      }
    } finally {
      await collection.dispose();
    }
  } finally {
    for (final file in files) {
      if (file.existsSync()) file.deleteSync();
    }
  }
  stdout.writeln(
    'Sidebar structure self-tests passed: aliases, native rows, metadata, contextual callbacks and host policy.',
  );
}

Future<void> main(List<String> args) async {
  final mark = args.contains('--root')
      ? Directory(
          Directory(args[args.indexOf('--root') + 1])
              .resolveSymbolicLinksSync(),
        )
      : Directory(
          Directory.fromUri(Platform.script.resolve('../../../'))
              .resolveSymbolicLinksSync(),
        );
  if (args.contains('--self-test')) return selfTest(mark);
  final shared = Directory('${mark.parent.path}/busystack_git_flutter');
  final design = '${mark.path}/lib/src/app/busymark_design.dart';
  final workspace =
      '${mark.path}/lib/src/workspace/presentation/workspace_screen.dart';
  final paths = [
    design,
    workspace,
    '${mark.path}/lib/src/local_history/local_history_panel.dart',
    '${mark.path}/lib/src/clipboard/clipboard_history_panel.dart',
    for (final file in ['commit_view', 'historical_change_tree', 'log_view'])
      '${shared.path}/lib/src/$file.dart',
  ];
  final errors = <String>[];
  final chain = await native.auditFirstPartyPresentationChain(design, [
    'BusyMarkSidebarTreeRow',
    'BusyMarkSidebarRecordRow',
    'BusyMarkSidebarRowSurface',
  ]);
  errors.addAll(chain.map((v) => '$v'));
  final collection = AnalysisContextCollection(includedPaths: paths);
  try {
    for (final path in paths) {
      final unit = await resolve(collection, path);
      final audit = EntryAudit(treeMenus: path == workspace);
      unit.unit.accept(audit);
      errors.addAll(audit.errors.map((e) => '$path:$e'));
      if (path == workspace && audit.rows['BusyMarkSidebarTreeRow'] != 3) {
        errors.add(
          '$path: Files, TOC and Outline must retain the shared tree row',
        );
      }
      for (final className in [
        '_BusyMarkSidebarRecordRowState',
        'BusyMarkSidebarTreeRowState',
      ]) {
        if (path != design) continue;
        final declaration = unit.unit.declarations
            .whereType<ClassDeclaration>()
            .singleWhere((c) => c.namePart.typeName.lexeme == className);
        final surface = _SurfaceReference();
        declaration.accept(surface);
        if (!surface.found) {
          errors.add('$className bypasses BusyMarkSidebarRowSurface');
        }
      }
    }
  } finally {
    await collection.dispose();
  }
  for (final error in errors) {
    stderr.writeln(error);
  }
  if (errors.isNotEmpty) {
    exitCode = 1;
  } else {
    stdout.writeln(
      'Resolved seven-sidebar presentation and contextual-action boundary passed.',
    );
  }
}

class _SurfaceReference extends RecursiveAstVisitor<void> {
  bool found = false;
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    found |= constructed(node) == 'BusyMarkSidebarRowSurface';
    super.visitInstanceCreationExpression(node);
  }
}
