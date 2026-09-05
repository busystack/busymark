import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'writerside_model.dart';
import 'writerside_source_loader.dart';

class WritersideReferenceData {
  const WritersideReferenceData({
    this.glossary = const {},
    this.shortcuts = const {},
    this.layouts = const {},
    this.resources = const {},
    this.sources = const {},
  });
  final Map<String, String> glossary;

  /// Profile -> action -> layout -> combinations. Empty profile is global.
  final Map<String, Map<String, Map<String, String>>> shortcuts;
  final Map<String, Map<String, String>> layouts;
  final Map<String, WritersideSourceFile> resources;
  final Map<String, WritersideSourceFile> sources;

  static Future<WritersideReferenceData> load(WritersideModule module) async {
    const loader = WritersideSourceLoader();
    final sources = <String, WritersideSourceFile>{};
    Future<XmlDocument?> xml(String path) async {
      final loaded = await loader.load(
        reference: path,
        documentPath: module.config.filePath,
        workspaceRoot: module.rootPath,
        overrides: module.sourceOverrides,
      );
      sources[path] = loaded;
      if (loaded.text == null) return null;
      try {
        return XmlDocument.parse(loaded.text!);
      } on FormatException {
        return null;
      }
    }

    final glossary = await xml(
      p.join(module.config.buildConfigDir, 'glossary.xml'),
    );
    final profiles = await xml(
      p.join(module.config.buildConfigDir, 'buildprofiles.xml'),
    );
    final shortcuts = <String, Map<String, Map<String, String>>>{};
    final layouts = <String, Map<String, String>>{};
    for (final config
        in profiles?.findAllElements('shortcuts') ?? const <XmlElement>[]) {
      final profile =
          config.ancestors
              .whereType<XmlElement>()
              .where((element) => element.name.local == 'build-profile')
              .firstOrNull
              ?.getAttribute('instance') ??
          '';
      final src = config.getElement('src')?.innerText.trim();
      if (src == null || src.isEmpty) continue;
      final keymap = await xml(src);
      if (keymap == null) continue;
      layouts[profile] = {
        for (final layout in config.findElements('layout'))
          if (layout.getAttribute('name') case final name?)
            name: layout.getAttribute('display-name') ?? name,
      };
      if (layouts[profile]!.isEmpty) {
        layouts[profile] = {
          for (final layout in keymap.findAllElements('layout'))
            if (layout.getAttribute('name') case final name?) name: name,
        };
      }
      shortcuts[profile] = {
        for (final action in keymap.findAllElements('action'))
          if (action.getAttribute('id') case final id?)
            id: {
              for (final layout in layouts[profile]!.keys)
                layout: action
                    .findElements('shortcut')
                    .where(
                      (shortcut) => shortcut.getAttribute('layout') == layout,
                    )
                    .map((shortcut) => shortcut.innerText.trim())
                    .where((text) => text.isNotEmpty)
                    .join(' / '),
            },
      };
    }
    final resources = <String, WritersideSourceFile>{};
    for (final topic in module.topics) {
      for (final resource in topic.document.elements.where(
        (element) => element.name == 'resource',
      )) {
        final src = resource.attributes['src'];
        if (src == null) continue;
        resources[src] = await loader.load(
          reference: src,
          documentPath: p.join(
            module.rootPath,
            module.config.resourcesDir ?? 'resources',
            '.resources',
          ),
          workspaceRoot: module.rootPath,
          overrides: module.sourceOverrides,
          readText: false,
        );
      }
    }
    return WritersideReferenceData(
      glossary: {
        for (final term
            in glossary?.findAllElements('term') ?? const <XmlElement>[])
          if (term.getAttribute('name') case final name?)
            name: term.innerText.trim(),
      },
      shortcuts: shortcuts,
      layouts: layouts,
      resources: resources,
      sources: sources,
    );
  }
}
