// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Nytt notat fra bevart tekst';

  @override
  String get notesAccountThrottled =>
      'Nextcloud ba om en pause. Vent før du starter innloggingen på nytt.';

  @override
  String get notesSettingsRefreshing =>
      'Oppdaterer Notes etter bekreftet innstillingsendring';

  @override
  String get notesExportOperationFailed =>
      'Eksporten mislyktes før publisering. Kontroller kilde og mål, og eksporter igjen.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Den gjenopprettede notaten er lagret, men kunne ikke åpnes. Avklar ventende redigerings- eller egenskapsendringer, og åpne denne eksisterende notaten.';

  @override
  String get notesSettingsPendingNotes =>
      'Ventende notater, konflikter eller usikre opprettelser blokkerer endringen. Synkroniser eller gjennomgå dem i Notes, og prøv det bevarte innstillingsutkastet igjen.';

  @override
  String get notesSettingsPendingAttachments =>
      'Ventende vedleggsoperasjoner blokkerer endringen. Gjennomgå vedlegg i Notes, og prøv det bevarte innstillingsutkastet igjen.';

  @override
  String get notesAccountServerAddress =>
      'Bruk Nextclouds kanoniske HTTPS-adresse og start innloggingen på nytt. Adressen eller videresendingen kunne ikke bekreftes.';

  @override
  String get notesAccountUnsupported =>
      'Notes er utilgjengelig eller API-et støttes ikke. Aktiver Nextcloud Notes med API-hovedversjon 1, underversjon 4 eller nyere.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud avviste påloggingsinformasjonen. Godkjenn kontoen på nytt eller koble til igjen.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud nektet kontroll av Notes-funksjoner. Be administratoren tillate den, og prøv igjen.';

  @override
  String get notesAccountMalformed =>
      'Nextcloud-svaret kunne ikke bekreftes. Kontroller serverinstallasjonen og logg inn igjen.';

  @override
  String get notesAccountTimedOut =>
      'Innloggingen ble tidsavbrutt. Start igjen og fullfør godkjenningen i nettleseren.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Systemnettleseren kunne ikke åpnes. Kontroller standardnettleseren og logg inn igjen.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud kunne ikke nås. Kontroller tilkobling og server, og logg inn igjen.';

  @override
  String get notesAccountRejected =>
      'Nextcloud avviste funksjonsforespørselen. Kontroller tilgang med administratoren og prøv igjen.';

  @override
  String get notesAccountFailed =>
      'Kontooppsettet kunne ikke fullføres. Prøv å logge inn igjen.';

  @override
  String get notesTransferSourceChanged =>
      'Kilden ble endret etter gjennomgang. Gjennomgå gjeldende fil eller lag et nytt øyeblikksbilde før nytt forsøk.';

  @override
  String get notesTransferUnreadable =>
      'Kilden kunne ikke leses. Kontroller tilgang til fil eller mappe, og gjennomgå igjen.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Øyeblikksbildet er ugyldig eller ustøttet. Velg et gyldig BusyMark Notes-bilde eller en Markdown-kilde.';

  @override
  String get notesTransferMediaLimit =>
      'Medier overskrider importgrensen. Reduser mediene for berørt element og gjennomgå igjen.';

  @override
  String get notesTransferUnsafeSource =>
      'Kilden inneholder en utrygg sti. Velg filer i kildemappen og gjennomgå igjen.';

  @override
  String get notesTransferDestination =>
      'Eksporten kunne ikke skrives. Kontroller tilgang og ledig plass på målet, og eksporter igjen.';

  @override
  String get notesTransferOperationFailed =>
      'Overføringen kunne ikke fullføres. Gjennomgå berørte elementer og prøv igjen. Tidligere importerte elementer er lagret.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Eksport tilgjengelig med utelatelser';

  @override
  String get notesBatchUnchanged => 'De ønskede verdiene var allerede angitt.';

  @override
  String get notesBatchReadOnly =>
      'Notaten er skrivebeskyttet. Beskyttede egenskaper kan ikke endres; Favoritt er fortsatt tillatt.';

  @override
  String get notesBatchReviewChanged =>
      'Notaten ble endret etter gjennomgang. Gjennomgå gjeldende tilstand før handlingen gjentas.';

  @override
  String get notesBatchMissing =>
      'Notaten er ikke lenger tilgjengelig. Oppdater listen og gjennomgå målene igjen.';

  @override
  String get notesBatchStorage =>
      'Lokal lagring mislyktes. Kontroller lagringsplassen og prøv dette elementet igjen; vellykkede elementer er lagret.';

  @override
  String get notesRemoteReviewChanged =>
      'Servernotaten ble endret. Fletteutkastet er bevart. Gjennomgå den oppdaterte sammenligningen og velg løsning på nytt.';

  @override
  String get notesReviewRemote => 'Jeg har gjennomgått gjeldende serverversjon';

  @override
  String get wsModuleCapsNotPublished =>
      'Modulens bokstavstil publiseres ikke.';

  @override
  String get wsTitleOverridesAction =>
      'Titler for instans og innholdsfortegnelse…';

  @override
  String get wsHeadingNotPublished => 'Publiseres ikke av denne byggeren.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Den fastlåste byggeren publiserer ikke instanstitler i Markdown-emner. Eksisterende markering bevares; se kilden.';

  @override
  String get wsTopicIdentity => 'Emne-ID';

  @override
  String get wsElementAnchor => 'Elementanker';

  @override
  String get wsHeadingText => 'Overskriftstekst';

  @override
  String get wsDefaultTitle => 'Standardtittel';

  @override
  String get wsTopicNavigation => 'Emnenavigasjon';

  @override
  String get wsHeadingOptions => 'Overskriftsattributter';

  @override
  String get wsDocumentOptions => 'Dokumentinnstillinger';

  @override
  String get wsSettingsPresent => 'Eksplisitte innstillinger finnes';

  @override
  String get wsTitleOverrideExplanation =>
      'Overstyrer publisert tittel; overskriftsteksten beholdes.';

  @override
  String get wsIgnoreVariables => 'Behandle variabeltekst bokstavelig';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Når aktivert erstattes ikke tekst som ligner variabler.';

  @override
  String get wsInstanceSelection => 'Hjelpeinstanser';

  @override
  String get wsInstanceExplanation =>
      'Velg hjelpeutgaver med navn, grupper, lister, unntak eller uttrykk.';

  @override
  String get wsFilterExplanation =>
      'Filtrer gjenbrukbart innhold etter kriterier; dette velger ikke en hjelpeinstans.';

  @override
  String get wsContextHelp => 'Konteksthjelp-ID';

  @override
  String get wsCapitalization => 'Store og små bokstaver';

  @override
  String get wsLibraryTopic => 'Bibliotekemne';

  @override
  String get wsLastModified => 'Sist endret';

  @override
  String get wsMissingTopicHeading =>
      'Ingen H1 for emnet. Legg den til i kilden.';

  @override
  String get wsMultipleTopicHeadings =>
      'Den første H1 bestemmer emnetittelen. Senere H1 er egne overskrifter.';

  @override
  String get wsTopicIdentityMismatch =>
      'Rotens id avviker fra filnavnets emne-ID. Bruk Gi emnefil nytt navn eller se kilden.';

  @override
  String get wsUnsupportedProperties =>
      'Ustøttede attributter bevares. Se dem i kilden.';

  @override
  String get wsGeneratedAnchor =>
      'Generert anker; en verdi oppretter en overstyring.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Den fastlåste byggeren publiserer ikke H1-attributter. De tilhører overskriften, ikke XML-roten.';

  @override
  String get closeOtherTabs => 'Lukk andre faner';

  @override
  String get tocTopicFromTemplate => 'Emne fra mal...';

  @override
  String get tocSaveAsTemplate => 'Lagre som mal';

  @override
  String get tocTemplateDialog => 'Opprett emne fra mal';

  @override
  String get tocTemplatesEditor => 'Fil- og kodemaler';

  @override
  String get tocEditTemplates => 'Rediger maler...';

  @override
  String get tocCreateCustomTemplate => 'Opprett egendefinert mal...';

  @override
  String get tocTemplateCreated => 'Mal opprettet';

  @override
  String get tocTemplateDefault => 'Standard';

  @override
  String get tocTemplateCustom => 'Egendefinerte';

  @override
  String get tocTemplateFilename => 'Filnavn:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Interne';

  @override
  String get tocTemplateUnnamed => 'Uten navn';

  @override
  String get tocTemplateNew => 'Ny mal...';

  @override
  String get tocTemplateName => 'Navn:';

  @override
  String get tocTemplateExtension => 'Filtype:';

  @override
  String get tocTemplateLoadError =>
      'Kunne ikke laste maler. Eksisterende maler er ikke endret.';

  @override
  String get tocTemplateSaveError =>
      'Kunne ikke lagre maler. Endringene dine er fortsatt tilgjengelige her.';

  @override
  String get tocTemplateConflict =>
      'Malene ble endret i et annet vindu. Avbryt og åpne redigereren på nytt.';

  @override
  String get tocTemplateDuplicateName =>
      'En mal med dette navnet og denne filtypen finnes allerede.';

  @override
  String get tocTemplateFormat => 'Format:';

  @override
  String get tocTemplateReset => 'Tilbakestill';

  @override
  String get tocTemplateRetry => 'Prøv igjen';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Fjern $count innholdsfortegnelseselementer';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Kildefilene som er knyttet til disse innholdsfortegnelseselementene, blir ikke slettet.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Velg emne som skal legges til i gjeldende instans';

  @override
  String get tocGroupName => 'Gruppenavn';

  @override
  String get tocMoveLineUp => 'Flytt linje opp';

  @override
  String get tocMoveLineDown => 'Flytt linje ned';

  @override
  String get tocEmptyMdTopic => 'Tomt MD-emne';

  @override
  String get tocEmptyXmlTopic => 'Tomt XML-emne';

  @override
  String get tocCopySpecial => 'Spesiell kopiering';

  @override
  String tocCopyFileName(String name) {
    return 'Emnefilnavn \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Emnefilbane';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Emnetittel \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID for innholdsfortegnelseselement \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Emnefilnavn';

  @override
  String get tocCopyTopicTitleUnavailable => 'Emnetittel';

  @override
  String get tocCopyElementIdUnavailable =>
      'ID for innholdsfortegnelseselement';

  @override
  String get tocEditTitleAction => 'Rediger tittel...';

  @override
  String get tocEditTitleDialog => 'Rediger tittel';

  @override
  String get tocRemoveElementAction => 'Fjern innholdsfortegnelseselement...';

  @override
  String get tocSetHomePage => 'Angi som startside';

  @override
  String tocGoToElement(String fileName) {
    return 'Gå til innholdsfortegnelseselement i \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Synkroniser innholdsfortegnelse og redigering';

  @override
  String get tocEmptyGroupAction => 'Tom gruppe';

  @override
  String get tocNewEmptyGroup => 'Ny tom gruppe';

  @override
  String get tocGroupAction => 'Grupper';

  @override
  String get tocNewGroup => 'Ny gruppe';

  @override
  String get tocSortChildren => 'Sorter underemner alfabetisk';

  @override
  String get tocLinkTopicFiles => 'Koble emnefiler til innholdsfortegnelsen...';

  @override
  String get addLocalMarkdownFiles => 'Legg til lokale Markdown-filer';

  @override
  String get tocTitleField => 'Tittel i innholdsfortegnelsen:';

  @override
  String get tocTopicTitleField => 'Emnetittel:';

  @override
  String get tocAdvancedSettings => 'Avanserte innstillinger';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Tittel for \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Tittel kun for innholdsfortegnelsen:';

  @override
  String get tocInstanceTitleExplanation =>
      'Brukes bare for den gjeldende instansen. Arves som standard fra emnetittelen.';

  @override
  String get tocOnlyTitleExplanation =>
      'Brukes bare i innholdsfortegnelsen. Arves som standard fra emnetittelen eller den instansspesifikke tittelen hvis den er angitt. Titler er forklart';

  @override
  String get tocTitleDocumentationLink => 'her';

  @override
  String get tocFindUsages => 'Finn';

  @override
  String get tocRefactorMenu => 'Refaktorer';

  @override
  String get tocSafeDelete => 'Sikker sletting';

  @override
  String get tocDuplicate => 'Dupliser';

  @override
  String get tocDuplicateFilename => 'Emnefilnavn:';

  @override
  String get tocDuplicateDialog => 'Dupliser emne';

  @override
  String get pdfTitlePage => 'Tittelside';

  @override
  String get pdfIncludeTitlePage => 'Ta med tittelside';

  @override
  String get pdfTitlePageNote =>
      'Denne siden har ingen topptekst, bunntekst eller synlig sidetall.';

  @override
  String get pdfTitlePageTitle => 'Tittel';

  @override
  String get pdfTitlePageSubtitle => 'Undertittel';

  @override
  String get pdfTitlePageAuthor => 'Forfatter';

  @override
  String get pdfTitlePageOrganization => 'Organisasjon';

  @override
  String get pdfTitlePageVersion => 'Versjon';

  @override
  String get pdfTitlePageDate => 'Dato';

  @override
  String get pdfTitlePageTitleRequired =>
      'Skriv inn en tittel for tittelsiden.';

  @override
  String get pdfTocSectionNote =>
      'Starter på en egen side og kan gå over flere sider.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Redigerer for Markdown-filer og Writerside-kompatible dokumentasjonsprosjekter.';

  @override
  String get aboutBusyMark => 'Om BusyMark';

  @override
  String get aboutTagline => 'Markdown- og Writerside-redigerer';

  @override
  String get aboutLicenseLabel => 'Lisens';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Nettsted';

  @override
  String get aboutSourceCode => 'Kildekode';

  @override
  String get reportIssue => 'Rapporter et problem';

  @override
  String get feedbackCategory => 'Kategori';

  @override
  String get feedbackChooseCategory => 'Velg en kategori';

  @override
  String get feedbackCategoryProblem => 'Problem eller feil';

  @override
  String get feedbackCategoryFeature => 'Funksjonsønske';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Bekymring om personvern eller sikkerhet';

  @override
  String get feedbackCategoryUsability => 'Bekymring om brukervennlighet';

  @override
  String get feedbackCategoryOther => 'Annet';

  @override
  String get feedbackSubject => 'Emne';

  @override
  String get feedbackMessage => 'Detaljert melding';

  @override
  String get feedbackReplyEmail => 'E-post for svar (valgfritt)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Ta med tekniske detaljer';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Når dette er aktivert, legges bare Linux-operativsystemversjonen og BusyMark-programmets lokalinnstilling til. Ingen logger, filer, kontodata eller annen diagnostikk legges ved.';

  @override
  String get feedbackSubmit => 'Send';

  @override
  String get feedbackSubmitting => 'Sender…';

  @override
  String get feedbackCategoryRequired => 'Velg en kategori.';

  @override
  String get feedbackSubjectLength =>
      'Emnet må inneholde mellom 3 og 120 tegn.';

  @override
  String get feedbackMessageLength =>
      'Meldingen må inneholde mellom 10 og 5000 tegn.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Skriv inn en gyldig e-postadresse, eller la feltet stå tomt.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark kunne ikke koble til. Kontroller internettforbindelsen og prøv igjen.';

  @override
  String get feedbackTimeoutFailure =>
      'Forespørselen ble tidsavbrutt. Prøv igjen.';

  @override
  String get feedbackRateLimitedFailure =>
      'Det ble sendt for mange rapporter fra denne forbindelsen. Vent og prøv igjen.';

  @override
  String get feedbackRejectedFailure =>
      'Serveren avviste rapporten. Kontroller skjemafeltene og prøv igjen.';

  @override
  String get feedbackServerFailure =>
      'Serveren kunne ikke ta imot rapporten. Prøv igjen senere.';

  @override
  String feedbackSuccess(String id) {
    return 'Tilbakemeldingen er sendt. Referanse-ID: $id';
  }

  @override
  String get advanced => 'Avansert';

  @override
  String get addToGit => 'Legg til i Git';

  @override
  String get appearance => 'Utseende';

  @override
  String get apply => 'Bruk';

  @override
  String get back => 'Tilbake';

  @override
  String get bottomLeft => 'Nederst til venstre';

  @override
  String get bottomRight => 'Nederst til høyre';

  @override
  String get cancel => 'Avbryt';

  @override
  String get choose => 'Velg';

  @override
  String get chooseLocation => 'Velg plassering';

  @override
  String get copy => 'Kopier';

  @override
  String get copyPlainText => 'Kopier som ren tekst';

  @override
  String get clipboardCopyFailed =>
      'Utvalget kunne ikke kopieres til utklippstavlen.';

  @override
  String get copyName => 'Kopier navn';

  @override
  String get copyFileName => 'Kopier filnavn';

  @override
  String get copyPath => 'Kopier sti';

  @override
  String get create => 'Opprett';

  @override
  String get creating => 'Oppretter...';

  @override
  String get cut => 'Klipp ut';

  @override
  String get promoteSection => 'Hev seksjonen';

  @override
  String get demoteSection => 'Senk seksjonen';

  @override
  String get moveSectionUp => 'Flytt seksjonen opp';

  @override
  String get moveSectionDown => 'Flytt seksjonen ned';

  @override
  String get confirmDeleteSectionTitle => 'Slette seksjonen?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Slette «$name» og alt innholdet i seksjonen? Dette kan ikke angres.';
  }

  @override
  String get darkTheme => 'Mørk';

  @override
  String get delete => 'Slett';

  @override
  String get discard => 'Forkast';

  @override
  String get editor => 'Redigerer';

  @override
  String get file => 'Fil';

  @override
  String get fileHistory => 'Filhistorikk';

  @override
  String get folder => 'Mappe';

  @override
  String get insert => 'Sett inn';

  @override
  String get keyboardShortcuts => 'Tastatursnarveier';

  @override
  String get commandUnavailableInContext =>
      'Denne kommandoen er ikke tilgjengelig i gjeldende kontekst.';

  @override
  String get lightTheme => 'Lys';

  @override
  String get mainMenu => 'Hovedmeny';

  @override
  String get fullScreen => 'Fullskjerm';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Åpne';

  @override
  String get openInFiles => 'Åpne i Filer';

  @override
  String get pathActions => 'Stihandlinger';

  @override
  String get outline => 'Disposisjon';

  @override
  String get overwrite => 'Overskriv';

  @override
  String get paste => 'Lim inn';

  @override
  String get reading => 'Lesevisning';

  @override
  String get removeFromRecent => 'Fjern fra nylige';

  @override
  String get recent => 'Nylige';

  @override
  String get redo => 'Gjør om';

  @override
  String get save => 'Lagre';

  @override
  String get search => 'Søk';

  @override
  String get selectAll => 'Velg alle';

  @override
  String get settings => 'Innstillinger';

  @override
  String get source => 'Kilde';

  @override
  String get split => 'Delt';

  @override
  String get systemTheme => 'System';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Språk';

  @override
  String get systemLanguage => 'System';

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
  String get toggleSidebar => 'Sidepanel';

  @override
  String get topLeft => 'Øverst til venstre';

  @override
  String get topRight => 'Øverst til høyre';

  @override
  String get undo => 'Angre';

  @override
  String get validate => 'Valider';

  @override
  String get validation => 'Validering';

  @override
  String get viewMode => 'Visningsmodus';

  @override
  String get welcome => 'Velkommen';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Bilder';

  @override
  String get openMarkdownFile => 'Åpne Markdown-fil';

  @override
  String get markdownFileExtensions => '.md eller .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Åpne mappe eller Writerside-prosjekt';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown-mappe eller Writerside-kompatibelt prosjekt';

  @override
  String get noOpenFile => 'Ingen åpen fil';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Slett det valgte elementet i Filer, eller fjern det valgte emnet fra innholdsfortegnelsen';

  @override
  String get shortcutGroupGeneral => 'Generelt';

  @override
  String get shortcutNewDocument => 'Opprett';

  @override
  String get shortcutNewDocumentDescription =>
      'Opprett en Markdown-fil eller et Writerside-prosjekt';

  @override
  String get shortcutOpenDescription =>
      'Åpne en Markdown-fil, en mappe eller et Writerside-prosjekt';

  @override
  String get shortcutSaveDescription => 'Lagre gjeldende dokument';

  @override
  String get shortcutSearchDescription => 'Søk i gjeldende arbeidsområde';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Tilpass programmets hurtigtaster';

  @override
  String get shortcutSyntaxReferenceDescription => 'Åpne syntaksreferansen';

  @override
  String get shortcutSettingsDescription => 'Åpne BusyMark-innstillinger';

  @override
  String get shortcutNextTab => 'Neste fane';

  @override
  String get shortcutNextTabDescription => 'Gå til neste åpne fane';

  @override
  String get shortcutPreviousTab => 'Forrige fane';

  @override
  String get shortcutPreviousTabDescription => 'Gå til forrige åpne fane';

  @override
  String get shortcutCloseTab => 'Lukk fane';

  @override
  String get shortcutCloseTabDescription => 'Lukk den aktive fanen';

  @override
  String get shortcutCloseAllTabs => 'Lukk alle faner';

  @override
  String get shortcutCloseAllTabsDescription => 'Lukk alle åpne faner';

  @override
  String get shortcutGroupTextEditing => 'Tekstredigering';

  @override
  String get shortcutSelectAllDescription =>
      'Velg all tekst i kildemodus; trykk to ganger i redigeringsmodus for å velge alle blokker';

  @override
  String get shortcutCutDescription => 'Klipp ut den valgte teksten';

  @override
  String get shortcutCopyDescription => 'Kopier den valgte teksten';

  @override
  String get shortcutPasteDescription => 'Lim inn fra utklippstavlen';

  @override
  String get shortcutPastePlainTextDescription =>
      'Lim inn utklippstavletekst uten formatering';

  @override
  String get shortcutUndoDescription => 'Angre siste redigering';

  @override
  String get shortcutRedoDescription =>
      'Gjør om den siste angrede redigeringen';

  @override
  String get shortcutInsertIndentation => 'Sett inn innrykk';

  @override
  String get shortcutInsertIndentationDescription =>
      'Sett inn innrykk ved markøren';

  @override
  String get shortcutOutdentSource => 'Reduser innrykk i kilden';

  @override
  String get shortcutOutdentSourceDescription =>
      'Fjern ett innrykksnivå i kildemodus';

  @override
  String get shortcutEscape => 'Lukk søk eller fjern blokkmarkering';

  @override
  String get shortcutEscapeDescription =>
      'Lukk arbeidsområdesøket eller fjern en blokkmarkering i redigeringsmodus';

  @override
  String get shortcutGroupFormatting => 'Formatering';

  @override
  String get shortcutBoldDescription =>
      'Slå fet skrift av/på for den valgte teksten';

  @override
  String get shortcutItalicDescription =>
      'Slå kursiv av/på for den valgte teksten';

  @override
  String get shortcutUnderlineDescription =>
      'Slå understreking av/på for den valgte teksten';

  @override
  String get shortcutLinkDescription => 'Sett inn eller rediger en lenke';

  @override
  String get shortcutInlineCodeDescription =>
      'Slå inline-kode av/på for den valgte teksten';

  @override
  String get shortcutStrikethroughDescription =>
      'Slå gjennomstreking av/på for den valgte teksten';

  @override
  String get shortcutGroupBlocks => 'Blokker';

  @override
  String get shortcutParagraphDescription => 'Sett gjeldende blokk til avsnitt';

  @override
  String get shortcutHeading1Description =>
      'Sett gjeldende blokk til overskrift 1';

  @override
  String get shortcutHeading2Description =>
      'Sett gjeldende blokk til overskrift 2';

  @override
  String get shortcutHeading3Description =>
      'Sett gjeldende blokk til overskrift 3';

  @override
  String get shortcutHeading4Description =>
      'Sett gjeldende blokk til overskrift 4';

  @override
  String get shortcutHeading5Description =>
      'Sett gjeldende blokk til overskrift 5';

  @override
  String get shortcutHeading6Description =>
      'Sett gjeldende blokk til overskrift 6';

  @override
  String get shortcutGroupLists => 'Lister';

  @override
  String get numberedList => 'Nummerert liste';

  @override
  String get shortcutNumberedListDescription => 'Slå nummerert liste av/på';

  @override
  String get bulletedList => 'Punktliste';

  @override
  String get shortcutBulletedListDescription => 'Slå punktliste av/på';

  @override
  String get checklist => 'Sjekkliste';

  @override
  String get shortcutChecklistDescription => 'Slå sjekkliste av/på';

  @override
  String get shortcutGroupSidebar => 'Sidefelt';

  @override
  String get sidebarViewMenu => 'Sidefeltvisning';

  @override
  String get createMarkdownFile => 'Opprett Markdown-fil';

  @override
  String get createMarkdownFileDescription =>
      'Opprett et ulagret lokalt Markdown-dokument';

  @override
  String get createWritersideProject => 'Opprett Writerside-prosjekt';

  @override
  String get createWritersideProjectDescription =>
      'Opprett et lokalt Writerside-kompatibelt prosjekt';

  @override
  String get defaultProjectName => 'Dokumentasjon';

  @override
  String get defaultInstanceName => 'Brukerveiledning';

  @override
  String get defaultStartTopicTitle => 'Kom i gang';

  @override
  String get projectName => 'Prosjektnavn';

  @override
  String get directoryName => 'Mappenavn';

  @override
  String get instanceName => 'Instansnavn';

  @override
  String get instanceId => 'Instans-ID';

  @override
  String get startTopicTitle => 'Tittel på startemne';

  @override
  String get location => 'Plassering';

  @override
  String get projectNameRequired => 'Prosjektnavn er påkrevd.';

  @override
  String get directoryNameRequired => 'Mappenavn er påkrevd.';

  @override
  String get useSingleSafeDirectoryName => 'Bruk ett enkelt, trygt mappenavn.';

  @override
  String get useLowercaseIdentifier =>
      'Bruk en identifikator med små bokstaver, tall, understrek eller bindestrek.';

  @override
  String get startTopicTitleRequired => 'Tittel på startemne er påkrevd.';

  @override
  String get createWritersideProjectFailed =>
      'Kunne ikke opprette Writerside-prosjektet.';

  @override
  String get settingsTitle => 'Innstillinger for BusyMark';

  @override
  String get autoSave => 'Automatisk lagring';

  @override
  String get autoSaveDescription =>
      'Lagre filendringer automatisk etter en kort pause i redigeringen.';

  @override
  String get wordWrap => 'Tekstbryting';

  @override
  String get wordWrapDescription =>
      'Bryt lange linjer så de passer til redigeringsbredden i stedet for å rulle vannrett.';

  @override
  String get editorFontSize => 'Skriftstørrelse i redigereren';

  @override
  String get validateOnEdit => 'Valider under redigering';

  @override
  String get clearRecentWorkspaces => 'Tøm nylig historikk';

  @override
  String get editingButtonsPosition => 'Plassering av redigeringsknapper';

  @override
  String get editingButtonsPositionDescription =>
      'Velg hvor de flytende WYSIWYG-redigeringsknappene skal vises.';

  @override
  String get editingButtonsDirection => 'Retning for redigeringsknapper';

  @override
  String get editingButtonsDirectionDescription =>
      'Velg om de flytende WYSIWYG-redigeringsknappene skal ordnes vannrett eller loddrett.';

  @override
  String get horizontal => 'Vannrett';

  @override
  String get vertical => 'Loddrett';

  @override
  String get privacy => 'Personvern';

  @override
  String get allowRemoteImages => 'Last inn eksterne bilder';

  @override
  String get allowRemoteImagesDescription =>
      'Tillat at bilder i Markdown-forhåndsvisningen og redigereren lastes inn fra HTTP- og HTTPS-adresser.';

  @override
  String get clearRemoteImagePermissions =>
      'Tøm tillatelser for eksterne bilder';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Glem arbeidsområder som fikk tillatelse til å laste inn eksterne bilder.';

  @override
  String get clearGitWorkspaceTrust => 'Tøm klarerte Git-arbeidsområder';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Spør før Git-funksjoner aktiveres for tidligere klarerte arbeidsområder.';

  @override
  String get settingsEditingButtonsSectionTitle => 'Redigeringsknapper';

  @override
  String get spellingDictionaries => 'Stavekontrollordbøker';

  @override
  String get spellingDictionariesDescription =>
      'Installer og administrer stavekontrollordbøker';

  @override
  String get settingsDictionariesSectionTitle => 'Ordbøker';

  @override
  String get availableSpellingDictionaries => 'Tilgjengelige ordbøker';

  @override
  String get customSpellingDictionaries => 'Egendefinerte ordbøker';

  @override
  String get spellingDictionaryProblems => 'Ordbokproblemer';

  @override
  String get settingsWindowSectionTitle => 'Vindu';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Åpne forrige arbeidsområde ved oppstart';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Åpne arbeidsområdet og fanene fra forrige økt når BusyMark starter.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Bekreft lukking ved ulagrede endringer';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Spør før BusyMark lukkes når dokumenter har ulagrede endringer.';

  @override
  String get closeUnsavedChangesTitle => 'Ulagrede endringer';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Dette dokumentet har ulagrede endringer. Lagre endringene før BusyMark lukkes?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumenter har ulagrede endringer. Lagre endringene før BusyMark lukkes?',
      one:
          '1 dokument har ulagrede endringer. Lagre endringene før BusyMark lukkes?',
      zero: 'Lagre endringene før BusyMark lukkes?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Avbryt';

  @override
  String get closeUnsavedChangesDiscard => 'Forkast';

  @override
  String get closeUnsavedChangesSave => 'Lagre';

  @override
  String get currentFile => 'gjeldende fil';

  @override
  String get unsavedChanges => 'Ulagrede endringer';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Du har ulagrede endringer i $fileName. Vil du lagre dem før du fortsetter?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumenter har ulagrede endringer. Lagre dem før du fortsetter.',
      one: '1 dokument har ulagrede endringer. Lagre det før du fortsetter.',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Fil endret på disken';

  @override
  String get fileChangedOnDiskMessage =>
      'Denne filen er endret på disken siden du åpnet den. Vil du overskrive den?';

  @override
  String get untitledMarkdownFileName => 'Uten tittel.md';

  @override
  String get unorderedList => 'Uordnet liste';

  @override
  String get orderedList => 'Nummerert liste';

  @override
  String get taskList => 'Oppgaveliste';

  @override
  String get toggleTaskChecked => 'Merk av/fjern avmerking for oppgave';

  @override
  String get indentListItem => 'Rykk inn listeelement';

  @override
  String get outdentListItem => 'Rykk ut listeelement';

  @override
  String get blockquote => 'Sitatblokk';

  @override
  String get codeBlock => 'Kodeblokk';

  @override
  String get codeBlockLanguage => 'Språk for kodeblokk';

  @override
  String get image => 'Bilde';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Spill av video';

  @override
  String get pauseVideo => 'Sett video på pause';

  @override
  String get videoUnavailable => 'Videoen er utilgjengelig';

  @override
  String get videoPreview => 'Videoforhåndsvisning';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Videoen mangler src-attributtet.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Videokilden støttes ikke: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Videofilen finnes ikke: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Forhåndsvisningsbildet finnes ikke: $preview';
  }

  @override
  String get inlineImage => 'Innebygd bilde';

  @override
  String get table => 'Tabell';

  @override
  String get htmlBlock => 'HTML-blokk';

  @override
  String get htmlContentDefault => 'HTML-innhold';

  @override
  String get shortcutHtmlBlockDescription =>
      'Sett inn eller rediger en HTML-blokk';

  @override
  String get renderedHtml => 'Gjengitt HTML';

  @override
  String get editHtml => 'Rediger HTML';

  @override
  String get htmlSource => 'HTML-kilde';

  @override
  String get thematicBreak => 'Tematisk skille';

  @override
  String get bold => 'Fet skrift';

  @override
  String get italic => 'Kursiv';

  @override
  String get underline => 'Understreking';

  @override
  String get strikethrough => 'Gjennomstreking';

  @override
  String get inlineCode => 'Inline-kode';

  @override
  String get link => 'Lenke';

  @override
  String get hardLineBreak => 'Tvungent linjeskift';

  @override
  String get insertBlankLine => 'Sett inn tom linje';

  @override
  String get textStyle => 'Tekststil';

  @override
  String get paragraph => 'Avsnitt';

  @override
  String get heading1 => 'Overskrift 1';

  @override
  String get heading2 => 'Overskrift 2';

  @override
  String get heading3 => 'Overskrift 3';

  @override
  String get heading4 => 'Overskrift 4';

  @override
  String get heading5 => 'Overskrift 5';

  @override
  String get heading6 => 'Overskrift 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Slett tabell';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Kolonne $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Sett inn kolonne til venstre';

  @override
  String get insertColumnRight => 'Sett inn kolonne til høyre';

  @override
  String get deleteColumn => 'Slett kolonne';

  @override
  String get tableAlignmentUnspecified => 'Justering: ikke angitt';

  @override
  String get tableAlignmentLeft => 'Justering: venstre';

  @override
  String get tableAlignmentCenter => 'Justering: midtstilt';

  @override
  String get tableAlignmentRight => 'Justering: høyre';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Rad $rowNumber';
  }

  @override
  String get insertRowAbove => 'Sett inn rad over';

  @override
  String get insertRowBelow => 'Sett inn rad under';

  @override
  String get deleteRow => 'Slett rad';

  @override
  String get tableHeaderHint => 'Overskrift';

  @override
  String get tableCellHint => 'Celle';

  @override
  String get language => 'Språk';

  @override
  String get hideEditingButtons => 'Skjul redigeringsknapper';

  @override
  String get showEditingButtons => 'Vis redigeringsknapper';

  @override
  String get altText => 'Alternativ tekst';

  @override
  String get editorPlaceholderText => 'tekst';

  @override
  String get editorPlaceholderCode => 'kode';

  @override
  String get editorPlaceholderAltText => 'alternativ tekst';

  @override
  String get describeTheImage => 'Beskriv bildet';

  @override
  String get columns => 'Kolonner';

  @override
  String get rows => 'Rader';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Overskrift $columnNumber';
  }

  @override
  String get tableCellDefault => 'Celle';

  @override
  String get noImageSource => 'Ingen bildekilde';

  @override
  String get remoteImageBlocked => 'Eksternt bilde blokkert';

  @override
  String get remoteImageBlockedTooltip =>
      'Velg om BusyMark kan laste inn eksterne bilder.';

  @override
  String get remoteImagesBlockedTitle => 'Eksterne bilder er blokkert';

  @override
  String get remoteImagesBlockedMessage =>
      'Dette dokumentet refererer til bilder på Internett. Når de lastes inn, kan nettverksinformasjon bli avslørt for bildeverten.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Last inn for dette arbeidsområdet';

  @override
  String get alwaysLoadRemoteImages => 'Last alltid inn eksterne bilder';

  @override
  String get hideSidebar => 'Skjul sidepanel';

  @override
  String get showSidebar => 'Vis sidepanel';

  @override
  String get showPreview => 'Vis forhåndsvisning';

  @override
  String get hidePreview => 'Skjul forhåndsvisning';

  @override
  String get workspaceKindUnsavedMarkdown => 'Ulagret Markdown-fil';

  @override
  String get workspaceKindSingleMarkdown => 'Én Markdown-fil';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown-mappe';

  @override
  String get workspaceKindWritersideModule => 'Writerside-modul';

  @override
  String get problems => 'Problemer';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostikkmeldinger',
      one: '1 diagnostikkmelding',
      zero: 'Ingen diagnostikkmeldinger',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Filer';

  @override
  String get toc => 'Innholdsfortegnelse';

  @override
  String get tocActions => 'Handlinger for innholdsfortegnelsen';

  @override
  String get markdownUnsaved => 'Markdown – ikke lagret';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
    );
    return '$kind – $_temp0';
  }

  @override
  String get noFiles => 'Ingen filer';

  @override
  String get newFile => 'Ny fil';

  @override
  String get noWritersideToc => 'Ingen Writerside-innholdsfortegnelse';

  @override
  String get tocSection => 'Del av innholdsfortegnelsen';

  @override
  String get newTopic => 'Nytt emne';

  @override
  String get newChildTopic => 'Nytt underemne';

  @override
  String get newSiblingTopic => 'Nytt emne';

  @override
  String get renameTopicFile => 'Gi emnefilen nytt navn';

  @override
  String get topicPlacement => 'Plassering i innholdsfortegnelsen';

  @override
  String get tocRoot => 'På toppnivå i innholdsfortegnelsen';

  @override
  String get afterSelectedTopic => 'Etter valgt emne';

  @override
  String get insideSelectedTopic => 'Under valgt emne';

  @override
  String get pasteAfterTopic => 'Lim inn etter';

  @override
  String get pasteAsChildTopic => 'Lim inn som underemne';

  @override
  String get removeFromToc => 'Fjern fra innholdsfortegnelsen';

  @override
  String get confirmRemoveFromTocTitle => 'Fjerne fra innholdsfortegnelsen?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Fjerne $name fra denne innholdsfortegnelsen? Emnefilen beholdes.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Slette emnefilen?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Slette $name og fjerne den fra alle innholdsfortegnelser? Dette kan ikke angres.';
  }

  @override
  String get safeDeleteTopicFile => 'Slett emnefilen trygt …';

  @override
  String get removeTocElement => 'Fjern element fra innholdsfortegnelsen';

  @override
  String get removeTocElements => 'Fjern elementer fra innholdsfortegnelsen';

  @override
  String get reviewUsages => 'Se gjennom bruk';

  @override
  String get deleteTopicFile => 'Slett emnefil';

  @override
  String get removeAction => 'Fjern';

  @override
  String topicRemovalSummary(String topic) {
    return 'Fjerne innholdsfortegnelseselementet «$topic»? Den tilknyttede kildefilen blir ikke slettet.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Slett «$topic», og oppdater referansene til emnet trygt i hele dette Writerside-prosjektet.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count underemner flyttes ett nivå opp.',
      one: '1 underemne flyttes ett nivå opp.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning =>
      'Dette emnet er startsiden for denne instansen. Velg en annen startside før du fjerner det fra innholdsfortegnelsen.';

  @override
  String get newHomePage => 'Ny startside';

  @override
  String get chooseHomePage => 'Velg en startside';

  @override
  String get noHomePageReplacement =>
      'Legg til eller koble et annet egnet emne til denne instansen før du fjerner startsiden.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Dette emnet er startsiden for en instans. Angi en annen startside før du sletter kildefilen.';

  @override
  String topicUsagesCount(int count) {
    return '$count brukssteder funnet.';
  }

  @override
  String get noBreakingTopicUsages =>
      'Fant ingen referanser som ville slutte å fungere.';

  @override
  String get topicUsagesFound =>
      'BusyMark fant følgende referanser til dette emnet.';

  @override
  String get topicUsageTocElements => 'Elementer i innholdsfortegnelsen';

  @override
  String get topicUsageStartPages => 'Startsider';

  @override
  String get topicUsageTopicLinks => 'Emnelenker';

  @override
  String get topicUsageIncludes => 'Inkluderinger';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bruk',
      one: '1 bruk',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Refaktoreringsalternativer';

  @override
  String get updateUsagesAutomatically => 'Oppdater bruk automatisk';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Fjern referanser i innholdsfortegnelsen og inkluderinger, og behold lenketeksten.';

  @override
  String get manualUsageUpdatesRequired =>
      'Noe bruk må endres manuelt før denne refaktoreringen.';

  @override
  String get setRedirectTo => 'Omdiriger til:';

  @override
  String get noRedirectDescription =>
      'Ikke omdiriger den gamle publiserte siden.';

  @override
  String get redirectTarget => 'Mål for omdirigering';

  @override
  String get remainingUsagesBlockRemoval =>
      'Se gjennom og oppdater gjenværende bruk før du fortsetter, eller slå på automatiske oppdateringer når de er tilgjengelige.';

  @override
  String usagesOfTopic(String topic) {
    return 'Bruk av «$topic»';
  }

  @override
  String get noUsagesFound => 'Fant ingen bruk.';

  @override
  String get outsideSelectedInstance => 'utenfor den valgte instansen';

  @override
  String get doRefactor => 'Utfør refaktorering';

  @override
  String get preview => 'Forhåndsvisning';

  @override
  String get topicRenamePreviewTitle => 'Forhåndsvisning av navneendring';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Sti: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'Emne-ID: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instans $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Berørte filer';

  @override
  String get orphanTopicTitle => 'Emnefilen brukes ikke lenger';

  @override
  String get keepTopicFile => 'Behold emnefilen';

  @override
  String orphanTopicMessage(String topic) {
    return '«$topic» brukes ikke lenger noe sted i dette Writerside-prosjektet. Slett filen, eller behold den for bruk i en annen instans.';
  }

  @override
  String get defaultNewTopicTitle => 'Nytt emne';

  @override
  String get topicTitle => 'Emnetittel';

  @override
  String get fileName => 'Filnavn';

  @override
  String get topicTitleRequired => 'Emnetittel er påkrevd.';

  @override
  String get fileNameRequired => 'Filnavn er påkrevd.';

  @override
  String get rename => 'Gi nytt navn';

  @override
  String get confirmDeleteFileTitle => 'Slette fil?';

  @override
  String get confirmDeleteFolderTitle => 'Slette mappe?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Slette $name? Dette kan ikke angres.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Slette $name og alle filene i den? Dette kan ikke angres.';
  }

  @override
  String get useSingleSafeFileName => 'Bruk ett enkelt, trygt filnavn.';

  @override
  String useExpectedExtension(String extension) {
    return 'Bruk filendelsen $extension for det valgte formatet.';
  }

  @override
  String get useIdentifierCharacters =>
      'Bruk bokstaver, tall, understrek eller bindestrek før filendelsen.';

  @override
  String get topicIdAlreadyExists => 'Emne-ID-en finnes allerede.';

  @override
  String get createWritersideTopicFailed =>
      'Kunne ikke opprette Writerside-emne.';

  @override
  String get noOutline => 'Ingen disposisjon';

  @override
  String expandKind(String kind) {
    return 'Utvid $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Fold sammen $kind';
  }

  @override
  String get foldKindSection => 'seksjon';

  @override
  String get foldKindList => 'liste';

  @override
  String get foldKindQuote => 'sitat';

  @override
  String get foldKindTag => 'tagg';

  @override
  String get sourceSearchPreviousMatch => 'Forrige treff';

  @override
  String get sourceSearchNextMatch => 'Neste treff';

  @override
  String get sourceSearchReplacement => 'Erstatt med';

  @override
  String get sourceSearchReplaceCurrent => 'Erstatt gjeldende treff';

  @override
  String get sourceSearchReplaceAndFindNext => 'Erstatt og finn neste';

  @override
  String get sourceSearchReplaceAll => 'Erstatt alle';

  @override
  String get workspaceReplace => 'Erstatt i arbeidsområdet';

  @override
  String get reviewReplacements => 'Se gjennom erstatninger';

  @override
  String get applyReplacements => 'Bruk erstatninger';

  @override
  String get skippedFiles => 'Filer som ble hoppet over';

  @override
  String get workspaceReplaceDirtyBuffer => 'Ulagret redigeringsinnhold';

  @override
  String get workspaceReplaceDiskContent => 'Innhold lagret på disk';

  @override
  String selectFileMatches(int count) {
    return 'Velg alle $count treff';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Erstattet $matches treff i $files filer; hoppet over $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Avsluttende linjeskift';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Ingen avsluttende linjeskift';
  }

  @override
  String get normalizeLineEndings => 'Normaliser linjeslutt';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Dette dokumentet inneholder blandede linjeslutt. Velg et format.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName bruker blandede linjeslutt. Velg format før du erstatter.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'En for stor fil ble hoppet over.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'En fil som ikke kunne leses, ble hoppet over.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'En fil som ikke er gyldig UTF-8, ble hoppet over.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Erstatningsforhåndsvisningen ble avkortet.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'En fil som ble endret etter forhåndsvisningen, ble hoppet over.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'En redigeringsbuffer som ble endret etter forhåndsvisningen, ble hoppet over.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Velg LF- eller CRLF-normalisering før du erstatter.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Tilbakerullingen ble stoppet fordi filen ble endret samtidig. Noen erstatninger kan fortsatt være utført; forskjøvet innhold ble bevart på banen nedenfor.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Ingen erstatninger ble utført fordi det gjennomgåtte settet ikke kunne lagres på en trygg måte.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Eksterne endringer — $fileName';
  }

  @override
  String get externalFileDeleted => 'Denne filen ble slettet fra disken.';

  @override
  String get externalFileChanged =>
      'Denne filen ble endret på disken mens du har ulagrede endringer.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Ulagret innhold for $fileName ble gjenopprettet. Se gjennom det, og lagre, lagre som eller forkast det.';
  }

  @override
  String get compare => 'Sammenlign';

  @override
  String get reloadFromDisk => 'Last inn fra disk på nytt';

  @override
  String get keepMine => 'Behold min versjon';

  @override
  String get saveAs => 'Lagre som';

  @override
  String get workspaceSearchIncomplete =>
      'Bare noen av resultatene vises. Vis flere eller avgrens søket.';

  @override
  String get workspaceSearchShowMore => 'Vis flere resultater';

  @override
  String get workspaceSearchSkippedFiles =>
      'Søket er ufullstendig. Disse filene er større enn 1 MiB eller kunne ikke leses:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Stor fil: utheving og folding er satt på pause';

  @override
  String get nothingToRead => 'Ingenting å lese';

  @override
  String get admonition => 'Merknadsblokk';

  @override
  String get quote => 'Sitat';

  @override
  String get note => 'Merknad';

  @override
  String get tip => 'Tips';

  @override
  String get warning => 'Advarsel';

  @override
  String get tabs => 'Faner';

  @override
  String get tab => 'Fane';

  @override
  String get procedure => 'Prosedyre';

  @override
  String get step => 'Trinn';

  @override
  String get topic => 'Emne';

  @override
  String get chapter => 'Kapittel';

  @override
  String couldNotOpenTarget(String target) {
    return 'Kunne ikke åpne $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Fant ikke lenkemål: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Kan ikke åpne denne filtypen i redigereren';

  @override
  String anchorNotFound(String anchor) {
    return 'Fant ikke anker: $anchor';
  }

  @override
  String get noProblemsFound => 'Ingen problemer funnet';

  @override
  String get noResults => 'Ingen resultater';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath – linje $lineNumber';
  }

  @override
  String get untitledResult => 'Resultat uten tittel';

  @override
  String get documentKindMarkdownFile => 'Markdown-fil';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown-emne';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML-emne';

  @override
  String get documentKindWritersideTree => 'Writerside-tre';

  @override
  String get documentKindConfigurationFile => 'Konfigurasjonsfil';

  @override
  String get documentKindVariablesFile => 'Variabelfil';

  @override
  String get documentKindCategoriesFile => 'Kategorifil';

  @override
  String get documentKindResourceFile => 'Ressursfil';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Kunne ikke oppdatere nylige elementer: $error.';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Åpning mislyktes: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Kunne ikke opprette Writerside-prosjekt: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Kunne ikke opprette Writerside-emne: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Kunne ikke åpne filen: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Velg hvor du vil lagre denne Markdown-filen.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Lagring blokkert: filen er endret på disken.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Lagring mislyktes: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Filoperasjonen mislyktes: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Validering mislyktes: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Gjenopprettet $count ulagrede dokumenter. Gå gjennom hvert ett før du lagrer eller forkaster det.',
      one:
          'Gjenopprettet 1 ulagret dokument. Gå gjennom det før du lagrer eller forkaster det.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count skadede gjenopprettingsposter kunne ikke gjenopprettes. Gyldige gjenopprettingsposter er fortsatt tilgjengelige.',
      one:
          'Kunne ikke gjenopprette 1 skadet gjenopprettingspost. Den opprinnelige gjenopprettingsfilen er bevart for gjennomgang.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Stien finnes ikke: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Målmappen finnes allerede og er ikke tom: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Målstien finnes allerede og er ikke en mappe: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Den genererte filen finnes allerede: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Overordnet mappe er påkrevd.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Overordnet mappe finnes ikke: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Mappen finnes ikke: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Stien finnes allerede: $path';
  }

  @override
  String get errorFileNameRequired => 'Filnavn kreves.';

  @override
  String get errorFileNameUnsafe => 'Filnavnet må være ett trygt stisegment.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Kan ikke flytte en mappe inn i seg selv.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Filoperasjonen må holde seg i arbeidsområdet.';

  @override
  String get errorFileOperationRoot =>
      'Roten til arbeidsområdet kan ikke endres fra filtreet.';

  @override
  String get errorProjectNameRequired => 'Prosjektnavn er påkrevd.';

  @override
  String get errorDirectoryNameRequired => 'Mappenavn er påkrevd.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Mappenavnet må være ett enkelt, trygt stisegment.';

  @override
  String get errorInstanceIdInvalid =>
      'Instans-ID-en må starte med en liten bokstav og bare inneholde små bokstaver, tall, understrek og bindestrek.';

  @override
  String get errorTopicFileInvalid =>
      'Emnefilnavnet må være et Markdown-filnavn uten stiskilletegn.';

  @override
  String get errorTopicTitleRequired => 'Emnetittel er påkrevd.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside-modulroten finnes ikke: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'En Writerside-modul må være åpen for å opprette et emne.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside-modulen har ikke noe instanstre.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside-trefilen finnes ikke: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Emne-ID-en «$topicId» finnes allerede i denne hjelpemodulen.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Emnefilen finnes allerede: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Referanseemnet finnes ikke i det valgte treet: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Den valgte oppføringen i innholdsfortegnelsen finnes ikke lenger.';

  @override
  String get errorWritersideTocInvalidMove =>
      'En oppføring i innholdsfortegnelsen kan ikke flyttes under seg selv eller en av sine underoppføringer.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Startsiden $topic kan ikke slettes. Velg en annen startside først.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Bruk trygg sletting for Writerside-emnefiler.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Kunne ikke fullføre søket etter emnebruk. Ingen filer ble endret.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Noen forekomster av emnet krever fortsatt oppfølging. Se gjennom dem før du fortsetter.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Det valgte målet for videresending er ikke lenger gyldig. Velg det på nytt.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Fjerningen av emnet kunne ikke angres fullstendig. Se gjennom disse banene før du fortsetter: $paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Navneendringen kan ikke oppdatere alle prosjektreferanser trygt fordi $count emnefil(er) i modulen $module ikke ble analysert: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside-prosjektfiler har ulagrede endringer. Løs dem og klargjør en ny forhåndsvisning av navneendringen.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Modulsettet i Writerside-prosjektet er endret. Klargjør en ny forhåndsvisning av navneendringen før refaktorering.';

  @override
  String get errorTopicsRootUnsafe =>
      'Emneroten må være en sikker relativ mappe.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Emnefilnavnet må være ett enkelt, trygt stisegment.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Emnefilendelsen må samsvare med det valgte formatet ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Emnefilnavnet kan bare inneholde bokstaver, tall, understrek og bindestrek.';

  @override
  String errorUnknown(String code) {
    return 'Ukjent feil: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Kunne ikke lese filmetadata: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Stort arbeidsområde oppdaget. Noen filer ble hoppet over for at appen fortsatt skal svare raskt.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Kunne ikke inspisere oppføring i arbeidsområdet: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Filen er større enn betagrensen for automatisk analyse.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Kunne ikke lese Markdown-fil: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Feil format på Writerside-attributtblokken i overskriften.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Duplisert overskrifts-ID «$id».';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Ytterligere H1-overskrifter på toppnivå behandles som kapitler.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown-emnet har ingen H1-overskrift eller front matter-tittel.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML-emnet mangler tittel.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Emnet «$fileName» mangler tittel.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Front matter er ikke lukket.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Usikkert HTML-element.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Lenkemålet finnes ikke: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Ankeret «$anchor» finnes ikke.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Bildet «$destination» mangler alternativ tekst.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Bildet finnes ikke: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Ugyldig XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg-roten må være <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets-deklarasjon mangler src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups-deklarasjon mangler src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Keymaps-modusen støttes ikke: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'instance-deklarasjon mangler src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg registrerer ingen instans.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree-roten må være <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId => 'Instansprofilen mangler id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Trefilens navn uten filendelse samsvarer ikke med instans-ID-en «$id».';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Instans som ikke er et bibliotek, mangler start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Startsiden «$startPage» finnes ikke.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Emnet «$topic» vises mer enn én gang i denne instansens innholdsfortegnelse.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Variabeldeklarasjonen må ha navn og verdi.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Variabelen «$name» er deklarert mer enn én gang.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'Kategorien mangler id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Kategorien «$id» er deklarert mer enn én gang.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Kategorirekkefølgen «$order» er deklarert mer enn én gang.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic-roten må være <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML-emnet mangler rot-ID.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Rot-ID-en «$id» i XML-emnet må samsvare med filnavnet «$expectedId».';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Element-ID-en «$elementId» vises mer enn én gang.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> mangler href-attributt.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside-modus krever writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Konfigurert mappe for byggekonfigurasjon mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Konfigurert mappe for API-spesifikasjoner mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Konfigurert snippets-mappe mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Konfigurert variabelfil mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Konfigurert kategorifil mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Konfigurert instance-groups-fil mangler: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Det registrerte instanstreet «$source» finnes ikke.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Kunne ikke lese emnefilen: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Standard emnemappe mangler: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Konfigurert emnemappe mangler: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Konfigurert bildemappe mangler: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Element-ID-en «$id» vises mer enn én gang.';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Instansen \"$instanceId\" publiserer det ugyldige nettfilnavnet \"$webFileName\" for emnet \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Instansen \"$instanceId\" publiserer både \"$firstTopic\" og \"$secondTopic\" som \"$webFileName\".';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Innholdsfortegnelsen refererer til et manglende emne: «$topic».';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Ekstern href «$href» er ugyldig.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Variabelen «%$name%» er ikke deklarert.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Emnelenken «$destination» kan ikke løses.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Ankeret «$anchor» finnes ikke i «$targetName».';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> mangler from-attributt.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Include-kilden «$from» finnes ikke.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Include-elementet «$elementId» finnes ikke i «$from».';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso-kategorien «$ref» er ikke deklarert.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Emnereferansen «$reference» er tvetydig.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Ukjent diagnostikkmelding: $code';
  }

  @override
  String get close => 'Lukk';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git-diff';

  @override
  String get gitShowDiff => 'Vis diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'gammel $oldRange → ny $newRange';
  }

  @override
  String get gitDiffNoLines => 'ingen linjer';

  @override
  String get gitUnavailableTitle => 'Git er ikke tilgjengelig';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Installer Git, eller konfigurer BusyMark til å bruke en tilgjengelig Git-programfil. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Vil du stole på dette arbeidsområdet for Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Git-repositorier kan kjøre programmer via hooks, filtre og annen konfigurasjon. Stol på dette arbeidsområdet før BusyMark leser repositoriedata eller aktiverer Git-handlinger.';

  @override
  String get gitTrustWorkspace => 'Stol på arbeidsområdet';

  @override
  String get gitNotRepositoryTitle => 'Ikke et Git-repositorium';

  @override
  String get gitNotRepositoryMessage =>
      'Dette arbeidsområdet er ikke i et Git-repositorium.';

  @override
  String get gitInitializeRepository => 'Initialiser repositorium';

  @override
  String get gitDetachedHead => 'Frakoblet HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Frakoblet ved $commit';
  }

  @override
  String get gitNoUpstream => 'Ingen upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits som ikke er pushet',
      one: '1 commit som ikke er pushet',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits å hente',
      one: '1 commit å hente',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Ren';

  @override
  String get gitConflicts => 'Konflikter';

  @override
  String get gitChanges => 'Endringer';

  @override
  String get gitStaged => 'Indeksert';

  @override
  String get gitUnstaged => 'Ikke indeksert';

  @override
  String get gitHistory => 'Historikk';

  @override
  String get gitBranches => 'Grener';

  @override
  String get gitActions => 'Git-handlinger';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Hent';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Legg fil i indeksen';

  @override
  String get gitRemoveFromCommit => 'Fjern fil fra indeksen';

  @override
  String get gitDiscard => 'Forkast';

  @override
  String get gitOpenFile => 'Åpne fil';

  @override
  String get gitMarkResolved => 'Merk som løst';

  @override
  String get gitUntracked => 'Usporede filer';

  @override
  String get gitCommitMessage => 'Commit-melding';

  @override
  String get gitCommitSelectedFiles => 'Valgte filer';

  @override
  String get gitCommitNoSelectedFiles =>
      'Legg minst én fil i indeksen før du oppretter en commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indekserte filer',
      one: '1 indeksert fil',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Utenfor arbeidsområdet';

  @override
  String get gitCommitMessageRequired => 'Skriv inn en commit-melding.';

  @override
  String get gitCreateBranch => 'Opprett gren';

  @override
  String get gitNewBranch => 'Ny gren';

  @override
  String get gitBranchName => 'Grennavn';

  @override
  String get gitSwitchBranch => 'Bytt';

  @override
  String get gitNoChanges => 'Ingen endringer';

  @override
  String get gitNoHistory => 'Ingen historikk';

  @override
  String get gitNoBranches => 'Ingen grener';

  @override
  String get gitNoDiff => 'Ingen diff å vise';

  @override
  String get gitBinaryFile => 'Binærfil. BusyMark viser ikke binære patcher.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Binærfil ($size byte). BusyMark viser ikke binære patcher.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Ulagrede endringer i redigereren tas ikke med før de er lagret.';

  @override
  String get gitConfirmDiscardTitle => 'Forkaste Git-endringer?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle indekserte og ikke-indekserte endringer i de valgte sporede filene vil bli gjenopprettet til HEAD.',
      one:
          'Alle indekserte og ikke-indekserte endringer i den valgte sporede filen vil bli gjenopprettet til HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'De valgte usporede filene slettes.',
      one: 'Den valgte usporede filen slettes.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De valgte filene gjenopprettes eller slettes ut fra Git-statusen.',
      one: 'Den valgte filen gjenopprettes eller slettes ut fra Git-statusen.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Bytt til $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark laster arbeidsområdet på nytt fra disken etter at Git har byttet gren.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Angi upstream-gren?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Denne grenen har ingen upstream. BusyMark kan pushe $branch og angi upstream når nøyaktig én remote er konfigurert.';
  }

  @override
  String get gitProjectHistory => 'Prosjekthistorie';

  @override
  String get gitFileHistory => 'Filhistorie';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Filhistorikk krever en åpen Markdown-fil.';

  @override
  String get gitLoadMore => 'Last inn flere';

  @override
  String get gitChangesInCommit => 'Endringer i denne innsjekkingen';

  @override
  String get gitCompareWithCurrent => 'Sammenlign med gjeldende versjon';

  @override
  String get gitRestoreVersion => 'Gjenopprett denne versjonen';

  @override
  String get gitConfirmRestoreTitle => 'Gjenopprette denne filversjonen?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark erstatter den gjeldende filen i arbeidstreet med den valgte innsjekkede versjonen. Den gjenopprettede filen forblir uindeksert.';

  @override
  String get gitCommitActions => 'Handlinger for innsjekking';

  @override
  String get gitResetCurrentBranchToHere => 'Tilbakestill gjeldende gren hit…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Tilbakestille $branch til $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Dette flytter grenen $branch til innsjekkingen $commit. Velg hvordan Git skal oppdatere indeksen og arbeidstreet.';
  }

  @override
  String get gitReset => 'Tilbakestill';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Flytt bare grenen. Behold indeksen og arbeidstreet uendret; forskjeller fra den valgte innsjekkingen forblir indeksert.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Flytt grenen og tilbakestill indeksen. Behold arbeidstreet uendret, slik at forskjellene blir uindekserte.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Flytt grenen og tilbakestill indeksen og arbeidstreet. Sporede endringer forkastes; usporede filer som blokkerer operasjonen, kan bli slettet.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Flytt grenen og tilbakestill sporede filer, men behold lokale endringer. Git avbryter hvis endringene kommer i konflikt med tilbakestillingen.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Filhandlinger';

  @override
  String get actions => 'Handlinger';

  @override
  String get gitStatusAdded => 'Lagt til';

  @override
  String get gitStatusDeleted => 'Slettet';

  @override
  String get gitStatusRenamed => 'Gitt nytt navn';

  @override
  String get gitStatusCopied => 'Kopiert';

  @override
  String get gitStatusUntracked => 'Usporet';

  @override
  String get gitStatusConflicted => 'I konflikt';

  @override
  String get gitStatusIgnored => 'Ignorert';

  @override
  String get gitStatusTypeChanged => 'Type endret';

  @override
  String get gitStatusModified => 'Endret';

  @override
  String get gitStatusUnknown => 'Ukjent';

  @override
  String get gitErrorUnavailable => 'Git er ikke tilgjengelig.';

  @override
  String get gitErrorNotRepository =>
      'Dette arbeidsområdet er ikke et Git-repositorium.';

  @override
  String get gitErrorUnsafePath => 'BusyMark blokkerte en usikker Git-sti.';

  @override
  String get gitErrorInvalidBranchName => 'Skriv inn et gyldig grennavn.';

  @override
  String get gitErrorNoRemote => 'Ingen Git-remote er konfigurert.';

  @override
  String get gitErrorNoUpstream => 'Ingen upstream-gren er konfigurert.';

  @override
  String get gitErrorMultipleRemotes =>
      'Flere remoter er konfigurert. Velg en upstream utenfor denne versjonen av BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Lagre eller forkast endringene i BusyMark-redigereren før du bytter gren.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Lagre eller forkast endringer i BusyMark-redigereren før du tilbakestiller gjeldende gren.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Fjern filen fra indeksen før du gjenoppretter en tidligere versjon.';

  @override
  String get gitErrorResetDetachedHead =>
      'Bytt til en gren før du tilbakestiller den.';

  @override
  String get gitErrorDiverged =>
      'Grenen har divergert. Løs merge eller rebase utenfor denne versjonen av BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git trenger forfatternavn og e-postadresse før endringer kan lagres.';

  @override
  String get gitAuthorIdentityTitle => 'Git-forfatteridentitet';

  @override
  String get gitAuthorIdentityMessage =>
      'Skriv inn identiteten Git skal registrere på endringer. BusyMark lagrer den og prøver denne endringen på nytt.';

  @override
  String get gitAuthorName => 'Navn';

  @override
  String get gitAuthorEmail => 'E-post';

  @override
  String get gitAuthorIdentityGlobal => 'Bruk for alle kodelagre';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Når appen er installert som en Snap, gjelder dette kodelagre som åpnes i BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Lagre og utfør commit';

  @override
  String get gitErrorAuthentication => 'Git-autentisering mislyktes.';

  @override
  String get gitErrorNetwork => 'Git-nettverksoperasjonen mislyktes.';

  @override
  String get gitErrorConflict => 'Git rapporterte uløste konflikter.';

  @override
  String get gitErrorCommandFailed => 'Git-kommandoen mislyktes.';

  @override
  String get syntaxReference => 'Syntaksreferanse';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown-blokker';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Blokkstrukturer som støttes i Markdown-kilde og forhåndsvisning.';

  @override
  String get syntaxReferenceInlineFormatting => 'Inline-Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatering i avsnitt, listeelementer og tabellceller.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Rå HTML-blokker';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Trygge HTML-blokktagger rendres med BusyMark-forhåndsvisning.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Rå HTML-inline-tagger';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Trygge inline-HTML-tagger rendres uten å vise taggene bokstavelig.';

  @override
  String get syntaxReferenceHeadings => 'Overskrifter';

  @override
  String get syntaxReferenceParagraphs => 'Avsnitt';

  @override
  String get syntaxReferenceLists => 'Lister';

  @override
  String get syntaxReferenceHtmlContainers => 'Beholdere';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Tekstblokker';

  @override
  String get syntaxReferenceHtmlFigures => 'Figurer og bilder';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Forhåndsformatert kode';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Utvidbare blokker';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Beskrivelseslister';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Formateringstagger';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Inline-kodetagger';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Semantiske teksttagger';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'Tillatt HTML konverteres til BusyMark-forhåndsvisningsblokker og rendres ikke i en nettleser.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Uendret rå HTML lagres nøyaktig som kildetekst.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Markdown-markører inni rå HTML vises som bokstavelig tekst.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Skript, stiler, rammer, skjemaer, SVG, MathML, hendelser og usikre attributter blokkeres.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Lenker tillater http, https, mailto, tel, relative URL-er og fragmenter; usikre URI-skjemaer blokkeres.';

  @override
  String get syntaxReferenceCategory => 'Kategori';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagrammer og API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matematikk';

  @override
  String get syntaxReferenceExample => 'Eksempel';

  @override
  String get syntaxReferenceIdentifiers => 'Identifikatorer og aliaser';

  @override
  String get syntaxReferenceScope => 'Omfang';

  @override
  String get syntaxReferenceLimitation => 'BusyMark-begrensning';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Offisiell dokumentasjon';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Bare Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Bare Writerside Markdown og Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'De viktigste Markdown-formene BusyMark kan skrive og forhåndsvise.';

  @override
  String get syntaxReferenceParagraphExample => 'Et tekstavsnitt.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabeller bruker pipe-syntaksen fra GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'to mellomrom på slutten av linjen, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark godtar et avgrenset, trygt delsett av rå HTML i Markdown-kilden.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Inngjerdede Mermaid-, PlantUML-, D2- og OpenAPI-blokker fungerer i Markdown-kilde. Blokkidentifikatorer skiller ikke mellom store og små bokstaver, og BusyMark bevarer den opprinnelige skrivemåten.';

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
      'Bruk inngjerdet YAML- eller JSON-innhold. BusyMark behandler ikke et vilkårlig helt YAML- eller JSON-dokument som en OpenAPI-referanse.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Semantiske kodeblokker for diagrammer';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Semantiske code-block- og src-former støtter Mermaid, PlantUML og D2, ikke OpenAPI, og bare i Writerside-prosjekter.';

  @override
  String get syntaxReferenceReferencedDiagramSource => 'Referert diagramkilde';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Stier må være relative og forbli i det åpne Writerside-prosjektet; inngjerdet form med src gjelder bare Writerside Markdown.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark støtter TeX-uttrykk, ikke komplette TeX- eller LaTeX-dokumenter.';

  @override
  String get syntaxReferenceInlineMath => 'Matematikk i linjen';

  @override
  String get syntaxReferenceGithubMath =>
      'GitHub-matematikk med dollartegn og grav aksent';

  @override
  String get syntaxReferenceDisplayMath => 'Matematikk som blokk';

  @override
  String get syntaxReferenceMathFence => 'math-blokk';

  @override
  String get syntaxReferenceTexFence => 'tex-blokk';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark gjenkjenner ikke \\(...\\) eller \\[...\\] som matematikkskilletegn i Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Utenfor Writerside-modus forblir en tex-blokk en vanlig kodeblokk.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside-math-element';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math-elementet er semantisk Writerside-syntaks, ikke tillatt rå HTML MathML.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Semantisk TeX-kodeblokk';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Disse målrettede utvidelsene tolkes bare i åpne Writerside-prosjekter.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Merknadssitat';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Et vanlig blokksitat er et tips i Writerside Markdown; i vanlig Markdown forblir det et ordinært sitat.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Semantiske merknader';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Vanlig Markdown tolker ikke disse semantiske Writerside-elementene.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Sammenleggbar overskrift';

  @override
  String get syntaxReferenceCollapsibleCode => 'Sammenleggbar kodeblokk';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Semantisk sammenleggbart innhold';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark støtter sammenleggbare chapter-, procedure-, code-block- og definisjonslisteformer, ikke hele Writerside-katalogen.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Semantiske kodeblokker for matematikk og diagrammer';

  @override
  String get syntaxReferenceVideo => 'Writerside-video';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Lokal video bruker et lokalt preview-src-bilde; vertsbaserte kilder må være støttede HTTPS-adresser fra YouTube eller Vimeo.';

  @override
  String get exportAsPdf => 'Eksporter som PDF';

  @override
  String get pdfExportDescription =>
      'Velg sideoppsett for en gjennomarbeidet, selvstendig PDF.';

  @override
  String get pdfRemoteImagesNote =>
      'Eksterne bilder lastes ikke ned under eksport. Lokale bilder tas med når de er tilgjengelige.';

  @override
  String get pdfPageSize => 'Sidestørrelse';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'US Letter';

  @override
  String get pdfOrientation => 'Retning';

  @override
  String get pdfPortrait => 'Stående';

  @override
  String get pdfLandscape => 'Liggende';

  @override
  String get pdfMargins => 'Marger';

  @override
  String get pdfMarginNarrow => 'Smale';

  @override
  String get pdfMarginNormal => 'Normale';

  @override
  String get pdfMarginWide => 'Brede';

  @override
  String get pdfIncludePageNumbers => 'Ta med sidetall';

  @override
  String get export => 'Eksporter';

  @override
  String get exportFormat => 'Utdataformat';

  @override
  String get exportingPdf => 'Eksporterer PDF…';

  @override
  String get fileTypePdf => 'PDF-dokument';

  @override
  String pdfExported(String fileName) {
    return '$fileName ble eksportert.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count advarsler',
      one: '1 advarsel',
    );
    return '$fileName ble eksportert med $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF-eksportkomponenten mangler. Installer BusyMark på nytt og prøv igjen.';

  @override
  String get pdfExportTimedOut =>
      'PDF-eksporten tok for lang tid og ble stoppet.';

  @override
  String get pdfExportFailed =>
      'BusyMark kunne ikke eksportere dette dokumentet som PDF.';

  @override
  String get visualizationRendering => 'Gjengir…';

  @override
  String get visualizationStale => 'Viser siste gyldige gjengivelse';

  @override
  String get visualizationShowSource => 'Vis kilde';

  @override
  String get visualizationShowRender => 'Vis gjengivelse';

  @override
  String get visualizationFitWidth => 'Tilpass til bredden';

  @override
  String get visualizationSaveImage => 'Lagre bilde';

  @override
  String get visualizationCopyImage => 'Kopier bilde';

  @override
  String get visualizationImageCopied => 'Bildet er kopiert';

  @override
  String get visualizationOpenApiReference => 'Åpne API-referanse';

  @override
  String get visualizationValid => 'Gyldig';

  @override
  String get visualizationInvalid => 'Ugyldig';

  @override
  String get visualizationServers => 'Servere';

  @override
  String get visualizationPaths => 'Baner';

  @override
  String get visualizationOperations => 'Operasjoner';

  @override
  String get visualizationTags => 'Tagger';

  @override
  String get visualizationNoOperations => 'Ingen samsvarende operasjoner';

  @override
  String get visualizationSearchOperations => 'Søk i operasjoner';

  @override
  String get visualizationRenderFailed =>
      'Denne visualiseringen kunne ikke gjengis.';

  @override
  String get visualizationRetry => 'Prøv igjen';

  @override
  String visualizationSaved(String fileName) {
    return 'Lagret $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Eksporter det aktive dokumentet eller Writerside-modulen som PDF.';

  @override
  String get instances => 'Instanser';

  @override
  String get newInstance => 'Ny instans';

  @override
  String get newTocLibrary => 'Nytt innholdsfortegnelsesbibliotek';

  @override
  String get editInstance => 'Rediger instans';

  @override
  String get openTocFile => 'Åpne innholdsfortegnelsesfil';

  @override
  String get createInstance => 'Opprett instans';

  @override
  String get createTocLibrary => 'Opprett innholdsfortegnelsesbibliotek';

  @override
  String get instanceContent => 'Innhold';

  @override
  String get instanceContentSource => 'Opprett fra';

  @override
  String get emptyInstance => 'Tom instans';

  @override
  String get markdownFiles => 'Lokale Markdown-filer';

  @override
  String get chooseMarkdownFolder => 'Velg Markdown-mappe';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Velg en mappe som inneholder Markdown-filer.';

  @override
  String get instanceAppearance => 'Utseende';

  @override
  String get instanceColor => 'Ikonfarge';

  @override
  String get instanceVersion => 'Versjon';

  @override
  String instanceVersionInherited(String version) {
    return 'Når dette feltet er tomt, brukes prosjektversjonen $version.';
  }

  @override
  String get instanceWebPath => 'Nettsti';

  @override
  String get instanceStatus => 'Status';

  @override
  String get instanceStatusRelease => 'Utgivelse';

  @override
  String get instanceStatusEap => 'Tidlig tilgang';

  @override
  String get instanceStatusDeprecated => 'Foreldet';

  @override
  String get allowSearchEngineIndexing => 'Tillat indeksering i søkemotorer';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Tillat eksterne søkemotorer å indeksere denne utdataen.';

  @override
  String get offlineArtifact => 'Frakoblet artefakt';

  @override
  String get offlineArtifactDescription =>
      'Pakk ressursene slik at den bygde dokumentasjonen er selvstendig.';

  @override
  String get instanceOutputSettings => 'Utdatainnstillinger';

  @override
  String get markdownImportSource => 'Markdown-kilde';

  @override
  String get markdownImportFiles => 'Markdown-filer';

  @override
  String get selectNone => 'Velg ingen';

  @override
  String markdownFilesFound(int count) {
    return 'Fant $count Markdown-fil(er)';
  }

  @override
  String get noMarkdownFilesFound =>
      'Ingen Markdown-filer ble funnet i denne mappen.';

  @override
  String get copyReferencedMedia => 'Kopier refererte medier';

  @override
  String get copyReferencedMediaDescription =>
      'Kopier lokale bilder og videoer som de valgte filene refererer til, og behold relative stier.';

  @override
  String get instanceIdRenameWarningTitle => 'Gi instans-ID-en nytt navn?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark gir .tree-filen nytt navn og oppdaterer Writerside-prosjektreferanser fra «$oldId» til «$newId». Publiseringsskript endres ikke og må oppdateres separat.';
  }

  @override
  String get renameAndUpdateReferences => 'Gi nytt navn og oppdater referanser';

  @override
  String get tocLibraryDescription =>
      'Et innholdsfortegnelsesbibliotek lagrer gjenbrukbare deler og produserer ikke egne utdata.';

  @override
  String get defaultTocLibraryName => 'Delt innholdsfortegnelse';

  @override
  String get instanceColorAutomatic => 'Automatisk';

  @override
  String get instanceColorBlue => 'Blå';

  @override
  String get instanceColorGreen => 'Grønn';

  @override
  String get instanceColorOrange => 'Oransje';

  @override
  String get instanceColorPurple => 'Lilla';

  @override
  String get instanceColorRed => 'Rød';

  @override
  String get instanceColorTeal => 'Blågrønn';

  @override
  String get instanceColorYellow => 'Gul';

  @override
  String get errorWritersideInstanceNameRequired => 'Skriv inn et instansnavn.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Det finnes allerede en instans med ID-en «$id».';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Instanstreet finnes allerede: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown-kildemappen finnes ikke: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Velg minst én Markdown-fil som skal importeres.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Dette er ikke en lesbar Markdown-fil i den valgte kilden: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Importen ville overskrevet en eksisterende prosjektfil: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Instansfilene er endret på disken. Se gjennom dem og prøv igjen.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark kunne ikke angre hele instansendringen. Se gjennom disse filene før du fortsetter: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Et innholdsfortegnelsesbibliotek kan ikke importere Markdown-emner.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Nettstien må være på én linje.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside-instanskonfigurasjonen er ugyldig. Rett diagnostikken og prøv igjen.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark kunne ikke klargjøre instansendringene på en trygg måte.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Ukjent instansstatus «$status». Bruk release, eap eller deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'Instans-ID-en «$id» brukes av mer enn én tre-fil.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml må ha et <buildprofiles>-rotelement.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Verdien $name «$value» må være true eller false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Et <build-profile>-element må angi en instans-ID.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'En <include> i treet må angi både from og element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'En <snippet> i treet må angi en id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'En innholdsfortegnelsesreferanse mellom instanser må angi både ref og in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Et innholdsfortegnelseselement kan ikke peke til mer enn ett emne, én referanse, én lenke eller én omadressering.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Treelement-ID-en «$id» er deklarert mer enn én gang.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Instansgruppefilen må ha et <instance-groups>-rotelement.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'En instansgruppe må angi en ikke-tom id og instansliste.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Instansgruppe-ID-en «$id» er deklarert mer enn én gang.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Innholdsfortegnelsesinkluderingen «$source#$id» tilhører den eksterne modulen «$origin» og kan ikke utvides i dette arbeidsområdet.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Treelementet «$id» finnes ikke i det registrerte treet «$source».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Treinkluderingen «$source#$id» oppretter en syklus.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Instansbetingelsen refererer til den ukjente gruppen «@$group».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Referansen mellom instanser peker til den ukjente instansen «$instance».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Emnet «$topic» finnes ikke i den refererte instansen «$instance».';
  }

  @override
  String get download => 'Last ned';

  @override
  String get exportWritersideAsPdf => 'Eksporter Writerside som PDF';

  @override
  String get writersidePdfContent => 'Eksportinnhold';

  @override
  String get writersidePdfPage => 'Side';

  @override
  String get exportingWritersidePdf => 'Eksporterer Writerside-PDF…';

  @override
  String get ai => 'KI';

  @override
  String get aiLocalOllama => 'Lokal Ollama';

  @override
  String get aiDisabled => 'Deaktivert';

  @override
  String get aiExplicitEditingDescription =>
      'KI-redigering startes bare eksplisitt. BusyMark sender kun den viste konteksten til den valgte leverandøren og bruker aldri et forslag uten gjennomgang.';

  @override
  String get aiProvider => 'KI-leverandør';

  @override
  String get aiDefaultProvider => 'Standardleverandør';

  @override
  String get aiConfigureProvider => 'Konfigurer leverandør';

  @override
  String get aiChooseProvider => 'Velg KI-leverandør';

  @override
  String get aiOllamaEndpoint => 'Ollama-endepunkt';

  @override
  String get aiOllamaModel => 'Ollama-modell';

  @override
  String get aiTestConnection => 'Test tilkobling';

  @override
  String get aiTestingConnection => 'Tester…';

  @override
  String aiConnectionReady(int count) {
    return 'Tilkoblet. Fant $count installert(e) modell(er).';
  }

  @override
  String get aiNoModels => 'Ingen modell er valgt.';

  @override
  String get aiConnectionFailed =>
      'BusyMark kunne ikke bekrefte KI-tekstgenerering.';

  @override
  String get aiConfigureFirst =>
      'Aktiver en KI-leverandør og bekreft en modell under Innstillinger → KI.';

  @override
  String get aiEditWithAi => 'Rediger med KI';

  @override
  String get aiRefineWithAi => 'Forbedre med KI';

  @override
  String get aiInstruction => 'Instruksjon';

  @override
  String get aiChangeTarget => 'Hva som kan endres';

  @override
  String get aiSharedContext => 'Kontekst som deles med KI';

  @override
  String get aiTargetSelection => 'Markert innhold';

  @override
  String get aiTargetInsertAfterBlock => 'Sett inn etter gjeldende blokk';

  @override
  String get aiTargetCurrentBlock => 'Gjeldende blokk';

  @override
  String get aiTargetCurrentSection => 'Gjeldende del';

  @override
  String get aiTargetCompleteDocument => 'Hele dokumentet';

  @override
  String get aiContextNone => 'Ingen dokumentkontekst';

  @override
  String get aiContextSelection => 'Markert innhold';

  @override
  String get aiContextCurrentBlock => 'Gjeldende blokk';

  @override
  String get aiContextCurrentSection => 'Gjeldende del';

  @override
  String get aiContextCompleteDocument => 'Hele dokumentet';

  @override
  String get aiGenerating => 'Genererer forslag…';

  @override
  String get aiProposal => 'KI-forslag';

  @override
  String get aiGenerateProposal => 'Generer forslag';

  @override
  String aiContextDisclosure(int count) {
    return 'Den valgte leverandøren mottar $count tegn fra den viste konteksten.';
  }

  @override
  String get aiOriginal => 'Opprinnelig tekst';

  @override
  String get aiSuggested => 'Forslag';

  @override
  String get aiApplyProposal => 'Bruk forslag';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input inndatatokener · $output utdatatokener';
  }

  @override
  String get aiStaleProposal =>
      'Dokumentet ble endret mens forslaget ble generert. Kjør handlingen på nytt.';

  @override
  String get gitAiStagedChangesChanged =>
      'De indekserte endringene ble endret mens denne commit-meldingen ble generert. Kjør handlingen på nytt.';

  @override
  String get aiViewContext => 'Vis sendt kontekst';

  @override
  String get aiReviewExactContent => 'Se gjennom nøyaktig innhold';

  @override
  String get aiContentToChange => 'Innhold som skal endres';

  @override
  String get aiContentSentToAi => 'Innhold sendt til KI';

  @override
  String get aiApiKey => 'API-nøkkel';

  @override
  String get aiApiKeyStoredHint =>
      'En nøkkel er lagret i systemets legitimasjonslager';

  @override
  String get aiApiKeyEnterHint => 'Skriv inn en API-nøkkel for leverandøren';

  @override
  String get aiReplaceApiKey => 'Erstatt API-nøkkel';

  @override
  String get aiSaveApiKey => 'Lagre API-nøkkel sikkert';

  @override
  String get aiRemoveApiKey => 'Fjern lagret API-nøkkel';

  @override
  String get aiCredentialSaved =>
      'API-nøkkelen ble lagret i systemets legitimasjonslager.';

  @override
  String get aiCredentialRemoved => 'Den lagrede API-nøkkelen ble fjernet.';

  @override
  String get aiModelRouting => 'Modellvalg';

  @override
  String get aiAutomaticRouting => 'Automatisk etter oppgave';

  @override
  String get aiFixedModelRouting => 'Bruk valgt modell';

  @override
  String get aiPreferredModel => 'Foretrukket modell';

  @override
  String get aiModel => 'Modell';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests forespørsler · $input inndata-tokener · $output utdata-tokener';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Sende innhold til $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Aktiver $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Bare innholdet som vises i hver KI-gjennomgangsdialog, sendes. Forespørsler er tilstandsløse, forslag krever gjennomgang, og API-nøkkelen lagres i legitimasjonslageret til Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Bekreft først datadeling med $provider under Innstillinger → KI.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Generering bekreftet med $model. $count kompatible modeller er tilgjengelige.';
  }

  @override
  String get aiColdStartObserved =>
      'En kaldstart av den lokale modellen ble oppdaget.';

  @override
  String get aiNoCompatibleModels =>
      'Ingen kompatibel tekstgenereringsmodell er tilgjengelig.';

  @override
  String get aiEnableProvider => 'Aktiver en KI-leverandør først.';

  @override
  String get aiDraftCommitMessage => 'Lag utkast til commit-melding';

  @override
  String get aiDrafting => 'Lager utkast…';

  @override
  String get aiDraftWithAi => 'Lag utkast med KI';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Overskrift på nivå $level følger nivå $previousLevel; kontroller seksjonsnestingen.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Lenketeksten er tom. Oppgi et tilgjengelig navn som beskriver formålet.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Kontroller om lenketeksten «$text» beskriver formålet i konteksten.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Tabelloverskrifter må identifisere kolonnene. Fyll ut alle tomme overskrifter.';

  @override
  String get mathRenderFailed =>
      'Det matematiske uttrykket kunne ikke gjengis.';

  @override
  String get inlineMath => 'Integrert matematikk';

  @override
  String get displayMath => 'Matematikkblokk';

  @override
  String get goToDeclaration => 'Gå til deklarasjon';

  @override
  String get findUsages => 'Finn bruk';

  @override
  String get cannotRenameSymbol =>
      'Symbolet kan ikke gis nytt navn trygt. Kontroller navnet og oppdater referansen før du prøver igjen.';

  @override
  String get renameTopicFileInstead =>
      'Emne-ID-er kommer fra filnavnene. Bruk Gi nytt navn til emnefil i innholdsfortegnelsen eller sidepanelet Filer.';

  @override
  String get keyboardLayout => 'Tastaturoppsett';

  @override
  String get diagnosticWritersideUnsupported =>
      'Innhold som ikke støttes eller er feilformet, vises som kildekode.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Kan ikke løse kilden «$reference»: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Lenkemålet er ikke tilgjengelig i denne instansen: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Ugyldig Writerside-markering: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Bruk <llms-txt>true</llms-txt> eller <llms-txt>false</llms-txt>; single-file støttes ikke lenger.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Kan ikke løse $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Eksporter som HTML…';

  @override
  String get fileTypeHtml => 'HTML-dokument';

  @override
  String get exportingHtml => 'Eksporterer HTML…';

  @override
  String get htmlExported => 'HTML-eksport fullført';

  @override
  String get htmlExportFailed => 'HTML-eksport mislyktes';

  @override
  String get htmlKeepAssetsTogether =>
      'Hold HTML-filen og den tilhørende ressursmappen sammen når du kopierer eksporten.';

  @override
  String get htmlInstanceDescription =>
      'Eksporter én instans som lenkede frakoblede sider. Velg et navn for en egen utdatamappe.';

  @override
  String get htmlInstance => 'Instans';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Bare en mappe opprettet av BusyMarks HTML-eksport kan erstattes. Endrede eller uvedkommende filer beholdes.';

  @override
  String get showInFolder => 'Vis i mappe';

  @override
  String sortTableColumn(String column) {
    return 'Sorter $column';
  }

  @override
  String get exportReset => 'Tilbakestill til standard';

  @override
  String get exportToc => 'Ta med innholdsfortegnelse';

  @override
  String get exportTocDepth => 'Dybde på innholdsfortegnelse';

  @override
  String get exportNumberHeadings => 'Nummerer overskrifter';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Egendefinert';

  @override
  String get exportPageWidth => 'Sidebredde (mm)';

  @override
  String get exportPageHeight => 'Sidehøyde (mm)';

  @override
  String get exportMarginTop => 'Toppmarg (mm)';

  @override
  String get exportMarginRight => 'Høyremarg (mm)';

  @override
  String get exportMarginBottom => 'Bunnmarg (mm)';

  @override
  String get exportMarginLeft => 'Venstremarg (mm)';

  @override
  String get exportTypography => 'Typografi';

  @override
  String get exportSans => 'Uten seriffer';

  @override
  String get exportSerif => 'Med seriffer';

  @override
  String get exportBodySize => 'Tekststørrelse';

  @override
  String get exportCodeSize => 'Kodestørrelse';

  @override
  String get exportRunningText => 'Topp- og bunntekst';

  @override
  String get exportHeader => 'Topptekst';

  @override
  String get exportFooter => 'Bunntekst';

  @override
  String get exportNone => 'Ingen';

  @override
  String get exportDocumentTitle => 'Dokumenttittel';

  @override
  String get exportBottomLeft => 'Nederst til venstre';

  @override
  String get exportBottomCenter => 'Nederst i midten';

  @override
  String get exportBottomRight => 'Nederst til høyre';

  @override
  String get exportFirstPage => 'Vis topp- og bunntekst på første side';

  @override
  String get exportAccent => 'Aksent-/lenkefarge';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Automatisk';

  @override
  String get exportLayout => 'Oppsett';

  @override
  String get exportContentWidth => 'Maksimal innholdsbredde';

  @override
  String get exportOutput => 'Utdata';

  @override
  String get exportPackaging => 'Pakking';

  @override
  String get exportSingleFile => 'Én HTML-fil';

  @override
  String get exportAssetsDirectory => 'HTML + ressursmappe';

  @override
  String get exportCustomCss => 'Egendefinert stilark…';

  @override
  String get exportRemoveCss => 'Fjern egendefinert stilark';

  @override
  String get exportCssNote =>
      'Velg en valgfri UTF-8-CSS-fil (opptil 256 KiB). Importer, ressurs-URL-er og kjørbar eller escaped CSS avvises. Stilene følger BusyMarks stilark. Eksterne ressurser hentes aldri.';

  @override
  String get exportSitePackagingNote =>
      'Writerside beholder separate, lenkede emnesider. Enkeltfilmodus bygger ressursene inn i hver side.';

  @override
  String get exportInvalidGeometry =>
      'La minst 20 mm innholdsbredde og -høyde stå igjen etter margene.';

  @override
  String get exportInvalidColor => 'Skriv inn en farge som #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Velg en lesbar UTF-8 .css-fil opptil 256 KiB uten importer, ressurs-URL-er, HTML eller kjørbar eller escaped CSS.';

  @override
  String get clipboardHistory => 'Utklippshistorie';

  @override
  String get clipboardHistoryDescription =>
      'Åpne historien for utklippet som er lokal for sesjonen.';

  @override
  String get clipboardCurrent => 'Nåværende utklipp';

  @override
  String get clipboardCurrentExternal =>
      'Nåværende utklipp fra en annen applikasjon';

  @override
  String clipboardDestination(String name) {
    return 'Lim inn i $name';
  }

  @override
  String get clipboardSessionOnly => 'Lagret kun for denne BusyMark-sesjonen.';

  @override
  String get clipboardNoItems => 'Utklippshistorien er tom.';

  @override
  String get clipboardDisabled =>
      'Samlingen \"Utklippshistorie\" er deaktivert i Innstillinger.';

  @override
  String get clipboardUnavailable =>
      'Innholdet i det nåværende utklippet er ikke tilgjengelig eller støttet.';

  @override
  String get clipboardTooLarge =>
      'Denne utklippsteksten er for stor til å lagre.';

  @override
  String get clipboardPastePlainText => 'Lim inn som ren tekst';

  @override
  String get clipboardClearAll => 'Tøm utklippshistorie';

  @override
  String get clipboardEntryText => 'Tekst';

  @override
  String get clipboardEntryRichText => 'Rik tekst';

  @override
  String get clipboardEntryImage => 'Bilde';

  @override
  String clipboardOrigin(String name) {
    return 'Kopiert fra $name';
  }

  @override
  String get localHistory => 'Lokal historie';

  @override
  String get localHistoryEllipsis => 'Lokal historie…';

  @override
  String get localHistoryDescription =>
      'Vis lagrede og automatiserte lokale versjoner for det nåværende dokumentet.';

  @override
  String get findLocalHistoryEllipsis => 'Finn i Lokal Historikk…';

  @override
  String get findLocalHistoryDescription =>
      'Søk etter dokumenter og innhold i Lokal Historikk.';

  @override
  String get localHistoryNoDocuments =>
      'Ingen dokumenter har Lokal Historikk ennå.';

  @override
  String get localHistoryNoRevisions =>
      'Dette dokumentet har ingen revisjoner i Lokal Historikk.';

  @override
  String get localHistorySelectedRevision => 'Valgt revisjon';

  @override
  String get localHistoryCurrentEditor => 'Nåværende innhold i redigereren';

  @override
  String get localHistoryCurrentDisk => 'Nåværende innhold på disken';

  @override
  String get localHistoryMissingFile => 'Den opprinnelige filen mangler.';

  @override
  String get localHistoryRestoreRevision => 'Gjenopprett Versjon';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Gjenopprett til Opprinnelig Sted';

  @override
  String get localHistoryRestoreNewLocation => 'Gjenopprett til Nytt Sted…';

  @override
  String get localHistoryRestoreChange => 'Gjenopprett Endring';

  @override
  String get localHistoryRestoreUnavailable =>
      'Denne endringen kan ikke gjenopprettes fordi sammenligningen er ikke lenger aktuell.';

  @override
  String get localHistoryComparisonSimplified =>
      'Denne store sammenligningen er forenklet. Gjenopprett individuelle endringer er ikke tilgjengelig.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Eldre versjonsendring: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Nåværende innholdsendring: $text';
  }

  @override
  String get localHistoryDeleted => 'Slettet';

  @override
  String get localHistoryUntitled => 'Uten tittel';

  @override
  String get localHistoryClearDocument =>
      'Tøm historikken for dette dokumentet';

  @override
  String get localHistoryClearAll => 'Tøm all lokal historikk';

  @override
  String get localHistoryClearDocumentTitle => 'Tøm dokumentets historikk?';

  @override
  String get localHistoryClearAllTitle => 'Tøm all lokal historikk?';

  @override
  String get localHistoryClearConfirmation =>
      'Dette sletter permanent lagrede versjoner. Denne handlingen kan ikke angres.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Lokal historikk indeksen ble skadet og gjenopprettet fra intakte versjoner.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Denne lokale historikk-lagringen bruker et støttet format $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Lokal historikk er ikke tilgjengelig: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Opptak er deaktivert eller denne stien er utelatt. Aktiver opptak før gjenoppretting.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Lokal historikk kunne ikke registrere endringen av stien: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Lokal Historikk kunne ikke lagre den slettede stien: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Den valgte versjonen mangler eller er skadet.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Den valgte versjonen kan ikke leses: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Lokal Historikk kunne ikke fange opp denne versjonen: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Baselinje';

  @override
  String get localHistoryReasonSaved => 'Lagret';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Automatisk sjekkpunkt';

  @override
  String get localHistoryReasonBeforeReload => 'Før omlasting';

  @override
  String get localHistoryReasonBeforeDiscard => 'Før avvisning';

  @override
  String get localHistoryReasonBeforeRestore => 'Før gjenoppbygging';

  @override
  String get localHistoryReasonBeforeDelete => 'Før sletting';

  @override
  String get localHistoryReasonExternalChange => 'Ekstern endring';

  @override
  String get settingsHistory => 'Historikk';

  @override
  String get settingsClipboardHistoryTitle =>
      'Samle Historikk fra utklippstavlen';

  @override
  String get settingsClipboardHistoryDescription =>
      'Behold kopiert og vellykket limt innhold kun for denne BusyMark-sesjonen.';

  @override
  String get settingsLocalHistoryTitle => 'Lag lokal historikk';

  @override
  String get settingsLocalHistoryDescription =>
      'Lagre dokumentversjoner på denne enheten for gjenoppretting og sammenligning.';

  @override
  String get settingsHistoryCheckpoint => 'Automatisk sjekkpunktintervall';

  @override
  String get settingsHistoryRetention => 'Bevaringsperiode';

  @override
  String get settingsHistoryStorage => 'Maks lagringsplass';

  @override
  String get settingsHistoryExcludedPaths => 'Udelte stier';

  @override
  String get settingsHistoryExcludedPathsHint => 'Én absolutt sti per linje';

  @override
  String settingsSecondsValue(int value) {
    return '$value sekunder';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value dager';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Stavekontroll';

  @override
  String get automaticSpelling => 'Automatisk stavekontroll';

  @override
  String get defaultSpellingLanguage => 'Standard språk for stavekontroll';

  @override
  String get projectSpellingLanguage => 'Prosjektspråk for stavekontroll';

  @override
  String get chooseSpellingLanguage => 'Velg språk for stavekontroll';

  @override
  String get spellingLanguageUnsetStatus => 'Språk…';

  @override
  String get spellingOffStatus => 'Stavekontroll av';

  @override
  String get checkSpelling => 'Kontroller staving';

  @override
  String get ignoreSpellingOnce => 'Ignorer én gang';

  @override
  String get ignoreSpellingDocument => 'Ignorer alle i dette dokumentet';

  @override
  String get addPersonalSpellingWord => 'Legg til i personlig ordliste';

  @override
  String get addProjectSpellingWord => 'Legg til i prosjektordlisten';

  @override
  String get inheritSpellingLanguage => 'Bruk prosjekt- eller programspråk';

  @override
  String get disableDocumentSpelling => 'Ikke kontroller staving';

  @override
  String get importSpellingDictionary => 'Importer ordliste';

  @override
  String get personalSpellingDictionary => 'Personlig ordliste';

  @override
  String get projectSpellingDictionary => 'Prosjektordliste';

  @override
  String get noSpellingErrors => 'Ingen stavefeil';

  @override
  String get noSpellingSuggestions => 'Ingen staveforslag';

  @override
  String get spellingWordCheckFailed => 'Kunne ikke kontrollere dette ordet';

  @override
  String get spellingCheckFailed => 'Stavekontrollen mislyktes';

  @override
  String get spellingSettingsLoadFailed =>
      'Kunne ikke laste inn innstillinger for stavekontroll';

  @override
  String get retrySpellingSettings =>
      'Prøv å laste inn innstillinger for stavekontroll på nytt';

  @override
  String get spellingCheckIncomplete => 'Stavekontrollen er ufullstendig';

  @override
  String get spellingDictionaryNotInstalled => 'Ordliste er ikke installert';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Ordlisten for $dictionary er ikke installert';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Ikke installert · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Installert';

  @override
  String get installSpellingDictionary => 'Installer ordliste';

  @override
  String get removeSpellingDictionary => 'Fjern ordliste';

  @override
  String get cancelSpellingDictionaryInstall => 'Avbryt nedlasting av ordliste';

  @override
  String get retrySpellingDictionaryInstall =>
      'Prøv å installere ordlisten på nytt';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Laster ned $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Validerer ordliste…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Installasjonen mislyktes — velg for å prøve på nytt';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Installere $dictionary ($size)? Etter installering er den tilgjengelig frakoblet til du fjerner den.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Ordliste utilgjengelig';

  @override
  String get spellingChecking => 'Kontrollerer staving…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: skriv inn et tall mellom $minimum og $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Staveordboken ble endret eksternt. En gjenopprettingskopi ble bevart.';

  @override
  String get windowMinimize => 'Minimer';

  @override
  String get windowMaximize => 'Maksimer';

  @override
  String get windowRestore => 'Gjenopprett';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Koble til';

  @override
  String get nextcloudReconnect => 'Koble til på nytt';

  @override
  String get nextcloudDisconnect => 'Koble fra';

  @override
  String get nextcloudServer => 'Serveradresse';

  @override
  String get nextcloudSignInBrowser => 'Fullfør innloggingen i nettleseren.';

  @override
  String get nextcloudFavorites => 'Favoritter';

  @override
  String get nextcloudNewNote => 'Nytt notat';

  @override
  String get nextcloudSavedLocally =>
      'Lagret lokalt · venter på synkronisering';

  @override
  String get nextcloudSyncing => 'Synkroniserer';

  @override
  String get nextcloudSynced => 'Synkronisert';

  @override
  String get nextcloudOffline => 'Frakoblet';

  @override
  String get nextcloudLocked => 'Låst av serveren';

  @override
  String get nextcloudReconnectRequired => 'Ny tilkobling kreves';

  @override
  String get nextcloudCreationUncertain =>
      'Resultatet av opprettelsen er usikkert';

  @override
  String get nextcloudReadOnly => 'Skrivebeskyttet';

  @override
  String get nextcloudTakeRemote => 'Bruk ekstern versjon';

  @override
  String get nextcloudMerge => 'Slå sammen';

  @override
  String get nextcloudDeleteNote => 'Slette notatet?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Erstatning i arbeidsområdet er utilgjengelig for Nextcloud Notes. Erstatt i hvert enkelt notat.';

  @override
  String get nextcloudSaveLocalCopy => 'Lagre lokal kopi…';

  @override
  String get nextcloudDisconnectWarning =>
      'Fjerning av kontoen sletter mellomlagrede notater og ventende endringer fra denne enheten. Synkroniser først for å beholde arbeidet på serveren.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Hvis forrige opplasting lyktes, kan et nytt forsøk etterlate et ubrukt vedlegg på serveren.';

  @override
  String get nextcloudAttachmentReference => 'Vedleggsreferanse på serveren';

  @override
  String get nextcloudAddAttachment => 'Legg til vedlegg…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Når du sletter dette vedlegget, blir lenkene til det i notatet utilgjengelige. Lagrede data kan gjenopprettes fra lokal historikk.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Velg hver motstridende egenskap.';

  @override
  String get nextcloudUseServerNote => 'Bruk dette servernotatet';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Knytter dette utkastet til det valgte servernotatet og synkroniserer deretter beholdte lokale endringer. En samsvarende forespørsel bekrefter ikke hvem som opprettet notatet.';

  @override
  String get nextcloudExactCandidate =>
      'Nøyaktig samsvar med forespørselen; identiteten er ubekreftet.';

  @override
  String get nextcloudPossibleCandidate =>
      'Mulig samsvar etter normalisering; identiteten er ubekreftet.';

  @override
  String get nextcloudSelectCandidate =>
      'Velg et servernotat som skal gjennomgås';

  @override
  String get nextcloudCreateSeparate => 'Opprett et separat notat';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Den første forespørselen kan allerede ha opprettet et servernotat. Dette oppretter et separat notat med ditt beholdte lokale arbeid. Ingen antatte duplikater slettes.';

  @override
  String get wsSemanticFormats => 'Semantisk formatering';

  @override
  String get wsUiControl => 'UI-kontroll';

  @override
  String get wsFilePath => 'Fil / Sti';

  @override
  String get wsUiPath => 'UI-sti';

  @override
  String get wsDefinitionList => 'Definisjonsliste';

  @override
  String get wsIncludeContent => 'Inkluder gjenbrukbart innhold';

  @override
  String get wsVariableReference => 'Variabelreferanse';

  @override
  String get wsConvertList => 'Konverter liste til prosedyre';

  @override
  String get wsElementProperties => 'Elementegenskaper';

  @override
  String get wsTopicProperties => 'Emneegenskaper';

  @override
  String get wsCollapsible => 'Sammenleggbar';

  @override
  String get wsPublishedState => 'Publisert starttilstand';

  @override
  String get wsExpanded => 'Utvidet';

  @override
  String get wsCollapsed => 'Sammenlagt';

  @override
  String get wsCollapsedTitle => 'Sammenlagt tittel';

  @override
  String get wsTerm => 'Begrep';

  @override
  String get wsListLayout => 'Listeoppsett';

  @override
  String get wsSyncGroup => 'Synkroniseringsgruppe';

  @override
  String get wsTabKey => 'Fanenøkkel';

  @override
  String get wsSwitcherLabel => 'Bytteetikett';

  @override
  String get wsNavigationElements => 'Navigasjonselementer';

  @override
  String get wsNavigationDepth => 'Navigasjonsdybde';

  @override
  String get wsAddItem => 'Legg til element';

  @override
  String get wsStep => 'Trinn';

  @override
  String get wsPropertyInvalid => 'Ugyldig egenskapsverdi';

  @override
  String get wsFilter => 'Innholdsfilter';

  @override
  String get wsIdentifier => 'Element-ID';

  @override
  String get wsTldr => 'Sammendrag (TLDR)';

  @override
  String get wsFullLayout => 'Full bredde';

  @override
  String get wsMediumLayout => 'Middels (1:2)';

  @override
  String get wsNarrowLayout => 'Smal termkolonne';

  @override
  String get wsTitle => 'Tittel';

  @override
  String get wsSwitcherKey => 'Byttenøkkel';

  @override
  String get nextcloudServerSettings => 'Notes-innstillinger på serveren';

  @override
  String get nextcloudNotesPath => 'Sti til notatmappen';

  @override
  String get nextcloudFileSuffix => 'Filendelse for nye notater';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Disse Notes-innstillingene påvirker andre klienter. Endring av stien flytter ikke filer; endring av filendelsen gir ikke eksisterende notater nye navn.';

  @override
  String get nextcloudSettingsSaved => 'Serverinnstillinger lagret';

  @override
  String get nextcloudSettingsNormalized =>
      'Lagret med verdier normalisert av serveren';

  @override
  String get nextcloudPendingUpload => 'Vedlegg venter på opplasting';

  @override
  String nextcloudServerCheck(String time) {
    return 'Siste serverkontroll: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Laster serverinnstillinger';

  @override
  String get nextcloudSettingsSaving => 'Lagrer serverinnstillinger';

  @override
  String get nextcloudPreviousLocalEdit => 'Forrige lokale endring';

  @override
  String get nextcloudUsePreviousEdit => 'Bruk forrige endring';

  @override
  String get quickOpen => 'Hurtigåpning';

  @override
  String get notesAll => 'Alle notater';

  @override
  String get notesUncategorized => 'Uten kategori';

  @override
  String get notesRecovery => 'Gjenoppretting';

  @override
  String get notesRecentlyEdited => 'Nylig redigert';

  @override
  String get notesOldestEdited => 'Eldste redigering';

  @override
  String get notesTitleAscending => 'Tittel A–Z';

  @override
  String get notesTitleDescending => 'Tittel Z–A';

  @override
  String get notesMove => 'Flytt til kategori';

  @override
  String get notesRemoveFavorite => 'Fjern favoritt';

  @override
  String get notesOffline => 'Gjør tilgjengelig frakoblet';

  @override
  String get notesOfflineRemove => 'Fjern frakoblet oppbevaring';

  @override
  String get notesIndexing => 'Indekserer notater…';

  @override
  String get notesSearchHelp =>
      'Ord bruker OG. Bruk \"siterte fraser\", title: og category:.';

  @override
  String get notesSourceLocation => 'Kildeplassering';

  @override
  String get notesRecoveryHelp =>
      'Kun beholdte lokale notater og lokal historikk. Serverens papirkurv og historikk er utilgjengelige.';

  @override
  String get notesImport => 'Importer notater';

  @override
  String get notesExport => 'Eksporter notater';

  @override
  String get notesImportDistinct => 'Importer som eget notat';

  @override
  String get notesAvailableOffline => 'Tilgjengelig frakoblet';

  @override
  String get notesIncomplete => 'Ufullstendig';

  @override
  String get notesSelected => 'Valgte notater';

  @override
  String get notesNoHistory =>
      'Ingen beholdte revisjoner. Historikken kan være deaktivert, utløpt eller slettet.';

  @override
  String get notesTextAvailable => 'Tekst tilgjengelig lokalt';

  @override
  String get notesLocalVersion => 'Lokal arbeidsversjon';

  @override
  String get notesAttachments => 'Vedlegg';

  @override
  String get notesSkipped => 'Hoppet over';

  @override
  String get notesFailed => 'Mislyktes';

  @override
  String get notesCompleted => 'Fullført';

  @override
  String get notesImportNew => 'Start en ny import';

  @override
  String get notesImportResume => 'Fortsett avbrutt import';

  @override
  String get notesImportAlreadyImported =>
      'Allerede importert i denne operasjonen';

  @override
  String get references => 'Referanser';

  @override
  String get referenceIncoming => 'Innkommende';

  @override
  String get referenceOutgoing => 'Utgående';

  @override
  String get referenceChooseTarget => 'Velg lenkemål';

  @override
  String get referenceWholeDocument => 'Hele dokumentet';

  @override
  String get referenceSourceLocation => 'Kildeplassering';

  @override
  String get referenceTargetLocation => 'Målplassering';

  @override
  String get referenceResolved => 'Løst';

  @override
  String get referenceMissing => 'Mangler';

  @override
  String get referenceAmbiguous => 'Tvetydig';

  @override
  String get referenceUnavailable => 'Utilgjengelig i denne konteksten';

  @override
  String get referenceUnsupported => 'Ikke støttet';

  @override
  String get referenceNoPortableId =>
      'Dette målet har ingen bekreftet portabel notatadresse.';

  @override
  String get wsIncludeLines => 'Inkluder linjer';

  @override
  String get wsIncludeSymbol => 'Inkluder symbol';

  @override
  String get wsEmphasizeLines => 'Fremhev viste linjer';

  @override
  String get wsPropertiesReadOnly =>
      'Egenskapene er skrivebeskyttet i denne visningen.';

  @override
  String get wsPropertiesProtected => 'Elementet er beskyttet. Rediger kilden.';

  @override
  String get wsPropertiesConflict =>
      'Dokument eller element endret. Tilbakestill utkastet og velg på nytt.';

  @override
  String get wsPropertiesUnresolved => 'Referansen kan ikke løses nå.';

  @override
  String get wsUseDefault => 'Bruk standard';

  @override
  String get wsPropertiesSelection => 'Velg ett element.';

  @override
  String get wsImageDisplay => 'Bildevisning';

  @override
  String get wsImageThumbnail => 'Klikkbart miniatyrbilde';

  @override
  String get wsEnabled => 'Aktivert';

  @override
  String get wsDisabled => 'Deaktivert';

  @override
  String get wsWidth => 'Bredde';

  @override
  String get wsHeight => 'Høyde';

  @override
  String get wsPropertiesInactive =>
      'Egenskapen virker bare med publisert sammenfolding.';

  @override
  String get wsNavigationAll => 'Alle elementer med tittel';

  @override
  String get wsNavigationNone => 'Ingen navigasjon';

  @override
  String get wsNavigationCustom => 'Egendefinert navigasjon';

  @override
  String get wsTitleOverride => 'Overstyr tittel';

  @override
  String get wsCompactLayout => 'Kompakt';

  @override
  String get wsWideLayout => 'Bred';

  @override
  String get wsCodeSourceConflict =>
      'Flytt eller fjern koden skrevet i denne blokken før du setter src. Writerside avviser en ikke-tom kodeblokk med en kildereferanse.';

  @override
  String get wsInherited => 'Arv fra listen';

  @override
  String get wsExternalImageSize =>
      'Writerside endrer ikke størrelsen på eksterne bilder pålitelig. Eksisterende mål kan ses og fjernes.';

  @override
  String get wsPropertiesNotSerialized =>
      'Denne endringen ble ikke skrevet til kilden. Utkastet er beholdt.';

  @override
  String get wsListItem => 'Listeelement';

  @override
  String get wsSourceFile => 'Kildefil';

  @override
  String get wsLinkTarget => 'Lenkemål';

  @override
  String get wsPreviewImage => 'Forhåndsvisningsbilde';

  @override
  String get wsIncludedElement => 'Inkludert element';

  @override
  String get wsHelpModule => 'Hjelpemodul';

  @override
  String get wsActionId => 'Handlings-ID';

  @override
  String get wsKeymapHelpInstance => 'Hjelpeinstans for tastaturkart';

  @override
  String get wsShowInSource => 'Vis i Kilde';

  @override
  String get wsOriginElement => 'Elementoverstyring';

  @override
  String get wsOriginAncestor => 'Overordnet element';

  @override
  String get wsOriginModule => 'Modulstandard';

  @override
  String get wsOriginBuiltIn => 'Innebygd standard';

  @override
  String get wsOriginUnresolved => 'Uavklart';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Effektiv: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Element';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Generert: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Standard: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Standard: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Avklart: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Uavklart';

  @override
  String get wsModule => 'Modul';

  @override
  String get wsParent => 'Overordnet element';

  @override
  String get wsListType => 'Listetype';

  @override
  String get wsStartingNumber => 'Startnummer';

  @override
  String get wsListSorting => 'Sortering';

  @override
  String get wsLetteredList => 'Bokstavliste';

  @override
  String get wsCheckboxList => 'Liste med avkrysningsbokser';

  @override
  String get wsMarkerlessList => 'Liste uten markører';

  @override
  String get wsAscending => 'Stigende';

  @override
  String get wsDescending => 'Synkende';

  @override
  String get wsNoSorting => 'Ingen sortering';

  @override
  String get wsAsWritten => 'Som skrevet';

  @override
  String get wsSentenceCase => 'Stor forbokstav i setning';

  @override
  String get wsTitleCase => 'Store forbokstaver i tittel';

  @override
  String get wsLowerCase => 'Små bokstaver';

  @override
  String get wsUpperCase => 'Store bokstaver';

  @override
  String get wsNativeMarkers => 'Markdown-markører';

  @override
  String wsListMarkerStart(String number) {
    return 'Første markør: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Nivå $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Den fastsatte byggeren ignorerer modulens <caps>-regler. Bruk et lokalt caps-attributt eller default-property.';

  @override
  String get wsInsertElements => 'Sett inn elementer';

  @override
  String get wsAdmonitionsAndQuotes => 'Merknader og sitater';

  @override
  String get wsSemanticText => 'Semantisk tekst';

  @override
  String get wsPropertiesUnavailable =>
      'Det inspiserte elementet er utilgjengelig. Inspiser et element for å fortsette.';

  @override
  String get searchDocumentsCategory => 'Dokumenter';

  @override
  String get searchTopicsCategory => 'Emner';

  @override
  String get searchCurrentDocument => 'Gjeldende dokument';

  @override
  String get searchCurrentWorkspace => 'Gjeldende arbeidsområde';

  @override
  String get browseNotes => 'Bla gjennom notater';

  @override
  String get searchActionsCommand => 'Søk etter handlinger';

  @override
  String get searchDocumentsCommand => 'Søk etter dokumenter';

  @override
  String get searchTopicsCommand => 'Søk etter emner';

  @override
  String get searchRecentCommand => 'Søk i nylige';

  @override
  String get searchResourceUnavailable => 'Denne ressursen er utilgjengelig.';

  @override
  String get notesSync => 'Synkroniser notater';

  @override
  String get searchInWorkspace => 'Søk i arbeidsområde';

  @override
  String get searchCategory => 'Søkekategori';

  @override
  String get clearHistorySearchScope => 'Søk i dokumenthistorikken';

  @override
  String get searchInDocument => 'Søk i dokument';

  @override
  String get searchDocumentHint => 'Søk i dette dokumentet…';

  @override
  String get searchWorkspaceHint => 'Søk i dette arbeidsområdet…';

  @override
  String get searchOutlineHint => 'Søk i overskrifter…';

  @override
  String get searchHistoryHint => 'Søk i lokal historikk…';

  @override
  String get searchEnterText => 'Skriv inn tekst for å søke';

  @override
  String get searchAccountUnavailable => 'Konto utilgjengelig';

  @override
  String get searchDocumentsHint => 'Søk etter dokumenter…';

  @override
  String get searchTopicsHint => 'Søk etter emner…';

  @override
  String get searchRecentHint => 'Søk i nylige…';

  @override
  String get searchActionsHint => 'Søk etter handlinger…';

  @override
  String get searchRequiresNotesWorkspace => 'Krever et notatarbeidsområde';

  @override
  String get searchSidebarLabel => 'Søk:';

  @override
  String get searchDocumentTextCategory => 'Dokumenttekst';

  @override
  String get searchWorkspaceTextCategory => 'Arbeidsområdetekst';

  @override
  String get searchHeadingsCategory => 'Overskrifter';

  @override
  String get shortcutUnassigned => 'Ikke tilordnet';

  @override
  String get shortcutPressKeys => 'Trykk en tastekombinasjon…';

  @override
  String get shortcutRecord => 'Registrer hurtigtast';

  @override
  String get shortcutRestoreAll => 'Gjenopprett alle standarder';

  @override
  String get shortcutRestoreAllQuestion =>
      'Gjenopprette standardhurtigtaster for alle handlinger? Egne tilordninger fjernes.';

  @override
  String get shortcutSaveFailed =>
      'Hurtigtastene er aktive, men kunne ikke lagres. Prøv igjen for å beholde dem etter omstart.';

  @override
  String get shortcutRetry => 'Prøv lagring igjen';

  @override
  String get shortcutChanged =>
      'Tilordningene er endret. Se gjennom gjeldende hurtigtaster og prøv igjen.';

  @override
  String get shortcutInvalid =>
      'Denne kombinasjonen kan ikke tilordnes i denne sammenhengen.';

  @override
  String get shortcutSystemWarning =>
      'Skrivebordet kan bruke denne kombinasjonen. BusyMark kan ikke overstyre systemhurtigtaster.';

  @override
  String get shortcutConflicts =>
      'Denne hurtigtasten overlapper disse handlingene:';

  @override
  String get shortcutRemove => 'Fjern tilordning';

  @override
  String get shortcutRestoreDefault => 'Gjenopprett standard';

  @override
  String get shortcutAssign => 'Tilordne';

  @override
  String get shortcutReassign => 'Tilordne på nytt';

  @override
  String get shortcutContextApplication => 'Program';

  @override
  String get shortcutContextDocument => 'Dokumentvisninger';

  @override
  String get shortcutContextEditor => 'Redigering og kilde';

  @override
  String get shortcutContextWritersideSource => 'Writerside-kilde';

  @override
  String get shortcutContextWorkspace => 'Arbeidsområdenavigasjon';

  @override
  String get shortcutContextTree => 'Sidefelttrær';

  @override
  String get searchHeadingsCommand => 'Søk i overskrifter';

  @override
  String get shortcutFixed => 'Håndteres av redigereren; kan ikke tilpasses.';

  @override
  String get shortcutDefaultConflict =>
      'Standardhurtigtasten er i konflikt med en egendefinert tilordning.';

  @override
  String get shortcutCurrentBinding => 'Gjeldende hurtigtast';

  @override
  String get shortcutProposedBinding => 'Foreslått hurtigtast';

  @override
  String get notesActions => 'Notathandlinger';

  @override
  String get noteActions => 'Handlinger for notatet';

  @override
  String get noteProperties => 'Notategenskaper';

  @override
  String get notesExportAll => 'Eksporter notater · Alle notater…';

  @override
  String get notesExportCategory => 'Eksporter notater · Kategori…';

  @override
  String get notesOfflineAll => 'Gjør tilgjengelig frakoblet · Alle notater';

  @override
  String get notesOfflineCategory => 'Gjør tilgjengelig frakoblet · Kategori';

  @override
  String get notesOfflineRemoveAll =>
      'Fjern frakoblet oppbevaring · Alle notater';

  @override
  String get notesOfflineRemoveCategory =>
      'Fjern frakoblet oppbevaring · Kategori';

  @override
  String get notesOfflinePause => 'Sett nedlastinger på pause';

  @override
  String get notesOfflineResume => 'Fortsett nedlastinger';

  @override
  String get notesOfflineKeep => 'Gjør tilgjengelig frakoblet';

  @override
  String get notesOfflineRetentionHelp =>
      'Å fjerne dette kravet beholder eksisterende hurtigbuffer. Et kategori- eller kontokrav kan fortsatt beholde notatet.';

  @override
  String get notesOfflineBroader =>
      'Notatet beholdes også av et kategori- eller kontokrav.';

  @override
  String get notesOfflineExternal =>
      'Eksterne medier krever en tilkobling. BusyMark beholder bare notattekst og administrerte vedlegg.';

  @override
  String get notesEmptyAll =>
      'Ingen notater ennå. Opprett et notat for å begynne.';

  @override
  String get notesEmptyFavorites => 'Ingen favorittnotater.';

  @override
  String get notesEmptyCategory => 'Ingen notater i denne kategorien.';

  @override
  String get notesEmptyUncategorized => 'Ingen ukategoriserte notater.';

  @override
  String get notesEmptyRecovery => 'Ingen beholdte notater å gjenopprette.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Mislyktes. Prøv igjen';

  @override
  String get notesOperationFailed =>
      'Handlingen kunne ikke fullføres. Utkastet er beholdt. Kontroller lagring og konflikter, og prøv igjen.';

  @override
  String get notesInspectionFailed => 'Vedlegg · Mislyktes. Prøv igjen';

  @override
  String get notesStartingConnection => 'Starter Nextcloud-tilkoblingen…';

  @override
  String get notesVerifyingConnection => 'Kontrollerer tilgang til notater…';

  @override
  String get notesCancellingConnection => 'Avbryter innlogging og rydder opp…';

  @override
  String get notesRemovingConnection => 'Fjerner den lokale kontoen…';

  @override
  String get notesRemovedWarning =>
      'Den lokale Nextcloud-kontoen er fjernet. Tilbakekalling av app-passordet er ikke bekreftet. Fjern BusyMarks passord i sikkerhetsinnstillingene i Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Ikke alle åpne notater kunne lagres lokalt. Kontroller lagring, konflikter eller normalisering i arbeidsområdet. Lokale endringer må kanskje fortsatt synkroniseres med Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Lagre endringer i Nextcloud-innstillinger før du går videre?';

  @override
  String get notesSettingsLeaveHelp =>
      'Notes-innstillinger på serveren · Ulagrede endringer';

  @override
  String get notesSettingsReload => 'Last inn serverinnstillinger på nytt…';

  @override
  String get notesSettingsReloadHelp =>
      'Ny innlasting erstatter utkastet med gjeldende Nextcloud-innstillinger. Forkaste utkastet og laste inn på nytt?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud godtok innstillingene, men oppdatering av notatene mislyktes. Verdiene som vises er bekreftet av serveren. Prøv å oppdatere fra Notater igjen.';

  @override
  String get notesUnavailable =>
      'Frakoblet · Tekst tilgjengelig lokalt · Lagret lokalt · venter på synkronisering';

  @override
  String get notesStorageFull =>
      'Nextcloud-lagringen er full. Frigjør plass på serveren og prøv igjen.';

  @override
  String get notesRejected =>
      'Nextcloud avviste endringen. Kontroller notatet og lagre en lokal kopi før du prøver igjen.';

  @override
  String get notesThrottled =>
      'Nextcloud ba om en pause. Synkroniseringen fortsetter etter ventefristen.';

  @override
  String get notesRecoveryRequired => 'Konflikter · Sammenlign';

  @override
  String get notesScanning => 'Skanner filer…';

  @override
  String get notesCancelling =>
      'Avbryter… Venter på at gjeldende handling avsluttes.';

  @override
  String get notesCancelled => 'Avbrutt';

  @override
  String get notesPartial => 'Delvis fullført';

  @override
  String get notesTransferFailed => 'Mislyktes. Prøv igjen';

  @override
  String get notesImportPartialHelp =>
      'Tidligere elementer kan allerede være lagret lokalt. Fortsett denne importen for å unngå duplikater.';

  @override
  String get notesNotStarted => 'Ikke startet';

  @override
  String get notesCreated => 'Opprettet';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Serveradresse · Ikke støttet · Slett · Vedlegg';

  @override
  String get notesCurrentText => 'Gjeldende beholdte tekst';

  @override
  String get notesRecovering => 'Gjenoppretter som et nytt notat…';

  @override
  String get notesReadOnlyHelp =>
      'Skrivebeskyttet · Favoritter · Lagre lokal kopi…';

  @override
  String get notesSort => 'Sorter notater';

  @override
  String get notesPathRelative =>
      'Notatmappens sti er relativ til Nextcloud-lagringen din.';

  @override
  String get notesSettingsStale =>
      'Innstillingene er endret i Nextcloud. Last inn og kontroller serververdiene før du erstatter utkastet.';

  @override
  String get notesDownloadsPaused => 'Nedlastinger satt på pause';

  @override
  String get notesExportNotPublished => 'Ingen eksport ble publisert.';

  @override
  String get notesKeyringUnavailable =>
      'Lås opp skrivebordets nøkkelring og prøv igjen.';

  @override
  String get notesConnectFailed =>
      'Kunne ikke koble til Nextcloud Notes. Kontroller serveradressen og prøv igjen.';

  @override
  String get notesAccountMismatch =>
      'Logg inn på samme Nextcloud-konto. Fjern denne kontoen først for å koble til en annen.';

  @override
  String get notesLocalRemovalFailed =>
      'Lokal kontoopprydding mislyktes. Kontoen beholdes slik at du kan prøve å fjerne den igjen.';

  @override
  String get notesTransferring => 'Overfører notater…';

  @override
  String get notesTechnicalDetails => 'Tekniske detaljer';

  @override
  String get notesPauseRequirement => 'Sett frakoblet krav på pause';

  @override
  String get notesResumeRequirement => 'Fortsett frakoblet krav';

  @override
  String get gitReturnToDocument => 'Tilbake til dokumentet';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Skrivebeskyttet øyeblikksbilde · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Filnavnet inneholder byte som ikke er UTF-8. Git-gjennomgang og mellomlagring er fortsatt tilgjengelig; dokumentredigereren krever et UTF-8-filnavn.';

  @override
  String get gitUiMergeInProgress => 'Fletting pågår';

  @override
  String get gitUiRebaseInProgress => 'Gjentakelse pågår';

  @override
  String get gitUiCherryPickInProgress => 'Kirsebærplukking pågår';

  @override
  String get gitUiRevertInProgress => 'Tilbakestill pågår';

  @override
  String get gitUiPatchApplicationInProgress => 'Oppdateringsprogram pågår';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Resultat av sammenslåing av Krusj i påvente av innmelding';

  @override
  String get gitUiUnresolvedIndexConflicts => 'Uløste indekskonflikter';

  @override
  String get gitUiUnresolvedConflicts => ' · uløste konflikter';

  @override
  String get gitUiReviewOperation => 'Gjennomgåelsesoperasjon';

  @override
  String get gitUiRefresh => 'Oppdater';

  @override
  String get gitUiCreateNamedStash => 'Lag navngitte lagre';

  @override
  String get gitUiCreateStash => 'Opprett stash…';

  @override
  String get gitUiNoStashes => 'Ingen lagre';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Velg et lager som skal undersøkes for endringene';

  @override
  String get gitUiStashedUntrackedFiles => 'Stashed usporede filer';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Undersøk om filer som ikke er sporet ...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Angi igjen lagerets trinnvise/indekstilstand ved anvendelse';

  @override
  String get gitUiApplyAndRetain => 'Bruk og behold';

  @override
  String get gitUiPop => 'Pop ...';

  @override
  String get gitUiCreateBranch => 'Opprett gren…';

  @override
  String get gitUiDropStash => 'Slett stash…';

  @override
  String get gitUiBranchFromStash => 'Opprett gren fra stash';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Opprett/ bytt til en gren ved den opprinnelige basen i lageret, og bruk den. Det opprinnelige lageret beholdes for eksplisitt senere sletting.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 dette lageret?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Det opprinnelige lageret beholdes hvis det tas i bruk konflikter.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Sletter denne lageroppføringa. Endringene blir ikke tatt i bruk.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Løs de uflettede filene. Git har ingen kommando for å fortsette eller avbryte en stash; den opprinnelige stashen beholdes.';

  @override
  String get gitUiStashNameMessage => 'Stash name/message';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Stash-innhold og resultatindeks';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stopp arbeidende og trinnvise endringer';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Stash endringer og la indeksinnholdet bli stående (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Stash bare endringene i indeksen (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Ta med usporede filer';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Alle relevante stier i dette arkivet';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Ingen relevante endringer for disse lagre- valgene.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Velg minst én sti som skal velges.';

  @override
  String get gitUiCreateStash2 => 'Opprett stash';

  @override
  String get gitUiCreateWorktree => 'Lag arbeidstre ...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Opprett en commit før du oppretter et arbeidstre ved HEAD.';

  @override
  String get gitUiDetachedHEAD => 'Frakoblet HEAD';

  @override
  String get gitUiCurrent => 'Nåværende ·';

  @override
  String get gitUiLocked => 'Låst ·';

  @override
  String get gitUiOpenInBusyStack => 'Åpne i opptattStack ·';

  @override
  String get gitUiStatusNotInspected => 'Status ikke inspisert';

  @override
  String get gitUiDirty => 'Uren';

  @override
  String get gitUiClean => 'Ren';

  @override
  String get gitUiOpenWorkingFolder => 'Åpne arbeidsmappe';

  @override
  String get gitUiMoveWorktree => 'Flytt arbeidstreet ...';

  @override
  String get gitUiUnlock => 'Lås opp';

  @override
  String get gitUiLock => 'Lås';

  @override
  String get gitUiRemoveCleanWorktree => 'Fjern rent arbeidstre ...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Gjennomgå fjerning med lokale endringer ...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nytt mappenavn i arbeidstreet';

  @override
  String get gitUiNewWorktreeBranch => 'Ny gren i arbeidstreet';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Opprett $arg0/$arg1 med en ny lokal gren ved $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Målmappenavn';

  @override
  String get gitUiRemoveWorktree => 'Fjerne arbeidstre?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Uttrykkelig forkast alle lokale endringer som er sporet/ ikke sporet i dette arbeidstreet. Låste/ i bruk vil fortsatt være beskyttet.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git nekter å fjerne filer hvis det er lokale endringer, filer som ikke er sporet, eller en lås.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Forkast lokalt innhold i arbeidstreet og fjern';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Fjern rent arbeidstre';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Gjentas uttrykkelig i nestede undermoduler for oppdateringer/synkronisering';

  @override
  String get gitUiNoRecordedSubmodules => 'Ingen registrerte undermoduler';

  @override
  String get gitUiNotInitialized => 'ikke klargjort';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Overliggende gitlink: $arg0 Sjekket ut: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Smitt nestet arkiv';

  @override
  String get gitUiCleanNestedRepository => 'Reint nestet lager';

  @override
  String get gitUiNestedStatusUnavailable => 'Nøstet status ikke tilgjengelig';

  @override
  String get gitUiEnterNestedRepository => 'Skriv inn nestet lager';

  @override
  String get gitUiInitializeConfiguration => 'Klargjør oppsett';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Oppdater til foreldrens registrerte innlevering ...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Følg oppsatte fjerngrener ...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Synkroniser oppsatte URL- er ...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Den gjeldende undermodulpekeren i trinnet i forelderen';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Forelder - og undermodulen sender inn, skyver, og skitten tilstand forblir atskilt. Nettlesing klargjør eller oppdaterer dem ikke.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Hent og sjekk innmelding fra den oppsatte fjerngrenen. Dette er forskjellig fra den oppsatte gitlinken. Rekursive: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Klargjør om nødvendig og sjekk nøyaktig $arg0. Rekursiv: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Bruk den gjennomgangsoperasjonen for oppsett av undermoduler. Rekursiv: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Utfør undermodul- operasjon';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Undersøker en registrert revisjon eller oppretter en gjenvinningsgren. Reflog gjenvinner ikke vilkårlig ulagret innhold.';

  @override
  String get gitUiSelectAReflogEntry => 'Velg en reflog- oppføring';

  @override
  String get gitUiPreviousPage => 'Forrige side';

  @override
  String get gitUiNextPage => 'Neste side';

  @override
  String get gitUiRecoveryBranchName => 'Filialnavn for gjenvinning';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Oppretter en gren hos $arg0. Arbeidsfilene og den gjeldende grenen er uendret.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Opprett gjenopprettingsgren ...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'Skjermbilde med skrivebeskyttet gjenoppretting';

  @override
  String get gitUiInspectSnapshot => 'Inspiser skjermbildet ...';

  @override
  String get gitUiReviewReset => 'Gjennomgå nullstilling ...';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Side $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'En Git- teksthistorie må ha sitt redigerbare felt.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Rediger HEAD | Indeks | Arbeidstre…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Indeksen eller arbeidsinnholdet som ble gjennomgått ble endret. Oppdater denne sammenlikningen før mellomlagring.';

  @override
  String get gitUiRefreshComparison => 'Frisk opp sammenlikning';

  @override
  String get gitUiPreviousChangedFile => 'Forrige endrede fil';

  @override
  String get gitUiNextChangedFile => 'Neste endrede fil';

  @override
  String get gitUiPreviousDifference => 'Forrige forskjell';

  @override
  String get gitUiNextDifference => 'Neste forskjell';

  @override
  String get gitUiComparisonMode => 'Sammenligningsmåte';

  @override
  String get gitUiSideBySide => 'Side ved side';

  @override
  String get gitUiUnified => 'Forent';

  @override
  String get gitUiDiffDisplayOptions => 'Innstillinger for visning av diff';

  @override
  String get gitUiWrap => 'Bryt tekst';

  @override
  String get gitUiWords => 'Ord';

  @override
  String get gitUiCollapseContext => 'Fold sammen kontekst';

  @override
  String get gitUiIgnoreWhitespace => 'Ignorer tomrom';

  @override
  String get gitUiSearchComparison => 'Søk i sammenlikning';

  @override
  String get gitUiSearch => 'Søk';

  @override
  String get gitUiCloseSearch => 'Lukk søk';

  @override
  String get gitUiStagingActions => 'Igangsettingstiltak';

  @override
  String get gitUiStagingActions2 => 'Sporer handlinger ...';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Fjern valgte endrede linjer fra indeks';

  @override
  String get gitUiStageSelectedChangedLines => 'Klargjør valgte endrede linjer';

  @override
  String get gitUiUnstageWholeFile => 'Fjern hele filen fra indeks';

  @override
  String get gitUiStageWholeFile => 'Klargjør hele filen';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0- tomrom bare endrede linjer skjult · Vis nøyaktige endringer';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 endret linjer · Visningsinnstillinger endrer aldri de trinnvise bytene.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Skrivebeskyttet sammenligning · Kopier tekst eller juster visningen.';

  @override
  String get gitUiNoFinalNewline => ' · ingen endelig linjeskift';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 bytes$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'Sammenlikning av tekst er ikke tilgjengelig for dette innholdet.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Denne sammenlikningen overskrider grensen for tekstgjennomgåelse. Innholdet er ikke erklært identisk.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Sammenlignet innhold er identisk.';

  @override
  String get gitUiUnstage => 'Ufaset';

  @override
  String get gitUiStage => 'Nivå';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 endret linje';
  }

  @override
  String get gitUiContext => 'Kontekst';

  @override
  String get gitUiExpandUnchangedContext => 'Utvid uendret kontekst';

  @override
  String get gitUiUnstageThisHunk => 'Fjern denne blokken fra indeks';

  @override
  String get gitUiStageThisHunk => 'Klargjør denne blokken';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Rediger innholdet i trinnet · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Skriver gjennomgått indeksresultat';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Indeks';

  @override
  String get gitUiWorkingTree => 'Arbeidstre';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Indeks · redigerbar UTF-8- klatt';

  @override
  String get gitUiUndo => 'Angre';

  @override
  String get gitUiRedo => 'Gjør om';

  @override
  String get gitUiReloadIndexReview => 'Laste indeksen på nytt på nytt?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Last inn gjeldende HEAD-, indeks- og arbeidsversjoner på nytt. Dette erstatter det ulagrede utkastet i indeksredigeringen.';

  @override
  String get gitUiReplaceDraftAndReload => 'Erstatt kladd og last på nytt';

  @override
  String get gitUiReloadVersions => 'Last inn på nytt versjoner ...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Skriv redigert resultat til denne indeksoppføringa';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Arbeidsfiler blir værende på disken. Gjennomgå den redigerte indeksen før du søker.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Gjennomgå endringer i tekstformat i indeksen';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Oppdater bare den reviderte indeksoppføringa for $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Skriv gjennomgått indeksresultat';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Resultatet er endret under gjennomgangen av formatet. Se over det igjen.';

  @override
  String get gitUiSynchronizeScrolling => 'Synkroniser rulling';

  @override
  String get gitUiReadOnlyRevisionContent => 'Skrivebeskyttet revisjonsinnhold';

  @override
  String get gitUiEditableIndexContent => 'Redigerbart innhold i indeksen';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Den etterspurte revisjonen er utenfor gjeldende filtre. Tilbakestill filtrene til å vise den.';

  @override
  String get gitUiFilterLog => 'Filterlogg';

  @override
  String get gitUiFilters => 'Filtre ...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtre ($count) ...';
  }

  @override
  String get gitUiMessage => 'Melding…';

  @override
  String get gitUiAuthor => 'Forfatter…';

  @override
  String get gitUiPath => 'Sti ...';

  @override
  String get gitUiDate => 'Dato ...';

  @override
  String get gitUiMessageFilter => 'Meldingsfilter';

  @override
  String get gitUiAuthorFilter => 'Forfatterfilter';

  @override
  String get gitUiPathFilter => 'Stifilter';

  @override
  String get gitUiMessage2 => 'Melding';

  @override
  String get gitUiAuthor2 => 'Forfatter';

  @override
  String get gitUiPath2 => 'Sti';

  @override
  String get gitUiDateFilter => 'Datofilter ...';

  @override
  String get gitUiResetFilters => 'Tilbakestill filtre';

  @override
  String get gitUiRefreshLog => 'Frisk opp logg';

  @override
  String get gitUiGoToCommitReference => 'Gå til inn-/referanse ...';

  @override
  String get gitUiBackToHEAD => 'Tilbake til HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Ordnet kirsebærplukk';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Gjennomse kirsebærplukk ($arg0) ...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Sammenlikne to markerte revisjoner ...';

  @override
  String get gitUiToggleBranchesPane => 'Slå grener av/ på';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtrer forgreninger og etiketter';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Meld inn $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Legg inn detaljer ...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referanse: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Velg denne commiten';

  @override
  String get gitUiBranchOrTag => 'Gren eller tagg';

  @override
  String get gitUiAllReferences => 'Alle referanser';

  @override
  String get gitUiLocal => 'Lokal';

  @override
  String get gitUiRemote => 'Ekstern';

  @override
  String get gitUiTags => 'Tagger';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Ingen innsending stemmer med gjeldende filtre.';

  @override
  String get gitUiObjectID => 'Objekt- ID';

  @override
  String get gitUiSubjectReferences => 'Emne/ referanser';

  @override
  String get gitUiDate2 => 'Dato';

  @override
  String get gitUiGitCommits => 'Git- innsendinger';

  @override
  String get gitUiParents => 'Foreldrecommiter';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 foreldre';
  }

  @override
  String get gitUiLoadMoreCommits => 'Last inn flere innmeldinger';

  @override
  String get gitUiLoadingChangedFiles => 'Laster inn endrede filer';

  @override
  String get gitUiNoChangedFiles => 'Ingen endrede filer';

  @override
  String get gitUiSelectACommit => 'Velg en innsending';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Sammenlikne forelder- $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Endrede filer';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Forfatter: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Sender: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Grense for hele/ deler: et overliggende objekt er ikke tilgjengelig.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Forelderen er utenfor denne siden eller en grunn grense.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Foreldrecommit $arg0';
  }

  @override
  String get gitUiCommitActions => 'Send inn handlinger ...';

  @override
  String get gitUiEmptyTree => 'tomt tre';

  @override
  String get gitUiCreateBranch2 => 'Opprett gren';

  @override
  String get gitUiCreateTag => 'Opprett tagg';

  @override
  String get gitUiCompareRevisions => 'Sammenlikne revisjoner';

  @override
  String get gitUiOpenSnapshot => 'Åpne skjermbilde';

  @override
  String get gitUiRevertCommit => 'Tilbakestill innsending';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Interaktiv rebase etter denne grensen';

  @override
  String get gitUiResetCurrentBranch => 'Tilbakestill gjeldende gren';

  @override
  String get gitUiCopyFullObjectID => 'Kopier fullstendig objekt- ID';

  @override
  String get gitUiGoToCommitReference2 => 'Gå til inn-/referanse';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Oppgi en innsendings- ID eller referanse som viser i logg.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Den etterspurte revisjonen er ikke tilgjengelig.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Metadata fra arkivet er skrivebeskyttet. Det finnes fortsatt inspeksjon og sammenlikning av avdelinger.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Arbeidsfiler er ikke tilgjengelig eller skrivebeskyttet. Det er ikke mulig å bytte gren og flette.';

  @override
  String get gitUiSearchBranchesAndTags => 'Søk i grener og tagger';

  @override
  String get gitUiNewBranch => 'Ny gren…';

  @override
  String get gitUiLocalBranches => 'Lokale grener';

  @override
  String get gitUiRemoteBranches => 'Eksterne grener';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Spor $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Sjekket ut ved $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Oppfrisker grenmetadata';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Bytt til $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Åpent arbeidstre';

  @override
  String get gitUiCreateLocalTrackingBranch => 'Opprett lokal sporingsgren ...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Sammenlign med gjeldende HEAD';

  @override
  String get gitUiMergeIntoCurrentBranch =>
      'Flett sammen til gjeldende gren ...';

  @override
  String get gitUiRename => 'Endre navn ...';

  @override
  String get gitUiChangeUpstream => 'Endre oppstrøms ...';

  @override
  String get gitUiDelete => 'Slett ...';

  @override
  String get gitUiDeleteFromRemote => 'Slett fra fjern ...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Handlinger for $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Lokalt grennavn';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Opprett ved $arg0. Den nye grenen blir sjekket ut.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Den lokale grenen vil spore $arg0 og bli sjekket ut.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Velg nettverk for sletting';

  @override
  String get gitUiDeleteRemoteReference => 'Slett fjernreferanse';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Flett sammen $arg0 til $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Endre navn på $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Oppstrøms for $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Ingen oppstrømsgren';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Slett $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Lokal sletting bare. En gren som ikke er samlet blir nektet.';
  }

  @override
  String get gitUiDelete2 => 'Slett';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Slette usammensatt gren $arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git rapporterer at denne grenen ikke er fullstendig flettet. Slett nøyaktig den lokale referansen etter å ha gjennomgått innsendingene. Fjernkopiene er uendret.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Slett den lokale grenen som ikke er flettet sammen';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Bestemmelsessted: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Kildegren eller tagg';

  @override
  String get gitUiMergePolicy => 'Flettepraksis';

  @override
  String get gitUiFastForwardWhenPossible => 'Hurtig framover når det er mulig';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'Lag alltid en fletting';

  @override
  String get gitUiFastForwardOnly => 'Bare forover';

  @override
  String get gitUiSquashIntoStagedChanges => 'Squash inn i trinnvise endringer';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Stopp før det opprettes en flettingsinnsending';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Spoling fremover er deaktivert slik at HEAD ikke flyttes før gjennomgangen.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Legger igjen iscenesatte endringer for en egen innsending. Dette er ikke en fortsatt fletting.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Konflikter er fortsatt tilgjengelige på det felles arbeidsområdet for oppløsning.';

  @override
  String get gitUiAddRemote => 'Legg til fjernstyring ...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Hent: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Fjern fjernstyring ...';

  @override
  String get gitUiChangeFetchURL => 'Endre hente- URL ...';

  @override
  String get gitUiAddPushDestination => 'Legg til skyvemål ...';

  @override
  String get gitUiRemovePushDestination => 'Fjern skyvemål ...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Håndter $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nettverksnavn';

  @override
  String get gitUiNewRemoteName => 'Nytt fjernnavn';

  @override
  String get gitUiRepositoryURLOrLocalSource => 'Arkiv- URL eller lokal kilde';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Oppgi nøyaktig gjennomgått mål som skal fjernes. @ info: whatsthis';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Påloggingsinformasjon leveres av oppsatte hjelpeprogrammer eller en privat forespørsel.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Fjerne fjern $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Fjerner lokale nettverksoppsett og sporingsreferanser. Det sletter ikke tjenerlageret.';

  @override
  String get gitUiRemoveRemote2 => 'Fjern fjernstyring';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Innlever inn område: hele arkivet';

  @override
  String get gitUiCachedTracking => 'Mellomlagret sporing';

  @override
  String get gitUiAmendLastCommit => 'Endre siste commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Konfigurerte kroker og signeringer respekteres.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Skriver om den valgte HEAD-commiten. Ekstern sporing beviser ikke at den er upublisert.';

  @override
  String get gitUiRepository => 'Kodelager';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Frakoblet $arg0';
  }

  @override
  String get gitUiLog => 'Historikk';

  @override
  String get gitUiRepositoryActions => 'Kodelagerhandlinger';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Mellomlagret sporing · $upstream · $ahead foran · $behind bak';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Bare lager · ingen arbeidstre. Åpne logg for å undersøke historien.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Arkiv med skrivebeskyttet fil · mellomlagring og innsendinger er ikke tilgjengelig.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Lagerstatus ikke tilgjengelig';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Endre $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Legg til godkjenningslinje';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Bruk oppsett signeringspraksis';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Kryptografisk signering av denne innmeldingen';

  @override
  String get gitUiDoNotSignThisCommit => 'Ikke signer denne innsendingen';

  @override
  String get gitUiRecentCommitMessages => 'Nylig innsendte meldinger ...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Bruk den oppsatte innsendingsmalen ...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Forfatteridentitet og oppsatte kroker ...';

  @override
  String get gitUiDraftMessage => 'Kladd melding ...';

  @override
  String get gitUiCommitOptions => 'Commit-valg';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Kladd beholdt i minnet, lagring mislyktes. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Commit-melding';

  @override
  String get gitUiGitOperationInProgress => 'Git- operasjon pågår';

  @override
  String get gitUiCancel => 'Avbryt';

  @override
  String get gitUiAmendStaged => 'Endret trinnvis';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Meld inn i trinn ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit og push…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Det er ikke satt opp en lesbar innmeldingsmal.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Meld inn identitet og kroker';

  @override
  String get gitUiRecentMessages => 'Nylige meldinger';

  @override
  String get gitUiReplaceMessageDraft => 'Erstatte kladd?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Erstatte den eksisterende sende- meldinga med den valgte meldinga?';

  @override
  String get gitUiReplaceDraft => 'Erstatt kladd';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Det finnes en lokal innmelding med $arg0.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Lokalt innmeldingsmelding for $arg0 finnes. Gjennomgå logg før det forsøkes en annen innsending. Kladdet er blitt beholdt.';
  }

  @override
  String get gitUiCommitAuthorName => 'Send inn forfatterens navn';

  @override
  String get gitUiCommitAuthorEmail => 'Meld inn e- post fra forfatteren';

  @override
  String get gitUiConfiguredDefault => 'satt opp standard';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Signering: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Konfigurerte kroker: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'En godkjenningslinje er en erklæring i meldingen, atskilt fra en kryptografisk signatur. Identiteten lagres bare i dette kodelagerets lokale innstillinger; utkastet beholdes.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Lagre arkiv- identitet';

  @override
  String get gitUiStaged => 'Klargjort';

  @override
  String get gitUiUntracked => 'Usporet';

  @override
  String get gitUiUnstaged => 'Ikke klargjort';

  @override
  String get gitUiConflicts => 'Konflikter';

  @override
  String get gitUiNoChanges => 'Ingen endringer';

  @override
  String get gitUiRepositoryChangeTree => 'Lagerendringstre';

  @override
  String get gitUiChanges => 'Endringer';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Utvid';

  @override
  String get gitUiCollapse => 'Fold sammen';

  @override
  String get gitUiUnstageFile => 'Fjern fil fra indeks';

  @override
  String get gitUiStageFile => 'Klargjør fil';

  @override
  String get gitUiExpandGroup => 'Fold ut gruppe';

  @override
  String get gitUiCollapseGroup => 'Fold sammen gruppe';

  @override
  String get gitUiReviewDifference => 'Revisjonsforskjell';

  @override
  String get gitUiUnstageSelectedFiles => 'Fjern valgte filer fra indeks';

  @override
  String get gitUiStageSelectedFiles => 'Klargjør valgte filer';

  @override
  String get gitUiFileHistoryAndBlame => 'Filhistorie og skyld ...';

  @override
  String get gitUiDeleteUntrackedFile => 'Slett usporet fil ...';

  @override
  String get gitUiDiscardUnstagedChange => 'Forkast ikke- trinnvis endring ...';

  @override
  String get gitUiFileHistory => 'Filhistorikk';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Forkast $arg0 som ikke er trinn?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Erstatter innhold som virker med indeksen, eller sletter denne usporede fila. Innholdet i et trinn blir beholdt. Ulagrede vertsdokumenter må gjennomgås først.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Slett usporet fil';

  @override
  String get gitUiDiscardWorkingChange => 'Forkast arbeidsendring';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Slett REMOTE referanse $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Dette fjerner referansen for hvert faktiske skyvemål oppført nedenfor. Lokale grener/ merker beholdes. Forventede tips er fastsatt i denne gjennomgangen.';

  @override
  String get gitUiReferenceDoesNotExist => 'referansen finnes ikke';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Forventet tips: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Fjernsletting fullført.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Slett $arg0 fra fjernkontrollen?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'De eksakte tipsene over blir fjernet. Alle endrede fjerntips stopper operasjonen for en ny gjennomgang.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Gjennomgå og slett fra fjernstyring ...';

  @override
  String get gitUiDestinationReference => 'Bestemmelsessted';

  @override
  String get gitUiReviewDestinations => 'Revurderingsbestemmelsessteder';

  @override
  String get gitUiNewRemoteBranch => 'ny fjern gren';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · forventet: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Et mål har sendt inn som ikke er tilgjengelig lokalt. Hent det reviderte målet før du gjennomgår utgående historie.';

  @override
  String get gitUiFetchReviewedDestination => 'Hent gjennomsøkt mål';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Velg et mål og gjennomgå utgående innmeldinger.';

  @override
  String get gitUiNoOutgoingCommits => 'Ingen utgående innmeldinger';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Velg en utgående innmelding';

  @override
  String get gitUiLoadMoreOutgoingCommits =>
      'Last inn flere utgående innmeldinger';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Sett dette målet som oppstrøms';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Velg nøyaktige etiketter å publisere';

  @override
  String get gitUiTagsNone => 'Merker: ingen';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Merker: $arg0 valgt';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Utgi nøyaktig: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push ferdig. Den lokale innmeldingen er fortsatt tilgjengelig i Logg.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Tvungen push krever nøyaktig de målrevisjonene som er vist i denne gjennomgangen.';

  @override
  String get gitUiForceWithReviewedLease =>
      'Kraft med gjennomgått leieavtale ...';

  @override
  String get gitUiPush => 'Push';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Tvinge på med reviderte leieavtaler?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Skriv om $arg0 bare hvis alle destinationer ennå har nøyaktig det tipset som er vist over.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Andre kan allerede bruke denne historikken. Henting i bakgrunnen fornyer ikke denne sikkerhetsbetingelsen.';

  @override
  String get gitUiForceWithLease => 'Kraft med leieavtale';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Resultatet er usikkert. Gjennomgå mål igjen før et annet trykk.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Overliggende $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Nettverkstjener som skal hentes';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Fjernsorterte, slettede fjernsporende grener';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Hent oppdateringsinformasjon fra nettverket uten å erstatte filer.';

  @override
  String get gitUiFetch => 'Hent';

  @override
  String get gitUiSourceRemote => 'Fjernkilde';

  @override
  String get gitUiSourceBranch => 'Kildegren';

  @override
  String get gitUiReviewedStrategy => 'Gjennomgået strategi';

  @override
  String get gitUiMerge => 'Flett';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Stopp hvis målet ikke kan gå forover, aldri slå sammen eller gjenopprett.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Flett sammen med en fletting, herunder når fort forover er mulig.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Flett sammen, tillat forover dersom mulig.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Start lokal historie på nytt samtidig som lokal fletting lagres.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Lokalt innlegg på nytt som en lineær historie.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git er satt opp for interaktiv rebase. Velg en dra- strategi her, eller åpne og åpne Rebase ... for å gjennomgå en plan.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Bruk gjennomgått ordinær rebase for dette trekket';

  @override
  String get gitUiOptions => 'Valg';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Lag alltid en fletting (ingen forover)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Bevar lokale fletteinnføyninger';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Lokale endringer kan hindre trekk. Gjennomgå/ta med dem, eller lag et lager uttrykkelig.';

  @override
  String get gitUiStashes => 'Stasher';

  @override
  String get gitUiCreateOrReviewStash => 'Opprett eller gjennomse lager ...';

  @override
  String get gitUiPullWithSelectedStrategy => 'Dra med valgt strategi';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'Arkiv- URL eller lokal Git- kilde';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH eller lokal sti';

  @override
  String get gitUiFolderToInitialize => 'Mappe å klargjøre';

  @override
  String get gitUiFinalCloneDestination => 'Endelig klonemål';

  @override
  String get gitUiChoose => 'Velg ...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Lager bare Git- metadata. Eksisterende filer er ikke i e- post eller er i e- post.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Målmappen må ikke finnes eller må være tom. Eksisterende brukerdata overskrives aldri.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Filialen som ble valgt først · blank bruker effektiv Git- praksis';

  @override
  String get gitUiSelectedBranchOptional => 'Valgt gren · valgfritt';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Rekursivt innledende/ajourførte undermoduler';

  @override
  String get gitUiPreparingGitOperation => 'Forbereder Git- operasjonen ...';

  @override
  String get gitUiThisAttemptCreated => 'Dette forsøket opprettet';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Målet eksisterte før dette forsøket:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Mappa blir stående for inspeksjon. Se gjennom den før et annet kloneforsøk.';

  @override
  String get gitUiNoDestinationDirectoryRemains => 'Ingen målmappe gjenstår.';

  @override
  String get gitUiCancelProcess => 'Avbryt prosess';

  @override
  String get gitUiInitialize => 'Initialiser';

  @override
  String get gitUiClone => 'Klon';

  @override
  String get gitUiChooseNewBase => 'Velg ny base';

  @override
  String get gitUiChooseUpstreamBoundary => 'Velg oppstrømsgrense';

  @override
  String get gitUiNewBase => 'Ny base';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Oppstrømsgrense · utelatt';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Samme som oppstrømsgrense';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Velg gren, tagg eller commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Bruk oppstrøms som ny base';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Velg en gyldig gren, tagg eller send fra logg.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Første beholdte commit i en grenblokk kan ikke være squash eller fixup: den har ingen foregående målcommit.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Grenblokk $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Åpne ord vil be om en ny melding]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Planlagte meldinger';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Forhåndsvisning av original/sammensatt melding · Git ber om de siste om ord/forhåndsmeldinger';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Resultat $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Gjeldende gren: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'Frakoblet HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Rebase skriver om commit-identiteter. Sporingsdata for eksterne grener beviser ikke at historikken aldri er publisert.';

  @override
  String get gitUiIncludeRootCommits => 'Ta med rotcommiter';

  @override
  String get gitUiMergeCommits => 'Flett innsendinger';

  @override
  String get gitUiFlattenHistory => 'Gjør historikken lineær';

  @override
  String get gitUiPreserveBranchStructure => 'Behold grenstrukturen';

  @override
  String get gitUiAutosquash => 'Automatisk sammenslåing';

  @override
  String get gitUiPrepareGitPlan => 'Klargjør Git-plan';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Legger inn i gjenspilling: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Omfatter alle rot- innsendinger som kan nås fra denne grenen.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Commiter etter $boundary brukes på nytt oppå $base; selve grensecommiten er utelatt.';
  }

  @override
  String get gitUiRoot => 'Rot';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git gren/etikett/gjenoppbygging/flettingsstruktur';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Velg en eksplisitt gammel grense eller rotmodus, og forbered planen.';

  @override
  String get gitUiMoveUp => 'Flytt opp';

  @override
  String get gitUiMoveDown => 'Flytt ned';

  @override
  String get gitUiResetPlan => 'Tilbakestill plan';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · grenblokk $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Velg en innsending for detaljer og endrede filer';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Forhåndsvis kombinerte meldinger ...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ flytter den valgte innmeldinga. Ikke- relaterte grenreferanser blir ikke oppdatert automatisk.';

  @override
  String get gitUiCancelPlan => 'Avbryt plan';

  @override
  String get gitUiStartReviewedRebase => 'Begynn rebase?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Omskriving av $arg0 planlagte innsendinger på $arg1. Nedfelte innsendinger er fortsatt synlig markert i denne planen til du starter.';
  }

  @override
  String get gitUiStartRebase => 'Start rebase';

  @override
  String get gitUiNoContinuingGitOperation => 'Ingen fortsatte Git- operasjon';

  @override
  String get gitUiStoppedForEditingAmend => ' · stoppet for redigering/endring';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Dette er indeksoppføringer som ikke er flettet sammen, muligens fra et lagerprogram. Git har ingen lagerinnstillinger, eller avbryt kommandoen.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Rediger arbeidsfilene, etappe og endre gjeldende e- post, og fortsett så med denne ny base.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · uflettede indekstrinn $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Indeksen har ingen uløste oppføringer.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Behold denne innmeldinga som en tom innsending';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Den virkelige indeksen har ingen trinnvise endringer. Lag en eksplisitt tom inntasting, fortsett så sekvenseren hvis den fortsatt er aktiv.';

  @override
  String get gitUiKeepEmptyCommit => 'Behold tom innsending ...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git prøver å gå tilbake til operasjonens start. Det garanteres ikke at tidligere innhold utenfor indeksen, usporede filer eller ulagrede endringer kan gjenopprettes.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Hopp over den aktuelle forpliktelsen og fortsett med den neste planlagte forpliktelsen.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Gløym denne operasjonens bokføring samtidig som gjeldende filer og innholdsfortegnelse beholdes.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Fortsett $arg0';
  }

  @override
  String get gitUiReloadConflictVersions =>
      'Laste inn konfliktversjoner på nytt?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Erstatt kladden til det ulagrede resultatet med gjeldende arbeidsfil. Lagret arbeidsinnhold beholdes.';

  @override
  String get gitUiLoadingConflictVersions => 'Laster konfliktversjoner ...';

  @override
  String get gitUiLoadingConflict => 'Laster konflikt';

  @override
  String get gitUiBaseLeft => 'Base → til venstre';

  @override
  String get gitUiBaseRight => 'Basis → høyre';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Ingen grunnoppføring for denne konflikten';

  @override
  String get gitUiAcceptEntireLeftFile => 'Godta hele fila til venstre ...';

  @override
  String get gitUiAcceptEntireRightFile => 'Godta hele fila til høyre ...';

  @override
  String get gitUiPreviousConflictRegion => 'Forrige konfliktområde';

  @override
  String get gitUiNextConflictRegion => 'Neste konfliktområde';

  @override
  String get gitUiManualResolution => 'Manuell oppløsning';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Regionen $arg0/$arg1 · $arg2 gjennomgått';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Kildejusteringen gikk over sammenligningsgrensen for tekst; kilderutene er fortsatt tilgjengelige for manuell gjennomgang.';

  @override
  String get gitUiAcceptLeftRegion => 'Godta venstre område';

  @override
  String get gitUiAcceptRightRegion => 'Godta høyre region';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Behold manuelt resultat for regionen';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Bruk Git sine ikke- konvekse endringer?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Bytt ut kladden for gjeldende resultat med Git sin fletteforhåndsvisning. Dette forkaster manuelle endringer for ulagrede resultater, fila er uendret til Lagre.';

  @override
  String get gitUiUseMergePreview => 'Bruk forhåndsvisning av fletting';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Bruk ikke- sammenflettende endringer ...';

  @override
  String get gitUiLeftSource => 'Venstre kilde';

  @override
  String get gitUiResult => 'Resultat';

  @override
  String get gitUiRightSource => 'Høyre kilde';

  @override
  String get gitUiStage2 => 'Trinn 2';

  @override
  String get gitUiStage3 => 'Fase 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Konfliktversjoner er ikke tilgjengelig. Oppdater for å gjennomgå deres nåværende tilstand.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Resultatet lagret til disk. Indeksen avgjør fremdeles om denne fila er løst.';

  @override
  String get gitUiSaveResultDraft => 'Lagre resultatutkast';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Bruk resultat og klargjør løsningen';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Resultat · innhold som kan redigeres i UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Redigerbart konfliktresultat';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Venstre: $arg0 · $arg1\nHøyre: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Velg innhold, sletting eller en undermodul som uttrykkelig sender inn. Ingen binærdata er dekodet som redigerbar tekst.';

  @override
  String get gitUiUseEntireLeftContent => 'Bruk hele innholdet til venstre ...';

  @override
  String get gitUiUseEntireRightContent => 'Bruk hele innholdet til høyre ...';

  @override
  String get gitUiDeleteThisPath => 'Slett denne stien ...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Løst inn- delmodul';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Stage denne eksakte gitlinken i forelderen. Dette sjekker ikke ut eller sender inn undermodulen.';

  @override
  String get gitUiSetResolvedGitlink => 'Sett oppløst gitlink ...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Basis- → stadiet $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Resultatet ble redigert. Behold det manuelle resultatet eller velg et annet uendret område.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Bruke løsningen «$arg0»?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Iscenelegg den valgte gitlinken i forelderen. Sjekk ut undermodulen og dens filer blir ikke erstattet.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Erstatter hele arbeidsstien $arg0 og iscenesetter beslutningen. Gjeldende arbeidsinnhold og eventuelt ulagret resultatutkast blir forkastet.';
  }

  @override
  String get gitUiApplyEntireFileDecision => 'Bruk hele filavgjørelsen';

  @override
  String get gitUiStageThisConflictResolution =>
      'Iscenesett denne konfliktløsningen?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Bruk hele det redigerte resultatet som $arg0. Git registrerer stien løst når den er i etappe. Se gjennom alt planlagt innhold først. $arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Bruk og klargjør';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Se gjennom endringer i tekstformat på resultatet';

  @override
  String get gitUiSaveReviewedResult => 'Lagre gjennomgått resultat';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Tilgjengelighet for det innebygde Git- tabellen er ikke tilgjengelig. Prøv igjen etter at programmet er koblet til igjen.';

  @override
  String get gitUiSans => 'Sansfrance. kgm';

  @override
  String get gitUiSelect => 'Velg';

  @override
  String get gitUiContextMenu => 'Kontekstmeny';

  @override
  String get gitUiCopyText => 'Kopier tekst';

  @override
  String get gitUiLoadingRow => 'Laster rad';

  @override
  String get gitUiRetry => 'Prøv igjen';

  @override
  String get gitUiGitMessage => 'Git- melding';

  @override
  String get gitUiCancelPrompt => 'Avbryt spørring';

  @override
  String get gitUiUseMessageAndContinue => 'Bruk meldinga og fortsett';

  @override
  String get gitUiRespondPrivately => 'Svar privat';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Visningsinnstillinger kunne ikke lagres: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Meld inn utkast til lagring: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Visningsinnstillinger kunne ikke leses: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Send inn kladd ble lagret i minnet, men kunne ikke lagres: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Det undersøkte arkivet er skrivebeskyttet for denne operasjonen. Historikk og innholdsinspeksjon er fortsatt tilgjengelig.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git returnerte $arg0. Programmet kunne ikke friske opp sine dokumenter: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Velg commit i historikken…';

  @override
  String get gitUiCurrentBranch => 'Gjeldende gren';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Ingen grener eller tagger som passer. Velg en innsending i logg.';

  @override
  String get gitUiBranches => 'Grener';

  @override
  String get gitUiPushCommits => 'Push commiter';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Dra inn i $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Løs opp $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Gjeldende handling';

  @override
  String get gitUiRebaseCommits => 'Rebase commiter';

  @override
  String get gitUiFetch2 => 'Hent…';

  @override
  String get gitUiPull => 'Pull…';

  @override
  String get gitUiPush2 => 'Push…';

  @override
  String get gitUiBranches2 => 'Grener…';

  @override
  String get gitUiManageRemotes => 'Administrer eksterne lagre…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Flett sammen til $arg0 ...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Konflikter og gjeldende handling ...';

  @override
  String get gitUiStashes2 => 'Stasher…';

  @override
  String get gitUiWorktrees => 'Arbeidstrær…';

  @override
  String get gitUiSubmodules => 'Undermoduler…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog og gjenoppretting…';

  @override
  String get gitUiCloneRepository => 'Klon kodelager…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Trekk tilbake arkivtillit';

  @override
  String get gitUiWaitingForRepositoryStatus => 'Venter på lagerstatus';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Lagerstatus ikke tilgjengelig, oppfrisk';

  @override
  String get gitUiManageRemotes2 => 'Administrer eksterne lagre';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Flett sammen til $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Arbeidstrær';

  @override
  String get gitUiSubmodules2 => 'Undermoduler';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog og gjenoppretting';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Klonelager · $arg0';
  }

  @override
  String get gitUiApply => 'Bruk';

  @override
  String get gitUiResizeGitPanes => 'Endre størrelse på Git- rutene';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 prosent';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Utgangsstatus: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Lageret er endret. Frisk opp og se over før det forsøkes igjen.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'En annen handling holder arkivet eller indeksen låst. Vent, og oppfrisk så.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Denne handlinga må ha tillit til lageret.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Git- tjenesten ble frakoblet. Koble til og avstemme arkivet på nytt.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Den installerte Git- programmet kan ikke støtte denne operasjonen. Se gjennom kjøretiden nedenfor.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Dette arkivet er skrivebeskyttet for den etterspurte operasjonen. Gjennomgang og historie er fortsatt tilgjengelig.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Operasjonen trenger avstemming. Se over arkivet eller fjernstatusen før du gjentar det.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git- autentisering mislyktes. Sjekk referansehjelperen eller lås opp den oppsatte nøkkelringen.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH- vertsverifisering mislyktes. Sjekk vertsidentiteten gjennom de SSH- verktøyene du har satt opp.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Signering mislyktes eller ble avbrutt. Gjennomgå signeringsnøkkelen, agenten og det oppsette signeringsverktøyet.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Oppgi navn og e- post for et fillager, og gå så tilbake til kladden for bevart melding.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git avviste den reviderte oppdateringen. Frisk opp og se over det faktiske målet før du forsøker igjen.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Arbeidende eller trinnvise endringer hindrer denne operasjonen. Gjennomgå, oppgi eller uttrykkelig lagre dem.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Et nødvendig Git- objekt er ikke tilgjengelig. Se gjennom grunne eller delvise grenser og hent uttrykkelig om nødvendig.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git- operasjonen mislyktes: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnostikk';

  @override
  String get gitUiAuthorizeGitInspection => 'Godkjenn Git- inspeksjon ...';

  @override
  String get gitUiCopyDiagnostics => 'Kopier diagnose';

  @override
  String get gitUiActions => 'Handlinger';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Filial i $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Lager en lokal gren uten å sjekke den ut.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tagg $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Skrivebeskyttet skjermbilde · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Kryssingplukkerkommiter';

  @override
  String get gitUiRevertCommits => 'Tilbakestill innsendinger';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Sammenlikne med fullstendig revisjons- ID';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Tre- sammenlikningsretning: $arg0 → revisjonen som er oppgitt her.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Oppgi en fullstendig gyldig objekt- ID.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · tresammenlikning';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Tilbakestill $arg0 til $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Flytter HEAD/gjeldende gren. Reflog gjenoppretter ikke vilkårlig usporet eller ulagret innhold.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Flytt HEAD; behold indeks og arbeidsfiler.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Flytt HEAD og erstatt indeksen; behold arbeidsfilene.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Erstatt HEAD, indeks og sporede arbeidsfiler; usporede filer som er i veien, kan overskrives.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Erstatt HEAD, indeks og aktuelle filer; avvis hvis lokale endringer ville gå tapt.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Tilbakestill med $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Gjennomgå effektene av valgt modus før anvendelse.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Tilbakestill $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Mål $arg0';
  }

  @override
  String get gitUiTagName => 'Taggnavn';

  @override
  String get gitUiAnnotatedTag => 'Annotert tagg';

  @override
  String get gitUiCryptographicSigning => 'Kryptografisk signering';

  @override
  String get gitUiConfiguredPolicy => 'Sett opp praksis';

  @override
  String get gitUiSignThisTag => 'Signer denne taggen';

  @override
  String get gitUiDoNotSign => 'Ikke signer';

  @override
  String get gitUiTagMessage => 'Tagg- melding';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Lager taggen lokalt. Publiser valgte tagger uttrykkelig i Push- gjennomgang.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Fullstendige trær: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Neste endrede fil- side';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Skjermbilde av arkivet som bare kan leses. Å åpne en fil sjekker aldri denne revisjonen.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Åpne skrivebeskyttet versjon';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Gjenopprett denne stien ... · Venter på lagerstatus';

  @override
  String get gitUiRestoreThisPath => 'Gjenopprett denne stien ...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Historie · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Gjenopprette $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Erstatt denne arbeidsstien med revisjon $arg0. Innhold som finnes fra før beholdes.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Gjenopprett arbeidsfila';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Filhistorien følger navneendringene · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Linjehistorikk · committet innhold';

  @override
  String get gitUiBlame => 'Linjehistorikk…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Arbeidstre';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile => 'Åpne skrivebeskyttet loggfil';

  @override
  String get gitUiCompareToCurrentFile => 'Sammenlikne med gjeldende fil';

  @override
  String get gitUiCompareToParent => 'Sammenlikne med forelder ...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Innsendt $arg0 · ulagret innhold i redigeringen er ikke en del av disse merknadene';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Historie fra $arg0';
  }

  @override
  String get gitUiBoundary => ' · grense';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nOpprinnelig linje $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Forrige linjer';

  @override
  String get gitUiNextLines => 'Neste linjer';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Uttrykkelig programrekkefølge · mål $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Legg til full objekt- ID';

  @override
  String get gitUiAddReviewedCommit => 'Legg til gjennomgått innmelding ...';

  @override
  String get gitUiMoveEarlier => 'Flytt tidligere';

  @override
  String get gitUiMoveLater => 'Flytt senere';

  @override
  String get gitUiRemoveFromReviewedSequence => 'Fjern fra gjennomgått sekvens';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Bruk endringene uten å lage innsendinger';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Bruk denne uttrykkelige forelderlinja for fletting av innsendinger';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Tomme eller allerede anvendte innsendinger kan stoppe Git for en uttrykkelig over- eller videreføringsbeslutning.';

  @override
  String get gitUiRevertInReviewedOrder => 'Tilbakestill i revidert rekkefølge';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Cherry-pick i revidert rekkefølge';

  @override
  String get gitUiReturnToFiles => 'Gå tilbake til filer';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Commit';

  @override
  String get gitUiBackToCommit => 'Tilbake til innlevering';

  @override
  String get gitUiSelectAChangeToReview =>
      'Velg en endring som skal gjennomgås';

  @override
  String get gitUiLoadingBranch => 'Laster gren ...';

  @override
  String get gitUiBranchUnavailable => 'Ikke tilgjengelig for gren';

  @override
  String get gitUiUnbornHEAD => 'HEAD uten commit';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'Frakoblet HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'Fortsett';

  @override
  String get gitUiPick => 'Behold';

  @override
  String get gitUiReword => 'Endre melding';

  @override
  String get gitUiEdit => 'Rediger';

  @override
  String get gitUiSquash => 'Slå sammen';

  @override
  String get gitUiFixup => 'Slå sammen uten melding';

  @override
  String get gitUiDrop => 'Utelat';

  @override
  String get gitUiAbort => 'Avbryt operasjon';

  @override
  String get gitUiSkip => 'Hopp over';

  @override
  String get gitUiQuit => 'Avslutt operasjon';

  @override
  String get gitUiSoft => 'Myk';

  @override
  String get gitUiMixed => 'Blandet';

  @override
  String get gitUiHard => 'Hard';

  @override
  String get gitUiKeep => 'Behold';

  @override
  String get gitUiCreate => 'Opprett';

  @override
  String get gitUiApplyStash => 'Bruk stash';

  @override
  String get gitUiPopStash => 'Bruk stash og fjern ved suksess';

  @override
  String get gitUiDropStashAction => 'Slett stash';

  @override
  String get gitUiEditedResult => 'Redigert resultat';

  @override
  String get gitUiLeftContent => 'Venstre innhold';

  @override
  String get gitUiRightContent => 'Høyre innhold';

  @override
  String get gitUiDeletePath => 'Slett sti';

  @override
  String get gitUiSubmoduleCommit => 'Delmodulinngåelse';

  @override
  String get gitUiPresentContent => 'Tilgjengelig innhold';

  @override
  String get gitUiAbsentContent => 'Fraværende';

  @override
  String get gitUiBinaryContent => 'Binært innhold';

  @override
  String get gitUiTooLargeContent => 'Innholdet overskrider visningsgrensen';

  @override
  String get gitUiUnavailableContent => 'Ikke tilgjengelig innhold';

  @override
  String get gitUiGitlinkContent => 'Undermodulpeker';

  @override
  String get gitUiSymlinkContent => 'Symbolsk lenke';

  @override
  String get gitUiNoOperation => 'Ingen operasjon';

  @override
  String get gitUiCherryPickOperation => 'Cherry-pick';

  @override
  String get gitUiRevertOperation => 'Tilbakefør';

  @override
  String get gitUiApplyMailboxOperation => 'Bruk oppdateringer';

  @override
  String get gitUiSquashOperation => 'Squashfletting';

  @override
  String get gitUiUnmergedOperation => 'Indeks uten fletting';

  @override
  String get gitUiWaitingForPromptPhase => 'Venter på svar';

  @override
  String get gitUiStoppedPhase => 'Stoppet for gjennomgang';

  @override
  String get gitUiCompletedPhase => 'Fullført';

  @override
  String get gitUiFailedPhase => 'Mislyktes';

  @override
  String get gitUiCancelledPhase => 'Avbrutt';

  @override
  String get gitUiUncertainPhase => 'Resultat krever avstemming';

  @override
  String gitUiStageVersion(String stage) {
    return 'Konflikttrinn $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git forhåndsvisning av fletting';

  @override
  String get gitUiNormalizedWorking => 'Arbeidstreet · Git normalisert';

  @override
  String gitUiPercentValue(String value) {
    return '$value prosent';
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
  String get gitUiUtf8Bom => 'UTF- 8 med byterekkefølgemerke (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF- 8 uten byterekkefølgemerke (BOM)';

  @override
  String get gitUiAddsBom =>
      'Denne redigeringen legger til et UTF- 8 byte- rekkefølgemerke (BOM) ved begynnelsen av fila.';

  @override
  String get gitUiRemovesBom =>
      'Dette redigeringa fjerner UTF- 8 byterekkefølge- merket (BOM) fra filas begynnelse.';

  @override
  String get gitUiNoLineTerminators => 'Ingen linjeterminatorer';

  @override
  String gitUiLineEndings(String format) {
    return '$format-linjeskift';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Blandet linje slutter ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · ingen endelig LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Endring av linjesluttformatet fra $before til $after. Tekst på utklippstavla kan bruke forskjellige linjeslutter fra den opprinnelige fila.';
  }

  @override
  String get gitUiGitFailure =>
      'Git- operasjonen mislyktes. Se gjennom diagnoseen nedenfor.';

  @override
  String get gitUiAbortInline => 'Avbryt operasjon';

  @override
  String get gitUiSkipInline => 'Hopp over';

  @override
  String get gitUiQuitInline => 'avslutt';

  @override
  String get gitUiMergeInline => 'Flett';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-pick';

  @override
  String get gitUiRevertInline => 'Tilbakefør';

  @override
  String get gitUiApplyMailboxInline => 'appleMailbox';

  @override
  String get gitUiSquashInline => 'Slå sammen';

  @override
  String get gitUiUnmergedInline => 'usammenflettet';

  @override
  String get gitHostFetch => 'Hent';

  @override
  String get gitHostRefreshGitStatus => 'Oppdater Git- status';

  @override
  String get gitHostCommitStaged => 'Meld inn trinnvis';

  @override
  String get gitHostGitBranches => 'Git grene';

  @override
  String get gitHostReviewPush => 'Gjennomgangstrykk';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git- operasjoner gjelder hele dette arkivet og kan utføre dets oppsatte kroker, filtre, referanse- og signeringsverktøy.';

  @override
  String get gitHostContentUnavailable => 'Innhold ikke tilgjengelig';

  @override
  String get gitHostInitializeRepository => 'Initialiser repositorium';

  @override
  String get gitHostCloneRepository => 'Klon kodelager';

  @override
  String get gitHostInitializeHere => 'Klargjør her ...';

  @override
  String get gitHostCloneRepository2 => 'Klon kodelager…';

  @override
  String get gitHostGitLog => 'Git- logg';

  @override
  String get gitUiAbsentPlaceholder => '(ikke sendt)';

  @override
  String get gitUiUnborn => 'ufødt';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Historikk etter rebase · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Gjeldende historikk · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit som brukes på nytt · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Innkommende innhold · $revision';
  }

  @override
  String get gitUiContentConflict => 'Innholdskonflikt';

  @override
  String get gitUiSubmoduleConflict => 'Konflikt i delmodul';

  @override
  String get gitUiSymlinkConflict => 'Konflikt i symbolsk lenke';

  @override
  String get gitUiAddAddConflict => 'Tillagt på begge sider';

  @override
  String get gitUiModifyDeleteConflict =>
      'Endret/slettet eller omnavngitt/slettet';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
