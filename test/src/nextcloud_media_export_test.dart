import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/assets/asset_ingestion_service.dart';
import 'package:busymark/src/assets/document_media_context.dart';
import 'package:busymark/src/assets/provider_asset_ingestion_service.dart';
import 'package:busymark/src/editor/markdown_image_view.dart';
import 'package:busymark/src/export/html_export_assets.dart';
import 'package:busymark/src/export/html_export_models.dart';
import 'package:busymark/src/export/html_export_service.dart';
import 'package:busymark/src/export/markdown_copy_export_service.dart';
import 'package:busymark/src/export/markdown_export_assets.dart';
import 'package:busymark/src/export/markdown_export_document.dart';
import 'package:busymark/src/export/markdown_pdf_models.dart';
import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/nextcloud_notes/application/attachment_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:busymark/src/nextcloud_notes/data/notes_attachment_references.dart';

void main() {
  late Directory root;
  late File image;
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jR1kAAAAASUVORK5CYII=',
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('notes-media-test-');
    image = await File(p.join(root.path, 'private.png')).writeAsBytes(png);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  testWidgets(
    'remote authored absolute and file image paths never enter local resolver',
    (tester) async {
      final requested = <String>[];
      final media = DocumentMediaContext(
        identity: 'account:note',
        resolve: (reference) async {
          requested.add(reference);
          return null;
        },
        resolveCached: (_) => null,
      );
      for (final source in [image.path, Uri.file(image.path).toString()]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DocumentMediaScope(
                media: media,
                child: MarkdownImageView(
                  source: source,
                  alt: '',
                  activeFilePath: '',
                  workspaceRoot: root.path,
                  writersideRoot: null,
                  imagesDir: 'images',
                  allowRemoteImages: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNothing);
        expect(requested, contains(source));
      }
    },
  );

  testWidgets('managed attachment renderer resolves through provider', (
    tester,
  ) async {
    const reference = 'busymark-attachment:account:note:attachment';
    final media = DocumentMediaContext(
      identity: 'account:note',
      resolve: (value) async => value == reference ? image.path : null,
      resolveCached: (value) => value == reference ? image.path : null,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DocumentMediaScope(
            media: media,
            child: const MarkdownImageView(
              source: reference,
              alt: '',
              activeFilePath: '',
              workspaceRoot: null,
              writersideRoot: null,
              imagesDir: 'images',
              allowRemoteImages: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      image.path,
    );
  });

  test(
    'provider publication accepts a remote note with no file path and rolls back through provider',
    () async {
      final deleted = <String>[];
      final service = ProviderAssetIngestionService(
        publish: (bytes, name) async {
          expect(bytes, png);
          expect(name, 'image.png');
          return ManagedAssetPublication(
            id: 'attachment',
            reference: 'busymark-attachment:account:note:attachment',
            cachedPath: image.path,
          );
        },
        cancelPublication: (value) async => deleted.add(value),
      );
      final asset = await service.ingestBytes(
        bytes: Uint8List.fromList(png),
        suggestedFileName: 'image.png',
        request: const AssetIngestionRequest(
          documentFilePath: '',
          workspaceKind: AssetWorkspaceKind.standalone,
        ),
        origin: AssetIngestionOrigin.screenshotPaste,
      );
      expect(asset.markdownPath, startsWith('busymark-attachment:'));
      await service.rollback(asset);
      expect(deleted, [asset.markdownPath]);
    },
  );

  test(
    'HTML and PDF remote assets cannot read authored machine files',
    () async {
      final media = DocumentMediaContext.unavailable;
      final warnings = <HtmlExportWarning>[];
      final assets = HtmlExportAssets(
        directory: Directory(p.join(root.path, 'html-assets')),
        urlDirectory: 'assets',
        allowedRoots: [root.path],
        token: HtmlExportCancellationToken(),
        warnings: warnings,
        media: media,
      );
      expect(
        await assets.local(
          image.path,
          sourcePath: p.join(root.path, 'note.md'),
        ),
        isNull,
      );
      expect(warnings, hasLength(1));
      final stage = Directory(p.join(root.path, 'pdf'));
      await stage.create();
      final result = await const MarkdownExportAssetStager().stage(
        document: MarkdownExportDocument(
          metadata: const MarkdownExportMetadata(title: 'Note'),
          blocks: [
            MarkdownExportBlock(
              kind: MarkdownExportBlockKind.paragraph,
              inlines: [
                MarkdownExportInline(
                  kind: MarkdownExportInlineKind.image,
                  destination: image.path,
                ),
              ],
            ),
          ],
        ),
        exportRoot: stage,
        activeFilePath: '',
        workspaceRoot: root.path,
        cancellationToken: MarkdownPdfCancellationToken(),
        media: media,
      );
      expect(result.assets, isEmpty);
      expect(result.warnings.single.code, MarkdownPdfWarningCode.imageNotFound);
    },
  );

  test(
    'Markdown local copy owns portable attachments and preserves code and ordinary text',
    () async {
      const reference = 'busymark-attachment:account:note:attachment';
      const source =
          '![image]($reference)\n\n`![example]($reference)`\n\n```md\n![example]($reference)\n```\n\n$reference\n';
      final media = DocumentMediaContext(
        identity: 'account:note',
        resolve: (value) async => value == reference ? image.path : null,
        resolveCached: (value) => value == reference ? image.path : null,
      );
      final destination = p.join(root.path, 'export.md');
      await const MarkdownCopyExportService().export(
        source: source,
        destinationPath: destination,
        media: media,
      );
      final text = await File(destination).readAsString();
      final referencePath = RegExp(
        r'^!\[image\]\(([^)]+)\)',
      ).firstMatch(text)!.group(1)!;
      expect(referencePath, startsWith('export.attachments-'));
      expect(
        await File(
          p.join(root.path, Uri.decodeComponent(referencePath)),
        ).readAsBytes(),
        png,
      );
      expect(text, contains('`![example]($reference)`'));
      expect(text, contains('```md\n![example]($reference)\n```'));
      expect(text, endsWith('\n\n$reference\n'));
      expect(text, isNot(contains(image.path)));
    },
  );

  test('Markdown export rewrites exact prefix-sharing destinations', () async {
    const short = '.attachments.1/a.png';
    const long = '.attachments.1/a.png.bak';
    final backup = await File(
      p.join(root.path, 'backup.bak'),
    ).writeAsBytes([7, 8, 9]);
    final media = DocumentMediaContext(
      identity: 'note',
      resolve: (reference) async => reference == short
          ? image.path
          : reference == long
          ? backup.path
          : null,
      resolveCached: (_) => null,
    );
    final destination = p.join(root.path, 'prefix.md');
    await const MarkdownCopyExportService().export(
      source:
          '![short]($short)\n\n[long](<$long> "Backup")\n\n[again][backup]\n\n[backup]: $long\n\n`[literal]($short)`\n\n$long',
      destinationPath: destination,
      media: media,
    );
    final text = await File(destination).readAsString();
    final occurrences = notesAttachmentReferences(text);
    expect(occurrences, hasLength(3));
    for (final occurrence in occurrences) {
      final bytes = await File(
        p.join(root.path, Uri.decodeComponent(occurrence.reference)),
      ).readAsBytes();
      expect(bytes, occurrence.image ? png : [7, 8, 9]);
    }
    expect(occurrences[1].reference, occurrences[2].reference);
    expect(text, contains('`[literal]($short)`'));
    expect(text, endsWith(long));
  });

  test(
    'generic attachment links are escaped and exported as portable HTML downloads',
    () async {
      const reference = 'busymark-attachment:account:note:attachment';
      final file = await File(
        p.join(root.path, 'report.docx'),
      ).writeAsBytes([1, 2, 3, 4]);
      final source = appendNextcloudAttachmentLink(
        content: 'Note',
        filename: 'Report [draft].docx',
        reference: reference,
      );
      final parsed = const MarkdownParser().parse(
        filePath: '',
        source: source,
        validateLocalReferences: false,
      );
      final link = parsed.busyDocument.blocks.last.inlines.single;
      expect(link.kind, BusyInlineKind.link);
      expect(link.plainText, 'Report [draft].docx');
      expect(link.destination, reference);
      final media = DocumentMediaContext(
        identity: 'account:note',
        resolve: (value) async => value == reference ? file.path : null,
        resolveCached: (_) => null,
      );
      final result = await HtmlExportService(stylesheetLoader: () async => '')
          .exportMarkdown(
            MarkdownHtmlExportRequest(
              source: source,
              filePath: '',
              workspaceRoot: '',
              destinationPath: p.join(root.path, 'attachment.html'),
              media: media,
            ),
          );
      final html = await File(result.entryPointPath).readAsString();
      expect(result.warnings, isEmpty);
      expect(html, contains('download="attachment"'));
      expect(html, isNot(contains(reference)));
      expect(html, isNot(contains(file.path)));
      final staged = Directory(result.assetsPath!)
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.docx');
      expect(staged, hasLength(1));
      expect(await staged.single.readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test(
    'unavailable published attachment cannot silently export a broken copy',
    () async {
      final destination = p.join(root.path, 'published.md');
      await expectLater(
        const MarkdownCopyExportService().export(
          source: '[report](.attachments.5/report.pdf)',
          destinationPath: destination,
          media: DocumentMediaContext.unavailable,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File(destination).exists(), isFalse);
    },
  );

  test(
    'unavailable pending attachment cannot produce a broken local copy',
    () async {
      final destination = p.join(root.path, 'broken.md');
      await expectLater(
        const MarkdownCopyExportService().export(
          source: '![image](busymark-attachment:account:note:id)',
          destinationPath: destination,
          media: DocumentMediaContext.unavailable,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File(destination).exists(), isFalse);
      expect((await root.list().toList()).whereType<Directory>(), isEmpty);
    },
  );
}
