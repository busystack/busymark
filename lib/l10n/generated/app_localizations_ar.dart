// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'ملاحظة جديدة من النص المحتفَظ به';

  @override
  String get notesAccountThrottled =>
      'طلب Nextcloud التوقف مؤقتًا. انتظر قبل بدء تسجيل الدخول مجددًا.';

  @override
  String get notesSettingsRefreshing => 'جارٍ تحديث Notes بعد تأكيد الإعدادات';

  @override
  String get notesExportOperationFailed =>
      'فشل التصدير قبل النشر. تحقق من المصدر والوجهة ثم أعد التصدير.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'حُفظت الملاحظة المستردة لكن تعذر فتحها. عالج تعديلات المحرر أو الخصائص المعلقة ثم افتح هذه الملاحظة الموجودة.';

  @override
  String get notesSettingsPendingNotes =>
      'تمنع الملاحظات المعلقة أو التعارضات أو عمليات الإنشاء غير المؤكدة هذا التغيير. زامنها أو راجعها في Notes ثم أعد حفظ مسودة الإعدادات المحفوظة.';

  @override
  String get notesSettingsPendingAttachments =>
      'تمنع عمليات المرفقات المعلقة هذا التغيير. راجع المرفقات في Notes ثم أعد حفظ مسودة الإعدادات المحفوظة.';

  @override
  String get notesAccountServerAddress =>
      'استخدم عنوان HTTPS الأساسي لخادم Nextcloud وأعد تسجيل الدخول. تعذر التحقق من العنوان أو إعادة التوجيه.';

  @override
  String get notesAccountUnsupported =>
      'Notes غير متاح أو واجهته غير مدعومة. فعّل Nextcloud Notes بواجهة API ذات الإصدار الرئيسي 1 والفرعي 4 أو أحدث.';

  @override
  String get notesAccountAuthorizeAgain =>
      'رفض Nextcloud بيانات الاعتماد. أعد تفويض الحساب أو الاتصال به.';

  @override
  String get notesAccountCheckForbidden =>
      'رفض Nextcloud فحص إمكانات Notes. اطلب من مسؤول الخادم السماح به ثم أعد المحاولة.';

  @override
  String get notesAccountMalformed =>
      'تعذر التحقق من استجابة Nextcloud. تحقق من تثبيت الخادم ثم أعد تسجيل الدخول.';

  @override
  String get notesAccountTimedOut =>
      'انتهت مهلة تسجيل الدخول. ابدأ مجددًا وأكمل التفويض في المتصفح.';

  @override
  String get notesAccountBrowserUnavailable =>
      'تعذر فتح متصفح النظام. تحقق من المتصفح الافتراضي ثم أعد تسجيل الدخول.';

  @override
  String get notesAccountNetwork =>
      'تعذر الوصول إلى Nextcloud. تحقق من الاتصال والخادم ثم أعد تسجيل الدخول.';

  @override
  String get notesAccountRejected =>
      'رفض Nextcloud طلب الإمكانات. تحقق من صلاحية الوصول مع المسؤول ثم أعد المحاولة.';

  @override
  String get notesAccountFailed =>
      'تعذر إكمال إعداد الحساب. أعد محاولة تسجيل الدخول.';

  @override
  String get notesTransferSourceChanged =>
      'تغير المصدر بعد المراجعة. راجع الملف الحالي أو التقط نسخة جديدة قبل إعادة المحاولة.';

  @override
  String get notesTransferUnreadable =>
      'تعذرت قراءة المصدر. تحقق من الوصول إلى الملف أو المجلد ثم راجعه مجددًا.';

  @override
  String get notesTransferInvalidSnapshot =>
      'النسخة غير صالحة أو غير مدعومة. اختر نسخة BusyMark Notes صالحة أو مصدر Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'تتجاوز الوسائط حد الاستيراد. قلل وسائط العنصر المتأثر ثم راجعه مجددًا.';

  @override
  String get notesTransferUnsafeSource =>
      'يحتوي المصدر على مسار غير آمن. اختر ملفات داخل مجلد المصدر ثم راجعها مجددًا.';

  @override
  String get notesTransferDestination =>
      'تعذرت كتابة التصدير. تحقق من الوصول والمساحة المتاحة في الوجهة ثم أعد التصدير.';

  @override
  String get notesTransferOperationFailed =>
      'تعذر إكمال النقل. راجع العناصر المتأثرة وأعد المحاولة. تبقى العناصر المستوردة سابقًا محفوظة.';

  @override
  String get notesExportPublishedWithOmissions =>
      'التصدير متاح مع عناصر مستثناة';

  @override
  String get notesBatchUnchanged => 'القيم المطلوبة مضبوطة بالفعل.';

  @override
  String get notesBatchReadOnly =>
      'هذه الملاحظة للقراءة فقط. لا يمكن تغيير الخصائص المحمية؛ ما زال تغيير المفضلة مسموحًا.';

  @override
  String get notesBatchReviewChanged =>
      'تغيرت هذه الملاحظة بعد المراجعة. راجع حالتها الحالية قبل تطبيق الإجراء مجددًا.';

  @override
  String get notesBatchMissing =>
      'لم تعد هذه الملاحظة متاحة. حدّث القائمة وراجع العناصر المستهدفة مجددًا.';

  @override
  String get notesBatchStorage =>
      'فشل الحفظ المحلي. تحقق من التخزين وأعد محاولة هذا العنصر؛ تبقى العناصر الناجحة محفوظة.';

  @override
  String get notesRemoteReviewChanged =>
      'تغيرت ملاحظة الخادم. مسودة الدمج محفوظة. راجع المقارنة المحدثة واختر طريقة الحل مجددًا.';

  @override
  String get notesReviewRemote => 'راجعت إصدار الخادم الحالي';

  @override
  String get wsModuleCapsNotPublished => 'لا يُنشر تنسيق أحرف الوحدة.';

  @override
  String get wsTitleOverridesAction => 'عناوين المثيل وجدول المحتويات…';

  @override
  String get wsHeadingNotPublished => 'لا ينشرها هذا المنشئ.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'لا ينشر الباني المثبّت عناوين النسخ في مواضيع Markdown. تُحفظ العلامات الحالية؛ افحصها في المصدر.';

  @override
  String get wsTopicIdentity => 'معرّف الموضوع';

  @override
  String get wsElementAnchor => 'مرساة العنصر';

  @override
  String get wsHeadingText => 'نص العنوان';

  @override
  String get wsDefaultTitle => 'العنوان الافتراضي';

  @override
  String get wsTopicNavigation => 'تنقّل الموضوع';

  @override
  String get wsHeadingOptions => 'سمات العنوان';

  @override
  String get wsDocumentOptions => 'إعدادات المستند';

  @override
  String get wsSettingsPresent => 'توجد إعدادات مكتوبة';

  @override
  String get wsTitleOverrideExplanation =>
      'يتجاوز العنوان المنشور؛ يبقى نص العنوان كما هو.';

  @override
  String get wsIgnoreVariables => 'معاملة المتغيرات كنص حرفي';

  @override
  String get wsIgnoreVariablesExplanation =>
      'عند التفعيل، لا يُستبدل النص الذي يشبه المتغيرات.';

  @override
  String get wsInstanceSelection => 'نُسخ المساعدة';

  @override
  String get wsInstanceExplanation =>
      'اختر المخرجات بالأسماء أو المجموعات أو القوائم أو الاستثناءات أو التعبيرات.';

  @override
  String get wsFilterExplanation =>
      'يرشّح المحتوى المعاد استخدامه حسب المعايير؛ لا يختار نسخة مساعدة.';

  @override
  String get wsContextHelp => 'معرّف المساعدة السياقية';

  @override
  String get wsCapitalization => 'حالة الأحرف';

  @override
  String get wsLibraryTopic => 'موضوع مكتبة';

  @override
  String get wsLastModified => 'آخر تعديل';

  @override
  String get wsMissingTopicHeading => 'لا يوجد H1 للموضوع. أضفه في المصدر.';

  @override
  String get wsMultipleTopicHeadings =>
      'يحدّد أول H1 عنوان الموضوع. عناوين H1 اللاحقة مستقلة.';

  @override
  String get wsTopicIdentityMismatch =>
      'يختلف id الجذر عن معرّف الموضوع المشتق من اسم الملف. استخدم إعادة تسمية ملف الموضوع أو افحص المصدر.';

  @override
  String get wsUnsupportedProperties =>
      'تُحفظ السمات غير المدعومة. افحصها في المصدر.';

  @override
  String get wsGeneratedAnchor => 'مرساة مولّدة؛ إدخال قيمة ينشئ تجاوزًا.';

  @override
  String get wsHeadingBuilderLimitation =>
      'لا ينشر الباني المثبّت سمات H1. تخص العنوان وليس جذر XML.';

  @override
  String get closeOtherTabs => 'إغلاق علامات التبويب الأخرى';

  @override
  String get tocTopicFromTemplate => 'موضوع من قالب...';

  @override
  String get tocSaveAsTemplate => 'حفظ كقالب';

  @override
  String get tocTemplateDialog => 'إنشاء موضوع من قالب';

  @override
  String get tocTemplatesEditor => 'قوالب الملفات والشيفرة';

  @override
  String get tocEditTemplates => 'تحرير القوالب...';

  @override
  String get tocCreateCustomTemplate => 'إنشاء قالب مخصص...';

  @override
  String get tocTemplateCreated => 'تم إنشاء القالب';

  @override
  String get tocTemplateDefault => 'افتراضي';

  @override
  String get tocTemplateCustom => 'مخصص';

  @override
  String get tocTemplateFilename => 'اسم الملف:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'داخلي';

  @override
  String get tocTemplateUnnamed => 'بلا اسم';

  @override
  String get tocTemplateNew => 'قالب جديد...';

  @override
  String get tocTemplateName => 'الاسم:';

  @override
  String get tocTemplateExtension => 'الامتداد:';

  @override
  String get tocTemplateLoadError =>
      'تعذر تحميل القوالب. لم تتغير القوالب الموجودة.';

  @override
  String get tocTemplateSaveError =>
      'تعذر حفظ القوالب. لا تزال تعديلاتك متاحة هنا.';

  @override
  String get tocTemplateConflict =>
      'تغيرت القوالب في نافذة أخرى. ألغِ وأعد فتح المحرر.';

  @override
  String get tocTemplateDuplicateName =>
      'يوجد بالفعل قالب بهذا الاسم والامتداد.';

  @override
  String get tocTemplateFormat => 'التنسيق:';

  @override
  String get tocTemplateReset => 'إعادة تعيين';

  @override
  String get tocTemplateRetry => 'إعادة المحاولة';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'إزالة $count من عناصر جدول المحتويات';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'لن تُحذف ملفات المصدر المرتبطة بعناصر جدول المحتويات هذه.';

  @override
  String get tocOk => 'موافق';

  @override
  String get tocSelectExistingTopic =>
      'اختر موضوعًا لإضافته إلى النسخة الحالية';

  @override
  String get tocGroupName => 'اسم المجموعة';

  @override
  String get tocMoveLineUp => 'نقل السطر لأعلى';

  @override
  String get tocMoveLineDown => 'نقل السطر لأسفل';

  @override
  String get tocEmptyMdTopic => 'موضوع MD فارغ';

  @override
  String get tocEmptyXmlTopic => 'موضوع XML فارغ';

  @override
  String get tocCopySpecial => 'نسخ خاص';

  @override
  String tocCopyFileName(String name) {
    return 'اسم ملف الموضوع \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'مسار ملف الموضوع';

  @override
  String tocCopyTopicTitle(String title) {
    return 'عنوان الموضوع \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'معرّف عنصر جدول المحتويات \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'اسم ملف الموضوع';

  @override
  String get tocCopyTopicTitleUnavailable => 'عنوان الموضوع';

  @override
  String get tocCopyElementIdUnavailable => 'معرّف عنصر جدول المحتويات';

  @override
  String get tocEditTitleAction => 'تحرير العنوان...';

  @override
  String get tocEditTitleDialog => 'تحرير العنوان';

  @override
  String get tocRemoveElementAction => 'إزالة عنصر جدول المحتويات...';

  @override
  String get tocSetHomePage => 'تعيين كصفحة رئيسية';

  @override
  String tocGoToElement(String fileName) {
    return 'الانتقال إلى عنصر جدول المحتويات في \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'مزامنة جدول المحتويات والمحرر';

  @override
  String get tocEmptyGroupAction => 'مجموعة فارغة';

  @override
  String get tocNewEmptyGroup => 'مجموعة فارغة جديدة';

  @override
  String get tocGroupAction => 'تجميع';

  @override
  String get tocNewGroup => 'مجموعة جديدة';

  @override
  String get tocSortChildren => 'ترتيب المواضيع الفرعية أبجديًا';

  @override
  String get tocLinkTopicFiles => 'ربط ملفات المواضيع بجدول المحتويات...';

  @override
  String get addLocalMarkdownFiles => 'إضافة ملفات Markdown محلية';

  @override
  String get tocTitleField => 'عنوان جدول المحتويات:';

  @override
  String get tocTopicTitleField => 'عنوان الموضوع:';

  @override
  String get tocAdvancedSettings => 'إعدادات متقدمة';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'عنوان \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'عنوان خاص بجدول المحتويات:';

  @override
  String get tocInstanceTitleExplanation =>
      'يُستخدم للمثيل الحالي فقط. يُورث من عنوان الموضوع افتراضيًا.';

  @override
  String get tocOnlyTitleExplanation =>
      'يُستخدم في جدول المحتويات فقط. يُورث افتراضيًا من عنوان الموضوع أو من العنوان الخاص بالمثيل إن وُجد. تجد شرحًا للعناوين';

  @override
  String get tocTitleDocumentationLink => 'هنا';

  @override
  String get tocFindUsages => 'بحث';

  @override
  String get tocRefactorMenu => 'إعادة الهيكلة';

  @override
  String get tocSafeDelete => 'حذف آمن';

  @override
  String get tocDuplicate => 'تكرار';

  @override
  String get tocDuplicateFilename => 'اسم ملف الموضوع:';

  @override
  String get tocDuplicateDialog => 'تكرار الموضوع';

  @override
  String get pdfTitlePage => 'صفحة العنوان';

  @override
  String get pdfIncludeTitlePage => 'تضمين صفحة العنوان';

  @override
  String get pdfTitlePageNote =>
      'لا تحتوي هذه الصفحة على رأس أو تذييل أو رقم صفحة ظاهر.';

  @override
  String get pdfTitlePageTitle => 'العنوان';

  @override
  String get pdfTitlePageSubtitle => 'العنوان الفرعي';

  @override
  String get pdfTitlePageAuthor => 'المؤلف';

  @override
  String get pdfTitlePageOrganization => 'المؤسسة';

  @override
  String get pdfTitlePageVersion => 'الإصدار';

  @override
  String get pdfTitlePageDate => 'التاريخ';

  @override
  String get pdfTitlePageTitleRequired => 'أدخل عنوانًا لصفحة العنوان.';

  @override
  String get pdfTocSectionNote => 'يبدأ في صفحة منفصلة وقد يمتد إلى عدة صفحات.';

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
  String get copyPlainText => 'نسخ كنص عادي';

  @override
  String get clipboardCopyFailed => 'تعذّر نسخ المحتوى المحدد إلى الحافظة.';

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
  String get promoteSection => 'ترقية القسم';

  @override
  String get demoteSection => 'خفض رتبة القسم';

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
  String get commandUnavailableInContext =>
      'هذا الأمر غير متاح في السياق الحالي.';

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
  String get reading => 'وضع القراءة';

  @override
  String get removeFromRecent => 'إزالة من الأخيرة';

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
  String get shortcutNewDocument => 'إنشاء';

  @override
  String get shortcutNewDocumentDescription =>
      'إنشاء ملف Markdown أو مشروع Writerside';

  @override
  String get shortcutOpenDescription =>
      'فتح ملف Markdown أو مجلد أو مشروع Writerside';

  @override
  String get shortcutSaveDescription => 'حفظ المستند الحالي';

  @override
  String get shortcutSearchDescription => 'البحث في مساحة العمل الحالية';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'تخصيص اختصارات لوحة مفاتيح التطبيق';

  @override
  String get shortcutSyntaxReferenceDescription => 'فتح مرجع بناء الجملة';

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
  String get wordWrapDescription =>
      'التفاف السطور الطويلة لتلائم عرض المحرر بدلاً من التمرير أفقيًا.';

  @override
  String get editorFontSize => 'حجم خط المحرر';

  @override
  String get validateOnEdit => 'التحقق أثناء التحرير';

  @override
  String get clearRecentWorkspaces => 'مسح السجل الأخير';

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
  String get settingsEditingButtonsSectionTitle => 'أزرار التحرير';

  @override
  String get spellingDictionaries => 'قواميس التدقيق الإملائي';

  @override
  String get spellingDictionariesDescription =>
      'تثبيت قواميس التدقيق الإملائي وإدارتها';

  @override
  String get settingsDictionariesSectionTitle => 'القواميس';

  @override
  String get availableSpellingDictionaries => 'القواميس المتاحة';

  @override
  String get customSpellingDictionaries => 'القواميس المخصصة';

  @override
  String get spellingDictionaryProblems => 'مشكلات القواميس';

  @override
  String get settingsWindowSectionTitle => 'النافذة';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'إعادة فتح مساحة العمل السابقة عند بدء التشغيل';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'افتح مساحة العمل وعلامات التبويب من الجلسة السابقة عند بدء BusyMark.';

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
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توجد تغييرات غير محفوظة في ⁨$count⁩ مستند. احفظها قبل المتابعة؟',
      many: 'توجد تغييرات غير محفوظة في ⁨$count⁩ مستندًا. احفظها قبل المتابعة؟',
      few: 'توجد تغييرات غير محفوظة في ⁨$count⁩ مستندات. احفظها قبل المتابعة؟',
      two: 'يوجد مستندان يحتويان على تغييرات غير محفوظة. احفظهما قبل المتابعة؟',
      one: 'يوجد مستند واحد يحتوي على تغييرات غير محفوظة. احفظه قبل المتابعة؟',
      zero: 'لا توجد مستندات ذات تغييرات غير محفوظة.',
    );
    return '$_temp0';
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
  String get video => 'فيديو';

  @override
  String get openVideo => 'تشغيل الفيديو';

  @override
  String get pauseVideo => 'إيقاف الفيديو مؤقتًا';

  @override
  String get videoUnavailable => 'الفيديو غير متاح';

  @override
  String get videoPreview => 'معاينة الفيديو';

  @override
  String get diagnosticWritersideVideoMissingSource => 'يفتقد الفيديو سمة src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'مصدر فيديو غير مدعوم: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'ملف الفيديو غير موجود: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'صورة معاينة الفيديو غير موجودة: $preview';
  }

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
  String get insertBlankLine => 'إدراج سطر فارغ';

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
  String get tableAlignmentUnspecified => 'المحاذاة: غير محددة';

  @override
  String get tableAlignmentLeft => 'المحاذاة: إلى اليسار';

  @override
  String get tableAlignmentCenter => 'المحاذاة: إلى الوسط';

  @override
  String get tableAlignmentRight => 'المحاذاة: إلى اليمين';

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
  String get newSiblingTopic => 'موضوع جديد';

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
  String get removeTocElements => 'إزالة عناصر جدول المحتويات';

  @override
  String get reviewUsages => 'مراجعة الاستخدامات';

  @override
  String get deleteTopicFile => 'حذف ملف الموضوع';

  @override
  String get removeAction => 'إزالة';

  @override
  String topicRemovalSummary(String topic) {
    return 'هل تريد إزالة عنصر جدول المحتويات «⁨$topic⁩»؟ لن يُحذف الملف المصدر المرتبط بجدول المحتويات.';
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
  String get topicIsHomePageRemovalWarning =>
      'هذا الموضوع هو الصفحة الرئيسية لهذا المثيل. اختر صفحة رئيسية أخرى قبل إزالته من جدول المحتويات.';

  @override
  String get newHomePage => 'الصفحة الرئيسية الجديدة';

  @override
  String get chooseHomePage => 'اختر صفحة رئيسية';

  @override
  String get noHomePageReplacement =>
      'أضف موضوعًا مؤهلًا آخر إلى هذا المثيل أو اربطه به قبل إزالة صفحته الرئيسية.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'هذا الموضوع هو الصفحة الرئيسية لمثيل. عيّن صفحة رئيسية أخرى قبل حذف ملفه المصدر.';

  @override
  String topicUsagesCount(int count) {
    return 'تم العثور على $count من مواضع الاستخدام.';
  }

  @override
  String get noBreakingTopicUsages => 'لم يُعثر على مراجع قد تتعطل.';

  @override
  String get topicUsagesFound =>
      'عثر BusyMark على المراجع التالية لهذا الموضوع.';

  @override
  String get topicUsageTocElements => 'عناصر جدول المحتويات';

  @override
  String get topicUsageStartPages => 'الصفحات الرئيسية';

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
  String get setRedirectTo => 'تعيين إعادة التوجيه إلى:';

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
  String get preview => 'معاينة';

  @override
  String get topicRenamePreviewTitle => 'معاينة إعادة التسمية';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'المسار: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'معرّف الموضوع: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'المثيل $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'الملفات المتأثرة';

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
  String get sourceSearchReplacement => 'استبدال بـ';

  @override
  String get sourceSearchReplaceCurrent => 'استبدال المطابقة الحالية';

  @override
  String get sourceSearchReplaceAndFindNext => 'استبدال والبحث عن التالي';

  @override
  String get sourceSearchReplaceAll => 'استبدال الكل';

  @override
  String get workspaceReplace => 'استبدال في مساحة العمل';

  @override
  String get reviewReplacements => 'مراجعة الاستبدالات';

  @override
  String get applyReplacements => 'تطبيق الاستبدالات';

  @override
  String get skippedFiles => 'الملفات المتخطاة';

  @override
  String get workspaceReplaceDirtyBuffer => 'محتوى المحرر غير المحفوظ';

  @override
  String get workspaceReplaceDiskContent => 'المحتوى المحفوظ على القرص';

  @override
  String selectFileMatches(int count) {
    return 'تحديد كل المطابقات وعددها $count';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'تم استبدال $matches مطابقة في $files ملفًا؛ وتم تخطي $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '⁨$encoding⁩ · ⁨$lineEnding⁩ · سطر جديد نهائي';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '⁨$encoding⁩ · ⁨$lineEnding⁩ · بلا سطر جديد نهائي';
  }

  @override
  String get normalizeLineEndings => 'توحيد نهايات الأسطر';

  @override
  String get mixedLineEndingsSavePrompt =>
      'يحتوي هذا المستند على نهايات أسطر مختلطة. اختر تنسيقًا.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return 'يستخدم الملف ⁨$fileName⁩ نهايات أسطر مختلطة. اختر التنسيق قبل الاستبدال.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'تم تخطي ملف يتجاوز الحجم المسموح.';

  @override
  String get workspaceReplaceIssueUnreadable => 'تم تخطي ملف تعذرت قراءته.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'تم تخطي ملف بترميز UTF-8 غير صالح.';

  @override
  String get workspaceReplaceIssueTruncated => 'تم اقتطاع معاينة الاستبدال.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'تم تخطي ملف تغيّر بعد المعاينة.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'تم تخطي مخزن محرر مؤقت تغيّر بعد المعاينة.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'اختر توحيد LF أو CRLF قبل الاستبدال.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'توقف التراجع لأن الملف تغير بالتزامن. قد تبقى بعض الاستبدالات؛ حُفظ المحتوى المُزاح في المسار أدناه.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'لم تُطبّق أي استبدالات لأن المجموعة التي تمت مراجعتها تعذر حفظها بأمان.';

  @override
  String externalChangesTitle(String fileName) {
    return 'تغييرات خارجية — ⁨$fileName⁩';
  }

  @override
  String get externalFileDeleted => 'تم حذف هذا الملف من القرص.';

  @override
  String get externalFileChanged =>
      'تغيّر هذا الملف على القرص بينما لديك تعديلات غير محفوظة.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'تمت استعادة المحتوى غير المحفوظ للملف $fileName. راجعه، ثم احفظه أو احفظه باسم جديد أو تجاهله.';
  }

  @override
  String get compare => 'مقارنة';

  @override
  String get reloadFromDisk => 'إعادة التحميل من القرص';

  @override
  String get keepMine => 'الاحتفاظ بنسختي';

  @override
  String get saveAs => 'حفظ باسم';

  @override
  String get workspaceSearchIncomplete =>
      'تظهر بعض النتائج فقط. اعرض المزيد أو ضيّق نطاق البحث.';

  @override
  String get workspaceSearchShowMore => 'عرض المزيد من النتائج';

  @override
  String get workspaceSearchSkippedFiles =>
      'البحث غير مكتمل. تجاوز حجم هذه الملفات 1 MiB أو تعذّرت قراءتها:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'ملف كبير: تم إيقاف التمييز والطي مؤقتًا';

  @override
  String get nothingToRead => 'لا يوجد محتوى للقراءة';

  @override
  String get admonition => 'تنبيه';

  @override
  String get quote => 'اقتباس';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'تعذر تحديث العناصر الأخيرة: $error.';
  }

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
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'تمت استعادة ⁨$count⁩ مستند غير محفوظ. راجع كل مستند قبل حفظه أو تجاهله.',
      many:
          'تمت استعادة ⁨$count⁩ مستندًا غير محفوظ. راجع كل مستند قبل حفظه أو تجاهله.',
      few:
          'تمت استعادة ⁨$count⁩ مستندات غير محفوظة. راجع كل مستند قبل حفظه أو تجاهله.',
      two: 'تمت استعادة مستندين غير محفوظين. راجعهما قبل حفظهما أو تجاهلهما.',
      one: 'تمت استعادة مستند واحد غير محفوظ. راجعه قبل حفظه أو تجاهله.',
      zero: 'لم تتم استعادة أي مستندات غير محفوظة.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'تعذر استعادة ⁨$count⁩ سجل استعادة تالف. لا تزال سجلات الاسترداد الصالحة متاحة.',
      many:
          'تعذر استعادة ⁨$count⁩ سجل استعادة تالفًا. لا تزال سجلات الاسترداد الصالحة متاحة.',
      few:
          'تعذر استعادة ⁨$count⁩ سجلات استعادة تالفة. لا تزال سجلات الاسترداد الصالحة متاحة.',
      two:
          'تعذر استعادة سجلَّي استعادة تالفين. لا تزال سجلات الاسترداد الصالحة متاحة.',
      one:
          'تعذر استعادة سجل استعادة تالف واحد. تم الاحتفاظ بملف الاسترداد الأصلي للفحص.',
      zero: 'لا توجد سجلات استعادة تالفة.',
    );
    return '$_temp0';
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
      'لا تحتوي وحدة Writerside على شجرة مثيل.';

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
    return 'لا يمكن حذف الصفحة الرئيسية $topic. اختر صفحة رئيسية أخرى أولًا.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'لا يمكن لإعادة التسمية تحديث كل مراجع المشروع بأمان لأن $count من ملفات المواضيع في الوحدة $module لم تُحلَّل: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'تحتوي ملفات مشروع Writerside على تغييرات غير محفوظة. عالجها وأنشئ معاينة جديدة لإعادة التسمية.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'تغيّرت مجموعة وحدات مشروع Writerside. أنشئ معاينة جديدة لإعادة التسمية قبل إعادة الهيكلة.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'ينشر المثيل \"$instanceId\" اسم ملف ويب غير صالح \"$webFileName\" للموضوع \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'ينشر المثيل \"$instanceId\" الموضوعين \"$firstTopic\" و\"$secondTopic\" باسم \"$webFileName\".';
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
  String get gitStaged => 'مُرحَّلة';

  @override
  String get gitUnstaged => 'غير مُرحَّلة';

  @override
  String get gitHistory => 'السجل';

  @override
  String get gitBranches => 'الفروع';

  @override
  String get gitActions => 'إجراءات Git';

  @override
  String get gitPull => 'سحب';

  @override
  String get gitFetch => 'جلب';

  @override
  String get gitPush => 'دفع';

  @override
  String get gitCommit => 'إنشاء التزام';

  @override
  String get gitSelectForCommit => 'تجهيز الملف';

  @override
  String get gitRemoveFromCommit => 'إلغاء تجهيز الملف';

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
      'جهّز ملفًا واحدًا على الأقل قبل إنشاء الالتزام.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف مُرحّل',
      many: '$count ملفًا مُرحّلًا',
      few: '$count ملفات مرحّلة',
      two: 'ملفان مرحّلان',
      one: 'ملف مُرحَّل واحد',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'خارج مساحة العمل';

  @override
  String get gitCommitMessageRequired => 'أدخل رسالة الالتزام.';

  @override
  String get gitCreateBranch => 'إنشاء فرع';

  @override
  String get gitNewBranch => 'فرع جديد';

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
  String gitBinaryFileInfo(int size) {
    return 'ملف ثنائي ($size بايت). لا يعرض BusyMark رقع الملفات الثنائية.';
  }

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
      other:
          'ستتم استعادة جميع التغييرات المُرحَّلة وغير المُرحَّلة في الملفات المتعقبة المحددة إلى HEAD.',
      one:
          'ستتم استعادة جميع التغييرات المُرحَّلة وغير المُرحَّلة في الملف المتعقب المحدد إلى HEAD.',
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
  String get gitProjectHistory => 'تاريخ المشروع';

  @override
  String get gitFileHistory => 'تاريخ الملف';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'يتطلب سجل الملف فتح ملف Markdown.';

  @override
  String get gitLoadMore => 'تحميل المزيد';

  @override
  String get gitChangesInCommit => 'التغييرات في هذا الإيداع';

  @override
  String get gitCompareWithCurrent => 'مقارنة بالإصدار الحالي';

  @override
  String get gitRestoreVersion => 'استعادة هذا الإصدار';

  @override
  String get gitConfirmRestoreTitle => 'هل تريد استعادة إصدار الملف هذا؟';

  @override
  String get gitConfirmRestoreMessage =>
      'سيستبدل BusyMark ملف شجرة العمل الحالي بالإصدار المحدد من الإيداع. سيبقى الملف المستعاد غير مُرحَّل.';

  @override
  String get gitCommitActions => 'إجراءات الإيداع';

  @override
  String get gitResetCurrentBranchToHere => 'إعادة تعيين الفرع الحالي إلى هنا…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'إعادة تعيين ⁨$branch⁩ إلى ⁨$commit⁩؟';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'سينقل هذا الفرع ⁨$branch⁩ إلى الإيداع ⁨$commit⁩. اختر كيفية تحديث Git للفهرس وشجرة العمل.';
  }

  @override
  String get gitReset => 'إعادة تعيين';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'نقل الفرع فقط. إبقاء الفهرس وشجرة العمل دون تغيير؛ تظل الاختلافات عن الإيداع المحدد مُرحَّلة.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'نقل الفرع وإعادة تعيين الفهرس. إبقاء شجرة العمل دون تغيير، مع ترك الاختلافات غير مُرحَّلة.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'نقل الفرع وإعادة تعيين الفهرس وشجرة العمل. تُلغى التغييرات المتتبعة؛ وقد تُحذف الملفات غير المتتبعة التي تعيق العملية.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'نقل الفرع وإعادة تعيين الملفات المتتبعة مع الاحتفاظ بالتغييرات المحلية. يتوقف Git إذا تعارضت هذه التغييرات مع إعادة التعيين.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '⁨+$additions -$deletions⁩';
  }

  @override
  String get fileActions => 'إجراءات الملف';

  @override
  String get actions => 'إجراءات';

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
  String get gitErrorResetDirtyWorkspace =>
      'احفظ تغييرات محرر BusyMark أو تجاهلها قبل إعادة تعيين الفرع الحالي.';

  @override
  String get gitErrorRestoreStagedFile =>
      'أزل الملف من منطقة التجهيز قبل استعادة إصدار سابق.';

  @override
  String get gitErrorResetDetachedHead => 'انتقل إلى فرع قبل إعادة تعيينه.';

  @override
  String get gitErrorDiverged =>
      'تباعد الفرع. عالج الدمج أو إعادة التأسيس خارج هذا الإصدار من BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'يحتاج Git إلى اسم المؤلف وعنوان بريده الإلكتروني قبل إنشاء الالتزام.';

  @override
  String get gitAuthorIdentityTitle => 'هوية مؤلف Git';

  @override
  String get gitAuthorIdentityMessage =>
      'أدخل الهوية التي يجب أن يسجلها Git في الالتزامات. سيحفظها BusyMark ويعيد محاولة هذا الالتزام.';

  @override
  String get gitAuthorName => 'الاسم';

  @override
  String get gitAuthorEmail => 'البريد الإلكتروني';

  @override
  String get gitAuthorIdentityGlobal => 'استخدامها لجميع المستودعات';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'عند التثبيت كحزمة Snap، ينطبق هذا على المستودعات المفتوحة في BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'حفظ وإنشاء الالتزام';

  @override
  String get gitErrorAuthentication => 'فشلت مصادقة Git.';

  @override
  String get gitErrorNetwork => 'فشلت عملية Git عبر الشبكة.';

  @override
  String get gitErrorConflict => 'أبلغ Git عن تعارضات لم تُحل.';

  @override
  String get gitErrorCommandFailed => 'فشل أمر Git.';

  @override
  String get syntaxReference => 'مرجع بناء الجملة';

  @override
  String get syntaxReferenceMarkdownBlocks => 'كتل Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'بنى الكتل المدعومة في مصدر Markdown والمعاينة.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown داخل السطر';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'تنسيق يمكن استخدامه داخل الفقرات وعناصر القوائم وخلايا الجداول.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'كتل HTML الخام';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'وسوم HTML الكتلية الآمنة التي تعرضها ودجات معاينة BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'وسوم HTML داخل السطر';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'وسوم HTML آمنة داخل السطر تعرض بدون إظهار الوسوم حرفيًا.';

  @override
  String get syntaxReferenceHeadings => 'العناوين';

  @override
  String get syntaxReferenceParagraphs => 'الفقرات';

  @override
  String get syntaxReferenceLists => 'القوائم';

  @override
  String get syntaxReferenceHtmlContainers => 'الحاويات';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'كتل النص';

  @override
  String get syntaxReferenceHtmlFigures => 'الأشكال والصور';

  @override
  String get syntaxReferenceHtmlPreformatted => 'كود منسق مسبقًا';

  @override
  String get syntaxReferenceHtmlDisclosure => 'كتل قابلة للفتح';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'قوائم وصفية';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'وسوم التنسيق';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'وسوم الكود داخل السطر';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'وسوم نصية دلالية';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'يتم تحويل HTML المسموح به إلى كتل معاينة BusyMark، وليس عرضه في متصفح.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'يتم حفظ HTML الخام غير المعدل كما هو تمامًا كنص مصدر.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'تعرض علامات Markdown داخل HTML الخام كنص حرفي.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'يتم حظر السكربتات والأنماط والإطارات والنماذج وSVG وMathML والأحداث والسمات غير الآمنة.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'تسمح الروابط بـ http وhttps وmailto وtel والروابط النسبية والمقاطع؛ وتحظر المخططات غير الآمنة.';

  @override
  String get syntaxReferenceCategory => 'الفئة';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'المخططات وواجهات API';

  @override
  String get syntaxReferenceCategoryMathematics => 'الرياضيات';

  @override
  String get syntaxReferenceExample => 'مثال';

  @override
  String get syntaxReferenceIdentifiers => 'المعرّفات والأسماء البديلة';

  @override
  String get syntaxReferenceScope => 'النطاق';

  @override
  String get syntaxReferenceLimitation => 'قيد في BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'الوثائق الرسمية';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Markdown في Writerside فقط';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Markdown وXML في Writerside فقط';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'أشكال Markdown الأساسية التي يستطيع BusyMark كتابتها ومعاينتها.';

  @override
  String get syntaxReferenceParagraphExample => 'فقرة نصية.';

  @override
  String get syntaxReferenceTableLimitation =>
      'تستخدم الجداول صيغة الأنابيب في GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'مسافتان في نهاية السطر، \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'يقبل BusyMark مجموعة محدودة وآمنة من HTML الخام في مصدر Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'تعمل كتل Mermaid وPlantUML وD2 وOpenAPI المسيّجة في مصدر Markdown. لا تتأثر معرّفات السياج بحالة الأحرف، ويحافظ BusyMark على التهجئة الأصلية.';

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
      'استخدم محتوى YAML أو JSON داخل سياج. لا يعامل BusyMark مستند YAML أو JSON كاملاً عشوائياً على أنه مرجع OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'كتل شيفرة دلالية للمخططات';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'تدعم صيغتا code-block وsrc الدلاليتان Mermaid وPlantUML وD2، لا OpenAPI، وتعملان داخل مشاريع Writerside فقط.';

  @override
  String get syntaxReferenceReferencedDiagramSource => 'مصدر مخطط مُشار إليه';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'يجب أن تكون المسارات نسبية وأن تبقى داخل مشروع Writerside المفتوح؛ صيغة السياج مع src خاصة بـMarkdown في Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'يدعم BusyMark تعبيرات TeX، وليس مستندات TeX أو LaTeX الكاملة.';

  @override
  String get syntaxReferenceInlineMath => 'رياضيات مضمنة';

  @override
  String get syntaxReferenceGithubMath =>
      'رياضيات GitHub بعلامة الدولار والفاصلة العليا المائلة';

  @override
  String get syntaxReferenceDisplayMath => 'رياضيات معروضة';

  @override
  String get syntaxReferenceMathFence => 'سياج math';

  @override
  String get syntaxReferenceTexFence => 'سياج tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'لا يتعرّف BusyMark على ⁨\\(...\\)⁩ أو ⁨\\[...\\]⁩ كمحددات رياضيات في Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'خارج وضع Writerside، يبقى سياج tex كتلة شيفرة عادية.';

  @override
  String get syntaxReferenceWritersideMathElement => 'عنصر math في Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'عنصر math صيغة دلالية في Writerside، وليس HTML MathML خاماً مسموحاً به.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'كتلة شيفرة TeX دلالية';

  @override
  String get syntaxReferenceWritersideDescription =>
      'لا تُفسَّر هذه الامتدادات المحددة إلا داخل مشاريع Writerside المفتوحة.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'اقتباس كتلي للتنبيه';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'يكون الاقتباس الكتلي العادي تلميحاً في Markdown ضمن Writerside؛ ويبقى اقتباساً عادياً في Markdown العادي.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'تنبيهات دلالية';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'لا يفسر Markdown العادي عناصر Writerside الدلالية هذه.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'عنوان قابل للطي';

  @override
  String get syntaxReferenceCollapsibleCode => 'سياج شيفرة قابل للطي';

  @override
  String get syntaxReferenceSemanticCollapsibles => 'محتوى دلالي قابل للطي';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'يدعم BusyMark صيغ chapter وprocedure وcode-block وقائمة التعريفات القابلة للطي، وليس فهرس Writerside كاملاً.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'كتل شيفرة دلالية للرياضيات والمخططات';

  @override
  String get syntaxReferenceVideo => 'فيديو Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'يستخدم الفيديو المحلي صورة preview-src محلية؛ ويجب أن تكون المصادر المستضافة عناوين HTTPS مدعومة من YouTube أو Vimeo.';

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
  String get exportFormat => 'تنسيق الإخراج';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تحذيرات',
      one: 'تحذير واحد',
    );
    return '$fileName تم تصديره مع $_temp0.';
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
  String get visualizationRendering => 'جارٍ التصيير…';

  @override
  String get visualizationStale => 'عرض آخر تصيير صالح';

  @override
  String get visualizationShowSource => 'إظهار المصدر';

  @override
  String get visualizationShowRender => 'إظهار التصيير';

  @override
  String get visualizationFitWidth => 'ملاءمة مع العرض';

  @override
  String get visualizationSaveImage => 'حفظ الصورة';

  @override
  String get visualizationCopyImage => 'نسخ الصورة';

  @override
  String get visualizationImageCopied => 'تم نسخ الصورة';

  @override
  String get visualizationOpenApiReference => 'فتح مرجع API';

  @override
  String get visualizationValid => 'صالح';

  @override
  String get visualizationInvalid => 'غير صالح';

  @override
  String get visualizationServers => 'الخوادم';

  @override
  String get visualizationPaths => 'المسارات';

  @override
  String get visualizationOperations => 'العمليات';

  @override
  String get visualizationTags => 'الوسوم';

  @override
  String get visualizationNoOperations => 'لا توجد عمليات مطابقة';

  @override
  String get visualizationSearchOperations => 'البحث في العمليات';

  @override
  String get visualizationRenderFailed => 'تعذر تصيير هذا التصور.';

  @override
  String get visualizationRetry => 'إعادة المحاولة';

  @override
  String visualizationSaved(String fileName) {
    return 'تم حفظ $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'تصدير المستند النشط أو وحدة Writerside بصيغة PDF.';

  @override
  String get instances => 'المثيلات';

  @override
  String get newInstance => 'مثيل جديد';

  @override
  String get newTocLibrary => 'مكتبة جديدة لجدول المحتويات';

  @override
  String get editInstance => 'تعديل المثيل';

  @override
  String get openTocFile => 'فتح ملف جدول المحتويات';

  @override
  String get createInstance => 'إنشاء مثيل';

  @override
  String get createTocLibrary => 'إنشاء مكتبة جدول محتويات';

  @override
  String get instanceContent => 'المحتوى';

  @override
  String get instanceContentSource => 'إنشاء من';

  @override
  String get emptyInstance => 'مثيل فارغ';

  @override
  String get markdownFiles => 'ملفات Markdown المحلية';

  @override
  String get chooseMarkdownFolder => 'اختيار مجلد Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'اختر مجلدًا يحتوي على ملفات Markdown.';

  @override
  String get instanceAppearance => 'المظهر';

  @override
  String get instanceColor => 'لون الأيقونة';

  @override
  String get instanceVersion => 'الإصدار';

  @override
  String instanceVersionInherited(String version) {
    return 'يكون إصدار المشروع ⁨$version⁩ عندما يكون هذا الحقل فارغًا.';
  }

  @override
  String get instanceWebPath => 'مسار الويب';

  @override
  String get instanceStatus => 'الحالة';

  @override
  String get instanceStatusRelease => 'إصدار نهائي';

  @override
  String get instanceStatusEap => 'وصول مبكر';

  @override
  String get instanceStatusDeprecated => 'مهجور';

  @override
  String get allowSearchEngineIndexing => 'السماح بفهرسة محركات البحث';

  @override
  String get allowSearchEngineIndexingDescription =>
      'السماح لمحركات البحث الخارجية بفهرسة هذا الناتج.';

  @override
  String get offlineArtifact => 'حزمة دون اتصال';

  @override
  String get offlineArtifactDescription =>
      'ضمّن الموارد بحيث تكون الوثائق المنشأة مكتفية ذاتيًا.';

  @override
  String get instanceOutputSettings => 'إعدادات الناتج';

  @override
  String get markdownImportSource => 'مصدر Markdown';

  @override
  String get markdownImportFiles => 'ملفات Markdown';

  @override
  String get selectNone => 'إلغاء تحديد الكل';

  @override
  String markdownFilesFound(int count) {
    return 'عُثر على ⁨$count⁩ من ملفات Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'لم يُعثر على ملفات Markdown في هذا الدليل.';

  @override
  String get copyReferencedMedia => 'نسخ الوسائط المشار إليها';

  @override
  String get copyReferencedMediaDescription =>
      'انسخ الصور ومقاطع الفيديو المحلية التي تشير إليها الملفات المحددة مع الحفاظ على المسارات النسبية.';

  @override
  String get instanceIdRenameWarningTitle =>
      'هل تريد إعادة تسمية معرّف المثيل؟';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'سيعيد BusyMark تسمية ملف ⁨.tree⁩ ويحدّث مراجع مشروع Writerside من «⁨$oldId⁩» إلى «⁨$newId⁩». لن تتغير نصوص النشر البرمجية ويجب تحديثها بصورة منفصلة.';
  }

  @override
  String get renameAndUpdateReferences => 'إعادة التسمية وتحديث المراجع';

  @override
  String get tocLibraryDescription =>
      'تخزّن مكتبة جدول المحتويات أقسامًا قابلة لإعادة الاستخدام ولا تنشئ ناتجًا خاصًا بها.';

  @override
  String get defaultTocLibraryName => 'جدول محتويات مشترك';

  @override
  String get instanceColorAutomatic => 'تلقائي';

  @override
  String get instanceColorBlue => 'أزرق';

  @override
  String get instanceColorGreen => 'أخضر';

  @override
  String get instanceColorOrange => 'برتقالي';

  @override
  String get instanceColorPurple => 'أرجواني';

  @override
  String get instanceColorRed => 'أحمر';

  @override
  String get instanceColorTeal => 'فيروزي';

  @override
  String get instanceColorYellow => 'أصفر';

  @override
  String get errorWritersideInstanceNameRequired => 'أدخل اسمًا للمثيل.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'يوجد بالفعل مثيل بالمعرّف «⁨$id⁩».';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'شجرة المثيل موجودة بالفعل: ⁨$path⁩';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'دليل مصدر Markdown غير موجود: ⁨$path⁩';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'حدّد ملف Markdown واحدًا على الأقل لاستيراده.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'هذا ليس ملف Markdown قابلاً للقراءة داخل المصدر المحدد: ⁨$path⁩';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'سيؤدي الاستيراد إلى استبدال ملف مشروع موجود: ⁨$path⁩';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'تغيّرت ملفات المثيل على القرص. راجعها وحاول مرة أخرى.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'تعذّر على BusyMark التراجع عن تغيير المثيل بالكامل. راجع هذه الملفات قبل المتابعة: ⁨$paths⁩';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'لا يمكن لمكتبة جدول المحتويات استيراد موضوعات Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'يجب أن يكون مسار الويب سطرًا واحدًا.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'إعداد مثيل Writerside غير صالح. صحّح تشخيصاته وحاول مرة أخرى.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'تعذّر على BusyMark تجهيز تغييرات المثيل بأمان.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'حالة المثيل «⁨$status⁩» غير معروفة. استخدم ⁨release⁩ أو ⁨eap⁩ أو ⁨deprecated⁩.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'يستخدم أكثر من ملف شجرة معرّف المثيل «⁨$id⁩».';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'يجب أن يكون العنصر الجذر في ⁨buildprofiles.xml⁩ هو ⁨<buildprofiles>⁩.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'يجب أن تكون قيمة ⁨$name⁩ «⁨$value⁩» إما ⁨true⁩ أو ⁨false⁩.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'يجب أن يحدد عنصر ⁨<build-profile>⁩ معرّف مثيل.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'يجب أن يحدد عنصر ⁨<include>⁩ في الشجرة كلًا من ⁨from⁩ و⁨element-id⁩.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'يجب أن يحدد عنصر ⁨<snippet>⁩ في الشجرة قيمة ⁨id⁩.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'يجب أن يحدد مرجع جدول المحتويات العابر للمثيلات كلًا من ⁨ref⁩ و⁨in⁩.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'لا يمكن لعنصر جدول محتويات استهداف أكثر من موضوع أو مرجع أو رابط أو إعادة توجيه واحدة.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'تم تعريف معرّف عنصر الشجرة «⁨$id⁩» أكثر من مرة.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'يجب أن يكون العنصر الجذر في ملف مجموعات المثيلات هو ⁨<instance-groups>⁩.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'يجب أن تحدد مجموعة المثيلات معرّفًا غير فارغ وقائمة مثيلات.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'تم تعريف معرّف مجموعة المثيلات «⁨$id⁩» أكثر من مرة.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'ينتمي تضمين جدول المحتويات «⁨$source#$id⁩» إلى الوحدة الخارجية «⁨$origin⁩» ولا يمكن توسيعه في مساحة العمل هذه.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'عنصر الشجرة «⁨$id⁩» غير موجود في الشجرة المسجلة «⁨$source⁩».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'ينشئ تضمين الشجرة «⁨$source#$id⁩» دورة.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'يشير شرط المثيل إلى المجموعة غير المعروفة «⁨@$group⁩».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'يستهدف المرجع العابر للمثيلات المثيل غير المعروف «⁨$instance⁩».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'الموضوع «⁨$topic⁩» غير موجود في المثيل المشار إليه «⁨$instance⁩».';
  }

  @override
  String get download => 'تنزيل';

  @override
  String get exportWritersideAsPdf => 'تصدير Writerside بصيغة PDF';

  @override
  String get writersidePdfContent => 'محتوى التصدير';

  @override
  String get writersidePdfPage => 'الصفحة';

  @override
  String get exportingWritersidePdf => 'جارٍ تصدير ملف Writerside PDF…';

  @override
  String get ai => 'الذكاء الاصطناعي';

  @override
  String get aiLocalOllama => 'Ollama المحلي';

  @override
  String get aiDisabled => 'معطّل';

  @override
  String get aiExplicitEditingDescription =>
      'لا يبدأ التحرير بالذكاء الاصطناعي إلا بإجراء صريح. لا يرسل BusyMark إلا السياق المعروض إلى المزوّد المحدد، ولا يطبّق أي اقتراح من دون مراجعته.';

  @override
  String get aiProvider => 'موفّر الذكاء الاصطناعي';

  @override
  String get aiDefaultProvider => 'موفّر الذكاء الاصطناعي الافتراضي';

  @override
  String get aiConfigureProvider => 'تهيئة موفّر الذكاء الاصطناعي';

  @override
  String get aiChooseProvider => 'اختر موفّر الذكاء الاصطناعي';

  @override
  String get aiOllamaEndpoint => 'نقطة نهاية Ollama';

  @override
  String get aiOllamaModel => 'نموذج Ollama';

  @override
  String get aiTestConnection => 'اختبار الاتصال';

  @override
  String get aiTestingConnection => 'جارٍ الاختبار…';

  @override
  String aiConnectionReady(int count) {
    return 'تم الاتصال. عُثر على ⁨$count⁩ من النماذج المثبّتة.';
  }

  @override
  String get aiNoModels => 'لم يتم تحديد نموذج.';

  @override
  String get aiConnectionFailed =>
      'تعذّر على BusyMark التحقق من إنشاء النص بالذكاء الاصطناعي.';

  @override
  String get aiConfigureFirst =>
      'فعّل مزوّد ذكاء اصطناعي وتحقق من نموذج في الإعدادات ← الذكاء الاصطناعي.';

  @override
  String get aiEditWithAi => 'تحرير باستخدام الذكاء الاصطناعي';

  @override
  String get aiRefineWithAi => 'تحسين باستخدام الذكاء الاصطناعي';

  @override
  String get aiInstruction => 'التعليمات';

  @override
  String get aiChangeTarget => 'ما الذي يمكن تغييره';

  @override
  String get aiSharedContext => 'السياق المُشارك مع الذكاء الاصطناعي';

  @override
  String get aiTargetSelection => 'المحتوى المحدد';

  @override
  String get aiTargetInsertAfterBlock => 'إدراج بعد الكتلة الحالية';

  @override
  String get aiTargetCurrentBlock => 'الكتلة الحالية';

  @override
  String get aiTargetCurrentSection => 'القسم الحالي';

  @override
  String get aiTargetCompleteDocument => 'المستند بالكامل';

  @override
  String get aiContextNone => 'بلا سياق من المستند';

  @override
  String get aiContextSelection => 'المحتوى المحدد';

  @override
  String get aiContextCurrentBlock => 'الكتلة الحالية';

  @override
  String get aiContextCurrentSection => 'القسم الحالي';

  @override
  String get aiContextCompleteDocument => 'المستند بالكامل';

  @override
  String get aiGenerating => 'جارٍ إنشاء الاقتراح…';

  @override
  String get aiProposal => 'اقتراح الذكاء الاصطناعي';

  @override
  String get aiGenerateProposal => 'إنشاء الاقتراح';

  @override
  String aiContextDisclosure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيتلقى المزوّد المحدد ⁨$count⁩ حرف من السياق المعروض.',
      many: 'سيتلقى المزوّد المحدد ⁨$count⁩ حرفًا من السياق المعروض.',
      few: 'سيتلقى المزوّد المحدد ⁨$count⁩ أحرف من السياق المعروض.',
      two: 'سيتلقى المزوّد المحدد حرفين من السياق المعروض.',
      one: 'سيتلقى المزوّد المحدد حرفًا واحدًا من السياق المعروض.',
      zero: 'لن يتلقى المزوّد المحدد أي أحرف من السياق المعروض.',
    );
    return '$_temp0';
  }

  @override
  String get aiOriginal => 'النص الأصلي';

  @override
  String get aiSuggested => 'النص المقترح';

  @override
  String get aiApplyProposal => 'تطبيق الاقتراح';

  @override
  String aiTokenUsage(int input, int output) {
    return '⁨$input⁩ رموز إدخال · ⁨$output⁩ رموز إخراج';
  }

  @override
  String get aiStaleProposal =>
      'تغيّر المستند أثناء إنشاء هذا الاقتراح. شغّل الإجراء مرة أخرى.';

  @override
  String get gitAiStagedChangesChanged =>
      'تغيّرت التغييرات المُرحَّلة أثناء إنشاء رسالة الالتزام هذه. شغّل الإجراء مرة أخرى.';

  @override
  String get aiViewContext => 'عرض السياق المُرسل';

  @override
  String get aiReviewExactContent => 'مراجعة المحتوى الدقيق';

  @override
  String get aiContentToChange => 'المحتوى المراد تغييره';

  @override
  String get aiContentSentToAi => 'المحتوى المُرسل إلى الذكاء الاصطناعي';

  @override
  String get aiApiKey => 'مفتاح API';

  @override
  String get aiApiKeyStoredHint =>
      'يوجد مفتاح محفوظ في مخزن بيانات الاعتماد في النظام';

  @override
  String get aiApiKeyEnterHint => 'أدخل مفتاح API للمزوّد';

  @override
  String get aiReplaceApiKey => 'استبدال مفتاح API';

  @override
  String get aiSaveApiKey => 'حفظ مفتاح API بأمان';

  @override
  String get aiRemoveApiKey => 'إزالة مفتاح API المحفوظ';

  @override
  String get aiCredentialSaved =>
      'حُفظ مفتاح API في مخزن بيانات الاعتماد في النظام.';

  @override
  String get aiCredentialRemoved => 'أُزيل مفتاح API المحفوظ.';

  @override
  String get aiModelRouting => 'اختيار النموذج';

  @override
  String get aiAutomaticRouting => 'تلقائي حسب المهمة';

  @override
  String get aiFixedModelRouting => 'استخدام النموذج المحدد';

  @override
  String get aiPreferredModel => 'النموذج المفضّل';

  @override
  String get aiModel => 'النموذج';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '⁨$requests⁩ طلبات · ⁨$input⁩ رموز إدخال · ⁨$output⁩ رموز إخراج';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'هل تريد إرسال المحتوى إلى ⁨$provider⁩؟';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'تفعيل ⁨$provider⁩';
  }

  @override
  String get aiCloudConsentMessage =>
      'لا يُرسل إلا المحتوى المعروض في كل مربع حوار لمراجعة الذكاء الاصطناعي. الطلبات عديمة الحالة، وتتطلب الاقتراحات مراجعة، ويُحفظ مفتاح API في مخزن بيانات الاعتماد في نظام Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'أكد أولًا مشاركة البيانات مع ⁨$provider⁩ في الإعدادات ← الذكاء الاصطناعي.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'تم التحقق من الإنشاء باستخدام ⁨$model⁩. يتوفر ⁨$count⁩ من النماذج المتوافقة.';
  }

  @override
  String get aiColdStartObserved => 'تم اكتشاف بدء تشغيل بارد للنموذج المحلي.';

  @override
  String get aiNoCompatibleModels => 'لا يتوفر نموذج متوافق لإنشاء النص.';

  @override
  String get aiEnableProvider => 'فعّل مزوّد ذكاء اصطناعي أولًا.';

  @override
  String get aiDraftCommitMessage => 'صياغة مسودة رسالة الالتزام';

  @override
  String get aiDrafting => 'جارٍ إعداد المسودة…';

  @override
  String get aiDraftWithAi => 'إعداد مسودة بالذكاء الاصطناعي';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'يلي عنوان المستوى ⁨$previousLevel⁩ عنوان من المستوى ⁨$level⁩؛ راجع تداخل الأقسام.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'نص الرابط فارغ؛ أدخل اسمًا ميسّرًا يصف الغرض منه.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'راجع ما إذا كان نص الرابط «⁨$text⁩» يصف غرضه ضمن السياق.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'يجب أن تعرّف رؤوس الجدول أعمدتها؛ أكمل كل رأس فارغ.';

  @override
  String get mathRenderFailed => 'تعذر عرض التعبير الرياضي.';

  @override
  String get inlineMath => 'رياضيات مضمنة';

  @override
  String get displayMath => 'رياضيات معروضة';

  @override
  String get goToDeclaration => 'الانتقال إلى التصريح';

  @override
  String get findUsages => 'البحث عن الاستخدامات';

  @override
  String get cannotRenameSymbol =>
      'لا يمكن إعادة تسمية الرمز بأمان. تحقق من الاسم وحدّث المرجع قبل المحاولة مجددًا.';

  @override
  String get renameTopicFileInstead =>
      'تُشتق معرّفات الموضوعات من أسماء ملفاتها. استخدم «إعادة تسمية ملف الموضوع» في جدول المحتويات أو الشريط الجانبي للملفات.';

  @override
  String get keyboardLayout => 'تخطيط لوحة المفاتيح';

  @override
  String get diagnosticWritersideUnsupported =>
      'يُعرض المحتوى غير المدعوم أو المشوّه كنص مصدر.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'تعذّر حل المصدر «$reference»: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'هدف الرابط غير متاح في هذه النسخة: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'ترميز Writerside غير صالح: $element، $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'استخدم <llms-txt>true</llms-txt> أو <llms-txt>false</llms-txt>؛ لم يعد single-file مدعومًا.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'تعذّر حل $kind: $reference';
  }

  @override
  String get exportAsHtml => 'تصدير بتنسيق HTML…';

  @override
  String get fileTypeHtml => 'مستند HTML';

  @override
  String get exportingHtml => 'جارٍ تصدير HTML…';

  @override
  String get htmlExported => 'اكتمل تصدير HTML';

  @override
  String get htmlExportFailed => 'فشل تصدير HTML';

  @override
  String get htmlKeepAssetsTogether =>
      'عند نسخ التصدير، احتفظ بملف HTML ومجلد الموارد المرافق له معًا.';

  @override
  String get htmlInstanceDescription =>
      'صدّر نسخة واحدة على هيئة صفحات مترابطة تعمل دون اتصال. اختر اسمًا لمجلد إخراج مخصص.';

  @override
  String get htmlInstance => 'النسخة';

  @override
  String get htmlOwnedDirectoryOnly =>
      'يمكن استبدال مجلد أنشأه تصدير HTML في BusyMark فقط. ستُحفظ الملفات المعدّلة أو غير المرتبطة.';

  @override
  String get showInFolder => 'إظهار في المجلد';

  @override
  String sortTableColumn(String column) {
    return 'فرز $column';
  }

  @override
  String get exportReset => 'استعادة الإعدادات الافتراضية';

  @override
  String get exportToc => 'تضمين جدول المحتويات';

  @override
  String get exportTocDepth => 'عمق جدول المحتويات';

  @override
  String get exportNumberHeadings => 'ترقيم العناوين';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'مخصص';

  @override
  String get exportPageWidth => 'عرض الصفحة (مم)';

  @override
  String get exportPageHeight => 'ارتفاع الصفحة (مم)';

  @override
  String get exportMarginTop => 'الهامش العلوي (مم)';

  @override
  String get exportMarginRight => 'الهامش الأيمن (مم)';

  @override
  String get exportMarginBottom => 'الهامش السفلي (مم)';

  @override
  String get exportMarginLeft => 'الهامش الأيسر (مم)';

  @override
  String get exportTypography => 'الخطوط';

  @override
  String get exportSans => 'بلا زوائد';

  @override
  String get exportSerif => 'بزوائد';

  @override
  String get exportBodySize => 'حجم خط النص';

  @override
  String get exportCodeSize => 'حجم خط الشيفرة';

  @override
  String get exportRunningText => 'رأس الصفحة وتذييلها';

  @override
  String get exportHeader => 'رأس الصفحة';

  @override
  String get exportFooter => 'تذييل الصفحة';

  @override
  String get exportNone => 'بلا';

  @override
  String get exportDocumentTitle => 'عنوان المستند';

  @override
  String get exportBottomLeft => 'أسفل اليسار';

  @override
  String get exportBottomCenter => 'أسفل الوسط';

  @override
  String get exportBottomRight => 'أسفل اليمين';

  @override
  String get exportFirstPage => 'إظهار الرأس والتذييل في الصفحة الأولى';

  @override
  String get exportAccent => 'لون التمييز / الروابط';

  @override
  String get exportTheme => 'المظهر';

  @override
  String get exportAutomatic => 'تلقائي';

  @override
  String get exportLayout => 'التخطيط';

  @override
  String get exportContentWidth => 'العرض الأقصى للمحتوى';

  @override
  String get exportOutput => 'الإخراج';

  @override
  String get exportPackaging => 'التجميع';

  @override
  String get exportSingleFile => 'ملف HTML واحد';

  @override
  String get exportAssetsDirectory => 'HTML + مجلد موارد';

  @override
  String get exportCustomCss => 'ورقة أنماط مخصصة…';

  @override
  String get exportRemoveCss => 'إزالة ورقة الأنماط المخصصة';

  @override
  String get exportCssNote =>
      'اختر ملف CSS اختياريًا بترميز UTF-8 (حتى 256 KiB). تُرفض عمليات الاستيراد وعناوين الموارد وCSS القابل للتنفيذ أو المحتوي على محارف هروب. تُطبق الأنماط بعد أنماط BusyMark. لا تُجلب موارد بعيدة.';

  @override
  String get exportSitePackagingNote =>
      'يحتفظ Writerside بصفحات مواضيع منفصلة ومترابطة. يضمّن وضع الملف الواحد الموارد في كل صفحة.';

  @override
  String get exportInvalidGeometry =>
      'اترك عرضًا وارتفاعًا للمحتوى لا يقلان عن 20 مم بعد الهوامش.';

  @override
  String get exportInvalidColor => 'أدخل لونًا بصيغة #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'اختر ملف .css مقروءًا بترميز UTF-8 حتى 256 KiB، دون استيراد أو عناوين موارد أو HTML أو CSS قابل للتنفيذ أو يحتوي على محارف هروب.';

  @override
  String get clipboardHistory => 'سجل النسخ واللصق';

  @override
  String get clipboardHistoryDescription =>
      'افتح سجل النسخ واللصق الخاص بالجلسة.';

  @override
  String get clipboardCurrent => 'النسخة واللصق الحالية';

  @override
  String get clipboardCurrentExternal => 'النسخة واللصق من تطبيق آخر';

  @override
  String clipboardDestination(String name) {
    return 'الصق في $name';
  }

  @override
  String get clipboardSessionOnly => 'مخزن فقط لهذه جلسة BusyMark.';

  @override
  String get clipboardNoItems => 'سجل النسخ واللصق فارغ.';

  @override
  String get clipboardDisabled => 'مجموعة سجل النسخ واللصق معطلة في الإعدادات.';

  @override
  String get clipboardUnavailable =>
      'محتوى النسخة واللصق الحالي غير متاح أو غير مدعوم.';

  @override
  String get clipboardTooLarge =>
      'هذا العنصر في النسخة واللصق كبير جدًا بحيث لا يمكن الاحتفاظ به.';

  @override
  String get clipboardPastePlainText => 'الصق كنص عادي';

  @override
  String get clipboardClearAll => 'مسح سجل النسخ واللصق';

  @override
  String get clipboardEntryText => 'نص';

  @override
  String get clipboardEntryRichText => 'نص غني';

  @override
  String get clipboardEntryImage => 'صورة';

  @override
  String clipboardOrigin(String name) {
    return 'تم نسخها من $name';
  }

  @override
  String get localHistory => 'سجل محلي';

  @override
  String get localHistoryEllipsis => 'سجل محلي…';

  @override
  String get localHistoryDescription =>
      'اعرض النسخ والمراجعات المحلية المحفوظة والآلية للمستند الحالي.';

  @override
  String get findLocalHistoryEllipsis => 'البحث في التاريخ المحلي…';

  @override
  String get findLocalHistoryDescription =>
      'البحث في مستندات التاريخ المحلي ومحتوى الإصدارات.';

  @override
  String get localHistoryNoDocuments => 'لا توجد مستندات لديها تاريخ محلي.';

  @override
  String get localHistoryNoRevisions =>
      'هذا المستند ليس لديه إصدارات في التاريخ المحلي.';

  @override
  String get localHistorySelectedRevision => 'الإصدار المحدد';

  @override
  String get localHistoryCurrentEditor => 'محتوى المحرر الحالي';

  @override
  String get localHistoryCurrentDisk => 'المحتوى الحالي على القرص';

  @override
  String get localHistoryMissingFile => 'الملف الأصلي مفقود.';

  @override
  String get localHistoryRestoreRevision => 'استعادة الإصدار';

  @override
  String get localHistoryRestoreOriginalLocation => 'استعادة إلى الموقع الأصلي';

  @override
  String get localHistoryRestoreNewLocation => 'استعادة إلى موقع جديد…';

  @override
  String get localHistoryRestoreChange => 'استعادة التغيير';

  @override
  String get localHistoryRestoreUnavailable =>
      'لا يمكن استعادة هذا التغيير لأن المقارنة لم تعد حديثة.';

  @override
  String get localHistoryComparisonSimplified =>
      'تم تبسيط هذا المقارنة الكبير. لا يمكن استعادة التغييرات الفردية.';

  @override
  String localHistoryOlderChange(String text) {
    return 'تغيير الإصدار الأقدم: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'تغيير المحتوى الحالي: $text';
  }

  @override
  String get localHistoryDeleted => 'تم الحذف';

  @override
  String get localHistoryUntitled => 'غير مُسمى';

  @override
  String get localHistoryClearDocument => 'مسح سجل هذا المستند';

  @override
  String get localHistoryClearAll => 'مسح السجل المحلي بالكامل';

  @override
  String get localHistoryClearDocumentTitle => 'هل تريد مسح سجل المحلي؟';

  @override
  String get localHistoryClearAllTitle => 'هل تريد مسح السجل المحلي؟';

  @override
  String get localHistoryClearConfirmation =>
      'هذا يزيل بشكل دائم النسخ المحفوظة. لا يمكن التراجع عن هذه العملية.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'تم تلف فهرس السجل المحلي وإعادة بنائه من النسخ السليمة.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'يستخدم هذا السجل المحلي تنسيقًا غير مدعوم $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'السجل المحلي غير متاح: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'تم تعطيل التسجيل أو تم استبعاد هذا المسار. قم بتفعيل التسجيل مرة أخرى قبل الاستعادة.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'لم يتمكن السجل المحلي من تسجيل تغيير المسار: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'لم يتمكن السجل المحلي من الاحتفاظ بالمسار المحذوف: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'النسخة المختارة مفقودة أو تالفة.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'لا يمكن قراءة النسخة المختارة: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'لم يتمكن السجل المحلي من التقاط هذه النسخة: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason، $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'النسخة الأساسية';

  @override
  String get localHistoryReasonSaved => 'محفوظ';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'نقطة فحص تلقائية';

  @override
  String get localHistoryReasonBeforeReload => 'قبل إعادة التحميل';

  @override
  String get localHistoryReasonBeforeDiscard => 'قبل التخلص';

  @override
  String get localHistoryReasonBeforeRestore => 'قبل الاستعادة';

  @override
  String get localHistoryReasonBeforeDelete => 'قبل الحذف';

  @override
  String get localHistoryReasonExternalChange => 'تغيير خارجي';

  @override
  String get settingsHistory => 'سجل التغييرات';

  @override
  String get settingsClipboardHistoryTitle => 'جمع سجل الحافظة';

  @override
  String get settingsClipboardHistoryDescription =>
      'احتفظ بالمحتوى المنسوخ والمُلصق بنجاح لهذه الجلسة فقط في BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'تسجيل سجل محلي';

  @override
  String get settingsLocalHistoryDescription =>
      'حفظ إصدارات المستند على هذا الجهاز للتعافي والمقارنة.';

  @override
  String get settingsHistoryCheckpoint => 'فترة التحقق التلقائي';

  @override
  String get settingsHistoryRetention => 'مدة الاحتفاظ';

  @override
  String get settingsHistoryStorage => 'الحد الأقصى للتخزين';

  @override
  String get settingsHistoryExcludedPaths => 'مسارات مستبعدة';

  @override
  String get settingsHistoryExcludedPathsHint => 'مسار مطلق واحد في كل سطر';

  @override
  String settingsSecondsValue(int value) {
    return '$value ثوان';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value أيام';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value ميجابايت';
  }

  @override
  String get spelling => 'الإملاء';

  @override
  String get automaticSpelling => 'التدقيق الإملائي التلقائي';

  @override
  String get defaultSpellingLanguage => 'لغة الإملاء الافتراضية';

  @override
  String get projectSpellingLanguage => 'لغة التدقيق الإملائي للمشروع';

  @override
  String get chooseSpellingLanguage => 'اختر لغة الإملاء';

  @override
  String get spellingLanguageUnsetStatus => 'اللغة…';

  @override
  String get spellingOffStatus => 'التدقيق الإملائي متوقف';

  @override
  String get checkSpelling => 'تدقيق الإملاء';

  @override
  String get ignoreSpellingOnce => 'تجاهل مرة واحدة';

  @override
  String get ignoreSpellingDocument => 'تجاهل الكل في هذا المستند';

  @override
  String get addPersonalSpellingWord => 'إضافة إلى القاموس الشخصي';

  @override
  String get addProjectSpellingWord => 'إضافة إلى قاموس المشروع';

  @override
  String get inheritSpellingLanguage => 'استخدام لغة المشروع أو التطبيق';

  @override
  String get disableDocumentSpelling => 'عدم التدقيق الإملائي';

  @override
  String get importSpellingDictionary => 'استيراد قاموس';

  @override
  String get personalSpellingDictionary => 'القاموس الشخصي';

  @override
  String get projectSpellingDictionary => 'قاموس المشروع';

  @override
  String get noSpellingErrors => 'لا توجد أخطاء إملائية';

  @override
  String get noSpellingSuggestions => 'لا توجد اقتراحات إملائية';

  @override
  String get spellingWordCheckFailed => 'تعذّر التحقق من هذه الكلمة';

  @override
  String get spellingCheckFailed => 'فشل التدقيق الإملائي';

  @override
  String get spellingSettingsLoadFailed =>
      'تعذّر تحميل إعدادات التدقيق الإملائي';

  @override
  String get retrySpellingSettings =>
      'إعادة محاولة تحميل إعدادات التدقيق الإملائي';

  @override
  String get spellingCheckIncomplete => 'التدقيق الإملائي غير مكتمل';

  @override
  String get spellingDictionaryNotInstalled => 'القاموس غير مثبّت';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'قاموس ⁨$dictionary⁩ غير مثبّت';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'غير مثبّت · ⁨$size⁩';
  }

  @override
  String get spellingDictionaryInstalled => 'مثبّت';

  @override
  String get installSpellingDictionary => 'تثبيت القاموس';

  @override
  String get removeSpellingDictionary => 'إزالة القاموس';

  @override
  String get cancelSpellingDictionaryInstall => 'إلغاء تنزيل القاموس';

  @override
  String get retrySpellingDictionaryInstall => 'إعادة محاولة تثبيت القاموس';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'جارٍ تنزيل ⁨$size⁩…';
  }

  @override
  String get spellingDictionaryValidating => 'جارٍ التحقق من القاموس…';

  @override
  String get spellingDictionaryInstallFailed =>
      'فشل تثبيت القاموس — حدده لإعادة المحاولة';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'هل تريد تثبيت ⁨$dictionary⁩ (⁨$size⁩)؟ بعد التثبيت، يظل متاحًا دون اتصال حتى تزيله.';
  }

  @override
  String get spellingDictionaryUnavailable => 'القاموس غير متاح';

  @override
  String get spellingChecking => 'جارٍ التدقيق الإملائي…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: أدخل رقمًا بين $minimum و$maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'تم تغيير قاموس التدقيق الإملائي خارجيًا. تم الاحتفاظ بنسخة استرداد.';

  @override
  String get windowMinimize => 'تصغير';

  @override
  String get windowMaximize => 'تكبير';

  @override
  String get windowRestore => 'استعادة';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'اتصال';

  @override
  String get nextcloudReconnect => 'إعادة الاتصال';

  @override
  String get nextcloudDisconnect => 'قطع الاتصال';

  @override
  String get nextcloudServer => 'عنوان الخادم';

  @override
  String get nextcloudSignInBrowser => 'أكمل تسجيل الدخول في المتصفح.';

  @override
  String get nextcloudFavorites => 'المفضلة';

  @override
  String get nextcloudNewNote => 'ملاحظة جديدة';

  @override
  String get nextcloudSavedLocally => 'محفوظ محليًا · المزامنة معلقة';

  @override
  String get nextcloudSyncing => 'جارٍ المزامنة';

  @override
  String get nextcloudSynced => 'تمت المزامنة';

  @override
  String get nextcloudOffline => 'غير متصل';

  @override
  String get nextcloudLocked => 'مقفل بواسطة الخادم';

  @override
  String get nextcloudReconnectRequired => 'تجب إعادة الاتصال';

  @override
  String get nextcloudCreationUncertain => 'نتيجة الإنشاء غير مؤكدة';

  @override
  String get nextcloudReadOnly => 'للقراءة فقط';

  @override
  String get nextcloudTakeRemote => 'استخدام نسخة الخادم';

  @override
  String get nextcloudMerge => 'دمج';

  @override
  String get nextcloudDeleteNote => 'حذف الملاحظة؟';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'الاستبدال في مساحة العمل غير متاح لملاحظات Nextcloud. استخدم الاستبدال داخل كل ملاحظة.';

  @override
  String get nextcloudSaveLocalCopy => 'حفظ نسخة محلية…';

  @override
  String get nextcloudDisconnectWarning =>
      'تؤدي إزالة الحساب إلى حذف الملاحظات المخزنة مؤقتًا والتغييرات المعلقة من هذا الجهاز. زامن أولًا للاحتفاظ بالعمل على الخادم.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'قد تترك إعادة المحاولة مرفقًا غير مستخدم على الخادم إذا نجح التحميل السابق.';

  @override
  String get nextcloudAttachmentReference => 'مرجع المرفق على الخادم';

  @override
  String get nextcloudAddAttachment => 'إضافة مرفق…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'سيؤدي حذف المرفق إلى جعل روابطه في الملاحظة غير متاحة. يمكن استعادة البيانات المحتفَظ بها من السجل المحلي.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'اختر قيمة لكل سمة متعارضة.';

  @override
  String get nextcloudUseServerNote => 'استخدام هذه الملاحظة على الخادم';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'يربط هذه المسودة بالملاحظة المحددة على الخادم، ثم يزامن التغييرات المحلية المحفوظة. تطابق الطلب لا يؤكد من أنشأ الملاحظة.';

  @override
  String get nextcloudExactCandidate => 'تطابق تام مع الطلب؛ الهوية غير مؤكدة.';

  @override
  String get nextcloudPossibleCandidate =>
      'تطابق محتمل بعد تنقية الطلب؛ الهوية غير مؤكدة.';

  @override
  String get nextcloudSelectCandidate => 'اختر ملاحظة على الخادم لمراجعتها';

  @override
  String get nextcloudCreateSeparate => 'إنشاء ملاحظة منفصلة';

  @override
  String get nextcloudCreateSeparateWarning =>
      'قد يكون الطلب الأول قد أنشأ ملاحظة على الخادم بالفعل. ينشئ هذا ملاحظة منفصلة بعملك المحلي المحفوظ. لن تُحذف أي ملاحظة يُشتبه بأنها مكررة.';

  @override
  String get wsSemanticFormats => 'تنسيق دلالي';

  @override
  String get wsUiControl => 'عنصر تحكم في الواجهة';

  @override
  String get wsFilePath => 'ملف / مسار';

  @override
  String get wsUiPath => 'مسار الواجهة';

  @override
  String get wsDefinitionList => 'قائمة تعريفات';

  @override
  String get wsIncludeContent => 'تضمين محتوى قابل لإعادة الاستخدام';

  @override
  String get wsVariableReference => 'مرجع متغير';

  @override
  String get wsConvertList => 'تحويل القائمة إلى إجراء';

  @override
  String get wsElementProperties => 'خصائص العنصر';

  @override
  String get wsTopicProperties => 'خصائص الموضوع';

  @override
  String get wsCollapsible => 'قابل للطي';

  @override
  String get wsPublishedState => 'الحالة الأولية عند النشر';

  @override
  String get wsExpanded => 'موسع';

  @override
  String get wsCollapsed => 'مطوي';

  @override
  String get wsCollapsedTitle => 'العنوان عند الطي';

  @override
  String get wsTerm => 'المصطلح';

  @override
  String get wsListLayout => 'تخطيط القائمة';

  @override
  String get wsSyncGroup => 'مجموعة المزامنة';

  @override
  String get wsTabKey => 'مفتاح علامة التبويب';

  @override
  String get wsSwitcherLabel => 'تسمية المبدل';

  @override
  String get wsNavigationElements => 'عناصر التنقل';

  @override
  String get wsNavigationDepth => 'عمق التنقل';

  @override
  String get wsAddItem => 'إضافة عنصر';

  @override
  String get wsStep => 'خطوة';

  @override
  String get wsPropertyInvalid => 'قيمة خاصية غير صالحة';

  @override
  String get wsFilter => 'عامل التصفية';

  @override
  String get wsIdentifier => 'معرّف العنصر';

  @override
  String get wsTldr => 'ملخّص (TLDR)';

  @override
  String get wsFullLayout => 'عرض كامل';

  @override
  String get wsMediumLayout => 'متوسط (1:2)';

  @override
  String get wsNarrowLayout => 'مصطلح ضيق';

  @override
  String get wsTitle => 'العنوان';

  @override
  String get wsSwitcherKey => 'مفتاح المبدّل';

  @override
  String get nextcloudServerSettings => 'إعدادات Notes على الخادم';

  @override
  String get nextcloudNotesPath => 'مسار مجلد الملاحظات';

  @override
  String get nextcloudFileSuffix => 'لاحقة ملفات الملاحظات الجديدة';

  @override
  String get nextcloudServerSettingsExplanation =>
      'تؤثر إعدادات Notes هذه على العملاء الآخرين. تغيير المسار لا ينقل الملفات؛ وتغيير اللاحقة لا يعيد تسمية الملاحظات الحالية.';

  @override
  String get nextcloudSettingsSaved => 'حُفظت إعدادات الخادم';

  @override
  String get nextcloudSettingsNormalized =>
      'حُفظت القيم بعد توحيدها على الخادم';

  @override
  String get nextcloudPendingUpload => 'رفع المرفق قيد الانتظار';

  @override
  String nextcloudServerCheck(String time) {
    return 'آخر فحص للخادم: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'جارٍ تحميل إعدادات الخادم';

  @override
  String get nextcloudSettingsSaving => 'جارٍ حفظ إعدادات الخادم';

  @override
  String get nextcloudPreviousLocalEdit => 'التعديل المحلي السابق';

  @override
  String get nextcloudUsePreviousEdit => 'استخدام التعديل السابق';

  @override
  String get quickOpen => 'فتح سريع';

  @override
  String get notesAll => 'كل الملاحظات';

  @override
  String get notesUncategorized => 'بلا تصنيف';

  @override
  String get notesRecovery => 'استعادة';

  @override
  String get notesRecentlyEdited => 'المعدلة مؤخراً';

  @override
  String get notesOldestEdited => 'الأقدم تعديلاً';

  @override
  String get notesTitleAscending => 'العنوان تصاعدياً';

  @override
  String get notesTitleDescending => 'العنوان تنازلياً';

  @override
  String get notesMove => 'نقل إلى تصنيف';

  @override
  String get notesRemoveFavorite => 'إزالة من المفضلة';

  @override
  String get notesOffline => 'إتاحة دون اتصال';

  @override
  String get notesOfflineRemove => 'إزالة الاحتفاظ دون اتصال';

  @override
  String get notesIndexing => 'جارٍ فهرسة الملاحظات…';

  @override
  String get notesSearchHelp =>
      'تُجمع الكلمات باستخدام AND. استخدم \"عبارات مقتبسة\" و title: و category:.';

  @override
  String get notesSourceLocation => 'الموضع في المصدر';

  @override
  String get notesRecoveryHelp =>
      'الملاحظات المحلية المحتفظ بها والسجل المحلي فقط. سلة المحذوفات وسجل الخادم غير متاحين.';

  @override
  String get notesImport => 'استيراد ملاحظات';

  @override
  String get notesExport => 'تصدير ملاحظات';

  @override
  String get notesImportDistinct => 'استيراد كملاحظة مستقلة';

  @override
  String get notesAvailableOffline => 'متاح دون اتصال';

  @override
  String get notesIncomplete => 'غير مكتمل';

  @override
  String get notesSelected => 'الملاحظات المحددة';

  @override
  String get notesNoHistory =>
      'لا توجد مراجعات محفوظة. قد يكون السجل معطلاً أو منتهياً أو ممسوحاً.';

  @override
  String get notesTextAvailable => 'النص متاح محليًا';

  @override
  String get notesLocalVersion => 'نسخة العمل المحلية';

  @override
  String get notesAttachments => 'المرفقات';

  @override
  String get notesSkipped => 'تم التخطي';

  @override
  String get notesFailed => 'فشل';

  @override
  String get notesCompleted => 'مكتمل';

  @override
  String get notesImportNew => 'بدء استيراد جديد';

  @override
  String get notesImportResume => 'استئناف الاستيراد المنقطع';

  @override
  String get notesImportAlreadyImported => 'تم الاستيراد بالفعل في هذه العملية';

  @override
  String get references => 'المراجع';

  @override
  String get referenceIncoming => 'الواردة';

  @override
  String get referenceOutgoing => 'الصادرة';

  @override
  String get referenceChooseTarget => 'اختر هدف الرابط';

  @override
  String get referenceWholeDocument => 'المستند بالكامل';

  @override
  String get referenceSourceLocation => 'موقع المصدر';

  @override
  String get referenceTargetLocation => 'موقع الهدف';

  @override
  String get referenceResolved => 'تم الحل';

  @override
  String get referenceMissing => 'مفقود';

  @override
  String get referenceAmbiguous => 'ملتبس';

  @override
  String get referenceUnavailable => 'غير متاح في هذا السياق';

  @override
  String get referenceUnsupported => 'غير مدعوم';

  @override
  String get referenceNoPortableId =>
      'ليس لهذا الهدف عنوان URL محمول ومُتحقَّق منه للملاحظة.';

  @override
  String get wsIncludeLines => 'تضمين الأسطر';

  @override
  String get wsIncludeSymbol => 'تضمين الرمز';

  @override
  String get wsEmphasizeLines => 'تمييز الأسطر المعروضة';

  @override
  String get wsPropertiesReadOnly => 'الخصائص للقراءة فقط في هذا العرض.';

  @override
  String get wsPropertiesProtected => 'هذا العنصر محمي. حرر مصدره.';

  @override
  String get wsPropertiesConflict =>
      'تغير المستند أو العنصر. تراجع عن المسودة وحدد العنصر مجدداً.';

  @override
  String get wsPropertiesUnresolved => 'لا يمكن حل المرجع حالياً.';

  @override
  String get wsUseDefault => 'استخدام الافتراضي';

  @override
  String get wsPropertiesSelection => 'حدد عنصراً واحداً.';

  @override
  String get wsImageDisplay => 'عرض الصورة';

  @override
  String get wsImageThumbnail => 'صورة مصغرة قابلة للنقر';

  @override
  String get wsEnabled => 'مفعّل';

  @override
  String get wsDisabled => 'معطّل';

  @override
  String get wsWidth => 'العرض';

  @override
  String get wsHeight => 'الارتفاع';

  @override
  String get wsPropertiesInactive =>
      'لا تؤثر هذه الخاصية إلا عند تفعيل الطي المنشور.';

  @override
  String get wsNavigationAll => 'كل العناصر ذات العناوين';

  @override
  String get wsNavigationNone => 'بلا تنقل';

  @override
  String get wsNavigationCustom => 'تنقل مخصص';

  @override
  String get wsTitleOverride => 'تجاوز العنوان';

  @override
  String get wsCompactLayout => 'مضغوط';

  @override
  String get wsWideLayout => 'عريض';

  @override
  String get wsCodeSourceConflict =>
      'انقل أو أزل الشفرة المكتوبة في هذه الكتلة قبل تعيين src. يرفض Writerside كتلة شفرة غير فارغة لها مرجع مصدر.';

  @override
  String get wsInherited => 'وراثة من القائمة';

  @override
  String get wsExternalImageSize =>
      'لا يحدد Writerside أبعاد الصور الخارجية بشكل موثوق. يمكنك فحص الأبعاد الحالية وإزالتها.';

  @override
  String get wsPropertiesNotSerialized =>
      'لم يُطبّق هذا التغيير على المصدر. تم الاحتفاظ بالمسودة.';

  @override
  String get wsListItem => 'عنصر قائمة';

  @override
  String get wsSourceFile => 'ملف المصدر';

  @override
  String get wsLinkTarget => 'وجهة الرابط';

  @override
  String get wsPreviewImage => 'صورة المعاينة';

  @override
  String get wsIncludedElement => 'العنصر المُضمَّن';

  @override
  String get wsHelpModule => 'وحدة المساعدة';

  @override
  String get wsActionId => 'معرّف الإجراء';

  @override
  String get wsKeymapHelpInstance => 'نسخة مساعدة خريطة المفاتيح';

  @override
  String get wsShowInSource => 'إظهار في المصدر';

  @override
  String get wsOriginElement => 'تجاوز العنصر';

  @override
  String get wsOriginAncestor => 'العنصر الأب';

  @override
  String get wsOriginModule => 'القيمة الافتراضية للوحدة';

  @override
  String get wsOriginBuiltIn => 'القيمة الافتراضية المضمّنة';

  @override
  String get wsOriginUnresolved => 'غير محلول';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'القيمة الفعلية: $value — $origin';
  }

  @override
  String get wsElementSelector => 'العنصر';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'مُولَّد: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'الافتراضي: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'الافتراضي: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'القيمة المحلولة: $value';
  }

  @override
  String get wsPropertyUnresolved => 'غير محلول';

  @override
  String get wsModule => 'الوحدة';

  @override
  String get wsParent => 'العنصر الأب';

  @override
  String get wsListType => 'نوع القائمة';

  @override
  String get wsStartingNumber => 'رقم البداية';

  @override
  String get wsListSorting => 'الفرز';

  @override
  String get wsLetteredList => 'قائمة حرفية';

  @override
  String get wsCheckboxList => 'قائمة مربعات اختيار';

  @override
  String get wsMarkerlessList => 'قائمة دون علامات';

  @override
  String get wsAscending => 'تصاعدي';

  @override
  String get wsDescending => 'تنازلي';

  @override
  String get wsNoSorting => 'دون فرز';

  @override
  String get wsAsWritten => 'كما كُتب';

  @override
  String get wsSentenceCase => 'حالة أحرف الجملة';

  @override
  String get wsTitleCase => 'حالة أحرف العنوان';

  @override
  String get wsLowerCase => 'أحرف صغيرة';

  @override
  String get wsUpperCase => 'أحرف كبيرة';

  @override
  String get wsNativeMarkers => 'علامات Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'علامة البداية: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'المستوى $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'يتجاهل الباني المثبّت قواعد <caps> للوحدة. استخدم سمة caps محلية أو default-property.';

  @override
  String get wsInsertElements => 'إدراج عناصر';

  @override
  String get wsAdmonitionsAndQuotes => 'تنبيهات واقتباسات';

  @override
  String get wsSemanticText => 'نص دلالي';

  @override
  String get wsPropertiesUnavailable =>
      'العنصر الذي يتم فحصه غير متاح. افحص عنصرًا للمتابعة.';

  @override
  String get searchDocumentsCategory => 'المستندات';

  @override
  String get searchTopicsCategory => 'المواضيع';

  @override
  String get searchCurrentDocument => 'المستند الحالي';

  @override
  String get searchCurrentWorkspace => 'مساحة العمل الحالية';

  @override
  String get browseNotes => 'تصفح الملاحظات';

  @override
  String get searchActionsCommand => 'البحث عن إجراءات';

  @override
  String get searchDocumentsCommand => 'البحث عن مستندات';

  @override
  String get searchTopicsCommand => 'البحث عن مواضيع';

  @override
  String get searchRecentCommand => 'البحث في الأخيرة';

  @override
  String get searchResourceUnavailable => 'هذا المورد غير متاح.';

  @override
  String get notesSync => 'مزامنة الملاحظات';

  @override
  String get searchInWorkspace => 'البحث في مساحة العمل';

  @override
  String get searchCategory => 'فئة البحث';

  @override
  String get clearHistorySearchScope => 'البحث في سجل المستندات';

  @override
  String get searchInDocument => 'البحث في المستند';

  @override
  String get searchDocumentHint => 'ابحث في هذا المستند…';

  @override
  String get searchWorkspaceHint => 'ابحث في مساحة العمل هذه…';

  @override
  String get searchOutlineHint => 'ابحث في العناوين…';

  @override
  String get searchHistoryHint => 'ابحث في السجل المحلي…';

  @override
  String get searchEnterText => 'أدخل نصًا للبحث';

  @override
  String get searchAccountUnavailable => 'الحساب غير متاح';

  @override
  String get searchDocumentsHint => 'البحث عن مستندات…';

  @override
  String get searchTopicsHint => 'البحث عن مواضيع…';

  @override
  String get searchRecentHint => 'البحث في الأخيرة…';

  @override
  String get searchActionsHint => 'البحث عن إجراءات…';

  @override
  String get searchRequiresNotesWorkspace => 'يتطلب مساحة عمل للملاحظات';

  @override
  String get searchSidebarLabel => 'بحث:';

  @override
  String get searchDocumentTextCategory => 'نص المستند';

  @override
  String get searchWorkspaceTextCategory => 'نص مساحة العمل';

  @override
  String get searchHeadingsCategory => 'العناوين';

  @override
  String get shortcutUnassigned => 'غير معيّن';

  @override
  String get shortcutPressKeys => 'اضغط مجموعة مفاتيح…';

  @override
  String get shortcutRecord => 'تسجيل اختصار';

  @override
  String get shortcutRestoreAll => 'استعادة جميع الإعدادات الافتراضية';

  @override
  String get shortcutRestoreAllQuestion =>
      'هل تريد استعادة الاختصارات الافتراضية لجميع الإجراءات؟ ستُزال التعيينات المخصصة.';

  @override
  String get shortcutSaveFailed =>
      'الاختصارات مفعّلة ولكن تعذر حفظها. أعد المحاولة للاحتفاظ بها بعد إعادة التشغيل.';

  @override
  String get shortcutRetry => 'إعادة محاولة الحفظ';

  @override
  String get shortcutChanged =>
      'تغيرت التعيينات. راجع الاختصارات الحالية وحاول مجددًا.';

  @override
  String get shortcutInvalid => 'لا يمكن تعيين هذه المجموعة في هذا السياق.';

  @override
  String get shortcutSystemWarning =>
      'قد يستخدم سطح المكتب هذه المجموعة. لا يستطيع BusyMark تجاوز اختصارات النظام.';

  @override
  String get shortcutConflicts => 'يتعارض هذا الاختصار مع الإجراءات التالية:';

  @override
  String get shortcutRemove => 'إزالة التعيين';

  @override
  String get shortcutRestoreDefault => 'استعادة الافتراضي';

  @override
  String get shortcutAssign => 'تعيين';

  @override
  String get shortcutReassign => 'إعادة التعيين';

  @override
  String get shortcutContextApplication => 'التطبيق';

  @override
  String get shortcutContextDocument => 'طرق عرض المستند';

  @override
  String get shortcutContextEditor => 'المحرر والمصدر';

  @override
  String get shortcutContextWritersideSource => 'مصدر Writerside';

  @override
  String get shortcutContextWorkspace => 'التنقل في مساحة العمل';

  @override
  String get shortcutContextTree => 'أشجار الشريط الجانبي';

  @override
  String get searchHeadingsCommand => 'البحث عن العناوين';

  @override
  String get shortcutFixed => 'يتولاه المحرر؛ غير قابل للتخصيص.';

  @override
  String get shortcutDefaultConflict =>
      'يتعارض الاختصار الافتراضي مع تعيين مخصص.';

  @override
  String get shortcutCurrentBinding => 'الاختصار الحالي';

  @override
  String get shortcutProposedBinding => 'الاختصار المقترح';

  @override
  String get notesActions => 'إجراءات الملاحظات';

  @override
  String get noteActions => 'إجراءات الملاحظة';

  @override
  String get noteProperties => 'خصائص الملاحظة';

  @override
  String get notesExportAll => 'تصدير ملاحظات · كل الملاحظات…';

  @override
  String get notesExportCategory => 'تصدير ملاحظات · الفئة…';

  @override
  String get notesOfflineAll => 'إتاحة دون اتصال · كل الملاحظات';

  @override
  String get notesOfflineCategory => 'إتاحة دون اتصال · الفئة';

  @override
  String get notesOfflineRemoveAll => 'إزالة الاحتفاظ دون اتصال · كل الملاحظات';

  @override
  String get notesOfflineRemoveCategory => 'إزالة الاحتفاظ دون اتصال · الفئة';

  @override
  String get notesOfflinePause => 'إيقاف التنزيلات مؤقتًا';

  @override
  String get notesOfflineResume => 'استئناف التنزيلات';

  @override
  String get notesOfflineKeep => 'إتاحة دون اتصال';

  @override
  String get notesOfflineRetentionHelp =>
      'إزالة هذا المتطلب تبقي المحتوى المخزن مؤقتًا. قد يظل متطلب الفئة أو الحساب يحتفظ بالملاحظة.';

  @override
  String get notesOfflineBroader =>
      'تُحتفظ بهذه الملاحظة أيضًا بسبب متطلب الفئة أو الحساب.';

  @override
  String get notesOfflineExternal =>
      'تتطلب الوسائط الخارجية اتصالًا. يحتفظ BusyMark بنص الملاحظة والمرفقات المُدارة فقط.';

  @override
  String get notesEmptyAll => 'لا توجد ملاحظات بعد. أنشئ ملاحظة للبدء.';

  @override
  String get notesEmptyFavorites => 'لا توجد ملاحظات مفضلة.';

  @override
  String get notesEmptyCategory => 'لا توجد ملاحظات في هذه الفئة.';

  @override
  String get notesEmptyUncategorized => 'لا توجد ملاحظات غير مصنفة.';

  @override
  String get notesEmptyRecovery => 'لا توجد ملاحظات محفوظة لاستعادتها.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · فشل. إعادة المحاولة';

  @override
  String get notesOperationFailed =>
      'تعذر إكمال العملية. المسودة محفوظة. راجع الحفظ والتعارضات ثم أعد المحاولة.';

  @override
  String get notesInspectionFailed => 'المرفقات · فشل. إعادة المحاولة';

  @override
  String get notesStartingConnection => 'جارٍ بدء الاتصال بـ Nextcloud…';

  @override
  String get notesVerifyingConnection => 'جارٍ التحقق من الوصول إلى الملاحظات…';

  @override
  String get notesCancellingConnection => 'جارٍ إلغاء تسجيل الدخول والتنظيف…';

  @override
  String get notesRemovingConnection => 'جارٍ إزالة الحساب المحلي…';

  @override
  String get notesRemovedWarning =>
      'أُزيل حساب Nextcloud المحلي. لم يُؤكد إبطال كلمة مرور التطبيق. احذف كلمة مرور BusyMark من إعدادات أمان Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'تعذر حفظ جميع الملاحظات المفتوحة محليًا. راجع الحفظ والتعارضات أو التسوية في مساحة العمل. قد تظل التغييرات المحلية بحاجة إلى المزامنة مع Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'حفظ تغييرات إعدادات Nextcloud قبل المغادرة؟';

  @override
  String get notesSettingsLeaveHelp =>
      'إعدادات Notes على الخادم · تغييرات غير محفوظة';

  @override
  String get notesSettingsReload => 'إعادة تحميل إعدادات الخادم…';

  @override
  String get notesSettingsReloadHelp =>
      'تحل إعدادات Nextcloud الحالية محل المسودة عند إعادة التحميل. أتريد تجاهل المسودة وإعادة التحميل؟';

  @override
  String get notesSettingsRefreshFailed =>
      'قَبِل Nextcloud الإعدادات، لكن تعذر تحديث الملاحظات. القيم المعروضة هي ما أكده الخادم. أعد التحديث من الملاحظات.';

  @override
  String get notesUnavailable =>
      'غير متصل · النص متاح محليًا · محفوظ محليًا · المزامنة معلقة';

  @override
  String get notesStorageFull =>
      'مساحة Nextcloud ممتلئة. أفرغ مساحة على الخادم ثم أعد المحاولة.';

  @override
  String get notesRejected =>
      'رفض Nextcloud هذا التغيير. راجع الملاحظة واحفظ نسخة محلية قبل إعادة المحاولة.';

  @override
  String get notesThrottled =>
      'طلب Nextcloud الانتظار. تُستأنف المزامنة بعد انتهاء مهلة إعادة المحاولة.';

  @override
  String get notesRecoveryRequired => 'تعارضات · مقارنة';

  @override
  String get notesScanning => 'جارٍ فحص الملفات…';

  @override
  String get notesCancelling =>
      'جارٍ الإلغاء… في انتظار انتهاء العملية الحالية.';

  @override
  String get notesCancelled => 'أُلغي';

  @override
  String get notesPartial => 'اكتمل جزئيًا';

  @override
  String get notesTransferFailed => 'فشل. إعادة المحاولة';

  @override
  String get notesImportPartialHelp =>
      'قد تكون العناصر السابقة محفوظة محليًا بالفعل. استأنف هذا الاستيراد للمتابعة دون تكرارها.';

  @override
  String get notesNotStarted => 'لم يبدأ';

  @override
  String get notesCreated => 'أُنشئ';

  @override
  String get notesRemoteDeleteUnavailable =>
      'عنوان الخادم · غير مدعوم · حذف · المرفقات';

  @override
  String get notesCurrentText => 'النص المحلي المحفوظ حاليًا';

  @override
  String get notesRecovering => 'جارٍ الاستعادة كملاحظة جديدة…';

  @override
  String get notesReadOnlyHelp => 'للقراءة فقط · المفضلة · حفظ نسخة محلية…';

  @override
  String get notesSort => 'ترتيب الملاحظات';

  @override
  String get notesPathRelative =>
      'مسار مجلد الملاحظات نسبي إلى مساحة تخزين Nextcloud الخاصة بك.';

  @override
  String get notesSettingsStale =>
      'تغيرت الإعدادات في Nextcloud. أعد تحميل قيم الخادم وراجعها قبل استبدال المسودة.';

  @override
  String get notesDownloadsPaused => 'التنزيلات متوقفة مؤقتًا';

  @override
  String get notesExportNotPublished => 'لم يُنشر أي تصدير.';

  @override
  String get notesKeyringUnavailable =>
      'افتح قفل سلسلة مفاتيح سطح المكتب وأعد المحاولة.';

  @override
  String get notesConnectFailed =>
      'تعذر الاتصال بملاحظات Nextcloud. تحقق من عنوان الخادم وأعد المحاولة.';

  @override
  String get notesAccountMismatch =>
      'سجل الدخول إلى حساب Nextcloud نفسه. أزل هذا الحساب أولًا للاتصال بحساب مختلف.';

  @override
  String get notesLocalRemovalFailed =>
      'تعذر تنظيف الحساب المحلي. احتُفظ بالحساب لتتمكن من إعادة محاولة إزالته.';

  @override
  String get notesTransferring => 'جارٍ نقل الملاحظات…';

  @override
  String get notesTechnicalDetails => 'تفاصيل تقنية';

  @override
  String get notesPauseRequirement => 'إيقاف متطلب الإتاحة دون اتصال مؤقتًا';

  @override
  String get notesResumeRequirement => 'استئناف متطلب الإتاحة دون اتصال';

  @override
  String get gitReturnToDocument => 'العودة إلى المستند';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'لقطة للقراءة فقط · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'يحتوي اسم الملف على بايتات ليست بترميز UTF-8. تظل مراجعة Git والإضافة إلى الفهرس متاحتين؛ يتطلب محرر المستندات اسم ملف بترميز UTF-8.';

  @override
  String get gitUiMergeInProgress => 'دمج في التقدم';

  @override
  String get gitUiRebaseInProgress => 'إعادة القاعدة قيد التنفيذ';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick قيد التنفيذ';

  @override
  String get gitUiRevertInProgress => 'عكس في التقدم';

  @override
  String get gitUiPatchApplicationInProgress => 'تطبيق التصحيح قيد التقدم';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'نتيجة دمج الاسكواش في انتظار الالتزام';

  @override
  String get gitUiUnresolvedIndexConflicts => 'تضارب الفهرس غير المحلول';

  @override
  String get gitUiUnresolvedConflicts => ' · النزاعات التي لم تحل';

  @override
  String get gitUiReviewOperation => 'عملية الاستعراض';

  @override
  String get gitUiRefresh => 'تحديث';

  @override
  String get gitUiCreateNamedStash => 'إنشاء خبأ اسمه';

  @override
  String get gitUiCreateStash => 'حفظ التغييرات مؤقتًا…';

  @override
  String get gitUiNoStashes => 'لا يوجد مخابئ';

  @override
  String get gitUiSelectAStashToInspectItsChanges => 'حدد مخبأ لفحص تغييراته';

  @override
  String get gitUiStashedUntrackedFiles => 'الملفات غير المتعقبة';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'افحص الملفات غير المتعقبة المخبأة...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'إعادة حالة خبأ / مؤشر عند تطبيق';

  @override
  String get gitUiApplyAndRetain => 'تطبيق والاحتفاظ بها';

  @override
  String get gitUiPop => 'أبي...';

  @override
  String get gitUiCreateBranch => 'إنشاء فرع…';

  @override
  String get gitUiDropStash => 'حذف التغييرات المحفوظة مؤقتًا…';

  @override
  String get gitUiBranchFromStash => 'إنشاء فرع من المحفوظ مؤقتًا';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'قم بإنشاء / التبديل إلى فرع في قاعدة المخبأ الأصلية ، ثم قم بتطبيقه. يتم الاحتفاظ بالخبأ الأصلي للحذف الصريح لاحقًا.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 هذا المخبأ؟';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'يتم الاحتفاظ بالمخزون الأصلي في حالة تطبيق النزاعات.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'يحذف هذا الخبيئة المدخلة. لا يتم تطبيق تغييراته.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'حل تعارضات الملفات غير المدمجة. لا توجد في Git أوامر متابعة أو إحباط للحفظ المؤقت؛ وتبقى النسخة الأصلية المحفوظة مؤقتًا.';

  @override
  String get gitUiStashNameMessage => 'اسم / رسالة stash';

  @override
  String get gitUiStashContentAndResultingIndex => 'محتوى Stash والفهرس الناتج';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'تتبع ستاش العمل والتغييرات المنظمة';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'حفظ التغييرات مؤقتًا مع إبقاء تغييرات الفهرس في مكانها (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'حفظ تغييرات الفهرس فقط مؤقتًا (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'تضمين الملفات غير المتعقبة';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'كل المسارات المؤهلة في هذا المستودع';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'لا توجد تغييرات مؤهلة لخيارات المخبأ هذه.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'حدد مسارًا واحدًا على الأقل مؤهلًا.';

  @override
  String get gitUiCreateStash2 => 'حفظ التغييرات مؤقتًا';

  @override
  String get gitUiCreateWorktree => 'أنشئ شجرة عمل...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'أنشئ إيداعًا قبل إنشاء شجرة عمل عند HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD منفصل';

  @override
  String get gitUiCurrent => 'الحالي';

  @override
  String get gitUiLocked => 'مغلق';

  @override
  String get gitUiOpenInBusyStack => 'فتح في BusyStack';

  @override
  String get gitUiStatusNotInspected => 'لم يتم فحص الحالة';

  @override
  String get gitUiDirty => 'قذر';

  @override
  String get gitUiClean => 'نظيف';

  @override
  String get gitUiOpenWorkingFolder => 'افتح مجلد العمل';

  @override
  String get gitUiMoveWorktree => 'حرّك شجرة العمل...';

  @override
  String get gitUiUnlock => 'فتح';

  @override
  String get gitUiLock => 'قفل';

  @override
  String get gitUiRemoveCleanWorktree => 'أزل شجرة العمل النظيفة...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'مراجعة الإزالة بما في ذلك التغييرات المحلية ...';

  @override
  String get gitUiNewWorktreeFolderName => 'اسم مجلد شجرة العمل الجديد';

  @override
  String get gitUiNewWorktreeBranch => 'فرع شجرة العمل الجديد';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'إنشاء $arg0 / $arg1 مع فرع محلي جديد في $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'اسم المجلد الوجهة';

  @override
  String get gitUiRemoveWorktree => 'إزالة شجرة العمل؟';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'تجاهل صراحة جميع التغييرات المحلية المتعقبة / غير المتتبعة في شجرة العمل هذه. تظل أشجار العمل المغلقة / قيد الاستخدام محمية.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'يرفض Git الإزالة إذا كانت هناك تغييرات محلية أو ملفات غير متتبعة أو قفل.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'تجاهل محتويات شجرة العمل المحلية وإزالتها';

  @override
  String get gitUiRemoveCleanWorktree2 => 'أزل شجرة العمل النظيفة';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'تكرر صراحة في الوحدات الفرعية المتداخلة للتحديثات / التزامن';

  @override
  String get gitUiNoRecordedSubmodules => 'لا توجد وحدات فرعية مسجلة';

  @override
  String get gitUiNotInitialized => 'غير مهيأ';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'الأصل gitlink: $arg0 تحقق من: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'مستودع القذرة المتداخلة';

  @override
  String get gitUiCleanNestedRepository => 'مستودع متداخل نظيف';

  @override
  String get gitUiNestedStatusUnavailable => 'حالة التعشيش غير متوفرة';

  @override
  String get gitUiEnterNestedRepository => 'أدخل مستودع متداخل';

  @override
  String get gitUiInitializeConfiguration => 'تهيئة التهيئة';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'تحديث إلى التزام الوالدين المسجل ...';

  @override
  String get gitUiFollowConfiguredRemoteBranch => 'اتبع تكوين الفرع البعيد...';

  @override
  String get gitUiSynchronizeConfiguredURLs => 'زامِن عناوين URL المُهيّأة...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'المرحلة الحالية مؤشر الوحدة الفرعية في الأصل';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'الأم و submodule يرتكب ، يدفع ، وحالة قذرة تبقى منفصلة. التصفح لا يقوم بتهيئة أو تحديثها.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'اجلب وتحقق من التزام الفرع البعيد الذي تم تكوينه. هذا يختلف عن gitlink المسجل للوالد. التكرار: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'تهيئة حسب الحاجة وتحقق من بالضبط $arg0. التكرار: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'تطبيق عملية تكوين الوحدة الفرعية التي تمت مراجعتها. التكرار: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'تطبيق عملية submodule';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'افحص مراجعة مسجلة أو أنشئ فرع استرداد. لا يسترد Reflog محتوى تعسفيًا غير محفوظ أو غير متتبع.';

  @override
  String get gitUiSelectAReflogEntry => 'اختر إدخال reflog';

  @override
  String get gitUiPreviousPage => 'الصفحة السابقة';

  @override
  String get gitUiNextPage => 'الصفحة التالية';

  @override
  String get gitUiRecoveryBranchName => 'اسم فرع الاسترداد';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'إنشاء فرع في $arg0 ؛ ملفات العمل والفرع الحالي دون تغيير.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'أنشئ فرعًا للاسترداد...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'لقطة استرداد للقراءة فقط';

  @override
  String get gitUiInspectSnapshot => 'افحص اللقطة...';

  @override
  String get gitUiReviewReset => 'مراجعة إعادة الضبط…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'صفحة $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'يجب أن يمتلك تأريخ نص Git حقله القابل للتحرير.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'تحرير HEAD | الفهرس | شجرة العمل…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'تغير الفهرس أو محتوى العمل الذي تمت مراجعته. انعش هذه المقارنة قبل التدريج.';

  @override
  String get gitUiRefreshComparison => 'تحديث المقارنة';

  @override
  String get gitUiPreviousChangedFile => 'الملف السابق تم تغييره';

  @override
  String get gitUiNextChangedFile => 'التالي تغير الملف';

  @override
  String get gitUiPreviousDifference => 'الفرق السابق';

  @override
  String get gitUiNextDifference => 'الفرق التالي';

  @override
  String get gitUiComparisonMode => 'وضع المقارنة';

  @override
  String get gitUiSideBySide => 'جنبا إلى جنب';

  @override
  String get gitUiUnified => 'موحد';

  @override
  String get gitUiDiffDisplayOptions => 'خيارات العرض Diff';

  @override
  String get gitUiWrap => 'لف';

  @override
  String get gitUiWords => 'الكلمات';

  @override
  String get gitUiCollapseContext => 'طي السياق';

  @override
  String get gitUiIgnoreWhitespace => 'تجاهل المساحة البيضاء';

  @override
  String get gitUiSearchComparison => 'مقارنة البحث';

  @override
  String get gitUiSearch => 'بحث';

  @override
  String get gitUiCloseSearch => 'أغلق البحث';

  @override
  String get gitUiStagingActions => 'إجراءات الفهرس';

  @override
  String get gitUiStagingActions2 => 'إجراءات الفهرس…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'إزالة الأسطر المعدلة المحددة من الفهرس';

  @override
  String get gitUiStageSelectedChangedLines =>
      'إضافة الأسطر المعدلة المحددة إلى الفهرس';

  @override
  String get gitUiUnstageWholeFile => 'إزالة الملف كاملًا من الفهرس';

  @override
  String get gitUiStageWholeFile => 'إضافة الملف كاملًا إلى الفهرس';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 الخطوط التي تم تغييرها فقط مخفية  إظهار التغييرات الدقيقة';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 تغيير الخطوط المحددة  إعدادات العرض أبدا تغيير بايت نظمت.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'مقارنة للقراءة فقط · انسخ النص أو عدّل إعدادات العرض.';

  @override
  String get gitUiNoFinalNewline => ' · لا يوجد سطر جديد نهائي';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1  $arg2 بايت $arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'مقارنة النص غير متوفرة لهذه المحتويات.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'هذه المقارنة تتجاوز الحد الأقصى لمراجعة النص. لم يتم الإعلان عن المحتويات متطابقة.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'المحتويات المقارنة متطابقة.';

  @override
  String get gitUiUnstage => 'انستاج';

  @override
  String get gitUiStage => 'المرحلة';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 تغير الخط';
  }

  @override
  String get gitUiContext => 'السياق';

  @override
  String get gitUiExpandUnchangedContext => 'توسيع السياق دون تغيير';

  @override
  String get gitUiUnstageThisHunk => 'إزالة هذا المقطع من الفهرس';

  @override
  String get gitUiStageThisHunk => 'إضافة هذا المقطع إلى الفهرس';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'تحرير المحتوى المنظم  $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult => 'كتابة مراجعة نتيجة الفهرس';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'الفهرس';

  @override
  String get gitUiWorkingTree => 'شجرة العمل';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'مؤشر  قابل للتحرير UTF-8 نقطة';

  @override
  String get gitUiUndo => 'تراجع';

  @override
  String get gitUiRedo => 'إعادة';

  @override
  String get gitUiReloadIndexReview => 'إعادة تحميل مراجعة الفهرس؟';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'أعد تحميل إصدارات HEAD والفهرس والعمل الحالية. سيحل هذا محل مسودة محرر الفهرس غير المحفوظة.';

  @override
  String get gitUiReplaceDraftAndReload => 'يستعاض عن المشروع ويعاد تحميله';

  @override
  String get gitUiReloadVersions => 'أعد تحميل الإصدارات...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'اكتب النتيجة المحررة إلى إدخال الفهرس هذا';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'ملفات العمل تبقى على القرص. راجع الفهرس المحرر قبل التقديم.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'مراجعة التغييرات في تنسيق نص الفهرس';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'قم بتحديث إدخال الفهرس الذي تمت مراجعته فقط لـ $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => 'اكتب نتيجة الفهرس المُراجعة';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'تم تغيير النتيجة المحررة أثناء مراجعة التنسيق. راجعها مرة أخرى.';

  @override
  String get gitUiSynchronizeScrolling => 'زامِن التمرير';

  @override
  String get gitUiReadOnlyRevisionContent => 'محتوى مراجعة للقراءة فقط';

  @override
  String get gitUiEditableIndexContent => 'محتوى الفهرس القابل للتحرير';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'المراجعة المطلوبة خارج المرشحات الحالية. إعادة تعيين المرشحات للكشف عنها.';

  @override
  String get gitUiFilterLog => 'سجل الفلتر';

  @override
  String get gitUiFilters => 'مرشحات...';

  @override
  String gitUiFiltersCount(String count) {
    return 'مرشحات ($count)...';
  }

  @override
  String get gitUiMessage => 'الرسالة…';

  @override
  String get gitUiAuthor => 'المؤلف…';

  @override
  String get gitUiPath => 'المسار...';

  @override
  String get gitUiDate => 'التاريخ...';

  @override
  String get gitUiMessageFilter => 'فلتر الرسائل';

  @override
  String get gitUiAuthorFilter => 'الكاتب filter';

  @override
  String get gitUiPathFilter => 'مسار المرشّح';

  @override
  String get gitUiMessage2 => 'الرسالة';

  @override
  String get gitUiAuthor2 => 'المؤلف';

  @override
  String get gitUiPath2 => 'المسار';

  @override
  String get gitUiDateFilter => 'تاريخ المرشّح...';

  @override
  String get gitUiResetFilters => 'إعادة تعيين المرشحات';

  @override
  String get gitUiRefreshLog => 'تحديث السجل';

  @override
  String get gitUiGoToCommitReference => 'انتقل إلى الالتزام / المرجع ...';

  @override
  String get gitUiBackToHEAD => 'العودة إلى HEAD';

  @override
  String get gitUiOrderedCherryPick => 'انتقاء الإيداعات بالترتيب المحدد';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'استعراض الكرز بيك ($arg0) ...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'قارن بين اثنين من المراجعات المختارة...';

  @override
  String get gitUiToggleBranchesPane => 'بدّل جزء الفروع';

  @override
  String get gitUiFilterBranchesAndTags => 'تصفية الفروع والعلامات';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'الالتزام $arg0';
  }

  @override
  String get gitUiCommitDetails => 'إلتزم بالتفاصيل...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'مرجع: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'اختيار هذا الإيداع';

  @override
  String get gitUiBranchOrTag => 'الفرع أو العلامة';

  @override
  String get gitUiAllReferences => 'جميع المراجع';

  @override
  String get gitUiLocal => 'المحلية';

  @override
  String get gitUiRemote => 'المستودع البعيد';

  @override
  String get gitUiTags => 'الوسوم';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'لا توجد التزامات تطابق المرشحات الحالية.';

  @override
  String get gitUiObjectID => 'معرّف الكائن';

  @override
  String get gitUiSubjectReferences => 'الموضوع / المراجع';

  @override
  String get gitUiDate2 => 'التاريخ';

  @override
  String get gitUiGitCommits => 'إيداعات Git';

  @override
  String get gitUiParents => 'الإيداعات الأصلية';

  @override
  String gitUiArg0Parents(String arg0) {
    return 'الآباء $arg0';
  }

  @override
  String get gitUiLoadMoreCommits => 'تحميل المزيد من الإلتزامات';

  @override
  String get gitUiLoadingChangedFiles => 'تحميل الملفات التي تم تغييرها';

  @override
  String get gitUiNoChangedFiles => 'لم يتم تغيير الملفات';

  @override
  String get gitUiSelectACommit => 'اختر التزامًا';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'قارن الأم $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'الملفات المعدلة';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'المؤلف: $arg0 $arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'عميل: $arg0 $arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'الحدود الضحلة / الجزئية: الكائن الأصلي غير متوفر.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'الأم خارج هذه الصفحة أو الحدود الضحلة.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'الإيداع الأصل $arg0';
  }

  @override
  String get gitUiCommitActions => 'إرتكبْ الإجراءاتَ...';

  @override
  String get gitUiEmptyTree => 'شجرة فارغة';

  @override
  String get gitUiCreateBranch2 => 'إنشاء فرع';

  @override
  String get gitUiCreateTag => 'إنشاء وسم';

  @override
  String get gitUiCompareRevisions => 'مقارنة المراجعات';

  @override
  String get gitUiOpenSnapshot => 'افتح اللقطة';

  @override
  String get gitUiRevertCommit => 'تراجع الالتزام';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'قاعدة تفاعلية بعد هذه الحدود';

  @override
  String get gitUiResetCurrentBranch => 'إعادة ضبط الفرع الحالي';

  @override
  String get gitUiCopyFullObjectID => 'انسخ معرف الكائن الكامل';

  @override
  String get gitUiGoToCommitReference2 => 'انتقل إلى الالتزام / المرجع';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'أدخل معرف التزام أو مرجع للكشف في السجل.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'والتنقيح المطلوب غير متاح.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'البيانات الوصفية للمستودع للقراءة فقط. التفتيش الفرع والمقارنة لا تزال متاحة.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'ملفات العمل غير متوفرة أو للقراءة فقط. تبديل فرع ودمج غير متوفرة.';

  @override
  String get gitUiSearchBranchesAndTags => 'البحث في الفروع والوسوم';

  @override
  String get gitUiNewBranch => 'فرع جديد…';

  @override
  String get gitUiLocalBranches => 'الفروع المحلية';

  @override
  String get gitUiRemoteBranches => 'الفروع البعيدة';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'المسارات $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'تسجيل المغادرة في $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'تحديث البيانات الوصفية للفرع';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'بدّل إلى $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'فتح شجرة العمل المحتلة';

  @override
  String get gitUiCreateLocalTrackingBranch => 'أنشئ فرع تتبع محلي...';

  @override
  String get gitUiCompareToCurrentHEAD => 'مقارنة مع HEAD الحالي';

  @override
  String get gitUiMergeIntoCurrentBranch => 'ادمج في الفرع الحالي...';

  @override
  String get gitUiRename => 'إعادة تسمية...';

  @override
  String get gitUiChangeUpstream => 'غيّر المنبع...';

  @override
  String get gitUiDelete => 'احذف...';

  @override
  String get gitUiDeleteFromRemote => 'احذف من بعيد...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'إجراءات لـ $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'اسم الفرع المحلي';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'أنشئ في $arg0. سيتم التحقق من الفرع الجديد.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'سيقوم الفرع المحلي بتتبع $arg0 ويتم التحقق منه.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'اختر عن بعد للحذف';

  @override
  String get gitUiDeleteRemoteReference => 'احذف المرجع البعيد';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'دمج $arg0 في $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'إعادة تسمية $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'المنبع ل $arg0';
  }

  @override
  String get gitUiNoUpstream => 'لا يوجد منبع';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'حذف $arg0؟';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 الهدف $arg1 الحذف المحلي فقط. تم رفض فرع غير مدمج.';
  }

  @override
  String get gitUiDelete2 => 'حذف';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'حذف فرع غير مندمج $arg0؟';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return 'تقارير $arg0 Git هذا الفرع غير مدمج بالكامل. احذف المرجع المحلي بوضوح بعد مراجعة التزاماته ؛ النسخ عن بعد لم تتغير.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => 'احذف الفرع المحلي غير المدمج';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'الوجهة: $arg0  $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'فرع المصدر أو العلامة';

  @override
  String get gitUiMergePolicy => 'سياسة الدمج';

  @override
  String get gitUiFastForwardWhenPossible =>
      'سريع إلى الأمام عندما يكون ذلك ممكنا';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'دائما إنشاء التزام دمج';

  @override
  String get gitUiFastForwardOnly => 'سريع إلى الأمام فقط';

  @override
  String get gitUiSquashIntoStagedChanges => 'الاسكواش في التغييرات على مراحل';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'توقف قبل إنشاء التزام الدمج';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'التقديم السريع معطّل حتى لا يتحرك HEAD قبل المراجعة.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'يترك تغييرات منظمة لالتزام منفصل ؛ هذا ليس دمج مستمر.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'ولا تزال النزاعات متاحة في حيز العمل المشترك لحلها.';

  @override
  String get gitUiAddRemote => 'أضف جهاز التحكم عن بعد...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'جلب: $arg0 دفع: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'أزِل بعيدًا...';

  @override
  String get gitUiChangeFetchURL => 'غيّر عنوان الجلب...';

  @override
  String get gitUiAddPushDestination => 'أضف وجهة دفع...';

  @override
  String get gitUiRemovePushDestination => 'أزل وجهة الدفع...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'إدارة $arg0';
  }

  @override
  String get gitUiRemoteName => 'الاسم البعيد';

  @override
  String get gitUiNewRemoteName => 'اسم جديد عن بعد';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'عنوان URL للمستودع أو المصدر المحلي';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'أدخل الوجهة التي تمت مراجعتها بالضبط لإزالتها.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'يتم توفير وثائق التفويض من قبل المساعدين تكوين أو موجه خاص.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'إزالة البعيد $arg0؟';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'يزيل التكوين عن بعد المحلية وتتبع المراجع. فإنه لا حذف مستودع الخادم.';

  @override
  String get gitUiRemoveRemote2 => 'أزل بعيدًا';

  @override
  String get gitUiCommitScopeEntireRepository => 'نطاق الإلتزام: مستودع كامل';

  @override
  String get gitUiCachedTracking => 'تتبع المخبأ';

  @override
  String get gitUiAmendLastCommit => 'تعديل آخر إيداع';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'يتم احترام السنانير المكونة والتوقيع.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'يعيد كتابة إيداع HEAD المحدد. التتبع البعيد لا يثبت أنه لم يُنشر.';

  @override
  String get gitUiRepository => 'المستودع';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'منفصلة $arg0';
  }

  @override
  String get gitUiLog => 'السجل';

  @override
  String get gitUiRepositoryActions => 'إجراءات المستودع';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'تتبع مخزّن مؤقتًا · $upstream · متقدم $ahead · متأخر $behind';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'مستودع عارية  لا شجرة العمل. فتح سجل لفحص تاريخها.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'مستودع للقراءة فقط  التدريج والالتزامات غير متوفرة.';

  @override
  String get gitUiRepositoryStatusUnavailable => 'حالة المستودع غير متوفرة';

  @override
  String gitUiAmendRevision(String revision) {
    return 'تعديل $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'إضافة سطر إقرار';

  @override
  String get gitUiUseConfiguredSigningPolicy => 'استخدم سياسة التوقيع المهيأة';

  @override
  String get gitUiCryptographicallySignThisCommit => 'وقع هذا الإلتزام';

  @override
  String get gitUiDoNotSignThisCommit => 'لا توقع على هذا الالتزام';

  @override
  String get gitUiRecentCommitMessages => 'رسائل الالتزام الأخيرة...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'استخدم قالب الالتزام المُهيّأ...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'هوية المؤلف وخطافات تكوين...';

  @override
  String get gitUiDraftMessage => 'مسودة الرسالة...';

  @override
  String get gitUiCommitOptions => 'خيارات الإيداع';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'مشروع الاحتفاظ في الذاكرة؛ حفظه فشل. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'رسالة الإيداع';

  @override
  String get gitUiGitOperationInProgress => 'عملية Git قيد التنفيذ';

  @override
  String get gitUiCancel => 'إلغاء';

  @override
  String get gitUiAmendStaged => 'عدّل على مراحل';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'إيداع محتوى الفهرس ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'إيداع ودفع…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'لم يتم تكوين قالب التزام قابل للقراءة.';

  @override
  String get gitUiCommitIdentityAndHooks => 'إلتزم بالهوية والخطافات';

  @override
  String get gitUiRecentMessages => 'الرسائل الأخيرة';

  @override
  String get gitUiReplaceMessageDraft => 'استبدل مسودة الرسالة؟';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'استبدال رسالة الالتزام الحالية بالرسالة المحددة؟';

  @override
  String get gitUiReplaceDraft => 'يستعاض عن مشروع';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'الالتزام المحلي $arg0 موجود.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'الالتزام المحلي $arg0 موجود. سجل المراجعة قبل محاولة ارتكاب آخر. تم الاحتفاظ بمسودة الرسالة.';
  }

  @override
  String get gitUiCommitAuthorName => 'اسم المؤلف الملتزم';

  @override
  String get gitUiCommitAuthorEmail => 'البريد الإلكتروني لمؤلف الالتزام';

  @override
  String get gitUiConfiguredDefault => 'تكوين افتراضي';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'التوقيع: $arg0  $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'السنانير المكونة: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'سطر الإقرار بيان داخل الرسالة وهو منفصل عن التوقيع التشفيري. تُحفظ الهوية في إعدادات هذا المستودع فقط، وتبقى المسودة محفوظة.';

  @override
  String get gitUiSaveRepositoryIdentity => 'احفظ هوية المستودع';

  @override
  String get gitUiStaged => 'في الفهرس';

  @override
  String get gitUiUntracked => 'غير متتبعة';

  @override
  String get gitUiUnstaged => 'خارج الفهرس';

  @override
  String get gitUiConflicts => 'التعارضات';

  @override
  String get gitUiNoChanges => 'لا توجد تغييرات';

  @override
  String get gitUiRepositoryChangeTree => 'شجرة تغيير المستودع';

  @override
  String get gitUiChanges => 'التغييرات';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'وسّع';

  @override
  String get gitUiCollapse => 'اطوِ';

  @override
  String get gitUiUnstageFile => 'إزالة الملف من الفهرس';

  @override
  String get gitUiStageFile => 'إضافة الملف إلى الفهرس';

  @override
  String get gitUiExpandGroup => 'وسّع المجموعة';

  @override
  String get gitUiCollapseGroup => 'اطوِ المجموعة';

  @override
  String get gitUiReviewDifference => 'مراجعة الفرق';

  @override
  String get gitUiUnstageSelectedFiles => 'إزالة الملفات المحددة من الفهرس';

  @override
  String get gitUiStageSelectedFiles => 'إضافة الملفات المحددة إلى الفهرس';

  @override
  String get gitUiFileHistoryAndBlame => 'ملف التاريخ واللوم...';

  @override
  String get gitUiDeleteUntrackedFile => 'احذف ملفّ.';

  @override
  String get gitUiDiscardUnstagedChange => 'تخلّى عن التغيير الغير مُتدرّج...';

  @override
  String get gitUiFileHistory => 'سجل الملف';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'تجاهل $arg0؟';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 بايت  $arg1 يستبدل محتوى العمل بالفهرس ، أو يحذف هذا الملف غير المتتبع. يتم الاحتفاظ بالمحتوى المرحلي. يجب مراجعة مستندات المضيف غير المحفوظة أولاً.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'احذف الملف غير المتعقب';

  @override
  String get gitUiDiscardWorkingChange => 'تجاهل تغيير العمل';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'حذف مرجع REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'هذا يزيل المرجع على كل وجهة دفع فعلية مدرجة أدناه. يتم الاحتفاظ بالفروع / العلامات المحلية. يتم إصلاح النصائح المتوقعة من خلال هذا الاستعراض.';

  @override
  String get gitUiReferenceDoesNotExist => 'المرجعية غير موجودة';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 نصيحة متوقعة: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'اكتمل الحذف عن بُعد.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'حذف $arg0 من جهاز التحكم عن بعد؟';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'ستتم إزالة نصائح الوجهة المحددة الموضحة أعلاه. أي طرف عن بعد تغيير توقف العملية لمراجعة أخرى.';

  @override
  String get gitUiReviewAndDeleteFromRemote => 'مراجعة وحذف من بعيد...';

  @override
  String get gitUiDestinationReference => 'مرجع الوجهة';

  @override
  String get gitUiReviewDestinations => 'استعراض الوجهات';

  @override
  String get gitUiNewRemoteBranch => 'فرع بعيد جديد';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · المتوقع: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'تلتزم الوجهة التي لا تتوفر محليًا. أحضر تلك الوجهة التي راجعت قبل مراجعة التاريخ الصادر.';

  @override
  String get gitUiFetchReviewedDestination => 'جلب وجهة مراجعة';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'اختيار وجهة ومراجعة الالتزامات الصادرة.';

  @override
  String get gitUiNoOutgoingCommits => 'لا توجد التزامات صادرة';

  @override
  String get gitUiSelectAnOutgoingCommit => 'اختر التزامًا صادرًا';

  @override
  String get gitUiLoadMoreOutgoingCommits =>
      'تحميل المزيد من الالتزامات الصادرة';

  @override
  String get gitUiSetThisDestinationAsUpstream => 'عيّن هذه الوجهة كمنبع';

  @override
  String get gitUiChooseExactTagsToPublish => 'اختر العلامات الدقيقة للنشر';

  @override
  String get gitUiTagsNone => 'العلامات: لا شيء';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'العلامات: $arg0 المحدد';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'نشر بالضبط: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'اكتمل الدفع. الالتزام المحلي لا يزال متاحًا في السجل.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'يتطلب الدفع القسري تطابق أطراف مراجع الوجهة تمامًا مع ما عُرض في هذه المراجعة.';

  @override
  String get gitUiForceWithReviewedLease => 'قوة مع مراجعة الإيجار...';

  @override
  String get gitUiPush => 'دفع';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'دفع القوة مع عقود الإيجار المراجعة؟';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'أعد كتابة $arg0 فقط إذا كانت كل وجهة نائية لا تزال تحتوي على الطرف الدقيق الموضح أعلاه.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'قد يكون آخرون يستخدمون هذا السجل بالفعل. الجلب في الخلفية لا يجدّد شرط الحماية هذا.';

  @override
  String get gitUiForceWithLease => 'القوة مع الإيجار';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'النتيجة البعيدة غير مؤكدة. راجع الوجهات مرة أخرى قبل دفعة أخرى.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'الأم $arg0  $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'عن بعد لجلب';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune حذف فروع التتبع عن بعد';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'جلب تحديثات معلومات التتبع عن بعد دون استبدال ملفات العمل.';

  @override
  String get gitUiFetch => 'جلب';

  @override
  String get gitUiSourceRemote => 'مصدر بعيد';

  @override
  String get gitUiSourceBranch => 'فرع المصدر';

  @override
  String get gitUiReviewedStrategy => 'الاستراتيجية المستعرضة';

  @override
  String get gitUiMerge => 'دمج';

  @override
  String get gitUiRebase => 'إعادة تأسيس';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'توقف إذا كانت الوجهة لا يمكن أن تسرع إلى الأمام؛ لا دمج أو إعادة قاعدة.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'دمج مع التزام دمج، بما في ذلك عندما سريع إلى الأمام هو ممكن.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'ادمج؛ اسمح بسرعة إلى الأمام عندما يكون ذلك ممكنًا.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'إعادة قاعدة التاريخ المحلي مع الحفاظ على الدمج المحلي.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'إعادة قاعدة المحلية يرتكب كتاريخ خطي.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'تم تكوين Git لإعادة قاعدة تفاعلية. حدد استراتيجية سحب صراحة هنا ، أو قم بجلب وفتح إعادة قاعدة ... لمراجعة خطة.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'استخدم rebase العادي المُراجع لهذا السحب';

  @override
  String get gitUiOptions => 'الخيارات';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'دائما إنشاء التزام دمج (لا سريع إلى الأمام)';

  @override
  String get gitUiPreserveLocalMergeCommits => 'الحفاظ على الدمج المحلي';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'قد تمنع التغييرات المحلية السحب. قم بمراجعتها / الالتزام بها أو قم بإنشاء خبأ بشكل صريح.';

  @override
  String get gitUiStashes => 'التغييرات المحفوظة مؤقتًا';

  @override
  String get gitUiCreateOrReviewStash => 'أنشئ أو راجع خبأ...';

  @override
  String get gitUiPullWithSelectedStrategy => 'سحب مع استراتيجية مختارة';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'عنوان URL للمستودع أو مصدر Git محلي';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS أو SSH أو المسار المحلي';

  @override
  String get gitUiFolderToInitialize => 'مجلّد إلى تهيئة';

  @override
  String get gitUiFinalCloneDestination => 'الوجهة المستنسخة النهائية';

  @override
  String get gitUiChoose => 'اختر...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'يخلق جيت البيانات الوصفية فقط. الملفات الموجودة ليست على مراحل أو ارتكبت.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'يجب ألا تكون الوجهة النهائية موجودة أو أن تكون فارغة. لن تُستبدل بيانات المستخدم الموجودة مطلقًا.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'الفرع الأولي  استخدامات فارغة سياسة Git الفعالة';

  @override
  String get gitUiSelectedBranchOptional => 'فرع محدد  اختياري';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'تهيئة/تحديث الوحدات الفرعية بشكل صريح';

  @override
  String get gitUiPreparingGitOperation => 'إعداد عملية GIT...';

  @override
  String get gitUiThisAttemptCreated => 'هذه المحاولة التي تم إنشاؤها';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'كانت الوجهة موجودة قبل هذه المحاولة:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'يبقى الدليل للتفتيش. مراجعته قبل محاولة استنساخ أخرى.';

  @override
  String get gitUiNoDestinationDirectoryRemains => 'لا يوجد دليل للوجهة.';

  @override
  String get gitUiCancelProcess => 'إلغاء العملية';

  @override
  String get gitUiInitialize => 'تهيئة';

  @override
  String get gitUiClone => 'استنساخ';

  @override
  String get gitUiChooseNewBase => 'اختيار الأساس الجديد';

  @override
  String get gitUiChooseUpstreamBoundary => 'اختيار حد المنبع';

  @override
  String get gitUiNewBase => 'الأساس الجديد';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'حد المنبع · مستبعد';

  @override
  String get gitUiSameAsUpstreamBoundary => 'مثل حد المنبع';

  @override
  String get gitUiChooseBranchTagOrCommit => 'اختيار فرع أو وسم أو إيداع…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'استخدم المنبع كقاعدة جديدة';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'اختر فرعًا صالحًا أو علامة أو التزام من السجل.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'لا يمكن تطبيق squash أو fixup على أول إيداع محتفظ به في كتلة فرع، لعدم وجود إيداع سابق لدمجه معه.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'كتلة الفرع $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[الرسالة سوف تطلب رسالة جديدة]\n';

  @override
  String get gitUiPlannedCommitMessages => 'رسائل الالتزام المخطط لها';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'معاينة الرسالة الأصلية / المجمعة  Git يطلب رسائل إعادة الصياغة / الاسكواش النهائية';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'النتيجة $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'الفرع الحالي: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD منفصل';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'إعادة التأسيس تعيد كتابة هويات الإيداعات. معلومات تتبع الفروع البعيدة لا تثبت أن السجل لم يُنشر من قبل.';

  @override
  String get gitUiIncludeRootCommits => 'تضمين الإيداعات الجذرية';

  @override
  String get gitUiMergeCommits => 'دمج يلتزم';

  @override
  String get gitUiFlattenHistory => 'تسطيح السجل';

  @override
  String get gitUiPreserveBranchStructure => 'الحفاظ على بنية الفروع';

  @override
  String get gitUiAutosquash => 'ضم تلقائي';

  @override
  String get gitUiPrepareGitPlan => 'إعداد خطة Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'الإيداعات التي ستُعاد تطبيقها: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'يشمل جميع الالتزامات الجذرية التي يمكن الوصول إليها من هذا الفرع.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'ستُعاد تطبيق الإيداعات بعد $boundary على $base؛ الإيداع الحدّي نفسه غير مشمول.';
  }

  @override
  String get gitUiRoot => 'الجذر';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git branch/label/إعادة تعيين/دمج هيكل';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'اختر وضعًا واضحًا أو وضعًا قديمًا للجذر ، ثم قم بإعداد الخطة.';

  @override
  String get gitUiMoveUp => 'نقل لأعلى';

  @override
  String get gitUiMoveDown => 'نقل لأسفل';

  @override
  String get gitUiResetPlan => 'إعادة ضبط الخطة';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · فرع كتلة $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'حدد التزامًا للحصول على التفاصيل والملفات التي تم تغييرها';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'معاينة رسائل الإلتزام مجتمعة...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt/ ينقل الالتزام المحدد. لن يتم تحديث مراجع الفروع غير المرتبطة تلقائيًا.';

  @override
  String get gitUiCancelPlan => 'ألغِ الخطة';

  @override
  String get gitUiStartReviewedRebase => 'بدء إعادة التأسيس التي تمت مراجعتها؟';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'أعد كتابة الالتزامات المخططة لـ $arg0 على $arg1. تظل الالتزامات المنسدلة ملحوظة بشكل واضح في هذه الخطة حتى تبدأ.';
  }

  @override
  String get gitUiStartRebase => 'بدء إعادة التأسيس';

  @override
  String get gitUiNoContinuingGitOperation => 'لا عملية Git مستمرة';

  @override
  String get gitUiStoppedForEditingAmend => ' · توقف للتحرير / التعديل';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'هذه هي إدخالات الفهرس غير مندمجة ، ربما من تطبيق خبأ. Git لا يوجد لديه متابعة خبأ أو أمر إجهاض.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'تحرير ملفات العمل، مرحلة وتعديل الالتزام الحالي، ثم الاستمرار في هذه القاعدة.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · مراحل الفهرس غير المدمجة $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'المؤشر لا يوجد لديه إدخالات لم تحل.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'حافظ على الالتزام الحالي كالتزام فارغ';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'الفهرس الحقيقي لا يحتوي على تغييرات مرحلية. إنشاء التزام فارغ صريح ، ثم الاستمرار في التسلسل إذا كان لا يزال نشطًا.';

  @override
  String get gitUiKeepEmptyCommit => 'حافظ على الالتزام الفارغ...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'سيحاول Git العودة إلى بداية العملية. لا يضمن استعادة المحتوى السابق خارج الفهرس أو غير المتتبع أو غير المحفوظ.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'تخطي الالتزام الحالي والاستمرار في الالتزام المخطط التالي.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'ننسى مسك الدفاتر هذه العملية مع الاحتفاظ الملفات والفهرس الحالي.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'تابع $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'إعادة تحميل إصدارات الصراع؟';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'استبدل مسودة النتيجة غير المحفوظة بملف العمل الحالي. يتم الاحتفاظ بمحتوى العمل المحفوظ.';

  @override
  String get gitUiLoadingConflictVersions => 'جاري تحميل إصدارات التعارض...';

  @override
  String get gitUiLoadingConflict => 'تحميل التعارض';

  @override
  String get gitUiBaseLeft => 'قاعدة  يسار';

  @override
  String get gitUiBaseRight => 'قاعدة  يمين';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'لا يوجد مدخل أساسي لهذا النزاع';

  @override
  String get gitUiAcceptEntireLeftFile => 'اقبل الملف الأيسر بالكامل...';

  @override
  String get gitUiAcceptEntireRightFile => 'اعتماد الملف الأيمن بالكامل…';

  @override
  String get gitUiPreviousConflictRegion => 'منطقة النزاع السابقة';

  @override
  String get gitUiNextConflictRegion => 'منطقة الصراع القادمة';

  @override
  String get gitUiManualResolution => 'القرار اليدوي';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'منطقة $arg0 / $arg1  $arg2 استعرض';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'تجاوزت محاذاة المصدر الحد الأقصى لمقارنة النص ؛ تظل أجزاء المصدر متاحة للمراجعة اليدوية.';

  @override
  String get gitUiAcceptLeftRegion => 'قبول المنطقة اليسرى';

  @override
  String get gitUiAcceptRightRegion => 'قبول المنطقة الصحيحة';

  @override
  String get gitUiKeepManualResultForRegion =>
      'حافظ على النتيجة اليدوية للمنطقة';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'تطبيق التغييرات غيت غير متضاربة؟';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'استبدل مسودة النتيجة الحالية بمعاينة دمج Git. هذا يتجاهل تعديلات النتائج اليدوية غير المحفوظة ؛ ملف العمل لم يتغير حتى حفظ.';

  @override
  String get gitUiUseMergePreview => 'استخدم معاينة الدمج';

  @override
  String get gitUiApplyNonConflictingChanges => 'تطبيق تغييرات غير متضاربة...';

  @override
  String get gitUiLeftSource => 'المصدر الأيسر';

  @override
  String get gitUiResult => 'النتيجة';

  @override
  String get gitUiRightSource => 'المصدر الصحيح';

  @override
  String get gitUiStage2 => 'المرحلة الثانية';

  @override
  String get gitUiStage3 => 'المرحلة 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'إصدارات التعارض غير متوفرة. تحديث لمراجعة حالتها الحالية.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'النتيجة محفوظة على القرص. الفهرس لا يزال يحدد ما إذا كان هذا الملف قد تم حله.';

  @override
  String get gitUiSaveResultDraft => 'حفظ مسودة النتيجة';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'تطبيق النتيجة وإضافة الحل إلى الفهرس';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'نتيجة  محتوى العمل UTF-8 قابل للتحرير';

  @override
  String get gitUiEditableConflictResult => 'نتيجة النزاع القابلة للتحرير';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'اليسار: $arg0 · $arg1\nاليمين: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'اختر المحتوى أو الحذف أو وحدة فرعية تلتزم صراحة. لا يتم فك تشفير أي بيانات ثنائية كنص قابل للتحرير.';

  @override
  String get gitUiUseEntireLeftContent => 'استخدم المحتوى الأيسر بالكامل...';

  @override
  String get gitUiUseEntireRightContent => 'استخدام المحتوى الأيمن بالكامل…';

  @override
  String get gitUiDeleteThisPath => 'احذف هذا المسار...';

  @override
  String get gitUiResolvedSubmoduleCommit =>
      'الالتزام بالوحدات الفرعية التي تم حلها';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'مرحلة هذه gitlink بالضبط في الوالد. هذا لا تحقق من أو ارتكاب submodule.';

  @override
  String get gitUiSetResolvedGitlink => 'ضبط حلّ gitlink.';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'قاعدة  مرحلة $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'تم تحرير النتيجة. احتفظ بالنتيجة اليدوية أو حدد منطقة أخرى دون تغيير.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'هل تريد تطبيق الحل «$arg0»؟';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'المرحلة التي تم اختيارها gitlink ارتكاب في الوالد. لا يتم استبدال الخروج وحدة فرعية وملفاتها.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'يستبدل مسار العمل بأكمله $arg0 ويمرر القرار. سيتم التخلص من محتوى العمل الحالي وأي مسودة نتيجة غير محفوظة.';
  }

  @override
  String get gitUiApplyEntireFileDecision => 'تطبيق قرار الملف بالكامل';

  @override
  String get gitUiStageThisConflictResolution => 'مرحلة حل النزاع؟';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'استخدم النتيجة المحررة بالكامل كـ $arg0. يسجل Git المسار الذي تم حله عند إعداده. راجع كل المحتوى المقصود أولاً.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'تطبيق وإضافة إلى الفهرس';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'مراجعة التغييرات في تنسيق نص النتيجة';

  @override
  String get gitUiSaveReviewedResult => 'احفظ نتيجة المراجعة';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'إمكانية الوصول إلى جدول Native Git غير متوفرة. أعد المحاولة بعد إعادة توصيل التطبيق.';

  @override
  String get gitUiSans => 'دونس';

  @override
  String get gitUiSelect => 'اختر';

  @override
  String get gitUiContextMenu => 'قائمة السياق';

  @override
  String get gitUiCopyText => 'انسخ النص';

  @override
  String get gitUiLoadingRow => 'صف التحميل';

  @override
  String get gitUiRetry => 'إعادة المحاولة';

  @override
  String get gitUiGitMessage => 'رسالة Git';

  @override
  String get gitUiCancelPrompt => 'إلغاء موجه';

  @override
  String get gitUiUseMessageAndContinue => 'استخدم الرسالة وتابع';

  @override
  String get gitUiRespondPrivately => 'الرد بشكل خاص';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'تعذر حفظ تفضيلات العرض: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'تخصيص مشروع التخزين: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'عرض التفضيلات لا يمكن قراءته: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'تم الاحتفاظ بمسودة الالتزام في الذاكرة ولكن تعذر حفظها: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'يتم قراءة المستودع الذي تمت مراجعته فقط لهذه العملية. يبقى التاريخ وفحص المحتوى متاحين.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'عاد Git $arg0. لم يتمكن التطبيق من تحديث مستنداته: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'اختيار إيداع من السجل…';

  @override
  String get gitUiCurrentBranch => 'الفرع الحالي';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'لا توجد فروع أو علامات مطابقة. حدد التزام في السجل.';

  @override
  String get gitUiBranches => 'الفروع';

  @override
  String get gitUiPushCommits => 'دفع الإيداعات';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'اسحب إلى $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'حل $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'العملية الحالية';

  @override
  String get gitUiRebaseCommits => 'إعادة تأسيس الإيداعات';

  @override
  String get gitUiFetch2 => 'جلب…';

  @override
  String get gitUiPull => 'سحب…';

  @override
  String get gitUiPush2 => 'دفع…';

  @override
  String get gitUiBranches2 => 'الفروع…';

  @override
  String get gitUiManageRemotes => 'إدارة المستودعات البعيدة…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'ادمج في $arg0...';
  }

  @override
  String get gitUiRebase2 => 'إعادة تأسيس…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'النزاعات والعمليات الحالية..';

  @override
  String get gitUiStashes2 => 'التغييرات المحفوظة مؤقتًا…';

  @override
  String get gitUiWorktrees => 'أشجار العمل…';

  @override
  String get gitUiSubmodules => 'الوحدات الفرعية…';

  @override
  String get gitUiReflogAndRecovery => 'سجل المراجع والاستعادة…';

  @override
  String get gitUiCloneRepository => 'استنساخ المستودع…';

  @override
  String get gitUiRevokeRepositoryTrust => 'إلغاء الثقة في المستودع';

  @override
  String get gitUiWaitingForRepositoryStatus => 'في انتظار حالة المستودع';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'حالة المستودع غير متوفرة؛ تحديث';

  @override
  String get gitUiManageRemotes2 => 'إدارة المستودعات البعيدة';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'دمج في $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'أشجار العمل';

  @override
  String get gitUiSubmodules2 => 'الوحدات الفرعية';

  @override
  String get gitUiReflogAndRecovery2 => 'سجل المراجع والاستعادة';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'مستودع استنساخ  $arg0';
  }

  @override
  String get gitUiApply => 'تطبيق';

  @override
  String get gitUiResizeGitPanes => 'غيّر حجم أجزاء Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 في المئة';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'حالة الخروج: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'تم تغيير المستودع. تحديث ومراجعة قبل المحاولة مرة أخرى.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'عملية أخرى تحمل المستودع أو قفل الفهرس. انتظر ، ثم قم بالتحديث.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'مطلوب الثقة مستودع لهذه العملية.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'خدمة Git غير متصلة. أعد الاتصال والتوفيق بين المستودع.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'لا يمكن أن يدعم Git القابل للتنفيذ المثبت هذه العملية. راجع متطلبات وقت التشغيل أدناه.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'هذا المستودع قابل للقراءة فقط للعملية المطلوبة. المراجعة والتاريخ متوفران.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'العملية تحتاج إلى المصالحة. راجع المستودع الناتج أو الحالة البعيدة قبل تكرارها.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'فشلت مصادقة Git. راجع مساعد بيانات الاعتماد أو افتح حلقة المفاتيح التي تم تكوينها.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'فشل التحقق من مضيف SSH. راجع هوية المضيف من خلال أدوات SSH التي تم تكوينها.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'فشل تسجيل الدخول أو تم إلغاؤه. راجع مفتاح التوقيع والوكيل وأداة التوقيع المهيأة.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'تعيين اسم مؤلف مستودع والبريد الإلكتروني، ثم العودة إلى مشروع الرسالة المحفوظة.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'رفض Git التحديث الذي تمت مراجعته. قم بتحديث ومراجعة الوجهة الفعلية قبل المحاولة مرة أخرى.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'العمل أو التغييرات على مراحل منع هذه العملية. مراجعة, ارتكاب أو خبأ صراحة لهم.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'كائن Git المطلوب غير متوفر. راجع حدود المستودع الضحلة أو الجزئية واجلبها صراحة إذا لزم الأمر.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'فشلت عملية Git: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'التشخيصات';

  @override
  String get gitUiAuthorizeGitInspection => 'تخويل التفتيش Git ...';

  @override
  String get gitUiCopyDiagnostics => 'نسخ التشخيص';

  @override
  String get gitUiActions => 'إجراءات';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'فرع في $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'إنشاء فرع محلي دون التحقق من ذلك.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'الوسم $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'لقطة للقراءة فقط $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'انتقاء الإيداعات وتطبيقها';

  @override
  String get gitUiRevertCommits => 'الإلتزامات';

  @override
  String get gitUiCompareToFullRevisionID => 'مقارنة مع معرف المراجعة الكاملة';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'اتجاه مقارنة الشجرة: $arg0  تم إدخال المراجعة هنا.';
  }

  @override
  String get gitUiEnterAFullValidObjectID => 'أدخل معرف كائن صالح بالكامل.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0  $arg1  مقارنة الشجرة';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'إعادة تعيين $arg0 إلى $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'ينقل HEAD/الفرع الحالي. لا يستعيد reflog أي محتوى غير متتبع أو غير محفوظ بشكل عام.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'نقل HEAD مع إبقاء الفهرس وملفات العمل.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'نقل HEAD واستبدال الفهرس مع إبقاء ملفات العمل.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'استبدال HEAD والفهرس وملفات العمل المتتبعة؛ قد تُستبدل الملفات غير المتتبعة التي تعيق العملية.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'استبدال HEAD والفهرس والملفات المؤهلة؛ تُرفض العملية إن كانت ستفقد تغييرات محلية.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'إعادة تعيين مع $arg0؟';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0  $arg1 راجع تأثيرات الوضع المحدد قبل التقديم.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'إعادة تعيين $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'الهدف $arg0';
  }

  @override
  String get gitUiTagName => 'اسم الوسم';

  @override
  String get gitUiAnnotatedTag => 'وسم مشروح';

  @override
  String get gitUiCryptographicSigning => 'التوقيع التشفيري';

  @override
  String get gitUiConfiguredPolicy => 'السياسة المُكوّنة';

  @override
  String get gitUiSignThisTag => 'وقّع هذه العلامة';

  @override
  String get gitUiDoNotSign => 'لا توقع';

  @override
  String get gitUiTagMessage => 'رسالة الوسوم';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'ينشئ العلامة محليًا. نشر العلامات المحددة صراحة في مراجعة الدفع.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'الأشجار الكاملة: $arg0  $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'التالي تغيير صفحة الملف';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'لقطة مستودع للقراءة فقط. فتح ملف لا يتحقق أبدا من هذا التنقيح.';

  @override
  String get gitUiOpenReadOnlyVersion => 'افتح النسخة للقراءة فقط';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'استعد هذا المسار... في انتظار حالة المستودع';

  @override
  String get gitUiRestoreThisPath => 'استعادة هذا المسار...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'التاريخ $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'استعادة $arg0؟';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'استبدل مسار العمل هذا بالمراجعة $arg0. يتم الاحتفاظ بالمحتوى الموجود.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'استعادة ملف العمل';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'تاريخ الملف يتبع إعادة تسمية $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'نسب الأسطر · المحتوى المودع';

  @override
  String get gitUiBlame => 'نسب الأسطر…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 شجرة العمل';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'افتح الملف التاريخي للقراءة فقط';

  @override
  String get gitUiCompareToCurrentFile => 'قارن إلى الحالي ملفّ';

  @override
  String get gitUiCompareToParent => 'مقارنة مع الوالد...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'محتوى محرر $arg0  غير المحفوظ ليس جزءًا من هذه الشروح';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'تاريخ من $arg0';
  }

  @override
  String get gitUiBoundary => ' · الحدود';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nالسطر الأصلي $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'السطور السابقة';

  @override
  String get gitUiNextLines => 'السطور التالية';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'طلب تطبيق صريح  الوجهة $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'إضافة معرف كائن الالتزام الكامل';

  @override
  String get gitUiAddReviewedCommit => 'إضافة مراجعة التزام...';

  @override
  String get gitUiMoveEarlier => 'نقل في وقت سابق';

  @override
  String get gitUiMoveLater => 'تحرك لاحقاً';

  @override
  String get gitUiRemoveFromReviewedSequence => 'إزالة من استعراض تسلسل';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'تطبيق التغييرات دون إنشاء التزامات';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'استخدم هذا الأصل الرئيسي الصريح للدمج';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'الالتزامات الفارغة أو المطبقة بالفعل قد توقف Git لقرار تخطي أو استمرار صريح.';

  @override
  String get gitUiRevertInReviewedOrder => 'عكس في ترتيب المراجعة';

  @override
  String get gitUiCherryPickInReviewedOrder => 'Cherry-pick في ترتيب المراجعة';

  @override
  String get gitUiReturnToFiles => 'العودة إلى الملفات';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'إنشاء إيداع';

  @override
  String get gitUiBackToCommit => 'العودة إلى الالتزام';

  @override
  String get gitUiSelectAChangeToReview => 'اختر تغييراً للمراجعة';

  @override
  String get gitUiLoadingBranch => 'جارٍ تحميل الفرع...';

  @override
  String get gitUiBranchUnavailable => 'الفرع غير متوفر';

  @override
  String get gitUiUnbornHEAD => 'HEAD بلا إيداعات';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD منفصل · $revision';
  }

  @override
  String get gitUiContinueAction => 'متابعة';

  @override
  String get gitUiPick => 'اختيار';

  @override
  String get gitUiReword => 'تعديل الرسالة';

  @override
  String get gitUiEdit => 'تحرير';

  @override
  String get gitUiSquash => 'ضم الإيداعات';

  @override
  String get gitUiFixup => 'ضم دون الرسالة';

  @override
  String get gitUiDrop => 'إسقاط';

  @override
  String get gitUiAbort => 'إحباط العملية';

  @override
  String get gitUiSkip => 'تخطي';

  @override
  String get gitUiQuit => 'إنهاء العملية';

  @override
  String get gitUiSoft => 'مرن';

  @override
  String get gitUiMixed => 'مختلط';

  @override
  String get gitUiHard => 'صارم';

  @override
  String get gitUiKeep => 'حفظ';

  @override
  String get gitUiCreate => 'إنشاء';

  @override
  String get gitUiApplyStash => 'تطبيق التغييرات المحفوظة مؤقتًا';

  @override
  String get gitUiPopStash => 'تطبيق المحفوظ مؤقتًا وإزالته عند النجاح';

  @override
  String get gitUiDropStashAction => 'حذف التغييرات المحفوظة مؤقتًا';

  @override
  String get gitUiEditedResult => 'النتيجة المحررة';

  @override
  String get gitUiLeftContent => 'المحتوى الأيسر';

  @override
  String get gitUiRightContent => 'المحتوى الصحيح';

  @override
  String get gitUiDeletePath => 'احذف المسار';

  @override
  String get gitUiSubmoduleCommit => 'الالتزام بالوحدات الفرعية';

  @override
  String get gitUiPresentContent => 'المحتوى المتاح';

  @override
  String get gitUiAbsentContent => 'غائبة';

  @override
  String get gitUiBinaryContent => 'محتوى ثنائي';

  @override
  String get gitUiTooLargeContent => 'المحتوى يتجاوز حد العرض';

  @override
  String get gitUiUnavailableContent => 'محتوى غير متوفر';

  @override
  String get gitUiGitlinkContent => 'مؤشر الوحدة الفرعية';

  @override
  String get gitUiSymlinkContent => 'رابط رمزي';

  @override
  String get gitUiNoOperation => 'لا عملية';

  @override
  String get gitUiCherryPickOperation => 'انتقاء إيداع';

  @override
  String get gitUiRevertOperation => 'عكس إيداع';

  @override
  String get gitUiApplyMailboxOperation => 'تطبيق بقع';

  @override
  String get gitUiSquashOperation => 'اسكواش دمج';

  @override
  String get gitUiUnmergedOperation => 'مؤشر غير مندمج';

  @override
  String get gitUiWaitingForPromptPhase => 'في انتظار ردك';

  @override
  String get gitUiStoppedPhase => 'توقف للمراجعة';

  @override
  String get gitUiCompletedPhase => 'مكتمل';

  @override
  String get gitUiFailedPhase => 'فشل';

  @override
  String get gitUiCancelledPhase => 'أُلغي';

  @override
  String get gitUiUncertainPhase => 'النتيجة تتطلب المصالحة';

  @override
  String gitUiStageVersion(String stage) {
    return 'مرحلة الصراع $stage';
  }

  @override
  String get gitUiGitMergePreview => 'غيت دمج المعاينة';

  @override
  String get gitUiNormalizedWorking => 'شجرة العمل  Git تطبيع';

  @override
  String gitUiPercentValue(String value) {
    return '$value في المئة';
  }

  @override
  String gitUiOperationActionQuestion(String action, String operation) {
    return '$operation · $action؟';
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
  String get gitUiUtf8Bom => 'UTF-8 مع علامة ترتيب البايت (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 بدون علامة ترتيب البايت (BOM)';

  @override
  String get gitUiAddsBom =>
      'يضيف هذا التعديل علامة ترتيب بايت UTF-8 (BOM) في بداية الملف.';

  @override
  String get gitUiRemovesBom =>
      'يزيل هذا التعديل علامة ترتيب البايت UTF-8 (BOM) من بداية الملف.';

  @override
  String get gitUiNoLineTerminators => 'لا يوجد خط terminators';

  @override
  String gitUiLineEndings(String format) {
    return 'نهايات أسطر $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'نهايات خط مختلطة ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format  لا LF النهائي';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'يتغير تنسيق إنهاء السطر من $before إلى $after. يمكن لنص الحافظة استخدام نهايات سطر مختلفة من الملف الأصلي.';
  }

  @override
  String get gitUiGitFailure => 'فشلت عملية Git. مراجعة التشخيص أدناه.';

  @override
  String get gitUiAbortInline => 'إحباط العملية';

  @override
  String get gitUiSkipInline => 'تخطي';

  @override
  String get gitUiQuitInline => 'إنهاء';

  @override
  String get gitUiMergeInline => 'دمج';

  @override
  String get gitUiRebaseInline => 'إعادة تأسيس';

  @override
  String get gitUiCherryPickInline => 'انتقاء إيداع';

  @override
  String get gitUiRevertInline => 'عكس إيداع';

  @override
  String get gitUiApplyMailboxInline => 'تطبيقصندوق البريد';

  @override
  String get gitUiSquashInline => 'ضم الإيداعات';

  @override
  String get gitUiUnmergedInline => 'غير مندمجة';

  @override
  String get gitHostFetch => 'جلب';

  @override
  String get gitHostRefreshGitStatus => 'تحديث حالة Git';

  @override
  String get gitHostCommitStaged => 'الالتزام على مراحل';

  @override
  String get gitHostGitBranches => 'فروع Git';

  @override
  String get gitHostReviewPush => 'دفع الاستعراض';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'تنطبق عمليات Git على هذا المستودع بأكمله وقد تنفذ أدوات الخطافات والمرشحات والاعتمادات والتوقيعات التي تم تكوينها.';

  @override
  String get gitHostContentUnavailable => 'المحتوى غير متوفر';

  @override
  String get gitHostInitializeRepository => 'تهيئة المستودع';

  @override
  String get gitHostCloneRepository => 'استنساخ المستودع';

  @override
  String get gitHostInitializeHere => 'تهيئة هنا...';

  @override
  String get gitHostCloneRepository2 => 'استنساخ المستودع…';

  @override
  String get gitHostGitLog => 'Git سجل';

  @override
  String get gitUiAbsentPlaceholder => '(غياب)';

  @override
  String get gitUiUnborn => 'لم يولد بعد';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'السجل بعد إعادة التأسيس · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'السجل الحالي · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'الإيداع المعاد تطبيقه · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'المحتوى الوارد · $revision';
  }

  @override
  String get gitUiContentConflict => 'تضارب المحتوى';

  @override
  String get gitUiSubmoduleConflict => 'صراع الوحدات الفرعية';

  @override
  String get gitUiSymlinkConflict => 'صراع الارتباط الرمزي';

  @override
  String get gitUiAddAddConflict => 'أضيفت على كلا الجانبين';

  @override
  String get gitUiModifyDeleteConflict => 'تعديل/حذف أو إعادة تسمية/حذف';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path  $kind';
  }
}
