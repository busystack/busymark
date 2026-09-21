import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/src/assets/asset_ingestion_service.dart';

Future<void> main(List<String> arguments) async {
  final action = arguments[0];
  final workspace = arguments[1];
  final document = arguments[2];
  final filename = arguments[3];
  final bytes = Uint8List.fromList(base64Decode(arguments[4]));
  final service = AssetIngestionService(
    hooks: action == 'fail-publication'
        ? AssetIngestionHooks(
            afterDestinationReserved: (_) async {
              throw const FileSystemException('injected publication failure');
            },
          )
        : null,
  );
  final request = AssetIngestionRequest(
    documentFilePath: document,
    workspaceKind: AssetWorkspaceKind.markdownWorkspace,
    workspaceRoot: workspace,
  );
  try {
    final asset = await service.ingestBytes(
      bytes: bytes,
      suggestedFileName: filename,
      request: request,
      origin: AssetIngestionOrigin.screenshotPaste,
    );
    stdout.writeln(
      jsonEncode({
        'path': asset.absolutePath,
        'publicationId': asset.publicationId,
      }),
    );
    if (action == 'commit') {
      await service.commit(asset);
      return;
    }
    if (action == 'wait') {
      final command = await stdin
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      if (command == 'commit') {
        await service.commit(asset);
      } else if (command == 'rollback') {
        await service.rollback(asset);
      }
    }
  } on Object catch (error) {
    stdout.writeln(jsonEncode({'error': error.toString()}));
    if (action != 'fail-publication') rethrow;
  }
}
