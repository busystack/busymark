import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../assets/asset_limits.dart';
import '../domain/notes_models.dart';
import 'notes_attachment_references.dart';
import 'server_uri.dart';

class NotesDownloadCancellation {
  final _cancelled = Completer<void>();
  Future<void> get whenCancelled => _cancelled.future;
  bool get isCancelled => _cancelled.isCompleted;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }

  void check() {
    if (isCancelled) {
      throw const NotesException(
        NotesFailureCode.network,
        'Attachment download was cancelled.',
      );
    }
  }
}

class NotesListResult {
  const NotesListResult({
    required this.notes,
    required this.ids,
    this.etag,
    this.lastModified,
    this.notModified = false,
  });

  final List<NoteState> notes;
  final Set<int> ids;
  final String? etag;
  final String? lastModified;
  final bool notModified;
}

/// The authenticated official Notes API. Redirects are never followed.
class NotesApiClient {
  NotesApiClient({
    required http.Client client,
    required this.account,
    required String appPassword,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client,
       _authorization =
           'Basic ${base64Encode(utf8.encode('${account.loginName}:$appPassword'))}';

  final http.Client _client;
  final NextcloudAccount account;
  final String _authorization;
  final Duration timeout;

  Uri _endpoint(String path, [Map<String, String>? query]) => nextcloudEndpoint(
    account.server,
    'index.php/apps/notes/api/$path',
    queryParameters: query,
  );

  Future<http.Response> _send(http.BaseRequest request) async {
    request.followRedirects = false;
    request.headers['Authorization'] = _authorization;
    request.headers['Accept'] = 'application/json';
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
      if (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          response.statusCode != 304) {
        throw const NotesException(
          NotesFailureCode.authentication,
          'The server redirected an authenticated request. Reconnect using its canonical URL.',
        );
      }
      return response;
    } on NotesException {
      rethrow;
    } on TimeoutException {
      throw const NotesException(
        NotesFailureCode.network,
        'The Nextcloud request timed out. Local changes are preserved.',
      );
    } on http.ClientException {
      throw const NotesException(
        NotesFailureCode.network,
        'Nextcloud is unreachable. Local changes are preserved.',
      );
    } on IOException {
      throw const NotesException(
        NotesFailureCode.network,
        'Nextcloud is unreachable. Local changes are preserved.',
      );
    }
  }

  static String? header(http.Response response, String name) {
    final lower = name.toLowerCase();
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  static dynamic _json(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'Nextcloud returned invalid JSON.',
      );
    }
  }

