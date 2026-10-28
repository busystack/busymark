// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'सहेजे गए पाठ से नया नोट';

  @override
  String get notesAccountThrottled =>
      'Nextcloud ने विराम माँगा है। फिर साइन इन शुरू करने से पहले प्रतीक्षा करें।';

  @override
  String get notesSettingsRefreshing =>
      'पुष्टि किए गए सेटिंग बदलाव के बाद Notes ताज़ा हो रहा है';

  @override
  String get notesExportOperationFailed =>
      'प्रकाशन से पहले निर्यात विफल हुआ। स्रोत और गंतव्य जाँचकर फिर निर्यात करें।';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'पुनर्प्राप्त नोट सहेजा गया, पर खुल नहीं सका। संपादक या गुणों के लंबित बदलाव सुलझाएँ, फिर इसी मौजूदा नोट को खोलें।';

  @override
  String get notesSettingsPendingNotes =>
      'लंबित नोट, विरोध या अनिश्चित निर्माण इस बदलाव को रोक रहे हैं। Notes में समन्वय या समीक्षा करें, फिर सुरक्षित रखा गया सेटिंग मसौदा दोबारा सहेजें।';

  @override
  String get notesSettingsPendingAttachments =>
      'लंबित संलग्नक कार्य इस बदलाव को रोक रहे हैं। Notes में संलग्नकों की समीक्षा करें, फिर सुरक्षित रखा गया सेटिंग मसौदा दोबारा सहेजें।';

  @override
  String get notesAccountServerAddress =>
      'Nextcloud का मानक HTTPS पता उपयोग करें और फिर साइन इन करें। पते या रीडायरेक्ट की पुष्टि नहीं हो सकी।';

  @override
  String get notesAccountUnsupported =>
      'Notes उपलब्ध नहीं है या API समर्थित नहीं है। मुख्य API संस्करण 1 और गौण संस्करण 4 या नए वाला Nextcloud Notes सक्षम करें।';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud ने पहचान जानकारी अस्वीकार की। खाते को फिर अधिकृत करें या दोबारा कनेक्ट करें।';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud ने Notes क्षमता जाँच की अनुमति नहीं दी। व्यवस्थापक से अनुमति लेकर फिर प्रयास करें।';

  @override
  String get notesAccountMalformed =>
      'Nextcloud के उत्तर की पुष्टि नहीं हो सकी। सर्वर स्थापना जाँचें और फिर साइन इन करें।';

  @override
  String get notesAccountTimedOut =>
      'साइन इन का समय समाप्त हुआ। फिर शुरू करें और ब्राउज़र में अनुमति पूरी करें।';

  @override
  String get notesAccountBrowserUnavailable =>
      'सिस्टम ब्राउज़र नहीं खुल सका। डिफ़ॉल्ट ब्राउज़र जाँचें और फिर साइन इन करें।';

  @override
  String get notesAccountNetwork =>
      'Nextcloud से संपर्क नहीं हो सका। कनेक्शन और सर्वर जाँचें, फिर साइन इन करें।';

  @override
  String get notesAccountRejected =>
      'Nextcloud ने क्षमता अनुरोध अस्वीकार किया। व्यवस्थापक के साथ पहुँच जाँचकर फिर प्रयास करें।';

  @override
  String get notesAccountFailed =>
      'खाता सेटअप पूरा नहीं हुआ। फिर साइन इन करें।';

  @override
  String get notesTransferSourceChanged =>
      'समीक्षा के बाद स्रोत बदल गया। फिर प्रयास से पहले मौजूदा फ़ाइल की समीक्षा करें या नया स्नैपशॉट लें।';

  @override
  String get notesTransferUnreadable =>
      'स्रोत पढ़ा नहीं जा सका। फ़ाइल या फ़ोल्डर की पहुँच जाँचकर फिर समीक्षा करें।';

  @override
  String get notesTransferInvalidSnapshot =>
      'स्नैपशॉट अमान्य या असमर्थित है। मान्य BusyMark Notes स्नैपशॉट या Markdown स्रोत चुनें।';

  @override
  String get notesTransferMediaLimit =>
      'मीडिया आयात आकार सीमा से बड़ा है। प्रभावित आइटम का मीडिया छोटा करके फिर समीक्षा करें।';

  @override
  String get notesTransferUnsafeSource =>
      'स्रोत में असुरक्षित पथ है। स्रोत फ़ोल्डर के अंदर की फ़ाइलें चुनकर फिर समीक्षा करें।';

  @override
  String get notesTransferDestination =>
      'निर्यात लिखा नहीं जा सका। गंतव्य की पहुँच और खाली स्थान जाँचकर फिर निर्यात करें।';

  @override
  String get notesTransferOperationFailed =>
      'स्थानांतरण पूरा नहीं हुआ। प्रभावित आइटम की समीक्षा करके फिर प्रयास करें। पहले आयात किए आइटम सहेजे हुए हैं।';

  @override
  String get notesExportPublishedWithOmissions =>
      'कुछ चीज़ें छूटी हैं, निर्यात उपलब्ध है';

  @override
  String get notesBatchUnchanged => 'माँगे गए मान पहले से तय हैं।';

  @override
  String get notesBatchReadOnly =>
      'यह नोट केवल पढ़ने योग्य है। सुरक्षित गुण नहीं बदल सकते; पसंदीदा स्थिति बदलना अनुमत है।';

  @override
  String get notesBatchReviewChanged =>
      'समीक्षा के बाद नोट बदल गया। कार्य दोबारा लागू करने से पहले उसकी मौजूदा स्थिति की समीक्षा करें।';

  @override
  String get notesBatchMissing =>
      'यह नोट अब उपलब्ध नहीं है। सूची ताज़ा करके लक्ष्यों की समीक्षा करें।';

  @override
  String get notesBatchStorage =>
      'स्थानीय सहेजना विफल हुआ। संग्रहण जाँचकर इस आइटम पर फिर प्रयास करें; सफल आइटम सहेजे हुए हैं।';

  @override
  String get notesRemoteReviewChanged =>
      'सर्वर का नोट बदल गया। आपका विलय मसौदा सुरक्षित है। नई तुलना की समीक्षा करें और समाधान फिर चुनें।';

  @override
  String get notesReviewRemote =>
      'मैंने सर्वर के मौजूदा संस्करण की समीक्षा की है';

  @override
  String get wsModuleCapsNotPublished =>
      'मॉड्यूल का अक्षर-शैली नियम प्रकाशित नहीं होता।';

  @override
  String get wsTitleOverridesAction => 'इंस्टेंस और विषय-सूची के शीर्षक…';

  @override
  String get wsHeadingNotPublished => 'यह बिल्डर इसे प्रकाशित नहीं करता।';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'निश्चित बिल्डर Markdown विषयों में इंस्टेंस शीर्षक प्रकाशित नहीं करता। मौजूदा मार्कअप सुरक्षित है; स्रोत में देखें।';

  @override
  String get wsTopicIdentity => 'विषय ID';

  @override
  String get wsElementAnchor => 'तत्व एंकर';

  @override
  String get wsHeadingText => 'शीर्षक पाठ';

  @override
  String get wsDefaultTitle => 'डिफ़ॉल्ट शीर्षक';

  @override
  String get wsTopicNavigation => 'विषय नेविगेशन';

  @override
  String get wsHeadingOptions => 'शीर्षक विशेषताएँ';

  @override
  String get wsDocumentOptions => 'दस्तावेज़ सेटिंग';

  @override
  String get wsSettingsPresent => 'लिखी हुई सेटिंग मौजूद हैं';

  @override
  String get wsTitleOverrideExplanation =>
      'प्रकाशित शीर्षक को बदलता है; शीर्षक पाठ अपरिवर्तित रहता है।';

  @override
  String get wsIgnoreVariables => 'चरों को शाब्दिक पाठ मानें';

  @override
  String get wsIgnoreVariablesExplanation =>
      'सक्षम होने पर चर जैसा पाठ प्रतिस्थापित नहीं होता।';

  @override
  String get wsInstanceSelection => 'सहायता इंस्टेंस';

  @override
  String get wsInstanceExplanation =>
      'नाम, समूह, सूची, बहिष्करण या अभिव्यक्ति से सहायता आउटपुट चुनें।';

  @override
  String get wsFilterExplanation =>
      'पुनः उपयोग की सामग्री को मानदंड से फ़िल्टर करता है; सहायता इंस्टेंस नहीं चुनता।';

  @override
  String get wsContextHelp => 'प्रासंगिक सहायता ID';

  @override
  String get wsCapitalization => 'अक्षर केस';

  @override
  String get wsLibraryTopic => 'लाइब्रेरी विषय';

  @override
  String get wsLastModified => 'अंतिम संशोधन';

  @override
  String get wsMissingTopicHeading =>
      'विषय H1 मौजूद नहीं है। स्रोत में जोड़ें।';

  @override
  String get wsMultipleTopicHeadings =>
      'पहला H1 विषय शीर्षक निर्धारित करता है। बाद के H1 अलग शीर्षक हैं।';

  @override
  String get wsTopicIdentityMismatch =>
      'मूल id फ़ाइलनाम से बने विषय ID से अलग है। विषय फ़ाइल का नाम बदलें या स्रोत देखें।';

  @override
  String get wsUnsupportedProperties =>
      'असमर्थित विशेषताएँ सुरक्षित रहती हैं। स्रोत में देखें।';

  @override
  String get wsGeneratedAnchor =>
      'बना हुआ एंकर; मान दर्ज करने से ओवरराइड बनता है।';

  @override
  String get wsHeadingBuilderLimitation =>
      'निश्चित बिल्डर H1 विशेषताएँ प्रकाशित नहीं करता। वे शीर्षक की हैं, XML मूल की नहीं।';

  @override
  String get closeOtherTabs => 'अन्य टैब बंद करें';

  @override
  String get tocTopicFromTemplate => 'टेम्पलेट से विषय...';

  @override
  String get tocSaveAsTemplate => 'टेम्पलेट के रूप में सहेजें';

  @override
  String get tocTemplateDialog => 'टेम्पलेट से विषय बनाएँ';

  @override
  String get tocTemplatesEditor => 'फ़ाइल और कोड टेम्पलेट';

  @override
  String get tocEditTemplates => 'टेम्पलेट संपादित करें...';

  @override
  String get tocCreateCustomTemplate => 'कस्टम टेम्पलेट बनाएँ...';

  @override
  String get tocTemplateCreated => 'टेम्पलेट बनाया गया';

  @override
  String get tocTemplateDefault => 'डिफ़ॉल्ट';

  @override
  String get tocTemplateCustom => 'कस्टम';

  @override
  String get tocTemplateFilename => 'फ़ाइल का नाम:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'आंतरिक';

  @override
  String get tocTemplateUnnamed => 'बिना नाम';

  @override
  String get tocTemplateNew => 'नया टेम्पलेट...';

  @override
  String get tocTemplateName => 'नाम:';

  @override
  String get tocTemplateExtension => 'एक्सटेंशन:';

  @override
  String get tocTemplateLoadError =>
      'टेम्पलेट लोड नहीं हो सके। मौजूदा टेम्पलेट बदले नहीं गए हैं।';

  @override
  String get tocTemplateSaveError =>
      'टेम्पलेट सहेजे नहीं जा सके। आपके संपादन अभी भी यहाँ उपलब्ध हैं।';

  @override
  String get tocTemplateConflict =>
      'टेम्पलेट दूसरी विंडो में बदल गए हैं। रद्द करें और संपादक फिर से खोलें।';

  @override
  String get tocTemplateDuplicateName =>
      'इस नाम और एक्सटेंशन वाला टेम्पलेट पहले से मौजूद है।';

  @override
  String get tocTemplateFormat => 'प्रारूप:';

  @override
  String get tocTemplateReset => 'रीसेट करें';

  @override
  String get tocTemplateRetry => 'फिर से कोशिश करें';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'विषय-सूची के $count तत्व हटाएँ';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'इन विषय-सूची तत्वों से जुड़ी स्रोत फ़ाइलें नहीं हटाई जाएँगी।';

  @override
  String get tocOk => 'ठीक है';

  @override
  String get tocSelectExistingTopic =>
      'वर्तमान इंस्टेंस में जोड़ने के लिए विषय चुनें';

  @override
  String get tocGroupName => 'समूह का नाम';

  @override
  String get tocMoveLineUp => 'पंक्ति ऊपर ले जाएँ';

  @override
  String get tocMoveLineDown => 'पंक्ति नीचे ले जाएँ';

  @override
  String get tocEmptyMdTopic => 'खाली MD विषय';

  @override
  String get tocEmptyXmlTopic => 'खाली XML विषय';

  @override
  String get tocCopySpecial => 'विशेष कॉपी';

  @override
  String tocCopyFileName(String name) {
    return 'विषय फ़ाइल का नाम \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'विषय फ़ाइल का पथ';

  @override
  String tocCopyTopicTitle(String title) {
    return 'विषय का शीर्षक \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'विषय-सूची तत्व की ID \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'विषय फ़ाइल का नाम';

  @override
  String get tocCopyTopicTitleUnavailable => 'विषय का शीर्षक';

  @override
  String get tocCopyElementIdUnavailable => 'विषय-सूची तत्व की ID';

  @override
  String get tocEditTitleAction => 'शीर्षक संपादित करें...';

  @override
  String get tocEditTitleDialog => 'शीर्षक संपादित करें';

  @override
  String get tocRemoveElementAction => 'विषय-सूची तत्व हटाएँ...';

  @override
  String get tocSetHomePage => 'मुखपृष्ठ के रूप में सेट करें';

  @override
  String tocGoToElement(String fileName) {
    return '\'$fileName\' में विषय-सूची तत्व पर जाएँ';
  }

  @override
  String get tocSynchronize => 'विषय-सूची और संपादक सिंक्रनाइज़ करें';

  @override
  String get tocEmptyGroupAction => 'खाली समूह';

  @override
  String get tocNewEmptyGroup => 'नया खाली समूह';

  @override
  String get tocGroupAction => 'समूह बनाएँ';

  @override
  String get tocNewGroup => 'नया समूह';

  @override
  String get tocSortChildren => 'उपविषयों को वर्णानुक्रम में क्रमबद्ध करें';

  @override
  String get tocLinkTopicFiles => 'विषय फ़ाइलों को विषय-सूची से लिंक करें...';

  @override
  String get addLocalMarkdownFiles => 'स्थानीय Markdown फ़ाइलें जोड़ें';

  @override
  String get tocTitleField => 'विषय-सूची का शीर्षक:';

  @override
  String get tocTopicTitleField => 'विषय का शीर्षक:';

  @override
  String get tocAdvancedSettings => 'उन्नत सेटिंग्स';

  @override
  String tocInstanceTitleField(String instanceId) {
    return '\'$instanceId\' के लिए शीर्षक:';
  }

  @override
  String get tocOnlyTitleField => 'केवल विषय-सूची का शीर्षक:';

  @override
  String get tocInstanceTitleExplanation =>
      'केवल वर्तमान इंस्टेंस के लिए उपयोग होता है। डिफ़ॉल्ट रूप से विषय के शीर्षक से प्राप्त होता है।';

  @override
  String get tocOnlyTitleExplanation =>
      'केवल विषय-सूची में उपयोग होता है। डिफ़ॉल्ट रूप से विषय के शीर्षक या, यदि सेट हो, इंस्टेंस-विशिष्ट शीर्षक से प्राप्त होता है। शीर्षकों का विवरण पढ़ें:';

  @override
  String get tocTitleDocumentationLink => 'यहाँ';

  @override
  String get tocFindUsages => 'खोजें';

  @override
  String get tocRefactorMenu => 'रिफ़ैक्टर';

  @override
  String get tocSafeDelete => 'सुरक्षित रूप से हटाएँ';

  @override
  String get tocDuplicate => 'प्रतिलिपि बनाएँ';

  @override
  String get tocDuplicateFilename => 'विषय फ़ाइल का नाम:';

  @override
  String get tocDuplicateDialog => 'विषय की प्रतिलिपि बनाएँ';

  @override
  String get pdfTitlePage => 'शीर्षक पृष्ठ';

  @override
  String get pdfIncludeTitlePage => 'शीर्षक पृष्ठ शामिल करें';

  @override
  String get pdfTitlePageNote =>
      'इस पृष्ठ पर शीर्षलेख, पादलेख या पृष्ठ संख्या नहीं दिखती है।';

  @override
  String get pdfTitlePageTitle => 'शीर्षक';

  @override
  String get pdfTitlePageSubtitle => 'उपशीर्षक';

  @override
  String get pdfTitlePageAuthor => 'लेखक';

  @override
  String get pdfTitlePageOrganization => 'संगठन';

  @override
  String get pdfTitlePageVersion => 'संस्करण';

  @override
  String get pdfTitlePageDate => 'तारीख';

  @override
  String get pdfTitlePageTitleRequired =>
      'शीर्षक पृष्ठ के लिए शीर्षक दर्ज करें।';

  @override
  String get pdfTocSectionNote =>
      'अलग पृष्ठ से शुरू होता है और कई पृष्ठों तक जा सकता है।';

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
  String get copyPlainText => 'सादे पाठ के रूप में कॉपी करें';

  @override
  String get clipboardCopyFailed =>
      'चयनित सामग्री को क्लिपबोर्ड पर कॉपी नहीं किया जा सका।';

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
      'अनुप्रयोग के कीबोर्ड शॉर्टकट अनुकूलित करें';

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
  String get wordWrapDescription =>
      'लंबी पंक्तियों को क्षैतिज रूप से स्क्रॉल करने के बजाय संपादक की चौड़ाई में समेटें।';

  @override
  String get editorFontSize => 'संपादक फ़ॉन्ट आकार';

  @override
  String get validateOnEdit => 'संपादन के समय सत्यापित करें';

  @override
  String get clearRecentWorkspaces => 'हाल का इतिहास साफ़ करें';

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
  String get settingsEditingButtonsSectionTitle => 'संपादन बटन';

  @override
  String get spellingDictionaries => 'वर्तनी शब्दकोश';

  @override
  String get spellingDictionariesDescription =>
      'वर्तनी शब्दकोश इंस्टॉल और प्रबंधित करें';

  @override
  String get settingsDictionariesSectionTitle => 'शब्दकोश';

  @override
  String get availableSpellingDictionaries => 'उपलब्ध शब्दकोश';

  @override
  String get customSpellingDictionaries => 'कस्टम शब्दकोश';

  @override
  String get spellingDictionaryProblems => 'शब्दकोश समस्याएँ';

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
          '$count दस्तावेज़ों में न सहेजे गए बदलाव हैं। जारी रखने से पहले उन्हें सहेजें?',
      one:
          '1 दस्तावेज़ में न सहेजे गए बदलाव हैं। जारी रखने से पहले इसे सहेजें?',
      zero:
          '0 दस्तावेज़ों में न सहेजे गए बदलाव हैं। जारी रखने से पहले उन्हें सहेजें?',
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
  String get insertBlankLine => 'खाली पंक्ति डालें';

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
  String get toc => 'विषय-सूची';

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
  String get newSiblingTopic => 'नया विषय';

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
  String get removeTocElements => 'TOC तत्व हटाएँ';

  @override
  String get reviewUsages => 'उपयोगों की समीक्षा करें';

  @override
  String get deleteTopicFile => 'विषय फ़ाइल हटाएँ';

  @override
  String get removeAction => 'हटाएँ';

  @override
  String topicRemovalSummary(String topic) {
    return 'विषय-सूची से “$topic” तत्व हटाएँ? विषय-सूची से जुड़ी स्रोत फ़ाइल नहीं हटाई जाएगी।';
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
  String get topicIsHomePageRemovalWarning =>
      'यह विषय इस इंस्टेंस का मुखपृष्ठ है। इसे विषय-सूची से हटाने से पहले कोई दूसरा मुखपृष्ठ चुनें।';

  @override
  String get newHomePage => 'नया मुखपृष्ठ';

  @override
  String get chooseHomePage => 'मुखपृष्ठ चुनें';

  @override
  String get noHomePageReplacement =>
      'इसका मुखपृष्ठ हटाने से पहले इस इंस्टेंस में कोई दूसरा योग्य विषय जोड़ें या लिंक करें।';

  @override
  String get topicIsStartPageRemovalWarning =>
      'यह विषय किसी इंस्टेंस का मुखपृष्ठ है। इसकी स्रोत फ़ाइल हटाने से पहले कोई दूसरा मुखपृष्ठ निर्धारित करें।';

  @override
  String topicUsagesCount(int count) {
    return '$count उपयोग मिले।';
  }

  @override
  String get noBreakingTopicUsages =>
      'कोई ऐसा संदर्भ नहीं मिला जो टूट सकता है।';

  @override
  String get topicUsagesFound => 'BusyMark को इस विषय के निम्न संदर्भ मिले।';

  @override
  String get topicUsageTocElements => 'TOC तत्व';

  @override
  String get topicUsageStartPages => 'मुखपृष्ठ';

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
  String get setRedirectTo => 'इस पर रीडायरेक्ट करें:';

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
  String get preview => 'पूर्वावलोकन';

  @override
  String get topicRenamePreviewTitle => 'नाम बदलने का पूर्वावलोकन';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'पथ: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'विषय ID: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'इंस्टेंस $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'प्रभावित फ़ाइलें';

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
  String get workspaceSearchIncomplete =>
      'केवल कुछ परिणाम दिखाए गए हैं। अधिक परिणाम देखें या खोज को सीमित करें।';

  @override
  String get workspaceSearchShowMore => 'अधिक परिणाम दिखाएँ';

  @override
  String get workspaceSearchSkippedFiles =>
      'खोज अधूरी है। ये फ़ाइलें 1 MiB से बड़ी हैं या पढ़ी नहीं जा सकीं:';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'हाल के आइटम अपडेट नहीं किए जा सके: $error.';
  }

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
    return 'मुखपृष्ठ $topic को हटाया नहीं जा सकता। पहले कोई दूसरा मुखपृष्ठ चुनें।';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'नाम बदलने से प्रोजेक्ट के सभी संदर्भ सुरक्षित रूप से अपडेट नहीं किए जा सकते क्योंकि मॉड्यूल $module में $count विषय फ़ाइल पार्स नहीं हुईं: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside प्रोजेक्ट फ़ाइलों में सहेजे न गए बदलाव हैं। उन्हें हल करें और नाम बदलने का नया पूर्वावलोकन तैयार करें।';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Writerside प्रोजेक्ट का मॉड्यूल सेट बदल गया है। रीफ़ैक्टर करने से पहले नाम बदलने का नया पूर्वावलोकन तैयार करें।';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'इंस्टेंस \"$instanceId\" विषय \"$topic\" के लिए अमान्य वेब फ़ाइल नाम \"$webFileName\" प्रकाशित करता है।';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'इंस्टेंस \"$instanceId\" \"$firstTopic\" और \"$secondTopic\" दोनों को \"$webFileName\" के रूप में प्रकाशित करता है।';
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
          'चयनित ट्रैक की गई फ़ाइलों के सभी स्टेज किए गए और स्टेज नहीं किए गए बदलाव HEAD पर वापस लाए जाएँगे।',
      one:
          'चयनित ट्रैक की गई फ़ाइल के सभी स्टेज किए गए और स्टेज नहीं किए गए बदलाव HEAD पर वापस लाए जाएँगे।',
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
  String get exportFormat => 'आउटपुट फ़ॉर्मैट';

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
  String get goToDeclaration => 'घोषणा पर जाएँ';

  @override
  String get findUsages => 'उपयोग खोजें';

  @override
  String get cannotRenameSymbol =>
      'प्रतीक का नाम सुरक्षित रूप से नहीं बदला जा सकता। नाम जाँचें और दोबारा प्रयास करने से पहले संदर्भ रीफ़्रेश करें।';

  @override
  String get renameTopicFileInstead =>
      'विषय ID उनके फ़ाइल नामों से बनते हैं। विषय-सूची या फ़ाइलें साइडबार में ‘विषय फ़ाइल का नाम बदलें’ का उपयोग करें।';

  @override
  String get keyboardLayout => 'कीबोर्ड लेआउट';

  @override
  String get diagnosticWritersideUnsupported =>
      'असमर्थित या गलत प्रारूप वाली सामग्री स्रोत के रूप में दिखाई जाती है।';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'स्रोत “$reference” हल नहीं किया जा सकता: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'इस इंस्टेंस में लिंक का लक्ष्य उपलब्ध नहीं है: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'अमान्य Writerside मार्कअप: $element, $attribute। $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      '<llms-txt>true</llms-txt> या <llms-txt>false</llms-txt> का उपयोग करें; single-file अब समर्थित नहीं है।';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '$kind हल नहीं किया जा सकता: $reference';
  }

  @override
  String get exportAsHtml => 'HTML के रूप में निर्यात करें…';

  @override
  String get fileTypeHtml => 'HTML दस्तावेज़';

  @override
  String get exportingHtml => 'HTML निर्यात हो रहा है…';

  @override
  String get htmlExported => 'HTML निर्यात पूरा हुआ';

  @override
  String get htmlExportFailed => 'HTML निर्यात विफल हुआ';

  @override
  String get htmlKeepAssetsTogether =>
      'इस निर्यात को कॉपी करते समय HTML फ़ाइल और उसके संसाधन फ़ोल्डर को साथ रखें।';

  @override
  String get htmlInstanceDescription =>
      'एक इंस्टेंस को लिंक किए गए ऑफ़लाइन पृष्ठों के रूप में निर्यात करें। एक अलग आउटपुट फ़ोल्डर का नाम चुनें।';

  @override
  String get htmlInstance => 'इंस्टेंस';

  @override
  String get htmlOwnedDirectoryOnly =>
      'केवल BusyMark HTML निर्यात द्वारा बनाया गया फ़ोल्डर बदला जा सकता है। बदली गई या असंबंधित फ़ाइलें सुरक्षित रहेंगी।';

  @override
  String get showInFolder => 'फ़ोल्डर में दिखाएँ';

  @override
  String sortTableColumn(String column) {
    return '$column क्रमबद्ध करें';
  }

  @override
  String get exportReset => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get exportToc => 'विषय-सूची शामिल करें';

  @override
  String get exportTocDepth => 'विषय-सूची की गहराई';

  @override
  String get exportNumberHeadings => 'शीर्षकों को क्रमांक दें';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'कस्टम';

  @override
  String get exportPageWidth => 'पृष्ठ की चौड़ाई (mm)';

  @override
  String get exportPageHeight => 'पृष्ठ की ऊँचाई (mm)';

  @override
  String get exportMarginTop => 'ऊपरी मार्जिन (mm)';

  @override
  String get exportMarginRight => 'दायाँ मार्जिन (mm)';

  @override
  String get exportMarginBottom => 'निचला मार्जिन (mm)';

  @override
  String get exportMarginLeft => 'बायाँ मार्जिन (mm)';

  @override
  String get exportTypography => 'टाइपोग्राफ़ी';

  @override
  String get exportSans => 'बिना सेरिफ़';

  @override
  String get exportSerif => 'सेरिफ़';

  @override
  String get exportBodySize => 'मुख्य पाठ का फ़ॉन्ट आकार';

  @override
  String get exportCodeSize => 'कोड का फ़ॉन्ट आकार';

  @override
  String get exportRunningText => 'शीर्षलेख और पादलेख';

  @override
  String get exportHeader => 'शीर्षलेख';

  @override
  String get exportFooter => 'पादलेख';

  @override
  String get exportNone => 'कोई नहीं';

  @override
  String get exportDocumentTitle => 'दस्तावेज़ का शीर्षक';

  @override
  String get exportBottomLeft => 'नीचे बाएँ';

  @override
  String get exportBottomCenter => 'नीचे बीच में';

  @override
  String get exportBottomRight => 'नीचे दाएँ';

  @override
  String get exportFirstPage => 'पहले पृष्ठ पर शीर्षलेख और पादलेख दिखाएँ';

  @override
  String get exportAccent => 'हाइलाइट / लिंक का रंग';

  @override
  String get exportTheme => 'थीम';

  @override
  String get exportAutomatic => 'स्वचालित';

  @override
  String get exportLayout => 'लेआउट';

  @override
  String get exportContentWidth => 'सामग्री की अधिकतम चौड़ाई';

  @override
  String get exportOutput => 'आउटपुट';

  @override
  String get exportPackaging => 'पैकेजिंग';

  @override
  String get exportSingleFile => 'एक HTML फ़ाइल';

  @override
  String get exportAssetsDirectory => 'HTML + संसाधन फ़ोल्डर';

  @override
  String get exportCustomCss => 'कस्टम स्टाइलशीट…';

  @override
  String get exportRemoveCss => 'कस्टम स्टाइलशीट हटाएँ';

  @override
  String get exportCssNote =>
      'वैकल्पिक UTF-8 CSS फ़ाइल चुनें (256 KiB तक)। इंपोर्ट, संसाधन URL और निष्पादन योग्य या एस्केप वाला CSS स्वीकार नहीं किया जाता। शैलियाँ BusyMark CSS के बाद लागू होती हैं। दूरस्थ संसाधन डाउनलोड नहीं किए जाते।';

  @override
  String get exportSitePackagingNote =>
      'Writerside अलग-अलग लिंक किए गए विषय पृष्ठ रखता है। एकल फ़ाइल मोड हर पृष्ठ में संसाधन एम्बेड करता है।';

  @override
  String get exportInvalidGeometry =>
      'मार्जिन के बाद सामग्री के लिए कम से कम 20 mm चौड़ाई और ऊँचाई छोड़ें।';

  @override
  String get exportInvalidColor => 'रंग #RRGGBB के रूप में दर्ज करें।';

  @override
  String get exportInvalidCss =>
      '256 KiB तक की पढ़ने योग्य UTF-8 .css फ़ाइल चुनें, जिसमें इंपोर्ट, संसाधन URL, HTML और निष्पादन योग्य या एस्केप वाला CSS न हो।';

  @override
  String get clipboardHistory => 'क्लिपबोर्ड इतिहास';

  @override
  String get clipboardHistoryDescription =>
      'सत्र-विशिष्ट क्लिपबोर्ड इतिहास खोलें।';

  @override
  String get clipboardCurrent => 'वर्तमान क्लिपबोर्ड';

  @override
  String get clipboardCurrentExternal =>
      'किसी अन्य एप्लिकेशन से वर्तमान क्लिपबोर्ड';

  @override
  String clipboardDestination(String name) {
    return '$name में पेस्ट करें';
  }

  @override
  String get clipboardSessionOnly => 'केवल इस BusyMark सत्र के लिए संग्रहीत।';

  @override
  String get clipboardNoItems => 'क्लिपबोर्ड इतिहास खाली है।';

  @override
  String get clipboardDisabled =>
      'क्लिपबोर्ड इतिहास संग्रह सेटिंग्स में अक्षम है।';

  @override
  String get clipboardUnavailable =>
      'वर्तमान क्लिपबोर्ड सामग्री अनुपलब्ध या समर्थित नहीं है।';

  @override
  String get clipboardTooLarge =>
      'यह क्लिपबोर्ड आइटम बहुत बड़ा है और इसे बनाए रखना संभव नहीं है।';

  @override
  String get clipboardPastePlainText => 'सादे टेक्स्ट के रूप में पेस्ट करें';

  @override
  String get clipboardClearAll => 'क्लिपबोर्ड इतिहास साफ़ करें';

  @override
  String get clipboardEntryText => 'टेक्स्ट';

  @override
  String get clipboardEntryRichText => 'रिच टेक्स्ट';

  @override
  String get clipboardEntryImage => 'इमेज';

  @override
  String clipboardOrigin(String name) {
    return '$name से कॉपी किया गया';
  }

  @override
  String get localHistory => 'स्थानीय इतिहास';

  @override
  String get localHistoryEllipsis => 'स्थानीय इतिहास…';

  @override
  String get localHistoryDescription =>
      'वर्तमान दस्तावेज़ के लिए सहेजे गए और स्वचालित स्थानीय संशोधनों को दिखाएं।';

  @override
  String get findLocalHistoryEllipsis => 'स्थानीय इतिहास में खोजें...';

  @override
  String get findLocalHistoryDescription =>
      'स्थानीय इतिहास में दस्तावेज़ और संशोधन सामग्री खोजें।';

  @override
  String get localHistoryNoDocuments =>
      'अभी तक किसी भी दस्तावेज़ में स्थानीय इतिहास नहीं है।';

  @override
  String get localHistoryNoRevisions =>
      'इस दस्तावेज़ में स्थानीय इतिहास में कोई संशोधन नहीं है।';

  @override
  String get localHistorySelectedRevision => 'चयनित संशोधन';

  @override
  String get localHistoryCurrentEditor => 'वर्तमान संपादक सामग्री';

  @override
  String get localHistoryCurrentDisk => 'डिस्क पर वर्तमान सामग्री';

  @override
  String get localHistoryMissingFile => 'मूल फ़ाइल गायब है।';

  @override
  String get localHistoryRestoreRevision => 'पिछली स्थिति को पुनर्स्थापित करें';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'मूल स्थान पर पुनर्स्थापित करें';

  @override
  String get localHistoryRestoreNewLocation => 'नए स्थान पर पुनर्स्थापित करें…';

  @override
  String get localHistoryRestoreChange => 'परिवर्तन को पुनर्स्थापित करें';

  @override
  String get localHistoryRestoreUnavailable =>
      'इस परिवर्तन को पुनर्स्थापित नहीं किया जा सकता क्योंकि तुलना अब अद्यतित नहीं है।';

  @override
  String get localHistoryComparisonSimplified =>
      'यह बड़ा परिवर्तन सरलीकृत है। व्यक्तिगत परिवर्तनों को पुनर्स्थापित करना संभव नहीं है।';

  @override
  String localHistoryOlderChange(String text) {
    return 'पुराने संस्करण में परिवर्तन: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'वर्तमान सामग्री में परिवर्तन: $text';
  }

  @override
  String get localHistoryDeleted => 'हटा दिया गया';

  @override
  String get localHistoryUntitled => 'शीर्षकहीन';

  @override
  String get localHistoryClearDocument => 'इस दस्तावेज़ का इतिहास साफ़ करें';

  @override
  String get localHistoryClearAll => 'सभी स्थानीय इतिहास साफ़ करें';

  @override
  String get localHistoryClearDocumentTitle => 'दस्तावेज़ का इतिहास साफ़ करना?';

  @override
  String get localHistoryClearAllTitle => 'सभी स्थानीय इतिहास साफ़ करना?';

  @override
  String get localHistoryClearConfirmation =>
      'यह स्थायी रूप से संग्रहीत संशोधनों को हटा देता है। इस कार्रवाई को पूर्ववत नहीं किया जा सकता।';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'स्थानीय इतिहास इंडेक्स क्षतिग्रस्त था और बरकरार संशोधनों से फिर से बनाया गया था।';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'यह स्थानीय इतिहास स्टोर समर्थित प्रारूप $version का उपयोग करता है।';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'स्थानीय इतिहास उपलब्ध नहीं: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'रिकॉर्डिंग अक्षम है या यह पथ बाहर रखा गया है। पुनर्स्थापित करने से पहले रिकॉर्डिंग को फिर से सक्षम करें।';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'स्थानीय इतिहास ने पथ परिवर्तन रिकॉर्ड नहीं किया: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'स्थानीय इतिहास को हटाए गए पथ को सहेजने में असमर्थ: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'चयनित संशोधन गायब है या क्षतिग्रस्त है।';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'चयनित संशोधन को नहीं पढ़ा जा सकता: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'स्थानीय इतिहास इस संशोधन को कैप्चर नहीं कर सका: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'बेसलाइन';

  @override
  String get localHistoryReasonSaved => 'सहेजा गया';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'स्वचालित चेकपॉइंट';

  @override
  String get localHistoryReasonBeforeReload => 'रीलोड करने से पहले';

  @override
  String get localHistoryReasonBeforeDiscard => 'त्यागने से पहले';

  @override
  String get localHistoryReasonBeforeRestore => 'पुनर्स्थापना से पहले';

  @override
  String get localHistoryReasonBeforeDelete => 'हटाने से पहले';

  @override
  String get localHistoryReasonExternalChange => 'बाहरी परिवर्तन';

  @override
  String get settingsHistory => 'इतिहास';

  @override
  String get settingsClipboardHistoryTitle => 'क्लिपबोर्ड इतिहास एकत्र करें';

  @override
  String get settingsClipboardHistoryDescription =>
      'केवल इस BusyMark सत्र के लिए कॉपी किए गए और सफलतापूर्वक पेस्ट किए गए सामग्री को बनाए रखें।';

  @override
  String get settingsLocalHistoryTitle => 'स्थानीय इतिहास रिकॉर्ड करें';

  @override
  String get settingsLocalHistoryDescription =>
      'पुनर्प्राप्ति और तुलना के लिए इस डिवाइस पर दस्तावेज़ के संस्करणों को सहेजें।';

  @override
  String get settingsHistoryCheckpoint => 'स्वचालित चेकपॉइंट अंतराल';

  @override
  String get settingsHistoryRetention => 'प्रतिधारण आयु';

  @override
  String get settingsHistoryStorage => 'अधिकतम संग्रहण';

  @override
  String get settingsHistoryExcludedPaths => 'बाहर किए गए पथ';

  @override
  String get settingsHistoryExcludedPathsHint => 'प्रति पंक्ति एक पूर्ण पथ';

  @override
  String settingsSecondsValue(int value) {
    return '$value सेकंड';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value दिन';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'वर्तनी';

  @override
  String get automaticSpelling => 'स्वचालित वर्तनी जाँच';

  @override
  String get defaultSpellingLanguage => 'डिफ़ॉल्ट वर्तनी भाषा';

  @override
  String get projectSpellingLanguage => 'परियोजना की वर्तनी भाषा';

  @override
  String get chooseSpellingLanguage => 'वर्तनी भाषा चुनें';

  @override
  String get spellingLanguageUnsetStatus => 'भाषा…';

  @override
  String get spellingOffStatus => 'वर्तनी बंद';

  @override
  String get checkSpelling => 'वर्तनी जाँचें';

  @override
  String get ignoreSpellingOnce => 'एक बार अनदेखा करें';

  @override
  String get ignoreSpellingDocument => 'इस दस्तावेज़ में सभी अनदेखे करें';

  @override
  String get addPersonalSpellingWord => 'निजी शब्दकोश में जोड़ें';

  @override
  String get addProjectSpellingWord => 'परियोजना शब्दकोश में जोड़ें';

  @override
  String get inheritSpellingLanguage => 'परियोजना या ऐप की भाषा उपयोग करें';

  @override
  String get disableDocumentSpelling => 'वर्तनी जाँच न करें';

  @override
  String get importSpellingDictionary => 'शब्दकोश आयात करें';

  @override
  String get personalSpellingDictionary => 'व्यक्तिगत शब्दकोश';

  @override
  String get projectSpellingDictionary => 'परियोजना शब्दकोश';

  @override
  String get noSpellingErrors => 'कोई वर्तनी त्रुटि नहीं';

  @override
  String get noSpellingSuggestions => 'कोई वर्तनी सुझाव नहीं';

  @override
  String get spellingWordCheckFailed => 'इस शब्द की जाँच नहीं हो सकी';

  @override
  String get spellingCheckFailed => 'वर्तनी जाँच विफल रही';

  @override
  String get spellingSettingsLoadFailed =>
      'वर्तनी जाँच सेटिंग लोड नहीं हो सकीं';

  @override
  String get retrySpellingSettings => 'वर्तनी जाँच सेटिंग फिर से लोड करें';

  @override
  String get spellingCheckIncomplete => 'वर्तनी जाँच अधूरी है';

  @override
  String get spellingDictionaryNotInstalled => 'शब्दकोश इंस्टॉल नहीं है';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return '$dictionary शब्दकोश इंस्टॉल नहीं है';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'इंस्टॉल नहीं है · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'इंस्टॉल है';

  @override
  String get installSpellingDictionary => 'शब्दकोश इंस्टॉल करें';

  @override
  String get removeSpellingDictionary => 'शब्दकोश हटाएँ';

  @override
  String get cancelSpellingDictionaryInstall => 'शब्दकोश डाउनलोड रद्द करें';

  @override
  String get retrySpellingDictionaryInstall => 'शब्दकोश इंस्टॉलेशन फिर आज़माएँ';

  @override
  String spellingDictionaryDownloading(String size) {
    return '$size डाउनलोड हो रहा है…';
  }

  @override
  String get spellingDictionaryValidating => 'शब्दकोश सत्यापित हो रहा है…';

  @override
  String get spellingDictionaryInstallFailed =>
      'शब्दकोश इंस्टॉलेशन विफल — फिर प्रयास करने के लिए चुनें';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '$dictionary ($size) इंस्टॉल करें? इंस्टॉल होने के बाद यह हटाए जाने तक ऑफ़लाइन उपलब्ध रहेगा।';
  }

  @override
  String get spellingDictionaryUnavailable => 'शब्दकोश उपलब्ध नहीं है';

  @override
  String get spellingChecking => 'वर्तनी की जाँच हो रही है…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: $minimum से $maximum के बीच संख्या दर्ज करें।';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'वर्तनी शब्दकोश को बाहरी रूप से बदला गया। पुनर्प्राप्ति प्रति सुरक्षित रखी गई।';

  @override
  String get windowMinimize => 'छोटा करें';

  @override
  String get windowMaximize => 'अधिकतम करें';

  @override
  String get windowRestore => 'पुनर्स्थापित करें';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'कनेक्ट करें';

  @override
  String get nextcloudReconnect => 'फिर कनेक्ट करें';

  @override
  String get nextcloudDisconnect => 'डिस्कनेक्ट करें';

  @override
  String get nextcloudServer => 'सर्वर का पता';

  @override
  String get nextcloudSignInBrowser => 'अपने ब्राउज़र में साइन इन पूरा करें।';

  @override
  String get nextcloudFavorites => 'पसंदीदा';

  @override
  String get nextcloudNewNote => 'नया नोट';

  @override
  String get nextcloudSavedLocally => 'स्थानीय रूप से सहेजा · सिंक लंबित';

  @override
  String get nextcloudSyncing => 'सिंक हो रहा है';

  @override
  String get nextcloudSynced => 'सिंक हो गया';

  @override
  String get nextcloudOffline => 'ऑफ़लाइन';

  @override
  String get nextcloudLocked => 'सर्वर द्वारा लॉक';

  @override
  String get nextcloudReconnectRequired => 'फिर कनेक्ट करना आवश्यक';

  @override
  String get nextcloudCreationUncertain => 'बनाने का परिणाम अनिश्चित';

  @override
  String get nextcloudReadOnly => 'केवल पढ़ने योग्य';

  @override
  String get nextcloudTakeRemote => 'सर्वर संस्करण लें';

  @override
  String get nextcloudMerge => 'मिलाएँ';

  @override
  String get nextcloudDeleteNote => 'नोट हटाएँ?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Nextcloud Notes में कार्यक्षेत्र भर में बदलना उपलब्ध नहीं है। प्रत्येक नोट के भीतर बदलें।';

  @override
  String get nextcloudSaveLocalCopy => 'स्थानीय प्रति सहेजें…';

  @override
  String get nextcloudDisconnectWarning =>
      'इस खाते को हटाने से इस डिवाइस के कैश किए गए नोट और लंबित बदलाव हट जाते हैं। सर्वर पर काम सुरक्षित रखने के लिए पहले सिंक करें।';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'यदि पिछला अपलोड सफल हुआ था, तो फिर प्रयास करने से सर्वर पर एक अप्रयुक्त संलग्नक रह सकता है।';

  @override
  String get nextcloudAttachmentReference => 'सर्वर पर संलग्नक का संदर्भ';

  @override
  String get nextcloudAddAttachment => 'अटैचमेंट जोड़ें…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'यह अटैचमेंट हटाने पर नोट में इसके लिंक उपलब्ध नहीं रहेंगे। सुरक्षित रखे गए डेटा को स्थानीय इतिहास से पुनर्प्राप्त किया जा सकता है।';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'हर परस्पर विरोधी विशेषता का मान चुनें।';

  @override
  String get nextcloudUseServerNote => 'सर्वर के इस नोट का उपयोग करें';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'इस मसौदे को सर्वर के चुने हुए नोट से जोड़ता है, फिर सुरक्षित स्थानीय बदलाव समन्वयित करता है। अनुरोध का मिलना यह पुष्टि नहीं करता कि नोट किसने बनाया था।';

  @override
  String get nextcloudExactCandidate =>
      'अनुरोध से पूरी तरह मेल; पहचान की पुष्टि नहीं हुई है।';

  @override
  String get nextcloudPossibleCandidate =>
      'संशोधित अनुरोध से संभावित मेल; पहचान की पुष्टि नहीं हुई है।';

  @override
  String get nextcloudSelectCandidate => 'समीक्षा के लिए सर्वर का नोट चुनें';

  @override
  String get nextcloudCreateSeparate => 'अलग नोट बनाएँ';

  @override
  String get nextcloudCreateSeparateWarning =>
      'पहले अनुरोध ने सर्वर पर पहले ही नोट बना दिया हो सकता है। यह आपके सुरक्षित स्थानीय काम के साथ अलग नोट बनाता है। किसी संभावित प्रतिलिपि को हटाया नहीं जाएगा।';

  @override
  String get wsSemanticFormats => 'अर्थपूर्ण स्वरूपण';

  @override
  String get wsUiControl => 'यूआई नियंत्रण';

  @override
  String get wsFilePath => 'फ़ाइल / पथ';

  @override
  String get wsUiPath => 'यूआई पथ';

  @override
  String get wsDefinitionList => 'परिभाषा सूची';

  @override
  String get wsIncludeContent => 'पुनः उपयोग योग्य सामग्री शामिल करें';

  @override
  String get wsVariableReference => 'चर संदर्भ';

  @override
  String get wsConvertList => 'सूची को प्रक्रिया में बदलें';

  @override
  String get wsElementProperties => 'तत्व के गुण';

  @override
  String get wsTopicProperties => 'विषय के गुण';

  @override
  String get wsCollapsible => 'समेटने योग्य';

  @override
  String get wsPublishedState => 'प्रकाशित आरंभिक स्थिति';

  @override
  String get wsExpanded => 'विस्तृत';

  @override
  String get wsCollapsed => 'संक्षिप्त';

  @override
  String get wsCollapsedTitle => 'संक्षिप्त शीर्षक';

  @override
  String get wsTerm => 'शब्द';

  @override
  String get wsListLayout => 'सूची लेआउट';

  @override
  String get wsSyncGroup => 'सिंक समूह';

  @override
  String get wsTabKey => 'टैब कुंजी';

  @override
  String get wsSwitcherLabel => 'स्विचर लेबल';

  @override
  String get wsNavigationElements => 'नेविगेशन तत्व';

  @override
  String get wsNavigationDepth => 'नेविगेशन गहराई';

  @override
  String get wsAddItem => 'आइटम जोड़ें';

  @override
  String get wsStep => 'चरण';

  @override
  String get wsPropertyInvalid => 'अमान्य गुण मान';

  @override
  String get wsFilter => 'फ़िल्टर';

  @override
  String get wsIdentifier => 'तत्व आईडी';

  @override
  String get wsTldr => 'सारांश (TLDR)';

  @override
  String get wsFullLayout => 'पूरी चौड़ाई';

  @override
  String get wsMediumLayout => 'मध्यम (1:2)';

  @override
  String get wsNarrowLayout => 'संकीर्ण शब्द स्तंभ';

  @override
  String get wsTitle => 'शीर्षक';

  @override
  String get wsSwitcherKey => 'स्विचर कुंजी';

  @override
  String get nextcloudServerSettings => 'सर्वर Notes सेटिंग्स';

  @override
  String get nextcloudNotesPath => 'नोट फ़ोल्डर का पथ';

  @override
  String get nextcloudFileSuffix => 'नए नोट की फ़ाइल का प्रत्यय';

  @override
  String get nextcloudServerSettingsExplanation =>
      'ये सर्वर Notes सेटिंग्स दूसरे क्लाइंट को भी प्रभावित करती हैं। पथ बदलने से फ़ाइलें स्थानांतरित नहीं होतीं; प्रत्यय बदलने से मौजूदा नोट का नाम नहीं बदलता।';

  @override
  String get nextcloudSettingsSaved => 'सर्वर सेटिंग्स सहेजी गईं';

  @override
  String get nextcloudSettingsNormalized =>
      'सर्वर द्वारा सामान्यीकृत मानों के साथ सहेजा गया';

  @override
  String get nextcloudPendingUpload => 'अटैचमेंट अपलोड लंबित है';

  @override
  String nextcloudServerCheck(String time) {
    return 'सर्वर की अंतिम जाँच: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'सर्वर सेटिंग लोड हो रही हैं';

  @override
  String get nextcloudSettingsSaving => 'सर्वर सेटिंग सहेजी जा रही हैं';

  @override
  String get nextcloudPreviousLocalEdit => 'पिछला स्थानीय संपादन';

  @override
  String get nextcloudUsePreviousEdit => 'पिछला संपादन इस्तेमाल करें';

  @override
  String get quickOpen => 'त्वरित खोलें';

  @override
  String get notesAll => 'सभी नोट्स';

  @override
  String get notesUncategorized => 'बिना श्रेणी';

  @override
  String get notesRecovery => 'पुनर्प्राप्ति';

  @override
  String get notesRecentlyEdited => 'हाल में संपादित';

  @override
  String get notesOldestEdited => 'सबसे पुराना संपादन';

  @override
  String get notesTitleAscending => 'शीर्षक आरोही';

  @override
  String get notesTitleDescending => 'शीर्षक अवरोही';

  @override
  String get notesMove => 'श्रेणी में ले जाएँ';

  @override
  String get notesRemoveFavorite => 'पसंदीदा हटाएँ';

  @override
  String get notesOffline => 'ऑफ़लाइन उपलब्ध करें';

  @override
  String get notesOfflineRemove => 'ऑफ़लाइन संरक्षण हटाएँ';

  @override
  String get notesIndexing => 'नोट्स की अनुक्रमणिका बन रही है…';

  @override
  String get notesSearchHelp =>
      'शब्द AND से जुड़ते हैं। \"उद्धृत वाक्यांश\", title: और category: का उपयोग करें।';

  @override
  String get notesSourceLocation => 'स्रोत स्थान';

  @override
  String get notesRecoveryHelp =>
      'केवल संरक्षित स्थानीय नोट्स और स्थानीय इतिहास। सर्वर का कचरा और इतिहास उपलब्ध नहीं है।';

  @override
  String get notesImport => 'नोट्स आयात करें';

  @override
  String get notesExport => 'नोट्स निर्यात करें';

  @override
  String get notesImportDistinct => 'अलग नोट के रूप में आयात करें';

  @override
  String get notesAvailableOffline => 'ऑफ़लाइन उपलब्ध';

  @override
  String get notesIncomplete => 'अपूर्ण';

  @override
  String get notesSelected => 'चुने गए नोट्स';

  @override
  String get notesNoHistory =>
      'कोई संरक्षित संशोधन नहीं। इतिहास बंद, समाप्त या साफ़ किया गया हो सकता है।';

  @override
  String get notesTextAvailable => 'पाठ स्थानीय रूप से उपलब्ध है';

  @override
  String get notesLocalVersion => 'स्थानीय कार्य संस्करण';

  @override
  String get notesAttachments => 'अटैचमेंट';

  @override
  String get notesSkipped => 'छोड़ा गया';

  @override
  String get notesFailed => 'विफल';

  @override
  String get notesCompleted => 'पूर्ण';

  @override
  String get notesImportNew => 'नया आयात शुरू करें';

  @override
  String get notesImportResume => 'बाधित आयात फिर से शुरू करें';

  @override
  String get notesImportAlreadyImported =>
      'इस प्रक्रिया में पहले ही आयात किया गया';

  @override
  String get references => 'संदर्भ';

  @override
  String get referenceIncoming => 'आने वाले';

  @override
  String get referenceOutgoing => 'जाने वाले';

  @override
  String get referenceChooseTarget => 'लिंक लक्ष्य चुनें';

  @override
  String get referenceWholeDocument => 'पूरा दस्तावेज़';

  @override
  String get referenceSourceLocation => 'स्रोत स्थान';

  @override
  String get referenceTargetLocation => 'लक्ष्य स्थान';

  @override
  String get referenceResolved => 'हल हुआ';

  @override
  String get referenceMissing => 'गुम';

  @override
  String get referenceAmbiguous => 'अस्पष्ट';

  @override
  String get referenceUnavailable => 'इस संदर्भ में अनुपलब्ध';

  @override
  String get referenceUnsupported => 'असमर्थित';

  @override
  String get referenceNoPortableId =>
      'इस लक्ष्य का सत्यापित पोर्टेबल नोट URL नहीं है.';

  @override
  String get wsIncludeLines => 'पंक्तियाँ शामिल करें';

  @override
  String get wsIncludeSymbol => 'प्रतीक शामिल करें';

  @override
  String get wsEmphasizeLines => 'दिखाई गई पंक्तियाँ हाइलाइट करें';

  @override
  String get wsPropertiesReadOnly => 'इस दृश्य में गुण केवल पढ़ने के लिए हैं।';

  @override
  String get wsPropertiesProtected =>
      'यह तत्व सुरक्षित है। इसका स्रोत संपादित करें।';

  @override
  String get wsPropertiesConflict =>
      'दस्तावेज़ या तत्व बदल गया। मसौदा वापस करें और फिर चुनें।';

  @override
  String get wsPropertiesUnresolved => 'संदर्भ अभी हल नहीं हो सकता।';

  @override
  String get wsUseDefault => 'डिफ़ॉल्ट उपयोग करें';

  @override
  String get wsPropertiesSelection => 'एक तत्व चुनें।';

  @override
  String get wsImageDisplay => 'छवि प्रदर्शन';

  @override
  String get wsImageThumbnail => 'क्लिक करने योग्य थंबनेल';

  @override
  String get wsEnabled => 'सक्षम';

  @override
  String get wsDisabled => 'अक्षम';

  @override
  String get wsWidth => 'चौड़ाई';

  @override
  String get wsHeight => 'ऊँचाई';

  @override
  String get wsPropertiesInactive =>
      'प्रकाशित संकुचन बंद होने पर इस गुण का प्रभाव नहीं होता।';

  @override
  String get wsNavigationAll => 'सभी शीर्षक वाले तत्व';

  @override
  String get wsNavigationNone => 'नेविगेशन नहीं';

  @override
  String get wsNavigationCustom => 'कस्टम नेविगेशन';

  @override
  String get wsTitleOverride => 'शीर्षक बदलें';

  @override
  String get wsCompactLayout => 'संक्षिप्त';

  @override
  String get wsWideLayout => 'चौड़ा';

  @override
  String get wsCodeSourceConflict =>
      'src सेट करने से पहले इस ब्लॉक में लिखे कोड को हटाएँ या स्थानांतरित करें। Writerside स्रोत संदर्भ वाले गैर-खाली कोड ब्लॉक को अस्वीकार करता है।';

  @override
  String get wsInherited => 'सूची से प्राप्त करें';

  @override
  String get wsExternalImageSize =>
      'Writerside बाहरी छवियों का आकार विश्वसनीय ढंग से नहीं बदलता। मौजूदा आयाम देखे और हटाए जा सकते हैं।';

  @override
  String get wsPropertiesNotSerialized =>
      'यह बदलाव स्रोत में लागू नहीं हुआ। मसौदा सुरक्षित रखा गया है।';

  @override
  String get wsListItem => 'सूची आइटम';

  @override
  String get wsSourceFile => 'स्रोत फ़ाइल';

  @override
  String get wsLinkTarget => 'लिंक लक्ष्य';

  @override
  String get wsPreviewImage => 'पूर्वावलोकन छवि';

  @override
  String get wsIncludedElement => 'शामिल तत्व';

  @override
  String get wsHelpModule => 'सहायता मॉड्यूल';

  @override
  String get wsActionId => 'कार्रवाई ID';

  @override
  String get wsKeymapHelpInstance => 'कीमैप सहायता इंस्टेंस';

  @override
  String get wsShowInSource => 'स्रोत में दिखाएँ';

  @override
  String get wsOriginElement => 'तत्व का ओवरराइड';

  @override
  String get wsOriginAncestor => 'मूल तत्व';

  @override
  String get wsOriginModule => 'मॉड्यूल का डिफ़ॉल्ट';

  @override
  String get wsOriginBuiltIn => 'अंतर्निहित डिफ़ॉल्ट';

  @override
  String get wsOriginUnresolved => 'अनसुलझा';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'प्रभावी: $value — $origin';
  }

  @override
  String get wsElementSelector => 'तत्व';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'जनित: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'डिफ़ॉल्ट: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'डिफ़ॉल्ट: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'समाधित: $value';
  }

  @override
  String get wsPropertyUnresolved => 'असमाधित';

  @override
  String get wsModule => 'मॉड्यूल';

  @override
  String get wsParent => 'मूल तत्व';

  @override
  String get wsListType => 'सूची प्रकार';

  @override
  String get wsStartingNumber => 'आरंभ संख्या';

  @override
  String get wsListSorting => 'क्रमबद्ध करना';

  @override
  String get wsLetteredList => 'अक्षर सूची';

  @override
  String get wsCheckboxList => 'चेकबॉक्स सूची';

  @override
  String get wsMarkerlessList => 'बिना चिह्नों की सूची';

  @override
  String get wsAscending => 'आरोही';

  @override
  String get wsDescending => 'अवरोही';

  @override
  String get wsNoSorting => 'क्रमबद्ध नहीं';

  @override
  String get wsAsWritten => 'जैसा लिखा है';

  @override
  String get wsSentenceCase => 'वाक्य अक्षर शैली';

  @override
  String get wsTitleCase => 'शीर्षक अक्षर शैली';

  @override
  String get wsLowerCase => 'छोटे अक्षर';

  @override
  String get wsUpperCase => 'बड़े अक्षर';

  @override
  String get wsNativeMarkers => 'Markdown चिह्न';

  @override
  String wsListMarkerStart(String number) {
    return 'आरंभ चिह्न: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'स्तर $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'निर्धारित बिल्डर मॉड्यूल के <caps> नियमों को अनदेखा करता है। स्थानीय caps विशेषता या default-property का उपयोग करें।';

  @override
  String get wsInsertElements => 'तत्व जोड़ें';

  @override
  String get wsAdmonitionsAndQuotes => 'सूचनाएँ और उद्धरण';

  @override
  String get wsSemanticText => 'अर्थपूर्ण पाठ';

  @override
  String get wsPropertiesUnavailable =>
      'जाँचा गया तत्व उपलब्ध नहीं है। जारी रखने के लिए कोई तत्व जाँचें।';

  @override
  String get searchDocumentsCategory => 'दस्तावेज़';

  @override
  String get searchTopicsCategory => 'विषय';

  @override
  String get searchCurrentDocument => 'वर्तमान दस्तावेज़';

  @override
  String get searchCurrentWorkspace => 'वर्तमान कार्यक्षेत्र';

  @override
  String get browseNotes => 'नोट ब्राउज़ करें';

  @override
  String get searchActionsCommand => 'क्रियाएँ खोजें';

  @override
  String get searchDocumentsCommand => 'दस्तावेज़ खोजें';

  @override
  String get searchTopicsCommand => 'विषय खोजें';

  @override
  String get searchRecentCommand => 'हाल के आइटम खोजें';

  @override
  String get searchResourceUnavailable => 'यह संसाधन उपलब्ध नहीं है।';

  @override
  String get notesSync => 'नोट सिंक करें';

  @override
  String get searchInWorkspace => 'कार्यस्थान में खोजें';

  @override
  String get searchCategory => 'खोज श्रेणी';

  @override
  String get clearHistorySearchScope => 'दस्तावेज़ों के इतिहास में खोजें';

  @override
  String get searchInDocument => 'दस्तावेज़ में खोजें';

  @override
  String get searchDocumentHint => 'इस दस्तावेज़ में खोजें…';

  @override
  String get searchWorkspaceHint => 'इस कार्यक्षेत्र में खोजें…';

  @override
  String get searchOutlineHint => 'शीर्षक खोजें…';

  @override
  String get searchHistoryHint => 'स्थानीय इतिहास में खोजें…';

  @override
  String get searchEnterText => 'खोजने के लिए पाठ दर्ज करें';

  @override
  String get searchAccountUnavailable => 'खाता उपलब्ध नहीं है';

  @override
  String get searchDocumentsHint => 'दस्तावेज़ खोजें…';

  @override
  String get searchTopicsHint => 'विषय खोजें…';

  @override
  String get searchRecentHint => 'हाल के आइटम खोजें…';

  @override
  String get searchActionsHint => 'क्रियाएँ खोजें…';

  @override
  String get searchRequiresNotesWorkspace => 'नोट्स कार्यक्षेत्र आवश्यक है';

  @override
  String get searchSidebarLabel => 'खोजें:';

  @override
  String get searchDocumentTextCategory => 'दस्तावेज़ पाठ';

  @override
  String get searchWorkspaceTextCategory => 'कार्यस्थान पाठ';

  @override
  String get searchHeadingsCategory => 'शीर्षक';

  @override
  String get shortcutUnassigned => 'असाइन नहीं किया गया';

  @override
  String get shortcutPressKeys => 'कुंजी संयोजन दबाएँ…';

  @override
  String get shortcutRecord => 'शॉर्टकट रिकॉर्ड करें';

  @override
  String get shortcutRestoreAll => 'सभी डिफ़ॉल्ट पुनर्स्थापित करें';

  @override
  String get shortcutRestoreAllQuestion =>
      'सभी क्रियाओं के डिफ़ॉल्ट शॉर्टकट पुनर्स्थापित करें? कस्टम असाइनमेंट हटा दिए जाएँगे।';

  @override
  String get shortcutSaveFailed =>
      'शॉर्टकट सक्रिय हैं लेकिन सहेजे नहीं जा सके। पुनः प्रारंभ के बाद रखने के लिए दोबारा सहेजें।';

  @override
  String get shortcutRetry => 'सहेजने का पुनः प्रयास करें';

  @override
  String get shortcutChanged =>
      'असाइनमेंट बदल गए हैं। वर्तमान शॉर्टकट जाँचें और पुनः प्रयास करें।';

  @override
  String get shortcutInvalid =>
      'इस संदर्भ में यह संयोजन असाइन नहीं किया जा सकता।';

  @override
  String get shortcutSystemWarning =>
      'आपका डेस्कटॉप इस संयोजन का उपयोग कर सकता है। BusyMark सिस्टम शॉर्टकट नहीं बदल सकता।';

  @override
  String get shortcutConflicts => 'यह शॉर्टकट इन क्रियाओं से टकराता है:';

  @override
  String get shortcutRemove => 'असाइनमेंट हटाएँ';

  @override
  String get shortcutRestoreDefault => 'डिफ़ॉल्ट पुनर्स्थापित करें';

  @override
  String get shortcutAssign => 'असाइन करें';

  @override
  String get shortcutReassign => 'फिर से असाइन करें';

  @override
  String get shortcutContextApplication => 'अनुप्रयोग';

  @override
  String get shortcutContextDocument => 'दस्तावेज़ दृश्य';

  @override
  String get shortcutContextEditor => 'संपादक और स्रोत';

  @override
  String get shortcutContextWritersideSource => 'Writerside स्रोत';

  @override
  String get shortcutContextWorkspace => 'कार्यस्थान नेविगेशन';

  @override
  String get shortcutContextTree => 'साइडबार ट्री';

  @override
  String get searchHeadingsCommand => 'शीर्षक खोजें';

  @override
  String get shortcutFixed =>
      'संपादक द्वारा प्रबंधित; कॉन्फ़िगर नहीं किया जा सकता।';

  @override
  String get shortcutDefaultConflict =>
      'डिफ़ॉल्ट शॉर्टकट का कस्टम असाइनमेंट से टकराव है।';

  @override
  String get shortcutCurrentBinding => 'वर्तमान शॉर्टकट';

  @override
  String get shortcutProposedBinding => 'प्रस्तावित शॉर्टकट';

  @override
  String get notesActions => 'नोटों की कार्रवाइयाँ';

  @override
  String get noteActions => 'नोट की कार्रवाइयाँ';

  @override
  String get noteProperties => 'नोट के गुण';

  @override
  String get notesExportAll => 'नोट्स निर्यात करें · सभी नोट्स…';

  @override
  String get notesExportCategory => 'नोट्स निर्यात करें · श्रेणी…';

  @override
  String get notesOfflineAll => 'ऑफ़लाइन उपलब्ध करें · सभी नोट्स';

  @override
  String get notesOfflineCategory => 'ऑफ़लाइन उपलब्ध करें · श्रेणी';

  @override
  String get notesOfflineRemoveAll => 'ऑफ़लाइन संरक्षण हटाएँ · सभी नोट्स';

  @override
  String get notesOfflineRemoveCategory => 'ऑफ़लाइन संरक्षण हटाएँ · श्रेणी';

  @override
  String get notesOfflinePause => 'डाउनलोड रोकें';

  @override
  String get notesOfflineResume => 'डाउनलोड जारी रखें';

  @override
  String get notesOfflineKeep => 'ऑफ़लाइन उपलब्ध करें';

  @override
  String get notesOfflineRetentionHelp =>
      'यह आवश्यकता हटाने से कैश की मौजूदा सामग्री नहीं हटती। श्रेणी या खाते की आवश्यकता अब भी यह नोट सुरक्षित रख सकती है।';

  @override
  String get notesOfflineBroader =>
      'यह नोट श्रेणी या खाते की आवश्यकता के कारण भी सुरक्षित है।';

  @override
  String get notesOfflineExternal =>
      'बाहरी मीडिया को कनेक्शन चाहिए। BusyMark केवल नोट का पाठ और प्रबंधित संलग्नक सुरक्षित रखता है।';

  @override
  String get notesEmptyAll =>
      'अभी कोई नोट नहीं है। शुरू करने के लिए नोट बनाएँ।';

  @override
  String get notesEmptyFavorites => 'कोई पसंदीदा नोट नहीं है।';

  @override
  String get notesEmptyCategory => 'इस श्रेणी में कोई नोट नहीं है।';

  @override
  String get notesEmptyUncategorized => 'कोई बिना श्रेणी वाला नोट नहीं है।';

  @override
  String get notesEmptyRecovery =>
      'पुनर्प्राप्ति के लिए कोई सहेजा हुआ नोट नहीं है।';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · विफल. फिर प्रयास करें';

  @override
  String get notesOperationFailed =>
      'कार्रवाई पूरी नहीं हुई। आपका मसौदा सुरक्षित है। सहेजने और विरोधों की जाँच करके फिर प्रयास करें।';

  @override
  String get notesInspectionFailed => 'अटैचमेंट · विफल. फिर प्रयास करें';

  @override
  String get notesStartingConnection => 'Nextcloud कनेक्शन शुरू हो रहा है…';

  @override
  String get notesVerifyingConnection => 'नोटों तक पहुँच जाँची जा रही है…';

  @override
  String get notesCancellingConnection =>
      'साइन-इन रद्द करके सफ़ाई की जा रही है…';

  @override
  String get notesRemovingConnection => 'स्थानीय खाता हटाया जा रहा है…';

  @override
  String get notesRemovedWarning =>
      'स्थानीय Nextcloud खाता हटा दिया गया। ऐप पासवर्ड रद्द होने की पुष्टि नहीं हुई। Nextcloud की सुरक्षा सेटिंग में BusyMark का ऐप पासवर्ड हटाएँ।';

  @override
  String get notesBuffersNotSaved =>
      'सभी खुले नोट स्थानीय रूप से नहीं सहेजे जा सके। कार्यक्षेत्र में सहेजने, विरोधों या सामान्यीकरण की समीक्षा करें। स्थानीय बदलावों को अब भी Nextcloud से समन्वय की ज़रूरत हो सकती है।';

  @override
  String get notesSettingsLeave =>
      'जाने से पहले Nextcloud सेटिंग के बदलाव सहेजें?';

  @override
  String get notesSettingsLeaveHelp =>
      'सर्वर Notes सेटिंग्स · न सहेजे गए बदलाव';

  @override
  String get notesSettingsReload => 'सर्वर सेटिंग फिर लोड करें…';

  @override
  String get notesSettingsReloadHelp =>
      'फिर लोड करने से मसौदे की जगह वर्तमान Nextcloud सेटिंग आएगी। मसौदा छोड़कर फिर लोड करें?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud ने सेटिंग स्वीकार की, पर नोट रीफ़्रेश नहीं हुए। दिखाई गई सेटिंग सर्वर द्वारा स्वीकृत हैं। नोटों से रीफ़्रेश फिर आज़माएँ।';

  @override
  String get notesUnavailable =>
      'ऑफ़लाइन · पाठ स्थानीय रूप से उपलब्ध है · स्थानीय रूप से सहेजा · सिंक लंबित';

  @override
  String get notesStorageFull =>
      'Nextcloud का संग्रहण भर गया है। सर्वर पर जगह खाली करके फिर प्रयास करें।';

  @override
  String get notesRejected =>
      'Nextcloud ने यह बदलाव अस्वीकार कर दिया। फिर प्रयास करने से पहले नोट जाँचें और स्थानीय प्रति सहेजें।';

  @override
  String get notesThrottled =>
      'Nextcloud ने प्रतीक्षा को कहा है। फिर प्रयास की समय-सीमा के बाद समन्वय जारी होगा।';

  @override
  String get notesRecoveryRequired => 'टकराव · तुलना करें';

  @override
  String get notesScanning => 'फ़ाइलें जाँची जा रही हैं…';

  @override
  String get notesCancelling =>
      'रद्द हो रहा है… वर्तमान कार्रवाई समाप्त होने की प्रतीक्षा है।';

  @override
  String get notesCancelled => 'रद्द किया गया';

  @override
  String get notesPartial => 'आंशिक रूप से पूरा';

  @override
  String get notesTransferFailed => 'विफल. फिर प्रयास करें';

  @override
  String get notesImportPartialHelp =>
      'पिछले आइटम पहले ही स्थानीय रूप से सहेजे हो सकते हैं। प्रतियाँ बनाए बिना जारी रखने के लिए यही आयात फिर शुरू करें।';

  @override
  String get notesNotStarted => 'शुरू नहीं हुआ';

  @override
  String get notesCreated => 'बनाया गया';

  @override
  String get notesRemoteDeleteUnavailable =>
      'सर्वर का पता · असमर्थित · हटाएँ · अटैचमेंट';

  @override
  String get notesCurrentText => 'वर्तमान सुरक्षित पाठ';

  @override
  String get notesRecovering => 'नए नोट के रूप में पुनर्प्राप्त हो रहा है…';

  @override
  String get notesReadOnlyHelp =>
      'केवल पढ़ने योग्य · पसंदीदा · स्थानीय प्रति सहेजें…';

  @override
  String get notesSort => 'नोट क्रमबद्ध करें';

  @override
  String get notesPathRelative =>
      'नोट फ़ोल्डर का पथ आपके Nextcloud संग्रहण के सापेक्ष है।';

  @override
  String get notesSettingsStale =>
      'Nextcloud पर सेटिंग बदल गई है। मसौदा बदलने से पहले सर्वर के मान फिर लोड करके जाँचें।';

  @override
  String get notesDownloadsPaused => 'डाउनलोड रुके हुए हैं';

  @override
  String get notesExportNotPublished => 'कोई निर्यात प्रकाशित नहीं हुआ।';

  @override
  String get notesKeyringUnavailable =>
      'डेस्कटॉप कीरिंग अनलॉक करके फिर प्रयास करें।';

  @override
  String get notesConnectFailed =>
      'Nextcloud Notes से कनेक्ट नहीं हो सका। सर्वर का पता जाँचें और फिर प्रयास करें।';

  @override
  String get notesAccountMismatch =>
      'उसी Nextcloud खाते में साइन-इन करें। दूसरे खाते से कनेक्ट करने के लिए पहले यह खाता हटाएँ।';

  @override
  String get notesLocalRemovalFailed =>
      'स्थानीय खाते की सफ़ाई विफल रही। हटाने का फिर प्रयास करने के लिए खाता रखा गया है।';

  @override
  String get notesTransferring => 'नोट स्थानांतरित हो रहे हैं…';

  @override
  String get notesTechnicalDetails => 'तकनीकी विवरण';

  @override
  String get notesPauseRequirement => 'ऑफ़लाइन आवश्यकता रोकें';

  @override
  String get notesResumeRequirement => 'ऑफ़लाइन आवश्यकता जारी रखें';

  @override
  String get gitReturnToDocument => 'दस्तावेज़ पर लौटें';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'केवल पढ़ने योग्य स्नैपशॉट · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'इस फ़ाइल नाम में गैर-UTF-8 बाइट हैं। Git समीक्षा और स्टेजिंग उपलब्ध हैं; दस्तावेज़ संपादक को UTF-8 फ़ाइल नाम चाहिए।';

  @override
  String get gitUiMergeInProgress => 'प्रगति पर मिलाएं';

  @override
  String get gitUiRebaseInProgress => 'प्रगति में रिबेस';

  @override
  String get gitUiCherryPickInProgress => 'डाउनलोड प्रगति में चेरी-पिक';

  @override
  String get gitUiRevertInProgress => 'उलटें इंच प्रगति';

  @override
  String get gitUiPatchApplicationInProgress => 'पैच अनुप्रयोग प्रगति पर है';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'स्QICANKE( ID) का परिणाम होगा a';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'समाधान- रहित अनुक्रमणिका परस्पर विरोध';

  @override
  String get gitUiUnresolvedConflicts => ' · परस्पर विरोध';

  @override
  String get gitUiReviewOperation => 'संक्रिया मिटाएँ';

  @override
  String get gitUiRefresh => 'रिफ़्रेश करें';

  @override
  String get gitUiCreateNamedStash => 'बनाएँ नाम';

  @override
  String get gitUiCreateStash => 'स्टैश बनाएँ…';

  @override
  String get gitUiNoStashes => 'कोई स्टैश नहीं';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'इसके परिवर्तनों का निरीक्षण करने के लिए चतुर्भुज चुनें';

  @override
  String get gitUiStashedUntrackedFiles => 'ट्रैकर नहीं किया गया फ़ाइल';

  @override
  String get gitUiInspectStashedUntrackedFiles => 'नहीं सहेजें फ़ाइल';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'लागू करने के दौरान लागू की गई स्थिति रीग्रेड की स्थिति';

  @override
  String get gitUiApplyAndRetain => 'लागू करें और बनाए रखें';

  @override
  String get gitUiPop => 'पॉप...';

  @override
  String get gitUiCreateBranch => 'शाखा बनाएँ…';

  @override
  String get gitUiDropStash => 'स्टैश हटाएँ…';

  @override
  String get gitUiBranchFromStash => 'स्टैश से शाखा बनाएँ';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'स्टैश के मूल आधार पर शाखा बनाएँ/उस पर जाएँ, फिर स्टैश लागू करें। मूल स्टैश बाद में स्पष्ट रूप से हटाने तक रखा जाता है।';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 इस स्टैश?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'यदि परस्पर विरोधों को लागू किया जाए तो मूल संशोधन क़ायम रखा गया है.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'इस प्रविष्टि को मिटाएँ. इसके परिवर्तनों को लागू नहीं किया गया है.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'अनमर्ज फ़ाइलों के टकराव सुलझाएँ। Git में स्टैश जारी रखने या निरस्त करने का आदेश नहीं है; मूल स्टैश सुरक्षित रहता है।';

  @override
  String get gitUiStashNameMessage => 'स्थिति नाम/message';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'सफल हो गए और परिणाम अनुक्रमणिका';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'चल रहे परिवर्तनों को प्रारंभ किया जा रहा है';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'बदलाव स्टैश करें, इंडेक्स के बदलाव यथावत रखें (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'केवल इंडेक्स के बदलाव स्टैश करें (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'शामिल नहीं किया गया फ़ाइल';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'इस रेपॉसिटरी में सभी योग्य पथ';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'इन संशोधन विकल्प के लिए कोई योग्य परिवर्तन नहीं.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath => 'कम से कम एक योग्य पथ चुनें.';

  @override
  String get gitUiCreateStash2 => 'स्टैश बनाएँ';

  @override
  String get gitUiCreateWorktree => 'कार्य ट्री बनाएँ...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'HEAD पर वर्कट्री बनाने से पहले कमिट बनाएँ।';

  @override
  String get gitUiDetachedHEAD => 'अलग HEAD';

  @override
  String get gitUiCurrent => 'मौजूदा';

  @override
  String get gitUiLocked => 'तालाबंद';

  @override
  String get gitUiOpenInBusyStack => 'व्यस्त रोकने में खोलें';

  @override
  String get gitUiStatusNotInspected => 'प्रस्थिति जाँच नहीं की गई';

  @override
  String get gitUiDirty => 'गंदा';

  @override
  String get gitUiClean => 'क्लीन';

  @override
  String get gitUiOpenWorkingFolder => 'कार्यशील फ़ोल्डर खोलें';

  @override
  String get gitUiMoveWorktree => 'कार्य ट्री खिसकाएँ...';

  @override
  String get gitUiUnlock => 'तालाखोलें';

  @override
  String get gitUiLock => 'तालाबंद';

  @override
  String get gitUiRemoveCleanWorktree => 'साफ कार्य ट्री मिटाएँ...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'स्थानीय परिवर्तनों सहित हटाने की समीक्षा करें...';

  @override
  String get gitUiNewWorktreeFolderName => 'नया कार्य ट्री फ़ोल्डर नाम';

  @override
  String get gitUiNewWorktreeBranch => 'नया कार्य ट्री';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg2 ($arg3) पर एक नई स्थानीय शाखा के साथ $arg0/$arg1 बनाएँ।';
  }

  @override
  String get gitUiDestinationFolderName => 'गंतव्य फ़ोल्डर का नाम';

  @override
  String get gitUiRemoveWorktree => 'कार्य ट्री मिटाएँ?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'इस वर्कट्री के सभी स्थानीय ट्रैक और अनट्रैक बदलाव स्पष्ट रूप से हटाएँ। लॉक या उपयोग में मौजूद वर्कट्री सुरक्षित रहती हैं।';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'यदि वहाँ स्थानीय परिवर्तन हैं, तो Git फ़ाइलों को मिटाया जा रहा है, या तालाबंद कर रहा है.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'स्थानीय कार्य ट्री अंतर्वस्तु को छोड़ें और हटा दें';

  @override
  String get gitUiRemoveCleanWorktree2 => 'साफ कार्य ट्री';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'अद्यतन/ ऑस्टेंसाइजेशन के लिए सरल रूप से घोंसले में फिर से उभरता है';

  @override
  String get gitUiNoRecordedSubmodules => 'कोई दर्ज नहीं';

  @override
  String get gitUiNotInitialized => 'आरंभ नहीं किया';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'मूल रिपॉज़िटरी का gitlink: $arg0\nचेकआउट: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'डिरटी नेबेड भंडार';

  @override
  String get gitUiCleanNestedRepository => 'साफ नेबेड भंडार';

  @override
  String get gitUiNestedStatusUnavailable => 'नेड स्थिति अनुपलब्ध';

  @override
  String get gitUiEnterNestedRepository => 'नेबेड भंडार प्रविष्ट करें';

  @override
  String get gitUiInitializeConfiguration =>
      'कॉन्फ़िगरेशन प्रारंभ किया जा रहा है';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'माता - पिता के लिखित कार्यों को अद्यतन करें...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'केगेट को रिमोट शाखा कॉन्फ़िगर करें...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'कॉन्फ़िगर किए गए यूआरएल को सिंक्रोनाइज़ करें...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'चरण मौज़ूदा@ info: whatsthis';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'मूल रिपॉज़िटरी और सबमॉड्यूल के कमिट, पुश और बदलावों की स्थिति अलग रहती है। केवल ब्राउज़ करने से वे प्रारंभ या अपडेट नहीं होते।';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'कॉन्फ़िगर की गई रिमोट शाखा का कमिट फ़ेच करके चेकआउट करें। यह मूल रिपॉज़िटरी में दर्ज gitlink से अलग है। पुनरावर्ती: $arg0।';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'प्रारंभ करें तथा वास्तव में $arg0. पुनरावर्तन: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'समीक्षा उप- लॉक कॉन्फ़िगरेशन ऑपरेशन लागू करें. रिकर्सिवली: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'सब- मॉड्यूल ऑपरेशन लागू करें';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'दर्ज रिविज़न देखें या रिकवरी शाखा बनाएँ। reflog मनमानी बिना सहेजी या अनट्रैक सामग्री वापस नहीं ला सकता।';

  @override
  String get gitUiSelectAReflogEntry => 'रीलॉग प्रविष्टि चुनें';

  @override
  String get gitUiPreviousPage => 'पिछला पृष्ठ';

  @override
  String get gitUiNextPage => 'अगला पृष्ठ';

  @override
  String get gitUiRecoveryBranchName => 'टैग नाम';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return '$arg0 में शाखा बनाता है; काम करने के लिए फ़ाइलें तथा वर्तमान शाखा को अटूट किया जाता है.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'ठीक करने के लिए शाखा बनाएँ...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'सिर्फ पढ़ने के लिए स्नैपशॉट बहाल करें';

  @override
  String get gitUiInspectSnapshot => 'स्नेपशॉट का निरीक्षण करें...';

  @override
  String get gitUiReviewReset => 'रीसेट की समीक्षा करें…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'पृष्ठ $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Git पाठ इतिहास को अपने संपादन योग्य क्षेत्र को होना चाहिए.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'संपादित करें HEAD | इंडेक्स | कार्य ट्री…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'समीक्षा किया गया इंडेक्स या कार्यशील सामग्री बदल गई है। स्टेज करने से पहले यह तुलना ताज़ा करें।';

  @override
  String get gitUiRefreshComparison => 'तुलना ताज़ा करें';

  @override
  String get gitUiPreviousChangedFile => 'पिछला परिवर्तित फ़ाइल';

  @override
  String get gitUiNextChangedFile => 'अगला परिवर्तित फ़ाइल';

  @override
  String get gitUiPreviousDifference => 'पिछला भिन्नता';

  @override
  String get gitUiNextDifference => 'अगला भिन्नता';

  @override
  String get gitUiComparisonMode => 'तुलना मोड';

  @override
  String get gitUiSideBySide => 'अगल- बगल में';

  @override
  String get gitUiUnified => 'एकीकृत';

  @override
  String get gitUiDiffDisplayOptions => 'डिफ प्रदर्शक विकल्प';

  @override
  String get gitUiWrap => 'लपेटें';

  @override
  String get gitUiWords => 'शब्द';

  @override
  String get gitUiCollapseContext => 'संदर्भ समेटें';

  @override
  String get gitUiIgnoreWhitespace => 'श्वेतस्थान नज़र अंदाज़ करें';

  @override
  String get gitUiSearchComparison => 'तुलना खोजें';

  @override
  String get gitUiSearch => 'खोजें';

  @override
  String get gitUiCloseSearch => 'खोज बन्द करें';

  @override
  String get gitUiStagingActions => 'इंडेक्स की कार्रवाइयाँ';

  @override
  String get gitUiStagingActions2 => 'इंडेक्स की कार्रवाइयाँ…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'चुनी बदली पंक्तियाँ इंडेक्स से हटाएँ';

  @override
  String get gitUiStageSelectedChangedLines =>
      'चुनी बदली पंक्तियाँ इंडेक्स में जोड़ें';

  @override
  String get gitUiUnstageWholeFile => 'पूरी फ़ाइल इंडेक्स से हटाएँ';

  @override
  String get gitUiStageWholeFile => 'पूरी फ़ाइल इंडेक्स में जोड़ें';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 श्वेत रेखाओं को छुपाएँ';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 चयनित पंक्तियों को बदल दिया गया है तथा चरण्ड बाइट्स को कभी नहीं बदलता.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'केवल पढ़ने की तुलना · पाठ कॉपी करें या प्रदर्शन सेटिंग बदलें।';

  @override
  String get gitUiNoFinalNewline => ' · कोई अंतिम नई पंक्ति नहीं';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 बाइट$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'इन अंतर्वस्तु के लिए पाठ तुलना अनुपलब्ध है.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'यह तुलना टेक्स्ट समीक्षा की सीमा से अधिक है। सामग्री को समान घोषित नहीं किया गया है।';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'तुलना सामग्री एक जैसी हैं.';

  @override
  String get gitUiUnstage => 'मंच पर नहीं';

  @override
  String get gitUiStage => 'चरण';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 पंक्ति';
  }

  @override
  String get gitUiContext => 'संदर्भ';

  @override
  String get gitUiExpandUnchangedContext =>
      'अ- निर्दिष्ट संदर्भों का विस्तार करें';

  @override
  String get gitUiUnstageThisHunk => 'यह हंक इंडेक्स से हटाएँ';

  @override
  String get gitUiStageThisHunk => 'यह हंक इंडेक्स में जोड़ें';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'स्टेज की गई सामग्री संपादित करें · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'समीक्षा सूची परिणाम लिखा जा रहा है';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'इंडेक्स';

  @override
  String get gitUiWorkingTree => 'कार्य ट्री';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'निर्देशिका- लेबल- सामग्री- 8 ब्लॉब';

  @override
  String get gitUiUndo => 'पूर्ववत करें';

  @override
  String get gitUiRedo => 'फिर से करें';

  @override
  String get gitUiReloadIndexReview => 'निर्देशिका फिर से लोड करें?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'वर्तमान HEAD, इंडेक्स और कार्यशील संस्करण फिर लोड करें। यह इंडेक्स संपादक के बिना सहेजे मसौदे को बदलता है।';

  @override
  String get gitUiReplaceDraftAndReload => 'मसौदा और फिर लोड करें';

  @override
  String get gitUiReloadVersions => 'संस्करण फिर से लोड करें...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'इस निर्देशिका प्रविष्टि में संपादित परिणाम लिखें';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'कार्यशील फ़ाइल डिस्क में जारी है. लागू करने से पहले संपादित अनुक्रमणिका की समीक्षा करें.';

  @override
  String get gitUiReviewIndexTextFormatChanges => 'सूची पाठ फ़ॉर्मेट बदलें';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'केवल $arg0 की समीक्षा की गई इंडेक्स प्रविष्टि अपडेट करें।\n\n$arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => 'समीक्षा सूची परिणाम लिखें';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'समीक्षा के दौरान संपादित परिणाम बदल गया है. फिर से समीक्षा करें.';

  @override
  String get gitUiSynchronizeScrolling => 'सिंक्रोनाइज़';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'सिर्फ पढ़ने के लिए संशोधन सामग्री';

  @override
  String get gitUiEditableIndexContent => 'संशोधनीय सूची';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'निवेदित संशोधन वर्तमान फ़िल्टर के बाहर है. इसे प्रकट करने के लिए फ़िल्टर रीसेट करें.';

  @override
  String get gitUiFilterLog => 'फ़िल्टर लॉग';

  @override
  String get gitUiFilters => 'फ़िल्टर्स...';

  @override
  String gitUiFiltersCount(String count) {
    return 'फ़िल्टर्स ($count)...';
  }

  @override
  String get gitUiMessage => 'संदेश…';

  @override
  String get gitUiAuthor => 'लेखक…';

  @override
  String get gitUiPath => 'पथ...';

  @override
  String get gitUiDate => 'तारीख़...';

  @override
  String get gitUiMessageFilter => 'संदेश फ़िल्टर';

  @override
  String get gitUiAuthorFilter => 'लेखक फ़िल्टर';

  @override
  String get gitUiPathFilter => 'पथ फ़िल्टर';

  @override
  String get gitUiMessage2 => 'संदेश';

  @override
  String get gitUiAuthor2 => 'लेखक';

  @override
  String get gitUiPath2 => 'पथ';

  @override
  String get gitUiDateFilter => 'तिथि फिल्टर...';

  @override
  String get gitUiResetFilters => 'बल्सा फिल्टर';

  @override
  String get gitUiRefreshLog => 'लॉग ताज़ा करें';

  @override
  String get gitUiGoToCommitReference => 'कमिट/ संदर्भ पर जाएँ...';

  @override
  String get gitUiBackToHEAD => 'HEAD पर वापस';

  @override
  String get gitUiOrderedCherryPick => 'चुने गए क्रम में cherry-pick';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'चतुर्भुज- प्रधान ($arg0) समीक्षा करें...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'दो चयनित संशोधनों की तुलना करें...';

  @override
  String get gitUiToggleBranchesPane =>
      'यदि आप छवि के चमकीलेपन को वैसा ही रहने देना चाहते हैं तो इस बटन पर क्लिक करें.';

  @override
  String get gitUiFilterBranchesAndTags => 'फ़िल्टर शाखा तथा टैग';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'कमिट $arg0';
  }

  @override
  String get gitUiCommitDetails => 'कमिट विवरण...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'संदर्भ: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'यह कमिट चुनें';

  @override
  String get gitUiBranchOrTag => 'शाखा या टैग';

  @override
  String get gitUiAllReferences => 'सभी संदर्भ';

  @override
  String get gitUiLocal => 'स्थानीय';

  @override
  String get gitUiRemote => 'रिमोट';

  @override
  String get gitUiTags => 'टैग';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'वर्तमान फ़िल्टर से कोई मेल नहीं खाता.';

  @override
  String get gitUiObjectID => 'वस्तु ID';

  @override
  String get gitUiSubjectReferences => 'विषय / संदर्भ';

  @override
  String get gitUiDate2 => 'तारीख';

  @override
  String get gitUiGitCommits => 'Git कमिट';

  @override
  String get gitUiParents => 'पैरेंट कमिट';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 माता पिता';
  }

  @override
  String get gitUiLoadMoreCommits => 'और अधिक फाइल लोड करें';

  @override
  String get gitUiLoadingChangedFiles => 'परिवर्तित फ़ाइलें लोड की जा रही हैं';

  @override
  String get gitUiNoChangedFiles => 'कोई परिवर्तित फ़ाइल नहीं';

  @override
  String get gitUiSelectACommit => 'चुनें a फ़ाइल';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'मूल कमिट $arg0 से तुलना करें: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'बदली फ़ाइलें';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'लेखक: $arg0 <$arg1>\n$arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'कमिटर: $arg0 <$arg1>\n$arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'ऋणात्मक/partit सीमा: जनक वस्तु अनुपलब्ध है.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'अभिभावक इस पृष्ठ या एक ऊपरी सीमा के बाहर है.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'पैरेंट कमिट $arg0';
  }

  @override
  String get gitUiCommitActions => 'कमिट';

  @override
  String get gitUiEmptyTree => 'खाली ट्री';

  @override
  String get gitUiCreateBranch2 => 'शाखा बनाएँ';

  @override
  String get gitUiCreateTag => 'टैग बनाएँ';

  @override
  String get gitUiCompareRevisions => 'संशोधनों की तुलना करें';

  @override
  String get gitUiOpenSnapshot => 'स्नेपशॉट खोलें';

  @override
  String get gitUiRevertCommit => 'उलटें';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'इस किनारा के बाद अंतर्क्रियात्मक रीफ्रेम';

  @override
  String get gitUiResetCurrentBranch => 'वर्तमान शाखा रीसेट करें';

  @override
  String get gitUiCopyFullObjectID => 'पूर्ण वस्तु आईडी नक़ल करें';

  @override
  String get gitUiGoToCommitReference2 => 'जाएँ को';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'लॉग में प्रकट करने के लिए कोई कमिट आईडी या संदर्भ भरें.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'निवेदित संशोधन अनुपलब्ध है.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'रेपोसिटरी मेटाडाटा सिर्फ पढ़ने के लिए है. शाखा जाँच तथा तुलना उपलब्ध है.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'कार्य फ़ाइलें अनुपलब्ध हैं या सिर्फ पढ़ने योग्य नहीं हैं. शाखा स्विच तथा कैंचनिंग अनुपलब्ध हैं.';

  @override
  String get gitUiSearchBranchesAndTags => 'शाखाएँ और टैग खोजें';

  @override
  String get gitUiNewBranch => 'नई शाखा…';

  @override
  String get gitUiLocalBranches => 'स्थानीय शाखाएँ';

  @override
  String get gitUiRemoteBranches => 'रिमोट शाखाएँ';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'ट्रैक्स $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Z पर चेक्ड आउट$arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'अद्यतन किया जा रहा है...';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Z पर स्विच करें$arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'व्यस्त कार्य ट्री खोलें';

  @override
  String get gitUiCreateLocalTrackingBranch => 'स्थानीय ट्रैकिंग शाखा बनाएँ...';

  @override
  String get gitUiCompareToCurrentHEAD => 'वर्तमान HEAD से तुलना';

  @override
  String get gitUiMergeIntoCurrentBranch => 'मिलाएं शाखा';

  @override
  String get gitUiRename => 'नाम बदलें...';

  @override
  String get gitUiChangeUpstream => 'के- चर- संपादित करें...';

  @override
  String get gitUiDelete => 'मिटाएँ...';

  @override
  String get gitUiDeleteFromRemote => 'रिमोट से मिटाएँ...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Z के लिए क्रिया$arg0';
  }

  @override
  String get gitUiLocalBranchName => 'स्थानीय शाखा नाम';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return '$arg0 में बनाएँ. नया शाखा चेक आउट किया जाएगा.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'स्थानीय शाखा द्वारा ट्रैक $arg0 किया जाएगा और बाहर चेक किया जाएगा.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'मिटाने के लिए रिमोट चुनें';

  @override
  String get gitUiDeleteRemoteReference => 'रिमोट संदर्भ मिटाएँ';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Z को सम्मिलित करें$arg0 को $arg1 में';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Z का नाम बदलें$arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return '$arg0 का अपस्ट्रीम';
  }

  @override
  String get gitUiNoUpstream => 'कोई अपस्ट्रीम नहीं';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '$arg0 को मिटाएँ?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0\nलक्ष्य $arg1\nकेवल स्थानीय शाखा हटाएँ। मर्ज न हुई शाखा को हटाने से मना किया जाएगा।';
  }

  @override
  String get gitUiDelete2 => 'हटाएँ';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'अनमेर्ड शाखा Z को मिटाएँ$arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0\nGit के अनुसार यह शाखा पूरी तरह मर्ज नहीं हुई है। इसके कमिट देखने के बाद स्थानीय संदर्भ स्पष्ट रूप से हटाएँ; रिमोट प्रतियाँ नहीं बदलेंगी।';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => 'हटाएँ स्थानीय शाखा';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'गंतव्य: $arg0 $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'स्रोत शाखा या टैग';

  @override
  String get gitUiMergePolicy => 'सम्मिलित करने की नीति';

  @override
  String get gitUiFastForwardWhenPossible => 'जब संभव हो तो तेज- वृद्धि';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'हमेशा a मिलाएं';

  @override
  String get gitUiFastForwardOnly => 'सिर्फ तेज आगे';

  @override
  String get gitUiSquashIntoStagedChanges => 'स्टेज परिवर्तनों को सूचित करें';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'सम्मिलित करने के पहले बन्द करें';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'समीक्षा से पहले HEAD न बदले, इसलिए फ़ास्ट-फ़ॉरवर्ड बंद है।';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'अलग किए गए परिवर्तनों को छोड़ें; यह जारी नहीं है.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'साझा रेज़ोल्यूशन वर्क में परस्पर विरोध उपलब्ध रहते हैं.';

  @override
  String get gitUiAddRemote => 'रिमोट जोड़ें...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'प्राप्त: $arg0 दबाएँ: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'रिमोट मिटाएँ...';

  @override
  String get gitUiChangeFetchURL => 'यूआरएल ला रहे हैं...';

  @override
  String get gitUiAddPushDestination => 'पुश गंतव्य जोड़ें...';

  @override
  String get gitUiRemovePushDestination => 'पुश गंतव्य मिटाएँ...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Z का प्रबंधन करें$arg0';
  }

  @override
  String get gitUiRemoteName => 'रिमोट नाम';

  @override
  String get gitUiNewRemoteName => 'नया रिमोट नाम';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'रेपोसिटरी यूआरएल या स्थानीय श्रोत';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'मिटाने के लिए सटीक समीक्षा गंतव्य भरें.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'कॉन्फ़िगर सहायक या निजी प्राम्प्ट द्वारा प्रदान किया जाता है.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'रिमोट Z मिटाएँ$arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'स्थानीय रिमोट कॉन्फ़िगरेशन और ट्रैकिंग संदर्भ हटाता है। यह सर्वर की रिपॉज़िटरी नहीं हटाता।';

  @override
  String get gitUiRemoveRemote2 => 'हटाएँ रिमोट';

  @override
  String get gitUiCommitScopeEntireRepository => 'कमिट पूर्ण';

  @override
  String get gitUiCachedTracking => 'कैश ट्रैक किया जा रहा है';

  @override
  String get gitUiAmendLastCommit => 'पिछला कमिट संशोधित करें';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'हस्ताक्षर सक्षम किया गया है और हस्ताक्षर सम्मानित हैं.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'चुना हुआ HEAD कमिट दोबारा लिखता है। रिमोट ट्रैकिंग से यह साबित नहीं होता कि वह प्रकाशित नहीं है।';

  @override
  String get gitUiRepository => 'रिपॉज़िटरी';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'अलग किए गए $arg0';
  }

  @override
  String get gitUiLog => 'इतिहास';

  @override
  String get gitUiRepositoryActions => 'रिपॉज़िटरी कार्रवाइयाँ';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'कैश की गई ट्रैकिंग · $upstream · $ahead आगे · $behind पीछे';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'बारे भंडार (कोई कार्यशील पेड़ नहीं है. अपने इतिहास का निरीक्षण करने के लिए खुले लॉग खोलें.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'केवल भंडार भंडार पढ़ने और कार्य अनुपलब्ध है.';

  @override
  String get gitUiRepositoryStatusUnavailable => 'रेपोसिटरी स्थिति अनुपलब्ध';

  @override
  String gitUiAmendRevision(String revision) {
    return 'जिकॉन्फ़ $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'साइन-ऑफ़ पंक्ति जोड़ें';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'विन्यस्त हस्ताक्षर नीति इस्तेमाल करें';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'क्रिप्टोग्राफ़ी इस कमिट्स पर हस्ताक्षर करें';

  @override
  String get gitUiDoNotSignThisCommit => 'इस कमिट पर हस्ताक्षर नहीं करें';

  @override
  String get gitUiRecentCommitMessages => 'हालिया कमिट संदेश...';

  @override
  String get gitUiUseConfiguredCommitTemplate => 'कॉन्फ़िगर टैम्प्लेट...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'लेखक पहचान तथा विन्यस्त अंतराल...';

  @override
  String get gitUiDraftMessage => 'ड्राफ्ट संदेश...';

  @override
  String get gitUiCommitOptions => 'कमिट विकल्प';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'ड्राफ्ट मेमोरी में बना रहता है; इसे सहेजने में असफल. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'कमिट संदेश';

  @override
  String get gitUiGitOperationInProgress => 'Git प्रक्रिया प्रगति में है';

  @override
  String get gitUiCancel => 'रद्द करें';

  @override
  String get gitUiAmendStaged => 'आमीन- स्टेज्ड';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'स्टेज की गई सामग्री कमिट करें ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'कमिट करके पुश करें…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'कोई पढ़ने योग्य टैम्प्लेट कॉन्फ़िगर्ड नहीं है.';

  @override
  String get gitUiCommitIdentityAndHooks => 'कमिट पहचान तथा विकृतियाँ';

  @override
  String get gitUiRecentMessages => 'नवीनतम संदेश';

  @override
  String get gitUiReplaceMessageDraft => 'संदेश मसौदा बदलें?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'मौजूदा कमिट संदेश को चयनित संदेश से बदलें?';

  @override
  String get gitUiReplaceDraft => 'मसौदा बदलें';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'स्थानीय कमिट $arg0 मौजूद है।';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'स्थानीय कमिट $arg0 मौजूद है। फिर से कमिट करने से पहले लॉग की समीक्षा करें। संदेश का मसौदा सुरक्षित रखा गया है।';
  }

  @override
  String get gitUiCommitAuthorName => 'कमिट लेखक';

  @override
  String get gitUiCommitAuthorEmail => 'कमिट लेखक';

  @override
  String get gitUiConfiguredDefault => 'विन्यस्त डिफ़ॉल्ट';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'हस्ताक्षर: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'कॉन्फ़िगर्ड आंकड़े: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'साइन-ऑफ़ संदेश में एक वक्तव्य है, क्रिप्टोग्राफ़िक हस्ताक्षर से अलग। पहचान केवल इस रिपॉज़िटरी के स्थानीय कॉन्फ़िगरेशन में सहेजी जाती है; मसौदा सुरक्षित रहता है।';

  @override
  String get gitUiSaveRepositoryIdentity => 'भंडार पहचान सहेजें';

  @override
  String get gitUiStaged => 'इंडेक्स में';

  @override
  String get gitUiUntracked => 'ट्रैक नहीं की गईं';

  @override
  String get gitUiUnstaged => 'इंडेक्स के बाहर';

  @override
  String get gitUiConflicts => 'टकराव';

  @override
  String get gitUiNoChanges => 'कोई बदलाव नहीं';

  @override
  String get gitUiRepositoryChangeTree => 'रेपोसिटरी परिवर्तन ट्री';

  @override
  String get gitUiChanges => 'बदलाव';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'विस्तार';

  @override
  String get gitUiCollapse => 'समेटें';

  @override
  String get gitUiUnstageFile => 'फ़ाइल इंडेक्स से हटाएँ';

  @override
  String get gitUiStageFile => 'फ़ाइल इंडेक्स में जोड़ें';

  @override
  String get gitUiExpandGroup => 'समूह फैलाएँ';

  @override
  String get gitUiCollapseGroup => 'समूह सिकोड़ें';

  @override
  String get gitUiReviewDifference => 'अंतर की समीक्षा करें';

  @override
  String get gitUiUnstageSelectedFiles => 'चुनी फ़ाइलें इंडेक्स से हटाएँ';

  @override
  String get gitUiStageSelectedFiles => 'चुनी फ़ाइलें इंडेक्स में जोड़ें';

  @override
  String get gitUiFileHistoryAndBlame => 'फ़ाइल इतिहास तथा दोष...';

  @override
  String get gitUiDeleteUntrackedFile => 'हटाएँ- ट्रैक फ़ाइल...';

  @override
  String get gitUiDiscardUnstagedChange => 'गलत परिवर्तन फेंक दें...';

  @override
  String get gitUiFileHistory => 'फ़ाइल का इतिहास';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'फेंक दिया $arg0?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 बाइट · $arg1\nकार्यशील सामग्री को इंडेक्स से बदलता है, या इस अनट्रैक फ़ाइल को हटाता है। स्टेज की गई सामग्री बनी रहती है। पहले ऐप में बिना सहेजे दस्तावेज़ों की समीक्षा करें।';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'बिना- सहेजें फ़ाइल मिटाएँ';

  @override
  String get gitUiDiscardWorkingChange => 'परिवर्तनों को फेंक दें';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'रिमोट संदर्भ $arg0 हटाएँ';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'यह नीचे दिए हर वास्तविक पुश गंतव्य से संदर्भ हटाता है। स्थानीय शाखाएँ/टैग रखे जाते हैं। अपेक्षित शीर्ष कमिट इस समीक्षा से बँधे हैं।';

  @override
  String get gitUiReferenceDoesNotExist => 'संदर्भ मौजूद नहीं है';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 प्रस्ताव: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'रिमोट मिटाना सम्पन्न.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'रिमोट से $arg0 को मिटाएँ?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'ऊपर दिखाए गए गंतव्य के सटीक शीर्ष कमिट हटाए जाएँगे। कोई रिमोट शीर्ष बदलने पर कार्रवाई फिर से समीक्षा के लिए रुकती है।';

  @override
  String get gitUiReviewAndDeleteFromRemote => 'रिमोट से समीक्षा और मिटाएँ...';

  @override
  String get gitUiDestinationReference => 'गंतव्य संदर्भ';

  @override
  String get gitUiReviewDestinations => 'गंतव्यों की समीक्षा करें';

  @override
  String get gitUiNewRemoteBranch => 'नया रिमोट';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · अपेक्षित: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'गंतव्य में ऐसे कमिट हैं जो स्थानीय रूप से उपलब्ध नहीं हैं। भेजे जाने वाले इतिहास की समीक्षा से पहले उस समीक्षा किए गंतव्य को फ़ेच करें।';

  @override
  String get gitUiFetchReviewedDestination => 'पोस्टेड गंतव्य लाएँ';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'एक गंतव्य चुनें और बाहर जाने वाले निवेश पर पुनर्विचार करें.';

  @override
  String get gitUiNoOutgoingCommits => 'कोई बाहर जाने वाला कार्य नहीं है';

  @override
  String get gitUiSelectAnOutgoingCommit => 'बाहर जाने वाले कमिट को चुनें';

  @override
  String get gitUiLoadMoreOutgoingCommits =>
      'और अधिक बाहर जाने वाले क्रिया को लोड करें';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'इस गंतव्य को बतौर फोंट सेट करें';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'प्रकाशित करने के लिए सटीक टैग चुनें';

  @override
  String get gitUiTagsNone => 'टैगः कोई नहीं';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'टैग: $arg0 चुने गए';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'प्रकाशित करना : $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'दबाएँ पूर्ण. स्थानीय भंडारण लॉग में उपलब्ध है.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'बलपूर्वक पुश के लिए गंतव्य संदर्भों के सिरे इस समीक्षा में दिखाए गए सिरों से बिल्कुल मेल खाने चाहिए।';

  @override
  String get gitUiForceWithReviewedLease => 'समीक्षा के साथ बाध्य करें...';

  @override
  String get gitUiPush => 'पुश करें';

  @override
  String get gitUiForcePushWithReviewedLeases => 'समीक्षा के साथ धक्का?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return '$arg0 को तभी दोबारा लिखें जब हर रिमोट गंतव्य का शीर्ष कमिट ठीक वही हो जो ऊपर दिखाया गया है।\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'दूसरे लोग इस इतिहास का उपयोग कर रहे हो सकते हैं। बैकग्राउंड फ़ेच इस सुरक्षा शर्त को नवीकृत नहीं करेगा।';

  @override
  String get gitUiForceWithLease => 'के- लीवर्स के साथ बाध्य करें';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'एक और धक्का देने से पहले दोबारा खोजिए ।';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'मूल कमिट $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'पाने के लिए रिमोट';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches => 'पूर्व- ट्रैक शाखा';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'रद्दी की टोकरी को स्थानांतरित कर रहे फ़ाइलों को बदलने के बिना अद्यतन किए अद्यतन करें.';

  @override
  String get gitUiFetch => 'फ़ेच करें';

  @override
  String get gitUiSourceRemote => 'स्रोत रिमोट';

  @override
  String get gitUiSourceBranch => 'स्रोत शाखा';

  @override
  String get gitUiReviewedStrategy => 'समीक्षा की गई रणनीति';

  @override
  String get gitUiMerge => 'मर्ज करें';

  @override
  String get gitUiRebase => 'रीबेस करें';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'बंद करें यदि गंतव्य तेजी से आगे नहीं बढ़ सकता है; कभी सम्मिलित नहीं हों या फिर गलत.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'सम्मिलित करें a मिलाएं के साथ, जब तेज आगे संभव हो.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'सम्मिलित करें; जब संभव हो तो तेज- आगे जाएँ.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'स्थानीय सम्मिलित करने के दौरान अ-समय स्थानीय इतिहास.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'रिबेस स्थानीय एक लीनियर इतिहास के रूप में करता है.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git इंटरैक्टिव रीबेस के लिए कॉन्फ़िगर है। यहाँ स्पष्ट रूप से पुल रणनीति चुनें, या फ़ेच करके योजना की समीक्षा के लिए रीबेस खोलें।';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'इस खींचने के लिए चेक्ड सामान्य रीप्रेशन इस्तेमाल करें';

  @override
  String get gitUiOptions => 'विकल्प';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'हमेशा a मिलाएं (कोई तेज आगे नहीं)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'स्थानीय सम्मिलित करना सुरक्षित रखें';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'स्थानीय परिवर्तन खींचने से रोक सकते हैं. समीक्षा/ उन्हें दूर या प्रत्यक्ष रूप से एक पहचान बनाता है.';

  @override
  String get gitUiStashes => 'स्टैश';

  @override
  String get gitUiCreateOrReviewStash => 'बनाएँ या समीक्षा करें...';

  @override
  String get gitUiPullWithSelectedStrategy => 'चयनित रणनीति के साथ खींचो';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'रेपोसिटरी यूआरएल या स्थानीय Git श्रोत';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, एसएसएच, या स्थानीय पथ';

  @override
  String get gitUiFolderToInitialize => 'प्रारंभ करने के लिए फ़ोल्डर';

  @override
  String get gitUiFinalCloneDestination => 'फाइनल क्लोन गंतव्य';

  @override
  String get gitUiChoose => 'चुनें...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'मेटाडाटा सिर्फ तैयार करता है. मौज़ूदा फ़ाइलें मंच नहीं हैं या कार्यान्वित नहीं हैं.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'अंतिम गंतव्य मौजूद नहीं होना चाहिए या खाली होना चाहिए। मौजूदा उपयोगकर्ता डेटा कभी ओवरराइट नहीं किया जाएगा।';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'आरंभिक शाखा खाली Git नीति इस्तेमाल करता है';

  @override
  String get gitUiSelectedBranchOptional => 'चयनित शाखा';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'एक्सपोजरी प्रारंभ/ अप उपनिर्देशिका';

  @override
  String get gitUiPreparingGitOperation => 'तैयारी की जा रही है ...';

  @override
  String get gitUiThisAttemptCreated => 'इस प्रयास का सृजन किया गया';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'इस प्रयास से पहले गंतव्य मौजूद है:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'डिरेक्ट्री जाँच के लिए रह गया है. किसी अन्य क्लोन प्रयास से पहले समीक्षा करें.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'कोई गंतव्य डिरेक्ट्री नहीं रह गया है.';

  @override
  String get gitUiCancelProcess => 'प्रक्रिया रद्द करें';

  @override
  String get gitUiInitialize => 'आरंभ करें';

  @override
  String get gitUiClone => 'क्लोन करें';

  @override
  String get gitUiChooseNewBase => 'नया आधार चुनें';

  @override
  String get gitUiChooseUpstreamBoundary => 'अपस्ट्रीम सीमा चुनें';

  @override
  String get gitUiNewBase => 'नया आधार';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'अपस्ट्रीम सीमा · बाहर रखी गई';

  @override
  String get gitUiSameAsUpstreamBoundary => 'अपस्ट्रीम सीमा के समान';

  @override
  String get gitUiChooseBranchTagOrCommit => 'शाखा, टैग या कमिट चुनें…';

  @override
  String get gitUiUseUpstreamAsNewBase =>
      'नए आधार के रूप में बतौर प्लेलिस्ट प्रयोग करें';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'लॉग से एक वैध शाखा या टैग चुनें.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'शाखा ब्लॉक का पहला रखा गया कमिट squash या fixup नहीं हो सकता: उससे पहले कोई लक्ष्य कमिट नहीं है।';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'शाखा ब्लॉक $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[RRWENE नया संदेश आग्रह करेगा]\n';

  @override
  String get gitUiPlannedCommitMessages => 'प्लान किया गया संदेश';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'मूल/संयुक्त संदेश का पूर्वावलोकन · Git अंतिम रीवर्ड/स्क्वैश संदेश माँगेगा';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'परिणाम $arg0\n$arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'वर्तमान शाखा: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'अलग HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'रीबेस कमिट की पहचान बदलता है। रिमोट ट्रैकिंग जानकारी यह साबित नहीं करती कि इतिहास कभी प्रकाशित नहीं हुआ।';

  @override
  String get gitUiIncludeRootCommits => 'रूट कमिट शामिल करें';

  @override
  String get gitUiMergeCommits => 'सम्मिलित करता है';

  @override
  String get gitUiFlattenHistory => 'इतिहास रैखिक करें';

  @override
  String get gitUiPreserveBranchStructure => 'शाखाओं की संरचना रखें';

  @override
  String get gitUiAutosquash => 'स्वचालित कमिट संयोजन';

  @override
  String get gitUiPrepareGitPlan => 'Git योजना तैयार करें';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'फिर से लागू किए जाने वाले कमिट: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'इस शाखा से सभी रूट को शामिल करता है.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return '$boundary के बाद के कमिट $base पर दोबारा लागू होंगे; सीमा कमिट स्वयं शामिल नहीं होगा।';
  }

  @override
  String get gitUiRoot => 'रूट';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git शाखा/तंवर/रवेर इसी स्ट्रक्चर';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'साफ पुराना किनारा या रूट मोड चुनें, फिर योजना तैयार करें.';

  @override
  String get gitUiMoveUp => 'ऊपर ले जाएँ';

  @override
  String get gitUiMoveDown => 'नीचे ले जाएँ';

  @override
  String get gitUiResetPlan => 'योजना रीसेट करें';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · शाखा ब्लॉक $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'विवरण हेतु एक फ़ाइल चुनें तथा परिवर्तित फाइल चुनें';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'पूर्वावलोकन पूर्ण संदेशों को देखा जा रहा है...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ से चुना हुआ कमिट स्थानांतरित करें। असंबंधित शाखा संदर्भ अपने आप अपडेट नहीं होंगे।';

  @override
  String get gitUiCancelPlan => 'योजना रद्द करें';

  @override
  String get gitUiStartReviewedRebase => 'समीक्षित रीबेस शुरू करें?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return '$arg1 पर योजना के $arg0 कमिट दोबारा लिखें। हटाए जाने वाले कमिट शुरू करने तक योजना में चिह्नित रहते हैं।';
  }

  @override
  String get gitUiStartRebase => 'रीबेस शुरू करें';

  @override
  String get gitUiNoContinuingGitOperation => 'कोई जारी रखें परियोजना नहीं';

  @override
  String get gitUiStoppedForEditingAmend => ' · संपादन/je के लिए बन्द';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'ये इंडेक्स में अनमर्ज प्रविष्टियाँ हैं, संभवतः स्टैश लागू करने के कारण। Git में स्टैश जारी रखने या निरस्त करने का आदेश नहीं है।';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'कार्यशील फ़ाइलें संपादित करें, स्टेज करके वर्तमान कमिट संशोधित करें, फिर यह रीबेस जारी रखें।';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · अनमर्ज इंडेक्स चरण $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'निर्देशिका में कोई खराब प्रविष्टि नहीं है.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'वर्तमान कमिट को एक खाली कमिट के रूप में रखें';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'वास्तविक इंडेक्स में स्टेज किए बदलाव नहीं हैं। स्पष्ट रूप से खाली कमिट बनाएँ, फिर सीक्वेंसर सक्रिय हो तो जारी रखें।';

  @override
  String get gitUiKeepEmptyCommit => 'खाली कमिट रखें...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git प्रक्रिया की शुरुआत पर लौटने का प्रयास करेगा। पहले से मौजूद इंडेक्स के बाहर, अनट्रैक या असहेजी सामग्री की वापसी की गारंटी नहीं है।';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'छोड़ें और अगली योजना के साथ जारी रखें.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'मौजूदा फ़ाइलों तथा अनुक्रमणिका को रखे हुए इस ऑपरेशन की पुस्तक की निगरानी को भूल जाएँ.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'जारी रखें $arg0';
  }

  @override
  String get gitUiReloadConflictVersions =>
      'परस्पर विरोधों के संस्करण फिर से लोड करें?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'बिना सहेजे परिणाम मसौदे को वर्तमान कार्यशील फ़ाइल से बदलें। सहेजी गई कार्यशील सामग्री बनी रहती है।';

  @override
  String get gitUiLoadingConflictVersions =>
      'परस्पर विरोध संस्करण लोड किया जा रहा है...';

  @override
  String get gitUiLoadingConflict => 'विरोधाभास लोड किया जा रहा है';

  @override
  String get gitUiBaseLeft => 'बेस ETree छोड़ दिया गया';

  @override
  String get gitUiBaseRight => 'आधार ✔ सही';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'इस विरोधाभास में कोई आधार प्रविष्टि नहीं';

  @override
  String get gitUiAcceptEntireLeftFile => 'पूरी बाएं फ़ाइलों को स्वीकारें...';

  @override
  String get gitUiAcceptEntireRightFile => 'दाईं ओर की पूरी फ़ाइल स्वीकारें…';

  @override
  String get gitUiPreviousConflictRegion => 'पिछला विरोधाभास क्षेत्र';

  @override
  String get gitUiNextConflictRegion => 'अगला विरोधाभास क्षेत्र';

  @override
  String get gitUiManualResolution => 'मैनुअल विभेदन';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'क्षेत्र $arg0/$arg1 · $arg2 की समीक्षा हुई';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'स्रोत संरेखण पाठ तुलना सीमा से अधिक हो गया; स्रोत फलक हस्तचालित समीक्षा के लिए उपलब्ध हैं.';

  @override
  String get gitUiAcceptLeftRegion => 'बायाँ क्षेत्र स्वीकारें';

  @override
  String get gitUiAcceptRightRegion => 'दायाँ क्षेत्र स्वीकारें';

  @override
  String get gitUiKeepManualResultForRegion =>
      'क्षेत्र के लिए हस्तचालित परिणाम रखे रहें';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Git के अ- वर्गीकृत परिवर्तन लागू करें?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'वर्तमान परिणाम मसौदे को Git के मर्ज पूर्वावलोकन से बदलें। इससे बिना सहेजे मैनुअल संपादन हटते हैं; सहेजने तक कार्यशील फ़ाइल नहीं बदलती।';

  @override
  String get gitUiUseMergePreview => 'सम्मिलित पूर्वावलोकन इस्तेमाल करें';

  @override
  String get gitUiApplyNonConflictingChanges => 'परिवर्तन लागू करें...';

  @override
  String get gitUiLeftSource => 'बायाँ श्रोत';

  @override
  String get gitUiResult => 'परिणाम';

  @override
  String get gitUiRightSource => 'दायाँ श्रोत';

  @override
  String get gitUiStage2 => 'चरण 2';

  @override
  String get gitUiStage3 => 'चरण 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'विरोधी संस्करण अनुपलब्ध हैं ।';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'परिणाम डिस्क में सहेजा गया. निर्देशिका अभी भी निर्धारित करता है कि क्या यह फ़ाइल हल किया गया है.';

  @override
  String get gitUiSaveResultDraft => 'परिणाम का मसौदा सहेजें';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'परिणाम लागू कर समाधान इंडेक्स में जोड़ें';

  @override
  String get gitUiResultEditableUTF8WorkingContent => 'परिणाम';

  @override
  String get gitUiEditableConflictResult => 'संशोधनीय परस्पर विरोध परिणाम';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'बायाँ: $arg0 · $arg1\nदायाँ: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'सामग्री, हटाना या सबमॉड्यूल कमिट स्पष्ट रूप से चुनें। बाइनरी डेटा संपादन योग्य टेक्स्ट में डिकोड नहीं होता।';

  @override
  String get gitUiUseEntireLeftContent =>
      'सम्पूर्ण बायाँ सामग्री प्रयोग करें...';

  @override
  String get gitUiUseEntireRightContent =>
      'दाईं ओर की पूरी सामग्री इस्तेमाल करें…';

  @override
  String get gitUiDeleteThisPath => 'इस पथ को मिटाएँ...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'हल सब';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'जनक में इस सटीक लिंक को बन्द करें. यह बाहर या करें सब- मॉड्यूल को चेक नहीं करता या कमिट नहीं करता है.';

  @override
  String get gitUiSetResolvedGitlink => 'कमांड सेट करें... (g)';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'बेस चरण $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'परिणाम संपादित किया गया. हस्तचालित परिणाम रखे रहें या अन्य असक्रिय क्षेत्र चुनें.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return '«$arg0» समाधान लागू करें?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'चुना gitlink कमिट मूल रिपॉज़िटरी में स्टेज करें। सबमॉड्यूल का चेकआउट और उसकी फ़ाइलें नहीं बदलतीं।';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'पूरा कार्यशील पथ $arg0 बदलता है और निर्णय स्टेज करता है। वर्तमान कार्यशील सामग्री और बिना सहेजे परिणाम मसौदे हट जाएँगे।';
  }

  @override
  String get gitUiApplyEntireFileDecision => 'सम्पूर्ण फ़ाइल निर्णय लागू करें';

  @override
  String get gitUiStageThisConflictResolution =>
      'इस संघर्ष प्रस्ताव को चरण करें?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'पूरे संपादित परिणाम को $arg0 के रूप में उपयोग करें। Git स्टेज करने पर पथ को हल हुआ दर्ज करता है। पहले सभी आवश्यक सामग्री की समीक्षा करें।$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'लागू करके इंडेक्स में जोड़ें';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'परिणाम फ़ॉर्मेट परिवर्तनों की समीक्षा करें';

  @override
  String get gitUiSaveReviewedResult => 'समीक्षा परिणाम सहेजें';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'ने कहा गया सारणी पहुँच अनुपलब्ध है. अनुप्रयोग से फिर कोशिश करें.';

  @override
  String get gitUiSans => 'सैन्स';

  @override
  String get gitUiSelect => 'चुनें';

  @override
  String get gitUiContextMenu => 'कॉन्टेक्स्ट मेन्यू';

  @override
  String get gitUiCopyText => 'पाठ की नक़ल लें';

  @override
  String get gitUiLoadingRow => 'पंक्ति लोड किया जा रहा है';

  @override
  String get gitUiRetry => 'फिर से कोशिश करें';

  @override
  String get gitUiGitMessage => 'Git संदेश';

  @override
  String get gitUiCancelPrompt => 'प्राम्प्ट रद्द करें';

  @override
  String get gitUiUseMessageAndContinue => 'संदेश का उपयोग करें और जारी रखें';

  @override
  String get gitUiRespondPrivately => 'निजी रूप में जवाब दें';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'दृश्य प्राथमिकताएँ सहेजी नहीं जा सकीं: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'कमिट भंडारण: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'दृश्य प्राथमिकताएँ पढ़ी नहीं जा सकीं: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'कमिट ड्राफ्ट स्मरण में रखा गया था, परंतु सहेजा नहीं जा सका: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'समीक्षा भंडार इस ऑपरेशन के लिए केवल पढ़ने के लिए है. इतिहास और सामग्री जाँच उपलब्ध हैं.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git $arg0. अनुप्रयोग अपने दस्तावेज़ों को ताज़ा नहीं कर सका: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'इतिहास से कमिट चुनें…';

  @override
  String get gitUiCurrentBranch => 'वर्तमान शाखा';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'कोई मेल- बक्सा नहीं या टैग चुनें. लॉग में a चुनें.';

  @override
  String get gitUiBranches => 'शाखाएँ';

  @override
  String get gitUiPushCommits => 'कमिट पुश करें';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Z में जाएँ$arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'भंवर $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'मौजूदा ऑपरेशन';

  @override
  String get gitUiRebaseCommits => 'कमिट रीबेस करें';

  @override
  String get gitUiFetch2 => 'फ़ेच करें…';

  @override
  String get gitUiPull => 'पुल करें…';

  @override
  String get gitUiPush2 => 'पुश करें…';

  @override
  String get gitUiBranches2 => 'शाखाएँ…';

  @override
  String get gitUiManageRemotes => 'रिमोट प्रबंधित करें…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Z में सम्मिलित करें$arg0...';
  }

  @override
  String get gitUiRebase2 => 'रीबेस करें…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'परस्पर विरोध तथा वर्तमान ऑपरेशन...';

  @override
  String get gitUiStashes2 => 'स्टैश…';

  @override
  String get gitUiWorktrees => 'कार्य ट्री…';

  @override
  String get gitUiSubmodules => 'सबमॉड्यूल…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog और पुनर्प्राप्ति…';

  @override
  String get gitUiCloneRepository => 'रिपॉज़िटरी क्लोन करें…';

  @override
  String get gitUiRevokeRepositoryTrust => 'रिपॉज़िटरी पर भरोसा वापस लें';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'भण्डार स्थिति के लिए प्रतीक्षारत';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'रेपोसिटरी स्थिति अनुपलब्ध';

  @override
  String get gitUiManageRemotes2 => 'रिमोट प्रबंधित करें';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Z में सम्मिलित करें$arg0';
  }

  @override
  String get gitUiWorktrees2 => 'कार्य ट्री';

  @override
  String get gitUiSubmodules2 => 'सबमॉड्यूल';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog और पुनर्प्राप्ति';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'क्लोन भंडार $arg0';
  }

  @override
  String get gitUiApply => 'लागू करें';

  @override
  String get gitUiResizeGitPanes => 'टाइल आकार बदलें';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 प्रतिशत';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'बाहर स्थिति: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'रेपोसिटरी बदल गया. फिर से कोशिश करने से पहले पुनः समीक्षा करें.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'एक और ऑपरेशन में भंडार या इंडेक्स ताला लगा है ।';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'रेपोसिटरी भरोसेमंद इस संक्रिया के लिए आवश्यक है.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      '\"%s\" सेवा असंबंधित हो गया. भंडार को फिर से कनेक्ट करे.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'इंस्टॉल किया गया Git इस कार्रवाई का समर्थन नहीं करता। नीचे इसकी रनटाइम आवश्यकताओं की समीक्षा करें।';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'यह भंडार सिर्फ निवेदित ऑपरेशन के लिए पढ़ा हुआ है. समीक्षा तथा इतिहास उपलब्ध है.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'इस कार्रवाई की स्थिति का मिलान ज़रूरी है। दोहराने से पहले परिणामी रिपॉज़िटरी या रिमोट स्थिति की समीक्षा करें।';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git सत्यापन असफल. महत्व सहायक या विन्यस्त के लिए ताला खोलने में असफल.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'एसएसएच होस्ट प्रमाणीकरण असफल. अपने कॉन्फ़िगर किए गए एसएसएच औज़ारों के माध्यम से होस्ट पहचान समीक्षा करें.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'कमिट पर हस्ताक्षर विफल हुआ या रद्द किया गया। हस्ताक्षर कुंजी, एजेंट और कॉन्फ़िगर किए हस्ताक्षर टूल की समीक्षा करें।';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'भंडार लेखक नाम तथा ईमेल सेट करें, तब सहेजा गया संदेश मसौदा में वापस जाएँ.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git ने समीक्षा अद्यतन अस्वीकार किया. फिर से कोशिश करने से पहले वास्तविक गंतव्य को ताज़ा करें और फिर से समीक्षा करें.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'काम करने या मंच पर किए गए बदलावों से इस क्रिया को रोका जा सकता है ।';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'आवश्यक Git ऑब्जेक्ट उपलब्ध नहीं है। शैलो या आंशिक रिपॉज़िटरी की सीमाओं की समीक्षा करें और ज़रूरत होने पर स्पष्ट रूप से फ़ेच करें।';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git ऑपरेशन असफल: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'जाँच';

  @override
  String get gitUiAuthorizeGitInspection =>
      'Git जाँच को प्राधिकृत किया जा रहा है...';

  @override
  String get gitUiCopyDiagnostics => 'निदान नक़ल करें';

  @override
  String get gitUiActions => 'कार्रवाइयाँ';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return '$arg0 में शाखा';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'बिना जाँच के स्थानीय शाखा बनाता है.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'टैग $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'सिर्फ पढ़ने के लिए स्नैपशॉट $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'चुने हुए कमिट लागू करें';

  @override
  String get gitUiRevertCommits => 'उलटें';

  @override
  String get gitUiCompareToFullRevisionID => 'पूरा संशोधन आईडी से तुलना करें';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'ट्री तुलना दिशा: ${arg0}X  पकड़े गए संशोधन यहाँ आए थे.';
  }

  @override
  String get gitUiEnterAFullValidObjectID => 'पूरी वैध वस्तु आईडी भरें.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · ट्री तुलना';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '$arg0 को $arg1 में रीसेट करें';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'HEAD/वर्तमान शाखा बदलता है। reflog किसी भी मनमानी अनट्रैक या बिना सहेजी सामग्री को पुनर्प्राप्त नहीं करता।';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'HEAD बदलें; इंडेक्स और कार्य फ़ाइलें बनाए रखें।';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'HEAD बदलें और इंडेक्स बदलें; कार्य फ़ाइलें बनाए रखें।';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'HEAD, इंडेक्स और ट्रैक की गई कार्य फ़ाइलें बदलें; बाधा डालने वाली अनट्रैक फ़ाइलें ओवरराइट हो सकती हैं।';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'HEAD, इंडेक्स और उपयुक्त फ़ाइलें बदलें; स्थानीय बदलाव खोने पर कार्रवाई अस्वीकार करें।';

  @override
  String gitUiResetWithArg0(String arg0) {
    return '$arg0 के साथ रीसेट करें?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1\nलागू करने से पहले चुने गए मोड के प्रभावों की समीक्षा करें।';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'रीसेट $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'लक्ष्य $arg0';
  }

  @override
  String get gitUiTagName => 'टैग का नाम';

  @override
  String get gitUiAnnotatedTag => 'टिप्पणी वाला टैग';

  @override
  String get gitUiCryptographicSigning => 'क्रिप्टोग्राफ़िक हस्ताक्षर';

  @override
  String get gitUiConfiguredPolicy => 'कॉन्फ़िगर किया जाने वाला पॉलिसी';

  @override
  String get gitUiSignThisTag => 'इस टैग को हस्ताक्षर करें';

  @override
  String get gitUiDoNotSign => 'हस्ताक्षर नहीं करें';

  @override
  String get gitUiTagMessage => 'संदेश का नक़ल लें';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'टैग स्थानीय रूप से बनाता है. सार्वजनिक समीक्षा में चुने गए टैगों को साफ- साफ सूचना दें.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'पूरे ट्री: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'अगला परिवर्तित- फ़ाइल पृष्ठ';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'सिर्फ पढ़ने के लिए भंडार स्नैपशॉट खोला जा रहा है. फ़ाइल खोलने में यह संशोधन बाहर की जाँच कभी नहीं करता.';

  @override
  String get gitUiOpenReadOnlyVersion => 'सिर्फ पढ़ने के लिए संस्करण खोलें';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'इस पथ को बहाल करें...';

  @override
  String get gitUiRestoreThisPath => 'इस पथ को बहाल करें...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'इतिहास $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '$arg0 बहाल करें?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'इस कार्यशील पथ को रिविज़न $arg0 से बदलें। पहले से स्टेज की गई सामग्री बनी रहती है।';
  }

  @override
  String get gitUiRestoreWorkingFile => 'फाइल बहाल करें';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'नाम बदलने को ट्रैक करती फ़ाइल हिस्ट्री · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'पंक्ति इतिहास · कमिट की सामग्री';

  @override
  String get gitUiBlame => 'पंक्ति इतिहास…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 कार्यशील ट्री';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'सिर्फ पढ़ने लायक ऐतिहासिक फ़ाइल खोलें';

  @override
  String get gitUiCompareToCurrentFile => 'वर्तमान फ़ाइल की तुलना करें';

  @override
  String get gitUiCompareToParent => 'जनक से तुलना करें...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'कमिट किया गया $arg0 · संपादक की बिना सहेजी सामग्री इन टिप्पणियों में शामिल नहीं है';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return '$arg0 से इतिहास';
  }

  @override
  String get gitUiBoundary => ' · सीमा';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nमूल पंक्ति $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'पिछली पंक्तियाँ';

  @override
  String get gitUiNextLines => 'अगला पंक्तियाँ';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'स्पष्ट लागू करने का क्रम · गंतव्य $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'पूरा कमिट वस्तु आईडी जोड़ें';

  @override
  String get gitUiAddReviewedCommit => 'समीक्षा किए गए कमिटों को जोड़ें...';

  @override
  String get gitUiMoveEarlier => 'पहले खिसकाएँ';

  @override
  String get gitUiMoveLater => 'बाद में खिसकाएँ';

  @override
  String get gitUiRemoveFromReviewedSequence => 'समीक्षा अनुक्रम से मिटाएँ';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'परिवर्तनों को बिना समान बनाने के लिए लागू करें';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'सम्मिलित करने के लिए इस विशिष्ट पंक्ति जनक इस्तेमाल करें';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'खाली या पहले से ही जो कुछ हुआ है वह Gincacko को बन्द कर सकता है या फिर से जारी रखने का निर्णय कर सकता है.';

  @override
  String get gitUiRevertInReviewedOrder => 'समीक्षा अनुक्रम में वापस जाएँ';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'डाउनलोड अनुक्रम में चेरी- इम्यूरी- मेंटेनर';

  @override
  String get gitUiReturnToFiles => 'फ़ाइलों में वापस जाएँ';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'कमिट करें';

  @override
  String get gitUiBackToCommit => 'पीछे से कमिट';

  @override
  String get gitUiSelectAChangeToReview => 'समीक्षा के लिए एक परिवर्तन चुनें';

  @override
  String get gitUiLoadingBranch => 'शाखा लोड किया जा रहा है...';

  @override
  String get gitUiBranchUnavailable => 'शाखा अनुपलब्ध';

  @override
  String get gitUiUnbornHEAD => 'कमिट रहित HEAD';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'अलग HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'जारी रखें';

  @override
  String get gitUiPick => 'रखें';

  @override
  String get gitUiReword => 'संदेश बदलें';

  @override
  String get gitUiEdit => 'संपादित करें';

  @override
  String get gitUiSquash => 'कमिट जोड़ें';

  @override
  String get gitUiFixup => 'संदेश छोड़कर जोड़ें';

  @override
  String get gitUiDrop => 'छोड़ दें';

  @override
  String get gitUiAbort => 'प्रक्रिया निरस्त करें';

  @override
  String get gitUiSkip => 'छोड़कर आगे बढ़ें';

  @override
  String get gitUiQuit => 'ऑपरेशन से बाहर जाएँ';

  @override
  String get gitUiSoft => 'सॉफ़्ट';

  @override
  String get gitUiMixed => 'मिश्रित';

  @override
  String get gitUiHard => 'हार्ड';

  @override
  String get gitUiKeep => 'सुरक्षित रखें';

  @override
  String get gitUiCreate => 'बनाएँ';

  @override
  String get gitUiApplyStash => 'स्टैश लागू करें';

  @override
  String get gitUiPopStash => 'स्टैश लागू कर सफलता पर हटाएँ';

  @override
  String get gitUiDropStashAction => 'स्टैश हटाएँ';

  @override
  String get gitUiEditedResult => 'संपादन परिणाम';

  @override
  String get gitUiLeftContent => 'बायाँ विषय सूची';

  @override
  String get gitUiRightContent => 'दायाँ सामग्री';

  @override
  String get gitUiDeletePath => 'पथ मिटाएँ';

  @override
  String get gitUiSubmoduleCommit => 'उप';

  @override
  String get gitUiPresentContent => 'उपलब्ध';

  @override
  String get gitUiAbsentContent => 'अवमानित';

  @override
  String get gitUiBinaryContent => 'द्विचर सामग्री';

  @override
  String get gitUiTooLargeContent => 'प्रदर्शन सीमा से अधिक विषयवस्तु';

  @override
  String get gitUiUnavailableContent => 'अनुपलब्ध सामग्री';

  @override
  String get gitUiGitlinkContent => 'सब् रोकने वाला संकेतक';

  @override
  String get gitUiSymlinkContent => 'सिंबालिक लिंक्स का पालन करें (_F)';

  @override
  String get gitUiNoOperation => 'कोई क्रिया नहीं';

  @override
  String get gitUiCherryPickOperation => 'चुना कमिट लागू करें';

  @override
  String get gitUiRevertOperation => 'रिवर्ट करें';

  @override
  String get gitUiApplyMailboxOperation => 'लागू करें पैचेस';

  @override
  String get gitUiSquashOperation => 'स्काज सम्मिलित करें';

  @override
  String get gitUiUnmergedOperation => 'अ- संपीडित इंडेक्स';

  @override
  String get gitUiWaitingForPromptPhase => 'प्रतिक्रिया के लिए प्रतीक्षारत';

  @override
  String get gitUiStoppedPhase => 'समीक्षा के लिए रुक गया';

  @override
  String get gitUiCompletedPhase => 'पूर्ण';

  @override
  String get gitUiFailedPhase => 'विफल';

  @override
  String get gitUiCancelledPhase => 'रद्द किया गया';

  @override
  String get gitUiUncertainPhase => 'परिणाम मेल मिलाप की आवश्यकता है';

  @override
  String gitUiStageVersion(String stage) {
    return 'परस्पर विरोधी स्टेज $stage';
  }

  @override
  String get gitUiGitMergePreview => 'सम्मिलित पूर्वावलोकन';

  @override
  String get gitUiNormalizedWorking => 'कार्यशील ट्री एगल्ड';

  @override
  String gitUiPercentValue(String value) {
    return '$value प्रतिशत';
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
  String get gitUiUtf8Bom => 'बाइट दृश्य के साथ UTF-8 (BOM)';

  @override
  String get gitUiUtf8NoBom => 'यूटीएफ़-क्रम चिह्न के बगैर (BOM)';

  @override
  String get gitUiAddsBom =>
      'यह संपादन एक यूटीएफ़-क्रम चिह्न को फ़ाइल के प्रारंभ में जोड़ता है.';

  @override
  String get gitUiRemovesBom =>
      'यह संपादन यूटीएफ़-क्रम चिह्न को फ़ाइल के प्रारंभ से हटाता है.';

  @override
  String get gitUiNoLineTerminators => 'कोई लाइन शब्द नहीं';

  @override
  String gitUiLineEndings(String format) {
    return '$format पंक्ति अंत';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'मिक्स लाइन समाप्त होता है ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'पंक्ति-अंत का प्रारूप $before से $after में बदलता है। क्लिपबोर्ड के टेक्स्ट में मूल फ़ाइल से अलग पंक्ति-अंत हो सकते हैं।';
  }

  @override
  String get gitUiGitFailure => 'Git प्रक्रिया असफल. नीचे जाँच करें';

  @override
  String get gitUiAbortInline => 'प्रक्रिया निरस्त करें';

  @override
  String get gitUiSkipInline => 'छोड़कर आगे बढ़ें';

  @override
  String get gitUiQuitInline => 'बाहर हों';

  @override
  String get gitUiMergeInline => 'मर्ज करें';

  @override
  String get gitUiRebaseInline => 'रीबेस करें';

  @override
  String get gitUiCherryPickInline => 'चुना कमिट लागू करें';

  @override
  String get gitUiRevertInline => 'रिवर्ट करें';

  @override
  String get gitUiApplyMailboxInline => 'डाकबाक्स लागू करें';

  @override
  String get gitUiSquashInline => 'कमिट जोड़ें';

  @override
  String get gitUiUnmergedInline => 'अ- धातु';

  @override
  String get gitHostFetch => 'फ़ेच करें';

  @override
  String get gitHostRefreshGitStatus => 'cdrecord स्थिति ताज़ा करें';

  @override
  String get gitHostCommitStaged => 'सबको कमिट करें';

  @override
  String get gitHostGitBranches => 'Git शाखा';

  @override
  String get gitHostReviewPush => 'समीक्षा पुश';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git कार्रवाइयाँ इस पूरी रिपॉज़िटरी पर लागू होती हैं और उसके कॉन्फ़िगर किए हुक, फ़िल्टर, क्रेडेंशियल और हस्ताक्षर टूल चला सकती हैं।';

  @override
  String get gitHostContentUnavailable => 'अनुपलब्ध';

  @override
  String get gitHostInitializeRepository => 'रिपॉज़िटरी आरंभ करें';

  @override
  String get gitHostCloneRepository => 'रिपॉज़िटरी क्लोन करें';

  @override
  String get gitHostInitializeHere => 'यहाँ प्रारंभ करें...';

  @override
  String get gitHostCloneRepository2 => 'रिपॉज़िटरी क्लोन करें…';

  @override
  String get gitHostGitLog => 'Git लॉग';

  @override
  String get gitUiAbsentPlaceholder => '(अशुभ)';

  @override
  String get gitUiUnborn => 'अजन्मे बच्चे';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'रीबेस किया इतिहास · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'वर्तमान इतिहास · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'दोबारा लागू कमिट · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'आने वाली सामग्री · $revision';
  }

  @override
  String get gitUiContentConflict => 'विरोधाभास विरोध';

  @override
  String get gitUiSubmoduleConflict => 'सब- कुंजी विरोधाभास';

  @override
  String get gitUiSymlinkConflict => 'सिंबालिक विरोधाभास';

  @override
  String get gitUiAddAddConflict => 'दोनों तरफ जोड़ी गई';

  @override
  String get gitUiModifyDeleteConflict =>
      'परिवर्धित/ मिटाएँ या परिवर्धित करें/ मिटाएँ';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
