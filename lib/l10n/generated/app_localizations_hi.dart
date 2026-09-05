// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Markdown फ़ाइलों और Writerside-संगत दस्तावेज़ीकरण परियोजनाओं का संपादक।';

  @override
  String get aboutBusyMark => 'BusyMark के बारे में';

  @override
  String get aboutTagline => 'Markdown और Writerside संपादक';

  @override
  String get aboutLicenseLabel => 'लाइसेंस';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'वेबसाइट';

  @override
  String get aboutSourceCode => 'स्रोत कोड';

  @override
  String get reportIssue => 'समस्या की रिपोर्ट करें';

  @override
  String get feedbackCategory => 'श्रेणी';

  @override
  String get feedbackChooseCategory => 'श्रेणी चुनें';

  @override
  String get feedbackCategoryProblem => 'समस्या या बग';

  @override
  String get feedbackCategoryFeature => 'सुविधा अनुरोध';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'गोपनीयता या सुरक्षा संबंधी चिंता';

  @override
  String get feedbackCategoryUsability => 'उपयोगिता संबंधी चिंता';

  @override
  String get feedbackCategoryOther => 'अन्य';

  @override
  String get feedbackSubject => 'विषय';

  @override
  String get feedbackMessage => 'विस्तृत संदेश';

  @override
  String get feedbackReplyEmail => 'उत्तर ईमेल (वैकल्पिक)';

  @override
  String get feedbackIncludeTechnicalDetails => 'तकनीकी विवरण शामिल करें';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'सक्षम होने पर केवल Linux ऑपरेटिंग सिस्टम का संस्करण और BusyMark ऐप की भाषा व क्षेत्र सेटिंग जोड़ी जाती है। कोई लॉग, फ़ाइल, खाता डेटा या अन्य निदान जानकारी संलग्न नहीं की जाती।';

  @override
  String get feedbackSubmit => 'भेजें';

  @override
  String get feedbackSubmitting => 'भेजा जा रहा है…';

  @override
  String get feedbackCategoryRequired => 'श्रेणी चुनें।';

  @override
  String get feedbackSubjectLength => 'विषय 3 से 120 वर्णों के बीच होना चाहिए।';

  @override
  String get feedbackMessageLength =>
      'संदेश 10 से 5000 वर्णों के बीच होना चाहिए।';

  @override
  String get feedbackReplyEmailInvalid =>
      'मान्य ईमेल पता दर्ज करें या यह फ़ील्ड खाली छोड़ें।';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark कनेक्ट नहीं हो सका। अपना इंटरनेट कनेक्शन जाँचें और फिर प्रयास करें।';

  @override
  String get feedbackTimeoutFailure =>
      'अनुरोध का समय समाप्त हो गया। फिर प्रयास करें।';

  @override
  String get feedbackRateLimitedFailure =>
      'इस कनेक्शन से बहुत अधिक रिपोर्ट भेजी गई हैं। प्रतीक्षा करें और फिर प्रयास करें।';

  @override
  String get feedbackRejectedFailure =>
      'सर्वर ने रिपोर्ट अस्वीकार कर दी। फ़ॉर्म फ़ील्ड जाँचें और फिर प्रयास करें।';

  @override
  String get feedbackServerFailure =>
      'सर्वर रिपोर्ट स्वीकार नहीं कर सका। बाद में फिर प्रयास करें।';

  @override
  String feedbackSuccess(String id) {
    return 'प्रतिक्रिया भेजी गई। संदर्भ आईडी: $id';
  }

  @override
  String get advanced => 'उन्नत';

  @override
  String get addToGit => 'Git में जोड़ें';

  @override
  String get appearance => 'दिखावट';

  @override
  String get apply => 'लागू करें';

  @override
  String get back => 'वापस';

  @override
  String get bottomLeft => 'नीचे बाएँ';

  @override
  String get bottomRight => 'नीचे दाएँ';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get choose => 'चुनें';

  @override
  String get chooseLocation => 'स्थान चुनें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copyName => 'नाम कॉपी करें';

  @override
  String get copyFileName => 'फ़ाइल नाम कॉपी करें';

  @override
  String get copyPath => 'पथ कॉपी करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get creating => 'बनाया जा रहा है...';

  @override
  String get cut => 'कट करें';

  @override
  String get promoteSection => 'अनुभाग को ऊपर करें';

  @override
  String get demoteSection => 'अनुभाग को नीचे करें';

  @override
  String get moveSectionUp => 'अनुभाग ऊपर ले जाएँ';

  @override
  String get moveSectionDown => 'अनुभाग नीचे ले जाएँ';

  @override
  String get confirmDeleteSectionTitle => 'अनुभाग हटाएँ?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '$name और उसके अनुभाग की सारी सामग्री हटाएँ? इसे वापस नहीं किया जा सकता।';
  }

  @override
  String get darkTheme => 'डार्क';

  @override
  String get delete => 'हटाएँ';

  @override
  String get discard => 'त्यागें';

  @override
  String get editor => 'संपादक';

  @override
  String get file => 'फ़ाइल';

  @override
  String get fileHistory => 'फ़ाइल इतिहास';

  @override
  String get folder => 'फ़ोल्डर';

  @override
  String get insert => 'सम्मिलित करें';

  @override
  String get keyboardShortcuts => 'कीबोर्ड शॉर्टकट';

  @override
  String get commandPalette => 'कमांड पैलेट';

  @override
  String get commandPaletteHint => 'कमांड लिखें';

  @override
  String get commandPaletteEmpty => 'कोई मेल खाता कमांड नहीं';

  @override
  String get commandUnavailableInContext =>
      'यह आदेश वर्तमान संदर्भ में उपलब्ध नहीं है।';

  @override
  String get lightTheme => 'लाइट';

  @override
  String get mainMenu => 'मुख्य मेन्यू';

  @override
  String get fullScreen => 'पूर्ण स्क्रीन';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'खोलें';

  @override
  String get openInFiles => 'Files में खोलें';

  @override
  String get pathActions => 'पथ संबंधी कार्रवाइयाँ';

  @override
  String get outline => 'रूपरेखा';

  @override
  String get overwrite => 'ओवरराइट करें';

  @override
  String get paste => 'पेस्ट करें';

  @override
  String get pasteWithoutFormatting => 'बिना फ़ॉर्मेटिंग पेस्ट करें';

  @override
  String get reading => 'पठन दृश्य';

  @override
  String get removeFromRecent => 'हालिया से हटाएँ';

  @override
  String get recent => 'हालिया';

  @override
  String get redo => 'फिर से करें';

  @override
  String get save => 'सहेजें';

  @override
  String get search => 'खोजें';

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get source => 'स्रोत';

  @override
  String get split => 'विभाजित';

  @override
  String get systemTheme => 'सिस्टम';

  @override
  String get theme => 'थीम';

  @override
  String get appLanguage => 'भाषा';

  @override
  String get systemLanguage => 'सिस्टम';

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
  String get toggleSidebar => 'साइडबार पैनल';

  @override
  String get topLeft => 'ऊपर बाएँ';

  @override
  String get topRight => 'ऊपर दाएँ';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get validate => 'सत्यापित करें';

  @override
  String get validation => 'सत्यापन';

  @override
  String get viewMode => 'दृश्य मोड';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'छवियाँ';

  @override
  String get openMarkdownFile => 'Markdown फ़ाइल खोलें';

  @override
  String get markdownFileExtensions => '.md या .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'फ़ोल्डर या Writerside प्रोजेक्ट खोलें';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown फ़ोल्डर या Writerside-संगत प्रोजेक्ट';

  @override
  String get noOpenFile => 'कोई फ़ाइल खुली नहीं है';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'फ़ाइलों में चुना गया आइटम मिटाएँ या विषय-सूची से चुना गया विषय हटाएँ';

  @override
  String get shortcutGroupGeneral => 'सामान्य';

  @override
  String get shortcutNewDocument => 'बनाएँ';

  @override
  String get shortcutNewDocumentDescription =>
      'Markdown फ़ाइल या Writerside प्रोजेक्ट बनाएँ';

  @override
  String get shortcutOpenDescription =>
      'Markdown फ़ाइल, फ़ोल्डर या Writerside प्रोजेक्ट खोलें';

  @override
  String get shortcutSaveDescription => 'मौजूदा दस्तावेज़ सहेजें';

  @override
  String get shortcutSearchDescription => 'मौजूदा कार्यस्थान में खोजें';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'यह कीबोर्ड शॉर्टकट संदर्भ दिखाएँ';

  @override
  String get shortcutSyntaxReferenceDescription => 'सिंटैक्स संदर्भ खोलें';

  @override
  String get shortcutSettingsDescription => 'BusyMark सेटिंग्स खोलें';

  @override
  String get shortcutNextTab => 'अगला टैब';

  @override
  String get shortcutNextTabDescription => 'अगले खुले टैब पर जाएँ';

  @override
  String get shortcutPreviousTab => 'पिछला टैब';

  @override
  String get shortcutPreviousTabDescription => 'पिछले खुले टैब पर जाएँ';

  @override
  String get shortcutCloseTab => 'टैब बंद करें';

  @override
  String get shortcutCloseTabDescription => 'सक्रिय टैब बंद करें';

  @override
  String get shortcutCloseAllTabs => 'सभी टैब बंद करें';

  @override
  String get shortcutCloseAllTabsDescription => 'सभी खुले टैब बंद करें';

  @override
  String get shortcutGroupTextEditing => 'टेक्स्ट संपादन';

  @override
  String get shortcutSelectAllDescription =>
      'स्रोत मोड में पूरा पाठ चुनें; संपादक मोड में सभी ब्लॉक चुनने के लिए दो बार दबाएँ';

  @override
  String get shortcutCutDescription => 'चयनित टेक्स्ट कट करें';

  @override
  String get shortcutCopyDescription => 'चयनित टेक्स्ट कॉपी करें';

  @override
  String get shortcutPasteDescription => 'क्लिपबोर्ड से चिपकाएँ';

  @override
  String get shortcutPastePlainTextDescription =>
      'क्लिपबोर्ड टेक्स्ट को बिना फ़ॉर्मेटिंग के चिपकाएँ';

  @override
  String get shortcutUndoDescription => 'अंतिम संपादन पूर्ववत करें';

  @override
  String get shortcutRedoDescription => 'अंतिम पूर्ववत संपादन फिर से करें';

  @override
  String get shortcutInsertIndentation => 'इंडेंट डालें';

  @override
  String get shortcutInsertIndentationDescription => 'कर्सर पर इंडेंट डालें';

  @override
  String get shortcutOutdentSource => 'स्रोत का इंडेंट घटाएँ';

  @override
  String get shortcutOutdentSourceDescription =>
      'स्रोत मोड में इंडेंट का एक स्तर हटाएँ';

  @override
  String get shortcutEscape => 'खोज बंद करें या ब्लॉक चयन हटाएँ';

  @override
  String get shortcutEscapeDescription =>
      'कार्यस्थान खोज बंद करें या संपादक मोड में ब्लॉक चयन हटाएँ';

  @override
  String get shortcutGroupFormatting => 'फ़ॉर्मेटिंग';

  @override
  String get shortcutBoldDescription => 'चयनित टेक्स्ट पर बोल्ड चालू/बंद करें';

  @override
  String get shortcutItalicDescription =>
      'चयनित टेक्स्ट पर इटैलिक चालू/बंद करें';

  @override
  String get shortcutUnderlineDescription =>
      'चयनित टेक्स्ट पर अंडरलाइन चालू/बंद करें';

  @override
  String get shortcutLinkDescription => 'कोई लिंक डालें या संपादित करें';

  @override
  String get shortcutInlineCodeDescription =>
      'चयनित टेक्स्ट पर इनलाइन कोड चालू/बंद करें';

  @override
  String get shortcutStrikethroughDescription =>
      'चयनित टेक्स्ट पर स्ट्राइकथ्रू चालू/बंद करें';

  @override
  String get shortcutGroupBlocks => 'ब्लॉक';

  @override
  String get shortcutParagraphDescription => 'मौजूदा ब्लॉक को अनुच्छेद बनाएँ';

  @override
  String get shortcutHeading1Description => 'मौजूदा ब्लॉक को शीर्षक 1 बनाएँ';

  @override
  String get shortcutHeading2Description => 'मौजूदा ब्लॉक को शीर्षक 2 बनाएँ';

  @override
  String get shortcutHeading3Description => 'मौजूदा ब्लॉक को शीर्षक 3 बनाएँ';

  @override
  String get shortcutHeading4Description => 'मौजूदा ब्लॉक को शीर्षक 4 बनाएँ';

  @override
  String get shortcutHeading5Description => 'मौजूदा ब्लॉक को शीर्षक 5 बनाएँ';

  @override
  String get shortcutHeading6Description => 'मौजूदा ब्लॉक को शीर्षक 6 बनाएँ';

  @override
  String get shortcutGroupLists => 'सूचियाँ';

  @override
  String get numberedList => 'क्रमांकित सूची';

  @override
  String get shortcutNumberedListDescription =>
      'क्रमांकित सूची फ़ॉर्मेटिंग चालू/बंद करें';

  @override
  String get bulletedList => 'बुलेट सूची';

  @override
  String get shortcutBulletedListDescription =>
      'बुलेट सूची फ़ॉर्मेटिंग चालू/बंद करें';

  @override
  String get checklist => 'चेकलिस्ट';

  @override
  String get shortcutChecklistDescription =>
      'चेकलिस्ट फ़ॉर्मेटिंग चालू/बंद करें';

  @override
  String get shortcutGroupSidebar => 'साइडबार';

  @override
  String get sidebarViewMenu => 'साइडबार दृश्य';

  @override
  String get createMarkdownFile => 'Markdown फ़ाइल बनाएँ';

  @override
  String get createMarkdownFileDescription =>
      'स्थानीय सहेजा न गया Markdown दस्तावेज़ शुरू करें';

  @override
  String get createWritersideProject => 'Writerside प्रोजेक्ट बनाएँ';

  @override
  String get createWritersideProjectDescription =>
      'स्थानीय Writerside-संगत प्रोजेक्ट शुरू करें';

  @override
  String get defaultProjectName => 'दस्तावेज़ीकरण';

  @override
  String get defaultInstanceName => 'उपयोगकर्ता मार्गदर्शिका';

  @override
  String get defaultStartTopicTitle => 'आरंभ करना';

  @override
  String get projectName => 'प्रोजेक्ट का नाम';

  @override
  String get directoryName => 'डायरेक्टरी नाम';

  @override
  String get instanceName => 'इंस्टेंस नाम';

  @override
  String get instanceId => 'इंस्टेंस ID';

  @override
  String get startTopicTitle => 'आरंभिक विषय शीर्षक';

  @override
  String get location => 'स्थान';

  @override
  String get projectNameRequired => 'प्रोजेक्ट का नाम आवश्यक है।';

  @override
  String get directoryNameRequired => 'डायरेक्टरी नाम आवश्यक है।';

  @override
  String get useSingleSafeDirectoryName =>
      'एक ही सुरक्षित डायरेक्टरी नाम इस्तेमाल करें।';

  @override
  String get useLowercaseIdentifier =>
      'छोटे अक्षरों वाला पहचानकर्ता इस्तेमाल करें, जिसमें केवल अक्षर, अंक, अंडरस्कोर या हाइफ़न हों।';

  @override
  String get startTopicTitleRequired => 'आरंभिक विषय शीर्षक आवश्यक है।';

  @override
  String get createWritersideProjectFailed =>
      'Writerside प्रोजेक्ट नहीं बनाया जा सका।';

  @override
  String get settingsTitle => 'BusyMark सेटिंग्स';

  @override
  String get autoSave => 'स्वतः सहेजें';

  @override
  String get autoSaveDescription =>
      'थोड़ी देर निष्क्रिय रहने के बाद फ़ाइल बदलाव अपने-आप सहेजें।';

  @override
  String get wordWrap => 'वर्ड रैप';

  @override
  String get editorFontSize => 'संपादक फ़ॉन्ट आकार';

  @override
  String get validateOnEdit => 'संपादन के समय सत्यापित करें';

  @override
  String get clearRecentWorkspaces => 'हालिया कार्यस्थान साफ़ करें';

  @override
  String get editingButtonsPosition => 'संपादन बटनों की स्थिति';

  @override
  String get editingButtonsPositionDescription =>
      'चुनें कि फ़्लोटिंग WYSIWYG संपादन बटन कहाँ दिखें।';

  @override
  String get editingButtonsDirection => 'संपादन बटनों की दिशा';

  @override
  String get editingButtonsDirectionDescription =>
      'चुनें कि फ़्लोटिंग WYSIWYG संपादन बटन क्षैतिज रूप से व्यवस्थित हों या लंबवत रूप से।';

  @override
  String get horizontal => 'क्षैतिज';

  @override
  String get vertical => 'लंबवत';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get allowRemoteImages => 'दूरस्थ छवियाँ लोड करें';

  @override
  String get allowRemoteImagesDescription =>
      'Markdown पूर्वावलोकन और संपादक की छवियों को http और https URL से लोड होने दें।';

  @override
  String get clearRemoteImagePermissions => 'दूरस्थ छवि अनुमतियाँ साफ़ करें';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'उन कार्यस्थानों को भूलें जिन्हें दूरस्थ छवियाँ लोड करने की अनुमति दी गई थी।';

  @override
  String get clearGitWorkspaceTrust => 'विश्वसनीय Git कार्यस्थान साफ़ करें';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'पहले से विश्वसनीय कार्यस्थानों के लिए Git सुविधाएँ चालू करने से पहले पूछें।';

  @override
  String get settingsWindowSectionTitle => 'विंडो';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'स्टार्टअप पर पिछला कार्यक्षेत्र फिर से खोलें';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark शुरू होने पर पिछले सत्र का कार्यक्षेत्र और टैब खोलें।';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'न सहेजे गए बदलाव हों तो बंद करने से पहले पुष्टि करें';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'दस्तावेज़ों में न सहेजे गए बदलाव हों तो BusyMark बंद करने से पहले पूछें।';

  @override
  String get closeUnsavedChangesTitle => 'न सहेजे गए बदलाव';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'इस दस्तावेज़ में न सहेजे गए बदलाव हैं। BusyMark बंद करने से पहले बदलाव सहेजें?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count दस्तावेज़ों में न सहेजे गए बदलाव हैं। BusyMark बंद करने से पहले बदलाव सहेजें?',
      one:
          '1 दस्तावेज़ में न सहेजे गए बदलाव हैं। BusyMark बंद करने से पहले बदलाव सहेजें?',
      zero: 'BusyMark बंद करने से पहले बदलाव सहेजें?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'रद्द करें';

  @override
  String get closeUnsavedChangesDiscard => 'त्यागें';

  @override
  String get closeUnsavedChangesSave => 'सहेजें';

  @override
  String get currentFile => 'मौजूदा फ़ाइल';

  @override
  String get unsavedChanges => 'न सहेजे गए बदलाव';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName में न सहेजे गए बदलाव हैं। जारी रखने से पहले उन्हें सहेजें?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count दस्तावेज़ों में असुरक्षित बदलाव हैं। इन्हें जारी रखने से पहले सहेजें।',
      one: '1 दस्तावेज़ में असुरक्षित बदलाव हैं। इसे जारी रखने से पहले सहेजें।',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'डिस्क पर फ़ाइल बदल गई';

  @override
  String get fileChangedOnDiskMessage =>
      'आपके इसे खोलने के बाद यह फ़ाइल डिस्क पर बदल गई है। क्या इसे ओवरराइट करें?';

  @override
  String get untitledMarkdownFileName => 'शीर्षकहीन.md';

  @override
  String get unorderedList => 'बुलेट सूची';

  @override
  String get orderedList => 'क्रमांकित सूची';

  @override
  String get taskList => 'कार्य सूची';

  @override
  String get toggleTaskChecked => 'कार्य को चेक/अनचेक करें';

  @override
  String get indentListItem => 'सूची आइटम का इंडेंट बढ़ाएँ';

  @override
  String get outdentListItem => 'सूची आइटम का इंडेंट घटाएँ';

  @override
  String get blockquote => 'ब्लॉक उद्धरण';

  @override
  String get codeBlock => 'कोड ब्लॉक';

  @override
  String get codeBlockLanguage => 'कोड ब्लॉक भाषा';

  @override
  String get image => 'छवि';

  @override
  String get video => 'वीडियो';

  @override
  String get openVideo => 'वीडियो चलाएँ';

  @override
  String get pauseVideo => 'वीडियो रोकें';

  @override
  String get videoUnavailable => 'वीडियो उपलब्ध नहीं है';

  @override
  String get videoPreview => 'वीडियो पूर्वावलोकन';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'वीडियो में src विशेषता मौजूद नहीं है।';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'असमर्थित वीडियो स्रोत: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'वीडियो फ़ाइल मौजूद नहीं है: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'वीडियो पूर्वावलोकन छवि मौजूद नहीं है: $preview';
  }

  @override
  String get inlineImage => 'इनलाइन छवि';

  @override
  String get table => 'तालिका';

  @override
  String get htmlBlock => 'HTML ब्लॉक';

  @override
  String get htmlContentDefault => 'HTML सामग्री';

  @override
  String get shortcutHtmlBlockDescription => 'HTML ब्लॉक डालें या संपादित करें';

  @override
  String get renderedHtml => 'रेंडर किया गया HTML';

  @override
  String get editHtml => 'HTML संपादित करें';

  @override
  String get htmlSource => 'HTML स्रोत';

  @override
  String get thematicBreak => 'थीमैटिक ब्रेक';

  @override
  String get bold => 'बोल्ड';

  @override
  String get italic => 'इटैलिक';

  @override
  String get underline => 'अंडरलाइन';

  @override
  String get strikethrough => 'स्ट्राइकथ्रू';

  @override
  String get inlineCode => 'इनलाइन कोड';

  @override
  String get link => 'लिंक';

  @override
  String get hardLineBreak => 'हार्ड लाइन ब्रेक';

  @override
  String get textStyle => 'टेक्स्ट शैली';

  @override
  String get paragraph => 'अनुच्छेद';

  @override
  String get heading1 => 'शीर्षक 1';

  @override
  String get heading2 => 'शीर्षक 2';

  @override
  String get heading3 => 'शीर्षक 3';

  @override
  String get heading4 => 'शीर्षक 4';

  @override
  String get heading5 => 'शीर्षक 5';

  @override
  String get heading6 => 'शीर्षक 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'तालिका हटाएँ';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'कॉलम $columnNumber';
  }

  @override
  String get insertColumnLeft => 'बाईं ओर कॉलम सम्मिलित करें';

  @override
  String get insertColumnRight => 'दाईं ओर कॉलम सम्मिलित करें';

  @override
  String get deleteColumn => 'कॉलम हटाएँ';

  @override
  String get tableAlignmentUnspecified => 'संरेखण: अनिर्दिष्ट';

  @override
  String get tableAlignmentLeft => 'संरेखण: बायाँ';

  @override
  String get tableAlignmentCenter => 'संरेखण: मध्य';

  @override
  String get tableAlignmentRight => 'संरेखण: दायाँ';

  @override
  String tableRowNumber(int rowNumber) {
    return 'पंक्ति $rowNumber';
  }

  @override
  String get insertRowAbove => 'ऊपर पंक्ति सम्मिलित करें';

  @override
  String get insertRowBelow => 'नीचे पंक्ति सम्मिलित करें';

  @override
  String get deleteRow => 'पंक्ति हटाएँ';

  @override
  String get tableHeaderHint => 'हेडर';

  @override
  String get tableCellHint => 'सेल';

  @override
  String get language => 'भाषा';

  @override
  String get hideEditingButtons => 'संपादन बटन छिपाएँ';

  @override
  String get showEditingButtons => 'संपादन बटन दिखाएँ';

  @override
  String get altText => 'Alt टेक्स्ट';

  @override
  String get editorPlaceholderText => 'टेक्स्ट';

  @override
  String get editorPlaceholderCode => 'कोड';

  @override
  String get editorPlaceholderAltText => 'वैकल्पिक टेक्स्ट';

  @override
  String get describeTheImage => 'छवि का वर्णन करें';

  @override
  String get columns => 'कॉलम';

  @override
  String get rows => 'पंक्तियाँ';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'हेडर $columnNumber';
  }

  @override
  String get tableCellDefault => 'सेल';

  @override
  String get noImageSource => 'कोई छवि स्रोत नहीं';

  @override
  String get remoteImageBlocked => 'दूरस्थ छवि अवरुद्ध';

  @override
  String get remoteImageBlockedTooltip =>
      'चुनें कि BusyMark दूरस्थ छवियाँ लोड कर सकता है या नहीं।';

  @override
  String get remoteImagesBlockedTitle => 'दूरस्थ छवियाँ अवरुद्ध हैं';

  @override
  String get remoteImagesBlockedMessage =>
      'यह दस्तावेज़ इंटरनेट की छवियों का संदर्भ देता है। उन्हें लोड करने पर छवि होस्ट को नेटवर्क की जानकारी मिल सकती है।';

  @override
  String get loadRemoteImagesForWorkspace => 'इस कार्यस्थान के लिए लोड करें';

  @override
  String get alwaysLoadRemoteImages => 'दूरस्थ छवियाँ हमेशा लोड करें';

  @override
  String get hideSidebar => 'साइडबार पैनल छिपाएँ';

  @override
  String get showSidebar => 'साइडबार पैनल दिखाएँ';

  @override
  String get showPreview => 'पूर्वावलोकन दिखाएँ';

  @override
  String get hidePreview => 'पूर्वावलोकन छिपाएँ';

  @override
  String get workspaceKindUnsavedMarkdown => 'सहेजी न गई Markdown फ़ाइल';

  @override
  String get workspaceKindSingleMarkdown => 'एकल Markdown फ़ाइल';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown फ़ोल्डर';

  @override
  String get workspaceKindWritersideModule => 'Writerside मॉड्यूल';

  @override
  String get problems => 'समस्याएँ';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डायग्नोस्टिक',
      one: '1 डायग्नोस्टिक',
      zero: 'कोई डायग्नोस्टिक नहीं',
    );
    return '$_temp0';
  }

  @override
  String get files => 'फ़ाइलें';

  @override
  String get toc => 'TOC';

  @override
  String get tocActions => 'विषय-सूची संबंधी कार्रवाइयाँ';

  @override
  String get markdownUnsaved => 'Markdown - सहेजा नहीं गया';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें',
      one: '1 फ़ाइल',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'कोई फ़ाइल नहीं';

  @override
  String get newFile => 'नई फ़ाइल';

  @override
  String get noWritersideToc => 'कोई Writerside TOC नहीं';

  @override
  String get tocSection => 'TOC अनुभाग';

  @override
  String get newTopic => 'नया विषय';

  @override
  String get newChildTopic => 'नया उप-विषय';

  @override
  String get newSiblingTopic => 'समान स्तर पर नया विषय';

  @override
  String get renameTopicFile => 'विषय फ़ाइल का नाम बदलें';

  @override
  String get topicPlacement => 'TOC में स्थान';

  @override
  String get tocRoot => 'TOC के शीर्ष स्तर पर';

  @override
  String get afterSelectedTopic => 'चयनित विषय के बाद';

  @override
  String get insideSelectedTopic => 'चयनित विषय के अंदर';

  @override
  String get pasteAfterTopic => 'इसके बाद पेस्ट करें';

  @override
  String get pasteAsChildTopic => 'उप-विषय के रूप में पेस्ट करें';

  @override
  String get removeFromToc => 'TOC से हटाएँ';

  @override
  String get confirmRemoveFromTocTitle => 'TOC से हटाएँ?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'इस TOC से $name को हटाएँ? विषय फ़ाइल बनी रहेगी।';
  }

  @override
  String get confirmDeleteTopicTitle => 'विषय फ़ाइल हटाएँ?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name को हटाकर सभी TOC से निकाल दें? इसे वापस नहीं किया जा सकता।';
  }

  @override
  String get safeDeleteTopicFile => 'विषय फ़ाइल को सुरक्षित रूप से हटाएँ…';

  @override
  String get removeTocElement => 'TOC तत्व हटाएँ';

  @override
  String get reviewUsages => 'उपयोगों की समीक्षा करें';

  @override
  String get deleteTopicFile => 'विषय फ़ाइल हटाएँ';

  @override
  String get removeAction => 'हटाएँ';

  @override
  String topicRemovalSummary(String topic) {
    return '“$topic” को चुने गए इंस्टेंस से हटाएँ। विषय फ़ाइल रखी जाएगी।';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '“$topic” को हटाएँ और इस पूरे Writerside प्रोजेक्ट में उसके संदर्भों को सुरक्षित रूप से अपडेट करें।';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count उप-विषय एक स्तर ऊपर चले जाएँगे।',
      one: '1 उप-विषय एक स्तर ऊपर चला जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'यह विषय किसी इंस्टेंस के प्रारंभ पृष्ठ के रूप में उपयोग हो रहा है। इसके उपयोगों की समीक्षा करें और आगे बढ़ने से पहले कोई दूसरा प्रारंभ पृष्ठ निर्धारित करें।';

  @override
  String topicUsagesCount(int count) {
    return 'उपयोग ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'कोई ऐसा संदर्भ नहीं मिला जो टूट सकता है।';

  @override
  String get topicUsagesFound => 'BusyMark को इस विषय के निम्न संदर्भ मिले।';

  @override
  String get topicUsageTocElements => 'TOC तत्व';

  @override
  String get topicUsageStartPages => 'प्रारंभ पृष्ठ';

  @override
  String get topicUsageTopicLinks => 'विषय लिंक';

  @override
  String get topicUsageIncludes => 'शामिल अंश';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count उपयोग',
      one: '1 उपयोग',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'रीफ़ैक्टरिंग विकल्प';

  @override
  String get updateUsagesAutomatically => 'उपयोगों को अपने आप अपडेट करें';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'TOC संदर्भ और शामिल अंश हटाएँ, और लिंक का टेक्स्ट बनाए रखें।';

  @override
  String get manualUsageUpdatesRequired =>
      'इस रीफ़ैक्टरिंग से पहले कुछ उपयोगों को मैन्युअल रूप से बदलना होगा।';

  @override
  String get setRedirectTo => 'इस पर रीडायरेक्ट करें';

  @override
  String get noRedirectDescription =>
      'पुराने प्रकाशित पृष्ठ को रीडायरेक्ट न करें।';

  @override
  String get redirectTarget => 'रीडायरेक्ट गंतव्य';

  @override
  String get remainingUsagesBlockRemoval =>
      'आगे बढ़ने से पहले शेष उपयोगों की समीक्षा करके उन्हें अपडेट करें, या उपलब्ध होने पर अपने आप अपडेट करने का विकल्प चालू करें।';

  @override
  String usagesOfTopic(String topic) {
    return '$topic के उपयोग';
  }

  @override
  String get noUsagesFound => 'कोई उपयोग नहीं मिला';

  @override
  String get outsideSelectedInstance => 'चुने गए इंस्टेंस के बाहर';

  @override
  String get doRefactor => 'रीफ़ैक्टर करें';

  @override
  String get orphanTopicTitle => 'विषय फ़ाइल अब उपयोग में नहीं है';

  @override
  String get keepTopicFile => 'विषय फ़ाइल रखें';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” अब इस Writerside प्रोजेक्ट में कहीं भी उपयोग नहीं होता। फ़ाइल हटाएँ या किसी दूसरे इंस्टेंस में उपयोग के लिए इसे रखें।';
  }

  @override
  String get defaultNewTopicTitle => 'नया विषय';

  @override
  String get topicTitle => 'विषय शीर्षक';

  @override
  String get fileName => 'फ़ाइल नाम';

  @override
  String get topicTitleRequired => 'विषय शीर्षक आवश्यक है।';

  @override
  String get fileNameRequired => 'फ़ाइल नाम आवश्यक है।';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get confirmDeleteFileTitle => 'फ़ाइल हटाएँ?';

  @override
  String get confirmDeleteFolderTitle => 'फ़ोल्डर हटाएँ?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name हटाएँ? इसे वापस नहीं किया जा सकता।';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name और उसके अंदर की सभी फ़ाइलें हटाएँ? इसे वापस नहीं किया जा सकता।';
  }

  @override
  String get useSingleSafeFileName => 'एक ही सुरक्षित फ़ाइल नाम इस्तेमाल करें।';

  @override
  String useExpectedExtension(String extension) {
    return 'चयनित फ़ॉर्मैट के लिए $extension एक्सटेंशन इस्तेमाल करें।';
  }

  @override
  String get useIdentifierCharacters =>
      'एक्सटेंशन से पहले अक्षर, अंक, अंडरस्कोर या हाइफ़न इस्तेमाल करें।';

  @override
  String get topicIdAlreadyExists => 'विषय ID पहले से मौजूद है।';

  @override
  String get createWritersideTopicFailed =>
      'Writerside विषय नहीं बनाया जा सका।';

  @override
  String get noOutline => 'कोई रूपरेखा नहीं';

  @override
  String expandKind(String kind) {
    return '$kind विस्तृत करें';
  }

  @override
  String collapseKind(String kind) {
    return '$kind समेटें';
  }

  @override
  String get foldKindSection => 'अनुभाग';

  @override
  String get foldKindList => 'सूची';

  @override
  String get foldKindQuote => 'उद्धरण';

  @override
  String get foldKindTag => 'टैग';

  @override
  String get sourceSearchPreviousMatch => 'पिछला मिलान';

  @override
  String get sourceSearchNextMatch => 'अगला मिलान';

  @override
  String get sourceSearchCaseSensitive =>
      'बड़े-छोटे अक्षरों के प्रति संवेदनशील';

  @override
  String get sourceSearchWholeWord => 'पूरा शब्द';

  @override
  String get sourceSearchRegex => 'रेगुलर एक्सप्रेशन';

  @override
  String get sourceSearchReplacement => 'इससे बदलें';

  @override
  String get sourceSearchReplaceCurrent => 'वर्तमान मिलान बदलें';

  @override
  String get sourceSearchReplaceAndFindNext => 'बदलें और अगला खोजें';

  @override
  String get sourceSearchReplaceAll => 'सभी बदलें';

  @override
  String get workspaceReplace => 'वर्कस्पेस में बदलें';

  @override
  String get reviewReplacements => 'बदलावों की समीक्षा करें';

  @override
  String get applyReplacements => 'बदलाव लागू करें';

  @override
  String get skippedFiles => 'छोड़ी गई फ़ाइलें';

  @override
  String get workspaceReplaceDirtyBuffer => 'सहेजी न गई संपादक सामग्री';

  @override
  String get workspaceReplaceDiskContent => 'डिस्क पर सहेजी सामग्री';

  @override
  String selectFileMatches(int count) {
    return 'सभी $count मिलान चुनें';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$files फ़ाइलों में $matches मिलान बदले गए; $skipped छोड़े गए।';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · अंतिम नई पंक्ति';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · अंतिम नई पंक्ति नहीं';
  }

  @override
  String get normalizeLineEndings => 'पंक्ति अंत सामान्य करें';

  @override
  String get mixedLineEndingsSavePrompt =>
      'इस दस्तावेज़ में मिले-जुले पंक्ति अंत हैं। कोई प्रारूप चुनें।';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName में मिले-जुले पंक्ति अंत हैं। बदलने से पहले प्रारूप चुनें।';
  }

  @override
  String get workspaceReplaceIssueOversized => 'बहुत बड़ी फ़ाइल छोड़ दी गई।';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'पढ़ी न जा सकने वाली फ़ाइल छोड़ दी गई।';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'अमान्य UTF-8 वाली फ़ाइल छोड़ दी गई।';

  @override
  String get workspaceReplaceIssueTruncated =>
      'बदलाव पूर्वावलोकन छोटा कर दिया गया।';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'पूर्वावलोकन के बाद बदली फ़ाइल छोड़ दी गई।';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'पूर्वावलोकन के बाद बदला संपादक बफ़र छोड़ दिया गया।';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'बदलने से पहले LF या CRLF सामान्यीकरण चुनें।';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'रोलबैक रोक दिया गया क्योंकि फ़ाइल उसी समय बदल गई थी। कुछ प्रतिस्थापन बने रह सकते हैं; हटाई गई सामग्री नीचे दिए गए पथ पर सुरक्षित रखी गई है।';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'कोई प्रतिस्थापन लागू नहीं किया गया क्योंकि समीक्षा किए गए समूह को सुरक्षित रूप से सहेजा नहीं जा सका।';

  @override
  String externalChangesTitle(String fileName) {
    return 'बाहरी बदलाव — $fileName';
  }

  @override
  String get externalFileDeleted => 'यह फ़ाइल डिस्क से हटा दी गई।';

  @override
  String get externalFileChanged =>
      'आपके सहेजे न गए बदलावों के दौरान यह फ़ाइल डिस्क पर बदल गई।';

  @override
  String recoveredDocumentReview(String fileName) {
    return '$fileName की सहेजी नहीं गई सामग्री पुनर्प्राप्त हुई। इसकी समीक्षा करें, फिर सहेजें, इस रूप में सहेजें या छोड़ दें।';
  }

  @override
  String get compare => 'तुलना करें';

  @override
  String get reloadFromDisk => 'डिस्क से फिर लोड करें';

  @override
  String get keepMine => 'मेरा संस्करण रखें';

  @override
  String get saveAs => 'इस रूप में सहेजें';

  @override
  String get sourceSearchInvalidRegex => 'अमान्य रेगुलर एक्सप्रेशन';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'बड़ी फ़ाइल: हाइलाइटिंग और फ़ोल्डिंग अस्थायी रूप से रुकी हुई हैं';

  @override
  String get nothingToRead => 'पढ़ने के लिए कोई सामग्री नहीं';

  @override
  String get admonition => 'सूचना ब्लॉक';

  @override
  String get quote => 'उद्धरण';

  @override
  String get note => 'नोट';

  @override
  String get tip => 'सुझाव';

  @override
  String get warning => 'चेतावनी';

  @override
  String get tabs => 'टैब';

  @override
  String get tab => 'टैब';

  @override
  String get procedure => 'प्रक्रिया';

  @override
  String get step => 'चरण';

  @override
  String get topic => 'विषय';

  @override
  String get chapter => 'अध्याय';

  @override
  String couldNotOpenTarget(String target) {
    return '$target नहीं खोला जा सका';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'लिंक लक्ष्य नहीं मिला: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'इस फ़ाइल प्रकार को संपादक में नहीं खोला जा सकता';

  @override
  String anchorNotFound(String anchor) {
    return 'एंकर नहीं मिला: $anchor';
  }

  @override
  String get noProblemsFound => 'कोई समस्या नहीं मिली';

  @override
  String get noResults => 'कोई परिणाम नहीं';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - लाइन $lineNumber';
  }

  @override
  String get untitledResult => 'शीर्षकहीन परिणाम';

  @override
  String get documentKindMarkdownFile => 'Markdown फ़ाइल';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown विषय';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML विषय';

  @override
  String get documentKindWritersideTree => 'Writerside ट्री';

  @override
  String get documentKindConfigurationFile => 'कॉन्फ़िगरेशन फ़ाइल';

  @override
  String get documentKindVariablesFile => 'वेरिएबल फ़ाइल';

  @override
  String get documentKindCategoriesFile => 'श्रेणी फ़ाइल';

  @override
  String get documentKindResourceFile => 'संसाधन फ़ाइल';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'खोलना विफल रहा: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Writerside प्रोजेक्ट नहीं बनाया जा सका: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Writerside विषय नहीं बनाया जा सका: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'फ़ाइल नहीं खोली जा सकी: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'इस Markdown फ़ाइल को कहाँ सहेजना है, चुनें।';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'सहेजना रोका गया: डिस्क पर फ़ाइल बदल गई है।';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'सहेजना विफल रहा: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'फ़ाइल ऑपरेशन विफल रहा: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'सत्यापन विफल रहा: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count बिना सहेजे दस्तावेज़ पुनर्प्राप्त किए गए। प्रत्येक की समीक्षा करके सहेजें या हटाएँ।',
      one:
          '1 बिना सहेजा दस्तावेज़ पुनर्प्राप्त किया गया। इसे सहेजने या हटाने से पहले समीक्षा करें।',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count क्षतिग्रस्त पुनर्प्राप्ति रिकॉर्ड पुनर्स्थापित नहीं किए जा सके। वैध पुनर्प्राप्ति रिकॉर्ड अभी भी उपलब्ध हैं।',
      one:
          'एक क्षतिग्रस्त पुनर्प्राप्ति रिकॉर्ड पुनर्स्थापित नहीं किया जा सका। मूल पुनर्प्राप्ति फ़ाइल निरीक्षण के लिए सुरक्षित रखी गई।',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'पाथ मौजूद नहीं है: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'लक्ष्य डायरेक्टरी पहले से मौजूद है और खाली नहीं है: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'लक्ष्य पाथ पहले से मौजूद है और डायरेक्टरी नहीं है: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'बनाई गई फ़ाइल पहले से मौजूद है: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'पैरेंट डायरेक्टरी आवश्यक है।';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'पैरेंट डायरेक्टरी मौजूद नहीं है: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'डायरेक्टरी मौजूद नहीं है: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'पथ पहले से मौजूद है: $path';
  }

  @override
  String get errorFileNameRequired => 'फ़ाइल नाम आवश्यक है।';

  @override
  String get errorFileNameUnsafe => 'फ़ाइल नाम एक सुरक्षित पथ खंड होना चाहिए।';

  @override
  String get errorFileOperationInvalidTarget =>
      'किसी फ़ोल्डर को उसी के अंदर नहीं ले जाया जा सकता।';

  @override
  String get errorFileOperationOutsideRoot =>
      'फ़ाइल कार्रवाई कार्यस्थान के अंदर ही रहनी चाहिए।';

  @override
  String get errorFileOperationRoot =>
      'फ़ाइल ट्री से कार्यस्थान का रूट नहीं बदला जा सकता।';

  @override
  String get errorProjectNameRequired => 'प्रोजेक्ट का नाम आवश्यक है।';

  @override
  String get errorDirectoryNameRequired => 'डायरेक्टरी नाम आवश्यक है।';

  @override
  String get errorDirectoryNameUnsafe =>
      'डायरेक्टरी नाम एक ही सुरक्षित पाथ सेगमेंट होना चाहिए।';

  @override
  String get errorInstanceIdInvalid =>
      'इंस्टेंस ID छोटे अक्षर से शुरू होनी चाहिए और उसमें केवल छोटे अक्षर, अंक, अंडरस्कोर और हाइफ़न होने चाहिए।';

  @override
  String get errorTopicFileInvalid =>
      'विषय फ़ाइल नाम पाथ सेपरेटर के बिना Markdown फ़ाइल नाम होना चाहिए।';

  @override
  String get errorTopicTitleRequired => 'विषय शीर्षक आवश्यक है।';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside मॉड्यूल रूट मौजूद नहीं है: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'विषय बनाने के लिए Writerside मॉड्यूल खुला होना चाहिए।';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside मॉड्यूल में कोई इंस्टेंस ट्री नहीं है।';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside ट्री फ़ाइल मौजूद नहीं है: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'विषय ID \"$topicId\" इस हेल्प मॉड्यूल में पहले से मौजूद है।';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'विषय फ़ाइल पहले से मौजूद है: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'संदर्भित विषय चयनित ट्री में मौजूद नहीं है: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'चयनित TOC प्रविष्टि अब मौजूद नहीं है।';

  @override
  String get errorWritersideTocInvalidMove =>
      'TOC प्रविष्टि को उसी के अंदर या उसकी किसी उप-प्रविष्टि के अंदर नहीं ले जाया जा सकता।';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'आरंभिक विषय $topic को हटाया नहीं जा सकता। पहले कोई दूसरा आरंभ पेज चुनें।';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Writerside विषय फ़ाइलों के लिए सुरक्षित रूप से हटाएँ सुविधा का उपयोग करें।';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'विषय के उपयोगों की जाँच पूरी नहीं हो सकी। कोई फ़ाइल नहीं बदली गई।';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'विषय के कुछ उपयोगों पर अभी ध्यान देना आवश्यक है। आगे बढ़ने से पहले उनकी समीक्षा करें।';

  @override
  String get errorWritersideRedirectInvalid =>
      'चुना गया रीडायरेक्ट लक्ष्य अब मान्य नहीं है। उसे फिर से चुनें।';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'विषय हटाने की कार्रवाई पूरी तरह वापस नहीं की जा सकी। आगे बढ़ने से पहले इन पथों की समीक्षा करें: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'विषय रूट सुरक्षित सापेक्ष डायरेक्टरी होना चाहिए।';

  @override
  String get errorTopicFileNameUnsafe =>
      'विषय फ़ाइल नाम एक ही सुरक्षित पाथ सेगमेंट होना चाहिए।';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'विषय फ़ाइल एक्सटेंशन चयनित फ़ॉर्मैट ($extension) से मेल खाना चाहिए।';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'विषय फ़ाइल नाम में केवल अक्षर, अंक, अंडरस्कोर और हाइफ़न होने चाहिए।';

  @override
  String errorUnknown(String code) {
    return 'अज्ञात त्रुटि: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'फ़ाइल मेटाडेटा नहीं पढ़ा जा सका: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'बड़ा कार्यस्थान मिला। ऐप को प्रतिक्रियाशील रखने के लिए कुछ फ़ाइलें छोड़ दी गईं।';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'कार्यस्थान प्रविष्टि का निरीक्षण नहीं किया जा सका: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'फ़ाइल बीटा ऑटो-पार्स सीमा से बड़ी है।';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Markdown फ़ाइल नहीं पढ़ी जा सकी: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Writerside हेडिंग एट्रिब्यूट ब्लॉक गलत संरचना वाला है।';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'डुप्लिकेट शीर्षक ID \"$id\"।';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'अतिरिक्त शीर्ष-स्तरीय H1 शीर्षकों को अध्याय माना जाता है।';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown विषय में H1 या फ्रंट मैटर शीर्षक नहीं है।';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML विषय में शीर्षक नहीं है।';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'विषय \"$fileName\" में शीर्षक नहीं है।';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'फ्रंट मैटर बंद नहीं है।';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'असुरक्षित HTML एलिमेंट।';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'लिंक लक्ष्य मौजूद नहीं है: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'एंकर \"$anchor\" मौजूद नहीं है।';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'छवि \"$destination\" में Alt टेक्स्ट नहीं है।';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'छवि मौजूद नहीं है: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'अमान्य XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg रूट <ihp> होना चाहिए।';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets घोषणा में src अनुपस्थित है।';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups घोषणा में src अनुपस्थित है।';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'असमर्थित keymaps मोड: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'इंस्टेंस घोषणा में src अनुपस्थित है।';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg कोई इंस्टेंस पंजीकृत नहीं करता है।';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree रूट <instance-profile> होना चाहिए।';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'इंस्टेंस प्रोफ़ाइल में id अनुपस्थित है।';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'ट्री फ़ाइल का स्टेम इंस्टेंस id \"$id\" से मेल नहीं खाता।';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'गैर-लाइब्रेरी इंस्टेंस में start-page अनुपस्थित है।';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'आरंभ पेज \"$startPage\" मौजूद नहीं है।';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'विषय \"$topic\" इस इंस्टेंस TOC में एक से अधिक बार आता है।';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'वेरिएबल घोषणा में नाम और मान होना चाहिए।';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'वेरिएबल \"$name\" एक से अधिक बार घोषित किया गया है।';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'श्रेणी में id अनुपस्थित है।';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'श्रेणी \"$id\" एक से अधिक बार घोषित की गई है।';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'श्रेणी क्रम \"$order\" एक से अधिक बार घोषित किया गया है।';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic रूट <topic> होना चाहिए।';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML विषय में रूट id अनुपस्थित है।';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML विषय रूट id \"$id\" फ़ाइल नाम \"$expectedId\" से मेल खाना चाहिए।';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'एलिमेंट id \"$elementId\" एक से अधिक बार दिखाई देता है।';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> में href अनुपस्थित है।';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside मोड के लिए writerside.cfg आवश्यक है।';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'कॉन्फ़िगर की गई बिल्ड कॉन्फ़िगरेशन डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'कॉन्फ़िगर की गई API विनिर्देश डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'कॉन्फ़िगर की गई स्निपेट्स डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'कॉन्फ़िगर की गई वेरिएबल्स फ़ाइल नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'कॉन्फ़िगर की गई श्रेणी फ़ाइल नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'कॉन्फ़िगर की गई इंस्टेंस समूह फ़ाइल नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'पंजीकृत इंस्टेंस ट्री \"$source\" मौजूद नहीं है।';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'विषय फ़ाइल नहीं पढ़ी जा सकी: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'डिफ़ॉल्ट विषय डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'कॉन्फ़िगर की गई विषय डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'कॉन्फ़िगर की गई छवि डायरेक्टरी नहीं मिली: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'एलिमेंट id \"$id\" एक से अधिक बार दिखाई देता है।';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC अनुपस्थित विषय \"$topic\" का संदर्भ देता है।';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'बाहरी href \"$href\" अमान्य है।';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'वेरिएबल \"%$name%\" घोषित नहीं है।';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'विषय लिंक \"$destination\" रिज़ॉल्व नहीं होता।';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'एंकर \"$anchor\" \"$targetName\" में मौजूद नहीं है।';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> में from अनुपस्थित है।';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'include स्रोत \"$from\" मौजूद नहीं है।';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'include एलिमेंट \"$elementId\" \"$from\" में मौजूद नहीं है।';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso श्रेणी \"$ref\" घोषित नहीं है।';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'विषय संदर्भ \"$reference\" अस्पष्ट है।';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'अज्ञात डायग्नोस्टिक: $code';
  }

  @override
  String get close => 'बंद करें';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git डिफ़';

  @override
  String get gitShowDiff => 'डिफ़ दिखाएँ';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'पुराना $oldRange → नया $newRange';
  }

  @override
  String get gitDiffNoLines => 'कोई पंक्ति नहीं';

  @override
  String get gitUnavailableTitle => 'Git उपलब्ध नहीं है';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Git इंस्टॉल करें या BusyMark को उपलब्ध Git एक्ज़ीक्यूटेबल इस्तेमाल करने के लिए कॉन्फ़िगर करें। $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Git के लिए इस कार्यस्थान पर भरोसा करें?';

  @override
  String get gitTrustRequiredMessage =>
      'Git रिपॉज़िटरी हुक, फ़िल्टर और अन्य कॉन्फ़िगरेशन के ज़रिए प्रोग्राम चला सकती हैं। BusyMark के रिपॉज़िटरी डेटा पढ़ने या Git कार्रवाइयाँ चालू करने से पहले इस कार्यस्थान पर भरोसा करें।';

  @override
  String get gitTrustWorkspace => 'कार्यस्थान पर भरोसा करें';

  @override
  String get gitNotRepositoryTitle => 'Git रिपॉज़िटरी नहीं है';

  @override
  String get gitNotRepositoryMessage =>
      'यह कार्यस्थान किसी Git रिपॉज़िटरी के अंदर नहीं है।';

  @override
  String get gitInitializeRepository => 'रिपॉज़िटरी आरंभ करें';

  @override
  String get gitDetachedHead => 'डिटैच्ड HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '$commit पर डिटैच्ड HEAD';
  }

  @override
  String get gitNoUpstream => 'कोई अपस्ट्रीम नहीं';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कमिट पुश नहीं किए गए',
      one: '1 कमिट पुश नहीं किया गया',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कमिट पुल करना बाकी',
      one: '1 कमिट पुल करना बाकी',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'क्लीन';

  @override
  String get gitConflicts => 'टकराव';

  @override
  String get gitChanges => 'बदलाव';

  @override
  String get gitStaged => 'स्टेज किए गए';

  @override
  String get gitUnstaged => 'स्टेज नहीं किए गए';

  @override
  String get gitHistory => 'इतिहास';

  @override
  String get gitBranches => 'शाखाएँ';

  @override
  String get gitActions => 'Git कार्रवाइयाँ';

  @override
  String get gitPull => 'पुल';

  @override
  String get gitFetch => 'प्राप्त करें';

  @override
  String get gitPush => 'पुश';

  @override
  String get gitCommit => 'कमिट करें';

  @override
  String get gitSelectForCommit => 'फ़ाइल स्टेज करें';

  @override
  String get gitRemoveFromCommit => 'फ़ाइल अनस्टेज करें';

  @override
  String get gitDiscard => 'त्यागें';

  @override
  String get gitOpenFile => 'फ़ाइल खोलें';

  @override
  String get gitMarkResolved => 'सुलझा हुआ चिह्नित करें';

  @override
  String get gitUntracked => 'अनट्रैक की गई फ़ाइलें';

  @override
  String get gitCommitMessage => 'कमिट संदेश';

  @override
  String get gitCommitSelectedFiles => 'चयनित फ़ाइलें';

  @override
  String get gitCommitNoSelectedFiles =>
      'कमिट करने से पहले कम से कम एक फ़ाइल स्टेज करें।';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्टेज की गई फ़ाइलें',
      one: '1 स्टेज की गई फ़ाइल',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'कार्यस्थान के बाहर';

  @override
  String get gitCommitMessageRequired => 'कमिट संदेश दर्ज करें।';

  @override
  String get gitCreateBranch => 'शाखा बनाएँ';

  @override
  String get gitNewBranch => 'नई शाखा';

  @override
  String get gitBranchName => 'शाखा का नाम';

  @override
  String get gitSwitchBranch => 'बदलें';

  @override
  String get gitNoChanges => 'कोई बदलाव नहीं';

  @override
  String get gitNoHistory => 'कोई इतिहास नहीं';

  @override
  String get gitNoBranches => 'कोई शाखा नहीं';

  @override
  String get gitNoDiff => 'दिखाने के लिए कोई अंतर नहीं';

  @override
  String get gitBinaryFile =>
      'बाइनरी फ़ाइल। BusyMark बाइनरी पैच रेंडर नहीं करता है।';

  @override
  String gitBinaryFileInfo(int size) {
    return 'बाइनरी फ़ाइल ($size बाइट)। BusyMark बाइनरी पैच प्रदर्शित नहीं करता।';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'संपादक के न सहेजे गए बदलाव सहेजे जाने तक शामिल नहीं किए जाते।';

  @override
  String get gitConfirmDiscardTitle => 'Git बदलाव त्यागें?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'चयनित ट्रैक की गई फ़ाइलों के सभी चरणबद्ध और अचयनित परिवर्तन HEAD पर वापस लाए जाएँगे।',
      one:
          'चयनित ट्रैक की गई फ़ाइल के सभी चरणबद्ध और अचयनित परिवर्तन HEAD पर वापस लाए जाएँगे।',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'चयनित अनट्रैक की गई फ़ाइलें हटा दी जाएँगी।',
      one: 'चयनित अनट्रैक की गई फ़ाइल हटा दी जाएगी।',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'चयनित फ़ाइलों को उनकी Git स्थिति के आधार पर पुनर्स्थापित किया या हटाया जाएगा।',
      one:
          'चयनित फ़ाइल को उसकी Git स्थिति के आधार पर पुनर्स्थापित किया या हटाया जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '$branch पर स्विच करें?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'Git के शाखा बदलने के बाद BusyMark कार्यस्थान को डिस्क से फिर लोड करेगा।';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'अपस्ट्रीम शाखा सेट करें?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'इस शाखा का कोई अपस्ट्रीम नहीं है। ठीक एक रिमोट कॉन्फ़िगर होने पर BusyMark $branch को पुश करके उसका अपस्ट्रीम सेट कर सकता है।';
  }

  @override
  String get gitProjectHistory => 'परियोजना इतिहास';

  @override
  String get gitFileHistory => 'फ़ाइल इतिहास';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'फ़ाइल इतिहास के लिए एक Markdown फ़ाइल खुली होनी चाहिए।';

  @override
  String get gitLoadMore => 'और लोड करें';

  @override
  String get gitChangesInCommit => 'इस कमिट में बदलाव';

  @override
  String get gitCompareWithCurrent => 'वर्तमान संस्करण से तुलना करें';

  @override
  String get gitRestoreVersion => 'यह संस्करण पुनर्स्थापित करें';

  @override
  String get gitConfirmRestoreTitle => 'फ़ाइल का यह संस्करण पुनर्स्थापित करें?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark वर्तमान कार्य-वृक्ष फ़ाइल को चुने गए कमिट संस्करण से बदल देगा। पुनर्स्थापित फ़ाइल स्टेज नहीं की जाएगी।';

  @override
  String get gitCommitActions => 'कमिट कार्रवाइयाँ';

  @override
  String get gitResetCurrentBranchToHere => 'मौजूदा ब्रांच को यहाँ रीसेट करें…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '$branch को $commit पर रीसेट करें?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'इससे ब्रांच $branch, कमिट $commit पर चली जाएगी। चुनें कि Git इंडेक्स और वर्किंग ट्री को कैसे अपडेट करे।';
  }

  @override
  String get gitReset => 'रीसेट करें';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'केवल ब्रांच को ले जाएँ। इंडेक्स और वर्किंग ट्री को न बदलें; चुने गए कमिट से अंतर स्टेज में बने रहेंगे।';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'ब्रांच को ले जाएँ और इंडेक्स रीसेट करें। वर्किंग ट्री को न बदलें, ताकि अंतर अनस्टेज्ड रहें।';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'ब्रांच को ले जाएँ और इंडेक्स तथा वर्किंग ट्री रीसेट करें। ट्रैक किए गए बदलाव हटा दिए जाएँगे; रास्ता रोकने वाली अनट्रैक्ड फ़ाइलें हटाई जा सकती हैं।';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'ब्रांच को ले जाएँ और स्थानीय बदलाव सुरक्षित रखते हुए ट्रैक की गई फ़ाइलें रीसेट करें। इन बदलावों में टकराव होने पर Git रीसेट रोक देता है।';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'फ़ाइल कार्रवाइयाँ';

  @override
  String get actions => 'कार्रवाइयाँ';

  @override
  String get gitStatusAdded => 'जोड़ा गया';

  @override
  String get gitStatusDeleted => 'हटाया गया';

  @override
  String get gitStatusRenamed => 'नाम बदला गया';

  @override
  String get gitStatusCopied => 'कॉपी किया गया';

  @override
  String get gitStatusUntracked => 'अनट्रैक किया गया';

  @override
  String get gitStatusConflicted => 'टकराव वाला';

  @override
  String get gitStatusIgnored => 'अनदेखा किया गया';

  @override
  String get gitStatusTypeChanged => 'प्रकार बदला गया';

  @override
  String get gitStatusModified => 'बदला गया';

  @override
  String get gitStatusUnknown => 'अज्ञात';

  @override
  String get gitErrorUnavailable => 'Git उपलब्ध नहीं है।';

  @override
  String get gitErrorNotRepository => 'यह कार्यस्थान Git रिपॉज़िटरी नहीं है।';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark ने असुरक्षित Git पथ को अवरुद्ध किया।';

  @override
  String get gitErrorInvalidBranchName => 'मान्य शाखा नाम दर्ज करें।';

  @override
  String get gitErrorNoRemote => 'कोई Git रिमोट कॉन्फ़िगर नहीं है।';

  @override
  String get gitErrorNoUpstream => 'कोई अपस्ट्रीम शाखा कॉन्फ़िगर नहीं है।';

  @override
  String get gitErrorMultipleRemotes =>
      'कई रिमोट कॉन्फ़िगर हैं। इस BusyMark संस्करण के बाहर कोई अपस्ट्रीम चुनें।';

  @override
  String get gitErrorDirtyWorkspace =>
      'शाखा बदलने से पहले BusyMark संपादक के बदलाव सहेजें या त्यागें।';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'मौजूदा ब्रांच को रीसेट करने से पहले BusyMark संपादक के बदलाव सहेजें या छोड़ दें।';

  @override
  String get gitErrorRestoreStagedFile =>
      'पिछला संस्करण पुनर्स्थापित करने से पहले फ़ाइल को अनस्टेज करें।';

  @override
  String get gitErrorResetDetachedHead =>
      'रीसेट करने से पहले किसी ब्रांच पर जाएँ।';

  @override
  String get gitErrorDiverged =>
      'शाखा अलग हो गई है। इस BusyMark संस्करण के बाहर मर्ज या रीबेस करके इसे सुलझाएँ।';

  @override
  String get gitErrorAuthorIdentity =>
      'कमिट करने से पहले Git को लेखक का नाम और ईमेल पता चाहिए।';

  @override
  String get gitAuthorIdentityTitle => 'Git लेखक पहचान';

  @override
  String get gitAuthorIdentityMessage =>
      'वह पहचान दर्ज करें जिसे Git कमिट में रिकॉर्ड करे। BusyMark इसे सहेजकर इस कमिट को फिर से आज़माएगा।';

  @override
  String get gitAuthorName => 'नाम';

  @override
  String get gitAuthorEmail => 'ईमेल';

  @override
  String get gitAuthorIdentityGlobal => 'सभी रिपॉज़िटरी के लिए उपयोग करें';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Snap के रूप में इंस्टॉल होने पर यह BusyMark में खोली गई रिपॉज़िटरी पर लागू होता है।';

  @override
  String get gitSaveIdentityAndCommit => 'सहेजें और कमिट करें';

  @override
  String get gitErrorAuthentication => 'Git प्रमाणीकरण विफल रहा।';

  @override
  String get gitErrorNetwork => 'Git नेटवर्क कार्रवाई विफल रही।';

  @override
  String get gitErrorConflict => 'Git ने अनसुलझे टकराव रिपोर्ट किए।';

  @override
  String get gitErrorCommandFailed => 'Git कमांड विफल रहा।';

  @override
  String get syntaxReference => 'सिंटैक्स संदर्भ';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown ब्लॉक';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown स्रोत और प्रीव्यू में समर्थित ब्लॉक संरचनाएँ।';

  @override
  String get syntaxReferenceInlineFormatting => 'इनलाइन Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'ऐसी फ़ॉर्मैटिंग जिसे पैराग्राफ़, सूची आइटम और तालिका सेल के अंदर इस्तेमाल किया जा सकता है।';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'कच्चे HTML ब्लॉक';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'सुरक्षित ब्लॉक-स्तर HTML टैग जिन्हें BusyMark प्रीव्यू विजेट से दिखाया जाता है।';

  @override
  String get syntaxReferenceRawHtmlInline => 'इनलाइन HTML टैग';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'सुरक्षित इनलाइन HTML टैग जिन्हें शाब्दिक टैग दिखाए बिना रेंडर किया जाता है।';

  @override
  String get syntaxReferenceHeadings => 'शीर्षक';

  @override
  String get syntaxReferenceParagraphs => 'पैराग्राफ';

  @override
  String get syntaxReferenceLists => 'सूचियाँ';

  @override
  String get syntaxReferenceHtmlContainers => 'कंटेनर';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'टेक्स्ट ब्लॉक';

  @override
  String get syntaxReferenceHtmlFigures => 'फ़िगर और चित्र';

  @override
  String get syntaxReferenceHtmlPreformatted => 'पूर्व-स्वरूपित कोड';

  @override
  String get syntaxReferenceHtmlDisclosure => 'खुलने वाले ब्लॉक';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'विवरण सूचियाँ';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'फ़ॉर्मैटिंग टैग';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'इनलाइन कोड टैग';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'अर्थपूर्ण टेक्स्ट टैग';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'अनुमत HTML को BusyMark प्रीव्यू ब्लॉक में बदला जाता है, ब्राउज़र में रेंडर नहीं किया जाता।';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'असंपादित कच्चे HTML को ठीक उसी तरह स्रोत टेक्स्ट के रूप में सहेजा जाता है।';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'कच्चे HTML के अंदर Markdown चिह्न शाब्दिक टेक्स्ट की तरह दिखते हैं।';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'स्क्रिप्ट, स्टाइल, फ़्रेम, फ़ॉर्म, SVG, MathML, इवेंट और असुरक्षित एट्रिब्यूट अवरुद्ध किए जाते हैं।';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'लिंक http, https, mailto, tel, सापेक्ष URL और फ़्रैगमेंट स्वीकार करते हैं; असुरक्षित स्कीमें अवरुद्ध की जाती हैं।';

  @override
  String get syntaxReferenceCategory => 'श्रेणी';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'आरेख और API';

  @override
  String get syntaxReferenceCategoryMathematics => 'गणित';

  @override
  String get syntaxReferenceExample => 'उदाहरण';

  @override
  String get syntaxReferenceIdentifiers => 'पहचानकर्ता और उपनाम';

  @override
  String get syntaxReferenceScope => 'दायरा';

  @override
  String get syntaxReferenceLimitation => 'BusyMark की सीमा';

  @override
  String get syntaxReferenceOfficialDocumentation => 'आधिकारिक दस्तावेज़';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'केवल Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'केवल Writerside Markdown और Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'मुख्य Markdown रूप जिन्हें BusyMark लिख और पूर्वावलोकित कर सकता है।';

  @override
  String get syntaxReferenceParagraphExample => 'पाठ का एक अनुच्छेद।';

  @override
  String get syntaxReferenceTableLimitation =>
      'तालिकाएँ GitHub Flavored Markdown की पाइप सिंटैक्स का उपयोग करती हैं।';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'पंक्ति के अंत में दो रिक्तियाँ, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark, Markdown स्रोत में कच्चे HTML का सीमित और सुरक्षित उपसमुच्चय स्वीकार करता है।';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'बाड़ वाले Mermaid, PlantUML, D2 और OpenAPI ब्लॉक Markdown स्रोत में काम करते हैं। बाड़ पहचानकर्ता अक्षर केस से स्वतंत्र हैं और BusyMark मूल वर्तनी सुरक्षित रखता है।';

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
      'बाड़ वाला YAML या JSON सामग्री उपयोग करें। BusyMark किसी भी पूरे YAML या JSON दस्तावेज़ को OpenAPI संदर्भ नहीं मानता।';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'आरेखों के लिए सिमैंटिक कोड ब्लॉक';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'सिमैंटिक code-block और src रूप Mermaid, PlantUML और D2 का समर्थन करते हैं, OpenAPI का नहीं, और केवल Writerside परियोजनाओं में काम करते हैं।';

  @override
  String get syntaxReferenceReferencedDiagramSource => 'संदर्भित आरेख स्रोत';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'पथ सापेक्ष होने चाहिए और खुले Writerside प्रोजेक्ट के भीतर रहने चाहिए; बाड़ के साथ src वाला रूप केवल Writerside Markdown के लिए है।';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark TeX व्यंजकों का समर्थन करता है, पूर्ण TeX या LaTeX दस्तावेज़ों का नहीं।';

  @override
  String get syntaxReferenceInlineMath => 'इनलाइन गणित';

  @override
  String get syntaxReferenceGithubMath => 'डॉलर और बैकटिक वाला GitHub गणित';

  @override
  String get syntaxReferenceDisplayMath => 'प्रदर्शित गणित';

  @override
  String get syntaxReferenceMathFence => 'math बाड़';

  @override
  String get syntaxReferenceTexFence => 'tex बाड़';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark \\(...\\) या \\[...\\] को Markdown गणित सीमांकक नहीं मानता।';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Writerside मोड के बाहर tex बाड़ सामान्य कोड ब्लॉक ही रहता है।';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside math तत्व';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math तत्व सिमैंटिक Writerside सिंटैक्स है, अनुमत कच्चा HTML MathML नहीं।';

  @override
  String get syntaxReferenceSemanticTexBlock => 'सिमैंटिक TeX कोड ब्लॉक';

  @override
  String get syntaxReferenceWritersideDescription =>
      'ये केंद्रित एक्सटेंशन केवल खुले Writerside प्रोजेक्ट में समझे जाते हैं।';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'सूचना ब्लॉककोट';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'सादा ब्लॉककोट Writerside Markdown में सुझाव होता है; सामान्य Markdown में वह सामान्य उद्धरण ही रहता है।';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'सिमैंटिक सूचनाएँ';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'सामान्य Markdown इन सिमैंटिक Writerside तत्वों को नहीं समझता।';

  @override
  String get syntaxReferenceCollapsibleHeading => 'सिकोड़ा जा सकने वाला शीर्षक';

  @override
  String get syntaxReferenceCollapsibleCode => 'सिकोड़ा जा सकने वाला कोड बाड़';

  @override
  String get syntaxReferenceSemanticCollapsibles => 'सिमैंटिक संकुचित सामग्री';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark सिकोड़े जा सकने वाले chapter, procedure, code-block और परिभाषा-सूची रूपों का समर्थन करता है, पूरे Writerside कैटलॉग का नहीं।';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'गणित और आरेखों के लिए सिमैंटिक कोड ब्लॉक';

  @override
  String get syntaxReferenceVideo => 'Writerside वीडियो';

  @override
  String get syntaxReferenceVideoLimitation =>
      'स्थानीय वीडियो स्थानीय preview-src चित्र उपयोग करता है; होस्ट किए गए स्रोत समर्थित YouTube या Vimeo HTTPS URL होने चाहिए।';

  @override
  String get exportAsPdf => 'PDF के रूप में निर्यात करें';

  @override
  String get pdfExportDescription =>
      'सुंदर और स्व-निहित PDF के लिए पृष्ठ लेआउट चुनें।';

  @override
  String get pdfRemoteImagesNote =>
      'निर्यात के दौरान दूरस्थ चित्र डाउनलोड नहीं किए जाते। उपलब्ध स्थानीय चित्र शामिल किए जाते हैं।';

  @override
  String get pdfPageSize => 'पृष्ठ आकार';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'लेटर';

  @override
  String get pdfOrientation => 'दिशा';

  @override
  String get pdfPortrait => 'पोर्ट्रेट';

  @override
  String get pdfLandscape => 'लैंडस्केप';

  @override
  String get pdfMargins => 'हाशिए';

  @override
  String get pdfMarginNarrow => 'संकीर्ण';

  @override
  String get pdfMarginNormal => 'सामान्य';

  @override
  String get pdfMarginWide => 'चौड़े';

  @override
  String get pdfIncludePageNumbers => 'पृष्ठ संख्याएँ शामिल करें';

  @override
  String get export => 'निर्यात करें';

  @override
  String get exportingPdf => 'PDF निर्यात हो रहा है…';

  @override
  String get fileTypePdf => 'PDF दस्तावेज़';

  @override
  String pdfExported(String fileName) {
    return '$fileName निर्यात किया गया।';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चेतावनियों',
      one: '1 चेतावनी',
    );
    return '$fileName को $_temp0 के साथ निर्यात किया गया.';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF निर्यात घटक उपलब्ध नहीं है। BusyMark को फिर स्थापित करके दोबारा प्रयास करें।';

  @override
  String get pdfExportTimedOut =>
      'PDF निर्यात में बहुत समय लगा और इसे रोक दिया गया।';

  @override
  String get pdfExportFailed =>
      'BusyMark इस दस्तावेज़ को PDF के रूप में निर्यात नहीं कर सका।';

  @override
  String get visualizationRendering => 'रेंडर हो रहा है…';

  @override
  String get visualizationStale => 'अंतिम मान्य रेंडर दिखाया जा रहा है';

  @override
  String get visualizationShowSource => 'स्रोत दिखाएँ';

  @override
  String get visualizationShowRender => 'रेंडर दिखाएँ';

  @override
  String get visualizationFitWidth => 'चौड़ाई के अनुसार फ़िट करें';

  @override
  String get visualizationSaveImage => 'चित्र सहेजें';

  @override
  String get visualizationCopyImage => 'चित्र कॉपी करें';

  @override
  String get visualizationImageCopied => 'चित्र कॉपी किया गया';

  @override
  String get visualizationOpenApiReference => 'API संदर्भ खोलें';

  @override
  String get visualizationValid => 'मान्य';

  @override
  String get visualizationInvalid => 'अमान्य';

  @override
  String get visualizationServers => 'सर्वर';

  @override
  String get visualizationPaths => 'पाथ';

  @override
  String get visualizationOperations => 'ऑपरेशन';

  @override
  String get visualizationTags => 'टैग';

  @override
  String get visualizationNoOperations => 'कोई मेल खाता ऑपरेशन नहीं';

  @override
  String get visualizationSearchOperations => 'ऑपरेशन खोजें';

  @override
  String get visualizationRenderFailed =>
      'इस विज़ुअलाइज़ेशन को रेंडर नहीं किया जा सका।';

  @override
  String get visualizationRetry => 'फिर प्रयास करें';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName सहेजा गया';
  }

  @override
  String get shortcutExportPdfDescription =>
      'सक्रिय दस्तावेज़ या Writerside मॉड्यूल को PDF के रूप में निर्यात करें।';

  @override
  String get instances => 'इंस्टेंस';

  @override
  String get newInstance => 'नया इंस्टेंस';

  @override
  String get newTocLibrary => 'नई विषय-सूची लाइब्रेरी';

  @override
  String get editInstance => 'इंस्टेंस संपादित करें';

  @override
  String get openTocFile => 'विषय-सूची फ़ाइल खोलें';

  @override
  String get createInstance => 'इंस्टेंस बनाएँ';

  @override
  String get createTocLibrary => 'विषय-सूची लाइब्रेरी बनाएँ';

  @override
  String get instanceContent => 'सामग्री';

  @override
  String get instanceContentSource => 'इससे बनाएँ';

  @override
  String get emptyInstance => 'खाली इंस्टेंस';

  @override
  String get markdownFiles => 'स्थानीय Markdown फ़ाइलें';

  @override
  String get chooseMarkdownFolder => 'Markdown फ़ोल्डर चुनें';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Markdown फ़ाइलों वाला फ़ोल्डर चुनें।';

  @override
  String get instanceAppearance => 'रूप-रंग';

  @override
  String get instanceColor => 'आइकन का रंग';

  @override
  String get instanceVersion => 'संस्करण';

  @override
  String instanceVersionInherited(String version) {
    return 'यह फ़ील्ड खाली होने पर प्रोजेक्ट का संस्करण $version है।';
  }

  @override
  String get instanceWebPath => 'वेब पथ';

  @override
  String get instanceStatus => 'स्थिति';

  @override
  String get instanceStatusRelease => 'रिलीज़';

  @override
  String get instanceStatusEap => 'प्रारंभिक पहुँच';

  @override
  String get instanceStatusDeprecated => 'अप्रचलित';

  @override
  String get allowSearchEngineIndexing => 'सर्च इंजन इंडेक्सिंग की अनुमति दें';

  @override
  String get allowSearchEngineIndexingDescription =>
      'बाहरी सर्च इंजनों को इस आउटपुट को इंडेक्स करने दें।';

  @override
  String get offlineArtifact => 'ऑफ़लाइन पैकेज';

  @override
  String get offlineArtifactDescription =>
      'संसाधनों को बंडल करें ताकि बनाई गई दस्तावेज़ीकरण सामग्री आत्मनिर्भर हो।';

  @override
  String get instanceOutputSettings => 'आउटपुट सेटिंग';

  @override
  String get markdownImportSource => 'Markdown स्रोत';

  @override
  String get markdownImportFiles => 'Markdown फ़ाइलें';

  @override
  String get selectNone => 'सभी का चयन हटाएँ';

  @override
  String markdownFilesFound(int count) {
    return '$count Markdown फ़ाइल मिलीं';
  }

  @override
  String get noMarkdownFilesFound =>
      'इस डायरेक्टरी में कोई Markdown फ़ाइल नहीं मिली।';

  @override
  String get copyReferencedMedia => 'संदर्भित मीडिया कॉपी करें';

  @override
  String get copyReferencedMediaDescription =>
      'चुनी गई फ़ाइलों में संदर्भित स्थानीय चित्र और वीडियो कॉपी करें और सापेक्ष पथ बनाए रखें।';

  @override
  String get instanceIdRenameWarningTitle => 'इंस्टेंस ID का नाम बदलें?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark .tree फ़ाइल का नाम बदलेगा और Writerside प्रोजेक्ट संदर्भों को “$oldId” से “$newId” में अपडेट करेगा। प्रकाशन स्क्रिप्ट नहीं बदली जाएँगी और उन्हें अलग से अपडेट करना होगा।';
  }

  @override
  String get renameAndUpdateReferences => 'नाम बदलें और संदर्भ अपडेट करें';

  @override
  String get tocLibraryDescription =>
      'विषय-सूची लाइब्रेरी पुनः उपयोग योग्य अनुभाग संग्रहीत करती है और अपना अलग आउटपुट नहीं बनाती।';

  @override
  String get defaultTocLibraryName => 'साझा विषय-सूची';

  @override
  String get instanceColorAutomatic => 'स्वचालित';

  @override
  String get instanceColorBlue => 'नीला';

  @override
  String get instanceColorGreen => 'हरा';

  @override
  String get instanceColorOrange => 'नारंगी';

  @override
  String get instanceColorPurple => 'बैंगनी';

  @override
  String get instanceColorRed => 'लाल';

  @override
  String get instanceColorTeal => 'हरिनील';

  @override
  String get instanceColorYellow => 'पीला';

  @override
  String get errorWritersideInstanceNameRequired =>
      'इंस्टेंस का नाम दर्ज करें।';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return '“$id” ID वाला इंस्टेंस पहले से मौजूद है।';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'इंस्टेंस ट्री पहले से मौजूद है: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown स्रोत डायरेक्टरी मौजूद नहीं है: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'आयात करने के लिए कम से कम एक Markdown फ़ाइल चुनें।';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'यह चुने गए स्रोत के भीतर पढ़ी जा सकने वाली Markdown फ़ाइल नहीं है: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'आयात करने पर मौजूदा प्रोजेक्ट फ़ाइल ओवरराइट हो जाएगी: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'डिस्क पर इंस्टेंस फ़ाइलें बदल गई हैं। उनकी समीक्षा करें और फिर से प्रयास करें।';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark इंस्टेंस बदलाव को पूरी तरह वापस नहीं कर सका। आगे बढ़ने से पहले इन फ़ाइलों की समीक्षा करें: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'विषय-सूची लाइब्रेरी Markdown विषय आयात नहीं कर सकती।';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'वेब पथ एक ही पंक्ति में होना चाहिए।';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside इंस्टेंस कॉन्फ़िगरेशन अमान्य है। इसके निदान सुधारें और फिर से प्रयास करें।';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark इंस्टेंस बदलाव सुरक्षित रूप से तैयार नहीं कर सका।';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'अज्ञात इंस्टेंस स्थिति “$status”। release, eap या deprecated का उपयोग करें।';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'इंस्टेंस ID “$id” एक से अधिक ट्री फ़ाइलों द्वारा उपयोग की गई है।';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml में मूल एलिमेंट <buildprofiles> होना चाहिए।';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name का मान “$value” true या false होना चाहिए।';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> एलिमेंट में इंस्टेंस ID निर्दिष्ट होनी चाहिए।';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'ट्री <include> में from और element-id दोनों निर्दिष्ट होने चाहिए।';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'ट्री <snippet> में id निर्दिष्ट होनी चाहिए।';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'क्रॉस-इंस्टेंस विषय-सूची संदर्भ में ref और in दोनों निर्दिष्ट होने चाहिए।';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'विषय-सूची एलिमेंट एक से अधिक विषय, संदर्भ, लिंक या रीडायरेक्ट को लक्षित नहीं कर सकता।';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ट्री एलिमेंट ID “$id” एक से अधिक बार घोषित की गई है।';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'इंस्टेंस समूह फ़ाइल में मूल एलिमेंट <instance-groups> होना चाहिए।';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'इंस्टेंस समूह में गैर-रिक्त id और इंस्टेंस सूची निर्दिष्ट होनी चाहिए।';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'इंस्टेंस समूह ID “$id” एक से अधिक बार घोषित की गई है।';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'विषय-सूची समावेशन “$source#$id” बाहरी मॉड्यूल “$origin” का है और इसे इस कार्यस्थान में विस्तृत नहीं किया जा सकता।';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'ट्री एलिमेंट “$id” पंजीकृत ट्री “$source” में मौजूद नहीं है।';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'ट्री समावेशन “$source#$id” चक्र बनाता है।';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'इंस्टेंस शर्त अज्ञात समूह “@$group” का संदर्भ देती है।';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'क्रॉस-इंस्टेंस संदर्भ अज्ञात इंस्टेंस “$instance” को लक्षित करता है।';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'विषय “$topic” संदर्भित इंस्टेंस “$instance” में नहीं है।';
  }

  @override
  String get download => 'डाउनलोड करें';

  @override
  String get exportWritersideAsPdf =>
      'Writerside को PDF के रूप में निर्यात करें';

  @override
  String get writersidePdfContent => 'निर्यात सामग्री';

  @override
  String get writersidePdfPage => 'पृष्ठ';

  @override
  String get exportingWritersidePdf => 'Writerside PDF निर्यात हो रहा है…';

  @override
  String get ai => 'एआई';

  @override
  String get aiLocalOllama => 'स्थानीय Ollama';

  @override
  String get aiDisabled => 'अक्षम';

  @override
  String get aiExplicitEditingDescription =>
      'AI संपादन केवल स्पष्ट कार्रवाई से शुरू होता है। BusyMark चयनित प्रदाता को केवल दिखाया गया संदर्भ भेजता है और समीक्षा के बिना किसी प्रस्ताव को लागू नहीं करता।';

  @override
  String get aiProvider => 'एआई प्रदाता';

  @override
  String get aiDefaultProvider => 'डिफ़ॉल्ट प्रदाता';

  @override
  String get aiConfigureProvider => 'प्रदाता कॉन्फ़िगर करें';

  @override
  String get aiChooseProvider => 'एआई प्रदाता चुनें';

  @override
  String get aiOllamaEndpoint => 'Ollama एंडपॉइंट';

  @override
  String get aiOllamaModel => 'Ollama मॉडल';

  @override
  String get aiTestConnection => 'कनेक्शन जाँचें';

  @override
  String get aiTestingConnection => 'जाँच जारी…';

  @override
  String aiConnectionReady(int count) {
    return 'कनेक्ट हो गया। $count इंस्टॉल किए गए मॉडल मिले।';
  }

  @override
  String get aiNoModels => 'कोई मॉडल नहीं चुना गया।';

  @override
  String get aiConnectionFailed =>
      'BusyMark AI टेक्स्ट जनरेशन को सत्यापित नहीं कर सका।';

  @override
  String get aiConfigureFirst =>
      'पहले सेटिंग्स → AI में किसी AI प्रदाता को सक्षम करें और मॉडल सत्यापित करें।';

  @override
  String get aiEditWithAi => 'AI से संपादित करें';

  @override
  String get aiRefineWithAi => 'AI से बेहतर बनाएँ';

  @override
  String get aiInstruction => 'निर्देश';

  @override
  String get aiChangeTarget => 'क्या बदला जा सकता है';

  @override
  String get aiSharedContext => 'AI के साथ साझा संदर्भ';

  @override
  String get aiTargetSelection => 'चयनित सामग्री';

  @override
  String get aiTargetInsertAfterBlock => 'वर्तमान ब्लॉक के बाद डालें';

  @override
  String get aiTargetCurrentBlock => 'वर्तमान ब्लॉक';

  @override
  String get aiTargetCurrentSection => 'वर्तमान अनुभाग';

  @override
  String get aiTargetCompleteDocument => 'पूरा दस्तावेज़';

  @override
  String get aiContextNone => 'कोई दस्तावेज़ संदर्भ नहीं';

  @override
  String get aiContextSelection => 'चयनित सामग्री';

  @override
  String get aiContextCurrentBlock => 'वर्तमान ब्लॉक';

  @override
  String get aiContextCurrentSection => 'वर्तमान अनुभाग';

  @override
  String get aiContextCompleteDocument => 'पूरा दस्तावेज़';

  @override
  String get aiGenerating => 'सुझाव बनाया जा रहा है…';

  @override
  String get aiProposal => 'एआई सुझाव';

  @override
  String get aiGenerateProposal => 'प्रस्ताव बनाएँ';

  @override
  String aiContextDisclosure(int count) {
    return 'चयनित प्रदाता को दिखाए गए संदर्भ के $count वर्ण मिलेंगे।';
  }

  @override
  String get aiOriginal => 'मूल टेक्स्ट';

  @override
  String get aiSuggested => 'सुझाया गया टेक्स्ट';

  @override
  String get aiApplyProposal => 'सुझाव लागू करें';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input इनपुट टोकन · $output आउटपुट टोकन';
  }

  @override
  String get aiStaleProposal =>
      'यह सुझाव बनते समय दस्तावेज़ बदल गया। क्रिया फिर से चलाएँ।';

  @override
  String get gitAiStagedChangesChanged =>
      'यह कमिट संदेश बनते समय स्टेज किए गए बदलाव बदल गए। क्रिया फिर से चलाएँ।';

  @override
  String get aiViewContext => 'भेजा गया संदर्भ देखें';

  @override
  String get aiReviewExactContent => 'सटीक सामग्री की समीक्षा करें';

  @override
  String get aiContentToChange => 'बदली जाने वाली सामग्री';

  @override
  String get aiContentSentToAi => 'AI को भेजी गई सामग्री';

  @override
  String get aiApiKey => 'API कुंजी';

  @override
  String get aiApiKeyStoredHint =>
      'एक कुंजी सिस्टम क्रेडेंशियल स्टोर में सुरक्षित है';

  @override
  String get aiApiKeyEnterHint => 'प्रदाता की API कुंजी दर्ज करें';

  @override
  String get aiReplaceApiKey => 'API कुंजी बदलें';

  @override
  String get aiSaveApiKey => 'API कुंजी सुरक्षित रूप से सहेजें';

  @override
  String get aiRemoveApiKey => 'सहेजी गई API कुंजी हटाएँ';

  @override
  String get aiCredentialSaved =>
      'API कुंजी सिस्टम क्रेडेंशियल स्टोर में सहेजी गई।';

  @override
  String get aiCredentialRemoved => 'सहेजी गई API कुंजी हटा दी गई।';

  @override
  String get aiModelRouting => 'मॉडल चयन';

  @override
  String get aiAutomaticRouting => 'कार्य के अनुसार स्वचालित';

  @override
  String get aiFixedModelRouting => 'चयनित मॉडल का उपयोग करें';

  @override
  String get aiPreferredModel => 'पसंदीदा मॉडल';

  @override
  String get aiModel => 'मॉडल';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests अनुरोध · $input इनपुट टोकन · $output आउटपुट टोकन';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'सामग्री $provider को भेजें?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '$provider सक्षम करें';
  }

  @override
  String get aiCloudConsentMessage =>
      'केवल प्रत्येक AI समीक्षा संवाद में दिखाई गई सामग्री भेजी जाती है। अनुरोध स्टेटलेस होते हैं, प्रस्तावों की समीक्षा आवश्यक होती है और API कुंजी Linux सिस्टम क्रेडेंशियल स्टोर में सुरक्षित रहती है।';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'पहले सेटिंग्स → AI में $provider के साथ डेटा साझा करने की पुष्टि करें।';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '$model के साथ जनरेशन सत्यापित हुआ। $count संगत मॉडल उपलब्ध हैं।';
  }

  @override
  String get aiColdStartObserved => 'स्थानीय मॉडल का कोल्ड स्टार्ट पाया गया।';

  @override
  String get aiNoCompatibleModels =>
      'कोई संगत टेक्स्ट-जनरेशन मॉडल उपलब्ध नहीं है।';

  @override
  String get aiEnableProvider => 'पहले किसी AI प्रदाता को सक्षम करें।';

  @override
  String get aiDraftCommitMessage => 'कमिट संदेश का मसौदा बनाएँ';

  @override
  String get aiDrafting => 'मसौदा बनाया जा रहा है…';

  @override
  String get aiDraftWithAi => 'AI से मसौदा बनाएँ';

  @override
  String get generateOrUpdateMarkdownToc => 'विषय-सूची बनाएँ/अपडेट करें';

  @override
  String get markdownTocTitle => 'विषय-सूची';

  @override
  String markdownTocUpdated(int count) {
    return 'विषय-सूची $count प्रविष्टियों के साथ अपडेट हुई।';
  }

  @override
  String get markdownTocNoHeadings =>
      'विषय-सूची बनाने से पहले कम-से-कम एक अनुभाग शीर्षक जोड़ें।';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMark विषय-सूची मार्कर अनुपस्थित, डुप्लिकेट या गलत क्रम में हैं।';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'स्तर $level का शीर्षक स्तर $previousLevel के बाद है; अनुभागों का नेस्टिंग जाँचें।';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'लिंक टेक्स्ट खाली है; उसके उद्देश्य का वर्णन करने वाला सुलभ नाम दें।';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'जाँचें कि लिंक टेक्स्ट “$text” संदर्भ में उसके उद्देश्य का वर्णन करता है या नहीं।';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'तालिका शीर्षकों को अपने कॉलम पहचानने चाहिए; हर खाली शीर्षक पूरा करें।';

  @override
  String get mathRenderFailed => 'गणितीय व्यंजक रेंडर नहीं किया जा सका।';

  @override
  String get inlineMath => 'इनलाइन गणित';

  @override
  String get displayMath => 'डिस्प्ले गणित';

  @override
  String get goToDeclaration => 'Go to Declaration';

  @override
  String get findUsages => 'Find Usages';

  @override
  String get cannotRenameSymbol =>
      'The symbol cannot be renamed safely. Check the name and refresh the reference before trying again.';

  @override
  String get keyboardLayout => 'Keyboard layout';

  @override
  String get diagnosticWritersideUnsupported =>
      'Unsupported or malformed content is displayed as source.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Cannot resolve source “$reference”: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Link target is unavailable in this instance: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Invalid Writerside markup: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Use <llms-txt>true</llms-txt> or <llms-txt>false</llms-txt>; single-file is no longer supported.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Cannot resolve $kind: $reference';
  }
}
