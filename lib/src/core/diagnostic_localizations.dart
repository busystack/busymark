import 'package:flutter/widgets.dart';

import '../app/localization.dart';
import 'diagnostic.dart';

String localizeDiagnostic(BuildContext context, Diagnostic diagnostic) {
  final l10n = context.l10n;
  final args = diagnostic.args;
  final code = diagnostic.code;
  String value(String key) => '${args[key] ?? ''}';

  return switch (code) {
    'workspace.file.stat-failed' => l10n.diagnosticWorkspaceFileStatFailed(
      value('error'),
    ),
    'workspace.scan.skipped' => l10n.diagnosticWorkspaceScanSkipped,
    'workspace.scan.document-limit' => l10n.diagnosticWorkspaceScanSkipped,
    'workspace.scan.inspect-failed' =>
      l10n.diagnosticWorkspaceScanInspectFailed(value('error')),
    'workspace.file.too-large' => l10n.diagnosticWorkspaceFileTooLarge,
    'workspace.file.read-failed' => l10n.diagnosticWorkspaceFileReadFailed(
      value('error'),
    ),
    'markdown.attribute.malformed' => l10n.diagnosticMarkdownAttributeMalformed,
    'markdown.heading.duplicate-id' =>
      l10n.diagnosticMarkdownHeadingDuplicateId(value('id')),
    'writerside.topic.h1-converted-to-chapter' =>
      l10n.diagnosticWritersideTopicH1ConvertedToChapter,
    'writerside.topic.missing-title' =>
      diagnostic.filePath.endsWith('.topic')
          ? l10n.diagnosticWritersideXmlTopicMissingTitle
          : args.containsKey('fileName')
          ? l10n.diagnosticWritersideTopicFileMissingTitle(value('fileName'))
          : l10n.diagnosticWritersideMarkdownTopicMissingTitle,
    'markdown.front-matter.malformed' =>
      l10n.diagnosticMarkdownFrontMatterMalformed,
    'markdown.raw-html.unsafe' => l10n.diagnosticMarkdownRawHtmlUnsafe,
    'markdown.link.unresolved-target' =>
      args.containsKey('destination')
          ? l10n.diagnosticWritersideTopicLinkUnresolved(value('destination'))
          : l10n.diagnosticMarkdownLinkUnresolvedTarget(value('targetPath')),
    'markdown.link.unresolved-anchor' =>
      args.containsKey('targetName')
          ? l10n.diagnosticWritersideAnchorUnresolved(
              value('anchor'),
              value('targetName'),
            )
          : l10n.diagnosticMarkdownLinkUnresolvedAnchor(value('anchor')),
    'markdown.image.missing-alt' => l10n.diagnosticMarkdownImageMissingAlt(
      value('destination'),
    ),
    'markdown.image.missing-file' => l10n.diagnosticMarkdownImageMissingFile(
      value('destination'),
    ),
    'writerside.config.invalid-xml' ||
    'writerside.build-profiles.invalid-xml' ||
    'writerside.instance-groups.invalid-xml' ||
    'writerside.tree.invalid-xml' ||
    'writerside.variables.invalid-xml' ||
    'writerside.categories.invalid-xml' ||
    'writerside.topic.invalid-xml' => l10n.diagnosticInvalidXml(
      value('message'),
    ),
    'writerside.config.invalid-root' =>
      l10n.diagnosticWritersideConfigInvalidRoot,
    'writerside.config.path-unsafe' => l10n.errorFileOperationOutsideRoot,
    'writerside.config.missing-snippets-src' =>
      l10n.diagnosticWritersideConfigMissingSnippetsSrc,
    'writerside.config.missing-instance-groups-src' =>
      l10n.diagnosticWritersideConfigMissingInstanceGroupsSrc,
    'writerside.config.invalid-keymaps-mode' =>
      l10n.diagnosticWritersideConfigInvalidKeymapsMode(value('mode')),
    'writerside.config.missing-instance-src' =>
      l10n.diagnosticWritersideConfigMissingInstanceSrc,
    'writerside.config.missing-instance' =>
      l10n.diagnosticWritersideConfigMissingInstance,
    'writerside.tree.invalid-root' => l10n.diagnosticWritersideTreeInvalidRoot,
    'writerside.tree.missing-id' => l10n.diagnosticWritersideTreeMissingId,
    'writerside.tree.id-mismatch' => l10n.diagnosticWritersideTreeIdMismatch(
      value('id'),
    ),
    'writerside.tree.invalid-status' =>
      l10n.diagnosticWritersideTreeInvalidStatus(value('status')),
    'writerside.tree.duplicate-instance-id' =>
      l10n.diagnosticWritersideDuplicateInstanceId(value('id')),
    'writerside.tree.invalid-include' =>
      l10n.diagnosticWritersideTreeInvalidInclude,
    'writerside.tree.missing-snippet-id' =>
      l10n.diagnosticWritersideTreeMissingSnippetId,
    'writerside.tree.invalid-cross-instance-reference' =>
      l10n.diagnosticWritersideTreeInvalidCrossInstanceReference,
    'writerside.tree.conflicting-toc-targets' =>
      l10n.diagnosticWritersideTreeConflictingTargets,
    'writerside.tree.duplicate-element-id' =>
      l10n.diagnosticWritersideTreeDuplicateElementId(value('id')),
    'writerside.instance-groups.invalid-root' =>
      l10n.diagnosticWritersideInstanceGroupsInvalidRoot,
    'writerside.instance-groups.invalid-group' =>
      l10n.diagnosticWritersideInstanceGroupInvalid,
    'writerside.instance-groups.duplicate-id' =>
      l10n.diagnosticWritersideInstanceGroupDuplicateId(value('id')),
    'writerside.tree.external-include' =>
      l10n.diagnosticWritersideExternalTreeInclude(
        value('source'),
        value('id'),
        value('origin'),
      ),
    'writerside.tree.unsafe-include-source' =>
      l10n.errorFileOperationOutsideRoot,
    'writerside.tree.unresolved-include-source' =>
      l10n.diagnosticWritersideIncludeSourceMissing(value('source')),
    'writerside.tree.unresolved-include-element' =>
      l10n.diagnosticWritersideTreeIncludeElementMissing(
        value('source'),
        value('id'),
      ),
    'writerside.tree.circular-include' =>
      l10n.diagnosticWritersideTreeCircularInclude(
        value('source'),
        value('id'),
      ),
    'writerside.tree.unknown-instance-group' =>
      l10n.diagnosticWritersideUnknownInstanceGroup(value('group')),
    'writerside.tree.missing-reference-instance' =>
      l10n.diagnosticWritersideReferenceInstanceMissing(value('instance')),
    'writerside.tree.missing-reference-topic' =>
      l10n.diagnosticWritersideReferenceTopicMissing(
        value('topic'),
        value('instance'),
      ),
    'writerside.build-profiles.invalid-root' =>
      l10n.diagnosticWritersideBuildProfilesInvalidRoot,
    'writerside.build-profiles.invalid-boolean' =>
      l10n.diagnosticWritersideBuildProfilesInvalidBoolean(
        value('name'),
        value('value'),
      ),
    'writerside.build-profiles.missing-instance' =>
      l10n.diagnosticWritersideBuildProfileMissingInstance,
    'writerside.tree.missing-start-page' =>
      args.containsKey('startPage')
          ? l10n.diagnosticWritersideStartPageMissing(value('startPage'))
          : l10n.diagnosticWritersideTreeMissingStartPage,
    'writerside.tree.duplicate-topic' =>
      l10n.diagnosticWritersideTreeDuplicateTopic(value('topic')),
    'writerside.variable.malformed-declaration' =>
      l10n.diagnosticWritersideVariableMalformedDeclaration,
    'writerside.variable.duplicate-name' =>
      l10n.diagnosticWritersideVariableDuplicateName(value('name')),
    'writerside.category.missing-id' =>
      l10n.diagnosticWritersideCategoryMissingId,
    'writerside.category.duplicate-id' =>
      l10n.diagnosticWritersideCategoryDuplicateId(value('id')),
    'writerside.category.duplicate-order' =>
      l10n.diagnosticWritersideCategoryDuplicateOrder(value('order')),
    'writerside.topic.invalid-root' =>
      l10n.diagnosticWritersideTopicInvalidRoot,
    'writerside.topic.missing-root-id' =>
      l10n.diagnosticWritersideTopicMissingRootId,
    'writerside.topic.root-id-mismatch' =>
      l10n.diagnosticWritersideTopicRootIdMismatch(
        value('id'),
        value('expectedId'),
      ),
    'writerside.topic.duplicate-element-id' =>
      l10n.diagnosticWritersideTopicDuplicateElementId(value('elementId')),
    'writerside.topic.missing-required-attribute' =>
      l10n.diagnosticWritersideTopicAnchorMissingHref,
    'writerside.config.missing' => l10n.diagnosticWritersideConfigMissing,
    'writerside.config.missing-build-config-directory' =>
      l10n.diagnosticWritersideConfigMissingBuildConfigDirectory(
        value('relativePath'),
      ),
    'writerside.config.missing-api-specifications-directory' =>
      l10n.diagnosticWritersideConfigMissingApiSpecificationsDirectory(
        value('relativePath'),
      ),
    'writerside.config.missing-snippets-directory' =>
      l10n.diagnosticWritersideConfigMissingSnippetsDirectory(
        value('relativePath'),
      ),
    'writerside.config.missing-vars-file' =>
      l10n.diagnosticWritersideConfigMissingVarsFile(value('relativePath')),
    'writerside.config.missing-categories-file' =>
      l10n.diagnosticWritersideConfigMissingCategoriesFile(
        value('relativePath'),
      ),
    'writerside.config.missing-instance-groups-file' =>
      l10n.diagnosticWritersideConfigMissingInstanceGroupsFile(
        value('relativePath'),
      ),
    'writerside.config.missing-instance-tree' =>
      l10n.diagnosticWritersideConfigMissingInstanceTree(value('source')),
    'writerside.topic.read-failed' => l10n.diagnosticWritersideTopicReadFailed(
      value('error'),
    ),
    'writerside.config.missing-directory' =>
      args['kind'] == 'topicsDefault'
          ? l10n.diagnosticWritersideDefaultTopicsDirectoryMissing(
              value('relativePath'),
            )
          : args['kind'] == 'topics'
          ? l10n.diagnosticWritersideTopicsDirectoryMissing(
              value('relativePath'),
            )
          : l10n.diagnosticWritersideImagesDirectoryMissing(
              value('relativePath'),
            ),
    'writerside.topic.duplicate-id' =>
      l10n.diagnosticWritersideTopicDuplicateId(value('id')),
    'writerside.tree.missing-topic' =>
      l10n.diagnosticWritersideTreeMissingTopic(value('topic')),
    'writerside.tree.invalid-href' => l10n.diagnosticWritersideTreeInvalidHref(
      value('href'),
    ),
    'writerside.variable.unresolved' =>
      l10n.diagnosticWritersideVariableUnresolved(value('name')),
    'writerside.include.unresolved-source' =>
      args.containsKey('from')
          ? l10n.diagnosticWritersideIncludeSourceMissing(value('from'))
          : l10n.diagnosticWritersideIncludeMissingFrom,
    'writerside.include.unresolved-element' =>
      l10n.diagnosticWritersideIncludeElementMissing(
        value('elementId'),
        value('from'),
      ),
    'writerside.category.unresolved' =>
      l10n.diagnosticWritersideCategoryUnresolved(value('ref')),
    'writerside.topic.ambiguous-reference' =>
      l10n.diagnosticWritersideTopicAmbiguousReference(value('reference')),
    _ => l10n.diagnosticUnknown(code),
  };
}
