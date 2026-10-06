import '../../assets/asset_ingestion_service.dart';
import '../../assets/document_media_context.dart';
import '../../assets/provider_asset_ingestion_service.dart';
import 'notes_repository.dart';

/// One note owns its resolver, byte staging, and cached reference namespace.
class NextcloudDocumentMedia {
  NextcloudDocumentMedia(this.repository, this.accountId, this.localId) {
    ingestion = ProviderAssetIngestionService(
      publish: (bytes, filename) async {
        final note = repository.noteById(localId);
        if (note == null || note.readonly) {
          throw const AssetIngestionException(
            'asset.read-only',
            'This note cannot be changed.',
          );
        }
        final attachment = await repository.addAttachment(
          localId,
          filename: filename,
          bytes: bytes,
        );
        final path = await resolve(attachment.reference);
        if (path == null) {
          throw const AssetIngestionException(
            'asset.cache-unavailable',
            'The attachment could not be retained.',
          );
        }
        return ManagedAssetPublication(
          id: attachment.id,
          reference: attachment.reference,
          cachedPath: path,
        );
      },
      cancelPublication: (reference) =>
          repository.deleteAttachment(localId, reference),
    );
  }
  final NotesRepository repository;
  final String accountId;
  final String localId;
  final _paths = <String, String>{};
  final _pending = <String, Future<String?>>{};
  DocumentMediaContext? _context;
  int _version = -1;
  DocumentMediaContext get context {
    _checkVersion();
    return _context ??= DocumentMediaContext(
      identity: '$accountId:$localId:$_version',
      resolve: resolve,
      resolveCached: (reference) {
        _checkVersion();
        return _paths[reference];
      },
    );
  }

  late final AssetIngestionService ingestion;

  void _checkVersion() {
    final version = repository.mediaVersion(localId);
    if (version == _version) return;
    _version = version;
    _context = null;
    _paths.clear();
    _pending.clear();
  }

  Future<String?> resolve(String reference) async {
    _checkVersion();
    if (_paths.containsKey(reference)) return _paths[reference];
    if (_pending.containsKey(reference)) return _pending[reference];
    final future = _resolve(reference);
    _pending[reference] = future;
    try {
      return await future;
    } finally {
      if (identical(_pending[reference], future)) _pending.remove(reference);
    }
  }

  Future<String?> _resolve(String reference) async {
    final version = _version;
    try {
      final path = await repository.resolveMedia(accountId, localId, reference);
      _checkVersion();
      if (version != _version) return null;
      if (path != null) _paths[reference] = path;
      return path;
    } on Object {
      // An unavailable remote item is represented by the renderer placeholder.
      return null;
    }
  }
}
