// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Nieuwe notitie van bewaarde tekst';

  @override
  String get notesAccountThrottled =>
      'Nextcloud vraagt om een pauze. Wacht voordat u opnieuw aanmeldt.';

  @override
  String get notesSettingsRefreshing =>
      'Notes vernieuwen na de bevestigde instellingenwijziging';

  @override
  String get notesExportOperationFailed =>
      'De export is vóór publicatie mislukt. Controleer bron en bestemming en exporteer opnieuw.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'De herstelde notitie is opgeslagen maar kon niet worden geopend. Los openstaande editor- of eigenschapswijzigingen op en open deze bestaande notitie.';

  @override
  String get notesSettingsPendingNotes =>
      'Openstaande notities, conflicten of onzekere aanmaak blokkeren deze wijziging. Synchroniseer of beoordeel ze in Notes en probeer dit bewaarde concept opnieuw.';

  @override
  String get notesSettingsPendingAttachments =>
      'Openstaande bijlagebewerkingen blokkeren deze wijziging. Beoordeel ze in Notes en probeer dit bewaarde instellingenconcept opnieuw.';

  @override
  String get notesAccountServerAddress =>
      'Gebruik het canonieke HTTPS-adres van Nextcloud en meld opnieuw aan. Het adres of de omleiding kon niet worden geverifieerd.';

  @override
  String get notesAccountUnsupported =>
      'Notes is niet beschikbaar of de API wordt niet ondersteund. Schakel Nextcloud Notes in met API-hoofdversie 1, subversie 4 of hoger.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud heeft de aanmeldgegevens geweigerd. Autoriseer dit account opnieuw of verbind opnieuw.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud heeft de controle van Notes-mogelijkheden geweigerd. Vraag toestemming aan de beheerder en probeer opnieuw.';

  @override
  String get notesAccountMalformed =>
      'Het Nextcloud-antwoord kon niet worden geverifieerd. Controleer de serverinstallatie en meld opnieuw aan.';

  @override
  String get notesAccountTimedOut =>
      'De aanmelding is verlopen. Begin opnieuw en voltooi de toestemming in de browser.';

  @override
  String get notesAccountBrowserUnavailable =>
      'De systeembrowser kon niet worden geopend. Controleer de standaardbrowser en meld opnieuw aan.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud is onbereikbaar. Controleer de verbinding en server en meld opnieuw aan.';

  @override
  String get notesAccountRejected =>
      'Nextcloud heeft het mogelijkhedenverzoek geweigerd. Controleer toegang met de beheerder en probeer opnieuw.';

  @override
  String get notesAccountFailed =>
      'Accountinstelling is mislukt. Probeer opnieuw aan te melden.';

  @override
  String get notesTransferSourceChanged =>
      'De bron is na beoordeling gewijzigd. Beoordeel het huidige bestand of maak een nieuwe momentopname.';

  @override
  String get notesTransferUnreadable =>
      'De bron kon niet worden gelezen. Controleer toegang tot het bestand of de map en beoordeel opnieuw.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Ongeldige of niet-ondersteunde momentopname. Kies een geldige BusyMark Notes-momentopname of Markdown-bron.';

  @override
  String get notesTransferMediaLimit =>
      'Media overschrijden de importlimiet. Verklein de media van het betreffende item en beoordeel opnieuw.';

  @override
  String get notesTransferUnsafeSource =>
      'De bron bevat een onveilig pad. Kies bestanden binnen de bronmap en beoordeel opnieuw.';

  @override
  String get notesTransferDestination =>
      'De export kon niet worden geschreven. Controleer toegang en vrije ruimte bij de bestemming en exporteer opnieuw.';

  @override
  String get notesTransferOperationFailed =>
      'De overdracht is mislukt. Beoordeel de betreffende items en probeer opnieuw. Eerder geïmporteerde items blijven opgeslagen.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Export met weglatingen beschikbaar';

  @override
  String get notesBatchUnchanged => 'De gevraagde waarden waren al ingesteld.';

  @override
  String get notesBatchReadOnly =>
      'Deze notitie is alleen-lezen. Beveiligde eigenschappen kunnen niet wijzigen; Favoriet blijft toegestaan.';

  @override
  String get notesBatchReviewChanged =>
      'Deze notitie is na beoordeling gewijzigd. Beoordeel de huidige staat voordat u de actie herhaalt.';

  @override
  String get notesBatchMissing =>
      'Deze notitie is niet meer beschikbaar. Vernieuw de lijst en beoordeel de doelen opnieuw.';

  @override
  String get notesBatchStorage =>
      'Lokaal opslaan is mislukt. Controleer de opslag en probeer dit item opnieuw; geslaagde items blijven opgeslagen.';

  @override
  String get notesRemoteReviewChanged =>
      'De servernotitie is gewijzigd. Uw samenvoegconcept blijft bewaard. Beoordeel de nieuwe vergelijking en kies opnieuw een oplossing.';

  @override
  String get notesReviewRemote => 'Ik heb de huidige serverversie beoordeeld';

  @override
  String get wsModuleCapsNotPublished =>
      'Hoofdlettergebruik van de module wordt niet gepubliceerd.';

  @override
  String get wsTitleOverridesAction => 'Instantie- en inhoudsopgavetitels…';

  @override
  String get wsHeadingNotPublished =>
      'Wordt niet gepubliceerd door deze bouwer.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'De vastgelegde builder publiceert geen instantietitels in Markdown-onderwerpen. Bestaande opmaak blijft behouden; bekijk de bron.';

  @override
  String get wsTopicIdentity => 'Onderwerp-ID';

  @override
  String get wsElementAnchor => 'Elementanker';

  @override
  String get wsHeadingText => 'Koptekst';

  @override
  String get wsDefaultTitle => 'Standaardtitel';

  @override
  String get wsTopicNavigation => 'Onderwerpnavigatie';

  @override
  String get wsHeadingOptions => 'Kopattributen';

  @override
  String get wsDocumentOptions => 'Documentinstellingen';

  @override
  String get wsSettingsPresent => 'Expliciete instellingen aanwezig';

  @override
  String get wsTitleOverrideExplanation =>
      'Vervangt de gepubliceerde titel; de koptekst blijft gelijk.';

  @override
  String get wsIgnoreVariables => 'Variabeletekst letterlijk behandelen';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Indien ingeschakeld wordt tekst die op variabelen lijkt niet vervangen.';

  @override
  String get wsInstanceSelection => 'Helpinstanties';

  @override
  String get wsInstanceExplanation =>
      'Selecteer helpuitvoer via namen, groepen, lijsten, uitsluitingen of expressies.';

  @override
  String get wsFilterExplanation =>
      'Filter herbruikbare inhoud op criteria; dit selecteert geen helpinstantie.';

  @override
  String get wsContextHelp => 'Contexthelp-ID';

  @override
  String get wsCapitalization => 'Hoofdlettergebruik';

  @override
  String get wsLibraryTopic => 'Bibliotheekonderwerp';

  @override
  String get wsLastModified => 'Laatst gewijzigd';

  @override
  String get wsMissingTopicHeading =>
      'Geen onderwerp-H1 aanwezig. Voeg deze toe in de bron.';

  @override
  String get wsMultipleTopicHeadings =>
      'De eerste H1 bepaalt de onderwerptitel. Latere H1’s zijn afzonderlijke koppen.';

  @override
  String get wsTopicIdentityMismatch =>
      'De root-id verschilt van de bestands-ID. Gebruik Onderwerpbestand hernoemen of bekijk de bron.';

  @override
  String get wsUnsupportedProperties =>
      'Niet-ondersteunde attributen blijven behouden. Bekijk ze in de bron.';

  @override
  String get wsGeneratedAnchor =>
      'Gegenereerd anker; een waarde maakt een overschrijving.';

  @override
  String get wsHeadingBuilderLimitation =>
      'De vastgelegde builder publiceert geen H1-attributen. Ze horen bij de kop, niet bij de XML-root.';

  @override
  String get closeOtherTabs => 'Andere tabbladen sluiten';

  @override
  String get tocTopicFromTemplate => 'Onderwerp uit sjabloon...';

  @override
  String get tocSaveAsTemplate => 'Opslaan als sjabloon';

  @override
  String get tocTemplateDialog => 'Onderwerp uit sjabloon maken';

  @override
  String get tocTemplatesEditor => 'Bestands- en codesjablonen';

  @override
  String get tocEditTemplates => 'Sjablonen bewerken...';

  @override
  String get tocCreateCustomTemplate => 'Aangepast sjabloon maken...';

  @override
  String get tocTemplateCreated => 'Sjabloon gemaakt';

  @override
  String get tocTemplateDefault => 'Standaard';

  @override
  String get tocTemplateCustom => 'Aangepast';

  @override
  String get tocTemplateFilename => 'Bestandsnaam:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Intern';

  @override
  String get tocTemplateUnnamed => 'Naamloos';

  @override
  String get tocTemplateNew => 'Nieuw sjabloon...';

  @override
  String get tocTemplateName => 'Naam:';

  @override
  String get tocTemplateExtension => 'Extensie:';

  @override
  String get tocTemplateLoadError =>
      'Sjablonen konden niet worden geladen. Bestaande sjablonen zijn niet gewijzigd.';

  @override
  String get tocTemplateSaveError =>
      'Sjablonen konden niet worden opgeslagen. Uw wijzigingen zijn hier nog beschikbaar.';

  @override
  String get tocTemplateConflict =>
      'Sjablonen zijn in een ander venster gewijzigd. Annuleer en open de editor opnieuw.';

  @override
  String get tocTemplateDuplicateName =>
      'Er bestaat al een sjabloon met deze naam en extensie.';

  @override
  String get tocTemplateFormat => 'Indeling:';

  @override
  String get tocTemplateReset => 'Herstellen';

  @override
  String get tocTemplateRetry => 'Opnieuw proberen';

  @override
  String tocRemoveElementsDialog(int count) {
    return '$count inhoudsopgave-elementen verwijderen';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'De bronbestanden die aan deze inhoudsopgave-elementen zijn gekoppeld, worden niet verwijderd.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Onderwerp selecteren om aan de huidige instantie toe te voegen';

  @override
  String get tocGroupName => 'Groepsnaam';

  @override
  String get tocMoveLineUp => 'Regel omhoog verplaatsen';

  @override
  String get tocMoveLineDown => 'Regel omlaag verplaatsen';

  @override
  String get tocEmptyMdTopic => 'Leeg MD-onderwerp';

  @override
  String get tocEmptyXmlTopic => 'Leeg XML-onderwerp';

  @override
  String get tocCopySpecial => 'Speciaal kopiëren';

  @override
  String tocCopyFileName(String name) {
    return 'Onderwerpbestandsnaam \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Onderwerpbestandspad';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Onderwerptitel \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID van inhoudsopgave-element \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Onderwerpbestandsnaam';

  @override
  String get tocCopyTopicTitleUnavailable => 'Onderwerptitel';

  @override
  String get tocCopyElementIdUnavailable => 'ID van inhoudsopgave-element';

  @override
  String get tocEditTitleAction => 'Titel bewerken...';

  @override
  String get tocEditTitleDialog => 'Titel bewerken';

  @override
  String get tocRemoveElementAction => 'Inhoudsopgave-element verwijderen...';

  @override
  String get tocSetHomePage => 'Als startpagina instellen';

  @override
  String tocGoToElement(String fileName) {
    return 'Naar inhoudsopgave-element in \'$fileName\' gaan';
  }

  @override
  String get tocSynchronize => 'Inhoudsopgave en editor synchroniseren';

  @override
  String get tocEmptyGroupAction => 'Lege groep';

  @override
  String get tocNewEmptyGroup => 'Nieuwe lege groep';

  @override
  String get tocGroupAction => 'Groeperen';

  @override
  String get tocNewGroup => 'Nieuwe groep';

  @override
  String get tocSortChildren =>
      'Onderliggende onderwerpen alfabetisch sorteren';

  @override
  String get tocLinkTopicFiles =>
      'Onderwerpbestanden aan inhoudsopgave koppelen...';

  @override
  String get addLocalMarkdownFiles => 'Lokale Markdown-bestanden toevoegen';

  @override
  String get tocTitleField => 'Titel in inhoudsopgave:';

  @override
  String get tocTopicTitleField => 'Onderwerptitel:';

  @override
  String get tocAdvancedSettings => 'Geavanceerde instellingen';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Titel voor \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Titel alleen voor inhoudsopgave:';

  @override
  String get tocInstanceTitleExplanation =>
      'Alleen gebruikt voor de huidige instantie. Standaard overgenomen van de onderwerptitel.';

  @override
  String get tocOnlyTitleExplanation =>
      'Alleen gebruikt in de inhoudsopgave. Standaard overgenomen van de onderwerptitel of de instantiespecifieke titel, indien ingesteld. Titels worden uitgelegd';

  @override
  String get tocTitleDocumentationLink => 'hier';

  @override
  String get tocFindUsages => 'Zoeken';

  @override
  String get tocRefactorMenu => 'Refactoren';

  @override
  String get tocSafeDelete => 'Veilig verwijderen';

  @override
  String get tocDuplicate => 'Dupliceren';

  @override
  String get tocDuplicateFilename => 'Onderwerpbestandsnaam:';

  @override
  String get tocDuplicateDialog => 'Onderwerp dupliceren';

  @override
  String get pdfTitlePage => 'Titelpagina';

  @override
  String get pdfIncludeTitlePage => 'Titelpagina opnemen';

  @override
  String get pdfTitlePageNote =>
      'Deze pagina heeft geen koptekst, voettekst of zichtbaar paginanummer.';

  @override
  String get pdfTitlePageTitle => 'Titel';

  @override
  String get pdfTitlePageSubtitle => 'Ondertitel';

  @override
  String get pdfTitlePageAuthor => 'Auteur';

  @override
  String get pdfTitlePageOrganization => 'Organisatie';

  @override
  String get pdfTitlePageVersion => 'Versie';

  @override
  String get pdfTitlePageDate => 'Datum';

  @override
  String get pdfTitlePageTitleRequired =>
      'Voer een titel voor de titelpagina in.';

  @override
  String get pdfTocSectionNote =>
      'Begint op een aparte pagina en kan meerdere pagina’s beslaan.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor voor Markdown-bestanden en Writerside-compatibele documentatieprojecten.';

  @override
  String get aboutBusyMark => 'Over BusyMark';

  @override
  String get aboutTagline => 'Markdown en Writerside-editor';

  @override
  String get aboutLicenseLabel => 'Licentie';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Broncode';

  @override
  String get reportIssue => 'Rapporteer een probleem';

  @override
  String get feedbackCategory => 'Categorie';

  @override
  String get feedbackChooseCategory => 'Kies een categorie';

  @override
  String get feedbackCategoryProblem => 'Probleem of bug';

  @override
  String get feedbackCategoryFeature => 'Functieverzoek';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Privacy- of beveiligingsproblemen';

  @override
  String get feedbackCategoryUsability => 'Bezorgdheid over bruikbaarheid';

  @override
  String get feedbackCategoryOther => 'Overig';

  @override
  String get feedbackSubject => 'Onderwerp';

  @override
  String get feedbackMessage => 'Gedetailleerd bericht';

  @override
  String get feedbackReplyEmail => 'E-mailadres voor antwoord (optioneel)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Voeg technische details toe';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Indien ingeschakeld, voegt dit alleen uw Linux-besturingssysteemversie en de landinstelling van de BusyMark-toepassing toe. Er zijn geen logbestanden, bestanden, accountgegevens of andere diagnostische gegevens bijgevoegd.';

  @override
  String get feedbackSubmit => 'Indienen';

  @override
  String get feedbackSubmitting => 'Verzenden…';

  @override
  String get feedbackCategoryRequired => 'Kies een categorie.';

  @override
  String get feedbackSubjectLength =>
      'Het onderwerp moet tussen 3 en 120 tekens lang zijn.';

  @override
  String get feedbackMessageLength =>
      'Het bericht moet tussen de 10 en 5.000 tekens lang zijn.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Voer een geldig e-mailadres in of laat dit veld leeg.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark kan geen verbinding maken. Controleer uw internetverbinding en probeer het opnieuw.';

  @override
  String get feedbackTimeoutFailure =>
      'Er is een time-out opgetreden voor het verzoek. Probeer het opnieuw.';

  @override
  String get feedbackRateLimitedFailure =>
      'Er zijn te veel rapporten verzonden via deze verbinding. Wacht en probeer het opnieuw.';

  @override
  String get feedbackRejectedFailure =>
      'De server heeft dit rapport afgewezen. Controleer de formuliervelden en probeer het opnieuw.';

  @override
  String get feedbackServerFailure =>
      'De server kon het rapport niet accepteren. Probeer het later opnieuw.';

  @override
  String feedbackSuccess(String id) {
    return 'Feedback verzonden. Referentie-ID: $id';
  }

  @override
  String get advanced => 'Geavanceerd';

  @override
  String get addToGit => 'Toevoegen aan Git';

  @override
  String get appearance => 'Uiterlijk';

  @override
  String get apply => 'Toepassen';

  @override
  String get back => 'Terug';

  @override
  String get bottomLeft => 'Linksonder';

  @override
  String get bottomRight => 'Rechtsonder';

  @override
  String get cancel => 'Annuleren';

  @override
  String get choose => 'Kiezen';

  @override
  String get chooseLocation => 'Kies locatie';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copyPlainText => 'Kopiëren als platte tekst';

  @override
  String get clipboardCopyFailed =>
      'De selectie kon niet naar het klembord worden gekopieerd.';

  @override
  String get copyName => 'Kopieer naam';

  @override
  String get copyFileName => 'Bestandsnaam kopiëren';

  @override
  String get copyPath => 'Kopieer pad';

  @override
  String get create => 'Maken';

  @override
  String get creating => 'Maken...';

  @override
  String get cut => 'Knippen';

  @override
  String get promoteSection => 'Sectie promoten';

  @override
  String get demoteSection => 'Sectie degraderen';

  @override
  String get moveSectionUp => 'Verplaats sectie naar boven';

  @override
  String get moveSectionDown => 'Verplaats sectie naar beneden';

  @override
  String get confirmDeleteSectionTitle => 'Sectie verwijderen?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '\'$name\' en alle inhoud in de bijbehorende sectie verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get darkTheme => 'Donker';

  @override
  String get delete => 'Verwijderen';

  @override
  String get discard => 'Weggooien';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Bestand';

  @override
  String get fileHistory => 'Bestandsgeschiedenis';

  @override
  String get folder => 'Map';

  @override
  String get insert => 'Invoegen';

  @override
  String get keyboardShortcuts => 'Sneltoetsen op het toetsenbord';

  @override
  String get commandUnavailableInContext =>
      'Niet beschikbaar in de huidige editorcontext';

  @override
  String get lightTheme => 'Licht';

  @override
  String get mainMenu => 'Hoofdmenu';

  @override
  String get fullScreen => 'Volledig scherm';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Openen';

  @override
  String get openInFiles => 'Openen in Bestandsbeheer';

  @override
  String get pathActions => 'Padacties';

  @override
  String get outline => 'Overzicht';

  @override
  String get overwrite => 'Overschrijven';

  @override
  String get paste => 'Plakken';

  @override
  String get reading => 'Lezen';

  @override
  String get removeFromRecent => 'Verwijderen uit recent';

  @override
  String get recent => 'Recent';

  @override
  String get redo => 'Opnieuw uitvoeren';

  @override
  String get save => 'Opslaan';

  @override
  String get search => 'Zoeken';

  @override
  String get selectAll => 'Selecteer alles';

  @override
  String get settings => 'Instellingen';

  @override
  String get source => 'Bron';

  @override
  String get split => 'Splitsen';

  @override
  String get systemTheme => 'Systeem';

  @override
  String get theme => 'Thema';

  @override
  String get appLanguage => 'Taal';

  @override
  String get systemLanguage => 'Systeem';

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
  String get toggleSidebar => 'Zijbalk in-/uitschakelen';

  @override
  String get topLeft => 'Linksboven';

  @override
  String get topRight => 'Rechtsboven';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get validate => 'Valideren';

  @override
  String get validation => 'Validatie';

  @override
  String get viewMode => 'Weergavemodus';

  @override
  String get welcome => 'Welkom';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Afbeeldingen';

  @override
  String get openMarkdownFile => 'Markdown-bestand openen';

  @override
  String get markdownFileExtensions => '.md of .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Open een map of Writerside-project';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown-map of Writerside-compatibel project';

  @override
  String get noOpenFile => 'Geen bestand geopend';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Verwijder het geselecteerde item uit Bestanden of verwijder het geselecteerde onderwerp uit de inhoudsopgave';

  @override
  String get shortcutGroupGeneral => 'Algemeen';

  @override
  String get shortcutNewDocument => 'Maken';

  @override
  String get shortcutNewDocumentDescription =>
      'Maak een Markdown-bestand of Writerside-project';

  @override
  String get shortcutOpenDescription =>
      'Open een Markdown-bestand, map of Writerside-project';

  @override
  String get shortcutSaveDescription => 'Sla het huidige document op';

  @override
  String get shortcutSearchDescription => 'Zoek in de huidige werkruimte';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Sneltoetsen van de toepassing aanpassen';

  @override
  String get shortcutSyntaxReferenceDescription => 'Syntaxisreferentie openen';

  @override
  String get shortcutSettingsDescription => 'Open BusyMark-instellingen';

  @override
  String get shortcutNextTab => 'Volgende tabblad';

  @override
  String get shortcutNextTabDescription =>
      'Ga naar het volgende geopende tabblad';

  @override
  String get shortcutPreviousTab => 'Vorig tabblad';

  @override
  String get shortcutPreviousTabDescription =>
      'Ga naar het vorige geopende tabblad';

  @override
  String get shortcutCloseTab => 'Tabblad sluiten';

  @override
  String get shortcutCloseTabDescription => 'Sluit het actieve tabblad';

  @override
  String get shortcutCloseAllTabs => 'Sluit alle tabbladen';

  @override
  String get shortcutCloseAllTabsDescription => 'Sluit alle geopende tabbladen';

  @override
  String get shortcutGroupTextEditing => 'Tekstbewerking';

  @override
  String get shortcutSelectAllDescription =>
      'Selecteer in de bronmodus alle tekst; druk in de Editor-modus tweemaal om elk blok te selecteren';

  @override
  String get shortcutCutDescription => 'Knip de geselecteerde tekst';

  @override
  String get shortcutCopyDescription => 'Kopieer de geselecteerde tekst';

  @override
  String get shortcutPasteDescription => 'Plakken vanaf het klembord';

  @override
  String get shortcutPastePlainTextDescription =>
      'Klembordtekst plakken zonder opmaak';

  @override
  String get shortcutUndoDescription => 'Maak de laatste bewerking ongedaan';

  @override
  String get shortcutRedoDescription =>
      'Voer de laatste ongedaan gemaakte bewerking opnieuw uit';

  @override
  String get shortcutInsertIndentation => 'Inspringing invoegen';

  @override
  String get shortcutInsertIndentationDescription =>
      'Voeg een inspringing toe bij de cursor';

  @override
  String get shortcutOutdentSource => 'Inspringing in bron verminderen';

  @override
  String get shortcutOutdentSourceDescription =>
      'Verwijder één inspringingsniveau in de bronmodus';

  @override
  String get shortcutEscape => 'Zoeken sluiten of blokselectie wissen';

  @override
  String get shortcutEscapeDescription =>
      'Sluit het zoeken in de werkruimte of wis een blokselectie in de Editor-modus';

  @override
  String get shortcutGroupFormatting => 'Opmaak';

  @override
  String get shortcutBoldDescription =>
      'Vetgedrukt in- of uitschakelen voor geselecteerde tekst';

  @override
  String get shortcutItalicDescription =>
      'Schakel cursief in op de geselecteerde tekst';

  @override
  String get shortcutUnderlineDescription =>
      'Schakel het onderstrepen van de geselecteerde tekst in of uit';

  @override
  String get shortcutLinkDescription => 'Een link invoegen of bewerken';

  @override
  String get shortcutInlineCodeDescription =>
      'Schakel inlinecode voor de geselecteerde tekst in of uit';

  @override
  String get shortcutStrikethroughDescription =>
      'Schakel doorhalen van de geselecteerde tekst in of uit';

  @override
  String get shortcutGroupBlocks => 'Blokken';

  @override
  String get shortcutParagraphDescription =>
      'Stel het huidige blok in op alinea';

  @override
  String get shortcutHeading1Description => 'Stel het huidige blok in op Kop 1';

  @override
  String get shortcutHeading2Description => 'Stel het huidige blok in op Kop 2';

  @override
  String get shortcutHeading3Description => 'Stel het huidige blok in op Kop 3';

  @override
  String get shortcutHeading4Description => 'Stel het huidige blok in op Kop 4';

  @override
  String get shortcutHeading5Description => 'Stel het huidige blok in op Kop 5';

  @override
  String get shortcutHeading6Description => 'Stel het huidige blok in op Kop 6';

  @override
  String get shortcutGroupLists => 'Lijsten';

  @override
  String get numberedList => 'Genummerde lijst';

  @override
  String get shortcutNumberedListDescription =>
      'Schakel genummerde lijstopmaak in of uit';

  @override
  String get bulletedList => 'Lijst met opsommingstekens';

  @override
  String get shortcutBulletedListDescription =>
      'Schakel de opmaak van de lijst met opsommingstekens in of uit';

  @override
  String get checklist => 'Controlelijst';

  @override
  String get shortcutChecklistDescription =>
      'Schakel de opmaak van de checklist in of uit';

  @override
  String get shortcutGroupSidebar => 'Zijbalk';

  @override
  String get sidebarViewMenu => 'Zijbalkweergave';

  @override
  String get createMarkdownFile => 'Markdown-bestand maken';

  @override
  String get createMarkdownFileDescription =>
      'Start een niet-opgeslagen lokaal Markdown-document';

  @override
  String get createWritersideProject => 'Maak een Writerside-project';

  @override
  String get createWritersideProjectDescription =>
      'Start een lokaal Writerside-compatibel project';

  @override
  String get defaultProjectName => 'Documentatie';

  @override
  String get defaultInstanceName => 'Gebruikershandleiding';

  @override
  String get defaultStartTopicTitle => 'Aan de slag';

  @override
  String get projectName => 'Projectnaam';

  @override
  String get directoryName => 'Mapnaam';

  @override
  String get instanceName => 'Instantienaam';

  @override
  String get instanceId => 'Instantie-ID';

  @override
  String get startTopicTitle => 'Titel van startonderwerp';

  @override
  String get location => 'Locatie';

  @override
  String get projectNameRequired => 'Projectnaam is vereist.';

  @override
  String get directoryNameRequired => 'Mapnaam is vereist.';

  @override
  String get useSingleSafeDirectoryName => 'Gebruik één veilige mapnaam.';

  @override
  String get useLowercaseIdentifier =>
      'Gebruik een identificatiecode in kleine letters met letters, cijfers, onderstrepingstekens of koppeltekens.';

  @override
  String get startTopicTitleRequired => 'Titel van startonderwerp is vereist.';

  @override
  String get createWritersideProjectFailed =>
      'Kan Writerside-project niet maken.';

  @override
  String get settingsTitle => 'BusyMark-instellingen';

  @override
  String get autoSave => 'Automatisch opslaan';

  @override
  String get autoSaveDescription =>
      'Sla bestandswijzigingen automatisch op na een korte periode van inactiviteit.';

  @override
  String get wordWrap => 'Regelterugloop';

  @override
  String get wordWrapDescription =>
      'Laat lange regels op de editorbreedte doorlopen in plaats van horizontaal te schuiven.';

  @override
  String get editorFontSize => 'Lettergrootte van de editor';

  @override
  String get validateOnEdit => 'Valideren bij bewerken';

  @override
  String get clearRecentWorkspaces => 'Recente geschiedenis wissen';

  @override
  String get editingButtonsPosition => 'Positie van knoppen bewerken';

  @override
  String get editingButtonsPositionDescription =>
      'Kies waar de zwevende WYSIWYG-bewerkingsknoppen verschijnen.';

  @override
  String get editingButtonsDirection => 'Richting van knoppen bewerken';

  @override
  String get editingButtonsDirectionDescription =>
      'Kies of de zwevende WYSIWYG-bewerkingsknoppen horizontaal of verticaal zijn gerangschikt.';

  @override
  String get horizontal => 'Horizontaal';

  @override
  String get vertical => 'Verticaal';

  @override
  String get privacy => 'Privacy';

  @override
  String get allowRemoteImages => 'Laad externe afbeeldingen';

  @override
  String get allowRemoteImagesDescription =>
      'Sta toe dat Markdown-voorbeelden en editorafbeeldingen worden geladen vanaf http- en https-URL\'s.';

  @override
  String get clearRemoteImagePermissions =>
      'Wis machtigingen voor externe afbeeldingen';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Verwijder de opgeslagen rechten voor werkruimten die externe afbeeldingen mochten laden.';

  @override
  String get clearGitWorkspaceTrust => 'Wis vertrouwde Git-werkruimten';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Vraag dit voordat u Git-functies inschakelt voor eerder vertrouwde werkruimten.';

  @override
  String get settingsEditingButtonsSectionTitle => 'Bewerkingsknoppen';

  @override
  String get spellingDictionaries => 'Spellingswoordenboeken';

  @override
  String get spellingDictionariesDescription =>
      'Spellingswoordenboeken installeren en beheren';

  @override
  String get settingsDictionariesSectionTitle => 'Woordenboeken';

  @override
  String get availableSpellingDictionaries => 'Beschikbare woordenboeken';

  @override
  String get customSpellingDictionaries => 'Aangepaste woordenboeken';

  @override
  String get spellingDictionaryProblems => 'Woordenboekproblemen';

  @override
  String get settingsWindowSectionTitle => 'Raam';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Open de vorige werkruimte opnieuw bij het opstarten';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Open de werkruimte en tabbladen van de vorige sessie wanneer BusyMark start.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Bevestig voordat u sluit met niet-opgeslagen wijzigingen';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Vraag dit voordat u BusyMark sluit als documenten niet-opgeslagen wijzigingen bevatten.';

  @override
  String get closeUnsavedChangesTitle => 'Niet-opgeslagen wijzigingen';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Dit document bevat niet-opgeslagen wijzigingen. Wijzigingen opslaan voordat u BusyMark sluit?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documenten bevatten niet-opgeslagen wijzigingen. Wijzigingen opslaan voordat BusyMark wordt gesloten?',
      one:
          '1 document bevat niet-opgeslagen wijzigingen. Wijzigingen opslaan voordat BusyMark wordt gesloten?',
      zero: 'Wijzigingen opslaan voordat BusyMark wordt gesloten?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Annuleren';

  @override
  String get closeUnsavedChangesDiscard => 'Weggooien';

  @override
  String get closeUnsavedChangesSave => 'Opslaan';

  @override
  String get currentFile => 'huidig bestand';

  @override
  String get unsavedChanges => 'Niet-opgeslagen wijzigingen';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Er zijn niet-opgeslagen wijzigingen in $fileName. Sla ze op voordat je verdergaat?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documenten bevatten niet-opgeslagen wijzigingen. Sla ze op voordat u doorgaat?',
      one:
          '1 document bevat niet-opgeslagen wijzigingen. Sla het op voordat u doorgaat?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Bestand gewijzigd op schijf';

  @override
  String get fileChangedOnDiskMessage =>
      'Dit bestand is op schijf gewijzigd sinds u het hebt geopend. Overschrijven?';

  @override
  String get untitledMarkdownFileName => 'Untitled.md';

  @override
  String get unorderedList => 'Ongenummerde lijst';

  @override
  String get orderedList => 'Genummerde lijst';

  @override
  String get taskList => 'Takenlijst';

  @override
  String get toggleTaskChecked => 'Taak als voltooid markeren';

  @override
  String get indentListItem => 'Lijstitem inspringen';

  @override
  String get outdentListItem => 'Lijstitem uitspringen';

  @override
  String get blockquote => 'Blokcitaat';

  @override
  String get codeBlock => 'Codeblok';

  @override
  String get codeBlockLanguage => 'Codebloktaal';

  @override
  String get image => 'Afbeelding';

  @override
  String get video => 'Video';

  @override
  String get openVideo => 'Video afspelen';

  @override
  String get pauseVideo => 'Video pauzeren';

  @override
  String get videoUnavailable => 'Video niet beschikbaar';

  @override
  String get videoPreview => 'Videovoorbeeld';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Video mist het kenmerk src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Niet-ondersteunde videobron: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Videobestand bestaat niet: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Videovoorbeeldafbeelding bestaat niet: $preview';
  }

  @override
  String get inlineImage => 'Inline-afbeelding';

  @override
  String get table => 'Tabel';

  @override
  String get htmlBlock => 'HTML-blok';

  @override
  String get htmlContentDefault => 'HTML-inhoud';

  @override
  String get shortcutHtmlBlockDescription =>
      'Voeg een HTML-blok in of bewerk het';

  @override
  String get renderedHtml => 'Weergegeven HTML';

  @override
  String get editHtml => 'HTML bewerken';

  @override
  String get htmlSource => 'HTML-bron';

  @override
  String get thematicBreak => 'Horizontale scheidingslijn';

  @override
  String get bold => 'Vetgedrukt';

  @override
  String get italic => 'Cursief';

  @override
  String get underline => 'Onderstrepen';

  @override
  String get strikethrough => 'Doorhalen';

  @override
  String get inlineCode => 'Inline-code';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Hard regeleinde';

  @override
  String get insertBlankLine => 'Lege regel invoegen';

  @override
  String get textStyle => 'Tekststijl';

  @override
  String get paragraph => 'Alinea';

  @override
  String get heading1 => 'Kop 1';

  @override
  String get heading2 => 'Kop 2';

  @override
  String get heading3 => 'Kop 3';

  @override
  String get heading4 => 'Kop 4';

  @override
  String get heading5 => 'Kop 5';

  @override
  String get heading6 => 'Kop 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Tabel verwijderen';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Kolom $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Kolom links invoegen';

  @override
  String get insertColumnRight => 'Kolom rechts invoegen';

  @override
  String get deleteColumn => 'Kolom verwijderen';

  @override
  String get tableAlignmentUnspecified => 'Uitlijning: niet gespecificeerd';

  @override
  String get tableAlignmentLeft => 'Uitlijning: links';

  @override
  String get tableAlignmentCenter => 'Uitlijning: midden';

  @override
  String get tableAlignmentRight => 'Uitlijning: rechts';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Rij $rowNumber';
  }

  @override
  String get insertRowAbove => 'Rij erboven invoegen';

  @override
  String get insertRowBelow => 'Voeg rij hieronder in';

  @override
  String get deleteRow => 'Rij verwijderen';

  @override
  String get tableHeaderHint => 'Kolomkop';

  @override
  String get tableCellHint => 'Cel';

  @override
  String get language => 'Taal';

  @override
  String get hideEditingButtons => 'Bewerkingsknoppen verbergen';

  @override
  String get showEditingButtons => 'Toon bewerkingsknoppen';

  @override
  String get altText => 'Alt-tekst';

  @override
  String get editorPlaceholderText => 'tekst';

  @override
  String get editorPlaceholderCode => 'code';

  @override
  String get editorPlaceholderAltText => 'alternatieve tekst';

  @override
  String get describeTheImage => 'Beschrijf de afbeelding';

  @override
  String get columns => 'Kolommen';

  @override
  String get rows => 'Rijen';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Kolomkop $columnNumber';
  }

  @override
  String get tableCellDefault => 'Cel';

  @override
  String get noImageSource => 'Geen afbeeldingsbron';

  @override
  String get remoteImageBlocked => 'Externe afbeelding geblokkeerd';

  @override
  String get remoteImageBlockedTooltip =>
      'Kies of BusyMark externe afbeeldingen kan laden.';

  @override
  String get remoteImagesBlockedTitle =>
      'Externe afbeeldingen worden geblokkeerd';

  @override
  String get remoteImagesBlockedMessage =>
      'Dit document verwijst naar afbeeldingen van internet. Als u ze laadt, kan netwerkinformatie aan de afbeeldingshost worden onthuld.';

  @override
  String get loadRemoteImagesForWorkspace => 'Voor deze werkruimte laden';

  @override
  String get alwaysLoadRemoteImages => 'Externe afbeeldingen altijd laden';

  @override
  String get hideSidebar => 'Zijbalkpaneel verbergen';

  @override
  String get showSidebar => 'Zijbalkpaneel tonen';

  @override
  String get showPreview => 'Voorbeeld weergeven';

  @override
  String get hidePreview => 'Voorbeeld verbergen';

  @override
  String get workspaceKindUnsavedMarkdown => 'Niet-opgeslagen Markdown-bestand';

  @override
  String get workspaceKindSingleMarkdown => 'Eén Markdown-bestand';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown-map';

  @override
  String get workspaceKindWritersideModule => 'Writerside-module';

  @override
  String get problems => 'Problemen';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnoses',
      one: '1 diagnose',
      zero: 'Geen diagnoses',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Bestanden';

  @override
  String get toc => 'Inhoudsopgave';

  @override
  String get tocActions => 'TOC-acties';

  @override
  String get markdownUnsaved => 'Niet-opgeslagen Markdown';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bestanden',
      one: '1 bestand',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Geen bestanden';

  @override
  String get newFile => 'Nieuw bestand';

  @override
  String get noWritersideToc => 'Geen Writerside-inhoudsopgave';

  @override
  String get tocSection => 'TOC-sectie';

  @override
  String get newTopic => 'Nieuw onderwerp';

  @override
  String get newChildTopic => 'Nieuw onderliggend onderwerp';

  @override
  String get newSiblingTopic => 'Nieuw onderwerp';

  @override
  String get renameTopicFile => 'Onderwerpbestand hernoemen';

  @override
  String get topicPlacement => 'TOC-plaatsing';

  @override
  String get tocRoot => 'Bij TOC-root';

  @override
  String get afterSelectedTopic => 'Na geselecteerd onderwerp';

  @override
  String get insideSelectedTopic => 'Binnen geselecteerd onderwerp';

  @override
  String get pasteAfterTopic => 'Na onderwerp plakken';

  @override
  String get pasteAsChildTopic => 'Als onderliggend onderwerp plakken';

  @override
  String get removeFromToc => 'Verwijderen uit inhoudsopgave';

  @override
  String get confirmRemoveFromTocTitle => 'Verwijderen uit inhoudsopgave?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '$name verwijderen uit deze inhoudsopgave? Het onderwerpbestand wordt bewaard.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Onderwerpbestand verwijderen?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name verwijderen en uit elke inhoudsopgave verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get safeDeleteTopicFile => 'Onderwerpbestand veilig verwijderen…';

  @override
  String get removeTocElement => 'TOC-element verwijderen';

  @override
  String get removeTocElements => 'TOC-elementen verwijderen';

  @override
  String get reviewUsages => 'Gebruik controleren';

  @override
  String get deleteTopicFile => 'Onderwerpbestand verwijderen';

  @override
  String get removeAction => 'Verwijderen';

  @override
  String topicRemovalSummary(String topic) {
    return 'Inhoudsopgave-element ‘$topic’ verwijderen? Het bijbehorende bronbestand wordt niet verwijderd.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Verwijder “$topic” en werk de referenties veilig bij in dit Writerside-project.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count onderliggende onderwerpen worden één niveau hoger geplaatst.',
      one: '1 onderliggend onderwerp wordt één niveau hoger geplaatst.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning =>
      'Dit onderwerp is de startpagina van deze instantie. Kies een andere startpagina voordat u het uit de inhoudsopgave verwijdert.';

  @override
  String get newHomePage => 'Nieuwe startpagina';

  @override
  String get chooseHomePage => 'Startpagina kiezen';

  @override
  String get noHomePageReplacement =>
      'Voeg een ander geschikt onderwerp toe aan deze instantie of koppel het voordat u de startpagina verwijdert.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Dit onderwerp is de startpagina van een instantie. Stel een andere startpagina in voordat u het bronbestand verwijdert.';

  @override
  String topicUsagesCount(int count) {
    return '$count gebruikslocaties gevonden.';
  }

  @override
  String get noBreakingTopicUsages =>
      'Er zijn geen verwijzingen gevonden die kunnen worden verbroken.';

  @override
  String get topicUsagesFound =>
      'BusyMark heeft de volgende verwijzingen naar dit onderwerp gevonden.';

  @override
  String get topicUsageTocElements => 'TOC-elementen';

  @override
  String get topicUsageStartPages => 'Startpagina’s';

  @override
  String get topicUsageTopicLinks => 'Onderwerplinks';

  @override
  String get topicUsageIncludes => 'Include-elementen';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer gebruikt',
      one: '1 gebruik',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Refactoring-opties';

  @override
  String get updateUsagesAutomatically => 'Gebruik automatisch bijwerken';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Verwijder inhoudsopgavereferenties en -includes en behoud de linktekst.';

  @override
  String get manualUsageUpdatesRequired =>
      'Voor sommige verwijzingen zijn handmatige wijzigingen vereist voordat deze refactoring plaatsvindt.';

  @override
  String get setRedirectTo => 'Omleiding instellen naar:';

  @override
  String get noRedirectDescription =>
      'De oude, gepubliceerde pagina niet omleiden.';

  @override
  String get redirectTarget => 'Omleidingsdoel';

  @override
  String get remainingUsagesBlockRemoval =>
      'Controleer en werk de resterende verwijzingen bij voordat u doorgaat, of schakel automatische updates in als die beschikbaar zijn.';

  @override
  String usagesOfTopic(String topic) {
    return 'Gebruik van $topic';
  }

  @override
  String get noUsagesFound => 'Geen gebruik gevonden';

  @override
  String get outsideSelectedInstance => 'buiten de geselecteerde instantie';

  @override
  String get doRefactor => 'Refactoring uitvoeren';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get topicRenamePreviewTitle => 'Voorbeeld van naamswijziging';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Pad: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'Onderwerp-ID: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instantie $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Betrokken bestanden';

  @override
  String get orphanTopicTitle => 'Onderwerpbestand wordt niet meer gebruikt';

  @override
  String get keepTopicFile => 'Onderwerpbestand behouden';

  @override
  String orphanTopicMessage(String topic) {
    return '“$topic” wordt nergens meer gebruikt in dit Writerside-project. Verwijder het bestand of bewaar het voor gebruik in een andere instantie.';
  }

  @override
  String get defaultNewTopicTitle => 'Nieuw onderwerp';

  @override
  String get topicTitle => 'Onderwerptitel';

  @override
  String get fileName => 'Bestandsnaam';

  @override
  String get topicTitleRequired => 'Onderwerptitel is vereist.';

  @override
  String get fileNameRequired => 'Bestandsnaam is vereist.';

  @override
  String get rename => 'Hernoemen';

  @override
  String get confirmDeleteFileTitle => 'Bestand verwijderen?';

  @override
  String get confirmDeleteFolderTitle => 'Map verwijderen?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name en alle bestanden daarin verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get useSingleSafeFileName => 'Gebruik één veilige bestandsnaam.';

  @override
  String useExpectedExtension(String extension) {
    return 'Gebruik de extensie $extension voor het geselecteerde formaat.';
  }

  @override
  String get useIdentifierCharacters =>
      'Gebruik letters, cijfers, onderstrepingstekens of koppeltekens vóór de extensie.';

  @override
  String get topicIdAlreadyExists => 'Onderwerp-ID bestaat al.';

  @override
  String get createWritersideTopicFailed =>
      'Kan Writerside-onderwerp niet maken.';

  @override
  String get noOutline => 'Geen overzicht';

  @override
  String expandKind(String kind) {
    return 'Vouw $kind uit';
  }

  @override
  String collapseKind(String kind) {
    return '$kind samenvouwen';
  }

  @override
  String get foldKindSection => 'sectie';

  @override
  String get foldKindList => 'lijst';

  @override
  String get foldKindQuote => 'citaat';

  @override
  String get foldKindTag => 'label';

  @override
  String get sourceSearchPreviousMatch => 'Vorige overeenkomst';

  @override
  String get sourceSearchNextMatch => 'Volgende overeenkomst';

  @override
  String get sourceSearchReplacement => 'Vervangen door';

  @override
  String get sourceSearchReplaceCurrent => 'Vervang huidige overeenkomst';

  @override
  String get sourceSearchReplaceAndFindNext => 'Vervangen en volgende zoeken';

  @override
  String get sourceSearchReplaceAll => 'Vervang alles';

  @override
  String get workspaceReplace => 'Vervangen in werkruimte';

  @override
  String get reviewReplacements => 'Vervangingen controleren';

  @override
  String get applyReplacements => 'Vervangingen toepassen';

  @override
  String get skippedFiles => 'Overgeslagen bestanden';

  @override
  String get workspaceReplaceDirtyBuffer => 'Niet-opgeslagen editorinhoud';

  @override
  String get workspaceReplaceDiskContent => 'Opgeslagen schijfinhoud';

  @override
  String selectFileMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count overeenkomsten selecteren',
      one: '1 overeenkomst selecteren',
    );
    return '$_temp0';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$matches overeenkomsten in $files bestanden vervangen; $skipped overgeslagen.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Met afsluitende nieuwe regel';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Zonder afsluitende nieuwe regel';
  }

  @override
  String get normalizeLineEndings => 'Normaliseer regeleinden';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Dit document bevat gemengde regeleinden. Kies een formaat.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName gebruikt gemengde regeleinden. Kies het formaat dat u wilt gebruiken voordat u het vervangt.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Een te groot bestand overgeslagen.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Er is een bestand overgeslagen dat niet kon worden gelezen.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Er is een bestand overgeslagen dat geen geldige UTF-8 is.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Het vervangende voorbeeld is ingekort.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Een bestand overgeslagen dat na het voorbeeld is gewijzigd.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Er is een editorbuffer overgeslagen die na het voorbeeld is gewijzigd.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Kies LF- of CRLF-normalisatie voordat u vervangt.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Het terugdraaien is gestopt omdat het bestand tegelijkertijd is gewijzigd. Er kunnen enkele vervangingen overblijven; verplaatste inhoud werd bewaard op het onderstaande pad.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'De herziene vervanging kon niet worden vastgelegd; er zijn geen bestanden gewijzigd.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Externe wijzigingen — $fileName';
  }

  @override
  String get externalFileDeleted => 'Dit bestand is van schijf verwijderd.';

  @override
  String get externalFileChanged =>
      'Dit bestand is op schijf gewijzigd terwijl er niet-opgeslagen bewerkingen waren.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Niet-opgeslagen inhoud hersteld voor $fileName. Bekijk de inhoud en sla op, sla op als of verwerp.';
  }

  @override
  String get compare => 'Vergelijken';

  @override
  String get reloadFromDisk => 'Herladen vanaf schijf';

  @override
  String get keepMine => 'Mijn versie behouden';

  @override
  String get saveAs => 'Opslaan als';

  @override
  String get workspaceSearchIncomplete =>
      'Slechts een deel van de resultaten wordt getoond. Toon meer of verfijn de zoekopdracht.';

  @override
  String get workspaceSearchShowMore => 'Meer resultaten tonen';

  @override
  String get workspaceSearchSkippedFiles =>
      'De zoekopdracht is onvolledig. Deze bestanden zijn groter dan 1 MiB of konden niet worden gelezen:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Groot bestand: markeren en vouwen worden gepauzeerd';

  @override
  String get nothingToRead => 'Niets te lezen';

  @override
  String get admonition => 'Aandachtspunt';

  @override
  String get quote => 'Citaat';

  @override
  String get note => 'Opmerking';

  @override
  String get tip => 'Tip';

  @override
  String get warning => 'Waarschuwing';

  @override
  String get tabs => 'Tabbladen';

  @override
  String get tab => 'Tab';

  @override
  String get procedure => 'Procedure';

  @override
  String get step => 'Stap';

  @override
  String get topic => 'Onderwerp';

  @override
  String get chapter => 'Hoofdstuk';

  @override
  String couldNotOpenTarget(String target) {
    return 'Kon $target niet openen';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Linkdoel niet gevonden: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Kan dit bestandstype niet openen in de editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Anker niet gevonden: $anchor';
  }

  @override
  String get noProblemsFound => 'Geen problemen gevonden';

  @override
  String get noResults => 'Geen resultaten';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - Regel $lineNumber';
  }

  @override
  String get untitledResult => 'Naamloos resultaat';

  @override
  String get documentKindMarkdownFile => 'Markdown-bestand';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Writerside Markdown-onderwerp';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML-onderwerp';

  @override
  String get documentKindWritersideTree => 'Writerside-tree';

  @override
  String get documentKindConfigurationFile => 'Configuratiebestand';

  @override
  String get documentKindVariablesFile => 'Variabelenbestand';

  @override
  String get documentKindCategoriesFile => 'Categoriebestand';

  @override
  String get documentKindResourceFile => 'Bronbestand';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Recente items konden niet worden bijgewerkt: $error.';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Openen mislukt: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Kan Writerside-project niet maken: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Kan Writerside-onderwerp niet maken: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Kan bestand niet openen: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Kies waar u dit Markdown-bestand wilt opslaan.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Opslaan geblokkeerd: bestand gewijzigd op schijf.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Bestandsbewerking mislukt: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Validatie mislukt: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count niet-opgeslagen documenten zijn hersteld. Controleer elk document voordat u het opslaat of weggooit.',
      one:
          '1 niet-opgeslagen document is hersteld. Controleer het voordat u het opslaat of weggooit.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count beschadigde herstelrecords konden niet worden hersteld. Geldige herstelrecords blijven beschikbaar.',
      one:
          '1 beschadigd herstelrecord kon niet worden hersteld. Het oorspronkelijke herstelbestand is bewaard voor inspectie.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Pad bestaat niet: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Doelmap bestaat al en is niet leeg: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Doelpad bestaat al en is geen map: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Gegenereerd bestand bestaat al: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Bovenliggende map is vereist.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Bovenliggende map bestaat niet: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Map bestaat niet: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Pad bestaat al: $path';
  }

  @override
  String get errorFileNameRequired => 'Bestandsnaam is vereist.';

  @override
  String get errorFileNameUnsafe =>
      'De bestandsnaam moet uit één veilig padsegment bestaan.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Kan een map niet naar zichzelf verplaatsen.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Bestandsbewerkingen moeten binnen de werkruimte blijven.';

  @override
  String get errorFileOperationRoot =>
      'De hoofdmap van de werkruimte kan niet worden gewijzigd vanuit de bestandsboom.';

  @override
  String get errorProjectNameRequired => 'Projectnaam is vereist.';

  @override
  String get errorDirectoryNameRequired => 'Mapnaam is vereist.';

  @override
  String get errorDirectoryNameUnsafe =>
      'De mapnaam moet uit één veilig padsegment bestaan.';

  @override
  String get errorInstanceIdInvalid =>
      'De instantie-ID moet beginnen met een kleine letter en mag alleen kleine letters, cijfers, onderstrepingstekens en koppeltekens bevatten.';

  @override
  String get errorTopicFileInvalid =>
      'De onderwerpbestandsnaam moet een Markdown-bestandsnaam zijn zonder padscheidingstekens.';

  @override
  String get errorTopicTitleRequired => 'Onderwerptitel is vereist.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'De root van de Writerside-module bestaat niet: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Er moet een Writerside-module geopend zijn om een onderwerp te kunnen maken.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'De Writerside-module heeft geen instantieboom.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside-treebestand bestaat niet: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Onderwerp-ID \"$topicId\" bestaat al in deze helpmodule.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Onderwerpbestand bestaat al: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Referentieonderwerp is niet aanwezig in de geselecteerde boom: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Het geselecteerde TOC-item bestaat niet meer.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Een TOC-item kan niet naar zichzelf of naar een van zijn onderliggende items worden verplaatst.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'De startpagina $topic kan niet worden verwijderd. Kies eerst een andere startpagina.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Gebruik Veilig verwijderen voor Writerside-onderwerpbestanden.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Kan de onderwerpgebruikscan niet voltooien. Er zijn geen bestanden gewijzigd.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Sommige verwijzingen naar onderwerpen vereisen nog aandacht. Controleer ze voordat u verdergaat.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Het geselecteerde omleidingsdoel is niet langer geldig. Kies het opnieuw.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Het verwijderen van het onderwerp kan niet volledig worden teruggedraaid. Bekijk deze paden voordat u verdergaat: $paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Niet alle projectverwijzingen kunnen veilig worden bijgewerkt omdat $count topicbestand(en) in module $module niet zijn geparseerd: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside-projectbestanden bevatten niet-opgeslagen wijzigingen. Los deze op en maak een nieuw voorbeeld van de naamswijziging.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'De moduleset van het Writerside-project is gewijzigd. Maak vóór het refactoren een nieuw voorbeeld van de naamswijziging.';

  @override
  String get errorTopicsRootUnsafe =>
      'De hoofdmap van Onderwerpen moet een veilige relatieve map zijn.';

  @override
  String get errorTopicFileNameUnsafe =>
      'De onderwerpbestandsnaam moet uit één veilig padsegment bestaan.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'De onderwerpbestandsextensie moet overeenkomen met het geselecteerde formaat ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'De bestandsnaam van het onderwerp mag alleen letters, cijfers, onderstrepingstekens en koppeltekens bevatten.';

  @override
  String errorUnknown(String code) {
    return 'Onbekende fout: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Kan de metadata van het bestand niet lezen: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Grote werkruimte gedetecteerd. Sommige bestanden zijn overgeslagen om de app responsief te houden.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Kan werkruimte-item niet inspecteren: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Bestand is groter dan de limiet voor automatisch parseren van de bèta.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Kon het Markdown-bestand niet lezen: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Ongeldig opgemaakt kopattribuutblok in Writerside.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Dubbele kop-ID \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Extra H1-koppen op het hoogste niveau worden behandeld als hoofdstukken.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown-onderwerp heeft geen H1 of front matter-titel.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML-onderwerp mist titel.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Onderwerp \"$fileName\" mist een titel.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Frontmatter is niet afgesloten.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Onveilig HTML-element.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Linkdoel bestaat niet: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Anker \"$anchor\" bestaat niet.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Afbeelding \"$destination\" mist alt-tekst.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Afbeelding bestaat niet: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Ongeldige XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg root moet <ihp> zijn.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets-declaratie ontbreekt src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups-declaratie ontbreekt src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Niet-ondersteunde toetsenbordmodus: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Instance-declaratie ontbreekt src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg registreert geen instantie.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree root moet <instance-profile> zijn.';

  @override
  String get diagnosticWritersideTreeMissingId => 'Instantieprofiel mist ID.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Boombestandsstam komt niet overeen met instantie-ID \'$id\'.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Bij de niet-bibliotheekinstantie ontbreekt het attribuut start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Startpagina \"$startPage\" bestaat niet.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Onderwerp \"$topic\" komt meer dan één keer voor in de inhoudsopgave van deze instantie.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Variabeledeclaratie moet een naam en waarde hebben.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Variabele \"$name\" wordt meer dan één keer gedeclareerd.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'Categorie mist ID.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Categorie \"$id\" wordt meer dan één keer gedeclareerd.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Categorievolgorde \'$order\' wordt meer dan één keer gedeclareerd.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic root moet <topic> zijn.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML-onderwerp mist root-ID.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML-onderwerphoofd-id \"$id\" moet overeenkomen met de bestandsnaam \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Element-ID \"$elementId\" komt meerdere keren voor.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> mist href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Voor de Writerside-modus is writerside.cfg vereist.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'De geconfigureerde build-configuratiemap ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'De geconfigureerde map met API-specificaties ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'De map met geconfigureerde fragmenten ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Het geconfigureerde variabelenbestand ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Het geconfigureerde categorieënbestand ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Het geconfigureerde instantiegroepenbestand ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Geregistreerde instantiestructuur \"$source\" bestaat niet.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Kan onderwerpbestand niet lezen: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Standaard onderwerpenmap ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'De map met geconfigureerde onderwerpen ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Geconfigureerde afbeeldingenmap ontbreekt: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Element-ID \"$id\" komt meerdere keren voor.';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Instantie \"$instanceId\" publiceert de ongeldige webbestandsnaam \"$webFileName\" voor onderwerp \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Instantie \"$instanceId\" publiceert zowel \"$firstTopic\" als \"$secondTopic\" als \"$webFileName\".';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'De inhoudsopgave verwijst naar het ontbrekende onderwerp \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Externe href \"$href\" is ongeldig.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Variabele \"%$name%\" is niet gedeclareerd.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Onderwerplink \"$destination\" werkt niet.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Anker \"$anchor\" bestaat niet in \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'Het attribuut from ontbreekt in <include>.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Includebron \"$from\" bestaat niet.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Include-element \"$elementId\" bestaat niet in \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso-categorie \"$ref\" is niet gedeclareerd.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Onderwerpreferentie \"$reference\" is dubbelzinnig.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Onbekende diagnose: $code';
  }

  @override
  String get close => 'Sluiten';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git diff';

  @override
  String get gitShowDiff => 'Verschil tonen';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'oud $oldRange → nieuw $newRange';
  }

  @override
  String get gitDiffNoLines => 'geen regels';

  @override
  String get gitUnavailableTitle => 'Git is niet beschikbaar';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Installeer Git of configureer BusyMark om een beschikbaar Git-uitvoerbaar bestand te gebruiken. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Deze werkruimte vertrouwen voor Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Git-repository\'s kunnen programma\'s uitvoeren via hooks, filters en andere configuraties. Vertrouw deze werkruimte voordat BusyMark repositorygegevens leest of Git-acties inschakelt.';

  @override
  String get gitTrustWorkspace => 'Werkruimte vertrouwen';

  @override
  String get gitNotRepositoryTitle => 'Geen Git-repository';

  @override
  String get gitNotRepositoryMessage =>
      'Deze werkruimte bevindt zich niet in een Git-repository.';

  @override
  String get gitInitializeRepository => 'Git-repository initialiseren';

  @override
  String get gitDetachedHead => 'Losgekoppelde HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Vrijstaand bij $commit';
  }

  @override
  String get gitNoUpstream => 'Geen upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niet-gepushte commits',
      one: '1 niet-gepushte commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits om te pullen',
      one: '1 commit om te pullen',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Geen wijzigingen';

  @override
  String get gitConflicts => 'Conflicten';

  @override
  String get gitChanges => 'Wijzigingen';

  @override
  String get gitStaged => 'Gestaged';

  @override
  String get gitUnstaged => 'Niet-gestaged';

  @override
  String get gitHistory => 'Geschiedenis';

  @override
  String get gitBranches => 'Takken';

  @override
  String get gitActions => 'Git-acties';

  @override
  String get gitPull => 'Git pull';

  @override
  String get gitFetch => 'Git fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Voor commit selecteren';

  @override
  String get gitRemoveFromCommit => 'Bestand uit staging verwijderen';

  @override
  String get gitDiscard => 'Wijzigingen verwerpen';

  @override
  String get gitOpenFile => 'Bestand openen';

  @override
  String get gitMarkResolved => 'Als opgelost markeren';

  @override
  String get gitUntracked => 'Niet-getrackt';

  @override
  String get gitCommitMessage => 'Commitbericht';

  @override
  String get gitCommitSelectedFiles => 'Geselecteerde bestanden';

  @override
  String get gitCommitNoSelectedFiles =>
      'Stage ten minste één bestand voordat u commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gestagede bestanden',
      one: '1 gestaged bestand',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Buiten werkruimte';

  @override
  String get gitCommitMessageRequired => 'Voer een commit-bericht in.';

  @override
  String get gitCreateBranch => 'Branch maken';

  @override
  String get gitNewBranch => 'Nieuwe branch';

  @override
  String get gitBranchName => 'Branchnaam';

  @override
  String get gitSwitchBranch => 'Branch wisselen';

  @override
  String get gitNoChanges => 'Geen wijzigingen';

  @override
  String get gitNoHistory => 'Geen geschiedenis';

  @override
  String get gitNoBranches => 'Geen branches';

  @override
  String get gitNoDiff => 'Geen verschil om te laten zien';

  @override
  String get gitBinaryFile =>
      'Binair bestand. BusyMark geeft geen binaire patches weer.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Binair bestand ($size bytes). BusyMark geeft geen binaire patches weer.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Niet-opgeslagen editorwijzigingen worden pas opgenomen nadat ze zijn opgeslagen.';

  @override
  String get gitConfirmDiscardTitle => 'Git-wijzigingen verwerpen?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Alle gestagede en niet-gestagede wijzigingen in de geselecteerde getrackte bestanden worden teruggezet naar HEAD.',
      one:
          'Alle gestagede en niet-gestagede wijzigingen in het geselecteerde getrackte bestand worden teruggezet naar HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'De geselecteerde niet-getrackte bestanden worden verwijderd.',
      one: 'Het geselecteerde niet-getrackte bestand wordt verwijderd.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De geselecteerde bestanden worden teruggezet of verwijderd op basis van hun Git-status.',
      one:
          'Het geselecteerde bestand wordt teruggezet of verwijderd op basis van de Git-status.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Overstappen naar $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark laadt de werkruimte opnieuw vanaf schijf nadat Git van branch is gewisseld.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Upstream-branch instellen?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Deze branch heeft geen upstream. BusyMark kan $branch pushen en de upstream instellen als er precies één remote is geconfigureerd.';
  }

  @override
  String get gitProjectHistory => 'Projectgeschiedenis';

  @override
  String get gitFileHistory => 'Bestandshistorie';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Bestandsgeschiedenis vereist een geopend Markdown-bestand.';

  @override
  String get gitLoadMore => 'Meer laden';

  @override
  String get gitChangesInCommit => 'Wijzigingen in deze commit';

  @override
  String get gitCompareWithCurrent => 'Vergelijk met actueel';

  @override
  String get gitRestoreVersion => 'Herstel deze versie';

  @override
  String get gitConfirmRestoreTitle => 'Deze bestandsversie herstellen?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark vervangt het huidige werkboombestand door de geselecteerde vastgelegde versie. Het herstelde bestand blijft niet-gestaged.';

  @override
  String get gitCommitActions => 'Commitacties';

  @override
  String get gitResetCurrentBranchToHere =>
      'Huidige branch resetten naar hier…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Branch $branch resetten naar $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Dit verplaatst branch $branch naar commit $commit. Kies hoe Git de index en werkboom bijwerkt.';
  }

  @override
  String get gitReset => 'Resetten';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Verplaats alleen de branch. Houd de index en werkboom ongewijzigd; verschillen met de geselecteerde commit blijven gestaged.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Verplaats de branch en reset de index. Houd de werkboom ongewijzigd; de verschillen worden niet-gestaged.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Verplaats de branch en reset de index en werkboom. Wijzigingen in getrackte bestanden worden genegeerd; niet-getrackte bestanden die in de weg staan kunnen worden verwijderd.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Verplaats de branch en reset getrackte bestanden met behoud van lokale wijzigingen. Git wordt afgebroken als deze wijzigingen in conflict komen met de reset.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Bestandsacties';

  @override
  String get actions => 'Acties';

  @override
  String get gitStatusAdded => 'Toegevoegd';

  @override
  String get gitStatusDeleted => 'Verwijderd';

  @override
  String get gitStatusRenamed => 'Hernoemd';

  @override
  String get gitStatusCopied => 'Gekopieerd';

  @override
  String get gitStatusUntracked => 'Niet-getrackt';

  @override
  String get gitStatusConflicted => 'In conflict';

  @override
  String get gitStatusIgnored => 'Genegeerd';

  @override
  String get gitStatusTypeChanged => 'Soort gewijzigd';

  @override
  String get gitStatusModified => 'Gewijzigd';

  @override
  String get gitStatusUnknown => 'Onbekend';

  @override
  String get gitErrorUnavailable => 'Git is niet beschikbaar.';

  @override
  String get gitErrorNotRepository =>
      'Deze werkruimte is geen Git-opslagplaats.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark heeft een onveilig Git-pad geblokkeerd.';

  @override
  String get gitErrorInvalidBranchName => 'Voer een geldige branchnaam in.';

  @override
  String get gitErrorNoRemote => 'Er is geen Git-remote geconfigureerd.';

  @override
  String get gitErrorNoUpstream => 'Er is geen upstream-branch geconfigureerd.';

  @override
  String get gitErrorMultipleRemotes =>
      'Er zijn meerdere remotes geconfigureerd. Kies een upstream buiten deze versie van BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Sla wijzigingen in de BusyMark-editor op of verwerp ze voordat u van branch wisselt.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Sla wijzigingen in de BusyMark-editor op of verwerp ze voordat u de huidige branch reset.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Haal dit bestand eerst uit staging voordat u een historische versie herstelt.';

  @override
  String get gitErrorResetDetachedHead =>
      'Checkout eerst een branch voordat u deze reset.';

  @override
  String get gitErrorDiverged =>
      'De branches zijn uiteen gelopen. Los het samenvoegen of opnieuw baseren buiten deze versie van BusyMark op.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git heeft een auteursnaam en e-mailadres nodig voordat het kan committen.';

  @override
  String get gitAuthorIdentityTitle => 'Git-auteuridentiteit';

  @override
  String get gitAuthorIdentityMessage =>
      'Voer de identiteit in die Git moet vastleggen bij commits. BusyMark zal het opslaan en deze commit opnieuw proberen.';

  @override
  String get gitAuthorName => 'Naam';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Gebruik voor alle opslagplaatsen';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Als BusyMark als Snap is geïnstalleerd, geldt dit voor alle opslagplaatsen die in BusyMark worden geopend.';

  @override
  String get gitSaveIdentityAndCommit => 'Identiteit opslaan en committen';

  @override
  String get gitErrorAuthentication => 'Git-authenticatie is mislukt.';

  @override
  String get gitErrorNetwork => 'Git-netwerkbewerking is mislukt.';

  @override
  String get gitErrorConflict => 'Git rapporteerde onopgeloste conflicten.';

  @override
  String get gitErrorCommandFailed => 'Git-opdracht is mislukt.';

  @override
  String get syntaxReference => 'Syntaxisreferentie';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown-blokken';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Blokstructuren ondersteund in Markdown-bron en preview.';

  @override
  String get syntaxReferenceInlineFormatting => 'Inline-opmaak';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Opmaak die kan verschijnen in alinea\'s, lijstitems en tabelcellen.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Ruwe HTML-blokken';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Veilige HTML-tags op blokniveau weergegeven via BusyMark-voorbeeldwidgets.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Onbewerkte HTML-inlinetags';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Veilige inline HTML-tags weergegeven zonder letterlijke tags weer te geven.';

  @override
  String get syntaxReferenceHeadings => 'Koppen';

  @override
  String get syntaxReferenceParagraphs => 'Paragrafen';

  @override
  String get syntaxReferenceLists => 'Lijsten';

  @override
  String get syntaxReferenceHtmlContainers => 'Containers';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Tekstblokken';

  @override
  String get syntaxReferenceHtmlFigures => 'Figuren en afbeeldingen';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Voorgeformatteerde code';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Openklapbare blokken';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Beschrijvingslijsten';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Opmaaktags';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Inline codetags';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Semantische inline-tags';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'Toegestane HTML wordt geconverteerd naar BusyMark-voorbeeldblokken en niet weergegeven in een browser.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Ruwe HTML wordt exact als brontekst opgeslagen.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Markdown-markeringen in onbewerkte HTML worden weergegeven als letterlijke tekst.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Scripts, stijlen, frames, formulieren, SVG, MathML, gebeurtenissen en onveilige attributen worden geblokkeerd.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Links staan http-, https-, mailto-, tel-, relatieve en fragment-URL\'s toe; onveilige schema\'s worden geblokkeerd.';

  @override
  String get syntaxReferenceCategory => 'Categorie';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagrammen en API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Wiskunde';

  @override
  String get syntaxReferenceExample => 'Voorbeeld';

  @override
  String get syntaxReferenceIdentifiers => 'Identificatoren en aliassen';

  @override
  String get syntaxReferenceScope => 'Bereik';

  @override
  String get syntaxReferenceLimitation => 'BusyMark-beperking';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Officiële documentatie';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Alleen Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Alleen Writerside Markdown en Writerside XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'De belangrijkste Markdown-vormen die BusyMark kan schrijven en weergeven.';

  @override
  String get syntaxReferenceParagraphExample => 'Een alinea met tekst.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabellen gebruiken de pipe-syntaxis van GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'twee spaties aan het einde van de regel, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark accepteert een gerichte, veilige subset van ruwe HTML in Markdown-broncode.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Afgebakende Mermaid-, PlantUML-, D2- en OpenAPI-blokken werken in Markdown-broncode. Blokidentificatoren zijn niet hoofdlettergevoelig en BusyMark behoudt de oorspronkelijke spelling.';

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
      'Gebruik afgebakende YAML- of JSON-inhoud. BusyMark behandelt een willekeurig volledig YAML- of JSON-document niet als een OpenAPI-referentie.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Semantische codeblokken voor diagrammen';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Semantische code-block- en src-vormen ondersteunen Mermaid, PlantUML en D2, niet OpenAPI, en alleen binnen Writerside-projecten.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Diagrambron met verwijzing';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Paden moeten relatief zijn en binnen het geopende Writerside-project blijven; de afgebakende vorm met src is alleen voor Writerside Markdown.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark ondersteunt TeX-expressies, geen volledige TeX- of LaTeX-documenten.';

  @override
  String get syntaxReferenceInlineMath => 'Wiskunde in de regel';

  @override
  String get syntaxReferenceGithubMath =>
      'GitHub-wiskunde met dollar en backtick';

  @override
  String get syntaxReferenceDisplayMath => 'Wiskunde als blok';

  @override
  String get syntaxReferenceMathFence => 'math-blok';

  @override
  String get syntaxReferenceTexFence => 'tex-blok';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark herkent \\(...\\) en \\[...\\] niet als Markdown-wiskundescheidingstekens.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Buiten de Writerside-modus blijft een tex-blok een gewoon codeblok.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside-math-element';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'Het math-element is semantische Writerside-syntaxis, geen toegestane ruwe HTML MathML.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Semantisch TeX-codeblok';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Deze gerichte uitbreidingen worden alleen in geopende Writerside-projecten geïnterpreteerd.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Waarschuwingscitaat';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Een gewoon blokcitaat is een tip in Writerside Markdown; in gewone Markdown blijft het een normaal citaat.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Semantische waarschuwingen';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Gewone Markdown interpreteert deze semantische Writerside-elementen niet.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Inklapbare kop';

  @override
  String get syntaxReferenceCollapsibleCode => 'Inklapbaar codeblok';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Semantische inklapbare inhoud';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark ondersteunt inklapbare chapter-, procedure-, code-block- en definitielijstvormen, niet de volledige Writerside-catalogus.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Semantische codeblokken voor wiskunde en diagrammen';

  @override
  String get syntaxReferenceVideo => 'Writerside-video';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Lokale video gebruikt een lokale preview-src-afbeelding; gehoste bronnen moeten ondersteunde HTTPS-URL\'s van YouTube of Vimeo zijn.';

  @override
  String get exportAsPdf => 'Exporteren als PDF';

  @override
  String get pdfExportDescription =>
      'Kies de pagina-indeling voor een verzorgde, op zichzelf staande PDF.';

  @override
  String get pdfRemoteImagesNote =>
      'Externe afbeeldingen worden tijdens het exporteren niet gedownload. Lokale afbeeldingen zijn inbegrepen indien beschikbaar.';

  @override
  String get pdfPageSize => 'Paginagrootte';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => 'Oriëntatie';

  @override
  String get pdfPortrait => 'Portret';

  @override
  String get pdfLandscape => 'Landschap';

  @override
  String get pdfMargins => 'Marges';

  @override
  String get pdfMarginNarrow => 'Smal';

  @override
  String get pdfMarginNormal => 'Normaal';

  @override
  String get pdfMarginWide => 'Breed';

  @override
  String get pdfIncludePageNumbers => 'Voeg paginanummers toe';

  @override
  String get export => 'Exporteren';

  @override
  String get exportFormat => 'Uitvoerformaat';

  @override
  String get exportingPdf => 'PDF exporteren…';

  @override
  String get fileTypePdf => 'PDF-document';

  @override
  String pdfExported(String fileName) {
    return '$fileName is geëxporteerd.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waarschuwingen',
      one: '1 waarschuwing',
    );
    return '$fileName is geëxporteerd met $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'Het PDF-exportonderdeel ontbreekt. Installeer BusyMark opnieuw en probeer het opnieuw.';

  @override
  String get pdfExportTimedOut =>
      'De PDF-export duurde te lang en werd gestopt.';

  @override
  String get pdfExportFailed =>
      'BusyMark kon dit document niet als PDF exporteren.';

  @override
  String get visualizationRendering => 'Renderen…';

  @override
  String get visualizationStale => 'Laatste geldige weergave wordt getoond';

  @override
  String get visualizationShowSource => 'Bron tonen';

  @override
  String get visualizationShowRender => 'Render weergeven';

  @override
  String get visualizationFitWidth => 'Passend maken op breedte';

  @override
  String get visualizationSaveImage => 'Afbeelding opslaan';

  @override
  String get visualizationCopyImage => 'Afbeelding kopiëren';

  @override
  String get visualizationImageCopied => 'Afbeelding gekopieerd';

  @override
  String get visualizationOpenApiReference => 'Open API-referentie';

  @override
  String get visualizationValid => 'Geldig';

  @override
  String get visualizationInvalid => 'Ongeldig';

  @override
  String get visualizationServers => 'Servers';

  @override
  String get visualizationPaths => 'Paden';

  @override
  String get visualizationOperations => 'Operaties';

  @override
  String get visualizationTags => 'Labels';

  @override
  String get visualizationNoOperations => 'Geen overeenkomende bewerkingen';

  @override
  String get visualizationSearchOperations => 'Zoekbewerkingen';

  @override
  String get visualizationRenderFailed =>
      'Deze visualisatie kon niet worden weergegeven.';

  @override
  String get visualizationRetry => 'Opnieuw proberen';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName opgeslagen';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Exporteer het actieve document of de Writerside-module als PDF.';

  @override
  String get instances => 'Instanties';

  @override
  String get newInstance => 'Nieuwe instantie';

  @override
  String get newTocLibrary => 'Nieuwe TOC-bibliotheek';

  @override
  String get editInstance => 'Instantie bewerken';

  @override
  String get openTocFile => 'Inhoudsopgavebestand openen';

  @override
  String get createInstance => 'Instantie maken';

  @override
  String get createTocLibrary => 'TOC-bibliotheek maken';

  @override
  String get instanceContent => 'Inhoud';

  @override
  String get instanceContentSource => 'Maken vanuit';

  @override
  String get emptyInstance => 'Lege instantie';

  @override
  String get markdownFiles => 'Lokale Markdown-bestanden';

  @override
  String get chooseMarkdownFolder => 'Kies de Markdown-map';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Kies een map met Markdown-bestanden.';

  @override
  String get instanceAppearance => 'Uiterlijk';

  @override
  String get instanceColor => 'Pictogramkleur';

  @override
  String get instanceVersion => 'Versie';

  @override
  String instanceVersionInherited(String version) {
    return 'De projectversie is $version als dit veld leeg is.';
  }

  @override
  String get instanceWebPath => 'Webpad';

  @override
  String get instanceStatus => 'Status';

  @override
  String get instanceStatusRelease => 'Release';

  @override
  String get instanceStatusEap => 'EAP';

  @override
  String get instanceStatusDeprecated => 'Verouderd';

  @override
  String get allowSearchEngineIndexing => 'Sta zoekmachine-indexering toe';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Laat externe zoekmachines deze uitvoer indexeren.';

  @override
  String get offlineArtifact => 'Offline artefact';

  @override
  String get offlineArtifactDescription =>
      'Bundel bronnen zodat de gebouwde documentatie op zichzelf staat.';

  @override
  String get instanceOutputSettings => 'Uitvoerinstellingen';

  @override
  String get markdownImportSource => 'Markdown-bron';

  @override
  String get markdownImportFiles => 'Markdown-bestanden';

  @override
  String get selectNone => 'Selecteer geen';

  @override
  String markdownFilesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Markdown-bestanden gevonden',
      one: '1 Markdown-bestand gevonden',
    );
    return '$_temp0';
  }

  @override
  String get noMarkdownFilesFound =>
      'Er zijn geen Markdown-bestanden gevonden in deze map.';

  @override
  String get copyReferencedMedia => 'Kopieer de media waarnaar wordt verwezen';

  @override
  String get copyReferencedMediaDescription =>
      'Kopieer lokale afbeeldingen en video waarnaar door de geselecteerde bestanden wordt verwezen, terwijl de relatieve paden behouden blijven.';

  @override
  String get instanceIdRenameWarningTitle => 'Naam van instantie-ID wijzigen?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark hernoemt het .tree-bestand en werkt de Writerside-projectreferenties bij van “$oldId” naar “$newId”. Publicatiescripts worden niet gewijzigd en moeten afzonderlijk worden bijgewerkt.';
  }

  @override
  String get renameAndUpdateReferences => 'Hernoem en update referenties';

  @override
  String get tocLibraryDescription =>
      'Een TOC-bibliotheek slaat herbruikbare secties op en produceert geen eigen uitvoer.';

  @override
  String get defaultTocLibraryName => 'Gedeelde inhoudsopgave';

  @override
  String get instanceColorAutomatic => 'Automatisch';

  @override
  String get instanceColorBlue => 'Blauw';

  @override
  String get instanceColorGreen => 'Groen';

  @override
  String get instanceColorOrange => 'Oranje';

  @override
  String get instanceColorPurple => 'Paars';

  @override
  String get instanceColorRed => 'Rood';

  @override
  String get instanceColorTeal => 'Turkoois';

  @override
  String get instanceColorYellow => 'Geel';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Voer een instantienaam in.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Er bestaat al een instantie met ID “$id”.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'De instantiestructuur bestaat al: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'De Markdown-bronmap bestaat niet: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Selecteer ten minste één Markdown-bestand om te importeren.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Dit is geen leesbaar Markdown-bestand binnen de geselecteerde bron: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Importeren zou een bestaand projectbestand overschrijven: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Instantiebestanden gewijzigd op schijf. Bekijk ze en probeer het opnieuw.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark kon de wijziging aan de instantie niet volledig ongedaan maken. Controleer deze bestanden voordat u verdergaat: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Een inhoudsopgavebibliotheek kan geen Markdown-onderwerpen importeren.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Het webpad moet uit één regel bestaan.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'De Writerside-instantieconfiguratie is ongeldig. Corrigeer de diagnose en probeer het opnieuw.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark kon de wijzigingen aan de instantie niet veilig doorvoeren.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Onbekende instantiestatus \'$status\'. Gebruik release, eap of deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'De instantie-ID “$id” wordt door meer dan één boombestand gebruikt.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml moet een <buildprofiles> hoofdelement hebben.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'De waarde voor $name “$value” moet true of false zijn.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Een <build-profile>-element moet een instantie-ID specificeren.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Een boom <include> moet zowel from als element-id specificeren.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Een boom <snippet> moet een ID specificeren.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Een TOC-referentie tussen meerdere instanties moet zowel ref als in specificeren.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Een TOC-element kan niet meer dan één onderwerp, referentie, link of omleiding targeten.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Boomelement-ID “$id” wordt meer dan één keer gedeclareerd.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Het instantiegroepenbestand moet een hoofdelement <instance-groups> hebben.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Een instantiegroep moet een niet-lege ID en lijst met instanties opgeven.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Instantiegroep-ID \'$id\' wordt meer dan één keer gedeclareerd.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'TOC include “$source#$id” behoort tot de externe module “$origin” en kan niet worden uitgebreid in deze werkruimte.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Boomelement “$id” bestaat niet in de geregistreerde boom “$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Boom include “$source#$id” creëert een cyclus.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Instantievoorwaarde verwijst naar onbekende groep “@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Referentie voor meerdere instanties is gericht op onbekende instantie \'$instance\'.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Onderwerp “$topic” bevindt zich niet in de instantie waarnaar wordt verwezen “$instance”.';
  }

  @override
  String get download => 'Downloaden';

  @override
  String get exportWritersideAsPdf => 'Exporteer Writerside als PDF';

  @override
  String get writersidePdfContent => 'Inhoud exporteren';

  @override
  String get writersidePdfPage => 'Pagina';

  @override
  String get exportingWritersidePdf => 'Writerside-PDF exporteren...';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'Lokale Ollama';

  @override
  String get aiDisabled => 'Uitgeschakeld';

  @override
  String get aiExplicitEditingDescription =>
      'AI-bewerking is expliciet. BusyMark stuurt alleen de weergegeven context naar de geselecteerde provider en past nooit een voorstel toe zonder beoordeling.';

  @override
  String get aiProvider => 'AI-provider';

  @override
  String get aiDefaultProvider => 'Standaardprovider';

  @override
  String get aiConfigureProvider => 'Provider configureren';

  @override
  String get aiChooseProvider => 'Kies een AI-provider';

  @override
  String get aiOllamaEndpoint => 'Ollama-eindpunt';

  @override
  String get aiOllamaModel => 'Ollama-model';

  @override
  String get aiTestConnection => 'Verbinding testen';

  @override
  String get aiTestingConnection => 'Testen…';

  @override
  String aiConnectionReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geïnstalleerde modellen gevonden',
      one: '1 geïnstalleerd model gevonden',
    );
    return 'Verbonden. $_temp0.';
  }

  @override
  String get aiNoModels => 'Geen model geselecteerd.';

  @override
  String get aiConnectionFailed =>
      'BusyMark kon het genereren van AI-tekst niet verifiëren.';

  @override
  String get aiConfigureFirst =>
      'Schakel een AI-provider in en verifieer een model in Instellingen → AI.';

  @override
  String get aiEditWithAi => 'Bewerken met AI';

  @override
  String get aiRefineWithAi => 'Verfijn met AI';

  @override
  String get aiInstruction => 'Instructie';

  @override
  String get aiChangeTarget => 'Wat kan er veranderen';

  @override
  String get aiSharedContext => 'Context gedeeld met AI';

  @override
  String get aiTargetSelection => 'Geselecteerde inhoud';

  @override
  String get aiTargetInsertAfterBlock => 'Invoegen na huidig blok';

  @override
  String get aiTargetCurrentBlock => 'Huidig blok';

  @override
  String get aiTargetCurrentSection => 'Huidige sectie';

  @override
  String get aiTargetCompleteDocument => 'Volledig document';

  @override
  String get aiContextNone => 'Geen documentcontext';

  @override
  String get aiContextSelection => 'Geselecteerde inhoud';

  @override
  String get aiContextCurrentBlock => 'Huidig blok';

  @override
  String get aiContextCurrentSection => 'Huidige sectie';

  @override
  String get aiContextCompleteDocument => 'Volledig document';

  @override
  String get aiGenerating => 'Voorstel genereren…';

  @override
  String get aiProposal => 'AI-voorstel';

  @override
  String get aiGenerateProposal => 'Voorstel genereren';

  @override
  String aiContextDisclosure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tekens',
      one: '1 teken',
    );
    return 'De geselecteerde provider ontvangt $_temp0 uit de weergegeven context.';
  }

  @override
  String get aiOriginal => 'Origineel';

  @override
  String get aiSuggested => 'Voorgesteld';

  @override
  String get aiApplyProposal => 'Voorstel toepassen';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input invoertokens · $output uitvoertokens';
  }

  @override
  String get aiStaleProposal =>
      'Het document is gewijzigd terwijl dit voorstel werd gegenereerd. Voer de actie opnieuw uit.';

  @override
  String get gitAiStagedChangesChanged =>
      'De gestagede wijzigingen zijn gewijzigd terwijl dit commitbericht werd gegenereerd. Voer de actie opnieuw uit.';

  @override
  String get aiViewContext => 'Verzonden context bekijken';

  @override
  String get aiReviewExactContent => 'Controleer de exacte inhoud';

  @override
  String get aiContentToChange => 'Te wijzigen inhoud';

  @override
  String get aiContentSentToAi => 'Inhoud verzonden naar AI';

  @override
  String get aiApiKey => 'API-sleutel';

  @override
  String get aiApiKeyStoredHint =>
      'Er wordt een sleutel opgeslagen in het systeemreferentiearchief';

  @override
  String get aiApiKeyEnterHint => 'Voer de API-sleutel van de provider in';

  @override
  String get aiReplaceApiKey => 'Vervang de API-sleutel';

  @override
  String get aiSaveApiKey => 'API-sleutel veilig opslaan';

  @override
  String get aiRemoveApiKey => 'Opgeslagen API-sleutel verwijderen';

  @override
  String get aiCredentialSaved =>
      'API-sleutel opgeslagen in het systeemreferentiesarchief.';

  @override
  String get aiCredentialRemoved => 'De opgeslagen API-sleutel is verwijderd.';

  @override
  String get aiModelRouting => 'Modelroutering';

  @override
  String get aiAutomaticRouting => 'Automatisch per taak';

  @override
  String get aiFixedModelRouting => 'Gebruik het geselecteerde model';

  @override
  String get aiPreferredModel => 'Voorkeursmodel';

  @override
  String get aiModel => 'Model';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests verzoeken · $input invoertokens · $output uitvoertokens';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Inhoud naar $provider sturen?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Schakel $provider in';
  }

  @override
  String get aiCloudConsentMessage =>
      'Alleen de inhoud die in elk AI-beoordelingsdialoogvenster wordt weergegeven, wordt verzonden. Verzoeken zijn staatloos, voorstellen moeten worden beoordeeld en de API-sleutel wordt opgeslagen in het referentiearchief van het Linux-systeem.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Bevestig eerst het delen van gegevens door $provider in Instellingen → AI.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compatibele modellen zijn',
      one: '1 compatibel model is',
    );
    return 'Generatie geverifieerd met $model. $_temp0 beschikbaar.';
  }

  @override
  String get aiColdStartObserved =>
      'Er werd een lokale koude start waargenomen.';

  @override
  String get aiNoCompatibleModels =>
      'Er is geen compatibel model voor tekstgeneratie beschikbaar.';

  @override
  String get aiEnableProvider => 'Schakel eerst een AI-provider in.';

  @override
  String get aiDraftCommitMessage => 'Concept commit-bericht';

  @override
  String get aiDrafting => 'Opstellen…';

  @override
  String get aiDraftWithAi => 'Met AI opstellen';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Kopniveau $level volgt niveau $previousLevel; controleer de nesting van secties.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Linktekst is leeg. Geef een toegankelijke naam op die het doel ervan beschrijft.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Controleer of de linktekst “$text” het doel ervan in de context beschrijft.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'De cellen van de tabelkop moeten hun kolommen identificeren; voltooi elke lege kop.';

  @override
  String get mathRenderFailed =>
      'De wiskundige uitdrukking kon niet worden weergegeven.';

  @override
  String get inlineMath => 'Inline wiskunde';

  @override
  String get displayMath => 'Wiskunde weergeven';

  @override
  String get goToDeclaration => 'Ga naar declaratie';

  @override
  String get findUsages => 'Gebruik zoeken';

  @override
  String get cannotRenameSymbol =>
      'Het symbool kan niet veilig worden hernoemd. Controleer de naam en vernieuw de verwijzing voordat u het opnieuw probeert.';

  @override
  String get renameTopicFileInstead =>
      'Onderwerp-ID\'s zijn afgeleid van de bestandsnamen. Gebruik Onderwerpbestand hernoemen in de inhoudsopgave of de zijbalk Bestanden.';

  @override
  String get keyboardLayout => 'Toetsenbordindeling';

  @override
  String get diagnosticWritersideUnsupported =>
      'Niet-ondersteunde of ongeldige inhoud wordt als broncode getoond.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Bron ‘$reference’ kan niet worden gevonden: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Het linkdoel is niet beschikbaar in deze instantie: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Ongeldige Writerside-opmaak: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Gebruik <llms-txt>true</llms-txt> of <llms-txt>false</llms-txt>; single-file wordt niet meer ondersteund.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '$kind kan niet worden gevonden: $reference';
  }

  @override
  String get exportAsHtml => 'Exporteren als HTML…';

  @override
  String get fileTypeHtml => 'HTML-document';

  @override
  String get exportingHtml => 'HTML exporteren…';

  @override
  String get htmlExported => 'HTML-export voltooid';

  @override
  String get htmlExportFailed => 'HTML-export mislukt';

  @override
  String get htmlKeepAssetsTogether =>
      'Houd het HTML-bestand en de bijbehorende middelenmap bij elkaar wanneer u deze export kopieert.';

  @override
  String get htmlInstanceDescription =>
      'Exporteer één instantie als gekoppelde offline pagina’s. Kies een naam voor een aparte uitvoermap.';

  @override
  String get htmlInstance => 'Instantie';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Alleen een map die door BusyMark HTML-export is gemaakt kan worden vervangen. Gewijzigde of andere bestanden blijven behouden.';

  @override
  String get showInFolder => 'Tonen in map';

  @override
  String sortTableColumn(String column) {
    return '$column sorteren';
  }

  @override
  String get exportReset => 'Standaardwaarden herstellen';

  @override
  String get exportToc => 'Inhoudsopgave opnemen';

  @override
  String get exportTocDepth => 'Diepte inhoudsopgave';

  @override
  String get exportNumberHeadings => 'Koppen nummeren';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Aangepast';

  @override
  String get exportPageWidth => 'Paginabreedte (mm)';

  @override
  String get exportPageHeight => 'Paginahoogte (mm)';

  @override
  String get exportMarginTop => 'Bovenmarge (mm)';

  @override
  String get exportMarginRight => 'Rechtermarge (mm)';

  @override
  String get exportMarginBottom => 'Ondermarge (mm)';

  @override
  String get exportMarginLeft => 'Linkermarge (mm)';

  @override
  String get exportTypography => 'Typografie';

  @override
  String get exportSans => 'Schreefloos';

  @override
  String get exportSerif => 'Met schreef';

  @override
  String get exportBodySize => 'Tekstgrootte';

  @override
  String get exportCodeSize => 'Codegrootte';

  @override
  String get exportRunningText => 'Kop- en voettekst';

  @override
  String get exportHeader => 'Koptekst';

  @override
  String get exportFooter => 'Voettekst';

  @override
  String get exportNone => 'Geen';

  @override
  String get exportDocumentTitle => 'Documenttitel';

  @override
  String get exportBottomLeft => 'Linksonder';

  @override
  String get exportBottomCenter => 'Middenonder';

  @override
  String get exportBottomRight => 'Rechtsonder';

  @override
  String get exportFirstPage => 'Kop- en voettekst op de eerste pagina tonen';

  @override
  String get exportAccent => 'Accent-/linkkleur';

  @override
  String get exportTheme => 'Thema';

  @override
  String get exportAutomatic => 'Automatisch';

  @override
  String get exportLayout => 'Indeling';

  @override
  String get exportContentWidth => 'Maximale inhoudsbreedte';

  @override
  String get exportOutput => 'Uitvoer';

  @override
  String get exportPackaging => 'Verpakking';

  @override
  String get exportSingleFile => 'Eén HTML-bestand';

  @override
  String get exportAssetsDirectory => 'HTML + middelenmap';

  @override
  String get exportCustomCss => 'Aangepast stijlblad…';

  @override
  String get exportRemoveCss => 'Aangepast stijlblad verwijderen';

  @override
  String get exportCssNote =>
      'Kies een optioneel UTF-8-CSS-bestand (maximaal 256 KiB). Imports, bron-URL’s en uitvoerbare of ontsnapte CSS worden geweigerd. De stijlen volgen die van BusyMark. Externe bronnen worden nooit opgehaald.';

  @override
  String get exportSitePackagingNote =>
      'Writerside behoudt aparte gekoppelde onderwerppagina’s. De enkelbestandsmodus sluit bronnen in elke pagina in.';

  @override
  String get exportInvalidGeometry =>
      'Laat na de marges minimaal 20 mm inhoudsbreedte en -hoogte over.';

  @override
  String get exportInvalidColor => 'Voer een kleur in als #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Kies een leesbaar UTF-8 .css-bestand tot 256 KiB zonder imports, bron-URL’s, HTML of uitvoerbare of ontsnapte CSS.';

  @override
  String get clipboardHistory => 'Historie van de klembord';

  @override
  String get clipboardHistoryDescription =>
      'Open de klembordgeschiedenis per sessie.';

  @override
  String get clipboardCurrent => 'Huidig klembord';

  @override
  String get clipboardCurrentExternal =>
      'Huidig klembord van een ander programma';

  @override
  String clipboardDestination(String name) {
    return 'Plakken in $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Alleen opgeslagen voor deze BusyMark sessie.';

  @override
  String get clipboardNoItems => 'De klembordgeschiedenis is leeg.';

  @override
  String get clipboardDisabled =>
      'De collectie \"Historie van het klembord\" is uitgeschakeld in de instellingen.';

  @override
  String get clipboardUnavailable =>
      'De inhoud van het huidige klembord is niet beschikbaar of niet ondersteund.';

  @override
  String get clipboardTooLarge =>
      'Dit item op het klembord is te groot om te bewaren.';

  @override
  String get clipboardPastePlainText => 'Plak als gewone tekst';

  @override
  String get clipboardClearAll => 'Maak de geschiedenis van het klembord leeg';

  @override
  String get clipboardEntryText => 'Tekst';

  @override
  String get clipboardEntryRichText => 'Rijke tekst';

  @override
  String get clipboardEntryImage => 'Afbeelding';

  @override
  String clipboardOrigin(String name) {
    return 'Geplakt van $name';
  }

  @override
  String get localHistory => 'Lokale geschiedenis';

  @override
  String get localHistoryEllipsis => 'Lokale geschiedenis…';

  @override
  String get localHistoryDescription =>
      'Toon opgeslagen en automatische lokale revisies voor het huidige document.';

  @override
  String get findLocalHistoryEllipsis => 'Zoeken in Lokale Geschiedenis…';

  @override
  String get findLocalHistoryDescription =>
      'Zoek naar documenten en inhoud van revisies in de lokale geschiedenis.';

  @override
  String get localHistoryNoDocuments =>
      'Er zijn nog geen documenten met Lokale Geschiedenis.';

  @override
  String get localHistoryNoRevisions =>
      'Dit document heeft geen revisies van de Lokale Geschiedenis.';

  @override
  String get localHistorySelectedRevision => 'Geselecteerde revisie';

  @override
  String get localHistoryCurrentEditor => 'Huidige inhoud van de editor';

  @override
  String get localHistoryCurrentDisk => 'Huidige inhoud op schijf';

  @override
  String get localHistoryMissingFile => 'Het originele bestand ontbreekt.';

  @override
  String get localHistoryRestoreRevision => 'Herstel Versie';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Herstel naar Originele Locatie';

  @override
  String get localHistoryRestoreNewLocation => 'Herstel naar Nieuwe Locatie…';

  @override
  String get localHistoryRestoreChange => 'Herstel Wijziging';

  @override
  String get localHistoryRestoreUnavailable =>
      'Deze wijziging kan niet worden hersteld omdat de vergelijking niet meer actueel is.';

  @override
  String get localHistoryComparisonSimplified =>
      'Deze grote vergelijking is vereenvoudigd. Het herstellen van individuele wijzigingen is niet mogelijk.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Oudere versie wijziging: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Huidige inhoud wijziging: $text';
  }

  @override
  String get localHistoryDeleted => 'Verwijderd';

  @override
  String get localHistoryUntitled => 'Onbenoemd';

  @override
  String get localHistoryClearDocument =>
      'Verwijder de geschiedenis van dit document';

  @override
  String get localHistoryClearAll => 'Verwijder de lokale geschiedenis';

  @override
  String get localHistoryClearDocumentTitle =>
      'Verwijder de documentgeschiedenis?';

  @override
  String get localHistoryClearAllTitle => 'Verwijder de lokale geschiedenis?';

  @override
  String get localHistoryClearConfirmation =>
      'Dit verwijdert permanent opgeslagen revisies. Deze actie kan niet worden teruggedraaid.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'De index van de lokale geschiedenis is beschadigd en opnieuw gebouwd vanuit intacte revisies.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Deze lokale geschiedenisopslag gebruikt een onondersteunde $version-formaat.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'De lokale geschiedenis is niet beschikbaar: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Opnemen is uitgeschakeld of deze pad is uitgesloten. Schakel opnemen opnieuw in voordat u herstelt.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'De lokale geschiedenis kon de padwijziging niet opslaan: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Lokale Geschiedenis kon de verwijderde pad niet opslaan: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'De geselecteerde versie ontbreekt of is beschadigd.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'De geselecteerde versie kan niet worden gelezen: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Lokale Geschiedenis kon deze versie niet vastleggen: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Basislijn';

  @override
  String get localHistoryReasonSaved => 'Bewaard';

  @override
  String get localHistoryReasonAutomaticCheckpoint =>
      'Automatische controlepunt';

  @override
  String get localHistoryReasonBeforeReload => 'Voor herladen';

  @override
  String get localHistoryReasonBeforeDiscard => 'Voor verwijderen';

  @override
  String get localHistoryReasonBeforeRestore => 'Voordat herstellen';

  @override
  String get localHistoryReasonBeforeDelete => 'Voordat verwijderen';

  @override
  String get localHistoryReasonExternalChange => 'Externe wijziging';

  @override
  String get settingsHistory => 'Geschiedenis';

  @override
  String get settingsClipboardHistoryTitle =>
      'Verzamelen van de geschiedenis van de klembord';

  @override
  String get settingsClipboardHistoryDescription =>
      'Behoud van gekopieerd en succesvol geplakt materiaal alleen voor deze BusyMark sessie.';

  @override
  String get settingsLocalHistoryTitle => 'Opnemen van lokale geschiedenis';

  @override
  String get settingsLocalHistoryDescription =>
      'Opslaan van documentversies op dit apparaat voor herstel en vergelijking.';

  @override
  String get settingsHistoryCheckpoint =>
      'Automatische interval voor controlepunten';

  @override
  String get settingsHistoryRetention => 'Bewaarperiode';

  @override
  String get settingsHistoryStorage => 'Maximale opslag';

  @override
  String get settingsHistoryExcludedPaths => 'Uitsluitingen';

  @override
  String get settingsHistoryExcludedPathsHint => 'Eén absolute pad per regel';

  @override
  String settingsSecondsValue(int value) {
    return '$value seconden';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value dagen';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Spellingcontrole';

  @override
  String get automaticSpelling => 'Spelling automatisch controleren';

  @override
  String get defaultSpellingLanguage => 'Standaardtaal voor spelling';

  @override
  String get projectSpellingLanguage => 'Projecttaal voor spelling';

  @override
  String get chooseSpellingLanguage => 'Taal voor spelling kiezen';

  @override
  String get spellingLanguageUnsetStatus => 'Taal…';

  @override
  String get spellingOffStatus => 'Spelling uit';

  @override
  String get checkSpelling => 'Spelling controleren';

  @override
  String get ignoreSpellingOnce => 'Eenmaal negeren';

  @override
  String get ignoreSpellingDocument => 'Alles in dit document negeren';

  @override
  String get addPersonalSpellingWord => 'Aan persoonlijk woordenboek toevoegen';

  @override
  String get addProjectSpellingWord => 'Aan projectwoordenboek toevoegen';

  @override
  String get inheritSpellingLanguage => 'Project- of toepassingstaal gebruiken';

  @override
  String get disableDocumentSpelling => 'Spelling niet controleren';

  @override
  String get importSpellingDictionary => 'Woordenboek importeren';

  @override
  String get personalSpellingDictionary => 'Persoonlijk woordenboek';

  @override
  String get projectSpellingDictionary => 'Projectwoordenboek';

  @override
  String get noSpellingErrors => 'Geen spelfouten';

  @override
  String get noSpellingSuggestions => 'Geen spellingsuggesties';

  @override
  String get spellingWordCheckFailed =>
      'Dit woord kon niet worden gecontroleerd';

  @override
  String get spellingCheckFailed => 'Spellingcontrole mislukt';

  @override
  String get spellingSettingsLoadFailed =>
      'Instellingen voor spellingcontrole konden niet worden geladen';

  @override
  String get retrySpellingSettings =>
      'Instellingen voor spellingcontrole opnieuw laden';

  @override
  String get spellingCheckIncomplete => 'De spellingcontrole is onvolledig';

  @override
  String get spellingDictionaryNotInstalled => 'Woordenboek niet geïnstalleerd';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Het woordenboek voor $dictionary is niet geïnstalleerd';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Niet geïnstalleerd · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Geïnstalleerd';

  @override
  String get installSpellingDictionary => 'Woordenboek installeren';

  @override
  String get removeSpellingDictionary => 'Woordenboek verwijderen';

  @override
  String get cancelSpellingDictionaryInstall =>
      'Download van woordenboek annuleren';

  @override
  String get retrySpellingDictionaryInstall =>
      'Installatie van woordenboek opnieuw proberen';

  @override
  String spellingDictionaryDownloading(String size) {
    return '$size downloaden…';
  }

  @override
  String get spellingDictionaryValidating => 'Woordenboek valideren…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Installatie mislukt — selecteer om opnieuw te proberen';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '$dictionary ($size) installeren? Daarna blijft het offline beschikbaar totdat u het verwijdert.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Woordenboek niet beschikbaar';

  @override
  String get spellingChecking => 'Spelling controleren…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: voer een getal tussen $minimum en $maximum in.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Het spellingwoordenboek is extern gewijzigd. Er is een herstelkopie bewaard.';

  @override
  String get windowMinimize => 'Minimaliseren';

  @override
  String get windowMaximize => 'Maximaliseren';

  @override
  String get windowRestore => 'Herstellen';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Verbinden';

  @override
  String get nextcloudReconnect => 'Opnieuw verbinden';

  @override
  String get nextcloudDisconnect => 'Verbinding verbreken';

  @override
  String get nextcloudServer => 'Server-URL';

  @override
  String get nextcloudSignInBrowser => 'Voltooi het aanmelden in uw browser.';

  @override
  String get nextcloudFavorites => 'Favorieten';

  @override
  String get nextcloudNewNote => 'Nieuwe notitie';

  @override
  String get nextcloudSavedLocally =>
      'Lokaal opgeslagen · synchronisatie in behandeling';

  @override
  String get nextcloudSyncing => 'Synchroniseren';

  @override
  String get nextcloudSynced => 'Gesynchroniseerd';

  @override
  String get nextcloudOffline => 'Geen verbinding';

  @override
  String get nextcloudLocked => 'Vergrendeld door server';

  @override
  String get nextcloudReconnectRequired => 'Opnieuw verbinden vereist';

  @override
  String get nextcloudCreationUncertain => 'Resultaat van aanmaken onzeker';

  @override
  String get nextcloudReadOnly => 'Alleen lezen';

  @override
  String get nextcloudTakeRemote => 'Externe versie gebruiken';

  @override
  String get nextcloudMerge => 'Samenvoegen';

  @override
  String get nextcloudDeleteNote => 'Notitie verwijderen?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Vervangen in de werkruimte is niet beschikbaar voor Nextcloud Notes. Vervang binnen elke notitie.';

  @override
  String get nextcloudSaveLocalCopy => 'Lokale kopie opslaan…';

  @override
  String get nextcloudDisconnectWarning =>
      'Dit account verwijderen wist de opgeslagen notities en wijzigingen in behandeling op dit apparaat. Synchroniseer eerst om dit werk op de server te bewaren.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Als de vorige upload is gelukt, kan opnieuw proberen een ongebruikte bijlage op de server achterlaten.';

  @override
  String get nextcloudAttachmentReference => 'Bijlageverwijzing op de server';

  @override
  String get nextcloudAddAttachment => 'Bijlage toevoegen…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Als u deze bijlage verwijdert, zijn de links ernaar in de notitie niet meer beschikbaar. Bewaarde gegevens kunnen via de lokale geschiedenis worden hersteld.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Kies voor elk conflicterend kenmerk een waarde.';

  @override
  String get nextcloudUseServerNote => 'Deze servernotitie gebruiken';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Koppelt dit concept aan de geselecteerde servernotitie en synchroniseert daarna de behouden lokale wijzigingen. Een overeenkomend verzoek bevestigt niet wie de notitie heeft gemaakt.';

  @override
  String get nextcloudExactCandidate =>
      'Exacte overeenkomst met het verzoek; identiteit onbevestigd.';

  @override
  String get nextcloudPossibleCandidate =>
      'Mogelijke overeenkomst na normalisatie; identiteit onbevestigd.';

  @override
  String get nextcloudSelectCandidate =>
      'Selecteer een servernotitie om te bekijken';

  @override
  String get nextcloudCreateSeparate => 'Een afzonderlijke notitie maken';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Het eerste verzoek heeft mogelijk al een servernotitie gemaakt. Dit maakt een afzonderlijke notitie met uw behouden lokale werk. Vermoedelijke duplicaten worden niet verwijderd.';

  @override
  String get wsSemanticFormats => 'Semantische opmaak';

  @override
  String get wsUiControl => 'UI-besturingselement';

  @override
  String get wsFilePath => 'Bestand / Pad';

  @override
  String get wsUiPath => 'UI-pad';

  @override
  String get wsDefinitionList => 'Definitielijst';

  @override
  String get wsIncludeContent => 'Herbruikbare inhoud opnemen';

  @override
  String get wsVariableReference => 'Variabelereferentie';

  @override
  String get wsConvertList => 'Lijst omzetten naar procedure';

  @override
  String get wsElementProperties => 'Elementeigenschappen';

  @override
  String get wsTopicProperties => 'Onderwerpeigenschappen';

  @override
  String get wsCollapsible => 'Inklapbaar';

  @override
  String get wsPublishedState => 'Gepubliceerde beginstatus';

  @override
  String get wsExpanded => 'Uitgeklapt';

  @override
  String get wsCollapsed => 'Ingeklapt';

  @override
  String get wsCollapsedTitle => 'Ingeklapte titel';

  @override
  String get wsTerm => 'Begrip';

  @override
  String get wsListLayout => 'Lijstindeling';

  @override
  String get wsSyncGroup => 'Synchronisatiegroep';

  @override
  String get wsTabKey => 'Tabsleutel';

  @override
  String get wsSwitcherLabel => 'Schakelaarlabel';

  @override
  String get wsNavigationElements => 'Navigatie-elementen';

  @override
  String get wsNavigationDepth => 'Navigatiediepte';

  @override
  String get wsAddItem => 'Item toevoegen';

  @override
  String get wsStep => 'Stap';

  @override
  String get wsPropertyInvalid => 'Ongeldige eigenschapswaarde';

  @override
  String get wsFilter => 'Inhoudsfilter';

  @override
  String get wsIdentifier => 'Element-ID';

  @override
  String get wsTldr => 'Samenvatting (TLDR)';

  @override
  String get wsFullLayout => 'Volledige breedte';

  @override
  String get wsMediumLayout => 'Gemiddeld (1:2)';

  @override
  String get wsNarrowLayout => 'Smalle begripskolom';

  @override
  String get wsTitle => 'Titel';

  @override
  String get wsSwitcherKey => 'Keuzeschakelaar';

  @override
  String get nextcloudServerSettings => 'Notes-instellingen op de server';

  @override
  String get nextcloudNotesPath => 'Pad van de notitiemap';

  @override
  String get nextcloudFileSuffix => 'Bestandsextensie voor nieuwe notities';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Deze Notes-instellingen gelden ook voor andere clients. Een ander pad verplaatst geen bestanden; een andere extensie hernoemt bestaande notities niet.';

  @override
  String get nextcloudSettingsSaved => 'Serverinstellingen opgeslagen';

  @override
  String get nextcloudSettingsNormalized =>
      'Opgeslagen met door de server genormaliseerde waarden';

  @override
  String get nextcloudPendingUpload => 'Bijlage wacht op upload';

  @override
  String nextcloudServerCheck(String time) {
    return 'Laatste servercontrole: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Serverinstellingen laden';

  @override
  String get nextcloudSettingsSaving => 'Serverinstellingen opslaan';

  @override
  String get nextcloudPreviousLocalEdit => 'Vorige lokale wijziging';

  @override
  String get nextcloudUsePreviousEdit => 'Vorige wijziging gebruiken';

  @override
  String get quickOpen => 'Snel openen';

  @override
  String get notesAll => 'Alle notities';

  @override
  String get notesUncategorized => 'Zonder categorie';

  @override
  String get notesRecovery => 'Herstel';

  @override
  String get notesRecentlyEdited => 'Recent bewerkt';

  @override
  String get notesOldestEdited => 'Oudste bewerking';

  @override
  String get notesTitleAscending => 'Titel A–Z';

  @override
  String get notesTitleDescending => 'Titel Z–A';

  @override
  String get notesMove => 'Naar categorie verplaatsen';

  @override
  String get notesRemoveFavorite => 'Favoriet verwijderen';

  @override
  String get notesOffline => 'Offline beschikbaar maken';

  @override
  String get notesOfflineRemove => 'Offlinebewaring verwijderen';

  @override
  String get notesIndexing => 'Notities indexeren…';

  @override
  String get notesSearchHelp =>
      'Termen gebruiken EN. Gebruik \"geciteerde zinnen\", title: en category:.';

  @override
  String get notesSourceLocation => 'Bronlocatie';

  @override
  String get notesRecoveryHelp =>
      'Alleen bewaarde lokale notities en lokale geschiedenis. Prullenbak en geschiedenis van de server zijn niet beschikbaar.';

  @override
  String get notesImport => 'Notities importeren';

  @override
  String get notesExport => 'Notities exporteren';

  @override
  String get notesImportDistinct => 'Als afzonderlijke notitie importeren';

  @override
  String get notesAvailableOffline => 'Offline beschikbaar';

  @override
  String get notesIncomplete => 'Onvolledig';

  @override
  String get notesSelected => 'Geselecteerde notities';

  @override
  String get notesNoHistory =>
      'Geen bewaarde revisies. Geschiedenis kan uitgeschakeld, verlopen of gewist zijn.';

  @override
  String get notesTextAvailable => 'Tekst lokaal beschikbaar';

  @override
  String get notesLocalVersion => 'Lokale werkversie';

  @override
  String get notesAttachments => 'Bijlagen';

  @override
  String get notesSkipped => 'Overgeslagen';

  @override
  String get notesFailed => 'Mislukt';

  @override
  String get notesCompleted => 'Voltooid';

  @override
  String get notesImportNew => 'Nieuwe import starten';

  @override
  String get notesImportResume => 'Onderbroken import hervatten';

  @override
  String get notesImportAlreadyImported => 'Al geïmporteerd in deze bewerking';

  @override
  String get references => 'Verwijzingen';

  @override
  String get referenceIncoming => 'Inkomend';

  @override
  String get referenceOutgoing => 'Uitgaand';

  @override
  String get referenceChooseTarget => 'Linkdoel kiezen';

  @override
  String get referenceWholeDocument => 'Heel document';

  @override
  String get referenceSourceLocation => 'Bronlocatie';

  @override
  String get referenceTargetLocation => 'Doellocatie';

  @override
  String get referenceResolved => 'Opgelost';

  @override
  String get referenceMissing => 'Ontbreekt';

  @override
  String get referenceAmbiguous => 'Dubbelzinnig';

  @override
  String get referenceUnavailable => 'Niet beschikbaar in deze context';

  @override
  String get referenceUnsupported => 'Niet ondersteund';

  @override
  String get referenceNoPortableId =>
      'Dit doel heeft geen geverifieerde overdraagbare notitie-URL.';

  @override
  String get wsIncludeLines => 'Regels opnemen';

  @override
  String get wsIncludeSymbol => 'Symbool opnemen';

  @override
  String get wsEmphasizeLines => 'Weergegeven regels markeren';

  @override
  String get wsPropertiesReadOnly =>
      'Eigenschappen zijn alleen-lezen in deze weergave.';

  @override
  String get wsPropertiesProtected =>
      'Dit element is beschermd. Bewerk de bron.';

  @override
  String get wsPropertiesConflict =>
      'Document of element gewijzigd. Herstel het concept en selecteer opnieuw.';

  @override
  String get wsPropertiesUnresolved =>
      'De verwijzing kan momenteel niet worden opgelost.';

  @override
  String get wsUseDefault => 'Standaard gebruiken';

  @override
  String get wsPropertiesSelection => 'Selecteer één element.';

  @override
  String get wsImageDisplay => 'Afbeeldingsweergave';

  @override
  String get wsImageThumbnail => 'Klikbare miniatuur';

  @override
  String get wsEnabled => 'Ingeschakeld';

  @override
  String get wsDisabled => 'Uitgeschakeld';

  @override
  String get wsWidth => 'Breedte';

  @override
  String get wsHeight => 'Hoogte';

  @override
  String get wsPropertiesInactive =>
      'Deze eigenschap werkt alleen bij gepubliceerd inklappen.';

  @override
  String get wsNavigationAll => 'Alle elementen met titel';

  @override
  String get wsNavigationNone => 'Geen navigatie';

  @override
  String get wsNavigationCustom => 'Aangepaste navigatie';

  @override
  String get wsTitleOverride => 'Titel overschrijven';

  @override
  String get wsCompactLayout => 'Compacte indeling';

  @override
  String get wsWideLayout => 'Breed';

  @override
  String get wsCodeSourceConflict =>
      'Verplaats of verwijder de code in dit blok voordat u src instelt. Writerside weigert een niet-leeg codeblok met een bronverwijzing.';

  @override
  String get wsInherited => 'Overnemen van lijst';

  @override
  String get wsExternalImageSize =>
      'Writerside past het formaat van externe afbeeldingen niet betrouwbaar aan. Bestaande maten kunnen worden bekeken en verwijderd.';

  @override
  String get wsPropertiesNotSerialized =>
      'Deze wijziging is niet in de bron verwerkt. Het concept is behouden.';

  @override
  String get wsListItem => 'Lijstitem';

  @override
  String get wsSourceFile => 'Bronbestand';

  @override
  String get wsLinkTarget => 'Linkdoel';

  @override
  String get wsPreviewImage => 'Voorbeeldafbeelding';

  @override
  String get wsIncludedElement => 'Opgenomen element';

  @override
  String get wsHelpModule => 'Helpmodule';

  @override
  String get wsActionId => 'Actie-ID';

  @override
  String get wsKeymapHelpInstance => 'Helpinstantie van toetsindeling';

  @override
  String get wsShowInSource => 'Tonen in Bron';

  @override
  String get wsOriginElement => 'Elementoverschrijving';

  @override
  String get wsOriginAncestor => 'Bovenliggend element';

  @override
  String get wsOriginModule => 'Modulestandaard';

  @override
  String get wsOriginBuiltIn => 'Ingebouwde standaard';

  @override
  String get wsOriginUnresolved => 'Niet opgelost';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Effectief: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Element';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Gegenereerd: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Standaard: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Standaard: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Opgelost: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Onopgelost';

  @override
  String get wsModule => 'Module';

  @override
  String get wsParent => 'Bovenliggend element';

  @override
  String get wsListType => 'Lijsttype';

  @override
  String get wsStartingNumber => 'Startnummer';

  @override
  String get wsListSorting => 'Sortering';

  @override
  String get wsLetteredList => 'Letterlijst';

  @override
  String get wsCheckboxList => 'Lijst met selectievakjes';

  @override
  String get wsMarkerlessList => 'Lijst zonder markeringen';

  @override
  String get wsAscending => 'Oplopend';

  @override
  String get wsDescending => 'Aflopend';

  @override
  String get wsNoSorting => 'Geen sortering';

  @override
  String get wsAsWritten => 'Zoals geschreven';

  @override
  String get wsSentenceCase => 'Zinskapitalisatie';

  @override
  String get wsTitleCase => 'Titelkapitalisatie';

  @override
  String get wsLowerCase => 'Kleine letters';

  @override
  String get wsUpperCase => 'Hoofdletters';

  @override
  String get wsNativeMarkers => 'Markdown-markeringen';

  @override
  String wsListMarkerStart(String number) {
    return 'Beginmarkering: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Niveau $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'De vastgezette builder negeert <caps>-regels van de module. Gebruik een lokaal caps-attribuut of default-property.';

  @override
  String get wsInsertElements => 'Elementen invoegen';

  @override
  String get wsAdmonitionsAndQuotes => 'Opmerkingen en citaten';

  @override
  String get wsSemanticText => 'Semantische tekst';

  @override
  String get wsPropertiesUnavailable =>
      'Het geïnspecteerde element is niet beschikbaar. Inspecteer een element om door te gaan.';

  @override
  String get searchDocumentsCategory => 'Documenten';

  @override
  String get searchTopicsCategory => 'Onderwerpen';

  @override
  String get searchCurrentDocument => 'Huidig document';

  @override
  String get searchCurrentWorkspace => 'Huidige werkruimte';

  @override
  String get browseNotes => 'Notities bekijken';

  @override
  String get searchActionsCommand => 'Acties zoeken';

  @override
  String get searchDocumentsCommand => 'Documenten zoeken';

  @override
  String get searchTopicsCommand => 'Onderwerpen zoeken';

  @override
  String get searchRecentCommand => 'Recente items zoeken';

  @override
  String get searchResourceUnavailable => 'Deze bron is niet beschikbaar.';

  @override
  String get notesSync => 'Notities synchroniseren';

  @override
  String get searchInWorkspace => 'Zoeken in werkruimte';

  @override
  String get searchCategory => 'Zoekcategorie';

  @override
  String get clearHistorySearchScope => 'Zoeken in documentgeschiedenis';

  @override
  String get searchInDocument => 'Zoeken in document';

  @override
  String get searchDocumentHint => 'Dit document doorzoeken…';

  @override
  String get searchWorkspaceHint => 'Deze werkruimte doorzoeken…';

  @override
  String get searchOutlineHint => 'Koppen zoeken…';

  @override
  String get searchHistoryHint => 'Lokale geschiedenis doorzoeken…';

  @override
  String get searchEnterText => 'Voer tekst in om te zoeken';

  @override
  String get searchAccountUnavailable => 'Account niet beschikbaar';

  @override
  String get searchDocumentsHint => 'Documenten zoeken…';

  @override
  String get searchTopicsHint => 'Onderwerpen zoeken…';

  @override
  String get searchRecentHint => 'Recente items zoeken…';

  @override
  String get searchActionsHint => 'Acties zoeken…';

  @override
  String get searchRequiresNotesWorkspace => 'Vereist een notitiewerkruimte';

  @override
  String get searchSidebarLabel => 'Zoeken:';

  @override
  String get searchDocumentTextCategory => 'Documenttekst';

  @override
  String get searchWorkspaceTextCategory => 'Werkruimtetekst';

  @override
  String get searchHeadingsCategory => 'Koppen';

  @override
  String get shortcutUnassigned => 'Niet toegewezen';

  @override
  String get shortcutPressKeys => 'Druk op een toetscombinatie…';

  @override
  String get shortcutRecord => 'Sneltoets opnemen';

  @override
  String get shortcutRestoreAll => 'Alle standaardwaarden herstellen';

  @override
  String get shortcutRestoreAllQuestion =>
      'Standaardsneltoetsen van alle acties herstellen? Aangepaste toewijzingen worden verwijderd.';

  @override
  String get shortcutSaveFailed =>
      'Sneltoetsen zijn actief, maar konden niet worden opgeslagen. Probeer opnieuw om ze na herstart te behouden.';

  @override
  String get shortcutRetry => 'Opslaan opnieuw proberen';

  @override
  String get shortcutChanged =>
      'Toewijzingen zijn gewijzigd. Controleer de huidige sneltoetsen en probeer opnieuw.';

  @override
  String get shortcutInvalid =>
      'Deze combinatie kan in deze context niet worden toegewezen.';

  @override
  String get shortcutSystemWarning =>
      'Deze combinatie wordt mogelijk door uw bureaublad gebruikt. BusyMark kan systeemsneltoetsen niet overschrijven.';

  @override
  String get shortcutConflicts => 'Deze sneltoets overlapt met deze acties:';

  @override
  String get shortcutRemove => 'Toewijzing verwijderen';

  @override
  String get shortcutRestoreDefault => 'Standaard herstellen';

  @override
  String get shortcutAssign => 'Toewijzen';

  @override
  String get shortcutReassign => 'Opnieuw toewijzen';

  @override
  String get shortcutContextApplication => 'Toepassing';

  @override
  String get shortcutContextDocument => 'Documentweergaven';

  @override
  String get shortcutContextEditor => 'Editor en bron';

  @override
  String get shortcutContextWritersideSource => 'Writerside-bron';

  @override
  String get shortcutContextWorkspace => 'Werkruimtenavigatie';

  @override
  String get shortcutContextTree => 'Zijbalkbomen';

  @override
  String get searchHeadingsCommand => 'Koppen zoeken';

  @override
  String get shortcutFixed => 'Beheerd door de editor; niet instelbaar.';

  @override
  String get shortcutDefaultConflict =>
      'De standaardsneltoets conflicteert met een aangepaste toewijzing.';

  @override
  String get shortcutCurrentBinding => 'Huidige sneltoets';

  @override
  String get shortcutProposedBinding => 'Voorgestelde sneltoets';

  @override
  String get notesActions => 'Notitieacties';

  @override
  String get noteActions => 'Acties voor deze notitie';

  @override
  String get noteProperties => 'Notitie-eigenschappen';

  @override
  String get notesExportAll => 'Notities exporteren · Alle notities…';

  @override
  String get notesExportCategory => 'Notities exporteren · Categorie…';

  @override
  String get notesOfflineAll => 'Offline beschikbaar maken · Alle notities';

  @override
  String get notesOfflineCategory => 'Offline beschikbaar maken · Categorie';

  @override
  String get notesOfflineRemoveAll =>
      'Offlinebewaring verwijderen · Alle notities';

  @override
  String get notesOfflineRemoveCategory =>
      'Offlinebewaring verwijderen · Categorie';

  @override
  String get notesOfflinePause => 'Downloads pauzeren';

  @override
  String get notesOfflineResume => 'Downloads hervatten';

  @override
  String get notesOfflineKeep => 'Offline beschikbaar maken';

  @override
  String get notesOfflineRetentionHelp =>
      'Het verwijderen van deze vereiste behoudt de cache. Een categorie- of accountvereiste kan de notitie nog steeds bewaren.';

  @override
  String get notesOfflineBroader =>
      'Deze notitie wordt ook bewaard door een categorie- of accountvereiste.';

  @override
  String get notesOfflineExternal =>
      'Externe media vereisen een verbinding. BusyMark bewaart alleen notitietekst en beheerde bijlagen.';

  @override
  String get notesEmptyAll =>
      'Nog geen notities. Maak een notitie om te beginnen.';

  @override
  String get notesEmptyFavorites => 'Geen favoriete notities.';

  @override
  String get notesEmptyCategory => 'Geen notities in deze categorie.';

  @override
  String get notesEmptyUncategorized => 'Geen notities zonder categorie.';

  @override
  String get notesEmptyRecovery => 'Geen bewaarde notities om te herstellen.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Mislukt. Opnieuw proberen';

  @override
  String get notesOperationFailed =>
      'De bewerking kon niet worden voltooid. Uw concept blijft bewaard. Controleer opslaan en conflicten en probeer opnieuw.';

  @override
  String get notesInspectionFailed => 'Bijlagen · Mislukt. Opnieuw proberen';

  @override
  String get notesStartingConnection => 'Nextcloud-verbinding starten…';

  @override
  String get notesVerifyingConnection => 'Toegang tot Notities controleren…';

  @override
  String get notesCancellingConnection => 'Aanmelden annuleren en opruimen…';

  @override
  String get notesRemovingConnection => 'Lokaal account verwijderen…';

  @override
  String get notesRemovedWarning =>
      'Het lokale Nextcloud-account is verwijderd. Het intrekken van het app-wachtwoord is niet bevestigd. Verwijder het wachtwoord van BusyMark in de beveiligingsinstellingen van Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Niet alle open notities konden lokaal worden opgeslagen. Controleer opslaan, conflicten of normalisatie in de werkruimte. Lokale wijzigingen moeten mogelijk nog met Nextcloud synchroniseren.';

  @override
  String get notesSettingsLeave =>
      'Wijzigingen in Nextcloud-instellingen opslaan voor vertrek?';

  @override
  String get notesSettingsLeaveHelp =>
      'Notes-instellingen op de server · Niet-opgeslagen wijzigingen';

  @override
  String get notesSettingsReload => 'Serverinstellingen opnieuw laden…';

  @override
  String get notesSettingsReloadHelp =>
      'Opnieuw laden vervangt uw concept door de huidige Nextcloud-instellingen. Concept verwerpen en opnieuw laden?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud heeft de instellingen geaccepteerd, maar het vernieuwen van notities is mislukt. De getoonde waarden zijn door de server bevestigd. Vernieuw opnieuw vanuit Notities.';

  @override
  String get notesUnavailable =>
      'Geen verbinding · Tekst lokaal beschikbaar · Lokaal opgeslagen · synchronisatie in behandeling';

  @override
  String get notesStorageFull =>
      'De Nextcloud-opslag is vol. Maak ruimte vrij op de server en probeer opnieuw.';

  @override
  String get notesRejected =>
      'Nextcloud heeft deze wijziging geweigerd. Controleer de notitie en sla een lokale kopie op voordat u opnieuw probeert.';

  @override
  String get notesThrottled =>
      'Nextcloud heeft gevraagd te wachten. Synchronisatie gaat verder na de wachttijd.';

  @override
  String get notesRecoveryRequired => 'Conflicten · Vergelijken';

  @override
  String get notesScanning => 'Bestanden scannen…';

  @override
  String get notesCancelling =>
      'Annuleren… Wachten tot de huidige bewerking is afgerond.';

  @override
  String get notesCancelled => 'Geannuleerd';

  @override
  String get notesPartial => 'Gedeeltelijk voltooid';

  @override
  String get notesTransferFailed => 'Mislukt. Opnieuw proberen';

  @override
  String get notesImportPartialHelp =>
      'Eerdere items kunnen al lokaal opgeslagen zijn. Hervat deze import om zonder duplicaten verder te gaan.';

  @override
  String get notesNotStarted => 'Niet gestart';

  @override
  String get notesCreated => 'Gemaakt';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Server-URL · Niet ondersteund · Verwijderen · Bijlagen';

  @override
  String get notesCurrentText => 'Huidige bewaarde tekst';

  @override
  String get notesRecovering => 'Herstellen als nieuwe notitie…';

  @override
  String get notesReadOnlyHelp =>
      'Alleen lezen · Favorieten · Lokale kopie opslaan…';

  @override
  String get notesSort => 'Notities sorteren';

  @override
  String get notesPathRelative =>
      'Het pad van de notitiemap is relatief aan uw Nextcloud-opslag.';

  @override
  String get notesSettingsStale =>
      'De instellingen zijn gewijzigd op Nextcloud. Laad en controleer de serverwaarden voordat u het concept vervangt.';

  @override
  String get notesDownloadsPaused => 'Downloads gepauzeerd';

  @override
  String get notesExportNotPublished => 'Er is geen export gepubliceerd.';

  @override
  String get notesKeyringUnavailable =>
      'Ontgrendel de bureaubladsleutelbos en probeer opnieuw.';

  @override
  String get notesConnectFailed =>
      'Kan niet verbinden met Nextcloud Notes. Controleer het serveradres en probeer opnieuw.';

  @override
  String get notesAccountMismatch =>
      'Meld u aan bij hetzelfde Nextcloud-account. Verwijder dit account eerst om een ander te verbinden.';

  @override
  String get notesLocalRemovalFailed =>
      'Het lokaal opruimen is mislukt. Het account blijft bewaard zodat u de verwijdering opnieuw kunt proberen.';

  @override
  String get notesTransferring => 'Notities overdragen…';

  @override
  String get notesTechnicalDetails => 'Technische details';

  @override
  String get notesPauseRequirement => 'Offlinevereiste pauzeren';

  @override
  String get notesResumeRequirement => 'Offlinevereiste hervatten';

  @override
  String get gitReturnToDocument => 'Terug naar document';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Alleen-lezen momentopname · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Deze bestandsnaam bevat niet-UTF-8-bytes. Git-controle en staging blijven beschikbaar; de documenteditor vereist een UTF-8-bestandsnaam.';

  @override
  String get gitUiMergeInProgress => 'Aan de gang samenvoegen';

  @override
  String get gitUiRebaseInProgress => 'Rebase is bezig';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick is bezig';

  @override
  String get gitUiRevertInProgress => 'Bezig met terugdraaien';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Patch-toepassing is aan de gang';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Squash merge resultaat wacht op commit';

  @override
  String get gitUiUnresolvedIndexConflicts => 'Onopgeloste indexconflicten';

  @override
  String get gitUiUnresolvedConflicts => ' · onopgeloste conflicten';

  @override
  String get gitUiReviewOperation => 'Evaluatie';

  @override
  String get gitUiRefresh => 'Vernieuwen';

  @override
  String get gitUiCreateNamedStash => 'Aanmaken met naam stash';

  @override
  String get gitUiCreateStash => 'Stash maken…';

  @override
  String get gitUiNoStashes => 'Geen stashes';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Selecteer een opslagruimte om de wijzigingen te inspecteren';

  @override
  String get gitUiStashedUntrackedFiles =>
      'Niet-getrackte bestanden worden opgeslagen';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Inspecteer niet-getraceerde bestanden...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Geef bij het toepassen van de status stash... geënsceneerd/index';

  @override
  String get gitUiApplyAndRetain => 'Toepassen en behouden';

  @override
  String get gitUiPop => 'Pap...';

  @override
  String get gitUiCreateBranch => 'Branch maken…';

  @override
  String get gitUiDropStash => 'Stash verwijderen…';

  @override
  String get gitUiBranchFromStash => 'Branch uit stash maken';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Creëer/schakel naar een tak op de oorspronkelijke basis van de stash. De oorspronkelijke stash wordt behouden voor expliciete latere verwijdering.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 deze voorraad?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'De oorspronkelijke voorraad wordt behouden als er conflicten worden toegepast.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Verwijdert dit item. De wijzigingen worden niet toegepast.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Los de niet-samengevoegde bestanden op. Git heeft geen opdracht om een stash voort te zetten of af te breken; de oorspronkelijke stash blijft bestaan.';

  @override
  String get gitUiStashNameMessage => 'Naam/bericht opslaan';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Inhoud en resulterende index opslaan';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Getraceerde werk- en geënsceneerde wijzigingen opslaan';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Wijzigingen stashen en indexinhoud laten staan (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Alleen indexwijzigingen stashen (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Niet-getrackte bestanden invoegen';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Alle subsidiabele paden in deze repository';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Geen in aanmerking komende wijzigingen voor deze opslagopties.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Selecteer ten minste één geschikt pad.';

  @override
  String get gitUiCreateStash2 => 'Stash maken';

  @override
  String get gitUiCreateWorktree => 'Werkboom aanmaken...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Maak een commit voordat u een worktree bij HEAD maakt.';

  @override
  String get gitUiDetachedHEAD => 'Losgekoppelde HEAD';

  @override
  String get gitUiCurrent => 'Lopend ·';

  @override
  String get gitUiLocked => 'Vergrendeld ·';

  @override
  String get gitUiOpenInBusyStack => 'Openen in BezigStack ·';

  @override
  String get gitUiStatusNotInspected => 'Status niet geïnspecteerd';

  @override
  String get gitUiDirty => 'Vuil';

  @override
  String get gitUiClean => 'Geen wijzigingen';

  @override
  String get gitUiOpenWorkingFolder => 'Werkmap openen';

  @override
  String get gitUiMoveWorktree => 'Werkboom verplaatsen...';

  @override
  String get gitUiUnlock => 'Ontgrendelen';

  @override
  String get gitUiLock => 'Vergrendelen';

  @override
  String get gitUiRemoveCleanWorktree => 'Verwijder schone werkboom...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Beoordeling verwijdering inclusief lokale wijzigingen...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nieuwe werkboom-mapnaam';

  @override
  String get gitUiNewWorktreeBranch => 'Nieuwe werkboom tak';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Maak $arg0/$arg1 met een nieuwe lokale tak op $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Mapnaam van bestemming';

  @override
  String get gitUiRemoveWorktree => 'Werkboom verwijderen?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Alle lokale tracked/untracted wijzigingen in deze werkboom expliciet weggooien. Vergrendelde/in-use werkbomen blijven beschermd.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git weigert verwijdering als er lokale wijzigingen, ongetraceerde bestanden of een slot.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Verwijder de inhoud van de lokale werkboom en verwijder';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Verwijder schone werkboom';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Expliciet recurseren in geneste submodules voor updates/synchronisatie';

  @override
  String get gitUiNoRecordedSubmodules => 'Geen geregistreerde submodules';

  @override
  String get gitUiNotInitialized => 'niet geïnitialiseerd';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Ouder gitlink: $arg0 Checked out: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Vuile geneste repository';

  @override
  String get gitUiCleanNestedRepository => 'Leg geneste repository op';

  @override
  String get gitUiNestedStatusUnavailable =>
      'Geneste status is niet beschikbaar';

  @override
  String get gitUiEnterNestedRepository => 'Voer geneste repository in';

  @override
  String get gitUiInitializeConfiguration => 'Configuratie initialiseren';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Update van de geregistreerde commit van ouder...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Ingestelde remote branch volgen...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Geconfigureerde URL\'s synchroniseren...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Stage huidige submodule pointer in ouder';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Parent en submodule commits, pushes en vuile staat blijven gescheiden. Bladeren initialiseert of werkt ze niet bij.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Ophalen en controleren van de geconfigureerde remote taks commit. Dit verschilt van de ouder .Gitlink opgenomen gitlink. Recursive: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Initialiseer indien nodig en bekijk precies $arg0. Recursief: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Pas de herziene submodule configuratiebewerking toe. Recursive: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Submodulebewerking toepassen';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspecteer een geregistreerde revisie of maak een recovery branch aan. Reflog herstelt geen willekeurige niet-opgeslagen of ongetraceerde inhoud.';

  @override
  String get gitUiSelectAReflogEntry => 'Selecteer een reflog-item';

  @override
  String get gitUiPreviousPage => 'Vorige pagina';

  @override
  String get gitUiNextPage => 'Volgende pagina';

  @override
  String get gitUiRecoveryBranchName => 'Naam hersteltak';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Maakt een branch aan bij $arg0; de werkbestanden en de huidige branch zijn ongewijzigd.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Hersteltak aanmaken...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'Alleen-lezen recovery snapshot';

  @override
  String get gitUiInspectSnapshot => 'Snapshot inspecteren...';

  @override
  String get gitUiReviewReset => 'Recensie resetten...';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Pagina $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Een Git-tekstgeschiedenis moet het bewerkbare veld bezitten.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Bewerken HEAD | Index | Werkboom…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'De herziene index of de werkinhoud is gewijzigd. Vernieuw deze vergelijking voordat deze wordt geënsceneerd.';

  @override
  String get gitUiRefreshComparison => 'Vergelijking vernieuwen';

  @override
  String get gitUiPreviousChangedFile => 'Vorig gewijzigd bestand';

  @override
  String get gitUiNextChangedFile => 'Volgende gewijzigd bestand';

  @override
  String get gitUiPreviousDifference => 'Vorig verschil';

  @override
  String get gitUiNextDifference => 'Volgende verschil';

  @override
  String get gitUiComparisonMode => 'Vergelijkingsmodus';

  @override
  String get gitUiSideBySide => 'Zij aan zij';

  @override
  String get gitUiUnified => 'Unified';

  @override
  String get gitUiDiffDisplayOptions => 'Schermopties';

  @override
  String get gitUiWrap => 'Omloop';

  @override
  String get gitUiWords => 'Woorden';

  @override
  String get gitUiCollapseContext => 'Context invouwen';

  @override
  String get gitUiIgnoreWhitespace => 'Witruimte negeren';

  @override
  String get gitUiSearchComparison => 'Vergelijken zoeken';

  @override
  String get gitUiSearch => 'Zoeken';

  @override
  String get gitUiCloseSearch => 'Zoeken sluiten';

  @override
  String get gitUiStagingActions => 'Stagingsacties';

  @override
  String get gitUiStagingActions2 => 'Staging acties...';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Geselecteerde gewijzigde regels uit index halen';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Geselecteerde gewijzigde regels klaarzetten';

  @override
  String get gitUiUnstageWholeFile => 'Heel bestand uit index halen';

  @override
  String get gitUiStageWholeFile => 'Heel bestand klaarzetten';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 witruimte-alleen veranderde regels verborgen · Toon exacte wijzigingen';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 veranderde de geselecteerde regels · Weergave-instellingen veranderen nooit de geënsceneerde bytes.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Alleen-lezenvergelijking · Kopieer tekst of pas de weergave aan.';

  @override
  String get gitUiNoFinalNewline => ' · geen definitieve nieuwe regel';

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
      'Tekstvergelijking is niet beschikbaar voor deze inhoud.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Deze vergelijking overschrijdt de grensgrens voor de herziening van de tekst. De inhoud is niet identiek verklaard.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'De vergeleken inhoud is identiek.';

  @override
  String get gitUiUnstage => 'Niet-statief';

  @override
  String get gitUiStage => 'Fase';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 veranderde regel';
  }

  @override
  String get gitUiContext => 'Context';

  @override
  String get gitUiExpandUnchangedContext => 'Ongewijzigde context uitvouwen';

  @override
  String get gitUiUnstageThisHunk => 'Dit blok uit index halen';

  @override
  String get gitUiStageThisHunk => 'Dit blok klaarzetten';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Geënsceneerde inhoud bewerken · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Beoordeeld indexresultaat schrijven';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Index';

  @override
  String get gitUiWorkingTree => 'Werkboom';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Index · bewerkbare UTF-8 blob';

  @override
  String get gitUiUndo => 'Ongedaan maken';

  @override
  String get gitUiRedo => 'Opnieuw uitvoeren';

  @override
  String get gitUiReloadIndexReview => 'Indexoverzicht herladen?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Laad de huidige HEAD-, index- en werkversies opnieuw. Dit vervangt het niet-opgeslagen concept in de indexeditor.';

  @override
  String get gitUiReplaceDraftAndReload => 'Ontwerp vervangen en herladen';

  @override
  String get gitUiReloadVersions => 'Versies herladen...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Bewerkt resultaat naar dit indexitem schrijven';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Werkbestanden blijven op de schijf. Bekijk de bewerkte index voordat u dit toepast.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Wijzigingen in het tekstformaat van de index bekijken';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Update alleen de herziene index voor $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Gerecenseerd indexresultaat schrijven';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Het bewerkte resultaat veranderde tijdens de format review. Bekijk het opnieuw.';

  @override
  String get gitUiSynchronizeScrolling => 'Schuiven synchroniseren';

  @override
  String get gitUiReadOnlyRevisionContent => 'Alleen-lezen revisie-inhoud';

  @override
  String get gitUiEditableIndexContent => 'Bewerkbare indexinhoud';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'De gevraagde revisie is buiten de huidige filters. Filters resetten om het te onthullen.';

  @override
  String get gitUiFilterLog => 'Filterlog';

  @override
  String get gitUiFilters => 'Filters...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filters ($count)...';
  }

  @override
  String get gitUiMessage => 'Bericht…';

  @override
  String get gitUiAuthor => 'Auteur…';

  @override
  String get gitUiPath => 'Pad...';

  @override
  String get gitUiDate => 'Afspraakje...';

  @override
  String get gitUiMessageFilter => 'Berichtfilter';

  @override
  String get gitUiAuthorFilter => 'Auteursfilter';

  @override
  String get gitUiPathFilter => 'Padfilter';

  @override
  String get gitUiMessage2 => 'Bericht';

  @override
  String get gitUiAuthor2 => 'Auteur';

  @override
  String get gitUiPath2 => 'Pad';

  @override
  String get gitUiDateFilter => 'Datumfilter...';

  @override
  String get gitUiResetFilters => 'Filters resetten';

  @override
  String get gitUiRefreshLog => 'Log verversen';

  @override
  String get gitUiGoToCommitReference => 'Ga naar commit/reference...';

  @override
  String get gitUiBackToHEAD => 'Terug naar HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Bestelde kers-pick';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Beoordeling van de kersen-pluk ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Vergelijk twee geselecteerde revisies...';

  @override
  String get gitUiToggleBranchesPane => 'Vertakkingenpaneel aan/uit';

  @override
  String get gitUiFilterBranchesAndTags => 'Filter branches en tags';

  @override
  String gitUiCommitArg0(String arg0) {
    return '$arg0 committen';
  }

  @override
  String get gitUiCommitDetails => 'Commit details...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Referentie: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Deze commit kiezen';

  @override
  String get gitUiBranchOrTag => 'Tak of tag';

  @override
  String get gitUiAllReferences => 'Alle verwijzingen';

  @override
  String get gitUiLocal => 'Lokaal';

  @override
  String get gitUiRemote => 'Extern';

  @override
  String get gitUiTags => 'Tags';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Geen commits komen overeen met de huidige filters.';

  @override
  String get gitUiObjectID => 'Object-ID';

  @override
  String get gitUiSubjectReferences => 'Onderwerp / referenties';

  @override
  String get gitUiDate2 => 'Datum';

  @override
  String get gitUiGitCommits => 'Git commits';

  @override
  String get gitUiParents => 'Bovenliggende commits';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 ouders';
  }

  @override
  String get gitUiLoadMoreCommits => 'Meer commits laden';

  @override
  String get gitUiLoadingChangedFiles => 'Gewijzigde bestanden worden geladen';

  @override
  String get gitUiNoChangedFiles => 'Geen gewijzigde bestanden';

  @override
  String get gitUiSelectACommit => 'Selecteer een commit';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Vergelijk ouder $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Gewijzigde bestanden';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Auteur: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Committer: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Ondiepe/gedeeltelijke grens: een ouderobject is niet beschikbaar.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'De ouder is buiten deze pagina of een ondiepe grens.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Bovenliggende commit $arg0';
  }

  @override
  String get gitUiCommitActions => 'Acties committeren...';

  @override
  String get gitUiEmptyTree => 'lege boom';

  @override
  String get gitUiCreateBranch2 => 'Branch maken';

  @override
  String get gitUiCreateTag => 'Tag maken';

  @override
  String get gitUiCompareRevisions => 'Revisies vergelijken';

  @override
  String get gitUiOpenSnapshot => 'Snapshot openen';

  @override
  String get gitUiRevertCommit => 'Verbinden terugdraaien';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Interactieve rebase na deze grens';

  @override
  String get gitUiResetCurrentBranch => 'Huidige branch terugzetten';

  @override
  String get gitUiCopyFullObjectID => 'Volledig object-ID kopiëren';

  @override
  String get gitUiGoToCommitReference2 => 'Ga naar commit/reference';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Voer een commit ID of verwijzing naar onthullen in Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'De gevraagde herziening is niet beschikbaar.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Repository metadata is alleen-lezen. Tak inspectie en vergelijking blijven beschikbaar.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Werkende bestanden zijn niet beschikbaar of alleen-lezen. Branch schakelen en samenvoegen zijn niet beschikbaar.';

  @override
  String get gitUiSearchBranchesAndTags => 'Branches en tags zoeken';

  @override
  String get gitUiNewBranch => 'Nieuwe branch…';

  @override
  String get gitUiLocalBranches => 'Lokale branches';

  @override
  String get gitUiRemoteBranches => 'Externe branches';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Tracks $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Uitgecheckt op $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Verversen van branchemetadata';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Schakel over naar $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Bezette werkboom openen';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Lokale tracking-branch aanmaken...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Met huidige HEAD vergelijken';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Samenvoegen in huidige tak...';

  @override
  String get gitUiRename => 'Hernoemen...';

  @override
  String get gitUiChangeUpstream => 'Verander stroomopwaarts...';

  @override
  String get gitUiDelete => 'Verwijderen...';

  @override
  String get gitUiDeleteFromRemote => 'Verwijderen van remote...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Acties voor $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Lokale branchenaam';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Maak aan op $arg0. De nieuwe branch zal worden uitgecheckt.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'De lokale tak zal $arg0 volgen en worden uitgecheckt.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Kies remote voor verwijdering';

  @override
  String get gitUiDeleteRemoteReference => 'Referentie op afstand verwijderen';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '$arg0 samenvoegen tot $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return '$arg0 hernoemen';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Upstream voor $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Geen upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '$arg0 verwijderen?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Alleen lokale verwijdering. Een niet-samengevoegde tak wordt geweigerd.';
  }

  @override
  String get gitUiDelete2 => 'Verwijderen';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Niet-samengevoegde tak $arg0 verwijderen?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git meldt dat deze branch niet volledig is samengevoegd. Verwijder de lokale referentie na het bekijken van de commits expliciet; kopieën op afstand zijn ongewijzigd.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Niet-samengevoegde lokale tak verwijderen';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Bestemming: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Bron tak of tag';

  @override
  String get gitUiMergePolicy => 'Beleid samenvoegen';

  @override
  String get gitUiFastForwardWhenPossible => 'Indien mogelijk doorspoelen';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Altijd een merge commit aanmaken';

  @override
  String get gitUiFastForwardOnly => 'Alleen vooruitspoelen';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Squash in geënsceneerde veranderingen';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Stop voordat de merge commit wordt aangemaakt';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Fast-forward is uitgeschakeld zodat HEAD niet vóór de controle kan verplaatsen.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Laat geënsceneerde wijzigingen na voor een aparte commit; dit is geen continue merge.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Conflicten blijven beschikbaar in de gedeelde resolutiewerkruimte.';

  @override
  String get gitUiAddRemote => 'Afstandsbediening toevoegen...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Fetch: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Verwijderen...';

  @override
  String get gitUiChangeFetchURL => 'Ophalen-URL wijzigen...';

  @override
  String get gitUiAddPushDestination => 'Pushdoel toevoegen...';

  @override
  String get gitUiRemovePushDestination => 'Pushdoel verwijderen...';

  @override
  String gitUiManageArg0(String arg0) {
    return '$arg0 beheren';
  }

  @override
  String get gitUiRemoteName => 'Naam op afstand';

  @override
  String get gitUiNewRemoteName => 'Nieuwe naam op afstand';

  @override
  String get gitUiRepositoryURLOrLocalSource => 'Repository URL of lokale bron';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Voer de exacte beoordeelde bestemming in om te verwijderen.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'De geloofsbrieven worden geleverd door geconfigureerde helpers of een privéprompt.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return '$arg0 op afstand verwijderen?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Verwijdert lokale configuratie op afstand en tracking referenties. Het verwijdert de server repository niet.';

  @override
  String get gitUiRemoveRemote2 => 'Verwijderen';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Commit scope: volledige repository';

  @override
  String get gitUiCachedTracking => 'Tracking in beslag genomen';

  @override
  String get gitUiAmendLastCommit => 'Laatste commit wijzigen';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Geconfigureerde haken en ondertekening worden gerespecteerd.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Herschrijft de geselecteerde HEAD-commit. Externe volggegevens bewijzen niet dat deze niet is gepubliceerd.';

  @override
  String get gitUiRepository => 'Repository';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Vrijstaande $arg0';
  }

  @override
  String get gitUiLog => 'Geschiedenis';

  @override
  String get gitUiRepositoryActions => 'Repositoryacties';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Volggegevens in cache · $upstream · $ahead vooruit · $behind achter';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Bare repository · geen werkboom. Open Log om de geschiedenis te inspecteren.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Alleen-lezen repository · enscenering en commits zijn niet beschikbaar.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Repository-status is niet beschikbaar';

  @override
  String gitUiAmendRevision(String revision) {
    return '$revision wijzigen';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Aftekenregel toevoegen';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Geconfigureerd ondertekeningsbeleid gebruiken';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Cryptografisch ondertekenen van deze commit';

  @override
  String get gitUiDoNotSignThisCommit => 'Deze commit niet ondertekenen';

  @override
  String get gitUiRecentCommitMessages => 'Recente commit berichten...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Gebruik geconfigureerd commit sjabloon...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Auteur identiteit en geconfigureerde haken...';

  @override
  String get gitUiDraftMessage => 'Ontwerpbericht...';

  @override
  String get gitUiCommitOptions => 'Commitopties';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Concept bewaard in het geheugen; opslaan is mislukt. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Commitbericht';

  @override
  String get gitUiGitOperationInProgress => 'Bezig met uitvoeren';

  @override
  String get gitUiCancel => 'Annuleren';

  @override
  String get gitUiAmendStaged => 'Gefaseerd wijzigen';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit geënsceneerd ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Committen en pushen…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Er is geen leesbaar commit-sjabloon geconfigureerd.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Identiteit en haken committen';

  @override
  String get gitUiRecentMessages => 'Recente berichten';

  @override
  String get gitUiReplaceMessageDraft => 'Berichtontwerp vervangen?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Het bestaande commit-bericht vervangen door het geselecteerde bericht?';

  @override
  String get gitUiReplaceDraft => 'Ontwerp vervangen';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Lokale commit $arg0 bestaat.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Lokale commit $arg0 bestaat. Beoordeel Log voordat u een andere commit probeert. Het concept van het bericht is behouden.';
  }

  @override
  String get gitUiCommitAuthorName => 'Auteursnaam committen';

  @override
  String get gitUiCommitAuthorEmail => 'E-mail van auteur committen';

  @override
  String get gitUiConfiguredDefault => 'standaard ingesteld';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Ondertekening: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Geconfigureerde haken: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Een aftekenregel is een verklaring in het bericht, geen cryptografische handtekening. De identiteit wordt alleen in de lokale repositoryconfiguratie opgeslagen; uw concept blijft bewaard.';

  @override
  String get gitUiSaveRepositoryIdentity =>
      'Identiteit van de repository opslaan';

  @override
  String get gitUiStaged => 'Klaargezet';

  @override
  String get gitUiUntracked => 'Niet gevolgd';

  @override
  String get gitUiUnstaged => 'Niet klaargezet';

  @override
  String get gitUiConflicts => 'Conflicten';

  @override
  String get gitUiNoChanges => 'Geen wijzigingen';

  @override
  String get gitUiRepositoryChangeTree => 'Repository boom wijzigen';

  @override
  String get gitUiChanges => 'Wijzigingen';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Uitvouwen';

  @override
  String get gitUiCollapse => 'Inklappen';

  @override
  String get gitUiUnstageFile => 'Bestand uit index halen';

  @override
  String get gitUiStageFile => 'Bestand klaarzetten';

  @override
  String get gitUiExpandGroup => 'Groep uitvouwen';

  @override
  String get gitUiCollapseGroup => 'Groep invouwen';

  @override
  String get gitUiReviewDifference => 'Beoordelingsverschil';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Geselecteerde bestanden uit index halen';

  @override
  String get gitUiStageSelectedFiles => 'Geselecteerde bestanden klaarzetten';

  @override
  String get gitUiFileHistoryAndBlame => 'Bestandsgeschiedenis en schuld...';

  @override
  String get gitUiDeleteUntrackedFile => 'Verwijder untracked bestand...';

  @override
  String get gitUiDiscardUnstagedChange =>
      'Niet-gefaseerde wijziging weggooien...';

  @override
  String get gitUiFileHistory => 'Bestandsgeschiedenis';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return '$arg0 niet gestageerd weggooien?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Vervangt de werkinhoud met de index, of verwijdert dit ongetraceerde bestand. Gefaseerde inhoud wordt bewaard. Niet-opgeslagen hostdocumenten moeten eerst worden herzien.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Verwijder untracked bestand';

  @override
  String get gitUiDiscardWorkingChange => 'Werkverandering verwerpen';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'REMOTE-referentie $arg0 verwijderen';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Dit verwijdert de referentie op elke pushbestemming die hieronder wordt vermeld. Lokale branches/tags worden behouden. De verwachte tips worden door deze beoordeling vastgesteld.';

  @override
  String get gitUiReferenceDoesNotExist => 'verwijzing bestaat niet';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Verwachte tip: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted =>
      'Verwijdering op afstand voltooid.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '$arg0 verwijderen van de remote?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'De bovenstaande doeltips worden verwijderd. Elke veranderde remote tip stopt de bewerking voor een andere beoordeling.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Beoordelen en verwijderen van remote...';

  @override
  String get gitUiDestinationReference => 'Bestemming';

  @override
  String get gitUiReviewDestinations => 'Evaluatie van de bestemmingen';

  @override
  String get gitUiNewRemoteBranch => 'nieuwe remote tak';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · verwacht: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Een bestemming heeft commits die lokaal niet beschikbaar zijn. Haal de beoordeelde bestemming op voordat u de uitgaande geschiedenis bekijkt.';

  @override
  String get gitUiFetchReviewedDestination => 'Gereviewde bestemming ophalen';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Kies een bestemming en bekijk de uitgaande commits.';

  @override
  String get gitUiNoOutgoingCommits => 'Geen uitgaande commits';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Selecteer een uitgaande commit';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Meer uitgaande commits laden';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Deze bestemming als stroomopwaarts instellen';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Kies exacte tags om te publiceren';

  @override
  String get gitUiTagsNone => 'Tags: geen';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Tags: $arg0 geselecteerd';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Publiceer precies: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push voltooid. De lokale commit blijft beschikbaar in Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Geforceerd pushen vereist exact de hier gecontroleerde doelrevisies.';

  @override
  String get gitUiForceWithReviewedLease => 'Gedwongen met herschikte huur...';

  @override
  String get gitUiPush => 'Pushen';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Force push met herziene huurcontracten?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Herschrijf $arg0 alleen als elke bestemming op afstand nog steeds de exacte tip hierboven heeft.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Anderen gebruiken deze geschiedenis mogelijk al. Ophalen op de achtergrond vernieuwt deze lease niet.';

  @override
  String get gitUiForceWithLease => 'Gedwongen met lease';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Het resultaat op afstand is onzeker. Bekijk de bestemmingen opnieuw voordat een andere push.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Ouder $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Verwijderen om op te halen';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Snoei verwijderde remote-tracking branches';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Ophalen updates remote-tracking informatie zonder het vervangen van werkende bestanden.';

  @override
  String get gitUiFetch => 'Ophalen';

  @override
  String get gitUiSourceRemote => 'Bron op afstand';

  @override
  String get gitUiSourceBranch => 'Brontak';

  @override
  String get gitUiReviewedStrategy => 'Bekeken strategie';

  @override
  String get gitUiMerge => 'Samenvoegen';

  @override
  String get gitUiRebase => 'Rebasen';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Stop als de bestemming niet kan doorspoelen; merge of rebase nooit.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Samenvoegen met een merge commit, inclusief wanneer fast-forward mogelijk is.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Samenvoegen; laat fast-forward toe indien mogelijk.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Lokale geschiedenis rebaseren met behoud van lokale merge commits.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Lokale commits rebasen als een lineaire geschiedenis.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git is geconfigureerd voor interactieve rebase. Selecteer hier expliciet een pull-strategie of haal Rebase op... om een plan te bekijken.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Gebruik gerecenseerde gewone rebase voor deze pull';

  @override
  String get gitUiOptions => 'Opties';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Altijd een merge commit aanmaken (geen fast-forward)';

  @override
  String get gitUiPreserveLocalMergeCommits => 'Lokale merge commits behouden';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Lokale wijzigingen kunnen aantrekking voorkomen. Beoordelen/aanbevelen of expliciet een voorraad aanmaken.';

  @override
  String get gitUiStashes => 'Stashes';

  @override
  String get gitUiCreateOrReviewStash => 'Stash aanmaken of recenseren...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Trek met geselecteerde strategie';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'Repository-URL of lokale Git-bron';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH, of lokaal pad';

  @override
  String get gitUiFolderToInitialize => 'Map om te initialiseren';

  @override
  String get gitUiFinalCloneDestination => 'Eindkloonbestemming';

  @override
  String get gitUiChoose => 'Kies...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Maakt alleen Git-metadata aan. Bestaande bestanden worden niet geënsceneerd of vastgelegd.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'De uiteindelijke doelmap mag niet bestaan of moet leeg zijn. Bestaande gebruikersgegevens worden nooit overschreven.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Initiële tak · blanco gebruikt effectief Git-beleid';

  @override
  String get gitUiSelectedBranchOptional => 'Geselecteerde tak · optioneel';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Expliciet submodules recursief initialiseren/updaten';

  @override
  String get gitUiPreparingGitOperation => 'Git-bewerking wordt voorbereid...';

  @override
  String get gitUiThisAttemptCreated => 'Deze poging creëerde';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'De bestemming bestond vóór deze poging:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'De map blijft voor inspectie. Bekijk het voordat een andere kloon poging.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Er blijft geen doelmap over.';

  @override
  String get gitUiCancelProcess => 'Proces annuleren';

  @override
  String get gitUiInitialize => 'Initialiseren';

  @override
  String get gitUiClone => 'Klonen';

  @override
  String get gitUiChooseNewBase => 'Nieuwe basis kiezen';

  @override
  String get gitUiChooseUpstreamBoundary => 'Upstreamgrens kiezen';

  @override
  String get gitUiNewBase => 'Nieuwe basis';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Upstreamgrens · uitgesloten';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Gelijk aan upstreamgrens';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Branch, tag of commit kiezen…';

  @override
  String get gitUiUseUpstreamAsNewBase =>
      'Gebruik stroomopwaarts als nieuwe basis';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Kies een geldige branch, tag of commit uit Log.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'De eerste behouden commit in een branchblok kan geen squash of fixup zijn: er is geen voorafgaande doelcommit.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Takblok $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Wordt een nieuw bericht gevraagd]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Geplande commit-berichten';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Origineel/gecombineerd berichtvoorbeeld · Git verzoekt om de laatste herwoord/squash berichten';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Resultaat $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Huidige branch: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'Losgekoppelde HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Een rebase herschrijft commitidentiteiten. Externe volggegevens bewijzen niet dat de geschiedenis nooit is gepubliceerd.';

  @override
  String get gitUiIncludeRootCommits => 'Rootcommits opnemen';

  @override
  String get gitUiMergeCommits => 'Commits samenvoegen';

  @override
  String get gitUiFlattenHistory => 'Geschiedenis lineair maken';

  @override
  String get gitUiPreserveBranchStructure => 'Branchstructuur behouden';

  @override
  String get gitUiAutosquash => 'Automatisch combineren';

  @override
  String get gitUiPrepareGitPlan => 'Git-plan voorbereiden';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commits to replay: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Bevat alle root commits bereikbaar vanuit deze branch.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Commits na $boundary worden opnieuw toegepast op $base; de grenscommit zelf is uitgesloten.';
  }

  @override
  String get gitUiRoot => 'Wortel';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git tak/label/reset/merge structuur';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Kies een expliciete oude grens of root-modus en bereid het plan voor.';

  @override
  String get gitUiMoveUp => 'Omhoog';

  @override
  String get gitUiMoveDown => 'Omlaag';

  @override
  String get gitUiResetPlan => 'Plan herstellen';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · tak blok $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Selecteer een commit voor details en gewijzigde bestanden';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Voorbeeld van gecombineerde commit berichten...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ verplaatst de geselecteerde commit. Niet-gerelateerde branchverwijzingen worden niet automatisch bijgewerkt.';

  @override
  String get gitUiCancelPlan => 'Plan annuleren';

  @override
  String get gitUiStartReviewedRebase => 'Een nieuwe rebase beginnen?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Herschrijf $arg0 geplande commits op $arg1. Gedropte commits blijven zichtbaar gemarkeerd in dit plan totdat u start.';
  }

  @override
  String get gitUiStartRebase => 'Rebase starten';

  @override
  String get gitUiNoContinuingGitOperation => 'Geen Git-bewerking';

  @override
  String get gitUiStoppedForEditingAmend =>
      ' · gestopt om te bewerken/amenderen';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Dit zijn ongemergede index-items, mogelijk uit een stash-programma. Git heeft geen stash-opdracht voortgezet of afgebroken.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Bewerk de werkbestanden, podium en wijzig de huidige commit en ga verder met deze rebase.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · niet-samengevoegde indexstappen $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'De index bevat geen onopgeloste gegevens.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'De huidige commit als lege commit bewaren';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'De echte index heeft geen geënsceneerde wijzigingen. Maak een expliciete lege commit aan en ga verder met de sequencer als deze actief blijft.';

  @override
  String get gitUiKeepEmptyCommit => 'Lege commit bewaren...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git probeert terug te keren naar het beginpunt. Herstel van vooraf bestaande wijzigingen buiten de index, niet-gevolgde bestanden en niet-opgeslagen inhoud is niet gegarandeerd.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Sla de huidige commit over en ga verder met de volgende geplande commit.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Vergeet deze bewerking met behoud van de huidige bestanden en index.';

  @override
  String gitUiContinueArg0(String arg0) {
    return '$arg0 voortzetten';
  }

  @override
  String get gitUiReloadConflictVersions => 'Conflictversies herladen?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Het niet-opgeslagen resultaatontwerp vervangen door het huidige werkbestand. Opgeslagen werkinhoud blijft behouden.';

  @override
  String get gitUiLoadingConflictVersions => 'Conflictversies laden...';

  @override
  String get gitUiLoadingConflict => 'Conflict laden';

  @override
  String get gitUiBaseLeft => 'Basis → links';

  @override
  String get gitUiBaseRight => 'Basis → rechts';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Geen basisregel voor dit conflict';

  @override
  String get gitUiAcceptEntireLeftFile =>
      'Het hele linker bestand accepteren...';

  @override
  String get gitUiAcceptEntireRightFile =>
      'Volledig rechts bestand accepteren...';

  @override
  String get gitUiPreviousConflictRegion => 'Vorig conflictgebied';

  @override
  String get gitUiNextConflictRegion => 'Volgend conflictgebied';

  @override
  String get gitUiManualResolution => 'Handmatige resolutie';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Regio $arg0/$arg1 · $arg2 beoordeeld';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Bronuitlijning overschreed de tekstvergelijkingslimiet; bronvensters blijven beschikbaar voor handmatige toetsing.';

  @override
  String get gitUiAcceptLeftRegion => 'Linkergebied accepteren';

  @override
  String get gitUiAcceptRightRegion => 'Juiste regio accepteren';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Handmatig resultaat voor regio bewaren';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'De niet-conflicterende wijzigingen van Git toepassen?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'De huidige resultaatopzet vervangen door een voorbeeld van Git. Dit gooit niet opgeslagen handmatige resultaatbewerkingen weg; het werkbestand blijft ongewijzigd totdat het opgeslagen is.';

  @override
  String get gitUiUseMergePreview => 'Voorbeeld van samenvoegen gebruiken';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Niet-conflicterende wijzigingen toepassen...';

  @override
  String get gitUiLeftSource => 'Linkerbron';

  @override
  String get gitUiResult => 'Resultaat';

  @override
  String get gitUiRightSource => 'Rechterbron';

  @override
  String get gitUiStage2 => 'Fase 2';

  @override
  String get gitUiStage3 => 'Fase 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Conflictversies zijn niet beschikbaar. Vernieuwen om hun huidige status te herzien.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Resultaat opgeslagen op schijf. De index bepaalt nog steeds of dit bestand is opgelost.';

  @override
  String get gitUiSaveResultDraft => 'Resultaatconcept opslaan';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Resultaat toepassen en oplossing klaarzetten';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Resultaat · bewerkbare UTF-8 werkinhoud';

  @override
  String get gitUiEditableConflictResult => 'Bewerkbaar conflictresultaat';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Links: $arg0 · $arg1\nRechts: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Kies expliciet inhoud, verwijdering of een submodule commit. Geen binaire gegevens worden gedecodeerd als bewerkbare tekst.';

  @override
  String get gitUiUseEntireLeftContent =>
      'Volledige linkse inhoud gebruiken...';

  @override
  String get gitUiUseEntireRightContent =>
      'Volledige rechtse inhoud gebruiken...';

  @override
  String get gitUiDeleteThisPath => 'Dit pad verwijderen...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Opgelost submodule commit';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Stage deze exacte gitlink in de ouder. Dit checkt niet uit of commit de submodule.';

  @override
  String get gitUiSetResolvedGitlink => 'Gitlink instellen...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Basis → fase $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Het resultaat werd bewerkt. Houd het handmatige resultaat of selecteer een ander ongewijzigd gebied.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Oplossing ‘$arg0’ toepassen?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Stage de gekozen gitlink commit in de ouder. De submodule checkout en de bestanden worden niet vervangen.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Vervangt het volledige werkpad $arg0 en leidt het besluit in. Huidige werkinhoud en eventuele niet-opgeslagen resultaatontwerpen worden verworpen.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Volledige bestandsbeslissing toepassen';

  @override
  String get gitUiStageThisConflictResolution =>
      'Deze conflictoplossing in scène zetten?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Gebruik het volledige bewerkte resultaat als $arg0. Git registreert het pad dat is opgelost wanneer het is geënsceneerd. Bekijk eerst alle beoogde inhoud.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Toepassen en klaarzetten';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Beoordelen resultaat tekst formaat wijzigingen';

  @override
  String get gitUiSaveReviewedResult => 'Beoordeeld resultaat opslaan';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Inheemse Git-tabel is niet bereikbaar. Probeer het opnieuw na het opnieuw verbinden van de toepassing.';

  @override
  String get gitUiSans => 'Sans';

  @override
  String get gitUiSelect => 'Selecteren';

  @override
  String get gitUiContextMenu => 'Contextmenu';

  @override
  String get gitUiCopyText => 'Tekst kopiëren';

  @override
  String get gitUiLoadingRow => 'Rij wordt geladen';

  @override
  String get gitUiRetry => 'Opnieuw proberen';

  @override
  String get gitUiGitMessage => 'Bericht ontvangen';

  @override
  String get gitUiCancelPrompt => 'Prompt annuleren';

  @override
  String get gitUiUseMessageAndContinue => 'Bericht gebruiken en doorgaan';

  @override
  String get gitUiRespondPrivately => 'Privé reageren';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Beeldvoorkeuren konden niet worden opgeslagen: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Conceptopslag committen: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Beeldvoorkeuren konden niet gelezen worden: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Commit concept werd bewaard in het geheugen maar kon niet worden opgeslagen: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'De beoordeelde repository is alleen-lezen voor deze operatie. Geschiedenis en inhoud inspectie blijven beschikbaar.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git gaf $arg0 terug. De toepassing kon de documenten niet vernieuwen: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Commit uit geschiedenis kiezen…';

  @override
  String get gitUiCurrentBranch => 'Huidige branch';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Geen overeenkomende branches of tags. Selecteer een commit in Log.';

  @override
  String get gitUiBranches => 'Branches';

  @override
  String get gitUiPushCommits => 'Commits pushen';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Trek in $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return '$arg0 oplossen';
  }

  @override
  String get gitUiCurrentOperation => 'Huidige bewerking';

  @override
  String get gitUiRebaseCommits => 'Commits rebasen';

  @override
  String get gitUiFetch2 => 'Ophalen…';

  @override
  String get gitUiPull => 'Pullen…';

  @override
  String get gitUiPush2 => 'Pushen…';

  @override
  String get gitUiBranches2 => 'Branches…';

  @override
  String get gitUiManageRemotes => 'Externe repositories beheren…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Samenvoegen in $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebasen…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Conflicten en huidige operatie...';

  @override
  String get gitUiStashes2 => 'Stashes…';

  @override
  String get gitUiWorktrees => 'Werkbomen…';

  @override
  String get gitUiSubmodules => 'Submodules…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog en herstel…';

  @override
  String get gitUiCloneRepository => 'Repository klonen…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Herroep repository trust';

  @override
  String get gitUiWaitingForRepositoryStatus => 'Wachten op repository status';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Repository-status is niet beschikbaar; vernieuwen';

  @override
  String get gitUiManageRemotes2 => 'Externe repositories beheren';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Samenvoegen in $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Werkbomen';

  @override
  String get gitUiSubmodules2 => 'Submodules';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog en herstel';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Kloon repository · $arg0';
  }

  @override
  String get gitUiApply => 'Toepassen';

  @override
  String get gitUiResizeGitPanes => 'Git-paneelgrootte wijzigen';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 procent';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Afsluitstatus: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repository is veranderd. Vernieuwen en herzien voordat u het opnieuw probeert.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Een andere bewerking bevat het archief of index slot. Wacht en verversen.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Voor deze operatie is vertrouwen in repository vereist.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'De Git-service is verbroken. Verbind de repository opnieuw en combineer deze.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Het geïnstalleerde Git uitvoerbare bestand kan deze bewerking niet ondersteunen. Bekijk hieronder de runtime eisen.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Deze repository is alleen-lezen voor de gevraagde bewerking. Review en geschiedenis blijven beschikbaar.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'De operatie moet worden gereconstrueerd. Bekijk de resulterende repository of remote state alvorens deze te herhalen.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Git-authenticatie is mislukt. Bekijk de credential helper of ontgrendel de geconfigureerde sleutelbos.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Verificatie van SSH-host is mislukt. Bekijk de identiteit van de host via uw geconfigureerde SSH-tools.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Ondertekenen van commit is mislukt of is geannuleerd. Bekijk de ondertekeningssleutel, agent en geconfigureerd ondertekeningsgereedschap.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Stel een naam en e-mail in van een repository auteur en keer dan terug naar het bewaard gebleven berichtontwerp.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git heeft de herziene update afgewezen. Vernieuw en bekijk de werkelijke bestemming voordat u het opnieuw probeert.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Wijzigingen werken of geënsceneerd voorkomen deze bewerking. Beoordelen, committen of expliciet opslaan.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Een vereist Git-object is niet beschikbaar. Bekijk ondiepe of gedeeltelijke-repository grenzen en haal expliciet indien nodig.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git-bewerking mislukt: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnostica';

  @override
  String get gitUiAuthorizeGitInspection => 'Machtig Git inspectie...';

  @override
  String get gitUiCopyDiagnostics => 'Kopiëren van diagnostiek';

  @override
  String get gitUiActions => 'Acties';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Branch op $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Maakt een lokale branch aan zonder het te controleren.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tag $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Alleen-lezen snapshot · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Cherry-pick commits';

  @override
  String get gitUiRevertCommits => 'Commits terugdraaien';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Vergelijk met volledige revisie-ID';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Boom vergelijking richting: $arg0 → de revisie hier ingevoerd.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Voer een volledig geldig object-ID in.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · boomvergelijking';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '$arg0 terugzetten naar $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Verplaatst HEAD/de huidige branch. Reflog herstelt geen willekeurige niet-gevolgde of niet-opgeslagen inhoud.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'HEAD verplaatsen; index en werkbestanden behouden.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'HEAD verplaatsen en index vervangen; werkbestanden behouden.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'HEAD, index en gevolgde werkbestanden vervangen; hinderende niet-gevolgde bestanden kunnen worden overschreven.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'HEAD, index en geschikte bestanden vervangen; weigeren als lokale wijzigingen verloren zouden gaan.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Reset met $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Bekijk de geselecteerde moduseffecten voordat u deze toepast.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '$arg0 resetten';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Doel $arg0';
  }

  @override
  String get gitUiTagName => 'Tagnaam';

  @override
  String get gitUiAnnotatedTag => 'Geannoteerde tag';

  @override
  String get gitUiCryptographicSigning => 'Cryptografische ondertekening';

  @override
  String get gitUiConfiguredPolicy => 'Geconfigureerd beleid';

  @override
  String get gitUiSignThisTag => 'Deze tag ondertekenen';

  @override
  String get gitUiDoNotSign => 'Niet ondertekenen';

  @override
  String get gitUiTagMessage => 'Tag-bericht';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Maakt de tag lokaal aan. Publiceer de geselecteerde tags expliciet in Push review.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Complete bomen: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Volgende gewijzigde bestandspagina';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Alleen-lezen repository snapshot. Het openen van een bestand controleert nooit deze revisie.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Alleen-lezen versie openen';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Dit pad herstellen... · Wachten op repositorystatus';

  @override
  String get gitUiRestoreThisPath => 'Dit pad herstellen...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Geschiedenis · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '$arg0 herstellen?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Vervang dit werkpad door revisie $arg0. Bestaande geënsceneerde inhoud wordt behouden.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Werkbestand herstellen';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Bestandsgeschiedenis volgt hernoemen · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Annotaties · vastgelegde inhoud';

  @override
  String get gitUiBlame => 'Annotaties…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Werkboom';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Alleen-lezen historisch bestand openen';

  @override
  String get gitUiCompareToCurrentFile => 'Vergelijk met het huidige bestand';

  @override
  String get gitUiCompareToParent => 'Vergelijk met ouder...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Toegewezen $arg0 · niet-opgeslagen editor inhoud maakt geen deel uit van deze annotaties';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Geschiedenis van $arg0';
  }

  @override
  String get gitUiBoundary => ' · grens';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nOorspronkelijke regel $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Vorige regels';

  @override
  String get gitUiNextLines => 'Volgende regels';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Expliciete aanvraag bestelling · bestemming $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID =>
      'Volledige commit-object-ID toevoegen';

  @override
  String get gitUiAddReviewedCommit => 'Herziene commit toevoegen...';

  @override
  String get gitUiMoveEarlier => 'Eerder verplaatsen';

  @override
  String get gitUiMoveLater => 'Later';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Verwijderen uit herziene volgorde';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Wijzigingen toepassen zonder commits aan te maken';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Gebruik deze expliciete hoofdregel moeder voor merge commits';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Lege of reeds toegepaste commits kunnen Git stoppen voor een expliciete beslissing om te springen of te vervolgen.';

  @override
  String get gitUiRevertInReviewedOrder => 'Terugdraaien in herziene volgorde';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Cherry-pick in herziene volgorde';

  @override
  String get gitUiReturnToFiles => 'Terug naar bestanden';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Committen';

  @override
  String get gitUiBackToCommit => 'Terug naar Commit';

  @override
  String get gitUiSelectAChangeToReview =>
      'Selecteer een wijziging om te bekijken';

  @override
  String get gitUiLoadingBranch => 'Tak wordt geladen...';

  @override
  String get gitUiBranchUnavailable => 'Tak niet beschikbaar';

  @override
  String get gitUiUnbornHEAD => 'HEAD zonder commits';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'Losgekoppelde HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'Doorgaan';

  @override
  String get gitUiPick => 'Behouden';

  @override
  String get gitUiReword => 'Bericht wijzigen';

  @override
  String get gitUiEdit => 'Bewerken';

  @override
  String get gitUiSquash => 'Combineren';

  @override
  String get gitUiFixup => 'Combineren zonder bericht';

  @override
  String get gitUiDrop => 'Overslaan';

  @override
  String get gitUiAbort => 'Afbreken';

  @override
  String get gitUiSkip => 'Overslaan';

  @override
  String get gitUiQuit => 'Opdracht afsluiten';

  @override
  String get gitUiSoft => 'Zacht';

  @override
  String get gitUiMixed => 'Gemengd';

  @override
  String get gitUiHard => 'Hard';

  @override
  String get gitUiKeep => 'Behouden';

  @override
  String get gitUiCreate => 'Maken';

  @override
  String get gitUiApplyStash => 'Stash toepassen';

  @override
  String get gitUiPopStash => 'Stash toepassen en bij succes verwijderen';

  @override
  String get gitUiDropStashAction => 'Stash verwijderen';

  @override
  String get gitUiEditedResult => 'Uitgegeven resultaat';

  @override
  String get gitUiLeftContent => 'Linkerinhoud';

  @override
  String get gitUiRightContent => 'Rechtse inhoud';

  @override
  String get gitUiDeletePath => 'Pad verwijderen';

  @override
  String get gitUiSubmoduleCommit => 'Submodule commit';

  @override
  String get gitUiPresentContent => 'Beschikbare inhoud';

  @override
  String get gitUiAbsentContent => 'Afwezig';

  @override
  String get gitUiBinaryContent => 'Binaire inhoud';

  @override
  String get gitUiTooLargeContent =>
      'Inhoud overschrijdt de limiet voor het weergeven';

  @override
  String get gitUiUnavailableContent => 'Niet-beschikbare inhoud';

  @override
  String get gitUiGitlinkContent => 'Submodule pointer';

  @override
  String get gitUiSymlinkContent => 'Symbolische koppeling';

  @override
  String get gitUiNoOperation => 'Geen bewerking';

  @override
  String get gitUiCherryPickOperation => 'Cherry-picken';

  @override
  String get gitUiRevertOperation => 'Terugdraaien';

  @override
  String get gitUiApplyMailboxOperation => 'Breng patches aan';

  @override
  String get gitUiSquashOperation => 'Squash samenvoegen';

  @override
  String get gitUiUnmergedOperation => 'Niet-samengevoegde index';

  @override
  String get gitUiWaitingForPromptPhase => 'Wachten op uw antwoord';

  @override
  String get gitUiStoppedPhase => 'Gestopt voor beoordeling';

  @override
  String get gitUiCompletedPhase => 'Voltooid';

  @override
  String get gitUiFailedPhase => 'Mislukt';

  @override
  String get gitUiCancelledPhase => 'Geannuleerd';

  @override
  String get gitUiUncertainPhase => 'Resultaat vereist verzoening';

  @override
  String gitUiStageVersion(String stage) {
    return 'Conflictfase $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Voorbeeld van samenvoegen git';

  @override
  String get gitUiNormalizedWorking => 'Werkboom · Git genormaliseerd';

  @override
  String gitUiPercentValue(String value) {
    return '$value procent';
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
  String get gitUiUtf8Bom => 'UTF-8 met bytevolgteken (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 zonder bytevolgteken (BOM)';

  @override
  String get gitUiAddsBom =>
      'Deze bewerking voegt een UTF-8 byte-order mark (BOM) toe aan het begin van het bestand.';

  @override
  String get gitUiRemovesBom =>
      'Deze bewerking verwijdert de UTF-8 byte-order mark (BOM) vanaf het begin van het bestand.';

  @override
  String get gitUiNoLineTerminators => 'Geen regelterminatoren';

  @override
  String gitUiLineEndings(String format) {
    return '$format-regeleinden';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Gemengde regeleinden ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · geen definitieve LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Line ending formaat wijzigingen van $before naar $after. Klembord tekst kan verschillende regeleinden van het oorspronkelijke bestand gebruiken.';
  }

  @override
  String get gitUiGitFailure =>
      'Git-operatie is mislukt. Bekijk de diagnostiek hieronder.';

  @override
  String get gitUiAbortInline => 'Afbreken';

  @override
  String get gitUiSkipInline => 'Overslaan';

  @override
  String get gitUiQuitInline => 'afsluiten';

  @override
  String get gitUiMergeInline => 'Samenvoegen';

  @override
  String get gitUiRebaseInline => 'Rebasen';

  @override
  String get gitUiCherryPickInline => 'Cherry-picken';

  @override
  String get gitUiRevertInline => 'Terugdraaien';

  @override
  String get gitUiApplyMailboxInline => 'applyMailbox';

  @override
  String get gitUiSquashInline => 'Combineren';

  @override
  String get gitUiUnmergedInline => 'ongemerged';

  @override
  String get gitHostFetch => 'Ophalen';

  @override
  String get gitHostRefreshGitStatus => 'Git-status vernieuwen';

  @override
  String get gitHostCommitStaged => 'Commit geënsceneerd';

  @override
  String get gitHostGitBranches => 'Git branches';

  @override
  String get gitHostReviewPush => 'Evaluatiepush';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git-bewerkingen zijn van toepassing op deze gehele repository en kunnen de geconfigureerde hooks, filters, credential en signing tools uitvoeren.';

  @override
  String get gitHostContentUnavailable => 'Inhoud niet beschikbaar';

  @override
  String get gitHostInitializeRepository => 'Git-repository initialiseren';

  @override
  String get gitHostCloneRepository => 'Repository klonen';

  @override
  String get gitHostInitializeHere => 'Initialiseren...';

  @override
  String get gitHostCloneRepository2 => 'Repository klonen…';

  @override
  String get gitHostGitLog => 'Log';

  @override
  String get gitUiAbsentPlaceholder => '(afwezig)';

  @override
  String get gitUiUnborn => 'ongeboren';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Gerebasete geschiedenis · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Huidige geschiedenis · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Opnieuw toegepaste commit · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Binnenkomende inhoud · $revision';
  }

  @override
  String get gitUiContentConflict => 'Inhoudsconflict';

  @override
  String get gitUiSubmoduleConflict => 'Conflict submodule';

  @override
  String get gitUiSymlinkConflict => 'Symbolische-link conflict';

  @override
  String get gitUiAddAddConflict => 'Aan beide zijden toegevoegd';

  @override
  String get gitUiModifyDeleteConflict =>
      'Gewijzigd/verwijderd of hernoemd/verwijderd';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
