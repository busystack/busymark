import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/atomic_file_writer.dart';
import '../markdown/busymark_document.dart';
import '../markdown/markdown_parser.dart';
import 'writerside_document.dart';
import 'writerside_model.dart';
import 'writerside_parsers.dart';

final writersideTemplateServiceProvider = Provider(
  (ref) => WritersideTemplateService(),
);

/// One source variant, not a generated topic. The default collection groups
/// Markdown/XML variants by name; custom templates retain their own identity.
class WritersideTemplate {
  const WritersideTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.extension,
    required this.source,
    this.url,
    this.description,
  });
  final String id;
  final String name;
  final String category;
  final String extension;
  final String source;
  final String? url;
  final String? description;
  WritersideTopicFormat get format => extension == 'topic'
      ? WritersideTopicFormat.xml
      : WritersideTopicFormat.markdown;
  String get groupKey => category == 'default' ? '$category:$name' : id;
  WritersideTemplate copyWith({
    String? name,
    String? extension,
    String? source,
  }) => WritersideTemplate(
    id: id,
    name: name ?? this.name,
    category: category,
    extension: extension ?? this.extension,
    source: source ?? this.source,
    url: url,
    description: description,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'extension': extension,
    'source': source,
    if (url != null) 'url': url,
    if (description != null) 'description': description,
  };
  factory WritersideTemplate.fromJson(Map<String, dynamic> data) {
    final result = WritersideTemplate(
      id: data['id'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      extension: data['extension'] as String,
      source: data['source'] as String,
      url: data['url'] as String?,
      description: data['description'] as String?,
    );
    if (result.id.isEmpty ||
        result.name.trim().isEmpty ||
        !['md', 'topic'].contains(result.extension) ||
        !['default', 'custom', 'tgdp'].contains(result.category)) {
      throw const FormatException('Invalid Writerside template record');
    }
    return result;
  }
}

class WritersideTemplateSnapshot {
  const WritersideTemplateSnapshot(this.entries, this.revision);
  final List<WritersideTemplate> entries;
  final String? revision;
}

class WritersideTemplateConflict implements Exception {
  const WritersideTemplateConflict();
}

/// User-approved application-support integration. The project is never used as
/// a template database. Reads do not create a store, and a corrupt/stale store
/// cannot be silently replaced. Publication is atomic and serialized across
/// services in this isolate and cooperating application processes.
class WritersideTemplateService {
  WritersideTemplateService({this.storagePath, this.loadBundledSource});
  final String? storagePath;
  final Future<String> Function()? loadBundledSource;
  Future<List<WritersideTemplate>>? _bundled;
  static final _writes = <String, Future<void>>{};

  Future<List<WritersideTemplate>> bundled() => _bundled ??= () async {
    final source =
        await (loadBundledSource?.call() ??
            rootBundle.loadString('assets/writerside/templates.json'));
    return List<WritersideTemplate>.unmodifiable(
      (jsonDecode(source) as List).map(
        (value) => WritersideTemplate.fromJson(value as Map<String, dynamic>),
      ),
    );
  }();

  Future<String> _path() async =>
      storagePath ??
      p.join(
        (await getApplicationSupportDirectory()).path,
        'writerside',
        'templates.json',
      );

