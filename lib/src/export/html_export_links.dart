import 'package:path/path.dart' as p;
import '../writerside/writerside_document.dart';
import '../writerside/writerside_model.dart';
import 'html_export_assets.dart';
import 'html_export_models.dart';
import 'html_publication_plan.dart';

class HtmlExportLinks {
  HtmlExportLinks({
    required this.plan,
    required this.assets,
    required this.warnings,
    this.modules = const [],
  });
  final HtmlPublicationPlan plan;
  final HtmlExportAssets assets;
  final List<HtmlExportWarning> warnings;
  final List<WritersideModule> modules;

  String source(HtmlPage page, Map<String, String> attributes) =>
      attributes[writersideSourceTopicPathAttribute] ?? page.sourcePath;
  List<String> roots(HtmlPage page, Map<String, String> attributes) {
    final root = attributes[writersideSourceModuleRootAttribute];
    final module =
        modules
            .where((m) => root != null && p.equals(m.rootPath, root))
            .firstOrNull ??
        page.module;
    return module == null
        ? []
        : [
            p.join(module.rootPath, module.effectiveImagesDir),
            if (module.config.resourcesDir case final dir?)
              p.join(module.rootPath, dir),
            module.rootPath,
          ];
  }

  static String? external(String value) {
    if (RegExp(r'[\x00-\x20\x7f\\]').hasMatch(value)) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !{
          'https',
          'http',
          'mailto',
          'tel',
        }.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }

  Future<String?> resolve(
    String? value,
    HtmlPage page,
    Map<String, String> attributes, {
    int line = 1,
  }) async {
    if (value == null || value.trim().isEmpty) return null;
    final destination = value.trim();
    if (external(destination) case final url?) return url;
    final origin = source(page, attributes);
    void warn(String message) => warnings.add(
      HtmlExportWarning(
        'link.unresolved',
        message,
        sourcePath: origin,
        line: line,
      ),
    );
    if (attributes['nullable'] == 'true' &&
        attributes['resolved-available'] == 'false') {
      return null;
    }
    if (attributes['element'] == 'resource') {
      return assets.local(
        destination,
        sourcePath: origin,
        searchRoots: roots(page, attributes),
        line: line,
        download: true,
      );
    }
    final uri = Uri.tryParse(destination);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        RegExp(r'[\x00-\x1f\\]').hasMatch(destination)) {
      warn('Unsafe or unsupported link destination was omitted.');
      return null;
    }
    var fragment = Uri.decodeComponent(uri.fragment);
    final path = uri.path;
    HtmlPage? target;
    if (path.isEmpty) {
      target = page;
      if (!page.ids.contains(fragment) && origin != page.sourcePath) {
        target = plan.pageForSource(origin);
      }
    } else {
      final absolute = p.normalize(
        p.isAbsolute(path)
            ? path
            : p.join(p.dirname(origin), Uri.decodeComponent(path)),
      );
      target = plan.pageForSource(absolute);
      if (target == null && page.module != null) {
        final module =
            modules
                .where(
                  (m) =>
                      m.rootPath ==
                      attributes[writersideSourceModuleRootAttribute],
                )
                .firstOrNull ??
            page.module!;
        final topic = module.topicByReference(Uri.decodeComponent(path));
        if (topic != null) target = plan.pageForSource(topic.filePath);
      }
    }
    if (target != null) {
      if (!target.ids.contains(fragment) && target.ids.contains(uri.fragment)) {
        fragment = uri.fragment;
      }
      if (fragment.isNotEmpty && !target.ids.contains(fragment)) {
        warn('Missing anchor "$fragment" in ${p.basename(target.sourcePath)}.');
        return null;
      }
      return '${target == page ? (fragment.isEmpty ? Uri.encodeComponent(target.filename) : '') : Uri.encodeComponent(target.filename)}${fragment.isEmpty ? '' : '#${Uri.encodeComponent(fragment)}'}';
    }
    if (attributes['nullable'] == 'true') return null;
    if (const {
      '.md',
      '.markdown',
      '.topic',
      '.html',
      '.htm',
    }.contains(p.extension(path).toLowerCase())) {
      warn('Linked document ${p.basename(path)} is outside this export.');
      return null;
    }
    final asset = await assets.local(
      destination,
      sourcePath: origin,
      searchRoots: roots(page, attributes),
      line: line,
      download: true,
    );
    if (asset == null) {
      warn('Link target ${p.basename(path)} could not be resolved.');
    }
    return asset;
  }
}
