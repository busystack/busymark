// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

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
  String get commandPalette => 'Kommandopalett';

  @override
  String get commandPaletteHint => 'Skriv inn en kommando';

  @override
  String get commandPaletteEmpty => 'Ingen samsvarende kommandoer';

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
  String get pasteWithoutFormatting => 'Lim inn uten formatering';

  @override
  String get reading => 'Lesevisning';

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
      'Vis denne oversikten over tastatursnarveier';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Åpne Markdown- og HTML-referansen';

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
  String get editorFontSize => 'Skriftstørrelse i redigereren';

  @override
  String get validateOnEdit => 'Valider under redigering';

  @override
  String get clearRecentWorkspaces => 'Tøm nylige arbeidsområder';

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
  String get settingsWindowSectionTitle => 'Vindu';

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
    return '$count dokumenter har ulagrede endringer. Lagre dem før du fortsetter?';
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
  String get newSiblingTopic => 'Nytt emne på samme nivå';

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
  String get reviewUsages => 'Se gjennom bruk';

  @override
  String get deleteTopicFile => 'Slett emnefil';

  @override
  String get removeAction => 'Fjern';

  @override
  String topicRemovalSummary(String topic) {
    return 'Fjern «$topic» fra den valgte instansen. Emnefilen beholdes.';
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
  String get topicIsStartPageRemovalWarning =>
      'Dette emnet brukes som startside for en instans. Se gjennom bruken, og angi en annen startside før du fortsetter.';

  @override
  String topicUsagesCount(int count) {
    return 'Bruk ($count)';
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
  String get setRedirectTo => 'Omdiriger til';

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
  String get sourceSearchCaseSensitive => 'Skill mellom store og små bokstaver';

  @override
  String get sourceSearchWholeWord => 'Hele ord';

  @override
  String get sourceSearchRegex => 'Regulært uttrykk';

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
  String get sourceSearchInvalidRegex => 'Ugyldig regulært uttrykk';

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
    return '$count ulagrede dokumenter ble gjenopprettet. Se gjennom hvert gjenopprettet dokument før du fortsetter.';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    return '$count skadede gjenopprettingsoppføringer kunne ikke gjenopprettes. Gyldige gjenopprettede dokumenter er fortsatt tilgjengelige.';
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
    return 'Startemnet $topic kan ikke slettes. Velg en annen startside først.';
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
      other: 'De valgte sporede filene gjenopprettes fra Git.',
      one: 'Den valgte sporede filen gjenopprettes fra Git.',
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
  String get gitProjectHistory => 'Prosjekt';

  @override
  String get gitFileHistory => 'Gjeldende fil';

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
  String get gitErrorAuthentication => 'Git-autentisering mislyktes.';

  @override
  String get gitErrorNetwork => 'Git-nettverksoperasjonen mislyktes.';

  @override
  String get gitErrorConflict => 'Git rapporterte uløste konflikter.';

  @override
  String get gitErrorCommandFailed => 'Git-kommandoen mislyktes.';

  @override
  String get markdownAndHtml => 'Markdown og HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown-blokker';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Blokkstrukturer som støttes i Markdown-kilde og forhåndsvisning.';

  @override
  String get markdownHtmlInlineFormatting => 'Inline-Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formatering i avsnitt, listeelementer og tabellceller.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Rå HTML-blokker';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Trygge HTML-blokktagger rendres med BusyMark-forhåndsvisning.';

  @override
  String get markdownHtmlRawHtmlInline => 'Rå HTML-inline-tagger';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Trygge inline-HTML-tagger rendres uten å vise taggene bokstavelig.';

  @override
  String get markdownHtmlSafety => 'Sikkerhetsregler';

  @override
  String get markdownHtmlSafetyDescription =>
      'Rå HTML analyseres og renses før forhåndsvisning.';

  @override
  String get markdownHtmlHeadings => 'Overskrifter';

  @override
  String get markdownHtmlParagraphs => 'Avsnitt';

  @override
  String get markdownHtmlLists => 'Lister';

  @override
  String get markdownHtmlHtmlContainers => 'Beholdere';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Tekstblokker';

  @override
  String get markdownHtmlHtmlFigures => 'Figurer og bilder';

  @override
  String get markdownHtmlHtmlPreformatted => 'Forhåndsformatert kode';

  @override
  String get markdownHtmlHtmlDisclosure => 'Utvidbare blokker';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Beskrivelseslister';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Formateringstagger';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Inline-kodetagger';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Semantiske teksttagger';

  @override
  String get markdownHtmlSanitizedPreview => 'Renset forhåndsvisning';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Tillatt HTML konverteres til BusyMark-forhåndsvisningsblokker og rendres ikke i en nettleser.';

  @override
  String get markdownHtmlSourcePreserved => 'Kilden bevares';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Uendret rå HTML lagres nøyaktig som kildetekst.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown inni HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown-markører inni rå HTML vises som bokstavelig tekst.';

  @override
  String get markdownHtmlBlockedContent => 'Blokkert aktivt innhold';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Skript, stiler, rammer, skjemaer, SVG, MathML, hendelser og usikre attributter blokkeres.';

  @override
  String get markdownHtmlSafeUrls => 'Bare trygge URL-er';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Lenker tillater http, https, mailto, tel, relative URL-er og fragmenter; usikre URI-skjemaer blokkeres.';

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
  String get exportingPdf => 'Eksporterer PDF…';

  @override
  String get fileTypePdf => 'PDF-dokument';

  @override
  String pdfExported(String fileName) {
    return '$fileName ble eksportert.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return '$fileName ble eksportert. Bilder som ikke kunne tas med: $count.';
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
  String get aiLocalOnlyDescription =>
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
  String get generateOrUpdateMarkdownToc =>
      'Generer/oppdater innholdsfortegnelse';

  @override
  String get markdownTocTitle => 'Innholdsfortegnelse';

  @override
  String markdownTocUpdated(int count) {
    return 'Innholdsfortegnelsen ble oppdatert med $count oppføringer.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Legg til minst én seksjonsoverskrift før du genererer en innholdsfortegnelse.';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMark-markørene for innholdsfortegnelsen mangler, er duplisert eller står i feil rekkefølge.';

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
}