  Future<WritersideTemplateSnapshot> read() async {
    final path = await _path();
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      return const WritersideTemplateSnapshot([], null);
    }
    if (type != FileSystemEntityType.file) {
      throw FileSystemException('Template store is not a regular file', path);
    }
    final raw = await File(path).readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != 1) {
      throw const FormatException('Unsupported Writerside template store');
    }
    final entries = (data['templates'] as List)
        .map(
          (item) => WritersideTemplate.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    _validate(entries);
    return WritersideTemplateSnapshot(List.unmodifiable(entries), raw);
  }

  Future<List<WritersideTemplate>> catalog() async {
    final base = await bundled();
    final stored = await read();
    return effectiveCatalog(base, stored.entries);
  }

  static List<WritersideTemplate> effectiveCatalog(
    List<WritersideTemplate> base,
    List<WritersideTemplate> stored,
  ) => [
    for (final template in base)
      stored.where((entry) => entry.id == template.id).firstOrNull ?? template,
    ...stored.where((entry) => entry.category == 'custom'),
  ];

  Future<void> save(
    WritersideTemplateSnapshot expected,
    List<WritersideTemplate> entries,
  ) async {
    _validate(entries);
    await _locked(() async {
      if ((await read()).revision != expected.revision) {
        throw const WritersideTemplateConflict();
      }
      await _publish(entries);
    });
  }

  Future<WritersideTemplate> saveTopic({
    required WritersideTopic topic,
    required String? contextualTitle,
  }) => _locked(() async {
    final snapshot = await read();
    final name = uniqueName(
      'Writerside_${p.basenameWithoutExtension(topic.fileName)}',
      snapshot.entries.map((entry) => entry.name),
    );
    final template = WritersideTemplate(
      id: const Uuid().v4(),
      name: name,
      category: 'custom',
      extension: topic.format == WritersideTopicFormat.xml ? 'topic' : 'md',
      source: prepareSavedSource(
        source: topic.document.source,
        title: contextualTitle,
        id: topic.format == WritersideTopicFormat.xml
            ? topic.document.rootElement?.attributes['id']
            : null,
        format: topic.format,
      ),
    );
    await _publish([...snapshot.entries, template]);
    return template;
  });

  static String uniqueName(String base, Iterable<String> names) {
    final occupied = names.toSet();
    var name = base;
    for (var index = 1; occupied.contains(name); index++) {
      name = '$base ($index)';
    }
    return name;
  }

  static void _validate(List<WritersideTemplate> entries) {
    final ids = <String>{};
    final names = <String>{};
    for (final entry in entries) {
      WritersideTemplate.fromJson(entry.toJson());
      if (entry.category == 'tgdp' ||
          !ids.add(entry.id) ||
          !names.add('${entry.category}:${entry.name}.${entry.extension}')) {
        throw const FormatException('Duplicate or invalid user template');
      }
    }
  }

  Future<void> _publish(List<WritersideTemplate> entries) async {
    _validate(entries);
    await const AtomicFileWriter().writeBytes(
      await _path(),
      utf8.encode(
        jsonEncode({
          'version': 1,
          'templates': entries.map((entry) => entry.toJson()).toList(),
        }),
      ),
      overwrite: true,
    );
  }

  Future<T> _locked<T>(Future<T> Function() action) async {
    final path = p.normalize(p.absolute(await _path()));
    final previous = _writes[path] ?? Future<void>.value();
    final completed = Completer<void>();
    _writes[path] = completed.future;
    await previous;
    RandomAccessFile? lock;
    try {
      await Directory(p.dirname(path)).create(recursive: true);
      final lockPath = '$path.lock';
      final type = await FileSystemEntity.type(lockPath, followLinks: false);
      if (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound) {
        throw FileSystemException('Unsafe template lock', lockPath);
      }
      lock = await File(lockPath).open(mode: FileMode.append);
      await lock.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      await lock?.close();
      completed.complete();
      if (identical(_writes[path], completed.future)) _writes.remove(path);
    }
  }

  /// Installed LocalFileTemplateProvider uses simultaneous literal replacement,
  /// NOT Velocity evaluation. Values containing another token are not expanded.
  static String generate(
    WritersideTemplate template, {
    required String title,
    required String id,
  }) {
    if (template.category == 'tgdp') return _adaptTgdp(template, title);
    final escapedTitle = template.format == WritersideTopicFormat.xml
        ? _escapeXml10(title)
        : title;
    return template.source.replaceAllMapped(
      RegExp(r'\$\{(TITLE|ID)\}'),
      (match) => match[1] == 'TITLE' ? escapedTitle : id,
    );
  }

  static String filenameFromTitle(String title) => title
      .replaceAll(RegExp(r'[!-/:-@\[-`{-~ ]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// Faithful to TemplateFromTopicAction, including its first-match substring
  /// replacement and Markdown pattern order. It does not rewrite every XML
  /// attribute semantically, invent placeholders, or change the source topic.
  static String prepareSavedSource({
    required String source,
    String? title,
    String? id,
    required WritersideTopicFormat format,
  }) {
    var result = source;
    for (final (variable, value) in [('title', title), ('id', id)]) {
      if (value == null) continue;
      final escaped = RegExp.escape(value);
      final patterns = format == WritersideTopicFormat.xml
          ? [variable + r'(\s+)?=(\s+)?"' + escaped]
          : [
              r'\((\s+)?' +
                  variable +
                  r'(\s+)?:(\s+)?$' +
                  escaped +
                  r'(\s+)?\)',
              r'#(\s+)?' + escaped,
              r'(\s+)?---(\s+)?(name|title):(\s+)?' + escaped + r'(\s+)?---',
              escaped + r'(\s+)?===',
            ];
      for (final pattern in patterns) {
        final match = RegExp(pattern).firstMatch(result);
        if (match == null) continue;
        final token = '\${${variable.toUpperCase()}}';
        result = result.replaceAll(
          match[0]!,
          format == WritersideTopicFormat.xml
              ? '$variable="$token'
              : '# $token',
        );
        break;
      }
    }
    return result;
  }

  static String _escapeXml10(String text) =>
      String.fromCharCodes(
            text.runes.where(
              (rune) =>
                  rune == 9 ||
                  rune == 10 ||
                  rune == 13 ||
                  (rune >= 0x20 && rune <= 0xd7ff) ||
                  (rune >= 0xe000 && rune <= 0xfffd) ||
                  (rune >= 0x10000 && rune <= 0x10ffff),
            ),
          )
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;')
          .replaceAllMapped(
            RegExp('[\u007f-\u0084\u0086-\u009f]'),
            (match) => '&#${match[0]!.codeUnitAt(0)};',
          );

  static String _adaptTgdp(WritersideTemplate template, String title) {
    var source = template.source.replaceAllMapped(RegExp(r'\{[^}]+\}'), (
      match,
    ) {
      final text = match[0]!;
      return RegExp(r'^\{\s*([\w-]+="[^"]*"\s*)+\}$').hasMatch(text.trim())
          ? text
          : '{(${text.substring(1, text.length - 1)})}';
    });
    // Use the Markdown parser's source ranges, not a search for heading text
    // that might also occur inside a code fence.
    final parsed = const MarkdownParser().parse(
      filePath: 'template.md',
      source: source,
      validateLocalReferences: false,
    );
    final edits = <({int start, int end, String value})>[];
    final occupied = <int>{};
    for (final (destination, span) in [
      for (final link in parsed.links) (link.destination, link.span),
      for (final image in parsed.images) (image.destination, image.span),
    ]) {
      final uri = Uri.tryParse(destination);
      if (uri == null || uri.hasScheme || destination.startsWith('#')) {
        continue;
      }
      final raw = source.substring(span.startOffset, span.endOffset);
      // Reference spans identify blocks, not individual destinations. Locate
      // only inline destination syntax, never matching label/prose text, and
      // consume each occurrence once when a block repeats a link or image.
      final code = RegExp(r'(`+).*?\1', dotAll: true).allMatches(raw).toList();
      final matches = RegExp(
        r'\]\([ \t]*<?(' + RegExp.escape(destination) + r')(?=[>)\s])',
      ).allMatches(raw);
      int? offset;
      for (final match in matches) {
        final candidate = match.end - destination.length;
        if (!occupied.contains(span.startOffset + candidate) &&
            !code.any(
              (range) => match.start >= range.start && match.start < range.end,
            )) {
          offset = candidate;
          break;
        }
      }
      if (offset == null) continue;
      occupied.add(span.startOffset + offset);
      edits.add((
        start: span.startOffset + offset,
        end: span.startOffset + offset + destination.length,
        value: Uri.parse(template.url!).resolveUri(uri).toString(),
      ));
    }
    final topic = const WritersideTopicParser().parseMarkdown(
      filePath: 'template.md',
      source: source,
      topicsRoot: '.',
    );
    final heading = topic.document.nodes
        .whereType<WritersideMarkdownBlockNode>()
        .where(
          (node) =>
              node.block.kind == BusyBlockKind.heading &&
              node.block.attributes['level'] == '1',
        )
        .firstOrNull;
    if (heading != null) {
      edits.removeWhere(
        (edit) =>
            edit.start >= heading.span.startOffset &&
            edit.start < heading.span.endOffset,
      );
      final raw = source.substring(
        heading.span.startOffset,
        heading.span.endOffset,
      );
      edits.add((
        start: heading.span.startOffset,
        end: heading.span.endOffset,
        value:
            '# $title${raw.endsWith('\r\n')
                ? '\r\n'
                : raw.endsWith('\n')
                ? '\n'
                : ''}',
      ));
    }
    edits.sort((a, b) => b.start.compareTo(a.start));
    for (final edit in edits) {
      source = source.replaceRange(edit.start, edit.end, edit.value);
    }
    return source;
  }
}