  static NoteState _note(http.Response response) {
    final json = _json(response);
    if (json is! Map<String, dynamic>) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'Nextcloud returned an invalid note.',
      );
    }
    return NoteState.fromJson(json);
  }

  static void _check(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;
    final (code, message) = switch (status) {
      401 => (
        NotesFailureCode.authentication,
        'Reconnect to Nextcloud to resume synchronization.',
      ),
      403 => (
        NotesFailureCode.forbidden,
        'Nextcloud does not permit this change. The note may be read-only.',
      ),
      404 => (
        NotesFailureCode.missing,
        'The note or attachment no longer exists on Nextcloud.',
      ),
      412 => (
        NotesFailureCode.conflict,
        'This note changed on Nextcloud. Resolve the conflict before synchronizing.',
      ),
      423 => (
        NotesFailureCode.locked,
        'Nextcloud has locked this note. Local changes are preserved; retry after the lock is released.',
      ),
      507 => (
        NotesFailureCode.storageFull,
        'Nextcloud has insufficient storage. Local changes are preserved.',
      ),
      >= 500 => (
        NotesFailureCode.server,
        'Nextcloud returned server error $status. Local changes are preserved.',
      ),
      _ => (
        NotesFailureCode.server,
        'Nextcloud rejected this request (HTTP $status). Local changes are preserved.',
      ),
    };
    NoteState? remote;
    if (status == 412) {
      try {
        remote = _note(response);
      } on NotesException {
        /* Fetch fresh state separately. */
      }
    }
    throw NotesException(code, message, statusCode: status, remote: remote);
  }

  /// Collects every chunk before returning; interrupted lists never imply deletion.
  Future<NotesListResult> list({
    int chunkSize = 100,
    bool forceFull = false,
  }) async {
    final notes = <int, NoteState>{};
    final ids = <int>{};
    final cursors = <String>{};
    String? cursor;
    String? modified;
    String? etag;
    for (var chunk = 0; chunk < 10000; chunk++) {
      final query = <String, String>{'chunkSize': '$chunkSize'};
      if (!forceFull && account.lastModified != null) {
        try {
          query['pruneBefore'] =
              '${HttpDate.parse(account.lastModified!).millisecondsSinceEpoch ~/ 1000}';
        } on FormatException {
          // Invalid persisted checkpoint safely triggers an unpruned list.
        }
      }
      if (cursor != null) query['chunkCursor'] = cursor;
      final request = http.Request('GET', _endpoint('v1/notes', query));
      if (!forceFull && cursor == null && account.listEtag != null) {
        request.headers['If-None-Match'] = account.listEtag!;
      }
      final response = await _send(request);
      if (response.statusCode == 304 && cursor == null) {
        return const NotesListResult(notes: [], ids: {}, notModified: true);
      }
      _check(response);
      final json = _json(response);
      if (json is! List) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'Nextcloud returned an invalid notes list.',
        );
      }
      for (final item in json) {
        if (item is! Map<String, dynamic> ||
            item['id'] is! int ||
            (item['id'] as int) <= 0) {
          throw const NotesException(
            NotesFailureCode.invalidResponse,
            'Nextcloud returned an invalid note identifier.',
          );
        }
        ids.add(item['id'] as int);
        if (item.containsKey('etag') || item.containsKey('content')) {
          final note = NoteState.fromJson(item);
          notes[note.id] = note;
        }
      }
      modified ??= header(response, 'Last-Modified');
      etag = header(response, 'ETag');
      cursor = header(response, 'X-Notes-Chunk-Cursor');
      if (cursor == null || cursor.isEmpty) {
        return NotesListResult(
          notes: notes.values.toList(),
          ids: ids,
          etag: etag,
          lastModified: modified,
        );
      }
      if (!cursors.add(cursor)) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'Nextcloud repeated a notes chunk cursor.',
        );
      }
    }
    throw const NotesException(
      NotesFailureCode.invalidResponse,
      'Nextcloud returned too many notes chunks.',
    );
  }

  Future<NoteState> get(int id) async {
    final response = await _send(
      http.Request('GET', _endpoint('v1/notes/$id')),
    );
    _check(response);
    return _note(response);
  }

  static Map<String, Object> writable(NextcloudNote note) => {
    'content': note.content,
    'title': note.title,
    'category': note.category,
    'favorite': note.favorite,
  };

  static Future<Map<String, Object>> creationAttributes(
    NextcloudNote note,
  ) async {
    final attributes = writable(note);
    // A new note needs its server ID before its attachments can be uploaded.
    // Private staging references must never be stored on Nextcloud.
    final references = await scanNotesAttachmentReferences(note.content);
    attributes['content'] =
        replaceNotesAttachmentReferences(note.content, references, {
          for (final reference in references)
            if (reference.reference.startsWith('busymark-attachment:'))
              reference.reference: '',
        });
    attributes['modified'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return attributes;
  }

  Future<NoteState> create(NextcloudNote note) async {
    final request = http.Request('POST', _endpoint('v1/notes'))
      ..headers['Content-Type'] = 'application/json'
      ..body =
          note.creationAttempt?.wireBody ??
          jsonEncode(await creationAttributes(note));
    final response = await _send(request);
    _check(response);
    return _note(response);
  }

  Future<NoteState> update(NextcloudNote note) async {
    if (!note.readonly &&
        note.content.contains('busymark-attachment:') &&
        (await scanNotesAttachmentReferences(
          note.content,
        )).any((r) => r.reference.startsWith('busymark-attachment:'))) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'A staged attachment must finish publication or its reference must be removed before this note can be updated.',
      );
    }
    if (note.serverId == null || note.etag == null) {
      throw const NotesException(
        NotesFailureCode.conflict,
        'A server reference state is required before updating a note.',
      );
    }
    // Stable Helper.php compares against quoted JSON etags. HTTP ETags are quoted.
    final request = http.Request('PUT', _endpoint('v1/notes/${note.serverId}'))
      ..headers['If-Match'] = '"${note.etag}"'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(
        note.readonly ? {'favorite': note.favorite} : writable(note),
      );
    final response = await _send(request);
    _check(response);
    return _note(response);
  }

  Future<void> delete(int id) async {
    final response = await _send(
      http.Request('DELETE', _endpoint('v1/notes/$id')),
    );
    _check(response);
  }

  Future<String> uploadAttachment(
    int id,
    String filename,
    Uint8List bytes,
  ) async {
    final request =
        http.MultipartRequest('POST', _endpoint('v1.4/attachment/$id'))
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );
    final response = await _send(request);
    _check(response);
    final json = _json(response);
    if (json is! Map ||
        json['filename'] is! String ||
        !isSafeAttachmentPath(json['filename'] as String) ||
        !isNoteAttachmentPath(id, json['filename'] as String)) {
      throw const NotesException(
        NotesFailureCode.invalidResponse,
        'Nextcloud returned an unsafe attachment filename.',
      );
    }
    return json['filename'] as String;
  }

  /// Streams into a private sibling and publishes only a complete bounded file.
  Future<File> fetchAttachment(
    int id,
    String path, {
    required File destination,
    NotesDownloadCancellation? cancellation,
  }) async {
    if (!isSafeAttachmentPath(path)) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'This attachment reference is unsafe.',
      );
    }
    final decodedPath = Uri.decodeComponent(path);
    if (decodedPath.startsWith('.attachments.') &&
        !decodedPath.startsWith('.attachments.$id/')) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'This attachment belongs to a different Nextcloud note.',
      );
    }
    final cancel = cancellation ?? NotesDownloadCancellation();
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(
            'GET',
            _endpoint('v1.4/attachment/$id', {'path': path}),
            abortTrigger: Future.any([cancel.whenCancelled, abort.future]),
          )
          ..headers['Authorization'] = _authorization
          ..followRedirects = false;
    Directory? partialDirectory;
    RandomAccessFile? output;
    StreamIterator<List<int>>? input;
    try {
      cancel.check();
      final response = await _client.send(request).timeout(timeout);
      // Register the stream before checking status/headers so every exit cancels it.
      input = StreamIterator(response.stream.timeout(timeout));
      cancel.check();
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const NotesException(
          NotesFailureCode.authentication,
          'Nextcloud redirected an authenticated attachment request. Reconnect using its canonical HTTPS URL.',
        );
      }
      _check(http.Response('', response.statusCode));
      if (response.statusCode != 200) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'Nextcloud returned an incomplete attachment.',
        );
      }
      final lengthHeader = response.headers.entries
          .where((entry) => entry.key.toLowerCase() == 'content-length')
          .firstOrNull
          ?.value;
      final declaredLength = lengthHeader == null
          ? response.contentLength
          : int.tryParse(lengthHeader);
      if (lengthHeader != null &&
          (declaredLength == null || declaredLength < 0)) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'Nextcloud returned an invalid attachment length.',
        );
      }
      if (declaredLength != null && declaredLength > maximumManagedAssetBytes) {
        throw const NotesException(
          NotesFailureCode.unsupported,
          'The attachment exceeds BusyMark’s 100 MiB asset limit.',
        );
      }
      if (await FileSystemEntity.isLink(destination.path) ||
          await FileSystemEntity.isLink(destination.parent.path)) {
        throw const NotesException(
          NotesFailureCode.unsafeReference,
          'The attachment cache destination is unsafe.',
        );
      }
      partialDirectory = await destination.parent.createTemp('.download-');
      if (Platform.isLinux) {
        final permission = await Process.run('chmod', [
          '700',
          partialDirectory.path,
        ]);
        if (permission.exitCode != 0) {
          throw const FileSystemException('Cannot protect download.');
        }
      }
      final partial = File('${partialDirectory.path}/attachment.part');
      output = await partial.open(mode: FileMode.write);
      var received = 0;
      while (await Future.any([
        input.moveNext(),
        cancel.whenCancelled.then<bool>((_) {
          cancel.check();
          return false;
        }),
      ])) {
        cancel.check();
        final chunk = input.current;
        received += chunk.length;
        if (received > maximumManagedAssetBytes) {
          throw const NotesException(
            NotesFailureCode.unsupported,
            'The attachment exceeds BusyMark’s 100 MiB asset limit.',
          );
        }
        await output.writeFrom(chunk);
      }
      cancel.check();
      if (declaredLength != null && received != declaredLength) {
        throw const NotesException(
          NotesFailureCode.invalidResponse,
          'The attachment download was incomplete.',
        );
      }
      await output.flush();
      await output.close();
      output = null;
      if (Platform.isLinux) {
        final permission = await Process.run('chmod', ['600', partial.path]);
        if (permission.exitCode != 0) {
          throw const FileSystemException('Cannot protect download.');
        }
      }
      cancel.check();
      return await partial.rename(destination.path);
    } on NotesException {
      rethrow;
    } on TimeoutException {
      throw const NotesException(
        NotesFailureCode.network,
        'The attachment download timed out.',
      );
    } on http.ClientException {
      cancel.check();
      throw const NotesException(
        NotesFailureCode.network,
        'The attachment download was interrupted.',
      );
    } on IOException {
      throw const NotesException(
        NotesFailureCode.network,
        'The attachment could not be downloaded safely.',
      );
    } finally {
      if (!abort.isCompleted) abort.complete();
      await input?.cancel();
      await output?.close();
      if (partialDirectory != null) {
        await partialDirectory.delete(recursive: true);
      }
    }
  }

  Future<void> deleteAttachment(int id, String path) async {
    if (!account.supportsAttachmentDeletion) {
      throw const NotesException(
        NotesFailureCode.unsupported,
        'Remote attachment cleanup is unavailable: it requires a verified Notes version of 6.1.0 or newer. Notes and attachment upload/download remain available.',
      );
    }
    if (!isSafeAttachmentPath(path) || !path.startsWith('.attachments.$id/')) {
      throw const NotesException(
        NotesFailureCode.unsafeReference,
        'Only this note’s managed attachments can be deleted.',
      );
    }
    final request = http.Request('DELETE', _endpoint('v1.4/attachment/$id'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'path': path});
    final response = await _send(request);
    _check(response);
  }
}

