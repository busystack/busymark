import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/source_span.dart';
import '../markdown/markdown_model.dart';
import '../markdown/markdown_parser.dart';
import '../nextcloud_notes/data/server_uri.dart';
import 'markdown_references.dart';

enum ReferenceResolution {
  resolved,
  missing,
  ambiguous,
  unavailable,
  unsupported,
}

String referenceRevision(String source) =>
    sha256.convert(utf8.encode(source)).toString();

class ReferenceDocument {
  const ReferenceDocument({
    required this.identity,
    required this.title,
    required this.source,
    this.path,
    this.localId,
    this.serverId,
    this.mode = MarkdownMode.commonMark,
    this.available = true,
  });
  final String identity, title, source;
  final String? path, localId;
  final int? serverId;
  final MarkdownMode mode;
  final bool available;
  String get revision => referenceRevision(source);
}

class ReferenceTarget {
  const ReferenceTarget(
    this.document, {
    this.anchor,
    this.label,
    this.span,
    this.moduleId,
    this.scopeSpan,
  });
  final ReferenceDocument document;
  final String? anchor, label, moduleId;
  final SourceSpan? span;
  final SourceSpan? scopeSpan;
  String get key => '${document.identity}#${anchor ?? ''}';
}

class IndexedReference {
  const IndexedReference({
    required this.source,
    required this.authored,
    required this.resolution,
    this.target,
  });
  final ReferenceDocument source;
  final AuthoredReference authored;
  final ReferenceResolution resolution;
  final ReferenceTarget? target;
  String get revision => source.revision;
}

class ReferencePage {
  const ReferencePage(this.values, this.total, this.nextOffset);
  final List<IndexedReference> values;
  final int total;
  final int? nextOffset;
}

class ParsedReferenceDocument {
  ParsedReferenceDocument(this.document)
    : headings = document.available
          ? const MarkdownParser()
                .parse(
                  filePath: document.identity,
                  source: document.source,
                  mode: document.mode,
                  validateLocalReferences: false,
                )
                .headings
          : const [],
      authored = document.available
          ? markdownReferences(
              identity: document.identity,
              source: document.source,
              mode: document.mode,
            )
          : const [];
  final ReferenceDocument document;
  final List<MarkdownHeading> headings;
  final List<AuthoredReference> authored;
}

/// Entirely derived; no writes to notes, source, history or synchronization.
class ReferenceIndex {
  ReferenceIndex({
    required List<ParsedReferenceDocument> parsed,
    this.root,
    this.server,
    Set<int> missingNoteIds = const {},
    Set<String> ownedPaths = const {},
    ReferenceIndex? previous,
  }) : missingNoteIds = Set.unmodifiable(missingNoteIds) {
    parsedDocuments = List.unmodifiable(parsed);
    documents = {
      for (final value in parsed) value.document.identity: value.document,
    };
    final paths = {
      for (final value in parsed)
        if (value.document.path != null)
          p.normalize(value.document.path!): value,
    };
    final ids = {
      for (final value in parsed)
        if (value.document.serverId != null) value.document.serverId!: value,
    };
    targets = [
      for (final value in parsed) ...[
        ReferenceTarget(value.document),
        for (final heading
            in ownedPaths.contains(value.document.path)
                ? <MarkdownHeading>[]
                : value.headings)
          ReferenceTarget(
            value.document,
            anchor: heading.id,
            label: heading.text,
            span: heading.span,
          ),
      ],
    ];
    references = [];
    final reusable =
        previous != null &&
        previous.root == root &&
        previous.server == server &&
        previous.missingNoteIds.length == missingNoteIds.length &&
        previous.missingNoteIds.every(missingNoteIds.contains) &&
        previous.documents.length == documents.length &&
        documents.entries.every((entry) {
          final old = previous.documents[entry.key];
          return old != null &&
              old.path == entry.value.path &&
              old.serverId == entry.value.serverId;
        });
    final owned = ownedPaths;
    final allTargetsUnchanged =
        reusable &&
        documents.entries.every(
          (entry) => identical(previous.documents[entry.key], entry.value),
        );
    for (final value in parsed) {
      if (owned.contains(value.document.path)) continue;
      if (reusable &&
          identical(
            previous.documents[value.document.identity],
            value.document,
          )) {
        final cached =
            previous._outgoing[value.document.identity] ??
            const <IndexedReference>[];
        if (cached.every(
          (r) =>
              (r.target == null &&
                  (allTargetsUnchanged ||
                      r.resolution == ReferenceResolution.unsupported)) ||
              (r.target != null &&
                  identical(
                    documents[r.target!.document.identity],
                    r.target!.document,
                  )),
        )) {
          references.addAll(cached);
          continue;
        }
      }
      for (final authored in value.authored) {
        var resolution = ReferenceResolution.unsupported;
        ReferenceTarget? target;
        final uri = Uri.tryParse(authored.destination);
        ParsedReferenceDocument? destination;
        if (server != null) {
          final noteId = nextcloudNoteId(server!, authored.destination);
          if (noteId != null) {
            if (missingNoteIds.contains(noteId)) {
              resolution = ReferenceResolution.missing;
            } else {
              destination = ids[noteId];
              resolution = ReferenceResolution.unavailable;
            }
          } else if (authored.destination.startsWith('#')) {
            destination = value;
          }
        } else if (uri != null &&
            !uri.hasScheme &&
            !uri.hasAuthority &&
            root != null) {
          try {
            final path = uri.path.isEmpty
                ? value.document.path
                : p.normalize(
                    p.join(
                      p.dirname(value.document.path!),
                      Uri.decodeComponent(uri.path),
                    ),
                  );
            if (path != null &&
                (p.equals(path, root!) || p.isWithin(root!, path))) {
              destination = paths[path];
              resolution =
                  destination == null &&
                      !const {
                        '.md',
                        '.markdown',
                      }.contains(p.extension(path).toLowerCase())
                  ? ReferenceResolution.unsupported
                  : ReferenceResolution.missing;
            }
          } on FormatException {
            /* malformed destinations remain unsupported */
          }
        }
        if (destination != null) {
          resolution = destination.document.available
              ? ReferenceResolution.resolved
              : ReferenceResolution.unavailable;
          final anchor = uri?.fragment;
          SourceSpan? span;
          if (anchor != null &&
              anchor.isNotEmpty &&
              destination.document.available) {
            final matches = destination.headings
                .where((h) => h.id == anchor)
                .toList();
            resolution = matches.isEmpty
                ? ReferenceResolution.missing
                : matches.length > 1
                ? ReferenceResolution.ambiguous
                : ReferenceResolution.resolved;
            span = matches.singleOrNull?.span;
          }
          target = ReferenceTarget(
            destination.document,
            anchor: anchor?.isEmpty == true ? null : anchor,
            span: span,
          );
        }
        references.add(
          IndexedReference(
            source: value.document,
            authored: authored,
            resolution: resolution,
            target: target,
          ),
        );
      }
    }
    rebuildLookups();
  }
  final String? root;
  final Uri? server;
  final Set<int> missingNoteIds;
  late final Map<String, ReferenceDocument> documents;
  late final List<ParsedReferenceDocument> parsedDocuments;
  late final List<ReferenceTarget> targets;
  late final List<IndexedReference> references;
  final _incoming = <String, List<IndexedReference>>{};
  final _outgoing = <String, List<IndexedReference>>{};
  final _headings = <String, List<ReferenceTarget>>{};

