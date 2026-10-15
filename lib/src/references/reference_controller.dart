import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../nextcloud_notes/application/nextcloud_connection.dart';
import '../nextcloud_notes/application/notes_navigation.dart';
import '../nextcloud_notes/domain/notes_models.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_model.dart';
import '../markdown/markdown_model.dart';
import 'reference_index.dart';
import 'writerside_reference_adapter.dart';

final referenceIndexProvider =
    NotifierProvider<ReferenceController, AsyncValue<ReferenceIndex>>(
      ReferenceController.new,
    );

typedef ReferenceBatchParser =
    Future<List<ParsedReferenceDocument>> Function(
      List<ReferenceDocument> documents,
    );
final referenceBatchParserProvider = Provider<ReferenceBatchParser>(
  (ref) => parseReferenceBatch,
);

/// Coalesces edits and filesystem/repository notifications outside widget builds.
/// Content digests retain unchanged parsing; generations fence obsolete results.
class ReferenceController extends Notifier<AsyncValue<ReferenceIndex>> {
  Timer? _timer;
  StreamSubscription<void>? _notes;
  int _generation = 0;
  final _cache = <String, ParsedReferenceDocument>{};
  @override
  AsyncValue<ReferenceIndex> build() {
    ref.listen(workspaceControllerProvider, (before, after) => refresh());
    ref.listen(nextcloudNotesRepositoryProvider, (before, after) {
      _notes?.cancel();
      _notes = after.value?.changes.listen((_) => refresh());
      refresh();
    }, fireImmediately: true);
    ref.onDispose(() {
      _generation++;
      _timer?.cancel();
      _notes?.cancel();
    });
    refresh();
    return const AsyncLoading();
  }

  void refresh() {
    final generation = ++_generation;
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 200),
      () => _rebuild(generation),
    );
  }

  Future<void> _rebuild(int generation) async {
    try {
      final snapshot = ref.read(workspaceControllerProvider);
      final workspace = snapshot.workspace;
      if (workspace == null) {
        if (generation == _generation && ref.mounted) {
          _cache.clear();
          state = AsyncData(ReferenceIndex(parsed: const []));
        }
        return;
      }
      final documents = <ReferenceDocument>[];
      Uri? server;
      final missingNoteIds = <int>{};
      String? root;
      if (workspace.isRemote) {
        final repository = await ref.read(
          nextcloudNotesRepositoryProvider.future,
        );
        server = repository.accountById(workspace.nextcloudAccountId!)?.server;
        missingNoteIds.addAll(
          repository.notes
              .where(
                (n) =>
                    n.accountId == workspace.nextcloudAccountId &&
                    n.syncState == NoteSyncState.deletedRemotely &&
                    n.serverId != null,
              )
              .map((n) => n.serverId!),
        );
        for (final note in repository.notes.where(
          (n) =>
              n.accountId == workspace.nextcloudAccountId &&
              !isNotesRecovery(n),
        )) {
          final buffer = snapshot.documentBuffers
              .where((b) => b.remoteNote?.localId == note.localId)
              .firstOrNull;
          documents.add(
            ReferenceDocument(
              identity: note.localId,
              title: note.title,
              source: buffer?.text ?? note.content,
              localId: note.localId,
              serverId: note.serverId,
              available: !note.error,
            ),
          );
        }
      } else {
        root = workspace.filesystemRootPath;
        for (final file in workspace.files.where(
          (f) => {
            DocumentKind.markdown,
            DocumentKind.writersideMarkdownTopic,
            DocumentKind.writersideXmlTopic,
          }.contains(f.kind),
        )) {
          if (generation != _generation || !ref.mounted) return;
          final buffer = snapshot.documentBuffers
              .where((b) => b.filePath == file.absolutePath)
              .firstOrNull;
          var source = buffer?.text;
          var available = true;
          if (source == null) {
            try {
              final disk = File(file.absolutePath);
              final canonical = await disk.resolveSymbolicLinks();
              final canonicalRoot = await Directory(
                root!,
              ).resolveSymbolicLinks();
              if (!p.isWithin(canonicalRoot, canonical) ||
                  !p.equals(canonical, file.absolutePath) ||
                  (await disk.stat()).size > 2 * 1024 * 1024) {
                throw const FileSystemException(
                  'Unavailable reference source.',
                );
              }
              source = await disk.readAsString();
            } on Object {
              available = false;
              source = '';
            }
          }
          documents.add(
            ReferenceDocument(
              identity: file.absolutePath,
              path: file.absolutePath,
              title: p.basenameWithoutExtension(file.relativePath),
              source: source,
              available: available,
              mode: file.kind == DocumentKind.writersideMarkdownTopic
                  ? MarkdownMode.writersideMarkdown
                  : MarkdownMode.commonMark,
            ),
          );
        }
      }
      final parsed = <ParsedReferenceDocument>[];
      final changed = <ReferenceDocument>[];
      for (final document in documents) {
        final cached = _cache[document.identity];
        if (cached?.document.revision == document.revision &&
            cached?.document.available == document.available &&
            cached?.document.title == document.title &&
            cached?.document.mode == document.mode &&
            cached?.document.serverId == document.serverId) {
          parsed.add(cached!);
        } else {
          changed.add(document);
        }
      }
      // A worker transfer is limited to 16 documents, never the entire corpus.
      for (var offset = 0; offset < changed.length; offset += 16) {
        final batch = changed.skip(offset).take(16).toList();
        final values = await ref.read(referenceBatchParserProvider)(batch);
        if (generation != _generation || !ref.mounted) return;
        parsed.addAll(values);
        // Keep completed, current batches when a later edit supersedes the
        // rebuild. Their revisions are checked before reuse on the next pass.
        _cache.addEntries(values.map((d) => MapEntry(d.document.identity, d)));
      }
      final writerside = workspace.writersideProject == null
          ? null
          : await ref
                .read(workspaceControllerProvider.notifier)
                .writersideEditorIndex();
      if (generation != _generation || !ref.mounted) return;
      _cache
        ..clear()
        ..addEntries(parsed.map((d) => MapEntry(d.document.identity, d)));
      final index = ReferenceIndex(
        parsed: parsed,
        root: root,
        server: server,
        missingNoteIds: missingNoteIds,
        previous: state.value,
        ownedPaths:
            writerside?.modulesById.values
                .expand((m) => m.topics)
                .map((t) => t.filePath)
                .toSet() ??
            const {},
      );
      if (writerside != null) {
        addWritersideReferences(
          index,
          writerside,
          workspace.writersideProject?.activeInstanceId,
        );
      }
      state = AsyncData(index);
    } on Object catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }
}