bool isSafeAttachmentReference(String reference) {
  if (reference.isEmpty ||
      reference.contains('\\') ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(reference)) {
    return false;
  }
  final uri = Uri.tryParse(reference);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment ||
      reference.startsWith('/')) {
    return false;
  }
  try {
    final decoded = Uri.decodeComponent(reference);
    if (decoded.startsWith('/') || decoded.contains('\\')) return false;
    return decoded
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');
  } on FormatException {
    return false;
  }
}

/// API filenames are opaque paths: a literal # can be a valid filename. The
/// Markdown URI spelling is decoded separately before passing it to the API.
bool isSafeAttachmentPath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(path) ||
      Uri.tryParse(path)?.hasScheme != false) {
    return false;
  }
  try {
    final decoded = Uri.decodeComponent(path);
    if (decoded.startsWith('/') || decoded.contains('\\')) return false;
    return decoded
        .split('/')
        .every((part) => part.isNotEmpty && part != '.' && part != '..');
  } on FormatException {
    return false;
  }
}

String? canonicalAttachmentReference(String reference) {
  if (!isSafeAttachmentReference(reference)) return null;
  try {
    return Uri.decodeComponent(reference);
  } on FormatException {
    return null;
  }
}

String attachmentMarkdownReference(String path) => path
    .split('/')
    .map(
      (part) => Uri.encodeComponent(
        part,
      ).replaceAll('(', '%28').replaceAll(')', '%29'),
    )
    .join('/');

/// API 1.4 returns flat filenames on 6.0.x and scoped filenames on 6.1.x.
/// A foreign note folder or any other directory is never an upload destination.
bool isNoteAttachmentPath(int id, String path) =>
    isSafeAttachmentPath(path) &&
    (!Uri.decodeComponent(path).contains('/') ||
        Uri.decodeComponent(path).startsWith('.attachments.$id/'));
