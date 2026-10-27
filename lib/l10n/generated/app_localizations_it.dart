// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Nuova nota dal testo conservato';

  @override
  String get notesAccountThrottled =>
      'Nextcloud richiede una pausa. Attendi prima di accedere nuovamente.';

  @override
  String get notesSettingsRefreshing =>
      'Aggiornamento di Notes dopo la conferma delle impostazioni';

  @override
  String get notesExportOperationFailed =>
      'Esportazione fallita prima della pubblicazione. Controlla origine e destinazione, poi riprova.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'La nota recuperata è stata salvata, ma non si è aperta. Risolvi le modifiche in sospeso nell’editor o nelle proprietà, poi apri questa nota.';

  @override
  String get notesSettingsPendingNotes =>
      'Note in sospeso, conflitti o creazioni incerte bloccano la modifica. Sincronizzali o esaminali in Notes, poi salva di nuovo la bozza conservata.';

  @override
  String get notesSettingsPendingAttachments =>
      'Operazioni sugli allegati bloccano la modifica. Esamina gli allegati in Notes, poi salva di nuovo la bozza conservata.';

  @override
  String get notesAccountServerAddress =>
      'Usa l’indirizzo HTTPS canonico di Nextcloud e riavvia l’accesso. L’indirizzo o il reindirizzamento non è verificabile.';

  @override
  String get notesAccountUnsupported =>
      'Notes non è disponibile o l’API non è supportata. Attiva Nextcloud Notes con API principale 1, secondaria 4 o successiva.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud ha rifiutato le credenziali. Autorizza nuovamente l’account o riconnettilo.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud ha negato la verifica delle funzionalità Notes. Chiedi all’amministratore di consentirla e riprova.';

  @override
  String get notesAccountMalformed =>
      'La risposta di Nextcloud non è verificabile. Controlla l’installazione del server e riavvia l’accesso.';

  @override
  String get notesAccountTimedOut =>
      'Accesso scaduto. Riavvialo e completa l’autorizzazione nel browser.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Impossibile aprire il browser di sistema. Controlla il browser predefinito e riavvia l’accesso.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud non è raggiungibile. Controlla connessione e server e riprova ad accedere.';

  @override
  String get notesAccountRejected =>
      'Nextcloud ha rifiutato la richiesta di funzionalità. Verifica l’accesso con l’amministratore e riprova.';

  @override
  String get notesAccountFailed =>
      'Configurazione dell’account non riuscita. Riprova ad accedere.';

  @override
  String get notesTransferSourceChanged =>
      'L’origine è cambiata dopo la revisione. Esamina il file attuale o crea una nuova istantanea prima di riprovare.';

  @override
  String get notesTransferUnreadable =>
      'Impossibile leggere l’origine. Controlla l’accesso al file o alla cartella e riesaminala.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Istantanea non valida o non supportata. Scegli un’istantanea BusyMark Notes valida o un’origine Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'I contenuti multimediali superano il limite d’importazione. Riduci quelli dell’elemento interessato e riesaminalo.';

  @override
  String get notesTransferUnsafeSource =>
      'L’origine contiene un percorso non sicuro. Scegli file nella cartella di origine e riesaminali.';

  @override
  String get notesTransferDestination =>
      'Impossibile scrivere l’esportazione. Controlla accesso e spazio libero nella destinazione e riprova.';

  @override
  String get notesTransferOperationFailed =>
      'Trasferimento non riuscito. Esamina gli elementi interessati e riprova. Quelli già importati rimangono salvati.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Esportazione disponibile con omissioni';

  @override
  String get notesBatchUnchanged => 'I valori richiesti erano già impostati.';

  @override
  String get notesBatchReadOnly =>
      'La nota è di sola lettura. Le proprietà protette non possono cambiare; Preferito rimane modificabile.';

  @override
  String get notesBatchReviewChanged =>
      'La nota è cambiata dopo la revisione. Esamina lo stato attuale prima di ripetere l’azione.';

  @override
  String get notesBatchMissing =>
      'La nota non è più disponibile. Aggiorna l’elenco e verifica gli elementi scelti.';

  @override
  String get notesBatchStorage =>
      'Salvataggio locale fallito. Controlla lo spazio e riprova questo elemento; quelli riusciti rimangono salvati.';

  @override
  String get notesRemoteReviewChanged =>
      'La nota sul server è cambiata. La bozza di unione è conservata. Esamina il nuovo confronto e scegli di nuovo la risoluzione.';

  @override
  String get notesReviewRemote => 'Ho esaminato la versione attuale del server';

  @override
  String get wsModuleCapsNotPublished =>
      'La capitalizzazione del modulo non viene pubblicata.';

  @override
  String get wsTitleOverridesAction => 'Titoli dell’istanza e dell’indice…';

  @override
  String get wsHeadingNotPublished => 'Non pubblicato da questo generatore.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Il builder fissato non pubblica titoli per istanza negli argomenti Markdown. Il markup esistente è conservato; consultalo nel sorgente.';

  @override
  String get wsTopicIdentity => 'ID argomento';

  @override
  String get wsElementAnchor => 'Ancora elemento';

  @override
  String get wsHeadingText => 'Testo intestazione';

  @override
  String get wsDefaultTitle => 'Titolo predefinito';

  @override
  String get wsTopicNavigation => 'Navigazione argomento';

  @override
  String get wsHeadingOptions => 'Attributi intestazione';

  @override
  String get wsDocumentOptions => 'Impostazioni documento';

  @override
  String get wsSettingsPresent => 'Impostazioni esplicite presenti';

  @override
  String get wsTitleOverrideExplanation =>
      'Sostituisce il titolo pubblicato; il testo dell’intestazione non cambia.';

  @override
  String get wsIgnoreVariables => 'Tratta le variabili come testo letterale';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Se attivo, il testo simile a una variabile non viene sostituito.';

  @override
  String get wsInstanceSelection => 'Istanze della guida';

  @override
  String get wsInstanceExplanation =>
      'Seleziona le uscite tramite nomi, gruppi, elenchi, esclusioni o espressioni.';

  @override
  String get wsFilterExplanation =>
      'Filtra contenuti riutilizzabili per criteri; non seleziona un’istanza della guida.';

  @override
  String get wsContextHelp => 'ID guida contestuale';

  @override
  String get wsCapitalization => 'Maiuscole e minuscole';

  @override
  String get wsLibraryTopic => 'Argomento libreria';

  @override
  String get wsLastModified => 'Ultima modifica';

  @override
  String get wsMissingTopicHeading =>
      'Nessun H1 dell’argomento. Aggiungilo nel sorgente.';

  @override
  String get wsMultipleTopicHeadings =>
      'Il primo H1 determina il titolo dell’argomento. Gli altri H1 sono intestazioni separate.';

  @override
  String get wsTopicIdentityMismatch =>
      'L’id radice differisce dall’ID del nome file. Usa Rinomina file argomento o consulta il sorgente.';

  @override
  String get wsUnsupportedProperties =>
      'Gli attributi non supportati sono conservati. Consultali nel sorgente.';

  @override
  String get wsGeneratedAnchor =>
      'Ancora generata; un valore crea una sostituzione.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Il builder fissato non pubblica gli attributi H1. Appartengono all’intestazione, non alla radice XML.';

  @override
  String get closeOtherTabs => 'Chiudi le altre schede';

  @override
  String get tocTopicFromTemplate => 'Argomento da modello...';

  @override
  String get tocSaveAsTemplate => 'Salva come modello';

  @override
  String get tocTemplateDialog => 'Crea argomento da modello';

  @override
  String get tocTemplatesEditor => 'Modelli di file e codice';

  @override
  String get tocEditTemplates => 'Modifica modelli...';

  @override
  String get tocCreateCustomTemplate => 'Crea modello personalizzato...';

  @override
  String get tocTemplateCreated => 'Modello creato';

  @override
  String get tocTemplateDefault => 'Predefiniti';

  @override
  String get tocTemplateCustom => 'Personalizzati';

  @override
  String get tocTemplateFilename => 'Nome file:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Interni';

  @override
  String get tocTemplateUnnamed => 'Senza nome';

  @override
  String get tocTemplateNew => 'Nuovo modello...';

  @override
  String get tocTemplateName => 'Nome:';

  @override
  String get tocTemplateExtension => 'Estensione:';

  @override
  String get tocTemplateLoadError =>
      'Impossibile caricare i modelli. I modelli esistenti non sono stati modificati.';

  @override
  String get tocTemplateSaveError =>
      'Impossibile salvare i modelli. Le modifiche sono ancora disponibili qui.';

  @override
  String get tocTemplateConflict =>
      'I modelli sono cambiati in un’altra finestra. Annulla e riapri l’editor.';

  @override
  String get tocTemplateDuplicateName =>
      'Esiste già un modello con questo nome ed estensione.';

  @override
  String get tocTemplateFormat => 'Formato:';

  @override
  String get tocTemplateReset => 'Ripristina';

  @override
  String get tocTemplateRetry => 'Riprova';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Rimuovi $count elementi dell’indice';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'I file sorgente associati a questi elementi dell’indice non verranno eliminati.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Seleziona un argomento da aggiungere all’istanza corrente';

  @override
  String get tocGroupName => 'Nome del gruppo';

  @override
  String get tocMoveLineUp => 'Sposta riga in alto';

  @override
  String get tocMoveLineDown => 'Sposta riga in basso';

  @override
  String get tocEmptyMdTopic => 'Argomento MD vuoto';

  @override
  String get tocEmptyXmlTopic => 'Argomento XML vuoto';

  @override
  String get tocCopySpecial => 'Copia speciale';

  @override
  String tocCopyFileName(String name) {
    return 'Nome del file dell’argomento \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Percorso del file dell’argomento';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Titolo dell’argomento \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID dell’elemento del sommario \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nome del file dell’argomento';

  @override
  String get tocCopyTopicTitleUnavailable => 'Titolo dell’argomento';

  @override
  String get tocCopyElementIdUnavailable => 'ID dell’elemento del sommario';

  @override
  String get tocEditTitleAction => 'Modifica titolo...';

  @override
  String get tocEditTitleDialog => 'Modifica titolo';

  @override
  String get tocRemoveElementAction => 'Rimuovi elemento del sommario...';

  @override
  String get tocSetHomePage => 'Imposta come pagina iniziale';

  @override
  String tocGoToElement(String fileName) {
    return 'Vai all’elemento del sommario in \'$fileName\'';
  }

  @override
  String get tocSynchronize => 'Sincronizza sommario ed editor';

  @override
  String get tocEmptyGroupAction => 'Gruppo vuoto';

  @override
  String get tocNewEmptyGroup => 'Nuovo gruppo vuoto';

  @override
  String get tocGroupAction => 'Raggruppa';

  @override
  String get tocNewGroup => 'Nuovo gruppo';

  @override
  String get tocSortChildren =>
      'Ordina alfabeticamente gli argomenti secondari';

  @override
  String get tocLinkTopicFiles => 'Collega file di argomenti al sommario...';

  @override
  String get addLocalMarkdownFiles => 'Aggiungi file Markdown locali';

  @override
  String get tocTitleField => 'Titolo nel sommario:';

  @override
  String get tocTopicTitleField => 'Titolo dell’argomento:';

  @override
  String get tocAdvancedSettings => 'Impostazioni avanzate';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Titolo per \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField => 'Titolo solo nel sommario:';

  @override
  String get tocInstanceTitleExplanation =>
      'Usato solo per l’istanza corrente. Per impostazione predefinita, viene ereditato dal titolo dell’argomento.';

  @override
  String get tocOnlyTitleExplanation =>
      'Usato solo nel sommario. Per impostazione predefinita, viene ereditato dal titolo dell’argomento o da quello specifico dell’istanza, se impostato. I titoli sono spiegati';

  @override
  String get tocTitleDocumentationLink => 'qui';

  @override
  String get tocFindUsages => 'Trova';

  @override
  String get tocRefactorMenu => 'Refactoring';

  @override
  String get tocSafeDelete => 'Eliminazione sicura';

  @override
  String get tocDuplicate => 'Duplica';

  @override
  String get tocDuplicateFilename => 'Nome del file dell’argomento:';

  @override
  String get tocDuplicateDialog => 'Duplica argomento';

  @override
  String get pdfTitlePage => 'Frontespizio';

  @override
  String get pdfIncludeTitlePage => 'Includi frontespizio';

  @override
  String get pdfTitlePageNote =>
      'Questa pagina non ha intestazione, piè di pagina o numero di pagina visibile.';

  @override
  String get pdfTitlePageTitle => 'Titolo';

  @override
  String get pdfTitlePageSubtitle => 'Sottotitolo';

  @override
  String get pdfTitlePageAuthor => 'Autore';

  @override
  String get pdfTitlePageOrganization => 'Organizzazione';

  @override
  String get pdfTitlePageVersion => 'Versione';

  @override
  String get pdfTitlePageDate => 'Data';

  @override
  String get pdfTitlePageTitleRequired =>
      'Inserisci un titolo per il frontespizio.';

  @override
  String get pdfTocSectionNote =>
      'Inizia su una pagina separata e può occupare più pagine.';

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
  String get copyPlainText => 'Copia come testo semplice';

  @override
  String get clipboardCopyFailed =>
      'Impossibile copiare la selezione negli appunti.';

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
  String get reading => 'Lettura';

  @override
  String get removeFromRecent => 'Rimuovi dai recenti';

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
      'Personalizza le scorciatoie da tastiera dell’applicazione';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Apri il riferimento della sintassi';

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
  String get wordWrapDescription =>
      'Adatta le righe lunghe alla larghezza dell’editor invece di scorrerle orizzontalmente.';

  @override
  String get editorFontSize => 'Dimensione del carattere dell\'editor';

  @override
  String get validateOnEdit => 'Convalida durante la modifica';

  @override
  String get clearRecentWorkspaces => 'Cancella la cronologia recente';

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
  String get settingsEditingButtonsSectionTitle => 'Pulsanti di modifica';

  @override
  String get spellingDictionaries => 'Dizionari ortografici';

  @override
  String get spellingDictionariesDescription =>
      'Installa e gestisci i dizionari ortografici';

  @override
  String get settingsDictionariesSectionTitle => 'Dizionari';

  @override
  String get availableSpellingDictionaries => 'Dizionari disponibili';

  @override
  String get customSpellingDictionaries => 'Dizionari personalizzati';

  @override
  String get spellingDictionaryProblems => 'Problemi dei dizionari';

  @override
  String get settingsWindowSectionTitle => 'Finestra';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Riapri l’area di lavoro precedente all’avvio';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Apri l’area di lavoro e le schede della sessione precedente all’avvio di BusyMark.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documenti hanno modifiche non salvate. Salvali prima di continuare?',
      one:
          '1 documento ha modifiche non salvate. Salvarlo prima di continuare?',
    );
    return '$_temp0';
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
  String get video => 'Video';

  @override
  String get openVideo => 'Riproduci video';

  @override
  String get pauseVideo => 'Metti in pausa il video';

  @override
  String get videoUnavailable => 'Video non disponibile';

  @override
  String get videoPreview => 'Anteprima video';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Al video manca l’attributo src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Sorgente video non supportata: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Il file video non esiste: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'L’immagine di anteprima del video non esiste: $preview';
  }

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
  String get insertBlankLine => 'Inserisci riga vuota';

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
  String get toc => 'Sommario';

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
  String get newSiblingTopic => 'Nuovo argomento';

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
  String get removeTocElements => 'Rimuovi elementi dal TOC';

  @override
  String get reviewUsages => 'Esamina utilizzi';

  @override
  String get deleteTopicFile => 'Elimina file dell’argomento';

  @override
  String get removeAction => 'Rimuovi';

  @override
  String topicRemovalSummary(String topic) {
    return 'Rimuovere l’elemento «$topic» dal sommario? Il file sorgente associato al sommario non verrà eliminato.';
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
  String get topicIsHomePageRemovalWarning =>
      'Questo argomento è la pagina iniziale di questa istanza. Scegli un’altra pagina iniziale prima di rimuoverlo dal sommario.';

  @override
  String get newHomePage => 'Nuova pagina iniziale';

  @override
  String get chooseHomePage => 'Scegli una pagina iniziale';

  @override
  String get noHomePageReplacement =>
      'Aggiungi o collega un altro argomento idoneo a questa istanza prima di rimuovere la sua pagina iniziale.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Questo argomento è la pagina iniziale di un’istanza. Imposta un’altra pagina iniziale prima di eliminare il suo file sorgente.';

  @override
  String topicUsagesCount(int count) {
    return '$count utilizzi trovati.';
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
  String get setRedirectTo => 'Reindirizza a:';

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
  String get preview => 'Anteprima';

  @override
  String get topicRenamePreviewTitle => 'Anteprima della ridenominazione';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Percorso: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'ID argomento: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Istanza $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'File interessati';

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
  String get sourceSearchReplacement => 'Sostituisci con';

  @override
  String get sourceSearchReplaceCurrent =>
      'Sostituisci la corrispondenza corrente';

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
    return 'Recuperato il contenuto non salvato di $fileName. Esaminalo, quindi salvalo, salvalo con un altro nome o scartalo.';
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
  String get workspaceSearchIncomplete =>
      'È mostrata solo una parte dei risultati. Mostrane altri o restringi la ricerca.';

  @override
  String get workspaceSearchShowMore => 'Mostra altri risultati';

  @override
  String get workspaceSearchSkippedFiles =>
      'La ricerca è incompleta. Questi file superano 1 MiB o non è stato possibile leggerli:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'File di grandi dimensioni: evidenziazione e ripiegamento sono sospesi';

  @override
  String get nothingToRead => 'Nessun contenuto da leggere';

  @override
  String get admonition => 'Riquadro informativo';

  @override
  String get quote => 'Citazione';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Impossibile aggiornare gli elementi recenti: $error.';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sono stati recuperati $count documenti non salvati. Revisiona ciascuno prima di salvare o scartare.',
      one:
          'È stato recuperato 1 documento non salvato. Revisionalo prima di salvarlo o scartarlo.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count record di ripristino danneggiati non sono stati ripristinati. I record di ripristino validi sono ancora disponibili.',
      one:
          'Un record di recupero danneggiato non può essere ripristinato. Il file di recupero originale è stato conservato per la revisione.',
    );
    return '$_temp0';
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
    return 'La pagina iniziale $topic non può essere eliminata. Scegli prima un’altra pagina iniziale.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'La ridenominazione non può aggiornare in modo sicuro tutti i riferimenti del progetto perché $count file di argomento nel modulo $module non sono stati analizzati: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'I file del progetto Writerside contengono modifiche non salvate. Risolvile e prepara una nuova anteprima della ridenominazione.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'L’insieme dei moduli del progetto Writerside è cambiato. Prepara una nuova anteprima della ridenominazione prima del refactoring.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'L’istanza \"$instanceId\" pubblica il nome file web non valido \"$webFileName\" per l’argomento \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'L’istanza \"$instanceId\" pubblica sia \"$firstTopic\" sia \"$secondTopic\" come \"$webFileName\".';
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
      other:
          'Tutte le modifiche in stage e non in stage nei file tracciati selezionati saranno ripristinate in HEAD.',
      one:
          'Tutte le modifiche in stage e non in stage nel file tracciato selezionato saranno ripristinate in HEAD.',
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
  String get gitProjectHistory => 'Cronologia del progetto';

  @override
  String get gitFileHistory => 'Cronologia del file';

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
  String get gitErrorAuthorIdentity =>
      'Git richiede il nome e l’indirizzo e-mail dell’autore prima di eseguire il commit.';

  @override
  String get gitAuthorIdentityTitle => 'Identità autore Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Inserisci l’identità che Git deve registrare nei commit. BusyMark la salverà e riproverà questo commit.';

  @override
  String get gitAuthorName => 'Nome';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Usa per tutti i repository';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Con l’installazione Snap, si applica ai repository aperti in BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Salva ed esegui commit';

  @override
  String get gitErrorAuthentication => 'Autenticazione Git non riuscita.';

  @override
  String get gitErrorNetwork => 'Operazione di rete Git non riuscita.';

  @override
  String get gitErrorConflict => 'Git ha segnalato conflitti non risolti.';

  @override
  String get gitErrorCommandFailed => 'Comando Git non riuscito.';

  @override
  String get syntaxReference => 'Riferimento della sintassi';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Blocchi Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Strutture a blocchi supportate nel sorgente Markdown e nell’anteprima.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown in linea';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formattazione dentro paragrafi, elementi di elenco e celle di tabella.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Blocchi HTML grezzi';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Tag HTML di blocco sicuri renderizzati dai widget di anteprima BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Tag HTML grezzi in linea';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Tag HTML in linea sicuri renderizzati senza mostrare i tag letterali.';

  @override
  String get syntaxReferenceHeadings => 'Titoli';

  @override
  String get syntaxReferenceParagraphs => 'Paragrafi';

  @override
  String get syntaxReferenceLists => 'Elenchi';

  @override
  String get syntaxReferenceHtmlContainers => 'Contenitori';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Blocchi di testo';

  @override
  String get syntaxReferenceHtmlFigures => 'Figure e immagini';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Codice preformattato';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Blocchi espandibili';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Elenchi descrittivi';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tag di formattazione';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tag di codice in linea';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Tag di testo semantico';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'L’HTML consentito viene convertito in blocchi di anteprima BusyMark e non viene renderizzato in un browser.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'L’HTML grezzo non modificato viene salvato esattamente come testo sorgente.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'I marcatori Markdown dentro HTML grezzo vengono visualizzati come testo letterale.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Script, stili, frame, moduli, SVG, MathML, eventi e attributi non sicuri vengono bloccati.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'I link consentono http, https, mailto, tel, URL relativi e frammenti; gli schemi non sicuri sono bloccati.';

  @override
  String get syntaxReferenceCategory => 'Categoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagrammi e API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matematica';

  @override
  String get syntaxReferenceExample => 'Esempio';

  @override
  String get syntaxReferenceIdentifiers => 'Identificatori e alias';

  @override
  String get syntaxReferenceScope => 'Ambito';

  @override
  String get syntaxReferenceLimitation => 'Limitazione di BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Documentazione ufficiale';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Solo Markdown Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Solo Markdown Writerside e XML Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Le forme Markdown essenziali che BusyMark può creare e visualizzare in anteprima.';

  @override
  String get syntaxReferenceParagraphExample => 'Un paragrafo di testo.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Le tabelle usano la sintassi con barre verticali di GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'due spazi a fine riga, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark accetta un sottoinsieme sicuro e mirato di HTML grezzo nel sorgente Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'I blocchi delimitati Mermaid, PlantUML, D2 e OpenAPI funzionano nel sorgente Markdown. Gli identificatori non distinguono maiuscole e minuscole e BusyMark conserva la grafia originale.';

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
      'Usare contenuto YAML o JSON in un blocco delimitato. BusyMark non considera un qualsiasi documento YAML o JSON completo come riferimento OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Blocchi di codice semantici per diagrammi';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Le forme semantiche code-block e src supportano Mermaid, PlantUML e D2, non OpenAPI, e solo nei progetti Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Sorgente di diagramma referenziato';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'I percorsi devono essere relativi e restare nel progetto Writerside aperto; la forma blocco delimitato con src è solo per Markdown Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark supporta espressioni TeX, non documenti TeX o LaTeX completi.';

  @override
  String get syntaxReferenceInlineMath => 'Formula in linea';

  @override
  String get syntaxReferenceGithubMath =>
      'Formula GitHub con dollaro e accento grave';

  @override
  String get syntaxReferenceDisplayMath => 'Formula visualizzata';

  @override
  String get syntaxReferenceMathFence => 'Blocco delimitato math';

  @override
  String get syntaxReferenceTexFence => 'Blocco delimitato tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark non riconosce \\(...\\) o \\[...\\] come delimitatori matematici Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Fuori dalla modalità Writerside, un blocco tex resta un normale blocco di codice.';

  @override
  String get syntaxReferenceWritersideMathElement =>
      'Elemento math di Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'L’elemento math è sintassi semantica Writerside, non MathML HTML grezzo consentito.';

  @override
  String get syntaxReferenceSemanticTexBlock =>
      'Blocco di codice TeX semantico';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Queste estensioni mirate sono interpretate solo nei progetti Writerside aperti.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Citazione di avviso';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Una citazione semplice è un suggerimento in Markdown Writerside; resta una citazione normale nel Markdown comune.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Avvisi semantici';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Il Markdown comune non interpreta questi elementi semantici Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Titolo comprimibile';

  @override
  String get syntaxReferenceCollapsibleCode => 'Blocco di codice comprimibile';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Contenuto semantico comprimibile';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark supporta le forme comprimibili chapter, procedure, code-block ed elenco di definizioni, non l’intero catalogo Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Blocchi di codice semantici per formule e diagrammi';

  @override
  String get syntaxReferenceVideo => 'Video Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Il video locale usa un’immagine preview-src locale; le sorgenti ospitate devono essere URL HTTPS supportati di YouTube o Vimeo.';

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
  String get exportFormat => 'Formato di output';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avvisi',
      one: '1 avviso',
    );
    return '$fileName è stato esportato con $_temp0.';
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
  String get writersidePdfContent => 'Contenuto dell’esportazione';

  @override
  String get writersidePdfPage => 'Pagina';

  @override
  String get exportingWritersidePdf => 'Esportazione del PDF Writerside…';

  @override
  String get ai => 'IA';

  @override
  String get aiLocalOllama => 'Ollama locale';

  @override
  String get aiDisabled => 'Disabilitato';

  @override
  String get aiExplicitEditingDescription =>
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

  @override
  String get goToDeclaration => 'Vai alla dichiarazione';

  @override
  String get findUsages => 'Trova utilizzi';

  @override
  String get cannotRenameSymbol =>
      'Impossibile rinominare il simbolo in sicurezza. Verifica il nome e aggiorna il riferimento prima di riprovare.';

  @override
  String get renameTopicFileInstead =>
      'Gli ID degli argomenti derivano dai nomi dei file. Usa Rinomina file argomento nel sommario o nella barra laterale File.';

  @override
  String get keyboardLayout => 'Disposizione della tastiera';

  @override
  String get diagnosticWritersideUnsupported =>
      'Il contenuto non supportato o malformato viene mostrato come sorgente.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Impossibile risolvere la sorgente «$reference»: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'La destinazione del collegamento non è disponibile in questa istanza: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Markup Writerside non valido: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Usa <llms-txt>true</llms-txt> o <llms-txt>false</llms-txt>; single-file non è più supportato.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Impossibile risolvere $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Esporta come HTML…';

  @override
  String get fileTypeHtml => 'Documento HTML';

  @override
  String get exportingHtml => 'Esportazione HTML…';

  @override
  String get htmlExported => 'Esportazione HTML completata';

  @override
  String get htmlExportFailed => 'Esportazione HTML non riuscita';

  @override
  String get htmlKeepAssetsTogether =>
      'Durante la copia, mantieni insieme il file HTML e la relativa cartella delle risorse.';

  @override
  String get htmlInstanceDescription =>
      'Esporta un’istanza come pagine collegate offline. Scegli un nome per una cartella di destinazione dedicata.';

  @override
  String get htmlInstance => 'Istanza';

  @override
  String get htmlOwnedDirectoryOnly =>
      'È possibile sostituire solo una cartella creata dall’esportazione HTML di BusyMark. I file modificati o estranei verranno conservati.';

  @override
  String get showInFolder => 'Mostra nella cartella';

  @override
  String sortTableColumn(String column) {
    return 'Ordina $column';
  }

  @override
  String get exportReset => 'Ripristina i valori predefiniti';

  @override
  String get exportToc => 'Includi indice';

  @override
  String get exportTocDepth => 'Profondità dell’indice';

  @override
  String get exportNumberHeadings => 'Numera i titoli';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Personalizzato';

  @override
  String get exportPageWidth => 'Larghezza pagina (mm)';

  @override
  String get exportPageHeight => 'Altezza pagina (mm)';

  @override
  String get exportMarginTop => 'Margine superiore (mm)';

  @override
  String get exportMarginRight => 'Margine destro (mm)';

  @override
  String get exportMarginBottom => 'Margine inferiore (mm)';

  @override
  String get exportMarginLeft => 'Margine sinistro (mm)';

  @override
  String get exportTypography => 'Tipografia';

  @override
  String get exportSans => 'Senza grazie';

  @override
  String get exportSerif => 'Con grazie';

  @override
  String get exportBodySize => 'Dimensione del testo';

  @override
  String get exportCodeSize => 'Dimensione del codice';

  @override
  String get exportRunningText => 'Intestazione e piè di pagina';

  @override
  String get exportHeader => 'Intestazione';

  @override
  String get exportFooter => 'Piè di pagina';

  @override
  String get exportNone => 'Nessuno';

  @override
  String get exportDocumentTitle => 'Titolo del documento';

  @override
  String get exportBottomLeft => 'In basso a sinistra';

  @override
  String get exportBottomCenter => 'In basso al centro';

  @override
  String get exportBottomRight => 'In basso a destra';

  @override
  String get exportFirstPage =>
      'Mostra intestazione e piè di pagina sulla prima pagina';

  @override
  String get exportAccent => 'Colore accento / collegamenti';

  @override
  String get exportTheme => 'Tema';

  @override
  String get exportAutomatic => 'Automatico';

  @override
  String get exportLayout => 'Impaginazione';

  @override
  String get exportContentWidth => 'Larghezza massima del contenuto';

  @override
  String get exportOutput => 'Uscita';

  @override
  String get exportPackaging => 'Pacchetto';

  @override
  String get exportSingleFile => 'Un solo file HTML';

  @override
  String get exportAssetsDirectory => 'HTML + cartella risorse';

  @override
  String get exportCustomCss => 'Foglio di stile personalizzato…';

  @override
  String get exportRemoveCss => 'Rimuovi il foglio di stile';

  @override
  String get exportCssNote =>
      'Scegli un file CSS UTF-8 facoltativo (fino a 256 KiB). Importazioni, URL di risorse e CSS eseguibile o con escape non sono ammessi. Gli stili seguono quelli di BusyMark. Le risorse remote non vengono scaricate.';

  @override
  String get exportSitePackagingNote =>
      'Writerside mantiene pagine separate e collegate. La modalità file singolo incorpora le risorse in ogni pagina.';

  @override
  String get exportInvalidGeometry =>
      'Lascia almeno 20 mm di larghezza e altezza del contenuto dopo i margini.';

  @override
  String get exportInvalidColor => 'Inserisci un colore come #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Scegli un file .css UTF-8 leggibile fino a 256 KiB, senza importazioni, URL di risorse, HTML o CSS eseguibile o con escape.';

  @override
  String get clipboardHistory => 'Cronologia della Copia';

  @override
  String get clipboardHistoryDescription =>
      'Apri la cronologia della copia locale della sessione.';

  @override
  String get clipboardCurrent => 'Copia corrente';

  @override
  String get clipboardCurrentExternal =>
      'Copia corrente da un\'altra applicazione';

  @override
  String clipboardDestination(String name) {
    return 'Incolla in $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Memorizzata solo per questa sessione BusyMark.';

  @override
  String get clipboardNoItems => 'La cronologia della copia è vuota.';

  @override
  String get clipboardDisabled =>
      'La collezione Cronologia della Copia è disabilitata nelle Impostazioni.';

  @override
  String get clipboardUnavailable =>
      'Il contenuto della copia corrente non è disponibile o non è supportato.';

  @override
  String get clipboardTooLarge =>
      'Questo elemento del segnalibro è troppo grande per essere conservato.';

  @override
  String get clipboardPastePlainText => 'Incolla come testo semplice';

  @override
  String get clipboardClearAll => 'Cancella la cronologia del segnalibro';

  @override
  String get clipboardEntryText => 'Testo';

  @override
  String get clipboardEntryRichText => 'Testo ricco';

  @override
  String get clipboardEntryImage => 'Immagine';

  @override
  String clipboardOrigin(String name) {
    return 'Copiato da $name';
  }

  @override
  String get localHistory => 'Cronologia locale';

  @override
  String get localHistoryEllipsis => 'Cronologia locale…';

  @override
  String get localHistoryDescription =>
      'Mostra le revisioni locali salvate e automatiche per il documento corrente.';

  @override
  String get findLocalHistoryEllipsis => 'Trova nella cronologia locale…';

  @override
  String get findLocalHistoryDescription =>
      'Cerca documenti e contenuti delle revisioni nella cronologia locale.';

  @override
  String get localHistoryNoDocuments =>
      'Nessun documento ha ancora una cronologia locale.';

  @override
  String get localHistoryNoRevisions =>
      'Questo documento non ha revisioni nella cronologia locale.';

  @override
  String get localHistorySelectedRevision => 'Revisione selezionata';

  @override
  String get localHistoryCurrentEditor => 'Contenuto dell\'editor corrente';

  @override
  String get localHistoryCurrentDisk => 'Contenuto corrente sul disco';

  @override
  String get localHistoryMissingFile => 'Il file originale è mancante.';

  @override
  String get localHistoryRestoreRevision => 'Ripristina Versione';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Ripristina alla Posizione Originale';

  @override
  String get localHistoryRestoreNewLocation =>
      'Ripristina alla Nuova Posizione…';

  @override
  String get localHistoryRestoreChange => 'Ripristina Modifica';

  @override
  String get localHistoryRestoreUnavailable =>
      'Questa modifica non può essere ripristinata perché il confronto non è più valido.';

  @override
  String get localHistoryComparisonSimplified =>
      'Questo confronto ampio è semplificato. Il ripristino di singole modifiche non è disponibile.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Modifica di una versione precedente: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Modifica del contenuto corrente: $text';
  }

  @override
  String get localHistoryDeleted => 'Eliminato';

  @override
  String get localHistoryUntitled => 'Senza Titolo';

  @override
  String get localHistoryClearDocument =>
      'Cancella la cronologia di questo documento';

  @override
  String get localHistoryClearAll => 'Cancella tutta la cronologia locale';

  @override
  String get localHistoryClearDocumentTitle =>
      'Cancella la cronologia del documento?';

  @override
  String get localHistoryClearAllTitle =>
      'Cancella tutta la cronologia locale?';

  @override
  String get localHistoryClearConfirmation =>
      'Questo rimuove permanentemente le revisioni memorizzate. Questa azione non può essere annullata.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'L\'indice della cronologia locale è stato danneggiato e ricostruito da revisioni intatte.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Questo archivio della cronologia locale utilizza un formato non supportato $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'La cronologia locale non è disponibile: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'La registrazione è disabilitata o questo percorso è escluso. Riattiva la registrazione prima di ripristinare.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'La cronologia locale non è riuscita a registrare la modifica del percorso: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'La cronologia locale non è riuscita a conservare il percorso eliminato: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'La revisione selezionata è mancante o danneggiata.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'La revisione selezionata non può essere letta: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'La cronologia locale non è riuscita a catturare questa revisione: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Versione iniziale';

  @override
  String get localHistoryReasonSaved => 'Salvato';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Controllo automatico';

  @override
  String get localHistoryReasonBeforeReload => 'Prima del ricaricamento';

  @override
  String get localHistoryReasonBeforeDiscard => 'Prima di eliminare';

  @override
  String get localHistoryReasonBeforeRestore => 'Prima del ripristino';

  @override
  String get localHistoryReasonBeforeDelete => 'Prima della cancellazione';

  @override
  String get localHistoryReasonExternalChange => 'Modifica esterna';

  @override
  String get settingsHistory => 'Cronologia';

  @override
  String get settingsClipboardHistoryTitle =>
      'Raccogli la cronologia della clipboard';

  @override
  String get settingsClipboardHistoryDescription =>
      'Mantieni il contenuto copiato e incollato per questa sessione BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'Registra la cronologia locale';

  @override
  String get settingsLocalHistoryDescription =>
      'Salva le revisioni del documento su questo dispositivo per il recupero e il confronto.';

  @override
  String get settingsHistoryCheckpoint => 'Intervallo di checkpoint automatico';

  @override
  String get settingsHistoryRetention => 'Periodo di conservazione';

  @override
  String get settingsHistoryStorage => 'Massimo spazio di archiviazione';

  @override
  String get settingsHistoryExcludedPaths => 'Percorsi esclusi';

  @override
  String get settingsHistoryExcludedPathsHint =>
      'Un percorso assoluto per riga';

  @override
  String settingsSecondsValue(int value) {
    return '$value secondi';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value giorni';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Ortografia';

  @override
  String get automaticSpelling => 'Controllo ortografico automatico';

  @override
  String get defaultSpellingLanguage => 'Lingua ortografica predefinita';

  @override
  String get projectSpellingLanguage =>
      'Lingua di controllo ortografico del progetto';

  @override
  String get chooseSpellingLanguage => 'Scegli la lingua ortografica';

  @override
  String get spellingLanguageUnsetStatus => 'Lingua…';

  @override
  String get spellingOffStatus => 'Controllo ortografico disattivato';

  @override
  String get checkSpelling => 'Controlla ortografia';

  @override
  String get ignoreSpellingOnce => 'Ignora una volta';

  @override
  String get ignoreSpellingDocument => 'Ignora tutto in questo documento';

  @override
  String get addPersonalSpellingWord => 'Aggiungi al dizionario personale';

  @override
  String get addProjectSpellingWord => 'Aggiungi al dizionario del progetto';

  @override
  String get inheritSpellingLanguage => 'Usa la lingua del progetto o dell’app';

  @override
  String get disableDocumentSpelling => 'Non controllare l’ortografia';

  @override
  String get importSpellingDictionary => 'Importa dizionario';

  @override
  String get personalSpellingDictionary => 'Dizionario personale';

  @override
  String get projectSpellingDictionary => 'Dizionario del progetto';

  @override
  String get noSpellingErrors => 'Nessun errore di ortografia';

  @override
  String get noSpellingSuggestions => 'Nessun suggerimento ortografico';

  @override
  String get spellingWordCheckFailed => 'Impossibile controllare questa parola';

  @override
  String get spellingCheckFailed => 'Controllo ortografico non riuscito';

  @override
  String get spellingSettingsLoadFailed =>
      'Impossibile caricare le impostazioni di controllo ortografico';

  @override
  String get retrySpellingSettings =>
      'Riprova a caricare le impostazioni di controllo ortografico';

  @override
  String get spellingCheckIncomplete => 'Il controllo ortografico è incompleto';

  @override
  String get spellingDictionaryNotInstalled => 'Dizionario non installato';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Il dizionario $dictionary non è installato';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Non installato · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Installato';

  @override
  String get installSpellingDictionary => 'Installa dizionario';

  @override
  String get removeSpellingDictionary => 'Rimuovi dizionario';

  @override
  String get cancelSpellingDictionaryInstall =>
      'Annulla download del dizionario';

  @override
  String get retrySpellingDictionaryInstall =>
      'Riprova l’installazione del dizionario';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Download di $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Convalida del dizionario…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Installazione non riuscita — seleziona per riprovare';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Installare $dictionary ($size)? Dopo l’installazione resterà disponibile offline finché non verrà rimosso.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Dizionario non disponibile';

  @override
  String get spellingChecking => 'Controllo ortografico…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: inserisci un numero tra $minimum e $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Il dizionario ortografico è stato modificato esternamente. È stata conservata una copia di ripristino.';

  @override
  String get windowMinimize => 'Riduci';

  @override
  String get windowMaximize => 'Ingrandisci';

  @override
  String get windowRestore => 'Ripristina';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Connetti';

  @override
  String get nextcloudReconnect => 'Riconnetti';

  @override
  String get nextcloudDisconnect => 'Disconnetti';

  @override
  String get nextcloudServer => 'URL del server';

  @override
  String get nextcloudSignInBrowser => 'Completa l’accesso nel browser.';

  @override
  String get nextcloudFavorites => 'Preferiti';

  @override
  String get nextcloudNewNote => 'Nuova nota';

  @override
  String get nextcloudSavedLocally =>
      'Salvato localmente · sincronizzazione in attesa';

  @override
  String get nextcloudSyncing => 'Sincronizzazione';

  @override
  String get nextcloudSynced => 'Sincronizzato';

  @override
  String get nextcloudOffline => 'Non in linea';

  @override
  String get nextcloudLocked => 'Bloccato dal server';

  @override
  String get nextcloudReconnectRequired => 'Riconnessione necessaria';

  @override
  String get nextcloudCreationUncertain => 'Esito della creazione incerto';

  @override
  String get nextcloudReadOnly => 'Sola lettura';

  @override
  String get nextcloudTakeRemote => 'Usa versione remota';

  @override
  String get nextcloudMerge => 'Unisci';

  @override
  String get nextcloudDeleteNote => 'Eliminare la nota?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'La sostituzione nell’area di lavoro non è disponibile per Nextcloud Notes. Sostituisci in ogni nota.';

  @override
  String get nextcloudSaveLocalCopy => 'Salva copia locale…';

  @override
  String get nextcloudDisconnectWarning =>
      'Rimuovendo questo account si eliminano note memorizzate e modifiche in attesa dal dispositivo. Sincronizza prima per conservare il lavoro sul server.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Se il caricamento precedente è riuscito, il nuovo tentativo può lasciare un allegato inutilizzato sul server.';

  @override
  String get nextcloudAttachmentReference => 'Riferimento allegato sul server';

  @override
  String get nextcloudAddAttachment => 'Aggiungi allegato…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Eliminando questo allegato, i suoi collegamenti nella nota non saranno più disponibili. I dati conservati possono essere recuperati dalla cronologia locale.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Scegli ogni attributo in conflitto.';

  @override
  String get nextcloudUseServerNote => 'Usa questa nota del server';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Collega questa bozza alla nota selezionata sul server, poi sincronizza le modifiche locali conservate. Una richiesta corrispondente non conferma chi ha creato la nota.';

  @override
  String get nextcloudExactCandidate =>
      'Corrispondenza esatta con la richiesta; identità non confermata.';

  @override
  String get nextcloudPossibleCandidate =>
      'Possibile corrispondenza dopo la normalizzazione; identità non confermata.';

  @override
  String get nextcloudSelectCandidate =>
      'Seleziona una nota del server da esaminare';

  @override
  String get nextcloudCreateSeparate => 'Crea una nota separata';

  @override
  String get nextcloudCreateSeparateWarning =>
      'La prima richiesta potrebbe aver già creato una nota sul server. Questa azione crea una nota separata con il lavoro locale conservato. Nessun presunto duplicato verrà eliminato.';

  @override
  String get wsSemanticFormats => 'Formattazione semantica';

  @override
  String get wsUiControl => 'Controllo dell’interfaccia';

  @override
  String get wsFilePath => 'File / Percorso';

  @override
  String get wsUiPath => 'Percorso dell’interfaccia';

  @override
  String get wsDefinitionList => 'Elenco di definizioni';

  @override
  String get wsIncludeContent => 'Includi contenuto riutilizzabile';

  @override
  String get wsVariableReference => 'Riferimento a variabile';

  @override
  String get wsConvertList => 'Converti elenco in procedura';

  @override
  String get wsElementProperties => 'Proprietà dell’elemento';

  @override
  String get wsTopicProperties => 'Proprietà dell’argomento';

  @override
  String get wsCollapsible => 'Comprimibile';

  @override
  String get wsPublishedState => 'Stato iniziale pubblicato';

  @override
  String get wsExpanded => 'Espanso';

  @override
  String get wsCollapsed => 'Compresso';

  @override
  String get wsCollapsedTitle => 'Titolo compresso';

  @override
  String get wsTerm => 'Termine';

  @override
  String get wsListLayout => 'Disposizione dell’elenco';

  @override
  String get wsSyncGroup => 'Gruppo di sincronizzazione';

  @override
  String get wsTabKey => 'Chiave della scheda';

  @override
  String get wsSwitcherLabel => 'Etichetta del selettore';

  @override
  String get wsNavigationElements => 'Elementi di navigazione';

  @override
  String get wsNavigationDepth => 'Profondità di navigazione';

  @override
  String get wsAddItem => 'Aggiungi elemento';

  @override
  String get wsStep => 'Passaggio';

  @override
  String get wsPropertyInvalid => 'Valore della proprietà non valido';

  @override
  String get wsFilter => 'Filtro';

  @override
  String get wsIdentifier => 'ID elemento';

  @override
  String get wsTldr => 'Riepilogo (TLDR)';

  @override
  String get wsFullLayout => 'Larghezza piena';

  @override
  String get wsMediumLayout => 'Medio (1:2)';

  @override
  String get wsNarrowLayout => 'Termine stretto';

  @override
  String get wsTitle => 'Titolo';

  @override
  String get wsSwitcherKey => 'Chiave del selettore';

  @override
  String get nextcloudServerSettings => 'Impostazioni Notes del server';

  @override
  String get nextcloudNotesPath => 'Percorso della cartella delle note';

  @override
  String get nextcloudFileSuffix => 'Estensione delle nuove note';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Queste impostazioni Notes influiscono sugli altri client. Cambiare il percorso non sposta i file; cambiare l’estensione non rinomina le note esistenti.';

  @override
  String get nextcloudSettingsSaved => 'Impostazioni del server salvate';

  @override
  String get nextcloudSettingsNormalized =>
      'Salvato con i valori normalizzati dal server';

  @override
  String get nextcloudPendingUpload => 'Caricamento allegato in attesa';

  @override
  String nextcloudServerCheck(String time) {
    return 'Ultimo controllo del server: $time';
  }

  @override
  String get nextcloudSettingsLoading =>
      'Caricamento delle impostazioni del server';

  @override
  String get nextcloudSettingsSaving =>
      'Salvataggio delle impostazioni del server';

  @override
  String get nextcloudPreviousLocalEdit => 'Modifica locale precedente';

  @override
  String get nextcloudUsePreviousEdit => 'Usa la modifica precedente';

  @override
  String get quickOpen => 'Apertura rapida';

  @override
  String get notesAll => 'Tutte le note';

  @override
  String get notesUncategorized => 'Senza categoria';

  @override
  String get notesRecovery => 'Recupero';

  @override
  String get notesRecentlyEdited => 'Modificate di recente';

  @override
  String get notesOldestEdited => 'Modifiche più vecchie';

  @override
  String get notesTitleAscending => 'Titolo A–Z';

  @override
  String get notesTitleDescending => 'Titolo Z–A';

  @override
  String get notesMove => 'Sposta nella categoria';

  @override
  String get notesRemoveFavorite => 'Rimuovi preferito';

  @override
  String get notesOffline => 'Rendi disponibile offline';

  @override
  String get notesOfflineRemove => 'Rimuovi conservazione offline';

  @override
  String get notesIndexing => 'Indicizzazione delle note…';

  @override
  String get notesSearchHelp =>
      'I termini usano E. Usa \"frasi tra virgolette\", title: e category:.';

  @override
  String get notesSourceLocation => 'Posizione nel sorgente';

  @override
  String get notesRecoveryHelp =>
      'Solo note locali conservate e cronologia locale. Cestino e cronologia del server non disponibili.';

  @override
  String get notesImport => 'Importa note';

  @override
  String get notesExport => 'Esporta note';

  @override
  String get notesImportDistinct => 'Importa come nota distinta';

  @override
  String get notesAvailableOffline => 'Disponibile offline';

  @override
  String get notesIncomplete => 'Incompleto';

  @override
  String get notesSelected => 'Note selezionate';

  @override
  String get notesNoHistory =>
      'Nessuna revisione conservata. La cronologia può essere disabilitata, scaduta o cancellata.';

  @override
  String get notesTextAvailable => 'Testo disponibile localmente';

  @override
  String get notesLocalVersion => 'Versione di lavoro locale';

  @override
  String get notesAttachments => 'Allegati';

  @override
  String get notesSkipped => 'Saltato';

  @override
  String get notesFailed => 'Non riuscito';

  @override
  String get notesCompleted => 'Completato';

  @override
  String get notesImportNew => 'Avvia una nuova importazione';

  @override
  String get notesImportResume => 'Riprendi importazione interrotta';

  @override
  String get notesImportAlreadyImported => 'Già importato in questa operazione';

  @override
  String get references => 'Riferimenti';

  @override
  String get referenceIncoming => 'In entrata';

  @override
  String get referenceOutgoing => 'In uscita';

  @override
  String get referenceChooseTarget => 'Scegli destinazione del collegamento';

  @override
  String get referenceWholeDocument => 'Intero documento';

  @override
  String get referenceSourceLocation => 'Posizione di origine';

  @override
  String get referenceTargetLocation => 'Posizione di destinazione';

  @override
  String get referenceResolved => 'Risolto';

  @override
  String get referenceMissing => 'Mancante';

  @override
  String get referenceAmbiguous => 'Ambiguo';

  @override
  String get referenceUnavailable => 'Non disponibile in questo contesto';

  @override
  String get referenceUnsupported => 'Non supportato';

  @override
  String get referenceNoPortableId =>
      'Questa destinazione non ha un URL portabile della nota verificato.';

  @override
  String get wsIncludeLines => 'Includi righe';

  @override
  String get wsIncludeSymbol => 'Includi simbolo';

  @override
  String get wsEmphasizeLines => 'Evidenzia righe visualizzate';

  @override
  String get wsPropertiesReadOnly =>
      'Proprietà di sola lettura in questa vista.';

  @override
  String get wsPropertiesProtected =>
      'Elemento protetto. Modifica la sorgente.';

  @override
  String get wsPropertiesConflict =>
      'Documento o elemento modificato. Annulla la bozza e seleziona di nuovo.';

  @override
  String get wsPropertiesUnresolved =>
      'Impossibile risolvere il riferimento al momento.';

  @override
  String get wsUseDefault => 'Usa predefinito';

  @override
  String get wsPropertiesSelection => 'Seleziona un solo elemento.';

  @override
  String get wsImageDisplay => 'Visualizzazione immagine';

  @override
  String get wsImageThumbnail => 'Miniatura cliccabile';

  @override
  String get wsEnabled => 'Abilitato';

  @override
  String get wsDisabled => 'Disabilitato';

  @override
  String get wsWidth => 'Larghezza';

  @override
  String get wsHeight => 'Altezza';

  @override
  String get wsPropertiesInactive =>
      'Questa proprietà non ha effetto senza compressione pubblicata.';

  @override
  String get wsNavigationAll => 'Tutti gli elementi con titolo';

  @override
  String get wsNavigationNone => 'Nessuna navigazione';

  @override
  String get wsNavigationCustom => 'Navigazione personalizzata';

  @override
  String get wsTitleOverride => 'Sostituisci titolo';

  @override
  String get wsCompactLayout => 'Compatto';

  @override
  String get wsWideLayout => 'Largo';

  @override
  String get wsCodeSourceConflict =>
      'Sposta o rimuovi il codice scritto in questo blocco prima di impostare src. Writerside rifiuta un blocco di codice non vuoto con un riferimento sorgente.';

  @override
  String get wsInherited => 'Eredita dall’elenco';

  @override
  String get wsExternalImageSize =>
      'Writerside non dimensiona in modo affidabile le immagini esterne. Le dimensioni esistenti possono essere consultate e rimosse.';

  @override
  String get wsPropertiesNotSerialized =>
      'Questa modifica non è stata applicata al sorgente. La bozza è stata conservata.';

  @override
  String get wsListItem => 'Elemento elenco';

  @override
  String get wsSourceFile => 'File sorgente';

  @override
  String get wsLinkTarget => 'Destinazione del collegamento';

  @override
  String get wsPreviewImage => 'Immagine di anteprima';

  @override
  String get wsIncludedElement => 'Elemento incluso';

  @override
  String get wsHelpModule => 'Modulo di aiuto';

  @override
  String get wsActionId => 'ID azione';

  @override
  String get wsKeymapHelpInstance => 'Istanza di aiuto della mappa tasti';

  @override
  String get wsShowInSource => 'Mostra nel sorgente';

  @override
  String get wsOriginElement => 'Valore dell’elemento';

  @override
  String get wsOriginAncestor => 'Elemento padre';

  @override
  String get wsOriginModule => 'Predefinito del modulo';

  @override
  String get wsOriginBuiltIn => 'Predefinito integrato';

  @override
  String get wsOriginUnresolved => 'Non risolto';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Effettivo: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Elemento';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Generato: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Predefinito: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Predefinito: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Risolto: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Non risolto';

  @override
  String get wsModule => 'Modulo';

  @override
  String get wsParent => 'Elemento padre';

  @override
  String get wsListType => 'Tipo di elenco';

  @override
  String get wsStartingNumber => 'Numero iniziale';

  @override
  String get wsListSorting => 'Ordinamento';

  @override
  String get wsLetteredList => 'Elenco alfabetico';

  @override
  String get wsCheckboxList => 'Elenco con caselle';

  @override
  String get wsMarkerlessList => 'Elenco senza indicatori';

  @override
  String get wsAscending => 'Crescente';

  @override
  String get wsDescending => 'Decrescente';

  @override
  String get wsNoSorting => 'Nessun ordinamento';

  @override
  String get wsAsWritten => 'Come scritto';

  @override
  String get wsSentenceCase => 'Maiuscola iniziale';

  @override
  String get wsTitleCase => 'Maiuscole del titolo';

  @override
  String get wsLowerCase => 'Minuscolo';

  @override
  String get wsUpperCase => 'Maiuscolo';

  @override
  String get wsNativeMarkers => 'Indicatori Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Indicatore iniziale: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Livello $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Il builder fissato ignora le regole <caps> del modulo. Usare un attributo caps locale o default-property.';

  @override
  String get wsInsertElements => 'Inserisci elementi';

  @override
  String get wsAdmonitionsAndQuotes => 'Avvisi e citazioni';

  @override
  String get wsSemanticText => 'Testo semantico';

  @override
  String get wsPropertiesUnavailable =>
      'L’elemento esaminato non è disponibile. Esamina un elemento per continuare.';

  @override
  String get searchDocumentsCategory => 'Documenti';

  @override
  String get searchTopicsCategory => 'Argomenti';

  @override
  String get searchCurrentDocument => 'Documento corrente';

  @override
  String get searchCurrentWorkspace => 'Area di lavoro corrente';

  @override
  String get browseNotes => 'Sfoglia note';

  @override
  String get searchActionsCommand => 'Cerca azioni';

  @override
  String get searchDocumentsCommand => 'Cerca documenti';

  @override
  String get searchTopicsCommand => 'Cerca argomenti';

  @override
  String get searchRecentCommand => 'Cerca recenti';

  @override
  String get searchResourceUnavailable => 'Questa risorsa non è disponibile.';

  @override
  String get notesSync => 'Sincronizza note';

  @override
  String get searchInWorkspace => 'Cerca nello spazio di lavoro';

  @override
  String get searchCategory => 'Categoria di ricerca';

  @override
  String get clearHistorySearchScope => 'Cerca nella cronologia dei documenti';

  @override
  String get searchInDocument => 'Cerca nel documento';

  @override
  String get searchDocumentHint => 'Cerca in questo documento…';

  @override
  String get searchWorkspaceHint => 'Cerca in questo spazio di lavoro…';

  @override
  String get searchOutlineHint => 'Cerca titoli…';

  @override
  String get searchHistoryHint => 'Cerca nella cronologia locale…';

  @override
  String get searchEnterText => 'Inserisci il testo da cercare';

  @override
  String get searchAccountUnavailable => 'Account non disponibile';

  @override
  String get searchDocumentsHint => 'Cerca documenti…';

  @override
  String get searchTopicsHint => 'Cerca argomenti…';

  @override
  String get searchRecentHint => 'Cerca recenti…';

  @override
  String get searchActionsHint => 'Cerca azioni…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Richiede uno spazio di lavoro Note';

  @override
  String get searchSidebarLabel => 'Ricerca:';

  @override
  String get searchDocumentTextCategory => 'Testo del documento';

  @override
  String get searchWorkspaceTextCategory => 'Testo dell’area di lavoro';

  @override
  String get searchHeadingsCategory => 'Intestazioni';

  @override
  String get shortcutUnassigned => 'Non assegnata';

  @override
  String get shortcutPressKeys => 'Premi una combinazione di tasti…';

  @override
  String get shortcutRecord => 'Acquisisci scorciatoia';

  @override
  String get shortcutRestoreAll =>
      'Ripristina tutte le impostazioni predefinite';

  @override
  String get shortcutRestoreAllQuestion =>
      'Ripristinare le scorciatoie predefinite di tutte le azioni? Le assegnazioni personalizzate verranno rimosse.';

  @override
  String get shortcutSaveFailed =>
      'Le scorciatoie sono attive ma non sono state salvate. Riprova per mantenerle dopo il riavvio.';

  @override
  String get shortcutRetry => 'Riprova salvataggio';

  @override
  String get shortcutChanged =>
      'Le assegnazioni sono cambiate. Controlla le scorciatoie attuali e riprova.';

  @override
  String get shortcutInvalid =>
      'Questa combinazione non può essere assegnata in questo contesto.';

  @override
  String get shortcutSystemWarning =>
      'Questa combinazione potrebbe essere usata dal desktop. BusyMark non può sostituire le scorciatoie di sistema.';

  @override
  String get shortcutConflicts =>
      'Questa scorciatoia è in conflitto con queste azioni:';

  @override
  String get shortcutRemove => 'Rimuovi assegnazione';

  @override
  String get shortcutRestoreDefault => 'Ripristina predefinita';

  @override
  String get shortcutAssign => 'Assegna';

  @override
  String get shortcutReassign => 'Riassegna';

  @override
  String get shortcutContextApplication => 'Applicazione';

  @override
  String get shortcutContextDocument => 'Viste del documento';

  @override
  String get shortcutContextEditor => 'Editor e sorgente';

  @override
  String get shortcutContextWritersideSource => 'Sorgente Writerside';

  @override
  String get shortcutContextWorkspace => 'Navigazione dell’area di lavoro';

  @override
  String get shortcutContextTree => 'Alberi laterali';

  @override
  String get searchHeadingsCommand => 'Cerca titoli';

  @override
  String get shortcutFixed => 'Gestito dall’editor; non configurabile.';

  @override
  String get shortcutDefaultConflict =>
      'La scorciatoia predefinita è in conflitto con un’assegnazione personalizzata.';

  @override
  String get shortcutCurrentBinding => 'Scorciatoia attuale';

  @override
  String get shortcutProposedBinding => 'Scorciatoia proposta';

  @override
  String get notesActions => 'Azioni delle note';

  @override
  String get noteActions => 'Azioni della nota';

  @override
  String get noteProperties => 'Proprietà della nota';

  @override
  String get notesExportAll => 'Esporta note · Tutte le note…';

  @override
  String get notesExportCategory => 'Esporta note · Categoria…';

  @override
  String get notesOfflineAll => 'Rendi disponibile offline · Tutte le note';

  @override
  String get notesOfflineCategory => 'Rendi disponibile offline · Categoria';

  @override
  String get notesOfflineRemoveAll =>
      'Rimuovi conservazione offline · Tutte le note';

  @override
  String get notesOfflineRemoveCategory =>
      'Rimuovi conservazione offline · Categoria';

  @override
  String get notesOfflinePause => 'Sospendi download';

  @override
  String get notesOfflineResume => 'Riprendi download';

  @override
  String get notesOfflineKeep => 'Rendi disponibile offline';

  @override
  String get notesOfflineRetentionHelp =>
      'Rimuovere questo requisito conserva i contenuti nella cache. Un requisito di categoria o account può ancora conservare la nota.';

  @override
  String get notesOfflineBroader =>
      'La nota è conservata anche da un requisito di categoria o account.';

  @override
  String get notesOfflineExternal =>
      'I contenuti multimediali esterni richiedono una connessione. BusyMark conserva solo testo e allegati gestiti.';

  @override
  String get notesEmptyAll => 'Nessuna nota. Creane una per iniziare.';

  @override
  String get notesEmptyFavorites => 'Nessuna nota preferita.';

  @override
  String get notesEmptyCategory => 'Nessuna nota in questa categoria.';

  @override
  String get notesEmptyUncategorized => 'Nessuna nota senza categoria.';

  @override
  String get notesEmptyRecovery => 'Nessuna nota conservata da recuperare.';

  @override
  String get notesLoadFailed => 'Nextcloud Notes · Non riuscito. Riprova';

  @override
  String get notesOperationFailed =>
      'L’operazione non è terminata. La bozza è conservata. Controlla il salvataggio e i conflitti, poi riprova.';

  @override
  String get notesInspectionFailed => 'Allegati · Non riuscito. Riprova';

  @override
  String get notesStartingConnection => 'Avvio della connessione Nextcloud…';

  @override
  String get notesVerifyingConnection => 'Verifica dell’accesso alle note…';

  @override
  String get notesCancellingConnection =>
      'Annullamento dell’accesso e pulizia…';

  @override
  String get notesRemovingConnection => 'Rimozione dell’account locale…';

  @override
  String get notesRemovedWarning =>
      'L’account Nextcloud locale è stato rimosso. La revoca della password dell’app non è confermata. Rimuovi la password di BusyMark nelle impostazioni di sicurezza di Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Non tutte le note aperte sono state salvate localmente. Controlla salvataggio, conflitti o normalizzazione nell’area di lavoro. Le modifiche locali potrebbero richiedere ancora la sincronizzazione con Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Salvare le modifiche alle impostazioni Nextcloud prima di uscire?';

  @override
  String get notesSettingsLeaveHelp =>
      'Impostazioni Notes del server · Modifiche non salvate';

  @override
  String get notesSettingsReload => 'Ricarica impostazioni del server…';

  @override
  String get notesSettingsReloadHelp =>
      'Il ricaricamento sostituisce la bozza con le impostazioni attuali di Nextcloud. Scartare la bozza e ricaricare?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud ha accettato le impostazioni, ma l’aggiornamento delle note è fallito. Sono mostrati i valori confermati dal server. Riprova l’aggiornamento dalle note.';

  @override
  String get notesUnavailable =>
      'Non in linea · Testo disponibile localmente · Salvato localmente · sincronizzazione in attesa';

  @override
  String get notesStorageFull =>
      'Lo spazio Nextcloud è esaurito. Libera spazio sul server e riprova.';

  @override
  String get notesRejected =>
      'Nextcloud ha rifiutato questa modifica. Controlla la nota e salva una copia locale prima di riprovare.';

  @override
  String get notesThrottled =>
      'Nextcloud ha chiesto di attendere. La sincronizzazione riprenderà al termine dell’attesa.';

  @override
  String get notesRecoveryRequired => 'Conflitti · Confronta';

  @override
  String get notesScanning => 'Analisi dei file…';

  @override
  String get notesCancelling =>
      'Annullamento… In attesa che termini l’operazione in corso.';

  @override
  String get notesCancelled => 'Annullato';

  @override
  String get notesPartial => 'Completato parzialmente';

  @override
  String get notesTransferFailed => 'Non riuscito. Riprova';

  @override
  String get notesImportPartialHelp =>
      'Gli elementi precedenti potrebbero essere già salvati localmente. Riprendi questa importazione per evitare duplicati.';

  @override
  String get notesNotStarted => 'Non avviato';

  @override
  String get notesCreated => 'Creato';

  @override
  String get notesRemoteDeleteUnavailable =>
      'URL del server · Non supportato · Elimina · Allegati';

  @override
  String get notesCurrentText => 'Testo attualmente conservato';

  @override
  String get notesRecovering => 'Recupero come nuova nota…';

  @override
  String get notesReadOnlyHelp =>
      'Sola lettura · Preferiti · Salva copia locale…';

  @override
  String get notesSort => 'Ordina note';

  @override
  String get notesPathRelative =>
      'Il percorso della cartella delle note è relativo al tuo spazio Nextcloud.';

  @override
  String get notesSettingsStale =>
      'Le impostazioni sono cambiate su Nextcloud. Ricarica e controlla i valori del server prima di sostituire la bozza.';

  @override
  String get notesDownloadsPaused => 'Download sospesi';

  @override
  String get notesExportNotPublished => 'Nessuna esportazione pubblicata.';

  @override
  String get notesKeyringUnavailable =>
      'Sblocca il portachiavi del desktop e riprova.';

  @override
  String get notesConnectFailed =>
      'Impossibile connettersi a Nextcloud Notes. Controlla l’indirizzo del server e riprova.';

  @override
  String get notesAccountMismatch =>
      'Accedi allo stesso account Nextcloud. Rimuovi prima questo account per collegarne un altro.';

  @override
  String get notesLocalRemovalFailed =>
      'La pulizia dell’account locale è fallita. L’account è conservato per riprovare la rimozione.';

  @override
  String get notesTransferring => 'Trasferimento delle note…';

  @override
  String get notesTechnicalDetails => 'Dettagli tecnici';

  @override
  String get notesPauseRequirement => 'Sospendi requisito offline';

  @override
  String get notesResumeRequirement => 'Riprendi requisito offline';

  @override
  String get gitReturnToDocument => 'Torna al documento';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Istantanea di sola lettura · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Il nome del file contiene byte non UTF-8. Revisione e staging Git restano disponibili; l’editor richiede un nome di file UTF-8.';

  @override
  String get gitUiMergeInProgress => 'Fondi in corso';

  @override
  String get gitUiRebaseInProgress => 'Ribase in corso';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick in corso';

  @override
  String get gitUiRevertInProgress => 'Inverti in corso';

  @override
  String get gitUiPatchApplicationInProgress => 'Applicazione patch in corso';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Risultato fusione squash in attesa di commit';

  @override
  String get gitUiUnresolvedIndexConflicts => 'Conflitti di indice non risolti';

  @override
  String get gitUiUnresolvedConflicts => ' · conflitti irrisolti';

  @override
  String get gitUiReviewOperation => 'Operazione di riesame';

  @override
  String get gitUiRefresh => 'Aggiorna';

  @override
  String get gitUiCreateNamedStash => 'Crea un nascondiglio con nome';

  @override
  String get gitUiCreateStash => 'Crea stash…';

  @override
  String get gitUiNoStashes => 'Nessun nascondiglio';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Selezionare un nascondiglio per controllare le modifiche';

  @override
  String get gitUiStashedUntrackedFiles => 'Nascosto file non tracciati';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Ispezionare i file non tracciati nascosti...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Reintegro dello stato dello stash in fase/indice in fase di applicazione';

  @override
  String get gitUiApplyAndRetain => 'Applicare e mantenere';

  @override
  String get gitUiPop => 'Papà...';

  @override
  String get gitUiCreateBranch => 'Crea ramo…';

  @override
  String get gitUiDropStash => 'Elimina stash…';

  @override
  String get gitUiBranchFromStash => 'Crea ramo dallo stash';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Crea/switch a un ramo alla base originale dello stash, quindi applicalo. Lo stash originale viene mantenuto per la cancellazione esplicita successiva.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 questa scorta?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'La riserva originale viene mantenuta in caso di applicazione di conflitti.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Elimina questa voce di recesso. Le sue modifiche non vengono applicate.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Risolvi i file non uniti. Git non offre comandi per continuare o interrompere uno stash; lo stash originale resta disponibile.';

  @override
  String get gitUiStashNameMessage => 'Nome/messaggio di recesso';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Contenuto di recesso e indice risultante';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash tracciati cambiamenti di lavoro e stage';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Metti in stash lasciando le modifiche preparate al loro posto (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Metti in stash solo le modifiche preparate (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Includi file non tracciati';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Tutti i percorsi idonei in questo archivio';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Nessuna modifica ammissibile per queste opzioni di riserva.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Selezionare almeno un percorso idoneo.';

  @override
  String get gitUiCreateStash2 => 'Crea stash';

  @override
  String get gitUiCreateWorktree => 'Crea albero di lavoro...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Crea un commit prima di creare un albero di lavoro su HEAD.';

  @override
  String get gitUiDetachedHEAD => 'HEAD scollegato';

  @override
  String get gitUiCurrent => 'Corrente ·';

  @override
  String get gitUiLocked => 'Bloccato ·';

  @override
  String get gitUiOpenInBusyStack => 'Aprire in BusyStack ·';

  @override
  String get gitUiStatusNotInspected => 'Stato non ispezionato';

  @override
  String get gitUiDirty => 'Sporco';

  @override
  String get gitUiClean => 'Pulito';

  @override
  String get gitUiOpenWorkingFolder => 'Apri cartella di lavoro';

  @override
  String get gitUiMoveWorktree => 'Sposta albero di lavoro...';

  @override
  String get gitUiUnlock => 'Sblocca';

  @override
  String get gitUiLock => 'Blocca';

  @override
  String get gitUiRemoveCleanWorktree => 'Rimuovi albero di lavoro pulito...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Rivedere la rimozione, comprese le modifiche locali...';

  @override
  String get gitUiNewWorktreeFolderName =>
      'Nuovo nome cartella albero di lavoro';

  @override
  String get gitUiNewWorktreeBranch => 'Nuovo ramo di albero di lavoro';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Creare $arg0/$arg1 con un nuovo ramo locale a $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Nome cartella destinazione';

  @override
  String get gitUiRemoveWorktree => 'Rimuovi l\'albero di lavoro?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Esplicitamente scartare tutti i cambiamenti locali tracciati/non tracciati in questo albero di lavoro. Gli alberi di lavoro bloccati/in uso rimangono protetti.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git rifiuta la rimozione se ci sono modifiche locali, file non tracciati, o un blocco.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Eliminare il contenuto dell\'albero di lavoro locale e rimuovere';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Rimuovi albero di lavoro pulito';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Ricorrere esplicitamente in sottomoduli annidati per aggiornamenti/sincronizzazioni';

  @override
  String get gitUiNoRecordedSubmodules => 'Nessun sottomodulo registrato';

  @override
  String get gitUiNotInitialized => 'non inizializzato';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Gitlink genitore: $arg0 Check out: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Repository sporchi nidificati';

  @override
  String get gitUiCleanNestedRepository => 'Pulisci il repository annidato';

  @override
  String get gitUiNestedStatusUnavailable => 'Stato negativo non disponibile';

  @override
  String get gitUiEnterNestedRepository => 'Inserisci repository annidato';

  @override
  String get gitUiInitializeConfiguration => 'Inizializza configurazione';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Aggiornamento ai commit registrati dai genitori...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Segui ramo remoto configurato...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Sincronizza gli URL configurati...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Puntatore stadio del sottomodulo attuale nella madre';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Genitore e submodule commette, spinge e lo stato sporco rimangono separati. La navigazione non li inizializza o li aggiorna.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Prendi e controlla il commit dei rami remoti configurati. Questo differisce dal gitlink registrato dai genitori. Recursive: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Inizializzare come necessario e controllare esattamente $arg0. Ricursivo: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Applica l\'operazione di configurazione del sottomodulo rivista. Ricursivo: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Applica operazione sottomodulo';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Ispezionare una revisione registrata o creare un ramo di recupero. Reflog non recupera contenuti arbitrari non salvati o non tracciati.';

  @override
  String get gitUiSelectAReflogEntry => 'Seleziona una voce reflog';

  @override
  String get gitUiPreviousPage => 'Pagina precedente';

  @override
  String get gitUiNextPage => 'Pagina successiva';

  @override
  String get gitUiRecoveryBranchName => 'Nome ramo di recupero';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Crea un ramo a $arg0; i file di lavoro e il ramo corrente sono immutati.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Crea ramo di recupero...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'Istantanea di recupero in sola lettura';

  @override
  String get gitUiInspectSnapshot => 'Ispeziona istantanea...';

  @override
  String get gitUiReviewReset => 'Recensione reset...';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Pagina $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Una cronologia di testo Git deve possedere il suo campo modificabile.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Modifica HEAD | Indice | Albero di lavoro…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'L\'indice rivisto o il contenuto di lavoro sono cambiati. Aggiornare questo confronto prima della messa in scena.';

  @override
  String get gitUiRefreshComparison => 'Aggiorna confronto';

  @override
  String get gitUiPreviousChangedFile => 'File precedente cambiato';

  @override
  String get gitUiNextChangedFile => 'File cambiato successivo';

  @override
  String get gitUiPreviousDifference => 'Differenza precedente';

  @override
  String get gitUiNextDifference => 'Differenza successiva';

  @override
  String get gitUiComparisonMode => 'Modalità confronto';

  @override
  String get gitUiSideBySide => 'Fianco a fianco';

  @override
  String get gitUiUnified => 'Unificato';

  @override
  String get gitUiDiffDisplayOptions => 'Opzioni di visualizzazione diff';

  @override
  String get gitUiWrap => 'Avvolgi';

  @override
  String get gitUiWords => 'Parole';

  @override
  String get gitUiCollapseContext => 'Contesto del collasso';

  @override
  String get gitUiIgnoreWhitespace => 'Ignora spazio bianco';

  @override
  String get gitUiSearchComparison => 'Confronto ricerca';

  @override
  String get gitUiSearch => 'Ricerca';

  @override
  String get gitUiCloseSearch => 'Chiudi ricerca';

  @override
  String get gitUiStagingActions => 'Azioni di standage';

  @override
  String get gitUiStagingActions2 => 'Stiamo mettendo in scena azioni...';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Rimuovi righe modificate selezionate dall\'indice';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Prepara righe modificate selezionate';

  @override
  String get gitUiUnstageWholeFile => 'Rimuovi intero file dall\'indice';

  @override
  String get gitUiStageWholeFile => 'Prepara intero file';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 linee modificate solo in spazi bianchi nascoste · Mostrare le modifiche esatte';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 ha cambiato le linee selezionate · Le impostazioni di visualizzazione non alterano mai i byte messi in scena.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Confronto in sola lettura · Copia testo o modifica la visualizzazione.';

  @override
  String get gitUiNoFinalNewline => ' · nessuna nuova linea finale';

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
      'Il confronto di testo non è disponibile per questi contenuti.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Questo confronto supera il limite di revisione del testo limitato. Il contenuto non è stato dichiarato identico.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'I contenuti confrontati sono identici.';

  @override
  String get gitUiUnstage => 'Smontaggio';

  @override
  String get gitUiStage => 'Fase';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 riga cambiata';
  }

  @override
  String get gitUiContext => 'Contesto';

  @override
  String get gitUiExpandUnchangedContext => 'Espandere il contesto invariato';

  @override
  String get gitUiUnstageThisHunk => 'Rimuovi questo blocco dall\'indice';

  @override
  String get gitUiStageThisHunk => 'Prepara questo blocco';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Modifica il contenuto in fase · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Scrittura risultato indice rivisto';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Indice';

  @override
  String get gitUiWorkingTree => 'Albero di lavoro';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob =>
      'Indice · Blob modificabile in UTF-8';

  @override
  String get gitUiUndo => 'Annulla';

  @override
  String get gitUiRedo => 'Ripeti';

  @override
  String get gitUiReloadIndexReview => 'Ricaricare la revisione dell\'indice?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Ricarica le versioni attuali di HEAD, dell’indice e di lavoro. Sostituisce la bozza non salvata dell’editor dell’indice.';

  @override
  String get gitUiReplaceDraftAndReload => 'Sostituisci bozza e ricarica';

  @override
  String get gitUiReloadVersions => 'Ricarica versioni...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Scrivi il risultato modificato a questa voce indice';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'I file di lavoro rimangono sul disco. Controllare l\'indice modificato prima di applicare.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Rivedere le modifiche del formato del testo dell\'indice';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Aggiorna solo la voce dell\'indice rivista per $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Scrivi il risultato dell\'indice rivisto';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Il risultato modificato è cambiato durante la revisione del formato.';

  @override
  String get gitUiSynchronizeScrolling => 'Sincronizza scorrimento';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'Contenuto di revisione in sola lettura';

  @override
  String get gitUiEditableIndexContent => 'Indice modificabile';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'La revisione richiesta è al di fuori dei filtri attuali. Reimposta i filtri per rivelarla.';

  @override
  String get gitUiFilterLog => 'Registro filtro';

  @override
  String get gitUiFilters => 'Filtri...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtri ($count)...';
  }

  @override
  String get gitUiMessage => 'Messaggio…';

  @override
  String get gitUiAuthor => 'Autore…';

  @override
  String get gitUiPath => 'Percorso...';

  @override
  String get gitUiDate => 'Data...';

  @override
  String get gitUiMessageFilter => 'Filtro messaggio';

  @override
  String get gitUiAuthorFilter => 'Filtro autore';

  @override
  String get gitUiPathFilter => 'Filtro tracciato';

  @override
  String get gitUiMessage2 => 'Messaggio';

  @override
  String get gitUiAuthor2 => 'Autore';

  @override
  String get gitUiPath2 => 'Percorso';

  @override
  String get gitUiDateFilter => 'Filtro data...';

  @override
  String get gitUiResetFilters => 'Reimposta i filtri';

  @override
  String get gitUiRefreshLog => 'Aggiorna registro';

  @override
  String get gitUiGoToCommitReference => 'Vai al commit/reference...';

  @override
  String get gitUiBackToHEAD => 'Torna a HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Ordinato ciliegia-pick';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Recensione ciliegia-pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Confronta due revisioni selezionate...';

  @override
  String get gitUiToggleBranchesPane => 'Commuta riquadro rami';

  @override
  String get gitUiFilterBranchesAndTags => 'Filtra i rami e le etichette';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Commit $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Commit dettagli...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Riferimento: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Seleziona questo commit';

  @override
  String get gitUiBranchOrTag => 'Ramo o etichetta';

  @override
  String get gitUiAllReferences => 'Tutte le referenze';

  @override
  String get gitUiLocal => 'Locale';

  @override
  String get gitUiRemote => 'Remoto';

  @override
  String get gitUiTags => 'Tag';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Nessun commit corrisponde ai filtri attuali.';

  @override
  String get gitUiObjectID => 'ID oggetto';

  @override
  String get gitUiSubjectReferences => 'Oggetto/riferimento';

  @override
  String get gitUiDate2 => 'Data';

  @override
  String get gitUiGitCommits => 'Commit Git';

  @override
  String get gitUiParents => 'Commit genitori';

  @override
  String gitUiArg0Parents(String arg0) {
    return 'Genitori $arg0';
  }

  @override
  String get gitUiLoadMoreCommits => 'Carica più commit';

  @override
  String get gitUiLoadingChangedFiles => 'Caricamento dei file modificati';

  @override
  String get gitUiNoChangedFiles => 'Nessun file modificato';

  @override
  String get gitUiSelectACommit => 'Seleziona un commit';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Confronta genitore $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'File modificati';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autore: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Committer: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Border poco profondo/parziale: un oggetto genitore non è disponibile.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Il genitore è fuori da questa pagina o da un confine poco profondo.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit genitore $arg0';
  }

  @override
  String get gitUiCommitActions => 'Commit azioni...';

  @override
  String get gitUiEmptyTree => 'albero vuoto';

  @override
  String get gitUiCreateBranch2 => 'Crea ramo';

  @override
  String get gitUiCreateTag => 'Crea tag';

  @override
  String get gitUiCompareRevisions => 'Confronta le revisioni';

  @override
  String get gitUiOpenSnapshot => 'Apri istantanea';

  @override
  String get gitUiRevertCommit => 'Inverti commit';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Ribase interattiva dopo questo confine';

  @override
  String get gitUiResetCurrentBranch => 'Reimposta ramo corrente';

  @override
  String get gitUiCopyFullObjectID => 'Copia l\'ID dell\'oggetto completo';

  @override
  String get gitUiGoToCommitReference2 => 'Vai al commit/reference';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Inserisci un ID di commit o un riferimento per rivelare in Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'La revisione richiesta non è disponibile.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'I metadati dei repository sono in sola lettura. L\'ispezione e il confronto dei rami rimangono disponibili.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'I file di lavoro non sono disponibili o in sola lettura. Switching e fusione del ramo non sono disponibili.';

  @override
  String get gitUiSearchBranchesAndTags => 'Cerca rami e tag';

  @override
  String get gitUiNewBranch => 'Nuovo ramo…';

  @override
  String get gitUiLocalBranches => 'Rami locali';

  @override
  String get gitUiRemoteBranches => 'Rami remoti';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Tracce $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Check out a $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata => 'Aggiornare i metadati del ramo';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Passa a $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Albero di lavoro occupato aperto';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Crea ramo di tracciamento locale...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Confronta con HEAD corrente';

  @override
  String get gitUiMergeIntoCurrentBranch => 'Unisce nel ramo corrente...';

  @override
  String get gitUiRename => 'Rinomina...';

  @override
  String get gitUiChangeUpstream => 'Cambia a monte...';

  @override
  String get gitUiDelete => 'Elimina...';

  @override
  String get gitUiDeleteFromRemote => 'Elimina dal remoto...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Azioni per $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Nome ramo locale';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Crea su $arg0. Il nuovo ramo verrà controllato.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Il ramo locale rintraccerà $arg0 e verrà controllato.';
  }

  @override
  String get gitUiChooseRemoteForDeletion =>
      'Scegliere il remoto per la cancellazione';

  @override
  String get gitUiDeleteRemoteReference => 'Elimina riferimento remoto';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Unisce $arg0 in $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Rinomina $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'A monte per $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Nessun upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Eliminare $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Solo cancellazione locale. Un ramo non collegato viene rifiutato.';
  }

  @override
  String get gitUiDelete2 => 'Elimina';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Eliminare il ramo $arg0 non collegato?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git segnala che questo ramo non è completamente unito. Elimina esplicitamente il riferimento locale dopo aver rivisto i commit; le copie remote sono immutate.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch =>
      'Elimina il ramo locale non fusa';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Destinazione: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Ramo sorgente o etichetta';

  @override
  String get gitUiMergePolicy => 'Unisci politica';

  @override
  String get gitUiFastForwardWhenPossible => 'Avanti veloce quando possibile';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Crea sempre un commit di fusione';

  @override
  String get gitUiFastForwardOnly => 'Solo avanti veloce';

  @override
  String get gitUiSquashIntoStagedChanges => 'Squash in cambiamenti in fase';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Ferma prima di creare il commit di fusione';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'L’avanzamento rapido è disabilitato affinché HEAD non si sposti prima della revisione.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Lascia i cambiamenti messi in scena per un commit separato; questa non è una fusione continua.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'I conflitti rimangono disponibili nello spazio di lavoro per la risoluzione condivisa.';

  @override
  String get gitUiAddRemote => 'Aggiungi telecomando...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Ricevi: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Rimuovi il telecomando...';

  @override
  String get gitUiChangeFetchURL => 'Cambia URL presa...';

  @override
  String get gitUiAddPushDestination => 'Aggiungi destinazione push...';

  @override
  String get gitUiRemovePushDestination => 'Rimuovi destinazione push...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Gestisci $arg0';
  }

  @override
  String get gitUiRemoteName => 'Nome remoto';

  @override
  String get gitUiNewRemoteName => 'Nuovo nome remoto';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'URL di deposito o sorgente locale';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Inserisci la destinazione esatta da rimuovere.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'I poteri sono forniti da helper configurati o da un prompt privato.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Rimuovere $arg0 remoto?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Rimuove i riferimenti locali di configurazione remota e di tracciamento. Non elimina il repository del server.';

  @override
  String get gitUiRemoveRemote2 => 'Rimuovi remoto';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Scope di commit: intero repository';

  @override
  String get gitUiCachedTracking => 'Tracciamento cache';

  @override
  String get gitUiAmendLastCommit => 'Modifica ultimo commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'I ganci configurati e la firma sono rispettati.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Riscrive il commit HEAD selezionato. Il tracciamento remoto non dimostra che non sia stato pubblicato.';

  @override
  String get gitUiRepository => 'Repository';

  @override
  String gitUiDetachedArg0(String arg0) {
    return '$arg0 staccato';
  }

  @override
  String get gitUiLog => 'Cronologia';

  @override
  String get gitUiRepositoryActions => 'Azioni del repository';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Tracciamento in cache · $upstream · $ahead avanti · $behind indietro';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Repository nudo · nessun albero di lavoro. Aprire Log per controllare la sua cronologia.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Repository in sola lettura · messa in scena e commit non sono disponibili.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Stato del deposito non disponibile';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Modifica $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Aggiungi riga di approvazione';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Usa la politica di firma configurata';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Firma criptograficamente questo commit';

  @override
  String get gitUiDoNotSignThisCommit => 'Non firmare questo commit';

  @override
  String get gitUiRecentCommitMessages => 'Messaggi di commit recenti...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Usa il modello di commit configurato...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Identità dell\'autore e ganci configurati...';

  @override
  String get gitUiDraftMessage => 'Messaggio di bozza...';

  @override
  String get gitUiCommitOptions => 'Opzioni commit';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Draft mantenuto in memoria; salvataggio non riuscito. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Messaggio di commit';

  @override
  String get gitUiGitOperationInProgress => 'Operazione Git in corso';

  @override
  String get gitUiCancel => 'Annulla';

  @override
  String get gitUiAmendStaged => 'Modificare gradualmente';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Commit staged ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit e push…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Nessun modello di commit leggibile è configurato.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Commit identità e ganci';

  @override
  String get gitUiRecentMessages => 'Messaggi recenti';

  @override
  String get gitUiReplaceMessageDraft => 'Sostituisci la bozza del messaggio?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Sostituire il messaggio di commit esistente con il messaggio selezionato?';

  @override
  String get gitUiReplaceDraft => 'Sostituisci progetto';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Il commit locale $arg0 esiste.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Il commit locale $arg0 esiste. Recensione Log prima di tentare un altro commit. La bozza del messaggio è stata mantenuta.';
  }

  @override
  String get gitUiCommitAuthorName => 'Nome dell\' autore del commit';

  @override
  String get gitUiCommitAuthorEmail => 'Commit email dell\' autore';

  @override
  String get gitUiConfiguredDefault => 'predefinito configurato';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Firma: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'ganci configurati: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'La riga di approvazione è una dichiarazione nel messaggio, distinta da una firma crittografica. L’identità viene salvata solo nella configurazione locale del repository; la bozza viene mantenuta.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Salva identità del repository';

  @override
  String get gitUiStaged => 'Preparati';

  @override
  String get gitUiUntracked => 'Non tracciati';

  @override
  String get gitUiUnstaged => 'Non preparati';

  @override
  String get gitUiConflicts => 'Conflitti';

  @override
  String get gitUiNoChanges => 'Nessuna modifica';

  @override
  String get gitUiRepositoryChangeTree => 'Albero di cambiamento del deposito';

  @override
  String get gitUiChanges => 'Modifiche';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Espandi';

  @override
  String get gitUiCollapse => 'Collasso';

  @override
  String get gitUiUnstageFile => 'Rimuovi file dall\'indice';

  @override
  String get gitUiStageFile => 'Prepara file';

  @override
  String get gitUiExpandGroup => 'Espandi gruppo';

  @override
  String get gitUiCollapseGroup => 'Gruppo collasso';

  @override
  String get gitUiReviewDifference => 'Differenza di riesame';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Rimuovi file selezionati dall\'indice';

  @override
  String get gitUiStageSelectedFiles => 'Prepara file selezionati';

  @override
  String get gitUiFileHistoryAndBlame => 'Cronologia file e colpa...';

  @override
  String get gitUiDeleteUntrackedFile => 'Elimina il file non tracciato...';

  @override
  String get gitUiDiscardUnstagedChange =>
      'Eliminare il cambiamento non inscenato...';

  @override
  String get gitUiFileHistory => 'Cronologia del file';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Eliminare $arg0 non inscenato?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bytes · $arg1 Sostituisce il contenuto di lavoro con l\'indice, o elimina questo file non tracciato. Il contenuto in fase di conservazione. I documenti host non salvati devono essere esaminati prima.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Elimina file non tracciato';

  @override
  String get gitUiDiscardWorkingChange => 'Eliminare il cambiamento di lavoro';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Cancellare il riferimento REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Questo rimuove il riferimento su ogni destinazione push reale elencati di seguito. I rami/tag locali vengono mantenuti. I suggerimenti previsti sono fissati da questa recensione.';

  @override
  String get gitUiReferenceDoesNotExist => 'il riferimento non esiste';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Consiglio previsto: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Cancellazione remota completata.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Eliminare $arg0 dal telecomando?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Le punte esatte di destinazione mostrate sopra saranno rimosse. Qualsiasi punta remota modificata interrompe l\'operazione per un\'altra revisione.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Recensione ed eliminazione da remoto...';

  @override
  String get gitUiDestinationReference => 'Riferimento della destinazione';

  @override
  String get gitUiReviewDestinations => 'Riesame delle destinazioni';

  @override
  String get gitUiNewRemoteBranch => 'nuovo ramo remoto';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · atteso: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Una destinazione ha commit che non sono disponibili localmente. Ricevi quella destinazione rivista prima di rivedere la cronologia in uscita.';

  @override
  String get gitUiFetchReviewedDestination => 'Ricevi destinazione rivista';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Scegliere una destinazione e rivedere i commit in uscita.';

  @override
  String get gitUiNoOutgoingCommits => 'Nessun commit in uscita';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Seleziona un commit in uscita';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Carica più commit in uscita';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Imposta questa destinazione come upstream';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Scegliere tag esatti da pubblicare';

  @override
  String get gitUiTagsNone => 'Tag: nessuno';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Tags: $arg0 selezionati';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Pubblicare esattamente: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Spingere completato. Il commit locale rimane disponibile in Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Il push forzato richiede esattamente le revisioni di destinazione mostrate in questa verifica.';

  @override
  String get gitUiForceWithReviewedLease =>
      'Forza con contratto di locazione rivisto...';

  @override
  String get gitUiPush => 'Push';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Forza di spinta con contratti di locazione rivisti?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Riscrivi $arg0 solo se ogni destinazione remota ha ancora la punta esatta mostrata sopra.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Altre persone potrebbero già usare questa cronologia. Un recupero in background non rinnova questa condizione di sicurezza.';

  @override
  String get gitUiForceWithLease => 'Forza con contratto di locazione';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Il risultato remoto è incerto. Ricontrollare le destinazioni prima di un\'altra spinta.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Genitore $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Remoto da recuperare';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune ha eliminato le filiali remota-tracking';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Ricevi aggiornamenti remoto-tracking informazioni senza sostituire i file di lavoro.';

  @override
  String get gitUiFetch => 'Recupera';

  @override
  String get gitUiSourceRemote => 'Sorgente remota';

  @override
  String get gitUiSourceBranch => 'Filiale sorgente';

  @override
  String get gitUiReviewedStrategy => 'Strategia riesaminata';

  @override
  String get gitUiMerge => 'Unisci';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Interrompere se la destinazione non può andare avanti velocemente; mai unire o ribase.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Unire con un commit di fusione, anche quando è possibile fare avanti veloce.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Unire; permettere di avanzare velocemente quando possibile.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Rifondare la cronologia locale mantenendo la fusione locale commit.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Rebase commit locali come cronologia lineare.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git è configurato per la ribase interattiva. Selezionare una strategia di prelievo qui esplicitamente, o recuperare e aprire Rebase... per rivedere un piano.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Utilizzare rebase ordinario recensito per questo tiro';

  @override
  String get gitUiOptions => 'Opzioni';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Crea sempre un commit di fusione (nessun fast-forward)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Preserva commit di fusione locale';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Le modifiche locali possono impedire l\'estrazione. Recensirle/comandarle o creare esplicitamente una riserva.';

  @override
  String get gitUiStashes => 'Stash';

  @override
  String get gitUiCreateOrReviewStash => 'Crea o recensisci nascondi...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Tirare con la strategia selezionata';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'URL di deposito o sorgente Git locale';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'Percorso HTTPS, SSH o locale';

  @override
  String get gitUiFolderToInitialize => 'Cartella da inizializzare';

  @override
  String get gitUiFinalCloneDestination => 'Destinazione finale del clone';

  @override
  String get gitUiChoose => 'Scegli...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Crea solo metadati Git. I file esistenti non sono messi in scena o impegnati.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'La destinazione finale deve essere assente o vuota. I dati esistenti dell’utente non vengono mai sovrascritti.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Branch iniziale · blank utilizza una politica Git efficace';

  @override
  String get gitUiSelectedBranchOptional => 'Branch selezionato · opzionale';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Esplicitamente inizializza/aggiorna i sottomoduli ricorsivamente';

  @override
  String get gitUiPreparingGitOperation => 'Preparazione operazione Git...';

  @override
  String get gitUiThisAttemptCreated => 'Questo tentativo creato';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'La destinazione esisteva prima di questo tentativo:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'La directory rimane da controllare. Rivedila prima di un altro tentativo di clone.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Non rimane nessuna directory di destinazione.';

  @override
  String get gitUiCancelProcess => 'Annulla processo';

  @override
  String get gitUiInitialize => 'Inizializza';

  @override
  String get gitUiClone => 'Clona';

  @override
  String get gitUiChooseNewBase => 'Scegli nuova base';

  @override
  String get gitUiChooseUpstreamBoundary => 'Scegli limite upstream';

  @override
  String get gitUiNewBase => 'Nuova base';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Limite upstream · escluso';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Come il limite upstream';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Scegli ramo, tag o commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Utilizzare a monte come nuova base';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Scegliere un ramo valido, un tag o un commit da Log.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Il primo commit mantenuto in un blocco di ramo non può usare squash o fixup: manca un commit precedente di destinazione.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Blocco ramo $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[La parola richiede un nuovo messaggio]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Messaggi di commit pianificati';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Anteprima del messaggio originale/combinato · Git richiede il reword finale/squash';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Risultato $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Ramo corrente: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'HEAD scollegato';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Il rebase riscrive le identità dei commit. I riferimenti remoti non dimostrano che la cronologia non sia mai stata pubblicata.';

  @override
  String get gitUiIncludeRootCommits => 'Includi commit radice';

  @override
  String get gitUiMergeCommits => 'Fondi commit';

  @override
  String get gitUiFlattenHistory => 'Appiattisci cronologia';

  @override
  String get gitUiPreserveBranchStructure => 'Mantieni struttura dei rami';

  @override
  String get gitUiAutosquash => 'Accorpamento automatico';

  @override
  String get gitUiPrepareGitPlan => 'Prepara piano Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commits to replay: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Include tutti i commit root raggiungibili da questo ramo.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'I commit successivi a $boundary verranno riapplicati su $base; il commit limite è escluso.';
  }

  @override
  String get gitUiRoot => 'Radice';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Struttura Git branch/label/reset/merge';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Scegliere un limite o una modalità radice esplicita, quindi preparare il piano.';

  @override
  String get gitUiMoveUp => 'Sposta su';

  @override
  String get gitUiMoveDown => 'Sposta giù';

  @override
  String get gitUiResetPlan => 'Ripristina piano';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · blocco ramo $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Selezionare un commit per i dettagli e modificare i file';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Anteprima messaggi di commit combinati...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ sposta il commit selezionato. I riferimenti al ramo non correlati non saranno aggiornati automaticamente.';

  @override
  String get gitUiCancelPlan => 'Annulla piano';

  @override
  String get gitUiStartReviewedRebase => 'Iniziare a rivedere la base?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Riscrivi i commit $arg0 pianificati su $arg1. I commit dropped rimangono visibilmente segnati in questo piano fino all\'inizio.';
  }

  @override
  String get gitUiStartRebase => 'Avvia rebase';

  @override
  String get gitUiNoContinuingGitOperation => 'Nessuna operazione Git continua';

  @override
  String get gitUiStoppedForEditingAmend =>
      ' · fermato per la modifica/modifica';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Queste sono voci indici non incorporate, possibilmente da un\'applicazione stash. Git non ha alcun comando stash continue o abortire.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Modificare i file di lavoro, stadio e modificare il commit corrente, quindi continuare questa ribase.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · stadi dell’indice non uniti $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'L\'indice non ha voci irrisolte.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Mantieni il commit corrente come un commit vuoto';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'L\'indice reale non ha cambiamenti in fase. Crea un commit vuoto esplicito, quindi continua il sequencer se rimane attivo.';

  @override
  String get gitUiKeepEmptyCommit => 'Mantieni il commit vuoto...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git tenterà di tornare al punto iniziale dell’operazione. Il recupero dei contenuti preesistenti non preparati, non tracciati o non salvati non è garantito.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Salta il commit corrente e continua con il prossimo commit pianificato.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Dimenticate questa operazione, mantenendo i file e l\'indice attuali.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Continua $arg0';
  }

  @override
  String get gitUiReloadConflictVersions =>
      'Ricaricare le versioni di conflitto?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Sostituire il draft dei risultati non salvati con il file di lavoro corrente. Il contenuto di lavoro salvato viene mantenuto.';

  @override
  String get gitUiLoadingConflictVersions =>
      'Caricamento delle versioni di conflitto...';

  @override
  String get gitUiLoadingConflict => 'Caricamento conflitto';

  @override
  String get gitUiBaseLeft => 'Base → sinistra';

  @override
  String get gitUiBaseRight => 'Base → destra';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Nessun elemento di base per questo conflitto';

  @override
  String get gitUiAcceptEntireLeftFile => 'Accetta tutto il file sinistro...';

  @override
  String get gitUiAcceptEntireRightFile => 'Accetta tutto il file giusto...';

  @override
  String get gitUiPreviousConflictRegion => 'Regione di conflitto precedente';

  @override
  String get gitUiNextConflictRegion => 'Prossima regione di conflitto';

  @override
  String get gitUiManualResolution => 'Risoluzione manuale';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Regione $arg0/$arg1 · $arg2 recensito';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'L\'allineamento sorgente ha superato il limite di comparazione del testo; i pannelli sorgente rimangono disponibili per la revisione manuale.';

  @override
  String get gitUiAcceptLeftRegion => 'Accetta la regione di sinistra';

  @override
  String get gitUiAcceptRightRegion => 'Accetta la regione di destra';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Mantieni il risultato manuale per la regione';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Applicare i cambiamenti non conflittuali dei Git-Solutions?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Sostituisci il progetto di risultato corrente con l\'anteprima di fusione di Git-Monete. Questo scarta le modifiche dei risultati manuali non salvate; il file di lavoro rimane invariato fino a Save.';

  @override
  String get gitUiUseMergePreview => 'Usa anteprima della fusione';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Applica modifiche non conflittuali...';

  @override
  String get gitUiLeftSource => 'Sorgente sinistra';

  @override
  String get gitUiResult => 'Risultato';

  @override
  String get gitUiRightSource => 'Sorgente destra';

  @override
  String get gitUiStage2 => 'Fase 2';

  @override
  String get gitUiStage3 => 'Fase 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Le versioni di conflitto non sono disponibili. Aggiorna per rivedere il loro stato attuale.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Risultato salvato su disco. L\'indice determina ancora se questo file è risolto.';

  @override
  String get gitUiSaveResultDraft => 'Salva bozza del risultato';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Applica risultato e prepara risoluzione';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Risultato · contenuto di lavoro modificabile in UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Risultato conflitto modificabile';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Sinistra: $arg0 · $arg1\nDestra: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Scegliere il contenuto, la cancellazione, o un commit submodule esplicitamente. Nessun dato binario viene decodificato come testo modificabile.';

  @override
  String get gitUiUseEntireLeftContent => 'Usa tutto il contenuto sinistro...';

  @override
  String get gitUiUseEntireRightContent => 'Usa tutto il contenuto giusto...';

  @override
  String get gitUiDeleteThisPath => 'Elimina questo percorso...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Commit submodule risolto';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Mettere in scena questo esatto gitlink nel genitore. Questo non controlla o commette il modulo.';

  @override
  String get gitUiSetResolvedGitlink => 'Imposta gitlink risolto...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Base → stadio $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Il risultato è stato modificato. Mantenere il risultato manuale o selezionare un\'altra regione invariata.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Applicare la risoluzione «$arg0»?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Mettere in scena il commit gitlink scelto nel genitore. Il modulo checkout e i suoi file non vengono sostituiti.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Sostituisce l\'intero percorso di lavoro $arg0 e mette in scena la decisione. I contenuti di lavoro attuali e qualsiasi bozza di risultato non salvata saranno scartati.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Applica l\'intera decisione del file';

  @override
  String get gitUiStageThisConflictResolution =>
      'Mettere in scena questa risoluzione dei conflitti?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Usa l\'intero risultato modificato come $arg0. Git registra il percorso risolto quando è in scena. Recensisci prima tutti i contenuti previsti.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Applica e prepara';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Rivedere le modifiche del formato del testo del risultato';

  @override
  String get gitUiSaveReviewedResult => 'Salva il risultato rivisto';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'L\'accessibilità della tabella Native Git non è disponibile. Riprovare dopo aver ricollegato l\'applicazione.';

  @override
  String get gitUiSans =>
      'SansCity name (optional, probably does not need a translation)';

  @override
  String get gitUiSelect => 'Seleziona';

  @override
  String get gitUiContextMenu => 'Menu contestuale';

  @override
  String get gitUiCopyText => 'Copia testo';

  @override
  String get gitUiLoadingRow => 'Caricamento riga';

  @override
  String get gitUiRetry => 'Riprova';

  @override
  String get gitUiGitMessage => 'Messaggio Git';

  @override
  String get gitUiCancelPrompt => 'Annulla prompt';

  @override
  String get gitUiUseMessageAndContinue => 'Usa messaggio e continua';

  @override
  String get gitUiRespondPrivately => 'Rispondi in privato';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Impossibile salvare le preferenze di visualizzazione: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Commit draft storage: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Impossibile leggere le preferenze di visualizzazione: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Il progetto di commit è stato mantenuto in memoria ma non è stato possibile salvarlo: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Il repository recensito è in sola lettura per questa operazione. La cronologia e l\'ispezione dei contenuti rimangono disponibili.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git ha restituito $arg0. L\'applicazione non ha potuto aggiornare i suoi documenti: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Seleziona commit nella cronologia…';

  @override
  String get gitUiCurrentBranch => 'Ramo corrente';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Nessun ramo o tag corrispondenti. Selezionare un commit in Log.';

  @override
  String get gitUiBranches => 'Rami';

  @override
  String get gitUiPushCommits => 'Invia commit';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Tirare in $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Risolvi $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Funzionamento corrente';

  @override
  String get gitUiRebaseCommits => 'Rebase dei commit';

  @override
  String get gitUiFetch2 => 'Recupera…';

  @override
  String get gitUiPull => 'Pull…';

  @override
  String get gitUiPush2 => 'Push…';

  @override
  String get gitUiBranches2 => 'Rami…';

  @override
  String get gitUiManageRemotes => 'Gestisci remoti…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Unisce in $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Conflitti e operazioni correnti...';

  @override
  String get gitUiStashes2 => 'Stash…';

  @override
  String get gitUiWorktrees => 'Alberi di lavoro…';

  @override
  String get gitUiSubmodules => 'Sottomoduli…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog e recupero…';

  @override
  String get gitUiCloneRepository => 'Clona repository…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Fiducia del repository di Revoke';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'In attesa dello stato del repository';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Stato del deposito non disponibile; aggiornamento';

  @override
  String get gitUiManageRemotes2 => 'Gestisci remoti';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Unisce in $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Alberi di lavoro';

  @override
  String get gitUiSubmodules2 => 'Sottomoduli';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog e recupero';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Repository clone · $arg0';
  }

  @override
  String get gitUiApply => 'Applica';

  @override
  String get gitUiResizeGitPanes => 'Ridimensiona i riquadri Git';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 percentuale';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Stato di uscita: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Il repository è cambiato. Aggiornare e rivedere prima di riprovare.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Un\'altra operazione tiene il repository o il blocco dell\'indice. Aspetta, poi aggiorna.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Per questa operazione è necessaria la fiducia nei depositi.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Il servizio Git disconnesso. Riconnetti e riconcilia il repository.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'L\' eseguibile Git installato non può supportare questa operazione. Rivedere i requisiti di runtime qui sotto.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Questo repository è in sola lettura per l\'operazione richiesta. Recensione e cronologia rimangono disponibili.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'L\'operazione ha bisogno di riconciliazione. Controllare il repository o lo stato remoto risultante prima di ripeterlo.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Autenticazione Git non riuscita. Controllare l\'helper credenziale o sbloccare il portachiavi configurato.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Verifica dell\'host SSH non riuscita. Controllare l\'identità dell\'host attraverso gli strumenti SSH configurati.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Compilare la firma non riuscita o annullata. Rivedere la chiave di firma, l\'agente e lo strumento di firma configurato.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Impostare un nome e un\'email dell\'autore del repository, quindi tornare alla bozza di messaggio conservata.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git ha rifiutato l\'aggiornamento rivisto. Aggiornare e rivedere la destinazione reale prima di riprovare.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Le modifiche in atto o in fase di elaborazione impediscono questa operazione. Rivedere, effettuare il commit o nasconderle esplicitamente.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Un oggetto Git richiesto non è disponibile. Rivedere i confini superficiali o parziali e recuperare esplicitamente se necessario.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Operazione Git non riuscita: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnostica';

  @override
  String get gitUiAuthorizeGitInspection => 'Autorizzare l\'ispezione Git...';

  @override
  String get gitUiCopyDiagnostics => 'Copia diagnostica';

  @override
  String get gitUiActions => 'Azioni';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Ramo a $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Crea un ramo locale senza controllarlo.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Etichetta $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Istantanea in sola lettura · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Commit di pesca delle ciliege';

  @override
  String get gitUiRevertCommits => 'Inverti commit';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Confronta con l\'ID di revisione completa';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Direzione confronto albero: $arg0 → la revisione è stata inserita qui.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Inserisci un ID completo dell\'oggetto valido.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · confronto tra alberi';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Reimposta $arg0 a $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Sposta HEAD/il ramo corrente. Il reflog non recupera contenuti arbitrari non tracciati o non salvati.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Sposta HEAD; mantieni indice e file di lavoro.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Sposta HEAD e sostituisci l’indice; mantieni i file di lavoro.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Sostituisci HEAD, indice e file tracciati; i file non tracciati che ostacolano l’operazione potrebbero essere sovrascritti.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Sostituisci HEAD, indice e file idonei; rifiuta se verrebbero perse modifiche locali.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Reimpostare con $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Prima di applicare, ripassare la modalità selezionata.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Reimposta $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Obiettivo $arg0';
  }

  @override
  String get gitUiTagName => 'Nome tag';

  @override
  String get gitUiAnnotatedTag => 'Tag annotato';

  @override
  String get gitUiCryptographicSigning => 'Firma crittografica';

  @override
  String get gitUiConfiguredPolicy => 'Politica configurata';

  @override
  String get gitUiSignThisTag => 'Firma questa etichetta';

  @override
  String get gitUiDoNotSign => 'Non firmare';

  @override
  String get gitUiTagMessage => 'Messaggio etichetta';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Crea il tag localmente. Pubblica esplicitamente i tag selezionati nella recensione Push.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Alberi completi: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage =>
      'Pagina successiva del file modificato';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Istantanea di repository in sola lettura. L\'apertura di un file non verifica mai questa revisione.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Apri la versione di sola lettura';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Ripristina questo percorso... · In attesa dello stato del repository';

  @override
  String get gitUiRestoreThisPath => 'Ripristinare questo percorso...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Storia · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Ripristinare $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Sostituisci questo percorso di lavoro con la revisione $arg0. I contenuti stage esistenti vengono mantenuti.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Ripristina file di lavoro';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'La cronologia dei file segue rinominazioni · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Annotazioni · contenuto del commit';

  @override
  String get gitUiBlame => 'Annotazioni…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Albero di lavoro';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Apri file storico in sola lettura';

  @override
  String get gitUiCompareToCurrentFile => 'Confronta con il file corrente';

  @override
  String get gitUiCompareToParent => 'Confronta con i genitori...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Committed $arg0 · Il contenuto dell\'editor non salvato non fa parte di queste annotazioni';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Cronologia da $arg0';
  }

  @override
  String get gitUiBoundary => ' · confine';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nRiga originale $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Righe precedenti';

  @override
  String get gitUiNextLines => 'Righe successive';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Ordine di applicazione esplicito · destinazione $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID =>
      'Aggiungi l\'ID dell\'oggetto di commit completo';

  @override
  String get gitUiAddReviewedCommit => 'Aggiungi commit recensito...';

  @override
  String get gitUiMoveEarlier => 'Sposta prima';

  @override
  String get gitUiMoveLater => 'Sposta dopo';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Rimuovi dalla sequenza rivista';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Applica modifiche senza creare commit';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Utilizzare questo genitore mainline esplicito per i commit di fusione';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'I commit vuoti o già applicati possono fermare Git per una decisione esplicita di salto o continuazione.';

  @override
  String get gitUiRevertInReviewedOrder => 'Inverti in ordine rivisto';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Cherry-pick in ordine recensito';

  @override
  String get gitUiReturnToFiles => 'Ritorna ai file';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Commit';

  @override
  String get gitUiBackToCommit => 'Torna al commit';

  @override
  String get gitUiSelectAChangeToReview => 'Seleziona una modifica da rivedere';

  @override
  String get gitUiLoadingBranch => 'Caricamento ramo...';

  @override
  String get gitUiBranchUnavailable => 'Ramo non disponibile';

  @override
  String get gitUiUnbornHEAD => 'HEAD senza commit';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'HEAD scollegato · $revision';
  }

  @override
  String get gitUiContinueAction => 'Continua';

  @override
  String get gitUiPick => 'Mantieni';

  @override
  String get gitUiReword => 'Modifica messaggio';

  @override
  String get gitUiEdit => 'Modifica';

  @override
  String get gitUiSquash => 'Accorpa';

  @override
  String get gitUiFixup => 'Accorpa senza messaggio';

  @override
  String get gitUiDrop => 'Escludi';

  @override
  String get gitUiAbort => 'Interrompi';

  @override
  String get gitUiSkip => 'Salta';

  @override
  String get gitUiQuit => 'Esci dall\'operazione';

  @override
  String get gitUiSoft => 'Soft';

  @override
  String get gitUiMixed => 'Mixed';

  @override
  String get gitUiHard => 'Hard';

  @override
  String get gitUiKeep => 'Keep';

  @override
  String get gitUiCreate => 'Crea';

  @override
  String get gitUiApplyStash => 'Applica stash';

  @override
  String get gitUiPopStash => 'Applica stash e rimuovilo se riesce';

  @override
  String get gitUiDropStashAction => 'Elimina stash';

  @override
  String get gitUiEditedResult => 'Risultato modificato';

  @override
  String get gitUiLeftContent => 'Contenuto sinistro';

  @override
  String get gitUiRightContent => 'Contenuto corretto';

  @override
  String get gitUiDeletePath => 'Elimina tracciato';

  @override
  String get gitUiSubmoduleCommit => 'Commit submodulo';

  @override
  String get gitUiPresentContent => 'Contenuto disponibile';

  @override
  String get gitUiAbsentContent => 'Assente';

  @override
  String get gitUiBinaryContent => 'Contenuto binario';

  @override
  String get gitUiTooLargeContent =>
      'Il contenuto supera il limite di visualizzazione';

  @override
  String get gitUiUnavailableContent => 'Contenuto non disponibile';

  @override
  String get gitUiGitlinkContent => 'Puntatore submodulo';

  @override
  String get gitUiSymlinkContent => 'Collegamento simbolico';

  @override
  String get gitUiNoOperation => 'Nessuna operazione';

  @override
  String get gitUiCherryPickOperation => 'Cherry-pick';

  @override
  String get gitUiRevertOperation => 'Annulla con commit';

  @override
  String get gitUiApplyMailboxOperation => 'Applica patch';

  @override
  String get gitUiSquashOperation => 'Fusione squash';

  @override
  String get gitUiUnmergedOperation => 'Indice non generato';

  @override
  String get gitUiWaitingForPromptPhase => 'Aspettando la tua risposta';

  @override
  String get gitUiStoppedPhase => 'Fermato per la revisione';

  @override
  String get gitUiCompletedPhase => 'Completato';

  @override
  String get gitUiFailedPhase => 'Non riuscito';

  @override
  String get gitUiCancelledPhase => 'Annullato';

  @override
  String get gitUiUncertainPhase => 'Il risultato richiede riconciliazione';

  @override
  String gitUiStageVersion(String stage) {
    return 'Fase di conflitto $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Anteprima fusione Git';

  @override
  String get gitUiNormalizedWorking => 'Albero di lavoro · Git normalizzato';

  @override
  String gitUiPercentValue(String value) {
    return '$value percentuale';
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
  String get gitUiUtf8Bom => 'UTF-8 con marchio di byte-order (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 senza marchio di byte-order (BOM)';

  @override
  String get gitUiAddsBom =>
      'Questa modifica aggiunge un marchio di byte-order UTF-8 (BOM) all\'inizio del file.';

  @override
  String get gitUiRemovesBom =>
      'Questa modifica rimuove il marchio di byte-order UTF-8 (BOM) dall\'inizio del file.';

  @override
  String get gitUiNoLineTerminators => 'Nessun terminatore di riga';

  @override
  String gitUiLineEndings(String format) {
    return 'Terminazioni di riga $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Terminali di riga misti ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · nessun LF finale';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Il formato finale della linea cambia da $before a $after. Il testo degli appunti può usare terminazioni di linea diverse dal file originale.';
  }

  @override
  String get gitUiGitFailure =>
      'Operazione Git non riuscita. Rivedi la diagnostica qui sotto.';

  @override
  String get gitUiAbortInline => 'Interrompi';

  @override
  String get gitUiSkipInline => 'Salta';

  @override
  String get gitUiQuitInline => 'esci';

  @override
  String get gitUiMergeInline => 'Unisci';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-pick';

  @override
  String get gitUiRevertInline => 'Annulla con commit';

  @override
  String get gitUiApplyMailboxInline => 'applicaMailbox';

  @override
  String get gitUiSquashInline => 'Accorpa';

  @override
  String get gitUiUnmergedInline => 'non fusa';

  @override
  String get gitHostFetch => 'Recupera';

  @override
  String get gitHostRefreshGitStatus => 'Aggiorna stato Git';

  @override
  String get gitHostCommitStaged => 'Commit in fase';

  @override
  String get gitHostGitBranches => 'Rami di git';

  @override
  String get gitHostReviewPush => 'Recensione push';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Le operazioni Git si applicano a questo intero repository e possono eseguire i suoi hook configurati, filtri, credenziali e strumenti di firma.';

  @override
  String get gitHostContentUnavailable => 'Contenuto non disponibile';

  @override
  String get gitHostInitializeRepository => 'Inizializza repository';

  @override
  String get gitHostCloneRepository => 'Clona repository';

  @override
  String get gitHostInitializeHere => 'Inizializza qui...';

  @override
  String get gitHostCloneRepository2 => 'Clona repository…';

  @override
  String get gitHostGitLog => 'Registro Git';

  @override
  String get gitUiAbsentPlaceholder => '(assente)';

  @override
  String get gitUiUnborn => 'non ancora nato';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Cronologia ribasata · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Cronologia corrente · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Commit riapplicato · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Contenuto in arrivo · $revision';
  }

  @override
  String get gitUiContentConflict => 'Conflitto di contenuto';

  @override
  String get gitUiSubmoduleConflict => 'Conflitto submodulo';

  @override
  String get gitUiSymlinkConflict => 'Conflitto di collegamenti simbolici';

  @override
  String get gitUiAddAddConflict => 'Aggiunto su entrambi i lati';

  @override
  String get gitUiModifyDeleteConflict =>
      'Modificato/cancellato o rinominato/cancellato';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
