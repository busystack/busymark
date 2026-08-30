// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'ویرایشگر فایل‌های Markdown و پروژه‌های مستندسازی سازگار با Writerside.';

  @override
  String get aboutBusyMark => 'دربارهٔ BusyMark';

  @override
  String get aboutTagline => 'ویرایشگر Markdown و Writerside';

  @override
  String get aboutLicenseLabel => 'مجوز';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'وب‌سایت';

  @override
  String get aboutSourceCode => 'کد منبع';

  @override
  String get reportIssue => 'گزارش مشکل';

  @override
  String get feedbackCategory => 'دسته‌بندی';

  @override
  String get feedbackChooseCategory => 'یک دسته‌بندی انتخاب کنید';

  @override
  String get feedbackCategoryProblem => 'مشکل یا خطا';

  @override
  String get feedbackCategoryFeature => 'درخواست قابلیت';

  @override
  String get feedbackCategoryPrivacySecurity => 'نگرانی حریم خصوصی یا امنیتی';

  @override
  String get feedbackCategoryUsability => 'نگرانی کاربردپذیری';

  @override
  String get feedbackCategoryOther => 'سایر';

  @override
  String get feedbackSubject => 'موضوع';

  @override
  String get feedbackMessage => 'پیام کامل';

  @override
  String get feedbackReplyEmail => 'ایمیل پاسخ (اختیاری)';

  @override
  String get feedbackIncludeTechnicalDetails => 'شامل کردن جزئیات فنی';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'در صورت فعال‌سازی، فقط نسخهٔ سیستم‌عامل لینوکس و تنظیمات محلی برنامهٔ BusyMark افزوده می‌شود. هیچ گزارش رویداد، فایل، دادهٔ حساب یا اطلاعات عیب‌یابی دیگری پیوست نمی‌شود.';

  @override
  String get feedbackSubmit => 'ارسال';

  @override
  String get feedbackSubmitting => 'در حال ارسال…';

  @override
  String get feedbackCategoryRequired => 'یک دسته‌بندی انتخاب کنید.';

  @override
  String get feedbackSubjectLength => 'موضوع باید بین ۳ تا ۱۲۰ نویسه باشد.';

  @override
  String get feedbackMessageLength => 'پیام باید بین ۱۰ تا ۵۰۰۰ نویسه باشد.';

  @override
  String get feedbackReplyEmailInvalid =>
      'یک نشانی ایمیل معتبر وارد کنید یا این فیلد را خالی بگذارید.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark نتوانست متصل شود. اتصال اینترنت خود را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get feedbackTimeoutFailure =>
      'مهلت درخواست به پایان رسید. دوباره تلاش کنید.';

  @override
  String get feedbackRateLimitedFailure =>
      'گزارش‌های زیادی از این اتصال ارسال شده است. کمی صبر کنید و دوباره تلاش کنید.';

  @override
  String get feedbackRejectedFailure =>
      'سرور گزارش را رد کرد. فیلدهای فرم را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get feedbackServerFailure =>
      'سرور نتوانست گزارش را بپذیرد. بعداً دوباره تلاش کنید.';

  @override
  String feedbackSuccess(String id) {
    return 'بازخورد ارسال شد. شناسهٔ مرجع: ⁨$id⁩';
  }

  @override
  String get advanced => 'پیشرفته';

  @override
  String get addToGit => 'افزودن به Git';

  @override
  String get appearance => 'ظاهر';

  @override
  String get apply => 'اعمال';

  @override
  String get back => 'بازگشت';

  @override
  String get bottomLeft => 'پایین سمت چپ';

  @override
  String get bottomRight => 'پایین سمت راست';

  @override
  String get cancel => 'لغو';

  @override
  String get choose => 'انتخاب';

  @override
  String get chooseLocation => 'انتخاب مکان';

  @override
  String get copy => 'کپی';

  @override
  String get copyName => 'کپی نام';

  @override
  String get copyFileName => 'کپی نام فایل';

  @override
  String get copyPath => 'کپی مسیر';

  @override
  String get create => 'ایجاد';

  @override
  String get creating => 'در حال ایجاد...';

  @override
  String get cut => 'برش';

  @override
  String get promoteSection => 'ارتقای بخش';

  @override
  String get demoteSection => 'تنزل بخش';

  @override
  String get moveSectionUp => 'انتقال بخش به بالا';

  @override
  String get moveSectionDown => 'انتقال بخش به پایین';

  @override
  String get confirmDeleteSectionTitle => 'بخش حذف شود؟';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '«⁨$name⁩» و همهٔ محتوای بخش آن حذف شود؟ این کار قابل بازگشت نیست.';
  }

  @override
  String get darkTheme => 'تیره';

  @override
  String get delete => 'حذف';

  @override
  String get discard => 'دور انداختن';

  @override
  String get editor => 'ویرایشگر';

  @override
  String get file => 'فایل';

  @override
  String get fileHistory => 'تاریخچهٔ فایل';

  @override
  String get folder => 'پوشه';

  @override
  String get insert => 'درج';

  @override
  String get keyboardShortcuts => 'میانبرهای صفحه‌کلید';

  @override
  String get commandPalette => 'پالت فرمان';

  @override
  String get commandPaletteHint => 'یک فرمان وارد کنید';

  @override
  String get commandPaletteEmpty => 'هیچ فرمان منطبقی وجود ندارد';

  @override
  String get commandUnavailableInContext =>
      'این فرمان در زمینهٔ فعلی در دسترس نیست.';

  @override
  String get lightTheme => 'روشن';

  @override
  String get mainMenu => 'منوی اصلی';

  @override
  String get fullScreen => 'تمام‌صفحه';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'باز کردن';

  @override
  String get openInFiles => 'باز کردن در فایل‌ها';

  @override
  String get pathActions => 'عملیات مسیر';

  @override
  String get outline => 'ساختار سند';

  @override
  String get overwrite => 'رونویسی';

  @override
  String get paste => 'جای‌گذاری';

  @override
  String get pasteWithoutFormatting => 'جای‌گذاری بدون قالب‌بندی';

  @override
  String get reading => 'حالت مطالعه';

  @override
  String get removeFromRecent => 'حذف از موارد اخیر';

  @override
  String get recent => 'موارد اخیر';

  @override
  String get redo => 'انجام دوباره';

  @override
  String get save => 'ذخیره';

  @override
  String get search => 'جستجو';

  @override
  String get selectAll => 'انتخاب همه';

  @override
  String get settings => 'تنظیمات';

  @override
  String get source => 'متن منبع';

  @override
  String get split => 'تقسیم‌شده';

  @override
  String get systemTheme => 'سیستم';

  @override
  String get theme => 'پوسته';

  @override
  String get appLanguage => 'زبان';

  @override
  String get systemLanguage => 'سیستم';

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
  String get toggleSidebar => 'پنل کناری';

  @override
  String get topLeft => 'بالا سمت چپ';

  @override
  String get topRight => 'بالا سمت راست';

  @override
  String get undo => 'واگرد';

  @override
  String get validate => 'اعتبارسنجی';

  @override
  String get validation => 'اعتبارسنجی';

  @override
  String get viewMode => 'حالت نمایش';

  @override
  String get welcome => 'خوش آمدید';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'تصاویر';

  @override
  String get openMarkdownFile => 'باز کردن فایل Markdown';

  @override
  String get markdownFileExtensions => '.md یا .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'باز کردن پوشه یا پروژه Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'پوشهٔ Markdown یا پروژهٔ سازگار با Writerside';

  @override
  String get noOpenFile => 'فایلی باز نیست';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'حذف مورد انتخاب‌شده در فایل‌ها یا برداشتن موضوع انتخاب‌شده از فهرست مطالب';

  @override
  String get shortcutGroupGeneral => 'عمومی';

  @override
  String get shortcutNewDocument => 'ایجاد';

  @override
  String get shortcutNewDocumentDescription =>
      'ایجاد فایل Markdown یا پروژهٔ Writerside';

  @override
  String get shortcutOpenDescription =>
      'باز کردن فایل Markdown، پوشه یا پروژهٔ Writerside';

  @override
  String get shortcutSaveDescription => 'ذخیرهٔ سند فعلی';

  @override
  String get shortcutSearchDescription => 'جستجو در فضای کاری فعلی';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'نمایش مرجع میانبرهای صفحه‌کلید';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'باز کردن مرجع Markdown و HTML';

  @override
  String get shortcutSettingsDescription => 'باز کردن تنظیمات BusyMark';

  @override
  String get shortcutNextTab => 'تب بعدی';

  @override
  String get shortcutNextTabDescription => 'رفتن به تب باز بعدی';

  @override
  String get shortcutPreviousTab => 'تب قبلی';

  @override
  String get shortcutPreviousTabDescription => 'رفتن به تب باز قبلی';

  @override
  String get shortcutCloseTab => 'بستن تب';

  @override
  String get shortcutCloseTabDescription => 'بستن تب فعال';

  @override
  String get shortcutCloseAllTabs => 'بستن همهٔ تب‌ها';

  @override
  String get shortcutCloseAllTabsDescription => 'بستن همهٔ تب‌های باز';

  @override
  String get shortcutGroupTextEditing => 'ویرایش متن';

  @override
  String get shortcutSelectAllDescription =>
      'در حالت منبع، همهٔ متن را انتخاب کنید؛ در حالت ویرایشگر، برای انتخاب همهٔ بلوک‌ها دو بار فشار دهید';

  @override
  String get shortcutCutDescription => 'برش متن انتخاب‌شده';

  @override
  String get shortcutCopyDescription => 'کپی متن انتخاب‌شده';

  @override
  String get shortcutPasteDescription => 'جای‌گذاری از کلیپ‌بورد';

  @override
  String get shortcutPastePlainTextDescription =>
      'جای‌گذاری متن کلیپ‌بورد بدون قالب‌بندی';

  @override
  String get shortcutUndoDescription => 'آخرین ویرایش را واگرد کنید';

  @override
  String get shortcutRedoDescription =>
      'آخرین ویرایش واگردشده را دوباره انجام دهید';

  @override
  String get shortcutInsertIndentation => 'درج تورفتگی';

  @override
  String get shortcutInsertIndentationDescription => 'درج تورفتگی در مکان‌نما';

  @override
  String get shortcutOutdentSource => 'کاهش تورفتگی در حالت منبع';

  @override
  String get shortcutOutdentSourceDescription =>
      'حذف یک سطح تورفتگی در حالت منبع';

  @override
  String get shortcutEscape => 'بستن جستجو یا پاک کردن انتخاب بلوک‌ها';

  @override
  String get shortcutEscapeDescription =>
      'بستن جستجوی فضای کاری یا لغو انتخاب بلوک‌ها در حالت ویرایشگر';

  @override
  String get shortcutGroupFormatting => 'قالب‌بندی';

  @override
  String get shortcutBoldDescription =>
      'فعال یا غیرفعال کردن پررنگی متن انتخاب‌شده';

  @override
  String get shortcutItalicDescription =>
      'فعال یا غیرفعال کردن حالت مورب متن انتخاب‌شده';

  @override
  String get shortcutUnderlineDescription =>
      'فعال یا غیرفعال کردن زیرخط متن انتخاب‌شده';

  @override
  String get shortcutLinkDescription => 'درج یا ویرایش پیوند';

  @override
  String get shortcutInlineCodeDescription =>
      'فعال یا غیرفعال کردن کد درون‌خطی برای متن انتخاب‌شده';

  @override
  String get shortcutStrikethroughDescription =>
      'فعال یا غیرفعال کردن خط‌خوردگی متن انتخاب‌شده';

  @override
  String get shortcutGroupBlocks => 'بلوک‌ها';

  @override
  String get shortcutParagraphDescription => 'تنظیم بلوک فعلی روی پاراگراف';

  @override
  String get shortcutHeading1Description => 'تنظیم بلوک فعلی روی عنوان ۱';

  @override
  String get shortcutHeading2Description => 'تنظیم بلوک فعلی روی عنوان ۲';

  @override
  String get shortcutHeading3Description => 'تنظیم بلوک فعلی روی عنوان ۳';

  @override
  String get shortcutHeading4Description => 'تنظیم بلوک فعلی روی عنوان ۴';

  @override
  String get shortcutHeading5Description => 'تنظیم بلوک فعلی روی عنوان ۵';

  @override
  String get shortcutHeading6Description => 'تنظیم بلوک فعلی روی عنوان ۶';

  @override
  String get shortcutGroupLists => 'فهرست‌ها';

  @override
  String get numberedList => 'فهرست شماره‌دار';

  @override
  String get shortcutNumberedListDescription =>
      'فعال یا غیرفعال کردن قالب‌بندی فهرست شماره‌دار';

  @override
  String get bulletedList => 'فهرست نشانه‌دار';

  @override
  String get shortcutBulletedListDescription =>
      'فعال یا غیرفعال کردن قالب‌بندی فهرست نشانه‌دار';

  @override
  String get checklist => 'چک‌لیست';

  @override
  String get shortcutChecklistDescription =>
      'فعال یا غیرفعال کردن قالب‌بندی چک‌لیست';

  @override
  String get shortcutGroupSidebar => 'نوار کناری';

  @override
  String get sidebarViewMenu => 'نمای نوار کناری';

  @override
  String get createMarkdownFile => 'ایجاد فایل Markdown';

  @override
  String get createMarkdownFileDescription =>
      'شروع یک سند Markdown محلی و ذخیره‌نشده';

  @override
  String get createWritersideProject => 'ایجاد پروژه Writerside';

  @override
  String get createWritersideProjectDescription =>
      'شروع یک پروژه محلی سازگار با Writerside';

  @override
  String get defaultProjectName => 'مستندات';

  @override
  String get defaultInstanceName => 'راهنمای کاربر';

  @override
  String get defaultStartTopicTitle => 'شروع کار';

  @override
  String get projectName => 'نام پروژه';

  @override
  String get directoryName => 'نام پوشه';

  @override
  String get instanceName => 'نام نمونه';

  @override
  String get instanceId => 'شناسه نمونه';

  @override
  String get startTopicTitle => 'عنوان موضوع آغازین';

  @override
  String get location => 'مکان';

  @override
  String get projectNameRequired => 'نام پروژه الزامی است.';

  @override
  String get directoryNameRequired => 'نام پوشه الزامی است.';

  @override
  String get useSingleSafeDirectoryName =>
      'از یک نام پوشهٔ واحد و مجاز استفاده کنید.';

  @override
  String get useLowercaseIdentifier =>
      'از شناسه‌ای با حروف کوچک لاتین، اعداد، زیرخط یا خط‌تیره استفاده کنید.';

  @override
  String get startTopicTitleRequired => 'عنوان موضوع آغازین الزامی است.';

  @override
  String get createWritersideProjectFailed =>
      'ایجاد پروژه Writerside ناموفق بود.';

  @override
  String get settingsTitle => 'تنظیمات BusyMark';

  @override
  String get autoSave => 'ذخیرهٔ خودکار';

  @override
  String get autoSaveDescription =>
      'تغییرات فایل را پس از مکثی کوتاه به‌طور خودکار ذخیره کنید.';

  @override
  String get wordWrap => 'شکستن خودکار خطوط';

  @override
  String get editorFontSize => 'اندازهٔ قلم ویرایشگر';

  @override
  String get validateOnEdit => 'اعتبارسنجی هنگام ویرایش';

  @override
  String get clearRecentWorkspaces => 'پاک کردن فضاهای کاری اخیر';

  @override
  String get editingButtonsPosition => 'موقعیت دکمه‌های ویرایش';

  @override
  String get editingButtonsPositionDescription =>
      'محل نمایش دکمه‌های شناور ویرایش WYSIWYG را انتخاب کنید.';

  @override
  String get editingButtonsDirection => 'جهت چیدمان دکمه‌های ویرایش';

  @override
  String get editingButtonsDirectionDescription =>
      'انتخاب کنید که دکمه‌های شناور ویرایش WYSIWYG به‌صورت افقی یا عمودی چیده شوند.';

  @override
  String get horizontal => 'افقی';

  @override
  String get vertical => 'عمودی';

  @override
  String get privacy => 'حریم خصوصی';

  @override
  String get allowRemoteImages => 'بارگیری تصاویر راه دور';

  @override
  String get allowRemoteImagesDescription =>
      'اجازه دهید تصاویر پیش‌نمایش و ویرایشگر Markdown از نشانی‌های http و https بارگیری شوند.';

  @override
  String get clearRemoteImagePermissions => 'پاک کردن مجوزهای تصاویر راه دور';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'فضاهای کاری‌ای را که اجازهٔ بارگیری تصاویر راه دور داشتند، فراموش کنید.';

  @override
  String get clearGitWorkspaceTrust => 'پاک کردن فضاهای کاری مورد اعتماد Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'پیش از فعال‌کردن ویژگی‌های Git برای فضاهای کاری که قبلاً مورد اعتماد بوده‌اند، پرسیده شود.';

  @override
  String get settingsWindowSectionTitle => 'پنجره';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'باز کردن دوبارهٔ فضای کاری قبلی هنگام راه‌اندازی';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'هنگام راه‌اندازی BusyMark، فضای کاری و زبانه‌های نشست قبلی باز شوند.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'تأیید پیش از بستن با تغییرات ذخیره‌نشده';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'وقتی سندها تغییرات ذخیره‌نشده دارند، پیش از بستن BusyMark پرسیده شود.';

  @override
  String get closeUnsavedChangesTitle => 'تغییرات ذخیره‌نشده';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'این سند تغییرات ذخیره‌نشده دارد. پیش از بستن BusyMark تغییرات ذخیره شوند؟';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString سند تغییرات ذخیره‌نشده دارند. پیش از بستن BusyMark تغییرات ذخیره شوند؟',
      one:
          '۱ سند تغییرات ذخیره‌نشده دارد. پیش از بستن BusyMark تغییرات ذخیره شوند؟',
      zero: 'پیش از بستن BusyMark تغییرات ذخیره شوند؟',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'لغو';

  @override
  String get closeUnsavedChangesDiscard => 'دور انداختن';

  @override
  String get closeUnsavedChangesSave => 'ذخیره';

  @override
  String get currentFile => 'فایل فعلی';

  @override
  String get unsavedChanges => 'تغییرات ذخیره‌نشده';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'در ⁨$fileName⁩ تغییرات ذخیره‌نشده دارید. قبل از ادامه ذخیره شوند؟';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count سند دارای تغییرات ذخیره‌نشده هستند. قبل از ادامه ذخیره کنید.',
      one: '۱ سند دارای تغییرات ذخیره‌نشده است. قبل از ادامه ذخیره کنید.',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'فایل روی دیسک تغییر کرده است';

  @override
  String get fileChangedOnDiskMessage =>
      'این فایل پس از باز شدن روی دیسک تغییر کرده است. بازنویسی شود؟';

  @override
  String get untitledMarkdownFileName => 'بدون عنوان.md';

  @override
  String get unorderedList => 'فهرست بدون ترتیب';

  @override
  String get orderedList => 'فهرست شماره‌دار';

  @override
  String get taskList => 'فهرست کارها';

  @override
  String get toggleTaskChecked => 'تغییر وضعیت انجام‌شدهٔ کار';

  @override
  String get indentListItem => 'افزایش تورفتگی مورد فهرست';

  @override
  String get outdentListItem => 'کاهش تورفتگی مورد فهرست';

  @override
  String get blockquote => 'نقل‌قول بلوکی';

  @override
  String get codeBlock => 'بلوک کد';

  @override
  String get codeBlockLanguage => 'زبان بلوک کد';

  @override
  String get image => 'تصویر';

  @override
  String get video => 'ویدیو';

  @override
  String get openVideo => 'پخش ویدیو';

  @override
  String get pauseVideo => 'مکث ویدیو';

  @override
  String get videoUnavailable => 'ویدیو در دسترس نیست';

  @override
  String get videoPreview => 'پیش‌نمایش ویدیو';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'ویژگی src برای ویدیو وجود ندارد.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'منبع ویدیو پشتیبانی نمی‌شود: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'فایل ویدیو وجود ندارد: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'تصویر پیش‌نمایش ویدیو وجود ندارد: $preview';
  }

  @override
  String get inlineImage => 'تصویر درون‌خطی';

  @override
  String get table => 'جدول';

  @override
  String get htmlBlock => 'بلوک HTML';

  @override
  String get htmlContentDefault => 'محتوای HTML';

  @override
  String get shortcutHtmlBlockDescription => 'درج یا ویرایش بلوک HTML';

  @override
  String get renderedHtml => 'HTML رندرشده';

  @override
  String get editHtml => 'ویرایش HTML';

  @override
  String get htmlSource => 'منبع HTML';

  @override
  String get thematicBreak => 'جداکنندهٔ موضوعی';

  @override
  String get bold => 'پررنگ';

  @override
  String get italic => 'مورب';

  @override
  String get underline => 'زیرخط‌دار';

  @override
  String get strikethrough => 'خط‌خورده';

  @override
  String get inlineCode => 'کد درون‌خطی';

  @override
  String get link => 'پیوند';

  @override
  String get hardLineBreak => 'شکست خط اجباری';

  @override
  String get textStyle => 'سبک متن';

  @override
  String get paragraph => 'پاراگراف';

  @override
  String get heading1 => 'عنوان ۱';

  @override
  String get heading2 => 'عنوان ۲';

  @override
  String get heading3 => 'عنوان ۳';

  @override
  String get heading4 => 'عنوان ۴';

  @override
  String get heading5 => 'عنوان ۵';

  @override
  String get heading6 => 'عنوان ۶';

  @override
  String headingLevelAbbreviation(int level) {
    final intl.NumberFormat levelNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String levelString = levelNumberFormat.format(level);

    return '⁨H$levelString⁩';
  }

  @override
  String get deleteTable => 'حذف جدول';

  @override
  String tableColumnNumber(int columnNumber) {
    final intl.NumberFormat columnNumberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String columnNumberString = columnNumberNumberFormat.format(
      columnNumber,
    );

    return 'ستون $columnNumberString';
  }

  @override
  String get insertColumnLeft => 'درج ستون در سمت چپ';

  @override
  String get insertColumnRight => 'درج ستون در سمت راست';

  @override
  String get deleteColumn => 'حذف ستون';

  @override
  String get tableAlignmentUnspecified => 'تراز: مشخص‌نشده';

  @override
  String get tableAlignmentLeft => 'تراز: چپ';

  @override
  String get tableAlignmentCenter => 'تراز: وسط';

  @override
  String get tableAlignmentRight => 'تراز: راست';

  @override
  String tableRowNumber(int rowNumber) {
    final intl.NumberFormat rowNumberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String rowNumberString = rowNumberNumberFormat.format(rowNumber);

    return 'ردیف $rowNumberString';
  }

  @override
  String get insertRowAbove => 'درج ردیف در بالا';

  @override
  String get insertRowBelow => 'درج ردیف در پایین';

  @override
  String get deleteRow => 'حذف ردیف';

  @override
  String get tableHeaderHint => 'سرستون';

  @override
  String get tableCellHint => 'سلول';

  @override
  String get language => 'زبان';

  @override
  String get hideEditingButtons => 'پنهان کردن دکمه‌های ویرایش';

  @override
  String get showEditingButtons => 'نمایش دکمه‌های ویرایش';

  @override
  String get altText => 'متن جایگزین';

  @override
  String get editorPlaceholderText => 'متن';

  @override
  String get editorPlaceholderCode => 'کد';

  @override
  String get editorPlaceholderAltText => 'متن جایگزین';

  @override
  String get describeTheImage => 'تصویر را توصیف کنید';

  @override
  String get columns => 'ستون‌ها';

  @override
  String get rows => 'ردیف‌ها';

  @override
  String tableHeaderNumber(int columnNumber) {
    final intl.NumberFormat columnNumberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String columnNumberString = columnNumberNumberFormat.format(
      columnNumber,
    );

    return 'سرستون $columnNumberString';
  }

  @override
  String get tableCellDefault => 'سلول';

  @override
  String get noImageSource => 'منبع تصویر وجود ندارد';

  @override
  String get remoteImageBlocked => 'تصویر راه دور مسدود است';

  @override
  String get remoteImageBlockedTooltip =>
      'انتخاب کنید BusyMark اجازهٔ بارگیری تصاویر راه دور داشته باشد یا نه.';

  @override
  String get remoteImagesBlockedTitle => 'تصاویر راه دور مسدود شده‌اند';

  @override
  String get remoteImagesBlockedMessage =>
      'این سند به تصاویری در اینترنت ارجاع می‌دهد. بارگیری آن‌ها ممکن است اطلاعات شبکه را برای میزبان تصویر آشکار کند.';

  @override
  String get loadRemoteImagesForWorkspace => 'بارگیری برای این فضای کاری';

  @override
  String get alwaysLoadRemoteImages => 'همیشه تصاویر راه دور بارگیری شوند';

  @override
  String get hideSidebar => 'پنهان کردن پنل کناری';

  @override
  String get showSidebar => 'نمایش پنل کناری';

  @override
  String get showPreview => 'نمایش پیش‌نمایش';

  @override
  String get hidePreview => 'پنهان کردن پیش‌نمایش';

  @override
  String get workspaceKindUnsavedMarkdown => 'فایل Markdown ذخیره‌نشده';

  @override
  String get workspaceKindSingleMarkdown => 'فایل Markdown منفرد';

  @override
  String get workspaceKindMarkdownFolder => 'پوشه Markdown';

  @override
  String get workspaceKindWritersideModule => 'ماژول Writerside';

  @override
  String get problems => 'مشکلات';

  @override
  String diagnosticCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString پیام تشخیصی',
      one: '۱ پیام تشخیصی',
      zero: 'هیچ پیام تشخیصی وجود ندارد',
    );
    return '$_temp0';
  }

  @override
  String get files => 'فایل‌ها';

  @override
  String get toc => 'فهرست مطالب';

  @override
  String get tocActions => 'عملیات فهرست مطالب';

  @override
  String get markdownUnsaved => 'Markdown — ذخیره‌نشده';

  @override
  String workspaceDetail(String kind, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString فایل',
      one: '۱ فایل',
    );
    return '$kind — $_temp0';
  }

  @override
  String get noFiles => 'فایلی وجود ندارد';

  @override
  String get newFile => 'فایل جدید';

  @override
  String get noWritersideToc => 'فهرست مطالب Writerside وجود ندارد';

  @override
  String get tocSection => 'بخش فهرست مطالب';

  @override
  String get newTopic => 'موضوع جدید';

  @override
  String get newChildTopic => 'موضوع فرزند جدید';

  @override
  String get newSiblingTopic => 'موضوع هم‌سطح جدید';

  @override
  String get renameTopicFile => 'تغییر نام فایل موضوع';

  @override
  String get topicPlacement => 'جایگاه در فهرست مطالب';

  @override
  String get tocRoot => 'در ریشهٔ فهرست مطالب';

  @override
  String get afterSelectedTopic => 'پس از موضوع انتخاب‌شده';

  @override
  String get insideSelectedTopic => 'داخل موضوع انتخاب‌شده';

  @override
  String get pasteAfterTopic => 'جای‌گذاری پس از آن';

  @override
  String get pasteAsChildTopic => 'جای‌گذاری به‌عنوان موضوع فرزند';

  @override
  String get removeFromToc => 'حذف از فهرست مطالب';

  @override
  String get confirmRemoveFromTocTitle => 'از فهرست مطالب حذف شود؟';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '⁨$name⁩ از این فهرست مطالب حذف شود؟ فایل موضوع حفظ خواهد شد.';
  }

  @override
  String get confirmDeleteTopicTitle => 'فایل موضوع حذف شود؟';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '⁨$name⁩ حذف و از همهٔ فهرست‌های مطالب برداشته شود؟ این کار قابل بازگشت نیست.';
  }

  @override
  String get safeDeleteTopicFile => 'حذف ایمن فایل موضوع…';

  @override
  String get removeTocElement => 'حذف عنصر فهرست مطالب';

  @override
  String get reviewUsages => 'مرور موارد استفاده';

  @override
  String get deleteTopicFile => 'حذف فایل موضوع';

  @override
  String get removeAction => 'حذف';

  @override
  String topicRemovalSummary(String topic) {
    return '«⁨$topic⁩» را از نمونهٔ انتخاب‌شده حذف کنید. فایل موضوع نگه داشته می‌شود.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '«⁨$topic⁩» را حذف کنید و ارجاع‌های آن را در سراسر این پروژهٔ Writerside به‌طور ایمن به‌روزرسانی کنید.';
  }

  @override
  String childTopicsPromoted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString موضوع فرزند یک سطح بالاتر می‌روند.',
      one: '۱ موضوع فرزند یک سطح بالاتر می‌رود.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'این موضوع به‌عنوان صفحهٔ آغاز یک نمونه استفاده می‌شود. موارد استفاده را مرور و پیش از ادامه صفحهٔ آغاز دیگری تعیین کنید.';

  @override
  String topicUsagesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'موارد استفاده ($countString)';
  }

  @override
  String get noBreakingTopicUsages => 'هیچ ارجاعی که دچار مشکل شود پیدا نشد.';

  @override
  String get topicUsagesFound =>
      'BusyMark ارجاع‌های زیر را به این موضوع پیدا کرد.';

  @override
  String get topicUsageTocElements => 'عناصر فهرست مطالب';

  @override
  String get topicUsageStartPages => 'صفحه‌های آغاز';

  @override
  String get topicUsageTopicLinks => 'پیوندهای موضوع';

  @override
  String get topicUsageIncludes => 'درج‌ها';

  @override
  String usageCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مورد استفاده',
      one: '۱ مورد استفاده',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'گزینه‌های بازآرایی';

  @override
  String get updateUsagesAutomatically => 'به‌روزرسانی خودکار موارد استفاده';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'ارجاع‌های فهرست مطالب و درج‌ها حذف و متن پیوندها حفظ می‌شود.';

  @override
  String get manualUsageUpdatesRequired =>
      'برخی موارد استفاده پیش از این بازآرایی به تغییر دستی نیاز دارند.';

  @override
  String get setRedirectTo => 'تنظیم تغییر مسیر به';

  @override
  String get noRedirectDescription =>
      'صفحهٔ منتشرشدهٔ قدیمی تغییر مسیر داده نشود.';

  @override
  String get redirectTarget => 'مقصد تغییر مسیر';

  @override
  String get remainingUsagesBlockRemoval =>
      'پیش از ادامه موارد استفادهٔ باقی‌مانده را مرور و به‌روزرسانی کنید، یا در صورت امکان به‌روزرسانی خودکار را فعال کنید.';

  @override
  String usagesOfTopic(String topic) {
    return 'موارد استفادهٔ ⁨$topic⁩';
  }

  @override
  String get noUsagesFound => 'هیچ مورد استفاده‌ای پیدا نشد';

  @override
  String get outsideSelectedInstance => 'بیرون از نمونهٔ انتخاب‌شده';

  @override
  String get doRefactor => 'انجام بازآرایی';

  @override
  String get orphanTopicTitle => 'فایل موضوع دیگر استفاده نمی‌شود';

  @override
  String get keepTopicFile => 'نگه داشتن فایل موضوع';

  @override
  String orphanTopicMessage(String topic) {
    return '«⁨$topic⁩» دیگر در هیچ جای این پروژهٔ Writerside استفاده نمی‌شود. فایل را حذف کنید یا برای استفاده در نمونه‌ای دیگر نگه دارید.';
  }

  @override
  String get defaultNewTopicTitle => 'موضوع جدید';

  @override
  String get topicTitle => 'عنوان موضوع';

  @override
  String get fileName => 'نام فایل';

  @override
  String get topicTitleRequired => 'عنوان موضوع الزامی است.';

  @override
  String get fileNameRequired => 'نام فایل الزامی است.';

  @override
  String get rename => 'تغییر نام';

  @override
  String get confirmDeleteFileTitle => 'فایل حذف شود؟';

  @override
  String get confirmDeleteFolderTitle => 'پوشه حذف شود؟';

  @override
  String confirmDeleteFileMessage(String name) {
    return '⁨$name⁩ حذف شود؟ این کار قابل بازگشت نیست.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '⁨$name⁩ و همهٔ فایل‌های داخل آن حذف شوند؟ این کار قابل بازگشت نیست.';
  }

  @override
  String get useSingleSafeFileName =>
      'از یک نام فایل واحد و مجاز استفاده کنید.';

  @override
  String useExpectedExtension(String extension) {
    return 'از پسوند ⁨$extension⁩ برای قالب انتخاب‌شده استفاده کنید.';
  }

  @override
  String get useIdentifierCharacters =>
      'پیش از پسوند فقط از حروف لاتین، اعداد، زیرخط یا خط‌تیره استفاده کنید.';

  @override
  String get topicIdAlreadyExists => 'شناسه موضوع از قبل وجود دارد.';

  @override
  String get createWritersideTopicFailed =>
      'ایجاد موضوع Writerside ناموفق بود.';

  @override
  String get noOutline => 'ساختار سندی وجود ندارد';

  @override
  String expandKind(String kind) {
    return 'گسترش $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'جمع کردن $kind';
  }

  @override
  String get foldKindSection => 'بخش';

  @override
  String get foldKindList => 'فهرست';

  @override
  String get foldKindQuote => 'نقل‌قول';

  @override
  String get foldKindTag => 'برچسب';

  @override
  String get sourceSearchPreviousMatch => 'تطابق قبلی';

  @override
  String get sourceSearchNextMatch => 'تطابق بعدی';

  @override
  String get sourceSearchCaseSensitive => 'حساس به بزرگی و کوچکی حروف';

  @override
  String get sourceSearchWholeWord => 'تمام کلمه';

  @override
  String get sourceSearchRegex => 'عبارت منظم';

  @override
  String get sourceSearchReplacement => 'جایگزینی با';

  @override
  String get sourceSearchReplaceCurrent => 'جایگزینی تطابق فعلی';

  @override
  String get sourceSearchReplaceAndFindNext => 'جایگزینی و یافتن بعدی';

  @override
  String get sourceSearchReplaceAll => 'جایگزینی همه';

  @override
  String get workspaceReplace => 'جایگزینی در فضای کاری';

  @override
  String get reviewReplacements => 'بازبینی جایگزینی‌ها';

  @override
  String get applyReplacements => 'اعمال جایگزینی‌ها';

  @override
  String get skippedFiles => 'فایل‌های نادیده‌گرفته‌شده';

  @override
  String get workspaceReplaceDirtyBuffer => 'محتوای ذخیره‌نشدهٔ ویرایشگر';

  @override
  String get workspaceReplaceDiskContent => 'محتوای ذخیره‌شده روی دیسک';

  @override
  String selectFileMatches(int count) {
    return 'انتخاب هر $count مورد';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$matches مورد در $files فایل جایگزین شد؛ $skipped مورد نادیده گرفته شد.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '⁨$encoding⁩ · ⁨$lineEnding⁩ · خط جدید پایانی';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '⁨$encoding⁩ · ⁨$lineEnding⁩ · بدون خط جدید پایانی';
  }

  @override
  String get normalizeLineEndings => 'یکسان‌سازی پایان خط‌ها';

  @override
  String get mixedLineEndingsSavePrompt =>
      'این سند پایان خط‌های ترکیبی دارد. یک قالب انتخاب کنید.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return 'فایل ⁨$fileName⁩ پایان خط‌های ترکیبی دارد. پیش از جایگزینی قالب را انتخاب کنید.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'یک فایل بیش‌ازحد بزرگ نادیده گرفته شد.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'فایلی که خوانده نمی‌شد نادیده گرفته شد.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'فایلی با UTF-8 نامعتبر نادیده گرفته شد.';

  @override
  String get workspaceReplaceIssueTruncated => 'پیش‌نمایش جایگزینی کوتاه شد.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'فایلی که پس از پیش‌نمایش تغییر کرده بود نادیده گرفته شد.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'بافر ویرایشگری که پس از پیش‌نمایش تغییر کرده بود نادیده گرفته شد.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'پیش از جایگزینی، یکسان‌سازی LF یا CRLF را انتخاب کنید.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'بازگردانی متوقف شد، زیرا فایل هم‌زمان تغییر کرد. ممکن است برخی جایگزینی‌ها باقی مانده باشند؛ محتوای جابه‌جا‌شده در مسیر زیر حفظ شد.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'هیچ جایگزینی اعمال نشد، زیرا مجموعهٔ بازبینی‌شده را نمی‌شد با ایمنی ذخیره کرد.';

  @override
  String externalChangesTitle(String fileName) {
    return 'تغییرات بیرونی — ⁨$fileName⁩';
  }

  @override
  String get externalFileDeleted => 'این فایل از روی دیسک حذف شد.';

  @override
  String get externalFileChanged =>
      'هنگامی که تغییرات ذخیره‌نشده داشتید، این فایل روی دیسک تغییر کرد.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'محتوای ذخیره‌نشدهٔ $fileName بازیابی شده است. آن را بررسی کنید و سپس ذخیره، ذخیره با نام یا رد کنید.';
  }

  @override
  String get compare => 'مقایسه';

  @override
  String get reloadFromDisk => 'بارگیری دوباره از دیسک';

  @override
  String get keepMine => 'نگه‌داشتن نسخهٔ من';

  @override
  String get saveAs => 'ذخیره با نام';

  @override
  String get sourceSearchInvalidRegex => 'عبارت منظم نامعتبر است';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'فایل بزرگ: برجسته‌سازی و جمع‌کردن موقتاً متوقف شده‌اند';

  @override
  String get nothingToRead => 'محتوایی برای مطالعه وجود ندارد';

  @override
  String get admonition => 'کادر هشدار';

  @override
  String get quote => 'نقل‌قول';

  @override
  String get note => 'یادداشت';

  @override
  String get tip => 'نکته';

  @override
  String get warning => 'هشدار';

  @override
  String get tabs => 'تب‌ها';

  @override
  String get tab => 'تب';

  @override
  String get procedure => 'رویه';

  @override
  String get step => 'مرحله';

  @override
  String get topic => 'موضوع';

  @override
  String get chapter => 'فصل';

  @override
  String couldNotOpenTarget(String target) {
    return 'باز کردن ⁨$target⁩ ممکن نشد';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'مقصد پیوند یافت نشد: ⁨$targetPath⁩';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'این نوع فایل را نمی‌توان در ویرایشگر باز کرد';

  @override
  String anchorNotFound(String anchor) {
    return 'لنگر یافت نشد: ⁨$anchor⁩';
  }

  @override
  String get noProblemsFound => 'مشکلی پیدا نشد';

  @override
  String get noResults => 'نتیجه‌ای وجود ندارد';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    final intl.NumberFormat lineNumberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lineNumberString = lineNumberNumberFormat.format(lineNumber);

    return '⁨$relativePath⁩ — خط ⁨$lineNumberString⁩';
  }

  @override
  String get untitledResult => 'نتیجهٔ بدون عنوان';

  @override
  String get documentKindMarkdownFile => 'فایل Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'موضوع Markdown در Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'موضوع XML در Writerside';

  @override
  String get documentKindWritersideTree => 'درخت Writerside';

  @override
  String get documentKindConfigurationFile => 'فایل پیکربندی';

  @override
  String get documentKindVariablesFile => 'فایل متغیرها';

  @override
  String get documentKindCategoriesFile => 'فایل دسته‌بندی‌ها';

  @override
  String get documentKindResourceFile => 'فایل منبع';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'باز کردن ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'ایجاد پروژه Writerside ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'ایجاد موضوع Writerside ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'باز کردن فایل ممکن نشد: ⁨$error⁩';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'محل ذخیرهٔ این فایل Markdown را انتخاب کنید.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'ذخیره‌سازی مسدود شد: فایل روی دیسک تغییر کرده است.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'ذخیره ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'عملیات فایل ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'اعتبارسنجی ناموفق بود: ⁨$error⁩';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count سند ذخیره‌نشده بازیابی شدند. هر کدام را قبل از ذخیره یا حذف بازبینی کنید.',
      one: 'یک سند ذخیره‌نشده بازیابی شد. قبل از ذخیره یا حذف آن بازبینی کنید.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count رکورد بازیابی آسیب‌دیده نتوانستیم بازیابی کنیم. رکوردهای بازیابی معتبر همچنان در دسترس هستند.',
      one:
          'یک رکورد بازیابی آسیب‌دیده را نتوانستیم بازیابی کنیم. فایل بازیابی اولیه برای بررسی حفظ شده است.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'مسیر وجود ندارد: ⁨$path⁩';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'پوشه مقصد از قبل وجود دارد و خالی نیست: ⁨$path⁩';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'مسیر مقصد از قبل وجود دارد، اما پوشه نیست: ⁨$path⁩';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'فایل تولیدشده از قبل وجود دارد: ⁨$path⁩';
  }

  @override
  String get errorParentDirectoryRequired => 'پوشه والد الزامی است.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'پوشه والد وجود ندارد: ⁨$path⁩';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'پوشه وجود ندارد: ⁨$path⁩';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'مسیر از قبل وجود دارد: ⁨$path⁩';
  }

  @override
  String get errorFileNameRequired => 'نام فایل لازم است.';

  @override
  String get errorFileNameUnsafe => 'نام فایل باید یک بخش مسیر امن باشد.';

  @override
  String get errorFileOperationInvalidTarget =>
      'نمی‌توان یک پوشه را به داخل خودش منتقل کرد.';

  @override
  String get errorFileOperationOutsideRoot =>
      'عملیات فایل باید داخل فضای کاری بماند.';

  @override
  String get errorFileOperationRoot =>
      'ریشهٔ فضای کاری را نمی‌توان از درخت فایل تغییر داد.';

  @override
  String get errorProjectNameRequired => 'نام پروژه الزامی است.';

  @override
  String get errorDirectoryNameRequired => 'نام پوشه الزامی است.';

  @override
  String get errorDirectoryNameUnsafe =>
      'نام پوشه باید یک بخش مسیر واحد و مجاز باشد.';

  @override
  String get errorInstanceIdInvalid =>
      'شناسهٔ نمونه باید با یک حرف کوچک لاتین شروع شود و فقط شامل حروف کوچک لاتین، اعداد، زیرخط و خط‌تیره باشد.';

  @override
  String get errorTopicFileInvalid =>
      'نام فایل موضوع باید نام یک فایل Markdown بدون جداکنندهٔ مسیر باشد.';

  @override
  String get errorTopicTitleRequired => 'عنوان موضوع الزامی است.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'ریشه ماژول Writerside وجود ندارد: ⁨$path⁩';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'برای ایجاد موضوع، باید یک ماژول Writerside باز باشد.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'ماژول Writerside درخت نمونه ندارد.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'فایل درخت Writerside وجود ندارد: ⁨$path⁩';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'شناسه موضوع «⁨$topicId⁩» از قبل در این ماژول راهنما وجود دارد.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'فایل موضوع از قبل وجود دارد: ⁨$path⁩';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'موضوع مرجع در درخت انتخاب‌شده وجود ندارد: ⁨$topic⁩';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'مدخل انتخاب‌شدهٔ فهرست مطالب دیگر وجود ندارد.';

  @override
  String get errorWritersideTocInvalidMove =>
      'مدخل فهرست مطالب را نمی‌توان به داخل خودش یا یکی از فرزندانش منتقل کرد.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'موضوع شروع ⁨$topic⁩ را نمی‌توان حذف کرد. ابتدا صفحهٔ شروع دیگری را انتخاب کنید.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'برای فایل‌های موضوع Writerside از حذف ایمن استفاده کنید.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'بررسی موارد استفاده از موضوع کامل نشد. هیچ فایلی تغییر نکرد.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'برخی موارد استفاده از موضوع هنوز نیاز به رسیدگی دارند. پیش از ادامه آن‌ها را بازبینی کنید.';

  @override
  String get errorWritersideRedirectInvalid =>
      'مقصد تغییر مسیر انتخاب‌شده دیگر معتبر نیست. دوباره آن را انتخاب کنید.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'حذف موضوع به‌طور کامل بازگردانده نشد. پیش از ادامه این مسیرها را بررسی کنید: ⁨$paths⁩';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'ریشهٔ موضوع‌ها باید یک پوشهٔ نسبی مجاز باشد.';

  @override
  String get errorTopicFileNameUnsafe =>
      'نام فایل موضوع باید یک بخش مسیر واحد و مجاز باشد.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'پسوند فایل موضوع باید با قالب انتخاب‌شده (⁨$extension⁩) مطابقت داشته باشد.';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'نام فایل موضوع باید فقط شامل حروف لاتین، اعداد، زیرخط و خط‌تیره باشد.';

  @override
  String errorUnknown(String code) {
    return 'خطای ناشناخته: ⁨$code⁩';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'خواندن فرادادهٔ فایل ممکن نشد: ⁨$error⁩';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'فضای کاری بزرگ شناسایی شد. برای حفظ پاسخ‌گویی برنامه، بعضی فایل‌ها نادیده گرفته شدند.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'بررسی ورودی فضای کاری ممکن نشد: ⁨$error⁩';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'فایل از حد تجزیهٔ خودکار نسخهٔ بتا بزرگ‌تر است.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'خواندن فایل Markdown ممکن نشد: ⁨$error⁩';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'بلوک ویژگی‌های عنوان Writerside نامعتبر است.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'شناسهٔ عنوان «⁨$id⁩» تکراری است.';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'عنوان‌های H1 سطح‌بالای اضافی به‌عنوان فصل در نظر گرفته می‌شوند.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'موضوع Markdown در Writerside عنوان H1 یا عنوان فرانت‌متر ندارد.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'موضوع XML عنوان ندارد.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'موضوع «⁨$fileName⁩» عنوان ندارد.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'فرانت‌متر بسته نشده است.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'عنصر HTML ناامن است.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'هدف پیوند وجود ندارد: ⁨$targetPath⁩';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'لنگر «⁨$anchor⁩» وجود ندارد.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'تصویر «⁨$destination⁩» متن جایگزین ندارد.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'تصویر وجود ندارد: ⁨$destination⁩';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML نامعتبر است: ⁨$message⁩';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'ریشه writerside.cfg باید <ihp> باشد.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'در اعلان snippets، ویژگی src وجود ندارد.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'در اعلان instance-groups، ویژگی src وجود ندارد.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'حالت keymaps پشتیبانی نمی‌شود: ⁨$mode⁩';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'در اعلان نمونه، ویژگی src وجود ندارد.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg هیچ نمونه‌ای را ثبت نکرده است.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'ریشهٔ .tree باید <instance-profile> باشد.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'نمایهٔ نمونه ویژگی id ندارد.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'نام بدون پسوند فایل درخت با شناسهٔ نمونه «⁨$id⁩» مطابقت ندارد.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'نمونهٔ غیرکتابخانه‌ای ویژگی start-page ندارد.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'صفحه شروع «⁨$startPage⁩» وجود ندارد.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'موضوع «⁨$topic⁩» بیش از یک بار در فهرست مطالب این نمونه ظاهر شده است.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'اعلان متغیر باید نام و مقدار داشته باشد.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'متغیر «⁨$name⁩» بیش از یک بار تعریف شده است.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'دسته‌بندی ویژگی id ندارد.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'دسته‌بندی «⁨$id⁩» بیش از یک بار تعریف شده است.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'ترتیب دسته‌بندی «⁨$order⁩» بیش از یک بار تعریف شده است.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'ریشه .topic باید <topic> باشد.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'موضوع XML شناسهٔ ریشه ندارد.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'شناسه ریشه موضوع XML «⁨$id⁩» باید با نام فایل «⁨$expectedId⁩» مطابقت داشته باشد.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'شناسهٔ عنصر «⁨$elementId⁩» بیش از یک بار ظاهر شده است.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> ویژگی href ندارد.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'حالت Writerside به writerside.cfg نیاز دارد.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'پوشهٔ پیکربندی ساختِ تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'پوشهٔ مشخصات API تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'پوشهٔ snippets تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'فایل متغیرهای تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'فایل دسته‌بندی‌های تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'فایل گروه‌های نمونهٔ تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'درخت نمونهٔ ثبت‌شده «⁨$source⁩» وجود ندارد.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'خواندن فایل موضوع ناموفق بود: ⁨$error⁩';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'پوشه پیش‌فرض موضوع‌ها وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'پوشه موضوع‌های تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'پوشه تصاویر تنظیم‌شده وجود ندارد: ⁨$relativePath⁩';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'شناسه عنصر «⁨$id⁩» بیش از یک بار ظاهر شده است.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'فهرست مطالب به موضوع ناموجود «⁨$topic⁩» ارجاع می‌دهد.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'href خارجی «⁨$href⁩» نامعتبر است.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'متغیر \"⁨%$name%⁩\" تعریف نشده است.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'پیوند موضوع «⁨$destination⁩» قابل حل نیست.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'لنگر «⁨$anchor⁩» در «⁨$targetName⁩» وجود ندارد.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> دارای from نیست.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'منبع include «⁨$from⁩» وجود ندارد.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'عنصر include «⁨$elementId⁩» در «⁨$from⁩» وجود ندارد.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'دسته‌بندی seealso «⁨$ref⁩» تعریف نشده است.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'ارجاع موضوع «⁨$reference⁩» مبهم است.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'پیام تشخیصی ناشناخته: ⁨$code⁩';
  }

  @override
  String get close => 'بستن';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'تفاوت‌های Git';

  @override
  String get gitShowDiff => 'نمایش تفاوت‌ها';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'قدیمی ⁨$oldRange⁩ ← جدید ⁨$newRange⁩';
  }

  @override
  String get gitDiffNoLines => 'بدون خط';

  @override
  String get gitUnavailableTitle => 'Git در دسترس نیست';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Git را نصب کنید یا BusyMark را برای استفاده از یک برنامهٔ اجرایی Git در دسترس پیکربندی کنید. ⁨$reason⁩',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'برای استفاده از Git به این فضای کاری اعتماد می‌کنید؟';

  @override
  String get gitTrustRequiredMessage =>
      'مخزن‌های Git می‌توانند از طریق هوک‌ها، فیلترها و پیکربندی‌های دیگر برنامه اجرا کنند. پیش از اینکه BusyMark داده‌های مخزن را بخواند یا عملیات Git را فعال کند، به این فضای کاری اعتماد کنید.';

  @override
  String get gitTrustWorkspace => 'اعتماد به فضای کاری';

  @override
  String get gitNotRepositoryTitle => 'مخزن Git نیست';

  @override
  String get gitNotRepositoryMessage => 'این فضای کاری درون یک مخزن Git نیست.';

  @override
  String get gitInitializeRepository => 'راه‌اندازی مخزن';

  @override
  String get gitDetachedHead => 'HEAD جداشده';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'HEAD در ⁨$commit⁩ جدا شده است';
  }

  @override
  String get gitNoUpstream => 'شاخهٔ بالادست وجود ندارد';

  @override
  String gitAheadCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString کامیت ارسال‌نشده',
      one: 'یک کامیت ارسال‌نشده',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString کامیت برای دریافت',
      one: 'یک کامیت برای دریافت',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'بدون تغییر';

  @override
  String get gitConflicts => 'تداخل‌ها';

  @override
  String get gitChanges => 'تغییرات';

  @override
  String get gitStaged => 'مرحله‌بندی‌شده';

  @override
  String get gitUnstaged => 'مرحله‌بندی‌نشده';

  @override
  String get gitHistory => 'تاریخچه';

  @override
  String get gitBranches => 'شاخه‌ها';

  @override
  String get gitActions => 'عملیات Git';

  @override
  String get gitPull => 'کشیدن';

  @override
  String get gitFetch => 'واکشی';

  @override
  String get gitPush => 'ارسال';

  @override
  String get gitCommit => 'کامیت';

  @override
  String get gitSelectForCommit => 'مرحله‌بندی فایل';

  @override
  String get gitRemoveFromCommit => 'خارج کردن فایل از مرحله‌بندی';

  @override
  String get gitDiscard => 'دور انداختن';

  @override
  String get gitOpenFile => 'باز کردن فایل';

  @override
  String get gitMarkResolved => 'علامت‌گذاری به‌عنوان حل‌شده';

  @override
  String get gitUntracked => 'فایل‌های رهگیری‌نشده';

  @override
  String get gitCommitMessage => 'پیام کامیت';

  @override
  String get gitCommitSelectedFiles => 'فایل‌های انتخاب‌شده';

  @override
  String get gitCommitNoSelectedFiles =>
      'پیش از کامیت، دست‌کم یک فایل را مرحله‌بندی کنید.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فایل مرحله‌بندی‌شده',
      one: '۱ فایل مرحله‌بندی‌شده',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'خارج از فضای کاری';

  @override
  String get gitCommitMessageRequired => 'پیام کامیت را وارد کنید.';

  @override
  String get gitCreateBranch => 'ایجاد شاخه';

  @override
  String get gitNewBranch => 'شاخهٔ جدید';

  @override
  String get gitBranchName => 'نام شاخه';

  @override
  String get gitSwitchBranch => 'تغییر';

  @override
  String get gitNoChanges => 'تغییری وجود ندارد';

  @override
  String get gitNoHistory => 'تاریخچه‌ای وجود ندارد';

  @override
  String get gitNoBranches => 'شاخه‌ای وجود ندارد';

  @override
  String get gitNoDiff => 'تفاوتی برای نمایش نیست';

  @override
  String get gitBinaryFile =>
      'فایل دودویی است. BusyMark وصله‌های دودویی را نمایش نمی‌دهد.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'فایل دودویی ($size بایت). BusyMark وصله‌های دودویی را نمایش نمی‌دهد.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'تغییرات ذخیره‌نشدهٔ ویرایشگر تا زمان ذخیره‌شدن در نظر گرفته نمی‌شوند.';

  @override
  String get gitConfirmDiscardTitle => 'تغییرات Git دور انداخته شوند؟';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'تمام تغییرات مرحله‌بندی‌شده و مرحله‌نشده فایل‌های رهگیری‌شدهٔ انتخاب‌شده به HEAD بازگردانده می‌شود.',
      one:
          'تمام تغییرات مرحله‌بندی‌شده و مرحله‌نشده فایل رهگیری‌شدهٔ انتخاب‌شده به HEAD بازگردانده می‌شود.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فایل‌های رهگیری‌نشدهٔ انتخابی حذف خواهند شد.',
      one: 'فایل رهگیری‌نشدهٔ انتخابی حذف خواهد شد.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'فایل‌های انتخابی بر اساس وضعیت Git آن‌ها بازیابی یا حذف خواهند شد.',
      one: 'فایل انتخابی بر اساس وضعیت Git آن بازیابی یا حذف خواهد شد.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'به ⁨$branch⁩ بروید؟';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'پس از تغییر شاخه توسط Git، BusyMark فضای کاری را دوباره از دیسک بارگیری می‌کند.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'شاخهٔ بالادست تنظیم شود؟';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'این شاخه بالادست ندارد. اگر دقیقاً یک مخزن راه دور پیکربندی شده باشد، BusyMark می‌تواند ⁨$branch⁩ را ارسال و آن را به‌عنوان بالادست تنظیم کند.';
  }

  @override
  String get gitProjectHistory => 'سابقه پروژه';

  @override
  String get gitFileHistory => 'سابقه فایل';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'تاریخچهٔ فایل به یک فایل Markdown باز نیاز دارد.';

  @override
  String get gitLoadMore => 'بارگیری بیشتر';

  @override
  String get gitChangesInCommit => 'تغییرات این ثبت';

  @override
  String get gitCompareWithCurrent => 'مقایسه با نسخهٔ فعلی';

  @override
  String get gitRestoreVersion => 'بازیابی این نسخه';

  @override
  String get gitConfirmRestoreTitle => 'این نسخهٔ فایل بازیابی شود؟';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark فایل فعلی در درخت کاری را با نسخهٔ انتخاب‌شده از ثبت جایگزین می‌کند. فایل بازیابی‌شده مرحله‌بندی‌نشده باقی می‌ماند.';

  @override
  String get gitCommitActions => 'عملیات ثبت';

  @override
  String get gitResetCurrentBranchToHere => 'بازنشانی شاخهٔ فعلی به اینجا…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '⁨$branch⁩ روی ⁨$commit⁩ بازنشانی شود؟';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'این کار شاخهٔ ⁨$branch⁩ را به ثبت ⁨$commit⁩ منتقل می‌کند. نحوهٔ به‌روزرسانی فهرست و درخت کاری توسط Git را انتخاب کنید.';
  }

  @override
  String get gitReset => 'بازنشانی';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'فقط شاخه را جابه‌جا کنید. فهرست و درخت کاری بدون تغییر می‌مانند؛ تفاوت‌ها با ثبت انتخاب‌شده همچنان مرحله‌بندی‌شده خواهند بود.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'شاخه را جابه‌جا و فهرست را بازنشانی کنید. درخت کاری بدون تغییر می‌ماند و تفاوت‌ها مرحله‌بندی‌نشده خواهند بود.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'شاخه را جابه‌جا و فهرست و درخت کاری را بازنشانی کنید. تغییرات فایل‌های رهگیری‌شده کنار گذاشته می‌شوند؛ فایل‌های رهگیری‌نشدهٔ مانع ممکن است حذف شوند.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'شاخه را جابه‌جا و فایل‌های رهگیری‌شده را بازنشانی کنید، اما تغییرات محلی را نگه دارید. اگر این تغییرات با بازنشانی تداخل داشته باشند، Git عملیات را متوقف می‌کند.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    final intl.NumberFormat additionsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String additionsString = additionsNumberFormat.format(additions);
    final intl.NumberFormat deletionsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String deletionsString = deletionsNumberFormat.format(deletions);

    return '⁨+$additionsString -$deletionsString⁩';
  }

  @override
  String get fileActions => 'عملیات فایل';

  @override
  String get actions => 'عملیات';

  @override
  String get gitStatusAdded => 'افزوده‌شده';

  @override
  String get gitStatusDeleted => 'حذف‌شده';

  @override
  String get gitStatusRenamed => 'تغییرنام‌یافته';

  @override
  String get gitStatusCopied => 'کپی‌شده';

  @override
  String get gitStatusUntracked => 'رهگیری‌نشده';

  @override
  String get gitStatusConflicted => 'دارای تداخل';

  @override
  String get gitStatusIgnored => 'نادیده‌گرفته‌شده';

  @override
  String get gitStatusTypeChanged => 'نوع تغییر کرده';

  @override
  String get gitStatusModified => 'تغییریافته';

  @override
  String get gitStatusUnknown => 'ناشناخته';

  @override
  String get gitErrorUnavailable => 'Git در دسترس نیست.';

  @override
  String get gitErrorNotRepository => 'این فضای کاری یک مخزن Git نیست.';

  @override
  String get gitErrorUnsafePath => 'BusyMark یک مسیر ناامن Git را مسدود کرد.';

  @override
  String get gitErrorInvalidBranchName => 'یک نام معتبر برای شاخه وارد کنید.';

  @override
  String get gitErrorNoRemote => 'هیچ مخزن راه دور Git پیکربندی نشده است.';

  @override
  String get gitErrorNoUpstream => 'هیچ شاخهٔ بالادستی پیکربندی نشده است.';

  @override
  String get gitErrorMultipleRemotes =>
      'چند مخزن راه دور پیکربندی شده است. یک بالادست را خارج از این نسخهٔ BusyMark انتخاب کنید.';

  @override
  String get gitErrorDirtyWorkspace =>
      'پیش از تغییر شاخه، تغییرات ویرایشگر BusyMark را ذخیره کنید یا دور بیندازید.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'پیش از بازنشانی شاخهٔ فعلی، تغییرات ویرایشگر BusyMark را ذخیره یا کنار بگذارید.';

  @override
  String get gitErrorRestoreStagedFile =>
      'پیش از بازیابی نسخهٔ پیشین، فایل را از حالت مرحله‌بندی خارج کنید.';

  @override
  String get gitErrorResetDetachedHead => 'پیش از بازنشانی، به یک شاخه بروید.';

  @override
  String get gitErrorDiverged =>
      'شاخه واگرا شده است. مشکل را با ادغام یا بازپایه‌گذاری در خارج از این نسخهٔ BusyMark حل کنید.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git پیش از ثبت تغییر به نام و نشانی ایمیل نویسنده نیاز دارد.';

  @override
  String get gitAuthorIdentityTitle => 'هویت نویسندهٔ Git';

  @override
  String get gitAuthorIdentityMessage =>
      'هویتی را وارد کنید که Git باید در ثبت‌ها ذخیره کند. BusyMark آن را ذخیره می‌کند و این ثبت را دوباره انجام می‌دهد.';

  @override
  String get gitAuthorName => 'نام';

  @override
  String get gitAuthorEmail => 'ایمیل';

  @override
  String get gitAuthorIdentityGlobal => 'استفاده برای همهٔ مخزن‌ها';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'در نصب Snap، این تنظیم برای مخزن‌های بازشده در BusyMark اعمال می‌شود.';

  @override
  String get gitSaveIdentityAndCommit => 'ذخیره و ثبت تغییر';

  @override
  String get gitErrorAuthentication => 'احراز هویت Git ناموفق بود.';

  @override
  String get gitErrorNetwork => 'عملیات شبکهٔ Git ناموفق بود.';

  @override
  String get gitErrorConflict => 'Git تداخل‌های حل‌نشده گزارش کرد.';

  @override
  String get gitErrorCommandFailed => 'فرمان Git ناموفق بود.';

  @override
  String get markdownAndHtml => 'Markdown و HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'بلوک‌های Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'ساختارهای بلوکی پشتیبانی‌شده در متن Markdown و پیش‌نمایش.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown درون‌خطی';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'قالب‌بندی درون پاراگراف‌ها، موارد فهرست و سلول‌های جدول.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'بلوک‌های HTML خام';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'تگ‌های بلوکی HTML امن که با ویجت‌های پیش‌نمایش BusyMark نمایش داده می‌شوند.';

  @override
  String get markdownHtmlRawHtmlInline => 'تگ‌های HTML درون‌خطی';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'تگ‌های HTML درون‌خطی امن بدون نمایش خود تگ‌ها رندر می‌شوند.';

  @override
  String get markdownHtmlSafety => 'قوانین امنیتی';

  @override
  String get markdownHtmlSafetyDescription =>
      'HTML خام پیش از پیش‌نمایش تحلیل و پاک‌سازی می‌شود.';

  @override
  String get markdownHtmlHeadings => 'عنوان‌ها';

  @override
  String get markdownHtmlParagraphs => 'پاراگراف‌ها';

  @override
  String get markdownHtmlLists => 'فهرست‌ها';

  @override
  String get markdownHtmlHtmlContainers => 'کانتینرها';

  @override
  String get markdownHtmlHtmlTextBlocks => 'بلوک‌های متن';

  @override
  String get markdownHtmlHtmlFigures => 'شکل‌ها و تصاویر';

  @override
  String get markdownHtmlHtmlPreformatted => 'کد پیش‌قالب‌بندی‌شده';

  @override
  String get markdownHtmlHtmlDisclosure => 'بلوک‌های بازشونده';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'فهرست‌های توصیفی';

  @override
  String get markdownHtmlHtmlFormattingTags => 'تگ‌های قالب‌بندی';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'تگ‌های کد درون‌خطی';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'تگ‌های متنی معنایی';

  @override
  String get markdownHtmlSanitizedPreview => 'پیش‌نمایش پاک‌سازی‌شده';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'HTML مجاز به بلوک‌های پیش‌نمایش BusyMark تبدیل می‌شود، نه اینکه در مرورگر رندر شود.';

  @override
  String get markdownHtmlSourcePreserved => 'منبع حفظ می‌شود';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'HTML خام ویرایش‌نشده دقیقاً به‌عنوان متن منبع ذخیره می‌شود.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown داخل HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'نشانه‌های Markdown داخل HTML خام به‌صورت متن واقعی نمایش داده می‌شوند.';

  @override
  String get markdownHtmlBlockedContent => 'محتوای فعال مسدود است';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'اسکریپت‌ها، استایل‌ها، فریم‌ها، فرم‌ها، SVG، MathML، رویدادها و ویژگی‌های ناامن مسدود می‌شوند.';

  @override
  String get markdownHtmlSafeUrls => 'فقط URLهای امن';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'پیوندها http، https، mailto، tel، URLهای نسبی و قطعه‌ها را می‌پذیرند؛ طرح‌های ناامن مسدود می‌شوند.';

  @override
  String get exportAsPdf => 'خروجی به‌صورت PDF';

  @override
  String get pdfExportDescription =>
      'چیدمان صفحه را برای یک PDF حرفه‌ای و مستقل انتخاب کنید.';

  @override
  String get pdfRemoteImagesNote =>
      'تصاویر راه‌دور هنگام خروجی دانلود نمی‌شوند. تصاویر محلی در صورت دسترس بودن افزوده می‌شوند.';

  @override
  String get pdfPageSize => 'اندازه صفحه';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter (نامه)';

  @override
  String get pdfOrientation => 'جهت';

  @override
  String get pdfPortrait => 'عمودی';

  @override
  String get pdfLandscape => 'افقی';

  @override
  String get pdfMargins => 'حاشیه‌ها';

  @override
  String get pdfMarginNarrow => 'باریک';

  @override
  String get pdfMarginNormal => 'عادی';

  @override
  String get pdfMarginWide => 'پهن';

  @override
  String get pdfIncludePageNumbers => 'افزودن شماره صفحه';

  @override
  String get export => 'خروجی';

  @override
  String get exportingPdf => 'در حال تهیه PDF…';

  @override
  String get fileTypePdf => 'سند PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName صادر شد.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count هشدار',
      one: '1 هشدار',
    );
    return '$fileName با $_temp0 صادر شد.';
  }

  @override
  String get pdfExportUnavailable =>
      'مؤلفه خروجی PDF موجود نیست. BusyMark را دوباره نصب و تلاش کنید.';

  @override
  String get pdfExportTimedOut => 'خروجی PDF بیش از حد طول کشید و متوقف شد.';

  @override
  String get pdfExportFailed => 'BusyMark نتوانست این سند را به PDF تبدیل کند.';

  @override
  String get visualizationRendering => 'در حال رندر…';

  @override
  String get visualizationStale => 'نمایش آخرین رندر معتبر';

  @override
  String get visualizationShowSource => 'نمایش منبع';

  @override
  String get visualizationShowRender => 'نمایش رندر';

  @override
  String get visualizationFitWidth => 'تطبیق با عرض';

  @override
  String get visualizationSaveImage => 'ذخیره تصویر';

  @override
  String get visualizationCopyImage => 'کپی تصویر';

  @override
  String get visualizationImageCopied => 'تصویر کپی شد';

  @override
  String get visualizationOpenApiReference => 'باز کردن مرجع API';

  @override
  String get visualizationValid => 'معتبر';

  @override
  String get visualizationInvalid => 'نامعتبر';

  @override
  String get visualizationServers => 'سرورها';

  @override
  String get visualizationPaths => 'مسیرها';

  @override
  String get visualizationOperations => 'عملیات‌ها';

  @override
  String get visualizationTags => 'برچسب‌ها';

  @override
  String get visualizationNoOperations => 'عملیات منطبقی وجود ندارد';

  @override
  String get visualizationSearchOperations => 'جستجوی عملیات';

  @override
  String get visualizationRenderFailed => 'این تصویرسازی رندر نشد.';

  @override
  String get visualizationRetry => 'تلاش دوباره';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName ذخیره شد';
  }

  @override
  String get shortcutExportPdfDescription =>
      'سند فعال یا ماژول Writerside را به PDF صادر کنید.';

  @override
  String get instances => 'نمونه‌ها';

  @override
  String get newInstance => 'نمونهٔ جدید';

  @override
  String get newTocLibrary => 'کتابخانهٔ جدید فهرست مطالب';

  @override
  String get editInstance => 'ویرایش نمونه';

  @override
  String get openTocFile => 'باز کردن فایل فهرست مطالب';

  @override
  String get createInstance => 'ایجاد نمونه';

  @override
  String get createTocLibrary => 'ایجاد کتابخانهٔ فهرست مطالب';

  @override
  String get instanceContent => 'محتوا';

  @override
  String get instanceContentSource => 'ایجاد از';

  @override
  String get emptyInstance => 'نمونهٔ خالی';

  @override
  String get markdownFiles => 'فایل‌های محلی Markdown';

  @override
  String get chooseMarkdownFolder => 'انتخاب پوشهٔ Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'پوشه‌ای حاوی فایل‌های Markdown انتخاب کنید.';

  @override
  String get instanceAppearance => 'ظاهر';

  @override
  String get instanceColor => 'رنگ نماد';

  @override
  String get instanceVersion => 'نسخه';

  @override
  String instanceVersionInherited(String version) {
    return 'وقتی این فیلد خالی باشد، نسخهٔ پروژه ⁨$version⁩ است.';
  }

  @override
  String get instanceWebPath => 'مسیر وب';

  @override
  String get instanceStatus => 'وضعیت';

  @override
  String get instanceStatusRelease => 'انتشار نهایی';

  @override
  String get instanceStatusEap => 'دسترسی زودهنگام';

  @override
  String get instanceStatusDeprecated => 'منسوخ';

  @override
  String get allowSearchEngineIndexing =>
      'اجازهٔ نمایه‌سازی به موتورهای جست‌وجو';

  @override
  String get allowSearchEngineIndexingDescription =>
      'به موتورهای جست‌وجوی خارجی اجازه دهید این خروجی را نمایه کنند.';

  @override
  String get offlineArtifact => 'بستهٔ آفلاین';

  @override
  String get offlineArtifactDescription =>
      'منابع را بسته‌بندی کنید تا مستندات ساخته‌شده خودکفا باشند.';

  @override
  String get instanceOutputSettings => 'تنظیمات خروجی';

  @override
  String get markdownImportSource => 'منبع Markdown';

  @override
  String get markdownImportFiles => 'فایل‌های Markdown';

  @override
  String get selectNone => 'لغو انتخاب همه';

  @override
  String markdownFilesFound(int count) {
    return '⁨$count⁩ فایل Markdown پیدا شد';
  }

  @override
  String get noMarkdownFilesFound => 'هیچ فایل Markdown در این پوشه پیدا نشد.';

  @override
  String get copyReferencedMedia => 'کپی رسانه‌های ارجاع‌شده';

  @override
  String get copyReferencedMediaDescription =>
      'تصویرها و ویدیوهای محلی ارجاع‌شده در فایل‌های انتخابی را با حفظ مسیرهای نسبی کپی کنید.';

  @override
  String get instanceIdRenameWarningTitle => 'شناسهٔ نمونه تغییر نام کند؟';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark نام فایل ⁨.tree⁩ را تغییر می‌دهد و ارجاع‌های پروژهٔ Writerside را از «⁨$oldId⁩» به «⁨$newId⁩» به‌روزرسانی می‌کند. اسکریپت‌های انتشار تغییر نمی‌کنند و باید جداگانه به‌روزرسانی شوند.';
  }

  @override
  String get renameAndUpdateReferences => 'تغییر نام و به‌روزرسانی ارجاع‌ها';

  @override
  String get tocLibraryDescription =>
      'کتابخانهٔ فهرست مطالب بخش‌های قابل استفادهٔ مجدد را نگه می‌دارد و خروجی مستقلی تولید نمی‌کند.';

  @override
  String get defaultTocLibraryName => 'فهرست مطالب مشترک';

  @override
  String get instanceColorAutomatic => 'خودکار';

  @override
  String get instanceColorBlue => 'آبی';

  @override
  String get instanceColorGreen => 'سبز';

  @override
  String get instanceColorOrange => 'نارنجی';

  @override
  String get instanceColorPurple => 'بنفش';

  @override
  String get instanceColorRed => 'قرمز';

  @override
  String get instanceColorTeal => 'سبزآبی';

  @override
  String get instanceColorYellow => 'زرد';

  @override
  String get errorWritersideInstanceNameRequired => 'نام نمونه را وارد کنید.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'نمونه‌ای با شناسهٔ «⁨$id⁩» از قبل وجود دارد.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'درخت نمونه از قبل وجود دارد: ⁨$path⁩';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'پوشهٔ منبع Markdown وجود ندارد: ⁨$path⁩';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'دست‌کم یک فایل Markdown برای وارد کردن انتخاب کنید.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'این یک فایل Markdown خواندنی درون منبع انتخاب‌شده نیست: ⁨$path⁩';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'وارد کردن، فایل موجود پروژه را بازنویسی می‌کند: ⁨$path⁩';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'فایل‌های نمونه روی دیسک تغییر کرده‌اند. آن‌ها را بررسی و دوباره تلاش کنید.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark نتوانست تغییر نمونه را کاملاً برگرداند. پیش از ادامه این فایل‌ها را بررسی کنید: ⁨$paths⁩';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'کتابخانهٔ فهرست مطالب نمی‌تواند موضوع‌های Markdown را وارد کند.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'مسیر وب باید یک خط باشد.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'پیکربندی نمونهٔ Writerside نامعتبر است. عیب‌یابی‌های آن را اصلاح و دوباره تلاش کنید.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark نتوانست تغییرات نمونه را با ایمنی آماده کند.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'وضعیت نمونهٔ «⁨$status⁩» ناشناخته است. از ⁨release⁩، ⁨eap⁩ یا ⁨deprecated⁩ استفاده کنید.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'شناسهٔ نمونهٔ «⁨$id⁩» در بیش از یک فایل درخت استفاده شده است.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'عنصر ریشهٔ ⁨buildprofiles.xml⁩ باید ⁨<buildprofiles>⁩ باشد.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'مقدار ⁨$name⁩ یعنی «⁨$value⁩» باید ⁨true⁩ یا ⁨false⁩ باشد.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'عنصر ⁨<build-profile>⁩ باید شناسهٔ نمونه را مشخص کند.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'عنصر ⁨<include>⁩ درخت باید هر دو مقدار ⁨from⁩ و ⁨element-id⁩ را مشخص کند.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'عنصر ⁨<snippet>⁩ درخت باید ⁨id⁩ را مشخص کند.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'ارجاع میان‌نمونه‌ای فهرست مطالب باید هر دو مقدار ⁨ref⁩ و ⁨in⁩ را مشخص کند.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'یک عنصر فهرست مطالب نمی‌تواند بیش از یک موضوع، ارجاع، پیوند یا تغییرمسیر را هدف قرار دهد.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'شناسهٔ عنصر درخت «⁨$id⁩» بیش از یک بار تعریف شده است.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'عنصر ریشهٔ فایل گروه‌های نمونه باید ⁨<instance-groups>⁩ باشد.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'گروه نمونه باید یک شناسهٔ غیرخالی و فهرست نمونه‌ها را مشخص کند.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'شناسهٔ گروه نمونهٔ «⁨$id⁩» بیش از یک بار تعریف شده است.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'گنجاندن فهرست مطالب «⁨$source#$id⁩» به پیمانهٔ خارجی «⁨$origin⁩» تعلق دارد و در این فضای کاری قابل گسترش نیست.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'عنصر درخت «⁨$id⁩» در درخت ثبت‌شدهٔ «⁨$source⁩» وجود ندارد.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'گنجاندن درخت «⁨$source#$id⁩» یک چرخه ایجاد می‌کند.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'شرط نمونه به گروه ناشناختهٔ «⁨@$group⁩» ارجاع می‌دهد.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'ارجاع میان‌نمونه‌ای، نمونهٔ ناشناختهٔ «⁨$instance⁩» را هدف قرار می‌دهد.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'موضوع «⁨$topic⁩» در نمونهٔ ارجاع‌شدهٔ «⁨$instance⁩» نیست.';
  }

  @override
  String get download => 'بارگیری';

  @override
  String get exportWritersideAsPdf => 'صدور Writerside به‌صورت PDF';

  @override
  String get writersidePdfContent => 'محتوای صدور';

  @override
  String get writersidePdfPage => 'صفحه';

  @override
  String get exportingWritersidePdf => 'در حال صدور PDF از Writerside…';

  @override
  String get ai => 'هوش مصنوعی';

  @override
  String get aiLocalOllama => 'Ollama محلی';

  @override
  String get aiDisabled => 'غیرفعال';

  @override
  String get aiExplicitEditingDescription =>
      'ویرایش با هوش مصنوعی فقط با اقدام صریح آغاز می‌شود. BusyMark تنها زمینهٔ نمایش‌داده‌شده را برای ارائه‌دهندهٔ انتخابی می‌فرستد و هیچ پیشنهادی را بدون بازبینی اعمال نمی‌کند.';

  @override
  String get aiProvider => 'ارائه‌دهندهٔ هوش مصنوعی';

  @override
  String get aiDefaultProvider => 'ارائه‌دهندهٔ پیش‌فرض';

  @override
  String get aiConfigureProvider => 'پیکربندی ارائه‌دهنده';

  @override
  String get aiChooseProvider => 'انتخاب ارائه‌دهندهٔ هوش مصنوعی';

  @override
  String get aiOllamaEndpoint => 'نقطهٔ پایانی Ollama';

  @override
  String get aiOllamaModel => 'مدل Ollama';

  @override
  String get aiTestConnection => 'آزمایش اتصال';

  @override
  String get aiTestingConnection => 'در حال آزمایش…';

  @override
  String aiConnectionReady(int count) {
    return 'متصل شد. ⁨$count⁩ مدل نصب‌شده پیدا شد.';
  }

  @override
  String get aiNoModels => 'هیچ مدلی انتخاب نشده است.';

  @override
  String get aiConnectionFailed =>
      'BusyMark نتوانست تولید متن با هوش مصنوعی را تأیید کند.';

  @override
  String get aiConfigureFirst =>
      'ابتدا یک ارائه‌دهندهٔ هوش مصنوعی را فعال و مدلی را در تنظیمات ← هوش مصنوعی تأیید کنید.';

  @override
  String get aiEditWithAi => 'ویرایش با هوش مصنوعی';

  @override
  String get aiRefineWithAi => 'بهبود با هوش مصنوعی';

  @override
  String get aiInstruction => 'دستور';

  @override
  String get aiChangeTarget => 'چه چیزی می‌تواند تغییر کند';

  @override
  String get aiSharedContext => 'زمینهٔ اشتراکی با هوش مصنوعی';

  @override
  String get aiTargetSelection => 'محتوای انتخاب‌شده';

  @override
  String get aiTargetInsertAfterBlock => 'درج پس از بلوک فعلی';

  @override
  String get aiTargetCurrentBlock => 'بلوک فعلی';

  @override
  String get aiTargetCurrentSection => 'بخش فعلی';

  @override
  String get aiTargetCompleteDocument => 'کل سند';

  @override
  String get aiContextNone => 'بدون زمینه از سند';

  @override
  String get aiContextSelection => 'محتوای انتخاب‌شده';

  @override
  String get aiContextCurrentBlock => 'بلوک فعلی';

  @override
  String get aiContextCurrentSection => 'بخش فعلی';

  @override
  String get aiContextCompleteDocument => 'کل سند';

  @override
  String get aiGenerating => 'در حال تولید پیشنهاد…';

  @override
  String get aiProposal => 'پیشنهاد هوش مصنوعی';

  @override
  String get aiGenerateProposal => 'ایجاد پیشنهاد';

  @override
  String aiContextDisclosure(int count) {
    return 'ارائه‌دهندهٔ انتخابی ⁨$count⁩ نویسه از زمینهٔ نمایش‌داده‌شده دریافت می‌کند.';
  }

  @override
  String get aiOriginal => 'متن اصلی';

  @override
  String get aiSuggested => 'متن پیشنهادی';

  @override
  String get aiApplyProposal => 'اعمال پیشنهاد';

  @override
  String aiTokenUsage(int input, int output) {
    return '⁨$input⁩ توکن ورودی · ⁨$output⁩ توکن خروجی';
  }

  @override
  String get aiStaleProposal =>
      'سند هنگام تولید این پیشنهاد تغییر کرد. کنش را دوباره اجرا کنید.';

  @override
  String get gitAiStagedChangesChanged =>
      'تغییرات مرحله‌بندی‌شده هنگام تولید این پیام کامیت تغییر کرد. کنش را دوباره اجرا کنید.';

  @override
  String get aiViewContext => 'نمایش بافت ارسال‌شده';

  @override
  String get aiReviewExactContent => 'بازبینی محتوای دقیق';

  @override
  String get aiContentToChange => 'محتوایی که تغییر می‌کند';

  @override
  String get aiContentSentToAi => 'محتوای ارسال‌شده به هوش مصنوعی';

  @override
  String get aiApiKey => 'کلید API';

  @override
  String get aiApiKeyStoredHint =>
      'یک کلید در مخزن اعتبارنامهٔ سیستم ذخیره شده است';

  @override
  String get aiApiKeyEnterHint => 'کلید API ارائه‌دهنده را وارد کنید';

  @override
  String get aiReplaceApiKey => 'جایگزینی کلید API';

  @override
  String get aiSaveApiKey => 'ذخیرهٔ امن کلید API';

  @override
  String get aiRemoveApiKey => 'حذف کلید API ذخیره‌شده';

  @override
  String get aiCredentialSaved =>
      'کلید API در مخزن اعتبارنامهٔ سیستم ذخیره شد.';

  @override
  String get aiCredentialRemoved => 'کلید API ذخیره‌شده حذف شد.';

  @override
  String get aiModelRouting => 'انتخاب مدل';

  @override
  String get aiAutomaticRouting => 'خودکار بر اساس کار';

  @override
  String get aiFixedModelRouting => 'استفاده از مدل انتخابی';

  @override
  String get aiPreferredModel => 'مدل ترجیحی';

  @override
  String get aiModel => 'مدل';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '⁨$requests⁩ درخواست · ⁨$input⁩ توکن ورودی · ⁨$output⁩ توکن خروجی';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'محتوا برای ⁨$provider⁩ ارسال شود؟';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'فعال‌کردن ⁨$provider⁩';
  }

  @override
  String get aiCloudConsentMessage =>
      'فقط محتوای نمایش‌داده‌شده در هر کادر بازبینی هوش مصنوعی ارسال می‌شود. درخواست‌ها بدون حالت هستند، پیشنهادها نیاز به بازبینی دارند و کلید API در مخزن اعتبارنامهٔ سیستم Linux ذخیره می‌شود.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'ابتدا اشتراک‌گذاری داده با ⁨$provider⁩ را در تنظیمات ← هوش مصنوعی تأیید کنید.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'تولید با ⁨$model⁩ تأیید شد. ⁨$count⁩ مدل سازگار در دسترس است.';
  }

  @override
  String get aiColdStartObserved => 'راه‌اندازی سرد مدل محلی شناسایی شد.';

  @override
  String get aiNoCompatibleModels => 'هیچ مدل سازگار تولید متن در دسترس نیست.';

  @override
  String get aiEnableProvider =>
      'ابتدا یک ارائه‌دهندهٔ هوش مصنوعی را فعال کنید.';

  @override
  String get aiDraftCommitMessage => 'تهیهٔ پیش‌نویس پیام ثبت';

  @override
  String get aiDrafting => 'در حال تهیهٔ پیش‌نویس…';

  @override
  String get aiDraftWithAi => 'تهیهٔ پیش‌نویس با هوش مصنوعی';

  @override
  String get generateOrUpdateMarkdownToc => 'ایجاد/به‌روزرسانی فهرست مطالب';

  @override
  String get markdownTocTitle => 'فهرست مطالب';

  @override
  String markdownTocUpdated(int count) {
    return 'فهرست مطالب با ⁨$count⁩ مدخل به‌روزرسانی شد.';
  }

  @override
  String get markdownTocNoHeadings =>
      'پیش از ایجاد فهرست مطالب دست‌کم یک عنوان بخش اضافه کنید.';

  @override
  String get markdownTocMalformedMarkers =>
      'نشانگرهای فهرست مطالب BusyMark وجود ندارند، تکراری‌اند یا ترتیب نادرستی دارند.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'عنوان سطح ⁨$level⁩ پس از سطح ⁨$previousLevel⁩ آمده است؛ تودرتویی بخش‌ها را بازبینی کنید.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'متن پیوند خالی است؛ نام دسترس‌پذیری وارد کنید که هدف آن را توضیح دهد.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'بررسی کنید که آیا متن پیوند «⁨$text⁩» هدف آن را در زمینه توضیح می‌دهد.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'سرستون‌های جدول باید ستون‌های خود را مشخص کنند؛ هر سرستون خالی را تکمیل کنید.';

  @override
  String get mathRenderFailed => 'عبارت ریاضی قابل نمایش نبود.';

  @override
  String get inlineMath => 'ریاضی درون‌خطی';

  @override
  String get displayMath => 'ریاضی نمایشی';
}
