import 'dart:convert';

import 'writerside_model.dart';

class WritersideSummaryExporter {
  const WritersideSummaryExporter();

  String export(WritersideModule module) {
    return const JsonEncoder.withIndent('  ').convert(toJson(module));
  }

  Map<String, Object?> toJson(WritersideModule module) {
    final config = module.config;
    return {
      'rootPath': module.rootPath,
      'config': {
        'filePath': config.filePath,
        'fileName': config.configFileName,
        'version': config.version,
        'moduleName': config.moduleName,
        'topicRoots': [
          for (final root in config.topicRoots)
            {'dir': root.dir, 'explicit': root.explicit},
        ],
        'imageRoots': [
          for (final root in config.imageRoots)
            {
              'dir': root.dir,
              'version': root.version,
              'webPath': root.webPath,
              'explicit': root.explicit,
            },
        ],
        'buildConfigDir': config.buildConfigDir,
        'buildConfigExplicit': config.buildConfigExplicit,
        'apiSpecificationsDir': config.apiSpecificationsDir,
        'apiSpecificationsExplicit': config.apiSpecificationsExplicit,
        'snippetsDir': config.snippetsDir,
        'resourcesFile': config.resourcesFile,
        'resourcesDir': config.resourcesDir,
        'varsFile': config.varsFile,
        'categoriesFile': config.categoriesFile,
        'instanceGroupsFile': config.instanceGroupsFile,
        'instances': [
          for (final instance in config.instances)
            {
              'src': instance.src,
              'webPath': instance.webPath,
              'version': instance.version,
              'keymapsMode': instance.keymapsMode,
            },
        ],
        'settings': {
          'smartIgnoreVars': config.settings.smartIgnoreVars,
          'disableWebNamePreprocessing':
              config.settings.disableWebNamePreprocessing,
          'wrsSupernovaUseVersion': config.settings.wrsSupernovaUseVersion,
          'capsRules': [
            for (final rule in config.settings.capsRules)
              {'style': rule.style, 'target': rule.target},
          ],
          'defaultProperties': [
            for (final property in config.settings.defaultProperties)
              {
                'elementName': property.elementName,
                'propertyName': property.propertyName,
                'value': property.value,
              },
          ],
        },
      },
      'instances': [
        for (final instance in module.instances)
          {
            'id': instance.id,
            'name': instance.name,
            'sourceTreePath': instance.sourceTreePath,
            'startPage': instance.startPage,
            'status': instance.status,
            'isLibrary': instance.isLibrary,
            'topics': instance.topicFileSet.toList()..sort(),
          },
      ],
      'topics': [
        for (final topic in module.topics)
          {
            'id': topic.id,
            'fileName': topic.fileName,
            'baseName': topic.baseName,
            'filePath': topic.filePath,
            'topicRoot': topic.topicRoot,
            'format': topic.format.name,
            'title': topic.title,
            'webFileName': topic.webFileName,
            'titleOverrides': [
              for (final override in topic.titleOverrides)
                {'instance': override.instance, 'title': override.title},
            ],
          },
      ],
      'diagnostics': [
        for (final diagnostic in module.diagnostics)
          {
            'code': diagnostic.code,
            'severity': diagnostic.severity.name,
            'message': diagnostic.message,
            'filePath': diagnostic.filePath,
          },
      ],
    };
  }
}
