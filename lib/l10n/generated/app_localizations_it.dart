// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor per file Markdown e progetti di documentazione compatibili con Writerside.';

  @override
  String get aboutBusyMark => 'Informazioni su BusyMark';

  @override
  String get aboutTagline => 'Editor Markdown e Writerside';

  @override
  String get aboutLicenseLabel => 'Licenza';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Sito web';

  @override
  String get aboutSourceCode => 'Codice sorgente';

  @override
  String get reportIssue => 'Segnala un problema';

  @override
  String get feedbackCategory => 'Categoria';

  @override
  String get feedbackChooseCategory => 'Scegli una categoria';

  @override
  String get feedbackCategoryProblem => 'Problema o errore';

  @override
  String get feedbackCategoryFeature => 'Richiesta di funzionalità';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Problema di privacy o sicurezza';

  @override
  String get feedbackCategoryUsability => 'Problema di usabilità';

  @override
  String get feedbackCategoryOther => 'Altro';

  @override
  String get feedbackSubject => 'Oggetto';

  @override
  String get feedbackMessage => 'Messaggio dettagliato';

  @override
  String get feedbackReplyEmail => 'E-mail per la risposta (facoltativa)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Includi dettagli tecnici';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Quando questa opzione è attiva, vengono aggiunti solo la versione del sistema operativo Linux e le impostazioni locali dell’applicazione BusyMark. Non vengono allegati registri, file, dati dell’account o altri dati diagnostici.';

  @override
  String get feedbackSubmit => 'Invia';

  @override
  String get feedbackSubmitting => 'Invio in corso…';

  @override
  String get feedbackCategoryRequired => 'Scegli una categoria.';

  @override
  String get feedbackSubjectLength =>
      'L’oggetto deve contenere tra 3 e 120 caratteri.';

  @override
  String get feedbackMessageLength =>
      'Il messaggio deve contenere tra 10 e 5.000 caratteri.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Inserisci un indirizzo e-mail valido o lascia vuoto questo campo.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark non è riuscito a connettersi. Controlla la connessione Internet e riprova.';

  @override
  String get feedbackTimeoutFailure => 'La richiesta è scaduta. Riprova.';

  @override
  String get feedbackRateLimitedFailure =>
      'Sono state inviate troppe segnalazioni da questa connessione. Attendi e riprova.';

  @override
  String get feedbackRejectedFailure =>
      'Il server ha rifiutato la segnalazione. Controlla i campi del modulo e riprova.';

  @override
  String get feedbackServerFailure =>
      'Il server non ha potuto accettare la segnalazione. Riprova più tardi.';

  @override
  String feedbackSuccess(String id) {
    return 'Feedback inviato. ID di riferimento: $id';
  }

  @override
  String get advanced => 'Avanzate';

  @override
  String get addToGit => 'Aggiungi a Git';

  @override
  String get appearance => 'Aspetto';

  @override
  String get apply => 'Applica';

  @override
  String get back => 'Indietro';

  @override
  String get bottomLeft => 'In basso a sinistra';

  @override
  String get bottomRight => 'In basso a destra';

  @override
  String get cancel => 'Annulla';

  @override
  String get choose => 'Scegli';

  @override
  String get chooseLocation => 'Scegli la posizione';

  @override
  String get copy => 'Copia';

  @override
  String get copyName => 'Copia nome';

  @override
  String get copyFileName => 'Copia nome file';

  @override
  String get copyPath => 'Copia percorso';

  @override
  String get create => 'Crea';

  @override
  String get creating => 'Creazione...';

  @override
  String get cut => 'Taglia';

  @override
  String get promoteSection => 'Promuovi sezione';

  @override
  String get demoteSection => 'Retrocedi sezione';

  @override
  String get moveSectionUp => 'Sposta sezione in alto';

  @override
  String get moveSectionDown => 'Sposta sezione in basso';

  @override
  String get confirmDeleteSectionTitle => 'Eliminare la sezione?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Eliminare «$name» e tutto il contenuto della sua sezione? Questa operazione non può essere annullata.';
  }

  @override
  String get darkTheme => 'Scuro';

  @override
  String get delete => 'Elimina';

  @override
  String get discard => 'Scarta';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'File';

  @override
  String get fileHistory => 'Cronologia file';

  @override
  String get folder => 'Cartella';

  @override
  String get insert => 'Inserisci';

  @override
  String get keyboardShortcuts => 'Scorciatoie da tastiera';

  @override
  String get commandPalette => 'Tavolozza dei comandi';

  @override
  String get commandPaletteHint => 'Digita un comando';

  @override
  String get commandPaletteEmpty => 'Nessun comando corrispondente';

  @override
  String get commandUnavailableInContext =>
      'Questo comando non è disponibile nel contesto corrente.';

  @override
  String get lightTheme => 'Chiaro';

  @override
  String get mainMenu => 'Menu principale';

  @override
  String get fullScreen => 'Schermo intero';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Apri';

  @override
  String get openInFiles => 'Apri in File';

  @override
  String get pathActions => 'Azioni sul percorso';

  @override
  String get outline => 'Struttura';

  @override
  String get overwrite => 'Sovrascrivi';

  @override
  String get paste => 'Incolla';

  @override
  String get pasteWithoutFormatting => 'Incolla senza formattazione';

  @override
  String get reading => 'Lettura';

  @override
  String get recent => 'Recenti';

  @override
  String get redo => 'Ripeti';

  @override
  String get save => 'Salva';

  @override
  String get search => 'Ricerca';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get settings => 'Impostazioni';

  @override
  String get source => 'Sorgente';

  @override
  String get split => 'Divisa';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get theme => 'Tema';

  @override
  String get appLanguage => 'Lingua';

  @override
  String get systemLanguage => 'Sistema';

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
  String get toggleSidebar => 'Pannello laterale';

  @override
  String get topLeft => 'In alto a sinistra';

  @override
  String get topRight => 'In alto a destra';

  @override
  String get undo => 'Annulla';

  @override
  String get validate => 'Convalida';

  @override
  String get validation => 'Convalida';

  @override
  String get viewMode => 'Modalità di visualizzazione';

  @override
  String get welcome => 'Benvenuto';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Immagini';

  @override
  String get openMarkdownFile => 'Apri file Markdown';

  @override
  String get markdownFileExtensions => '.md o .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Apri cartella o progetto Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Cartella Markdown o progetto compatibile con Writerside';

  @override
  String get noOpenFile => 'Nessun file aperto';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Elimina l\'elemento selezionato in File oppure rimuovi l\'argomento selezionato dal sommario';

  @override
  String get shortcutGroupGeneral => 'Generale';

  @override
  String get shortcutNewDocument => 'Crea';

  @override
  String get shortcutNewDocumentDescription =>
      'Crea un file Markdown o un progetto Writerside';

  @override
  String get shortcutOpenDescription =>
      'Apri un file Markdown, una cartella o un progetto Writerside';

  @override
  String get shortcutSaveDescription => 'Salva il documento corrente';

  @override
  String get shortcutSearchDescription => 'Cerca nell\'area di lavoro corrente';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Mostra il riferimento alle scorciatoie da tastiera';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Apri il riferimento Markdown e HTML';

  @override
  String get shortcutSettingsDescription => 'Apri le impostazioni di BusyMark';

  @override
  String get shortcutNextTab => 'Scheda successiva';

  @override
  String get shortcutNextTabDescription =>
      'Passa alla scheda aperta successiva';

  @override
  String get shortcutPreviousTab => 'Scheda precedente';

  @override
  String get shortcutPreviousTabDescription =>
      'Passa alla scheda aperta precedente';

  @override
  String get shortcutCloseTab => 'Chiudi scheda';

  @override
  String get shortcutCloseTabDescription => 'Chiudi la scheda attiva';

  @override
  String get shortcutCloseAllTabs => 'Chiudi tutte le schede';

  @override
  String get shortcutCloseAllTabsDescription => 'Chiudi tutte le schede aperte';

  @override
  String get shortcutGroupTextEditing => 'Modifica del testo';

  @override
  String get shortcutSelectAllDescription =>
      'In modalità Sorgente, seleziona tutto il testo; in modalità Editor, premi due volte per selezionare tutti i blocchi';

  @override
  String get shortcutCutDescription => 'Taglia il testo selezionato';

  @override
  String get shortcutCopyDescription => 'Copia il testo selezionato';

  @override
  String get shortcutPasteDescription => 'Incolla dagli appunti';

  @override
  String get shortcutPastePlainTextDescription =>
      'Incolla il testo degli appunti senza formattazione';

  @override
  String get shortcutUndoDescription => 'Annulla l\'ultima modifica';

  @override
  String get shortcutRedoDescription => 'Ripeti l\'ultima modifica annullata';

  @override
  String get shortcutInsertIndentation => 'Inserisci rientro';

  @override
  String get shortcutInsertIndentationDescription =>
      'Inserisci un rientro in corrispondenza del cursore';

  @override
  String get shortcutOutdentSource => 'Riduci rientro del sorgente';

  @override
  String get shortcutOutdentSourceDescription =>
      'Rimuovi un livello di rientro in modalità Sorgente';

  @override
  String get shortcutEscape =>
      'Chiudi la ricerca o annulla la selezione dei blocchi';

  @override
  String get shortcutEscapeDescription =>
      'Chiudi la ricerca nell\'area di lavoro o annulla una selezione di blocchi in modalità Editor';

  @override
  String get shortcutGroupFormatting => 'Formattazione';

  @override
  String get shortcutBoldDescription =>
      'Attiva/disattiva il grassetto per il testo selezionato';

  @override
  String get shortcutItalicDescription =>
      'Attiva/disattiva il corsivo per il testo selezionato';

  @override
  String get shortcutUnderlineDescription =>
      'Attiva/disattiva la sottolineatura per il testo selezionato';

  @override
  String get shortcutLinkDescription => 'Inserisci o modifica un collegamento';

  @override
  String get shortcutInlineCodeDescription =>
      'Attiva/disattiva il codice in linea per il testo selezionato';

  @override
  String get shortcutStrikethroughDescription =>
      'Attiva/disattiva la barratura per il testo selezionato';

  @override
  String get shortcutGroupBlocks => 'Blocchi';

  @override
  String get shortcutParagraphDescription =>
      'Imposta il blocco corrente come paragrafo';

  @override
  String get shortcutHeading1Description =>
      'Imposta il blocco corrente come Titolo 1';

  @override
  String get shortcutHeading2Description =>
      'Imposta il blocco corrente come Titolo 2';

  @override
  String get shortcutHeading3Description =>
      'Imposta il blocco corrente come Titolo 3';

  @override
  String get shortcutHeading4Description =>
      'Imposta il blocco corrente come Titolo 4';

  @override
  String get shortcutHeading5Description =>
      'Imposta il blocco corrente come Titolo 5';

  @override
  String get shortcutHeading6Description =>
      'Imposta il blocco corrente come Titolo 6';

  @override
  String get shortcutGroupLists => 'Elenchi';

  @override
  String get numberedList => 'Elenco numerato';

  @override
  String get shortcutNumberedListDescription =>
      'Attiva/disattiva la formattazione come elenco numerato';

  @override
  String get bulletedList => 'Elenco puntato';

  @override
  String get shortcutBulletedListDescription =>
      'Attiva/disattiva la formattazione come elenco puntato';

  @override
  String get checklist => 'Checklist';

  @override
  String get shortcutChecklistDescription =>
      'Attiva/disattiva la formattazione come checklist';

  @override
  String get shortcutGroupSidebar => 'Barra laterale';

  @override
  String get sidebarViewMenu => 'Vista barra laterale';

  @override
  String get createMarkdownFile => 'Crea file Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Crea un documento Markdown locale non salvato';

  @override
  String get createWritersideProject => 'Crea un progetto Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Crea un progetto locale compatibile con Writerside';

  @override
  String get defaultProjectName => 'Documentazione';

  @override
  String get defaultInstanceName => 'Guida per l\'utente';

  @override
  String get defaultStartTopicTitle => 'Per iniziare';

  @override
  String get projectName => 'Nome del progetto';

  @override
  String get directoryName => 'Nome della directory';

  @override
  String get instanceName => 'Nome dell\'istanza';

  @override
  String get instanceId => 'ID istanza';

  @override
  String get startTopicTitle => 'Titolo dell\'argomento iniziale';

  @override
  String get location => 'Posizione';

  @override
  String get projectNameRequired => 'Il nome del progetto è obbligatorio.';

  @override
  String get directoryNameRequired => 'Il nome della directory è obbligatorio.';

  @override
  String get useSingleSafeDirectoryName =>
      'Usa un singolo nome di directory sicuro.';

  @override
  String get useLowercaseIdentifier =>
      'Usa un identificatore in minuscolo composto da lettere, numeri, trattini bassi o trattini.';

  @override
  String get startTopicTitleRequired =>
      'Il titolo dell\'argomento iniziale è obbligatorio.';

  @override
  String get createWritersideProjectFailed =>
      'Impossibile creare il progetto Writerside.';

  @override
  String get settingsTitle => 'Impostazioni di BusyMark';

  @override
  String get autoSave => 'Salvataggio automatico';

  @override
  String get autoSaveDescription =>
      'Salva automaticamente le modifiche ai file dopo una breve pausa di inattività.';

  @override
  String get wordWrap => 'A capo automatico';

  @override
  String get editorFontSize => 'Dimensione del carattere dell\'editor';

  @override
  String get validateOnEdit => 'Convalida durante la modifica';

  @override
  String get clearRecentWorkspaces => 'Cancella le aree di lavoro recenti';

  @override
  String get editingButtonsPosition => 'Posizione dei pulsanti di modifica';

  @override
  String get editingButtonsPositionDescription =>
      'Scegli dove visualizzare i pulsanti mobili di modifica WYSIWYG.';

  @override
  String get editingButtonsDirection => 'Orientamento dei pulsanti di modifica';

  @override
  String get editingButtonsDirectionDescription =>
      'Scegli se disporre i pulsanti mobili di modifica WYSIWYG in orizzontale o in verticale.';

  @override
  String get horizontal => 'Orizzontale';

  @override
  String get vertical => 'Verticale';

  @override
  String get privacy => 'Privacy';

  @override
  String get allowRemoteImages => 'Carica immagini remote';

  @override
  String get allowRemoteImagesDescription =>
      'Consenti all’anteprima Markdown e all’editor di caricare immagini da URL HTTP e HTTPS.';

  @override
  String get clearRemoteImagePermissions =>
      'Cancella autorizzazioni per immagini remote';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Dimentica le aree di lavoro autorizzate a caricare immagini remote.';

  @override
  String get clearGitWorkspaceTrust =>
      'Cancella aree di lavoro Git attendibili';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Chiedi conferma prima di attivare le funzionalità Git per le aree di lavoro considerate attendibili in precedenza.';

  @override
  String get settingsWindowSectionTitle => 'Finestra';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Conferma prima di chiudere con modifiche non salvate';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Chiedi conferma prima di chiudere BusyMark quando i documenti hanno modifiche non salvate.';

  @override
  String get closeUnsavedChangesTitle => 'Modifiche non salvate';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Questo documento contiene modifiche non salvate. Salvare le modifiche prima di chiudere BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documenti contengono modifiche non salvate. Salvare le modifiche prima di chiudere BusyMark?',
      one:
          '1 documento contiene modifiche non salvate. Salvare le modifiche prima di chiudere BusyMark?',
      zero: 'Salvare le modifiche prima di chiudere BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Annulla';

  @override
  String get closeUnsavedChangesDiscard => 'Scarta';

  @override
  String get closeUnsavedChangesSave => 'Salva';

  @override
  String get currentFile => 'file corrente';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Sono presenti modifiche non salvate in $fileName. Salvarle prima di continuare?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    return '$count documenti contengono modifiche non salvate. Salvarli prima di continuare?';
  }

  @override
  String get fileChangedOnDisk => 'File modificato su disco';

  @override
  String get fileChangedOnDiskMessage =>
      'Questo file è stato modificato su disco da quando è stato aperto. Sovrascriverlo?';

  @override
  String get untitledMarkdownFileName => 'Senza titolo.md';

  @override
  String get unorderedList => 'Elenco non ordinato';

  @override
  String get orderedList => 'Elenco ordinato';

  @override
  String get taskList => 'Elenco attività';

  @override
  String get toggleTaskChecked => 'Seleziona/deseleziona attività';

  @override
  String get indentListItem => 'Aumenta il rientro dell\'elemento elenco';

  @override
  String get outdentListItem => 'Riduci il rientro dell\'elemento elenco';

  @override
  String get blockquote => 'Citazione';

  @override
  String get codeBlock => 'Blocco di codice';

  @override
  String get codeBlockLanguage => 'Linguaggio del blocco di codice';

  @override
  String get image => 'Immagine';

  @override
  String get inlineImage => 'Immagine in linea';

  @override
  String get table => 'Tabella';

  @override
  String get htmlBlock => 'Blocco HTML';

  @override
  String get htmlContentDefault => 'Contenuto HTML';

  @override
  String get shortcutHtmlBlockDescription =>
      'Inserisci o modifica un blocco HTML';

  @override
  String get renderedHtml => 'HTML renderizzato';

  @override
  String get editHtml => 'Modifica HTML';

  @override
  String get htmlSource => 'Codice sorgente HTML';

  @override
  String get thematicBreak => 'Separatore tematico';

  @override
  String get bold => 'Grassetto';

  @override
  String get italic => 'Corsivo';

  @override
  String get underline => 'Sottolineato';

  @override
  String get strikethrough => 'Barrato';

  @override
  String get inlineCode => 'Codice in linea';

  @override
  String get link => 'Collegamento';

  @override
  String get hardLineBreak => 'Interruzione di riga forzata';

  @override
  String get textStyle => 'Stile del testo';

  @override
  String get paragraph => 'Paragrafo';

  @override
  String get heading1 => 'Titolo 1';

  @override
  String get heading2 => 'Titolo 2';

  @override
  String get heading3 => 'Titolo 3';

  @override
  String get heading4 => 'Titolo 4';

  @override
  String get heading5 => 'Titolo 5';

  @override
  String get heading6 => 'Titolo 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Elimina tabella';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Colonna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Inserisci colonna a sinistra';

  @override
  String get insertColumnRight => 'Inserisci colonna a destra';

  @override
  String get deleteColumn => 'Elimina colonna';

  @override
  String get tableAlignmentUnspecified => 'Allineamento: non specificato';

  @override
  String get tableAlignmentLeft => 'Allineamento: sinistra';

  @override
  String get tableAlignmentCenter => 'Allineamento: centro';

  @override
  String get tableAlignmentRight => 'Allineamento: destra';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Riga $rowNumber';
  }

  @override
  String get insertRowAbove => 'Inserisci riga sopra';

  @override
  String get insertRowBelow => 'Inserisci riga sotto';

  @override
  String get deleteRow => 'Elimina riga';

  @override
  String get tableHeaderHint => 'Intestazione';

  @override
  String get tableCellHint => 'Cella';

  @override
  String get language => 'Linguaggio';

  @override
  String get hideEditingButtons => 'Nascondi i pulsanti di modifica';

  @override
  String get showEditingButtons => 'Mostra i pulsanti di modifica';

  @override
  String get altText => 'Testo alternativo';

  @override
  String get editorPlaceholderText => 'testo';

  @override
  String get editorPlaceholderCode => 'codice';

  @override
  String get editorPlaceholderAltText => 'testo alternativo';

  @override
  String get describeTheImage => 'Descrivi l\'immagine';

  @override
  String get columns => 'Colonne';

  @override
  String get rows => 'Righe';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Intestazione $columnNumber';
  }

  @override
  String get tableCellDefault => 'Cella';

  @override
  String get noImageSource => 'Nessuna sorgente dell\'immagine';

  @override
  String get remoteImageBlocked => 'Immagine remota bloccata';

  @override
  String get remoteImageBlockedTooltip =>
      'Scegli se BusyMark può caricare immagini remote.';

  @override
  String get remoteImagesBlockedTitle => 'Le immagini remote sono bloccate';

  @override
  String get remoteImagesBlockedMessage =>
      'Questo documento fa riferimento a immagini su Internet. Il caricamento può rivelare informazioni di rete all’host delle immagini.';

  @override
  String get loadRemoteImagesForWorkspace => 'Carica per quest’area di lavoro';

  @override
  String get alwaysLoadRemoteImages => 'Carica sempre le immagini remote';

  @override
  String get hideSidebar => 'Nascondi il pannello laterale';

  @override
  String get showSidebar => 'Mostra il pannello laterale';

  @override
  String get showPreview => 'Mostra l\'anteprima';

  @override
  String get hidePreview => 'Nascondi l\'anteprima';

  @override
  String get workspaceKindUnsavedMarkdown => 'File Markdown non salvato';

  @override
  String get workspaceKindSingleMarkdown => 'Singolo file Markdown';

  @override
  String get workspaceKindMarkdownFolder => 'Cartella Markdown';

  @override
  String get workspaceKindWritersideModule => 'Modulo Writerside';

  @override
  String get problems => 'Problemi';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi diagnostici',
      one: '1 messaggio diagnostico',
      zero: 'Nessun messaggio diagnostico',
    );
    return '$_temp0';
  }

  @override
  String get files => 'File';

  @override
  String get toc => 'TOC';

  @override
  String get tocActions => 'Azioni dell\'indice';

  @override
  String get markdownUnsaved => 'Markdown - non salvato';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file',
      one: '1 file',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Nessun file';

  @override
  String get newFile => 'Nuovo file';

  @override
  String get noWritersideToc => 'Nessun TOC Writerside';

  @override
  String get tocSection => 'Sezione TOC';

  @override
  String get newTopic => 'Nuovo argomento';

  @override
  String get newChildTopic => 'Nuovo sottoargomento';

  @override
  String get newSiblingTopic => 'Nuovo argomento allo stesso livello';

  @override
  String get renameTopicFile => 'Rinomina il file dell\'argomento';

  @override
  String get topicPlacement => 'Posizione nel TOC';

  @override
  String get tocRoot => 'Alla radice del TOC';

  @override
  String get afterSelectedTopic => 'Dopo l\'argomento selezionato';

  @override
  String get insideSelectedTopic => 'All\'interno dell\'argomento selezionato';

  @override
  String get pasteAfterTopic => 'Incolla dopo';

  @override
  String get pasteAsChildTopic => 'Incolla come sottoargomento';

  @override
  String get removeFromToc => 'Rimuovi dal TOC';

  @override
  String get confirmRemoveFromTocTitle => 'Rimuovere dal TOC?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Rimuovere $name da questo TOC? Il file dell\'argomento verrà mantenuto.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Eliminare il file dell\'argomento?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Eliminare $name e rimuoverlo da tutti i TOC? Questa operazione non può essere annullata.';
  }

  @override
  String get safeDeleteTopicFile =>
      'Elimina in modo sicuro il file dell’argomento…';

  @override
  String get removeTocElement => 'Rimuovi elemento dal TOC';

  @override
  String get reviewUsages => 'Esamina utilizzi';

  @override
  String get deleteTopicFile => 'Elimina file dell’argomento';

  @override
  String get removeAction => 'Rimuovi';

  @override
  String topicRemovalSummary(String topic) {
    return 'Rimuovi «$topic» dall’istanza selezionata. Il file dell’argomento verrà conservato.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Elimina «$topic» e ne aggiorna in modo sicuro i riferimenti nell’intero progetto Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count argomenti secondari verranno spostati un livello più in alto.',
      one: '1 argomento secondario verrà spostato un livello più in alto.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Questo argomento è utilizzato come pagina iniziale di un’istanza. Esaminane gli utilizzi e assegna un’altra pagina iniziale prima di continuare.';

  @override
  String topicUsagesCount(int count) {
    return 'Utilizzi ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Non sono stati trovati riferimenti che smetterebbero di funzionare.';

  @override
  String get topicUsagesFound =>
      'BusyMark ha trovato i seguenti riferimenti a questo argomento.';

  @override
  String get topicUsageTocElements => 'Elementi del TOC';

  @override
  String get topicUsageStartPages => 'Pagine iniziali';

  @override
  String get topicUsageTopicLinks => 'Collegamenti agli argomenti';

  @override
  String get topicUsageIncludes => 'Inclusioni';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilizzi',
      one: '1 utilizzo',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Opzioni di refactoring';

  @override
  String get updateUsagesAutomatically =>
      'Aggiorna automaticamente gli utilizzi';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Rimuove i riferimenti dai TOC e le inclusioni, mantenendo il testo dei collegamenti.';

  @override
  String get manualUsageUpdatesRequired =>
      'Alcuni utilizzi richiedono modifiche manuali prima di questo refactoring.';

  @override
  String get setRedirectTo => 'Reindirizza a';

  @override
  String get noRedirectDescription =>
      'Non reindirizzare la vecchia pagina pubblicata.';

  @override
  String get redirectTarget => 'Destinazione del reindirizzamento';

  @override
  String get remainingUsagesBlockRemoval =>
      'Esamina e aggiorna gli utilizzi rimanenti prima di continuare oppure abilita gli aggiornamenti automatici, se disponibili.';

  @override
  String usagesOfTopic(String topic) {
    return 'Utilizzi di $topic';
  }

  @override
  String get noUsagesFound => 'Nessun utilizzo trovato.';

  @override
  String get outsideSelectedInstance => 'Fuori dall’istanza selezionata';

  @override
  String get doRefactor => 'Esegui refactoring';

  @override
  String get orphanTopicTitle => 'Il file dell’argomento non è più utilizzato';

  @override
  String get keepTopicFile => 'Conserva il file dell’argomento';

  @override
  String orphanTopicMessage(String topic) {
    return '«$topic» non è più utilizzato in alcun punto di questo progetto Writerside. Elimina il file oppure conservalo per utilizzarlo in un’altra istanza.';
  }

  @override
  String get defaultNewTopicTitle => 'Nuovo argomento';

  @override
  String get topicTitle => 'Titolo dell\'argomento';

  @override
  String get fileName => 'Nome del file';

  @override
  String get topicTitleRequired => 'Il titolo dell\'argomento è obbligatorio.';

  @override
  String get fileNameRequired => 'Il nome del file è obbligatorio.';

  @override
  String get rename => 'Rinomina';

  @override
  String get confirmDeleteFileTitle => 'Eliminare il file?';

  @override
  String get confirmDeleteFolderTitle => 'Eliminare la cartella?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Eliminare $name? Questa operazione non può essere annullata.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Eliminare $name e tutti i file al suo interno? Questa operazione non può essere annullata.';
  }

  @override
  String get useSingleSafeFileName => 'Usa un unico nome di file sicuro.';

  @override
  String useExpectedExtension(String extension) {
    return 'Utilizza l\'estensione $extension per il formato selezionato.';
  }

  @override
  String get useIdentifierCharacters =>
      'Utilizza lettere, numeri, trattini bassi o trattini prima dell\'estensione.';

  @override
  String get topicIdAlreadyExists => 'L\'ID dell\'argomento esiste già.';

  @override
  String get createWritersideTopicFailed =>
      'Impossibile creare l\'argomento Writerside.';

  @override
  String get noOutline => 'Nessuna struttura';

  @override
  String expandKind(String kind) {
    return 'Espandi $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Comprimi $kind';
  }

  @override
  String get foldKindSection => 'sezione';

  @override
  String get foldKindList => 'elenco';

  @override
  String get foldKindQuote => 'citazione';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Corrispondenza precedente';

  @override
  String get sourceSearchNextMatch => 'Corrispondenza successiva';

  @override
  String get sourceSearchCaseSensitive => 'Maiuscole/minuscole';

  @override
  String get sourceSearchWholeWord => 'Parola intera';

  @override
  String get sourceSearchRegex => 'Espressione regolare';

  @override
  String get sourceSearchReplacement => 'Sostituisci con';

  @override
  String get sourceSearchReplaceCurrent => 'Sostituisci corrente';

  @override
  String get sourceSearchReplaceAndFindNext => 'Sostituisci e trova successivo';

  @override
  String get sourceSearchReplaceAll => 'Sostituisci tutto';

  @override
  String get workspaceReplace => 'Sostituisci nell’area di lavoro';

  @override
  String get reviewReplacements => 'Rivedi sostituzioni';

  @override
  String get applyReplacements => 'Applica sostituzioni';

  @override
  String get skippedFiles => 'File ignorati';

  @override
  String get workspaceReplaceDirtyBuffer => 'Contenuto dell’editor non salvato';

  @override
  String get workspaceReplaceDiskContent => 'Contenuto salvato su disco';

  @override
  String selectFileMatches(int count) {
    return 'Seleziona tutte le $count corrispondenze';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Sostituite $matches corrispondenze in $files file; $skipped ignorate.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · A capo finale';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Nessun a capo finale';
  }

  @override
  String get normalizeLineEndings => 'Normalizza terminatori di riga';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Questo documento contiene terminatori di riga misti. Scegli un formato.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName usa terminatori di riga misti. Scegli il formato prima di sostituire.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'È stato ignorato un file troppo grande.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'È stato ignorato un file illeggibile.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'È stato ignorato un file che non è UTF-8 valido.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'L’anteprima delle sostituzioni è stata troncata.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'È stato ignorato un file modificato dopo l’anteprima.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'È stato ignorato un buffer modificato dopo l’anteprima.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Scegli la normalizzazione LF o CRLF prima di sostituire.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Il rollback è stato interrotto perché il file è stato modificato contemporaneamente. Alcune sostituzioni potrebbero rimanere; il contenuto spostato è stato conservato nel percorso seguente.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Non è stata applicata alcuna sostituzione perché non è stato possibile salvare in sicurezza l’insieme verificato.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Modifiche esterne — $fileName';
  }

  @override
  String get externalFileDeleted => 'Questo file è stato eliminato dal disco.';

  @override
  String get externalFileChanged =>
      'Questo file è cambiato sul disco mentre sono presenti modifiche non salvate.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'È stato recuperato il contenuto non salvato di $fileName. Controllarlo, quindi salvarlo, salvarlo con nome o eliminarlo.';
  }

  @override
  String get compare => 'Confronta';

  @override
  String get reloadFromDisk => 'Ricarica dal disco';

  @override
  String get keepMine => 'Mantieni la mia versione';

  @override
  String get saveAs => 'Salva con nome';

  @override
  String get sourceSearchInvalidRegex => 'Espressione regolare non valida';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'File di grandi dimensioni: evidenziazione e ripiegamento sono sospesi';

  @override
  String get nothingToRead => 'Nessun contenuto da leggere';

  @override
  String get note => 'Nota';

  @override
  String get tip => 'Suggerimento';

  @override
  String get warning => 'Avviso';

  @override
  String get tabs => 'Schede';

  @override
  String get tab => 'Scheda';

  @override
  String get procedure => 'Procedura';

  @override
  String get step => 'Passaggio';

  @override
  String get topic => 'Argomento';

  @override
  String get chapter => 'Capitolo';

  @override
  String couldNotOpenTarget(String target) {
    return 'Impossibile aprire $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Destinazione del collegamento non trovata: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Impossibile aprire questo tipo di file nell\'editor';

  @override
  String anchorNotFound(String anchor) {
    return 'Ancora non trovata: $anchor';
  }

  @override
  String get noProblemsFound => 'Nessun problema riscontrato';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - riga $lineNumber';
  }

  @override
  String get untitledResult => 'Risultato senza titolo';

  @override
  String get documentKindMarkdownFile => 'File Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Argomento Markdown Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Argomento XML Writerside';

  @override
  String get documentKindWritersideTree => 'Albero Writerside';

  @override
  String get documentKindConfigurationFile => 'File di configurazione';

  @override
  String get documentKindVariablesFile => 'File delle variabili';

  @override
  String get documentKindCategoriesFile => 'File delle categorie';

  @override
  String get documentKindResourceFile => 'File di risorse';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Apertura non riuscita: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Impossibile creare il progetto Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Impossibile creare l\'argomento Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Impossibile aprire il file: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Scegli dove salvare questo file Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Salvataggio bloccato: file modificato su disco.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Salvataggio non riuscito: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Operazione sul file non riuscita: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Convalida non riuscita: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    return 'Sono stati recuperati $count documenti non salvati. Controllare ogni documento recuperato prima di continuare.';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    return 'Non è stato possibile ripristinare $count record di recupero danneggiati. I documenti recuperati validi restano disponibili.';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Il percorso non esiste: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'La directory di destinazione esiste già e non è vuota: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Il percorso di destinazione esiste già e non è una directory: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Il file generato esiste già: $path';
  }

  @override
  String get errorParentDirectoryRequired =>
      'La directory padre è obbligatoria.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'La directory padre non esiste: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'La directory non esiste: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Il percorso esiste già: $path';
  }

  @override
  String get errorFileNameRequired => 'Il nome file è obbligatorio.';

  @override
  String get errorFileNameUnsafe =>
      'Il nome file deve essere un singolo segmento di percorso sicuro.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Non è possibile spostare una cartella dentro se stessa.';

  @override
  String get errorFileOperationOutsideRoot =>
      'L’operazione sul file deve restare nell’area di lavoro.';

  @override
  String get errorFileOperationRoot =>
      'La radice dell’area di lavoro non può essere modificata dall’albero dei file.';

  @override
  String get errorProjectNameRequired => 'Il nome del progetto è obbligatorio.';

  @override
  String get errorDirectoryNameRequired =>
      'Il nome della directory è obbligatorio.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Il nome della directory deve essere un unico segmento di percorso sicuro.';

  @override
  String get errorInstanceIdInvalid =>
      'L\'ID dell\'istanza deve iniziare con una lettera minuscola e contenere solo lettere minuscole, numeri, trattini bassi e trattini.';

  @override
  String get errorTopicFileInvalid =>
      'Il nome del file dell\'argomento deve essere un nome di file Markdown senza separatori di percorso.';

  @override
  String get errorTopicTitleRequired =>
      'Il titolo dell\'argomento è obbligatorio.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'La radice del modulo Writerside non esiste: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Per creare un argomento deve essere aperto un modulo Writerside.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Il modulo Writerside non ha un albero dell’istanza.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Il file dell\'albero Writerside non esiste: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'L\'ID argomento \"$topicId\" esiste già in questo modulo della guida.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Il file dell\'argomento esiste già: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'L\'argomento di riferimento non è presente nell\'albero selezionato: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'La voce del TOC selezionata non esiste più.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Una voce del TOC non può essere spostata all\'interno di sé stessa né di uno dei suoi discendenti.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'L\'argomento iniziale $topic non può essere eliminato. Scegli prima un\'altra pagina iniziale.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Usa l’eliminazione sicura per i file degli argomenti Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Non è stato possibile completare l’analisi degli utilizzi dell’argomento. Nessun file è stato modificato.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Alcuni utilizzi dell’argomento richiedono ancora attenzione. Esaminali prima di continuare.';

  @override
  String get errorWritersideRedirectInvalid =>
      'La destinazione di reindirizzamento selezionata non è più valida. Selezionala di nuovo.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Non è stato possibile annullare completamente la rimozione dell’argomento. Controlla questi percorsi prima di continuare: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'La radice degli argomenti deve essere una directory relativa sicura.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Il nome del file dell\'argomento deve essere un unico segmento di percorso sicuro.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'L\'estensione del file dell\'argomento deve corrispondere al formato selezionato ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Il nome del file dell\'argomento deve contenere solo lettere, numeri, trattini bassi e trattini.';

  @override
  String errorUnknown(String code) {
    return 'Errore sconosciuto: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Impossibile leggere i metadati del file: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Rilevata un\'area di lavoro di grandi dimensioni. Alcuni file sono stati ignorati per mantenere reattiva l\'app.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Impossibile ispezionare la voce dell\'area di lavoro: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Il file supera il limite beta per l\'analisi automatica.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Impossibile leggere il file Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Blocco di attributi dell\'intestazione Writerside non valido.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'ID dell\'intestazione duplicato \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Le intestazioni H1 aggiuntive di primo livello vengono trattate come capitoli.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'L\'argomento Markdown Writerside non contiene un H1 né un titolo nel front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Manca il titolo dell\'argomento XML.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Manca il titolo dell\'argomento \"$fileName\".';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Il front matter non è chiuso.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Elemento HTML non sicuro.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'La destinazione del collegamento non esiste: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'L\'ancora \"$anchor\" non esiste.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'L\'immagine \"$destination\" non ha testo alternativo.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'L\'immagine non esiste: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'XML non valido: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'L\'elemento radice di writerside.cfg deve essere <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'La dichiarazione <snippets> non ha l\'attributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'La dichiarazione <instance-groups> non ha l\'attributo src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Modalità keymaps non supportata: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'La dichiarazione dell\'istanza non ha l\'attributo src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg non registra alcuna istanza.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'L\'elemento radice di .tree deve essere <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Il profilo dell\'istanza non ha l\'attributo id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Il nome base del file .tree non corrisponde all\'ID dell\'istanza \"$id\".';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'L\'istanza non di libreria non ha start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'La pagina iniziale \"$startPage\" non esiste.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'L\'argomento \"$topic\" compare più di una volta nel TOC di questa istanza.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'La dichiarazione della variabile deve includere nome e valore.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'La variabile \"$name\" è dichiarata più di una volta.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'La categoria non ha l\'attributo id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'La categoria \"$id\" è dichiarata più di una volta.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'L\'ordine della categoria \"$order\" è dichiarato più di una volta.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'L\'elemento radice di .topic deve essere <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Manca l\'attributo id nell\'elemento radice dell\'argomento XML.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'L\'ID dell\'elemento radice dell\'argomento XML \"$id\" deve corrispondere al nome file \"$expectedId\".';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'L\'ID dell\'elemento \"$elementId\" compare più di una volta.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      '<a> non ha l\'attributo href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'La modalità Writerside richiede writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Manca la directory configurata per la build: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Manca la directory configurata per le specifiche API: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Manca la directory configurata per gli snippet: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Manca il file delle variabili configurato: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Manca il file delle categorie configurato: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Manca il file dei gruppi di istanze configurato: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'L\'albero dell\'istanza registrato \"$source\" non esiste.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Impossibile leggere il file dell\'argomento: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Manca la directory predefinita degli argomenti: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Manca la directory degli argomenti configurata: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Manca la directory delle immagini configurata: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'L\'ID dell\'elemento \"$id\" compare più di una volta.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Il TOC fa riferimento a un argomento mancante \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'L\'href esterno \"$href\" non è valido.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'La variabile \"%$name%\" non è dichiarata.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Il collegamento all\'argomento \"$destination\" non è risolvibile.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'L\'ancora \"$anchor\" non esiste in \"$targetName\".';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> non ha l\'attributo from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'La sorgente dell\'include \"$from\" non esiste.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'L\'elemento da includere \"$elementId\" non esiste in \"$from\".';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'La categoria seealso \"$ref\" non è dichiarata.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Il riferimento all\'argomento \"$reference\" è ambiguo.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Messaggio diagnostico sconosciuto: $code';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Diff Git';

  @override
  String get gitShowDiff => 'Mostra diff';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'precedente $oldRange → nuovo $newRange';
  }

  @override
  String get gitDiffNoLines => 'nessuna riga';

  @override
  String get gitUnavailableTitle => 'Git non è disponibile';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Installa Git o configura BusyMark per utilizzare un eseguibile Git disponibile. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Considerare attendibile quest’area di lavoro per Git?';

  @override
  String get gitTrustRequiredMessage =>
      'I repository Git possono eseguire programmi tramite hook, filtri e altre configurazioni. Considera attendibile quest’area di lavoro prima che BusyMark legga i dati del repository o attivi le azioni Git.';

  @override
  String get gitTrustWorkspace => 'Considera attendibile l’area di lavoro';

  @override
  String get gitNotRepositoryTitle => 'Non è un repository Git';

  @override
  String get gitNotRepositoryMessage =>
      'Quest’area di lavoro non si trova in un repository Git.';

  @override
  String get gitInitializeRepository => 'Inizializza repository';

  @override
  String get gitDetachedHead => 'HEAD scollegato';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Scollegato su $commit';
  }

  @override
  String get gitNoUpstream => 'Nessun upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit non inviati',
      one: '1 commit non inviato',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commit da recuperare',
      one: '1 commit da recuperare',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Pulito';

  @override
  String get gitConflicts => 'Conflitti';

  @override
  String get gitChanges => 'Modifiche';

  @override
  String get gitStaged => 'In stage';

  @override
  String get gitUnstaged => 'Non in stage';

  @override
  String get gitHistory => 'Cronologia';

  @override
  String get gitBranches => 'Rami';

  @override
  String get gitActions => 'Azioni Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Recupera';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Aggiungi file all’indice';

  @override
  String get gitRemoveFromCommit => 'Rimuovi file dall’indice';

  @override
  String get gitDiscard => 'Scarta';

  @override
  String get gitOpenFile => 'Apri file';

  @override
  String get gitMarkResolved => 'Segna come risolto';

  @override
  String get gitUntracked => 'File non tracciati';

  @override
  String get gitCommitMessage => 'Messaggio di commit';

  @override
  String get gitCommitSelectedFiles => 'File selezionati';

  @override
  String get gitCommitNoSelectedFiles =>
      'Aggiungi almeno un file all’indice prima di creare il commit.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file in stage',
      one: '1 file in stage',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Fuori dall’area di lavoro';

  @override
  String get gitCommitMessageRequired => 'Inserisci un messaggio di commit.';

  @override
  String get gitCreateBranch => 'Crea ramo';

  @override
  String get gitNewBranch => 'Nuovo ramo';

  @override
  String get gitBranchName => 'Nome del ramo';

  @override
  String get gitSwitchBranch => 'Passa';

  @override
  String get gitNoChanges => 'Nessuna modifica';

  @override
  String get gitNoHistory => 'Nessuna cronologia';

  @override
  String get gitNoBranches => 'Nessun ramo';

  @override
  String get gitNoDiff => 'Nessun diff da mostrare';

  @override
  String get gitBinaryFile =>
      'File binario. BusyMark non visualizza le patch binarie.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'File binario ($size byte). BusyMark non visualizza le patch binarie.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Le modifiche non salvate dell’editor non vengono incluse finché non vengono salvate.';

  @override
  String get gitConfirmDiscardTitle => 'Scartare le modifiche Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I file tracciati selezionati verranno ripristinati da Git.',
      one: 'Il file tracciato selezionato verrà ripristinato da Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I file non tracciati selezionati verranno eliminati.',
      one: 'Il file non tracciato selezionato verrà eliminato.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'I file selezionati verranno ripristinati o eliminati in base al loro stato Git.',
      one:
          'Il file selezionato verrà ripristinato o eliminato in base al suo stato Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Passare a $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark ricaricherà l’area di lavoro dal disco dopo il cambio di ramo da parte di Git.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Impostare il ramo upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Questo ramo non ha un upstream. BusyMark può inviare $branch e impostarne l’upstream quando è configurato esattamente un repository remoto.';
  }

  @override
  String get gitProjectHistory => 'Progetto';

  @override
  String get gitFileHistory => 'File corrente';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'La cronologia file richiede un file Markdown aperto.';

  @override
  String get gitLoadMore => 'Carica altro';

  @override
  String get gitChangesInCommit => 'Modifiche in questo commit';

  @override
  String get gitCompareWithCurrent => 'Confronta con la versione corrente';

  @override
  String get gitRestoreVersion => 'Ripristina questa versione';

  @override
  String get gitConfirmRestoreTitle => 'Ripristinare questa versione del file?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark sostituirà il file corrente nell’albero di lavoro con la versione selezionata del commit. Il file ripristinato resterà fuori dallo stage.';

  @override
  String get gitCommitActions => 'Azioni del commit';

  @override
  String get gitResetCurrentBranchToHere => 'Reimposta qui il branch corrente…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Reimpostare $branch su $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Questa operazione sposta il branch $branch sul commit $commit. Scegli come Git deve aggiornare l’indice e l’albero di lavoro.';
  }

  @override
  String get gitReset => 'Reimposta';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Sposta solo il branch. Mantiene invariati l’indice e l’albero di lavoro; le differenze rispetto al commit selezionato restano nello stage.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Sposta il branch e reimposta l’indice. Mantiene invariato l’albero di lavoro, lasciando le differenze fuori dallo stage.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Sposta il branch e reimposta l’indice e l’albero di lavoro. Le modifiche ai file tracciati vengono eliminate; i file non tracciati che ostacolano l’operazione possono essere rimossi.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Sposta il branch e reimposta i file tracciati conservando le modifiche locali. Git interrompe l’operazione se tali modifiche sono in conflitto con il ripristino.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Azioni sul file';

  @override
  String get actions => 'Azioni';

  @override
  String get gitStatusAdded => 'Aggiunto';

  @override
  String get gitStatusDeleted => 'Eliminato';

  @override
  String get gitStatusRenamed => 'Rinominato';

  @override
  String get gitStatusCopied => 'Copiato';

  @override
  String get gitStatusUntracked => 'Non tracciato';

  @override
  String get gitStatusConflicted => 'In conflitto';

  @override
  String get gitStatusIgnored => 'Ignorato';

  @override
  String get gitStatusTypeChanged => 'Tipo modificato';

  @override
  String get gitStatusModified => 'Modificato';

  @override
  String get gitStatusUnknown => 'Sconosciuto';

  @override
  String get gitErrorUnavailable => 'Git non è disponibile.';

  @override
  String get gitErrorNotRepository =>
      'Quest’area di lavoro non è un repository Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark ha bloccato un percorso Git non sicuro.';

  @override
  String get gitErrorInvalidBranchName => 'Inserisci un nome di ramo valido.';

  @override
  String get gitErrorNoRemote =>
      'Non è configurato alcun repository Git remoto.';

  @override
  String get gitErrorNoUpstream => 'Non è configurato alcun ramo upstream.';

  @override
  String get gitErrorMultipleRemotes =>
      'Sono configurati più repository remoti. Scegli un upstream al di fuori di questa versione di BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Salva o scarta le modifiche dell’editor di BusyMark prima di cambiare ramo.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Salva o scarta le modifiche nell’editor di BusyMark prima di reimpostare il branch corrente.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Rimuovi il file dall’indice prima di ripristinare una versione precedente.';

  @override
  String get gitErrorResetDetachedHead =>
      'Passa a un branch prima di reimpostarlo.';

  @override
  String get gitErrorDiverged =>
      'Il ramo è divergente. Risolvi il merge o il rebase al di fuori di questa versione di BusyMark.';

  @override
  String get gitErrorAuthentication =>
      'Autenticazione Git non riuscita. Nello snap, i repository SSH remoti potrebbero richiedere il collegamento dell’interfaccia ssh-keys.';

  @override
  String get gitErrorNetwork => 'Operazione di rete Git non riuscita.';

  @override
  String get gitErrorConflict => 'Git ha segnalato conflitti non risolti.';

  @override
  String get gitErrorCommandFailed => 'Comando Git non riuscito.';

  @override
  String get markdownAndHtml => 'Markdown e HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Blocchi Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Strutture a blocchi supportate nel sorgente Markdown e nell’anteprima.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown in linea';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formattazione dentro paragrafi, elementi di elenco e celle di tabella.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Blocchi HTML grezzi';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Tag HTML di blocco sicuri renderizzati dai widget di anteprima BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Tag HTML grezzi in linea';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Tag HTML in linea sicuri renderizzati senza mostrare i tag letterali.';

  @override
  String get markdownHtmlSafety => 'Regole di sicurezza';

  @override
  String get markdownHtmlSafetyDescription =>
      'L’HTML grezzo viene analizzato e sanificato prima dell’anteprima.';

  @override
  String get markdownHtmlHeadings => 'Titoli';

  @override
  String get markdownHtmlParagraphs => 'Paragrafi';

  @override
  String get markdownHtmlLists => 'Elenchi';

  @override
  String get markdownHtmlHtmlContainers => 'Contenitori';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Blocchi di testo';

  @override
  String get markdownHtmlHtmlFigures => 'Figure e immagini';

  @override
  String get markdownHtmlHtmlPreformatted => 'Codice preformattato';

  @override
  String get markdownHtmlHtmlDisclosure => 'Blocchi espandibili';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Elenchi descrittivi';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Tag di formattazione';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Tag di codice in linea';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Tag di testo semantico';

  @override
  String get markdownHtmlSanitizedPreview => 'Anteprima sanificata';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'L’HTML consentito viene convertito in blocchi di anteprima BusyMark e non viene renderizzato in un browser.';

  @override
  String get markdownHtmlSourcePreserved => 'Codice sorgente conservato';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'L’HTML grezzo non modificato viene salvato esattamente come testo sorgente.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown dentro HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'I marcatori Markdown dentro HTML grezzo vengono visualizzati come testo letterale.';

  @override
  String get markdownHtmlBlockedContent => 'Contenuto attivo bloccato';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Script, stili, frame, moduli, SVG, MathML, eventi e attributi non sicuri vengono bloccati.';

  @override
  String get markdownHtmlSafeUrls => 'Solo URL sicuri';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'I link consentono http, https, mailto, tel, URL relativi e frammenti; gli schemi non sicuri sono bloccati.';

  @override
  String get exportAsPdf => 'Esporta come PDF';

  @override
  String get pdfExportDescription =>
      'Scegli l’impaginazione per creare un PDF rifinito e autonomo.';

  @override
  String get pdfRemoteImagesNote =>
      'Le immagini remote non vengono scaricate durante l’esportazione. Le immagini locali vengono incluse quando disponibili.';

  @override
  String get pdfPageSize => 'Formato pagina';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Lettera';

  @override
  String get pdfOrientation => 'Orientamento';

  @override
  String get pdfPortrait => 'Verticale';

  @override
  String get pdfLandscape => 'Orizzontale';

  @override
  String get pdfMargins => 'Margini';

  @override
  String get pdfMarginNarrow => 'Stretti';

  @override
  String get pdfMarginNormal => 'Normali';

  @override
  String get pdfMarginWide => 'Ampi';

  @override
  String get pdfIncludePageNumbers => 'Includi numeri di pagina';

  @override
  String get export => 'Esporta';

  @override
  String get exportingPdf => 'Esportazione PDF…';

  @override
  String get fileTypePdf => 'Documento PDF';

  @override
  String pdfExported(String fileName) {
    return '$fileName è stato esportato.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return '$fileName è stato esportato. Immagini non incluse: $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'Il componente di esportazione PDF non è disponibile. Reinstalla BusyMark e riprova.';

  @override
  String get pdfExportTimedOut =>
      'L’esportazione PDF ha richiesto troppo tempo ed è stata interrotta.';

  @override
  String get pdfExportFailed =>
      'BusyMark non ha potuto esportare questo documento come PDF.';

  @override
  String get visualizationRendering => 'Rendering in corso…';

  @override
  String get visualizationStale =>
      'Visualizzazione dell’ultimo rendering valido';

  @override
  String get visualizationShowSource => 'Mostra sorgente';

  @override
  String get visualizationShowRender => 'Mostra rendering';

  @override
  String get visualizationFitWidth => 'Adatta alla larghezza';

  @override
  String get visualizationSaveImage => 'Salva immagine';

  @override
  String get visualizationCopyImage => 'Copia immagine';

  @override
  String get visualizationImageCopied => 'Immagine copiata';

  @override
  String get visualizationOpenApiReference => 'Apri riferimento API';

  @override
  String get visualizationValid => 'Valido';

  @override
  String get visualizationInvalid => 'Non valido';

  @override
  String get visualizationServers => 'Server';

  @override
  String get visualizationPaths => 'Percorsi';

  @override
  String get visualizationOperations => 'Operazioni';

  @override
  String get visualizationTags => 'Tag';

  @override
  String get visualizationNoOperations => 'Nessuna operazione corrispondente';

  @override
  String get visualizationSearchOperations => 'Cerca operazioni';

  @override
  String get visualizationRenderFailed =>
      'Impossibile eseguire il rendering di questa visualizzazione.';

  @override
  String get visualizationRetry => 'Riprova';

  @override
  String visualizationSaved(String fileName) {
    return 'Salvato $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Esporta il documento attivo o il modulo Writerside come PDF.';

  @override
  String get instances => 'Istanze';

  @override
  String get newInstance => 'Nuova istanza';

  @override
  String get newTocLibrary => 'Nuova libreria del sommario';

  @override
  String get editInstance => 'Modifica istanza';

  @override
  String get openTocFile => 'Apri file del sommario';

  @override
  String get createInstance => 'Crea istanza';

  @override
  String get createTocLibrary => 'Crea libreria del sommario';

  @override
  String get instanceContent => 'Contenuto';

  @override
  String get instanceContentSource => 'Crea da';

  @override
  String get emptyInstance => 'Istanza vuota';

  @override
  String get markdownFiles => 'File Markdown locali';

  @override
  String get chooseMarkdownFolder => 'Scegli cartella Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Scegli una cartella contenente file Markdown.';

  @override
  String get instanceAppearance => 'Aspetto';

  @override
  String get instanceColor => 'Colore dell’icona';

  @override
  String get instanceVersion => 'Versione';

  @override
  String instanceVersionInherited(String version) {
    return 'Se questo campo è vuoto, viene usata la versione del progetto $version.';
  }

  @override
  String get instanceWebPath => 'Percorso web';

  @override
  String get instanceStatus => 'Stato';

  @override
  String get instanceStatusRelease => 'Versione stabile';

  @override
  String get instanceStatusEap => 'Accesso anticipato';

  @override
  String get instanceStatusDeprecated => 'Obsoleta';

  @override
  String get allowSearchEngineIndexing =>
      'Consenti l’indicizzazione dei motori di ricerca';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Consenti ai motori di ricerca esterni di indicizzare questo output.';

  @override
  String get offlineArtifact => 'Artefatto offline';

  @override
  String get offlineArtifactDescription =>
      'Includi le risorse affinché la documentazione generata sia autonoma.';

  @override
  String get instanceOutputSettings => 'Impostazioni di output';

  @override
  String get markdownImportSource => 'Origine Markdown';

  @override
  String get markdownImportFiles => 'File Markdown';

  @override
  String get selectNone => 'Non selezionare nulla';

  @override
  String markdownFilesFound(int count) {
    return 'Trovati $count file Markdown';
  }

  @override
  String get noMarkdownFilesFound =>
      'Nessun file Markdown trovato in questa directory.';

  @override
  String get copyReferencedMedia => 'Copia media referenziati';

  @override
  String get copyReferencedMediaDescription =>
      'Copia immagini e video locali referenziati dai file selezionati mantenendo i percorsi relativi.';

  @override
  String get instanceIdRenameWarningTitle => 'Rinominare l’ID dell’istanza?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark rinominerà il file .tree e aggiornerà i riferimenti del progetto Writerside da «$oldId» a «$newId». Gli script di pubblicazione non vengono modificati e devono essere aggiornati separatamente.';
  }

  @override
  String get renameAndUpdateReferences => 'Rinomina e aggiorna riferimenti';

  @override
  String get tocLibraryDescription =>
      'Una libreria del sommario conserva sezioni riutilizzabili e non produce un output proprio.';

  @override
  String get defaultTocLibraryName => 'Sommario condiviso';

  @override
  String get instanceColorAutomatic => 'Automatico';

  @override
  String get instanceColorBlue => 'Blu';

  @override
  String get instanceColorGreen => 'Verde';

  @override
  String get instanceColorOrange => 'Arancione';

  @override
  String get instanceColorPurple => 'Viola';

  @override
  String get instanceColorRed => 'Rosso';

  @override
  String get instanceColorTeal => 'Verde acqua';

  @override
  String get instanceColorYellow => 'Giallo';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Inserisci un nome per l’istanza.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Esiste già un’istanza con ID «$id».';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'L’albero dell’istanza esiste già: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'La directory di origine Markdown non esiste: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Seleziona almeno un file Markdown da importare.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Questo non è un file Markdown leggibile nell’origine selezionata: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'L’importazione sovrascriverebbe un file di progetto esistente: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'I file dell’istanza sono cambiati sul disco. Verificali e riprova.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark non ha potuto annullare completamente la modifica dell’istanza. Verifica questi file prima di continuare: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Una libreria del sommario non può importare argomenti Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Il percorso web deve occupare una sola riga.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'La configurazione dell’istanza Writerside non è valida. Correggi le segnalazioni e riprova.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark non ha potuto preparare in modo sicuro le modifiche dell’istanza.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Stato dell’istanza sconosciuto «$status». Usa release, eap o deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'L’ID istanza «$id» è usato da più file di albero.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml deve avere un elemento radice <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Il valore $name «$value» deve essere true o false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Un elemento <build-profile> deve specificare un ID istanza.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Un <include> dell’albero deve specificare sia from sia element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Uno <snippet> dell’albero deve specificare un id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Un riferimento del sommario tra istanze deve specificare sia ref sia in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Un elemento del sommario non può puntare a più di un argomento, riferimento, collegamento o reindirizzamento.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'L’ID elemento dell’albero «$id» è dichiarato più di una volta.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Il file dei gruppi di istanze deve avere un elemento radice <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Un gruppo di istanze deve specificare un id e un elenco di istanze non vuoti.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'L’ID gruppo di istanze «$id» è dichiarato più di una volta.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'L’inclusione del sommario «$source#$id» appartiene al modulo esterno «$origin» e non può essere espansa in questo spazio di lavoro.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'L’elemento dell’albero «$id» non esiste nell’albero registrato «$source».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'L’inclusione dell’albero «$source#$id» crea un ciclo.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'La condizione dell’istanza fa riferimento al gruppo sconosciuto «@$group».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Il riferimento tra istanze punta all’istanza sconosciuta «$instance».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'L’argomento «$topic» non appartiene all’istanza referenziata «$instance».';
  }

  @override
  String get download => 'Scarica';

  @override
  String get exportWritersideAsPdf => 'Esporta Writerside come PDF';

  @override
  String get writersidePdfExportDescription =>
      'Scegli un’istanza e le impostazioni PDF. BusyMark usa il generatore Writerside ufficiale di JetBrains.';

  @override
  String get writersidePdfContent => 'Contenuto dell’esportazione';

  @override
  String get writersidePdfSettings => 'Impostazioni PDF';

  @override
  String get writersidePdfConfigureHere => 'Configura per questa esportazione';

  @override
  String get writersidePdfProjectConfiguration =>
      'Usa la configurazione del progetto';

  @override
  String get writersidePdfConfigurationFile => 'File di configurazione PDF';

  @override
  String get writersidePdfPage => 'Pagina';

  @override
  String get writersidePdfKeymap => 'Mappa dei tasti';

  @override
  String get writersidePdfNoKeymap => 'Nessuna mappa dei tasti';

  @override
  String get writersidePdfTocTitle => 'Titolo dell’indice';

  @override
  String get writersidePdfCover => 'Pagina di copertina';

  @override
  String get writersidePdfIncludeCover => 'Includi pagina di copertina';

  @override
  String get writersidePdfCoverTitle => 'Titolo di copertina';

  @override
  String get writersidePdfCoverDescription => 'Descrizione di copertina';

  @override
  String get writersidePdfCopyright => 'Diritto d’autore';

  @override
  String get writersidePdfCoverLogo => 'Logo di copertina';

  @override
  String get writersidePdfChooseCoverLogo => 'Scegli logo di copertina';

  @override
  String get writersidePdfHeaderAndFooter => 'Intestazione e piè di pagina';

  @override
  String get writersidePdfHeader => 'Intestazione';

  @override
  String get writersidePdfFooter => 'Piè di pagina';

  @override
  String get writersidePdfAdvancedDescription =>
      'Questi valori associano il modulo aperto alla struttura delle sorgenti del generatore.';

  @override
  String get writersidePdfModuleName => 'Nome del modulo';

  @override
  String get writersidePdfSourceRoot => 'Radice delle sorgenti';

  @override
  String get writersidePdfChooseSourceRoot => 'Scegli radice delle sorgenti';

  @override
  String get writersidePdfBuilderVersion => 'Versione del generatore';

  @override
  String get writersidePdfAllowNetwork =>
      'Consenti rete durante la generazione';

  @override
  String get writersidePdfAllowNetworkDescription =>
      'Disattivato per impostazione predefinita. Attivalo solo se il progetto richiede intenzionalmente risorse remote.';

  @override
  String get writersidePdfModuleNameRequired => 'Inserisci il nome del modulo.';

  @override
  String get writersidePdfSourceRootRequired =>
      'Scegli la radice delle sorgenti.';

  @override
  String get writersidePdfBuilderVersionInvalid =>
      'Inserisci una versione valida del generatore.';

  @override
  String get writersidePdfBuilderRequired => 'Generatore Writerside necessario';

  @override
  String writersidePdfBuilderDownloadDescription(String image) {
    return 'BusyMark usa l’immagine contenitore ufficiale $image. Scaricarla ora? L’immagine è grande e viene archiviata da Docker.';
  }

  @override
  String get writersidePdfDownloadingBuilder =>
      'Download del generatore Writerside…';

  @override
  String get exportingWritersidePdf => 'Esportazione del PDF Writerside…';

  @override
  String get writersidePdfDockerUnavailable =>
      'Docker è necessario per esportare Writerside in PDF. Installa e avvia Docker, quindi riprova.';

  @override
  String get writersidePdfBuilderUnavailable =>
      'L’immagine richiesta del generatore Writerside non è disponibile.';

  @override
  String get writersidePdfConfigurationInvalid =>
      'La configurazione PDF di Writerside non è valida.';

  @override
  String get writersidePdfBuildFailed =>
      'Il generatore Writerside non ha potuto creare il PDF.';

  @override
  String get writersidePdfInvalidOutput =>
      'Il generatore Writerside non ha prodotto un PDF valido.';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama locale';

  @override
  String get aiDisabled => 'Disabilitato';

  @override
  String get aiLocalOnlyDescription =>
      'La modifica con IA viene avviata solo esplicitamente. BusyMark invia esclusivamente il contesto mostrato al fornitore selezionato e non applica mai una proposta senza revisione.';

  @override
  String get aiProvider => 'Provider IA';

  @override
  String get aiDefaultProvider => 'Provider predefinito';

  @override
  String get aiConfigureProvider => 'Configura provider';

  @override
  String get aiChooseProvider => 'Scegli provider IA';

  @override
  String get aiOllamaEndpoint => 'Endpoint Ollama';

  @override
  String get aiOllamaModel => 'Modello Ollama';

  @override
  String get aiTestConnection => 'Verifica connessione';

  @override
  String get aiTestingConnection => 'Verifica in corso…';

  @override
  String aiConnectionReady(int count) {
    return 'Connesso. Trovati $count modelli installati.';
  }

  @override
  String get aiNoModels => 'Nessun modello selezionato.';

  @override
  String get aiConnectionFailed =>
      'BusyMark non è riuscito a verificare la generazione di testo con IA.';

  @override
  String get aiConfigureFirst =>
      'Abilita un fornitore di IA e verifica un modello in Impostazioni → IA.';

  @override
  String get aiEditWithAi => 'Modifica con l’IA';

  @override
  String get aiRefineWithAi => 'Migliora con l’IA';

  @override
  String get aiInstruction => 'Istruzione';

  @override
  String get aiChangeTarget => 'Cosa può cambiare';

  @override
  String get aiSharedContext => 'Contesto condiviso con l’IA';

  @override
  String get aiTargetSelection => 'Contenuto selezionato';

  @override
  String get aiTargetInsertAfterBlock => 'Inserisci dopo il blocco corrente';

  @override
  String get aiTargetCurrentBlock => 'Blocco corrente';

  @override
  String get aiTargetCurrentSection => 'Sezione corrente';

  @override
  String get aiTargetCompleteDocument => 'Documento completo';

  @override
  String get aiContextNone => 'Nessun contesto del documento';

  @override
  String get aiContextSelection => 'Contenuto selezionato';

  @override
  String get aiContextCurrentBlock => 'Blocco corrente';

  @override
  String get aiContextCurrentSection => 'Sezione corrente';

  @override
  String get aiContextCompleteDocument => 'Documento completo';

  @override
  String get aiGenerating => 'Generazione della proposta…';

  @override
  String get aiProposal => 'Proposta IA';

  @override
  String get aiGenerateProposal => 'Genera proposta';

  @override
  String aiContextDisclosure(int count) {
    return 'Il fornitore selezionato riceverà $count caratteri dal contesto mostrato.';
  }

  @override
  String get aiOriginal => 'Testo originale';

  @override
  String get aiSuggested => 'Suggerimento';

  @override
  String get aiApplyProposal => 'Applica proposta';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input token di input · $output token di output';
  }

  @override
  String get aiStaleProposal =>
      'Il documento è cambiato durante la generazione della proposta. Esegui di nuovo l’azione.';

  @override
  String get gitAiStagedChangesChanged =>
      'Le modifiche in stage sono cambiate durante la generazione di questo messaggio di commit. Esegui di nuovo l’azione.';

  @override
  String get aiViewContext => 'Visualizza contesto inviato';

  @override
  String get aiReviewExactContent => 'Esamina contenuto esatto';

  @override
  String get aiContentToChange => 'Contenuto da modificare';

  @override
  String get aiContentSentToAi => 'Contenuto inviato all’IA';

  @override
  String get aiApiKey => 'Chiave API';

  @override
  String get aiApiKeyStoredHint =>
      'Una chiave è salvata nell’archivio credenziali di sistema';

  @override
  String get aiApiKeyEnterHint => 'Inserisci una chiave API del fornitore';

  @override
  String get aiReplaceApiKey => 'Sostituisci chiave API';

  @override
  String get aiSaveApiKey => 'Salva la chiave API in modo sicuro';

  @override
  String get aiRemoveApiKey => 'Rimuovi la chiave API salvata';

  @override
  String get aiCredentialSaved =>
      'La chiave API è stata salvata nell’archivio credenziali di sistema.';

  @override
  String get aiCredentialRemoved => 'La chiave API salvata è stata rimossa.';

  @override
  String get aiModelRouting => 'Selezione del modello';

  @override
  String get aiAutomaticRouting => 'Automatica in base all’attività';

  @override
  String get aiFixedModelRouting => 'Usa il modello selezionato';

  @override
  String get aiPreferredModel => 'Modello preferito';

  @override
  String get aiModel => 'Modello';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests richieste · $input token di input · $output token di output';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Inviare contenuti a $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Abilita $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Viene inviato solo il contenuto mostrato in ciascuna finestra di revisione dell’IA. Le richieste sono senza stato, le proposte richiedono revisione e la chiave API viene salvata nell’archivio credenziali di sistema di Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Conferma prima la condivisione dei dati con $provider in Impostazioni → IA.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Generazione verificata con $model. Sono disponibili $count modelli compatibili.';
  }

  @override
  String get aiColdStartObserved =>
      'È stato rilevato un avvio a freddo del modello locale.';

  @override
  String get aiNoCompatibleModels =>
      'Non è disponibile alcun modello compatibile per la generazione di testo.';

  @override
  String get aiEnableProvider => 'Abilita prima un fornitore di IA.';

  @override
  String get aiDraftCommitMessage => 'Crea una bozza del messaggio di commit';

  @override
  String get aiDrafting => 'Creazione bozza…';

  @override
  String get aiDraftWithAi => 'Crea bozza con IA';

  @override
  String get generateOrUpdateMarkdownToc => 'Genera/aggiorna indice';

  @override
  String get markdownTocTitle => 'Indice';

  @override
  String markdownTocUpdated(int count) {
    return 'Indice aggiornato con $count voci.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Aggiungi almeno un titolo di sezione prima di generare un indice.';

  @override
  String get markdownTocMalformedMarkers =>
      'I marcatori dell’indice di BusyMark sono mancanti, duplicati o fuori ordine.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Il titolo di livello $level segue il livello $previousLevel; verifica la struttura delle sezioni.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Il testo del collegamento è vuoto; fornisci un nome accessibile che ne descriva lo scopo.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Verifica se il testo del collegamento “$text” ne descrive lo scopo nel contesto.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Le intestazioni della tabella devono identificare le colonne; completa ogni intestazione vuota.';

  @override
  String get mathRenderFailed =>
      'Impossibile visualizzare l’espressione matematica.';

  @override
  String get inlineMath => 'Formula in linea';

  @override
  String get displayMath => 'Formula in blocco';
}
