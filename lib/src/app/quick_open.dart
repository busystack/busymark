import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/domain/notes_search.dart';
import '../search/workspace_search_scope.dart';
import '../workspace/workspace_controller.dart';
import 'busymark_design.dart';
import 'busymark_dialogs.dart';
import 'localization.dart';

class QuickOpenDocument {
  const QuickOpenDocument({
    required this.title,
    required this.path,
    this.localId,
    this.filePath,
  });
  final String title, path;
  final String? localId, filePath;
  String get identity => localId ?? filePath!;
}

List<QuickOpenDocument> rankQuickOpen(
  List<QuickOpenDocument> documents,
  String query, {
  int limit = 100,
}) {
  final normalized = normalizeNotesSearch(query.trim());
  final ranked = <({QuickOpenDocument document, String title, int rank})>[];
  for (final document in documents) {
    final title = normalizeNotesSearch(document.title);
    final rank = normalized.isEmpty || title == normalized
        ? 0
        : title.startsWith(normalized)
        ? 1
        : title.contains(normalized)
        ? 2
        : normalizeNotesSearch(document.path).contains(normalized)
        ? 3
        : 4;
    if (rank < 4) ranked.add((document: document, title: title, rank: rank));
  }
  ranked.sort((a, b) {
    final rank = a.rank.compareTo(b.rank);
    if (rank != 0) return rank;
    final title = a.title.compareTo(b.title);
    if (title != 0) return title;
    final path = a.document.path.compareTo(b.document.path);
    return path != 0
        ? path
        : a.document.identity.compareTo(b.document.identity);
  });
  return ranked.take(limit).map((r) => r.document).toList();
}

Future<void> showQuickOpen(BuildContext context, WidgetRef ref) async {
  final workspace = ref.read(workspaceControllerProvider).workspace;
  if (workspace == null) return;
  final previous = FocusManager.instance.primaryFocus;
  final documents = <QuickOpenDocument>[];
  if (workspace.isRemote) {
    final repository = await ref.read(nextcloudNotesRepositoryProvider.future);
    documents.addAll(
      repository.notes
          .where(
            (n) =>
                n.accountId == workspace.nextcloudAccountId &&
                !isNotesRecovery(n),
          )
          .map(
            (n) => QuickOpenDocument(
              title: n.title,
              path: n.category,
              localId: n.localId,
            ),
          ),
    );
  } else {
    documents.addAll(
      workspace.files
          .where(isSearchableWorkspaceDocument)
          .map(
            (f) => QuickOpenDocument(
              title: p.basenameWithoutExtension(f.relativePath),
              path: f.relativePath,
              filePath: f.absolutePath,
            ),
          ),
    );
  }
  if (!context.mounted) return;
  final result = await showBusyMarkModalDialog<QuickOpenDocument>(
    context,
    builder: (_) => QuickOpenDialog(documents: documents),
  );
  if (!ref.context.mounted ||
      ref.read(workspaceControllerProvider).workspace?.id != workspace.id) {
    return;
  }
  if (result == null) {
    if (previous?.context?.mounted == true) previous!.requestFocus();
    return;
  }
  final controller = ref.read(workspaceControllerProvider.notifier);
  if (result.localId != null) {
    await controller.openNextcloudNote(result.localId!);
  } else {
    await controller.openActiveFile(result.filePath!);
  }
}

class QuickOpenDialog extends StatefulWidget {
  const QuickOpenDialog({super.key, required this.documents});
  final List<QuickOpenDocument> documents;
  @override
  State<QuickOpenDialog> createState() => _QuickOpenDialogState();
}

class _QuickOpenDialogState extends State<QuickOpenDialog> {
  late final FocusNode _focus = FocusNode(onKeyEvent: _key);
  final _scroll = ScrollController();
  List<QuickOpenDocument> _results = [];
  int _selected = 0, _generation = 0;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() => _loading = true);
    final documents = widget.documents;
    final results = await _rankQuickOpenAsync(documents, query);
    if (!mounted || generation != _generation) return;
    setState(() {
      _results = results;
      _selected = 0;
      _loading = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _open();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_results.isNotEmpty) {
        setState(
          () => _selected =
              (_selected +
                      (event.logicalKey == LogicalKeyboardKey.arrowDown
                          ? 1
                          : -1))
                  .clamp(0, _results.length - 1),
        );
        if (_scroll.hasClients) {
          _scroll.animateTo(
            (_selected * 64.0).clamp(0, _scroll.position.maxScrollExtent),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _open() {
    if (!_loading && _results.isNotEmpty) {
      Navigator.pop(context, _results[_selected]);
    }
  }

  @override
  void dispose() {
    _generation++;
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BusyMarkDialogShell(
    title: context.l10n.quickOpen,
    maxWidth: 640,
    children: [
      TextField(
        autofocus: true,
        focusNode: _focus,
        decoration: InputDecoration(labelText: context.l10n.quickOpen),
        onChanged: _search,
      ),
      if (_loading) const LinearProgressIndicator(),
      SizedBox(
        height: 340,
        child: _results.isEmpty
            ? Center(child: Text(context.l10n.noResults))
            : ListView.builder(
                controller: _scroll,
                itemCount: _results.length,
                itemExtent: 64,
                itemBuilder: (context, index) {
                  final document = _results[index];
                  return ListTile(
                    selected: index == _selected,
                    title: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      document.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, document),
                  );
                },
              ),
      ),
    ],
  );
}

Future<List<QuickOpenDocument>> _rankQuickOpenAsync(
  List<QuickOpenDocument> documents,
  String query,
) => Isolate.run(() => rankQuickOpen(documents, query));