  /// Called by the format adapter before publishing a completed index.
  void rebuildLookups() {
    _incoming.clear();
    _outgoing.clear();
    _headings.clear();
    for (final target in targets.where((t) => t.anchor != null)) {
      _headings.putIfAbsent(target.document.identity, () => []).add(target);
    }
    for (final headings in _headings.values) {
      headings.sort(
        (a, b) =>
            (a.span?.startOffset ?? 0).compareTo(b.span?.startOffset ?? 0),
      );
    }
    for (final reference in references) {
      _outgoing.putIfAbsent(reference.source.identity, () => []).add(reference);
      final identity = reference.target?.document.identity;
      if (identity != null) {
        _incoming.putIfAbsent(identity, () => []).add(reference);
      }
    }
  }

  List<ReferenceTarget> headingsFor(String identity) =>
      List.unmodifiable(_headings[identity] ?? const []);

  ReferencePage query(
    String identity, {
    bool incoming = false,
    String? anchor,
    int offset = 0,
    int limit = 100,
  }) {
    if (offset < 0 || limit < 1 || limit > 100) {
      throw ArgumentError('Invalid reference page.');
    }
    final candidates =
        (incoming ? _incoming : _outgoing)[identity] ??
        const <IndexedReference>[];
    final values = anchor == null
        ? candidates
        : candidates
              .where(
                (r) => incoming
                    ? r.target?.document.identity == identity &&
                          r.target?.anchor == anchor
                    : r.source.identity == identity &&
                          _insideHeading(r, anchor),
              )
              .toList();
    return ReferencePage(
      List.unmodifiable(values.skip(offset).take(limit)),
      values.length,
      offset + limit < values.length ? offset + limit : null,
    );
  }

  bool _insideHeading(IndexedReference reference, String anchor) {
    final headings =
        (_headings[reference.source.identity] ?? const <ReferenceTarget>[])
            .where((t) => t.span != null)
            .toList();
    final selected = headings.where((h) => h.anchor == anchor).singleOrNull;
    if (selected == null) return false;
    final start = selected.span!.startOffset;
    if (selected.scopeSpan case final scope?) {
      return reference.authored.occurrence.startOffset >= scope.startOffset &&
          reference.authored.occurrence.startOffset < scope.endOffset;
    }
    final end =
        headings
            .where((h) => h.span!.startOffset > start)
            .firstOrNull
            ?.span
            ?.startOffset ??
        reference.source.source.length;
    return reference.authored.occurrence.startOffset >= start &&
        reference.authored.occurrence.startOffset < end;
  }
}
