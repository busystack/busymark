// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get notesNewFromRetainedText => '从保留的文本新建笔记';

  @override
  String get notesAccountThrottled => 'Nextcloud 要求暂停。请等待后再重新登录。';

  @override
  String get notesSettingsRefreshing => '正在按已确认的设置更新笔记';

  @override
  String get notesExportOperationFailed => '导出在发布前失败。请检查来源和目标后重新导出。';

  @override
  String get notesRecoveryCreatedNotOpened =>
      '恢复的笔记已保存，但无法打开。请处理待保存的编辑或属性，再打开这篇已有笔记。';

  @override
  String get notesSettingsPendingNotes =>
      '待处理的笔记、冲突或结果不明的创建阻止了此更改。请在笔记中同步或检查，再重试保留的设置草稿。';

  @override
  String get notesSettingsPendingAttachments =>
      '待处理的附件操作阻止了此更改。请在笔记中检查附件，再重试保留的设置草稿。';

  @override
  String get notesAccountServerAddress =>
      '请使用 Nextcloud 的规范 HTTPS 地址并重新登录。无法验证地址或重定向。';

  @override
  String get notesAccountUnsupported =>
      '笔记不可用或 API 不受支持。请启用 API 主版本为 1、次版本不低于 4 的 Nextcloud Notes。';

  @override
  String get notesAccountAuthorizeAgain => 'Nextcloud 拒绝了凭据。请重新授权或重新连接账户。';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud 拒绝了笔记功能检查。请联系管理员允许此检查后重试。';

  @override
  String get notesAccountMalformed => '无法验证 Nextcloud 的响应。请检查服务器安装并重新登录。';

  @override
  String get notesAccountTimedOut => '登录超时。请重新登录并在浏览器中完成授权。';

  @override
  String get notesAccountBrowserUnavailable => '无法打开系统浏览器。请检查默认浏览器并重新登录。';

  @override
  String get notesAccountNetwork => '无法连接 Nextcloud。请检查网络和服务器后重新登录。';

  @override
  String get notesAccountRejected => 'Nextcloud 拒绝了功能请求。请与管理员确认访问权限后重试。';

  @override
  String get notesAccountFailed => '无法完成账户设置。请重新登录。';

  @override
  String get notesTransferSourceChanged => '来源在审核后已更改。请重新审核当前文件或创建新快照后重试。';

  @override
  String get notesTransferUnreadable => '无法读取来源。请检查文件或文件夹的访问权限，再重新审核。';

  @override
  String get notesTransferInvalidSnapshot =>
      '快照无效或不受支持。请选择有效的 BusyMark Notes 快照或 Markdown 来源。';

  @override
  String get notesTransferMediaLimit => '媒体超出导入大小限制。请缩小受影响项目的媒体，再重新审核。';

  @override
  String get notesTransferUnsafeSource => '来源包含不安全的路径。请选择来源文件夹内的文件并重新审核。';

  @override
  String get notesTransferDestination => '无法写入导出内容。请检查目标的访问权限和可用空间后重新导出。';

  @override
  String get notesTransferOperationFailed => '传输未能完成。请检查受影响的项目并重试。之前导入的项目仍已保存。';

  @override
  String get notesExportPublishedWithOmissions => '导出已发布，但有遗漏';

  @override
  String get notesBatchUnchanged => '请求的值已经设置。';

  @override
  String get notesBatchReadOnly => '此笔记为只读。受保护的属性无法更改，但仍可修改收藏状态。';

  @override
  String get notesBatchReviewChanged => '此笔记在审核后已更改。请审核当前状态后重新执行操作。';

  @override
  String get notesBatchMissing => '此笔记已不可用。请刷新列表并重新检查操作目标。';

  @override
  String get notesBatchStorage => '本地保存失败。请检查存储并重试此项目；成功的项目仍已保存。';

  @override
  String get notesRemoteReviewChanged => '服务器笔记已更改。合并草稿已保留。请审核更新的比较并重新选择解决方式。';

  @override
  String get notesReviewRemote => '我已审核当前服务器版本';

  @override
  String get wsModuleCapsNotPublished => '模块的大小写规则不会发布。';

  @override
  String get wsTitleOverridesAction => '实例与目录标题…';

  @override
  String get wsHeadingNotPublished => '此构建器不会发布此属性。';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      '固定版本构建器不发布 Markdown 主题的实例标题覆盖。保留现有标记，请在源码中查看。';

  @override
  String get wsTopicIdentity => '主题 ID';

  @override
  String get wsElementAnchor => '元素锚点';

  @override
  String get wsHeadingText => '标题文本';

  @override
  String get wsDefaultTitle => '默认标题';

  @override
  String get wsTopicNavigation => '主题导航';

  @override
  String get wsHeadingOptions => '标题属性';

  @override
  String get wsDocumentOptions => '文档设置';

  @override
  String get wsSettingsPresent => '存在已编写设置';

  @override
  String get wsTitleOverrideExplanation => '覆盖发布的标题；标题文本保持不变。';

  @override
  String get wsIgnoreVariables => '将变量视为字面文本';

  @override
  String get wsIgnoreVariablesExplanation => '启用时，不替换类似变量的文本。';

  @override
  String get wsInstanceSelection => '帮助实例';

  @override
  String get wsInstanceExplanation => '通过名称、组、列表、排除项或表达式选择帮助输出。';

  @override
  String get wsFilterExplanation => '按条件筛选可复用内容；这不会选择帮助实例。';

  @override
  String get wsContextHelp => '上下文帮助 ID';

  @override
  String get wsCapitalization => '大小写';

  @override
  String get wsLibraryTopic => '库主题';

  @override
  String get wsLastModified => '最后修改';

  @override
  String get wsMissingTopicHeading => '尚未编写主题 H1。请在源码中添加。';

  @override
  String get wsMultipleTopicHeadings => '第一个 H1 决定主题标题，后续 H1 是独立标题。';

  @override
  String get wsTopicIdentityMismatch => '根 id 与文件名派生的主题 ID 不同。请重命名主题文件或查看源码。';

  @override
  String get wsUnsupportedProperties => '保留不受支持的属性。请在源码中查看。';

  @override
  String get wsGeneratedAnchor => '自动生成的锚点；输入值可覆盖。';

  @override
  String get wsHeadingBuilderLimitation =>
      '固定版本构建器不发布 H1 属性。属性属于标题，而非 XML 根元素。';

  @override
  String get closeOtherTabs => '关闭其他标签页';

  @override
  String get tocTopicFromTemplate => '从模板创建主题...';

  @override
  String get tocSaveAsTemplate => '保存为模板';

  @override
  String get tocTemplateDialog => '从模板创建主题';

  @override
  String get tocTemplatesEditor => '文件和代码模板';

  @override
  String get tocEditTemplates => '编辑模板...';

  @override
  String get tocCreateCustomTemplate => '创建自定义模板...';

  @override
  String get tocTemplateCreated => '已创建模板';

  @override
  String get tocTemplateDefault => '默认';

  @override
  String get tocTemplateCustom => '自定义';

  @override
  String get tocTemplateFilename => '文件名：';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => '内部';

  @override
  String get tocTemplateUnnamed => '未命名';

  @override
  String get tocTemplateNew => '新建模板...';

  @override
  String get tocTemplateName => '名称：';

  @override
  String get tocTemplateExtension => '扩展名：';

  @override
  String get tocTemplateLoadError => '无法加载模板。现有模板未更改。';

  @override
  String get tocTemplateSaveError => '无法保存模板。您的编辑内容仍保留在此处。';

  @override
  String get tocTemplateConflict => '模板已在其他窗口中更改。请取消并重新打开编辑器。';

  @override
  String get tocTemplateDuplicateName => '已存在相同名称和扩展名的模板。';

  @override
  String get tocTemplateFormat => '格式：';

  @override
  String get tocTemplateReset => '重置';

  @override
  String get tocTemplateRetry => '重试';

  @override
  String tocRemoveElementsDialog(int count) {
    return '移除 $count 个目录元素';
  }

  @override
  String get tocRemoveElementsRetainFiles => '不会删除与这些目录元素关联的源文件。';

  @override
  String get tocOk => '确定';

  @override
  String get tocSelectExistingTopic => '选择要添加到当前实例的主题';

  @override
  String get tocGroupName => '组名';

  @override
  String get tocMoveLineUp => '上移行';

  @override
  String get tocMoveLineDown => '下移行';

  @override
  String get tocEmptyMdTopic => '空 MD 主题';

  @override
  String get tocEmptyXmlTopic => '空 XML 主题';

  @override
  String get tocCopySpecial => '特殊复制';

  @override
  String tocCopyFileName(String name) {
    return '主题文件名 \'$name\'';
  }

  @override
  String get tocCopyFilePath => '主题文件路径';

  @override
  String tocCopyTopicTitle(String title) {
    return '主题标题 \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return '目录元素 ID \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => '主题文件名';

  @override
  String get tocCopyTopicTitleUnavailable => '主题标题';

  @override
  String get tocCopyElementIdUnavailable => '目录元素 ID';

  @override
  String get tocEditTitleAction => '编辑标题...';

  @override
  String get tocEditTitleDialog => '编辑标题';

  @override
  String get tocRemoveElementAction => '移除目录元素...';

  @override
  String get tocSetHomePage => '设为主页';

  @override
  String tocGoToElement(String fileName) {
    return '转到“$fileName”中的目录元素';
  }

  @override
  String get tocSynchronize => '同步目录与编辑器';

  @override
  String get tocEmptyGroupAction => '空组';

  @override
  String get tocNewEmptyGroup => '新建空组';

  @override
  String get tocGroupAction => '分组';

  @override
  String get tocNewGroup => '新建组';

  @override
  String get tocSortChildren => '按字母顺序排列子主题';

  @override
  String get tocLinkTopicFiles => '将主题文件链接到目录...';

  @override
  String get addLocalMarkdownFiles => '添加本地 Markdown 文件';

  @override
  String get tocTitleField => '目录标题:';

  @override
  String get tocTopicTitleField => '主题标题:';

  @override
  String get tocAdvancedSettings => '高级设置';

  @override
  String tocInstanceTitleField(String instanceId) {
    return '“$instanceId”的标题:';
  }

  @override
  String get tocOnlyTitleField => '仅用于目录的标题:';

  @override
  String get tocInstanceTitleExplanation => '仅用于当前实例。默认继承主题标题。';

  @override
  String get tocOnlyTitleExplanation =>
      '仅用于目录。默认继承主题标题；如果设置了实例专用标题，则继承该标题。标题的说明见';

  @override
  String get tocTitleDocumentationLink => '此处';

  @override
  String get tocFindUsages => '查找';

  @override
  String get tocRefactorMenu => '重构';

  @override
  String get tocSafeDelete => '安全删除';

  @override
  String get tocDuplicate => '创建副本';

  @override
  String get tocDuplicateFilename => '主题文件名:';

  @override
  String get tocDuplicateDialog => '创建主题副本';

  @override
  String get pdfTitlePage => '标题页';

  @override
  String get pdfIncludeTitlePage => '包含标题页';

  @override
  String get pdfTitlePageNote => '此页不显示页眉、页脚或页码。';

  @override
  String get pdfTitlePageTitle => '标题';

  @override
  String get pdfTitlePageSubtitle => '副标题';

  @override
  String get pdfTitlePageAuthor => '作者';

  @override
  String get pdfTitlePageOrganization => '组织';

  @override
  String get pdfTitlePageVersion => '版本';

  @override
  String get pdfTitlePageDate => '日期';

  @override
  String get pdfTitlePageTitleRequired => '请输入标题页的标题。';

  @override
  String get pdfTocSectionNote => '从单独一页开始，可以跨多页。';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle => 'Markdown 文件和兼容 Writerside 的文档项目编辑器。';

  @override
  String get aboutBusyMark => '关于 BusyMark';

  @override
  String get aboutTagline => 'Markdown 和 Writerside 编辑器';

  @override
  String get aboutLicenseLabel => '许可证';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => '网站';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get reportIssue => '报告问题';

  @override
  String get feedbackCategory => '类别';

  @override
  String get feedbackChooseCategory => '选择类别';

  @override
  String get feedbackCategoryProblem => '问题或错误';

  @override
  String get feedbackCategoryFeature => '功能请求';

  @override
  String get feedbackCategoryPrivacySecurity => '隐私或安全问题';

  @override
  String get feedbackCategoryUsability => '可用性问题';

  @override
  String get feedbackCategoryOther => '其他';

  @override
  String get feedbackSubject => '主题';

  @override
  String get feedbackMessage => '详细留言';

  @override
  String get feedbackReplyEmail => '回复邮箱（可选）';

  @override
  String get feedbackIncludeTechnicalDetails => '包含技术详细信息';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      '启用后，此选项仅会添加您的 Linux 操作系统版本和 BusyMark 应用语言。不会附加日志、文件、账户数据或其他诊断信息。';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get feedbackSubmitting => '正在提交…';

  @override
  String get feedbackCategoryRequired => '请选择类别。';

  @override
  String get feedbackSubjectLength => '主题必须包含 3 到 120 个字符。';

  @override
  String get feedbackMessageLength => '信息必须包含 10 到 5,000 个字符。';

  @override
  String get feedbackReplyEmailInvalid => '请输入有效的邮箱地址，或将此字段留空。';

  @override
  String get feedbackConnectionFailure => 'BusyMark 无法连接。请检查网络连接后重试。';

  @override
  String get feedbackTimeoutFailure => '请求超时。请重试。';

  @override
  String get feedbackRateLimitedFailure => '此连接发送的报告过多。请稍候再试。';

  @override
  String get feedbackRejectedFailure => '服务器拒绝了此报告。请检查表单字段后重试。';

  @override
  String get feedbackServerFailure => '服务器无法接收此报告。请稍后重试。';

  @override
  String feedbackSuccess(String id) {
    return '反馈已发送。参考 ID：$id';
  }

  @override
  String get advanced => '高级';

  @override
  String get addToGit => '添加到 Git';

  @override
  String get appearance => '外观';

  @override
  String get apply => '应用';

  @override
  String get back => '返回';

  @override
  String get bottomLeft => '左下';

  @override
  String get bottomRight => '右下';

  @override
  String get cancel => '取消';

  @override
  String get choose => '选择';

  @override
  String get chooseLocation => '选择位置';

  @override
  String get copy => '复制';

  @override
  String get copyPlainText => '复制为纯文本';

  @override
  String get clipboardCopyFailed => '无法将所选内容复制到剪贴板。';

  @override
  String get copyName => '复制名称';

  @override
  String get copyFileName => '复制文件名';

  @override
  String get copyPath => '复制路径';

  @override
  String get create => '创建';

  @override
  String get creating => '正在创建…';

  @override
  String get cut => '剪切';

  @override
  String get promoteSection => '提升节级别';

  @override
  String get demoteSection => '降低节级别';

  @override
  String get moveSectionUp => '上移节';

  @override
  String get moveSectionDown => '下移节';

  @override
  String get confirmDeleteSectionTitle => '删除此节？';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '删除“$name”及其节中的全部内容？此操作无法撤销。';
  }

  @override
  String get darkTheme => '深色';

  @override
  String get delete => '删除';

  @override
  String get discard => '放弃';

  @override
  String get editor => '编辑器';

  @override
  String get file => '文件';

  @override
  String get fileHistory => '文件历史记录';

  @override
  String get folder => '文件夹';

  @override
  String get insert => '插入';

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get commandUnavailableInContext => '当前编辑器上下文中无法使用此命令';

  @override
  String get lightTheme => '浅色';

  @override
  String get mainMenu => '主菜单';

  @override
  String get fullScreen => '全屏';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => '打开';

  @override
  String get openInFiles => '在文件中打开';

  @override
  String get pathActions => '路径操作';

  @override
  String get outline => '大纲';

  @override
  String get overwrite => '覆盖';

  @override
  String get paste => '粘贴';

  @override
  String get reading => '阅读';

  @override
  String get removeFromRecent => '从最近使用记录中移除';

  @override
  String get recent => '最近使用';

  @override
  String get redo => '重做';

  @override
  String get save => '保存';

  @override
  String get search => '搜索';

  @override
  String get selectAll => '全选';

  @override
  String get settings => '设置';

  @override
  String get source => '源代码';

  @override
  String get split => '拆分';

  @override
  String get systemTheme => '系统';

  @override
  String get theme => '主题';

  @override
  String get appLanguage => '语言';

  @override
  String get systemLanguage => '系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk bokmål';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEstonian => 'Eesti';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get toggleSidebar => '侧边栏面板';

  @override
  String get topLeft => '左上';

  @override
  String get topRight => '右上';

  @override
  String get undo => '撤销';

  @override
  String get validate => '验证';

  @override
  String get validation => '验证';

  @override
  String get viewMode => '视图模式';

  @override
  String get welcome => '欢迎';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => '图像';

  @override
  String get openMarkdownFile => '打开 Markdown 文件';

  @override
  String get markdownFileExtensions => '.md 或 .markdown';

  @override
  String get openFolderOrWritersideProject => '打开文件夹或 Writerside 项目';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown 文件夹或兼容 Writerside 的项目';

  @override
  String get noOpenFile => '没有打开的文件';

  @override
  String get shortcutDeleteTreeItemDescription => '删除选中的文件项，或从目录中移除选中的主题';

  @override
  String get shortcutGroupGeneral => '常规';

  @override
  String get shortcutNewDocument => '创建';

  @override
  String get shortcutNewDocumentDescription => '创建 Markdown 文件或 Writerside 项目';

  @override
  String get shortcutOpenDescription => '打开 Markdown 文件、文件夹或 Writerside 项目';

  @override
  String get shortcutSaveDescription => '保存当前文档';

  @override
  String get shortcutSearchDescription => '搜索当前工作区';

  @override
  String get shortcutKeyboardShortcutsDescription => '自定义应用程序键盘快捷键';

  @override
  String get shortcutSyntaxReferenceDescription => '打开语法参考';

  @override
  String get shortcutSettingsDescription => '打开 BusyMark 设置';

  @override
  String get shortcutNextTab => '下一个标签页';

  @override
  String get shortcutNextTabDescription => '移至下一个打开的标签页';

  @override
  String get shortcutPreviousTab => '上一个标签页';

  @override
  String get shortcutPreviousTabDescription => '移至上一个打开的标签页';

  @override
  String get shortcutCloseTab => '关闭标签页';

  @override
  String get shortcutCloseTabDescription => '关闭当前标签页';

  @override
  String get shortcutCloseAllTabs => '关闭所有标签页';

  @override
  String get shortcutCloseAllTabsDescription => '关闭所有打开的标签页';

  @override
  String get shortcutGroupTextEditing => '文本编辑';

  @override
  String get shortcutSelectAllDescription => '在源代码模式下选择全部文本；在编辑器模式下按两次以选择所有块';

  @override
  String get shortcutCutDescription => '剪切选中的文本';

  @override
  String get shortcutCopyDescription => '复制选中的文本';

  @override
  String get shortcutPasteDescription => '从剪贴板粘贴';

  @override
  String get shortcutPastePlainTextDescription => '粘贴剪贴板中的无格式文本';

  @override
  String get shortcutUndoDescription => '撤销上次编辑';

  @override
  String get shortcutRedoDescription => '重做上次撤销的编辑';

  @override
  String get shortcutInsertIndentation => '插入缩进';

  @override
  String get shortcutInsertIndentationDescription => '在光标处插入缩进';

  @override
  String get shortcutOutdentSource => '减少源代码缩进';

  @override
  String get shortcutOutdentSourceDescription => '在源代码模式下减少一级缩进';

  @override
  String get shortcutEscape => '关闭搜索或清除块选择';

  @override
  String get shortcutEscapeDescription => '关闭工作区搜索，或在编辑器模式下清除块选择';

  @override
  String get shortcutGroupFormatting => '格式';

  @override
  String get shortcutBoldDescription => '切换选中文本的粗体';

  @override
  String get shortcutItalicDescription => '切换选中文本的斜体';

  @override
  String get shortcutUnderlineDescription => '切换选中文本的下划线';

  @override
  String get shortcutLinkDescription => '插入或编辑链接';

  @override
  String get shortcutInlineCodeDescription => '切换选中文本的行内代码格式';

  @override
  String get shortcutStrikethroughDescription => '切换选中文本的删除线';

  @override
  String get shortcutGroupBlocks => '块';

  @override
  String get shortcutParagraphDescription => '将当前块设为段落';

  @override
  String get shortcutHeading1Description => '将当前块设为标题 1';

  @override
  String get shortcutHeading2Description => '将当前块设为标题 2';

  @override
  String get shortcutHeading3Description => '将当前块设为标题 3';

  @override
  String get shortcutHeading4Description => '将当前块设为标题 4';

  @override
  String get shortcutHeading5Description => '将当前块设为标题 5';

  @override
  String get shortcutHeading6Description => '将当前块设为标题 6';

  @override
  String get shortcutGroupLists => '列表';

  @override
  String get numberedList => '编号列表';

  @override
  String get shortcutNumberedListDescription => '切换编号列表格式';

  @override
  String get bulletedList => '项目符号列表';

  @override
  String get shortcutBulletedListDescription => '切换项目符号列表格式';

  @override
  String get checklist => '检查清单';

  @override
  String get shortcutChecklistDescription => '切换检查清单格式';

  @override
  String get shortcutGroupSidebar => '侧边栏';

  @override
  String get sidebarViewMenu => '侧边栏视图';

  @override
  String get createMarkdownFile => '创建 Markdown 文件';

  @override
  String get createMarkdownFileDescription => '开始创建未保存的本地 Markdown 文档';

  @override
  String get createWritersideProject => '创建 Writerside 项目';

  @override
  String get createWritersideProjectDescription => '开始创建本地兼容 Writerside 的项目';

  @override
  String get defaultProjectName => '文档';

  @override
  String get defaultInstanceName => '用户指南';

  @override
  String get defaultStartTopicTitle => '开始使用';

  @override
  String get projectName => '项目名称';

  @override
  String get directoryName => '目录名称';

  @override
  String get instanceName => '实例名称';

  @override
  String get instanceId => '实例 ID';

  @override
  String get startTopicTitle => '起始主题标题';

  @override
  String get location => '位置';

  @override
  String get projectNameRequired => '项目名称为必填项。';

  @override
  String get directoryNameRequired => '目录名称为必填项。';

  @override
  String get useSingleSafeDirectoryName => '使用单一且安全的目录名称。';

  @override
  String get useLowercaseIdentifier => '使用仅包含小写字母、数字、下划线或连字符的小写标识符。';

  @override
  String get startTopicTitleRequired => '起始主题标题为必填项。';

  @override
  String get createWritersideProjectFailed => '无法创建 Writerside 项目。';

  @override
  String get settingsTitle => 'BusyMark 设置';

  @override
  String get autoSave => '自动保存';

  @override
  String get autoSaveDescription => '在短暂空闲后自动保存文件更改。';

  @override
  String get wordWrap => '自动换行';

  @override
  String get wordWrapDescription => '将长行换行以适应编辑器宽度，而不是水平滚动。';

  @override
  String get editorFontSize => '编辑器字体大小';

  @override
  String get validateOnEdit => '编辑时验证';

  @override
  String get clearRecentWorkspaces => '清除最近记录';

  @override
  String get editingButtonsPosition => '编辑按钮位置';

  @override
  String get editingButtonsPositionDescription => '选择浮动 WYSIWYG 编辑按钮的显示位置。';

  @override
  String get editingButtonsDirection => '编辑按钮方向';

  @override
  String get editingButtonsDirectionDescription => '选择水平或垂直排列浮动 WYSIWYG 编辑按钮。';

  @override
  String get horizontal => '水平';

  @override
  String get vertical => '垂直';

  @override
  String get privacy => '隐私';

  @override
  String get allowRemoteImages => '加载远程图像';

  @override
  String get allowRemoteImagesDescription =>
      '允许 Markdown 预览和编辑器从 http 和 https URL 加载图像。';

  @override
  String get clearRemoteImagePermissions => '清除远程图像权限';

  @override
  String get clearRemoteImagePermissionsDescription => '忘记已获准加载远程图像的工作区。';

  @override
  String get clearGitWorkspaceTrust => '清除受信任的 Git 工作区';

  @override
  String get clearGitWorkspaceTrustDescription => '为之前受信任的工作区启用 Git 功能前先进行询问。';

  @override
  String get settingsEditingButtonsSectionTitle => '编辑按钮';

  @override
  String get spellingDictionaries => '拼写词典';

  @override
  String get spellingDictionariesDescription => '安装和管理拼写词典';

  @override
  String get settingsDictionariesSectionTitle => '词典';

  @override
  String get availableSpellingDictionaries => '可用词典';

  @override
  String get customSpellingDictionaries => '自定义词典';

  @override
  String get spellingDictionaryProblems => '词典问题';

  @override
  String get settingsWindowSectionTitle => '窗口';

  @override
  String get settingsReopenWorkspaceOnStartupTitle => '启动时重新打开上次的工作区';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark 启动时打开上次会话中的工作区和标签页。';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle => '有未保存更改时关闭前进行确认';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      '文档有未保存更改时，关闭 BusyMark 前先进行询问。';

  @override
  String get closeUnsavedChangesTitle => '未保存的更改';

  @override
  String get closeUnsavedChangesSingleMessage =>
      '此文档有未保存的更改。关闭 BusyMark 前保存更改？';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      one: '有 1 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      zero: '关闭 BusyMark 前保存更改？',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => '取消';

  @override
  String get closeUnsavedChangesDiscard => '放弃';

  @override
  String get closeUnsavedChangesSave => '保存';

  @override
  String get currentFile => '当前文件';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName 中有未保存的更改。继续前保存这些更改？';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。继续前保存它们？',
      one: '有 1 个文档包含未保存的更改。继续前保存它？',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => '文件已在磁盘上更改';

  @override
  String get fileChangedOnDiskMessage => '自打开此文件后，它已在磁盘上发生更改。覆盖它？';

  @override
  String get untitledMarkdownFileName => '未命名.md';

  @override
  String get unorderedList => '无序列表';

  @override
  String get orderedList => '有序列表';

  @override
  String get taskList => '任务列表';

  @override
  String get toggleTaskChecked => '切换任务选中状态';

  @override
  String get indentListItem => '增加列表项缩进';

  @override
  String get outdentListItem => '减少列表项缩进';

  @override
  String get blockquote => '引用块';

  @override
  String get codeBlock => '代码块';

  @override
  String get codeBlockLanguage => '代码块语言';

  @override
  String get image => '图像';

  @override
  String get video => '视频';

  @override
  String get openVideo => '播放视频';

  @override
  String get pauseVideo => '暂停视频';

  @override
  String get videoUnavailable => '视频不可用';

  @override
  String get videoPreview => '视频预览';

  @override
  String get diagnosticWritersideVideoMissingSource => '视频缺少 src 属性。';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return '不支持的视频源：$source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return '视频文件不存在：$source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return '视频预览图像不存在：$preview';
  }

  @override
  String get inlineImage => '行内图像';

  @override
  String get table => '表格';

  @override
  String get htmlBlock => 'HTML 块';

  @override
  String get htmlContentDefault => 'HTML 内容';

  @override
  String get shortcutHtmlBlockDescription => '插入或编辑 HTML 块';

  @override
  String get renderedHtml => '已渲染的 HTML';

  @override
  String get editHtml => '编辑 HTML';

  @override
  String get htmlSource => 'HTML 源代码';

  @override
  String get thematicBreak => '分隔线';

  @override
  String get bold => '粗体';

  @override
  String get italic => '斜体';

  @override
  String get underline => '下划线';

  @override
  String get strikethrough => '删除线';

  @override
  String get inlineCode => '行内代码';

  @override
  String get link => '链接';

  @override
  String get hardLineBreak => '硬换行';

  @override
  String get insertBlankLine => '插入空行';

  @override
  String get textStyle => '文本样式';

  @override
  String get paragraph => '段落';

  @override
  String get heading1 => '标题 1';

  @override
  String get heading2 => '标题 2';

  @override
  String get heading3 => '标题 3';

  @override
  String get heading4 => '标题 4';

  @override
  String get heading5 => '标题 5';

  @override
  String get heading6 => '标题 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => '删除表格';

  @override
  String tableColumnNumber(int columnNumber) {
    return '列 $columnNumber';
  }

  @override
  String get insertColumnLeft => '在左侧插入列';

  @override
  String get insertColumnRight => '在右侧插入列';

  @override
  String get deleteColumn => '删除列';

  @override
  String get tableAlignmentUnspecified => '对齐方式：未指定';

  @override
  String get tableAlignmentLeft => '对齐方式：左对齐';

  @override
  String get tableAlignmentCenter => '对齐方式：居中';

  @override
  String get tableAlignmentRight => '对齐方式：右对齐';

  @override
  String tableRowNumber(int rowNumber) {
    return '行 $rowNumber';
  }

  @override
  String get insertRowAbove => '在上方插入行';

  @override
  String get insertRowBelow => '在下方插入行';

  @override
  String get deleteRow => '删除行';

  @override
  String get tableHeaderHint => '标题';

  @override
  String get tableCellHint => '单元格';

  @override
  String get language => '语言';

  @override
  String get hideEditingButtons => '隐藏编辑按钮';

  @override
  String get showEditingButtons => '显示编辑按钮';

  @override
  String get altText => '替代文本';

  @override
  String get editorPlaceholderText => '文本';

  @override
  String get editorPlaceholderCode => '代码';

  @override
  String get editorPlaceholderAltText => '替代文本';

  @override
  String get describeTheImage => '描述图像';

  @override
  String get columns => '列';

  @override
  String get rows => '行';

  @override
  String tableHeaderNumber(int columnNumber) {
    return '标题 $columnNumber';
  }

  @override
  String get tableCellDefault => '单元格';

  @override
  String get noImageSource => '没有图像源';

  @override
  String get remoteImageBlocked => '远程图像已阻止';

  @override
  String get remoteImageBlockedTooltip => '选择是否允许 BusyMark 加载远程图像。';

  @override
  String get remoteImagesBlockedTitle => '远程图像已阻止';

  @override
  String get remoteImagesBlockedMessage =>
      '本文档引用了来自互联网的图像。加载这些图像可能会向图像托管方泄露网络信息。';

  @override
  String get loadRemoteImagesForWorkspace => '为此工作区加载';

  @override
  String get alwaysLoadRemoteImages => '始终加载远程图像';

  @override
  String get hideSidebar => '隐藏侧边栏面板';

  @override
  String get showSidebar => '显示侧边栏面板';

  @override
  String get showPreview => '显示预览';

  @override
  String get hidePreview => '隐藏预览';

  @override
  String get workspaceKindUnsavedMarkdown => '未保存的 Markdown 文件';

  @override
  String get workspaceKindSingleMarkdown => '单个 Markdown 文件';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown 文件夹';

  @override
  String get workspaceKindWritersideModule => 'Writerside 模块';

  @override
  String get problems => '问题';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条诊断信息',
      one: '1 条诊断信息',
      zero: '没有诊断信息',
    );
    return '$_temp0';
  }

  @override
  String get files => '文件';

  @override
  String get toc => '目录';

  @override
  String get tocActions => '目录操作';

  @override
  String get markdownUnsaved => 'Markdown - 未保存';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => '没有文件';

  @override
  String get newFile => '新建文件';

  @override
  String get noWritersideToc => '没有 Writerside 目录';

  @override
  String get tocSection => '目录节';

  @override
  String get newTopic => '新建主题';

  @override
  String get newChildTopic => '新建子主题';

  @override
  String get newSiblingTopic => '新建主题';

  @override
  String get renameTopicFile => '重命名主题文件';

  @override
  String get topicPlacement => '目录位置';

  @override
  String get tocRoot => '位于目录根级别';

  @override
  String get afterSelectedTopic => '位于选中主题之后';

  @override
  String get insideSelectedTopic => '位于选中主题内';

  @override
  String get pasteAfterTopic => '粘贴到主题之后';

  @override
  String get pasteAsChildTopic => '粘贴为子主题';

  @override
  String get removeFromToc => '从目录中移除';

  @override
  String get confirmRemoveFromTocTitle => '从目录中移除？';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '从此目录中移除 $name？主题文件将被保留。';
  }

  @override
  String get confirmDeleteTopicTitle => '删除主题文件？';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '删除 $name 并从每个目录中移除它？此操作无法撤销。';
  }

  @override
  String get safeDeleteTopicFile => '安全删除主题文件…';

  @override
  String get removeTocElement => '移除目录元素';

  @override
  String get removeTocElements => '移除目录元素';

  @override
  String get reviewUsages => '查看使用情况';

  @override
  String get deleteTopicFile => '删除主题文件';

  @override
  String get removeAction => '移除';

  @override
  String topicRemovalSummary(String topic) {
    return '移除目录元素“$topic”？与目录关联的源文件不会被删除。';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '删除“$topic”，并在整个 Writerside 项目中安全更新其引用。';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个子主题将上移一级。',
      one: '1 个子主题将上移一级。',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning => '此主题是此实例的主页。从目录中移除它之前，请选择另一个主页。';

  @override
  String get newHomePage => '新主页';

  @override
  String get chooseHomePage => '选择主页';

  @override
  String get noHomePageReplacement => '移除主页之前，请向此实例添加或链接另一个符合条件的主题。';

  @override
  String get topicIsStartPageRemovalWarning => '此主题是某个实例的主页。删除其源文件之前，请指定另一个主页。';

  @override
  String topicUsagesCount(int count) {
    return '找到 $count 处使用。';
  }

  @override
  String get noBreakingTopicUsages => '未找到会导致引用失效的引用。';

  @override
  String get topicUsagesFound => 'BusyMark 找到了以下对该主题的引用。';

  @override
  String get topicUsageTocElements => '目录元素';

  @override
  String get topicUsageStartPages => '主页';

  @override
  String get topicUsageTopicLinks => '主题链接';

  @override
  String get topicUsageIncludes => '包含项';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次使用',
      one: '1 次使用',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => '重构选项';

  @override
  String get updateUsagesAutomatically => '自动更新使用情况';

  @override
  String get updateUsagesAutomaticallyDescription => '移除目录引用和包含项，同时保留链接文本。';

  @override
  String get manualUsageUpdatesRequired => '执行此重构前，某些使用情况需要手动更改。';

  @override
  String get setRedirectTo => '设置重定向到：';

  @override
  String get noRedirectDescription => '不重定向旧的已发布页面。';

  @override
  String get redirectTarget => '重定向目标';

  @override
  String get remainingUsagesBlockRemoval => '请在继续前查看并更新剩余的使用情况，或在可用时启用自动更新。';

  @override
  String usagesOfTopic(String topic) {
    return '$topic 的使用情况';
  }

  @override
  String get noUsagesFound => '未找到使用情况';

  @override
  String get outsideSelectedInstance => '在选中的实例之外';

  @override
  String get doRefactor => '执行重构';

  @override
  String get preview => '预览';

  @override
  String get topicRenamePreviewTitle => '重命名预览';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return '路径：$oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return '主题 ID：$oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return '实例 $instance：$oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => '受影响的文件';

  @override
  String get orphanTopicTitle => '主题文件已不再使用';

  @override
  String get keepTopicFile => '保留主题文件';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic”在此 Writerside 项目中已不再使用。删除该文件，或保留它以供其他实例使用。';
  }

  @override
  String get defaultNewTopicTitle => '新主题';

  @override
  String get topicTitle => '主题标题';

  @override
  String get fileName => '文件名';

  @override
  String get topicTitleRequired => '主题标题为必填项。';

  @override
  String get fileNameRequired => '文件名为必填项。';

  @override
  String get rename => '重命名';

  @override
  String get confirmDeleteFileTitle => '删除文件？';

  @override
  String get confirmDeleteFolderTitle => '删除文件夹？';

  @override
  String confirmDeleteFileMessage(String name) {
    return '删除 $name？此操作无法撤销。';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '删除 $name 及其中的所有文件？此操作无法撤销。';
  }

  @override
  String get useSingleSafeFileName => '使用单一且安全的文件名。';

  @override
  String useExpectedExtension(String extension) {
    return '为选中的格式使用 $extension 扩展名。';
  }

  @override
  String get useIdentifierCharacters => '在扩展名之前仅使用字母、数字、下划线或连字符。';

  @override
  String get topicIdAlreadyExists => '主题 ID 已存在。';

  @override
  String get createWritersideTopicFailed => '无法创建 Writerside 主题。';

  @override
  String get noOutline => '没有大纲';

  @override
  String expandKind(String kind) {
    return '展开 $kind';
  }

  @override
  String collapseKind(String kind) {
    return '折叠 $kind';
  }

  @override
  String get foldKindSection => '节';

  @override
  String get foldKindList => '列表';

  @override
  String get foldKindQuote => '引用';

  @override
  String get foldKindTag => '标签';

  @override
  String get sourceSearchPreviousMatch => '上一个匹配项';

  @override
  String get sourceSearchNextMatch => '下一个匹配项';

  @override
  String get sourceSearchReplacement => '替换为';

  @override
  String get sourceSearchReplaceCurrent => '替换当前匹配项';

  @override
  String get sourceSearchReplaceAndFindNext => '替换并查找下一个';

  @override
  String get sourceSearchReplaceAll => '全部替换';

  @override
  String get workspaceReplace => '在工作区中替换';

  @override
  String get reviewReplacements => '查看替换内容';

  @override
  String get applyReplacements => '应用替换';

  @override
  String get skippedFiles => '跳过的文件';

  @override
  String get workspaceReplaceDirtyBuffer => '未保存的编辑器内容';

  @override
  String get workspaceReplaceDiskContent => '磁盘上的已保存内容';

  @override
  String selectFileMatches(int count) {
    return '选择全部 $count 个匹配项';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '已在 $files 个文件中替换 $matches 个匹配项；跳过 $skipped 个。';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾有换行符';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾无换行符';
  }

  @override
  String get normalizeLineEndings => '规范化行尾';

  @override
  String get mixedLineEndingsSavePrompt => '此文档包含混合的行尾格式。请选择一种格式。';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName 使用混合的行尾格式。请在替换前选择要使用的格式。';
  }

  @override
  String get workspaceReplaceIssueOversized => '已跳过过大的文件。';

  @override
  String get workspaceReplaceIssueUnreadable => '已跳过无法读取的文件。';

  @override
  String get workspaceReplaceIssueInvalidUtf8 => '已跳过不是有效 UTF-8 的文件。';

  @override
  String get workspaceReplaceIssueTruncated => '替换预览已被截断。';

  @override
  String get workspaceReplaceIssueFileChanged => '已跳过预览后发生变化的文件。';

  @override
  String get workspaceReplaceIssueBufferChanged => '已跳过预览后发生变化的编辑器缓冲区。';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      '请在替换前选择 LF 或 CRLF 规范化。';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      '由于文件同时发生了变化，回滚已停止。部分替换可能仍然存在；被移出的内容已保留在下方路径中。';

  @override
  String get workspaceReplaceIssueApplyFailed => '无法提交经过审查的替换；没有文件发生更改。';

  @override
  String externalChangesTitle(String fileName) {
    return '外部更改 — $fileName';
  }

  @override
  String get externalFileDeleted => '此文件已从磁盘删除。';

  @override
  String get externalFileChanged => '在您有未保存编辑时，此文件已在磁盘上发生变化。';

  @override
  String recoveredDocumentReview(String fileName) {
    return '已恢复 $fileName 的未保存内容。请检查后保存、另存为或放弃。';
  }

  @override
  String get compare => '比较';

  @override
  String get reloadFromDisk => '从磁盘重新加载';

  @override
  String get keepMine => '保留我的版本';

  @override
  String get saveAs => '另存为';

  @override
  String get workspaceSearchIncomplete => '仅显示了部分结果。请显示更多结果或缩小搜索范围。';

  @override
  String get workspaceSearchShowMore => '显示更多结果';

  @override
  String get workspaceSearchSkippedFiles => '搜索不完整。以下文件超过 1 MiB 或无法读取：';

  @override
  String get sourceLargeFileFeaturesPaused => '大文件：已暂停语法突出显示和折叠';

  @override
  String get nothingToRead => '没有可读取的内容';

  @override
  String get admonition => '提示块';

  @override
  String get quote => '引用';

  @override
  String get note => '备注';

  @override
  String get tip => '提示';

  @override
  String get warning => '警告';

  @override
  String get tabs => '标签页';

  @override
  String get tab => '标签页';

  @override
  String get procedure => '操作步骤';

  @override
  String get step => '步骤';

  @override
  String get topic => '主题';

  @override
  String get chapter => '章节';

  @override
  String couldNotOpenTarget(String target) {
    return '无法打开 $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return '找不到链接目标：$targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor => '无法在编辑器中打开此文件类型';

  @override
  String anchorNotFound(String anchor) {
    return '找不到锚点：$anchor';
  }

  @override
  String get noProblemsFound => '未发现问题';

  @override
  String get noResults => '无结果';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - 第 $lineNumber 行';
  }

  @override
  String get untitledResult => '未命名结果';

  @override
  String get documentKindMarkdownFile => 'Markdown 文件';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown 主题';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML 主题';

  @override
  String get documentKindWritersideTree => 'Writerside 树';

  @override
  String get documentKindConfigurationFile => '配置文件';

  @override
  String get documentKindVariablesFile => '变量文件';

  @override
  String get documentKindCategoriesFile => '类别文件';

  @override
  String get documentKindResourceFile => '资源文件';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return '无法更新最近使用的项目：$error。';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return '打开失败：$error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return '无法创建 Writerside 项目：$error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return '无法创建 Writerside 主题：$error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown => '选择保存此 Markdown 文件的位置。';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk => '保存已阻止：文件已在磁盘上发生变化。';

  @override
  String workspaceErrorSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return '文件操作失败：$error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return '验证失败：$error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $count 个未保存的文档。请在保存或放弃前逐一检查。',
      one: '已恢复 1 个未保存的文档。请在保存或放弃前进行检查。',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '无法恢复 $count 条损坏的恢复记录。有效的恢复记录仍可用。',
      one: '无法恢复一条损坏的恢复记录。原始恢复文件已保留以供检查。',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return '路径不存在：$path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return '目标目录已存在且不为空：$path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return '目标路径已存在但不是目录：$path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return '生成的文件已存在：$path';
  }

  @override
  String get errorParentDirectoryRequired => '必须指定父目录。';

  @override
  String errorParentDirectoryMissing(String path) {
    return '父目录不存在：$path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return '目录不存在：$path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return '路径已存在：$path';
  }

  @override
  String get errorFileNameRequired => '文件名为必填项。';

  @override
  String get errorFileNameUnsafe => '文件名必须是单一且安全的路径段。';

  @override
  String get errorFileOperationInvalidTarget => '无法将文件夹移动到其自身中。';

  @override
  String get errorFileOperationOutsideRoot => '文件操作必须在工作区内进行。';

  @override
  String get errorFileOperationRoot => '无法从文件树更改工作区根目录。';

  @override
  String get errorProjectNameRequired => '项目名称为必填项。';

  @override
  String get errorDirectoryNameRequired => '目录名称为必填项。';

  @override
  String get errorDirectoryNameUnsafe => '目录名称必须是单一且安全的路径段。';

  @override
  String get errorInstanceIdInvalid => '实例 ID 必须以小写字母开头，且只能包含小写字母、数字、下划线和连字符。';

  @override
  String get errorTopicFileInvalid => '主题文件名必须是没有路径分隔符的 Markdown 文件名。';

  @override
  String get errorTopicTitleRequired => '主题标题为必填项。';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside 模块根目录不存在：$path';
  }

  @override
  String get errorWritersideModuleNotOpen => '必须打开 Writerside 模块才能创建主题。';

  @override
  String get errorWritersideInstanceTreeMissing => 'Writerside 模块没有实例树。';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside 树文件不存在：$path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return '主题 ID \"$topicId\" 已存在于此帮助模块中。';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return '主题文件已存在：$path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return '选中的树中不存在引用主题：$topic';
  }

  @override
  String get errorWritersideTocNodeMissing => '选中的目录项已不存在。';

  @override
  String get errorWritersideTocInvalidMove => '目录项无法移动到自身或其子项中。';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '无法删除主页 $topic。请先选择另一个主页。';
  }

  @override
  String get errorWritersideSafeDeleteRequired => '请对 Writerside 主题文件使用安全删除。';

  @override
  String get errorWritersideTopicUsageScanFailed => '无法完成主题使用情况扫描。没有文件发生更改。';

  @override
  String get errorWritersideTopicUsagesRemain => '某些主题使用情况仍需处理。请先查看后再继续。';

  @override
  String get errorWritersideRedirectInvalid => '选中的重定向目标已无效。请重新选择。';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return '无法完全回滚主题移除。请在继续前查看这些路径：$paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return '无法安全地重命名并更新所有项目引用，因为模块 $module 中有 $count 个主题文件尚未解析：$paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside 项目文件有未保存的更改。请先处理这些更改，再准备新的重命名预览。';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Writerside 项目的模块集合已更改。请在重构前准备新的重命名预览。';

  @override
  String get errorTopicsRootUnsafe => '主题根目录必须是安全的相对目录。';

  @override
  String get errorTopicFileNameUnsafe => '主题文件名必须是单一且安全的路径段。';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return '主题文件扩展名必须与选中的格式匹配（$extension）。';
  }

  @override
  String get errorTopicFileNameInvalid => '主题文件名只能包含字母、数字、下划线和连字符。';

  @override
  String errorUnknown(String code) {
    return '未知错误：$code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return '无法读取文件元数据：$error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped => '检测到大型工作区。为保持应用响应速度，已跳过部分文件。';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return '无法检查工作区项：$error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge => '文件超过 beta 自动解析限制。';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return '无法读取 Markdown 文件：$error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed => 'Writerside 标题属性块格式错误。';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return '标题 ID“$id”重复。';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      '额外的顶级 H1 标题将被视为章节。';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown 主题没有 H1 或 front matter 标题。';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle => 'XML 主题缺少标题。';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return '主题“$fileName”缺少标题。';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed => 'front matter 未闭合。';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => '不安全的 HTML 元素。';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return '链接目标不存在：$targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return '锚点“$anchor”不存在。';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '图像“$destination”缺少替代文本。';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return '图像不存在：$destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return '无效的 XML：$message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg 根元素必须是 <ihp>。';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups 声明缺少 src。';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return '不支持的 keymaps 模式：$mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'instance 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg 未注册实例。';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree 根元素必须是 <instance-profile>。';

  @override
  String get diagnosticWritersideTreeMissingId => '实例配置文件缺少 id。';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return '树文件名（不含扩展名）与实例 ID“$id”不匹配。';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage => '非库实例缺少 start-page。';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '起始页“$startPage”不存在。';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return '主题“$topic”在此实例目录中出现多次。';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      '变量声明必须包含名称和值。';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '变量“$name”被声明了多次。';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => '类别缺少 id。';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return '类别“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return '类别顺序“$order”被声明了多次。';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot => '.topic 根元素必须是 <topic>。';

  @override
  String get diagnosticWritersideTopicMissingRootId => 'XML 主题缺少根 id。';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML 主题根 ID“$id”必须与文件名“$expectedId”匹配。';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return '元素 ID“$elementId”出现多次。';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> 缺少 href。';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside 模式需要 writerside.cfg。';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return '配置的构建配置目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return '配置的 API 规范目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return '配置的 snippets 目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return '配置的变量文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return '配置的类别文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return '配置的实例组文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return '已注册的实例树“$source”不存在。';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return '无法读取主题文件：$error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return '默认主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return '配置的主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return '配置的图像目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return '元素 ID“$id”出现多次。';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return '实例 \"$instanceId\" 为主题 \"$topic\" 发布了无效的 Web 文件名 \"$webFileName\"。';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return '实例 \"$instanceId\" 将 \"$firstTopic\" 和 \"$secondTopic\" 都发布为 \"$webFileName\"。';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return '目录引用了缺失的主题“$topic”。';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return '外部 href“$href”无效。';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '变量“%$name%”未声明。';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return '主题链接“$destination”无法解析。';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '“$targetName”中不存在锚点“$anchor”。';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom => '<include> 缺少 from。';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return '包含源“$from”不存在。';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '“$from”中不存在包含元素“$elementId”。';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso 类别“$ref”未声明。';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return '主题引用“$reference”不明确。';
  }

  @override
  String diagnosticUnknown(String code) {
    return '未知诊断信息：$code';
  }

  @override
  String get close => '关闭';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git 差异';

  @override
  String get gitShowDiff => '显示差异';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return '旧 $oldRange → 新 $newRange';
  }

  @override
  String get gitDiffNoLines => '无行';

  @override
  String get gitUnavailableTitle => 'Git 不可用';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other': '安装 Git，或配置 BusyMark 以使用可用的 Git 可执行文件。$reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => '信任此工作区以使用 Git？';

  @override
  String get gitTrustRequiredMessage =>
      'Git 存储库可以通过 hook、过滤器和其他配置运行程序。在 BusyMark 读取存储库数据或启用 Git 操作前，请先信任此工作区。';

  @override
  String get gitTrustWorkspace => '信任工作区';

  @override
  String get gitNotRepositoryTitle => '不是 Git 存储库';

  @override
  String get gitNotRepositoryMessage => '此工作区不在 Git 存储库中。';

  @override
  String get gitInitializeRepository => '初始化存储库';

  @override
  String get gitDetachedHead => '分离的 HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '分离于 $commit';
  }

  @override
  String get gitNoUpstream => '没有上游分支';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个未推送的提交',
      one: '1 个未推送的提交',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个待拉取的提交',
      one: '1 个待拉取的提交',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => '干净';

  @override
  String get gitConflicts => '冲突';

  @override
  String get gitChanges => '更改';

  @override
  String get gitStaged => '已暂存';

  @override
  String get gitUnstaged => '未暂存';

  @override
  String get gitHistory => '历史记录';

  @override
  String get gitBranches => '分支';

  @override
  String get gitActions => 'Git 操作';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => '暂存文件';

  @override
  String get gitRemoveFromCommit => '取消暂存文件';

  @override
  String get gitDiscard => '还原';

  @override
  String get gitOpenFile => '打开文件';

  @override
  String get gitMarkResolved => '标记为已解决';

  @override
  String get gitUntracked => '未跟踪';

  @override
  String get gitCommitMessage => '提交消息';

  @override
  String get gitCommitSelectedFiles => '选中的文件';

  @override
  String get gitCommitNoSelectedFiles => '提交前至少暂存一个文件。';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已暂存文件',
      one: '1 个已暂存文件',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => '工作区之外';

  @override
  String get gitCommitMessageRequired => '请输入提交消息。';

  @override
  String get gitCreateBranch => '创建分支';

  @override
  String get gitNewBranch => '新分支';

  @override
  String get gitBranchName => '分支名称';

  @override
  String get gitSwitchBranch => '切换';

  @override
  String get gitNoChanges => '没有更改';

  @override
  String get gitNoHistory => '没有历史记录';

  @override
  String get gitNoBranches => '没有分支';

  @override
  String get gitNoDiff => '没有可显示的差异';

  @override
  String get gitBinaryFile => '二进制文件。BusyMark 不渲染二进制补丁。';

  @override
  String gitBinaryFileInfo(int size) {
    return '二进制文件（$size 字节）。BusyMark 不渲染二进制补丁。';
  }

  @override
  String get gitUnsavedChangesBanner => '保存前不会包含未保存的编辑器更改。';

  @override
  String get gitConfirmDiscardTitle => '放弃 Git 更改？';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
      one: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的未跟踪文件将被删除。',
      one: '选中的未跟踪文件将被删除。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将根据其 Git 状态还原或删除选中的文件。',
      one: '将根据其 Git 状态还原或删除选中的文件。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '切换到 $branch？';
  }

  @override
  String get gitConfirmSwitchBranchMessage => 'Git 切换分支后，BusyMark 将从磁盘重新加载工作区。';

  @override
  String get gitConfirmPushSetUpstreamTitle => '设置上游分支？';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return '此分支没有上游分支。当只配置了一个远程仓库时，BusyMark 可以推送 $branch 并设置其上游分支。';
  }

  @override
  String get gitProjectHistory => '项目历史记录';

  @override
  String get gitFileHistory => '文件历史记录';

  @override
  String get gitFileHistoryRequiresOpenFile => '文件历史记录需要打开的 Markdown 文件。';

  @override
  String get gitLoadMore => '加载更多';

  @override
  String get gitChangesInCommit => '此提交中的更改';

  @override
  String get gitCompareWithCurrent => '与当前版本比较';

  @override
  String get gitRestoreVersion => '还原此版本';

  @override
  String get gitConfirmRestoreTitle => '还原此文件版本？';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark 将使用选中的已提交版本替换当前工作树中的文件。还原后的文件将保持未暂存状态。';

  @override
  String get gitCommitActions => '提交操作';

  @override
  String get gitResetCurrentBranchToHere => '将当前分支重置到此处…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '将 $branch 重置到 $commit？';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return '这会将分支 $branch 移动到提交 $commit。请选择 Git 更新索引和工作树的方式。';
  }

  @override
  String get gitReset => '重置';

  @override
  String get gitResetModeSoft => '软';

  @override
  String get gitResetModeSoftDescription =>
      '仅移动分支。保持索引和工作树不变；与选中提交之间的差异仍会保持暂存状态。';

  @override
  String get gitResetModeMixed => '混合';

  @override
  String get gitResetModeMixedDescription => '移动分支并重置索引。保持工作树不变，使差异处于未暂存状态。';

  @override
  String get gitResetModeHard => '硬';

  @override
  String get gitResetModeHardDescription =>
      '移动分支并重置索引和工作树。已跟踪的更改将被放弃；造成阻碍的未跟踪文件可能会被删除。';

  @override
  String get gitResetModeKeep => '保留';

  @override
  String get gitResetModeKeepDescription =>
      '移动分支并重置已跟踪文件，同时保留本地更改。如果这些更改与重置冲突，Git 将中止操作。';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => '文件操作';

  @override
  String get actions => '操作';

  @override
  String get gitStatusAdded => '已添加';

  @override
  String get gitStatusDeleted => '已删除';

  @override
  String get gitStatusRenamed => '已重命名';

  @override
  String get gitStatusCopied => '已复制';

  @override
  String get gitStatusUntracked => '未跟踪';

  @override
  String get gitStatusConflicted => '有冲突';

  @override
  String get gitStatusIgnored => '已忽略';

  @override
  String get gitStatusTypeChanged => '类型已更改';

  @override
  String get gitStatusModified => '已修改';

  @override
  String get gitStatusUnknown => '未知';

  @override
  String get gitErrorUnavailable => 'Git 不可用。';

  @override
  String get gitErrorNotRepository => '此工作区不是 Git 存储库。';

  @override
  String get gitErrorUnsafePath => 'BusyMark 阻止了不安全的 Git 路径。';

  @override
  String get gitErrorInvalidBranchName => '请输入有效的分支名称。';

  @override
  String get gitErrorNoRemote => '未配置 Git 远程仓库。';

  @override
  String get gitErrorNoUpstream => '未配置上游分支。';

  @override
  String get gitErrorMultipleRemotes => '配置了多个远程仓库。请在此 BusyMark 版本之外选择上游分支。';

  @override
  String get gitErrorDirtyWorkspace => '切换分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorResetDirtyWorkspace => '重置当前分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorRestoreStagedFile => '还原历史版本前，请取消暂存此文件。';

  @override
  String get gitErrorResetDetachedHead => '重置前请先检出一个分支。';

  @override
  String get gitErrorDiverged => '分支已发生分歧。请在此 BusyMark 版本之外解决合并或变基问题。';

  @override
  String get gitErrorAuthorIdentity => 'Git 需要作者姓名和邮箱地址才能提交。';

  @override
  String get gitAuthorIdentityTitle => 'Git 作者身份';

  @override
  String get gitAuthorIdentityMessage =>
      '请输入 Git 应记录在提交中的身份信息。BusyMark 将保存它并重试此次提交。';

  @override
  String get gitAuthorName => '姓名';

  @override
  String get gitAuthorEmail => 'Email';

  @override
  String get gitAuthorIdentityGlobal => '用于所有存储库';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      '作为 Snap 安装时，此设置适用于在 BusyMark 中打开的存储库。';

  @override
  String get gitSaveIdentityAndCommit => '保存并提交';

  @override
  String get gitErrorAuthentication => 'Git 身份验证失败。';

  @override
  String get gitErrorNetwork => 'Git 网络操作失败。';

  @override
  String get gitErrorConflict => 'Git 报告存在未解决的冲突。';

  @override
  String get gitErrorCommandFailed => 'Git 命令失败。';

  @override
  String get syntaxReference => '语法参考';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown 块';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown 源代码和预览中支持的块结构。';

  @override
  String get syntaxReferenceInlineFormatting => '行内 Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      '可出现在段落、列表项和表格单元格中的格式。';

  @override
  String get syntaxReferenceRawHtmlBlocks => '原始 HTML 块';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      '通过 BusyMark 预览组件渲染的安全块级 HTML 标签。';

  @override
  String get syntaxReferenceRawHtmlInline => '原始 HTML 行内标签';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      '安全的行内 HTML 标签，渲染时不会显示字面标签。';

  @override
  String get syntaxReferenceHeadings => '标题';

  @override
  String get syntaxReferenceParagraphs => '段落';

  @override
  String get syntaxReferenceLists => '列表';

  @override
  String get syntaxReferenceHtmlContainers => '容器';

  @override
  String get syntaxReferenceHtmlTextBlocks => '文本块';

  @override
  String get syntaxReferenceHtmlFigures => '图和图像';

  @override
  String get syntaxReferenceHtmlPreformatted => '预格式化代码';

  @override
  String get syntaxReferenceHtmlDisclosure => '折叠块';

  @override
  String get syntaxReferenceHtmlDescriptionLists => '描述列表';

  @override
  String get syntaxReferenceHtmlFormattingTags => '格式标签';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => '行内代码标签';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => '语义文本标签';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      '允许的 HTML 会转换为 BusyMark 预览块，而不是在浏览器中渲染。';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      '未经编辑的原始 HTML 会按源文本原样保存。';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      '原始 HTML 内的 Markdown 标记会按字面文本渲染。';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      '脚本、样式、框架、表单、SVG、MathML、事件和不安全属性都会被阻止。';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      '链接允许 http、https、mailto、tel、相对路径和片段 URL；不安全的 scheme 会被阻止。';

  @override
  String get syntaxReferenceCategory => '类别';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => '图表和 API';

  @override
  String get syntaxReferenceCategoryMathematics => '数学';

  @override
  String get syntaxReferenceExample => '示例';

  @override
  String get syntaxReferenceIdentifiers => '标识符和别名';

  @override
  String get syntaxReferenceScope => '适用范围';

  @override
  String get syntaxReferenceLimitation => 'BusyMark 限制';

  @override
  String get syntaxReferenceOfficialDocumentation => '官方文档';

  @override
  String get syntaxReferenceScopeWritersideMarkdown => '仅 Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      '仅 Writerside Markdown 和 Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'BusyMark 可以编写和预览的核心 Markdown 形式。';

  @override
  String get syntaxReferenceParagraphExample => '一段文本。';

  @override
  String get syntaxReferenceTableLimitation =>
      '表格使用 GitHub Flavored Markdown 的竖线语法。';

  @override
  String get syntaxReferenceHardBreakIdentifiers => '行尾两个空格、\\、<br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark 在 Markdown 源码中仅接受有限且安全的原始 HTML 子集。';

  @override
  String get syntaxReferenceDiagramsDescription =>
      '带围栏的 Mermaid、PlantUML、D2 和 OpenAPI 块可在 Markdown 源码中使用。围栏标识符不区分大小写，BusyMark 会保留原始拼写。';

  @override
  String get syntaxReferenceMermaid => 'Mermaid';

  @override
  String get syntaxReferencePlantUml => 'PlantUML';

  @override
  String get syntaxReferenceD2 => 'D2';

  @override
  String get syntaxReferenceOpenApi => 'OpenAPI';

  @override
  String get syntaxReferenceOpenApiLimitation =>
      '请使用带围栏的 YAML 或 JSON 内容。BusyMark 不会将任意完整的 YAML 或 JSON 文档视为 OpenAPI 参考。';

  @override
  String get syntaxReferenceSemanticDiagramBlocks => '图表的语义代码块';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      '语义 code-block 和 src 形式仅支持 Mermaid、PlantUML 和 D2，不支持 OpenAPI，且只能在 Writerside 项目中使用。';

  @override
  String get syntaxReferenceReferencedDiagramSource => '引用的图表源';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      '路径必须是相对路径并位于已打开的 Writerside 项目内；围栏加 src 的形式仅适用于 Writerside Markdown。';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark 支持 TeX 表达式，但不支持完整的 TeX 或 LaTeX 文档。';

  @override
  String get syntaxReferenceInlineMath => '行内数学公式';

  @override
  String get syntaxReferenceGithubMath => '使用美元符号和反引号的 GitHub 数学公式';

  @override
  String get syntaxReferenceDisplayMath => '显示数学公式';

  @override
  String get syntaxReferenceMathFence => 'math 围栏';

  @override
  String get syntaxReferenceTexFence => 'tex 围栏';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark 不会将 \\(...\\) 或 \\[...\\] 识别为 Markdown 数学分隔符。';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      '在 Writerside 模式之外，tex 围栏仍是普通代码块。';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside math 元素';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math 元素是语义 Writerside 语法，不是允许的原始 HTML MathML。';

  @override
  String get syntaxReferenceSemanticTexBlock => '语义 TeX 代码块';

  @override
  String get syntaxReferenceWritersideDescription =>
      '这些特定扩展仅在已打开的 Writerside 项目中解析。';

  @override
  String get syntaxReferenceAdmonitionBlockquote => '提示块引用';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      '普通块引用在 Writerside Markdown 中是提示；在普通 Markdown 中仍是普通引用。';

  @override
  String get syntaxReferenceSemanticAdmonitions => '语义提示';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      '普通 Markdown 不会解析这些 Writerside 语义元素。';

  @override
  String get syntaxReferenceCollapsibleHeading => '可折叠标题';

  @override
  String get syntaxReferenceCollapsibleCode => '可折叠代码围栏';

  @override
  String get syntaxReferenceSemanticCollapsibles => '语义可折叠内容';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark 支持可折叠的 chapter、procedure、code-block 和定义列表形式，但不支持完整的 Writerside 目录。';

  @override
  String get syntaxReferenceSemanticCodeBlocks => '数学和图表的语义代码块';

  @override
  String get syntaxReferenceVideo => 'Writerside 视频';

  @override
  String get syntaxReferenceVideoLimitation =>
      '本地视频使用本地 preview-src 图像；托管视频源必须是受支持的 YouTube 或 Vimeo HTTPS URL。';

  @override
  String get exportAsPdf => '导出为 PDF';

  @override
  String get pdfExportDescription => '选择页面布局，生成精美且自包含的 PDF。';

  @override
  String get pdfRemoteImagesNote => '导出过程中不会下载远程图像。有可用的本地图像时将包含它们。';

  @override
  String get pdfPageSize => '页面大小';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => '方向';

  @override
  String get pdfPortrait => '纵向';

  @override
  String get pdfLandscape => '横向';

  @override
  String get pdfMargins => '页边距';

  @override
  String get pdfMarginNarrow => '窄';

  @override
  String get pdfMarginNormal => '普通';

  @override
  String get pdfMarginWide => '宽';

  @override
  String get pdfIncludePageNumbers => '包含页码';

  @override
  String get export => '导出';

  @override
  String get exportFormat => '输出格式';

  @override
  String get exportingPdf => '正在导出 PDF…';

  @override
  String get fileTypePdf => 'PDF 文档';

  @override
  String pdfExported(String fileName) {
    return '已导出 $fileName。';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条警告',
      one: '1 条警告',
    );
    return '$fileName 已导出，包含 $_temp0。';
  }

  @override
  String get pdfExportUnavailable => '缺少 PDF 导出组件。请重新安装 BusyMark 后重试。';

  @override
  String get pdfExportTimedOut => 'PDF 导出耗时过长，已停止。';

  @override
  String get pdfExportFailed => 'BusyMark 无法将此文档导出为 PDF。';

  @override
  String get visualizationRendering => '正在渲染…';

  @override
  String get visualizationStale => '正在显示上次有效的渲染结果';

  @override
  String get visualizationShowSource => '显示源代码';

  @override
  String get visualizationShowRender => '显示渲染结果';

  @override
  String get visualizationFitWidth => '适应宽度';

  @override
  String get visualizationSaveImage => '保存图像';

  @override
  String get visualizationCopyImage => '复制图像';

  @override
  String get visualizationImageCopied => '图像已复制';

  @override
  String get visualizationOpenApiReference => '打开 API 参考';

  @override
  String get visualizationValid => '有效';

  @override
  String get visualizationInvalid => '无效';

  @override
  String get visualizationServers => '服务器';

  @override
  String get visualizationPaths => '路径';

  @override
  String get visualizationOperations => '操作';

  @override
  String get visualizationTags => '标签';

  @override
  String get visualizationNoOperations => '没有匹配的操作';

  @override
  String get visualizationSearchOperations => '搜索操作';

  @override
  String get visualizationRenderFailed => '无法渲染此可视化内容。';

  @override
  String get visualizationRetry => '重试';

  @override
  String visualizationSaved(String fileName) {
    return '已保存 $fileName';
  }

  @override
  String get shortcutExportPdfDescription => '将当前文档或 Writerside 模块导出为 PDF。';

  @override
  String get instances => '实例';

  @override
  String get newInstance => '新建实例';

  @override
  String get newTocLibrary => '新建目录库';

  @override
  String get editInstance => '编辑实例';

  @override
  String get openTocFile => '打开目录文件';

  @override
  String get createInstance => '创建实例';

  @override
  String get createTocLibrary => '创建目录库';

  @override
  String get instanceContent => '内容';

  @override
  String get instanceContentSource => '创建来源';

  @override
  String get emptyInstance => '空实例';

  @override
  String get markdownFiles => '本地 Markdown 文件';

  @override
  String get chooseMarkdownFolder => '选择 Markdown 文件夹';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      '选择包含 Markdown 文件的文件夹。';

  @override
  String get instanceAppearance => '外观';

  @override
  String get instanceColor => '图标颜色';

  @override
  String get instanceVersion => '版本';

  @override
  String instanceVersionInherited(String version) {
    return '此字段为空时，项目版本为 $version。';
  }

  @override
  String get instanceWebPath => 'Web 路径';

  @override
  String get instanceStatus => '状态';

  @override
  String get instanceStatusRelease => '发布';

  @override
  String get instanceStatusEap => '抢先体验';

  @override
  String get instanceStatusDeprecated => '已弃用';

  @override
  String get allowSearchEngineIndexing => '允许搜索引擎建立索引';

  @override
  String get allowSearchEngineIndexingDescription => '允许外部搜索引擎为此输出建立索引。';

  @override
  String get offlineArtifact => '离线构件';

  @override
  String get offlineArtifactDescription => '捆绑资源，使构建的文档可以自包含。';

  @override
  String get instanceOutputSettings => '输出设置';

  @override
  String get markdownImportSource => 'Markdown 源';

  @override
  String get markdownImportFiles => 'Markdown 文件';

  @override
  String get selectNone => '全部取消选择';

  @override
  String markdownFilesFound(int count) {
    return '找到 $count 个 Markdown 文件';
  }

  @override
  String get noMarkdownFilesFound => '在此目录中未找到 Markdown 文件。';

  @override
  String get copyReferencedMedia => '复制引用的媒体';

  @override
  String get copyReferencedMediaDescription => '复制选中文件引用的本地图像和视频，同时保留相对路径。';

  @override
  String get instanceIdRenameWarningTitle => '重命名实例 ID？';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark 将重命名 .tree 文件，并将 Writerside 项目引用从“$oldId”更新为“$newId”。发布脚本不会更改，必须单独更新。';
  }

  @override
  String get renameAndUpdateReferences => '重命名并更新引用';

  @override
  String get tocLibraryDescription => '目录库用于存储可复用的节，不会生成自己的输出。';

  @override
  String get defaultTocLibraryName => '共享目录';

  @override
  String get instanceColorAutomatic => '自动';

  @override
  String get instanceColorBlue => '蓝色';

  @override
  String get instanceColorGreen => '绿色';

  @override
  String get instanceColorOrange => '橙色';

  @override
  String get instanceColorPurple => '紫色';

  @override
  String get instanceColorRed => '红色';

  @override
  String get instanceColorTeal => '青绿色';

  @override
  String get instanceColorYellow => '黄色';

  @override
  String get errorWritersideInstanceNameRequired => '请输入实例名称。';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return '已存在 ID 为“$id”的实例。';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return '实例树已存在：$path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown 源目录不存在：$path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      '请选择至少一个 Markdown 文件进行导入。';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return '选中的源中有一个不是可读取的 Markdown 文件：$path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return '导入将覆盖现有项目文件：$path';
  }

  @override
  String get errorWritersideInstanceFilesChanged => '实例文件已在磁盘上发生变化。请查看后重试。';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark 无法完全回滚实例更改。请在继续前查看这些文件：$paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport => '目录库无法导入 Markdown 主题。';

  @override
  String get errorWritersideInstanceWebPathInvalid => 'Web 路径必须为单行文本。';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside 实例配置无效。请修正其诊断信息后重试。';

  @override
  String get errorWritersideInstanceTemporaryFile => 'BusyMark 无法安全暂存实例更改。';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return '未知的实例状态“$status”。请使用 release、eap 或 deprecated。';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return '实例 ID“$id”被多个树文件使用。';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml 必须包含 <buildprofiles> 根元素。';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name 值“$value”必须为 true 或 false。';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> 元素必须指定实例 ID。';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '树中的 <include> 必须同时指定 from 和 element-id。';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '树中的 <snippet> 必须指定 id。';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      '跨实例目录引用必须同时指定 ref 和 in。';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      '目录元素不能同时指向多个主题、引用、链接或重定向。';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return '树元素 ID“$id”被声明了多次。';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      '实例组文件必须包含 <instance-groups> 根元素。';

  @override
  String get diagnosticWritersideInstanceGroupInvalid => '实例组必须指定非空 ID 和实例列表。';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return '实例组 ID“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return '目录包含项“$source#$id”属于外部模块“$origin”，无法在此工作区中展开。';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '已注册树“$source”中不存在树元素“$id”。';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return '树包含项“$source#$id”创建了循环。';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return '实例条件引用了未知组“@$group”。';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return '跨实例引用指向未知实例“$instance”。';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return '主题“$topic”不在被引用的实例“$instance”中。';
  }

  @override
  String get download => '下载';

  @override
  String get exportWritersideAsPdf => '将 Writerside 导出为 PDF';

  @override
  String get writersidePdfContent => '导出内容';

  @override
  String get writersidePdfPage => '页面';

  @override
  String get exportingWritersidePdf => '正在导出 Writerside PDF…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => '本地 Ollama';

  @override
  String get aiDisabled => '已禁用';

  @override
  String get aiExplicitEditingDescription =>
      'AI 编辑需要明确发起。BusyMark 只会将所选提供商对应的显示上下文发送出去，且不会在未经审核的情况下应用建议。';

  @override
  String get aiProvider => 'AI 提供商';

  @override
  String get aiDefaultProvider => '默认提供商';

  @override
  String get aiConfigureProvider => '配置提供商';

  @override
  String get aiChooseProvider => '选择 AI 提供商';

  @override
  String get aiOllamaEndpoint => 'Ollama 端点';

  @override
  String get aiOllamaModel => 'Ollama 模型';

  @override
  String get aiTestConnection => '测试连接';

  @override
  String get aiTestingConnection => '正在测试…';

  @override
  String aiConnectionReady(int count) {
    return '已连接。找到 $count 个已安装模型。';
  }

  @override
  String get aiNoModels => '未选择模型。';

  @override
  String get aiConnectionFailed => 'BusyMark 无法验证 AI 文本生成。';

  @override
  String get aiConfigureFirst => '请先在设置 → AI 中启用 AI 提供商并验证模型。';

  @override
  String get aiEditWithAi => '使用 AI 编辑';

  @override
  String get aiRefineWithAi => '使用 AI 优化';

  @override
  String get aiInstruction => '指令';

  @override
  String get aiChangeTarget => '可更改内容';

  @override
  String get aiSharedContext => '与 AI 共享的上下文';

  @override
  String get aiTargetSelection => '选中的内容';

  @override
  String get aiTargetInsertAfterBlock => '插入到当前块之后';

  @override
  String get aiTargetCurrentBlock => '当前块';

  @override
  String get aiTargetCurrentSection => '当前节';

  @override
  String get aiTargetCompleteDocument => '完整文档';

  @override
  String get aiContextNone => '没有文档上下文';

  @override
  String get aiContextSelection => '选中的内容';

  @override
  String get aiContextCurrentBlock => '当前块';

  @override
  String get aiContextCurrentSection => '当前节';

  @override
  String get aiContextCompleteDocument => '完整文档';

  @override
  String get aiGenerating => '正在生成建议…';

  @override
  String get aiProposal => 'AI 建议';

  @override
  String get aiGenerateProposal => '生成建议';

  @override
  String aiContextDisclosure(int count) {
    return '所选提供商将接收显示上下文中的 $count 个字符。';
  }

  @override
  String get aiOriginal => '原始内容';

  @override
  String get aiSuggested => '建议内容';

  @override
  String get aiApplyProposal => '应用建议';

  @override
  String aiTokenUsage(int input, int output) {
    return '输入 token：$input · 输出 token：$output';
  }

  @override
  String get aiStaleProposal => '生成此建议期间文档发生了变化。请重新执行操作。';

  @override
  String get gitAiStagedChangesChanged => '生成此提交消息期间，已暂存的更改发生了变化。请重新执行操作。';

  @override
  String get aiViewContext => '查看已发送的上下文';

  @override
  String get aiReviewExactContent => '查看确切内容';

  @override
  String get aiContentToChange => '要更改的内容';

  @override
  String get aiContentSentToAi => '发送给 AI 的内容';

  @override
  String get aiApiKey => 'API 密钥';

  @override
  String get aiApiKeyStoredHint => '密钥已存储在系统凭据存储中';

  @override
  String get aiApiKeyEnterHint => '输入提供商 API 密钥';

  @override
  String get aiReplaceApiKey => '替换 API 密钥';

  @override
  String get aiSaveApiKey => '安全保存 API 密钥';

  @override
  String get aiRemoveApiKey => '移除已保存的 API 密钥';

  @override
  String get aiCredentialSaved => 'API 密钥已保存到系统凭据存储中。';

  @override
  String get aiCredentialRemoved => '已移除保存的 API 密钥。';

  @override
  String get aiModelRouting => '模型路由';

  @override
  String get aiAutomaticRouting => '按任务自动选择';

  @override
  String get aiFixedModelRouting => '使用选中的模型';

  @override
  String get aiPreferredModel => '首选模型';

  @override
  String get aiModel => '模型';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests 个请求 · $input 个输入 token · $output 个输出 token';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '将内容发送给 $provider？';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '启用 $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      '只会发送每个 AI 审核对话框中显示的内容。请求不保存状态，建议需要审核，API 密钥存储在 Linux 系统凭据存储中。';

  @override
  String aiCloudConsentRequired(String provider) {
    return '请先在设置 → AI 中确认与 $provider 共享数据。';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '已通过 $model 验证生成能力。有 $count 个兼容模型可用。';
  }

  @override
  String get aiColdStartObserved => '检测到本地模型冷启动。';

  @override
  String get aiNoCompatibleModels => '没有可用的兼容文本生成模型。';

  @override
  String get aiEnableProvider => '请先启用 AI 提供商。';

  @override
  String get aiDraftCommitMessage => '起草提交消息';

  @override
  String get aiDrafting => '正在起草…';

  @override
  String get aiDraftWithAi => '使用 AI 起草';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '标题级别 $level 跟在级别 $previousLevel 之后；请检查节的嵌套结构。';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText => '链接文本为空；请提供能描述其用途的可访问名称。';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return '请检查链接文本“$text”是否在上下文中描述了其用途。';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader => '表头单元格必须标识其列；请补全每个空表头。';

  @override
  String get mathRenderFailed => '无法渲染数学表达式。';

  @override
  String get inlineMath => '行内数学';

  @override
  String get displayMath => '显示数学';

  @override
  String get goToDeclaration => '转到声明';

  @override
  String get findUsages => '查找用法';

  @override
  String get cannotRenameSymbol => '无法安全地重命名此符号。请检查名称并刷新引用，然后重试。';

  @override
  String get renameTopicFileInstead => '主题 ID 来自其文件名。请在目录或“文件”侧边栏中使用“重命名主题文件”。';

  @override
  String get keyboardLayout => '键盘布局';

  @override
  String get diagnosticWritersideUnsupported => '不支持或格式错误的内容将显示为源代码。';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return '无法解析源“$reference”：$reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return '此实例中无法使用链接目标：$destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return '无效的 Writerside 标记：$element，$attribute。$reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      '请使用 <llms-txt>true</llms-txt> 或 <llms-txt>false</llms-txt>；不再支持 single-file。';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '无法解析 $kind：$reference';
  }

  @override
  String get exportAsHtml => '导出为 HTML…';

  @override
  String get fileTypeHtml => 'HTML 文档';

  @override
  String get exportingHtml => '正在导出 HTML…';

  @override
  String get htmlExported => 'HTML 导出完成';

  @override
  String get htmlExportFailed => 'HTML 导出失败';

  @override
  String get htmlKeepAssetsTogether => '复制导出结果时，请将 HTML 文件及其配套资源文件夹放在一起。';

  @override
  String get htmlInstanceDescription => '将一个实例导出为相互链接的离线页面。请选择专用输出文件夹的名称。';

  @override
  String get htmlInstance => '实例';

  @override
  String get htmlOwnedDirectoryOnly =>
      '只能替换由 BusyMark HTML 导出创建的文件夹。已修改或无关的文件将被保留。';

  @override
  String get showInFolder => '在文件夹中显示';

  @override
  String sortTableColumn(String column) {
    return '排序 $column';
  }

  @override
  String get exportReset => '恢复默认值';

  @override
  String get exportToc => '包含目录';

  @override
  String get exportTocDepth => '目录深度';

  @override
  String get exportNumberHeadings => '为标题编号';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => '自定义';

  @override
  String get exportPageWidth => '页面宽度（mm）';

  @override
  String get exportPageHeight => '页面高度（mm）';

  @override
  String get exportMarginTop => '上边距（mm）';

  @override
  String get exportMarginRight => '右边距（mm）';

  @override
  String get exportMarginBottom => '下边距（mm）';

  @override
  String get exportMarginLeft => '左边距（mm）';

  @override
  String get exportTypography => '字体';

  @override
  String get exportSans => '无衬线';

  @override
  String get exportSerif => '衬线';

  @override
  String get exportBodySize => '正文字号';

  @override
  String get exportCodeSize => '代码字号';

  @override
  String get exportRunningText => '页眉和页脚';

  @override
  String get exportHeader => '页眉';

  @override
  String get exportFooter => '页脚';

  @override
  String get exportNone => '无';

  @override
  String get exportDocumentTitle => '文档标题';

  @override
  String get exportBottomLeft => '左下';

  @override
  String get exportBottomCenter => '底部居中';

  @override
  String get exportBottomRight => '右下';

  @override
  String get exportFirstPage => '在首页显示页眉和页脚';

  @override
  String get exportAccent => '强调色／链接颜色';

  @override
  String get exportTheme => '主题';

  @override
  String get exportAutomatic => '自动';

  @override
  String get exportLayout => '布局';

  @override
  String get exportContentWidth => '内容最大宽度';

  @override
  String get exportOutput => '输出';

  @override
  String get exportPackaging => '打包方式';

  @override
  String get exportSingleFile => '单个 HTML 文件';

  @override
  String get exportAssetsDirectory => 'HTML + 资源目录';

  @override
  String get exportCustomCss => '自定义样式表…';

  @override
  String get exportRemoveCss => '移除自定义样式表';

  @override
  String get exportCssNote =>
      '可选用 UTF-8 CSS 文件（最大 256 KiB）。不接受导入、资源 URL、可执行或转义 CSS。样式在 BusyMark 样式表之后应用。不会获取远程资源。';

  @override
  String get exportSitePackagingNote =>
      'Writerside 保留独立且相互链接的主题页面。单文件模式将资源嵌入每个页面。';

  @override
  String get exportInvalidGeometry => '扣除边距后，请至少保留 20 mm 的内容宽度和高度。';

  @override
  String get exportInvalidColor => '请输入 #RRGGBB 格式的颜色。';

  @override
  String get exportInvalidCss =>
      '请选择可读取的 UTF-8 .css 文件（最大 256 KiB），不得包含导入、资源 URL、HTML、可执行或转义 CSS。';

  @override
  String get clipboardHistory => '剪贴板历史';

  @override
  String get clipboardHistoryDescription => '打开会话本地剪贴板历史。';

  @override
  String get clipboardCurrent => '当前剪贴板';

  @override
  String get clipboardCurrentExternal => '来自其他应用程序的当前剪贴板';

  @override
  String clipboardDestination(String name) {
    return '粘贴到 $name';
  }

  @override
  String get clipboardSessionOnly => '仅存储在本次 BusyMark 会话中。';

  @override
  String get clipboardNoItems => '剪贴板历史为空。';

  @override
  String get clipboardDisabled => '剪贴板历史集合在设置中已禁用。';

  @override
  String get clipboardUnavailable => '当前剪贴板内容不可用或不受支持。';

  @override
  String get clipboardTooLarge => '此剪贴板内容过大，无法保留。';

  @override
  String get clipboardPastePlainText => '作为纯文本粘贴';

  @override
  String get clipboardClearAll => '清除剪贴板历史';

  @override
  String get clipboardEntryText => '文本';

  @override
  String get clipboardEntryRichText => '丰富文本';

  @override
  String get clipboardEntryImage => '图片';

  @override
  String clipboardOrigin(String name) {
    return '复制自 $name';
  }

  @override
  String get localHistory => '本地历史';

  @override
  String get localHistoryEllipsis => '本地历史…';

  @override
  String get localHistoryDescription => '显示当前文档的已保存和自动本地修订。';

  @override
  String get findLocalHistoryEllipsis => '在本地历史中查找…';

  @override
  String get findLocalHistoryDescription => '搜索本地历史文档和修订内容。';

  @override
  String get localHistoryNoDocuments => '尚无文档具有本地历史。';

  @override
  String get localHistoryNoRevisions => '此文档没有本地历史修订。';

  @override
  String get localHistorySelectedRevision => '已选择的修订';

  @override
  String get localHistoryCurrentEditor => '当前编辑器内容';

  @override
  String get localHistoryCurrentDisk => '磁盘上的当前内容';

  @override
  String get localHistoryMissingFile => '原始文件丢失。';

  @override
  String get localHistoryRestoreRevision => '恢复版本';

  @override
  String get localHistoryRestoreOriginalLocation => '恢复到原始位置';

  @override
  String get localHistoryRestoreNewLocation => '恢复到新位置…';

  @override
  String get localHistoryRestoreChange => '恢复更改';

  @override
  String get localHistoryRestoreUnavailable => '无法恢复此更改，因为比较已过时。';

  @override
  String get localHistoryComparisonSimplified => '此大型比较已简化。 无法恢复单个更改。';

  @override
  String localHistoryOlderChange(String text) {
    return '较旧的版本更改： $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return '当前内容更改： $text';
  }

  @override
  String get localHistoryDeleted => '已删除';

  @override
  String get localHistoryUntitled => '未命名';

  @override
  String get localHistoryClearDocument => '清除此文档的历史';

  @override
  String get localHistoryClearAll => '清除所有本地历史';

  @override
  String get localHistoryClearDocumentTitle => '清除文档历史？';

  @override
  String get localHistoryClearAllTitle => '清除所有本地历史？';

  @override
  String get localHistoryClearConfirmation => '这将永久删除存储的修订。 此操作无法撤销。';

  @override
  String get localHistoryWarningIndexRebuilt => '本地历史索引已损坏并从完整修订中重建。';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return '此本地历史存储使用不受支持的格式 $version。';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return '本地历史不可用： $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      '录音已禁用或此路径已排除。 在恢复之前重新启用录音。';

  @override
  String localHistoryWarningPathChange(String detail) {
    return '无法记录本地历史路径更改： $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return '本地历史记录无法保留已删除的路径： $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing => '所选版本丢失或损坏。';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return '无法读取所选版本： $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return '本地历史记录无法捕获此版本： $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason・$timestamp';
  }

  @override
  String get localHistoryReasonBaseline => '基线';

  @override
  String get localHistoryReasonSaved => '已保存';

  @override
  String get localHistoryReasonAutomaticCheckpoint => '自动检查点';

  @override
  String get localHistoryReasonBeforeReload => '在重新加载之前';

  @override
  String get localHistoryReasonBeforeDiscard => '在丢弃之前';

  @override
  String get localHistoryReasonBeforeRestore => '恢复前';

  @override
  String get localHistoryReasonBeforeDelete => '删除前';

  @override
  String get localHistoryReasonExternalChange => '外部修改';

  @override
  String get settingsHistory => '历史记录';

  @override
  String get settingsClipboardHistoryTitle => '收集剪贴板历史';

  @override
  String get settingsClipboardHistoryDescription =>
      '只保留本次 BusyMark 会话中已复制并成功粘贴的内容。';

  @override
  String get settingsLocalHistoryTitle => '记录本地历史';

  @override
  String get settingsLocalHistoryDescription => '将文档修订存储在此设备上，以便恢复和比较。';

  @override
  String get settingsHistoryCheckpoint => '自动检查点间隔';

  @override
  String get settingsHistoryRetention => '保留期限';

  @override
  String get settingsHistoryStorage => '最大存储';

  @override
  String get settingsHistoryExcludedPaths => '排除路径';

  @override
  String get settingsHistoryExcludedPathsHint => '每行一个绝对路径';

  @override
  String settingsSecondsValue(int value) {
    return '$value 秒';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value 天';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => '拼写检查';

  @override
  String get automaticSpelling => '自动检查拼写';

  @override
  String get defaultSpellingLanguage => '默认拼写语言';

  @override
  String get projectSpellingLanguage => '项目拼写检查语言';

  @override
  String get chooseSpellingLanguage => '选择拼写语言';

  @override
  String get spellingLanguageUnsetStatus => '语言…';

  @override
  String get spellingOffStatus => '拼写检查已关闭';

  @override
  String get checkSpelling => '检查拼写';

  @override
  String get ignoreSpellingOnce => '忽略一次';

  @override
  String get ignoreSpellingDocument => '在此文档中全部忽略';

  @override
  String get addPersonalSpellingWord => '添加到个人词典';

  @override
  String get addProjectSpellingWord => '添加到项目词典';

  @override
  String get inheritSpellingLanguage => '使用项目或应用语言';

  @override
  String get disableDocumentSpelling => '不检查拼写';

  @override
  String get importSpellingDictionary => '导入词典';

  @override
  String get personalSpellingDictionary => '个人词典';

  @override
  String get projectSpellingDictionary => '项目词典';

  @override
  String get noSpellingErrors => '没有拼写错误';

  @override
  String get noSpellingSuggestions => '没有拼写建议';

  @override
  String get spellingWordCheckFailed => '无法检查此单词';

  @override
  String get spellingCheckFailed => '拼写检查失败';

  @override
  String get spellingSettingsLoadFailed => '无法加载拼写检查设置';

  @override
  String get retrySpellingSettings => '重试加载拼写检查设置';

  @override
  String get spellingCheckIncomplete => '拼写检查未完成';

  @override
  String get spellingDictionaryNotInstalled => '尚未安装词典';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return '尚未安装 $dictionary 词典';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return '未安装 · $size';
  }

  @override
  String get spellingDictionaryInstalled => '已安装';

  @override
  String get installSpellingDictionary => '安装词典';

  @override
  String get removeSpellingDictionary => '移除词典';

  @override
  String get cancelSpellingDictionaryInstall => '取消下载词典';

  @override
  String get retrySpellingDictionaryInstall => '重试安装词典';

  @override
  String spellingDictionaryDownloading(String size) {
    return '正在下载 $size…';
  }

  @override
  String get spellingDictionaryValidating => '正在验证词典…';

  @override
  String get spellingDictionaryInstallFailed => '词典安装失败 — 选择以重试';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '要安装 $dictionary（$size）吗？安装后，在移除前都可离线使用。';
  }

  @override
  String get spellingDictionaryUnavailable => '词典不可用';

  @override
  String get spellingChecking => '正在检查拼写…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field：请输入 $minimum 到 $maximum 之间的数字。';
  }

  @override
  String get spellingDictionaryRecoveryConflict => '拼写词典已被外部更改。已保留恢复副本。';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => '连接';

  @override
  String get nextcloudReconnect => '重新连接';

  @override
  String get nextcloudDisconnect => '断开连接';

  @override
  String get nextcloudServer => '服务器地址';

  @override
  String get nextcloudSignInBrowser => '请在浏览器中完成登录。';

  @override
  String get nextcloudFavorites => '收藏';

  @override
  String get nextcloudNewNote => '新建笔记';

  @override
  String get nextcloudSavedLocally => '已保存到本地 · 等待同步';

  @override
  String get nextcloudSyncing => '正在同步';

  @override
  String get nextcloudSynced => '已同步';

  @override
  String get nextcloudOffline => '离线';

  @override
  String get nextcloudLocked => '被服务器锁定';

  @override
  String get nextcloudReconnectRequired => '需要重新连接';

  @override
  String get nextcloudCreationUncertain => '创建结果不确定';

  @override
  String get nextcloudReadOnly => '只读';

  @override
  String get nextcloudTakeRemote => '使用服务器版本';

  @override
  String get nextcloudMerge => '合并';

  @override
  String get nextcloudDeleteNote => '删除笔记？';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Nextcloud Notes不支持工作区整体替换。请在每条笔记中替换。';

  @override
  String get nextcloudSaveLocalCopy => '保存本地副本…';

  @override
  String get nextcloudDisconnectWarning =>
      '移除此账户将删除此设备上缓存的笔记和待同步的更改。请先同步，将工作保留在服务器上。';

  @override
  String get nextcloudAttachmentRetryWarning => '如果上次上传成功，重试可能会在服务器上留下未使用的附件。';

  @override
  String get nextcloudAttachmentReference => '服务器上的附件引用';

  @override
  String get nextcloudAddAttachment => '添加附件…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      '删除此附件后，笔记中指向它的链接将不可用。保留的数据可通过本地历史记录恢复。';

  @override
  String get nextcloudChooseConflictingAttributes => '为每个冲突属性选择一个值。';

  @override
  String get nextcloudUseServerNote => '使用此服务器笔记';

  @override
  String get nextcloudUseServerNoteExplanation =>
      '将此草稿关联到选定的服务器笔记，然后同步保留的本地更改。请求匹配并不能确认笔记由谁创建。';

  @override
  String get nextcloudExactCandidate => '与请求完全匹配；身份尚未确认。';

  @override
  String get nextcloudPossibleCandidate => '可能与规范化后的请求匹配；身份尚未确认。';

  @override
  String get nextcloudSelectCandidate => '选择要检查的服务器笔记';

  @override
  String get nextcloudCreateSeparate => '创建独立笔记';

  @override
  String get nextcloudCreateSeparateWarning =>
      '首次请求可能已在服务器上创建笔记。此操作将使用保留的本地工作创建独立笔记。不会删除任何疑似重复的笔记。';

  @override
  String get wsSemanticFormats => '语义格式';

  @override
  String get wsUiControl => '界面控件';

  @override
  String get wsFilePath => '文件 / 路径';

  @override
  String get wsUiPath => '界面路径';

  @override
  String get wsDefinitionList => '定义列表';

  @override
  String get wsIncludeContent => '包含可复用内容';

  @override
  String get wsVariableReference => '变量引用';

  @override
  String get wsConvertList => '将列表转换为过程';

  @override
  String get wsElementProperties => '元素属性';

  @override
  String get wsTopicProperties => '主题属性';

  @override
  String get wsCollapsible => '可折叠';

  @override
  String get wsPublishedState => '发布时的初始状态';

  @override
  String get wsExpanded => '展开';

  @override
  String get wsCollapsed => '折叠';

  @override
  String get wsCollapsedTitle => '折叠标题';

  @override
  String get wsTerm => '术语';

  @override
  String get wsListLayout => '列表布局';

  @override
  String get wsSyncGroup => '同步组';

  @override
  String get wsTabKey => '选项卡键';

  @override
  String get wsSwitcherLabel => '切换器标签';

  @override
  String get wsNavigationElements => '导航元素';

  @override
  String get wsNavigationDepth => '导航深度';

  @override
  String get wsAddItem => '添加项目';

  @override
  String get wsStep => '步骤';

  @override
  String get wsPropertyInvalid => '属性值无效';

  @override
  String get wsFilter => '筛选器';

  @override
  String get wsIdentifier => '元素 ID';

  @override
  String get wsTldr => '摘要 (TLDR)';

  @override
  String get wsFullLayout => '全宽';

  @override
  String get wsMediumLayout => '中等 (1:2)';

  @override
  String get wsNarrowLayout => '窄术语列';

  @override
  String get wsTitle => '标题';

  @override
  String get wsSwitcherKey => '切换键';

  @override
  String get nextcloudServerSettings => '服务器 Notes 设置';

  @override
  String get nextcloudNotesPath => '笔记文件夹路径';

  @override
  String get nextcloudFileSuffix => '新笔记的文件后缀';

  @override
  String get nextcloudServerSettingsExplanation =>
      '这些服务器 Notes 设置会影响其他客户端。更改路径不会移动文件；更改后缀不会重命名现有笔记。';

  @override
  String get nextcloudSettingsSaved => '服务器设置已保存';

  @override
  String get nextcloudSettingsNormalized => '已保存服务器规范化后的值';

  @override
  String get nextcloudPendingUpload => '附件等待上传';

  @override
  String nextcloudServerCheck(String time) {
    return '上次服务器检查：$time';
  }

  @override
  String get nextcloudSettingsLoading => '正在加载服务器设置';

  @override
  String get nextcloudSettingsSaving => '正在保存服务器设置';

  @override
  String get nextcloudPreviousLocalEdit => '先前的本地编辑';

  @override
  String get nextcloudUsePreviousEdit => '使用先前编辑';

  @override
  String get quickOpen => '快速打开';

  @override
  String get notesAll => '所有笔记';

  @override
  String get notesUncategorized => '未分类';

  @override
  String get notesRecovery => '恢复';

  @override
  String get notesRecentlyEdited => '最近编辑';

  @override
  String get notesOldestEdited => '最早编辑';

  @override
  String get notesTitleAscending => '标题升序';

  @override
  String get notesTitleDescending => '标题降序';

  @override
  String get notesMove => '移至分类';

  @override
  String get notesRemoveFavorite => '取消收藏';

  @override
  String get notesOffline => '设为离线可用';

  @override
  String get notesOfflineRemove => '移除离线保留要求';

  @override
  String get notesIndexing => '正在索引笔记…';

  @override
  String get notesSearchHelp => '词项使用“与”组合。可使用\"引号短语\"、title: 和 category:。';

  @override
  String get notesSourceLocation => '源文件位置';

  @override
  String get notesRecoveryHelp => '仅包括保留的本地笔记和本地历史。无法访问服务器回收站或历史。';

  @override
  String get notesImport => '导入笔记';

  @override
  String get notesExport => '导出笔记';

  @override
  String get notesImportDistinct => '导入为独立笔记';

  @override
  String get notesAvailableOffline => '离线可用';

  @override
  String get notesIncomplete => '不完整';

  @override
  String get notesSelected => '已选笔记';

  @override
  String get notesNoHistory => '没有保留的版本。历史可能已禁用、过期或清除。';

  @override
  String get notesTextAvailable => '文本已在本地可用';

  @override
  String get notesLocalVersion => '本地工作版本';

  @override
  String get notesAttachments => '附件';

  @override
  String get notesSkipped => '已跳过';

  @override
  String get notesFailed => '失败';

  @override
  String get notesCompleted => '已完成';

  @override
  String get notesImportNew => '开始新导入';

  @override
  String get notesImportResume => '继续中断的导入';

  @override
  String get notesImportAlreadyImported => '已在此操作中导入';

  @override
  String get references => '引用';

  @override
  String get referenceIncoming => '传入';

  @override
  String get referenceOutgoing => '传出';

  @override
  String get referenceChooseTarget => '选择链接目标';

  @override
  String get referenceWholeDocument => '整个文档';

  @override
  String get referenceSourceLocation => '源位置';

  @override
  String get referenceTargetLocation => '目标位置';

  @override
  String get referenceResolved => '已解析';

  @override
  String get referenceMissing => '缺失';

  @override
  String get referenceAmbiguous => '不明确';

  @override
  String get referenceUnavailable => '当前上下文中不可用';

  @override
  String get referenceUnsupported => '不支持';

  @override
  String get referenceNoPortableId => '此目标没有经过验证的可移植笔记网址。';

  @override
  String get wsIncludeLines => '包含行';

  @override
  String get wsIncludeSymbol => '包含符号';

  @override
  String get wsEmphasizeLines => '突出显示已显示的行';

  @override
  String get wsPropertiesReadOnly => '此视图中的属性为只读。';

  @override
  String get wsPropertiesProtected => '此元素受保护。请编辑其源代码。';

  @override
  String get wsPropertiesConflict => '文档或元素已更改。请还原草稿并重新选择。';

  @override
  String get wsPropertiesUnresolved => '目前无法解析此引用。';

  @override
  String get wsUseDefault => '使用默认值';

  @override
  String get wsPropertiesSelection => '请选择单个元素。';

  @override
  String get wsImageDisplay => '图像显示';

  @override
  String get wsImageThumbnail => '可点击缩略图';

  @override
  String get wsEnabled => '已启用';

  @override
  String get wsDisabled => '已禁用';

  @override
  String get wsWidth => '宽度';

  @override
  String get wsHeight => '高度';

  @override
  String get wsPropertiesInactive => '未启用发布折叠时，此属性无效。';

  @override
  String get wsNavigationAll => '所有有标题的元素';

  @override
  String get wsNavigationNone => '无导航';

  @override
  String get wsNavigationCustom => '自定义导航';

  @override
  String get wsTitleOverride => '覆盖标题';

  @override
  String get wsCompactLayout => '紧凑';

  @override
  String get wsWideLayout => '宽';

  @override
  String get wsCodeSourceConflict =>
      '设置 src 前，请移走或删除此代码块中编写的代码。Writerside 不接受带有源引用的非空代码块。';

  @override
  String get wsInherited => '从列表继承';

  @override
  String get wsExternalImageSize => 'Writerside 无法可靠地调整外部托管图片的尺寸。可以查看和移除已有尺寸。';

  @override
  String get wsPropertiesNotSerialized => '此更改未写入源文本。草稿已保留。';

  @override
  String get wsListItem => '列表项';

  @override
  String get wsSourceFile => '源文件';

  @override
  String get wsLinkTarget => '链接目标';

  @override
  String get wsPreviewImage => '预览图像';

  @override
  String get wsIncludedElement => '包含的元素';

  @override
  String get wsHelpModule => '帮助模块';

  @override
  String get wsActionId => '操作 ID';

  @override
  String get wsKeymapHelpInstance => '键位映射帮助实例';

  @override
  String get wsShowInSource => '在源代码中显示';

  @override
  String get wsOriginElement => '元素覆盖值';

  @override
  String get wsOriginAncestor => '父元素';

  @override
  String get wsOriginModule => '模块默认值';

  @override
  String get wsOriginBuiltIn => '内置默认值';

  @override
  String get wsOriginUnresolved => '未解析';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return '有效值：$value — $origin';
  }

  @override
  String get wsElementSelector => '元素';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return '生成值：$anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return '默认值：$value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return '默认值：$value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return '解析值：$value';
  }

  @override
  String get wsPropertyUnresolved => '未解析';

  @override
  String get wsModule => '模块';

  @override
  String get wsParent => '父元素';

  @override
  String get wsListType => '列表类型';

  @override
  String get wsStartingNumber => '起始编号';

  @override
  String get wsListSorting => '排序';

  @override
  String get wsLetteredList => '字母列表';

  @override
  String get wsCheckboxList => '复选框列表';

  @override
  String get wsMarkerlessList => '无标记列表';

  @override
  String get wsAscending => '升序';

  @override
  String get wsDescending => '降序';

  @override
  String get wsNoSorting => '不排序';

  @override
  String get wsAsWritten => '按原文';

  @override
  String get wsSentenceCase => '句首大写';

  @override
  String get wsTitleCase => '标题大写';

  @override
  String get wsLowerCase => '小写';

  @override
  String get wsUpperCase => '大写';

  @override
  String get wsNativeMarkers => 'Markdown 标记';

  @override
  String wsListMarkerStart(String number) {
    return '起始标记：$number';
  }

  @override
  String wsListLevel(String level) {
    return '层级 $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      '固定版本的构建器会忽略模块的 <caps> 规则。请使用本地 caps 属性或 default-property。';

  @override
  String get wsInsertElements => '插入元素';

  @override
  String get wsAdmonitionsAndQuotes => '提示和引用';

  @override
  String get wsSemanticText => '语义文本';

  @override
  String get wsPropertiesUnavailable => '所检查的元素不可用。请检查一个元素以继续。';

  @override
  String get searchDocumentsCategory => '文档';

  @override
  String get searchTopicsCategory => '主题';

  @override
  String get searchCurrentDocument => '当前文档';

  @override
  String get searchCurrentWorkspace => '当前工作区';

  @override
  String get browseNotes => '浏览笔记';

  @override
  String get searchActionsCommand => '搜索操作';

  @override
  String get searchDocumentsCommand => '搜索文档';

  @override
  String get searchTopicsCommand => '搜索主题';

  @override
  String get searchRecentCommand => '搜索最近项目';

  @override
  String get searchResourceUnavailable => '此资源不可用。';

  @override
  String get notesSync => '同步笔记';

  @override
  String get searchInWorkspace => '在工作区中搜索';

  @override
  String get searchCategory => '搜索类别';

  @override
  String get clearHistorySearchScope => '搜索文档历史记录';

  @override
  String get searchInDocument => '在文档中搜索';

  @override
  String get searchDocumentHint => '搜索此文档…';

  @override
  String get searchWorkspaceHint => '搜索此工作区…';

  @override
  String get searchOutlineHint => '搜索标题…';

  @override
  String get searchHistoryHint => '搜索本地历史记录…';

  @override
  String get searchEnterText => '输入要搜索的文本';

  @override
  String get searchAccountUnavailable => '账户不可用';

  @override
  String get searchDocumentsHint => '搜索文档…';

  @override
  String get searchTopicsHint => '搜索主题…';

  @override
  String get searchRecentHint => '搜索最近项目…';

  @override
  String get searchActionsHint => '搜索操作…';

  @override
  String get searchRequiresNotesWorkspace => '需要笔记工作区';

  @override
  String get searchSidebarLabel => '搜索：';

  @override
  String get searchDocumentTextCategory => '文档文本';

  @override
  String get searchWorkspaceTextCategory => '工作区文本';

  @override
  String get searchHeadingsCategory => '标题';

  @override
  String get shortcutUnassigned => '未分配';

  @override
  String get shortcutPressKeys => '请按下组合键…';

  @override
  String get shortcutRecord => '录制快捷键';

  @override
  String get shortcutRestoreAll => '恢复所有默认设置';

  @override
  String get shortcutRestoreAllQuestion => '恢复所有操作的默认快捷键？自定义分配将被移除。';

  @override
  String get shortcutSaveFailed => '快捷键已生效，但无法保存。请重试保存以便重启后保留。';

  @override
  String get shortcutRetry => '重试保存';

  @override
  String get shortcutChanged => '分配已更改。请检查当前快捷键并重试。';

  @override
  String get shortcutInvalid => '无法在此上下文中分配此组合键。';

  @override
  String get shortcutSystemWarning => '桌面可能正在使用此组合键。BusyMark 无法覆盖系统快捷键。';

  @override
  String get shortcutConflicts => '此快捷键与以下操作冲突：';

  @override
  String get shortcutRemove => '移除分配';

  @override
  String get shortcutRestoreDefault => '恢复默认设置';

  @override
  String get shortcutAssign => '分配';

  @override
  String get shortcutReassign => '重新分配';

  @override
  String get shortcutContextApplication => '应用程序';

  @override
  String get shortcutContextDocument => '文档视图';

  @override
  String get shortcutContextEditor => '编辑器和源码';

  @override
  String get shortcutContextWritersideSource => 'Writerside 源码';

  @override
  String get shortcutContextWorkspace => '工作区导航';

  @override
  String get shortcutContextTree => '侧栏树';

  @override
  String get searchHeadingsCommand => '搜索标题';

  @override
  String get shortcutFixed => '由编辑器管理，无法配置。';

  @override
  String get shortcutDefaultConflict => '默认快捷键与自定义分配冲突。';

  @override
  String get shortcutCurrentBinding => '当前快捷键';

  @override
  String get shortcutProposedBinding => '拟用快捷键';

  @override
  String get notesActions => '笔记操作';

  @override
  String get noteActions => '此笔记的操作';

  @override
  String get noteProperties => '笔记属性';

  @override
  String get notesExportAll => '导出笔记 · 所有笔记…';

  @override
  String get notesExportCategory => '导出笔记 · 类别…';

  @override
  String get notesOfflineAll => '设为离线可用 · 所有笔记';

  @override
  String get notesOfflineCategory => '设为离线可用 · 类别';

  @override
  String get notesOfflineRemoveAll => '移除离线保留要求 · 所有笔记';

  @override
  String get notesOfflineRemoveCategory => '移除离线保留要求 · 类别';

  @override
  String get notesOfflinePause => '暂停下载';

  @override
  String get notesOfflineResume => '继续下载';

  @override
  String get notesOfflineKeep => '设为离线可用';

  @override
  String get notesOfflineRetentionHelp => '移除此保留要求不会删除现有缓存。分类或账户的要求仍可能保留此笔记。';

  @override
  String get notesOfflineBroader => '此笔记也因分类或账户的要求而被保留。';

  @override
  String get notesOfflineExternal => '外部媒体需要网络连接。BusyMark 只保留笔记文本和托管附件。';

  @override
  String get notesEmptyAll => '还没有笔记。请新建一条笔记。';

  @override
  String get notesEmptyFavorites => '没有收藏的笔记。';

  @override
  String get notesEmptyCategory => '此分类中没有笔记。';

  @override
  String get notesEmptyUncategorized => '没有未分类笔记。';

  @override
  String get notesEmptyRecovery => '没有可恢复的本地保留笔记。';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · 失败. 重试';

  @override
  String get notesOperationFailed => '无法完成操作。草稿已保留。请检查保存状态和冲突后重试。';

  @override
  String get notesInspectionFailed => '附件 · 失败. 重试';

  @override
  String get notesStartingConnection => '正在连接 Nextcloud…';

  @override
  String get notesVerifyingConnection => '正在验证笔记访问权限…';

  @override
  String get notesCancellingConnection => '正在取消登录并清理…';

  @override
  String get notesRemovingConnection => '正在移除本地账户…';

  @override
  String get notesRemovedWarning =>
      '本地 Nextcloud 账户已移除，但无法确认应用密码已撤销。请在 Nextcloud 安全设置中移除 BusyMark 的应用密码。';

  @override
  String get notesBuffersNotSaved =>
      '无法将所有打开的笔记保存到本地。请在工作区检查保存、冲突或规范化处理。待处理的本地更改可能仍需与 Nextcloud 同步。';

  @override
  String get notesSettingsLeave => '离开前保存 Nextcloud 设置更改吗？';

  @override
  String get notesSettingsLeaveHelp => '服务器 Notes 设置 · 未保存的更改';

  @override
  String get notesSettingsReload => '重新加载服务器设置…';

  @override
  String get notesSettingsReloadHelp => '重新加载会用 Nextcloud 当前设置替换草稿。放弃草稿并重新加载吗？';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud 已接受设置，但刷新笔记失败。显示的是服务器确认的设置值。请从笔记界面重试刷新。';

  @override
  String get notesUnavailable => '离线 · 文本已在本地可用 · 已保存到本地 · 等待同步';

  @override
  String get notesStorageFull => 'Nextcloud 存储空间已满。请释放服务器空间后重试。';

  @override
  String get notesRejected => 'Nextcloud 拒绝了此更改。请检查笔记并保存本地副本后重试。';

  @override
  String get notesThrottled => 'Nextcloud 要求稍候。同步将在重试期限后继续。';

  @override
  String get notesRecoveryRequired => '冲突 · 比较';

  @override
  String get notesScanning => '正在扫描文件…';

  @override
  String get notesCancelling => '正在取消…等待当前操作结束。';

  @override
  String get notesCancelled => '已取消';

  @override
  String get notesPartial => '部分完成';

  @override
  String get notesTransferFailed => '失败. 重试';

  @override
  String get notesImportPartialHelp => '之前的项目可能已保存在本地。请继续本次导入，以免创建重复笔记。';

  @override
  String get notesNotStarted => '尚未开始';

  @override
  String get notesCreated => '已创建';

  @override
  String get notesRemoteDeleteUnavailable => '服务器地址 · 不支持 · 删除 · 附件';

  @override
  String get notesCurrentText => '当前保留的文本';

  @override
  String get notesRecovering => '正在恢复为新笔记…';

  @override
  String get notesReadOnlyHelp => '只读 · 收藏 · 保存本地副本…';

  @override
  String get notesSort => '笔记排序';

  @override
  String get notesPathRelative => '笔记文件夹路径相对于您的 Nextcloud 存储空间。';

  @override
  String get notesSettingsStale => 'Nextcloud 上的设置已更改。请重新加载并检查服务器值，再替换草稿。';

  @override
  String get notesDownloadsPaused => '下载已暂停';

  @override
  String get notesExportNotPublished => '未发布任何导出。';

  @override
  String get notesKeyringUnavailable => '请解锁桌面密钥环后重试。';

  @override
  String get notesConnectFailed => '无法连接 Nextcloud Notes。请检查服务器地址后重试。';

  @override
  String get notesAccountMismatch => '请登录同一 Nextcloud 账户。要连接其他账户，请先移除此账户。';

  @override
  String get notesLocalRemovalFailed => '本地账户清理失败。账户已保留，以便重试移除。';

  @override
  String get notesTransferring => '正在传输笔记…';

  @override
  String get notesTechnicalDetails => '技术详情';

  @override
  String get notesPauseRequirement => '暂停离线保留要求';

  @override
  String get notesResumeRequirement => '继续离线保留要求';

  @override
  String get gitReturnToDocument => '返回文档';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return '只读快照 · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      '此文件名包含非 UTF-8 字节。仍可进行 Git 审阅和暂存；文档编辑器需要 UTF-8 文件名。';

  @override
  String get gitUiMergeInProgress => '合并进行中';

  @override
  String get gitUiRebaseInProgress => '正在重定基准';

  @override
  String get gitUiCherryPickInProgress => '樱桃选集在进行中';

  @override
  String get gitUiRevertInProgress => '还原中';

  @override
  String get gitUiPatchApplicationInProgress => '补丁应用程序正在进行中';

  @override
  String get gitUiSquashMergeResultAwaitingCommit => 'Squash 合并结果等待执行';

  @override
  String get gitUiUnresolvedIndexConflicts => '未解决的索引冲突';

  @override
  String get gitUiUnresolvedConflicts => ' · 未解决的冲突';

  @override
  String get gitUiReviewOperation => '审查业务';

  @override
  String get gitUiRefresh => '刷新';

  @override
  String get gitUiCreateNamedStash => '创建命名的收藏';

  @override
  String get gitUiCreateStash => '创建贮藏…';

  @override
  String get gitUiNoStashes => '没有藏东西';

  @override
  String get gitUiSelectAStashToInspectItsChanges => '选择要检查更改的隐藏';

  @override
  String get gitUiStashedUntrackedFiles => '未跟踪的文件';

  @override
  String get gitUiInspectStashedUntrackedFiles => '检查隐藏的未跟踪文件...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      '在应用时恢复藏品的阶段状态/索引状态';

  @override
  String get gitUiApplyAndRetain => '应用和保留';

  @override
  String get gitUiPop => '爷爷...';

  @override
  String get gitUiCreateBranch => '创建分支…';

  @override
  String get gitUiDropStash => '删除贮藏…';

  @override
  String get gitUiBranchFromStash => '从贮藏创建分支';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      '创建/ 切换到藏匿处的分支, 然后应用它 。 原始隐藏部分留待日后明确删除 。';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0这个藏品?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      '如果适用冲突,则保留原始藏品。';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      '删除此隐藏条目。 其更改不应用 。';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      '请解决未合并文件的冲突。Git 没有 stash 的继续或中止命令；原始贮藏会被保留。';

  @override
  String get gitUiStashNameMessage => '堆放名称/信息';

  @override
  String get gitUiStashContentAndResultingIndex => '堆放内容和由此产生的索引';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges => '被跟踪的工作和分阶段的变更';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      '贮藏更改并保留已暂存的更改 (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged => '仅贮藏已暂存的更改 (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => '包含未跟踪的文件';

  @override
  String get gitUiAllEligiblePathsInThisRepository => '此仓库中的所有合格路径';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions => '没有符合条件的这些隐藏选项的更改 。';

  @override
  String get gitUiSelectAtLeastOneEligiblePath => '选择至少一个合格路径 。';

  @override
  String get gitUiCreateStash2 => '创建贮藏';

  @override
  String get gitUiCreateWorktree => '创建工作树...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      '在 HEAD 处创建工作树之前，请先创建提交。';

  @override
  String get gitUiDetachedHEAD => '分离的 HEAD';

  @override
  String get gitUiCurrent => '当前 ·';

  @override
  String get gitUiLocked => '锁定 ·';

  @override
  String get gitUiOpenInBusyStack => '在繁忙的堆叠中打开 ?';

  @override
  String get gitUiStatusNotInspected => '未检查的状况';

  @override
  String get gitUiDirty => '脏';

  @override
  String get gitUiClean => '干净';

  @override
  String get gitUiOpenWorkingFolder => '打开工作文件夹';

  @override
  String get gitUiMoveWorktree => '移动工作树...';

  @override
  String get gitUiUnlock => '解锁';

  @override
  String get gitUiLock => '锁定';

  @override
  String get gitUiRemoveCleanWorktree => '删除干净的工作树...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges => '审查删除,包括本地更改...';

  @override
  String get gitUiNewWorktreeFolderName => '新建工作树文件夹名称';

  @override
  String get gitUiNewWorktreeBranch => '新建工作树分支';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '在 $arg2（$arg3）创建本地分支，并创建 $arg0/$arg1。';
  }

  @override
  String get gitUiDestinationFolderName => '目标文件夹名称';

  @override
  String get gitUiRemoveWorktree => '移除工作树?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      '明确丢弃此工作树中所有本地跟踪/未跟踪的更改。 锁定/ 使用的工作树仍受到保护 。';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git拒绝删除本地更改、未跟踪的文件或锁定 。';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove => '丢弃本地工作树内容并删除';

  @override
  String get gitUiRemoveCleanWorktree2 => '删除清洁工作树';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      '明确循环到嵌入的子模块中进行更新/同步';

  @override
  String get gitUiNoRecordedSubmodules => '没有记录子模块';

  @override
  String get gitUiNotInitialized => '未初始化';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return '父母 gitlink: $arg0 检查完毕: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => '肮脏的嵌套仓库';

  @override
  String get gitUiCleanNestedRepository => '清洁嵌套仓库';

  @override
  String get gitUiNestedStatusUnavailable => '无嵌套状态';

  @override
  String get gitUiEnterNestedRepository => '输入嵌套仓库';

  @override
  String get gitUiInitializeConfiguration => '初始化配置';

  @override
  String get gitUiUpdateToParentSRecordedCommit => '更新父权承诺...';

  @override
  String get gitUiFollowConfiguredRemoteBranch => '跟随已配置的远程分支...';

  @override
  String get gitUiSynchronizeConfiguredURLs => '同步配置的 URL...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent => '父体中当前子模块指针的阶段';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      '父母和子模块承诺、 推动和肮脏状态保持分离 。 浏览不初始化或更新它们 。';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return '获取并检查已配置的远程分支的承诺。 这与父行所记录的 gitlink 不同 。 递归: $arg0 。';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return '根据需要初始化并检查准确的$arg0。递归:$arg1。';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return '应用已审查的子模块配置操作。 递归: $arg0 。';
  }

  @override
  String get gitUiApplySubmoduleOperation => '应用子模块操作';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      '检查已记录的修订版或创建回收分支。 Reflog 并不恢复任意的未保存或未跟踪的内容 。';

  @override
  String get gitUiSelectAReflogEntry => '选择重写条目';

  @override
  String get gitUiPreviousPage => '上一页';

  @override
  String get gitUiNextPage => '下一页';

  @override
  String get gitUiRecoveryBranchName => '回收分支名称';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return '创建分支于$arg0;工作文件和当前分支保持不变。';
  }

  @override
  String get gitUiCreateRecoveryBranch => '创建回收分支...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => '只读恢复快照';

  @override
  String get gitUiInspectSnapshot => '检查快照...';

  @override
  String get gitUiReviewReset => '审阅重置…';

  @override
  String gitUiPageArg0(String arg0) {
    return '第 $arg0 页';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Git 文本历史必须拥有可编辑的字段 。';

  @override
  String get gitUiEditHEADIndexWorkingTree => '编辑 HEAD | 暂存区 | 工作区…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      '经审查的索引或工作内容已改变。 在开始之前刷新此比较 。';

  @override
  String get gitUiRefreshComparison => '刷新比较';

  @override
  String get gitUiPreviousChangedFile => '上一个已更改的文件';

  @override
  String get gitUiNextChangedFile => '下一个更改的文件';

  @override
  String get gitUiPreviousDifference => '上一个差数';

  @override
  String get gitUiNextDifference => '下一个差数';

  @override
  String get gitUiComparisonMode => '比较模式';

  @override
  String get gitUiSideBySide => '并肩作战';

  @override
  String get gitUiUnified => '统一';

  @override
  String get gitUiDiffDisplayOptions => 'Diff 显示选项';

  @override
  String get gitUiWrap => '环绕';

  @override
  String get gitUiWords => '单词';

  @override
  String get gitUiCollapseContext => '折叠上下文';

  @override
  String get gitUiIgnoreWhitespace => '忽略空白';

  @override
  String get gitUiSearchComparison => '搜索比较';

  @override
  String get gitUiSearch => '搜索';

  @override
  String get gitUiCloseSearch => '关闭搜索';

  @override
  String get gitUiStagingActions => '暂存操作';

  @override
  String get gitUiStagingActions2 => '暂存操作…';

  @override
  String get gitUiUnstageSelectedChangedLines => '取消暂存所选更改行';

  @override
  String get gitUiStageSelectedChangedLines => '暂存所选更改行';

  @override
  String get gitUiUnstageWholeFile => '取消暂存整个文件';

  @override
  String get gitUiStageWholeFile => '暂存整个文件';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 只用空格修改的行隐藏 □ 显示精确的更改';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '已选择 $arg0 个更改行 · 显示设置不会改变暂存内容的字节。';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      '只读比较 · 复制文本或调整显示设置。';

  @override
  String get gitUiNoFinalNewline => ' · 没有最终的新线';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 ° $arg1 ° $arg2 字节 $arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents => '这些内容没有文本比较 。';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      '此比较超过了约束文本审查的限制。 内容未被宣布为完全相同 。';

  @override
  String get gitUiTheComparedContentsAreIdentical => '比较的内容相同 。';

  @override
  String get gitUiUnstage => '卸载';

  @override
  String get gitUiStage => '阶段';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 更改了线条';
  }

  @override
  String get gitUiContext => 'A. 背景情况';

  @override
  String get gitUiExpandUnchangedContext => '扩展无变化的上下文';

  @override
  String get gitUiUnstageThisHunk => '取消暂存此区块';

  @override
  String get gitUiStageThisHunk => '暂存此区块';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return '编辑阶段性内容 · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult => '写入已审查的索引结果';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => '暂存区';

  @override
  String get gitUiWorkingTree => '工作区';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => '可编辑的索引 □ UTF-8 blob';

  @override
  String get gitUiUndo => '撤销';

  @override
  String get gitUiRedo => '重做';

  @override
  String get gitUiReloadIndexReview => '重新装入索引审查吗 ?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      '重新加载当前 HEAD、暂存区和工作版本。这会替换暂存区编辑器中未保存的草稿。';

  @override
  String get gitUiReplaceDraftAndReload => '替换草稿和重新装入';

  @override
  String get gitUiReloadVersions => '重新装入版本...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry => '将编辑的结果写入此索引条目';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      '工作文件仍保留在磁盘上。 在应用前先审查编辑后的索引 。';

  @override
  String get gitUiReviewIndexTextFormatChanges => '审查索引文本格式更改';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return '仅更新已审阅的 $arg0 索引条目。\n\n$arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => '写入已审查的索引结果';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      '经编辑的结果在格式审查中更改。 重审一次 。';

  @override
  String get gitUiSynchronizeScrolling => '同步滚动';

  @override
  String get gitUiReadOnlyRevisionContent => '只读版本内容';

  @override
  String get gitUiEditableIndexContent => '可编辑索引内容';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      '请求的修订版在当前过滤器之外。 重置过滤器以显示它 。';

  @override
  String get gitUiFilterLog => '过滤日志';

  @override
  String get gitUiFilters => '过滤器...';

  @override
  String gitUiFiltersCount(String count) {
    return '过滤器 ($count)...';
  }

  @override
  String get gitUiMessage => '说明…';

  @override
  String get gitUiAuthor => '作者…';

  @override
  String get gitUiPath => '路径...';

  @override
  String get gitUiDate => '约会...';

  @override
  String get gitUiMessageFilter => '信件过滤器';

  @override
  String get gitUiAuthorFilter => '作者过滤器';

  @override
  String get gitUiPathFilter => '路径过滤器';

  @override
  String get gitUiMessage2 => '说明';

  @override
  String get gitUiAuthor2 => '作者';

  @override
  String get gitUiPath2 => '路径';

  @override
  String get gitUiDateFilter => '日期过滤器...';

  @override
  String get gitUiResetFilters => '重置过滤器';

  @override
  String get gitUiRefreshLog => '刷新日志';

  @override
  String get gitUiGoToCommitReference => '转到承诺/ 引用...';

  @override
  String get gitUiBackToHEAD => '返回 HEAD';

  @override
  String get gitUiOrderedCherryPick => '按指定顺序拣选';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return '审视樱桃选择($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions => '比较两个选中的修改...';

  @override
  String get gitUiToggleBranchesPane => '切换树枝窗格';

  @override
  String get gitUiFilterBranchesAndTags => '过滤分支和标记';

  @override
  String gitUiCommitArg0(String arg0) {
    return '提交$arg0';
  }

  @override
  String get gitUiCommitDetails => '提交细节...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return '参考: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => '选择此提交';

  @override
  String get gitUiBranchOrTag => '分支或标签';

  @override
  String get gitUiAllReferences => '全部引用';

  @override
  String get gitUiLocal => '当地';

  @override
  String get gitUiRemote => '远程';

  @override
  String get gitUiTags => '标签';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters => '没有承诺匹配当前过滤器 。';

  @override
  String get gitUiObjectID => '对象编号';

  @override
  String get gitUiSubjectReferences => '主题/参考文献';

  @override
  String get gitUiDate2 => '日期';

  @override
  String get gitUiGitCommits => 'Git 提交';

  @override
  String get gitUiParents => '父提交';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0父母';
  }

  @override
  String get gitUiLoadMoreCommits => '装入更多承诺';

  @override
  String get gitUiLoadingChangedFiles => '正在装入已更改的文件';

  @override
  String get gitUiNoChangedFiles => '没有更改文件';

  @override
  String get gitUiSelectACommit => '选择一项承诺';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return '比较父母 $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => '更改的文件';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '作者: $arg0 < $arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '提交者:$arg0 < $arg1 > $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      '浅色/ 部分边界: 父对象不可用 。';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      '父权在此页面外, 或浅边界外 。';

  @override
  String gitUiParentArg0(String arg0) {
    return '父提交 $arg0';
  }

  @override
  String get gitUiCommitActions => '提交动作...';

  @override
  String get gitUiEmptyTree => '空树';

  @override
  String get gitUiCreateBranch2 => '创建分支';

  @override
  String get gitUiCreateTag => '创建标签';

  @override
  String get gitUiCompareRevisions => '比较修改';

  @override
  String get gitUiOpenSnapshot => '打开快照';

  @override
  String get gitUiRevertCommit => '还原承诺';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary => '在此边界之后交互式重标';

  @override
  String get gitUiResetCurrentBranch => '重置当前分支';

  @override
  String get gitUiCopyFullObjectID => '复制完整的对象 ID';

  @override
  String get gitUiGoToCommitReference2 => '进行/ 引用';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      '输入要在日志中显示的承付 ID 或引用 。';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable => '请求的修订无法使用 。';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      '仓库元数据只读。 部门检查和比较仍然可用 。';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      '工作文件不可用或只读。 部门切换和合并不可用 。';

  @override
  String get gitUiSearchBranchesAndTags => '搜索分支和标签';

  @override
  String get gitUiNewBranch => '新建分支…';

  @override
  String get gitUiLocalBranches => '本地分支';

  @override
  String get gitUiRemoteBranches => '远程分支';

  @override
  String gitUiTracksArg0(String arg0) {
    return '音轨  $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return '在$arg0检查过';
  }

  @override
  String get gitUiRefreshingBranchMetadata => '正在刷新分支元数据';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return '切换到 $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => '开放已占用的工作树';

  @override
  String get gitUiCreateLocalTrackingBranch => '创建本地跟踪分支...';

  @override
  String get gitUiCompareToCurrentHEAD => '与当前 HEAD 比较';

  @override
  String get gitUiMergeIntoCurrentBranch => '合并为当前分支...';

  @override
  String get gitUiRename => '重命名...';

  @override
  String get gitUiChangeUpstream => '向上移动...';

  @override
  String get gitUiDelete => '删除...';

  @override
  String get gitUiDeleteFromRemote => '从远程删除...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return '$arg0的行动';
  }

  @override
  String get gitUiLocalBranchName => '本地分支名称';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return '创建于 $arg0。 新分支将被检查 。';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return '当地分行将追踪$arg0号,并检查完毕。';
  }

  @override
  String get gitUiChooseRemoteForDeletion => '选择要删除的远程';

  @override
  String get gitUiDeleteRemoteReference => '删除远程引用';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '合并号$arg0至$arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return '重命名 $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return '上游$arg0';
  }

  @override
  String get gitUiNoUpstream => '无上游分支';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '删除$arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0\n目标 $arg1\n仅删除本地分支。未合并的分支会被拒绝删除。';
  }

  @override
  String get gitUiDelete2 => '删除';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return '删除未合并的分支 $arg0 ?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git 报告该分支没有完全合并。 在审查它的承诺后, 明确删除本地引用; 远程副本不变 。';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => '删除未合并的本地分支';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return '目的地: $arg0 ° $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => '源分支或标记';

  @override
  String get gitUiMergePolicy => '合并政策';

  @override
  String get gitUiFastForwardWhenPossible => '可能时快速前进';

  @override
  String get gitUiAlwaysCreateAMergeCommit => '总是创建合并承诺';

  @override
  String get gitUiFastForwardOnly => '仅快速前进';

  @override
  String get gitUiSquashIntoStagedChanges => '静态到分阶段的更改';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit => '创建合并前停止';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      '已禁用快进，以防 HEAD 在审阅之前移动。';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      '用于单项承诺的请假已逐步更改;这不是持续合并。';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      '在共同的解决方案工作空间中仍然存在冲突。';

  @override
  String get gitUiAddRemote => '添加远程...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return '获取: $arg0 推: $arg1';
  }

  @override
  String get gitUiRemoveRemote => '删除远程...';

  @override
  String get gitUiChangeFetchURL => '更改获取 URL...';

  @override
  String get gitUiAddPushDestination => '添加推进目标...';

  @override
  String get gitUiRemovePushDestination => '删除推进目标...';

  @override
  String gitUiManageArg0(String arg0) {
    return '管理 $arg0';
  }

  @override
  String get gitUiRemoteName => '远程名称';

  @override
  String get gitUiNewRemoteName => '新建远程名称';

  @override
  String get gitUiRepositoryURLOrLocalSource => '仓库 URL 或本地来源';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove => '输入要删除的确切审查对象 。';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      '证书由配置的助手或私人提示提供 。';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '移除远程 $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      '删除本地远程配置和跟踪引用。 它不删除服务器仓库 。';

  @override
  String get gitUiRemoveRemote2 => '删除远程';

  @override
  String get gitUiCommitScopeEntireRepository => '提交范围: 整个仓库';

  @override
  String get gitUiCachedTracking => '缓存跟踪';

  @override
  String get gitUiAmendLastCommit => '修改上次提交';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected => '配置钩和签名受到尊重。';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      '重写选中的 HEAD 提交。远程跟踪信息无法证明它尚未发布。';

  @override
  String get gitUiRepository => '仓库';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '已破旧的 $arg0';
  }

  @override
  String get gitUiLog => '日志';

  @override
  String get gitUiRepositoryActions => '仓库操作';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return '缓存的跟踪信息 · $upstream · 领先 $ahead · 落后 $behind';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      '无工作树。打开日志检查其历史 。';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      '无法进行只读存储器 / 中继和承付 。';

  @override
  String get gitUiRepositoryStatusUnavailable => '没有仓库状态';

  @override
  String gitUiAmendRevision(String revision) {
    return '修正 $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => '添加签署确认尾注';

  @override
  String get gitUiUseConfiguredSigningPolicy => '使用已配置的签名策略';

  @override
  String get gitUiCryptographicallySignThisCommit => '加密签名此项';

  @override
  String get gitUiDoNotSignThisCommit => '不签署此承诺';

  @override
  String get gitUiRecentCommitMessages => '最近发送的信件...';

  @override
  String get gitUiUseConfiguredCommitTemplate => '使用已配置的提交模板...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks => '作者身份和配置的钩子...';

  @override
  String get gitUiDraftMessage => '信件草稿...';

  @override
  String get gitUiCommitOptions => '提交选项';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return '草稿保留在内存中，但保存失败。$arg0';
  }

  @override
  String get gitUiCommitMessage => '提交说明';

  @override
  String get gitUiGitOperationInProgress => '正在运行中';

  @override
  String get gitUiCancel => '取消';

  @override
  String get gitUiAmendStaged => '修订阶段';

  @override
  String gitUiCommitStagedCount(String count) {
    return '提交已暂存的更改（$count）';
  }

  @override
  String get gitUiCommitAndPush => '提交并推送…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured => '没有配置可读化的承诺模板 。';

  @override
  String get gitUiCommitIdentityAndHooks => '提交身份和钩子';

  @override
  String get gitUiRecentMessages => '最近的消息';

  @override
  String get gitUiReplaceMessageDraft => '替换信件草稿吗 ?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      '用选中的信件替换现有承诺信件吗 ?';

  @override
  String get gitUiReplaceDraft => '替换草稿';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return '本地提交 $arg0 已存在。';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return '本地承诺 $arg0 存在。 在尝试再次承诺前先查看日志。 信件草稿已被保留 。';
  }

  @override
  String get gitUiCommitAuthorName => '提交作者名称';

  @override
  String get gitUiCommitAuthorEmail => '提交作者电子邮件';

  @override
  String get gitUiConfiguredDefault => '已配置默认';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return '签署日期:$arg0 和 $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return '配置钩: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      '签署确认尾注是提交说明中的声明，与密码学签名不同。身份信息仅保存到此仓库的本地配置中；草稿会被保留。';

  @override
  String get gitUiSaveRepositoryIdentity => '保存仓库身份';

  @override
  String get gitUiStaged => '已暂存';

  @override
  String get gitUiUntracked => '未跟踪';

  @override
  String get gitUiUnstaged => '未暂存';

  @override
  String get gitUiConflicts => '冲突';

  @override
  String get gitUiNoChanges => '没有更改';

  @override
  String get gitUiRepositoryChangeTree => '仓库更改树';

  @override
  String get gitUiChanges => '更改';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => '展开';

  @override
  String get gitUiCollapse => '折叠';

  @override
  String get gitUiUnstageFile => '取消暂存文件';

  @override
  String get gitUiStageFile => '暂存文件';

  @override
  String get gitUiExpandGroup => '展开组';

  @override
  String get gitUiCollapseGroup => '折叠组';

  @override
  String get gitUiReviewDifference => '审查差异';

  @override
  String get gitUiUnstageSelectedFiles => '取消暂存所选文件';

  @override
  String get gitUiStageSelectedFiles => '暂存所选文件';

  @override
  String get gitUiFileHistoryAndBlame => '文件历史和责备...';

  @override
  String get gitUiDeleteUntrackedFile => '删除未跟踪的文件...';

  @override
  String get gitUiDiscardUnstagedChange => '丢弃未显示的更改...';

  @override
  String get gitUiFileHistory => '文件历史';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '丢弃未显示的 $arg0?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 字节 · $arg1\n使用索引内容替换工作文件，或删除此未跟踪文件。暂存内容保持不变。必须先检查应用中未保存的文档。';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => '删除未跟踪的文件';

  @override
  String get gitUiDiscardWorkingChange => '丢弃工作变更';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return '删除REMOTE参考文献 $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      '这将删除下面列出的每个实际推进目标的引用。 保留本地分支/ 标签。 本次审查将固定预期提示 。';

  @override
  String get gitUiReferenceDoesNotExist => '不存在引用';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0\n预期顶端：$arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => '远程删除完成 。';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '从遥控器中删除$arg0?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      '上面显示的确切目标提示将被删除。 任何已更改的远程提示都会停止操作, 以便再次审查 。';

  @override
  String get gitUiReviewAndDeleteFromRemote => '从远程审查并删除...';

  @override
  String get gitUiDestinationReference => '目标参考';

  @override
  String get gitUiReviewDestinations => '审查目的地';

  @override
  String get gitUiNewRemoteBranch => '新建远程分支';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · 预期：$arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      '目的地已承诺本地无法使用 。 在检查即将离开的历史前先获取已审查的目的地 。';

  @override
  String get gitUiFetchReviewedDestination => '获取已审查的目标';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      '选择目的地并审查即将退出的承诺 。';

  @override
  String get gitUiNoOutgoingCommits => '没有退出承诺';

  @override
  String get gitUiSelectAnOutgoingCommit => '选择一个即将退出的承诺';

  @override
  String get gitUiLoadMoreOutgoingCommits => '装入更多已发送承诺';

  @override
  String get gitUiSetThisDestinationAsUpstream => '将此目的地设为上游';

  @override
  String get gitUiChooseExactTagsToPublish => '选择要发布的确切标签';

  @override
  String get gitUiTagsNone => '标记:无';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return '标记: 选中 $arg0';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return '准确发布: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      '推进完成。 本地承诺仍然在日志中 。';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      '强制推送要求目标引用的顶端与本次审查显示的值完全一致。';

  @override
  String get gitUiForceWithReviewedLease => '强制使用经审核的租赁...';

  @override
  String get gitUiPush => '推送';

  @override
  String get gitUiForcePushWithReviewedLeases => '强制推进经过审查的租赁?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return '只有当每个遥远的目的地仍然拥有上面显示的确切提示时,才重写 $arg0 。\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      '其他人可能已经在使用这些历史。后台获取不会更新本次租约保护条件。';

  @override
  String get gitUiForceWithLease => '租赁';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      '远程结果不确定。 在再次推动之前再次审查目的地 。';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return '父 $arg0 $arg1';
  }

  @override
  String get gitUiRemoteToFetch => '远程获取';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches => 'Prune 删除远程跟踪分支';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      '在不替换工作文件的情况下获取远程跟踪信息更新 。';

  @override
  String get gitUiFetch => '获取';

  @override
  String get gitUiSourceRemote => '来源远程';

  @override
  String get gitUiSourceBranch => '源代码分支';

  @override
  String get gitUiReviewedStrategy => '审查的战略';

  @override
  String get gitUiMerge => '合并';

  @override
  String get gitUiRebase => '变基';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      '如果目的地不能快速前进, 则停止; 永远不要合并或重置 。';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      '与合并承诺合并,包括当有可能快速前进时。';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible => '合并; 允许在可能情况下快速前进 。';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      '重设本地历史, 保留本地合并承诺 。';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory => '重设本地承诺为线性历史 。';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git 被配置为交互式重置。 在此选择明确的拉动策略, 或者获取并打开 Rebase... 来审查一个计划 。';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull => '使用经过审查的普通重标进行此拉';

  @override
  String get gitUiOptions => '选项';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward => '总是创建合并承诺( 不快速前进)';

  @override
  String get gitUiPreserveLocalMergeCommits => '保存本地合并承诺';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      '本地更改可能阻止拉动。 检查/ 承诺它们或明确创建隐藏 。';

  @override
  String get gitUiStashes => '贮藏';

  @override
  String get gitUiCreateOrReviewStash => '创建或审查隐藏...';

  @override
  String get gitUiPullWithSelectedStrategy => '以选定的策略拉动';

  @override
  String get gitUiRepositoryURLOrLocalGitSource => '仓库 URL 或本地 Git 源';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS、 SSH 或本地路径';

  @override
  String get gitUiFolderToInitialize => '初始化文件夹';

  @override
  String get gitUiFinalCloneDestination => '最终克隆目标';

  @override
  String get gitUiChoose => '选择...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      '仅创建 Git 元数据。 现有文件没有进行编程或承诺 。';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      '最终目标必须不存在或为空。绝不会覆盖已有的用户数据。';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      '· 空白使用有效的 Git 政策';

  @override
  String get gitUiSelectedBranchOptional => '选定分支 □ 可选';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      '循环明确初始化/更新子模块';

  @override
  String get gitUiPreparingGitOperation => '准备 Git 操作...';

  @override
  String get gitUiThisAttemptCreated => '这种尝试创造了';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt => '在这次尝试之前,目的地已经存在:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      '目录还在检查中,在再次复制之前再检查一下';

  @override
  String get gitUiNoDestinationDirectoryRemains => '没有目标目录 。';

  @override
  String get gitUiCancelProcess => '取消进程';

  @override
  String get gitUiInitialize => '初始化';

  @override
  String get gitUiClone => '克隆';

  @override
  String get gitUiChooseNewBase => '选择新基底';

  @override
  String get gitUiChooseUpstreamBoundary => '选择上游边界';

  @override
  String get gitUiNewBase => '新基底';

  @override
  String get gitUiUpstreamBoundaryExcluded => '上游边界 · 不包含';

  @override
  String get gitUiSameAsUpstreamBoundary => '与上游边界相同';

  @override
  String get gitUiChooseBranchTagOrCommit => '选择分支、标签或提交…';

  @override
  String get gitUiUseUpstreamAsNewBase => '将上游用作新的基地';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      '从日志中选择一个有效的分支、标记或承诺 。';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      '分支块中第一个保留的提交不能设为 squash 或 fixup，因为它前面没有可合并的目标提交。';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return '分队区块 $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage => '[改写后将要求发出新电\n';

  @override
  String get gitUiPlannedCommitMessages => '计划承诺信息';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      '原始/ 合并信件预览';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return '结果$arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return '当前分支: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => '分离的 HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      '变基会重写提交的标识。远程跟踪信息无法证明这些历史从未被发布。';

  @override
  String get gitUiIncludeRootCommits => '包含根提交';

  @override
  String get gitUiMergeCommits => '合并承诺';

  @override
  String get gitUiFlattenHistory => '线性化历史';

  @override
  String get gitUiPreserveBranchStructure => '保留分支结构';

  @override
  String get gitUiAutosquash => '自动压缩合并';

  @override
  String get gitUiPrepareGitPlan => '准备 Git 计划';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return '将重新应用的提交：$count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      '包括从此分支可以达到的所有 root 。';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return '将把 $boundary 之后的提交重放到 $base 上；不包含边界提交本身。';
  }

  @override
  String get gitUiRoot => '根数';

  @override
  String get gitUiGitBranchLabelResetMergeStructure => 'Git 分支/ 标签/ 重置/ 合并结构';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      '选择明确的旧边界或根模式, 然后制定计划 。';

  @override
  String get gitUiMoveUp => '上移';

  @override
  String get gitUiMoveDown => '下移';

  @override
  String get gitUiResetPlan => '重置计划';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · 分支区块 $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles => '选择详细信息的承诺和已更改的文件';

  @override
  String get gitUiPreviewCombinedCommitMessages => '预览合并信件...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt/  移动选中的承诺。 无关的分支引用不会自动更新 。';

  @override
  String get gitUiCancelPlan => '取消计划';

  @override
  String get gitUiStartReviewedRebase => '开始已审阅的变基？';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return '计划于$arg1年重写$arg0,被放弃的承诺在开始之前仍明显可见。';
  }

  @override
  String get gitUiStartRebase => '开始变基';

  @override
  String get gitUiNoContinuingGitOperation => '没有持续 Git 操作';

  @override
  String get gitUiStoppedForEditingAmend => ' · 停止编辑/修正';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      '这些是未合并的索引条目, 可能来自隐藏应用程序。 Git 没有隐藏继续或中止命令 。';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      '编辑工作文件, 阶段和修正当前承诺, 然后继续重标 。';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · 未合并的暂存阶段 $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries => '该索引没有未解决的条目 。';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit => '将当前承诺保留为空承诺';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      '真实索引没有分阶段的更改。 创建一个明确的空承诺, 如果仍然活跃, 则继续排序 。';

  @override
  String get gitUiKeepEmptyCommit => '保持空承诺...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git 会尝试回到操作开始时的状态，但无法保证恢复操作前已有的未暂存、未跟踪或未保存内容。';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      '跳过当前承诺, 继续下一个计划的承诺 。';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      '忘记此操作的簿记, 同时保留当前文件和索引 。';

  @override
  String gitUiContinueArg0(String arg0) {
    return '继续$arg0';
  }

  @override
  String get gitUiReloadConflictVersions => '重新装入冲突版本 ?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      '将未保存结果草稿替换为当前工作文件。 保存的工作内容将予保留 。';

  @override
  String get gitUiLoadingConflictVersions => '正在装入冲突版本...';

  @override
  String get gitUiLoadingConflict => '正在装入冲突';

  @override
  String get gitUiBaseLeft => '基地 左转';

  @override
  String get gitUiBaseRight => '基数  右';

  @override
  String get gitUiNoBaseEntryForThisConflict => '此冲突无基条目';

  @override
  String get gitUiAcceptEntireLeftFile => '接受整个左侧文件...';

  @override
  String get gitUiAcceptEntireRightFile => '接受右侧整个文件…';

  @override
  String get gitUiPreviousConflictRegion => '先前的冲突地区';

  @override
  String get gitUiNextConflictRegion => '下一个冲突地区';

  @override
  String get gitUiManualResolution => '人工解析';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '地区 $arg0/$arg1 X XX $arg2 检查';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      '源对齐超过了文本比较限制;源板仍然可供手工审查。';

  @override
  String get gitUiAcceptLeftRegion => '接受左区域';

  @override
  String get gitUiAcceptRightRegion => '接受正确的区域';

  @override
  String get gitUiKeepManualResultForRegion => '保持区域手工结果';

  @override
  String get gitUiApplyGitSNonConflictingChanges => '应用 Git 的非冲突性变化吗 ?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      '将当前结果草稿替换为 Git 合并预览。 此丢弃未保存的手动结果编辑; 工作文件在保存前保持不变 。';

  @override
  String get gitUiUseMergePreview => '使用合并预览';

  @override
  String get gitUiApplyNonConflictingChanges => '应用非冲突更改...';

  @override
  String get gitUiLeftSource => '左侧来源';

  @override
  String get gitUiResult => '结果';

  @override
  String get gitUiRightSource => '正确来源';

  @override
  String get gitUiStage2 => '第2阶段';

  @override
  String get gitUiStage3 => '第3阶段';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      '没有冲突版本。 刷新以审查当前状态 。';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      '结果已保存到磁盘。 索引仍然决定此文件是否已经解决 。';

  @override
  String get gitUiSaveResultDraft => '保存结果草稿';

  @override
  String get gitUiApplyResultAndStageResolution => '应用结果并暂存解决方案';

  @override
  String get gitUiResultEditableUTF8WorkingContent => '· 可编辑的 UTF-8 工作内容';

  @override
  String get gitUiEditableConflictResult => '可编辑的冲突结果';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '左侧：$arg0 · $arg1\n右侧：$arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      '选择内容、 删除或子模块明确承诺。 没有二进制数据被解码为可编辑文本 。';

  @override
  String get gitUiUseEntireLeftContent => '使用全部左侧内容...';

  @override
  String get gitUiUseEntireRightContent => '使用右侧全部内容…';

  @override
  String get gitUiDeleteThisPath => '删除此路径...';

  @override
  String get gitUiResolvedSubmoduleCommit => '已解析子模块承诺';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      '在父体中弹出精确的 gitlink 。 这不会检查或执行子模块 。';

  @override
  String get gitUiSetResolvedGitlink => '设定解析 gitlink...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return '基底   $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      '结果是经过编辑的。 保留手动结果或选择其它未变区域 。';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '应用“$arg0”解决方案？';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      '阶段 所选 gitlink 承诺在母体中。 子模块检查及其文件不被替换 。';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return '替换整个工作路径 $arg0, 并分阶段作出决定。 当前的工作内容和任何未保存的结果草稿将被丢弃 。';
  }

  @override
  String get gitUiApplyEntireFileDecision => '应用整个文件决定';

  @override
  String get gitUiStageThisConflictResolution => '分阶段解决冲突?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return '使用整个编辑结果为 $arg0。 Git 记录了预设时的解析路径。 首先审查所有预定内容 $arg1';
  }

  @override
  String get gitUiApplyAndStage => '应用并暂存';

  @override
  String get gitUiReviewResultTextFormatChanges => '审查结果文本格式更改';

  @override
  String get gitUiSaveReviewedResult => '保存已审查的结果';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      '无法访问本地的 Git 表格。 在重新连接应用程序后重试 。';

  @override
  String get gitUiSans => '孙子';

  @override
  String get gitUiSelect => '选择';

  @override
  String get gitUiContextMenu => '上下文菜单';

  @override
  String get gitUiCopyText => '复制文本';

  @override
  String get gitUiLoadingRow => '正在装入行';

  @override
  String get gitUiRetry => '重试';

  @override
  String get gitUiGitMessage => 'Git 消息 :';

  @override
  String get gitUiCancelPrompt => '取消提示';

  @override
  String get gitUiUseMessageAndContinue => '使用信件并继续';

  @override
  String get gitUiRespondPrivately => '私人答复';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return '无法保存首选项: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return '提交存储草稿: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return '视图偏好无法读取: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return '提交草稿保留在记忆中,但无法保存: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      '经审查的仓库仅用于此操作,历史和内容检查仍然可用。';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git 返回 $arg0。 应用程序无法刷新其文档 :\\\\ $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => '在日志中选择提交…';

  @override
  String get gitUiCurrentBranch => '当前分支';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      '没有匹配的分支或标记。 在日志中选择一个承诺 。';

  @override
  String get gitUiBranches => '分支';

  @override
  String get gitUiPushCommits => '推送提交';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return '拉进 $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return '解决 $arg0';
  }

  @override
  String get gitUiCurrentOperation => '当前业务';

  @override
  String get gitUiRebaseCommits => '变基提交';

  @override
  String get gitUiFetch2 => '获取…';

  @override
  String get gitUiPull => '拉取…';

  @override
  String get gitUiPush2 => '推送…';

  @override
  String get gitUiBranches2 => '分支…';

  @override
  String get gitUiManageRemotes => '管理远程仓库…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return '合并到$arg0...';
  }

  @override
  String get gitUiRebase2 => '变基…';

  @override
  String get gitUiConflictsAndCurrentOperation => '冲突与当前操作...';

  @override
  String get gitUiStashes2 => '贮藏…';

  @override
  String get gitUiWorktrees => '工作树…';

  @override
  String get gitUiSubmodules => '子模块…';

  @override
  String get gitUiReflogAndRecovery => '引用日志与恢复…';

  @override
  String get gitUiCloneRepository => '克隆仓库…';

  @override
  String get gitUiRevokeRepositoryTrust => '撤销对此仓库的信任';

  @override
  String get gitUiWaitingForRepositoryStatus => '正在等待仓库状态';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh => '没有仓库状态; 刷新';

  @override
  String get gitUiManageRemotes2 => '管理远程仓库';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return '合并为$arg0';
  }

  @override
  String get gitUiWorktrees2 => '工作树';

  @override
  String get gitUiSubmodules2 => '子模块';

  @override
  String get gitUiReflogAndRecovery2 => '引用日志与恢复';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return '克隆库 · $arg0';
  }

  @override
  String get gitUiApply => '应用';

  @override
  String get gitUiResizeGitPanes => '调整 Git 窗帘大小';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0%';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return '退出状态:$status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      '仓库已更改。 重新刷新和审查后再尝试 。';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      '另一个操作持有仓库或索引锁定。 等等, 然后刷新 。';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation => '本次操作需要仓库信任 。';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Git 服务断开。 重新连接并调节仓库 。';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      '已安装的 Git 可执行文件无法支持此操作。 请在下面审查运行时间要求 。';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      '此仓库仅用于请求的操作。 仍然可用 。';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      '操作需要调节。 在重复之前先审查生成的仓库或远程状态 。';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git 认证失败。 审查证书助手或解锁配置的密钥环 。';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH 主机验证失败。 通过您配置的 SSH 工具审查主机身份 。';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      '提交签名失败或已取消。 请审查签名密钥、 代理和配置的签名工具 。';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      '设置仓库作者名称和电子邮件, 然后返回到保存的信件草稿 。';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git 拒绝了已审查的更新。 刷新并审查实际目的地, 然后再尝试 。';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      '工作或分阶段的修改阻止了这一操作。 审查、 承诺或明确隐藏这些操作 。';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      '所需的 Git 对象不可用。 检查浅处或部分仓库的边界, 必要时可以明确获取 。';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git 操作失败: $arg0';
  }

  @override
  String get gitUiDiagnostics => '诊断';

  @override
  String get gitUiAuthorizeGitInspection => '授权 Git 检查...';

  @override
  String get gitUiCopyDiagnostics => '复制诊断';

  @override
  String get gitUiActions => '操作';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return '分公司,$arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut => '创建本地分支而不检查 。';

  @override
  String gitUiTagArg0(String arg0) {
    return '标记  $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return '仅读快照 · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => '拣选提交';

  @override
  String get gitUiRevertCommits => '还原承诺';

  @override
  String get gitUiCompareToFullRevisionID => '与完整修订版ID比较';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return '树比较方向：$arg0 → 此处输入的修订版本。';
  }

  @override
  String get gitUiEnterAFullValidObjectID => '输入完整有效的对象 ID 。';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 $arg1 树对比';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '重置$arg0至$arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      '移动 HEAD/当前分支。reflog 无法恢复任意未跟踪或未保存的内容。';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles => '移动 HEAD，保留暂存区和工作文件。';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      '移动 HEAD 并替换暂存区，保留工作文件。';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      '替换 HEAD、暂存区和已跟踪的工作文件；可能覆盖妨碍操作的未跟踪文件。';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      '替换 HEAD、暂存区及符合条件的文件；若会丢失本地更改则拒绝操作。';

  @override
  String gitUiResetWithArg0(String arg0) {
    return '重置为$arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '+$arg0  $arg1 在应用前先审查选中模式的效果 。';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '重置 $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return '目标 $arg0';
  }

  @override
  String get gitUiTagName => '标签名称';

  @override
  String get gitUiAnnotatedTag => '附注标签';

  @override
  String get gitUiCryptographicSigning => '密码学签名';

  @override
  String get gitUiConfiguredPolicy => '配置策略';

  @override
  String get gitUiSignThisTag => '签名此标记';

  @override
  String get gitUiDoNotSign => '不要签名';

  @override
  String get gitUiTagMessage => '标记消息';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      '本地创建标记。 在 Push 审评中明确发布选中的标记 。';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return '整棵树: $arg0 $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => '下一个已更改的文件页';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      '只读仓库快照。 打开文件时从未检查此版本 。';

  @override
  String get gitUiOpenReadOnlyVersion => '打开只读版本';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus => '正在等待仓库状态';

  @override
  String get gitUiRestoreThisPath => '恢复这条路径...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return '历史 · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '恢复 $arg0吗?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return '将此工作路径替换为订正版 $arg0。 保留现有分阶段内容。';
  }

  @override
  String get gitUiRestoreWorkingFile => '恢复工作文件';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return '文件历史跟随重命名 □  $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => '逐行追溯 · 已提交内容';

  @override
  String get gitUiBlame => '逐行追溯…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0  工作树';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => '打开只读历史文件';

  @override
  String get gitUiCompareToCurrentFile => '与当前文件比较';

  @override
  String get gitUiCompareToParent => '与父性比较...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return '已提交 $arg0 · 编辑器中未保存的内容不包含在这些注解中';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return '来源于 $arg0 的历史';
  }

  @override
  String get gitUiBoundary => ' · 边界';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\n原始行 $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => '前一行';

  @override
  String get gitUiNextLines => '下一行';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return '明确应用命令 o 目的地 $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => '添加全部任务对象编号';

  @override
  String get gitUiAddReviewedCommit => '添加已审查的承诺...';

  @override
  String get gitUiMoveEarlier => '稍早移动';

  @override
  String get gitUiMoveLater => '稍后移动';

  @override
  String get gitUiRemoveFromReviewedSequence => '从已审查的序列中删除';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits => '应用更改而不创建承诺';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      '使用此明确的主行父母来合并承诺';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      '空的或已经应用的承诺可以阻止Git作出明确的跳过或继续决定。';

  @override
  String get gitUiRevertInReviewedOrder => '按审查顺序还原';

  @override
  String get gitUiCherryPickInReviewedOrder => '樱桃选手按顺序排列';

  @override
  String get gitUiReturnToFiles => '返回到文件';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => '提交';

  @override
  String get gitUiBackToCommit => '返回提交';

  @override
  String get gitUiSelectAChangeToReview => '选择要审查的修改';

  @override
  String get gitUiLoadingBranch => '正在装入分支...';

  @override
  String get gitUiBranchUnavailable => '分机无法使用';

  @override
  String get gitUiUnbornHEAD => '尚无提交的 HEAD';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return '分离的 HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => '继续';

  @override
  String get gitUiPick => '选取';

  @override
  String get gitUiReword => '修改说明';

  @override
  String get gitUiEdit => '编辑';

  @override
  String get gitUiSquash => '压缩合并';

  @override
  String get gitUiFixup => '丢弃说明并合并';

  @override
  String get gitUiDrop => '丢弃';

  @override
  String get gitUiAbort => '中止';

  @override
  String get gitUiSkip => '跳过';

  @override
  String get gitUiQuit => '退出操作';

  @override
  String get gitUiSoft => '软重置';

  @override
  String get gitUiMixed => '混合重置';

  @override
  String get gitUiHard => '硬重置';

  @override
  String get gitUiKeep => '保留更改';

  @override
  String get gitUiCreate => '创建';

  @override
  String get gitUiApplyStash => '应用贮藏';

  @override
  String get gitUiPopStash => '应用贮藏并在成功时删除';

  @override
  String get gitUiDropStashAction => '删除贮藏';

  @override
  String get gitUiEditedResult => '已编辑结果';

  @override
  String get gitUiLeftContent => '左侧内容';

  @override
  String get gitUiRightContent => '正确内容';

  @override
  String get gitUiDeletePath => '删除路径';

  @override
  String get gitUiSubmoduleCommit => '子模块承诺';

  @override
  String get gitUiPresentContent => '可用内容';

  @override
  String get gitUiAbsentContent => '缺席';

  @override
  String get gitUiBinaryContent => '二进制内容';

  @override
  String get gitUiTooLargeContent => '内容超过显示限制';

  @override
  String get gitUiUnavailableContent => '无内容';

  @override
  String get gitUiGitlinkContent => '子模块指针器';

  @override
  String get gitUiSymlinkContent => '符号链接';

  @override
  String get gitUiNoOperation => '无操作';

  @override
  String get gitUiCherryPickOperation => '拣选提交';

  @override
  String get gitUiRevertOperation => '还原提交';

  @override
  String get gitUiApplyMailboxOperation => '应用补丁';

  @override
  String get gitUiSquashOperation => 'Squash 合并';

  @override
  String get gitUiUnmergedOperation => '未合并索引';

  @override
  String get gitUiWaitingForPromptPhase => '等待你的回应';

  @override
  String get gitUiStoppedPhase => '停止审查';

  @override
  String get gitUiCompletedPhase => '已完成';

  @override
  String get gitUiFailedPhase => '失败';

  @override
  String get gitUiCancelledPhase => '已取消';

  @override
  String get gitUiUncertainPhase => '成果需要调节';

  @override
  String gitUiStageVersion(String stage) {
    return '冲突阶段 $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git 合并预览';

  @override
  String get gitUiNormalizedWorking => '工作树  正常';

  @override
  String gitUiPercentValue(String value) {
    return '$value%';
  }

  @override
  String gitUiOperationActionQuestion(String action, String operation) {
    return '$operation · $action?';
  }

  @override
  String gitUiOperationActionEllipsis(String action) {
    return '$action…';
  }

  @override
  String gitUiRebaseStepSemantics(
    String position,
    String action,
    String subject,
  ) {
    return '$position, $action, $subject';
  }

  @override
  String get gitUiUtf8Bom => 'UTF-8 带有字节顺序标记 (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 无字节顺序标记 (BOM)';

  @override
  String get gitUiAddsBom => '此编辑在文件开头添加 UTF-8 字节顺序标记( BOM ) 。';

  @override
  String get gitUiRemovesBom => '此编辑从文件开头删除 UTF-8 字节顺序标记( BOM ) 。';

  @override
  String get gitUiNoLineTerminators => '没有线条终止器';

  @override
  String gitUiLineEndings(String format) {
    return '$format 换行符';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return '混合线端 ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format □ 无最终的LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return '行结束符格式将从 $before 改为 $after。剪贴板中的文本可能使用与原文件不同的行结束符。';
  }

  @override
  String get gitUiGitFailure => 'Git 操作失败。 请检查下面的诊断 。';

  @override
  String get gitUiAbortInline => '中止';

  @override
  String get gitUiSkipInline => '跳过';

  @override
  String get gitUiQuitInline => '退出';

  @override
  String get gitUiMergeInline => '合并';

  @override
  String get gitUiRebaseInline => '变基';

  @override
  String get gitUiCherryPickInline => '拣选提交';

  @override
  String get gitUiRevertInline => '还原提交';

  @override
  String get gitUiApplyMailboxInline => '应用邮件框';

  @override
  String get gitUiSquashInline => '压缩合并';

  @override
  String get gitUiUnmergedInline => '未合并';

  @override
  String get gitHostFetch => '获取';

  @override
  String get gitHostRefreshGitStatus => '刷新 Git 状态';

  @override
  String get gitHostCommitStaged => '提交阶段';

  @override
  String get gitHostGitBranches => 'Git 分支';

  @override
  String get gitHostReviewPush => '审查推力';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git 操作适用于整个仓库, 并可以执行配置的钩子、 过滤器、 证书和签名工具 。';

  @override
  String get gitHostContentUnavailable => '无内容';

  @override
  String get gitHostInitializeRepository => '初始化存储库';

  @override
  String get gitHostCloneRepository => '克隆仓库';

  @override
  String get gitHostInitializeHere => '在此初始化...';

  @override
  String get gitHostCloneRepository2 => '克隆仓库…';

  @override
  String get gitHostGitLog => 'Git 日志';

  @override
  String get gitUiAbsentPlaceholder => '(缺席)';

  @override
  String get gitUiUnborn => '未出生婴儿';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return '已变基的历史 · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return '当前历史 · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return '正在重放的提交 · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return '传入的内容 · $revision';
  }

  @override
  String get gitUiContentConflict => '内容冲突';

  @override
  String get gitUiSubmoduleConflict => '子模块冲突';

  @override
  String get gitUiSymlinkConflict => '符号链接冲突';

  @override
  String get gitUiAddAddConflict => '双方均加';

  @override
  String get gitUiModifyDeleteConflict => '修改/删除或重新命名/删除';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft => '丢弃未保存的索引草稿？';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      '关闭索引编辑器只会丢弃草稿。索引和工作文件不会更改。';

  @override
  String get gitUiDiscardIndexDraft => '丢弃索引草稿';

  @override
  String get gitUiDiscardUnsavedConflictDraft => '放弃未保存的冲突解决结果？';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      '关闭冲突编辑器只会放弃未保存的结果草稿。已保存的工作内容和索引保持不变。';

  @override
  String get gitUiDiscardConflictDraft => '放弃冲突草稿';

  @override
  String get gitUiOpenCurrentFile => '打开当前文件';

  @override
  String get gitUiPreviousSearchMatch => '上一个搜索结果';

  @override
  String get gitUiNextSearchMatch => '下一个搜索结果';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return '第 $current 个，共 $count 个结果';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return '正在显示前 $count 个结果。请缩小搜索范围以查看更多结果。';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => '不使用筛选器显示修订';

  @override
  String get gitUiRestoreHistoryFilters => '恢复历史筛选器';

  @override
  String get gitUiShowAllAffectedFiles => '显示所有受影响的文件';

  @override
  String get gitUiGraphLanes => '图形轨道';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return '将 $arg0 变基到 $arg1';
  }

  @override
  String get gitUiChangedLine => '已更改的行';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft => '将 HEAD 区域复制到索引草稿';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft => '将工作区区域复制到索引草稿';

  @override
  String get gitUiUpdatingConflictRegions => '正在更新冲突区域';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return '含有冲突标记的结果区域：$count';
  }

  @override
  String get gitUiIgnoreLeftRegion => '忽略左侧建议';

  @override
  String get gitUiIgnoreRightRegion => '忽略右侧建议';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      '已将提交的草稿写入索引。较新的文本仍保留在此编辑器中。应用前请重新加载并检查当前版本。';

  @override
  String get gitUiNewerConflictDraftRetained => '提交的结果已保存。较新的结果草稿仍未保存。';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision => '此路径和修订没有可用的文件历史记录。';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft => '检查已保存的索引并保留草稿';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      '已保存的索引或其源内容已更改。较新的草稿已保留；应用前请单独检查这些更改。';

  @override
  String get gitUiReviewSavedMessage => '檢視已儲存的訊息';

  @override
  String get gitUiSavedMessage => '已儲存的訊息';

  @override
  String get gitUiKeepThisMessage => '保留此訊息';

  @override
  String get gitUiUseSavedMessage => '使用已儲存的訊息';

  @override
  String get gitUiCommitDraftChangedInAnotherWindow =>
      '此訊息已在另一個視窗中變更。請先檢視已儲存的訊息，再進行取代。';

  @override
  String get gitUiDiscardUnsavedCommitMessages => '捨棄未儲存的提交訊息？';

  @override
  String get gitUiMessagesCouldNotBeSavedStayInThisWindow =>
      '無法儲存的訊息仍保留在此視窗中。捨棄這些訊息不會變更已儲存的版本。';

  @override
  String get gitUiDiscardCommitMessages => '捨棄訊息';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get notesNewFromRetainedText => '从保留的文本新建笔记';

  @override
  String get notesAccountThrottled => 'Nextcloud 要求暂停。请等待后再重新登录。';

  @override
  String get notesSettingsRefreshing => '正在按已确认的设置更新笔记';

  @override
  String get notesExportOperationFailed => '导出在发布前失败。请检查来源和目标后重新导出。';

  @override
  String get notesRecoveryCreatedNotOpened =>
      '恢复的笔记已保存，但无法打开。请处理待保存的编辑或属性，再打开这篇已有笔记。';

  @override
  String get notesSettingsPendingNotes =>
      '待处理的笔记、冲突或结果不明的创建阻止了此更改。请在笔记中同步或检查，再重试保留的设置草稿。';

  @override
  String get notesSettingsPendingAttachments =>
      '待处理的附件操作阻止了此更改。请在笔记中检查附件，再重试保留的设置草稿。';

  @override
  String get notesAccountServerAddress =>
      '请使用 Nextcloud 的规范 HTTPS 地址并重新登录。无法验证地址或重定向。';

  @override
  String get notesAccountUnsupported =>
      '笔记不可用或 API 不受支持。请启用 API 主版本为 1、次版本不低于 4 的 Nextcloud Notes。';

  @override
  String get notesAccountAuthorizeAgain => 'Nextcloud 拒绝了凭据。请重新授权或重新连接账户。';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud 拒绝了笔记功能检查。请联系管理员允许此检查后重试。';

  @override
  String get notesAccountMalformed => '无法验证 Nextcloud 的响应。请检查服务器安装并重新登录。';

  @override
  String get notesAccountTimedOut => '登录超时。请重新登录并在浏览器中完成授权。';

  @override
  String get notesAccountBrowserUnavailable => '无法打开系统浏览器。请检查默认浏览器并重新登录。';

  @override
  String get notesAccountNetwork => '无法连接 Nextcloud。请检查网络和服务器后重新登录。';

  @override
  String get notesAccountRejected => 'Nextcloud 拒绝了功能请求。请与管理员确认访问权限后重试。';

  @override
  String get notesAccountFailed => '无法完成账户设置。请重新登录。';

  @override
  String get notesTransferSourceChanged => '来源在审核后已更改。请重新审核当前文件或创建新快照后重试。';

  @override
  String get notesTransferUnreadable => '无法读取来源。请检查文件或文件夹的访问权限，再重新审核。';

  @override
  String get notesTransferInvalidSnapshot =>
      '快照无效或不受支持。请选择有效的 BusyMark Notes 快照或 Markdown 来源。';

  @override
  String get notesTransferMediaLimit => '媒体超出导入大小限制。请缩小受影响项目的媒体，再重新审核。';

  @override
  String get notesTransferUnsafeSource => '来源包含不安全的路径。请选择来源文件夹内的文件并重新审核。';

  @override
  String get notesTransferDestination => '无法写入导出内容。请检查目标的访问权限和可用空间后重新导出。';

  @override
  String get notesTransferOperationFailed => '传输未能完成。请检查受影响的项目并重试。之前导入的项目仍已保存。';

  @override
  String get notesExportPublishedWithOmissions => '导出已发布，但有遗漏';

  @override
  String get notesBatchUnchanged => '请求的值已经设置。';

  @override
  String get notesBatchReadOnly => '此笔记为只读。受保护的属性无法更改，但仍可修改收藏状态。';

  @override
  String get notesBatchReviewChanged => '此笔记在审核后已更改。请审核当前状态后重新执行操作。';

  @override
  String get notesBatchMissing => '此笔记已不可用。请刷新列表并重新检查操作目标。';

  @override
  String get notesBatchStorage => '本地保存失败。请检查存储并重试此项目；成功的项目仍已保存。';

  @override
  String get notesRemoteReviewChanged => '服务器笔记已更改。合并草稿已保留。请审核更新的比较并重新选择解决方式。';

  @override
  String get notesReviewRemote => '我已审核当前服务器版本';

  @override
  String get wsModuleCapsNotPublished => '模块的大小写规则不会发布。';

  @override
  String get wsTitleOverridesAction => '实例与目录标题…';

  @override
  String get wsHeadingNotPublished => '此构建器不会发布此属性。';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      '固定版本构建器不发布 Markdown 主题的实例标题覆盖。保留现有标记，请在源码中查看。';

  @override
  String get wsTopicIdentity => '主题 ID';

  @override
  String get wsElementAnchor => '元素锚点';

  @override
  String get wsHeadingText => '标题文本';

  @override
  String get wsDefaultTitle => '默认标题';

  @override
  String get wsTopicNavigation => '主题导航';

  @override
  String get wsHeadingOptions => '标题属性';

  @override
  String get wsDocumentOptions => '文档设置';

  @override
  String get wsSettingsPresent => '存在已编写设置';

  @override
  String get wsTitleOverrideExplanation => '覆盖发布的标题；标题文本保持不变。';

  @override
  String get wsIgnoreVariables => '将变量视为字面文本';

  @override
  String get wsIgnoreVariablesExplanation => '启用时，不替换类似变量的文本。';

  @override
  String get wsInstanceSelection => '帮助实例';

  @override
  String get wsInstanceExplanation => '通过名称、组、列表、排除项或表达式选择帮助输出。';

  @override
  String get wsFilterExplanation => '按条件筛选可复用内容；这不会选择帮助实例。';

  @override
  String get wsContextHelp => '上下文帮助 ID';

  @override
  String get wsCapitalization => '大小写';

  @override
  String get wsLibraryTopic => '库主题';

  @override
  String get wsLastModified => '最后修改';

  @override
  String get wsMissingTopicHeading => '尚未编写主题 H1。请在源码中添加。';

  @override
  String get wsMultipleTopicHeadings => '第一个 H1 决定主题标题，后续 H1 是独立标题。';

  @override
  String get wsTopicIdentityMismatch => '根 id 与文件名派生的主题 ID 不同。请重命名主题文件或查看源码。';

  @override
  String get wsUnsupportedProperties => '保留不受支持的属性。请在源码中查看。';

  @override
  String get wsGeneratedAnchor => '自动生成的锚点；输入值可覆盖。';

  @override
  String get wsHeadingBuilderLimitation =>
      '固定版本构建器不发布 H1 属性。属性属于标题，而非 XML 根元素。';

  @override
  String get closeOtherTabs => '关闭其他标签页';

  @override
  String get tocTopicFromTemplate => '从模板创建主题...';

  @override
  String get tocSaveAsTemplate => '保存为模板';

  @override
  String get tocTemplateDialog => '从模板创建主题';

  @override
  String get tocTemplatesEditor => '文件和代码模板';

  @override
  String get tocEditTemplates => '编辑模板...';

  @override
  String get tocCreateCustomTemplate => '创建自定义模板...';

  @override
  String get tocTemplateCreated => '已创建模板';

  @override
  String get tocTemplateDefault => '默认';

  @override
  String get tocTemplateCustom => '自定义';

  @override
  String get tocTemplateFilename => '文件名：';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => '内部';

  @override
  String get tocTemplateUnnamed => '未命名';

  @override
  String get tocTemplateNew => '新建模板...';

  @override
  String get tocTemplateName => '名称：';

  @override
  String get tocTemplateExtension => '扩展名：';

  @override
  String get tocTemplateLoadError => '无法加载模板。现有模板未更改。';

  @override
  String get tocTemplateSaveError => '无法保存模板。您的编辑内容仍保留在此处。';

  @override
  String get tocTemplateConflict => '模板已在其他窗口中更改。请取消并重新打开编辑器。';

  @override
  String get tocTemplateDuplicateName => '已存在相同名称和扩展名的模板。';

  @override
  String get tocTemplateFormat => '格式：';

  @override
  String get tocTemplateReset => '重置';

  @override
  String get tocTemplateRetry => '重试';

  @override
  String tocRemoveElementsDialog(int count) {
    return '移除 $count 个目录元素';
  }

  @override
  String get tocRemoveElementsRetainFiles => '不会删除与这些目录元素关联的源文件。';

  @override
  String get tocOk => '确定';

  @override
  String get tocSelectExistingTopic => '选择要添加到当前实例的主题';

  @override
  String get tocGroupName => '组名';

  @override
  String get tocMoveLineUp => '上移行';

  @override
  String get tocMoveLineDown => '下移行';

  @override
  String get tocEmptyMdTopic => '空 MD 主题';

  @override
  String get tocEmptyXmlTopic => '空 XML 主题';

  @override
  String get tocCopySpecial => '特殊复制';

  @override
  String tocCopyFileName(String name) {
    return '主题文件名 \'$name\'';
  }

  @override
  String get tocCopyFilePath => '主题文件路径';

  @override
  String tocCopyTopicTitle(String title) {
    return '主题标题 \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return '目录元素 ID \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => '主题文件名';

  @override
  String get tocCopyTopicTitleUnavailable => '主题标题';

  @override
  String get tocCopyElementIdUnavailable => '目录元素 ID';

  @override
  String get tocEditTitleAction => '编辑标题...';

  @override
  String get tocEditTitleDialog => '编辑标题';

  @override
  String get tocRemoveElementAction => '移除目录元素...';

  @override
  String get tocSetHomePage => '设为主页';

  @override
  String tocGoToElement(String fileName) {
    return '转到“$fileName”中的目录元素';
  }

  @override
  String get tocSynchronize => '同步目录与编辑器';

  @override
  String get tocEmptyGroupAction => '空组';

  @override
  String get tocNewEmptyGroup => '新建空组';

  @override
  String get tocGroupAction => '分组';

  @override
  String get tocNewGroup => '新建组';

  @override
  String get tocSortChildren => '按字母顺序排列子主题';

  @override
  String get tocLinkTopicFiles => '将主题文件链接到目录...';

  @override
  String get addLocalMarkdownFiles => '添加本地 Markdown 文件';

  @override
  String get tocTitleField => '目录标题:';

  @override
  String get tocTopicTitleField => '主题标题:';

  @override
  String get tocAdvancedSettings => '高级设置';

  @override
  String tocInstanceTitleField(String instanceId) {
    return '“$instanceId”的标题:';
  }

  @override
  String get tocOnlyTitleField => '仅用于目录的标题:';

  @override
  String get tocInstanceTitleExplanation => '仅用于当前实例。默认继承主题标题。';

  @override
  String get tocOnlyTitleExplanation =>
      '仅用于目录。默认继承主题标题；如果设置了实例专用标题，则继承该标题。标题的说明见';

  @override
  String get tocTitleDocumentationLink => '此处';

  @override
  String get tocFindUsages => '查找';

  @override
  String get tocRefactorMenu => '重构';

  @override
  String get tocSafeDelete => '安全删除';

  @override
  String get tocDuplicate => '创建副本';

  @override
  String get tocDuplicateFilename => '主题文件名:';

  @override
  String get tocDuplicateDialog => '创建主题副本';

  @override
  String get pdfTitlePage => '标题页';

  @override
  String get pdfIncludeTitlePage => '包含标题页';

  @override
  String get pdfTitlePageNote => '此页不显示页眉、页脚或页码。';

  @override
  String get pdfTitlePageTitle => '标题';

  @override
  String get pdfTitlePageSubtitle => '副标题';

  @override
  String get pdfTitlePageAuthor => '作者';

  @override
  String get pdfTitlePageOrganization => '组织';

  @override
  String get pdfTitlePageVersion => '版本';

  @override
  String get pdfTitlePageDate => '日期';

  @override
  String get pdfTitlePageTitleRequired => '请输入标题页的标题。';

  @override
  String get pdfTocSectionNote => '从单独一页开始，可以跨多页。';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle => 'Markdown 文件和兼容 Writerside 的文档项目编辑器。';

  @override
  String get aboutBusyMark => '关于 BusyMark';

  @override
  String get aboutTagline => 'Markdown 和 Writerside 编辑器';

  @override
  String get aboutLicenseLabel => '许可证';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => '网站';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get reportIssue => '报告问题';

  @override
  String get feedbackCategory => '类别';

  @override
  String get feedbackChooseCategory => '选择类别';

  @override
  String get feedbackCategoryProblem => '问题或错误';

  @override
  String get feedbackCategoryFeature => '功能请求';

  @override
  String get feedbackCategoryPrivacySecurity => '隐私或安全问题';

  @override
  String get feedbackCategoryUsability => '可用性问题';

  @override
  String get feedbackCategoryOther => '其他';

  @override
  String get feedbackSubject => '主题';

  @override
  String get feedbackMessage => '详细留言';

  @override
  String get feedbackReplyEmail => '回复邮箱（可选）';

  @override
  String get feedbackIncludeTechnicalDetails => '包含技术详细信息';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      '启用后，此选项仅会添加您的 Linux 操作系统版本和 BusyMark 应用语言。不会附加日志、文件、账户数据或其他诊断信息。';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get feedbackSubmitting => '正在提交…';

  @override
  String get feedbackCategoryRequired => '请选择类别。';

  @override
  String get feedbackSubjectLength => '主题必须包含 3 到 120 个字符。';

  @override
  String get feedbackMessageLength => '信息必须包含 10 到 5,000 个字符。';

  @override
  String get feedbackReplyEmailInvalid => '请输入有效的邮箱地址，或将此字段留空。';

  @override
  String get feedbackConnectionFailure => 'BusyMark 无法连接。请检查网络连接后重试。';

  @override
  String get feedbackTimeoutFailure => '请求超时。请重试。';

  @override
  String get feedbackRateLimitedFailure => '此连接发送的报告过多。请稍候再试。';

  @override
  String get feedbackRejectedFailure => '服务器拒绝了此报告。请检查表单字段后重试。';

  @override
  String get feedbackServerFailure => '服务器无法接收此报告。请稍后重试。';

  @override
  String feedbackSuccess(String id) {
    return '反馈已发送。参考 ID：$id';
  }

  @override
  String get advanced => '高级';

  @override
  String get addToGit => '添加到 Git';

  @override
  String get appearance => '外观';

  @override
  String get apply => '应用';

  @override
  String get back => '返回';

  @override
  String get bottomLeft => '左下';

  @override
  String get bottomRight => '右下';

  @override
  String get cancel => '取消';

  @override
  String get choose => '选择';

  @override
  String get chooseLocation => '选择位置';

  @override
  String get copy => '复制';

  @override
  String get copyPlainText => '复制为纯文本';

  @override
  String get clipboardCopyFailed => '无法将所选内容复制到剪贴板。';

  @override
  String get copyName => '复制名称';

  @override
  String get copyFileName => '复制文件名';

  @override
  String get copyPath => '复制路径';

  @override
  String get create => '创建';

  @override
  String get creating => '正在创建…';

  @override
  String get cut => '剪切';

  @override
  String get promoteSection => '提升节级别';

  @override
  String get demoteSection => '降低节级别';

  @override
  String get moveSectionUp => '上移节';

  @override
  String get moveSectionDown => '下移节';

  @override
  String get confirmDeleteSectionTitle => '删除此节？';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '删除“$name”及其节中的全部内容？此操作无法撤销。';
  }

  @override
  String get darkTheme => '深色';

  @override
  String get delete => '删除';

  @override
  String get discard => '放弃';

  @override
  String get editor => '编辑器';

  @override
  String get file => '文件';

  @override
  String get fileHistory => '文件历史记录';

  @override
  String get folder => '文件夹';

  @override
  String get insert => '插入';

  @override
  String get keyboardShortcuts => '键盘快捷键';

  @override
  String get commandUnavailableInContext => '当前编辑器上下文中无法使用此命令';

  @override
  String get lightTheme => '浅色';

  @override
  String get mainMenu => '主菜单';

  @override
  String get fullScreen => '全屏';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => '打开';

  @override
  String get openInFiles => '在文件中打开';

  @override
  String get pathActions => '路径操作';

  @override
  String get outline => '大纲';

  @override
  String get overwrite => '覆盖';

  @override
  String get paste => '粘贴';

  @override
  String get reading => '阅读';

  @override
  String get removeFromRecent => '从最近使用记录中移除';

  @override
  String get recent => '最近使用';

  @override
  String get redo => '重做';

  @override
  String get save => '保存';

  @override
  String get search => '搜索';

  @override
  String get selectAll => '全选';

  @override
  String get settings => '设置';

  @override
  String get source => '源代码';

  @override
  String get split => '拆分';

  @override
  String get systemTheme => '系统';

  @override
  String get theme => '主题';

  @override
  String get appLanguage => '语言';

  @override
  String get systemLanguage => '系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk bokmål';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEstonian => 'Eesti';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get toggleSidebar => '侧边栏面板';

  @override
  String get topLeft => '左上';

  @override
  String get topRight => '右上';

  @override
  String get undo => '撤销';

  @override
  String get validate => '验证';

  @override
  String get validation => '验证';

  @override
  String get viewMode => '视图模式';

  @override
  String get welcome => '欢迎';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => '图像';

  @override
  String get openMarkdownFile => '打开 Markdown 文件';

  @override
  String get markdownFileExtensions => '.md 或 .markdown';

  @override
  String get openFolderOrWritersideProject => '打开文件夹或 Writerside 项目';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown 文件夹或兼容 Writerside 的项目';

  @override
  String get noOpenFile => '没有打开的文件';

  @override
  String get shortcutDeleteTreeItemDescription => '删除选中的文件项，或从目录中移除选中的主题';

  @override
  String get shortcutGroupGeneral => '常规';

  @override
  String get shortcutNewDocument => '创建';

  @override
  String get shortcutNewDocumentDescription => '创建 Markdown 文件或 Writerside 项目';

  @override
  String get shortcutOpenDescription => '打开 Markdown 文件、文件夹或 Writerside 项目';

  @override
  String get shortcutSaveDescription => '保存当前文档';

  @override
  String get shortcutSearchDescription => '搜索当前工作区';

  @override
  String get shortcutKeyboardShortcutsDescription => '自定义应用程序键盘快捷键';

  @override
  String get shortcutSyntaxReferenceDescription => '打开语法参考';

  @override
  String get shortcutSettingsDescription => '打开 BusyMark 设置';

  @override
  String get shortcutNextTab => '下一个标签页';

  @override
  String get shortcutNextTabDescription => '移至下一个打开的标签页';

  @override
  String get shortcutPreviousTab => '上一个标签页';

  @override
  String get shortcutPreviousTabDescription => '移至上一个打开的标签页';

  @override
  String get shortcutCloseTab => '关闭标签页';

  @override
  String get shortcutCloseTabDescription => '关闭当前标签页';

  @override
  String get shortcutCloseAllTabs => '关闭所有标签页';

  @override
  String get shortcutCloseAllTabsDescription => '关闭所有打开的标签页';

  @override
  String get shortcutGroupTextEditing => '文本编辑';

  @override
  String get shortcutSelectAllDescription => '在源代码模式下选择全部文本；在编辑器模式下按两次以选择所有块';

  @override
  String get shortcutCutDescription => '剪切选中的文本';

  @override
  String get shortcutCopyDescription => '复制选中的文本';

  @override
  String get shortcutPasteDescription => '从剪贴板粘贴';

  @override
  String get shortcutPastePlainTextDescription => '粘贴剪贴板中的无格式文本';

  @override
  String get shortcutUndoDescription => '撤销上次编辑';

  @override
  String get shortcutRedoDescription => '重做上次撤销的编辑';

  @override
  String get shortcutInsertIndentation => '插入缩进';

  @override
  String get shortcutInsertIndentationDescription => '在光标处插入缩进';

  @override
  String get shortcutOutdentSource => '减少源代码缩进';

  @override
  String get shortcutOutdentSourceDescription => '在源代码模式下减少一级缩进';

  @override
  String get shortcutEscape => '关闭搜索或清除块选择';

  @override
  String get shortcutEscapeDescription => '关闭工作区搜索，或在编辑器模式下清除块选择';

  @override
  String get shortcutGroupFormatting => '格式';

  @override
  String get shortcutBoldDescription => '切换选中文本的粗体';

  @override
  String get shortcutItalicDescription => '切换选中文本的斜体';

  @override
  String get shortcutUnderlineDescription => '切换选中文本的下划线';

  @override
  String get shortcutLinkDescription => '插入或编辑链接';

  @override
  String get shortcutInlineCodeDescription => '切换选中文本的行内代码格式';

  @override
  String get shortcutStrikethroughDescription => '切换选中文本的删除线';

  @override
  String get shortcutGroupBlocks => '块';

  @override
  String get shortcutParagraphDescription => '将当前块设为段落';

  @override
  String get shortcutHeading1Description => '将当前块设为标题 1';

  @override
  String get shortcutHeading2Description => '将当前块设为标题 2';

  @override
  String get shortcutHeading3Description => '将当前块设为标题 3';

  @override
  String get shortcutHeading4Description => '将当前块设为标题 4';

  @override
  String get shortcutHeading5Description => '将当前块设为标题 5';

  @override
  String get shortcutHeading6Description => '将当前块设为标题 6';

  @override
  String get shortcutGroupLists => '列表';

  @override
  String get numberedList => '编号列表';

  @override
  String get shortcutNumberedListDescription => '切换编号列表格式';

  @override
  String get bulletedList => '项目符号列表';

  @override
  String get shortcutBulletedListDescription => '切换项目符号列表格式';

  @override
  String get checklist => '检查清单';

  @override
  String get shortcutChecklistDescription => '切换检查清单格式';

  @override
  String get shortcutGroupSidebar => '侧边栏';

  @override
  String get sidebarViewMenu => '侧边栏视图';

  @override
  String get createMarkdownFile => '创建 Markdown 文件';

  @override
  String get createMarkdownFileDescription => '开始创建未保存的本地 Markdown 文档';

  @override
  String get createWritersideProject => '创建 Writerside 项目';

  @override
  String get createWritersideProjectDescription => '开始创建本地兼容 Writerside 的项目';

  @override
  String get defaultProjectName => '文档';

  @override
  String get defaultInstanceName => '用户指南';

  @override
  String get defaultStartTopicTitle => '开始使用';

  @override
  String get projectName => '项目名称';

  @override
  String get directoryName => '目录名称';

  @override
  String get instanceName => '实例名称';

  @override
  String get instanceId => '实例 ID';

  @override
  String get startTopicTitle => '起始主题标题';

  @override
  String get location => '位置';

  @override
  String get projectNameRequired => '项目名称为必填项。';

  @override
  String get directoryNameRequired => '目录名称为必填项。';

  @override
  String get useSingleSafeDirectoryName => '使用单一且安全的目录名称。';

  @override
  String get useLowercaseIdentifier => '使用仅包含小写字母、数字、下划线或连字符的小写标识符。';

  @override
  String get startTopicTitleRequired => '起始主题标题为必填项。';

  @override
  String get createWritersideProjectFailed => '无法创建 Writerside 项目。';

  @override
  String get settingsTitle => 'BusyMark 设置';

  @override
  String get autoSave => '自动保存';

  @override
  String get autoSaveDescription => '在短暂空闲后自动保存文件更改。';

  @override
  String get wordWrap => '自动换行';

  @override
  String get wordWrapDescription => '将长行换行以适应编辑器宽度，而不是水平滚动。';

  @override
  String get editorFontSize => '编辑器字体大小';

  @override
  String get validateOnEdit => '编辑时验证';

  @override
  String get clearRecentWorkspaces => '清除最近记录';

  @override
  String get editingButtonsPosition => '编辑按钮位置';

  @override
  String get editingButtonsPositionDescription => '选择浮动 WYSIWYG 编辑按钮的显示位置。';

  @override
  String get editingButtonsDirection => '编辑按钮方向';

  @override
  String get editingButtonsDirectionDescription => '选择水平或垂直排列浮动 WYSIWYG 编辑按钮。';

  @override
  String get horizontal => '水平';

  @override
  String get vertical => '垂直';

  @override
  String get privacy => '隐私';

  @override
  String get allowRemoteImages => '加载远程图像';

  @override
  String get allowRemoteImagesDescription =>
      '允许 Markdown 预览和编辑器从 http 和 https URL 加载图像。';

  @override
  String get clearRemoteImagePermissions => '清除远程图像权限';

  @override
  String get clearRemoteImagePermissionsDescription => '忘记已获准加载远程图像的工作区。';

  @override
  String get clearGitWorkspaceTrust => '清除受信任的 Git 工作区';

  @override
  String get clearGitWorkspaceTrustDescription => '为之前受信任的工作区启用 Git 功能前先进行询问。';

  @override
  String get settingsEditingButtonsSectionTitle => '编辑按钮';

  @override
  String get spellingDictionaries => '拼写词典';

  @override
  String get spellingDictionariesDescription => '安装和管理拼写词典';

  @override
  String get settingsDictionariesSectionTitle => '词典';

  @override
  String get availableSpellingDictionaries => '可用词典';

  @override
  String get customSpellingDictionaries => '自定义词典';

  @override
  String get spellingDictionaryProblems => '词典问题';

  @override
  String get settingsWindowSectionTitle => '窗口';

  @override
  String get settingsReopenWorkspaceOnStartupTitle => '启动时重新打开上次的工作区';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark 启动时打开上次会话中的工作区和标签页。';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle => '有未保存更改时关闭前进行确认';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      '文档有未保存更改时，关闭 BusyMark 前先进行询问。';

  @override
  String get closeUnsavedChangesTitle => '未保存的更改';

  @override
  String get closeUnsavedChangesSingleMessage =>
      '此文档有未保存的更改。关闭 BusyMark 前保存更改？';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      one: '有 1 个文档包含未保存的更改。关闭 BusyMark 前保存更改？',
      zero: '关闭 BusyMark 前保存更改？',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => '取消';

  @override
  String get closeUnsavedChangesDiscard => '放弃';

  @override
  String get closeUnsavedChangesSave => '保存';

  @override
  String get currentFile => '当前文件';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName 中有未保存的更改。继续前保存这些更改？';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文档包含未保存的更改。继续前保存它们？',
      one: '有 1 个文档包含未保存的更改。继续前保存它？',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => '文件已在磁盘上更改';

  @override
  String get fileChangedOnDiskMessage => '自打开此文件后，它已在磁盘上发生更改。覆盖它？';

  @override
  String get untitledMarkdownFileName => '未命名.md';

  @override
  String get unorderedList => '无序列表';

  @override
  String get orderedList => '有序列表';

  @override
  String get taskList => '任务列表';

  @override
  String get toggleTaskChecked => '切换任务选中状态';

  @override
  String get indentListItem => '增加列表项缩进';

  @override
  String get outdentListItem => '减少列表项缩进';

  @override
  String get blockquote => '引用块';

  @override
  String get codeBlock => '代码块';

  @override
  String get codeBlockLanguage => '代码块语言';

  @override
  String get image => '图像';

  @override
  String get video => '视频';

  @override
  String get openVideo => '播放视频';

  @override
  String get pauseVideo => '暂停视频';

  @override
  String get videoUnavailable => '视频不可用';

  @override
  String get videoPreview => '视频预览';

  @override
  String get diagnosticWritersideVideoMissingSource => '视频缺少 src 属性。';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return '不支持的视频源：$source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return '视频文件不存在：$source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return '视频预览图像不存在：$preview';
  }

  @override
  String get inlineImage => '行内图像';

  @override
  String get table => '表格';

  @override
  String get htmlBlock => 'HTML 块';

  @override
  String get htmlContentDefault => 'HTML 内容';

  @override
  String get shortcutHtmlBlockDescription => '插入或编辑 HTML 块';

  @override
  String get renderedHtml => '已渲染的 HTML';

  @override
  String get editHtml => '编辑 HTML';

  @override
  String get htmlSource => 'HTML 源代码';

  @override
  String get thematicBreak => '分隔线';

  @override
  String get bold => '粗体';

  @override
  String get italic => '斜体';

  @override
  String get underline => '下划线';

  @override
  String get strikethrough => '删除线';

  @override
  String get inlineCode => '行内代码';

  @override
  String get link => '链接';

  @override
  String get hardLineBreak => '硬换行';

  @override
  String get insertBlankLine => '插入空行';

  @override
  String get textStyle => '文本样式';

  @override
  String get paragraph => '段落';

  @override
  String get heading1 => '标题 1';

  @override
  String get heading2 => '标题 2';

  @override
  String get heading3 => '标题 3';

  @override
  String get heading4 => '标题 4';

  @override
  String get heading5 => '标题 5';

  @override
  String get heading6 => '标题 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => '删除表格';

  @override
  String tableColumnNumber(int columnNumber) {
    return '列 $columnNumber';
  }

  @override
  String get insertColumnLeft => '在左侧插入列';

  @override
  String get insertColumnRight => '在右侧插入列';

  @override
  String get deleteColumn => '删除列';

  @override
  String get tableAlignmentUnspecified => '对齐方式：未指定';

  @override
  String get tableAlignmentLeft => '对齐方式：左对齐';

  @override
  String get tableAlignmentCenter => '对齐方式：居中';

  @override
  String get tableAlignmentRight => '对齐方式：右对齐';

  @override
  String tableRowNumber(int rowNumber) {
    return '行 $rowNumber';
  }

  @override
  String get insertRowAbove => '在上方插入行';

  @override
  String get insertRowBelow => '在下方插入行';

  @override
  String get deleteRow => '删除行';

  @override
  String get tableHeaderHint => '标题';

  @override
  String get tableCellHint => '单元格';

  @override
  String get language => '语言';

  @override
  String get hideEditingButtons => '隐藏编辑按钮';

  @override
  String get showEditingButtons => '显示编辑按钮';

  @override
  String get altText => '替代文本';

  @override
  String get editorPlaceholderText => '文本';

  @override
  String get editorPlaceholderCode => '代码';

  @override
  String get editorPlaceholderAltText => '替代文本';

  @override
  String get describeTheImage => '描述图像';

  @override
  String get columns => '列';

  @override
  String get rows => '行';

  @override
  String tableHeaderNumber(int columnNumber) {
    return '标题 $columnNumber';
  }

  @override
  String get tableCellDefault => '单元格';

  @override
  String get noImageSource => '没有图像源';

  @override
  String get remoteImageBlocked => '远程图像已阻止';

  @override
  String get remoteImageBlockedTooltip => '选择是否允许 BusyMark 加载远程图像。';

  @override
  String get remoteImagesBlockedTitle => '远程图像已阻止';

  @override
  String get remoteImagesBlockedMessage =>
      '本文档引用了来自互联网的图像。加载这些图像可能会向图像托管方泄露网络信息。';

  @override
  String get loadRemoteImagesForWorkspace => '为此工作区加载';

  @override
  String get alwaysLoadRemoteImages => '始终加载远程图像';

  @override
  String get hideSidebar => '隐藏侧边栏面板';

  @override
  String get showSidebar => '显示侧边栏面板';

  @override
  String get showPreview => '显示预览';

  @override
  String get hidePreview => '隐藏预览';

  @override
  String get workspaceKindUnsavedMarkdown => '未保存的 Markdown 文件';

  @override
  String get workspaceKindSingleMarkdown => '单个 Markdown 文件';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown 文件夹';

  @override
  String get workspaceKindWritersideModule => 'Writerside 模块';

  @override
  String get problems => '问题';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条诊断信息',
      one: '1 条诊断信息',
      zero: '没有诊断信息',
    );
    return '$_temp0';
  }

  @override
  String get files => '文件';

  @override
  String get toc => '目录';

  @override
  String get tocActions => '目录操作';

  @override
  String get markdownUnsaved => 'Markdown - 未保存';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => '没有文件';

  @override
  String get newFile => '新建文件';

  @override
  String get noWritersideToc => '没有 Writerside 目录';

  @override
  String get tocSection => '目录节';

  @override
  String get newTopic => '新建主题';

  @override
  String get newChildTopic => '新建子主题';

  @override
  String get newSiblingTopic => '新建主题';

  @override
  String get renameTopicFile => '重命名主题文件';

  @override
  String get topicPlacement => '目录位置';

  @override
  String get tocRoot => '位于目录根级别';

  @override
  String get afterSelectedTopic => '位于选中主题之后';

  @override
  String get insideSelectedTopic => '位于选中主题内';

  @override
  String get pasteAfterTopic => '粘贴到主题之后';

  @override
  String get pasteAsChildTopic => '粘贴为子主题';

  @override
  String get removeFromToc => '从目录中移除';

  @override
  String get confirmRemoveFromTocTitle => '从目录中移除？';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '从此目录中移除 $name？主题文件将被保留。';
  }

  @override
  String get confirmDeleteTopicTitle => '删除主题文件？';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '删除 $name 并从每个目录中移除它？此操作无法撤销。';
  }

  @override
  String get safeDeleteTopicFile => '安全删除主题文件…';

  @override
  String get removeTocElement => '移除目录元素';

  @override
  String get removeTocElements => '移除目录元素';

  @override
  String get reviewUsages => '查看使用情况';

  @override
  String get deleteTopicFile => '删除主题文件';

  @override
  String get removeAction => '移除';

  @override
  String topicRemovalSummary(String topic) {
    return '移除目录元素“$topic”？与目录关联的源文件不会被删除。';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '删除“$topic”，并在整个 Writerside 项目中安全更新其引用。';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个子主题将上移一级。',
      one: '1 个子主题将上移一级。',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning => '此主题是此实例的主页。从目录中移除它之前，请选择另一个主页。';

  @override
  String get newHomePage => '新主页';

  @override
  String get chooseHomePage => '选择主页';

  @override
  String get noHomePageReplacement => '移除主页之前，请向此实例添加或链接另一个符合条件的主题。';

  @override
  String get topicIsStartPageRemovalWarning => '此主题是某个实例的主页。删除其源文件之前，请指定另一个主页。';

  @override
  String topicUsagesCount(int count) {
    return '找到 $count 处使用。';
  }

  @override
  String get noBreakingTopicUsages => '未找到会导致引用失效的引用。';

  @override
  String get topicUsagesFound => 'BusyMark 找到了以下对该主题的引用。';

  @override
  String get topicUsageTocElements => '目录元素';

  @override
  String get topicUsageStartPages => '主页';

  @override
  String get topicUsageTopicLinks => '主题链接';

  @override
  String get topicUsageIncludes => '包含项';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 次使用',
      one: '1 次使用',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => '重构选项';

  @override
  String get updateUsagesAutomatically => '自动更新使用情况';

  @override
  String get updateUsagesAutomaticallyDescription => '移除目录引用和包含项，同时保留链接文本。';

  @override
  String get manualUsageUpdatesRequired => '执行此重构前，某些使用情况需要手动更改。';

  @override
  String get setRedirectTo => '设置重定向到：';

  @override
  String get noRedirectDescription => '不重定向旧的已发布页面。';

  @override
  String get redirectTarget => '重定向目标';

  @override
  String get remainingUsagesBlockRemoval => '请在继续前查看并更新剩余的使用情况，或在可用时启用自动更新。';

  @override
  String usagesOfTopic(String topic) {
    return '$topic 的使用情况';
  }

  @override
  String get noUsagesFound => '未找到使用情况';

  @override
  String get outsideSelectedInstance => '在选中的实例之外';

  @override
  String get doRefactor => '执行重构';

  @override
  String get preview => '预览';

  @override
  String get topicRenamePreviewTitle => '重命名预览';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return '路径：$oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return '主题 ID：$oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return '实例 $instance：$oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => '受影响的文件';

  @override
  String get orphanTopicTitle => '主题文件已不再使用';

  @override
  String get keepTopicFile => '保留主题文件';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic”在此 Writerside 项目中已不再使用。删除该文件，或保留它以供其他实例使用。';
  }

  @override
  String get defaultNewTopicTitle => '新主题';

  @override
  String get topicTitle => '主题标题';

  @override
  String get fileName => '文件名';

  @override
  String get topicTitleRequired => '主题标题为必填项。';

  @override
  String get fileNameRequired => '文件名为必填项。';

  @override
  String get rename => '重命名';

  @override
  String get confirmDeleteFileTitle => '删除文件？';

  @override
  String get confirmDeleteFolderTitle => '删除文件夹？';

  @override
  String confirmDeleteFileMessage(String name) {
    return '删除 $name？此操作无法撤销。';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '删除 $name 及其中的所有文件？此操作无法撤销。';
  }

  @override
  String get useSingleSafeFileName => '使用单一且安全的文件名。';

  @override
  String useExpectedExtension(String extension) {
    return '为选中的格式使用 $extension 扩展名。';
  }

  @override
  String get useIdentifierCharacters => '在扩展名之前仅使用字母、数字、下划线或连字符。';

  @override
  String get topicIdAlreadyExists => '主题 ID 已存在。';

  @override
  String get createWritersideTopicFailed => '无法创建 Writerside 主题。';

  @override
  String get noOutline => '没有大纲';

  @override
  String expandKind(String kind) {
    return '展开 $kind';
  }

  @override
  String collapseKind(String kind) {
    return '折叠 $kind';
  }

  @override
  String get foldKindSection => '节';

  @override
  String get foldKindList => '列表';

  @override
  String get foldKindQuote => '引用';

  @override
  String get foldKindTag => '标签';

  @override
  String get sourceSearchPreviousMatch => '上一个匹配项';

  @override
  String get sourceSearchNextMatch => '下一个匹配项';

  @override
  String get sourceSearchReplacement => '替换为';

  @override
  String get sourceSearchReplaceCurrent => '替换当前匹配项';

  @override
  String get sourceSearchReplaceAndFindNext => '替换并查找下一个';

  @override
  String get sourceSearchReplaceAll => '全部替换';

  @override
  String get workspaceReplace => '在工作区中替换';

  @override
  String get reviewReplacements => '查看替换内容';

  @override
  String get applyReplacements => '应用替换';

  @override
  String get skippedFiles => '跳过的文件';

  @override
  String get workspaceReplaceDirtyBuffer => '未保存的编辑器内容';

  @override
  String get workspaceReplaceDiskContent => '磁盘上的已保存内容';

  @override
  String selectFileMatches(int count) {
    return '选择全部 $count 个匹配项';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '已在 $files 个文件中替换 $matches 个匹配项；跳过 $skipped 个。';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾有换行符';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾无换行符';
  }

  @override
  String get normalizeLineEndings => '规范化行尾';

  @override
  String get mixedLineEndingsSavePrompt => '此文档包含混合的行尾格式。请选择一种格式。';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName 使用混合的行尾格式。请在替换前选择要使用的格式。';
  }

  @override
  String get workspaceReplaceIssueOversized => '已跳过过大的文件。';

  @override
  String get workspaceReplaceIssueUnreadable => '已跳过无法读取的文件。';

  @override
  String get workspaceReplaceIssueInvalidUtf8 => '已跳过不是有效 UTF-8 的文件。';

  @override
  String get workspaceReplaceIssueTruncated => '替换预览已被截断。';

  @override
  String get workspaceReplaceIssueFileChanged => '已跳过预览后发生变化的文件。';

  @override
  String get workspaceReplaceIssueBufferChanged => '已跳过预览后发生变化的编辑器缓冲区。';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      '请在替换前选择 LF 或 CRLF 规范化。';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      '由于文件同时发生了变化，回滚已停止。部分替换可能仍然存在；被移出的内容已保留在下方路径中。';

  @override
  String get workspaceReplaceIssueApplyFailed => '无法提交经过审查的替换；没有文件发生更改。';

  @override
  String externalChangesTitle(String fileName) {
    return '外部更改 — $fileName';
  }

  @override
  String get externalFileDeleted => '此文件已从磁盘删除。';

  @override
  String get externalFileChanged => '在您有未保存编辑时，此文件已在磁盘上发生变化。';

  @override
  String recoveredDocumentReview(String fileName) {
    return '已恢复 $fileName 的未保存内容。请检查后保存、另存为或放弃。';
  }

  @override
  String get compare => '比较';

  @override
  String get reloadFromDisk => '从磁盘重新加载';

  @override
  String get keepMine => '保留我的版本';

  @override
  String get saveAs => '另存为';

  @override
  String get workspaceSearchIncomplete => '仅显示了部分结果。请显示更多结果或缩小搜索范围。';

  @override
  String get workspaceSearchShowMore => '显示更多结果';

  @override
  String get workspaceSearchSkippedFiles => '搜索不完整。以下文件超过 1 MiB 或无法读取：';

  @override
  String get sourceLargeFileFeaturesPaused => '大文件：已暂停语法突出显示和折叠';

  @override
  String get nothingToRead => '没有可读取的内容';

  @override
  String get admonition => '提示块';

  @override
  String get quote => '引用';

  @override
  String get note => '备注';

  @override
  String get tip => '提示';

  @override
  String get warning => '警告';

  @override
  String get tabs => '标签页';

  @override
  String get tab => '标签页';

  @override
  String get procedure => '操作步骤';

  @override
  String get step => '步骤';

  @override
  String get topic => '主题';

  @override
  String get chapter => '章节';

  @override
  String couldNotOpenTarget(String target) {
    return '无法打开 $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return '找不到链接目标：$targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor => '无法在编辑器中打开此文件类型';

  @override
  String anchorNotFound(String anchor) {
    return '找不到锚点：$anchor';
  }

  @override
  String get noProblemsFound => '未发现问题';

  @override
  String get noResults => '无结果';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - 第 $lineNumber 行';
  }

  @override
  String get untitledResult => '未命名结果';

  @override
  String get documentKindMarkdownFile => 'Markdown 文件';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown 主题';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML 主题';

  @override
  String get documentKindWritersideTree => 'Writerside 树';

  @override
  String get documentKindConfigurationFile => '配置文件';

  @override
  String get documentKindVariablesFile => '变量文件';

  @override
  String get documentKindCategoriesFile => '类别文件';

  @override
  String get documentKindResourceFile => '资源文件';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return '无法更新最近使用的项目：$error。';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return '打开失败：$error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return '无法创建 Writerside 项目：$error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return '无法创建 Writerside 主题：$error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return '无法打开文件：$error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown => '选择保存此 Markdown 文件的位置。';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk => '保存已阻止：文件已在磁盘上发生变化。';

  @override
  String workspaceErrorSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return '文件操作失败：$error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return '验证失败：$error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已恢复 $count 个未保存的文档。请在保存或放弃前逐一检查。',
      one: '已恢复 1 个未保存的文档。请在保存或放弃前进行检查。',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '无法恢复 $count 条损坏的恢复记录。有效的恢复记录仍可用。',
      one: '无法恢复一条损坏的恢复记录。原始恢复文件已保留以供检查。',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return '路径不存在：$path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return '目标目录已存在且不为空：$path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return '目标路径已存在但不是目录：$path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return '生成的文件已存在：$path';
  }

  @override
  String get errorParentDirectoryRequired => '必须指定父目录。';

  @override
  String errorParentDirectoryMissing(String path) {
    return '父目录不存在：$path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return '目录不存在：$path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return '路径已存在：$path';
  }

  @override
  String get errorFileNameRequired => '文件名为必填项。';

  @override
  String get errorFileNameUnsafe => '文件名必须是单一且安全的路径段。';

  @override
  String get errorFileOperationInvalidTarget => '无法将文件夹移动到其自身中。';

  @override
  String get errorFileOperationOutsideRoot => '文件操作必须在工作区内进行。';

  @override
  String get errorFileOperationRoot => '无法从文件树更改工作区根目录。';

  @override
  String get errorProjectNameRequired => '项目名称为必填项。';

  @override
  String get errorDirectoryNameRequired => '目录名称为必填项。';

  @override
  String get errorDirectoryNameUnsafe => '目录名称必须是单一且安全的路径段。';

  @override
  String get errorInstanceIdInvalid => '实例 ID 必须以小写字母开头，且只能包含小写字母、数字、下划线和连字符。';

  @override
  String get errorTopicFileInvalid => '主题文件名必须是没有路径分隔符的 Markdown 文件名。';

  @override
  String get errorTopicTitleRequired => '主题标题为必填项。';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside 模块根目录不存在：$path';
  }

  @override
  String get errorWritersideModuleNotOpen => '必须打开 Writerside 模块才能创建主题。';

  @override
  String get errorWritersideInstanceTreeMissing => 'Writerside 模块没有实例树。';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside 树文件不存在：$path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return '主题 ID \"$topicId\" 已存在于此帮助模块中。';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return '主题文件已存在：$path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return '选中的树中不存在引用主题：$topic';
  }

  @override
  String get errorWritersideTocNodeMissing => '选中的目录项已不存在。';

  @override
  String get errorWritersideTocInvalidMove => '目录项无法移动到自身或其子项中。';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '无法删除主页 $topic。请先选择另一个主页。';
  }

  @override
  String get errorWritersideSafeDeleteRequired => '请对 Writerside 主题文件使用安全删除。';

  @override
  String get errorWritersideTopicUsageScanFailed => '无法完成主题使用情况扫描。没有文件发生更改。';

  @override
  String get errorWritersideTopicUsagesRemain => '某些主题使用情况仍需处理。请先查看后再继续。';

  @override
  String get errorWritersideRedirectInvalid => '选中的重定向目标已无效。请重新选择。';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return '无法完全回滚主题移除。请在继续前查看这些路径：$paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return '无法安全地重命名并更新所有项目引用，因为模块 $module 中有 $count 个主题文件尚未解析：$paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside 项目文件有未保存的更改。请先处理这些更改，再准备新的重命名预览。';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Writerside 项目的模块集合已更改。请在重构前准备新的重命名预览。';

  @override
  String get errorTopicsRootUnsafe => '主题根目录必须是安全的相对目录。';

  @override
  String get errorTopicFileNameUnsafe => '主题文件名必须是单一且安全的路径段。';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return '主题文件扩展名必须与选中的格式匹配（$extension）。';
  }

  @override
  String get errorTopicFileNameInvalid => '主题文件名只能包含字母、数字、下划线和连字符。';

  @override
  String errorUnknown(String code) {
    return '未知错误：$code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return '无法读取文件元数据：$error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped => '检测到大型工作区。为保持应用响应速度，已跳过部分文件。';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return '无法检查工作区项：$error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge => '文件超过 beta 自动解析限制。';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return '无法读取 Markdown 文件：$error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed => 'Writerside 标题属性块格式错误。';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return '标题 ID“$id”重复。';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      '额外的顶级 H1 标题将被视为章节。';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown 主题没有 H1 或 front matter 标题。';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle => 'XML 主题缺少标题。';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return '主题“$fileName”缺少标题。';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed => 'front matter 未闭合。';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => '不安全的 HTML 元素。';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return '链接目标不存在：$targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return '锚点“$anchor”不存在。';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '图像“$destination”缺少替代文本。';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return '图像不存在：$destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return '无效的 XML：$message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg 根元素必须是 <ihp>。';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups 声明缺少 src。';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return '不支持的 keymaps 模式：$mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'instance 声明缺少 src。';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg 未注册实例。';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree 根元素必须是 <instance-profile>。';

  @override
  String get diagnosticWritersideTreeMissingId => '实例配置文件缺少 id。';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return '树文件名（不含扩展名）与实例 ID“$id”不匹配。';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage => '非库实例缺少 start-page。';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '起始页“$startPage”不存在。';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return '主题“$topic”在此实例目录中出现多次。';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      '变量声明必须包含名称和值。';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '变量“$name”被声明了多次。';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => '类别缺少 id。';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return '类别“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return '类别顺序“$order”被声明了多次。';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot => '.topic 根元素必须是 <topic>。';

  @override
  String get diagnosticWritersideTopicMissingRootId => 'XML 主题缺少根 id。';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML 主题根 ID“$id”必须与文件名“$expectedId”匹配。';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return '元素 ID“$elementId”出现多次。';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> 缺少 href。';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside 模式需要 writerside.cfg。';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return '配置的构建配置目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return '配置的 API 规范目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return '配置的 snippets 目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return '配置的变量文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return '配置的类别文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return '配置的实例组文件不存在：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return '已注册的实例树“$source”不存在。';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return '无法读取主题文件：$error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return '默认主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return '配置的主题目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return '配置的图像目录不存在：$relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return '元素 ID“$id”出现多次。';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return '实例 \"$instanceId\" 为主题 \"$topic\" 发布了无效的 Web 文件名 \"$webFileName\"。';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return '实例 \"$instanceId\" 将 \"$firstTopic\" 和 \"$secondTopic\" 都发布为 \"$webFileName\"。';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return '目录引用了缺失的主题“$topic”。';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return '外部 href“$href”无效。';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '变量“%$name%”未声明。';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return '主题链接“$destination”无法解析。';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '“$targetName”中不存在锚点“$anchor”。';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom => '<include> 缺少 from。';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return '包含源“$from”不存在。';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '“$from”中不存在包含元素“$elementId”。';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso 类别“$ref”未声明。';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return '主题引用“$reference”不明确。';
  }

  @override
  String diagnosticUnknown(String code) {
    return '未知诊断信息：$code';
  }

  @override
  String get close => '关闭';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git 差异';

  @override
  String get gitShowDiff => '显示差异';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return '旧 $oldRange → 新 $newRange';
  }

  @override
  String get gitDiffNoLines => '无行';

  @override
  String get gitUnavailableTitle => 'Git 不可用';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other': '安装 Git，或配置 BusyMark 以使用可用的 Git 可执行文件。$reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => '信任此工作区以使用 Git？';

  @override
  String get gitTrustRequiredMessage =>
      'Git 存储库可以通过 hook、过滤器和其他配置运行程序。在 BusyMark 读取存储库数据或启用 Git 操作前，请先信任此工作区。';

  @override
  String get gitTrustWorkspace => '信任工作区';

  @override
  String get gitNotRepositoryTitle => '不是 Git 存储库';

  @override
  String get gitNotRepositoryMessage => '此工作区不在 Git 存储库中。';

  @override
  String get gitInitializeRepository => '初始化存储库';

  @override
  String get gitDetachedHead => '分离的 HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '分离于 $commit';
  }

  @override
  String get gitNoUpstream => '没有上游分支';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个未推送的提交',
      one: '1 个未推送的提交',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个待拉取的提交',
      one: '1 个待拉取的提交',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => '干净';

  @override
  String get gitConflicts => '冲突';

  @override
  String get gitChanges => '更改';

  @override
  String get gitStaged => '已暂存';

  @override
  String get gitUnstaged => '未暂存';

  @override
  String get gitHistory => '历史记录';

  @override
  String get gitBranches => '分支';

  @override
  String get gitActions => 'Git 操作';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => '暂存文件';

  @override
  String get gitRemoveFromCommit => '取消暂存文件';

  @override
  String get gitDiscard => '还原';

  @override
  String get gitOpenFile => '打开文件';

  @override
  String get gitMarkResolved => '标记为已解决';

  @override
  String get gitUntracked => '未跟踪';

  @override
  String get gitCommitMessage => '提交消息';

  @override
  String get gitCommitSelectedFiles => '选中的文件';

  @override
  String get gitCommitNoSelectedFiles => '提交前至少暂存一个文件。';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个已暂存文件',
      one: '1 个已暂存文件',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => '工作区之外';

  @override
  String get gitCommitMessageRequired => '请输入提交消息。';

  @override
  String get gitCreateBranch => '创建分支';

  @override
  String get gitNewBranch => '新分支';

  @override
  String get gitBranchName => '分支名称';

  @override
  String get gitSwitchBranch => '切换';

  @override
  String get gitNoChanges => '没有更改';

  @override
  String get gitNoHistory => '没有历史记录';

  @override
  String get gitNoBranches => '没有分支';

  @override
  String get gitNoDiff => '没有可显示的差异';

  @override
  String get gitBinaryFile => '二进制文件。BusyMark 不渲染二进制补丁。';

  @override
  String gitBinaryFileInfo(int size) {
    return '二进制文件（$size 字节）。BusyMark 不渲染二进制补丁。';
  }

  @override
  String get gitUnsavedChangesBanner => '保存前不会包含未保存的编辑器更改。';

  @override
  String get gitConfirmDiscardTitle => '放弃 Git 更改？';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
      one: '选中的已跟踪文件中的所有已暂存和未暂存更改都将还原到 HEAD。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '选中的未跟踪文件将被删除。',
      one: '选中的未跟踪文件将被删除。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '将根据其 Git 状态还原或删除选中的文件。',
      one: '将根据其 Git 状态还原或删除选中的文件。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '切换到 $branch？';
  }

  @override
  String get gitConfirmSwitchBranchMessage => 'Git 切换分支后，BusyMark 将从磁盘重新加载工作区。';

  @override
  String get gitConfirmPushSetUpstreamTitle => '设置上游分支？';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return '此分支没有上游分支。当只配置了一个远程仓库时，BusyMark 可以推送 $branch 并设置其上游分支。';
  }

  @override
  String get gitProjectHistory => '项目历史记录';

  @override
  String get gitFileHistory => '文件历史记录';

  @override
  String get gitFileHistoryRequiresOpenFile => '文件历史记录需要打开的 Markdown 文件。';

  @override
  String get gitLoadMore => '加载更多';

  @override
  String get gitChangesInCommit => '此提交中的更改';

  @override
  String get gitCompareWithCurrent => '与当前版本比较';

  @override
  String get gitRestoreVersion => '还原此版本';

  @override
  String get gitConfirmRestoreTitle => '还原此文件版本？';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark 将使用选中的已提交版本替换当前工作树中的文件。还原后的文件将保持未暂存状态。';

  @override
  String get gitCommitActions => '提交操作';

  @override
  String get gitResetCurrentBranchToHere => '将当前分支重置到此处…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '将 $branch 重置到 $commit？';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return '这会将分支 $branch 移动到提交 $commit。请选择 Git 更新索引和工作树的方式。';
  }

  @override
  String get gitReset => '重置';

  @override
  String get gitResetModeSoft => '软';

  @override
  String get gitResetModeSoftDescription =>
      '仅移动分支。保持索引和工作树不变；与选中提交之间的差异仍会保持暂存状态。';

  @override
  String get gitResetModeMixed => '混合';

  @override
  String get gitResetModeMixedDescription => '移动分支并重置索引。保持工作树不变，使差异处于未暂存状态。';

  @override
  String get gitResetModeHard => '硬';

  @override
  String get gitResetModeHardDescription =>
      '移动分支并重置索引和工作树。已跟踪的更改将被放弃；造成阻碍的未跟踪文件可能会被删除。';

  @override
  String get gitResetModeKeep => '保留';

  @override
  String get gitResetModeKeepDescription =>
      '移动分支并重置已跟踪文件，同时保留本地更改。如果这些更改与重置冲突，Git 将中止操作。';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => '文件操作';

  @override
  String get actions => '操作';

  @override
  String get gitStatusAdded => '已添加';

  @override
  String get gitStatusDeleted => '已删除';

  @override
  String get gitStatusRenamed => '已重命名';

  @override
  String get gitStatusCopied => '已复制';

  @override
  String get gitStatusUntracked => '未跟踪';

  @override
  String get gitStatusConflicted => '有冲突';

  @override
  String get gitStatusIgnored => '已忽略';

  @override
  String get gitStatusTypeChanged => '类型已更改';

  @override
  String get gitStatusModified => '已修改';

  @override
  String get gitStatusUnknown => '未知';

  @override
  String get gitErrorUnavailable => 'Git 不可用。';

  @override
  String get gitErrorNotRepository => '此工作区不是 Git 存储库。';

  @override
  String get gitErrorUnsafePath => 'BusyMark 阻止了不安全的 Git 路径。';

  @override
  String get gitErrorInvalidBranchName => '请输入有效的分支名称。';

  @override
  String get gitErrorNoRemote => '未配置 Git 远程仓库。';

  @override
  String get gitErrorNoUpstream => '未配置上游分支。';

  @override
  String get gitErrorMultipleRemotes => '配置了多个远程仓库。请在此 BusyMark 版本之外选择上游分支。';

  @override
  String get gitErrorDirtyWorkspace => '切换分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorResetDirtyWorkspace => '重置当前分支前，请保存或放弃 BusyMark 编辑器中的更改。';

  @override
  String get gitErrorRestoreStagedFile => '还原历史版本前，请取消暂存此文件。';

  @override
  String get gitErrorResetDetachedHead => '重置前请先检出一个分支。';

  @override
  String get gitErrorDiverged => '分支已发生分歧。请在此 BusyMark 版本之外解决合并或变基问题。';

  @override
  String get gitErrorAuthorIdentity => 'Git 需要作者姓名和邮箱地址才能提交。';

  @override
  String get gitAuthorIdentityTitle => 'Git 作者身份';

  @override
  String get gitAuthorIdentityMessage =>
      '请输入 Git 应记录在提交中的身份信息。BusyMark 将保存它并重试此次提交。';

  @override
  String get gitAuthorName => '姓名';

  @override
  String get gitAuthorEmail => 'Email';

  @override
  String get gitAuthorIdentityGlobal => '用于所有存储库';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      '作为 Snap 安装时，此设置适用于在 BusyMark 中打开的存储库。';

  @override
  String get gitSaveIdentityAndCommit => '保存并提交';

  @override
  String get gitErrorAuthentication => 'Git 身份验证失败。';

  @override
  String get gitErrorNetwork => 'Git 网络操作失败。';

  @override
  String get gitErrorConflict => 'Git 报告存在未解决的冲突。';

  @override
  String get gitErrorCommandFailed => 'Git 命令失败。';

  @override
  String get syntaxReference => '语法参考';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown 块';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown 源代码和预览中支持的块结构。';

  @override
  String get syntaxReferenceInlineFormatting => '行内 Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      '可出现在段落、列表项和表格单元格中的格式。';

  @override
  String get syntaxReferenceRawHtmlBlocks => '原始 HTML 块';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      '通过 BusyMark 预览组件渲染的安全块级 HTML 标签。';

  @override
  String get syntaxReferenceRawHtmlInline => '原始 HTML 行内标签';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      '安全的行内 HTML 标签，渲染时不会显示字面标签。';

  @override
  String get syntaxReferenceHeadings => '标题';

  @override
  String get syntaxReferenceParagraphs => '段落';

  @override
  String get syntaxReferenceLists => '列表';

  @override
  String get syntaxReferenceHtmlContainers => '容器';

  @override
  String get syntaxReferenceHtmlTextBlocks => '文本块';

  @override
  String get syntaxReferenceHtmlFigures => '图和图像';

  @override
  String get syntaxReferenceHtmlPreformatted => '预格式化代码';

  @override
  String get syntaxReferenceHtmlDisclosure => '折叠块';

  @override
  String get syntaxReferenceHtmlDescriptionLists => '描述列表';

  @override
  String get syntaxReferenceHtmlFormattingTags => '格式标签';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => '行内代码标签';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => '语义文本标签';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      '允许的 HTML 会转换为 BusyMark 预览块，而不是在浏览器中渲染。';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      '未经编辑的原始 HTML 会按源文本原样保存。';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      '原始 HTML 内的 Markdown 标记会按字面文本渲染。';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      '脚本、样式、框架、表单、SVG、MathML、事件和不安全属性都会被阻止。';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      '链接允许 http、https、mailto、tel、相对路径和片段 URL；不安全的 scheme 会被阻止。';

  @override
  String get syntaxReferenceCategory => '类别';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => '图表和 API';

  @override
  String get syntaxReferenceCategoryMathematics => '数学';

  @override
  String get syntaxReferenceExample => '示例';

  @override
  String get syntaxReferenceIdentifiers => '标识符和别名';

  @override
  String get syntaxReferenceScope => '适用范围';

  @override
  String get syntaxReferenceLimitation => 'BusyMark 限制';

  @override
  String get syntaxReferenceOfficialDocumentation => '官方文档';

  @override
  String get syntaxReferenceScopeWritersideMarkdown => '仅 Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      '仅 Writerside Markdown 和 Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'BusyMark 可以编写和预览的核心 Markdown 形式。';

  @override
  String get syntaxReferenceParagraphExample => '一段文本。';

  @override
  String get syntaxReferenceTableLimitation =>
      '表格使用 GitHub Flavored Markdown 的竖线语法。';

  @override
  String get syntaxReferenceHardBreakIdentifiers => '行尾两个空格、\\、<br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark 在 Markdown 源码中仅接受有限且安全的原始 HTML 子集。';

  @override
  String get syntaxReferenceDiagramsDescription =>
      '带围栏的 Mermaid、PlantUML、D2 和 OpenAPI 块可在 Markdown 源码中使用。围栏标识符不区分大小写，BusyMark 会保留原始拼写。';

  @override
  String get syntaxReferenceMermaid => 'Mermaid';

  @override
  String get syntaxReferencePlantUml => 'PlantUML';

  @override
  String get syntaxReferenceD2 => 'D2';

  @override
  String get syntaxReferenceOpenApi => 'OpenAPI';

  @override
  String get syntaxReferenceOpenApiLimitation =>
      '请使用带围栏的 YAML 或 JSON 内容。BusyMark 不会将任意完整的 YAML 或 JSON 文档视为 OpenAPI 参考。';

  @override
  String get syntaxReferenceSemanticDiagramBlocks => '图表的语义代码块';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      '语义 code-block 和 src 形式仅支持 Mermaid、PlantUML 和 D2，不支持 OpenAPI，且只能在 Writerside 项目中使用。';

  @override
  String get syntaxReferenceReferencedDiagramSource => '引用的图表源';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      '路径必须是相对路径并位于已打开的 Writerside 项目内；围栏加 src 的形式仅适用于 Writerside Markdown。';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark 支持 TeX 表达式，但不支持完整的 TeX 或 LaTeX 文档。';

  @override
  String get syntaxReferenceInlineMath => '行内数学公式';

  @override
  String get syntaxReferenceGithubMath => '使用美元符号和反引号的 GitHub 数学公式';

  @override
  String get syntaxReferenceDisplayMath => '显示数学公式';

  @override
  String get syntaxReferenceMathFence => 'math 围栏';

  @override
  String get syntaxReferenceTexFence => 'tex 围栏';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark 不会将 \\(...\\) 或 \\[...\\] 识别为 Markdown 数学分隔符。';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      '在 Writerside 模式之外，tex 围栏仍是普通代码块。';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside math 元素';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math 元素是语义 Writerside 语法，不是允许的原始 HTML MathML。';

  @override
  String get syntaxReferenceSemanticTexBlock => '语义 TeX 代码块';

  @override
  String get syntaxReferenceWritersideDescription =>
      '这些特定扩展仅在已打开的 Writerside 项目中解析。';

  @override
  String get syntaxReferenceAdmonitionBlockquote => '提示块引用';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      '普通块引用在 Writerside Markdown 中是提示；在普通 Markdown 中仍是普通引用。';

  @override
  String get syntaxReferenceSemanticAdmonitions => '语义提示';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      '普通 Markdown 不会解析这些 Writerside 语义元素。';

  @override
  String get syntaxReferenceCollapsibleHeading => '可折叠标题';

  @override
  String get syntaxReferenceCollapsibleCode => '可折叠代码围栏';

  @override
  String get syntaxReferenceSemanticCollapsibles => '语义可折叠内容';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark 支持可折叠的 chapter、procedure、code-block 和定义列表形式，但不支持完整的 Writerside 目录。';

  @override
  String get syntaxReferenceSemanticCodeBlocks => '数学和图表的语义代码块';

  @override
  String get syntaxReferenceVideo => 'Writerside 视频';

  @override
  String get syntaxReferenceVideoLimitation =>
      '本地视频使用本地 preview-src 图像；托管视频源必须是受支持的 YouTube 或 Vimeo HTTPS URL。';

  @override
  String get exportAsPdf => '导出为 PDF';

  @override
  String get pdfExportDescription => '选择页面布局，生成精美且自包含的 PDF。';

  @override
  String get pdfRemoteImagesNote => '导出过程中不会下载远程图像。有可用的本地图像时将包含它们。';

  @override
  String get pdfPageSize => '页面大小';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => '方向';

  @override
  String get pdfPortrait => '纵向';

  @override
  String get pdfLandscape => '横向';

  @override
  String get pdfMargins => '页边距';

  @override
  String get pdfMarginNarrow => '窄';

  @override
  String get pdfMarginNormal => '普通';

  @override
  String get pdfMarginWide => '宽';

  @override
  String get pdfIncludePageNumbers => '包含页码';

  @override
  String get export => '导出';

  @override
  String get exportFormat => '输出格式';

  @override
  String get exportingPdf => '正在导出 PDF…';

  @override
  String get fileTypePdf => 'PDF 文档';

  @override
  String pdfExported(String fileName) {
    return '已导出 $fileName。';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条警告',
      one: '1 条警告',
    );
    return '$fileName 已导出，包含 $_temp0。';
  }

  @override
  String get pdfExportUnavailable => '缺少 PDF 导出组件。请重新安装 BusyMark 后重试。';

  @override
  String get pdfExportTimedOut => 'PDF 导出耗时过长，已停止。';

  @override
  String get pdfExportFailed => 'BusyMark 无法将此文档导出为 PDF。';

  @override
  String get visualizationRendering => '正在渲染…';

  @override
  String get visualizationStale => '正在显示上次有效的渲染结果';

  @override
  String get visualizationShowSource => '显示源代码';

  @override
  String get visualizationShowRender => '显示渲染结果';

  @override
  String get visualizationFitWidth => '适应宽度';

  @override
  String get visualizationSaveImage => '保存图像';

  @override
  String get visualizationCopyImage => '复制图像';

  @override
  String get visualizationImageCopied => '图像已复制';

  @override
  String get visualizationOpenApiReference => '打开 API 参考';

  @override
  String get visualizationValid => '有效';

  @override
  String get visualizationInvalid => '无效';

  @override
  String get visualizationServers => '服务器';

  @override
  String get visualizationPaths => '路径';

  @override
  String get visualizationOperations => '操作';

  @override
  String get visualizationTags => '标签';

  @override
  String get visualizationNoOperations => '没有匹配的操作';

  @override
  String get visualizationSearchOperations => '搜索操作';

  @override
  String get visualizationRenderFailed => '无法渲染此可视化内容。';

  @override
  String get visualizationRetry => '重试';

  @override
  String visualizationSaved(String fileName) {
    return '已保存 $fileName';
  }

  @override
  String get shortcutExportPdfDescription => '将当前文档或 Writerside 模块导出为 PDF。';

  @override
  String get instances => '实例';

  @override
  String get newInstance => '新建实例';

  @override
  String get newTocLibrary => '新建目录库';

  @override
  String get editInstance => '编辑实例';

  @override
  String get openTocFile => '打开目录文件';

  @override
  String get createInstance => '创建实例';

  @override
  String get createTocLibrary => '创建目录库';

  @override
  String get instanceContent => '内容';

  @override
  String get instanceContentSource => '创建来源';

  @override
  String get emptyInstance => '空实例';

  @override
  String get markdownFiles => '本地 Markdown 文件';

  @override
  String get chooseMarkdownFolder => '选择 Markdown 文件夹';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      '选择包含 Markdown 文件的文件夹。';

  @override
  String get instanceAppearance => '外观';

  @override
  String get instanceColor => '图标颜色';

  @override
  String get instanceVersion => '版本';

  @override
  String instanceVersionInherited(String version) {
    return '此字段为空时，项目版本为 $version。';
  }

  @override
  String get instanceWebPath => 'Web 路径';

  @override
  String get instanceStatus => '状态';

  @override
  String get instanceStatusRelease => '发布';

  @override
  String get instanceStatusEap => '抢先体验';

  @override
  String get instanceStatusDeprecated => '已弃用';

  @override
  String get allowSearchEngineIndexing => '允许搜索引擎建立索引';

  @override
  String get allowSearchEngineIndexingDescription => '允许外部搜索引擎为此输出建立索引。';

  @override
  String get offlineArtifact => '离线构件';

  @override
  String get offlineArtifactDescription => '捆绑资源，使构建的文档可以自包含。';

  @override
  String get instanceOutputSettings => '输出设置';

  @override
  String get markdownImportSource => 'Markdown 源';

  @override
  String get markdownImportFiles => 'Markdown 文件';

  @override
  String get selectNone => '全部取消选择';

  @override
  String markdownFilesFound(int count) {
    return '找到 $count 个 Markdown 文件';
  }

  @override
  String get noMarkdownFilesFound => '在此目录中未找到 Markdown 文件。';

  @override
  String get copyReferencedMedia => '复制引用的媒体';

  @override
  String get copyReferencedMediaDescription => '复制选中文件引用的本地图像和视频，同时保留相对路径。';

  @override
  String get instanceIdRenameWarningTitle => '重命名实例 ID？';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark 将重命名 .tree 文件，并将 Writerside 项目引用从“$oldId”更新为“$newId”。发布脚本不会更改，必须单独更新。';
  }

  @override
  String get renameAndUpdateReferences => '重命名并更新引用';

  @override
  String get tocLibraryDescription => '目录库用于存储可复用的节，不会生成自己的输出。';

  @override
  String get defaultTocLibraryName => '共享目录';

  @override
  String get instanceColorAutomatic => '自动';

  @override
  String get instanceColorBlue => '蓝色';

  @override
  String get instanceColorGreen => '绿色';

  @override
  String get instanceColorOrange => '橙色';

  @override
  String get instanceColorPurple => '紫色';

  @override
  String get instanceColorRed => '红色';

  @override
  String get instanceColorTeal => '青绿色';

  @override
  String get instanceColorYellow => '黄色';

  @override
  String get errorWritersideInstanceNameRequired => '请输入实例名称。';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return '已存在 ID 为“$id”的实例。';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return '实例树已存在：$path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown 源目录不存在：$path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      '请选择至少一个 Markdown 文件进行导入。';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return '选中的源中有一个不是可读取的 Markdown 文件：$path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return '导入将覆盖现有项目文件：$path';
  }

  @override
  String get errorWritersideInstanceFilesChanged => '实例文件已在磁盘上发生变化。请查看后重试。';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark 无法完全回滚实例更改。请在继续前查看这些文件：$paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport => '目录库无法导入 Markdown 主题。';

  @override
  String get errorWritersideInstanceWebPathInvalid => 'Web 路径必须为单行文本。';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside 实例配置无效。请修正其诊断信息后重试。';

  @override
  String get errorWritersideInstanceTemporaryFile => 'BusyMark 无法安全暂存实例更改。';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return '未知的实例状态“$status”。请使用 release、eap 或 deprecated。';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return '实例 ID“$id”被多个树文件使用。';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml 必须包含 <buildprofiles> 根元素。';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name 值“$value”必须为 true 或 false。';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> 元素必须指定实例 ID。';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '树中的 <include> 必须同时指定 from 和 element-id。';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '树中的 <snippet> 必须指定 id。';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      '跨实例目录引用必须同时指定 ref 和 in。';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      '目录元素不能同时指向多个主题、引用、链接或重定向。';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return '树元素 ID“$id”被声明了多次。';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      '实例组文件必须包含 <instance-groups> 根元素。';

  @override
  String get diagnosticWritersideInstanceGroupInvalid => '实例组必须指定非空 ID 和实例列表。';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return '实例组 ID“$id”被声明了多次。';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return '目录包含项“$source#$id”属于外部模块“$origin”，无法在此工作区中展开。';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '已注册树“$source”中不存在树元素“$id”。';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return '树包含项“$source#$id”创建了循环。';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return '实例条件引用了未知组“@$group”。';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return '跨实例引用指向未知实例“$instance”。';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return '主题“$topic”不在被引用的实例“$instance”中。';
  }

  @override
  String get download => '下载';

  @override
  String get exportWritersideAsPdf => '将 Writerside 导出为 PDF';

  @override
  String get writersidePdfContent => '导出内容';

  @override
  String get writersidePdfPage => '页面';

  @override
  String get exportingWritersidePdf => '正在导出 Writerside PDF…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => '本地 Ollama';

  @override
  String get aiDisabled => '已禁用';

  @override
  String get aiExplicitEditingDescription =>
      'AI 编辑需要明确发起。BusyMark 只会将所选提供商对应的显示上下文发送出去，且不会在未经审核的情况下应用建议。';

  @override
  String get aiProvider => 'AI 提供商';

  @override
  String get aiDefaultProvider => '默认提供商';

  @override
  String get aiConfigureProvider => '配置提供商';

  @override
  String get aiChooseProvider => '选择 AI 提供商';

  @override
  String get aiOllamaEndpoint => 'Ollama 端点';

  @override
  String get aiOllamaModel => 'Ollama 模型';

  @override
  String get aiTestConnection => '测试连接';

  @override
  String get aiTestingConnection => '正在测试…';

  @override
  String aiConnectionReady(int count) {
    return '已连接。找到 $count 个已安装模型。';
  }

  @override
  String get aiNoModels => '未选择模型。';

  @override
  String get aiConnectionFailed => 'BusyMark 无法验证 AI 文本生成。';

  @override
  String get aiConfigureFirst => '请先在设置 → AI 中启用 AI 提供商并验证模型。';

  @override
  String get aiEditWithAi => '使用 AI 编辑';

  @override
  String get aiRefineWithAi => '使用 AI 优化';

  @override
  String get aiInstruction => '指令';

  @override
  String get aiChangeTarget => '可更改内容';

  @override
  String get aiSharedContext => '与 AI 共享的上下文';

  @override
  String get aiTargetSelection => '选中的内容';

  @override
  String get aiTargetInsertAfterBlock => '插入到当前块之后';

  @override
  String get aiTargetCurrentBlock => '当前块';

  @override
  String get aiTargetCurrentSection => '当前节';

  @override
  String get aiTargetCompleteDocument => '完整文档';

  @override
  String get aiContextNone => '没有文档上下文';

  @override
  String get aiContextSelection => '选中的内容';

  @override
  String get aiContextCurrentBlock => '当前块';

  @override
  String get aiContextCurrentSection => '当前节';

  @override
  String get aiContextCompleteDocument => '完整文档';

  @override
  String get aiGenerating => '正在生成建议…';

  @override
  String get aiProposal => 'AI 建议';

  @override
  String get aiGenerateProposal => '生成建议';

  @override
  String aiContextDisclosure(int count) {
    return '所选提供商将接收显示上下文中的 $count 个字符。';
  }

  @override
  String get aiOriginal => '原始内容';

  @override
  String get aiSuggested => '建议内容';

  @override
  String get aiApplyProposal => '应用建议';

  @override
  String aiTokenUsage(int input, int output) {
    return '输入 token：$input · 输出 token：$output';
  }

  @override
  String get aiStaleProposal => '生成此建议期间文档发生了变化。请重新执行操作。';

  @override
  String get gitAiStagedChangesChanged => '生成此提交消息期间，已暂存的更改发生了变化。请重新执行操作。';

  @override
  String get aiViewContext => '查看已发送的上下文';

  @override
  String get aiReviewExactContent => '查看确切内容';

  @override
  String get aiContentToChange => '要更改的内容';

  @override
  String get aiContentSentToAi => '发送给 AI 的内容';

  @override
  String get aiApiKey => 'API 密钥';

  @override
  String get aiApiKeyStoredHint => '密钥已存储在系统凭据存储中';

  @override
  String get aiApiKeyEnterHint => '输入提供商 API 密钥';

  @override
  String get aiReplaceApiKey => '替换 API 密钥';

  @override
  String get aiSaveApiKey => '安全保存 API 密钥';

  @override
  String get aiRemoveApiKey => '移除已保存的 API 密钥';

  @override
  String get aiCredentialSaved => 'API 密钥已保存到系统凭据存储中。';

  @override
  String get aiCredentialRemoved => '已移除保存的 API 密钥。';

  @override
  String get aiModelRouting => '模型路由';

  @override
  String get aiAutomaticRouting => '按任务自动选择';

  @override
  String get aiFixedModelRouting => '使用选中的模型';

  @override
  String get aiPreferredModel => '首选模型';

  @override
  String get aiModel => '模型';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests 个请求 · $input 个输入 token · $output 个输出 token';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '将内容发送给 $provider？';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '启用 $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      '只会发送每个 AI 审核对话框中显示的内容。请求不保存状态，建议需要审核，API 密钥存储在 Linux 系统凭据存储中。';

  @override
  String aiCloudConsentRequired(String provider) {
    return '请先在设置 → AI 中确认与 $provider 共享数据。';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '已通过 $model 验证生成能力。有 $count 个兼容模型可用。';
  }

  @override
  String get aiColdStartObserved => '检测到本地模型冷启动。';

  @override
  String get aiNoCompatibleModels => '没有可用的兼容文本生成模型。';

  @override
  String get aiEnableProvider => '请先启用 AI 提供商。';

  @override
  String get aiDraftCommitMessage => '起草提交消息';

  @override
  String get aiDrafting => '正在起草…';

  @override
  String get aiDraftWithAi => '使用 AI 起草';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '标题级别 $level 跟在级别 $previousLevel 之后；请检查节的嵌套结构。';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText => '链接文本为空；请提供能描述其用途的可访问名称。';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return '请检查链接文本“$text”是否在上下文中描述了其用途。';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader => '表头单元格必须标识其列；请补全每个空表头。';

  @override
  String get mathRenderFailed => '无法渲染数学表达式。';

  @override
  String get inlineMath => '行内数学';

  @override
  String get displayMath => '显示数学';

  @override
  String get goToDeclaration => '转到声明';

  @override
  String get findUsages => '查找用法';

  @override
  String get cannotRenameSymbol => '无法安全地重命名此符号。请检查名称并刷新引用，然后重试。';

  @override
  String get renameTopicFileInstead => '主题 ID 来自其文件名。请在目录或“文件”侧边栏中使用“重命名主题文件”。';

  @override
  String get keyboardLayout => '键盘布局';

  @override
  String get diagnosticWritersideUnsupported => '不支持或格式错误的内容将显示为源代码。';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return '无法解析源“$reference”：$reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return '此实例中无法使用链接目标：$destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return '无效的 Writerside 标记：$element，$attribute。$reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      '请使用 <llms-txt>true</llms-txt> 或 <llms-txt>false</llms-txt>；不再支持 single-file。';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '无法解析 $kind：$reference';
  }

  @override
  String get exportAsHtml => '导出为 HTML…';

  @override
  String get fileTypeHtml => 'HTML 文档';

  @override
  String get exportingHtml => '正在导出 HTML…';

  @override
  String get htmlExported => 'HTML 导出完成';

  @override
  String get htmlExportFailed => 'HTML 导出失败';

  @override
  String get htmlKeepAssetsTogether => '复制导出结果时，请将 HTML 文件及其配套资源文件夹放在一起。';

  @override
  String get htmlInstanceDescription => '将一个实例导出为相互链接的离线页面。请选择专用输出文件夹的名称。';

  @override
  String get htmlInstance => '实例';

  @override
  String get htmlOwnedDirectoryOnly =>
      '只能替换由 BusyMark HTML 导出创建的文件夹。已修改或无关的文件将被保留。';

  @override
  String get showInFolder => '在文件夹中显示';

  @override
  String sortTableColumn(String column) {
    return '排序 $column';
  }

  @override
  String get exportReset => '恢复默认值';

  @override
  String get exportToc => '包含目录';

  @override
  String get exportTocDepth => '目录深度';

  @override
  String get exportNumberHeadings => '为标题编号';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => '自定义';

  @override
  String get exportPageWidth => '页面宽度（mm）';

  @override
  String get exportPageHeight => '页面高度（mm）';

  @override
  String get exportMarginTop => '上边距（mm）';

  @override
  String get exportMarginRight => '右边距（mm）';

  @override
  String get exportMarginBottom => '下边距（mm）';

  @override
  String get exportMarginLeft => '左边距（mm）';

  @override
  String get exportTypography => '字体';

  @override
  String get exportSans => '无衬线';

  @override
  String get exportSerif => '衬线';

  @override
  String get exportBodySize => '正文字号';

  @override
  String get exportCodeSize => '代码字号';

  @override
  String get exportRunningText => '页眉和页脚';

  @override
  String get exportHeader => '页眉';

  @override
  String get exportFooter => '页脚';

  @override
  String get exportNone => '无';

  @override
  String get exportDocumentTitle => '文档标题';

  @override
  String get exportBottomLeft => '左下';

  @override
  String get exportBottomCenter => '底部居中';

  @override
  String get exportBottomRight => '右下';

  @override
  String get exportFirstPage => '在首页显示页眉和页脚';

  @override
  String get exportAccent => '强调色／链接颜色';

  @override
  String get exportTheme => '主题';

  @override
  String get exportAutomatic => '自动';

  @override
  String get exportLayout => '布局';

  @override
  String get exportContentWidth => '内容最大宽度';

  @override
  String get exportOutput => '输出';

  @override
  String get exportPackaging => '打包方式';

  @override
  String get exportSingleFile => '单个 HTML 文件';

  @override
  String get exportAssetsDirectory => 'HTML + 资源目录';

  @override
  String get exportCustomCss => '自定义样式表…';

  @override
  String get exportRemoveCss => '移除自定义样式表';

  @override
  String get exportCssNote =>
      '可选用 UTF-8 CSS 文件（最大 256 KiB）。不接受导入、资源 URL、可执行或转义 CSS。样式在 BusyMark 样式表之后应用。不会获取远程资源。';

  @override
  String get exportSitePackagingNote =>
      'Writerside 保留独立且相互链接的主题页面。单文件模式将资源嵌入每个页面。';

  @override
  String get exportInvalidGeometry => '扣除边距后，请至少保留 20 mm 的内容宽度和高度。';

  @override
  String get exportInvalidColor => '请输入 #RRGGBB 格式的颜色。';

  @override
  String get exportInvalidCss =>
      '请选择可读取的 UTF-8 .css 文件（最大 256 KiB），不得包含导入、资源 URL、HTML、可执行或转义 CSS。';

  @override
  String get clipboardHistory => '剪贴板历史';

  @override
  String get clipboardHistoryDescription => '打开会话本地剪贴板历史。';

  @override
  String get clipboardCurrent => '当前剪贴板';

  @override
  String get clipboardCurrentExternal => '来自其他应用程序的当前剪贴板';

  @override
  String clipboardDestination(String name) {
    return '粘贴到 $name';
  }

  @override
  String get clipboardSessionOnly => '仅存储在本次 BusyMark 会话中。';

  @override
  String get clipboardNoItems => '剪贴板历史为空。';

  @override
  String get clipboardDisabled => '剪贴板历史集合在设置中已禁用。';

  @override
  String get clipboardUnavailable => '当前剪贴板内容不可用或不受支持。';

  @override
  String get clipboardTooLarge => '此剪贴板内容过大，无法保留。';

  @override
  String get clipboardPastePlainText => '作为纯文本粘贴';

  @override
  String get clipboardClearAll => '清除剪贴板历史';

  @override
  String get clipboardEntryText => '文本';

  @override
  String get clipboardEntryRichText => '丰富文本';

  @override
  String get clipboardEntryImage => '图片';

  @override
  String clipboardOrigin(String name) {
    return '复制自 $name';
  }

  @override
  String get localHistory => '本地历史';

  @override
  String get localHistoryEllipsis => '本地历史…';

  @override
  String get localHistoryDescription => '显示当前文档的已保存和自动本地修订。';

  @override
  String get findLocalHistoryEllipsis => '在本地历史中查找…';

  @override
  String get findLocalHistoryDescription => '搜索本地历史文档和修订内容。';

  @override
  String get localHistoryNoDocuments => '尚无文档具有本地历史。';

  @override
  String get localHistoryNoRevisions => '此文档没有本地历史修订。';

  @override
  String get localHistorySelectedRevision => '已选择的修订';

  @override
  String get localHistoryCurrentEditor => '当前编辑器内容';

  @override
  String get localHistoryCurrentDisk => '磁盘上的当前内容';

  @override
  String get localHistoryMissingFile => '原始文件丢失。';

  @override
  String get localHistoryRestoreRevision => '恢复版本';

  @override
  String get localHistoryRestoreOriginalLocation => '恢复到原始位置';

  @override
  String get localHistoryRestoreNewLocation => '恢复到新位置…';

  @override
  String get localHistoryRestoreChange => '恢复更改';

  @override
  String get localHistoryRestoreUnavailable => '无法恢复此更改，因为比较已过时。';

  @override
  String get localHistoryComparisonSimplified => '此大型比较已简化。 无法恢复单个更改。';

  @override
  String localHistoryOlderChange(String text) {
    return '较旧的版本更改： $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return '当前内容更改： $text';
  }

  @override
  String get localHistoryDeleted => '已删除';

  @override
  String get localHistoryUntitled => '未命名';

  @override
  String get localHistoryClearDocument => '清除此文档的历史';

  @override
  String get localHistoryClearAll => '清除所有本地历史';

  @override
  String get localHistoryClearDocumentTitle => '清除文档历史？';

  @override
  String get localHistoryClearAllTitle => '清除所有本地历史？';

  @override
  String get localHistoryClearConfirmation => '这将永久删除存储的修订。 此操作无法撤销。';

  @override
  String get localHistoryWarningIndexRebuilt => '本地历史索引已损坏并从完整修订中重建。';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return '此本地历史存储使用不受支持的格式 $version。';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return '本地历史不可用： $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      '录音已禁用或此路径已排除。 在恢复之前重新启用录音。';

  @override
  String localHistoryWarningPathChange(String detail) {
    return '无法记录本地历史路径更改： $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return '本地历史记录无法保留已删除的路径： $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing => '所选版本丢失或损坏。';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return '无法读取所选版本： $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return '本地历史记录无法捕获此版本： $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason・$timestamp';
  }

  @override
  String get localHistoryReasonBaseline => '基线';

  @override
  String get localHistoryReasonSaved => '已保存';

  @override
  String get localHistoryReasonAutomaticCheckpoint => '自动检查点';

  @override
  String get localHistoryReasonBeforeReload => '在重新加载之前';

  @override
  String get localHistoryReasonBeforeDiscard => '在丢弃之前';

  @override
  String get localHistoryReasonBeforeRestore => '恢复前';

  @override
  String get localHistoryReasonBeforeDelete => '删除前';

  @override
  String get localHistoryReasonExternalChange => '外部修改';

  @override
  String get settingsHistory => '历史记录';

  @override
  String get settingsClipboardHistoryTitle => '收集剪贴板历史';

  @override
  String get settingsClipboardHistoryDescription =>
      '只保留本次 BusyMark 会话中已复制并成功粘贴的内容。';

  @override
  String get settingsLocalHistoryTitle => '记录本地历史';

  @override
  String get settingsLocalHistoryDescription => '将文档修订存储在此设备上，以便恢复和比较。';

  @override
  String get settingsHistoryCheckpoint => '自动检查点间隔';

  @override
  String get settingsHistoryRetention => '保留期限';

  @override
  String get settingsHistoryStorage => '最大存储';

  @override
  String get settingsHistoryExcludedPaths => '排除路径';

  @override
  String get settingsHistoryExcludedPathsHint => '每行一个绝对路径';

  @override
  String settingsSecondsValue(int value) {
    return '$value 秒';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value 天';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => '拼写检查';

  @override
  String get automaticSpelling => '自动检查拼写';

  @override
  String get defaultSpellingLanguage => '默认拼写语言';

  @override
  String get projectSpellingLanguage => '项目拼写检查语言';

  @override
  String get chooseSpellingLanguage => '选择拼写语言';

  @override
  String get spellingLanguageUnsetStatus => '语言…';

  @override
  String get spellingOffStatus => '拼写检查已关闭';

  @override
  String get checkSpelling => '检查拼写';

  @override
  String get ignoreSpellingOnce => '忽略一次';

  @override
  String get ignoreSpellingDocument => '在此文档中全部忽略';

  @override
  String get addPersonalSpellingWord => '添加到个人词典';

  @override
  String get addProjectSpellingWord => '添加到项目词典';

  @override
  String get inheritSpellingLanguage => '使用项目或应用语言';

  @override
  String get disableDocumentSpelling => '不检查拼写';

  @override
  String get importSpellingDictionary => '导入词典';

  @override
  String get personalSpellingDictionary => '个人词典';

  @override
  String get projectSpellingDictionary => '项目词典';

  @override
  String get noSpellingErrors => '没有拼写错误';

  @override
  String get noSpellingSuggestions => '没有拼写建议';

  @override
  String get spellingWordCheckFailed => '无法检查此单词';

  @override
  String get spellingCheckFailed => '拼写检查失败';

  @override
  String get spellingSettingsLoadFailed => '无法加载拼写检查设置';

  @override
  String get retrySpellingSettings => '重试加载拼写检查设置';

  @override
  String get spellingCheckIncomplete => '拼写检查未完成';

  @override
  String get spellingDictionaryNotInstalled => '尚未安装词典';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return '尚未安装 $dictionary 词典';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return '未安装 · $size';
  }

  @override
  String get spellingDictionaryInstalled => '已安装';

  @override
  String get installSpellingDictionary => '安装词典';

  @override
  String get removeSpellingDictionary => '移除词典';

  @override
  String get cancelSpellingDictionaryInstall => '取消下载词典';

  @override
  String get retrySpellingDictionaryInstall => '重试安装词典';

  @override
  String spellingDictionaryDownloading(String size) {
    return '正在下载 $size…';
  }

  @override
  String get spellingDictionaryValidating => '正在验证词典…';

  @override
  String get spellingDictionaryInstallFailed => '词典安装失败 — 选择以重试';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '要安装 $dictionary（$size）吗？安装后，在移除前都可离线使用。';
  }

  @override
  String get spellingDictionaryUnavailable => '词典不可用';

  @override
  String get spellingChecking => '正在检查拼写…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field：请输入 $minimum 到 $maximum 之间的数字。';
  }

  @override
  String get spellingDictionaryRecoveryConflict => '拼写词典已被外部更改。已保留恢复副本。';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => '连接';

  @override
  String get nextcloudReconnect => '重新连接';

  @override
  String get nextcloudDisconnect => '断开连接';

  @override
  String get nextcloudServer => '服务器地址';

  @override
  String get nextcloudSignInBrowser => '请在浏览器中完成登录。';

  @override
  String get nextcloudFavorites => '收藏';

  @override
  String get nextcloudNewNote => '新建笔记';

  @override
  String get nextcloudSavedLocally => '已保存到本地 · 等待同步';

  @override
  String get nextcloudSyncing => '正在同步';

  @override
  String get nextcloudSynced => '已同步';

  @override
  String get nextcloudOffline => '离线';

  @override
  String get nextcloudLocked => '被服务器锁定';

  @override
  String get nextcloudReconnectRequired => '需要重新连接';

  @override
  String get nextcloudCreationUncertain => '创建结果不确定';

  @override
  String get nextcloudReadOnly => '只读';

  @override
  String get nextcloudTakeRemote => '使用服务器版本';

  @override
  String get nextcloudMerge => '合并';

  @override
  String get nextcloudDeleteNote => '删除笔记？';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Nextcloud Notes不支持工作区整体替换。请在每条笔记中替换。';

  @override
  String get nextcloudSaveLocalCopy => '保存本地副本…';

  @override
  String get nextcloudDisconnectWarning =>
      '移除此账户将删除此设备上缓存的笔记和待同步的更改。请先同步，将工作保留在服务器上。';

  @override
  String get nextcloudAttachmentRetryWarning => '如果上次上传成功，重试可能会在服务器上留下未使用的附件。';

  @override
  String get nextcloudAttachmentReference => '服务器上的附件引用';

  @override
  String get nextcloudAddAttachment => '添加附件…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      '删除此附件后，笔记中指向它的链接将不可用。保留的数据可通过本地历史记录恢复。';

  @override
  String get nextcloudChooseConflictingAttributes => '为每个冲突属性选择一个值。';

  @override
  String get nextcloudUseServerNote => '使用此服务器笔记';

  @override
  String get nextcloudUseServerNoteExplanation =>
      '将此草稿关联到选定的服务器笔记，然后同步保留的本地更改。请求匹配并不能确认笔记由谁创建。';

  @override
  String get nextcloudExactCandidate => '与请求完全匹配；身份尚未确认。';

  @override
  String get nextcloudPossibleCandidate => '可能与规范化后的请求匹配；身份尚未确认。';

  @override
  String get nextcloudSelectCandidate => '选择要检查的服务器笔记';

  @override
  String get nextcloudCreateSeparate => '创建独立笔记';

  @override
  String get nextcloudCreateSeparateWarning =>
      '首次请求可能已在服务器上创建笔记。此操作将使用保留的本地工作创建独立笔记。不会删除任何疑似重复的笔记。';

  @override
  String get wsSemanticFormats => '语义格式';

  @override
  String get wsUiControl => '界面控件';

  @override
  String get wsFilePath => '文件 / 路径';

  @override
  String get wsUiPath => '界面路径';

  @override
  String get wsDefinitionList => '定义列表';

  @override
  String get wsIncludeContent => '包含可复用内容';

  @override
  String get wsVariableReference => '变量引用';

  @override
  String get wsConvertList => '将列表转换为过程';

  @override
  String get wsElementProperties => '元素属性';

  @override
  String get wsTopicProperties => '主题属性';

  @override
  String get wsCollapsible => '可折叠';

  @override
  String get wsPublishedState => '发布时的初始状态';

  @override
  String get wsExpanded => '展开';

  @override
  String get wsCollapsed => '折叠';

  @override
  String get wsCollapsedTitle => '折叠标题';

  @override
  String get wsTerm => '术语';

  @override
  String get wsListLayout => '列表布局';

  @override
  String get wsSyncGroup => '同步组';

  @override
  String get wsTabKey => '选项卡键';

  @override
  String get wsSwitcherLabel => '切换器标签';

  @override
  String get wsNavigationElements => '导航元素';

  @override
  String get wsNavigationDepth => '导航深度';

  @override
  String get wsAddItem => '添加项目';

  @override
  String get wsStep => '步骤';

  @override
  String get wsPropertyInvalid => '属性值无效';

  @override
  String get wsFilter => '筛选器';

  @override
  String get wsIdentifier => '元素 ID';

  @override
  String get wsTldr => '摘要 (TLDR)';

  @override
  String get wsFullLayout => '全宽';

  @override
  String get wsMediumLayout => '中等 (1:2)';

  @override
  String get wsNarrowLayout => '窄术语列';

  @override
  String get wsTitle => '标题';

  @override
  String get wsSwitcherKey => '切换键';

  @override
  String get nextcloudServerSettings => '服务器 Notes 设置';

  @override
  String get nextcloudNotesPath => '笔记文件夹路径';

  @override
  String get nextcloudFileSuffix => '新笔记的文件后缀';

  @override
  String get nextcloudServerSettingsExplanation =>
      '这些服务器 Notes 设置会影响其他客户端。更改路径不会移动文件；更改后缀不会重命名现有笔记。';

  @override
  String get nextcloudSettingsSaved => '服务器设置已保存';

  @override
  String get nextcloudSettingsNormalized => '已保存服务器规范化后的值';

  @override
  String get nextcloudPendingUpload => '附件等待上传';

  @override
  String nextcloudServerCheck(String time) {
    return '上次服务器检查：$time';
  }

  @override
  String get nextcloudSettingsLoading => '正在加载服务器设置';

  @override
  String get nextcloudSettingsSaving => '正在保存服务器设置';

  @override
  String get nextcloudPreviousLocalEdit => '先前的本地编辑';

  @override
  String get nextcloudUsePreviousEdit => '使用先前编辑';

  @override
  String get quickOpen => '快速打开';

  @override
  String get notesAll => '所有笔记';

  @override
  String get notesUncategorized => '未分类';

  @override
  String get notesRecovery => '恢复';

  @override
  String get notesRecentlyEdited => '最近编辑';

  @override
  String get notesOldestEdited => '最早编辑';

  @override
  String get notesTitleAscending => '标题升序';

  @override
  String get notesTitleDescending => '标题降序';

  @override
  String get notesMove => '移至分类';

  @override
  String get notesRemoveFavorite => '取消收藏';

  @override
  String get notesOffline => '设为离线可用';

  @override
  String get notesOfflineRemove => '移除离线保留要求';

  @override
  String get notesIndexing => '正在索引笔记…';

  @override
  String get notesSearchHelp => '词项使用“与”组合。可使用\"引号短语\"、title: 和 category:。';

  @override
  String get notesSourceLocation => '源文件位置';

  @override
  String get notesRecoveryHelp => '仅包括保留的本地笔记和本地历史。无法访问服务器回收站或历史。';

  @override
  String get notesImport => '导入笔记';

  @override
  String get notesExport => '导出笔记';

  @override
  String get notesImportDistinct => '导入为独立笔记';

  @override
  String get notesAvailableOffline => '离线可用';

  @override
  String get notesIncomplete => '不完整';

  @override
  String get notesSelected => '已选笔记';

  @override
  String get notesNoHistory => '没有保留的版本。历史可能已禁用、过期或清除。';

  @override
  String get notesTextAvailable => '文本已在本地可用';

  @override
  String get notesLocalVersion => '本地工作版本';

  @override
  String get notesAttachments => '附件';

  @override
  String get notesSkipped => '已跳过';

  @override
  String get notesFailed => '失败';

  @override
  String get notesCompleted => '已完成';

  @override
  String get notesImportNew => '开始新导入';

  @override
  String get notesImportResume => '继续中断的导入';

  @override
  String get notesImportAlreadyImported => '已在此操作中导入';

  @override
  String get references => '引用';

  @override
  String get referenceIncoming => '传入';

  @override
  String get referenceOutgoing => '传出';

  @override
  String get referenceChooseTarget => '选择链接目标';

  @override
  String get referenceWholeDocument => '整个文档';

  @override
  String get referenceSourceLocation => '源位置';

  @override
  String get referenceTargetLocation => '目标位置';

  @override
  String get referenceResolved => '已解析';

  @override
  String get referenceMissing => '缺失';

  @override
  String get referenceAmbiguous => '不明确';

  @override
  String get referenceUnavailable => '当前上下文中不可用';

  @override
  String get referenceUnsupported => '不支持';

  @override
  String get referenceNoPortableId => '此目标没有经过验证的可移植笔记网址。';

  @override
  String get wsIncludeLines => '包含行';

  @override
  String get wsIncludeSymbol => '包含符号';

  @override
  String get wsEmphasizeLines => '突出显示已显示的行';

  @override
  String get wsPropertiesReadOnly => '此视图中的属性为只读。';

  @override
  String get wsPropertiesProtected => '此元素受保护。请编辑其源代码。';

  @override
  String get wsPropertiesConflict => '文档或元素已更改。请还原草稿并重新选择。';

  @override
  String get wsPropertiesUnresolved => '目前无法解析此引用。';

  @override
  String get wsUseDefault => '使用默认值';

  @override
  String get wsPropertiesSelection => '请选择单个元素。';

  @override
  String get wsImageDisplay => '图像显示';

  @override
  String get wsImageThumbnail => '可点击缩略图';

  @override
  String get wsEnabled => '已启用';

  @override
  String get wsDisabled => '已禁用';

  @override
  String get wsWidth => '宽度';

  @override
  String get wsHeight => '高度';

  @override
  String get wsPropertiesInactive => '未启用发布折叠时，此属性无效。';

  @override
  String get wsNavigationAll => '所有有标题的元素';

  @override
  String get wsNavigationNone => '无导航';

  @override
  String get wsNavigationCustom => '自定义导航';

  @override
  String get wsTitleOverride => '覆盖标题';

  @override
  String get wsCompactLayout => '紧凑';

  @override
  String get wsWideLayout => '宽';

  @override
  String get wsCodeSourceConflict =>
      '设置 src 前，请移走或删除此代码块中编写的代码。Writerside 不接受带有源引用的非空代码块。';

  @override
  String get wsInherited => '从列表继承';

  @override
  String get wsExternalImageSize => 'Writerside 无法可靠地调整外部托管图片的尺寸。可以查看和移除已有尺寸。';

  @override
  String get wsPropertiesNotSerialized => '此更改未写入源文本。草稿已保留。';

  @override
  String get wsListItem => '列表项';

  @override
  String get wsSourceFile => '源文件';

  @override
  String get wsLinkTarget => '链接目标';

  @override
  String get wsPreviewImage => '预览图像';

  @override
  String get wsIncludedElement => '包含的元素';

  @override
  String get wsHelpModule => '帮助模块';

  @override
  String get wsActionId => '操作 ID';

  @override
  String get wsKeymapHelpInstance => '键位映射帮助实例';

  @override
  String get wsShowInSource => '在源代码中显示';

  @override
  String get wsOriginElement => '元素覆盖值';

  @override
  String get wsOriginAncestor => '父元素';

  @override
  String get wsOriginModule => '模块默认值';

  @override
  String get wsOriginBuiltIn => '内置默认值';

  @override
  String get wsOriginUnresolved => '未解析';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return '有效值：$value — $origin';
  }

  @override
  String get wsElementSelector => '元素';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return '生成值：$anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return '默认值：$value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return '默认值：$value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return '解析值：$value';
  }

  @override
  String get wsPropertyUnresolved => '未解析';

  @override
  String get wsModule => '模块';

  @override
  String get wsParent => '父元素';

  @override
  String get wsListType => '列表类型';

  @override
  String get wsStartingNumber => '起始编号';

  @override
  String get wsListSorting => '排序';

  @override
  String get wsLetteredList => '字母列表';

  @override
  String get wsCheckboxList => '复选框列表';

  @override
  String get wsMarkerlessList => '无标记列表';

  @override
  String get wsAscending => '升序';

  @override
  String get wsDescending => '降序';

  @override
  String get wsNoSorting => '不排序';

  @override
  String get wsAsWritten => '按原文';

  @override
  String get wsSentenceCase => '句首大写';

  @override
  String get wsTitleCase => '标题大写';

  @override
  String get wsLowerCase => '小写';

  @override
  String get wsUpperCase => '大写';

  @override
  String get wsNativeMarkers => 'Markdown 标记';

  @override
  String wsListMarkerStart(String number) {
    return '起始标记：$number';
  }

  @override
  String wsListLevel(String level) {
    return '层级 $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      '固定版本的构建器会忽略模块的 <caps> 规则。请使用本地 caps 属性或 default-property。';

  @override
  String get wsInsertElements => '插入元素';

  @override
  String get wsAdmonitionsAndQuotes => '提示和引用';

  @override
  String get wsSemanticText => '语义文本';

  @override
  String get wsPropertiesUnavailable => '所检查的元素不可用。请检查一个元素以继续。';

  @override
  String get searchDocumentsCategory => '文档';

  @override
  String get searchTopicsCategory => '主题';

  @override
  String get searchCurrentDocument => '当前文档';

  @override
  String get searchCurrentWorkspace => '当前工作区';

  @override
  String get browseNotes => '浏览笔记';

  @override
  String get searchActionsCommand => '搜索操作';

  @override
  String get searchDocumentsCommand => '搜索文档';

  @override
  String get searchTopicsCommand => '搜索主题';

  @override
  String get searchRecentCommand => '搜索最近项目';

  @override
  String get searchResourceUnavailable => '此资源不可用。';

  @override
  String get notesSync => '同步笔记';

  @override
  String get searchInWorkspace => '在工作区中搜索';

  @override
  String get searchCategory => '搜索类别';

  @override
  String get clearHistorySearchScope => '搜索文档历史记录';

  @override
  String get searchInDocument => '在文档中搜索';

  @override
  String get searchDocumentHint => '搜索此文档…';

  @override
  String get searchWorkspaceHint => '搜索此工作区…';

  @override
  String get searchOutlineHint => '搜索标题…';

  @override
  String get searchHistoryHint => '搜索本地历史记录…';

  @override
  String get searchEnterText => '输入要搜索的文本';

  @override
  String get searchAccountUnavailable => '账户不可用';

  @override
  String get searchDocumentsHint => '搜索文档…';

  @override
  String get searchTopicsHint => '搜索主题…';

  @override
  String get searchRecentHint => '搜索最近项目…';

  @override
  String get searchActionsHint => '搜索操作…';

  @override
  String get searchRequiresNotesWorkspace => '需要笔记工作区';

  @override
  String get searchSidebarLabel => '搜索：';

  @override
  String get searchDocumentTextCategory => '文档文本';

  @override
  String get searchWorkspaceTextCategory => '工作区文本';

  @override
  String get searchHeadingsCategory => '标题';

  @override
  String get shortcutUnassigned => '未分配';

  @override
  String get shortcutPressKeys => '请按下组合键…';

  @override
  String get shortcutRecord => '录制快捷键';

  @override
  String get shortcutRestoreAll => '恢复所有默认设置';

  @override
  String get shortcutRestoreAllQuestion => '恢复所有操作的默认快捷键？自定义分配将被移除。';

  @override
  String get shortcutSaveFailed => '快捷键已生效，但无法保存。请重试保存以便重启后保留。';

  @override
  String get shortcutRetry => '重试保存';

  @override
  String get shortcutChanged => '分配已更改。请检查当前快捷键并重试。';

  @override
  String get shortcutInvalid => '无法在此上下文中分配此组合键。';

  @override
  String get shortcutSystemWarning => '桌面可能正在使用此组合键。BusyMark 无法覆盖系统快捷键。';

  @override
  String get shortcutConflicts => '此快捷键与以下操作冲突：';

  @override
  String get shortcutRemove => '移除分配';

  @override
  String get shortcutRestoreDefault => '恢复默认设置';

  @override
  String get shortcutAssign => '分配';

  @override
  String get shortcutReassign => '重新分配';

  @override
  String get shortcutContextApplication => '应用程序';

  @override
  String get shortcutContextDocument => '文档视图';

  @override
  String get shortcutContextEditor => '编辑器和源码';

  @override
  String get shortcutContextWritersideSource => 'Writerside 源码';

  @override
  String get shortcutContextWorkspace => '工作区导航';

  @override
  String get shortcutContextTree => '侧栏树';

  @override
  String get searchHeadingsCommand => '搜索标题';

  @override
  String get shortcutFixed => '由编辑器管理，无法配置。';

  @override
  String get shortcutDefaultConflict => '默认快捷键与自定义分配冲突。';

  @override
  String get shortcutCurrentBinding => '当前快捷键';

  @override
  String get shortcutProposedBinding => '拟用快捷键';

  @override
  String get notesActions => '笔记操作';

  @override
  String get noteActions => '此笔记的操作';

  @override
  String get noteProperties => '笔记属性';

  @override
  String get notesExportAll => '导出笔记 · 所有笔记…';

  @override
  String get notesExportCategory => '导出笔记 · 类别…';

  @override
  String get notesOfflineAll => '设为离线可用 · 所有笔记';

  @override
  String get notesOfflineCategory => '设为离线可用 · 类别';

  @override
  String get notesOfflineRemoveAll => '移除离线保留要求 · 所有笔记';

  @override
  String get notesOfflineRemoveCategory => '移除离线保留要求 · 类别';

  @override
  String get notesOfflinePause => '暂停下载';

  @override
  String get notesOfflineResume => '继续下载';

  @override
  String get notesOfflineKeep => '设为离线可用';

  @override
  String get notesOfflineRetentionHelp => '移除此保留要求不会删除现有缓存。分类或账户的要求仍可能保留此笔记。';

  @override
  String get notesOfflineBroader => '此笔记也因分类或账户的要求而被保留。';

  @override
  String get notesOfflineExternal => '外部媒体需要网络连接。BusyMark 只保留笔记文本和托管附件。';

  @override
  String get notesEmptyAll => '还没有笔记。请新建一条笔记。';

  @override
  String get notesEmptyFavorites => '没有收藏的笔记。';

  @override
  String get notesEmptyCategory => '此分类中没有笔记。';

  @override
  String get notesEmptyUncategorized => '没有未分类笔记。';

  @override
  String get notesEmptyRecovery => '没有可恢复的本地保留笔记。';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · 失败. 重试';

  @override
  String get notesOperationFailed => '无法完成操作。草稿已保留。请检查保存状态和冲突后重试。';

  @override
  String get notesInspectionFailed => '附件 · 失败. 重试';

  @override
  String get notesStartingConnection => '正在连接 Nextcloud…';

  @override
  String get notesVerifyingConnection => '正在验证笔记访问权限…';

  @override
  String get notesCancellingConnection => '正在取消登录并清理…';

  @override
  String get notesRemovingConnection => '正在移除本地账户…';

  @override
  String get notesRemovedWarning =>
      '本地 Nextcloud 账户已移除，但无法确认应用密码已撤销。请在 Nextcloud 安全设置中移除 BusyMark 的应用密码。';

  @override
  String get notesBuffersNotSaved =>
      '无法将所有打开的笔记保存到本地。请在工作区检查保存、冲突或规范化处理。待处理的本地更改可能仍需与 Nextcloud 同步。';

  @override
  String get notesSettingsLeave => '离开前保存 Nextcloud 设置更改吗？';

  @override
  String get notesSettingsLeaveHelp => '服务器 Notes 设置 · 未保存的更改';

  @override
  String get notesSettingsReload => '重新加载服务器设置…';

  @override
  String get notesSettingsReloadHelp => '重新加载会用 Nextcloud 当前设置替换草稿。放弃草稿并重新加载吗？';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud 已接受设置，但刷新笔记失败。显示的是服务器确认的设置值。请从笔记界面重试刷新。';

  @override
  String get notesUnavailable => '离线 · 文本已在本地可用 · 已保存到本地 · 等待同步';

  @override
  String get notesStorageFull => 'Nextcloud 存储空间已满。请释放服务器空间后重试。';

  @override
  String get notesRejected => 'Nextcloud 拒绝了此更改。请检查笔记并保存本地副本后重试。';

  @override
  String get notesThrottled => 'Nextcloud 要求稍候。同步将在重试期限后继续。';

  @override
  String get notesRecoveryRequired => '冲突 · 比较';

  @override
  String get notesScanning => '正在扫描文件…';

  @override
  String get notesCancelling => '正在取消…等待当前操作结束。';

  @override
  String get notesCancelled => '已取消';

  @override
  String get notesPartial => '部分完成';

  @override
  String get notesTransferFailed => '失败. 重试';

  @override
  String get notesImportPartialHelp => '之前的项目可能已保存在本地。请继续本次导入，以免创建重复笔记。';

  @override
  String get notesNotStarted => '尚未开始';

  @override
  String get notesCreated => '已创建';

  @override
  String get notesRemoteDeleteUnavailable => '服务器地址 · 不支持 · 删除 · 附件';

  @override
  String get notesCurrentText => '当前保留的文本';

  @override
  String get notesRecovering => '正在恢复为新笔记…';

  @override
  String get notesReadOnlyHelp => '只读 · 收藏 · 保存本地副本…';

  @override
  String get notesSort => '笔记排序';

  @override
  String get notesPathRelative => '笔记文件夹路径相对于您的 Nextcloud 存储空间。';

  @override
  String get notesSettingsStale => 'Nextcloud 上的设置已更改。请重新加载并检查服务器值，再替换草稿。';

  @override
  String get notesDownloadsPaused => '下载已暂停';

  @override
  String get notesExportNotPublished => '未发布任何导出。';

  @override
  String get notesKeyringUnavailable => '请解锁桌面密钥环后重试。';

  @override
  String get notesConnectFailed => '无法连接 Nextcloud Notes。请检查服务器地址后重试。';

  @override
  String get notesAccountMismatch => '请登录同一 Nextcloud 账户。要连接其他账户，请先移除此账户。';

  @override
  String get notesLocalRemovalFailed => '本地账户清理失败。账户已保留，以便重试移除。';

  @override
  String get notesTransferring => '正在传输笔记…';

  @override
  String get notesTechnicalDetails => '技术详情';

  @override
  String get notesPauseRequirement => '暂停离线保留要求';

  @override
  String get notesResumeRequirement => '继续离线保留要求';

  @override
  String get gitReturnToDocument => '返回文档';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return '只读快照 · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      '此文件名包含非 UTF-8 字节。仍可进行 Git 审阅和暂存；文档编辑器需要 UTF-8 文件名。';

  @override
  String get gitUiMergeInProgress => '合并进行中';

  @override
  String get gitUiRebaseInProgress => '正在重定基准';

  @override
  String get gitUiCherryPickInProgress => '樱桃选集在进行中';

  @override
  String get gitUiRevertInProgress => '还原中';

  @override
  String get gitUiPatchApplicationInProgress => '补丁应用程序正在进行中';

  @override
  String get gitUiSquashMergeResultAwaitingCommit => 'Squash 合并结果等待执行';

  @override
  String get gitUiUnresolvedIndexConflicts => '未解决的索引冲突';

  @override
  String get gitUiUnresolvedConflicts => ' · 未解决的冲突';

  @override
  String get gitUiReviewOperation => '审查业务';

  @override
  String get gitUiRefresh => '刷新';

  @override
  String get gitUiCreateNamedStash => '创建命名的收藏';

  @override
  String get gitUiCreateStash => '创建贮藏…';

  @override
  String get gitUiNoStashes => '没有藏东西';

  @override
  String get gitUiSelectAStashToInspectItsChanges => '选择要检查更改的隐藏';

  @override
  String get gitUiStashedUntrackedFiles => '未跟踪的文件';

  @override
  String get gitUiInspectStashedUntrackedFiles => '检查隐藏的未跟踪文件...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      '在应用时恢复藏品的阶段状态/索引状态';

  @override
  String get gitUiApplyAndRetain => '应用和保留';

  @override
  String get gitUiPop => '爷爷...';

  @override
  String get gitUiCreateBranch => '创建分支…';

  @override
  String get gitUiDropStash => '删除贮藏…';

  @override
  String get gitUiBranchFromStash => '从贮藏创建分支';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      '创建/ 切换到藏匿处的分支, 然后应用它 。 原始隐藏部分留待日后明确删除 。';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0这个藏品?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      '如果适用冲突,则保留原始藏品。';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      '删除此隐藏条目。 其更改不应用 。';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      '请解决未合并文件的冲突。Git 没有 stash 的继续或中止命令；原始贮藏会被保留。';

  @override
  String get gitUiStashNameMessage => '堆放名称/信息';

  @override
  String get gitUiStashContentAndResultingIndex => '堆放内容和由此产生的索引';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges => '被跟踪的工作和分阶段的变更';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      '贮藏更改并保留已暂存的更改 (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged => '仅贮藏已暂存的更改 (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => '包含未跟踪的文件';

  @override
  String get gitUiAllEligiblePathsInThisRepository => '此仓库中的所有合格路径';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions => '没有符合条件的这些隐藏选项的更改 。';

  @override
  String get gitUiSelectAtLeastOneEligiblePath => '选择至少一个合格路径 。';

  @override
  String get gitUiCreateStash2 => '创建贮藏';

  @override
  String get gitUiCreateWorktree => '创建工作树...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      '在 HEAD 处创建工作树之前，请先创建提交。';

  @override
  String get gitUiDetachedHEAD => '分离的 HEAD';

  @override
  String get gitUiCurrent => '当前 ·';

  @override
  String get gitUiLocked => '锁定 ·';

  @override
  String get gitUiOpenInBusyStack => '在繁忙的堆叠中打开 ?';

  @override
  String get gitUiStatusNotInspected => '未检查的状况';

  @override
  String get gitUiDirty => '脏';

  @override
  String get gitUiClean => '干净';

  @override
  String get gitUiOpenWorkingFolder => '打开工作文件夹';

  @override
  String get gitUiMoveWorktree => '移动工作树...';

  @override
  String get gitUiUnlock => '解锁';

  @override
  String get gitUiLock => '锁定';

  @override
  String get gitUiRemoveCleanWorktree => '删除干净的工作树...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges => '审查删除,包括本地更改...';

  @override
  String get gitUiNewWorktreeFolderName => '新建工作树文件夹名称';

  @override
  String get gitUiNewWorktreeBranch => '新建工作树分支';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '在 $arg2（$arg3）创建本地分支，并创建 $arg0/$arg1。';
  }

  @override
  String get gitUiDestinationFolderName => '目标文件夹名称';

  @override
  String get gitUiRemoveWorktree => '移除工作树?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      '明确丢弃此工作树中所有本地跟踪/未跟踪的更改。 锁定/ 使用的工作树仍受到保护 。';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git拒绝删除本地更改、未跟踪的文件或锁定 。';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove => '丢弃本地工作树内容并删除';

  @override
  String get gitUiRemoveCleanWorktree2 => '删除清洁工作树';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      '明确循环到嵌入的子模块中进行更新/同步';

  @override
  String get gitUiNoRecordedSubmodules => '没有记录子模块';

  @override
  String get gitUiNotInitialized => '未初始化';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return '父母 gitlink: $arg0 检查完毕: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => '肮脏的嵌套仓库';

  @override
  String get gitUiCleanNestedRepository => '清洁嵌套仓库';

  @override
  String get gitUiNestedStatusUnavailable => '无嵌套状态';

  @override
  String get gitUiEnterNestedRepository => '输入嵌套仓库';

  @override
  String get gitUiInitializeConfiguration => '初始化配置';

  @override
  String get gitUiUpdateToParentSRecordedCommit => '更新父权承诺...';

  @override
  String get gitUiFollowConfiguredRemoteBranch => '跟随已配置的远程分支...';

  @override
  String get gitUiSynchronizeConfiguredURLs => '同步配置的 URL...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent => '父体中当前子模块指针的阶段';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      '父母和子模块承诺、 推动和肮脏状态保持分离 。 浏览不初始化或更新它们 。';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return '获取并检查已配置的远程分支的承诺。 这与父行所记录的 gitlink 不同 。 递归: $arg0 。';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return '根据需要初始化并检查准确的$arg0。递归:$arg1。';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return '应用已审查的子模块配置操作。 递归: $arg0 。';
  }

  @override
  String get gitUiApplySubmoduleOperation => '应用子模块操作';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      '检查已记录的修订版或创建回收分支。 Reflog 并不恢复任意的未保存或未跟踪的内容 。';

  @override
  String get gitUiSelectAReflogEntry => '选择重写条目';

  @override
  String get gitUiPreviousPage => '上一页';

  @override
  String get gitUiNextPage => '下一页';

  @override
  String get gitUiRecoveryBranchName => '回收分支名称';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return '创建分支于$arg0;工作文件和当前分支保持不变。';
  }

  @override
  String get gitUiCreateRecoveryBranch => '创建回收分支...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => '只读恢复快照';

  @override
  String get gitUiInspectSnapshot => '检查快照...';

  @override
  String get gitUiReviewReset => '审阅重置…';

  @override
  String gitUiPageArg0(String arg0) {
    return '第 $arg0 页';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Git 文本历史必须拥有可编辑的字段 。';

  @override
  String get gitUiEditHEADIndexWorkingTree => '编辑 HEAD | 暂存区 | 工作区…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      '经审查的索引或工作内容已改变。 在开始之前刷新此比较 。';

  @override
  String get gitUiRefreshComparison => '刷新比较';

  @override
  String get gitUiPreviousChangedFile => '上一个已更改的文件';

  @override
  String get gitUiNextChangedFile => '下一个更改的文件';

  @override
  String get gitUiPreviousDifference => '上一个差数';

  @override
  String get gitUiNextDifference => '下一个差数';

  @override
  String get gitUiComparisonMode => '比较模式';

  @override
  String get gitUiSideBySide => '并肩作战';

  @override
  String get gitUiUnified => '统一';

  @override
  String get gitUiDiffDisplayOptions => 'Diff 显示选项';

  @override
  String get gitUiWrap => '环绕';

  @override
  String get gitUiWords => '单词';

  @override
  String get gitUiCollapseContext => '折叠上下文';

  @override
  String get gitUiIgnoreWhitespace => '忽略空白';

  @override
  String get gitUiSearchComparison => '搜索比较';

  @override
  String get gitUiSearch => '搜索';

  @override
  String get gitUiCloseSearch => '关闭搜索';

  @override
  String get gitUiStagingActions => '暂存操作';

  @override
  String get gitUiStagingActions2 => '暂存操作…';

  @override
  String get gitUiUnstageSelectedChangedLines => '取消暂存所选更改行';

  @override
  String get gitUiStageSelectedChangedLines => '暂存所选更改行';

  @override
  String get gitUiUnstageWholeFile => '取消暂存整个文件';

  @override
  String get gitUiStageWholeFile => '暂存整个文件';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 只用空格修改的行隐藏 □ 显示精确的更改';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '已选择 $arg0 个更改行 · 显示设置不会改变暂存内容的字节。';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      '只读比较 · 复制文本或调整显示设置。';

  @override
  String get gitUiNoFinalNewline => ' · 没有最终的新线';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 ° $arg1 ° $arg2 字节 $arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents => '这些内容没有文本比较 。';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      '此比较超过了约束文本审查的限制。 内容未被宣布为完全相同 。';

  @override
  String get gitUiTheComparedContentsAreIdentical => '比较的内容相同 。';

  @override
  String get gitUiUnstage => '卸载';

  @override
  String get gitUiStage => '阶段';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 更改了线条';
  }

  @override
  String get gitUiContext => 'A. 背景情况';

  @override
  String get gitUiExpandUnchangedContext => '扩展无变化的上下文';

  @override
  String get gitUiUnstageThisHunk => '取消暂存此区块';

  @override
  String get gitUiStageThisHunk => '暂存此区块';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return '编辑阶段性内容 · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult => '写入已审查的索引结果';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => '暂存区';

  @override
  String get gitUiWorkingTree => '工作区';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => '可编辑的索引 □ UTF-8 blob';

  @override
  String get gitUiUndo => '撤销';

  @override
  String get gitUiRedo => '重做';

  @override
  String get gitUiReloadIndexReview => '重新装入索引审查吗 ?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      '重新加载当前 HEAD、暂存区和工作版本。这会替换暂存区编辑器中未保存的草稿。';

  @override
  String get gitUiReplaceDraftAndReload => '替换草稿和重新装入';

  @override
  String get gitUiReloadVersions => '重新装入版本...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry => '将编辑的结果写入此索引条目';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      '工作文件仍保留在磁盘上。 在应用前先审查编辑后的索引 。';

  @override
  String get gitUiReviewIndexTextFormatChanges => '审查索引文本格式更改';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return '仅更新已审阅的 $arg0 索引条目。\n\n$arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => '写入已审查的索引结果';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      '经编辑的结果在格式审查中更改。 重审一次 。';

  @override
  String get gitUiSynchronizeScrolling => '同步滚动';

  @override
  String get gitUiReadOnlyRevisionContent => '只读版本内容';

  @override
  String get gitUiEditableIndexContent => '可编辑索引内容';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      '请求的修订版在当前过滤器之外。 重置过滤器以显示它 。';

  @override
  String get gitUiFilterLog => '过滤日志';

  @override
  String get gitUiFilters => '过滤器...';

  @override
  String gitUiFiltersCount(String count) {
    return '过滤器 ($count)...';
  }

  @override
  String get gitUiMessage => '说明…';

  @override
  String get gitUiAuthor => '作者…';

  @override
  String get gitUiPath => '路径...';

  @override
  String get gitUiDate => '约会...';

  @override
  String get gitUiMessageFilter => '信件过滤器';

  @override
  String get gitUiAuthorFilter => '作者过滤器';

  @override
  String get gitUiPathFilter => '路径过滤器';

  @override
  String get gitUiMessage2 => '说明';

  @override
  String get gitUiAuthor2 => '作者';

  @override
  String get gitUiPath2 => '路径';

  @override
  String get gitUiDateFilter => '日期过滤器...';

  @override
  String get gitUiResetFilters => '重置过滤器';

  @override
  String get gitUiRefreshLog => '刷新日志';

  @override
  String get gitUiGoToCommitReference => '转到承诺/ 引用...';

  @override
  String get gitUiBackToHEAD => '返回 HEAD';

  @override
  String get gitUiOrderedCherryPick => '按指定顺序拣选';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return '审视樱桃选择($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions => '比较两个选中的修改...';

  @override
  String get gitUiToggleBranchesPane => '切换树枝窗格';

  @override
  String get gitUiFilterBranchesAndTags => '过滤分支和标记';

  @override
  String gitUiCommitArg0(String arg0) {
    return '提交$arg0';
  }

  @override
  String get gitUiCommitDetails => '提交细节...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return '参考: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => '选择此提交';

  @override
  String get gitUiBranchOrTag => '分支或标签';

  @override
  String get gitUiAllReferences => '全部引用';

  @override
  String get gitUiLocal => '当地';

  @override
  String get gitUiRemote => '远程';

  @override
  String get gitUiTags => '标签';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters => '没有承诺匹配当前过滤器 。';

  @override
  String get gitUiObjectID => '对象编号';

  @override
  String get gitUiSubjectReferences => '主题/参考文献';

  @override
  String get gitUiDate2 => '日期';

  @override
  String get gitUiGitCommits => 'Git 提交';

  @override
  String get gitUiParents => '父提交';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0父母';
  }

  @override
  String get gitUiLoadMoreCommits => '装入更多承诺';

  @override
  String get gitUiLoadingChangedFiles => '正在装入已更改的文件';

  @override
  String get gitUiNoChangedFiles => '没有更改文件';

  @override
  String get gitUiSelectACommit => '选择一项承诺';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return '比较父母 $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => '更改的文件';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '作者: $arg0 < $arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return '提交者:$arg0 < $arg1 > $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      '浅色/ 部分边界: 父对象不可用 。';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      '父权在此页面外, 或浅边界外 。';

  @override
  String gitUiParentArg0(String arg0) {
    return '父提交 $arg0';
  }

  @override
  String get gitUiCommitActions => '提交动作...';

  @override
  String get gitUiEmptyTree => '空树';

  @override
  String get gitUiCreateBranch2 => '创建分支';

  @override
  String get gitUiCreateTag => '创建标签';

  @override
  String get gitUiCompareRevisions => '比较修改';

  @override
  String get gitUiOpenSnapshot => '打开快照';

  @override
  String get gitUiRevertCommit => '还原承诺';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary => '在此边界之后交互式重标';

  @override
  String get gitUiResetCurrentBranch => '重置当前分支';

  @override
  String get gitUiCopyFullObjectID => '复制完整的对象 ID';

  @override
  String get gitUiGoToCommitReference2 => '进行/ 引用';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      '输入要在日志中显示的承付 ID 或引用 。';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable => '请求的修订无法使用 。';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      '仓库元数据只读。 部门检查和比较仍然可用 。';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      '工作文件不可用或只读。 部门切换和合并不可用 。';

  @override
  String get gitUiSearchBranchesAndTags => '搜索分支和标签';

  @override
  String get gitUiNewBranch => '新建分支…';

  @override
  String get gitUiLocalBranches => '本地分支';

  @override
  String get gitUiRemoteBranches => '远程分支';

  @override
  String gitUiTracksArg0(String arg0) {
    return '音轨  $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return '在$arg0检查过';
  }

  @override
  String get gitUiRefreshingBranchMetadata => '正在刷新分支元数据';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return '切换到 $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => '开放已占用的工作树';

  @override
  String get gitUiCreateLocalTrackingBranch => '创建本地跟踪分支...';

  @override
  String get gitUiCompareToCurrentHEAD => '与当前 HEAD 比较';

  @override
  String get gitUiMergeIntoCurrentBranch => '合并为当前分支...';

  @override
  String get gitUiRename => '重命名...';

  @override
  String get gitUiChangeUpstream => '向上移动...';

  @override
  String get gitUiDelete => '删除...';

  @override
  String get gitUiDeleteFromRemote => '从远程删除...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return '$arg0的行动';
  }

  @override
  String get gitUiLocalBranchName => '本地分支名称';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return '创建于 $arg0。 新分支将被检查 。';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return '当地分行将追踪$arg0号,并检查完毕。';
  }

  @override
  String get gitUiChooseRemoteForDeletion => '选择要删除的远程';

  @override
  String get gitUiDeleteRemoteReference => '删除远程引用';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '合并号$arg0至$arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return '重命名 $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return '上游$arg0';
  }

  @override
  String get gitUiNoUpstream => '无上游分支';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '删除$arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0\n目标 $arg1\n仅删除本地分支。未合并的分支会被拒绝删除。';
  }

  @override
  String get gitUiDelete2 => '删除';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return '删除未合并的分支 $arg0 ?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git 报告该分支没有完全合并。 在审查它的承诺后, 明确删除本地引用; 远程副本不变 。';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => '删除未合并的本地分支';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return '目的地: $arg0 ° $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => '源分支或标记';

  @override
  String get gitUiMergePolicy => '合并政策';

  @override
  String get gitUiFastForwardWhenPossible => '可能时快速前进';

  @override
  String get gitUiAlwaysCreateAMergeCommit => '总是创建合并承诺';

  @override
  String get gitUiFastForwardOnly => '仅快速前进';

  @override
  String get gitUiSquashIntoStagedChanges => '静态到分阶段的更改';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit => '创建合并前停止';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      '已禁用快进，以防 HEAD 在审阅之前移动。';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      '用于单项承诺的请假已逐步更改;这不是持续合并。';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      '在共同的解决方案工作空间中仍然存在冲突。';

  @override
  String get gitUiAddRemote => '添加远程...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return '获取: $arg0 推: $arg1';
  }

  @override
  String get gitUiRemoveRemote => '删除远程...';

  @override
  String get gitUiChangeFetchURL => '更改获取 URL...';

  @override
  String get gitUiAddPushDestination => '添加推进目标...';

  @override
  String get gitUiRemovePushDestination => '删除推进目标...';

  @override
  String gitUiManageArg0(String arg0) {
    return '管理 $arg0';
  }

  @override
  String get gitUiRemoteName => '远程名称';

  @override
  String get gitUiNewRemoteName => '新建远程名称';

  @override
  String get gitUiRepositoryURLOrLocalSource => '仓库 URL 或本地来源';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove => '输入要删除的确切审查对象 。';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      '证书由配置的助手或私人提示提供 。';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '移除远程 $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      '删除本地远程配置和跟踪引用。 它不删除服务器仓库 。';

  @override
  String get gitUiRemoveRemote2 => '删除远程';

  @override
  String get gitUiCommitScopeEntireRepository => '提交范围: 整个仓库';

  @override
  String get gitUiCachedTracking => '缓存跟踪';

  @override
  String get gitUiAmendLastCommit => '修改上次提交';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected => '配置钩和签名受到尊重。';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      '重写选中的 HEAD 提交。远程跟踪信息无法证明它尚未发布。';

  @override
  String get gitUiRepository => '仓库';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '已破旧的 $arg0';
  }

  @override
  String get gitUiLog => '日志';

  @override
  String get gitUiRepositoryActions => '仓库操作';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return '缓存的跟踪信息 · $upstream · 领先 $ahead · 落后 $behind';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      '无工作树。打开日志检查其历史 。';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      '无法进行只读存储器 / 中继和承付 。';

  @override
  String get gitUiRepositoryStatusUnavailable => '没有仓库状态';

  @override
  String gitUiAmendRevision(String revision) {
    return '修正 $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => '添加签署确认尾注';

  @override
  String get gitUiUseConfiguredSigningPolicy => '使用已配置的签名策略';

  @override
  String get gitUiCryptographicallySignThisCommit => '加密签名此项';

  @override
  String get gitUiDoNotSignThisCommit => '不签署此承诺';

  @override
  String get gitUiRecentCommitMessages => '最近发送的信件...';

  @override
  String get gitUiUseConfiguredCommitTemplate => '使用已配置的提交模板...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks => '作者身份和配置的钩子...';

  @override
  String get gitUiDraftMessage => '信件草稿...';

  @override
  String get gitUiCommitOptions => '提交选项';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return '草稿保留在内存中，但保存失败。$arg0';
  }

  @override
  String get gitUiCommitMessage => '提交说明';

  @override
  String get gitUiGitOperationInProgress => '正在运行中';

  @override
  String get gitUiCancel => '取消';

  @override
  String get gitUiAmendStaged => '修订阶段';

  @override
  String gitUiCommitStagedCount(String count) {
    return '提交已暂存的更改（$count）';
  }

  @override
  String get gitUiCommitAndPush => '提交并推送…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured => '没有配置可读化的承诺模板 。';

  @override
  String get gitUiCommitIdentityAndHooks => '提交身份和钩子';

  @override
  String get gitUiRecentMessages => '最近的消息';

  @override
  String get gitUiReplaceMessageDraft => '替换信件草稿吗 ?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      '用选中的信件替换现有承诺信件吗 ?';

  @override
  String get gitUiReplaceDraft => '替换草稿';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return '本地提交 $arg0 已存在。';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return '本地承诺 $arg0 存在。 在尝试再次承诺前先查看日志。 信件草稿已被保留 。';
  }

  @override
  String get gitUiCommitAuthorName => '提交作者名称';

  @override
  String get gitUiCommitAuthorEmail => '提交作者电子邮件';

  @override
  String get gitUiConfiguredDefault => '已配置默认';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return '签署日期:$arg0 和 $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return '配置钩: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      '签署确认尾注是提交说明中的声明，与密码学签名不同。身份信息仅保存到此仓库的本地配置中；草稿会被保留。';

  @override
  String get gitUiSaveRepositoryIdentity => '保存仓库身份';

  @override
  String get gitUiStaged => '已暂存';

  @override
  String get gitUiUntracked => '未跟踪';

  @override
  String get gitUiUnstaged => '未暂存';

  @override
  String get gitUiConflicts => '冲突';

  @override
  String get gitUiNoChanges => '没有更改';

  @override
  String get gitUiRepositoryChangeTree => '仓库更改树';

  @override
  String get gitUiChanges => '更改';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => '展开';

  @override
  String get gitUiCollapse => '折叠';

  @override
  String get gitUiUnstageFile => '取消暂存文件';

  @override
  String get gitUiStageFile => '暂存文件';

  @override
  String get gitUiExpandGroup => '展开组';

  @override
  String get gitUiCollapseGroup => '折叠组';

  @override
  String get gitUiReviewDifference => '审查差异';

  @override
  String get gitUiUnstageSelectedFiles => '取消暂存所选文件';

  @override
  String get gitUiStageSelectedFiles => '暂存所选文件';

  @override
  String get gitUiFileHistoryAndBlame => '文件历史和责备...';

  @override
  String get gitUiDeleteUntrackedFile => '删除未跟踪的文件...';

  @override
  String get gitUiDiscardUnstagedChange => '丢弃未显示的更改...';

  @override
  String get gitUiFileHistory => '文件历史';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '丢弃未显示的 $arg0?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 字节 · $arg1\n使用索引内容替换工作文件，或删除此未跟踪文件。暂存内容保持不变。必须先检查应用中未保存的文档。';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => '删除未跟踪的文件';

  @override
  String get gitUiDiscardWorkingChange => '丢弃工作变更';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return '删除REMOTE参考文献 $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      '这将删除下面列出的每个实际推进目标的引用。 保留本地分支/ 标签。 本次审查将固定预期提示 。';

  @override
  String get gitUiReferenceDoesNotExist => '不存在引用';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0\n预期顶端：$arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => '远程删除完成 。';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '从遥控器中删除$arg0?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      '上面显示的确切目标提示将被删除。 任何已更改的远程提示都会停止操作, 以便再次审查 。';

  @override
  String get gitUiReviewAndDeleteFromRemote => '从远程审查并删除...';

  @override
  String get gitUiDestinationReference => '目标参考';

  @override
  String get gitUiReviewDestinations => '审查目的地';

  @override
  String get gitUiNewRemoteBranch => '新建远程分支';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · 预期：$arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      '目的地已承诺本地无法使用 。 在检查即将离开的历史前先获取已审查的目的地 。';

  @override
  String get gitUiFetchReviewedDestination => '获取已审查的目标';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      '选择目的地并审查即将退出的承诺 。';

  @override
  String get gitUiNoOutgoingCommits => '没有退出承诺';

  @override
  String get gitUiSelectAnOutgoingCommit => '选择一个即将退出的承诺';

  @override
  String get gitUiLoadMoreOutgoingCommits => '装入更多已发送承诺';

  @override
  String get gitUiSetThisDestinationAsUpstream => '将此目的地设为上游';

  @override
  String get gitUiChooseExactTagsToPublish => '选择要发布的确切标签';

  @override
  String get gitUiTagsNone => '标记:无';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return '标记: 选中 $arg0';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return '准确发布: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      '推进完成。 本地承诺仍然在日志中 。';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      '强制推送要求目标引用的顶端与本次审查显示的值完全一致。';

  @override
  String get gitUiForceWithReviewedLease => '强制使用经审核的租赁...';

  @override
  String get gitUiPush => '推送';

  @override
  String get gitUiForcePushWithReviewedLeases => '强制推进经过审查的租赁?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return '只有当每个遥远的目的地仍然拥有上面显示的确切提示时,才重写 $arg0 。\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      '其他人可能已经在使用这些历史。后台获取不会更新本次租约保护条件。';

  @override
  String get gitUiForceWithLease => '租赁';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      '远程结果不确定。 在再次推动之前再次审查目的地 。';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return '父 $arg0 $arg1';
  }

  @override
  String get gitUiRemoteToFetch => '远程获取';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches => 'Prune 删除远程跟踪分支';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      '在不替换工作文件的情况下获取远程跟踪信息更新 。';

  @override
  String get gitUiFetch => '获取';

  @override
  String get gitUiSourceRemote => '来源远程';

  @override
  String get gitUiSourceBranch => '源代码分支';

  @override
  String get gitUiReviewedStrategy => '审查的战略';

  @override
  String get gitUiMerge => '合并';

  @override
  String get gitUiRebase => '变基';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      '如果目的地不能快速前进, 则停止; 永远不要合并或重置 。';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      '与合并承诺合并,包括当有可能快速前进时。';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible => '合并; 允许在可能情况下快速前进 。';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      '重设本地历史, 保留本地合并承诺 。';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory => '重设本地承诺为线性历史 。';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git 被配置为交互式重置。 在此选择明确的拉动策略, 或者获取并打开 Rebase... 来审查一个计划 。';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull => '使用经过审查的普通重标进行此拉';

  @override
  String get gitUiOptions => '选项';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward => '总是创建合并承诺( 不快速前进)';

  @override
  String get gitUiPreserveLocalMergeCommits => '保存本地合并承诺';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      '本地更改可能阻止拉动。 检查/ 承诺它们或明确创建隐藏 。';

  @override
  String get gitUiStashes => '贮藏';

  @override
  String get gitUiCreateOrReviewStash => '创建或审查隐藏...';

  @override
  String get gitUiPullWithSelectedStrategy => '以选定的策略拉动';

  @override
  String get gitUiRepositoryURLOrLocalGitSource => '仓库 URL 或本地 Git 源';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS、 SSH 或本地路径';

  @override
  String get gitUiFolderToInitialize => '初始化文件夹';

  @override
  String get gitUiFinalCloneDestination => '最终克隆目标';

  @override
  String get gitUiChoose => '选择...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      '仅创建 Git 元数据。 现有文件没有进行编程或承诺 。';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      '最终目标必须不存在或为空。绝不会覆盖已有的用户数据。';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      '· 空白使用有效的 Git 政策';

  @override
  String get gitUiSelectedBranchOptional => '选定分支 □ 可选';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      '循环明确初始化/更新子模块';

  @override
  String get gitUiPreparingGitOperation => '准备 Git 操作...';

  @override
  String get gitUiThisAttemptCreated => '这种尝试创造了';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt => '在这次尝试之前,目的地已经存在:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      '目录还在检查中,在再次复制之前再检查一下';

  @override
  String get gitUiNoDestinationDirectoryRemains => '没有目标目录 。';

  @override
  String get gitUiCancelProcess => '取消进程';

  @override
  String get gitUiInitialize => '初始化';

  @override
  String get gitUiClone => '克隆';

  @override
  String get gitUiChooseNewBase => '选择新基底';

  @override
  String get gitUiChooseUpstreamBoundary => '选择上游边界';

  @override
  String get gitUiNewBase => '新基底';

  @override
  String get gitUiUpstreamBoundaryExcluded => '上游边界 · 不包含';

  @override
  String get gitUiSameAsUpstreamBoundary => '与上游边界相同';

  @override
  String get gitUiChooseBranchTagOrCommit => '选择分支、标签或提交…';

  @override
  String get gitUiUseUpstreamAsNewBase => '将上游用作新的基地';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      '从日志中选择一个有效的分支、标记或承诺 。';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      '分支块中第一个保留的提交不能设为 squash 或 fixup，因为它前面没有可合并的目标提交。';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return '分队区块 $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage => '[改写后将要求发出新电\n';

  @override
  String get gitUiPlannedCommitMessages => '计划承诺信息';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      '原始/ 合并信件预览';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return '结果$arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return '当前分支: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => '分离的 HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      '变基会重写提交的标识。远程跟踪信息无法证明这些历史从未被发布。';

  @override
  String get gitUiIncludeRootCommits => '包含根提交';

  @override
  String get gitUiMergeCommits => '合并承诺';

  @override
  String get gitUiFlattenHistory => '线性化历史';

  @override
  String get gitUiPreserveBranchStructure => '保留分支结构';

  @override
  String get gitUiAutosquash => '自动压缩合并';

  @override
  String get gitUiPrepareGitPlan => '准备 Git 计划';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return '将重新应用的提交：$count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      '包括从此分支可以达到的所有 root 。';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return '将把 $boundary 之后的提交重放到 $base 上；不包含边界提交本身。';
  }

  @override
  String get gitUiRoot => '根数';

  @override
  String get gitUiGitBranchLabelResetMergeStructure => 'Git 分支/ 标签/ 重置/ 合并结构';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      '选择明确的旧边界或根模式, 然后制定计划 。';

  @override
  String get gitUiMoveUp => '上移';

  @override
  String get gitUiMoveDown => '下移';

  @override
  String get gitUiResetPlan => '重置计划';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · 分支区块 $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles => '选择详细信息的承诺和已更改的文件';

  @override
  String get gitUiPreviewCombinedCommitMessages => '预览合并信件...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt/  移动选中的承诺。 无关的分支引用不会自动更新 。';

  @override
  String get gitUiCancelPlan => '取消计划';

  @override
  String get gitUiStartReviewedRebase => '开始已审阅的变基？';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return '计划于$arg1年重写$arg0,被放弃的承诺在开始之前仍明显可见。';
  }

  @override
  String get gitUiStartRebase => '开始变基';

  @override
  String get gitUiNoContinuingGitOperation => '没有持续 Git 操作';

  @override
  String get gitUiStoppedForEditingAmend => ' · 停止编辑/修正';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      '这些是未合并的索引条目, 可能来自隐藏应用程序。 Git 没有隐藏继续或中止命令 。';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      '编辑工作文件, 阶段和修正当前承诺, 然后继续重标 。';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · 未合并的暂存阶段 $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries => '该索引没有未解决的条目 。';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit => '将当前承诺保留为空承诺';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      '真实索引没有分阶段的更改。 创建一个明确的空承诺, 如果仍然活跃, 则继续排序 。';

  @override
  String get gitUiKeepEmptyCommit => '保持空承诺...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git 会尝试回到操作开始时的状态，但无法保证恢复操作前已有的未暂存、未跟踪或未保存内容。';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      '跳过当前承诺, 继续下一个计划的承诺 。';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      '忘记此操作的簿记, 同时保留当前文件和索引 。';

  @override
  String gitUiContinueArg0(String arg0) {
    return '继续$arg0';
  }

  @override
  String get gitUiReloadConflictVersions => '重新装入冲突版本 ?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      '将未保存结果草稿替换为当前工作文件。 保存的工作内容将予保留 。';

  @override
  String get gitUiLoadingConflictVersions => '正在装入冲突版本...';

  @override
  String get gitUiLoadingConflict => '正在装入冲突';

  @override
  String get gitUiBaseLeft => '基地 左转';

  @override
  String get gitUiBaseRight => '基数  右';

  @override
  String get gitUiNoBaseEntryForThisConflict => '此冲突无基条目';

  @override
  String get gitUiAcceptEntireLeftFile => '接受整个左侧文件...';

  @override
  String get gitUiAcceptEntireRightFile => '接受右侧整个文件…';

  @override
  String get gitUiPreviousConflictRegion => '先前的冲突地区';

  @override
  String get gitUiNextConflictRegion => '下一个冲突地区';

  @override
  String get gitUiManualResolution => '人工解析';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '地区 $arg0/$arg1 X XX $arg2 检查';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      '源对齐超过了文本比较限制;源板仍然可供手工审查。';

  @override
  String get gitUiAcceptLeftRegion => '接受左区域';

  @override
  String get gitUiAcceptRightRegion => '接受正确的区域';

  @override
  String get gitUiKeepManualResultForRegion => '保持区域手工结果';

  @override
  String get gitUiApplyGitSNonConflictingChanges => '应用 Git 的非冲突性变化吗 ?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      '将当前结果草稿替换为 Git 合并预览。 此丢弃未保存的手动结果编辑; 工作文件在保存前保持不变 。';

  @override
  String get gitUiUseMergePreview => '使用合并预览';

  @override
  String get gitUiApplyNonConflictingChanges => '应用非冲突更改...';

  @override
  String get gitUiLeftSource => '左侧来源';

  @override
  String get gitUiResult => '结果';

  @override
  String get gitUiRightSource => '正确来源';

  @override
  String get gitUiStage2 => '第2阶段';

  @override
  String get gitUiStage3 => '第3阶段';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      '没有冲突版本。 刷新以审查当前状态 。';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      '结果已保存到磁盘。 索引仍然决定此文件是否已经解决 。';

  @override
  String get gitUiSaveResultDraft => '保存结果草稿';

  @override
  String get gitUiApplyResultAndStageResolution => '应用结果并暂存解决方案';

  @override
  String get gitUiResultEditableUTF8WorkingContent => '· 可编辑的 UTF-8 工作内容';

  @override
  String get gitUiEditableConflictResult => '可编辑的冲突结果';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '左侧：$arg0 · $arg1\n右侧：$arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      '选择内容、 删除或子模块明确承诺。 没有二进制数据被解码为可编辑文本 。';

  @override
  String get gitUiUseEntireLeftContent => '使用全部左侧内容...';

  @override
  String get gitUiUseEntireRightContent => '使用右侧全部内容…';

  @override
  String get gitUiDeleteThisPath => '删除此路径...';

  @override
  String get gitUiResolvedSubmoduleCommit => '已解析子模块承诺';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      '在父体中弹出精确的 gitlink 。 这不会检查或执行子模块 。';

  @override
  String get gitUiSetResolvedGitlink => '设定解析 gitlink...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return '基底   $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      '结果是经过编辑的。 保留手动结果或选择其它未变区域 。';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '应用“$arg0”解决方案？';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      '阶段 所选 gitlink 承诺在母体中。 子模块检查及其文件不被替换 。';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return '替换整个工作路径 $arg0, 并分阶段作出决定。 当前的工作内容和任何未保存的结果草稿将被丢弃 。';
  }

  @override
  String get gitUiApplyEntireFileDecision => '应用整个文件决定';

  @override
  String get gitUiStageThisConflictResolution => '分阶段解决冲突?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return '使用整个编辑结果为 $arg0。 Git 记录了预设时的解析路径。 首先审查所有预定内容 $arg1';
  }

  @override
  String get gitUiApplyAndStage => '应用并暂存';

  @override
  String get gitUiReviewResultTextFormatChanges => '审查结果文本格式更改';

  @override
  String get gitUiSaveReviewedResult => '保存已审查的结果';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      '无法访问本地的 Git 表格。 在重新连接应用程序后重试 。';

  @override
  String get gitUiSans => '孙子';

  @override
  String get gitUiSelect => '选择';

  @override
  String get gitUiContextMenu => '上下文菜单';

  @override
  String get gitUiCopyText => '复制文本';

  @override
  String get gitUiLoadingRow => '正在装入行';

  @override
  String get gitUiRetry => '重试';

  @override
  String get gitUiGitMessage => 'Git 消息 :';

  @override
  String get gitUiCancelPrompt => '取消提示';

  @override
  String get gitUiUseMessageAndContinue => '使用信件并继续';

  @override
  String get gitUiRespondPrivately => '私人答复';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return '无法保存首选项: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return '提交存储草稿: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return '视图偏好无法读取: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return '提交草稿保留在记忆中,但无法保存: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      '经审查的仓库仅用于此操作,历史和内容检查仍然可用。';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git 返回 $arg0。 应用程序无法刷新其文档 :\\\\ $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => '在日志中选择提交…';

  @override
  String get gitUiCurrentBranch => '当前分支';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      '没有匹配的分支或标记。 在日志中选择一个承诺 。';

  @override
  String get gitUiBranches => '分支';

  @override
  String get gitUiPushCommits => '推送提交';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return '拉进 $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return '解决 $arg0';
  }

  @override
  String get gitUiCurrentOperation => '当前业务';

  @override
  String get gitUiRebaseCommits => '变基提交';

  @override
  String get gitUiFetch2 => '获取…';

  @override
  String get gitUiPull => '拉取…';

  @override
  String get gitUiPush2 => '推送…';

  @override
  String get gitUiBranches2 => '分支…';

  @override
  String get gitUiManageRemotes => '管理远程仓库…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return '合并到$arg0...';
  }

  @override
  String get gitUiRebase2 => '变基…';

  @override
  String get gitUiConflictsAndCurrentOperation => '冲突与当前操作...';

  @override
  String get gitUiStashes2 => '贮藏…';

  @override
  String get gitUiWorktrees => '工作树…';

  @override
  String get gitUiSubmodules => '子模块…';

  @override
  String get gitUiReflogAndRecovery => '引用日志与恢复…';

  @override
  String get gitUiCloneRepository => '克隆仓库…';

  @override
  String get gitUiRevokeRepositoryTrust => '撤销对此仓库的信任';

  @override
  String get gitUiWaitingForRepositoryStatus => '正在等待仓库状态';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh => '没有仓库状态; 刷新';

  @override
  String get gitUiManageRemotes2 => '管理远程仓库';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return '合并为$arg0';
  }

  @override
  String get gitUiWorktrees2 => '工作树';

  @override
  String get gitUiSubmodules2 => '子模块';

  @override
  String get gitUiReflogAndRecovery2 => '引用日志与恢复';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return '克隆库 · $arg0';
  }

  @override
  String get gitUiApply => '应用';

  @override
  String get gitUiResizeGitPanes => '调整 Git 窗帘大小';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0%';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return '退出状态:$status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      '仓库已更改。 重新刷新和审查后再尝试 。';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      '另一个操作持有仓库或索引锁定。 等等, 然后刷新 。';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation => '本次操作需要仓库信任 。';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Git 服务断开。 重新连接并调节仓库 。';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      '已安装的 Git 可执行文件无法支持此操作。 请在下面审查运行时间要求 。';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      '此仓库仅用于请求的操作。 仍然可用 。';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      '操作需要调节。 在重复之前先审查生成的仓库或远程状态 。';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git 认证失败。 审查证书助手或解锁配置的密钥环 。';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH 主机验证失败。 通过您配置的 SSH 工具审查主机身份 。';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      '提交签名失败或已取消。 请审查签名密钥、 代理和配置的签名工具 。';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      '设置仓库作者名称和电子邮件, 然后返回到保存的信件草稿 。';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git 拒绝了已审查的更新。 刷新并审查实际目的地, 然后再尝试 。';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      '工作或分阶段的修改阻止了这一操作。 审查、 承诺或明确隐藏这些操作 。';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      '所需的 Git 对象不可用。 检查浅处或部分仓库的边界, 必要时可以明确获取 。';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git 操作失败: $arg0';
  }

  @override
  String get gitUiDiagnostics => '诊断';

  @override
  String get gitUiAuthorizeGitInspection => '授权 Git 检查...';

  @override
  String get gitUiCopyDiagnostics => '复制诊断';

  @override
  String get gitUiActions => '操作';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return '分公司,$arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut => '创建本地分支而不检查 。';

  @override
  String gitUiTagArg0(String arg0) {
    return '标记  $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return '仅读快照 · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => '拣选提交';

  @override
  String get gitUiRevertCommits => '还原承诺';

  @override
  String get gitUiCompareToFullRevisionID => '与完整修订版ID比较';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return '树比较方向：$arg0 → 此处输入的修订版本。';
  }

  @override
  String get gitUiEnterAFullValidObjectID => '输入完整有效的对象 ID 。';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 $arg1 树对比';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '重置$arg0至$arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      '移动 HEAD/当前分支。reflog 无法恢复任意未跟踪或未保存的内容。';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles => '移动 HEAD，保留暂存区和工作文件。';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      '移动 HEAD 并替换暂存区，保留工作文件。';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      '替换 HEAD、暂存区和已跟踪的工作文件；可能覆盖妨碍操作的未跟踪文件。';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      '替换 HEAD、暂存区及符合条件的文件；若会丢失本地更改则拒绝操作。';

  @override
  String gitUiResetWithArg0(String arg0) {
    return '重置为$arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '+$arg0  $arg1 在应用前先审查选中模式的效果 。';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '重置 $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return '目标 $arg0';
  }

  @override
  String get gitUiTagName => '标签名称';

  @override
  String get gitUiAnnotatedTag => '附注标签';

  @override
  String get gitUiCryptographicSigning => '密码学签名';

  @override
  String get gitUiConfiguredPolicy => '配置策略';

  @override
  String get gitUiSignThisTag => '签名此标记';

  @override
  String get gitUiDoNotSign => '不要签名';

  @override
  String get gitUiTagMessage => '标记消息';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      '本地创建标记。 在 Push 审评中明确发布选中的标记 。';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return '整棵树: $arg0 $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => '下一个已更改的文件页';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      '只读仓库快照。 打开文件时从未检查此版本 。';

  @override
  String get gitUiOpenReadOnlyVersion => '打开只读版本';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus => '正在等待仓库状态';

  @override
  String get gitUiRestoreThisPath => '恢复这条路径...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return '历史 · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '恢复 $arg0吗?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return '将此工作路径替换为订正版 $arg0。 保留现有分阶段内容。';
  }

  @override
  String get gitUiRestoreWorkingFile => '恢复工作文件';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return '文件历史跟随重命名 □  $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => '逐行追溯 · 已提交内容';

  @override
  String get gitUiBlame => '逐行追溯…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0  工作树';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => '打开只读历史文件';

  @override
  String get gitUiCompareToCurrentFile => '与当前文件比较';

  @override
  String get gitUiCompareToParent => '与父性比较...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return '已提交 $arg0 · 编辑器中未保存的内容不包含在这些注解中';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return '来源于 $arg0 的历史';
  }

  @override
  String get gitUiBoundary => ' · 边界';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\n原始行 $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => '前一行';

  @override
  String get gitUiNextLines => '下一行';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return '明确应用命令 o 目的地 $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => '添加全部任务对象编号';

  @override
  String get gitUiAddReviewedCommit => '添加已审查的承诺...';

  @override
  String get gitUiMoveEarlier => '稍早移动';

  @override
  String get gitUiMoveLater => '稍后移动';

  @override
  String get gitUiRemoveFromReviewedSequence => '从已审查的序列中删除';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits => '应用更改而不创建承诺';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      '使用此明确的主行父母来合并承诺';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      '空的或已经应用的承诺可以阻止Git作出明确的跳过或继续决定。';

  @override
  String get gitUiRevertInReviewedOrder => '按审查顺序还原';

  @override
  String get gitUiCherryPickInReviewedOrder => '樱桃选手按顺序排列';

  @override
  String get gitUiReturnToFiles => '返回到文件';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => '提交';

  @override
  String get gitUiBackToCommit => '返回提交';

  @override
  String get gitUiSelectAChangeToReview => '选择要审查的修改';

  @override
  String get gitUiLoadingBranch => '正在装入分支...';

  @override
  String get gitUiBranchUnavailable => '分机无法使用';

  @override
  String get gitUiUnbornHEAD => '尚无提交的 HEAD';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return '分离的 HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => '继续';

  @override
  String get gitUiPick => '选取';

  @override
  String get gitUiReword => '修改说明';

  @override
  String get gitUiEdit => '编辑';

  @override
  String get gitUiSquash => '压缩合并';

  @override
  String get gitUiFixup => '丢弃说明并合并';

  @override
  String get gitUiDrop => '丢弃';

  @override
  String get gitUiAbort => '中止';

  @override
  String get gitUiSkip => '跳过';

  @override
  String get gitUiQuit => '退出操作';

  @override
  String get gitUiSoft => '软重置';

  @override
  String get gitUiMixed => '混合重置';

  @override
  String get gitUiHard => '硬重置';

  @override
  String get gitUiKeep => '保留更改';

  @override
  String get gitUiCreate => '创建';

  @override
  String get gitUiApplyStash => '应用贮藏';

  @override
  String get gitUiPopStash => '应用贮藏并在成功时删除';

  @override
  String get gitUiDropStashAction => '删除贮藏';

  @override
  String get gitUiEditedResult => '已编辑结果';

  @override
  String get gitUiLeftContent => '左侧内容';

  @override
  String get gitUiRightContent => '正确内容';

  @override
  String get gitUiDeletePath => '删除路径';

  @override
  String get gitUiSubmoduleCommit => '子模块承诺';

  @override
  String get gitUiPresentContent => '可用内容';

  @override
  String get gitUiAbsentContent => '缺席';

  @override
  String get gitUiBinaryContent => '二进制内容';

  @override
  String get gitUiTooLargeContent => '内容超过显示限制';

  @override
  String get gitUiUnavailableContent => '无内容';

  @override
  String get gitUiGitlinkContent => '子模块指针器';

  @override
  String get gitUiSymlinkContent => '符号链接';

  @override
  String get gitUiNoOperation => '无操作';

  @override
  String get gitUiCherryPickOperation => '拣选提交';

  @override
  String get gitUiRevertOperation => '还原提交';

  @override
  String get gitUiApplyMailboxOperation => '应用补丁';

  @override
  String get gitUiSquashOperation => 'Squash 合并';

  @override
  String get gitUiUnmergedOperation => '未合并索引';

  @override
  String get gitUiWaitingForPromptPhase => '等待你的回应';

  @override
  String get gitUiStoppedPhase => '停止审查';

  @override
  String get gitUiCompletedPhase => '已完成';

  @override
  String get gitUiFailedPhase => '失败';

  @override
  String get gitUiCancelledPhase => '已取消';

  @override
  String get gitUiUncertainPhase => '成果需要调节';

  @override
  String gitUiStageVersion(String stage) {
    return '冲突阶段 $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git 合并预览';

  @override
  String get gitUiNormalizedWorking => '工作树  正常';

  @override
  String gitUiPercentValue(String value) {
    return '$value%';
  }

  @override
  String gitUiOperationActionQuestion(String action, String operation) {
    return '$operation · $action?';
  }

  @override
  String gitUiOperationActionEllipsis(String action) {
    return '$action…';
  }

  @override
  String gitUiRebaseStepSemantics(
    String position,
    String action,
    String subject,
  ) {
    return '$position, $action, $subject';
  }

  @override
  String get gitUiUtf8Bom => 'UTF-8 带有字节顺序标记 (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 无字节顺序标记 (BOM)';

  @override
  String get gitUiAddsBom => '此编辑在文件开头添加 UTF-8 字节顺序标记( BOM ) 。';

  @override
  String get gitUiRemovesBom => '此编辑从文件开头删除 UTF-8 字节顺序标记( BOM ) 。';

  @override
  String get gitUiNoLineTerminators => '没有线条终止器';

  @override
  String gitUiLineEndings(String format) {
    return '$format 换行符';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return '混合线端 ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format □ 无最终的LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return '行结束符格式将从 $before 改为 $after。剪贴板中的文本可能使用与原文件不同的行结束符。';
  }

  @override
  String get gitUiGitFailure => 'Git 操作失败。 请检查下面的诊断 。';

  @override
  String get gitUiAbortInline => '中止';

  @override
  String get gitUiSkipInline => '跳过';

  @override
  String get gitUiQuitInline => '退出';

  @override
  String get gitUiMergeInline => '合并';

  @override
  String get gitUiRebaseInline => '变基';

  @override
  String get gitUiCherryPickInline => '拣选提交';

  @override
  String get gitUiRevertInline => '还原提交';

  @override
  String get gitUiApplyMailboxInline => '应用邮件框';

  @override
  String get gitUiSquashInline => '压缩合并';

  @override
  String get gitUiUnmergedInline => '未合并';

  @override
  String get gitHostFetch => '获取';

  @override
  String get gitHostRefreshGitStatus => '刷新 Git 状态';

  @override
  String get gitHostCommitStaged => '提交阶段';

  @override
  String get gitHostGitBranches => 'Git 分支';

  @override
  String get gitHostReviewPush => '审查推力';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git 操作适用于整个仓库, 并可以执行配置的钩子、 过滤器、 证书和签名工具 。';

  @override
  String get gitHostContentUnavailable => '无内容';

  @override
  String get gitHostInitializeRepository => '初始化存储库';

  @override
  String get gitHostCloneRepository => '克隆仓库';

  @override
  String get gitHostInitializeHere => '在此初始化...';

  @override
  String get gitHostCloneRepository2 => '克隆仓库…';

  @override
  String get gitHostGitLog => 'Git 日志';

  @override
  String get gitUiAbsentPlaceholder => '(缺席)';

  @override
  String get gitUiUnborn => '未出生婴儿';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return '已变基的历史 · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return '当前历史 · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return '正在重放的提交 · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return '传入的内容 · $revision';
  }

  @override
  String get gitUiContentConflict => '内容冲突';

  @override
  String get gitUiSubmoduleConflict => '子模块冲突';

  @override
  String get gitUiSymlinkConflict => '符号链接冲突';

  @override
  String get gitUiAddAddConflict => '双方均加';

  @override
  String get gitUiModifyDeleteConflict => '修改/删除或重新命名/删除';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft => '丢弃未保存的索引草稿？';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      '关闭索引编辑器只会丢弃草稿。索引和工作文件不会更改。';

  @override
  String get gitUiDiscardIndexDraft => '丢弃索引草稿';

  @override
  String get gitUiDiscardUnsavedConflictDraft => '放弃未保存的冲突解决结果？';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      '关闭冲突编辑器只会放弃未保存的结果草稿。已保存的工作内容和索引保持不变。';

  @override
  String get gitUiDiscardConflictDraft => '放弃冲突草稿';

  @override
  String get gitUiOpenCurrentFile => '打开当前文件';

  @override
  String get gitUiPreviousSearchMatch => '上一个搜索结果';

  @override
  String get gitUiNextSearchMatch => '下一个搜索结果';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return '第 $current 个，共 $count 个结果';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return '正在显示前 $count 个结果。请缩小搜索范围以查看更多结果。';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => '不使用筛选器显示修订';

  @override
  String get gitUiRestoreHistoryFilters => '恢复历史筛选器';

  @override
  String get gitUiShowAllAffectedFiles => '显示所有受影响的文件';

  @override
  String get gitUiGraphLanes => '图形轨道';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return '将 $arg0 变基到 $arg1';
  }

  @override
  String get gitUiChangedLine => '已更改的行';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft => '将 HEAD 区域复制到索引草稿';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft => '将工作区区域复制到索引草稿';

  @override
  String get gitUiUpdatingConflictRegions => '正在更新冲突区域';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return '含有冲突标记的结果区域：$count';
  }

  @override
  String get gitUiIgnoreLeftRegion => '忽略左侧建议';

  @override
  String get gitUiIgnoreRightRegion => '忽略右侧建议';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      '已将提交的草稿写入索引。较新的文本仍保留在此编辑器中。应用前请重新加载并检查当前版本。';

  @override
  String get gitUiNewerConflictDraftRetained => '提交的结果已保存。较新的结果草稿仍未保存。';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision => '此路径和修订没有可用的文件历史记录。';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft => '检查已保存的索引并保留草稿';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      '已保存的索引或其源内容已更改。较新的草稿已保留；应用前请单独检查这些更改。';

  @override
  String get gitUiReviewSavedMessage => '查看已保存的消息';

  @override
  String get gitUiSavedMessage => '已保存的消息';

  @override
  String get gitUiKeepThisMessage => '保留此消息';

  @override
  String get gitUiUseSavedMessage => '使用已保存的消息';

  @override
  String get gitUiCommitDraftChangedInAnotherWindow =>
      '此消息已在另一个窗口中更改。请先查看已保存的消息，再进行替换。';

  @override
  String get gitUiDiscardUnsavedCommitMessages => '丢弃未保存的提交消息？';

  @override
  String get gitUiMessagesCouldNotBeSavedStayInThisWindow =>
      '无法保存的消息仍保留在此窗口中。丢弃这些消息不会更改已保存的版本。';

  @override
  String get gitUiDiscardCommitMessages => '丢弃消息';
}
