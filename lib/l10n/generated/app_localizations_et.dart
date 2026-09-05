// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Markdowni failide ja Writerside’iga ühilduvate dokumentatsiooniprojektide redaktor.';

  @override
  String get aboutBusyMark => 'Teave BusyMarki kohta';

  @override
  String get aboutTagline => 'Markdowni ja Writerside’i redaktor';

  @override
  String get aboutLicenseLabel => 'Litsents';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Veebisait';

  @override
  String get aboutSourceCode => 'Lähtekood';

  @override
  String get reportIssue => 'Teata probleemist';

  @override
  String get feedbackCategory => 'Kategooria';

  @override
  String get feedbackChooseCategory => 'Vali kategooria';

  @override
  String get feedbackCategoryProblem => 'Probleem või viga';

  @override
  String get feedbackCategoryFeature => 'Funktsioonisoov';

  @override
  String get feedbackCategoryPrivacySecurity => 'Privaatsus- või turvamure';

  @override
  String get feedbackCategoryUsability => 'Kasutatavusmure';

  @override
  String get feedbackCategoryOther => 'Muu';

  @override
  String get feedbackSubject => 'Teema';

  @override
  String get feedbackMessage => 'Üksikasjalik sõnum';

  @override
  String get feedbackReplyEmail =>
      'E-posti aadress vastuse saamiseks (valikuline)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Lisa tehnilised andmed';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Kui see on lubatud, lisatakse ainult Linuxi operatsioonisüsteemi versioon ja BusyMarki rakenduse lokaat. Logisid, faile, kontoandmeid ega muid diagnostikaandmeid ei lisata.';

  @override
  String get feedbackSubmit => 'Saada';

  @override
  String get feedbackSubmitting => 'Saatmine…';

  @override
  String get feedbackCategoryRequired => 'Vali kategooria.';

  @override
  String get feedbackSubjectLength => 'Teema peab olema 3–120 märki pikk.';

  @override
  String get feedbackMessageLength => 'Sõnum peab olema 10–5000 märki pikk.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Sisesta kehtiv e-posti aadress või jäta see väli tühjaks.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark ei saanud ühendust luua. Kontrolli internetiühendust ja proovi uuesti.';

  @override
  String get feedbackTimeoutFailure => 'Päring aegus. Proovi uuesti.';

  @override
  String get feedbackRateLimitedFailure =>
      'Selle ühenduse kaudu saadeti liiga palju teateid. Oota ja proovi uuesti.';

  @override
  String get feedbackRejectedFailure =>
      'Server lükkas teate tagasi. Kontrolli vormivälju ja proovi uuesti.';

  @override
  String get feedbackServerFailure =>
      'Server ei saanud teadet vastu võtta. Proovi hiljem uuesti.';

  @override
  String feedbackSuccess(String id) {
    return 'Tagasiside saadetud. Viite ID: $id';
  }

  @override
  String get advanced => 'Täpsemad sätted';

  @override
  String get addToGit => 'Lisa Giti';

  @override
  String get appearance => 'Välimus';

  @override
  String get apply => 'Rakenda';

  @override
  String get back => 'Tagasi';

  @override
  String get bottomLeft => 'All vasakul';

  @override
  String get bottomRight => 'All paremal';

  @override
  String get cancel => 'Tühista';

  @override
  String get choose => 'Vali';

  @override
  String get chooseLocation => 'Vali asukoht';

  @override
  String get copy => 'Kopeeri';

  @override
  String get copyName => 'Kopeeri nimi';

  @override
  String get copyFileName => 'Kopeeri failinimi';

  @override
  String get copyPath => 'Kopeeri tee';

  @override
  String get create => 'Loo';

  @override
  String get creating => 'Loomine…';

  @override
  String get cut => 'Lõika';

  @override
  String get promoteSection => 'Tõsta jaotise taset';

  @override
  String get demoteSection => 'Langeta jaotise taset';

  @override
  String get moveSectionUp => 'Liiguta jaotis üles';

  @override
  String get moveSectionDown => 'Liiguta jaotis alla';

  @override
  String get confirmDeleteSectionTitle => 'Kas kustutada jaotis?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Kas kustutada „$name” ja kogu selle jaotise sisu? Seda toimingut ei saa tagasi võtta.';
  }

  @override
  String get darkTheme => 'Tume';

  @override
  String get delete => 'Kustuta';

  @override
  String get discard => 'Hülga';

  @override
  String get editor => 'Redaktor';

  @override
  String get file => 'Fail';

  @override
  String get fileHistory => 'Faili ajalugu';

  @override
  String get folder => 'Kaust';

  @override
  String get insert => 'Lisa';

  @override
  String get keyboardShortcuts => 'Kiirklahvid';

  @override
  String get commandPalette => 'Käskude palett';

  @override
  String get commandPaletteHint => 'Sisesta käsk';

  @override
  String get commandPaletteEmpty => 'Sobivaid käske pole';

  @override
  String get commandUnavailableInContext =>
      'See käsk pole praeguses kontekstis saadaval.';

  @override
  String get lightTheme => 'Hele';

  @override
  String get mainMenu => 'Peamenüü';

  @override
  String get fullScreen => 'Täisekraan';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Ava';

  @override
  String get openInFiles => 'Ava failihalduris';

  @override
  String get pathActions => 'Failitee toimingud';

  @override
  String get outline => 'Liigendus';

  @override
  String get overwrite => 'Kirjuta üle';

  @override
  String get paste => 'Aseta';

  @override
  String get pasteWithoutFormatting => 'Aseta vorminduseta';

  @override
  String get reading => 'Lugemisvaade';

  @override
  String get removeFromRecent => 'Eemalda hiljutiste seast';

  @override
  String get recent => 'Hiljutised';

  @override
  String get redo => 'Tee uuesti';

  @override
  String get save => 'Salvesta';

  @override
  String get search => 'Otsi';

  @override
  String get selectAll => 'Vali kõik';

  @override
  String get settings => 'Sätted';

  @override
  String get source => 'Lähtekood';

  @override
  String get split => 'Kõrvuti';

  @override
  String get systemTheme => 'Süsteem';

  @override
  String get theme => 'Kujundus';

  @override
  String get appLanguage => 'Keel';

  @override
  String get systemLanguage => 'Süsteemi keel';

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
  String get toggleSidebar => 'Külgpaneel';

  @override
  String get topLeft => 'Ülal vasakul';

  @override
  String get topRight => 'Ülal paremal';

  @override
  String get undo => 'Võta tagasi';

  @override
  String get validate => 'Valideeri';

  @override
  String get validation => 'Valideerimine';

  @override
  String get viewMode => 'Vaaterežiim';

  @override
  String get welcome => 'Tere tulemast';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Pildid';

  @override
  String get openMarkdownFile => 'Ava Markdowni fail';

  @override
  String get markdownFileExtensions => '.md või .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Ava kaust või Writerside’i projekt';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdowni kaust või Writerside’iga ühilduv projekt';

  @override
  String get noOpenFile => 'Ühtegi faili pole avatud';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Kustuta failivaates valitud üksus või eemalda valitud teema sisukorrast';

  @override
  String get shortcutGroupGeneral => 'Üldine';

  @override
  String get shortcutNewDocument => 'Loo';

  @override
  String get shortcutNewDocumentDescription =>
      'Loo Markdowni fail või Writerside’i projekt';

  @override
  String get shortcutOpenDescription =>
      'Ava Markdowni fail, kaust või Writerside’i projekt';

  @override
  String get shortcutSaveDescription => 'Salvesta praegune dokument';

  @override
  String get shortcutSearchDescription => 'Otsi praegusest tööruumist';

  @override
  String get shortcutKeyboardShortcutsDescription => 'Kuva kiirklahvide loend';

  @override
  String get shortcutSyntaxReferenceDescription => 'Ava süntaksiviide';

  @override
  String get shortcutSettingsDescription => 'Ava BusyMarki sätted';

  @override
  String get shortcutNextTab => 'Järgmine vahekaart';

  @override
  String get shortcutNextTabDescription =>
      'Liigu järgmisele avatud vahekaardile';

  @override
  String get shortcutPreviousTab => 'Eelmine vahekaart';

  @override
  String get shortcutPreviousTabDescription =>
      'Liigu eelmisele avatud vahekaardile';

  @override
  String get shortcutCloseTab => 'Sulge vahekaart';

  @override
  String get shortcutCloseTabDescription => 'Sulge aktiivne vahekaart';

  @override
  String get shortcutCloseAllTabs => 'Sulge kõik vahekaardid';

  @override
  String get shortcutCloseAllTabsDescription => 'Sulge kõik avatud vahekaardid';

  @override
  String get shortcutGroupTextEditing => 'Teksti redigeerimine';

  @override
  String get shortcutSelectAllDescription =>
      'Vali lähtekoodirežiimis kogu tekst; redaktorirežiimis vajuta kaks korda, et valida kõik plokid';

  @override
  String get shortcutCutDescription => 'Lõika valitud tekst';

  @override
  String get shortcutCopyDescription => 'Kopeeri valitud tekst';

  @override
  String get shortcutPasteDescription => 'Aseta lõikelaualt';

  @override
  String get shortcutPastePlainTextDescription =>
      'Aseta lõikelaua tekst vorminduseta';

  @override
  String get shortcutUndoDescription => 'Võta viimane muudatus tagasi';

  @override
  String get shortcutRedoDescription => 'Taasta viimati tagasivõetud muudatus';

  @override
  String get shortcutInsertIndentation => 'Sisesta taane';

  @override
  String get shortcutInsertIndentationDescription =>
      'Sisesta kursori asukohta taane';

  @override
  String get shortcutOutdentSource => 'Vähenda lähtekoodi taanet';

  @override
  String get shortcutOutdentSourceDescription =>
      'Eemalda lähtekoodirežiimis üks taandetase';

  @override
  String get shortcutEscape => 'Sulge otsing või tühista plokkide valik';

  @override
  String get shortcutEscapeDescription =>
      'Sulge tööruumi otsing või tühista plokkide valik redaktorirežiimis';

  @override
  String get shortcutGroupFormatting => 'Vormindamine';

  @override
  String get shortcutBoldDescription =>
      'Lülita valitud tekstil paks kiri sisse või välja';

  @override
  String get shortcutItalicDescription =>
      'Lülita valitud teksti kursiivvormindus sisse või välja';

  @override
  String get shortcutUnderlineDescription =>
      'Lülita valitud teksti allajoonimine sisse või välja';

  @override
  String get shortcutLinkDescription => 'Lisa või muuda linki';

  @override
  String get shortcutInlineCodeDescription =>
      'Lülita valitud teksti reasisene koodivormindus sisse või välja';

  @override
  String get shortcutStrikethroughDescription =>
      'Lülita valitud teksti läbikriipsutus sisse või välja';

  @override
  String get shortcutGroupBlocks => 'Plokid';

  @override
  String get shortcutParagraphDescription => 'Muuda praegune plokk lõiguks';

  @override
  String get shortcutHeading1Description =>
      'Muuda praegune plokk 1. taseme pealkirjaks';

  @override
  String get shortcutHeading2Description =>
      'Muuda praegune plokk 2. taseme pealkirjaks';

  @override
  String get shortcutHeading3Description =>
      'Muuda praegune plokk 3. taseme pealkirjaks';

  @override
  String get shortcutHeading4Description =>
      'Muuda praegune plokk 4. taseme pealkirjaks';

  @override
  String get shortcutHeading5Description =>
      'Muuda praegune plokk 5. taseme pealkirjaks';

  @override
  String get shortcutHeading6Description =>
      'Muuda praegune plokk 6. taseme pealkirjaks';

  @override
  String get shortcutGroupLists => 'Loendid';

  @override
  String get numberedList => 'Nummerdatud loend';

  @override
  String get shortcutNumberedListDescription =>
      'Lülita nummerdatud loendi vormindus sisse või välja';

  @override
  String get bulletedList => 'Täpploend';

  @override
  String get shortcutBulletedListDescription =>
      'Lülita täpploendi vormindus sisse või välja';

  @override
  String get checklist => 'Kontrollnimekiri';

  @override
  String get shortcutChecklistDescription =>
      'Lülita kontrollnimekirja vormindus sisse või välja';

  @override
  String get shortcutGroupSidebar => 'Külgpaneel';

  @override
  String get sidebarViewMenu => 'Külgpaneeli vaade';

  @override
  String get createMarkdownFile => 'Loo Markdowni fail';

  @override
  String get createMarkdownFileDescription =>
      'Alusta salvestamata kohalikku Markdowni dokumenti';

  @override
  String get createWritersideProject => 'Loo Writerside’i projekt';

  @override
  String get createWritersideProjectDescription =>
      'Alusta kohalikku Writerside’iga ühilduvat projekti';

  @override
  String get defaultProjectName => 'Dokumentatsioon';

  @override
  String get defaultInstanceName => 'Kasutusjuhend';

  @override
  String get defaultStartTopicTitle => 'Alustamine';

  @override
  String get projectName => 'Projekti nimi';

  @override
  String get directoryName => 'Kataloogi nimi';

  @override
  String get instanceName => 'Eksemplari nimi';

  @override
  String get instanceId => 'Eksemplari ID';

  @override
  String get startTopicTitle => 'Avalehteema pealkiri';

  @override
  String get location => 'Asukoht';

  @override
  String get projectNameRequired => 'Projekti nimi on nõutav.';

  @override
  String get directoryNameRequired => 'Kataloogi nimi on nõutav.';

  @override
  String get useSingleSafeDirectoryName => 'Kasuta üht ohutut katalooginime.';

  @override
  String get useLowercaseIdentifier =>
      'Kasuta väiketähtedest, numbritest, allkriipsudest või sidekriipsudest koosnevat identifikaatorit.';

  @override
  String get startTopicTitleRequired => 'Avalehteema pealkiri on nõutav.';

  @override
  String get createWritersideProjectFailed =>
      'Writerside’i projekti loomine nurjus.';

  @override
  String get settingsTitle => 'BusyMarki sätted';

  @override
  String get autoSave => 'Automaatne salvestamine';

  @override
  String get autoSaveDescription =>
      'Salvesta failimuudatused pärast lühikest tegevusetust automaatselt.';

  @override
  String get wordWrap => 'Reamurdmine';

  @override
  String get editorFontSize => 'Redaktori fondi suurus';

  @override
  String get validateOnEdit => 'Valideeri muutmisel';

  @override
  String get clearRecentWorkspaces => 'Tühjenda hiljutiste tööruumide loend';

  @override
  String get editingButtonsPosition => 'Redigeerimisnuppude asukoht';

  @override
  String get editingButtonsPositionDescription =>
      'Vali, kus kuvatakse hõljuvad WYSIWYG-redigeerimisnupud.';

  @override
  String get editingButtonsDirection => 'Redigeerimisnuppude paigutussuund';

  @override
  String get editingButtonsDirectionDescription =>
      'Vali, kas hõljuvad WYSIWYG-redigeerimisnupud paigutatakse horisontaalselt või vertikaalselt.';

  @override
  String get horizontal => 'Horisontaalne';

  @override
  String get vertical => 'Vertikaalne';

  @override
  String get privacy => 'Privaatsus';

  @override
  String get allowRemoteImages => 'Laadi välispildid';

  @override
  String get allowRemoteImagesDescription =>
      'Luba Markdowni eelvaatel ja redaktoril laadida pilte HTTP- ja HTTPS-aadressidelt.';

  @override
  String get clearRemoteImagePermissions =>
      'Eemalda välispiltide laadimise load';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Unusta tööruumid, millel oli lubatud välispilte laadida.';

  @override
  String get clearGitWorkspaceTrust =>
      'Tühjenda usaldatud Giti tööruumide loend';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Küsi varem usaldatud tööruumides Giti funktsioonide lubamisel uuesti kinnitust.';

  @override
  String get settingsWindowSectionTitle => 'Aken';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Eelmise tööruumi taasavamine käivitamisel';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Ava BusyMarki käivitamisel eelmise seansi tööruum ja vahekaardid.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Küsi salvestamata muudatuste korral enne sulgemist kinnitust';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Küsi enne BusyMarki sulgemist kinnitust, kui dokumentides on salvestamata muudatusi.';

  @override
  String get closeUnsavedChangesTitle => 'Salvestamata muudatused';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Selles dokumendis on salvestamata muudatusi. Kas salvestada muudatused enne BusyMarki sulgemist?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumendis on salvestamata muudatusi. Kas salvestada muudatused enne BusyMarki sulgemist?',
      one:
          'Ühes dokumendis on salvestamata muudatusi. Kas salvestada muudatused enne BusyMarki sulgemist?',
      zero: 'Kas salvestada muudatused enne BusyMarki sulgemist?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Tühista';

  @override
  String get closeUnsavedChangesDiscard => 'Hülga';

  @override
  String get closeUnsavedChangesSave => 'Salvesta';

  @override
  String get currentFile => 'praegune fail';

  @override
  String get unsavedChanges => 'Salvestamata muudatused';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Failis $fileName on salvestamata muudatusi. Kas salvestada need enne jätkamist?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumendil on salvestamata muudatusi. Salvestage need enne jätkamist.',
      one:
          '1 dokumendil on salvestamata muudatusi. Salvestage see enne jätkamist.',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Faili on kettal muudetud';

  @override
  String get fileChangedOnDiskMessage =>
      'Seda faili on pärast avamist kettal muudetud. Kas kirjutada see üle?';

  @override
  String get untitledMarkdownFileName => 'Nimetu.md';

  @override
  String get unorderedList => 'Järjestamata loend';

  @override
  String get orderedList => 'Järjestatud loend';

  @override
  String get taskList => 'Ülesandeloend';

  @override
  String get toggleTaskChecked => 'Märgi ülesanne tehtuks või tegemata';

  @override
  String get indentListItem => 'Suurenda loendiüksuse taanet';

  @override
  String get outdentListItem => 'Vähenda loendiüksuse taanet';

  @override
  String get blockquote => 'Plokktsitaat';

  @override
  String get codeBlock => 'Koodiplokk';

  @override
  String get codeBlockLanguage => 'Koodiploki keel';

  @override
  String get image => 'Pilt';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Esita videot';

  @override
  String get pauseVideo => 'Peata video';

  @override
  String get videoUnavailable => 'Video pole saadaval';

  @override
  String get videoPreview => 'Video eelvaade';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Videol puudub atribuut src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Toetamata videoallikas: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Videofaili pole olemas: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Video eelvaatepilti pole olemas: $preview';
  }

  @override
  String get inlineImage => 'Reasisene pilt';

  @override
  String get table => 'Tabel';

  @override
  String get htmlBlock => 'HTML-plokk';

  @override
  String get htmlContentDefault => 'HTML-sisu';

  @override
  String get shortcutHtmlBlockDescription => 'Lisa või muuda HTML-plokki';

  @override
  String get renderedHtml => 'Kuvatud HTML';

  @override
  String get editHtml => 'Muuda HTML-i';

  @override
  String get htmlSource => 'HTML-lähtekood';

  @override
  String get thematicBreak => 'Eraldusjoon';

  @override
  String get bold => 'Paks kiri';

  @override
  String get italic => 'Kursiiv';

  @override
  String get underline => 'Allajoonimine';

  @override
  String get strikethrough => 'Läbikriipsutus';

  @override
  String get inlineCode => 'Reasisene kood';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Sundreavahetus';

  @override
  String get textStyle => 'Tekstilaad';

  @override
  String get paragraph => 'Lõik';

  @override
  String get heading1 => 'Pealkiri 1';

  @override
  String get heading2 => 'Pealkiri 2';

  @override
  String get heading3 => 'Pealkiri 3';

  @override
  String get heading4 => 'Pealkiri 4';

  @override
  String get heading5 => 'Pealkiri 5';

  @override
  String get heading6 => 'Pealkiri 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Kustuta tabel';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Veerg $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Lisa veerg vasakule';

  @override
  String get insertColumnRight => 'Lisa veerg paremale';

  @override
  String get deleteColumn => 'Kustuta veerg';

  @override
  String get tableAlignmentUnspecified => 'Joondus: määramata';

  @override
  String get tableAlignmentLeft => 'Joondus: vasakule';

  @override
  String get tableAlignmentCenter => 'Joondus: keskele';

  @override
  String get tableAlignmentRight => 'Joondus: paremale';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Rida $rowNumber';
  }

  @override
  String get insertRowAbove => 'Lisa rida ülespoole';

  @override
  String get insertRowBelow => 'Lisa rida allapoole';

  @override
  String get deleteRow => 'Kustuta rida';

  @override
  String get tableHeaderHint => 'Päis';

  @override
  String get tableCellHint => 'Lahter';

  @override
  String get language => 'Keel';

  @override
  String get hideEditingButtons => 'Peida redigeerimisnupud';

  @override
  String get showEditingButtons => 'Kuva redigeerimisnupud';

  @override
  String get altText => 'Asetekst';

  @override
  String get editorPlaceholderText => 'tekst';

  @override
  String get editorPlaceholderCode => 'kood';

  @override
  String get editorPlaceholderAltText => 'asetekst';

  @override
  String get describeTheImage => 'Kirjelda pilti';

  @override
  String get columns => 'Veerud';

  @override
  String get rows => 'Read';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Päis $columnNumber';
  }

  @override
  String get tableCellDefault => 'Lahter';

  @override
  String get noImageSource => 'Pildiallikas puudub';

  @override
  String get remoteImageBlocked => 'Välispilt on blokeeritud';

  @override
  String get remoteImageBlockedTooltip =>
      'Vali, kas BusyMark võib välispilte laadida.';

  @override
  String get remoteImagesBlockedTitle => 'Välispildid on blokeeritud';

  @override
  String get remoteImagesBlockedMessage =>
      'See dokument viitab internetis olevatele piltidele. Nende laadimine võib avaldada pildi majutajale teie võrguteavet.';

  @override
  String get loadRemoteImagesForWorkspace => 'Laadi selles tööruumis';

  @override
  String get alwaysLoadRemoteImages => 'Laadi välispildid alati';

  @override
  String get hideSidebar => 'Peida külgpaneel';

  @override
  String get showSidebar => 'Kuva külgpaneel';

  @override
  String get showPreview => 'Kuva eelvaade';

  @override
  String get hidePreview => 'Peida eelvaade';

  @override
  String get workspaceKindUnsavedMarkdown => 'Salvestamata Markdowni fail';

  @override
  String get workspaceKindSingleMarkdown => 'Üksik Markdowni fail';

  @override
  String get workspaceKindMarkdownFolder => 'Markdowni kaust';

  @override
  String get workspaceKindWritersideModule => 'Writerside’i moodul';

  @override
  String get problems => 'Probleemid';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostikateadet',
      one: '1 diagnostikateade',
      zero: 'Diagnostikateateid pole',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Failid';

  @override
  String get toc => 'Sisukord';

  @override
  String get tocActions => 'Sisukorra toimingud';

  @override
  String get markdownUnsaved => 'Markdown – salvestamata';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faili',
      one: '1 fail',
    );
    return '$kind – $_temp0';
  }

  @override
  String get noFiles => 'Faile pole';

  @override
  String get newFile => 'Uus fail';

  @override
  String get noWritersideToc => 'Writerside’i sisukord puudub';

  @override
  String get tocSection => 'Sisukorra jaotis';

  @override
  String get newTopic => 'Uus teema';

  @override
  String get newChildTopic => 'Uus alamteema';

  @override
  String get newSiblingTopic => 'Uus samatasemeline teema';

  @override
  String get renameTopicFile => 'Nimeta teemafail ümber';

  @override
  String get topicPlacement => 'Paigutus sisukorras';

  @override
  String get tocRoot => 'Sisukorra juurtasemel';

  @override
  String get afterSelectedTopic => 'Valitud teema järel';

  @override
  String get insideSelectedTopic => 'Valitud teema all';

  @override
  String get pasteAfterTopic => 'Aseta järele';

  @override
  String get pasteAsChildTopic => 'Aseta alamteemaks';

  @override
  String get removeFromToc => 'Eemalda sisukorrast';

  @override
  String get confirmRemoveFromTocTitle => 'Kas eemaldada sisukorrast?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Kas eemaldada „$name” sellest sisukorrast? Teemafail säilitatakse.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Kas kustutada teemafail?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Kas kustutada „$name” ja eemaldada see kõigist sisukordadest? Seda toimingut ei saa tagasi võtta.';
  }

  @override
  String get safeDeleteTopicFile => 'Kustuta teemafail turvaliselt…';

  @override
  String get removeTocElement => 'Eemalda sisukorraelement';

  @override
  String get reviewUsages => 'Vaata kasutuskohad üle';

  @override
  String get deleteTopicFile => 'Kustuta teemafail';

  @override
  String get removeAction => 'Eemalda';

  @override
  String topicRemovalSummary(String topic) {
    return 'Eemalda „$topic” valitud eksemplarist. Teemafail säilitatakse.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Kustuta „$topic” ja uuenda kogu Writerside’i projektis turvaliselt sellele viitavad kohad.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alamteemat liigub ühe taseme võrra üles.',
      one: '1 alamteema liigub ühe taseme võrra üles.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Seda teemat kasutatakse eksemplari avalehena. Enne jätkamist vaata kasutuskohad üle ja määra teine avaleht.';

  @override
  String topicUsagesCount(int count) {
    return 'Kasutuskohad ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Ei leitud viiteid, mis selle toimingu tõttu katkeksid.';

  @override
  String get topicUsagesFound =>
      'BusyMark leidis järgmised viited sellele teemale.';

  @override
  String get topicUsageTocElements => 'Sisukorraelemendid';

  @override
  String get topicUsageStartPages => 'Avalehed';

  @override
  String get topicUsageTopicLinks => 'Teemalingid';

  @override
  String get topicUsageIncludes => 'Kaasamiselemendid';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kasutuskohta',
      one: '1 kasutuskoht',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Refaktoreerimise valikud';

  @override
  String get updateUsagesAutomatically => 'Uuenda kasutuskohad automaatselt';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Eemalda sisukorraviited ja kaasamiselemendid ning säilita linkide tekst.';

  @override
  String get manualUsageUpdatesRequired =>
      'Mõnda kasutuskohta tuleb enne refaktoreerimist käsitsi muuta.';

  @override
  String get setRedirectTo => 'Määra ümbersuunamine';

  @override
  String get noRedirectDescription => 'Ära suuna vana avaldatud lehte ümber.';

  @override
  String get redirectTarget => 'Ümbersuunamise sihtkoht';

  @override
  String get remainingUsagesBlockRemoval =>
      'Enne jätkamist vaata üle ja uuenda ülejäänud kasutuskohad või luba automaatne uuendamine, kui see on saadaval.';

  @override
  String usagesOfTopic(String topic) {
    return 'Teema „$topic” kasutuskohad';
  }

  @override
  String get noUsagesFound => 'Kasutuskohti ei leitud';

  @override
  String get outsideSelectedInstance => 'väljaspool valitud eksemplari';

  @override
  String get doRefactor => 'Refaktoreeri';

  @override
  String get orphanTopicTitle => 'Teemafaili ei kasutata enam';

  @override
  String get keepTopicFile => 'Säilita teemafail';

  @override
  String orphanTopicMessage(String topic) {
    return '„$topic” pole selles Writerside’i projektis enam kusagil kasutusel. Kustuta fail või säilita see mõnes teises eksemplaris kasutamiseks.';
  }

  @override
  String get defaultNewTopicTitle => 'Uus teema';

  @override
  String get topicTitle => 'Teema pealkiri';

  @override
  String get fileName => 'Faili nimi';

  @override
  String get topicTitleRequired => 'Teema pealkiri on nõutav.';

  @override
  String get fileNameRequired => 'Faili nimi on nõutav.';

  @override
  String get rename => 'Nimeta ümber';

  @override
  String get confirmDeleteFileTitle => 'Kas kustutada fail?';

  @override
  String get confirmDeleteFolderTitle => 'Kas kustutada kaust?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Kas kustutada „$name”? Seda toimingut ei saa tagasi võtta.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Kas kustutada „$name” ja kõik selles olevad failid? Seda toimingut ei saa tagasi võtta.';
  }

  @override
  String get useSingleSafeFileName => 'Kasuta üht ohutut failinime.';

  @override
  String useExpectedExtension(String extension) {
    return 'Kasuta valitud vormingu puhul laiendit $extension.';
  }

  @override
  String get useIdentifierCharacters =>
      'Kasuta laiendi ees ainult tähti, numbreid, allkriipse või sidekriipse.';

  @override
  String get topicIdAlreadyExists => 'Teema ID on juba olemas.';

  @override
  String get createWritersideTopicFailed =>
      'Writerside’i teema loomine nurjus.';

  @override
  String get noOutline => 'Liigendus puudub';

  @override
  String expandKind(String kind) {
    return 'Laienda: $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Ahenda: $kind';
  }

  @override
  String get foldKindSection => 'jaotis';

  @override
  String get foldKindList => 'loend';

  @override
  String get foldKindQuote => 'tsitaat';

  @override
  String get foldKindTag => 'märgend';

  @override
  String get sourceSearchPreviousMatch => 'Eelmine vaste';

  @override
  String get sourceSearchNextMatch => 'Järgmine vaste';

  @override
  String get sourceSearchCaseSensitive => 'Tõstutundlik';

  @override
  String get sourceSearchWholeWord => 'Terve sõna';

  @override
  String get sourceSearchRegex => 'Regulaaravaldis';

  @override
  String get sourceSearchReplacement => 'Asenda väärtusega';

  @override
  String get sourceSearchReplaceCurrent => 'Asenda praegune vaste';

  @override
  String get sourceSearchReplaceAndFindNext => 'Asenda ja leia järgmine';

  @override
  String get sourceSearchReplaceAll => 'Asenda kõik';

  @override
  String get workspaceReplace => 'Asenda tööruumis';

  @override
  String get reviewReplacements => 'Vaata asendused üle';

  @override
  String get applyReplacements => 'Rakenda asendused';

  @override
  String get skippedFiles => 'Vahele jäetud failid';

  @override
  String get workspaceReplaceDirtyBuffer => 'Salvestamata redaktori sisu';

  @override
  String get workspaceReplaceDiskContent => 'Kettale salvestatud sisu';

  @override
  String selectFileMatches(int count) {
    return 'Vali kõik $count vastet';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Asendati $matches vastet $files failis; vahele jäeti $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Lõpus on reavahetus';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Lõpus pole reavahetust';
  }

  @override
  String get normalizeLineEndings => 'Normaliseeri reavahetused';

  @override
  String get mixedLineEndingsSavePrompt =>
      'See dokument sisaldab eri tüüpi reavahetusi. Vali vorming.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return 'Fail $fileName kasutab eri tüüpi reavahetusi. Vali enne asendamist vorming.';
  }

  @override
  String get workspaceReplaceIssueOversized => 'Liiga suur fail jäeti vahele.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Fail, mida ei saanud lugeda, jäeti vahele.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Fail, mis pole korrektne UTF-8, jäeti vahele.';

  @override
  String get workspaceReplaceIssueTruncated => 'Asenduste eelvaade kärbiti.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Pärast eelvaadet muutunud fail jäeti vahele.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Pärast eelvaadet muutunud redaktoripuhver jäeti vahele.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Vali enne asendamist LF- või CRLF-normaliseerimine.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Tagasivõtmine peatati, sest faili muudeti samal ajal. Mõned asendused võivad alles jääda; väljatõrjutud sisu säilitati alloleval teel.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Asendusi ei rakendatud, sest läbivaadatud kogumit ei saanud turvaliselt salvestada.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Välised muudatused — $fileName';
  }

  @override
  String get externalFileDeleted => 'See fail kustutati kettalt.';

  @override
  String get externalFileChanged =>
      'See fail muutus kettal ajal, kui sul on salvestamata muudatusi.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Faili $fileName salvestamata sisu taastati. Vaadake see üle ning salvestage, salvestage nimega või hüljake.';
  }

  @override
  String get compare => 'Võrdle';

  @override
  String get reloadFromDisk => 'Laadi kettalt uuesti';

  @override
  String get keepMine => 'Säilita minu versioon';

  @override
  String get saveAs => 'Salvesta nimega';

  @override
  String get sourceSearchInvalidRegex => 'Vigane regulaaravaldis';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Suur fail: esiletõstmine ja voltimine on peatatud';

  @override
  String get nothingToRead => 'Pole midagi lugeda';

  @override
  String get admonition => 'Märkusplokk';

  @override
  String get quote => 'Tsitaat';

  @override
  String get note => 'Märkus';

  @override
  String get tip => 'Näpunäide';

  @override
  String get warning => 'Hoiatus';

  @override
  String get tabs => 'Vahekaardid';

  @override
  String get tab => 'Vahekaart';

  @override
  String get procedure => 'Protseduur';

  @override
  String get step => 'Samm';

  @override
  String get topic => 'Teema';

  @override
  String get chapter => 'Peatükk';

  @override
  String couldNotOpenTarget(String target) {
    return 'Sihtkoha „$target” avamine nurjus';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Lingi sihtkohta ei leitud: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Seda failitüüpi ei saa redaktoris avada';

  @override
  String anchorNotFound(String anchor) {
    return 'Ankrut ei leitud: $anchor';
  }

  @override
  String get noProblemsFound => 'Probleeme ei leitud';

  @override
  String get noResults => 'Tulemusi pole';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath – rida $lineNumber';
  }

  @override
  String get untitledResult => 'Pealkirjata tulemus';

  @override
  String get documentKindMarkdownFile => 'Markdowni fail';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Writerside’i Markdowni teema';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside’i XML-teema';

  @override
  String get documentKindWritersideTree => 'Writerside’i puu';

  @override
  String get documentKindConfigurationFile => 'Konfiguratsioonifail';

  @override
  String get documentKindVariablesFile => 'Muutujate fail';

  @override
  String get documentKindCategoriesFile => 'Kategooriate fail';

  @override
  String get documentKindResourceFile => 'Ressursifail';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Avamine nurjus: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Writerside’i projekti loomine nurjus: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Writerside’i teema loomine nurjus: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Faili avamine nurjus: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Vali selle Markdowni faili salvestuskoht.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Salvestamine blokeeriti: faili on kettal muudetud.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Salvestamine nurjus: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Failitoiming nurjus: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Valideerimine nurjus: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Taastati $count salvestamata dokumenti. Kontrolli igaüht enne salvestamist või hülgamist.',
      one:
          'Taastati 1 salvestamata dokumendi. Kontrolli see enne salvestamist või hülgamist.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count kahjustunud taastamiskirjet ei õnnestunud taastada. Kehtivad taastamiskirjed jäävad alles.',
      one:
          'Ühte kahjustunud taastamiskirjet ei õnnestunud taastada. Algne taastamisfail on ülevaatuseks alles jäetud.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Teed pole olemas: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Sihtkataloog on juba olemas ega ole tühi: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Sihttee on juba olemas ega ole kataloog: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Loodav fail on juba olemas: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Ülemkataloog on nõutav.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Ülemkataloogi pole olemas: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Kataloogi pole olemas: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Tee on juba olemas: $path';
  }

  @override
  String get errorFileNameRequired => 'Faili nimi on nõutav.';

  @override
  String get errorFileNameUnsafe => 'Failinimi peab olema üks ohutu teeosa.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Kausta ei saa iseendasse teisaldada.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Failitoiming peab jääma tööruumi piiresse.';

  @override
  String get errorFileOperationRoot =>
      'Tööruumi juurkausta ei saa failipuus muuta.';

  @override
  String get errorProjectNameRequired => 'Projekti nimi on nõutav.';

  @override
  String get errorDirectoryNameRequired => 'Kataloogi nimi on nõutav.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Katalooginimi peab olema üks ohutu teeosa.';

  @override
  String get errorInstanceIdInvalid =>
      'Eksemplari ID peab algama väiketähega ning sisaldama ainult väiketähti, numbreid, allkriipse ja sidekriipse.';

  @override
  String get errorTopicFileInvalid =>
      'Teemafaili nimi peab olema Markdowni failinimi ilma kataloogieraldajateta.';

  @override
  String get errorTopicTitleRequired => 'Teema pealkiri on nõutav.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside’i mooduli juurkausta pole olemas: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Teema loomiseks peab Writerside’i moodul olema avatud.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside’i moodulil puudub eksemplaripuu.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside’i puufaili pole olemas: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Teema ID „$topicId” on selles abimoodulis juba olemas.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Teemafail on juba olemas: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Viidatud teemat pole valitud puus: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Valitud sisukorra kirjet pole enam olemas.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Sisukorra kirjet ei saa teisaldada iseenda ega ühegi oma alamkirje alla.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Avaleheks määratud teemat „$topic” ei saa kustutada. Vali esmalt teine avaleht.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Writerside’i teemafaili kustutamiseks kasuta turvalist kustutamist.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Teema kasutuskohtade kontrolli ei saanud lõpule viia. Ühtegi faili ei muudetud.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Mõned teema kasutuskohad vajavad veel tähelepanu. Vaata need enne jätkamist üle.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Valitud ümbersuunamise sihtkoht ei ole enam kehtiv. Vali see uuesti.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Teema eemaldamist ei saanud täielikult tagasi pöörata. Enne jätkamist vaata üle järgmised asukohad: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Teemade juurkaust peab olema ohutu suhteline kataloog.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Teemafaili nimi peab olema üks ohutu teeosa.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Teemafaili laiend peab vastama valitud vormingule ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Teemafaili nimi tohib sisaldada ainult tähti, numbreid, allkriipse ja sidekriipse.';

  @override
  String errorUnknown(String code) {
    return 'Tundmatu viga: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Faili metaandmete lugemine nurjus: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Tuvastati suur tööruum. Rakenduse reageerimisvõime säilitamiseks jäeti osa faile vahele.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Tööruumi kirje kontrollimine nurjus: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Fail ületab beetaversiooni automaatse parsimise mahupiirangu.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Markdowni faili lugemine nurjus: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Writerside’i pealkirja atribuudiplokk on vigane.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Pealkirja ID „$id” esineb mitu korda.';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Täiendavaid kõrgeima taseme H1-pealkirju käsitletakse peatükkidena.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside’i Markdowni teemal pole H1- ega metaandmeploki pealkirja.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML-teemal puudub pealkiri.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Teemal „$fileName” puudub pealkiri.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Metaandmeplokk pole suletud.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Ebaturvaline HTML-element.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Lingi sihtkohta pole olemas: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Ankrut „$anchor” pole olemas.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Pildil „$destination” puudub asetekst.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Pilti pole olemas: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Vigane XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Faili writerside.cfg juurelement peab olema <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'Deklaratsioonil snippets puudub atribuut src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'Deklaratsioonil instance-groups puudub atribuut src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Atribuudi keymaps-mode väärtust ei toetata: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Eksemplari deklaratsioonil puudub atribuut src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'Failis writerside.cfg pole registreeritud ühtegi eksemplari.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree-faili juurelement peab olema <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Eksemplariprofiilil puudub atribuut id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Puufaili tüvinimi ei vasta eksemplari ID-le „$id”.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Eksemplaril, mis pole teek, puudub atribuut start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Avalehte „$startPage” pole olemas.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Teema „$topic” esineb selle eksemplari sisukorras mitu korda.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Muutuja deklaratsioonil peavad olema atribuudid name ja value.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Muutuja „$name” on deklareeritud mitu korda.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'Kategoorial puudub atribuut id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Kategooria „$id” on deklareeritud mitu korda.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Kategooria järjekord „$order” on deklareeritud mitu korda.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic-faili juurelement peab olema <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML-teema juurelemendil puudub atribuut id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML-teema juurelemendi ID „$id” peab vastama failinimele „$expectedId”.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Elemendi ID „$elementId” esineb mitu korda.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'Elemendil <a> puudub atribuut href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside’i režiim nõuab faili writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Seadistatud koostekonfiguratsiooni kataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Seadistatud API-spetsifikatsioonide kataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Seadistatud koodilõikude kataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Seadistatud muutujate fail puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Seadistatud kategooriate fail puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Seadistatud eksemplarirühmade fail puudub: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Registreeritud eksemplaripuu faili „$source” pole olemas.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Teemafaili lugemine nurjus: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Vaikimisi teemakataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Seadistatud teemakataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Seadistatud pildikataloog puudub: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Elemendi ID „$id” esineb mitu korda.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Sisukord viitab puuduvale teemale „$topic”.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Väline href-aadress „$href” on vigane.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Muutujat „%$name%” pole deklareeritud.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Teemalink „$destination” ei viita olemasolevale teemale.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Ankrut „$anchor” pole sihtkohas „$targetName”.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'Elemendil <include> puudub atribuut from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Kaasatavat allikat „$from” pole olemas.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Kaasatavat elementi „$elementId” pole allikas „$from”.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Seealso-kategooriat „$ref” pole deklareeritud.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Teemaviide „$reference” pole ühene.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Tundmatu diagnostikateade: $code';
  }

  @override
  String get close => 'Sulge';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Giti erinevused';

  @override
  String get gitShowDiff => 'Kuva erinevused';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'vana $oldRange → uus $newRange';
  }

  @override
  String get gitDiffNoLines => 'ridu pole';

  @override
  String get gitUnavailableTitle => 'Git pole saadaval';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Paigalda Git või seadista BusyMark kasutama saadaolevat Giti täitmisfaili. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Kas usaldada seda tööruumi Giti jaoks?';

  @override
  String get gitTrustRequiredMessage =>
      'Giti hoidlad võivad haakide, filtrite ja muude seadistuste kaudu programme käivitada. Usalda seda tööruumi enne, kui BusyMark loeb hoidla andmeid või lubab Giti toimingud.';

  @override
  String get gitTrustWorkspace => 'Usalda tööruumi';

  @override
  String get gitNotRepositoryTitle => 'Pole Giti hoidla';

  @override
  String get gitNotRepositoryMessage => 'See tööruum ei asu Giti hoidlas.';

  @override
  String get gitInitializeRepository => 'Loo Giti hoidla';

  @override
  String get gitDetachedHead => 'Eraldatud HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Eraldatud HEAD commitil $commit';
  }

  @override
  String get gitNoUpstream => 'Upstream-haru puudub';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saatmata commiti',
      one: '1 saatmata commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tõmbamata commiti',
      one: '1 tõmbamata commit',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Muudatusi pole';

  @override
  String get gitConflicts => 'Konfliktid';

  @override
  String get gitChanges => 'Muudatused';

  @override
  String get gitStaged => 'Indekseeritud';

  @override
  String get gitUnstaged => 'Indekseerimata';

  @override
  String get gitHistory => 'Ajalugu';

  @override
  String get gitBranches => 'Harud';

  @override
  String get gitActions => 'Giti toimingud';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Hangi';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Lisa fail indeksisse';

  @override
  String get gitRemoveFromCommit => 'Eemalda fail indeksist';

  @override
  String get gitDiscard => 'Hülga';

  @override
  String get gitOpenFile => 'Ava fail';

  @override
  String get gitMarkResolved => 'Märgi lahendatuks';

  @override
  String get gitUntracked => 'Jälgimata failid';

  @override
  String get gitCommitMessage => 'Commiti sõnum';

  @override
  String get gitCommitSelectedFiles => 'Valitud failid';

  @override
  String get gitCommitNoSelectedFiles =>
      'Lisa enne commiti loomist vähemalt üks fail indeksisse.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indekseeritud faili',
      one: '1 indekseeritud fail',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Väljaspool tööruumi';

  @override
  String get gitCommitMessageRequired => 'Sisesta commiti sõnum.';

  @override
  String get gitCreateBranch => 'Loo haru';

  @override
  String get gitNewBranch => 'Uus haru';

  @override
  String get gitBranchName => 'Haru nimi';

  @override
  String get gitSwitchBranch => 'Vaheta';

  @override
  String get gitNoChanges => 'Muudatusi pole';

  @override
  String get gitNoHistory => 'Ajalugu puudub';

  @override
  String get gitNoBranches => 'Harusid pole';

  @override
  String get gitNoDiff => 'Kuvatavaid erinevusi pole';

  @override
  String get gitBinaryFile => 'Binaarfail. BusyMark ei kuva binaarpaiku.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Kahendfail ($size baiti). BusyMark ei kuva kahendpaiku.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Redaktori salvestamata muudatusi ei kaasata enne salvestamist.';

  @override
  String get gitConfirmDiscardTitle => 'Kas hüljata Giti muudatused?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Valitud jälgitavate failide kõiki indekseeritud ja indekseerimata muudatusi taastatakse HEAD-ile.',
      one:
          'Valitud jälgitava faili kõiki indekseeritud ja indekseerimata muudatusi taastatakse HEAD-ile.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Valitud jälgimata failid kustutatakse.',
      one: 'Valitud jälgimata fail kustutatakse.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Valitud failid taastatakse või kustutatakse vastavalt nende Giti olekule.',
      one:
          'Valitud fail taastatakse või kustutatakse vastavalt selle Giti olekule.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Kas minna üle harule „$branch”?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'Pärast haru vahetamist laadib BusyMark tööruumi kettalt uuesti.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Kas määrata upstream-haru?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Sellel harul pole upstream-haru. Kui seadistatud on täpselt üks kaughoidla, saab BusyMark haru „$branch” sinna saata ja määrata selle upstream-haruks.';
  }

  @override
  String get gitProjectHistory => 'Projekti ajalugu';

  @override
  String get gitFileHistory => 'Faili ajalugu';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Failiajalugu nõuab avatud Markdowni faili.';

  @override
  String get gitLoadMore => 'Laadi veel';

  @override
  String get gitChangesInCommit => 'Selle sissekande muudatused';

  @override
  String get gitCompareWithCurrent => 'Võrdle praeguse versiooniga';

  @override
  String get gitRestoreVersion => 'Taasta see versioon';

  @override
  String get gitConfirmRestoreTitle => 'Kas taastada see failiversioon?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark asendab praeguse tööpuu faili valitud sissekande versiooniga. Taastatud fail jääb indekseerimata.';

  @override
  String get gitCommitActions => 'Sissekande toimingud';

  @override
  String get gitResetCurrentBranchToHere => 'Lähtesta praegune haru siia…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Kas lähtestada $branch sissekandele $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'See liigutab haru $branch sissekandele $commit. Vali, kuidas Git indeksit ja tööpuud uuendab.';
  }

  @override
  String get gitReset => 'Lähtesta';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Liiguta ainult haru. Jäta indeks ja tööpuu muutmata; erinevused valitud sissekandest jäävad indekseerituks.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Liiguta haru ja lähtesta indeks. Jäta tööpuu muutmata, nii et erinevused jäävad indekseerimata.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Liiguta haru ning lähtesta indeks ja tööpuu. Jälgitavad muudatused hüljatakse; toimingut takistavad jälgimata failid võidakse kustutada.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Liiguta haru ja lähtesta jälgitavad failid, säilitades kohalikud muudatused. Git katkestab, kui need muudatused on lähtestamisega vastuolus.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Failitoimingud';

  @override
  String get actions => 'Toimingud';

  @override
  String get gitStatusAdded => 'Lisatud';

  @override
  String get gitStatusDeleted => 'Kustutatud';

  @override
  String get gitStatusRenamed => 'Ümbernimetatud';

  @override
  String get gitStatusCopied => 'Kopeeritud';

  @override
  String get gitStatusUntracked => 'Jälgimata';

  @override
  String get gitStatusConflicted => 'Konfliktis';

  @override
  String get gitStatusIgnored => 'Eiratud';

  @override
  String get gitStatusTypeChanged => 'Tüüp muutunud';

  @override
  String get gitStatusModified => 'Muudetud';

  @override
  String get gitStatusUnknown => 'Tundmatu';

  @override
  String get gitErrorUnavailable => 'Git pole saadaval.';

  @override
  String get gitErrorNotRepository => 'See tööruum pole Giti hoidla.';

  @override
  String get gitErrorUnsafePath => 'BusyMark blokeeris ebaturvalise Giti tee.';

  @override
  String get gitErrorInvalidBranchName => 'Sisesta sobiv haru nimi.';

  @override
  String get gitErrorNoRemote => 'Ühtegi Giti kaughoidlat pole seadistatud.';

  @override
  String get gitErrorNoUpstream => 'Upstream-haru pole seadistatud.';

  @override
  String get gitErrorMultipleRemotes =>
      'Seadistatud on mitu kaughoidlat. Vali upstream-haru mõne muu tööriistaga; see BusyMarki versioon seda ei võimalda.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Enne haru vahetamist salvesta või hülga BusyMarki redaktori muudatused.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Salvesta või hülga BusyMarki redaktori muudatused enne praeguse haru lähtestamist.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Eemalda fail enne varasema versiooni taastamist indeksist.';

  @override
  String get gitErrorResetDetachedHead =>
      'Enne lähtestamist võta kasutusele mõni haru.';

  @override
  String get gitErrorDiverged =>
      'Haru ajalugu on lahknenud. Lahenda ühendamine või ümberbaasimine mõne muu tööriistaga; see BusyMarki versioon seda ei võimalda.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git vajab enne sissekande loomist autori nime ja e-posti aadressi.';

  @override
  String get gitAuthorIdentityTitle => 'Giti autori identiteet';

  @override
  String get gitAuthorIdentityMessage =>
      'Sisesta identiteet, mille Git peaks sissekannetele lisama. BusyMark salvestab selle ja proovib sissekannet uuesti.';

  @override
  String get gitAuthorName => 'Nimi';

  @override
  String get gitAuthorEmail => 'E-post';

  @override
  String get gitAuthorIdentityGlobal => 'Kasuta kõigis hoidlates';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Snapi paigalduses kehtib see BusyMarkis avatud hoidlatele.';

  @override
  String get gitSaveIdentityAndCommit => 'Salvesta ja loo sissekanne';

  @override
  String get gitErrorAuthentication => 'Giti autentimine nurjus.';

  @override
  String get gitErrorNetwork => 'Giti võrgutoiming nurjus.';

  @override
  String get gitErrorConflict => 'Git teatas lahendamata konfliktidest.';

  @override
  String get gitErrorCommandFailed => 'Giti käsk nurjus.';

  @override
  String get syntaxReference => 'Süntaksiviide';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdowni plokid';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdowni lähtekoodis ja eelvaates toetatud plokkstruktuurid.';

  @override
  String get syntaxReferenceInlineFormatting => 'Reasisene Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Vormindus, mida saab kasutada lõikudes, loendiüksustes ja tabelilahtrites.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Töötlemata HTML-plokid';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Turvalised plokitaseme HTML-märgendid, mis kuvatakse BusyMarki eelvaatevidinate kaudu.';

  @override
  String get syntaxReferenceRawHtmlInline =>
      'Reasisesed töötlemata HTML-märgendid';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Turvalised reasisesed HTML-märgendid, mis kuvatakse märgendeid endid näitamata.';

  @override
  String get syntaxReferenceHeadings => 'Pealkirjad';

  @override
  String get syntaxReferenceParagraphs => 'Lõigud';

  @override
  String get syntaxReferenceLists => 'Loendid';

  @override
  String get syntaxReferenceHtmlContainers => 'Konteinerid';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Tekstiplokid';

  @override
  String get syntaxReferenceHtmlFigures => 'Joonised ja pildid';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Eelvormindatud kood';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Laiendatavad plokid';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Kirjeldusloendid';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Vormindusmärgendid';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Reasisesed koodimärgendid';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags =>
      'Semantilised tekstimärgendid';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'Lubatud HTML teisendatakse BusyMarki eelvaateplokkideks; seda ei kuvata brauseris.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Redigeerimata töötlemata HTML salvestatakse lähdetekstina täpselt algsel kujul.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Töötlemata HTML-is olevad Markdowni vormindusmärgid kuvatakse lihttekstina.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Skriptid, stiilid, raamid, vormid, SVG, MathML, sündmused ja ebaturvalised atribuudid blokeeritakse.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Linkides on lubatud HTTP-, HTTPS-, mailto- ja tel-skeemiga URL-id ning suhtelised ja fragmendi-URL-id; ebaturvalised skeemid blokeeritakse.';

  @override
  String get syntaxReferenceCategory => 'Kategooria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagrammid ja API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matemaatika';

  @override
  String get syntaxReferenceExample => 'Näide';

  @override
  String get syntaxReferenceIdentifiers => 'Identifikaatorid ja aliased';

  @override
  String get syntaxReferenceScope => 'Ulatus';

  @override
  String get syntaxReferenceLimitation => 'BusyMarki piirang';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Ametlik dokumentatsioon';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Ainult Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Ainult Writerside Markdown ja Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Põhilised Markdowni vormid, mida BusyMark võimaldab kirjutada ja eelvaadata.';

  @override
  String get syntaxReferenceParagraphExample => 'Tekstilõik.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabelid kasutavad GitHub Flavored Markdowni püstkriipsusüntaksit.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'kaks tühikut rea lõpus, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark aktsepteerib Markdowni lähtekoodis piiratud turvalist toor-HTML-i alamhulka.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Piiratud Mermaid-, PlantUML-, D2- ja OpenAPI-plokid töötavad Markdowni lähtekoodis. Plokiidentifikaatorid ei ole tõstutundlikud ja BusyMark säilitab algse kirjapildi.';

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
      'Kasuta piiratud YAML- või JSON-sisu. BusyMark ei käsitle suvalist terviklikku YAML- või JSON-dokumenti OpenAPI viitena.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Semantilised diagrammi koodiplokid';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Semantilised code-block- ja src-vormid toetavad Mermaidi, PlantUML-i ja D2-te, mitte OpenAPI-t, ning ainult Writerside\'i projektides.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Viidatud diagrammiallikas';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Teed peavad olema suhtelised ja jääma avatud Writerside\'i projekti sisse; piiratud vorm koos src-ga on ainult Writerside Markdowni jaoks.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark toetab TeX-i avaldisi, mitte terviklikke TeX-i või LaTeX-i dokumente.';

  @override
  String get syntaxReferenceInlineMath => 'Reasisene matemaatika';

  @override
  String get syntaxReferenceGithubMath =>
      'GitHubi matemaatika dollari- ja graavimärgiga';

  @override
  String get syntaxReferenceDisplayMath => 'Plokina matemaatika';

  @override
  String get syntaxReferenceMathFence => 'math-plokk';

  @override
  String get syntaxReferenceTexFence => 'tex-plokk';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark ei tuvasta \\(...\\) ega \\[...\\] Markdowni matemaatika eraldajatena.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Väljaspool Writerside\'i režiimi jääb tex-plokk tavaliseks koodiplokiks.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Writerside\'i math-element';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math-element on semantiline Writerside\'i süntaks, mitte lubatud toor-HTML-i MathML.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Semantiline TeX-i koodiplokk';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Neid valitud laiendusi tõlgendatakse ainult avatud Writerside\'i projektides.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Märkuse plokktsitaat';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Tavaline plokktsitaat on Writerside Markdownis nõuanne; tavalises Markdownis jääb see tavaliseks tsitaadiks.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Semantilised märkused';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Tavaline Markdown ei tõlgenda neid Writerside\'i semantilisi elemente.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Ahendatav pealkiri';

  @override
  String get syntaxReferenceCollapsibleCode => 'Ahendatav koodiplokk';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Semantiline ahendatav sisu';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark toetab ahendatavaid chapter-, procedure-, code-block- ja definitsiooniloendi vorme, mitte kogu Writerside\'i kataloogi.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Semantilised koodiplokid matemaatika ja diagrammide jaoks';

  @override
  String get syntaxReferenceVideo => 'Writerside\'i video';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Kohalik video kasutab kohalikku preview-src-pilti; majutatud allikad peavad olema toetatud YouTube\'i või Vimeo HTTPS-aadressid.';

  @override
  String get exportAsPdf => 'Ekspordi PDF-ina';

  @override
  String get pdfExportDescription =>
      'Vali viimistletud ja iseseisva PDF-i leheküljendus.';

  @override
  String get pdfRemoteImagesNote =>
      'Kaugpilte eksportimisel alla ei laadita. Kohalikud pildid lisatakse, kui need on saadaval.';

  @override
  String get pdfPageSize => 'Lehe suurus';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'USA Letter';

  @override
  String get pdfOrientation => 'Paigutus';

  @override
  String get pdfPortrait => 'Püstpaigutus';

  @override
  String get pdfLandscape => 'Rõhtpaigutus';

  @override
  String get pdfMargins => 'Veerised';

  @override
  String get pdfMarginNarrow => 'Kitsad';

  @override
  String get pdfMarginNormal => 'Tavalised';

  @override
  String get pdfMarginWide => 'Laiad';

  @override
  String get pdfIncludePageNumbers => 'Lisa leheküljenumbrid';

  @override
  String get export => 'Ekspordi';

  @override
  String get exportingPdf => 'PDF-i eksportimine…';

  @override
  String get fileTypePdf => 'PDF-dokument';

  @override
  String pdfExported(String fileName) {
    return '$fileName eksporditi.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hoiatusaga',
      one: '1 hoiatusuga',
    );
    return '$fileName eksporditi $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF-i ekspordikomponent puudub. Paigalda BusyMark uuesti ja proovi veel kord.';

  @override
  String get pdfExportTimedOut =>
      'PDF-i eksport võttis liiga kaua aega ja peatati.';

  @override
  String get pdfExportFailed =>
      'BusyMark ei saanud seda dokumenti PDF-ina eksportida.';

  @override
  String get visualizationRendering => 'Renderdamine…';

  @override
  String get visualizationStale => 'Kuvatakse viimast kehtivat renderdust';

  @override
  String get visualizationShowSource => 'Kuva lähtekood';

  @override
  String get visualizationShowRender => 'Kuva renderdus';

  @override
  String get visualizationFitWidth => 'Mahuta laiusele';

  @override
  String get visualizationSaveImage => 'Salvesta pilt';

  @override
  String get visualizationCopyImage => 'Kopeeri pilt';

  @override
  String get visualizationImageCopied => 'Pilt on kopeeritud';

  @override
  String get visualizationOpenApiReference => 'Ava API viitedokumentatsioon';

  @override
  String get visualizationValid => 'Kehtiv';

  @override
  String get visualizationInvalid => 'Kehtetu';

  @override
  String get visualizationServers => 'Serverid';

  @override
  String get visualizationPaths => 'Teed';

  @override
  String get visualizationOperations => 'Toimingud';

  @override
  String get visualizationTags => 'Sildid';

  @override
  String get visualizationNoOperations => 'Sobivaid toiminguid pole';

  @override
  String get visualizationSearchOperations => 'Otsi toiminguid';

  @override
  String get visualizationRenderFailed =>
      'Seda visualiseeringut ei saanud renderdada.';

  @override
  String get visualizationRetry => 'Proovi uuesti';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName on salvestatud';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Ekspordi aktiivne dokument või Writerside’i moodul PDF-ina.';

  @override
  String get instances => 'Eksemplarid';

  @override
  String get newInstance => 'Uus eksemplar';

  @override
  String get newTocLibrary => 'Uus sisukorrateek';

  @override
  String get editInstance => 'Muuda eksemplari';

  @override
  String get openTocFile => 'Ava sisukorrafail';

  @override
  String get createInstance => 'Loo eksemplar';

  @override
  String get createTocLibrary => 'Loo sisukorrateek';

  @override
  String get instanceContent => 'Sisu';

  @override
  String get instanceContentSource => 'Loo allikast';

  @override
  String get emptyInstance => 'Tühi eksemplar';

  @override
  String get markdownFiles => 'Kohalikud Markdowni failid';

  @override
  String get chooseMarkdownFolder => 'Vali Markdowni kaust';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Vali Markdowni faile sisaldav kaust.';

  @override
  String get instanceAppearance => 'Välimus';

  @override
  String get instanceColor => 'Ikooni värv';

  @override
  String get instanceVersion => 'Versioon';

  @override
  String instanceVersionInherited(String version) {
    return 'Kui see väli on tühi, on projekti versioon $version.';
  }

  @override
  String get instanceWebPath => 'Veebitee';

  @override
  String get instanceStatus => 'Olek';

  @override
  String get instanceStatusRelease => 'Väljalase';

  @override
  String get instanceStatusEap => 'Varajane juurdepääs';

  @override
  String get instanceStatusDeprecated => 'Aegunud';

  @override
  String get allowSearchEngineIndexing => 'Luba otsingumootoritel indekseerida';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Luba välistel otsingumootoritel seda väljundit indekseerida.';

  @override
  String get offlineArtifact => 'Võrguühenduseta pakett';

  @override
  String get offlineArtifactDescription =>
      'Paki ressursid kaasa, et loodud dokumentatsioon oleks iseseisev.';

  @override
  String get instanceOutputSettings => 'Väljundi sätted';

  @override
  String get markdownImportSource => 'Markdowni allikas';

  @override
  String get markdownImportFiles => 'Markdowni failid';

  @override
  String get selectNone => 'Tühista kõik valikud';

  @override
  String markdownFilesFound(int count) {
    return 'Leiti $count Markdowni faili';
  }

  @override
  String get noMarkdownFilesFound =>
      'Sellest kaustast ei leitud Markdowni faile.';

  @override
  String get copyReferencedMedia => 'Kopeeri viidatud meedia';

  @override
  String get copyReferencedMediaDescription =>
      'Kopeeri valitud failides viidatud kohalikud pildid ja videod ning säilita suhtelised teed.';

  @override
  String get instanceIdRenameWarningTitle =>
      'Kas nimetada eksemplari ID ümber?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark nimetab .tree-faili ümber ja värskendab Writerside’i projekti viited ID-lt „$oldId” ID-le „$newId”. Avaldamisskripte ei muudeta ja need tuleb eraldi värskendada.';
  }

  @override
  String get renameAndUpdateReferences => 'Nimeta ümber ja värskenda viited';

  @override
  String get tocLibraryDescription =>
      'Sisukorrateek talletab korduskasutatavaid jaotisi ega loo oma väljundit.';

  @override
  String get defaultTocLibraryName => 'Ühine sisukord';

  @override
  String get instanceColorAutomatic => 'Automaatne';

  @override
  String get instanceColorBlue => 'Sinine';

  @override
  String get instanceColorGreen => 'Roheline';

  @override
  String get instanceColorOrange => 'Oranž';

  @override
  String get instanceColorPurple => 'Lilla';

  @override
  String get instanceColorRed => 'Punane';

  @override
  String get instanceColorTeal => 'Sinakasroheline';

  @override
  String get instanceColorYellow => 'Kollane';

  @override
  String get errorWritersideInstanceNameRequired => 'Sisesta eksemplari nimi.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'ID-ga „$id” eksemplar on juba olemas.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Eksemplaripuu on juba olemas: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdowni lähtekausta pole olemas: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Vali importimiseks vähemalt üks Markdowni fail.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'See pole valitud allika sees asuv loetav Markdowni fail: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Import kirjutaks olemasoleva projektifaili üle: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Eksemplari failid on kettal muutunud. Vaata need üle ja proovi uuesti.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark ei saanud eksemplari muudatust täielikult tagasi võtta. Vaata enne jätkamist üle need failid: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Sisukorrateeki ei saa Markdowni teemasid importida.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Veebitee peab olema ühel real.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside’i eksemplari konfiguratsioon ei kehti. Paranda diagnostikateated ja proovi uuesti.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark ei saanud eksemplari muudatusi turvaliselt ette valmistada.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Tundmatu eksemplari olek „$status”. Kasuta väärtust release, eap või deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'Eksemplari ID-d „$id” kasutab mitu puufaili.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'Faili buildprofiles.xml juurelement peab olema <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Väärtuse $name väärtus „$value” peab olema true või false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Element <build-profile> peab määrama eksemplari ID.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Puu element <include> peab määrama nii atribuudi from kui ka element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Puu element <snippet> peab määrama atribuudi id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Eksemplariülene sisukorraviide peab määrama nii atribuudi ref kui ka in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Sisukorraelement ei saa sihtida korraga mitut teemat, viidet, linki ega ümbersuunamist.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Puuelemendi ID „$id” on määratud mitu korda.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Eksemplarirühmade faili juurelement peab olema <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Eksemplarirühm peab määrama mittetühja ID ja eksemplaride loendi.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Eksemplarirühma ID „$id” on määratud mitu korda.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Sisukorra kaasamine „$source#$id” kuulub välisesse moodulisse „$origin” ja seda ei saa selles tööruumis laiendada.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Puuelementi „$id” pole registreeritud puus „$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Puu kaasamine „$source#$id” tekitab tsükli.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Eksemplari tingimus viitab tundmatule rühmale „@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Eksemplariülene viide sihib tundmatut eksemplari „$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Teemat „$topic” pole viidatud eksemplaris „$instance”.';
  }

  @override
  String get download => 'Laadi alla';

  @override
  String get exportWritersideAsPdf => 'Ekspordi Writerside PDF-ina';

  @override
  String get writersidePdfContent => 'Ekspordi sisu';

  @override
  String get writersidePdfPage => 'Lehekülg';

  @override
  String get exportingWritersidePdf => 'Writerside’i PDF-i eksportimine…';

  @override
  String get ai => 'TI';

  @override
  String get aiLocalOllama => 'Kohalik Ollama';

  @override
  String get aiDisabled => 'Keelatud';

  @override
  String get aiExplicitEditingDescription =>
      'Tehisintellektiga redigeerimine käivitatakse ainult selgesõnaliselt. BusyMark saadab valitud teenusepakkujale üksnes kuvatud konteksti ega rakenda ettepanekut ilma ülevaatuseta.';

  @override
  String get aiProvider => 'TI-teenuse pakkuja';

  @override
  String get aiDefaultProvider => 'Vaikimisi teenusepakkuja';

  @override
  String get aiConfigureProvider => 'Seadista teenusepakkujat';

  @override
  String get aiChooseProvider => 'Vali TI-teenuse pakkuja';

  @override
  String get aiOllamaEndpoint => 'Ollama lõpp-punkt';

  @override
  String get aiOllamaModel => 'Ollama mudel';

  @override
  String get aiTestConnection => 'Testi ühendust';

  @override
  String get aiTestingConnection => 'Testimine…';

  @override
  String aiConnectionReady(int count) {
    return 'Ühendatud. Leiti $count installitud mudelit.';
  }

  @override
  String get aiNoModels => 'Mudelit pole valitud.';

  @override
  String get aiConnectionFailed =>
      'BusyMark ei saanud tehisintellekti tekstiloomet kontrollida.';

  @override
  String get aiConfigureFirst =>
      'Luba jaotises Sätted → TI teenusepakkuja ning kontrolli mudelit.';

  @override
  String get aiEditWithAi => 'Redigeeri TI abil';

  @override
  String get aiRefineWithAi => 'Täiusta TI abil';

  @override
  String get aiInstruction => 'Juhis';

  @override
  String get aiChangeTarget => 'Mida võib muuta';

  @override
  String get aiSharedContext => 'TI-ga jagatav kontekst';

  @override
  String get aiTargetSelection => 'Valitud sisu';

  @override
  String get aiTargetInsertAfterBlock => 'Lisa praeguse ploki järele';

  @override
  String get aiTargetCurrentBlock => 'Praegune plokk';

  @override
  String get aiTargetCurrentSection => 'Praegune jaotis';

  @override
  String get aiTargetCompleteDocument => 'Kogu dokument';

  @override
  String get aiContextNone => 'Dokumendi kontekst puudub';

  @override
  String get aiContextSelection => 'Valitud sisu';

  @override
  String get aiContextCurrentBlock => 'Praegune plokk';

  @override
  String get aiContextCurrentSection => 'Praegune jaotis';

  @override
  String get aiContextCompleteDocument => 'Kogu dokument';

  @override
  String get aiGenerating => 'Ettepaneku loomine…';

  @override
  String get aiProposal => 'TI ettepanek';

  @override
  String get aiGenerateProposal => 'Loo ettepanek';

  @override
  String aiContextDisclosure(int count) {
    return 'Valitud teenusepakkuja saab kuvatud kontekstist $count märki.';
  }

  @override
  String get aiOriginal => 'Algtekst';

  @override
  String get aiSuggested => 'Ettepanek';

  @override
  String get aiApplyProposal => 'Rakenda ettepanek';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input sisendtokenit · $output väljundtokenit';
  }

  @override
  String get aiStaleProposal =>
      'Dokumenti muudeti ettepaneku loomise ajal. Käivita toiming uuesti.';

  @override
  String get gitAiStagedChangesChanged =>
      'Indekseeritud muudatused muutusid selle commit-sõnumi loomise ajal. Käivita toiming uuesti.';

  @override
  String get aiViewContext => 'Kuva saadetud kontekst';

  @override
  String get aiReviewExactContent => 'Vaata täpne sisu üle';

  @override
  String get aiContentToChange => 'Muudetav sisu';

  @override
  String get aiContentSentToAi => 'TI-le saadetav sisu';

  @override
  String get aiApiKey => 'API-võti';

  @override
  String get aiApiKeyStoredHint =>
      'Võti on salvestatud süsteemi mandaadihoidlasse';

  @override
  String get aiApiKeyEnterHint => 'Sisesta teenusepakkuja API-võti';

  @override
  String get aiReplaceApiKey => 'Asenda API-võti';

  @override
  String get aiSaveApiKey => 'Salvesta API-võti turvaliselt';

  @override
  String get aiRemoveApiKey => 'Eemalda salvestatud API-võti';

  @override
  String get aiCredentialSaved =>
      'API-võti salvestati süsteemi mandaadihoidlasse.';

  @override
  String get aiCredentialRemoved => 'Salvestatud API-võti eemaldati.';

  @override
  String get aiModelRouting => 'Mudeli valimine';

  @override
  String get aiAutomaticRouting => 'Automaatselt ülesande järgi';

  @override
  String get aiFixedModelRouting => 'Kasuta valitud mudelit';

  @override
  String get aiPreferredModel => 'Eelistatud mudel';

  @override
  String get aiModel => 'Mudel';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests päringut · $input sisendmärgendit · $output väljundmärgendit';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Kas saata sisu teenusele $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Luba $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Saadetakse ainult igas TI ülevaatusdialoogis kuvatud sisu. Päringud on olekuta, ettepanekud vajavad ülevaatust ja API-võti salvestatakse Linuxi süsteemi mandaadihoidlasse.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Kinnita esmalt jaotises Sätted → TI andmete jagamine teenusega $provider.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Tekstiloome mudeliga $model on kontrollitud. Saadaval on $count ühilduvat mudelit.';
  }

  @override
  String get aiColdStartObserved => 'Tuvastati kohaliku mudeli külmkäivitus.';

  @override
  String get aiNoCompatibleModels =>
      'Ühilduvat tekstiloome mudelit ei ole saadaval.';

  @override
  String get aiEnableProvider => 'Luba esmalt TI teenusepakkuja.';

  @override
  String get aiDraftCommitMessage => 'Koosta sissekande sõnumi mustand';

  @override
  String get aiDrafting => 'Mustandi koostamine…';

  @override
  String get aiDraftWithAi => 'Koosta TI-ga mustand';

  @override
  String get generateOrUpdateMarkdownToc => 'Loo/värskenda sisukord';

  @override
  String get markdownTocTitle => 'Sisukord';

  @override
  String markdownTocUpdated(int count) {
    return 'Sisukord värskendati $count kirjega.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Lisa enne sisukorra loomist vähemalt üks jaotise pealkiri.';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMarki sisukorra tähised puuduvad, korduvad või on vales järjekorras.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Taseme $level pealkiri järgneb tasemele $previousLevel; kontrolli jaotiste pesastust.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Lingi tekst on tühi; lisa ligipääsetav nimi, mis kirjeldab selle otstarvet.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Kontrolli, kas lingi tekst „$text” kirjeldab kontekstis selle otstarvet.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Tabelipäised peavad veerge kirjeldama; täida kõik tühjad päised.';

  @override
  String get mathRenderFailed => 'Matemaatilist avaldist ei saanud kuvada.';

  @override
  String get inlineMath => 'Reasisene matemaatika';

  @override
  String get displayMath => 'Plokina matemaatika';

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
