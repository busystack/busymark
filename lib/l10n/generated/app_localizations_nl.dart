// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

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
  String get commandPalette => 'Commandopalet';

  @override
  String get commandPaletteHint => 'Typ een opdracht';

  @override
  String get commandPaletteEmpty => 'Geen overeenkomende opdrachten';

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
  String get pasteWithoutFormatting => 'Plakken zonder opmaak';

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
      'Toon deze sneltoetsreferentie';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Open de Markdown- en HTML-referentie';

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
  String get editorFontSize => 'Lettergrootte van de editor';

  @override
  String get validateOnEdit => 'Valideren bij bewerken';

  @override
  String get clearRecentWorkspaces => 'Wis recente werkruimten';

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
  String get toc => 'TOC';

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
  String get newSiblingTopic => 'Nieuw naastliggend onderwerp';

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
  String get reviewUsages => 'Gebruik controleren';

  @override
  String get deleteTopicFile => 'Onderwerpbestand verwijderen';

  @override
  String get removeAction => 'Verwijderen';

  @override
  String topicRemovalSummary(String topic) {
    return 'Verwijder “$topic” uit de geselecteerde instantie. Het onderwerpbestand wordt bewaard.';
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
  String get topicIsStartPageRemovalWarning =>
      'Dit onderwerp wordt gebruikt als startpagina van een instantie. Controleer het gebruik ervan en wijs een andere startpagina toe voordat u verdergaat.';

  @override
  String topicUsagesCount(int count) {
    return 'Gebruik ($count)';
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
  String get topicUsageStartPages => 'Startpagina\'s';

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
  String get setRedirectTo => 'Omleiding instellen naar';

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
  String get sourceSearchCaseSensitive => 'Hoofdlettergevoelig';

  @override
  String get sourceSearchWholeWord => 'Heel woord';

  @override
  String get sourceSearchRegex => 'Regex';

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
  String get sourceSearchInvalidRegex => 'Ongeldige reguliere expressie';

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
    return 'Het startonderwerp $topic kan niet worden verwijderd. Kies eerst een andere startpagina.';
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
  String get markdownAndHtml => 'Markdown en HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown-blokken';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Blokstructuren ondersteund in Markdown-bron en preview.';

  @override
  String get markdownHtmlInlineFormatting => 'Inline-opmaak';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Opmaak die kan verschijnen in alinea\'s, lijstitems en tabelcellen.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Ruwe HTML-blokken';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Veilige HTML-tags op blokniveau weergegeven via BusyMark-voorbeeldwidgets.';

  @override
  String get markdownHtmlRawHtmlInline => 'Onbewerkte HTML-inlinetags';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Veilige inline HTML-tags weergegeven zonder letterlijke tags weer te geven.';

  @override
  String get markdownHtmlSafety => 'Veiligheidsregels';

  @override
  String get markdownHtmlSafetyDescription =>
      'Onbewerkte HTML wordt geparseerd en opgeschoond voordat de preview wordt weergegeven.';

  @override
  String get markdownHtmlHeadings => 'Koppen';

  @override
  String get markdownHtmlParagraphs => 'Paragrafen';

  @override
  String get markdownHtmlLists => 'Lijsten';

  @override
  String get markdownHtmlHtmlContainers => 'Containers';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Tekstblokken';

  @override
  String get markdownHtmlHtmlFigures => 'Figuren en afbeeldingen';

  @override
  String get markdownHtmlHtmlPreformatted => 'Voorgeformatteerde code';

  @override
  String get markdownHtmlHtmlDisclosure => 'Openklapbare blokken';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Beschrijvingslijsten';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Opmaaktags';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Inline codetags';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Semantische inline-tags';

  @override
  String get markdownHtmlSanitizedPreview => 'Opgeschoond voorbeeld';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Toegestane HTML wordt geconverteerd naar BusyMark-voorbeeldblokken en niet weergegeven in een browser.';

  @override
  String get markdownHtmlSourcePreserved => 'Bron behouden';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Ruwe HTML wordt exact als brontekst opgeslagen.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown binnen HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown-markeringen in onbewerkte HTML worden weergegeven als letterlijke tekst.';

  @override
  String get markdownHtmlBlockedContent => 'Actieve inhoud geblokkeerd';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Scripts, stijlen, frames, formulieren, SVG, MathML, gebeurtenissen en onveilige attributen worden geblokkeerd.';

  @override
  String get markdownHtmlSafeUrls => 'Alleen veilige URL\'s';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Links staan http-, https-, mailto-, tel-, relatieve en fragment-URL\'s toe; onveilige schema\'s worden geblokkeerd.';

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
  String get openTocFile => 'TOC-bestand openen';

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
  String get generateOrUpdateMarkdownToc => 'Inhoudsopgave genereren/bijwerken';

  @override
  String get markdownTocTitle => 'Inhoudsopgave';

  @override
  String markdownTocUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vermeldingen',
      one: '1 vermelding',
    );
    return 'Inhoudsopgave bijgewerkt met $_temp0.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Voeg ten minste één sectiekop toe voordat u een inhoudsopgave genereert.';

  @override
  String get markdownTocMalformedMarkers =>
      'De BusyMark-inhoudsopgavemarkeringen ontbreken, zijn gedupliceerd of zijn niet in de juiste volgorde.';

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
}
