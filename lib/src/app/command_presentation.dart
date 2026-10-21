import 'package:flutter/widgets.dart';

import 'command_registry.dart';

/// Preserve the reference's category order, then include its previously omitted
/// unbound categories. Overrides never change the grouping order.
List<String> commandCategoryOrder(BuildContext context) {
  final commands = BusyMarkCommandCatalog.metadata.commands;
  return {
    for (final c in commands)
      if (c.shortcut != null && c.scope != BusyMarkCommandScope.sourceSymbol)
        c.category(context),
    for (final c in commands) c.category(context),
  }.toList(growable: false);
}

int? commandMatchRank({
  required String name,
  required String category,
  String? description,
  required String id,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;
  final title = name.toLowerCase();
  if (title == q) return 0;
  if (title.startsWith(q)) return 1;
  final tokens = q.split(RegExp(r'\s+'));
  final words = title.split(RegExp(r'[\s\p{P}]+', unicode: true));
  if (tokens.every((t) => words.any((w) => w.startsWith(t)))) return 2;
  if (title.contains(q)) return 3;
  final text =
      '$title ${category.toLowerCase()} ${description?.toLowerCase() ?? ''}';
  if (tokens.every(text.contains)) return 4;
  return id.toLowerCase().contains(q) ? 5 : null;
}