final referencePanelRequestProvider =
    NotifierProvider<ReferencePanelRequest, int>(ReferencePanelRequest.new);

class ReferencePanelRequest extends Notifier<int> {
  @override
  int build() => 0;
  void request() => state++;
}

Future<List<ParsedReferenceDocument>> parseReferenceBatch(
  List<ReferenceDocument> documents,
) => Isolate.run(() => documents.map(ParsedReferenceDocument.new).toList());

typedef ReferenceQuery = ({
  String identity,
  bool incoming,
  String? anchor,
  int count,
});

class ReferencePanelResults {
  const ReferencePanelResults(this.headings, this.references, this.total);
  final List<ReferenceTarget> headings;
  final List<IndexedReference> references;
  final int total;
}

// Cached queries keep corpus traversal out of widget builds.
final referencePanelResultsProvider = Provider.autoDispose
    .family<AsyncValue<ReferencePanelResults>, ReferenceQuery>((ref, query) {
      return ref.watch(referenceIndexProvider).whenData((index) {
        final values = <IndexedReference>[];
        var total = 0;
        for (var offset = 0; offset < query.count; offset += 100) {
          final page = index.query(
            query.identity,
            incoming: query.incoming,
            anchor: query.anchor,
            offset: offset,
          );
          values.addAll(page.values);
          total = page.total;
          if (page.nextOffset == null) break;
        }
        final headings = <String, ReferenceTarget>{
          for (final heading in index.headingsFor(query.identity))
            heading.anchor!: heading,
        }.values.toList();
        return ReferencePanelResults(
          headings,
          List.unmodifiable(values),
          total,
        );
      });
    });

typedef ReferenceTargetQuery = ({String text, int count});
final referenceTargetResultsProvider = Provider.autoDispose
    .family<
      AsyncValue<({List<ReferenceTarget> values, int total})>,
      ReferenceTargetQuery
    >((ref, query) {
      return ref.watch(referenceIndexProvider).whenData((index) {
        final values = <ReferenceTarget>[];
        var total = 0;
        for (final target in index.targets) {
          if (!'${target.document.title} ${target.label ?? ''} ${target.document.path ?? ''} ${target.moduleId ?? ''}'
              .toLowerCase()
              .contains(query.text)) {
            continue;
          }
          total++;
          if (values.length < query.count) values.add(target);
        }
        return (
          values: List<ReferenceTarget>.unmodifiable(values),
          total: total,
        );
      });
    });
