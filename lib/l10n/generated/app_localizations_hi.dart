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
  String get promoteHeading => 'शीर्षक को ऊपर करें';

  @override
  String get demoteHeading => 'शीर्षक को नीचे करें';

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
  String get preview => 'पूर्वावलोकन';

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
  String get shortcutNewDocument => 'नया दस्तावेज़';

  @override
  String get shortcutNewDocumentDescription =>
      'नया, सहेजा न गया Markdown दस्तावेज़ बनाएँ';

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
  String get shortcutMarkdownAndHtmlDescription =>
      'Markdown और HTML संदर्भ खोलें';

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
    return '“$topic” को चुने गए सहायता इंस्टेंस से हटाएँ। विषय फ़ाइल रखी जाएगी।';
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
  String get sourceSearchInvalidRegex => 'अमान्य रेगुलर एक्सप्रेशन';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'बड़ी फ़ाइल: हाइलाइटिंग और फ़ोल्डिंग अस्थायी रूप से रुकी हुई हैं';

  @override
  String get noPreview => 'कोई पूर्वावलोकन नहीं';

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
      'Writerside मॉड्यूल में कोई हेल्प इंस्टेंस ट्री नहीं है।';

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
  String get gitBranchActions => 'शाखा संबंधी कार्रवाइयाँ';

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
  String get gitNewBranch => '+ नई शाखा';

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
      other: 'चयनित ट्रैक की गई फ़ाइलें Git से पुनर्स्थापित की जाएँगी।',
      one: 'चयनित ट्रैक की गई फ़ाइल Git से पुनर्स्थापित की जाएगी।',
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
  String get gitProjectHistory => 'प्रोजेक्ट';

  @override
  String get gitFileHistory => 'मौजूदा फ़ाइल';

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
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'फ़ाइल कार्रवाइयाँ';

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
  String get gitErrorRestoreStagedFile =>
      'पिछला संस्करण पुनर्स्थापित करने से पहले फ़ाइल को अनस्टेज करें।';

  @override
  String get gitErrorDiverged =>
      'शाखा अलग हो गई है। इस BusyMark संस्करण के बाहर मर्ज या रीबेस करके इसे सुलझाएँ।';

  @override
  String get gitErrorAuthentication =>
      'Git प्रमाणीकरण विफल रहा। snap में SSH रिमोट के लिए ssh-keys इंटरफ़ेस कनेक्ट करना पड़ सकता है।';

  @override
  String get gitErrorNetwork => 'Git नेटवर्क कार्रवाई विफल रही।';

  @override
  String get gitErrorConflict => 'Git ने अनसुलझे टकराव रिपोर्ट किए।';

  @override
  String get gitErrorCommandFailed => 'Git कमांड विफल रहा।';

  @override
  String get markdownAndHtml => 'Markdown और HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown ब्लॉक';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Markdown स्रोत और प्रीव्यू में समर्थित ब्लॉक संरचनाएँ।';

  @override
  String get markdownHtmlInlineFormatting => 'इनलाइन Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'ऐसी फ़ॉर्मैटिंग जिसे पैराग्राफ़, सूची आइटम और तालिका सेल के अंदर इस्तेमाल किया जा सकता है।';

  @override
  String get markdownHtmlRawHtmlBlocks => 'कच्चे HTML ब्लॉक';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'सुरक्षित ब्लॉक-स्तर HTML टैग जिन्हें BusyMark प्रीव्यू विजेट से दिखाया जाता है।';

  @override
  String get markdownHtmlRawHtmlInline => 'इनलाइन HTML टैग';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'सुरक्षित इनलाइन HTML टैग जिन्हें शाब्दिक टैग दिखाए बिना रेंडर किया जाता है।';

  @override
  String get markdownHtmlSafety => 'सुरक्षा नियम';

  @override
  String get markdownHtmlSafetyDescription =>
      'कच्चे HTML को प्रीव्यू से पहले पार्स और साफ़ किया जाता है।';

  @override
  String get markdownHtmlHeadings => 'शीर्षक';

  @override
  String get markdownHtmlParagraphs => 'पैराग्राफ';

  @override
  String get markdownHtmlLists => 'सूचियाँ';

  @override
  String get markdownHtmlHtmlContainers => 'कंटेनर';

  @override
  String get markdownHtmlHtmlTextBlocks => 'टेक्स्ट ब्लॉक';

  @override
  String get markdownHtmlHtmlFigures => 'फ़िगर और चित्र';

  @override
  String get markdownHtmlHtmlPreformatted => 'पूर्व-स्वरूपित कोड';

  @override
  String get markdownHtmlHtmlDisclosure => 'खुलने वाले ब्लॉक';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'विवरण सूचियाँ';

  @override
  String get markdownHtmlHtmlFormattingTags => 'फ़ॉर्मैटिंग टैग';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'इनलाइन कोड टैग';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'अर्थपूर्ण टेक्स्ट टैग';

  @override
  String get markdownHtmlSanitizedPreview => 'साफ़ किया गया प्रीव्यू';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'अनुमत HTML को BusyMark प्रीव्यू ब्लॉक में बदला जाता है, ब्राउज़र में रेंडर नहीं किया जाता।';

  @override
  String get markdownHtmlSourcePreserved => 'स्रोत सुरक्षित रहता है';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'असंपादित कच्चे HTML को ठीक उसी तरह स्रोत टेक्स्ट के रूप में सहेजा जाता है।';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'HTML के अंदर Markdown';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'कच्चे HTML के अंदर Markdown चिह्न शाब्दिक टेक्स्ट की तरह दिखते हैं।';

  @override
  String get markdownHtmlBlockedContent => 'सक्रिय सामग्री अवरुद्ध';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'स्क्रिप्ट, स्टाइल, फ़्रेम, फ़ॉर्म, SVG, MathML, इवेंट और असुरक्षित एट्रिब्यूट अवरुद्ध किए जाते हैं।';

  @override
  String get markdownHtmlSafeUrls => 'केवल सुरक्षित URL';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'लिंक http, https, mailto, tel, सापेक्ष URL और फ़्रैगमेंट स्वीकार करते हैं; असुरक्षित स्कीमें अवरुद्ध की जाती हैं।';

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
    return '$fileName निर्यात किया गया। शामिल न हो सकने वाले चित्र: $count।';
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
      'सक्रिय Markdown दस्तावेज़ को PDF के रूप में निर्यात करें।';
}
