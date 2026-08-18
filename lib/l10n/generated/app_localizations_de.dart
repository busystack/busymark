// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Editor für Markdown-Dateien und Writerside-kompatible Dokumentationsprojekte.';

  @override
  String get aboutBusyMark => 'Über BusyMark';

  @override
  String get aboutTagline => 'Markdown- und Writerside-Editor';

  @override
  String get aboutLicenseLabel => 'Lizenz';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutSourceCode => 'Quellcode';

  @override
  String get reportIssue => 'Problem melden';

  @override
  String get feedbackCategory => 'Kategorie';

  @override
  String get feedbackChooseCategory => 'Kategorie auswählen';

  @override
  String get feedbackCategoryProblem => 'Problem oder Fehler';

  @override
  String get feedbackCategoryFeature => 'Funktionswunsch';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Datenschutz- oder Sicherheitsanliegen';

  @override
  String get feedbackCategoryUsability => 'Anliegen zur Bedienbarkeit';

  @override
  String get feedbackCategoryOther => 'Sonstiges';

  @override
  String get feedbackSubject => 'Betreff';

  @override
  String get feedbackMessage => 'Ausführliche Nachricht';

  @override
  String get feedbackReplyEmail => 'E-Mail für Antworten (optional)';

  @override
  String get feedbackIncludeTechnicalDetails =>
      'Technische Details einbeziehen';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Wenn diese Option aktiviert ist, werden nur die Linux-Betriebssystemversion und die Anwendungssprache von BusyMark hinzugefügt. Es werden keine Protokolle, Dateien, Kontodaten oder anderen Diagnosedaten angehängt.';

  @override
  String get feedbackSubmit => 'Absenden';

  @override
  String get feedbackSubmitting => 'Wird gesendet…';

  @override
  String get feedbackCategoryRequired => 'Wählen Sie eine Kategorie aus.';

  @override
  String get feedbackSubjectLength =>
      'Der Betreff muss zwischen 3 und 120 Zeichen lang sein.';

  @override
  String get feedbackMessageLength =>
      'Die Nachricht muss zwischen 10 und 5.000 Zeichen lang sein.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Geben Sie eine gültige E-Mail-Adresse ein oder lassen Sie dieses Feld leer.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark konnte keine Verbindung herstellen. Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get feedbackTimeoutFailure =>
      'Die Anfrage hat zu lange gedauert. Versuchen Sie es erneut.';

  @override
  String get feedbackRateLimitedFailure =>
      'Über diese Verbindung wurden zu viele Berichte gesendet. Warten Sie und versuchen Sie es erneut.';

  @override
  String get feedbackRejectedFailure =>
      'Der Server hat den Bericht abgelehnt. Prüfen Sie die Formularfelder und versuchen Sie es erneut.';

  @override
  String get feedbackServerFailure =>
      'Der Server konnte den Bericht nicht annehmen. Versuchen Sie es später erneut.';

  @override
  String feedbackSuccess(String id) {
    return 'Feedback gesendet. Referenz-ID: $id';
  }

  @override
  String get advanced => 'Erweitert';

  @override
  String get addToGit => 'Zu Git hinzufügen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get apply => 'Anwenden';

  @override
  String get back => 'Zurück';

  @override
  String get bottomLeft => 'Unten links';

  @override
  String get bottomRight => 'Unten rechts';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get choose => 'Wählen';

  @override
  String get chooseLocation => 'Speicherort wählen';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyName => 'Namen kopieren';

  @override
  String get copyFileName => 'Dateinamen kopieren';

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String get create => 'Erstellen';

  @override
  String get creating => 'Wird erstellt …';

  @override
  String get cut => 'Ausschneiden';

  @override
  String get promoteHeading => 'Überschrift hochstufen';

  @override
  String get demoteHeading => 'Überschrift herabstufen';

  @override
  String get moveSectionUp => 'Abschnitt nach oben verschieben';

  @override
  String get moveSectionDown => 'Abschnitt nach unten verschieben';

  @override
  String get confirmDeleteSectionTitle => 'Abschnitt löschen?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '„$name“ und den gesamten Inhalt des Abschnitts löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get delete => 'Löschen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get editor => 'Editor';

  @override
  String get file => 'Datei';

  @override
  String get fileHistory => 'Dateiverlauf';

  @override
  String get folder => 'Ordner';

  @override
  String get insert => 'Einfügen';

  @override
  String get keyboardShortcuts => 'Tastaturkürzel';

  @override
  String get lightTheme => 'Hell';

  @override
  String get mainMenu => 'Hauptmenü';

  @override
  String get fullScreen => 'Vollbild';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Öffnen';

  @override
  String get openInFiles => 'In Dateien öffnen';

  @override
  String get pathActions => 'Pfadaktionen';

  @override
  String get outline => 'Gliederung';

  @override
  String get overwrite => 'Überschreiben';

  @override
  String get paste => 'Einfügen';

  @override
  String get pasteWithoutFormatting => 'Ohne Formatierung einfügen';

  @override
  String get preview => 'Vorschau';

  @override
  String get recent => 'Zuletzt verwendet';

  @override
  String get redo => 'Wiederholen';

  @override
  String get save => 'Speichern';

  @override
  String get search => 'Suchen';

  @override
  String get selectAll => 'Alles auswählen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get source => 'Quelltext';

  @override
  String get split => 'Geteilt';

  @override
  String get systemTheme => 'Systemeinstellung';

  @override
  String get theme => 'Design';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

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
  String get toggleSidebar => 'Seitenbereich';

  @override
  String get topLeft => 'Oben links';

  @override
  String get topRight => 'Oben rechts';

  @override
  String get undo => 'Rückgängig machen';

  @override
  String get validate => 'Validieren';

  @override
  String get validation => 'Validierung';

  @override
  String get viewMode => 'Ansichtsmodus';

  @override
  String get welcome => 'Willkommen';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Bilder';

  @override
  String get openMarkdownFile => 'Markdown-Datei öffnen';

  @override
  String get markdownFileExtensions => '.md oder .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Ordner oder Writerside-Projekt öffnen';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown-Ordner oder Writerside-kompatibles Projekt';

  @override
  String get noOpenFile => 'Keine Datei geöffnet';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Ausgewähltes Element in „Dateien“ löschen oder ausgewähltes Thema aus dem Inhaltsverzeichnis entfernen';

  @override
  String get shortcutGroupGeneral => 'Allgemein';

  @override
  String get shortcutNewDocument => 'Neues Dokument';

  @override
  String get shortcutNewDocumentDescription =>
      'Neues, nicht gespeichertes Markdown-Dokument erstellen';

  @override
  String get shortcutOpenDescription =>
      'Markdown-Datei, Ordner oder Writerside-Projekt öffnen';

  @override
  String get shortcutSaveDescription => 'Aktuelles Dokument speichern';

  @override
  String get shortcutSearchDescription =>
      'Aktuellen Arbeitsbereich durchsuchen';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Diese Tastaturkürzelübersicht anzeigen';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Markdown- und HTML-Referenz öffnen';

  @override
  String get shortcutSettingsDescription => 'BusyMark-Einstellungen öffnen';

  @override
  String get shortcutNextTab => 'Nächster Tab';

  @override
  String get shortcutNextTabDescription =>
      'Zum nächsten geöffneten Tab wechseln';

  @override
  String get shortcutPreviousTab => 'Vorheriger Tab';

  @override
  String get shortcutPreviousTabDescription =>
      'Zum vorherigen geöffneten Tab wechseln';

  @override
  String get shortcutCloseTab => 'Tab schließen';

  @override
  String get shortcutCloseTabDescription => 'Aktiven Tab schließen';

  @override
  String get shortcutCloseAllTabs => 'Alle Tabs schließen';

  @override
  String get shortcutCloseAllTabsDescription =>
      'Alle geöffneten Tabs schließen';

  @override
  String get shortcutGroupTextEditing => 'Textbearbeitung';

  @override
  String get shortcutSelectAllDescription =>
      'Im Quelltextmodus gesamten Text auswählen; im Editormodus zweimal drücken, um alle Blöcke auszuwählen';

  @override
  String get shortcutCutDescription => 'Ausgewählten Text ausschneiden';

  @override
  String get shortcutCopyDescription => 'Ausgewählten Text kopieren';

  @override
  String get shortcutPasteDescription => 'Aus der Zwischenablage einfügen';

  @override
  String get shortcutPastePlainTextDescription =>
      'Text aus der Zwischenablage ohne Formatierung einfügen';

  @override
  String get shortcutUndoDescription => 'Letzte Bearbeitung rückgängig machen';

  @override
  String get shortcutRedoDescription =>
      'Letzte rückgängig gemachte Bearbeitung wiederherstellen';

  @override
  String get shortcutInsertIndentation => 'Einrückung einfügen';

  @override
  String get shortcutInsertIndentationDescription =>
      'An der Cursorposition eine Einrückung einfügen';

  @override
  String get shortcutOutdentSource => 'Quelltext ausrücken';

  @override
  String get shortcutOutdentSourceDescription =>
      'Im Quelltextmodus eine Einrückungsebene entfernen';

  @override
  String get shortcutEscape => 'Suche schließen oder Blockauswahl aufheben';

  @override
  String get shortcutEscapeDescription =>
      'Arbeitsbereichssuche schließen oder im Editormodus eine Blockauswahl aufheben';

  @override
  String get shortcutGroupFormatting => 'Formatierung';

  @override
  String get shortcutBoldDescription =>
      'Fettformatierung für den ausgewählten Text umschalten';

  @override
  String get shortcutItalicDescription =>
      'Kursivformatierung für den ausgewählten Text umschalten';

  @override
  String get shortcutUnderlineDescription =>
      'Unterstreichung für den ausgewählten Text umschalten';

  @override
  String get shortcutLinkDescription => 'Link einfügen oder bearbeiten';

  @override
  String get shortcutInlineCodeDescription =>
      'Inline-Code für den ausgewählten Text umschalten';

  @override
  String get shortcutStrikethroughDescription =>
      'Durchstreichung für den ausgewählten Text umschalten';

  @override
  String get shortcutGroupBlocks => 'Blöcke';

  @override
  String get shortcutParagraphDescription =>
      'Aktuellen Block als Absatz formatieren';

  @override
  String get shortcutHeading1Description =>
      'Aktuellen Block als Überschrift 1 formatieren';

  @override
  String get shortcutHeading2Description =>
      'Aktuellen Block als Überschrift 2 formatieren';

  @override
  String get shortcutHeading3Description =>
      'Aktuellen Block als Überschrift 3 formatieren';

  @override
  String get shortcutHeading4Description =>
      'Aktuellen Block als Überschrift 4 formatieren';

  @override
  String get shortcutHeading5Description =>
      'Aktuellen Block als Überschrift 5 formatieren';

  @override
  String get shortcutHeading6Description =>
      'Aktuellen Block als Überschrift 6 formatieren';

  @override
  String get shortcutGroupLists => 'Listen';

  @override
  String get numberedList => 'Nummerierte Liste';

  @override
  String get shortcutNumberedListDescription =>
      'Formatierung als nummerierte Liste umschalten';

  @override
  String get bulletedList => 'Aufzählungsliste';

  @override
  String get shortcutBulletedListDescription =>
      'Formatierung als Aufzählungsliste umschalten';

  @override
  String get checklist => 'Checkliste';

  @override
  String get shortcutChecklistDescription =>
      'Formatierung als Checkliste umschalten';

  @override
  String get shortcutGroupSidebar => 'Seitenleiste';

  @override
  String get sidebarViewMenu => 'Seitenleistenansicht';

  @override
  String get createMarkdownFile => 'Markdown-Datei erstellen';

  @override
  String get createMarkdownFileDescription =>
      'Neues, nicht gespeichertes lokales Markdown-Dokument starten';

  @override
  String get createWritersideProject => 'Writerside-Projekt erstellen';

  @override
  String get createWritersideProjectDescription =>
      'Neues lokales Writerside-kompatibles Projekt starten';

  @override
  String get defaultProjectName => 'Dokumentation';

  @override
  String get defaultInstanceName => 'Benutzerhandbuch';

  @override
  String get defaultStartTopicTitle => 'Erste Schritte';

  @override
  String get projectName => 'Projektname';

  @override
  String get directoryName => 'Verzeichnisname';

  @override
  String get instanceName => 'Instanzname';

  @override
  String get instanceId => 'Instanz-ID';

  @override
  String get startTopicTitle => 'Titel des Startthemas';

  @override
  String get location => 'Speicherort';

  @override
  String get projectNameRequired => 'Projektname ist erforderlich.';

  @override
  String get directoryNameRequired => 'Verzeichnisname ist erforderlich.';

  @override
  String get useSingleSafeDirectoryName =>
      'Verwenden Sie einen einzelnen zulässigen Verzeichnisnamen.';

  @override
  String get useLowercaseIdentifier =>
      'Verwenden Sie einen Bezeichner mit Kleinbuchstaben, Zahlen, Unterstrichen oder Bindestrichen.';

  @override
  String get startTopicTitleRequired =>
      'Der Titel des Startthemas ist erforderlich.';

  @override
  String get createWritersideProjectFailed =>
      'Das Writerside-Projekt konnte nicht erstellt werden.';

  @override
  String get settingsTitle => 'BusyMark-Einstellungen';

  @override
  String get autoSave => 'Automatisch speichern';

  @override
  String get autoSaveDescription =>
      'Dateiänderungen nach kurzer Inaktivität automatisch speichern.';

  @override
  String get wordWrap => 'Zeilenumbruch';

  @override
  String get editorFontSize => 'Schriftgröße des Editors';

  @override
  String get validateOnEdit => 'Bei Bearbeitung validieren';

  @override
  String get clearRecentWorkspaces =>
      'Zuletzt verwendete Arbeitsbereiche löschen';

  @override
  String get editingButtonsPosition => 'Position der Bearbeitungsschaltflächen';

  @override
  String get editingButtonsPositionDescription =>
      'Wählen Sie aus, wo die schwebenden WYSIWYG-Bearbeitungsschaltflächen angezeigt werden.';

  @override
  String get editingButtonsDirection =>
      'Ausrichtung der Bearbeitungsschaltflächen';

  @override
  String get editingButtonsDirectionDescription =>
      'Wählen Sie, ob die schwebenden WYSIWYG-Bearbeitungsschaltflächen horizontal oder vertikal angeordnet werden.';

  @override
  String get horizontal => 'Horizontal';

  @override
  String get vertical => 'Vertikal';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get allowRemoteImages => 'Externe Bilder laden';

  @override
  String get allowRemoteImagesDescription =>
      'Das Laden von Bildern in der Markdown-Vorschau und im Editor über HTTP- und HTTPS-URLs zulassen.';

  @override
  String get clearRemoteImagePermissions =>
      'Berechtigungen für externe Bilder löschen';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Arbeitsbereiche vergessen, denen das Laden externer Bilder erlaubt wurde.';

  @override
  String get clearGitWorkspaceTrust =>
      'Vertrauenswürdige Git-Arbeitsbereiche löschen';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Vor dem Aktivieren von Git-Funktionen für zuvor vertrauenswürdige Arbeitsbereiche nachfragen.';

  @override
  String get settingsWindowSectionTitle => 'Fenster';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Vor dem Schließen bei ungespeicherten Änderungen bestätigen';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Vor dem Schließen von BusyMark nachfragen, wenn Dokumente ungespeicherte Änderungen haben.';

  @override
  String get closeUnsavedChangesTitle => 'Ungespeicherte Änderungen';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Dieses Dokument enthält ungespeicherte Änderungen. Änderungen vor dem Schließen von BusyMark speichern?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Dokumente enthalten ungespeicherte Änderungen. Änderungen vor dem Schließen von BusyMark speichern?',
      one:
          '1 Dokument enthält ungespeicherte Änderungen. Änderungen vor dem Schließen von BusyMark speichern?',
      zero: 'Änderungen vor dem Schließen von BusyMark speichern?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Abbrechen';

  @override
  String get closeUnsavedChangesDiscard => 'Verwerfen';

  @override
  String get closeUnsavedChangesSave => 'Speichern';

  @override
  String get currentFile => 'die aktuelle Datei';

  @override
  String get unsavedChanges => 'Ungespeicherte Änderungen';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Für $fileName liegen ungespeicherte Änderungen vor. Vor dem Fortfahren speichern?';
  }

  @override
  String get fileChangedOnDisk => 'Datei auf dem Datenträger geändert';

  @override
  String get fileChangedOnDiskMessage =>
      'Diese Datei wurde auf dem Datenträger geändert, seit Sie sie geöffnet haben. Soll sie überschrieben werden?';

  @override
  String get untitledMarkdownFileName => 'Unbenannt.md';

  @override
  String get unorderedList => 'Ungeordnete Liste';

  @override
  String get orderedList => 'Nummerierte Liste';

  @override
  String get taskList => 'Aufgabenliste';

  @override
  String get toggleTaskChecked => 'Aufgabenstatus umschalten';

  @override
  String get indentListItem => 'Listenelement einrücken';

  @override
  String get outdentListItem => 'Listenelement ausrücken';

  @override
  String get blockquote => 'Blockzitat';

  @override
  String get codeBlock => 'Codeblock';

  @override
  String get codeBlockLanguage => 'Codeblock-Sprache';

  @override
  String get image => 'Bild';

  @override
  String get inlineImage => 'Inline-Bild';

  @override
  String get table => 'Tabelle';

  @override
  String get htmlBlock => 'HTML-Block';

  @override
  String get htmlContentDefault => 'HTML-Inhalt';

  @override
  String get shortcutHtmlBlockDescription =>
      'HTML-Block einfügen oder bearbeiten';

  @override
  String get renderedHtml => 'Gerendertes HTML';

  @override
  String get editHtml => 'HTML bearbeiten';

  @override
  String get htmlSource => 'HTML-Quelltext';

  @override
  String get thematicBreak => 'Trennlinie';

  @override
  String get bold => 'Fett';

  @override
  String get italic => 'Kursiv';

  @override
  String get underline => 'Unterstrichen';

  @override
  String get strikethrough => 'Durchgestrichen';

  @override
  String get inlineCode => 'Inline-Code';

  @override
  String get link => 'Link';

  @override
  String get hardLineBreak => 'Harter Zeilenumbruch';

  @override
  String get textStyle => 'Textstil';

  @override
  String get paragraph => 'Absatz';

  @override
  String get heading1 => 'Überschrift 1';

  @override
  String get heading2 => 'Überschrift 2';

  @override
  String get heading3 => 'Überschrift 3';

  @override
  String get heading4 => 'Überschrift 4';

  @override
  String get heading5 => 'Überschrift 5';

  @override
  String get heading6 => 'Überschrift 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Tabelle löschen';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Spalte $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Spalte links einfügen';

  @override
  String get insertColumnRight => 'Spalte rechts einfügen';

  @override
  String get deleteColumn => 'Spalte löschen';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Zeile $rowNumber';
  }

  @override
  String get insertRowAbove => 'Zeile oben einfügen';

  @override
  String get insertRowBelow => 'Zeile unten einfügen';

  @override
  String get deleteRow => 'Zeile löschen';

  @override
  String get tableHeaderHint => 'Kopfzeile';

  @override
  String get tableCellHint => 'Zelle';

  @override
  String get language => 'Sprache';

  @override
  String get hideEditingButtons => 'Bearbeitungsschaltflächen ausblenden';

  @override
  String get showEditingButtons => 'Bearbeitungsschaltflächen anzeigen';

  @override
  String get altText => 'Alternativtext';

  @override
  String get editorPlaceholderText => 'Text';

  @override
  String get editorPlaceholderCode => 'Code';

  @override
  String get editorPlaceholderAltText => 'Alternativtext';

  @override
  String get describeTheImage => 'Bild beschreiben';

  @override
  String get columns => 'Spalten';

  @override
  String get rows => 'Zeilen';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Kopfzeile $columnNumber';
  }

  @override
  String get tableCellDefault => 'Zelle';

  @override
  String get noImageSource => 'Keine Bildquelle';

  @override
  String get remoteImageBlocked => 'Externes Bild blockiert';

  @override
  String get remoteImageBlockedTooltip =>
      'Festlegen, ob BusyMark externe Bilder laden darf.';

  @override
  String get remoteImagesBlockedTitle => 'Externe Bilder sind blockiert';

  @override
  String get remoteImagesBlockedMessage =>
      'Dieses Dokument verweist auf Bilder aus dem Internet. Beim Laden können Netzwerkinformationen an den Bildhost übermittelt werden.';

  @override
  String get loadRemoteImagesForWorkspace => 'Für diesen Arbeitsbereich laden';

  @override
  String get alwaysLoadRemoteImages => 'Externe Bilder immer laden';

  @override
  String get hideSidebar => 'Seitenbereich ausblenden';

  @override
  String get showSidebar => 'Seitenbereich anzeigen';

  @override
  String get showPreview => 'Vorschau anzeigen';

  @override
  String get hidePreview => 'Vorschau ausblenden';

  @override
  String get workspaceKindUnsavedMarkdown => 'Ungespeicherte Markdown-Datei';

  @override
  String get workspaceKindSingleMarkdown => 'Einzelne Markdown-Datei';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown-Ordner';

  @override
  String get workspaceKindWritersideModule => 'Writerside-Modul';

  @override
  String get problems => 'Probleme';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Diagnosemeldungen',
      one: '1 Diagnosemeldung',
      zero: 'Keine Diagnosemeldungen',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Dateien';

  @override
  String get toc => 'Inhaltsverzeichnis';

  @override
  String get tocActions => 'Inhaltsverzeichnisaktionen';

  @override
  String get markdownUnsaved => 'Markdown – nicht gespeichert';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$kind – $_temp0';
  }

  @override
  String get noFiles => 'Keine Dateien';

  @override
  String get newFile => 'Neue Datei';

  @override
  String get noWritersideToc => 'Kein Writerside-Inhaltsverzeichnis';

  @override
  String get tocSection => 'Inhaltsverzeichnisabschnitt';

  @override
  String get newTopic => 'Neues Thema';

  @override
  String get newChildTopic => 'Neues untergeordnetes Thema';

  @override
  String get newSiblingTopic => 'Neues Thema auf gleicher Ebene';

  @override
  String get renameTopicFile => 'Themendatei umbenennen';

  @override
  String get topicPlacement => 'Position im Inhaltsverzeichnis';

  @override
  String get tocRoot => 'Auf oberster Ebene des Inhaltsverzeichnisses';

  @override
  String get afterSelectedTopic => 'Nach dem ausgewählten Thema';

  @override
  String get insideSelectedTopic => 'Im ausgewählten Thema';

  @override
  String get pasteAfterTopic => 'Danach einfügen';

  @override
  String get pasteAsChildTopic => 'Als untergeordnetes Thema einfügen';

  @override
  String get removeFromToc => 'Aus dem Inhaltsverzeichnis entfernen';

  @override
  String get confirmRemoveFromTocTitle =>
      'Aus dem Inhaltsverzeichnis entfernen?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '$name aus diesem Inhaltsverzeichnis entfernen? Die Themendatei bleibt erhalten.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Themendatei löschen?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name löschen und aus allen Inhaltsverzeichnissen entfernen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get safeDeleteTopicFile => 'Themendatei sicher löschen…';

  @override
  String get removeTocElement => 'Inhaltsverzeichniselement entfernen';

  @override
  String get reviewUsages => 'Verwendungen prüfen';

  @override
  String get deleteTopicFile => 'Themendatei löschen';

  @override
  String get removeAction => 'Entfernen';

  @override
  String topicRemovalSummary(String topic) {
    return '„$topic“ aus der ausgewählten Hilfeinstanz entfernen. Die Themendatei bleibt erhalten.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '„$topic“ löschen und die Verweise darauf im gesamten Writerside-Projekt sicher aktualisieren.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count untergeordnete Themen werden um eine Ebene nach oben verschoben.',
      one: '1 untergeordnetes Thema wird um eine Ebene nach oben verschoben.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Dieses Thema wird als Startseite einer Instanz verwendet. Prüfen Sie seine Verwendungen und weisen Sie eine andere Startseite zu, bevor Sie fortfahren.';

  @override
  String topicUsagesCount(int count) {
    return 'Verwendungen ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Es wurden keine Verweise gefunden, die ungültig würden.';

  @override
  String get topicUsagesFound =>
      'BusyMark hat die folgenden Verweise auf dieses Thema gefunden.';

  @override
  String get topicUsageTocElements => 'Inhaltsverzeichniselemente';

  @override
  String get topicUsageStartPages => 'Startseiten';

  @override
  String get topicUsageTopicLinks => 'Themenlinks';

  @override
  String get topicUsageIncludes => 'Einbindungen';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verwendungen',
      one: '1 Verwendung',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Refactoring-Optionen';

  @override
  String get updateUsagesAutomatically =>
      'Verwendungen automatisch aktualisieren';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Inhaltsverzeichnisverweise und Einbindungen entfernen und den Linktext beibehalten.';

  @override
  String get manualUsageUpdatesRequired =>
      'Einige Verwendungen müssen vor diesem Refactoring manuell geändert werden.';

  @override
  String get setRedirectTo => 'Weiterleiten an';

  @override
  String get noRedirectDescription =>
      'Die alte veröffentlichte Seite nicht weiterleiten.';

  @override
  String get redirectTarget => 'Umleitungsziel';

  @override
  String get remainingUsagesBlockRemoval =>
      'Prüfen und aktualisieren Sie die verbleibenden Verwendungen, bevor Sie fortfahren, oder aktivieren Sie automatische Aktualisierungen, wenn diese verfügbar sind.';

  @override
  String usagesOfTopic(String topic) {
    return 'Verwendungen von $topic';
  }

  @override
  String get noUsagesFound => 'Keine Verwendungen gefunden.';

  @override
  String get outsideSelectedInstance => 'Außerhalb der ausgewählten Instanz';

  @override
  String get doRefactor => 'Refactoring ausführen';

  @override
  String get orphanTopicTitle => 'Themendatei wird nicht mehr verwendet';

  @override
  String get keepTopicFile => 'Themendatei behalten';

  @override
  String orphanTopicMessage(String topic) {
    return '„$topic“ wird an keiner Stelle dieses Writerside-Projekts mehr verwendet. Löschen Sie die Datei oder behalten Sie sie für die Verwendung in einer anderen Instanz.';
  }

  @override
  String get defaultNewTopicTitle => 'Neues Thema';

  @override
  String get topicTitle => 'Thementitel';

  @override
  String get fileName => 'Dateiname';

  @override
  String get topicTitleRequired => 'Thementitel ist erforderlich.';

  @override
  String get fileNameRequired => 'Dateiname ist erforderlich.';

  @override
  String get rename => 'Umbenennen';

  @override
  String get confirmDeleteFileTitle => 'Datei löschen?';

  @override
  String get confirmDeleteFolderTitle => 'Ordner löschen?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name und alle enthaltenen Dateien löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get useSingleSafeFileName =>
      'Verwenden Sie einen einzelnen zulässigen Dateinamen.';

  @override
  String useExpectedExtension(String extension) {
    return 'Verwenden Sie die Dateiendung $extension für das ausgewählte Format.';
  }

  @override
  String get useIdentifierCharacters =>
      'Verwenden Sie vor der Dateiendung Buchstaben, Zahlen, Unterstriche oder Bindestriche.';

  @override
  String get topicIdAlreadyExists => 'Die Themen-ID existiert bereits.';

  @override
  String get createWritersideTopicFailed =>
      'Das Writerside-Thema konnte nicht erstellt werden.';

  @override
  String get noOutline => 'Keine Gliederung';

  @override
  String expandKind(String kind) {
    return '$kind erweitern';
  }

  @override
  String collapseKind(String kind) {
    return '$kind zuklappen';
  }

  @override
  String get foldKindSection => 'Abschnitt';

  @override
  String get foldKindList => 'Liste';

  @override
  String get foldKindQuote => 'Zitat';

  @override
  String get foldKindTag => 'Tag';

  @override
  String get sourceSearchPreviousMatch => 'Vorheriger Treffer';

  @override
  String get sourceSearchNextMatch => 'Nächster Treffer';

  @override
  String get sourceSearchCaseSensitive => 'Groß-/Kleinschreibung beachten';

  @override
  String get sourceSearchWholeWord => 'Nur ganze Wörter';

  @override
  String get sourceSearchRegex => 'Regulärer Ausdruck';

  @override
  String get sourceSearchInvalidRegex => 'Ungültiger regulärer Ausdruck';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Große Datei: Hervorhebung und Faltung sind pausiert';

  @override
  String get noPreview => 'Keine Vorschau';

  @override
  String get note => 'Hinweis';

  @override
  String get tip => 'Tipp';

  @override
  String get warning => 'Warnung';

  @override
  String get tabs => 'Tabs';

  @override
  String get tab => 'Tab';

  @override
  String get procedure => 'Vorgehensweise';

  @override
  String get step => 'Schritt';

  @override
  String get topic => 'Thema';

  @override
  String get chapter => 'Kapitel';

  @override
  String couldNotOpenTarget(String target) {
    return '$target konnte nicht geöffnet werden';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Linkziel nicht gefunden: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Dieser Dateityp kann nicht im Editor geöffnet werden';

  @override
  String anchorNotFound(String anchor) {
    return 'Anker nicht gefunden: $anchor';
  }

  @override
  String get noProblemsFound => 'Keine Probleme gefunden';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath – Zeile $lineNumber';
  }

  @override
  String get untitledResult => 'Ergebnis ohne Titel';

  @override
  String get documentKindMarkdownFile => 'Markdown-Datei';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside-Markdown-Thema';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside-XML-Thema';

  @override
  String get documentKindWritersideTree => 'Writerside-Baum';

  @override
  String get documentKindConfigurationFile => 'Konfigurationsdatei';

  @override
  String get documentKindVariablesFile => 'Variablendatei';

  @override
  String get documentKindCategoriesFile => 'Kategoriendatei';

  @override
  String get documentKindResourceFile => 'Ressourcendatei';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Öffnen fehlgeschlagen: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Das Writerside-Projekt konnte nicht erstellt werden: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Das Writerside-Thema konnte nicht erstellt werden: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Datei konnte nicht geöffnet werden: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Wählen Sie aus, wo diese Markdown-Datei gespeichert werden soll.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Speichern blockiert: Datei auf dem Datenträger geändert.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Dateivorgang fehlgeschlagen: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Validierung fehlgeschlagen: $error';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Pfad existiert nicht: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Zielverzeichnis existiert bereits und ist nicht leer: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Zielpfad existiert bereits und ist kein Verzeichnis: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Generierte Datei existiert bereits: $path';
  }

  @override
  String get errorParentDirectoryRequired =>
      'Übergeordnetes Verzeichnis ist erforderlich.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Das übergeordnete Verzeichnis existiert nicht: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Verzeichnis existiert nicht: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Pfad existiert bereits: $path';
  }

  @override
  String get errorFileNameRequired => 'Dateiname ist erforderlich.';

  @override
  String get errorFileNameUnsafe =>
      'Dateiname muss ein einzelnes sicheres Pfadsegment sein.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Ein Ordner kann nicht in sich selbst verschoben werden.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Der Dateivorgang muss im Arbeitsbereich bleiben.';

  @override
  String get errorFileOperationRoot =>
      'Das Stammverzeichnis des Arbeitsbereichs kann nicht über den Dateibaum geändert werden.';

  @override
  String get errorProjectNameRequired => 'Projektname ist erforderlich.';

  @override
  String get errorDirectoryNameRequired => 'Verzeichnisname ist erforderlich.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Der Verzeichnisname muss ein einzelnes zulässiges Pfadsegment sein.';

  @override
  String get errorInstanceIdInvalid =>
      'Die Instanz-ID muss mit einem Kleinbuchstaben beginnen und darf nur Kleinbuchstaben, Zahlen, Unterstriche und Bindestriche enthalten.';

  @override
  String get errorTopicFileInvalid =>
      'Der Name der Themendatei muss ein Markdown-Dateiname ohne Pfadtrennzeichen sein.';

  @override
  String get errorTopicTitleRequired => 'Thementitel ist erforderlich.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Das Stammverzeichnis des Writerside-Moduls existiert nicht: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Zum Erstellen eines Themas muss ein Writerside-Modul geöffnet sein.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Das Writerside-Modul enthält keinen Baum für die Hilfeinstanz.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Die Writerside-Tree-Datei existiert nicht: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Die Themen-ID „$topicId“ ist in diesem Hilfemodul bereits vorhanden.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Themendatei existiert bereits: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Das Referenzthema ist im ausgewählten Baum nicht vorhanden: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Der ausgewählte Inhaltsverzeichniseintrag ist nicht mehr vorhanden.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Ein Inhaltsverzeichniseintrag kann nicht in sich selbst oder in eines seiner untergeordneten Elemente verschoben werden.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Das Startthema $topic kann nicht gelöscht werden. Wählen Sie zuerst eine andere Startseite aus.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Verwenden Sie „Sicher löschen“ für Writerside-Themendateien.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Die Suche nach Verwendungen des Themas konnte nicht abgeschlossen werden. Es wurden keine Dateien geändert.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Einige Verwendungen des Themas müssen noch bearbeitet werden. Prüfen Sie sie, bevor Sie fortfahren.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Das ausgewählte Weiterleitungsziel ist nicht mehr gültig. Wählen Sie es erneut aus.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Das Entfernen des Themas konnte nicht vollständig rückgängig gemacht werden. Prüfen Sie vor dem Fortfahren diese Pfade: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Das Themen-Stammverzeichnis muss ein zulässiges relatives Verzeichnis sein.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Der Name der Themendatei muss ein einzelnes zulässiges Pfadsegment sein.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Die Dateiendung der Themendatei muss mit dem ausgewählten Format ($extension) übereinstimmen.';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Der Name der Themendatei darf nur Buchstaben, Zahlen, Unterstriche und Bindestriche enthalten.';

  @override
  String errorUnknown(String code) {
    return 'Unbekannter Fehler: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Dateimetadaten konnten nicht gelesen werden: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Großer Arbeitsbereich erkannt. Einige Dateien wurden übersprungen, damit die App reaktionsfähig bleibt.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Arbeitsbereichseintrag konnte nicht geprüft werden: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Die Datei ist größer als das Beta-Limit für die automatische Analyse.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Die Markdown-Datei konnte nicht gelesen werden: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Fehlerhafter Attributblock für Writerside-Überschriften.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Doppelte Überschriften-ID „$id“.';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Zusätzliche H1-Überschriften der obersten Ebene werden als Kapitel behandelt.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Das Writerside-Markdown-Thema hat weder eine H1-Überschrift noch einen Front-Matter-Titel.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Dem XML-Thema fehlt ein Titel.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Dem Thema „$fileName“ fehlt ein Titel.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Der Front-Matter-Block ist nicht geschlossen.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Unsicheres HTML-Element.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Linkziel existiert nicht: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Anker „$anchor“ existiert nicht.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Dem Bild „$destination“ fehlt Alternativtext.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Bilddatei existiert nicht: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Ungültiges XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Das Stammelement von writerside.cfg muss <ihp> sein.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'Der Snippets-Deklaration fehlt das Attribut src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'Der Instanzgruppen-Deklaration fehlt das Attribut src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Nicht unterstützter Keymaps-Modus: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'Der Instanzdeklaration fehlt das Attribut src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'In writerside.cfg ist keine Instanz registriert.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Das Stammelement von .tree muss <instance-profile> sein.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'Dem Instanzprofil fehlt das Attribut id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Der Dateiname der Tree-Datei ohne Endung stimmt nicht mit der Instanz-ID „$id“ überein.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Bei einer Instanz, die keine Bibliothek ist, fehlt start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Startseite „$startPage“ existiert nicht.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Das Thema „$topic“ kommt in diesem Inhaltsverzeichnis mehr als einmal vor.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Die Variablendeklaration muss einen Namen und einen Wert enthalten.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Variable „$name“ wird mehr als einmal deklariert.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'Der Kategorie fehlt die ID.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Kategorie „$id“ wird mehr als einmal deklariert.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Die Kategorie-Reihenfolge „$order“ wird mehr als einmal deklariert.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Das Stammelement von .topic muss <topic> sein.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'Dem Stammelement des XML-Themas fehlt das Attribut id.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Die Stammelement-ID „$id“ des XML-Themas muss mit dem Dateinamen „$expectedId“ übereinstimmen.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Die Element-ID „$elementId“ kommt mehr als einmal vor.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'Bei <a> fehlt das Attribut href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Der Writerside-Modus erfordert writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Das konfigurierte Build-Konfigurationsverzeichnis fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Das konfigurierte API-Spezifikationsverzeichnis fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Das konfigurierte Snippets-Verzeichnis fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Die konfigurierte Variablendatei fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Die konfigurierte Kategoriendatei fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Die konfigurierte Instanzgruppendatei fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Der registrierte Instanzbaum „$source“ existiert nicht.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Themendatei konnte nicht gelesen werden: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Das Standardverzeichnis für Themen fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Das konfigurierte Themenverzeichnis fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Das konfigurierte Bilderverzeichnis fehlt: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Die Element-ID „$id“ kommt mehr als einmal vor.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Das Inhaltsverzeichnis verweist auf das fehlende Thema „$topic“.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Externer href-Wert „$href“ ist ungültig.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Variable „%$name%“ ist nicht deklariert.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Themenlink „$destination“ lässt sich nicht auflösen.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Anker „$anchor“ existiert nicht in „$targetName“.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'Bei <include> fehlt das Attribut from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Die Include-Quelle „$from“ ist nicht vorhanden.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Das Include-Element „$elementId“ existiert nicht in „$from“.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Die seealso-Kategorie „$ref“ ist nicht deklariert.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Die Themenreferenz „$reference“ ist nicht eindeutig.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Unbekannte Diagnosemeldung: $code';
  }

  @override
  String get close => 'Schließen';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git-Diff';

  @override
  String get gitShowDiff => 'Diff anzeigen';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'alt $oldRange → neu $newRange';
  }

  @override
  String get gitDiffNoLines => 'keine Zeilen';

  @override
  String get gitUnavailableTitle => 'Git ist nicht verfügbar';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Installieren Sie Git oder konfigurieren Sie BusyMark so, dass ein verfügbares Git-Programm verwendet wird. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Diesem Arbeitsbereich für Git vertrauen?';

  @override
  String get gitTrustRequiredMessage =>
      'Git-Repositorys können über Hooks, Filter und andere Konfigurationen Programme ausführen. Vertrauen Sie diesem Arbeitsbereich, bevor BusyMark Repository-Daten liest oder Git-Aktionen aktiviert.';

  @override
  String get gitTrustWorkspace => 'Diesem Arbeitsbereich vertrauen';

  @override
  String get gitNotRepositoryTitle => 'Kein Git-Repository';

  @override
  String get gitNotRepositoryMessage =>
      'Dieser Arbeitsbereich befindet sich nicht in einem Git-Repository.';

  @override
  String get gitInitializeRepository => 'Repository initialisieren';

  @override
  String get gitDetachedHead => 'Detached HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Detached HEAD bei $commit';
  }

  @override
  String get gitNoUpstream => 'Kein Upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nicht gepushte Commits',
      one: '1 nicht gepushter Commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Commits zum Pullen',
      one: '1 Commit zum Pullen',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Sauber';

  @override
  String get gitConflicts => 'Konflikte';

  @override
  String get gitChanges => 'Änderungen';

  @override
  String get gitStaged => 'Vorgemerkt';

  @override
  String get gitUnstaged => 'Nicht vorgemerkt';

  @override
  String get gitHistory => 'Verlauf';

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitBranchActions => 'Branch-Aktionen';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Abrufen';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'Datei vormerken';

  @override
  String get gitRemoveFromCommit => 'Vormerkung der Datei aufheben';

  @override
  String get gitDiscard => 'Verwerfen';

  @override
  String get gitOpenFile => 'Datei öffnen';

  @override
  String get gitMarkResolved => 'Als gelöst markieren';

  @override
  String get gitUntracked => 'Nicht versionierte Dateien';

  @override
  String get gitCommitMessage => 'Commit-Nachricht';

  @override
  String get gitCommitSelectedFiles => 'Ausgewählte Dateien';

  @override
  String get gitCommitNoSelectedFiles =>
      'Merken Sie vor dem Commit mindestens eine Datei vor.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vorgemerkte Dateien',
      one: '1 vorgemerkte Datei',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Außerhalb des Arbeitsbereichs';

  @override
  String get gitCommitMessageRequired => 'Geben Sie eine Commit-Nachricht ein.';

  @override
  String get gitCreateBranch => 'Branch erstellen';

  @override
  String get gitNewBranch => '+ Neuer Branch';

  @override
  String get gitBranchName => 'Branchname';

  @override
  String get gitSwitchBranch => 'Wechseln';

  @override
  String get gitNoChanges => 'Keine Änderungen';

  @override
  String get gitNoHistory => 'Kein Verlauf';

  @override
  String get gitNoBranches => 'Keine Branches';

  @override
  String get gitNoDiff => 'Kein Diff anzuzeigen';

  @override
  String get gitBinaryFile =>
      'Binärdatei. BusyMark zeigt keine Binär-Patches an.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Binärdatei ($size Byte). BusyMark stellt Binär-Patches nicht dar.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Ungespeicherte Editoränderungen werden erst nach dem Speichern berücksichtigt.';

  @override
  String get gitConfirmDiscardTitle => 'Git-Änderungen verwerfen?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die ausgewählten versionierten Dateien werden auf den Stand in Git zurückgesetzt.',
      one:
          'Die ausgewählte versionierte Datei wird auf den Stand in Git zurückgesetzt.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die ausgewählten nicht versionierten Dateien werden gelöscht.',
      one: 'Die ausgewählte nicht versionierte Datei wird gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die ausgewählten Dateien werden abhängig von ihrem Git-Status zurückgesetzt oder gelöscht.',
      one:
          'Die ausgewählte Datei wird abhängig von ihrem Git-Status zurückgesetzt oder gelöscht.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Zu $branch wechseln?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark lädt den Arbeitsbereich vom Datenträger neu, nachdem Git den Branch gewechselt hat.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Upstream-Branch festlegen?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Dieser Branch hat keinen Upstream. BusyMark kann $branch pushen und den Upstream festlegen, wenn genau ein Remote konfiguriert ist.';
  }

  @override
  String get gitProjectHistory => 'Projekt';

  @override
  String get gitFileHistory => 'Aktuelle Datei';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Der Dateiverlauf erfordert eine geöffnete Markdown-Datei.';

  @override
  String get gitLoadMore => 'Mehr laden';

  @override
  String get gitChangesInCommit => 'Änderungen in diesem Commit';

  @override
  String get gitCompareWithCurrent => 'Mit aktueller Version vergleichen';

  @override
  String get gitRestoreVersion => 'Diese Version wiederherstellen';

  @override
  String get gitConfirmRestoreTitle => 'Diese Dateiversion wiederherstellen?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark ersetzt die aktuelle Datei im Arbeitsverzeichnis durch die ausgewählte Commit-Version. Die wiederhergestellte Datei bleibt nicht vorgemerkt.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Dateiaktionen';

  @override
  String get gitStatusAdded => 'Hinzugefügt';

  @override
  String get gitStatusDeleted => 'Gelöscht';

  @override
  String get gitStatusRenamed => 'Umbenannt';

  @override
  String get gitStatusCopied => 'Kopiert';

  @override
  String get gitStatusUntracked => 'Nicht versioniert';

  @override
  String get gitStatusConflicted => 'Konflikt';

  @override
  String get gitStatusIgnored => 'Ignoriert';

  @override
  String get gitStatusTypeChanged => 'Typ geändert';

  @override
  String get gitStatusModified => 'Geändert';

  @override
  String get gitStatusUnknown => 'Unbekannt';

  @override
  String get gitErrorUnavailable => 'Git ist nicht verfügbar.';

  @override
  String get gitErrorNotRepository =>
      'Dieser Arbeitsbereich ist kein Git-Repository.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark hat einen unsicheren Git-Pfad blockiert.';

  @override
  String get gitErrorInvalidBranchName =>
      'Geben Sie einen gültigen Branchnamen ein.';

  @override
  String get gitErrorNoRemote => 'Es ist kein Git-Remote konfiguriert.';

  @override
  String get gitErrorNoUpstream => 'Es ist kein Upstream-Branch konfiguriert.';

  @override
  String get gitErrorMultipleRemotes =>
      'Mehrere Remotes sind konfiguriert. Wählen Sie außerhalb dieser BusyMark-Version einen Upstream aus.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Speichern oder verwerfen Sie die Editoränderungen in BusyMark, bevor Sie den Branch wechseln.';

  @override
  String get gitErrorDiverged =>
      'Der Branch ist auseinandergelaufen. Führen Sie Merge oder Rebase außerhalb dieser BusyMark-Version aus.';

  @override
  String get gitErrorAuthentication =>
      'Git-Authentifizierung fehlgeschlagen. Im Snap muss für SSH-Remotes möglicherweise die Schnittstelle ssh-keys verbunden werden.';

  @override
  String get gitErrorNetwork => 'Git-Netzwerkvorgang fehlgeschlagen.';

  @override
  String get gitErrorConflict => 'Git hat ungelöste Konflikte gemeldet.';

  @override
  String get gitErrorCommandFailed => 'Git-Befehl fehlgeschlagen.';

  @override
  String get markdownAndHtml => 'Markdown und HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Markdown-Blöcke';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Blockstrukturen, die in Markdown-Quelltext und Vorschau unterstützt werden.';

  @override
  String get markdownHtmlInlineFormatting => 'Inline-Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formatierung innerhalb von Absätzen, Listeneinträgen und Tabellenzellen.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Roh-HTML-Blöcke';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Sichere HTML-Blocktags, die über BusyMark-Vorschauwidgets gerendert werden.';

  @override
  String get markdownHtmlRawHtmlInline => 'Roh-HTML-Inline-Tags';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Sichere Inline-HTML-Tags, die ohne sichtbare Tags gerendert werden.';

  @override
  String get markdownHtmlSafety => 'Sicherheitsregeln';

  @override
  String get markdownHtmlSafetyDescription =>
      'Roh-HTML wird vor der Vorschau geparst und bereinigt.';

  @override
  String get markdownHtmlHeadings => 'Überschriften';

  @override
  String get markdownHtmlParagraphs => 'Absätze';

  @override
  String get markdownHtmlLists => 'Listen';

  @override
  String get markdownHtmlHtmlContainers => 'Container';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Textblöcke';

  @override
  String get markdownHtmlHtmlFigures => 'Abbildungen und Bilder';

  @override
  String get markdownHtmlHtmlPreformatted => 'Vorformatierter Code';

  @override
  String get markdownHtmlHtmlDisclosure => 'Aufklappblöcke';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Beschreibungslisten';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Formatierungstags';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Inline-Code-Tags';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Semantische Texttags';

  @override
  String get markdownHtmlSanitizedPreview => 'Bereinigte Vorschau';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Erlaubtes HTML wird in BusyMark-Vorschaublöcke umgewandelt, nicht im Browser gerendert.';

  @override
  String get markdownHtmlSourcePreserved => 'Quelltext bleibt erhalten';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Unverändertes Roh-HTML wird exakt als Quelltext gespeichert.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown in HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown-Zeichen innerhalb von Roh-HTML werden als normaler Text angezeigt.';

  @override
  String get markdownHtmlBlockedContent => 'Blockierte aktive Inhalte';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Skripte, Styles, Frames, Formulare, SVG, MathML, Events und unsichere Attribute werden blockiert.';

  @override
  String get markdownHtmlSafeUrls => 'Nur sichere URLs';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Links erlauben http, https, mailto, tel, relative URLs und Fragmente; unsichere URL-Schemata werden blockiert.';

  @override
  String get exportAsPdf => 'Als PDF exportieren';

  @override
  String get pdfExportDescription =>
      'Wählen Sie das Seitenlayout für eine professionelle, eigenständige PDF-Datei.';

  @override
  String get pdfRemoteImagesNote =>
      'Remote Bilder werden beim Export nicht heruntergeladen. Lokale Bilder werden einbezogen, wenn sie verfügbar sind.';

  @override
  String get pdfPageSize => 'Seitengröße';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'US-Letter';

  @override
  String get pdfOrientation => 'Ausrichtung';

  @override
  String get pdfPortrait => 'Hochformat';

  @override
  String get pdfLandscape => 'Querformat';

  @override
  String get pdfMargins => 'Ränder';

  @override
  String get pdfMarginNarrow => 'Schmal';

  @override
  String get pdfMarginNormal => 'Standard';

  @override
  String get pdfMarginWide => 'Breit';

  @override
  String get pdfIncludePageNumbers => 'Seitenzahlen einfügen';

  @override
  String get export => 'Exportieren';

  @override
  String get exportingPdf => 'PDF wird exportiert…';

  @override
  String get fileTypePdf => 'PDF-Dokument';

  @override
  String pdfExported(String fileName) {
    return '$fileName wurde exportiert.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return '$fileName wurde exportiert. Nicht einbezogene Bilder: $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'Die PDF-Exportkomponente fehlt. Installieren Sie BusyMark neu und versuchen Sie es erneut.';

  @override
  String get pdfExportTimedOut =>
      'Der PDF-Export dauerte zu lange und wurde beendet.';

  @override
  String get pdfExportFailed =>
      'BusyMark konnte dieses Dokument nicht als PDF exportieren.';

  @override
  String get visualizationRendering => 'Wird gerendert…';

  @override
  String get visualizationStale => 'Letzte gültige Darstellung wird angezeigt';

  @override
  String get visualizationShowSource => 'Quelltext anzeigen';

  @override
  String get visualizationShowRender => 'Darstellung anzeigen';

  @override
  String get visualizationFitWidth => 'An Breite anpassen';

  @override
  String get visualizationSaveImage => 'Bild speichern';

  @override
  String get visualizationCopyImage => 'Bild kopieren';

  @override
  String get visualizationImageCopied => 'Bild kopiert';

  @override
  String get visualizationOpenApiReference => 'API-Referenz öffnen';

  @override
  String get visualizationValid => 'Gültig';

  @override
  String get visualizationInvalid => 'Ungültig';

  @override
  String get visualizationServers => 'Server';

  @override
  String get visualizationPaths => 'Pfade';

  @override
  String get visualizationOperations => 'Operationen';

  @override
  String get visualizationTags => 'Schlagwörter';

  @override
  String get visualizationNoOperations => 'Keine passenden Operationen';

  @override
  String get visualizationSearchOperations => 'Operationen durchsuchen';

  @override
  String get visualizationRenderFailed =>
      'Diese Visualisierung konnte nicht gerendert werden.';

  @override
  String get visualizationRetry => 'Erneut versuchen';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName gespeichert';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Das aktive Markdown-Dokument als PDF exportieren.';
}
