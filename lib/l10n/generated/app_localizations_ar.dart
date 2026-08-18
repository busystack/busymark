// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'محرر لملفات Markdown ومشاريع التوثيق المتوافقة مع Writerside.';

  @override
  String get aboutBusyMark => 'حول BusyMark';

  @override
  String get aboutTagline => 'محرر Markdown وWriterside';

  @override
  String get aboutLicenseLabel => 'الترخيص';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'الموقع الإلكتروني';

  @override
  String get aboutSourceCode => 'الشيفرة المصدرية';

  @override
  String get reportIssue => 'الإبلاغ عن مشكلة';

  @override
  String get feedbackCategory => 'الفئة';

  @override
  String get feedbackChooseCategory => 'اختر فئة';

  @override
  String get feedbackCategoryProblem => 'مشكلة أو خطأ';

  @override
  String get feedbackCategoryFeature => 'طلب ميزة';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'مخاوف تتعلق بالخصوصية أو الأمان';

  @override
  String get feedbackCategoryUsability => 'مخاوف تتعلق بسهولة الاستخدام';

  @override
  String get feedbackCategoryOther => 'أخرى';

  @override
  String get feedbackSubject => 'الموضوع';

  @override
  String get feedbackMessage => 'رسالة مفصلة';

  @override
  String get feedbackReplyEmail => 'بريد إلكتروني للرد (اختياري)';

  @override
  String get feedbackIncludeTechnicalDetails => 'تضمين التفاصيل التقنية';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'عند التفعيل، لا يُضاف سوى إصدار نظام التشغيل Linux والإعدادات المحلية لتطبيق BusyMark. لا يتم إرفاق أي سجلات أو ملفات أو بيانات حساب أو معلومات تشخيصية أخرى.';

  @override
  String get feedbackSubmit => 'إرسال';

  @override
  String get feedbackSubmitting => 'جارٍ الإرسال…';

  @override
  String get feedbackCategoryRequired => 'اختر فئة.';

  @override
  String get feedbackSubjectLength => 'يجب أن يتراوح الموضوع بين 3 و120 حرفًا.';

  @override
  String get feedbackMessageLength => 'يجب أن تتراوح الرسالة بين 10 و5000 حرف.';

  @override
  String get feedbackReplyEmailInvalid =>
      'أدخل عنوان بريد إلكتروني صالحًا أو اترك هذا الحقل فارغًا.';

  @override
  String get feedbackConnectionFailure =>
      'تعذر على BusyMark الاتصال. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get feedbackTimeoutFailure => 'انتهت مهلة الطلب. حاول مرة أخرى.';

  @override
  String get feedbackRateLimitedFailure =>
      'تم إرسال عدد كبير جدًا من البلاغات عبر هذا الاتصال. انتظر ثم حاول مرة أخرى.';

  @override
  String get feedbackRejectedFailure =>
      'رفض الخادم البلاغ. تحقّق من حقول النموذج وحاول مرة أخرى.';

  @override
  String get feedbackServerFailure =>
      'تعذر على الخادم قبول البلاغ. حاول مرة أخرى لاحقًا.';

  @override
  String feedbackSuccess(String id) {
    return 'تم إرسال الملاحظات. معرّف المرجع: ⁨$id⁩';
  }

  @override
  String get advanced => 'خيارات متقدمة';

  @override
  String get addToGit => 'إضافة إلى Git';

  @override
  String get appearance => 'المظهر';

  @override
  String get apply => 'تطبيق';

  @override
  String get back => 'رجوع';

  @override
  String get bottomLeft => 'أسفل اليسار';

  @override
  String get bottomRight => 'أسفل اليمين';

  @override
  String get cancel => 'إلغاء';

  @override
  String get choose => 'اختيار';

  @override
  String get chooseLocation => 'اختر الموقع';

  @override
  String get copy => 'نسخ';

  @override
  String get copyName => 'نسخ الاسم';

  @override
  String get copyFileName => 'نسخ اسم الملف';

  @override
  String get copyPath => 'نسخ المسار';

  @override
  String get create => 'إنشاء';

  @override
  String get creating => 'جارٍ الإنشاء...';

  @override
  String get cut => 'قص';

  @override
  String get promoteHeading => 'ترقية العنوان';

  @override
  String get demoteHeading => 'خفض رتبة العنوان';

  @override
  String get moveSectionUp => 'نقل القسم إلى أعلى';

  @override
  String get moveSectionDown => 'نقل القسم إلى أسفل';

  @override
  String get confirmDeleteSectionTitle => 'حذف القسم؟';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'هل تريد حذف ⁨$name⁩ وكل محتوى قسمه؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get darkTheme => 'داكن';

  @override
  String get delete => 'حذف';

  @override
  String get discard => 'تجاهل';

  @override
  String get editor => 'محرر';

  @override
  String get file => 'ملف';

  @override
  String get fileHistory => 'سجل الملف';

  @override
  String get folder => 'مجلد';

  @override
  String get insert => 'إدراج';

  @override
  String get keyboardShortcuts => 'اختصارات لوحة المفاتيح';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get mainMenu => 'القائمة الرئيسية';

  @override
  String get fullScreen => 'ملء الشاشة';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'فتح';

  @override
  String get openInFiles => 'فتح في الملفات';

  @override
  String get pathActions => 'إجراءات المسار';

  @override
  String get outline => 'المخطط التفصيلي';

  @override
  String get overwrite => 'الكتابة فوق';

  @override
  String get paste => 'لصق';

  @override
  String get pasteWithoutFormatting => 'لصق بدون تنسيق';

  @override
  String get preview => 'معاينة';

  @override
  String get recent => 'الأخيرة';

  @override
  String get redo => 'إعادة';

  @override
  String get save => 'حفظ';

  @override
  String get search => 'بحث';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get settings => 'إعدادات';

  @override
  String get source => 'المصدر';

  @override
  String get split => 'تقسيم';

  @override
  String get systemTheme => 'النظام';

  @override
  String get theme => 'السمة';

  @override
  String get appLanguage => 'اللغة';

  @override
  String get systemLanguage => 'النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageNorwegian => 'Norsk';

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
  String get languageEstonian => 'Eesti';

  @override
  String get toggleSidebar => 'اللوحة الجانبية';

  @override
  String get topLeft => 'أعلى اليسار';

  @override
  String get topRight => 'أعلى اليمين';

  @override
  String get undo => 'تراجع';

  @override
  String get validate => 'تحقق';

  @override
  String get validation => 'التحقق';

  @override
  String get viewMode => 'وضع العرض';

  @override
  String get welcome => 'مرحبًا';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'الصور';

  @override
  String get openMarkdownFile => 'فتح ملف Markdown';

  @override
  String get markdownFileExtensions => '.md أو .markdown';

  @override
  String get openFolderOrWritersideProject => 'فتح مجلد أو مشروع Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'مجلد Markdown أو مشروع متوافق مع Writerside';

  @override
  String get noOpenFile => 'لا يوجد ملف مفتوح';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'حذف العنصر المحدد في الملفات أو إزالة الموضوع المحدد من جدول المحتويات';

  @override
  String get shortcutGroupGeneral => 'عام';

  @override
  String get shortcutNewDocument => 'مستند جديد';

  @override
  String get shortcutNewDocumentDescription =>
      'إنشاء مستند Markdown جديد غير محفوظ';

  @override
  String get shortcutOpenDescription =>
      'فتح ملف Markdown أو مجلد أو مشروع Writerside';

  @override
  String get shortcutSaveDescription => 'حفظ المستند الحالي';

  @override
  String get shortcutSearchDescription => 'البحث في مساحة العمل الحالية';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'إظهار مرجع اختصارات لوحة المفاتيح';

  @override
  String get shortcutMarkdownAndHtmlDescription => 'فتح مرجع Markdown وHTML';

  @override
  String get shortcutSettingsDescription => 'فتح إعدادات BusyMark';

  @override
  String get shortcutNextTab => 'علامة التبويب التالية';

  @override
  String get shortcutNextTabDescription =>
      'الانتقال إلى علامة التبويب المفتوحة التالية';

  @override
  String get shortcutPreviousTab => 'علامة التبويب السابقة';

  @override
  String get shortcutPreviousTabDescription =>
      'الانتقال إلى علامة التبويب المفتوحة السابقة';

  @override
  String get shortcutCloseTab => 'إغلاق علامة التبويب';

  @override
  String get shortcutCloseTabDescription => 'إغلاق علامة التبويب النشطة';

  @override
  String get shortcutCloseAllTabs => 'إغلاق كل علامات التبويب';

  @override
  String get shortcutCloseAllTabsDescription =>
      'إغلاق كل علامات التبويب المفتوحة';

  @override
  String get shortcutGroupTextEditing => 'تحرير النص';

  @override
  String get shortcutSelectAllDescription =>
      'في وضع المصدر، حدد النص بالكامل؛ في وضع المحرر، اضغط مرتين لتحديد كل الكتل';

  @override
  String get shortcutCutDescription => 'قص النص المحدد';

  @override
  String get shortcutCopyDescription => 'نسخ النص المحدد';

  @override
  String get shortcutPasteDescription => 'لصق محتوى الحافظة';

  @override
  String get shortcutPastePlainTextDescription => 'لصق نص الحافظة بدون تنسيق';

  @override
  String get shortcutUndoDescription => 'التراجع عن التعديل الأخير';

  @override
  String get shortcutRedoDescription => 'إعادة آخر تعديل تم التراجع عنه';

  @override
  String get shortcutInsertIndentation => 'إدراج مسافة بادئة';

  @override
  String get shortcutInsertIndentationDescription =>
      'إدراج مسافة بادئة عند المؤشر';

  @override
  String get shortcutOutdentSource => 'تقليل المسافة البادئة في المصدر';

  @override
  String get shortcutOutdentSourceDescription =>
      'إزالة مستوى واحد من المسافة البادئة في وضع المصدر';

  @override
  String get shortcutEscape => 'إغلاق البحث أو مسح تحديد الكتل';

  @override
  String get shortcutEscapeDescription =>
      'إغلاق البحث في مساحة العمل أو إلغاء تحديد الكتل في وضع المحرر';

  @override
  String get shortcutGroupFormatting => 'التنسيق';

  @override
  String get shortcutBoldDescription =>
      'تطبيق/إزالة التنسيق العريض على النص المحدد';

  @override
  String get shortcutItalicDescription =>
      'تطبيق/إزالة التنسيق المائل على النص المحدد';

  @override
  String get shortcutUnderlineDescription =>
      'تطبيق/إزالة التسطير على النص المحدد';

  @override
  String get shortcutLinkDescription => 'إدراج رابط أو تحريره';

  @override
  String get shortcutInlineCodeDescription =>
      'تطبيق/إزالة الكود المضمن على النص المحدد';

  @override
  String get shortcutStrikethroughDescription =>
      'تطبيق/إزالة الشطب على النص المحدد';

  @override
  String get shortcutGroupBlocks => 'الكتل';

  @override
  String get shortcutParagraphDescription => 'تحويل الكتلة الحالية إلى فقرة';

  @override
  String get shortcutHeading1Description => 'تحويل الكتلة الحالية إلى عنوان 1';

  @override
  String get shortcutHeading2Description => 'تحويل الكتلة الحالية إلى عنوان 2';

  @override
  String get shortcutHeading3Description => 'تحويل الكتلة الحالية إلى عنوان 3';

  @override
  String get shortcutHeading4Description => 'تحويل الكتلة الحالية إلى عنوان 4';

  @override
  String get shortcutHeading5Description => 'تحويل الكتلة الحالية إلى عنوان 5';

  @override
  String get shortcutHeading6Description => 'تحويل الكتلة الحالية إلى عنوان 6';

  @override
  String get shortcutGroupLists => 'القوائم';

  @override
  String get numberedList => 'قائمة مرقمة';

  @override
  String get shortcutNumberedListDescription => 'تبديل تنسيق القائمة المرقمة';

  @override
  String get bulletedList => 'قائمة نقطية';

  @override
  String get shortcutBulletedListDescription => 'تبديل تنسيق القائمة النقطية';

  @override
  String get checklist => 'قائمة تحقق';

  @override
  String get shortcutChecklistDescription => 'تطبيق/إزالة تنسيق قائمة التحقق';

  @override
  String get shortcutGroupSidebar => 'الشريط الجانبي';

  @override
  String get sidebarViewMenu => 'عرض الشريط الجانبي';

  @override
  String get createMarkdownFile => 'إنشاء ملف Markdown';

  @override
  String get createMarkdownFileDescription =>
      'بدء مستند Markdown محلي غير محفوظ';

  @override
  String get createWritersideProject => 'إنشاء مشروع Writerside';

  @override
  String get createWritersideProjectDescription =>
      'بدء مشروع محلي متوافق مع Writerside';

  @override
  String get defaultProjectName => 'التوثيق';

  @override
  String get defaultInstanceName => 'دليل المستخدم';

  @override
  String get defaultStartTopicTitle => 'بدء الاستخدام';

  @override
  String get projectName => 'اسم المشروع';

  @override
  String get directoryName => 'اسم الدليل';

  @override
  String get instanceName => 'اسم المثيل';

  @override
  String get instanceId => 'معرّف المثيل';

  @override
  String get startTopicTitle => 'عنوان موضوع البداية';

  @override
  String get location => 'الموقع';

  @override
  String get projectNameRequired => 'اسم المشروع مطلوب.';

  @override
  String get directoryNameRequired => 'اسم الدليل مطلوب.';

  @override
  String get useSingleSafeDirectoryName => 'استخدم اسم دليل واحدًا آمنًا.';

  @override
  String get useLowercaseIdentifier =>
      'استخدم معرّفًا بأحرف صغيرة يتكون من أحرف وأرقام وشرطات سفلية وواصلات.';

  @override
  String get startTopicTitleRequired => 'عنوان موضوع البداية مطلوب.';

  @override
  String get createWritersideProjectFailed => 'تعذر إنشاء مشروع Writerside.';

  @override
  String get settingsTitle => 'إعدادات BusyMark';

  @override
  String get autoSave => 'الحفظ التلقائي';

  @override
  String get autoSaveDescription =>
      'حفظ تغييرات الملف تلقائيًا بعد فترة قصيرة من عدم النشاط.';

  @override
  String get wordWrap => 'التفاف النص';

  @override
  String get editorFontSize => 'حجم خط المحرر';

  @override
  String get validateOnEdit => 'التحقق أثناء التحرير';

  @override
  String get clearRecentWorkspaces => 'مسح مساحات العمل الأخيرة';

  @override
  String get editingButtonsPosition => 'موضع أزرار التحرير';

  @override
  String get editingButtonsPositionDescription =>
      'اختر مكان ظهور أزرار تحرير WYSIWYG العائمة.';

  @override
  String get editingButtonsDirection => 'اتجاه أزرار التحرير';

  @override
  String get editingButtonsDirectionDescription =>
      'اختر ترتيب أزرار تحرير WYSIWYG العائمة أفقيًا أو عموديًا.';

  @override
  String get horizontal => 'أفقي';

  @override
  String get vertical => 'عمودي';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get allowRemoteImages => 'تحميل الصور البعيدة';

  @override
  String get allowRemoteImagesDescription =>
      'السماح بتحميل صور معاينة Markdown والمحرر من عناوين URL التي تستخدم http وhttps.';

  @override
  String get clearRemoteImagePermissions => 'مسح أذونات الصور البعيدة';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'نسيان مساحات العمل التي سُمح لها بتحميل الصور البعيدة.';

  @override
  String get clearGitWorkspaceTrust => 'مسح مساحات عمل Git الموثوقة';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'طلب التأكيد قبل تمكين ميزات Git لمساحات العمل التي سبق الوثوق بها.';

  @override
  String get settingsWindowSectionTitle => 'النافذة';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'التأكيد قبل الإغلاق عند وجود تغييرات غير محفوظة';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'اطلب التأكيد قبل إغلاق BusyMark عندما تحتوي المستندات على تغييرات غير محفوظة.';

  @override
  String get closeUnsavedChangesTitle => 'تغييرات غير محفوظة';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'يحتوي هذا المستند على تغييرات غير محفوظة. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'توجد تغييرات غير محفوظة في $count مستند. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
      many:
          'توجد تغييرات غير محفوظة في $count مستندًا. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
      few:
          'توجد تغييرات غير محفوظة في $count مستندات. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
      two:
          'يحتوي مستندان على تغييرات غير محفوظة. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
      one:
          'يحتوي مستند واحد على تغييرات غير محفوظة. هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
      zero: 'هل تريد حفظ التغييرات قبل إغلاق BusyMark؟',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'إلغاء';

  @override
  String get closeUnsavedChangesDiscard => 'تجاهل';

  @override
  String get closeUnsavedChangesSave => 'حفظ';

  @override
  String get currentFile => 'الملف الحالي';

  @override
  String get unsavedChanges => 'التغييرات غير المحفوظة';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'لديك تغييرات غير محفوظة في ⁨$fileName⁩. هل تريد حفظها قبل المتابعة؟';
  }

  @override
  String get fileChangedOnDisk => 'تغيّر الملف على القرص';

  @override
  String get fileChangedOnDiskMessage =>
      'تغيّر هذا الملف على القرص منذ فتحه. هل تريد الكتابة فوقه؟';

  @override
  String get untitledMarkdownFileName => 'بلا عنوان.md';

  @override
  String get unorderedList => 'قائمة غير مرتبة';

  @override
  String get orderedList => 'قائمة مرتبة';

  @override
  String get taskList => 'قائمة المهام';

  @override
  String get toggleTaskChecked => 'تبديل حالة إنجاز المهمة';

  @override
  String get indentListItem => 'زيادة إزاحة عنصر القائمة';

  @override
  String get outdentListItem => 'تقليل إزاحة عنصر القائمة';

  @override
  String get blockquote => 'اقتباس كتلي';

  @override
  String get codeBlock => 'كتلة كود';

  @override
  String get codeBlockLanguage => 'لغة كتلة الكود';

  @override
  String get image => 'صورة';

  @override
  String get inlineImage => 'صورة مضمنة';

  @override
  String get table => 'جدول';

  @override
  String get htmlBlock => 'كتلة HTML';

  @override
  String get htmlContentDefault => 'محتوى HTML';

  @override
  String get shortcutHtmlBlockDescription => 'إدراج كتلة HTML أو تحريرها';

  @override
  String get renderedHtml => 'HTML معروض';

  @override
  String get editHtml => 'تحرير HTML';

  @override
  String get htmlSource => 'مصدر HTML';

  @override
  String get thematicBreak => 'فاصل أفقي';

  @override
  String get bold => 'عريض';

  @override
  String get italic => 'مائل';

  @override
  String get underline => 'تسطير';

  @override
  String get strikethrough => 'شطب';

  @override
  String get inlineCode => 'كود مضمن';

  @override
  String get link => 'رابط';

  @override
  String get hardLineBreak => 'فاصل سطر صريح';

  @override
  String get textStyle => 'نمط النص';

  @override
  String get paragraph => 'فقرة';

  @override
  String get heading1 => 'عنوان 1';

  @override
  String get heading2 => 'عنوان 2';

  @override
  String get heading3 => 'عنوان 3';

  @override
  String get heading4 => 'عنوان 4';

  @override
  String get heading5 => 'عنوان 5';

  @override
  String get heading6 => 'عنوان 6';

  @override
  String headingLevelAbbreviation(int level) {
    return '⁨H$level⁩';
  }

  @override
  String get deleteTable => 'حذف الجدول';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'العمود $columnNumber';
  }

  @override
  String get insertColumnLeft => 'إدراج عمود إلى اليسار';

  @override
  String get insertColumnRight => 'إدراج عمود إلى اليمين';

  @override
  String get deleteColumn => 'حذف العمود';

  @override
  String tableRowNumber(int rowNumber) {
    return 'الصف $rowNumber';
  }

  @override
  String get insertRowAbove => 'إدراج صف أعلى';

  @override
  String get insertRowBelow => 'إدراج صف أسفل';

  @override
  String get deleteRow => 'حذف الصف';

  @override
  String get tableHeaderHint => 'رأس';

  @override
  String get tableCellHint => 'خلية';

  @override
  String get language => 'لغة';

  @override
  String get hideEditingButtons => 'إخفاء أزرار التحرير';

  @override
  String get showEditingButtons => 'إظهار أزرار التحرير';

  @override
  String get altText => 'النص البديل';

  @override
  String get editorPlaceholderText => 'نص';

  @override
  String get editorPlaceholderCode => 'كود';

  @override
  String get editorPlaceholderAltText => 'نص بديل';

  @override
  String get describeTheImage => 'صِف الصورة';

  @override
  String get columns => 'أعمدة';

  @override
  String get rows => 'صفوف';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'رأس $columnNumber';
  }

  @override
  String get tableCellDefault => 'خلية';

  @override
  String get noImageSource => 'لا يوجد مصدر للصورة';

  @override
  String get remoteImageBlocked => 'الصورة البعيدة محظورة';

  @override
  String get remoteImageBlockedTooltip =>
      'اختر ما إذا كان بإمكان BusyMark تحميل الصور البعيدة.';

  @override
  String get remoteImagesBlockedTitle => 'الصور البعيدة محظورة';

  @override
  String get remoteImagesBlockedMessage =>
      'يشير هذا المستند إلى صور من الإنترنت. قد يكشف تحميلها معلومات عن الشبكة لمضيف الصورة.';

  @override
  String get loadRemoteImagesForWorkspace => 'تحميل لمساحة العمل هذه';

  @override
  String get alwaysLoadRemoteImages => 'تحميل الصور البعيدة دائمًا';

  @override
  String get hideSidebar => 'إخفاء اللوحة الجانبية';

  @override
  String get showSidebar => 'إظهار اللوحة الجانبية';

  @override
  String get showPreview => 'إظهار المعاينة';

  @override
  String get hidePreview => 'إخفاء المعاينة';

  @override
  String get workspaceKindUnsavedMarkdown => 'ملف Markdown غير محفوظ';

  @override
  String get workspaceKindSingleMarkdown => 'ملف Markdown منفرد';

  @override
  String get workspaceKindMarkdownFolder => 'مجلد Markdown';

  @override
  String get workspaceKindWritersideModule => 'وحدة Writerside';

  @override
  String get problems => 'المشكلات';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تشخيص',
      many: '$count تشخيصًا',
      few: '$count تشخيصات',
      two: 'تشخيصان',
      one: 'تشخيص واحد',
      zero: 'لا توجد تشخيصات',
    );
    return '$_temp0';
  }

  @override
  String get files => 'ملفات';

  @override
  String get toc => 'جدول المحتويات';

  @override
  String get tocActions => 'إجراءات جدول المحتويات';

  @override
  String get markdownUnsaved => 'Markdown - غير محفوظ';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: 'لا ملفات',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'لا توجد ملفات';

  @override
  String get newFile => 'ملف جديد';

  @override
  String get noWritersideToc => 'لا يوجد جدول محتويات لـ Writerside';

  @override
  String get tocSection => 'قسم في جدول المحتويات';

  @override
  String get newTopic => 'موضوع جديد';

  @override
  String get newChildTopic => 'موضوع فرعي جديد';

  @override
  String get newSiblingTopic => 'موضوع جديد على المستوى نفسه';

  @override
  String get renameTopicFile => 'إعادة تسمية ملف الموضوع';

  @override
  String get topicPlacement => 'الموضع في جدول المحتويات';

  @override
  String get tocRoot => 'في جذر جدول المحتويات';

  @override
  String get afterSelectedTopic => 'بعد الموضوع المحدد';

  @override
  String get insideSelectedTopic => 'داخل الموضوع المحدد';

  @override
  String get pasteAfterTopic => 'لصق بعده';

  @override
  String get pasteAsChildTopic => 'لصق كموضوع فرعي';

  @override
  String get removeFromToc => 'إزالة من جدول المحتويات';

  @override
  String get confirmRemoveFromTocTitle => 'هل تريد الإزالة من جدول المحتويات؟';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'هل تريد إزالة ⁨$name⁩ من جدول المحتويات هذا؟ سيُحتفظ بملف الموضوع.';
  }

  @override
  String get confirmDeleteTopicTitle => 'هل تريد حذف ملف الموضوع؟';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'هل تريد حذف ⁨$name⁩ وإزالته من جميع جداول المحتويات؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get safeDeleteTopicFile => 'حذف ملف الموضوع بأمان…';

  @override
  String get removeTocElement => 'إزالة عنصر جدول المحتويات';

  @override
  String get reviewUsages => 'مراجعة الاستخدامات';

  @override
  String get deleteTopicFile => 'حذف ملف الموضوع';

  @override
  String get removeAction => 'إزالة';

  @override
  String topicRemovalSummary(String topic) {
    return 'أزِل «⁨$topic⁩» من مثيل المساعدة المحدد. سيُحتفظ بملف الموضوع.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'احذف «⁨$topic⁩» وحدّث المراجع إليه بأمان في مشروع Writerside هذا بأكمله.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سينتقل $count موضوع فرعي مستوى واحدًا إلى الأعلى.',
      many: 'سينتقل $count موضوعًا فرعيًا مستوى واحدًا إلى الأعلى.',
      few: 'ستنتقل $count موضوعات فرعية مستوى واحدًا إلى الأعلى.',
      two: 'سينتقل موضوعان فرعيان مستوى واحدًا إلى الأعلى.',
      one: 'سينتقل موضوع فرعي واحد مستوى واحدًا إلى الأعلى.',
      zero: 'لن يُنقل أي موضوع فرعي.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'يُستخدم هذا الموضوع كصفحة بدء لمثيل. راجع استخداماته وعيّن صفحة بدء أخرى قبل المتابعة.';

  @override
  String topicUsagesCount(int count) {
    return 'الاستخدامات ($count)';
  }

  @override
  String get noBreakingTopicUsages => 'لم يُعثر على مراجع قد تتعطل.';

  @override
  String get topicUsagesFound =>
      'عثر BusyMark على المراجع التالية لهذا الموضوع.';

  @override
  String get topicUsageTocElements => 'عناصر جدول المحتويات';

  @override
  String get topicUsageStartPages => 'صفحات البدء';

  @override
  String get topicUsageTopicLinks => 'روابط الموضوعات';

  @override
  String get topicUsageIncludes => 'التضمينات';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count استخدام',
      many: '$count استخدامًا',
      few: '$count استخدامات',
      two: 'استخدامان',
      one: 'استخدام واحد',
      zero: 'لا استخدامات',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'خيارات إعادة الهيكلة';

  @override
  String get updateUsagesAutomatically => 'تحديث الاستخدامات تلقائيًا';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'إزالة مراجع جدول المحتويات والتضمينات مع الاحتفاظ بنص الروابط.';

  @override
  String get manualUsageUpdatesRequired =>
      'تتطلب بعض الاستخدامات تغييرات يدوية قبل إعادة الهيكلة هذه.';

  @override
  String get setRedirectTo => 'تعيين إعادة التوجيه إلى';

  @override
  String get noRedirectDescription =>
      'عدم إعادة توجيه الصفحة القديمة المنشورة.';

  @override
  String get redirectTarget => 'وجهة إعادة التوجيه';

  @override
  String get remainingUsagesBlockRemoval =>
      'راجع الاستخدامات المتبقية وحدّثها قبل المتابعة، أو فعّل التحديثات التلقائية عند توفرها.';

  @override
  String usagesOfTopic(String topic) {
    return 'استخدامات ⁨$topic⁩';
  }

  @override
  String get noUsagesFound => 'لم يُعثر على استخدامات';

  @override
  String get outsideSelectedInstance => 'خارج المثيل المحدد';

  @override
  String get doRefactor => 'تنفيذ إعادة الهيكلة';

  @override
  String get orphanTopicTitle => 'لم يعد ملف الموضوع مستخدمًا';

  @override
  String get keepTopicFile => 'الاحتفاظ بملف الموضوع';

  @override
  String orphanTopicMessage(String topic) {
    return 'لم يعد «⁨$topic⁩» مستخدمًا في أي مكان ضمن مشروع Writerside هذا. احذف الملف أو احتفظ به لاستخدامه في مثيل آخر.';
  }

  @override
  String get defaultNewTopicTitle => 'موضوع جديد';

  @override
  String get topicTitle => 'عنوان الموضوع';

  @override
  String get fileName => 'اسم الملف';

  @override
  String get topicTitleRequired => 'عنوان الموضوع مطلوب.';

  @override
  String get fileNameRequired => 'اسم الملف مطلوب.';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get confirmDeleteFileTitle => 'حذف الملف؟';

  @override
  String get confirmDeleteFolderTitle => 'حذف المجلد؟';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'حذف ⁨$name⁩؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'حذف ⁨$name⁩ وكل الملفات داخله؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get useSingleSafeFileName => 'استخدم اسم ملف واحدًا آمنًا.';

  @override
  String useExpectedExtension(String extension) {
    return 'استخدم الامتداد ⁨$extension⁩ للتنسيق المحدد.';
  }

  @override
  String get useIdentifierCharacters =>
      'استخدم الأحرف والأرقام والشرطات السفلية والواصلات قبل الامتداد.';

  @override
  String get topicIdAlreadyExists => 'معرّف الموضوع موجود بالفعل.';

  @override
  String get createWritersideTopicFailed => 'تعذر إنشاء موضوع Writerside.';

  @override
  String get noOutline => 'لا يوجد مخطط تفصيلي';

  @override
  String expandKind(String kind) {
    return 'توسيع $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'طي $kind';
  }

  @override
  String get foldKindSection => 'قسم';

  @override
  String get foldKindList => 'قائمة';

  @override
  String get foldKindQuote => 'اقتباس';

  @override
  String get foldKindTag => 'وسم';

  @override
  String get sourceSearchPreviousMatch => 'التطابق السابق';

  @override
  String get sourceSearchNextMatch => 'التطابق التالي';

  @override
  String get sourceSearchCaseSensitive => 'حساس لحالة الأحرف';

  @override
  String get sourceSearchWholeWord => 'الكلمة بالكامل';

  @override
  String get sourceSearchRegex => 'تعبير نمطي';

  @override
  String get sourceSearchInvalidRegex => 'تعبير نمطي غير صالح';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'ملف كبير: تم إيقاف التمييز والطي مؤقتًا';

  @override
  String get noPreview => 'لا توجد معاينة';

  @override
  String get note => 'ملاحظة';

  @override
  String get tip => 'نصيحة';

  @override
  String get warning => 'تحذير';

  @override
  String get tabs => 'علامات تبويب';

  @override
  String get tab => 'علامة تبويب';

  @override
  String get procedure => 'إجراء';

  @override
  String get step => 'خطوة';

  @override
  String get topic => 'موضوع';

  @override
  String get chapter => 'فصل';

  @override
  String couldNotOpenTarget(String target) {
    return 'تعذر فتح ⁨$target⁩';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'لم يتم العثور على هدف الرابط: ⁨$targetPath⁩';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'لا يمكن فتح هذا النوع من الملفات في المحرر';

  @override
  String anchorNotFound(String anchor) {
    return 'لم يتم العثور على المُرسى: ⁨$anchor⁩';
  }

  @override
  String get noProblemsFound => 'لم يتم العثور على أي مشكلات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '⁨$relativePath⁩ - السطر ⁨$lineNumber⁩';
  }

  @override
  String get untitledResult => 'نتيجة بلا عنوان';

  @override
  String get documentKindMarkdownFile => 'ملف Markdown';

  @override
  String get documentKindWritersideMarkdownTopic => 'موضوع Writerside Markdown';

  @override
  String get documentKindWritersideXmlTopic => 'موضوع Writerside XML';

  @override
  String get documentKindWritersideTree => 'شجرة Writerside';

  @override
  String get documentKindConfigurationFile => 'ملف التكوين';

  @override
  String get documentKindVariablesFile => 'ملف المتغيرات';

  @override
  String get documentKindCategoriesFile => 'ملف الفئات';

  @override
  String get documentKindResourceFile => 'ملف الموارد';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'فشل الفتح: ⁨$error⁩';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'تعذر إنشاء مشروع Writerside: ⁨$error⁩';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'تعذر إنشاء موضوع Writerside: ⁨$error⁩';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'تعذر فتح الملف: ⁨$error⁩';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'اختر مكان حفظ ملف Markdown هذا.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'تم حظر الحفظ: تغيّر الملف على القرص.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'فشل الحفظ: ⁨$error⁩';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'فشلت عملية الملف: ⁨$error⁩';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'فشل التحقق: ⁨$error⁩';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'المسار غير موجود: ⁨$path⁩';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'الدليل الهدف موجود بالفعل وليس فارغًا: ⁨$path⁩';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'المسار الهدف موجود بالفعل وليس دليلاً: ⁨$path⁩';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'الملف المُنشأ موجود بالفعل: ⁨$path⁩';
  }

  @override
  String get errorParentDirectoryRequired => 'الدليل الأصل مطلوب.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'الدليل الأصل غير موجود: ⁨$path⁩';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'المجلد غير موجود: ⁨$path⁩';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'المسار موجود بالفعل: ⁨$path⁩';
  }

  @override
  String get errorFileNameRequired => 'اسم الملف مطلوب.';

  @override
  String get errorFileNameUnsafe =>
      'يجب أن يكون اسم الملف مقطع مسار آمنًا واحدًا.';

  @override
  String get errorFileOperationInvalidTarget =>
      'لا يمكن نقل مجلد إلى داخل نفسه.';

  @override
  String get errorFileOperationOutsideRoot =>
      'يجب أن تبقى عملية الملف داخل مساحة العمل.';

  @override
  String get errorFileOperationRoot =>
      'لا يمكن تغيير جذر مساحة العمل من شجرة الملفات.';

  @override
  String get errorProjectNameRequired => 'اسم المشروع مطلوب.';

  @override
  String get errorDirectoryNameRequired => 'اسم الدليل مطلوب.';

  @override
  String get errorDirectoryNameUnsafe =>
      'يجب أن يكون اسم الدليل مقطع مسار واحدًا آمنًا.';

  @override
  String get errorInstanceIdInvalid =>
      'يجب أن يبدأ معرّف المثيل بحرف صغير وأن يحتوي فقط على أحرف صغيرة وأرقام وشرطات سفلية وواصلات.';

  @override
  String get errorTopicFileInvalid =>
      'يجب أن يكون اسم ملف الموضوع اسم ملف Markdown بدون فواصل المسار.';

  @override
  String get errorTopicTitleRequired => 'عنوان الموضوع مطلوب.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'جذر وحدة Writerside غير موجود: ⁨$path⁩';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'يجب أن تكون وحدة Writerside مفتوحة لإنشاء موضوع.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'لا تحتوي وحدة Writerside على شجرة مثيل للمساعدة.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'ملف شجرة Writerside غير موجود: ⁨$path⁩';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'معرّف الموضوع \"⁨$topicId⁩\" موجود بالفعل في وحدة المساعدة هذه.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'ملف الموضوع موجود بالفعل: ⁨$path⁩';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'الموضوع المرجعي غير موجود في الشجرة المحددة: ⁨$topic⁩';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'لم يعد عنصر جدول المحتويات المحدد موجودًا.';

  @override
  String get errorWritersideTocInvalidMove =>
      'لا يمكن نقل عنصر في جدول المحتويات إلى نفسه أو إلى أحد العناصر الفرعية التابعة له.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'لا يمكن حذف موضوع البدء ⁨$topic⁩. اختر صفحة بدء أخرى أولًا.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'استخدم الحذف الآمن لملفات موضوعات Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'تعذّر إكمال فحص استخدامات الموضوع. لم تُغيَّر أي ملفات.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'لا تزال بعض استخدامات الموضوع تتطلب المعالجة. راجعها قبل المتابعة.';

  @override
  String get errorWritersideRedirectInvalid =>
      'لم يعد هدف إعادة التوجيه المحدد صالحًا. حدده مرة أخرى.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'تعذّر التراجع بالكامل عن إزالة الموضوع. راجع هذه المسارات قبل المتابعة: ⁨$paths⁩';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'يجب أن يكون جذر المواضيع دليلاً نسبيًا آمنًا.';

  @override
  String get errorTopicFileNameUnsafe =>
      'يجب أن يكون اسم ملف الموضوع مقطع مسار واحدًا آمنًا.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'يجب أن يتطابق امتداد ملف الموضوع مع التنسيق المحدد (⁨$extension⁩).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'يجب أن يحتوي اسم ملف الموضوع على أحرف وأرقام وشرطات سفلية وواصلات فقط.';

  @override
  String errorUnknown(String code) {
    return 'خطأ غير معروف: ⁨$code⁩';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'تعذرت قراءة بيانات تعريف الملف: ⁨$error⁩';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'تم اكتشاف مساحة عمل كبيرة. تم تخطي بعض الملفات للحفاظ على استجابة التطبيق.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'تعذر فحص عنصر مساحة العمل: ⁨$error⁩';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'يتجاوز الملف حد التحليل التلقائي في الإصدار التجريبي.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'تعذرت قراءة ملف Markdown: ⁨$error⁩';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'كتلة سمات عنوان Writerside غير سليمة.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'معرّف عنوان مكرر \"⁨$id⁩\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'تُعامل عناوين H1 الإضافية في المستوى الأعلى كفصول.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'لا يحتوي موضوع Writerside Markdown على عنوان H1 أو عنوان في البيانات التمهيدية.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'موضوع XML يفتقد عنوانًا.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'الموضوع \"⁨$fileName⁩\" يفتقد عنوانًا.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'البيانات التمهيدية غير مغلقة.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'عنصر HTML غير آمن.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'هدف الرابط غير موجود: ⁨$targetPath⁩';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'المُرسى \"⁨$anchor⁩\" غير موجود.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'الصورة \"⁨$destination⁩\" تفتقد النص البديل.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'الصورة غير موجودة: ⁨$destination⁩';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML غير صالح: ⁨$message⁩';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'يجب أن يكون جذر writerside.cfg هو <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'إعلان snippets يفتقد السمة src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'إعلان instance-groups يفتقد السمة src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'وضع keymaps غير مدعوم: ⁨$mode⁩';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'إعلان instance يفتقد السمة src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'لا يسجل writerside.cfg أي مثيل.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'يجب أن يكون جذر ملف .tree هو <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'ملف تعريف المثيل يفتقد السمة id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'لا يتطابق اسم ملف الشجرة بدون الامتداد مع معرّف المثيل \"⁨$id⁩\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'المثيل غير المخصص للمكتبة يفتقد start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'صفحة البدء \"⁨$startPage⁩\" غير موجودة.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'يظهر الموضوع \"⁨$topic⁩\" أكثر من مرة في جدول محتويات هذا المثيل.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'يجب أن يحتوي إعلان المتغير على اسم وقيمة.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'تم الإعلان عن المتغير \"⁨$name⁩\" أكثر من مرة.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'الفئة تفتقد السمة id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'تم الإعلان عن الفئة \"⁨$id⁩\" أكثر من مرة.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'تم الإعلان عن ترتيب الفئة \"⁨$order⁩\" أكثر من مرة.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'يجب أن يكون جذر ملف .topic هو <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'موضوع XML يفتقد معرّف الجذر.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'يجب أن يتطابق معرّف جذر موضوع XML \"⁨$id⁩\" مع اسم الملف \"⁨$expectedId⁩\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'يظهر معرّف العنصر \"⁨$elementId⁩\" أكثر من مرة.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> يفتقد السمة href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'يتطلب وضع Writerside ملف writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'دليل تكوين البناء المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'دليل مواصفات API المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'دليل المقتطفات المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'ملف المتغيرات المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'ملف الفئات المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'ملف مجموعات المثيلات المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'شجرة المثيل المسجلة \"⁨$source⁩\" غير موجودة.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'تعذرت قراءة ملف الموضوع: ⁨$error⁩';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'دليل المواضيع الافتراضي مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'دليل المواضيع المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'دليل الصور المحدد مفقود: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'يظهر معرّف العنصر \"⁨$id⁩\" أكثر من مرة.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'يشير جدول المحتويات إلى موضوع مفقود \"⁨$topic⁩\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'قيمة href الخارجية \"⁨$href⁩\" غير صالحة.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'لم يتم الإعلان عن المتغير \"⁨%$name%⁩\".';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'لا يمكن حل رابط الموضوع \"⁨$destination⁩\".';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'المُرسى \"⁨$anchor⁩\" غير موجود في \"⁨$targetName⁩\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> يفتقد السمة from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'مصدر التضمين \"⁨$from⁩\" غير موجود.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'عنصر التضمين \"⁨$elementId⁩\" غير موجود في \"⁨$from⁩\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'فئة seealso \"⁨$ref⁩\" غير معلنة.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'مرجع الموضوع \"⁨$reference⁩\" غامض.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'تشخيص غير معروف: ⁨$code⁩';
  }

  @override
  String get close => 'إغلاق';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'فروقات Git';

  @override
  String get gitShowDiff => 'إظهار الفروقات';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'القديم ⁨$oldRange⁩ ← الجديد ⁨$newRange⁩';
  }

  @override
  String get gitDiffNoLines => 'لا أسطر';

  @override
  String get gitUnavailableTitle => 'Git غير متاح';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'ثبّت Git أو اضبط BusyMark لاستخدام ملف Git تنفيذي متاح. ⁨$reason⁩',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'الوثوق بمساحة العمل هذه لاستخدام Git؟';

  @override
  String get gitTrustRequiredMessage =>
      'يمكن لمستودعات Git تشغيل برامج من خلال الخطافات والمرشحات وإعدادات أخرى. ثق بمساحة العمل هذه قبل أن يقرأ BusyMark بيانات المستودع أو يمكّن إجراءات Git.';

  @override
  String get gitTrustWorkspace => 'الوثوق بمساحة العمل';

  @override
  String get gitNotRepositoryTitle => 'ليس مستودع Git';

  @override
  String get gitNotRepositoryMessage => 'مساحة العمل هذه ليست داخل مستودع Git.';

  @override
  String get gitInitializeRepository => 'تهيئة المستودع';

  @override
  String get gitDetachedHead => 'HEAD منفصل';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'HEAD منفصل عند ⁨$commit⁩';
  }

  @override
  String get gitNoUpstream => 'لا يوجد فرع منبع';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count التزام غير مرفوع',
      many: '$count التزامًا غير مرفوع',
      few: '$count التزامات غير مرفوعة',
      two: 'التزامان غير مرفوعين',
      one: 'التزام واحد غير مرفوع',
      zero: 'لا توجد التزامات غير مرفوعة',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count التزام لسحبه',
      many: '$count التزامًا لسحبها',
      few: '$count التزامات لسحبها',
      two: 'التزامان لسحبهما',
      one: 'التزام واحد لسحبه',
      zero: 'لا توجد التزامات لسحبها',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'نظيف';

  @override
  String get gitConflicts => 'تعارضات';

  @override
  String get gitChanges => 'التغييرات';

  @override
  String get gitHistory => 'السجل';

  @override
  String get gitBranches => 'الفروع';

  @override
  String get gitBranchActions => 'إجراءات الفروع';

  @override
  String get gitPull => 'سحب';

  @override
  String get gitPush => 'دفع';

  @override
  String get gitCommit => 'إنشاء التزام';

  @override
  String get gitSelectForCommit => 'تحديد للالتزام';

  @override
  String get gitRemoveFromCommit => 'استبعاد من الالتزام';

  @override
  String get gitDiscard => 'تجاهل';

  @override
  String get gitOpenFile => 'فتح الملف';

  @override
  String get gitMarkResolved => 'وضع علامة بأنه محلول';

  @override
  String get gitUntracked => 'الملفات غير المتتبعة';

  @override
  String get gitCommitMessage => 'رسالة الالتزام';

  @override
  String get gitCommitSelectedFiles => 'الملفات المحددة';

  @override
  String get gitCommitNoSelectedFiles =>
      'حدد ملفًا واحدًا على الأقل قبل إنشاء الالتزام.';

  @override
  String get gitCommitMessageRequired => 'أدخل رسالة الالتزام.';

  @override
  String get gitCreateBranch => 'إنشاء فرع';

  @override
  String get gitNewBranch => '+ فرع جديد';

  @override
  String get gitBranchName => 'اسم الفرع';

  @override
  String get gitSwitchBranch => 'تبديل';

  @override
  String get gitNoChanges => 'لا توجد تغييرات';

  @override
  String get gitNoHistory => 'لا يوجد سجل';

  @override
  String get gitNoBranches => 'لا توجد فروع';

  @override
  String get gitNoDiff => 'لا يوجد فرق لعرضه';

  @override
  String get gitBinaryFile =>
      'ملف ثنائي. لا يعرض BusyMark رقع الملفات الثنائية.';

  @override
  String get gitUnsavedChangesBanner =>
      'لا تُضمّن تغييرات المحرر غير المحفوظة حتى يتم حفظها.';

  @override
  String get gitConfirmDiscardTitle => 'تجاهل تغييرات Git؟';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستتم استعادة الملفات المتعقبة المحددة من Git.',
      many: 'ستتم استعادة الملفات المتعقبة المحددة من Git.',
      few: 'ستتم استعادة الملفات المتعقبة المحددة من Git.',
      two: 'ستتم استعادة الملفين المتعقبين المحددين من Git.',
      one: 'ستتم استعادة الملف المتعقب المحدد من Git.',
      zero: 'لا توجد ملفات متعقبة محددة لاستعادتها من Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستُحذف الملفات غير المتعقبة المحددة.',
      many: 'ستُحذف الملفات غير المتعقبة المحددة.',
      few: 'ستُحذف الملفات غير المتعقبة المحددة.',
      two: 'سيُحذف الملفان غير المتعقبين المحددان.',
      one: 'سيُحذف الملف غير المتعقب المحدد.',
      zero: 'لا توجد ملفات غير متعقبة محددة لحذفها.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستتم استعادة الملفات المحددة أو حذفها حسب حالتها في Git.',
      many: 'ستتم استعادة الملفات المحددة أو حذفها حسب حالتها في Git.',
      few: 'ستتم استعادة الملفات المحددة أو حذفها حسب حالتها في Git.',
      two: 'ستتم استعادة الملفين المحددين أو حذفهما حسب حالتهما في Git.',
      one: 'ستتم استعادة الملف المحدد أو حذفه حسب حالته في Git.',
      zero: 'لا توجد ملفات محددة لاستعادتها أو حذفها.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'التبديل إلى ⁨$branch⁩؟';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'سيعيد BusyMark تحميل مساحة العمل من القرص بعد أن يبدّل Git الفروع.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'تعيين فرع منبع؟';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'ليس لهذا الفرع فرع منبع. يمكن لـ BusyMark دفع ⁨$branch⁩ وتعيينه فرعًا منبعًا عندما يكون هناك مستودع بعيد واحد فقط مُعدّ.';
  }

  @override
  String get gitProjectHistory => 'المشروع';

  @override
  String get gitFileHistory => 'الملف الحالي';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '⁨+$additions -$deletions⁩';
  }

  @override
  String get fileActions => 'إجراءات الملف';

  @override
  String get gitStatusAdded => 'مضاف';

  @override
  String get gitStatusDeleted => 'محذوف';

  @override
  String get gitStatusRenamed => 'أُعيدت تسميته';

  @override
  String get gitStatusCopied => 'منسوخ';

  @override
  String get gitStatusUntracked => 'غير متعقب';

  @override
  String get gitStatusConflicted => 'متعارض';

  @override
  String get gitStatusIgnored => 'تم تجاهله';

  @override
  String get gitStatusTypeChanged => 'تغير النوع';

  @override
  String get gitStatusModified => 'معدّل';

  @override
  String get gitStatusUnknown => 'غير معروف';

  @override
  String get gitErrorUnavailable => 'Git غير متاح.';

  @override
  String get gitErrorNotRepository => 'مساحة العمل هذه ليست مستودع Git.';

  @override
  String get gitErrorUnsafePath => 'حظر BusyMark مسار Git غير آمن.';

  @override
  String get gitErrorInvalidBranchName => 'أدخل اسم فرع صالحًا.';

  @override
  String get gitErrorNoRemote => 'لم يتم إعداد مستودع Git بعيد.';

  @override
  String get gitErrorNoUpstream => 'لم يتم إعداد فرع منبع.';

  @override
  String get gitErrorMultipleRemotes =>
      'تم إعداد عدة مستودعات بعيدة. اختر فرع منبع خارج هذا الإصدار من BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'احفظ تغييرات محرر BusyMark أو تجاهلها قبل تبديل الفروع.';

  @override
  String get gitErrorDiverged =>
      'تباعد الفرع. عالج الدمج أو إعادة التأسيس خارج هذا الإصدار من BusyMark.';

  @override
  String get gitErrorAuthentication =>
      'فشلت مصادقة Git. في حزمة snap، قد تتطلب مستودعات SSH البعيدة توصيل واجهة ssh-keys.';

  @override
  String get gitErrorNetwork => 'فشلت عملية Git عبر الشبكة.';

  @override
  String get gitErrorConflict => 'أبلغ Git عن تعارضات لم تُحل.';

  @override
  String get gitErrorCommandFailed => 'فشل أمر Git.';

  @override
  String get markdownAndHtml => 'Markdown و HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'كتل Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'بنى الكتل المدعومة في مصدر Markdown والمعاينة.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown داخل السطر';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'تنسيق يمكن استخدامه داخل الفقرات وعناصر القوائم وخلايا الجداول.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'كتل HTML الخام';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'وسوم HTML الكتلية الآمنة التي تعرضها ودجات معاينة BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'وسوم HTML داخل السطر';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'وسوم HTML آمنة داخل السطر تعرض بدون إظهار الوسوم حرفيًا.';

  @override
  String get markdownHtmlSafety => 'قواعد الأمان';

  @override
  String get markdownHtmlSafetyDescription =>
      'يتم تحليل HTML الخام وتنظيفه قبل عرضه في المعاينة.';

  @override
  String get markdownHtmlHeadings => 'العناوين';

  @override
  String get markdownHtmlParagraphs => 'الفقرات';

  @override
  String get markdownHtmlLists => 'القوائم';

  @override
  String get markdownHtmlHtmlContainers => 'الحاويات';

  @override
  String get markdownHtmlHtmlTextBlocks => 'كتل النص';

  @override
  String get markdownHtmlHtmlFigures => 'الأشكال والصور';

  @override
  String get markdownHtmlHtmlPreformatted => 'كود منسق مسبقًا';

  @override
  String get markdownHtmlHtmlDisclosure => 'كتل قابلة للفتح';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'قوائم وصفية';

  @override
  String get markdownHtmlHtmlFormattingTags => 'وسوم التنسيق';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'وسوم الكود داخل السطر';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'وسوم نصية دلالية';

  @override
  String get markdownHtmlSanitizedPreview => 'معاينة منظفة';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'يتم تحويل HTML المسموح به إلى كتل معاينة BusyMark، وليس عرضه في متصفح.';

  @override
  String get markdownHtmlSourcePreserved => 'يتم حفظ المصدر';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'يتم حفظ HTML الخام غير المعدل كما هو تمامًا كنص مصدر.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown داخل HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'تعرض علامات Markdown داخل HTML الخام كنص حرفي.';

  @override
  String get markdownHtmlBlockedContent => 'المحتوى النشط محظور';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'يتم حظر السكربتات والأنماط والإطارات والنماذج وSVG وMathML والأحداث والسمات غير الآمنة.';

  @override
  String get markdownHtmlSafeUrls => 'عناوين URL آمنة فقط';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'تسمح الروابط بـ http وhttps وmailto وtel والروابط النسبية والمقاطع؛ وتحظر المخططات غير الآمنة.';

  @override
  String get exportAsPdf => 'تصدير بصيغة PDF';

  @override
  String get pdfExportDescription =>
      'اختر تخطيط الصفحة لإنشاء ملف PDF متقن ومستقل.';

  @override
  String get pdfRemoteImagesNote =>
      'لا تُنزّل الصور البعيدة أثناء التصدير. تُضمّن الصور المحلية عند توفرها.';

  @override
  String get pdfPageSize => 'حجم الصفحة';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter (رسائل)';

  @override
  String get pdfOrientation => 'الاتجاه';

  @override
  String get pdfPortrait => 'عمودي';

  @override
  String get pdfLandscape => 'أفقي';

  @override
  String get pdfMargins => 'الهوامش';

  @override
  String get pdfMarginNarrow => 'ضيقة';

  @override
  String get pdfMarginNormal => 'عادية';

  @override
  String get pdfMarginWide => 'عريضة';

  @override
  String get pdfIncludePageNumbers => 'تضمين أرقام الصفحات';

  @override
  String get export => 'تصدير';

  @override
  String get exportingPdf => 'جارٍ تصدير PDF…';

  @override
  String get fileTypePdf => 'مستند PDF';

  @override
  String pdfExported(String fileName) {
    return 'تم تصدير $fileName.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return 'تم تصدير $fileName. صور تعذر تضمينها: $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'مكوّن تصدير PDF مفقود. أعد تثبيت BusyMark ثم حاول مجددًا.';

  @override
  String get pdfExportTimedOut =>
      'استغرق تصدير PDF وقتًا طويلًا جدًا وتم إيقافه.';

  @override
  String get pdfExportFailed =>
      'تعذر على BusyMark تصدير هذا المستند بصيغة PDF.';

  @override
  String get shortcutExportPdfDescription =>
      'تصدير مستند Markdown النشط بصيغة PDF.';
}
