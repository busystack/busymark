// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Neue Notiz aus aufbewahrtem Text';

  @override
  String get notesAccountThrottled =>
      'Nextcloud hat um eine Pause gebeten. Warte, bevor du die Anmeldung erneut startest.';

  @override
  String get notesSettingsRefreshing =>
      'Notes wird nach der bestätigten Einstellungsänderung aktualisiert';

  @override
  String get notesExportOperationFailed =>
      'Der Export wurde nicht veröffentlicht. Quelle und Ziel prüfen und erneut exportieren.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Die wiederhergestellte Notiz wurde gespeichert, konnte aber nicht geöffnet werden. Ausstehende Editor- oder Eigenschaftsänderungen klären und diese Notiz öffnen.';

  @override
  String get notesSettingsPendingNotes =>
      'Ausstehende Notizen, Konflikte oder ungewisse Erstellungen blockieren diese Änderung. In Notes synchronisieren oder prüfen, dann den erhaltenen Einstellungsentwurf erneut speichern.';

  @override
  String get notesSettingsPendingAttachments =>
      'Ausstehende Anhangsvorgänge blockieren diese Änderung. Anhänge in Notes prüfen, dann den erhaltenen Einstellungsentwurf erneut speichern.';

  @override
  String get notesAccountServerAddress =>
      'Die kanonische HTTPS-Adresse des Nextcloud-Servers verwenden und die Anmeldung neu starten. Adresse oder Weiterleitung konnten nicht verifiziert werden.';

  @override
  String get notesAccountUnsupported =>
      'Notes ist nicht verfügbar oder die API wird nicht unterstützt. Nextcloud Notes mit API-Hauptversion 1 ab Nebenversion 4 aktivieren.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud hat die Zugangsdaten abgelehnt. Das Konto erneut autorisieren oder verbinden.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud hat die Notes-Funktionsprüfung verweigert. Die Serveradministration um Freigabe bitten und erneut versuchen.';

  @override
  String get notesAccountMalformed =>
      'Die Nextcloud-Antwort konnte nicht verifiziert werden. Die Serverinstallation prüfen und die Anmeldung neu starten.';

  @override
  String get notesAccountTimedOut =>
      'Die Anmeldung ist abgelaufen. Erneut starten und im Browser autorisieren.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Der Systembrowser konnte nicht geöffnet werden. Den Standardbrowser prüfen und die Anmeldung neu starten.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud ist nicht erreichbar. Verbindung und Server prüfen und die Anmeldung erneut versuchen.';

  @override
  String get notesAccountRejected =>
      'Nextcloud hat die Funktionsanfrage abgelehnt. Den Serverzugriff mit der Administration prüfen und erneut versuchen.';

  @override
  String get notesAccountFailed =>
      'Die Kontoeinrichtung konnte nicht abgeschlossen werden. Die Anmeldung erneut versuchen.';

  @override
  String get notesTransferSourceChanged =>
      'Die Quelle wurde nach der Prüfung geändert. Die aktuelle Datei erneut prüfen oder einen neuen Schnappschuss erstellen.';

  @override
  String get notesTransferUnreadable =>
      'Die Quelle konnte nicht gelesen werden. Den Datei- oder Ordnerzugriff prüfen und erneut einlesen.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Der Schnappschuss ist ungültig oder wird nicht unterstützt. Einen gültigen BusyMark-Notes-Schnappschuss oder eine Markdown-Quelle wählen.';

  @override
  String get notesTransferMediaLimit =>
      'Medien überschreiten das Importlimit. Die Medien des betroffenen Eintrags verkleinern und erneut prüfen.';

  @override
  String get notesTransferUnsafeSource =>
      'Die Quelle enthält einen unsicheren Pfad. Dateien innerhalb des Quellordners wählen und erneut prüfen.';

  @override
  String get notesTransferDestination =>
      'Der Export konnte nicht geschrieben werden. Zugriff und freien Speicher am Ziel prüfen und erneut exportieren.';

  @override
  String get notesTransferOperationFailed =>
      'Die Übertragung ist fehlgeschlagen. Betroffene Einträge prüfen und erneut versuchen. Bereits importierte Einträge bleiben gespeichert.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Export mit Auslassungen verfügbar';

  @override
  String get notesBatchUnchanged =>
      'Die angeforderten Werte waren bereits gesetzt.';

  @override
  String get notesBatchReadOnly =>
      'Diese Notiz ist schreibgeschützt. Geschützte Eigenschaften können nicht geändert werden; Favorit bleibt erlaubt.';

  @override
  String get notesBatchReviewChanged =>
      'Diese Notiz wurde nach der Prüfung geändert. Vor einem erneuten Versuch den aktuellen Stand prüfen.';

  @override
  String get notesBatchMissing =>
      'Diese Notiz ist nicht mehr verfügbar. Die Liste aktualisieren und die Ziele erneut prüfen.';

  @override
  String get notesBatchStorage =>
      'Lokales Speichern fehlgeschlagen. Speicher prüfen und diesen Eintrag erneut versuchen; erfolgreiche Einträge bleiben gespeichert.';

  @override
  String get notesRemoteReviewChanged =>
      'Die Servernotiz wurde geändert. Der Zusammenführungsentwurf bleibt erhalten. Den neuen Vergleich prüfen und die Auflösung erneut wählen.';

  @override
  String get notesReviewRemote => 'Ich habe die aktuelle Serverversion geprüft';

  @override
  String get wsModuleCapsNotPublished =>
      'Modul-Großschreibung wird nicht veröffentlicht.';

  @override
  String get wsTitleOverridesAction => 'Instanz- und Inhaltsverzeichnistitel…';

  @override
  String get wsHeadingNotPublished =>
      'Wird von diesem Builder nicht veröffentlicht.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Der festgelegte Builder veröffentlicht keine instanzspezifischen Titel in Markdown-Themen. Bestehendes Markup bleibt erhalten; prüfen Sie es im Quelltext.';

  @override
  String get wsTopicIdentity => 'Themen-ID';

  @override
  String get wsElementAnchor => 'Elementanker';

  @override
  String get wsHeadingText => 'Überschriftentext';

  @override
  String get wsDefaultTitle => 'Standardtitel';

  @override
  String get wsTopicNavigation => 'Themennavigation';

  @override
  String get wsHeadingOptions => 'Überschriftenattribute';

  @override
  String get wsDocumentOptions => 'Dokumenteinstellungen';

  @override
  String get wsSettingsPresent => 'Explizite Einstellungen vorhanden';

  @override
  String get wsTitleOverrideExplanation =>
      'Überschreibt den veröffentlichten Titel; der Überschriftentext bleibt erhalten.';

  @override
  String get wsIgnoreVariables => 'Variablentext wörtlich behandeln';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Bei Aktivierung wird variablenähnlicher Text nicht ersetzt.';

  @override
  String get wsInstanceSelection => 'Hilfeinstanzen';

  @override
  String get wsInstanceExplanation =>
      'Hilfeausgaben über Namen, Gruppen, Listen, Ausschlüsse oder Ausdrücke auswählen.';

  @override
  String get wsFilterExplanation =>
      'Wiederverwendbare Inhalte nach Kriterien filtern; dies wählt keine Hilfeinstanz aus.';

  @override
  String get wsContextHelp => 'Kontexthilfe-ID';

  @override
  String get wsCapitalization => 'Groß- und Kleinschreibung';

  @override
  String get wsLibraryTopic => 'Bibliotheksthema';

  @override
  String get wsLastModified => 'Zuletzt geändert';

  @override
  String get wsMissingTopicHeading =>
      'Keine Themenüberschrift H1 vorhanden. Fügen Sie sie im Quelltext hinzu.';

  @override
  String get wsMultipleTopicHeadings =>
      'Die erste H1 bestimmt den Thementitel. Weitere H1 sind eigene Überschriften.';

  @override
  String get wsTopicIdentityMismatch =>
      'Die Root-ID weicht von der dateibasierten Themen-ID ab. Verwenden Sie Thema umbenennen oder den Quelltext.';

  @override
  String get wsUnsupportedProperties =>
      'Nicht unterstützte Attribute bleiben erhalten. Prüfen Sie sie im Quelltext.';

  @override
  String get wsGeneratedAnchor =>
      'Generierter Anker; ein eingegebener Wert erstellt eine Überschreibung.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Der festgelegte Builder veröffentlicht keine H1-Attribute. Sie gehören zur Überschrift, nicht zur XML-Root.';

  @override
  String get closeOtherTabs => 'Andere Tabs schließen';

  @override
  String get tocTopicFromTemplate => 'Thema aus Vorlage...';

  @override
  String get tocSaveAsTemplate => 'Als Vorlage speichern';

  @override
  String get tocTemplateDialog => 'Thema aus Vorlage erstellen';

  @override
  String get tocTemplatesEditor => 'Datei- und Codevorlagen';

  @override
  String get tocEditTemplates => 'Vorlagen bearbeiten...';

  @override
  String get tocCreateCustomTemplate => 'Eigene Vorlage erstellen...';

  @override
  String get tocTemplateCreated => 'Vorlage erstellt';

  @override
  String get tocTemplateDefault => 'Standard';

  @override
  String get tocTemplateCustom => 'Benutzerdefiniert';

  @override
  String get tocTemplateFilename => 'Dateiname:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Intern';

  @override
  String get tocTemplateUnnamed => 'Unbenannt';

  @override
  String get tocTemplateNew => 'Neue Vorlage...';

  @override
  String get tocTemplateName => 'Name:';

  @override
  String get tocTemplateExtension => 'Erweiterung:';

  @override
  String get tocTemplateLoadError =>
      'Vorlagen konnten nicht geladen werden. Bestehende Vorlagen wurden nicht geändert.';

  @override
  String get tocTemplateSaveError =>
      'Vorlagen konnten nicht gespeichert werden. Ihre Änderungen sind hier noch verfügbar.';

  @override
  String get tocTemplateConflict =>
      'Vorlagen wurden in einem anderen Fenster geändert. Brechen Sie ab und öffnen Sie den Editor erneut.';

  @override
  String get tocTemplateDuplicateName =>
      'Eine Vorlage mit diesem Namen und dieser Erweiterung existiert bereits.';

  @override
  String get tocTemplateFormat => 'Format:';

  @override
  String get tocTemplateReset => 'Zurücksetzen';

  @override
  String get tocTemplateRetry => 'Erneut versuchen';

  @override
  String tocRemoveElementsDialog(int count) {
    return '$count Inhaltsverzeichniselemente entfernen';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Die mit diesen Inhaltsverzeichniselementen verknüpften Quelldateien werden nicht gelöscht.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Thema zum Hinzufügen zur aktuellen Instanz auswählen';

  @override
  String get tocGroupName => 'Gruppenname';

  @override
  String get tocMoveLineUp => 'Zeile nach oben verschieben';

  @override
  String get tocMoveLineDown => 'Zeile nach unten verschieben';

  @override
  String get tocEmptyMdTopic => 'Leeres MD-Thema';

  @override
  String get tocEmptyXmlTopic => 'Leeres XML-Thema';

  @override
  String get tocCopySpecial => 'Speziell kopieren';

  @override
  String tocCopyFileName(String name) {
    return 'Themendateiname \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Themendateipfad';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Thementitel \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID des Inhaltsverzeichniselements \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Themendateiname';

  @override
  String get tocCopyTopicTitleUnavailable => 'Thementitel';

  @override
  String get tocCopyElementIdUnavailable => 'ID des Inhaltsverzeichniselements';

  @override
  String get tocEditTitleAction => 'Titel bearbeiten...';

  @override
  String get tocEditTitleDialog => 'Titel bearbeiten';

  @override
  String get tocRemoveElementAction => 'Inhaltsverzeichniselement entfernen...';

  @override
  String get tocSetHomePage => 'Als Startseite festlegen';

  @override
  String tocGoToElement(String fileName) {
    return 'Zum Inhaltsverzeichniselement in \'$fileName\' wechseln';
  }

  @override
  String get tocSynchronize => 'Inhaltsverzeichnis und Editor synchronisieren';

  @override
  String get tocEmptyGroupAction => 'Leere Gruppe';

  @override
  String get tocNewEmptyGroup => 'Neue leere Gruppe';

  @override
  String get tocGroupAction => 'Gruppieren';

  @override
  String get tocNewGroup => 'Neue Gruppe';

  @override
  String get tocSortChildren => 'Untergeordnete Themen alphabetisch sortieren';

  @override
  String get tocLinkTopicFiles =>
      'Themendateien mit Inhaltsverzeichnis verknüpfen...';

  @override
  String get addLocalMarkdownFiles => 'Lokale Markdown-Dateien hinzufügen';

  @override
  String get tocTitleField => 'Inhaltsverzeichnistitel:';

  @override
  String get tocTopicTitleField => 'Thementitel:';

  @override
  String get tocAdvancedSettings => 'Erweiterte Einstellungen';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Titel für \'$instanceId\':';
  }

  @override
  String get tocOnlyTitleField =>
      'Nur im Inhaltsverzeichnis verwendeter Titel:';

  @override
  String get tocInstanceTitleExplanation =>
      'Wird nur für die aktuelle Instanz verwendet. Standardmäßig vom Thementitel übernommen.';

  @override
  String get tocOnlyTitleExplanation =>
      'Wird nur im Inhaltsverzeichnis verwendet. Standardmäßig vom Thementitel oder, falls gesetzt, vom instanzspezifischen Titel übernommen. Erläuterungen zu Titeln finden Sie';

  @override
  String get tocTitleDocumentationLink => 'hier';

  @override
  String get tocFindUsages => 'Suchen';

  @override
  String get tocRefactorMenu => 'Refaktorieren';

  @override
  String get tocSafeDelete => 'Sicher löschen';

  @override
  String get tocDuplicate => 'Duplizieren';

  @override
  String get tocDuplicateFilename => 'Themendateiname:';

  @override
  String get tocDuplicateDialog => 'Thema duplizieren';

  @override
  String get pdfTitlePage => 'Titelseite';

  @override
  String get pdfIncludeTitlePage => 'Titelseite einschließen';

  @override
  String get pdfTitlePageNote =>
      'Diese Seite hat keine Kopfzeile, Fußzeile oder sichtbare Seitenzahl.';

  @override
  String get pdfTitlePageTitle => 'Titel';

  @override
  String get pdfTitlePageSubtitle => 'Untertitel';

  @override
  String get pdfTitlePageAuthor => 'Autor';

  @override
  String get pdfTitlePageOrganization => 'Organisation';

  @override
  String get pdfTitlePageVersion => 'Version';

  @override
  String get pdfTitlePageDate => 'Datum';

  @override
  String get pdfTitlePageTitleRequired =>
      'Geben Sie einen Titel für die Titelseite ein.';

  @override
  String get pdfTocSectionNote =>
      'Beginnt auf einer separaten Seite und kann mehrere Seiten umfassen.';

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
  String get copyPlainText => 'Als Nur-Text kopieren';

  @override
  String get clipboardCopyFailed =>
      'Die Auswahl konnte nicht in die Zwischenablage kopiert werden.';

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
  String get promoteSection => 'Abschnitt hochstufen';

  @override
  String get demoteSection => 'Abschnitt herabstufen';

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
  String get commandUnavailableInContext =>
      'Dieser Befehl ist im aktuellen Kontext nicht verfügbar.';

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
  String get reading => 'Leseansicht';

  @override
  String get removeFromRecent => 'Aus „Zuletzt verwendet“ entfernen';

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
  String get shortcutNewDocument => 'Erstellen';

  @override
  String get shortcutNewDocumentDescription =>
      'Markdown-Datei oder Writerside-Projekt erstellen';

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
      'Tastenkürzel der Anwendung anpassen';

  @override
  String get shortcutSyntaxReferenceDescription => 'Syntaxreferenz öffnen';

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
  String get wordWrapDescription =>
      'Lange Zeilen an die Breite des Editors anpassen, anstatt horizontal zu scrollen.';

  @override
  String get editorFontSize => 'Schriftgröße des Editors';

  @override
  String get validateOnEdit => 'Bei Bearbeitung validieren';

  @override
  String get clearRecentWorkspaces => 'Zuletzt verwendete Einträge löschen';

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
  String get settingsEditingButtonsSectionTitle => 'Bearbeitungsschaltflächen';

  @override
  String get spellingDictionaries => 'Rechtschreibwörterbücher';

  @override
  String get spellingDictionariesDescription =>
      'Rechtschreibwörterbücher installieren und verwalten';

  @override
  String get settingsDictionariesSectionTitle => 'Wörterbücher';

  @override
  String get availableSpellingDictionaries => 'Verfügbare Wörterbücher';

  @override
  String get customSpellingDictionaries => 'Benutzerdefinierte Wörterbücher';

  @override
  String get spellingDictionaryProblems => 'Wörterbuchprobleme';

  @override
  String get settingsWindowSectionTitle => 'Fenster';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Vorherigen Arbeitsbereich beim Start erneut öffnen';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Arbeitsbereich und Tabs der vorherigen Sitzung beim Start von BusyMark öffnen.';

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
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Dokumente haben ungespeicherte Änderungen. Speichern Sie diese vor dem Fortfahren.',
      one:
          '1 Dokument hat ungespeicherte Änderungen. Speichern Sie es vor dem Fortfahren.',
    );
    return '$_temp0';
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
  String get video => 'Video';

  @override
  String get openVideo => 'Video abspielen';

  @override
  String get pauseVideo => 'Video pausieren';

  @override
  String get videoUnavailable => 'Video nicht verfügbar';

  @override
  String get videoPreview => 'Videovorschau';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Dem Video fehlt das src-Attribut.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Nicht unterstützte Videoquelle: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Videodatei ist nicht vorhanden: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Videovorschaubild ist nicht vorhanden: $preview';
  }

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
  String get insertBlankLine => 'Leerzeile einfügen';

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
  String get tableAlignmentUnspecified => 'Ausrichtung: Nicht festgelegt';

  @override
  String get tableAlignmentLeft => 'Ausrichtung: Links';

  @override
  String get tableAlignmentCenter => 'Ausrichtung: Mitte';

  @override
  String get tableAlignmentRight => 'Ausrichtung: Rechts';

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
  String get newSiblingTopic => 'Neues Thema';

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
  String get removeTocElements => 'Inhaltsverzeichniselemente entfernen';

  @override
  String get reviewUsages => 'Verwendungen prüfen';

  @override
  String get deleteTopicFile => 'Themendatei löschen';

  @override
  String get removeAction => 'Entfernen';

  @override
  String topicRemovalSummary(String topic) {
    return 'Inhaltsverzeichniseintrag „$topic“ entfernen? Die zugehörige Quelldatei wird nicht gelöscht.';
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
  String get topicIsHomePageRemovalWarning =>
      'Dieses Thema ist die Startseite dieser Instanz. Wählen Sie eine andere Startseite, bevor Sie es aus dem Inhaltsverzeichnis entfernen.';

  @override
  String get newHomePage => 'Neue Startseite';

  @override
  String get chooseHomePage => 'Startseite auswählen';

  @override
  String get noHomePageReplacement =>
      'Fügen Sie dieser Instanz ein anderes geeignetes Thema hinzu oder verknüpfen Sie es, bevor Sie ihre Startseite entfernen.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Dieses Thema ist die Startseite einer Instanz. Legen Sie eine andere Startseite fest, bevor Sie seine Quelldatei löschen.';

  @override
  String topicUsagesCount(int count) {
    return '$count Verwendungen gefunden.';
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
  String get setRedirectTo => 'Weiterleiten an:';

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
  String get preview => 'Vorschau';

  @override
  String get topicRenamePreviewTitle => 'Umbenennungsvorschau';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Pfad: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'Themen-ID: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instanz $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Betroffene Dateien';

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
  String get sourceSearchReplacement => 'Ersetzen durch';

  @override
  String get sourceSearchReplaceCurrent => 'Aktuellen Treffer ersetzen';

  @override
  String get sourceSearchReplaceAndFindNext => 'Ersetzen und weitersuchen';

  @override
  String get sourceSearchReplaceAll => 'Alle ersetzen';

  @override
  String get workspaceReplace => 'Im Arbeitsbereich ersetzen';

  @override
  String get reviewReplacements => 'Ersetzungen prüfen';

  @override
  String get applyReplacements => 'Ersetzungen anwenden';

  @override
  String get skippedFiles => 'Übersprungene Dateien';

  @override
  String get workspaceReplaceDirtyBuffer => 'Ungespeicherter Editorinhalt';

  @override
  String get workspaceReplaceDiskContent => 'Gespeicherter Festplatteninhalt';

  @override
  String selectFileMatches(int count) {
    return 'Alle $count Treffer auswählen';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$matches Treffer in $files Dateien ersetzt; $skipped übersprungen.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Abschließender Zeilenumbruch';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Kein abschließender Zeilenumbruch';
  }

  @override
  String get normalizeLineEndings => 'Zeilenenden normalisieren';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Dieses Dokument enthält gemischte Zeilenenden. Wählen Sie ein Format.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName verwendet gemischte Zeilenenden. Wählen Sie vor dem Ersetzen das gewünschte Format.';
  }

  @override
  String get workspaceReplaceIssueOversized =>
      'Eine zu große Datei wurde übersprungen.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Eine nicht lesbare Datei wurde übersprungen.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Eine Datei ohne gültige UTF-8-Codierung wurde übersprungen.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Die Ersetzungsvorschau wurde gekürzt.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Eine Datei, die sich nach der Vorschau geändert hat, wurde übersprungen.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Ein Editorpuffer, der sich nach der Vorschau geändert hat, wurde übersprungen.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Wählen Sie vor dem Ersetzen die Normalisierung auf LF oder CRLF.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Das Zurücksetzen wurde abgebrochen, da die Datei gleichzeitig geändert wurde. Einige Ersetzungen können bestehen bleiben; verdrängte Inhalte wurden unter dem folgenden Pfad gesichert.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Es wurden keine Ersetzungen vorgenommen, da die geprüfte Auswahl nicht sicher gespeichert werden konnte.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Externe Änderungen — $fileName';
  }

  @override
  String get externalFileDeleted =>
      'Diese Datei wurde auf dem Datenträger gelöscht.';

  @override
  String get externalFileChanged =>
      'Diese Datei wurde auf dem Datenträger geändert, während ungespeicherte Änderungen vorliegen.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Ungespeicherter Inhalt für $fileName wurde wiederhergestellt. Prüfen Sie ihn und speichern Sie ihn, speichern Sie ihn unter einem neuen Namen oder verwerfen Sie ihn.';
  }

  @override
  String get compare => 'Vergleichen';

  @override
  String get reloadFromDisk => 'Vom Datenträger neu laden';

  @override
  String get keepMine => 'Meine Version behalten';

  @override
  String get saveAs => 'Speichern unter';

  @override
  String get workspaceSearchIncomplete =>
      'Es wird nur ein Teil der Ergebnisse angezeigt. Zeigen Sie mehr an oder grenzen Sie die Suche ein.';

  @override
  String get workspaceSearchShowMore => 'Weitere Ergebnisse anzeigen';

  @override
  String get workspaceSearchSkippedFiles =>
      'Die Suche ist unvollständig. Diese Dateien sind größer als 1 MiB oder konnten nicht gelesen werden:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Große Datei: Hervorhebung und Faltung sind pausiert';

  @override
  String get nothingToRead => 'Nichts zu lesen';

  @override
  String get admonition => 'Hinweisblock';

  @override
  String get quote => 'Zitat';

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
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Zuletzt verwendete Elemente konnten nicht aktualisiert werden: $error.';
  }

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
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht gespeicherte Dokumente wiederhergestellt. Überprüfen Sie jedes wiederhergestellte Dokument vor dem Speichern oder Verwerfen.',
      one:
          '1 nicht gespeichertes Dokument wiederhergestellt. Überprüfen Sie es vor dem Speichern oder Verwerfen.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count beschädigte Wiederherstellungsdatensätze konnten nicht wiederhergestellt werden. Die gültigen Wiederherstellungsdatensätze bleiben verfügbar.',
      one:
          'Ein beschädigter Wiederherstellungsdatensatz konnte nicht wiederhergestellt werden. Die Originaldatei der Wiederherstellung wurde zur Überprüfung aufbewahrt.',
    );
    return '$_temp0';
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
      'Das Writerside-Modul enthält keinen Instanzbaum.';

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
    return 'Die Startseite $topic kann nicht gelöscht werden. Wählen Sie zuerst eine andere Startseite.';
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
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Die Umbenennung kann nicht alle Projektverweise sicher aktualisieren, da $count Themendatei(en) im Modul $module nicht analysiert wurden: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Writerside-Projektdateien enthalten ungespeicherte Änderungen. Beheben Sie diese und erstellen Sie eine neue Umbenennungsvorschau.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Die Modulgruppe des Writerside-Projekts wurde geändert. Erstellen Sie vor dem Refactoring eine neue Umbenennungsvorschau.';

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
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Instanz \"$instanceId\" veröffentlicht den ungültigen Webdateinamen \"$webFileName\" für das Thema \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Instanz \"$instanceId\" veröffentlicht sowohl \"$firstTopic\" als auch \"$secondTopic\" unter \"$webFileName\".';
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
  String get gitActions => 'Git-Aktionen';

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
  String get gitNewBranch => 'Neuer Branch';

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
          'Alle vorgemerkten und nicht vorgemerkten Änderungen der ausgewählten versionierten Dateien werden auf HEAD zurückgesetzt.',
      one:
          'Alle vorgemerkten und nicht vorgemerkten Änderungen der ausgewählten versionierten Datei werden auf HEAD zurückgesetzt.',
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
  String get gitProjectHistory => 'Projektverlauf';

  @override
  String get gitFileHistory => 'Dateiverlauf';

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
  String get gitCommitActions => 'Commit-Aktionen';

  @override
  String get gitResetCurrentBranchToHere =>
      'Aktuellen Branch hierher zurücksetzen…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '$branch auf $commit zurücksetzen?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Dadurch wird der Branch $branch auf den Commit $commit verschoben. Wählen Sie aus, wie Git den Index und das Arbeitsverzeichnis aktualisiert.';
  }

  @override
  String get gitReset => 'Zurücksetzen';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Nur den Branch verschieben. Index und Arbeitsverzeichnis bleiben unverändert; Unterschiede zum ausgewählten Commit bleiben vorgemerkt.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Den Branch verschieben und den Index zurücksetzen. Das Arbeitsverzeichnis bleibt unverändert; Unterschiede bleiben nicht vorgemerkt.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Branch, Index und Arbeitsverzeichnis zurücksetzen. Änderungen an verfolgten Dateien werden verworfen; blockierende nicht verfolgte Dateien können gelöscht werden.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Den Branch und verfolgte Dateien zurücksetzen, lokale Änderungen aber beibehalten. Git bricht ab, wenn diese Änderungen dem Zurücksetzen entgegenstehen.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Dateiaktionen';

  @override
  String get actions => 'Aktionen';

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
  String get gitErrorResetDirtyWorkspace =>
      'Speichern oder verwerfen Sie Änderungen im BusyMark-Editor, bevor Sie den aktuellen Branch zurücksetzen.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Entfernen Sie die Datei aus dem Index, bevor Sie eine frühere Version wiederherstellen.';

  @override
  String get gitErrorResetDetachedHead =>
      'Checken Sie vor dem Zurücksetzen einen Branch aus.';

  @override
  String get gitErrorDiverged =>
      'Der Branch ist auseinandergelaufen. Führen Sie Merge oder Rebase außerhalb dieser BusyMark-Version aus.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git benötigt vor dem Commit einen Autorennamen und eine E-Mail-Adresse.';

  @override
  String get gitAuthorIdentityTitle => 'Git-Autorenidentität';

  @override
  String get gitAuthorIdentityMessage =>
      'Geben Sie die Identität ein, die Git in Commits eintragen soll. BusyMark speichert sie und wiederholt diesen Commit.';

  @override
  String get gitAuthorName => 'Autorenname';

  @override
  String get gitAuthorEmail => 'E-Mail';

  @override
  String get gitAuthorIdentityGlobal => 'Für alle Repositorys verwenden';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Bei einer Snap-Installation gilt dies für Repositorys, die in BusyMark geöffnet werden.';

  @override
  String get gitSaveIdentityAndCommit => 'Speichern und committen';

  @override
  String get gitErrorAuthentication => 'Git-Authentifizierung fehlgeschlagen.';

  @override
  String get gitErrorNetwork => 'Git-Netzwerkvorgang fehlgeschlagen.';

  @override
  String get gitErrorConflict => 'Git hat ungelöste Konflikte gemeldet.';

  @override
  String get gitErrorCommandFailed => 'Git-Befehl fehlgeschlagen.';

  @override
  String get syntaxReference => 'Syntaxreferenz';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown-Blöcke';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Blockstrukturen, die in Markdown-Quelltext und Vorschau unterstützt werden.';

  @override
  String get syntaxReferenceInlineFormatting => 'Inline-Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatierung innerhalb von Absätzen, Listeneinträgen und Tabellenzellen.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Roh-HTML-Blöcke';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Sichere HTML-Blocktags, die über BusyMark-Vorschauwidgets gerendert werden.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Roh-HTML-Inline-Tags';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Sichere Inline-HTML-Tags, die ohne sichtbare Tags gerendert werden.';

  @override
  String get syntaxReferenceHeadings => 'Überschriften';

  @override
  String get syntaxReferenceParagraphs => 'Absätze';

  @override
  String get syntaxReferenceLists => 'Listen';

  @override
  String get syntaxReferenceHtmlContainers => 'Container';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Textblöcke';

  @override
  String get syntaxReferenceHtmlFigures => 'Abbildungen und Bilder';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Vorformatierter Code';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Aufklappblöcke';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Beschreibungslisten';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Formatierungstags';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Inline-Code-Tags';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Semantische Texttags';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'Erlaubtes HTML wird in BusyMark-Vorschaublöcke umgewandelt, nicht im Browser gerendert.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Unverändertes Roh-HTML wird exakt als Quelltext gespeichert.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Markdown-Zeichen innerhalb von Roh-HTML werden als normaler Text angezeigt.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Skripte, Styles, Frames, Formulare, SVG, MathML, Events und unsichere Attribute werden blockiert.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Links erlauben http, https, mailto, tel, relative URLs und Fragmente; unsichere URL-Schemata werden blockiert.';

  @override
  String get syntaxReferenceCategory => 'Kategorie';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramme und API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Mathematik';

  @override
  String get syntaxReferenceExample => 'Beispiel';

  @override
  String get syntaxReferenceIdentifiers => 'Bezeichner und Aliase';

  @override
  String get syntaxReferenceScope => 'Geltungsbereich';

  @override
  String get syntaxReferenceLimitation => 'BusyMark-Einschränkung';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Offizielle Dokumentation';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Nur Writerside-Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Nur Writerside-Markdown und Writerside-XML';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Die grundlegenden Markdown-Formen, die BusyMark erstellen und in der Vorschau anzeigen kann.';

  @override
  String get syntaxReferenceParagraphExample => 'Ein Textabsatz.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabellen verwenden die Pipe-Syntax von GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'zwei Leerzeichen am Zeilenende, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark akzeptiert eine gezielte sichere Teilmenge von Roh-HTML in Markdown-Quelltext.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Eingezäunte Mermaid-, PlantUML-, D2- und OpenAPI-Blöcke funktionieren in Markdown-Quelltext. Fence-Bezeichner unterscheiden nicht zwischen Groß- und Kleinschreibung; BusyMark bewahrt die ursprüngliche Schreibweise.';

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
      'Verwenden Sie eingezäunten YAML- oder JSON-Inhalt. BusyMark behandelt ein beliebiges vollständiges YAML- oder JSON-Dokument nicht als OpenAPI-Referenz.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Semantische Diagramm-Codeblöcke';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Semantische code-block- und src-Formen unterstützen Mermaid, PlantUML und D2, nicht OpenAPI, und nur in Writerside-Projekten.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Referenzierte Diagrammquelle';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Pfade müssen relativ sein und im geöffneten Writerside-Projekt bleiben; die Kombination aus Fence und src gilt nur für Writerside-Markdown.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark unterstützt TeX-Ausdrücke, keine vollständigen TeX- oder LaTeX-Dokumente.';

  @override
  String get syntaxReferenceInlineMath => 'Mathematik im Text';

  @override
  String get syntaxReferenceGithubMath =>
      'GitHub-Mathematik mit Dollarzeichen und Backticks';

  @override
  String get syntaxReferenceDisplayMath => 'Mathematische Formel als Block';

  @override
  String get syntaxReferenceMathFence => 'math-Fence';

  @override
  String get syntaxReferenceTexFence => 'tex-Fence';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark erkennt \\(...\\) und \\[...\\] nicht als Markdown-Mathematikbegrenzer.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Außerhalb des Writerside-Modus bleibt ein tex-Fence ein gewöhnlicher Codeblock.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside-math-Element';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'Das math-Element ist semantische Writerside-Syntax und kein zulässiges rohes HTML-MathML.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Semantischer TeX-Codeblock';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Diese gezielten Erweiterungen werden nur in geöffneten Writerside-Projekten interpretiert.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Hinweis-Blockzitat';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Ein einfaches Blockzitat ist in Writerside-Markdown ein Tipp; in normalem Markdown bleibt es ein gewöhnliches Zitat.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Semantische Hinweise';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Normales Markdown interpretiert diese semantischen Writerside-Elemente nicht.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Einklappbare Überschrift';

  @override
  String get syntaxReferenceCollapsibleCode => 'Einklappbarer Code-Fence';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Semantische einklappbare Inhalte';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark unterstützt einklappbare Kapitel-, Prozedur-, code-block- und Definitionslistenformen, nicht den vollständigen Writerside-Katalog.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Semantische Codeblöcke für Mathematik und Diagramme';

  @override
  String get syntaxReferenceVideo => 'Writerside-Video';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Lokale Videos verwenden ein lokales preview-src-Bild; gehostete Videoquellen müssen unterstützte HTTPS-URLs von YouTube oder Vimeo sein.';

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
  String get exportFormat => 'Ausgabeformat';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Warnungen',
      one: '1 Warnung',
    );
    return '$fileName wurde mit $_temp0 exportiert.';
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
      'Das aktive Dokument oder Writerside-Modul als PDF exportieren.';

  @override
  String get instances => 'Instanzen';

  @override
  String get newInstance => 'Neue Instanz';

  @override
  String get newTocLibrary => 'Neue TOC-Bibliothek';

  @override
  String get editInstance => 'Instanz bearbeiten';

  @override
  String get openTocFile => 'Inhaltsverzeichnisdatei öffnen';

  @override
  String get createInstance => 'Instanz erstellen';

  @override
  String get createTocLibrary => 'TOC-Bibliothek erstellen';

  @override
  String get instanceContent => 'Inhalt';

  @override
  String get instanceContentSource => 'Erstellen aus';

  @override
  String get emptyInstance => 'Leere Instanz';

  @override
  String get markdownFiles => 'Lokale Markdown-Dateien';

  @override
  String get chooseMarkdownFolder => 'Markdown-Ordner auswählen';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Wählen Sie einen Ordner mit Markdown-Dateien aus.';

  @override
  String get instanceAppearance => 'Darstellung';

  @override
  String get instanceColor => 'Symbolfarbe';

  @override
  String get instanceVersion => 'Version';

  @override
  String instanceVersionInherited(String version) {
    return 'Wenn dieses Feld leer ist, wird die Projektversion $version verwendet.';
  }

  @override
  String get instanceWebPath => 'Webpfad';

  @override
  String get instanceStatus => 'Status';

  @override
  String get instanceStatusRelease => 'Veröffentlichung';

  @override
  String get instanceStatusEap => 'Early Access';

  @override
  String get instanceStatusDeprecated => 'Veraltet';

  @override
  String get allowSearchEngineIndexing =>
      'Indizierung durch Suchmaschinen zulassen';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Externen Suchmaschinen erlauben, diese Ausgabe zu indizieren.';

  @override
  String get offlineArtifact => 'Offline-Artefakt';

  @override
  String get offlineArtifactDescription =>
      'Ressourcen bündeln, damit die erstellte Dokumentation eigenständig ist.';

  @override
  String get instanceOutputSettings => 'Ausgabeeinstellungen';

  @override
  String get markdownImportSource => 'Markdown-Quelle';

  @override
  String get markdownImportFiles => 'Markdown-Dateien';

  @override
  String get selectNone => 'Keine auswählen';

  @override
  String markdownFilesFound(int count) {
    return '$count Markdown-Datei(en) gefunden';
  }

  @override
  String get noMarkdownFilesFound =>
      'In diesem Verzeichnis wurden keine Markdown-Dateien gefunden.';

  @override
  String get copyReferencedMedia => 'Referenzierte Medien kopieren';

  @override
  String get copyReferencedMediaDescription =>
      'Lokale Bilder und Videos der ausgewählten Dateien unter Beibehaltung relativer Pfade kopieren.';

  @override
  String get instanceIdRenameWarningTitle => 'Instanz-ID umbenennen?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark benennt die .tree-Datei um und aktualisiert Writerside-Projektreferenzen von „$oldId“ zu „$newId“. Veröffentlichungsskripte werden nicht geändert und müssen separat aktualisiert werden.';
  }

  @override
  String get renameAndUpdateReferences =>
      'Umbenennen und Referenzen aktualisieren';

  @override
  String get tocLibraryDescription =>
      'Eine TOC-Bibliothek speichert wiederverwendbare Abschnitte und erzeugt keine eigene Ausgabe.';

  @override
  String get defaultTocLibraryName => 'Gemeinsames TOC';

  @override
  String get instanceColorAutomatic => 'Automatisch';

  @override
  String get instanceColorBlue => 'Blau';

  @override
  String get instanceColorGreen => 'Grün';

  @override
  String get instanceColorOrange => 'Orange';

  @override
  String get instanceColorPurple => 'Violett';

  @override
  String get instanceColorRed => 'Rot';

  @override
  String get instanceColorTeal => 'Türkis';

  @override
  String get instanceColorYellow => 'Gelb';

  @override
  String get errorWritersideInstanceNameRequired =>
      'Geben Sie einen Instanznamen ein.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Eine Instanz mit der ID „$id“ ist bereits vorhanden.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Der Instanzbaum ist bereits vorhanden: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Das Markdown-Quellverzeichnis ist nicht vorhanden: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Wählen Sie mindestens eine zu importierende Markdown-Datei aus.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Dies ist keine lesbare Markdown-Datei innerhalb der ausgewählten Quelle: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Der Import würde eine vorhandene Projektdatei überschreiben: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Instanzdateien wurden auf dem Datenträger geändert. Prüfen Sie sie und versuchen Sie es erneut.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark konnte die Instanzänderung nicht vollständig zurücknehmen. Prüfen Sie diese Dateien, bevor Sie fortfahren: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Eine TOC-Bibliothek kann keine Markdown-Themen importieren.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Der Webpfad muss aus einer einzigen Zeile bestehen.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Die Writerside-Instanzkonfiguration ist ungültig. Korrigieren Sie die Diagnosen und versuchen Sie es erneut.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark konnte die Instanzänderungen nicht sicher bereitstellen.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Unbekannter Instanzstatus „$status“. Verwenden Sie release, eap oder deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'Die Instanz-ID „$id“ wird von mehreren Baumdateien verwendet.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml muss ein <buildprofiles>-Wurzelelement besitzen.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Der Wert $name „$value“ muss true oder false sein.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Ein <build-profile>-Element muss eine Instanz-ID angeben.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Ein <include> im Baum muss sowohl from als auch element-id angeben.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Ein <snippet> im Baum muss eine id angeben.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Eine instanzübergreifende TOC-Referenz muss sowohl ref als auch in angeben.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Ein TOC-Element kann nicht gleichzeitig auf mehrere Themen, Referenzen, Links oder Weiterleitungen verweisen.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Die Baumelement-ID „$id“ ist mehrfach deklariert.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Die Instanzgruppendatei muss ein <instance-groups>-Wurzelelement besitzen.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Eine Instanzgruppe muss eine nicht leere id und Instanzliste angeben.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Die Instanzgruppen-ID „$id“ ist mehrfach deklariert.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Die TOC-Einbindung „$source#$id“ gehört zum externen Modul „$origin“ und kann in diesem Arbeitsbereich nicht erweitert werden.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Das Baumelement „$id“ ist im registrierten Baum „$source“ nicht vorhanden.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Die Baumeinbindung „$source#$id“ erzeugt einen Zyklus.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Die Instanzbedingung verweist auf die unbekannte Gruppe „@$group“.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Die instanzübergreifende Referenz verweist auf die unbekannte Instanz „$instance“.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Das Thema „$topic“ gehört nicht zur referenzierten Instanz „$instance“.';
  }

  @override
  String get download => 'Herunterladen';

  @override
  String get exportWritersideAsPdf => 'Writerside als PDF exportieren';

  @override
  String get writersidePdfContent => 'Exportinhalt';

  @override
  String get writersidePdfPage => 'Seite';

  @override
  String get exportingWritersidePdf => 'Writerside-PDF wird exportiert…';

  @override
  String get ai => 'KI';

  @override
  String get aiLocalOllama => 'Lokales Ollama';

  @override
  String get aiDisabled => 'Deaktiviert';

  @override
  String get aiExplicitEditingDescription =>
      'KI-Bearbeitung erfolgt nur auf ausdrücklichen Befehl. BusyMark sendet ausschließlich den angezeigten Kontext an den ausgewählten Anbieter und übernimmt keinen Vorschlag ohne Prüfung.';

  @override
  String get aiProvider => 'KI-Anbieter';

  @override
  String get aiDefaultProvider => 'Standardanbieter';

  @override
  String get aiConfigureProvider => 'Anbieter konfigurieren';

  @override
  String get aiChooseProvider => 'KI-Anbieter auswählen';

  @override
  String get aiOllamaEndpoint => 'Ollama-Endpunkt';

  @override
  String get aiOllamaModel => 'Ollama-Modell';

  @override
  String get aiTestConnection => 'Verbindung testen';

  @override
  String get aiTestingConnection => 'Wird getestet…';

  @override
  String aiConnectionReady(int count) {
    return 'Verbunden. $count installierte(s) Modell(e) gefunden.';
  }

  @override
  String get aiNoModels => 'Kein Modell ausgewählt.';

  @override
  String get aiConnectionFailed =>
      'BusyMark konnte die KI-Textgenerierung nicht überprüfen.';

  @override
  String get aiConfigureFirst =>
      'Aktivieren Sie unter Einstellungen → KI einen KI-Anbieter und überprüfen Sie ein Modell.';

  @override
  String get aiEditWithAi => 'Mit KI bearbeiten';

  @override
  String get aiRefineWithAi => 'Mit KI verfeinern';

  @override
  String get aiInstruction => 'Anweisung';

  @override
  String get aiChangeTarget => 'Was geändert werden darf';

  @override
  String get aiSharedContext => 'Mit KI geteilter Kontext';

  @override
  String get aiTargetSelection => 'Ausgewählter Inhalt';

  @override
  String get aiTargetInsertAfterBlock => 'Nach aktuellem Block einfügen';

  @override
  String get aiTargetCurrentBlock => 'Aktueller Block';

  @override
  String get aiTargetCurrentSection => 'Aktueller Abschnitt';

  @override
  String get aiTargetCompleteDocument => 'Gesamtes Dokument';

  @override
  String get aiContextNone => 'Kein Dokumentkontext';

  @override
  String get aiContextSelection => 'Ausgewählter Inhalt';

  @override
  String get aiContextCurrentBlock => 'Aktueller Block';

  @override
  String get aiContextCurrentSection => 'Aktueller Abschnitt';

  @override
  String get aiContextCompleteDocument => 'Gesamtes Dokument';

  @override
  String get aiGenerating => 'Vorschlag wird erstellt…';

  @override
  String get aiProposal => 'KI-Vorschlag';

  @override
  String get aiGenerateProposal => 'Vorschlag erstellen';

  @override
  String aiContextDisclosure(int count) {
    return 'Der ausgewählte Anbieter erhält $count Zeichen aus dem angezeigten Kontext.';
  }

  @override
  String get aiOriginal => 'Originaltext';

  @override
  String get aiSuggested => 'Vorschlag';

  @override
  String get aiApplyProposal => 'Vorschlag anwenden';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input Eingabetoken · $output Ausgabetoken';
  }

  @override
  String get aiStaleProposal =>
      'Das Dokument wurde während der Erstellung dieses Vorschlags geändert. Führen Sie die Aktion erneut aus.';

  @override
  String get gitAiStagedChangesChanged =>
      'Die vorgemerkten Änderungen wurden geändert, während diese Commit-Nachricht erstellt wurde. Führen Sie die Aktion erneut aus.';

  @override
  String get aiViewContext => 'Gesendeten Kontext anzeigen';

  @override
  String get aiReviewExactContent => 'Genaue Inhalte prüfen';

  @override
  String get aiContentToChange => 'Zu ändernder Inhalt';

  @override
  String get aiContentSentToAi => 'An KI gesendeter Inhalt';

  @override
  String get aiApiKey => 'API-Schlüssel';

  @override
  String get aiApiKeyStoredHint =>
      'Ein Schlüssel ist in der systemweiten Anmeldeinformationsverwaltung gespeichert';

  @override
  String get aiApiKeyEnterHint => 'API-Schlüssel des Anbieters eingeben';

  @override
  String get aiReplaceApiKey => 'API-Schlüssel ersetzen';

  @override
  String get aiSaveApiKey => 'API-Schlüssel sicher speichern';

  @override
  String get aiRemoveApiKey => 'Gespeicherten API-Schlüssel entfernen';

  @override
  String get aiCredentialSaved =>
      'Der API-Schlüssel wurde in der systemweiten Anmeldeinformationsverwaltung gespeichert.';

  @override
  String get aiCredentialRemoved =>
      'Der gespeicherte API-Schlüssel wurde entfernt.';

  @override
  String get aiModelRouting => 'Modellauswahl';

  @override
  String get aiAutomaticRouting => 'Automatisch nach Aufgabe';

  @override
  String get aiFixedModelRouting => 'Ausgewähltes Modell verwenden';

  @override
  String get aiPreferredModel => 'Bevorzugtes Modell';

  @override
  String get aiModel => 'Modell';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests Anfragen · $input Eingabetoken · $output Ausgabetoken';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Inhalte an $provider senden?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '$provider aktivieren';
  }

  @override
  String get aiCloudConsentMessage =>
      'Es werden nur Inhalte gesendet, die im jeweiligen KI-Prüfdialog angezeigt werden. Anfragen sind zustandslos, Vorschläge müssen geprüft werden, und der API-Schlüssel wird in der Anmeldeinformationsverwaltung von Linux gespeichert.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Bestätigen Sie zuerst unter Einstellungen → KI die Datenweitergabe an $provider.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Generierung mit $model überprüft. $count kompatible Modelle verfügbar.';
  }

  @override
  String get aiColdStartObserved =>
      'Ein Kaltstart des lokalen Modells wurde erkannt.';

  @override
  String get aiNoCompatibleModels =>
      'Es ist kein kompatibles Modell zur Textgenerierung verfügbar.';

  @override
  String get aiEnableProvider => 'Aktivieren Sie zuerst einen KI-Anbieter.';

  @override
  String get aiDraftCommitMessage => 'Commit-Nachricht entwerfen';

  @override
  String get aiDrafting => 'Entwurf wird erstellt…';

  @override
  String get aiDraftWithAi => 'Mit KI entwerfen';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Auf Überschriftenebene $previousLevel folgt Ebene $level; prüfen Sie die Abschnittsverschachtelung.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Der Linktext ist leer; geben Sie einen zugänglichen Namen an, der den Zweck beschreibt.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Prüfen Sie, ob der Linktext „$text“ seinen Zweck im Kontext beschreibt.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Tabellenüberschriften müssen ihre Spalten bezeichnen; füllen Sie jede leere Überschrift aus.';

  @override
  String get mathRenderFailed =>
      'Der mathematische Ausdruck konnte nicht dargestellt werden.';

  @override
  String get inlineMath => 'Mathematik im Text';

  @override
  String get displayMath => 'Mathematische Formel als Block';

  @override
  String get goToDeclaration => 'Zur Deklaration wechseln';

  @override
  String get findUsages => 'Verwendungen suchen';

  @override
  String get cannotRenameSymbol =>
      'Das Symbol kann nicht sicher umbenannt werden. Prüfen Sie den Namen und aktualisieren Sie die Referenz, bevor Sie es erneut versuchen.';

  @override
  String get renameTopicFileInstead =>
      'Themen-IDs werden aus ihren Dateinamen abgeleitet. Verwenden Sie „Themendatei umbenennen“ im Inhaltsverzeichnis oder in der Seitenleiste „Dateien“.';

  @override
  String get keyboardLayout => 'Tastaturbelegung';

  @override
  String get diagnosticWritersideUnsupported =>
      'Nicht unterstützter oder fehlerhafter Inhalt wird als Quelltext angezeigt.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Quelle „$reference“ kann nicht aufgelöst werden: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Das Linkziel ist in dieser Instanz nicht verfügbar: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Ungültiges Writerside-Markup: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Verwenden Sie <llms-txt>true</llms-txt> oder <llms-txt>false</llms-txt>; single-file wird nicht mehr unterstützt.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return '$kind kann nicht aufgelöst werden: $reference';
  }

  @override
  String get exportAsHtml => 'Als HTML exportieren…';

  @override
  String get fileTypeHtml => 'HTML-Dokument';

  @override
  String get exportingHtml => 'HTML wird exportiert…';

  @override
  String get htmlExported => 'HTML-Export abgeschlossen';

  @override
  String get htmlExportFailed => 'HTML-Export fehlgeschlagen';

  @override
  String get htmlKeepAssetsTogether =>
      'Lassen Sie beim Kopieren die HTML-Datei und den zugehörigen Ressourcenordner zusammen.';

  @override
  String get htmlInstanceDescription =>
      'Exportieren Sie eine Instanz als verknüpfte Offline-Seiten. Wählen Sie einen Namen für einen eigenen Ausgabeordner.';

  @override
  String get htmlInstance => 'Instanz';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Nur ein vom BusyMark-HTML-Export erstellter Ordner kann ersetzt werden. Geänderte oder fremde Dateien bleiben erhalten.';

  @override
  String get showInFolder => 'Im Ordner anzeigen';

  @override
  String sortTableColumn(String column) {
    return '$column sortieren';
  }

  @override
  String get exportReset => 'Auf Standardwerte zurücksetzen';

  @override
  String get exportToc => 'Inhaltsverzeichnis einfügen';

  @override
  String get exportTocDepth => 'Gliederungstiefe';

  @override
  String get exportNumberHeadings => 'Überschriften nummerieren';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Benutzerdefiniert';

  @override
  String get exportPageWidth => 'Seitenbreite (mm)';

  @override
  String get exportPageHeight => 'Seitenhöhe (mm)';

  @override
  String get exportMarginTop => 'Oberer Rand (mm)';

  @override
  String get exportMarginRight => 'Rechter Rand (mm)';

  @override
  String get exportMarginBottom => 'Unterer Rand (mm)';

  @override
  String get exportMarginLeft => 'Linker Rand (mm)';

  @override
  String get exportTypography => 'Typografie';

  @override
  String get exportSans => 'Serifenlos';

  @override
  String get exportSerif => 'Mit Serifen';

  @override
  String get exportBodySize => 'Schriftgröße des Texts';

  @override
  String get exportCodeSize => 'Schriftgröße für Code';

  @override
  String get exportRunningText => 'Kopf- und Fußzeile';

  @override
  String get exportHeader => 'Kopfzeile';

  @override
  String get exportFooter => 'Fußzeile';

  @override
  String get exportNone => 'Keine';

  @override
  String get exportDocumentTitle => 'Dokumenttitel';

  @override
  String get exportBottomLeft => 'Unten links';

  @override
  String get exportBottomCenter => 'Unten mittig';

  @override
  String get exportBottomRight => 'Unten rechts';

  @override
  String get exportFirstPage =>
      'Kopf- und Fußzeile auf der ersten Seite anzeigen';

  @override
  String get exportAccent => 'Akzent-/Linkfarbe';

  @override
  String get exportTheme => 'Design';

  @override
  String get exportAutomatic => 'Automatisch';

  @override
  String get exportLayout => 'Layout';

  @override
  String get exportContentWidth => 'Maximale Inhaltsbreite';

  @override
  String get exportOutput => 'Ausgabe';

  @override
  String get exportPackaging => 'Verpackung';

  @override
  String get exportSingleFile => 'Einzelne HTML-Datei';

  @override
  String get exportAssetsDirectory => 'HTML + Ressourcenordner';

  @override
  String get exportCustomCss => 'Eigenes Stylesheet…';

  @override
  String get exportRemoveCss => 'Eigenes Stylesheet entfernen';

  @override
  String get exportCssNote =>
      'Wählen Sie eine optionale UTF-8-CSS-Datei (bis 256 KiB). Importe, Ressourcen-URLs sowie ausführbares oder maskiertes CSS werden abgelehnt. Die Regeln folgen dem BusyMark-Stylesheet. Entfernte Ressourcen werden nie abgerufen.';

  @override
  String get exportSitePackagingNote =>
      'Writerside behält getrennte, verknüpfte Themenseiten. Der Einzeldateimodus bettet Ressourcen in jede Seite ein.';

  @override
  String get exportInvalidGeometry =>
      'Nach Abzug der Ränder müssen mindestens 20 mm Inhaltsbreite und -höhe bleiben.';

  @override
  String get exportInvalidColor => 'Geben Sie eine Farbe als #RRGGBB ein.';

  @override
  String get exportInvalidCss =>
      'Wählen Sie eine lesbare UTF-8-CSS-Datei bis 256 KiB ohne Importe, Ressourcen-URLs, HTML sowie ausführbares oder maskiertes CSS.';

  @override
  String get clipboardHistory => 'Zwischenablage-Historie';

  @override
  String get clipboardHistoryDescription =>
      'Öffne die Sitzungs-spezifische Zwischenablage-Historie.';

  @override
  String get clipboardCurrent => 'Aktuelle Zwischenablage';

  @override
  String get clipboardCurrentExternal =>
      'Aktuelle Zwischenablage aus einer anderen Anwendung';

  @override
  String clipboardDestination(String name) {
    return 'Einfügen in $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Nur für diese BusyMark-Sitzung gespeichert.';

  @override
  String get clipboardNoItems => 'Zwischenablage-Historie ist leer.';

  @override
  String get clipboardDisabled =>
      'Die Sammlung \"Zwischenablage-Historie\" ist in den Einstellungen deaktiviert.';

  @override
  String get clipboardUnavailable =>
      'Der aktuelle Zwischenablage-Inhalt ist nicht verfügbar oder wird nicht unterstützt.';

  @override
  String get clipboardTooLarge =>
      'Dieses Zwischenablagen-Element ist zu groß, um es zu speichern.';

  @override
  String get clipboardPastePlainText => 'Einfügen als reinen Text';

  @override
  String get clipboardClearAll => 'Löschen der Zwischenablage-Historie';

  @override
  String get clipboardEntryText => 'Textinhalt';

  @override
  String get clipboardEntryRichText => 'Reicher Text';

  @override
  String get clipboardEntryImage => 'Bild';

  @override
  String clipboardOrigin(String name) {
    return 'Kopiert aus $name';
  }

  @override
  String get localHistory => 'Lokale Historie';

  @override
  String get localHistoryEllipsis => 'Lokale Historie…';

  @override
  String get localHistoryDescription =>
      'Zeige gespeicherte und automatische lokale Revisionen für das aktuelle Dokument.';

  @override
  String get findLocalHistoryEllipsis => 'In Lokaler Historie suchen…';

  @override
  String get findLocalHistoryDescription =>
      'Lokale Historie Dokumente und Revisionen durchsuchen.';

  @override
  String get localHistoryNoDocuments =>
      'Es gibt noch keine Dokumente mit Lokaler Historie.';

  @override
  String get localHistoryNoRevisions =>
      'Dieses Dokument hat keine Lokalen Historie Revisionen.';

  @override
  String get localHistorySelectedRevision => 'Ausgewählte Revision';

  @override
  String get localHistoryCurrentEditor => 'Aktueller Editor Inhalt';

  @override
  String get localHistoryCurrentDisk => 'Aktueller Inhalt auf der Festplatte';

  @override
  String get localHistoryMissingFile => 'Die Originaldatei fehlt.';

  @override
  String get localHistoryRestoreRevision => 'Revision Wiederherstellen';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Zur Originalposition Wiederherstellen';

  @override
  String get localHistoryRestoreNewLocation =>
      'Zur neuen Position Wiederherstellen…';

  @override
  String get localHistoryRestoreChange => 'Änderung Wiederherstellen';

  @override
  String get localHistoryRestoreUnavailable =>
      'Diese Änderung kann nicht wiederhergestellt werden, da der Vergleich nicht mehr aktuell ist.';

  @override
  String get localHistoryComparisonSimplified =>
      'Dieser große Vergleich wurde vereinfacht. Einzelne Änderungen können nicht wiederhergestellt werden.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Ältere Revision Änderung: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Aktuelle Inhalt Änderung: $text';
  }

  @override
  String get localHistoryDeleted => 'Gelöscht';

  @override
  String get localHistoryUntitled => 'Unbenannt';

  @override
  String get localHistoryClearDocument =>
      'Löschen Sie den Verlauf dieses Dokuments';

  @override
  String get localHistoryClearAll => 'Löschen Sie den gesamten lokalen Verlauf';

  @override
  String get localHistoryClearDocumentTitle =>
      'Verlauf dieses Dokuments löschen?';

  @override
  String get localHistoryClearAllTitle => 'Verlauf dieses Dokuments löschen?';

  @override
  String get localHistoryClearConfirmation =>
      'Dies entfernt dauerhaft gespeicherte Revisionen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Der lokale Verlauf wurde beschädigt und aus intakten Revisionen neu aufgebaut.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Dieser lokale Verlauf verwendet das nicht unterstützte Format $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Lokaler Verlauf ist nicht verfügbar: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Aufzeichnung ist deaktiviert oder dieser Pfad ist ausgeschlossen. Aktivieren Sie die Aufzeichnung erneut, bevor Sie wiederherstellen.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Lokaler Verlauf konnte die Pfadänderung nicht aufzeichnen: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Lokaler Verlauf konnte den gelöschten Pfad nicht speichern: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Die ausgewählte Revision fehlt oder ist beschädigt.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Die ausgewählte Revision kann nicht gelesen werden: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Lokaler Verlauf konnte diese Revision nicht erfassen: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Basisversion';

  @override
  String get localHistoryReasonSaved => 'Gespeichert';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Automatische Checkpoint';

  @override
  String get localHistoryReasonBeforeReload => 'Vor dem Neuladen';

  @override
  String get localHistoryReasonBeforeDiscard => 'Vor dem Entsorgen';

  @override
  String get localHistoryReasonBeforeRestore => 'Vor der Wiederherstellung';

  @override
  String get localHistoryReasonBeforeDelete => 'Vor dem Löschen';

  @override
  String get localHistoryReasonExternalChange => 'Externe Änderung';

  @override
  String get settingsHistory => 'Verlauf';

  @override
  String get settingsClipboardHistoryTitle =>
      'Verlauf der Zwischenablage sammeln';

  @override
  String get settingsClipboardHistoryDescription =>
      'Behalten Sie den Inhalt, der erfolgreich kopiert und eingefügt wurde, nur für diese BusyMark-Sitzung.';

  @override
  String get settingsLocalHistoryTitle => 'Lokalen Verlauf speichern';

  @override
  String get settingsLocalHistoryDescription =>
      'Speichern Sie Dokumentversionen auf diesem Gerät zur Wiederherstellung und zum Vergleich.';

  @override
  String get settingsHistoryCheckpoint => 'Automatische Checkpoint-Intervall';

  @override
  String get settingsHistoryRetention => 'Aufbewahrungsdauer';

  @override
  String get settingsHistoryStorage => 'Maximale Speicherkapazität';

  @override
  String get settingsHistoryExcludedPaths => 'Ausschließlich Pfade';

  @override
  String get settingsHistoryExcludedPathsHint => 'Ein absoluter Pfad pro Zeile';

  @override
  String settingsSecondsValue(int value) {
    return '$value Sekunden';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value Tage';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Rechtschreibung';

  @override
  String get automaticSpelling => 'Automatische Rechtschreibprüfung';

  @override
  String get defaultSpellingLanguage => 'Standardsprache für Rechtschreibung';

  @override
  String get projectSpellingLanguage => 'Projektsprache für Rechtschreibung';

  @override
  String get chooseSpellingLanguage => 'Rechtschreibsprache auswählen';

  @override
  String get spellingLanguageUnsetStatus => 'Sprache…';

  @override
  String get spellingOffStatus => 'Rechtschreibung aus';

  @override
  String get checkSpelling => 'Rechtschreibung prüfen';

  @override
  String get ignoreSpellingOnce => 'Einmal ignorieren';

  @override
  String get ignoreSpellingDocument => 'Alle in diesem Dokument ignorieren';

  @override
  String get addPersonalSpellingWord =>
      'Zum persönlichen Wörterbuch hinzufügen';

  @override
  String get addProjectSpellingWord => 'Zum Projektwörterbuch hinzufügen';

  @override
  String get inheritSpellingLanguage =>
      'Projekt- oder Anwendungssprache verwenden';

  @override
  String get disableDocumentSpelling => 'Rechtschreibung nicht prüfen';

  @override
  String get importSpellingDictionary => 'Wörterbuch importieren';

  @override
  String get personalSpellingDictionary => 'Persönliches Wörterbuch';

  @override
  String get projectSpellingDictionary => 'Projektwörterbuch';

  @override
  String get noSpellingErrors => 'Keine Rechtschreibfehler';

  @override
  String get noSpellingSuggestions => 'Keine Rechtschreibvorschläge';

  @override
  String get spellingWordCheckFailed =>
      'Dieses Wort konnte nicht geprüft werden';

  @override
  String get spellingCheckFailed => 'Rechtschreibprüfung fehlgeschlagen';

  @override
  String get spellingSettingsLoadFailed =>
      'Rechtschreibeinstellungen konnten nicht geladen werden';

  @override
  String get retrySpellingSettings => 'Rechtschreibeinstellungen erneut laden';

  @override
  String get spellingCheckIncomplete => 'Rechtschreibprüfung ist unvollständig';

  @override
  String get spellingDictionaryNotInstalled => 'Wörterbuch nicht installiert';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Das Wörterbuch $dictionary ist nicht installiert';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Nicht installiert · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Installiert';

  @override
  String get installSpellingDictionary => 'Wörterbuch installieren';

  @override
  String get removeSpellingDictionary => 'Wörterbuch entfernen';

  @override
  String get cancelSpellingDictionaryInstall => 'Wörterbuchdownload abbrechen';

  @override
  String get retrySpellingDictionaryInstall =>
      'Wörterbuchinstallation wiederholen';

  @override
  String spellingDictionaryDownloading(String size) {
    return '$size werden heruntergeladen…';
  }

  @override
  String get spellingDictionaryValidating => 'Wörterbuch wird überprüft…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Wörterbuchinstallation fehlgeschlagen – zum Wiederholen auswählen';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return '$dictionary ($size) installieren? Danach bleibt es offline verfügbar, bis Sie es entfernen.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Wörterbuch nicht verfügbar';

  @override
  String get spellingChecking => 'Rechtschreibung wird geprüft…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: Geben Sie eine Zahl zwischen $minimum und $maximum ein.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Das Rechtschreibwörterbuch wurde extern geändert. Eine Wiederherstellungskopie wurde aufbewahrt.';

  @override
  String get windowMinimize => 'Minimieren';

  @override
  String get windowMaximize => 'Maximieren';

  @override
  String get windowRestore => 'Wiederherstellen';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Verbinden';

  @override
  String get nextcloudReconnect => 'Erneut verbinden';

  @override
  String get nextcloudDisconnect => 'Trennen';

  @override
  String get nextcloudServer => 'Server-URL';

  @override
  String get nextcloudSignInBrowser =>
      'Schließen Sie die Anmeldung im Browser ab.';

  @override
  String get nextcloudFavorites => 'Favoriten';

  @override
  String get nextcloudNewNote => 'Neue Notiz';

  @override
  String get nextcloudSavedLocally =>
      'Lokal gespeichert · Synchronisierung ausstehend';

  @override
  String get nextcloudSyncing => 'Wird synchronisiert';

  @override
  String get nextcloudSynced => 'Synchronisiert';

  @override
  String get nextcloudOffline => 'Nicht verbunden';

  @override
  String get nextcloudLocked => 'Vom Server gesperrt';

  @override
  String get nextcloudReconnectRequired => 'Erneute Verbindung erforderlich';

  @override
  String get nextcloudCreationUncertain => 'Ergebnis der Erstellung ungewiss';

  @override
  String get nextcloudReadOnly => 'Schreibgeschützt';

  @override
  String get nextcloudTakeRemote => 'Serverversion übernehmen';

  @override
  String get nextcloudMerge => 'Zusammenführen';

  @override
  String get nextcloudDeleteNote => 'Notiz löschen?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Arbeitsbereichsweites Ersetzen ist für Nextcloud Notes nicht verfügbar. Ersetzen Sie Inhalte in einzelnen Notizen.';

  @override
  String get nextcloudSaveLocalCopy => 'Lokale Kopie speichern…';

  @override
  String get nextcloudDisconnectWarning =>
      'Das Entfernen dieses Kontos löscht zwischengespeicherte Notizen und ausstehende Änderungen auf diesem Gerät. Synchronisieren Sie zuvor, um ausstehende Arbeit auf dem Server zu erhalten.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Wenn der vorherige Upload erfolgreich war, kann dieser erneute Versuch einen ungenutzten Anhang auf dem Server hinterlassen.';

  @override
  String get nextcloudAttachmentReference => 'Anhangreferenz auf dem Server';

  @override
  String get nextcloudAddAttachment => 'Anhang hinzufügen…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Durch Löschen des Anhangs sind seine Links in der Notiz nicht mehr verfügbar. Aufbewahrte Daten können über den lokalen Verlauf wiederhergestellt werden.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Wählen Sie jeden widersprüchlichen Wert.';

  @override
  String get nextcloudUseServerNote => 'Diese Servernotiz verwenden';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Verknüpft diesen Entwurf mit der ausgewählten Servernotiz und synchronisiert anschließend die behaltenen lokalen Änderungen. Ein passender Antrag bestätigt nicht, wer die Notiz erstellt hat.';

  @override
  String get nextcloudExactCandidate =>
      'Exakte Übereinstimmung mit der Anfrage; Identität unbestätigt.';

  @override
  String get nextcloudPossibleCandidate =>
      'Mögliche Übereinstimmung nach Bereinigung der Anfrage; Identität unbestätigt.';

  @override
  String get nextcloudSelectCandidate => 'Servernotiz zur Prüfung auswählen';

  @override
  String get nextcloudCreateSeparate => 'Separate Notiz erstellen';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Die erste Anfrage hat möglicherweise bereits eine Servernotiz erstellt. Dies erstellt eine separate Notiz mit Ihrer behaltenen lokalen Arbeit. Vermutete Duplikate werden nicht gelöscht.';

  @override
  String get wsSemanticFormats => 'Semantische Formatierung';

  @override
  String get wsUiControl => 'UI-Steuerelement';

  @override
  String get wsFilePath => 'Datei / Pfad';

  @override
  String get wsUiPath => 'UI-Pfad';

  @override
  String get wsDefinitionList => 'Definitionsliste';

  @override
  String get wsIncludeContent => 'Wiederverwendbaren Inhalt einbinden';

  @override
  String get wsVariableReference => 'Variablenreferenz';

  @override
  String get wsConvertList => 'Liste in Prozedur umwandeln';

  @override
  String get wsElementProperties => 'Elementeigenschaften';

  @override
  String get wsTopicProperties => 'Themeneigenschaften';

  @override
  String get wsCollapsible => 'Einklappbar';

  @override
  String get wsPublishedState => 'Anfangszustand bei Veröffentlichung';

  @override
  String get wsExpanded => 'Ausgeklappt';

  @override
  String get wsCollapsed => 'Eingeklappt';

  @override
  String get wsCollapsedTitle => 'Titel im eingeklappten Zustand';

  @override
  String get wsTerm => 'Begriff';

  @override
  String get wsListLayout => 'Listenlayout';

  @override
  String get wsSyncGroup => 'Synchronisierungsgruppe';

  @override
  String get wsTabKey => 'Registerschlüssel';

  @override
  String get wsSwitcherLabel => 'Beschriftung des Umschalters';

  @override
  String get wsNavigationElements => 'Navigationselemente';

  @override
  String get wsNavigationDepth => 'Navigationstiefe';

  @override
  String get wsAddItem => 'Element hinzufügen';

  @override
  String get wsStep => 'Schritt';

  @override
  String get wsPropertyInvalid => 'Ungültiger Eigenschaftswert';

  @override
  String get wsFilter => 'Inhaltsfilter';

  @override
  String get wsIdentifier => 'Element-ID';

  @override
  String get wsTldr => 'Kurzfassung (TLDR)';

  @override
  String get wsFullLayout => 'Volle Breite';

  @override
  String get wsMediumLayout => 'Mittel (1:2)';

  @override
  String get wsNarrowLayout => 'Schmale Begriffsspalte';

  @override
  String get wsTitle => 'Titel';

  @override
  String get wsSwitcherKey => 'Umschaltschlüssel';

  @override
  String get nextcloudServerSettings => 'Notes-Einstellungen auf dem Server';

  @override
  String get nextcloudNotesPath => 'Pfad des Notizordners';

  @override
  String get nextcloudFileSuffix => 'Dateiendung neuer Notizen';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Diese Notes-Einstellungen gelten auch für andere Clients. Ein Pfadwechsel verschiebt keine Dateien; eine neue Endung benennt bestehende Notizen nicht um.';

  @override
  String get nextcloudSettingsSaved => 'Servereinstellungen gespeichert';

  @override
  String get nextcloudSettingsNormalized =>
      'Mit vom Server normalisierten Werten gespeichert';

  @override
  String get nextcloudPendingUpload => 'Anhang wartet auf Upload';

  @override
  String nextcloudServerCheck(String time) {
    return 'Letzte Serverprüfung: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Servereinstellungen werden geladen';

  @override
  String get nextcloudSettingsSaving =>
      'Servereinstellungen werden gespeichert';

  @override
  String get nextcloudPreviousLocalEdit => 'Vorherige lokale Änderung';

  @override
  String get nextcloudUsePreviousEdit => 'Vorherige Änderung verwenden';

  @override
  String get quickOpen => 'Schnell öffnen';

  @override
  String get notesAll => 'Alle Notizen';

  @override
  String get notesUncategorized => 'Ohne Kategorie';

  @override
  String get notesRecovery => 'Wiederherstellung';

  @override
  String get notesRecentlyEdited => 'Zuletzt bearbeitet';

  @override
  String get notesOldestEdited => 'Älteste Bearbeitung';

  @override
  String get notesTitleAscending => 'Titel A–Z';

  @override
  String get notesTitleDescending => 'Titel Z–A';

  @override
  String get notesMove => 'In Kategorie verschieben';

  @override
  String get notesRemoveFavorite => 'Favorit entfernen';

  @override
  String get notesOffline => 'Offline verfügbar machen';

  @override
  String get notesOfflineRemove => 'Offline-Aufbewahrung entfernen';

  @override
  String get notesIndexing => 'Notizen werden indiziert…';

  @override
  String get notesSearchHelp =>
      'Begriffe verwenden UND. Verwenden Sie \"Wortgruppen\", title: und category:.';

  @override
  String get notesSourceLocation => 'Quellposition';

  @override
  String get notesRecoveryHelp =>
      'Nur lokal aufbewahrte Notizen und lokaler Verlauf. Server-Papierkorb und Server-Verlauf sind nicht verfügbar.';

  @override
  String get notesImport => 'Notizen importieren';

  @override
  String get notesExport => 'Notizen exportieren';

  @override
  String get notesImportDistinct => 'Als eigene Notiz importieren';

  @override
  String get notesAvailableOffline => 'Offline verfügbar';

  @override
  String get notesIncomplete => 'Unvollständig';

  @override
  String get notesSelected => 'Ausgewählte Notizen';

  @override
  String get notesNoHistory =>
      'Keine aufbewahrten Versionen. Der Verlauf kann deaktiviert, abgelaufen oder gelöscht sein.';

  @override
  String get notesTextAvailable => 'Text lokal verfügbar';

  @override
  String get notesLocalVersion => 'Lokale Arbeitsversion';

  @override
  String get notesAttachments => 'Anhänge';

  @override
  String get notesSkipped => 'Übersprungen';

  @override
  String get notesFailed => 'Fehlgeschlagen';

  @override
  String get notesCompleted => 'Abgeschlossen';

  @override
  String get notesImportNew => 'Neuen Import starten';

  @override
  String get notesImportResume => 'Unterbrochenen Import fortsetzen';

  @override
  String get notesImportAlreadyImported =>
      'In diesem Vorgang bereits importiert';

  @override
  String get references => 'Verweise';

  @override
  String get referenceIncoming => 'Eingehend';

  @override
  String get referenceOutgoing => 'Ausgehend';

  @override
  String get referenceChooseTarget => 'Linkziel auswählen';

  @override
  String get referenceWholeDocument => 'Gesamtes Dokument';

  @override
  String get referenceSourceLocation => 'Quellposition';

  @override
  String get referenceTargetLocation => 'Zielposition';

  @override
  String get referenceResolved => 'Aufgelöst';

  @override
  String get referenceMissing => 'Fehlt';

  @override
  String get referenceAmbiguous => 'Mehrdeutig';

  @override
  String get referenceUnavailable => 'In diesem Kontext nicht verfügbar';

  @override
  String get referenceUnsupported => 'Nicht unterstützt';

  @override
  String get referenceNoPortableId =>
      'Dieses Ziel hat keine bestätigte portable Notiz-URL.';

  @override
  String get wsIncludeLines => 'Zeilen einschließen';

  @override
  String get wsIncludeSymbol => 'Symbol einschließen';

  @override
  String get wsEmphasizeLines => 'Angezeigte Zeilen hervorheben';

  @override
  String get wsPropertiesReadOnly =>
      'Eigenschaften sind in dieser Ansicht schreibgeschützt.';

  @override
  String get wsPropertiesProtected =>
      'Dieses Element ist geschützt. Bearbeiten Sie seine Quelle.';

  @override
  String get wsPropertiesConflict =>
      'Dokument oder Element geändert. Entwurf zurücksetzen und erneut auswählen.';

  @override
  String get wsPropertiesUnresolved =>
      'Der Verweis kann derzeit nicht aufgelöst werden.';

  @override
  String get wsUseDefault => 'Standard verwenden';

  @override
  String get wsPropertiesSelection => 'Ein einzelnes Element auswählen.';

  @override
  String get wsImageDisplay => 'Bilddarstellung';

  @override
  String get wsImageThumbnail => 'Anklickbare Miniaturansicht';

  @override
  String get wsEnabled => 'Aktiviert';

  @override
  String get wsDisabled => 'Deaktiviert';

  @override
  String get wsWidth => 'Breite';

  @override
  String get wsHeight => 'Höhe';

  @override
  String get wsPropertiesInactive =>
      'Ohne veröffentlichtes Einklappen hat diese Eigenschaft keine Wirkung.';

  @override
  String get wsNavigationAll => 'Alle Elemente mit Titel';

  @override
  String get wsNavigationNone => 'Keine Navigation';

  @override
  String get wsNavigationCustom => 'Benutzerdefinierte Navigation';

  @override
  String get wsTitleOverride => 'Titel überschreiben';

  @override
  String get wsCompactLayout => 'Kompakt';

  @override
  String get wsWideLayout => 'Breit';

  @override
  String get wsCodeSourceConflict =>
      'Verschieben oder entfernen Sie den Code in diesem Block, bevor Sie src setzen. Writerside lehnt nicht leere Codeblöcke mit einer Quellreferenz ab.';

  @override
  String get wsInherited => 'Von Liste erben';

  @override
  String get wsExternalImageSize =>
      'Writerside skaliert extern gehostete Bilder nicht zuverlässig. Vorhandene Maße können geprüft und entfernt werden.';

  @override
  String get wsPropertiesNotSerialized =>
      'Diese Änderung wurde nicht in den Quelltext übernommen. Der Entwurf wurde beibehalten.';

  @override
  String get wsListItem => 'Listeneintrag';

  @override
  String get wsSourceFile => 'Quelldatei';

  @override
  String get wsLinkTarget => 'Linkziel';

  @override
  String get wsPreviewImage => 'Vorschaubild';

  @override
  String get wsIncludedElement => 'Eingebundenes Element';

  @override
  String get wsHelpModule => 'Hilfemodul';

  @override
  String get wsActionId => 'Aktions-ID';

  @override
  String get wsKeymapHelpInstance => 'Hilfeinstanz der Tastaturbelegung';

  @override
  String get wsShowInSource => 'Im Quelltext anzeigen';

  @override
  String get wsOriginElement => 'Elementüberschreibung';

  @override
  String get wsOriginAncestor => 'Übergeordnetes Element';

  @override
  String get wsOriginModule => 'Modulstandard';

  @override
  String get wsOriginBuiltIn => 'Integrierter Standard';

  @override
  String get wsOriginUnresolved => 'Nicht aufgelöst';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Effektiv: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Element';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Generiert: $anchor';
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
    return 'Aufgelöst: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Nicht aufgelöst';

  @override
  String get wsModule => 'Modul';

  @override
  String get wsParent => 'Übergeordnetes Element';

  @override
  String get wsListType => 'Listentyp';

  @override
  String get wsStartingNumber => 'Startnummer';

  @override
  String get wsListSorting => 'Sortierung';

  @override
  String get wsLetteredList => 'Buchstabenliste';

  @override
  String get wsCheckboxList => 'Liste mit Kontrollkästchen';

  @override
  String get wsMarkerlessList => 'Liste ohne Aufzählungszeichen';

  @override
  String get wsAscending => 'Aufsteigend';

  @override
  String get wsDescending => 'Absteigend';

  @override
  String get wsNoSorting => 'Keine Sortierung';

  @override
  String get wsAsWritten => 'Wie geschrieben';

  @override
  String get wsSentenceCase => 'Satzschreibung';

  @override
  String get wsTitleCase => 'Titelschreibung';

  @override
  String get wsLowerCase => 'Kleinbuchstaben';

  @override
  String get wsUpperCase => 'Großbuchstaben';

  @override
  String get wsNativeMarkers => 'Markdown-Listenzeichen';

  @override
  String wsListMarkerStart(String number) {
    return 'Listenbeginn: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Ebene $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Der festgelegte Builder ignoriert <caps>-Regeln des Moduls. Verwenden Sie ein lokales caps-Attribut oder default-property.';

  @override
  String get wsInsertElements => 'Elemente einfügen';

  @override
  String get wsAdmonitionsAndQuotes => 'Hinweise und Zitate';

  @override
  String get wsSemanticText => 'Semantischer Text';

  @override
  String get wsPropertiesUnavailable =>
      'Das betrachtete Element ist nicht verfügbar. Wählen Sie ein Element zum Fortfahren.';

  @override
  String get searchDocumentsCategory => 'Dokumente';

  @override
  String get searchTopicsCategory => 'Themen';

  @override
  String get searchCurrentDocument => 'Aktuelles Dokument';

  @override
  String get searchCurrentWorkspace => 'Aktueller Arbeitsbereich';

  @override
  String get browseNotes => 'Notizen durchsuchen';

  @override
  String get searchActionsCommand => 'Aktionen suchen';

  @override
  String get searchDocumentsCommand => 'Dokumente suchen';

  @override
  String get searchTopicsCommand => 'Themen suchen';

  @override
  String get searchRecentCommand => 'Zuletzt geöffnet suchen';

  @override
  String get searchResourceUnavailable =>
      'Diese Ressource ist nicht verfügbar.';

  @override
  String get notesSync => 'Notizen synchronisieren';

  @override
  String get searchInWorkspace => 'Im Arbeitsbereich suchen';

  @override
  String get searchCategory => 'Suchkategorie';

  @override
  String get clearHistorySearchScope => 'Verlauf aller Dokumente durchsuchen';

  @override
  String get searchInDocument => 'Im Dokument suchen';

  @override
  String get searchDocumentHint => 'Dieses Dokument durchsuchen…';

  @override
  String get searchWorkspaceHint => 'Diesen Arbeitsbereich durchsuchen…';

  @override
  String get searchOutlineHint => 'Überschriften suchen…';

  @override
  String get searchHistoryHint => 'Lokalen Verlauf durchsuchen…';

  @override
  String get searchEnterText => 'Suchtext eingeben';

  @override
  String get searchAccountUnavailable => 'Konto nicht verfügbar';

  @override
  String get searchDocumentsHint => 'Dokumente suchen…';

  @override
  String get searchTopicsHint => 'Themen suchen…';

  @override
  String get searchRecentHint => 'Zuletzt geöffnet suchen…';

  @override
  String get searchActionsHint => 'Aktionen suchen…';

  @override
  String get searchRequiresNotesWorkspace =>
      'Erfordert einen Notizen-Arbeitsbereich';

  @override
  String get searchSidebarLabel => 'Suchen:';

  @override
  String get searchDocumentTextCategory => 'Dokumenttext';

  @override
  String get searchWorkspaceTextCategory => 'Arbeitsbereichstext';

  @override
  String get searchHeadingsCategory => 'Überschriften';

  @override
  String get shortcutUnassigned => 'Nicht zugewiesen';

  @override
  String get shortcutPressKeys => 'Tastenkombination drücken…';

  @override
  String get shortcutRecord => 'Tastenkürzel aufnehmen';

  @override
  String get shortcutRestoreAll => 'Alle Vorgaben wiederherstellen';

  @override
  String get shortcutRestoreAllQuestion =>
      'Standardkürzel aller Aktionen wiederherstellen? Eigene Zuweisungen werden entfernt.';

  @override
  String get shortcutSaveFailed =>
      'Tastenkürzel sind aktiv, konnten aber nicht gespeichert werden. Zum Beibehalten nach Neustart erneut speichern.';

  @override
  String get shortcutRetry => 'Speichern wiederholen';

  @override
  String get shortcutChanged =>
      'Zuweisungen geändert. Aktuelle Tastenkürzel prüfen und erneut versuchen.';

  @override
  String get shortcutInvalid =>
      'Diese Kombination kann hier nicht zugewiesen werden.';

  @override
  String get shortcutSystemWarning =>
      'Diese Kombination wird möglicherweise vom Desktop verwendet. BusyMark kann Systemkürzel nicht überschreiben.';

  @override
  String get shortcutConflicts =>
      'Dieses Tastenkürzel überschneidet sich mit diesen Aktionen:';

  @override
  String get shortcutRemove => 'Zuweisung entfernen';

  @override
  String get shortcutRestoreDefault => 'Vorgabe wiederherstellen';

  @override
  String get shortcutAssign => 'Zuweisen';

  @override
  String get shortcutReassign => 'Neu zuweisen';

  @override
  String get shortcutContextApplication => 'Anwendung';

  @override
  String get shortcutContextDocument => 'Dokumentansichten';

  @override
  String get shortcutContextEditor => 'Editor und Quelltext';

  @override
  String get shortcutContextWritersideSource => 'Writerside-Quelltext';

  @override
  String get shortcutContextWorkspace => 'Arbeitsbereichsnavigation';

  @override
  String get shortcutContextTree => 'Seitenleistenbäume';

  @override
  String get searchHeadingsCommand => 'Überschriften suchen';

  @override
  String get shortcutFixed => 'Vom Editor verwaltet; nicht konfigurierbar.';

  @override
  String get shortcutDefaultConflict =>
      'Das Standardkürzel steht mit einer eigenen Zuweisung in Konflikt.';

  @override
  String get shortcutCurrentBinding => 'Aktuelles Tastenkürzel';

  @override
  String get shortcutProposedBinding => 'Vorgeschlagenes Tastenkürzel';

  @override
  String get notesActions => 'Notizaktionen';

  @override
  String get noteActions => 'Aktionen für diese Notiz';

  @override
  String get noteProperties => 'Notizeigenschaften';

  @override
  String get notesExportAll => 'Notizen exportieren · Alle Notizen…';

  @override
  String get notesExportCategory => 'Notizen exportieren · Kategorie…';

  @override
  String get notesOfflineAll => 'Offline verfügbar machen · Alle Notizen';

  @override
  String get notesOfflineCategory => 'Offline verfügbar machen · Kategorie';

  @override
  String get notesOfflineRemoveAll =>
      'Offline-Aufbewahrung entfernen · Alle Notizen';

  @override
  String get notesOfflineRemoveCategory =>
      'Offline-Aufbewahrung entfernen · Kategorie';

  @override
  String get notesOfflinePause => 'Downloads pausieren';

  @override
  String get notesOfflineResume => 'Downloads fortsetzen';

  @override
  String get notesOfflineKeep => 'Offline verfügbar machen';

  @override
  String get notesOfflineRetentionHelp =>
      'Das Entfernen dieser Anforderung löscht keine zwischengespeicherten Inhalte. Eine Kategorie- oder Kontoanforderung kann die Notiz weiter aufbewahren.';

  @override
  String get notesOfflineBroader =>
      'Diese Notiz wird auch durch eine Kategorie- oder Kontoanforderung aufbewahrt.';

  @override
  String get notesOfflineExternal =>
      'Externe Medien benötigen eine Verbindung. BusyMark bewahrt nur Notiztext und verwaltete Anhänge auf.';

  @override
  String get notesEmptyAll => 'Noch keine Notizen. Erstellen Sie eine Notiz.';

  @override
  String get notesEmptyFavorites => 'Keine favorisierten Notizen.';

  @override
  String get notesEmptyCategory => 'Keine Notizen in dieser Kategorie.';

  @override
  String get notesEmptyUncategorized => 'Keine nicht kategorisierten Notizen.';

  @override
  String get notesEmptyRecovery =>
      'Keine aufbewahrten Notizen zur Wiederherstellung.';

  @override
  String get notesLoadFailed =>
      'Nextcloud Notes · Fehlgeschlagen. Erneut versuchen';

  @override
  String get notesOperationFailed =>
      'Der Vorgang ist fehlgeschlagen. Ihr Entwurf bleibt erhalten. Prüfen Sie Speichern und Konflikte und versuchen Sie es erneut.';

  @override
  String get notesInspectionFailed =>
      'Anhänge · Fehlgeschlagen. Erneut versuchen';

  @override
  String get notesStartingConnection => 'Nextcloud-Verbindung wird gestartet…';

  @override
  String get notesVerifyingConnection => 'Zugriff auf Notizen wird geprüft…';

  @override
  String get notesCancellingConnection =>
      'Anmeldung wird abgebrochen und bereinigt…';

  @override
  String get notesRemovingConnection => 'Lokales Konto wird entfernt…';

  @override
  String get notesRemovedWarning =>
      'Das lokale Nextcloud-Konto wurde entfernt. Der Widerruf des App-Passworts wurde nicht bestätigt. Entfernen Sie BusyMarks App-Passwort in den Nextcloud-Sicherheitseinstellungen.';

  @override
  String get notesBuffersNotSaved =>
      'Nicht alle offenen Notizen konnten lokal gespeichert werden. Prüfen Sie Speichern, Konflikte oder Normalisierung im Arbeitsbereich. Lokale Änderungen müssen eventuell noch mit Nextcloud synchronisiert werden.';

  @override
  String get notesSettingsLeave =>
      'Änderungen an den Nextcloud-Einstellungen vor dem Verlassen speichern?';

  @override
  String get notesSettingsLeaveHelp =>
      'Notes-Einstellungen auf dem Server · Ungespeicherte Änderungen';

  @override
  String get notesSettingsReload => 'Servereinstellungen neu laden…';

  @override
  String get notesSettingsReloadHelp =>
      'Neu laden ersetzt Ihren Entwurf durch die aktuellen Nextcloud-Einstellungen. Entwurf verwerfen und neu laden?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud hat die Einstellungen angenommen, aber die Notizen konnten nicht aktualisiert werden. Angezeigt werden die bestätigten Serverwerte. Aktualisieren Sie die Notizen erneut.';

  @override
  String get notesUnavailable =>
      'Nicht verbunden · Text lokal verfügbar · Lokal gespeichert · Synchronisierung ausstehend';

  @override
  String get notesStorageFull =>
      'Der Nextcloud-Speicher ist voll. Geben Sie auf dem Server Speicherplatz frei und versuchen Sie es erneut.';

  @override
  String get notesRejected =>
      'Nextcloud hat diese Änderung abgelehnt. Prüfen Sie die Notiz und speichern Sie vor einem neuen Versuch eine lokale Kopie.';

  @override
  String get notesThrottled =>
      'Nextcloud hat eine Wartezeit angefordert. Die Synchronisierung wird nach Ablauf dieser Frist fortgesetzt.';

  @override
  String get notesRecoveryRequired => 'Konflikte · Vergleichen';

  @override
  String get notesScanning => 'Dateien werden durchsucht…';

  @override
  String get notesCancelling =>
      'Abbruch läuft… Der aktuelle Vorgang wird noch beendet.';

  @override
  String get notesCancelled => 'Abgebrochen';

  @override
  String get notesPartial => 'Teilweise abgeschlossen';

  @override
  String get notesTransferFailed => 'Fehlgeschlagen. Erneut versuchen';

  @override
  String get notesImportPartialHelp =>
      'Frühere Einträge können bereits lokal gespeichert sein. Setzen Sie diesen Import fort, um Duplikate zu vermeiden.';

  @override
  String get notesNotStarted => 'Nicht gestartet';

  @override
  String get notesCreated => 'Erstellt';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Server-URL · Nicht unterstützt · Löschen · Anhänge';

  @override
  String get notesCurrentText => 'Aktuell aufbewahrter Text';

  @override
  String get notesRecovering => 'Wiederherstellung als neue Notiz…';

  @override
  String get notesReadOnlyHelp =>
      'Schreibgeschützt · Favoriten · Lokale Kopie speichern…';

  @override
  String get notesSort => 'Notizen sortieren';

  @override
  String get notesPathRelative =>
      'Der Notizordnerpfad ist relativ zu Ihrem Nextcloud-Speicher.';

  @override
  String get notesSettingsStale =>
      'Die Einstellungen haben sich auf Nextcloud geändert. Laden und prüfen Sie die Serverwerte, bevor Sie den Entwurf ersetzen.';

  @override
  String get notesDownloadsPaused => 'Downloads pausiert';

  @override
  String get notesExportNotPublished => 'Es wurde kein Export veröffentlicht.';

  @override
  String get notesKeyringUnavailable =>
      'Entsperren Sie den Desktop-Schlüsselbund und versuchen Sie es erneut.';

  @override
  String get notesConnectFailed =>
      'Keine Verbindung zu Nextcloud Notes. Prüfen Sie die Serveradresse und versuchen Sie es erneut.';

  @override
  String get notesAccountMismatch =>
      'Melden Sie sich beim selben Nextcloud-Konto an. Entfernen Sie dieses Konto zuerst, um ein anderes zu verbinden.';

  @override
  String get notesLocalRemovalFailed =>
      'Die lokale Kontobereinigung ist fehlgeschlagen. Das Konto bleibt für einen erneuten Entfernungsversuch erhalten.';

  @override
  String get notesTransferring => 'Notizen werden übertragen…';

  @override
  String get notesTechnicalDetails => 'Technische Details';

  @override
  String get notesPauseRequirement => 'Offline-Anforderung pausieren';

  @override
  String get notesResumeRequirement => 'Offline-Anforderung fortsetzen';

  @override
  String get gitReturnToDocument => 'Zum Dokument zurückkehren';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Schreibgeschützter Stand · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Dieser Dateiname enthält Bytes außerhalb von UTF-8. Git-Prüfung und Staging bleiben verfügbar; der Dokumenteditor benötigt einen UTF-8-Dateinamen.';

  @override
  String get gitUiMergeInProgress => 'Zusammenführung';

  @override
  String get gitUiRebaseInProgress => 'In Arbeit befindliche Basis';

  @override
  String get gitUiCherryPickInProgress => 'Cherry-pick im Gange';

  @override
  String get gitUiRevertInProgress => 'In Bearbeitung umkehren';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Patch-Anwendung in Bearbeitung';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Squash-Zusammenführungsergebnis wartet auf Commit';

  @override
  String get gitUiUnresolvedIndexConflicts => 'Ungelöste Indexkonflikte';

  @override
  String get gitUiUnresolvedConflicts => ' · ungelöste Konflikte';

  @override
  String get gitUiReviewOperation => 'Überprüfungsvorgang';

  @override
  String get gitUiRefresh => 'Aktualisieren';

  @override
  String get gitUiCreateNamedStash => 'Name des Speichers erstellen';

  @override
  String get gitUiCreateStash => 'Stash erstellen…';

  @override
  String get gitUiNoStashes => 'Keine Stashes';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Wählen Sie einen Vorrat, um seine Änderungen zu überprüfen';

  @override
  String get gitUiStashedUntrackedFiles => 'Gespeicherte untracked Dateien';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Inspizieren Sie untracked Dateien...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Bei der Anwendung den Zustand des Vorrats wieder einsetzen.';

  @override
  String get gitUiApplyAndRetain => 'Anwenden und behalten';

  @override
  String get gitUiPop => 'Anwenden und entfernen…';

  @override
  String get gitUiCreateBranch => 'Branch erstellen…';

  @override
  String get gitUiDropStash => 'Stash verwerfen…';

  @override
  String get gitUiBranchFromStash => 'Branch aus Stash erstellen';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Erstellen/Schalten zu einem Zweig am Stammhaus Originalbasis, dann anwenden. Das Original-Verhalten wird für explizite spätere Löschung beibehalten.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 dieses Versteck?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Der ursprüngliche Bestand wird bei der Anwendung von Konflikten beibehalten.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Löscht diesen Eintrag. Seine Änderungen werden nicht angewendet.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Lösen Sie die nicht zusammengeführten Dateien auf. Für Stashes gibt es in Git weder Continue noch Abort; der ursprüngliche Stash bleibt erhalten.';

  @override
  String get gitUiStashNameMessage => 'Name/Nachricht des Lagers';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Bestand und resultierender Index';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash verfolgte Arbeiten und inszenierte Veränderungen';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Änderungen stashen, Index-Inhalt beibehalten (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Nur Index-Änderungen stashen (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Nicht verfolgte Dateien einbinden';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Alle in diesem Projektarchiv zugelassenen Pfade';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Keine förderungsfähigen Änderungen für diese Optionen.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Wählen Sie mindestens einen förderfähigen Pfad aus.';

  @override
  String get gitUiCreateStash2 => 'Stash erstellen';

  @override
  String get gitUiCreateWorktree => 'Worktree erstellen...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Vor dem Erstellen eines Worktrees bei HEAD einen Commit erstellen.';

  @override
  String get gitUiDetachedHEAD => 'Losgelöster HEAD';

  @override
  String get gitUiCurrent => 'Laufend ·';

  @override
  String get gitUiLocked => 'Verriegelt ·';

  @override
  String get gitUiOpenInBusyStack => 'Geöffnet im BusyStack ·';

  @override
  String get gitUiStatusNotInspected => 'Status nicht geprüft';

  @override
  String get gitUiDirty => 'Schmutzig';

  @override
  String get gitUiClean => 'Sauber';

  @override
  String get gitUiOpenWorkingFolder => 'Arbeitsordner öffnen';

  @override
  String get gitUiMoveWorktree => 'Arbeitsbaum verschieben...';

  @override
  String get gitUiUnlock => 'Entsperren';

  @override
  String get gitUiLock => 'Sperren';

  @override
  String get gitUiRemoveCleanWorktree => 'Entfernen Sie sauberen Worktree...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Entfernen von Überprüfungen einschließlich lokaler Änderungen...';

  @override
  String get gitUiNewWorktreeFolderName => 'Neuer Name des Ordners worktree';

  @override
  String get gitUiNewWorktreeBranch => 'Neuer Zweig des Werkbaums';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Erstellen Sie $arg0/$arg1 mit einem neuen lokalen Zweig bei $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Name des Zielordners';

  @override
  String get gitUiRemoveWorktree => 'Worktree entfernen?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Verwerfen Sie explizit alle lokalen, verfolgten/nicht verfolgten Änderungen in diesem Worktree. Gesperrte/in Betrieb befindliche Worktrees bleiben geschützt.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git lehnt das Entfernen ab, wenn lokale Änderungen, nicht verfolgte Dateien oder ein Schloss vorhanden sind.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Lokale Worktree-Inhalte verwerfen und entfernen';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Entfernen sauberer Arbeitsbaum';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Explizit in verschachtelte Submodule für Updates/Synchronisierung zurücklaufen';

  @override
  String get gitUiNoRecordedSubmodules => 'Keine aufgezeichneten Untermodule';

  @override
  String get gitUiNotInitialized => 'nicht initialisiert';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Eltern-Gitlink: $arg0 Ausgecheckt: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository =>
      'Schmutziges verschachteltes Repository';

  @override
  String get gitUiCleanNestedRepository =>
      'Sauberes verschachteltes Repository';

  @override
  String get gitUiNestedStatusUnavailable =>
      'Verschachtelter Status nicht verfügbar';

  @override
  String get gitUiEnterNestedRepository =>
      'Verschachteltes Repository eingeben';

  @override
  String get gitUiInitializeConfiguration => 'Konfiguration initialisieren';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Update auf parent .s aufgezeichnete Commit...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Befolgen Sie konfigurierten Remote-Zweig...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Konfigurierte URLs synchronisieren...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Stufe aktuelles Untermodul Zeiger im übergeordneten';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Eltern- und Untermodul-Commits, Pushs und schmutzigen Zustand bleiben getrennt. Browsing initialisiert sie nicht oder aktualisiert sie.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Holen und überprüfen Sie die konfigurierten Remote-Zweig-Engage. Dies unterscheidet sich von den parent-Engaged-Aufzeichnungen. Rekursiv: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'Initialisieren Sie nach Bedarf und überprüfen Sie genau $arg0. Rekursiv: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Wenden Sie die überprüfte Submodulkonfiguration an. Rekursiv: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Submodul-Betrieb anwenden';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Inspizieren Sie eine aufgezeichnete Revision oder erstellen Sie einen Recovery-Zweig. Reflog erholt sich nicht willkürlich ungespeichert oder untracked Inhalt.';

  @override
  String get gitUiSelectAReflogEntry => 'Einen Reflog-Eintrag auswählen';

  @override
  String get gitUiPreviousPage => 'Vorherige Seite';

  @override
  String get gitUiNextPage => 'Nächste Seite';

  @override
  String get gitUiRecoveryBranchName => 'Name des Wiedereinziehungszweigs';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Erstellt einen Zweig bei $arg0; Arbeitsdateien und der aktuelle Zweig sind unverändert.';
  }

  @override
  String get gitUiCreateRecoveryBranch =>
      'Wiederherstellungszweig erstellen...';

  @override
  String get gitUiReadOnlyRecoverySnapshot =>
      'Nur-Lese-Wiederherstellung-Snapshot';

  @override
  String get gitUiInspectSnapshot => 'Momentaufnahme prüfen...';

  @override
  String get gitUiReviewReset => 'Bewertung zurücksetzen...';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Seite $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Eine Git-Text-Historie muss ihr editierbares Feld besitzen.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Bearbeiten HEAD | Index | Arbeitsverzeichnis…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Der überprüfte Index oder Arbeitsinhalt änderte sich. Aktualisieren Sie diesen Vergleich vor der Inszenierung.';

  @override
  String get gitUiRefreshComparison => 'Vergleich aktualisieren';

  @override
  String get gitUiPreviousChangedFile => 'Vorherige geänderte Datei';

  @override
  String get gitUiNextChangedFile => 'Nächste geänderte Datei';

  @override
  String get gitUiPreviousDifference => 'Vorherige Differenz';

  @override
  String get gitUiNextDifference => 'Nächster Unterschied';

  @override
  String get gitUiComparisonMode => 'Vergleichsmodus';

  @override
  String get gitUiSideBySide => 'Seite an Seite';

  @override
  String get gitUiUnified => 'Einheit';

  @override
  String get gitUiDiffDisplayOptions => 'Diff-Anzeigenoptionen';

  @override
  String get gitUiWrap => 'Wrap';

  @override
  String get gitUiWords => 'Wörter';

  @override
  String get gitUiCollapseContext => 'Kontext des Zusammenbruchs';

  @override
  String get gitUiIgnoreWhitespace => 'Leerzeichen ignorieren';

  @override
  String get gitUiSearchComparison => 'Suchvergleich';

  @override
  String get gitUiSearch => 'Suchen';

  @override
  String get gitUiCloseSearch => 'Suche schließen';

  @override
  String get gitUiStagingActions => 'Staging-Maßnahmen';

  @override
  String get gitUiStagingActions2 => '- Ich versuch\'s.';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Ausgewählte Änderungszeilen aus Index entfernen';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Ausgewählte Änderungszeilen zum Index hinzufügen';

  @override
  String get gitUiUnstageWholeFile => 'Ganze Datei aus Index entfernen';

  @override
  String get gitUiStageWholeFile => 'Ganze Datei zum Index hinzufügen';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '$arg0 nur geänderte Zeilen versteckt · Genaue Änderungen anzeigen';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 änderte Linien ausgewählt · Display-Einstellungen verändern nie die inszenierten Bytes.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Schreibgeschützter Vergleich · Text kopieren oder Anzeige anpassen.';

  @override
  String get gitUiNoFinalNewline => ' · keine endgültige Neulinie';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 Bytes$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'Der Textvergleich ist für diese Inhalte nicht verfügbar.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Dieser Vergleich übersteigt die Grenzen der Textprüfung. Der Inhalt wurde nicht als identisch erklärt.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Die Vergleichsinhalte sind identisch.';

  @override
  String get gitUiUnstage => 'Unstufenweise';

  @override
  String get gitUiStage => 'Stufe';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 geänderte Zeile';
  }

  @override
  String get gitUiContext => 'Kontext';

  @override
  String get gitUiExpandUnchangedContext => 'Unveränderter Kontext erweitern';

  @override
  String get gitUiUnstageThisHunk => 'Diesen Block aus Index entfernen';

  @override
  String get gitUiStageThisHunk => 'Diesen Block zum Index hinzufügen';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Bearbeitung inszenierter Inhalte · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Schreiben überprüft Index-Ergebnis';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Index';

  @override
  String get gitUiWorkingTree => 'Arbeitsverzeichnis';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Index · editierbarer UTF-8-Blob';

  @override
  String get gitUiUndo => 'Rückgängig machen';

  @override
  String get gitUiRedo => 'Wiederholen';

  @override
  String get gitUiReloadIndexReview => 'Index-Rezension neu laden?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Aktuelle HEAD-, Index- und Arbeitsversionen neu laden. Dies ersetzt den ungespeicherten Entwurf im Indexeditor.';

  @override
  String get gitUiReplaceDraftAndReload => 'Entwurf ersetzen und neu laden';

  @override
  String get gitUiReloadVersions => 'Versionen neu laden...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Schreiben Sie bearbeitetes Ergebnis auf diesen Indexeintrag';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Arbeitsdateien bleiben auf der Festplatte. Überprüfen Sie den bearbeiteten Index vor der Anwendung.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Änderungen des Index-Textformats';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Aktualisieren Sie nur den überprüften Indexeintrag für $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult => 'Bewertung des Index-Ergebniss';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Das bearbeitete Ergebnis änderte sich während der Formatprüfung. Überprüfen Sie es erneut.';

  @override
  String get gitUiSynchronizeScrolling => 'Scrollen synchronisieren';

  @override
  String get gitUiReadOnlyRevisionContent => 'Nur-Lese-Revisions-Inhalte';

  @override
  String get gitUiEditableIndexContent => 'Bearbeitbarer Indexinhalt';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Die angeforderte Revision befindet sich außerhalb der aktuellen Filter. Alle Filter zurücksetzen, um sie anzuzeigen.';

  @override
  String get gitUiFilterLog => 'Filterprotokoll';

  @override
  String get gitUiFilters => 'Filter...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filter ($count)...';
  }

  @override
  String get gitUiMessage => 'Nachricht…';

  @override
  String get gitUiAuthor => 'Autor…';

  @override
  String get gitUiPath => 'Pfad...';

  @override
  String get gitUiDate => 'Verabredung...';

  @override
  String get gitUiMessageFilter => 'Nachrichtenfilter';

  @override
  String get gitUiAuthorFilter => 'Autor Filter';

  @override
  String get gitUiPathFilter => 'Pfadfilter';

  @override
  String get gitUiMessage2 => 'Nachricht';

  @override
  String get gitUiAuthor2 => 'Autor';

  @override
  String get gitUiPath2 => 'Pfad';

  @override
  String get gitUiDateFilter => 'Datumsfilter...';

  @override
  String get gitUiResetFilters => 'Filter zurücksetzen';

  @override
  String get gitUiRefreshLog => 'Protokoll aktualisieren';

  @override
  String get gitUiGoToCommitReference => 'Gehen Sie zu Commit/Reference...';

  @override
  String get gitUiBackToHEAD => 'Zurück zu HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Bestellte Kirsche-Pick';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Bewertung Kirsche-Pick ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Vergleichen Sie zwei ausgewählte Revisionen...';

  @override
  String get gitUiToggleBranchesPane => 'Bereich der Zweige umschalten';

  @override
  String get gitUiFilterBranchesAndTags => 'Zweige und Tags filtern';

  @override
  String gitUiCommitArg0(String arg0) {
    return '$arg0 einbinden';
  }

  @override
  String get gitUiCommitDetails => 'Details einreichen...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Bezug: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Diesen Commit wählen';

  @override
  String get gitUiBranchOrTag => 'Zweig oder Tag';

  @override
  String get gitUiAllReferences => 'Alle Verweise';

  @override
  String get gitUiLocal => 'Lokale';

  @override
  String get gitUiRemote => 'Remote';

  @override
  String get gitUiTags => 'Tags';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Keine Commits entsprechen den aktuellen Filtern.';

  @override
  String get gitUiObjectID => 'Objekt-ID';

  @override
  String get gitUiSubjectReferences => 'Gegenstand / Verweise';

  @override
  String get gitUiDate2 => 'Datum';

  @override
  String get gitUiGitCommits => 'Git verpflichtet sich';

  @override
  String get gitUiParents => 'Eltern-Commits';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 Eltern';
  }

  @override
  String get gitUiLoadMoreCommits => 'Mehr Commits laden';

  @override
  String get gitUiLoadingChangedFiles => 'Geänderte Dateien werden geladen';

  @override
  String get gitUiNoChangedFiles => 'Keine geänderten Dateien';

  @override
  String get gitUiSelectACommit => 'Einen Commit auswählen';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Vergleich Eltern $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Geänderte Dateien';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autor: $arg0 <$arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Ausschuss: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Flache/teilweise Grenze: ein übergeordnetes Objekt ist nicht verfügbar.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Eltern sind außerhalb dieser Seite oder einer flachen Grenze.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Eltern-Commit $arg0';
  }

  @override
  String get gitUiCommitActions => 'Einführen von Aktionen...';

  @override
  String get gitUiEmptyTree => 'leerer Baum';

  @override
  String get gitUiCreateBranch2 => 'Branch erstellen';

  @override
  String get gitUiCreateTag => 'Tag erstellen';

  @override
  String get gitUiCompareRevisions => 'Revisionen vergleichen';

  @override
  String get gitUiOpenSnapshot => 'Snapshot öffnen';

  @override
  String get gitUiRevertCommit => 'Commit rückgängig machen';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Interaktives Rebase nach dieser Grenze';

  @override
  String get gitUiResetCurrentBranch => 'Aktuellen Branch zurücksetzen';

  @override
  String get gitUiCopyFullObjectID => 'Vollständige Objekt-ID kopieren';

  @override
  String get gitUiGoToCommitReference2 => 'Gehe zu Commit/Reference';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Geben Sie eine Commit-ID oder Referenz ein, um sie in Log zu offenbaren.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Die angeforderte Revision ist nicht verfügbar.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Die Metadaten des Repositorys sind schreibgeschützt. Zweiginspektion und Vergleich bleiben verfügbar.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Arbeitsdateien sind nicht verfügbar oder nur lesbar. Zweigwechsel und Zusammenführen sind nicht verfügbar.';

  @override
  String get gitUiSearchBranchesAndTags => 'Branches und Tags suchen';

  @override
  String get gitUiNewBranch => 'Neuer Branch…';

  @override
  String get gitUiLocalBranches => 'Lokale Branches';

  @override
  String get gitUiRemoteBranches => 'Remote-Branches';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Spuren $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Ausgecheckt bei $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata =>
      'Aktualisierung der Metadaten von Zweigen';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Auf $arg0 wechseln';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Offene besetzte Arbeitsfläche';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Lokaler Tracking-Zweig erstellen...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Mit aktuellem HEAD vergleichen';

  @override
  String get gitUiMergeIntoCurrentBranch =>
      'Zusammenführen in den aktuellen Zweig...';

  @override
  String get gitUiRename => 'Umbenennen...';

  @override
  String get gitUiChangeUpstream => 'Weiter oben ändern...';

  @override
  String get gitUiDelete => 'Löschen...';

  @override
  String get gitUiDeleteFromRemote => 'Löschen aus der Ferne...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Aktionen für $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Name des lokalen Zweigs';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Erstellen Sie bei $arg0. Der neue Zweig wird ausgecheckt.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Der lokale Zweig wird $arg0 verfolgen und auschecken.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Wählen Sie Remote zum Löschen';

  @override
  String get gitUiDeleteRemoteReference => 'Fernreferenz löschen';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return '$arg0 in $arg1 zusammenführen';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return '$arg0 umbenennen';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Upstream für $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Kein Upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return '$arg0 löschen?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Nur lokales Löschen. Ein unverschmelzter Zweig wird abgelehnt.';
  }

  @override
  String get gitUiDelete2 => 'Löschen';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Nicht zusammengefügten Zweig $arg0 löschen?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git meldet, dass dieser Zweig nicht vollständig zusammengeführt wird. Löschen Sie die lokale Referenz nach Überprüfung der Commits ausdrücklich; Remote-Kopien sind unverändert.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => 'Lokaler Zweig löschen';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Ziel: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Quellzweig oder -tag';

  @override
  String get gitUiMergePolicy => 'Politik zusammenführen';

  @override
  String get gitUiFastForwardWhenPossible =>
      'Wenn möglich, schnell vorankommen';

  @override
  String get gitUiAlwaysCreateAMergeCommit =>
      'Erstellen Sie immer eine Zusammenführungs-Commit';

  @override
  String get gitUiFastForwardOnly => 'Nur schnell voran';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Squash in inszenierte Veränderungen';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Vor dem Erstellen des Commits anhalten';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Fast-Forward ist deaktiviert, damit HEAD vor der Prüfung nicht verschoben werden kann.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Lässt inszenierte Änderungen für eine separate Commit; dies ist kein fortdauerndes Zusammenführen.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'Konflikte bleiben im Workspace für gemeinsame Auflösungen verfügbar.';

  @override
  String get gitUiAddRemote => 'Remote hinzufügen...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Einholen: $arg0 Druck: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Entfernung entfernen...';

  @override
  String get gitUiChangeFetchURL => 'URL zum Abrufen ändern...';

  @override
  String get gitUiAddPushDestination => 'Push-Ziel hinzufügen...';

  @override
  String get gitUiRemovePushDestination => 'Zielort entfernen...';

  @override
  String gitUiManageArg0(String arg0) {
    return '$arg0 verwalten';
  }

  @override
  String get gitUiRemoteName => 'Fernname';

  @override
  String get gitUiNewRemoteName => 'Neuer entfernter Name';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'Repository URL oder lokale Quelle';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Geben Sie das genaue überprüfte Ziel zu entfernen.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Beglaubigungen werden von konfigurierten Helfern oder einer privaten Eingabeaufforderung geliefert.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Entfernt $arg0 entfernt?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Entfernt lokale Remote-Konfiguration und Tracking-Referenzen. Es löscht das Server-Repository nicht.';

  @override
  String get gitUiRemoveRemote2 => 'Fernbedienung entfernen';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Geltungsbereich einbinden: gesamtes Repository';

  @override
  String get gitUiCachedTracking => 'Gespeicherte Verfolgung';

  @override
  String get gitUiAmendLastCommit => 'Letzten Commit ändern';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Konfigurierte Hooks und Signing werden respektiert.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Schreibt den ausgewählten HEAD-Commit um. Remote-Tracking beweist nicht, dass er unveröffentlicht ist.';

  @override
  String get gitUiRepository => 'Repository';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Freistehende $arg0';
  }

  @override
  String get gitUiLog => 'Log';

  @override
  String get gitUiRepositoryActions => 'Repository-Aktionen';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Gespeicherter Tracking-Stand · $upstream · $ahead voraus · $behind zurück';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Bare repository · kein Arbeitsbaum. Öffnen Sie Protokoll, um seine Geschichte zu überprüfen.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Read-only repository · Staging und Commits sind nicht verfügbar.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Repository-Status nicht verfügbar';

  @override
  String gitUiAmendRevision(String revision) {
    return '$revision ändern';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Sign-off-Trailer hinzufügen';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Konfigurierte Signaturrichtlinie verwenden';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Kryptographisch unterzeichnen Sie diese Verpflichtung';

  @override
  String get gitUiDoNotSignThisCommit =>
      'Unterzeichnen Sie diese Verpflichtung nicht';

  @override
  String get gitUiRecentCommitMessages => 'Kürzliche Commit-Nachrichten...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Konfigurierte Commit-Vorlage verwenden...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Author Identity und konfigurierte Hooks...';

  @override
  String get gitUiDraftMessage => 'Entwurfsnachricht...';

  @override
  String get gitUiCommitOptions => 'Commit-Optionen';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Entwurf im Speicher beibehalten; Speichern fehlgeschlagen. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Commit-Nachricht';

  @override
  String get gitUiGitOperationInProgress => 'Laufender Git-Betrieb';

  @override
  String get gitUiCancel => 'Abbrechen';

  @override
  String get gitUiAmendStaged => 'Änderung';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Geplantes Commit ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Commit und Push…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Es ist keine lesbare Commit-Vorlage konfiguriert.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Identität und Haken einbinden';

  @override
  String get gitUiRecentMessages => 'Aktuelle Meldungen';

  @override
  String get gitUiReplaceMessageDraft => 'Nachrichtenentwurf ersetzen?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Ersetzen Sie die bestehende Commit-Nachricht durch die ausgewählte Nachricht?';

  @override
  String get gitUiReplaceDraft => 'Entwurf ersetzen';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Lokales Commit $arg0 existiert.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Lokales Commit $arg0 existiert. Überprüfungsprotokoll vor dem Versuch einer anderen Commit. Der Nachrichtenentwurf wurde beibehalten.';
  }

  @override
  String get gitUiCommitAuthorName => 'Name des Autors Commit';

  @override
  String get gitUiCommitAuthorEmail => 'E-Mail des Autors Commit';

  @override
  String get gitUiConfiguredDefault => 'Voreinstellung konfiguriert';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Unterschrift: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Konfigurierte Haken: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Ein Sign-off-Trailer ist eine Erklärung in der Nachricht und keine kryptografische Signatur. Die Identität wird nur in der lokalen Repository-Konfiguration gespeichert; Ihr Entwurf bleibt erhalten.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Archiv-Identität speichern';

  @override
  String get gitUiStaged => 'Im Index';

  @override
  String get gitUiUntracked => 'Unversioniert';

  @override
  String get gitUiUnstaged => 'Nicht im Index';

  @override
  String get gitUiConflicts => 'Konflikte';

  @override
  String get gitUiNoChanges => 'Keine Änderungen';

  @override
  String get gitUiRepositoryChangeTree => 'Verzeichnis-Veränderungsbaum';

  @override
  String get gitUiChanges => 'Änderungen';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Erweitern';

  @override
  String get gitUiCollapse => 'Zusammenbruch';

  @override
  String get gitUiUnstageFile => 'Datei aus Index entfernen';

  @override
  String get gitUiStageFile => 'Datei zum Index hinzufügen';

  @override
  String get gitUiExpandGroup => 'Gruppe erweitern';

  @override
  String get gitUiCollapseGroup => 'Gruppenzusammenbruch';

  @override
  String get gitUiReviewDifference => 'Überprüfungsdifferenz';

  @override
  String get gitUiUnstageSelectedFiles =>
      'Ausgewählte Dateien aus Index entfernen';

  @override
  String get gitUiStageSelectedFiles =>
      'Ausgewählte Dateien zum Index hinzufügen';

  @override
  String get gitUiFileHistoryAndBlame => 'Dateiverlauf und Schuld...';

  @override
  String get gitUiDeleteUntrackedFile => 'Unverfolgte Datei löschen...';

  @override
  String get gitUiDiscardUnstagedChange =>
      'Nicht inszenierte Veränderungen verwerfen...';

  @override
  String get gitUiFileHistory => 'Dateiverlauf';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Nicht inszeniertes $arg0 verwerfen?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Bytes · $arg1 Ersetzt Arbeitsinhalte durch den Index oder löscht diese untracked Datei. Staged Inhalt wird beibehalten. Nicht gespeicherte Hostdokumente müssen zuerst überprüft werden.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Unverfolgte Datei löschen';

  @override
  String get gitUiDiscardWorkingChange => 'Arbeitsveränderung verwerfen';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'REMOTE-Referenz $arg0 löschen';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'Dies entfernt die Referenz auf jedem tatsächlichen Push-Ziel, das unten aufgeführt ist. Lokale Zweige/Tags werden beibehalten. Die erwarteten Tipps werden durch diese Bewertung behoben.';

  @override
  String get gitUiReferenceDoesNotExist => 'Referenz existiert nicht';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Erwarteter Tipp: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted =>
      'Entferntes Löschen abgeschlossen.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return '$arg0 von der Fernbedienung löschen?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Die oben gezeigten genauen Ziel-Tipps werden entfernt. Jede geänderte entfernte Spitze stoppt den Betrieb für eine weitere Überprüfung.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Überprüfe und lösche von entfernten...';

  @override
  String get gitUiDestinationReference => 'Bezeichnung des Ziels';

  @override
  String get gitUiReviewDestinations => 'Überprüfungsziele';

  @override
  String get gitUiNewRemoteBranch => 'Neuer Remote-Zweig';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · erwartet: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Ein Ziel hat Commits, die lokal nicht verfügbar sind. Besorgen Sie, dass das Ziel überprüft, bevor Sie die ausgehende Geschichte überprüfen.';

  @override
  String get gitUiFetchReviewedDestination =>
      'Begutachtung des Bestimmungsorts';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Wählen Sie ein Ziel und überprüfen Sie die ausgehenden Commits.';

  @override
  String get gitUiNoOutgoingCommits => 'Keine ausgehenden Verpflichtungen';

  @override
  String get gitUiSelectAnOutgoingCommit =>
      'Eine ausgehende Übertragung auswählen';

  @override
  String get gitUiLoadMoreOutgoingCommits => 'Mehr ausgehende Commits laden';

  @override
  String get gitUiSetThisDestinationAsUpstream =>
      'Setzen Sie dieses Ziel als Upstream';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Genaue Tags zum Veröffentlichen auswählen';

  @override
  String get gitUiTagsNone => 'Schlagwörter: keine';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Tags: $arg0 ausgewählt';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Genau veröffentlichen: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push abgeschlossen. Der lokale Commit bleibt in Log verfügbar.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Erzwungenes Pushen erfordert exakt die hier geprüften Spitzen der Zielreferenzen.';

  @override
  String get gitUiForceWithReviewedLease =>
      'Kraft mit überprüftem Mietvertrag...';

  @override
  String get gitUiPush => 'Pushen';

  @override
  String get gitUiForcePushWithReviewedLeases =>
      'Macht Druck mit überprüften Pachtverträge?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Schreiben Sie $arg0 nur um, wenn jedes entfernte Ziel noch die genaue Spitze oben angezeigt hat.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Andere verwenden diese Historie möglicherweise bereits. Ein Abruf im Hintergrund erneuert diese Lease nicht.';

  @override
  String get gitUiForceWithLease => 'Kraft mit Pacht';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Das entfernte Ergebnis ist ungewiss. Prüfen Sie Ziele wieder vor einem weiteren Push.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Eltern $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Fernabfrage zum Abrufen';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Prune entfernt-Tracking-Zweige gelöscht';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Holen Sie Updates Remote-Tracking-Informationen, ohne Arbeitsdateien zu ersetzen.';

  @override
  String get gitUiFetch => 'Abrufen';

  @override
  String get gitUiSourceRemote => 'Quelle entfernt';

  @override
  String get gitUiSourceBranch => 'Quellenzweig';

  @override
  String get gitUiReviewedStrategy => 'Überprüfte Strategie';

  @override
  String get gitUiMerge => 'Zusammenführen';

  @override
  String get gitUiRebase => 'Rebase';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Stoppen Sie, wenn das Ziel nicht beschleunigt werden kann; nie zusammenführen oder neu aufbauen.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Zusammenführen mit einem Merge Commit, auch wenn Fast-Forward möglich ist.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Merge; ermöglichen Sie, wenn möglich, schnell vorwärts.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Lokalgeschichte neu aufbauen und dabei lokale Zusammenführungs-Commits erhalten.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Lokale Commits als lineare Geschichte neu zu begründen.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git ist für interaktives Rebase konfiguriert. Wählen Sie hier explizit eine Pull-Strategie aus oder holen und öffnen Sie Rebase..., um einen Plan zu überprüfen.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Verwendung geprüfter normaler Rebase für diesen Zug';

  @override
  String get gitUiOptions => 'Einstellungen';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Erstellen Sie immer eine Zusammenführungs-Commit (kein Fast-Forward)';

  @override
  String get gitUiPreserveLocalMergeCommits =>
      'Lokale Zusammenführungs-Commits beibehalten';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Lokale Änderungen können das Ziehen verhindern. Überprüfen/kommittieren Sie diese oder erstellen Sie explizit ein Versteck.';

  @override
  String get gitUiStashes => 'Stashes';

  @override
  String get gitUiCreateOrReviewStash =>
      'Erstellen oder überprüfen Sie das Vorratslager...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Ziehen Sie mit ausgewählten Strategie';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'Repository-URL oder lokale Git-Quelle';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH oder lokaler Pfad';

  @override
  String get gitUiFolderToInitialize => 'Ordner zum Initialisieren';

  @override
  String get gitUiFinalCloneDestination => 'Endgültiges Klone-Ziel';

  @override
  String get gitUiChoose => 'Wählen Sie...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Erstellt nur Git-Metadaten. Bestehende Dateien werden nicht inszeniert oder übertragen.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Das endgültige Ziel muss fehlen oder leer sein. Vorhandene Benutzerdaten werden nie überschrieben.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Erster Zweig · leer verwendet effektive Git-Politik';

  @override
  String get gitUiSelectedBranchOptional => 'Ausgewählter Zweig · optional';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Explizit initialisieren/Aktualisierung von Submodulen rekursiv';

  @override
  String get gitUiPreparingGitOperation => 'Git-Operation vorbereiten...';

  @override
  String get gitUiThisAttemptCreated => 'Dieser Versuch';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Das Ziel bestand vor diesem Versuch:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Das Verzeichnis bleibt für die Inspektion. Überprüfen Sie es vor einem weiteren Klonversuch.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Kein Zielverzeichnis bleibt erhalten.';

  @override
  String get gitUiCancelProcess => 'Vorgang abbrechen';

  @override
  String get gitUiInitialize => 'Initialisieren';

  @override
  String get gitUiClone => 'Klonen';

  @override
  String get gitUiChooseNewBase => 'Neue Basis wählen';

  @override
  String get gitUiChooseUpstreamBoundary => 'Upstream-Grenze wählen';

  @override
  String get gitUiNewBase => 'Neue Basis';

  @override
  String get gitUiUpstreamBoundaryExcluded =>
      'Upstream-Grenze · ausgeschlossen';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Wie Upstream-Grenze';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Branch, Tag oder Commit wählen…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Upstream als neue Basis verwenden';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Wählen Sie einen gültigen Zweig, Tag oder Commit aus Log.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Der erste beibehaltene Commit eines Branch-Blocks kann weder Squash noch Fixup sein: Es fehlt ein vorheriger Ziel-Commit.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Zweigblock $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Das Wort verlangt eine neue Nachricht]\n';

  @override
  String get gitUiPlannedCommitMessages => 'Geplante Commit-Nachrichten';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Original/kombinierte Nachrichtenvorschau · Git fordert die letzten Umwort/Squash-Nachrichten';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Ergebnis $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Aktueller Branch: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'Losgelöster HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Rebase schreibt Commit-Identitäten um. Remote-Tracking-Daten beweisen nicht, dass die Historie noch nie veröffentlicht wurde.';

  @override
  String get gitUiIncludeRootCommits => 'Root-Commits einbeziehen';

  @override
  String get gitUiMergeCommits => 'Zusammenführen von Commits';

  @override
  String get gitUiFlattenHistory => 'Historie linearisieren';

  @override
  String get gitUiPreserveBranchStructure => 'Branch-Struktur erhalten';

  @override
  String get gitUiAutosquash => 'Autosquash';

  @override
  String get gitUiPrepareGitPlan => 'Git-Plan vorbereiten';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Zu spielende Komponenten: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Enthält alle root Commits, die von diesem Zweig aus erreichbar sind.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Commits nach $boundary werden auf $base erneut angewendet; der Grenz-Commit selbst ist ausgeschlossen.';
  }

  @override
  String get gitUiRoot => 'Wurzel';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Git-Zweig/Etikett/Reset/Merge-Struktur';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Wählen Sie eine explizite alte Grenze oder Root-Modus, dann bereiten Sie den Plan.';

  @override
  String get gitUiMoveUp => 'Nach oben';

  @override
  String get gitUiMoveDown => 'Nach unten';

  @override
  String get gitUiResetPlan => 'Plan zurücksetzen';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · Zweigblock $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Wählen Sie einen Commit für Details und geänderte Dateien';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Vorschau kombinierte Commit-Nachrichten...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ verschiebt den ausgewählten Commit. Unbezogene Branchenreferenzen werden nicht automatisch aktualisiert.';

  @override
  String get gitUiCancelPlan => 'Plan abbrechen';

  @override
  String get gitUiStartReviewedRebase => 'Begutachtete Datenbank starten?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Rewrite $arg0 plante Commits auf $arg1. Dropped Commits bleiben sichtbar in diesem Plan markiert, bis Sie beginnen.';
  }

  @override
  String get gitUiStartRebase => 'Rebase starten';

  @override
  String get gitUiNoContinuingGitOperation =>
      'Keine Fortsetzung des Git-Betriebs';

  @override
  String get gitUiStoppedForEditingAmend => ' · zum Bearbeiten/Ändern gestoppt';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'Diese sind unverpackte Indexeinträge, möglicherweise aus einer Stash-Anwendung. Git hat keinen Stash-Weiterlauf oder Abbruchbefehl.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Bearbeiten Sie die Arbeitsdateien, stufen und ändern Sie den aktuellen Commit, dann setzen Sie diese Datenbank fort.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · unaufgelöste Index-Stufen $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Der Index hat keine ungelösten Einträge.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Halten Sie den aktuellen Commit als leeren Commit';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Der reale Index hat keine inszenierten Änderungen. Erstellen Sie einen expliziten leeren Commit, dann setzen Sie den Sequenzer fort, wenn er aktiv bleibt.';

  @override
  String get gitUiKeepEmptyCommit => 'Leere Übertragung beibehalten...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git versucht, zum Ausgangspunkt der Operation zurückzukehren. Bereits vorher vorhandene Änderungen außerhalb des Index sowie unversionierte und ungespeicherte Inhalte werden möglicherweise nicht wiederhergestellt.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Überspringen Sie den aktuellen Commit und fahren Sie mit dem nächsten geplanten Commit fort.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Vergessen Sie diese Operation . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Weiter $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Konfliktversionen neu laden?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Ersetzen Sie den nicht gespeicherten Ergebnisentwurf durch die aktuelle Arbeitsdatei. Gespeicherte Arbeitsinhalte werden beibehalten.';

  @override
  String get gitUiLoadingConflictVersions =>
      'Konfliktversionen werden geladen...';

  @override
  String get gitUiLoadingConflict => 'Konflikt wird geladen';

  @override
  String get gitUiBaseLeft => 'Basis → links';

  @override
  String get gitUiBaseRight => 'Basis → rechts';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Kein Grundeintrag für diesen Konflikt';

  @override
  String get gitUiAcceptEntireLeftFile =>
      'Die gesamte linke Datei akzeptieren...';

  @override
  String get gitUiAcceptEntireRightFile =>
      'Akzeptieren Sie die gesamte richtige Datei...';

  @override
  String get gitUiPreviousConflictRegion => 'Frühere Konfliktregion';

  @override
  String get gitUiNextConflictRegion => 'Nächste Konfliktregion';

  @override
  String get gitUiManualResolution => 'Manuelle Auflösung';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Region $arg0/$arg1 · $arg2 geprüft';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Quellenausrichtung überstieg die Textvergleichsgrenze; Quellbereiche bleiben zur manuellen Überprüfung verfügbar.';

  @override
  String get gitUiAcceptLeftRegion => 'Linke Region akzeptieren';

  @override
  String get gitUiAcceptRightRegion => 'Rechte Region akzeptieren';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Manuelles Ergebnis für Region aufbewahren';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Git-nicht-konfliktierende Änderungen anwenden?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Ersetzen Sie den aktuellen Ergebnisentwurf mit der Vorschau von Git . Dadurch werden nicht gespeicherte manuelle Ergebnis-Edits verworfen; die Arbeitsdatei bleibt bis Speichern unverändert.';

  @override
  String get gitUiUseMergePreview => 'Vorschau zum Zusammenführen verwenden';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Nicht-Konflikt-Änderungen anwenden...';

  @override
  String get gitUiLeftSource => 'Linke Quelle';

  @override
  String get gitUiResult => 'Ergebnis';

  @override
  String get gitUiRightSource => 'Rechte Quelle';

  @override
  String get gitUiStage2 => 'Stufe 2';

  @override
  String get gitUiStage3 => 'Stufe 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Conflict-Versionen sind nicht verfügbar. Aktualisieren, um ihren aktuellen Zustand zu überprüfen.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Ergebnis auf der Festplatte gespeichert. Der Index bestimmt immer noch, ob diese Datei aufgelöst wird.';

  @override
  String get gitUiSaveResultDraft => 'Ergebnisentwurf speichern';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Ergebnis anwenden und Auflösung zum Index hinzufügen';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Ergebnis · editierbarer UTF-8 Arbeitsinhalt';

  @override
  String get gitUiEditableConflictResult => 'Bearbeitbares Konfliktergebnis';

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
      'Wählen Sie Inhalte, Löschungen oder ein Submodul ausdrücklich Commit. Binäre Daten werden nicht als editierbarer Text dekodiert.';

  @override
  String get gitUiUseEntireLeftContent =>
      'Den gesamten linken Inhalt verwenden...';

  @override
  String get gitUiUseEntireRightContent =>
      'Den gesamten richtigen Inhalt verwenden...';

  @override
  String get gitUiDeleteThisPath => 'Diesen Pfad löschen...';

  @override
  String get gitUiResolvedSubmoduleCommit => 'Resolved submodule commit';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Setzen Sie diesen genauen Gitlink im übergeordneten System ein. Dies überprüft oder übergibt das Untermodul nicht.';

  @override
  String get gitUiSetResolvedGitlink => 'Behobenen Gitlink einstellen...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Basis → Stufe $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Das Ergebnis wurde bearbeitet. Halten Sie das manuelle Ergebnis oder wählen Sie eine andere unveränderte Region aus.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Auflösung „$arg0“ anwenden?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Legen Sie die gewählte gitlink-Commit im übergeordneten. Das Submodul Checkout und seine Dateien werden nicht ersetzt.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Ersetzt den gesamten Arbeitspfad $arg0 und inszeniert die Entscheidung. Aktueller Arbeitsinhalt und ein nicht gespeicherter Ergebnisentwurf werden verworfen.';
  }

  @override
  String get gitUiApplyEntireFileDecision =>
      'Vollständige Datei-Entscheidung anwenden';

  @override
  String get gitUiStageThisConflictResolution =>
      'Diese Konfliktlösung inszenieren?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Verwenden Sie das gesamte bearbeitete Ergebnis als $arg0. Git zeichnet den aufgelösten Pfad auf, wenn er inszeniert wird. Überprüfen Sie zuerst alle beabsichtigten Inhalte.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Anwenden und zum Index hinzufügen';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Änderungen des Textformats des Ergebnisses überprüfen';

  @override
  String get gitUiSaveReviewedResult => 'Ergebnis speichern';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Native Git Tisch Zugänglichkeit ist nicht verfügbar. Versuchen Sie nach dem erneuten Verbinden der Anwendung.';

  @override
  String get gitUiSans => 'Sans';

  @override
  String get gitUiSelect => 'Wählen';

  @override
  String get gitUiContextMenu => 'Kontextmenü';

  @override
  String get gitUiCopyText => 'Text kopieren';

  @override
  String get gitUiLoadingRow => 'Zeile wird geladen';

  @override
  String get gitUiRetry => 'Erneut versuchen';

  @override
  String get gitUiGitMessage => 'Git-Nachricht';

  @override
  String get gitUiCancelPrompt => 'Eingabeaufforderung abbrechen';

  @override
  String get gitUiUseMessageAndContinue => 'Nachricht verwenden und fortfahren';

  @override
  String get gitUiRespondPrivately => 'Private Antworten';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Einstellungen der Ansicht konnten nicht gespeichert werden: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Entwurf der Speicherung einreichen: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'View-Einstellungen konnten nicht gelesen werden: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Der Entwurf wurde im Speicher beibehalten, konnte aber nicht gespeichert werden: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Das überprüfte Repository ist für diesen Vorgang schreibgeschützt. Historie und Inhaltsinspektion bleiben verfügbar.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git gab $arg0 zurück. Die Anwendung konnte ihre Dokumente nicht aktualisieren: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Commit im Log wählen…';

  @override
  String get gitUiCurrentBranch => 'Aktueller Branch';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Keine passenden Zweige oder Tags. Wählen Sie einen Commit in Log.';

  @override
  String get gitUiBranches => 'Branches';

  @override
  String get gitUiPushCommits => 'Commits pushen';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Ziehen Sie in $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return '$arg0 auflösen';
  }

  @override
  String get gitUiCurrentOperation => 'Laufende Operation';

  @override
  String get gitUiRebaseCommits => 'Commits rebasen';

  @override
  String get gitUiFetch2 => 'Abrufen…';

  @override
  String get gitUiPull => 'Pullen…';

  @override
  String get gitUiPush2 => 'Pushen…';

  @override
  String get gitUiBranches2 => 'Branches…';

  @override
  String get gitUiManageRemotes => 'Remotes verwalten…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Zusammenführen in $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Rebase…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Konflikte und aktuelle Operationen...';

  @override
  String get gitUiStashes2 => 'Stashes…';

  @override
  String get gitUiWorktrees => 'Worktrees…';

  @override
  String get gitUiSubmodules => 'Submodule…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog und Wiederherstellung…';

  @override
  String get gitUiCloneRepository => 'Repository klonen…';

  @override
  String get gitUiRevokeRepositoryTrust =>
      'Vertrauen in die Repository-Repositorys';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Warten auf den Repository-Status';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Repository-Status nicht verfügbar; aktualisieren';

  @override
  String get gitUiManageRemotes2 => 'Remotes verwalten';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Zusammenführen in $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Worktrees';

  @override
  String get gitUiSubmodules2 => 'Submodule';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog und Wiederherstellung';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Clone repository · $arg0';
  }

  @override
  String get gitUiApply => 'Anwenden';

  @override
  String get gitUiResizeGitPanes => 'Größe der Git-Scheiben ändern';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 Prozent';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Status der Ausfahrt: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repository geändert. Aktualisieren und überprüfen, bevor es erneut versucht.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Eine weitere Operation hält das Repository oder Index-Lock. Warten Sie, dann aktualisieren.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Für diese Operation ist ein Repository-Trust erforderlich.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Der Git-Dienst ist getrennt.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Die installierte Git-Ausführbarkeit kann diese Operation nicht unterstützen.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Dieses Repository ist für die angeforderte Operation schreibgeschützt. Überprüfung und Historie bleiben verfügbar.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Die Operation braucht Versöhnung. Überprüfen Sie das resultierende Repository oder den Remote-Status, bevor Sie es wiederholen.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Die Git-Authentifizierung ist fehlgeschlagen. Überprüfen Sie den Anmeldehilfe-Helfer oder entsperren Sie den konfigurierten Schlüsselring.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'SSH Host-Verifikation fehlgeschlagen. Überprüfen Sie die Host-Identität über Ihre konfigurierten SSH-Tools.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Die Signierung ist fehlgeschlagen oder wurde abgesagt. Überprüfen Sie den Signierschlüssel, den Agenten und das konfigurierte Signierwerkzeug.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Legen Sie einen Namen und eine E-Mail des Projektarchivautors fest und kehren Sie dann zum erhaltenen Nachrichtenentwurf zurück.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git lehnte das überprüfte Update ab. Aktualisieren und überprüfen Sie das tatsächliche Ziel, bevor es erneut versucht.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Arbeiten oder inszenierte Änderungen verhindern diese Operation. Überprüfen, Commit oder explizit verstauen.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Ein erforderliches Git-Objekt ist nicht verfügbar. Überprüfen Sie flache oder partielle Repository-Grenzen und holen Sie sich bei Bedarf explizit.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Git-Operation fehlgeschlagen: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnose';

  @override
  String get gitUiAuthorizeGitInspection =>
      'Autorisieren Sie Git Inspektion...';

  @override
  String get gitUiCopyDiagnostics => 'Diagnose kopieren';

  @override
  String get gitUiActions => 'Aktionen';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Zweig bei $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Erstellt einen lokalen Zweig, ohne ihn auszuchecken.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Markierung $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Nur-Lese-Snapshot · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Kirschenpflücker-Verpflichtungen';

  @override
  String get gitUiRevertCommits => 'Übertragungen rückgängig machen';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Vergleichen mit der vollständigen Revisions-ID';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Baumvergleichsrichtung: $arg0 → die hier eingegebene Revision.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Geben Sie eine vollständige gültige Objekt-ID ein.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · Baumvergleich';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return '$arg0 auf $arg1 zurücksetzen';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Verschiebt HEAD/den aktuellen Branch. Reflog stellt keine beliebigen unversionierten oder ungespeicherten Inhalte wieder her.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'HEAD verschieben; Index und Arbeitsdateien beibehalten.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'HEAD verschieben und Index ersetzen; Arbeitsdateien beibehalten.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'HEAD, Index und versionierte Arbeitsdateien ersetzen; im Weg liegende unversionierte Dateien können überschrieben werden.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'HEAD, Index und geeignete Dateien ersetzen; ablehnen, falls lokale Änderungen verloren gingen.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Mit $arg0 zurücksetzen?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Überprüfen Sie vor der Anwendung die ausgewählten Effekte des Modus.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return '$arg0 zurücksetzen';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Ziel $arg0';
  }

  @override
  String get gitUiTagName => 'Tag-Name';

  @override
  String get gitUiAnnotatedTag => 'Annotierter Tag';

  @override
  String get gitUiCryptographicSigning => 'Kryptografische Signatur';

  @override
  String get gitUiConfiguredPolicy => 'Konfigurierte Richtlinie';

  @override
  String get gitUiSignThisTag => 'Dieses Tag unterschreiben';

  @override
  String get gitUiDoNotSign => 'Nicht unterzeichnen';

  @override
  String get gitUiTagMessage => 'Markierungsnachricht';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Erstellt das Tag lokal. Veröffentlichen Sie ausgewählte Tags explizit in Push-Review.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Vollständige Bäume: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Nächste geänderte Datei-Seite';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Nur-Lese-Repository-Snapshot. Das Öffnen einer Datei überprüft diese Revision nie.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Nur Lese-Version öffnen';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Wiederherstellen dieses Pfades... · Warten auf den Projektarchiv-Status';

  @override
  String get gitUiRestoreThisPath => 'Wiederherstellen Sie diesen Pfad...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Geschichte · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return '$arg0 wiederherstellen?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Ersetzen Sie diesen Arbeitspfad durch Revision $arg0. Bestehende inszenierte Inhalte werden beibehalten.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Arbeitsdatei wiederherstellen';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Dateiverlauf folgt den Umbenennungen · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent => 'Zeilenhistorie · Commit-Inhalt';

  @override
  String get gitUiBlame => 'Zeilenhistorie…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Arbeitsbaum';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Öffne die schreibgeschützte historische Datei';

  @override
  String get gitUiCompareToCurrentFile => 'Mit der aktuellen Datei vergleichen';

  @override
  String get gitUiCompareToParent => 'Vergleichen Sie mit Eltern...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Committed $arg0 · nicht gespeicherter Editorinhalt ist nicht Teil dieser Anmerkungen';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Geschichte von $arg0';
  }

  @override
  String get gitUiBoundary => ' · Grenze';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nUrsprüngliche Zeile $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Vorherige Zeilen';

  @override
  String get gitUiNextLines => 'Nächste Zeilen';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Explizite Anwendung Reihenfolge · Ziel $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Vollständige Objekt-ID hinzufügen';

  @override
  String get gitUiAddReviewedCommit => 'Reviewed Commit hinzufügen...';

  @override
  String get gitUiMoveEarlier => 'Frühere Bewegung';

  @override
  String get gitUiMoveLater => 'Später verschieben';

  @override
  String get gitUiRemoveFromReviewedSequence =>
      'Aus der überprüften Reihenfolge entfernen';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Änderungen anwenden, ohne Commits zu erstellen';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Verwenden Sie diese explizite Mainline parent für merge commits';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Leere oder bereits angewandte Verpflichtungen können Git für eine explizite Skip- oder Continuation-Entscheidung stoppen.';

  @override
  String get gitUiRevertInReviewedOrder =>
      'Rückgängig machen in überprüfter Reihenfolge';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Cherry-pick in geprüfter Reihenfolge';

  @override
  String get gitUiReturnToFiles => 'Zurück zu Dateien';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Commit';

  @override
  String get gitUiBackToCommit => 'Zurück zu Commit';

  @override
  String get gitUiSelectAChangeToReview =>
      'Wählen Sie eine Änderung zur Überprüfung';

  @override
  String get gitUiLoadingBranch => 'Zweig wird geladen...';

  @override
  String get gitUiBranchUnavailable => 'Zweig nicht verfügbar';

  @override
  String get gitUiUnbornHEAD => 'HEAD ohne Commit';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'Losgelöster HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'Fortsetzen';

  @override
  String get gitUiPick => 'Übernehmen';

  @override
  String get gitUiReword => 'Nachricht ändern';

  @override
  String get gitUiEdit => 'Bearbeiten';

  @override
  String get gitUiSquash => 'Zusammenfassen';

  @override
  String get gitUiFixup => 'Zusammenfassen ohne Nachricht';

  @override
  String get gitUiDrop => 'Auslassen';

  @override
  String get gitUiAbort => 'Abbrechen';

  @override
  String get gitUiSkip => 'Überspringen';

  @override
  String get gitUiQuit => 'Betrieb einstellen';

  @override
  String get gitUiSoft => 'Soft';

  @override
  String get gitUiMixed => 'Mixed';

  @override
  String get gitUiHard => 'Hard';

  @override
  String get gitUiKeep => 'Keep';

  @override
  String get gitUiCreate => 'Erstellen';

  @override
  String get gitUiApplyStash => 'Stash anwenden';

  @override
  String get gitUiPopStash => 'Stash anwenden und bei Erfolg entfernen';

  @override
  String get gitUiDropStashAction => 'Stash verwerfen';

  @override
  String get gitUiEditedResult => 'Bearbeitetes Ergebnis';

  @override
  String get gitUiLeftContent => 'Linker Inhalt';

  @override
  String get gitUiRightContent => 'Rechte Inhalte';

  @override
  String get gitUiDeletePath => 'Pfad löschen';

  @override
  String get gitUiSubmoduleCommit => 'Teilmodul Commit';

  @override
  String get gitUiPresentContent => 'Verfügbarer Inhalt';

  @override
  String get gitUiAbsentContent => 'Keine';

  @override
  String get gitUiBinaryContent => 'Binärer Inhalt';

  @override
  String get gitUiTooLargeContent => 'Inhalt überschreitet die Anzeigegrenze';

  @override
  String get gitUiUnavailableContent => 'Nicht verfügbarer Inhalt';

  @override
  String get gitUiGitlinkContent => 'Untermodulzeiger';

  @override
  String get gitUiSymlinkContent => 'Symbolische Verbindung';

  @override
  String get gitUiNoOperation => 'Kein Betrieb';

  @override
  String get gitUiCherryPickOperation => 'Cherry-Pick';

  @override
  String get gitUiRevertOperation => 'Rückgängig-Commit';

  @override
  String get gitUiApplyMailboxOperation => 'Patches anwenden';

  @override
  String get gitUiSquashOperation => 'Zusammenführung von Squash';

  @override
  String get gitUiUnmergedOperation => 'Nicht zusammengetragener Index';

  @override
  String get gitUiWaitingForPromptPhase => 'Warten auf Ihre Antwort';

  @override
  String get gitUiStoppedPhase => 'Zur Überprüfung eingestellt';

  @override
  String get gitUiCompletedPhase => 'Abgeschlossen';

  @override
  String get gitUiFailedPhase => 'Fehlgeschlagen';

  @override
  String get gitUiCancelledPhase => 'Abgebrochen';

  @override
  String get gitUiUncertainPhase => 'Ergebnis erfordert Aussöhnung';

  @override
  String gitUiStageVersion(String stage) {
    return 'Konfliktstadium $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Git-Merge-Vorschau';

  @override
  String get gitUiNormalizedWorking => 'Arbeitsbaum · Git normalisiert';

  @override
  String gitUiPercentValue(String value) {
    return '$value Prozent';
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
  String get gitUiUtf8Bom => 'UTF-8 mit Byte-Order-Zeichen (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 ohne Byte-Order-Zeichen (BOM)';

  @override
  String get gitUiAddsBom =>
      'Diese Editierung fügt am Anfang der Datei ein UTF-8 Byte-Order-Zeichen (BOM) hinzu.';

  @override
  String get gitUiRemovesBom =>
      'Diese Editierung entfernt das UTF-8 Byte-Order-Zeichen (BOM) vom Anfang der Datei.';

  @override
  String get gitUiNoLineTerminators => 'Keine Zeilenterminatoren';

  @override
  String gitUiLineEndings(String format) {
    return '$format-Zeilenenden';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Gemischte Zeilenenden ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · keine endgültige LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Zeilenende Format ändert sich von $before auf $after. Zwischenablage Text kann verschiedene Zeilenende von der ursprünglichen Datei verwenden.';
  }

  @override
  String get gitUiGitFailure =>
      'Git-Operation fehlgeschlagen. Überprüfen Sie die Diagnose unten.';

  @override
  String get gitUiAbortInline => 'Abbrechen';

  @override
  String get gitUiSkipInline => 'Überspringen';

  @override
  String get gitUiQuitInline => 'Beenden';

  @override
  String get gitUiMergeInline => 'Zusammenführen';

  @override
  String get gitUiRebaseInline => 'Rebase';

  @override
  String get gitUiCherryPickInline => 'Cherry-Pick';

  @override
  String get gitUiRevertInline => 'Rückgängig-Commit';

  @override
  String get gitUiApplyMailboxInline => 'AnwendungMailbox';

  @override
  String get gitUiSquashInline => 'Zusammenfassen';

  @override
  String get gitUiUnmergedInline => 'nicht gesäumt';

  @override
  String get gitHostFetch => 'Abrufen';

  @override
  String get gitHostRefreshGitStatus => 'Git-Status aktualisieren';

  @override
  String get gitHostCommitStaged => 'Eintreten ins Leben gerufen';

  @override
  String get gitHostGitBranches => 'Git-Zweige';

  @override
  String get gitHostReviewPush => 'Überprüfungsschub';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Git-Operationen gelten für dieses gesamte Repository und können seine konfigurierten Hooks, Filter, Anmelde- und Signierwerkzeuge ausführen.';

  @override
  String get gitHostContentUnavailable => 'Inhalt nicht verfügbar';

  @override
  String get gitHostInitializeRepository => 'Repository initialisieren';

  @override
  String get gitHostCloneRepository => 'Repository klonen';

  @override
  String get gitHostInitializeHere => 'Initialisieren Sie hier...';

  @override
  String get gitHostCloneRepository2 => 'Repository klonen…';

  @override
  String get gitHostGitLog => 'Git-Protokoll';

  @override
  String get gitUiAbsentPlaceholder => '(abwesend)';

  @override
  String get gitUiUnborn => 'ungeboren';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Neu basierte Historie · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Aktuelle Historie · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Erneut angewendeter Commit · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Eingehender Inhalt · $revision';
  }

  @override
  String get gitUiContentConflict => 'Inhaltliche Konflikte';

  @override
  String get gitUiSubmoduleConflict => 'Submodul-Konflikt';

  @override
  String get gitUiSymlinkConflict => 'Symbolischer Link-Konflikt';

  @override
  String get gitUiAddAddConflict => 'Auf beiden Seiten hinzugefügt';

  @override
  String get gitUiModifyDeleteConflict =>
      'Geändert/gelöscht oder umbenannt/gelöscht';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }
}
