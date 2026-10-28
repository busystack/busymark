// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get notesNewFromRetainedText => 'Nowa notatka z zachowanego tekstu';

  @override
  String get notesAccountThrottled =>
      'Nextcloud prosi o przerwę. Zaczekaj przed ponownym logowaniem.';

  @override
  String get notesSettingsRefreshing =>
      'Odświeżanie Notes po potwierdzeniu ustawień';

  @override
  String get notesExportOperationFailed =>
      'Eksport nie został opublikowany. Sprawdź źródło i miejsce docelowe, a następnie ponów.';

  @override
  String get notesRecoveryCreatedNotOpened =>
      'Odzyskana notatka została zapisana, ale nie otwarta. Rozwiąż oczekujące zmiany edytora lub właściwości i otwórz tę istniejącą notatkę.';

  @override
  String get notesSettingsPendingNotes =>
      'Oczekujące notatki, konflikty lub niepewne utworzenia blokują zmianę. Zsynchronizuj lub sprawdź je w Notes, potem ponów zapis zachowanej wersji roboczej ustawień.';

  @override
  String get notesSettingsPendingAttachments =>
      'Operacje załączników blokują zmianę. Sprawdź załączniki w Notes, potem ponów zapis zachowanej wersji roboczej ustawień.';

  @override
  String get notesAccountServerAddress =>
      'Użyj kanonicznego adresu HTTPS Nextcloud i zaloguj się ponownie. Nie udało się zweryfikować adresu lub przekierowania.';

  @override
  String get notesAccountUnsupported =>
      'Notes jest niedostępne lub API nieobsługiwane. Włącz Nextcloud Notes z główną wersją API 1 i podrzędną co najmniej 4.';

  @override
  String get notesAccountAuthorizeAgain =>
      'Nextcloud odrzucił dane logowania. Ponownie autoryzuj konto lub połącz je.';

  @override
  String get notesAccountCheckForbidden =>
      'Nextcloud zabronił sprawdzenia możliwości Notes. Poproś administratora o zgodę i ponów.';

  @override
  String get notesAccountMalformed =>
      'Nie udało się zweryfikować odpowiedzi Nextcloud. Sprawdź instalację serwera i zaloguj się ponownie.';

  @override
  String get notesAccountTimedOut =>
      'Czas logowania upłynął. Rozpocznij ponownie i dokończ autoryzację w przeglądarce.';

  @override
  String get notesAccountBrowserUnavailable =>
      'Nie udało się otworzyć przeglądarki systemowej. Sprawdź domyślną przeglądarkę i ponów logowanie.';

  @override
  String get notesAccountNetwork =>
      'Nextcloud jest nieosiągalny. Sprawdź połączenie i serwer, a następnie ponów logowanie.';

  @override
  String get notesAccountRejected =>
      'Nextcloud odrzucił żądanie możliwości. Sprawdź dostęp z administratorem i ponów.';

  @override
  String get notesAccountFailed =>
      'Nie udało się skonfigurować konta. Zaloguj się ponownie.';

  @override
  String get notesTransferSourceChanged =>
      'Źródło zmieniło się po przeglądzie. Sprawdź bieżący plik lub utwórz nową migawkę przed ponowieniem.';

  @override
  String get notesTransferUnreadable =>
      'Nie można odczytać źródła. Sprawdź dostęp do pliku lub katalogu i przejrzyj ponownie.';

  @override
  String get notesTransferInvalidSnapshot =>
      'Migawka jest nieprawidłowa lub nieobsługiwana. Wybierz poprawną migawkę BusyMark Notes lub źródło Markdown.';

  @override
  String get notesTransferMediaLimit =>
      'Media przekraczają limit importu. Zmniejsz media danego elementu i przejrzyj ponownie.';

  @override
  String get notesTransferUnsafeSource =>
      'Źródło zawiera niebezpieczną ścieżkę. Wybierz pliki wewnątrz katalogu źródłowego i przejrzyj ponownie.';

  @override
  String get notesTransferDestination =>
      'Nie można zapisać eksportu. Sprawdź dostęp i wolne miejsce w miejscu docelowym i ponów.';

  @override
  String get notesTransferOperationFailed =>
      'Transfer nie został ukończony. Sprawdź elementy i ponów. Wcześniej zaimportowane elementy pozostają zapisane.';

  @override
  String get notesExportPublishedWithOmissions =>
      'Eksport dostępny z pominięciami';

  @override
  String get notesBatchUnchanged => 'Żądane wartości były już ustawione.';

  @override
  String get notesBatchReadOnly =>
      'Notatka jest tylko do odczytu. Nie można zmieniać chronionych właściwości; Ulubione pozostaje dozwolone.';

  @override
  String get notesBatchReviewChanged =>
      'Notatka zmieniła się po przeglądzie. Sprawdź jej aktualny stan przed ponowieniem działania.';

  @override
  String get notesBatchMissing =>
      'Notatka nie jest już dostępna. Odśwież listę i sprawdź wybrane elementy.';

  @override
  String get notesBatchStorage =>
      'Zapis lokalny nie powiódł się. Sprawdź pamięć i ponów ten element; udane elementy są zapisane.';

  @override
  String get notesRemoteReviewChanged =>
      'Notatka na serwerze się zmieniła. Wersja robocza scalania jest zachowana. Sprawdź nowe porównanie i ponownie wybierz rozwiązanie.';

  @override
  String get notesReviewRemote => 'Sprawdzono aktualną wersję na serwerze';

  @override
  String get wsModuleCapsNotPublished =>
      'Reguła wielkości liter modułu nie jest publikowana.';

  @override
  String get wsTitleOverridesAction => 'Tytuły instancji i spisu treści…';

  @override
  String get wsHeadingNotPublished => 'Ten generator tego nie publikuje.';

  @override
  String get wsMarkdownInstanceTitleLimitation =>
      'Przypięty builder nie publikuje tytułów instancji w tematach Markdown. Istniejące znaczniki są zachowane; sprawdź źródło.';

  @override
  String get wsTopicIdentity => 'ID tematu';

  @override
  String get wsElementAnchor => 'Kotwica elementu';

  @override
  String get wsHeadingText => 'Tekst nagłówka';

  @override
  String get wsDefaultTitle => 'Tytuł domyślny';

  @override
  String get wsTopicNavigation => 'Nawigacja tematu';

  @override
  String get wsHeadingOptions => 'Atrybuty nagłówka';

  @override
  String get wsDocumentOptions => 'Ustawienia dokumentu';

  @override
  String get wsSettingsPresent => 'Obecne jawne ustawienia';

  @override
  String get wsTitleOverrideExplanation =>
      'Zastępuje opublikowany tytuł; tekst nagłówka pozostaje bez zmian.';

  @override
  String get wsIgnoreVariables => 'Traktuj zmienne jako tekst dosłowny';

  @override
  String get wsIgnoreVariablesExplanation =>
      'Po włączeniu tekst przypominający zmienne nie jest podstawiany.';

  @override
  String get wsInstanceSelection => 'Instancje pomocy';

  @override
  String get wsInstanceExplanation =>
      'Wybierz wyjścia pomocy za pomocą nazw, grup, list, wykluczeń lub wyrażeń.';

  @override
  String get wsFilterExplanation =>
      'Filtruje treść wielokrotnego użytku według kryteriów; nie wybiera instancji pomocy.';

  @override
  String get wsContextHelp => 'ID pomocy kontekstowej';

  @override
  String get wsCapitalization => 'Wielkość liter';

  @override
  String get wsLibraryTopic => 'Temat biblioteki';

  @override
  String get wsLastModified => 'Ostatnia zmiana';

  @override
  String get wsMissingTopicHeading => 'Brak H1 tematu. Dodaj go w źródle.';

  @override
  String get wsMultipleTopicHeadings =>
      'Pierwszy H1 określa tytuł tematu. Kolejne H1 są osobnymi nagłówkami.';

  @override
  String get wsTopicIdentityMismatch =>
      'Id korzenia różni się od ID z nazwy pliku. Użyj zmiany nazwy pliku tematu lub sprawdź źródło.';

  @override
  String get wsUnsupportedProperties =>
      'Nieobsługiwane atrybuty są zachowane. Sprawdź je w źródle.';

  @override
  String get wsGeneratedAnchor =>
      'Wygenerowana kotwica; wpisanie wartości tworzy nadpisanie.';

  @override
  String get wsHeadingBuilderLimitation =>
      'Przypięty builder nie publikuje atrybutów H1. Należą do nagłówka, nie korzenia XML.';

  @override
  String get closeOtherTabs => 'Zamknij pozostałe karty';

  @override
  String get tocTopicFromTemplate => 'Temat z szablonu...';

  @override
  String get tocSaveAsTemplate => 'Zapisz jako szablon';

  @override
  String get tocTemplateDialog => 'Utwórz temat z szablonu';

  @override
  String get tocTemplatesEditor => 'Szablony plików i kodu';

  @override
  String get tocEditTemplates => 'Edytuj szablony...';

  @override
  String get tocCreateCustomTemplate => 'Utwórz własny szablon...';

  @override
  String get tocTemplateCreated => 'Utworzono szablon';

  @override
  String get tocTemplateDefault => 'Domyślne';

  @override
  String get tocTemplateCustom => 'Własne';

  @override
  String get tocTemplateFilename => 'Nazwa pliku:';

  @override
  String get tocTemplateMarkdown => 'Markdown (.md)';

  @override
  String get tocTemplateXml => 'XML (.topic)';

  @override
  String get tocTemplatesInternal => 'Wewnętrzne';

  @override
  String get tocTemplateUnnamed => 'Bez nazwy';

  @override
  String get tocTemplateNew => 'Nowy szablon...';

  @override
  String get tocTemplateName => 'Nazwa:';

  @override
  String get tocTemplateExtension => 'Rozszerzenie:';

  @override
  String get tocTemplateLoadError =>
      'Nie można wczytać szablonów. Istniejące szablony nie zostały zmienione.';

  @override
  String get tocTemplateSaveError =>
      'Nie można zapisać szablonów. Twoje zmiany są nadal dostępne tutaj.';

  @override
  String get tocTemplateConflict =>
      'Szablony zmieniono w innym oknie. Anuluj i ponownie otwórz edytor.';

  @override
  String get tocTemplateDuplicateName =>
      'Szablon o tej nazwie i rozszerzeniu już istnieje.';

  @override
  String get tocTemplateFormat => 'Format:';

  @override
  String get tocTemplateReset => 'Przywróć';

  @override
  String get tocTemplateRetry => 'Ponów';

  @override
  String tocRemoveElementsDialog(int count) {
    return 'Usuń $count elementów spisu treści';
  }

  @override
  String get tocRemoveElementsRetainFiles =>
      'Pliki źródłowe powiązane z tymi elementami spisu treści nie zostaną usunięte.';

  @override
  String get tocOk => 'OK';

  @override
  String get tocSelectExistingTopic =>
      'Wybierz temat do dodania do bieżącej instancji';

  @override
  String get tocGroupName => 'Nazwa grupy';

  @override
  String get tocMoveLineUp => 'Przenieś wiersz w górę';

  @override
  String get tocMoveLineDown => 'Przenieś wiersz w dół';

  @override
  String get tocEmptyMdTopic => 'Pusty temat MD';

  @override
  String get tocEmptyXmlTopic => 'Pusty temat XML';

  @override
  String get tocCopySpecial => 'Kopiowanie specjalne';

  @override
  String tocCopyFileName(String name) {
    return 'Nazwa pliku tematu \'$name\'';
  }

  @override
  String get tocCopyFilePath => 'Ścieżka pliku tematu';

  @override
  String tocCopyTopicTitle(String title) {
    return 'Tytuł tematu \'$title\'';
  }

  @override
  String tocCopyElementId(String id) {
    return 'ID elementu spisu treści \'$id\'';
  }

  @override
  String get tocCopyFileNameUnavailable => 'Nazwa pliku tematu';

  @override
  String get tocCopyTopicTitleUnavailable => 'Tytuł tematu';

  @override
  String get tocCopyElementIdUnavailable => 'ID elementu spisu treści';

  @override
  String get tocEditTitleAction => 'Edytuj tytuł...';

  @override
  String get tocEditTitleDialog => 'Edytuj tytuł';

  @override
  String get tocRemoveElementAction => 'Usuń element spisu treści...';

  @override
  String get tocSetHomePage => 'Ustaw jako stronę główną';

  @override
  String tocGoToElement(String fileName) {
    return 'Przejdź do elementu spisu treści w „$fileName”';
  }

  @override
  String get tocSynchronize => 'Synchronizuj spis treści i edytor';

  @override
  String get tocEmptyGroupAction => 'Pusta grupa';

  @override
  String get tocNewEmptyGroup => 'Nowa pusta grupa';

  @override
  String get tocGroupAction => 'Grupuj';

  @override
  String get tocNewGroup => 'Nowa grupa';

  @override
  String get tocSortChildren => 'Sortuj tematy podrzędne alfabetycznie';

  @override
  String get tocLinkTopicFiles => 'Połącz pliki tematów ze spisem treści...';

  @override
  String get addLocalMarkdownFiles => 'Dodaj lokalne pliki Markdown';

  @override
  String get tocTitleField => 'Tytuł w spisie treści:';

  @override
  String get tocTopicTitleField => 'Tytuł tematu:';

  @override
  String get tocAdvancedSettings => 'Ustawienia zaawansowane';

  @override
  String tocInstanceTitleField(String instanceId) {
    return 'Tytuł dla „$instanceId”:';
  }

  @override
  String get tocOnlyTitleField => 'Tytuł tylko w spisie treści:';

  @override
  String get tocInstanceTitleExplanation =>
      'Używany tylko w bieżącej instancji. Domyślnie dziedziczony z tytułu tematu.';

  @override
  String get tocOnlyTitleExplanation =>
      'Używany tylko w spisie treści. Domyślnie dziedziczony z tytułu tematu lub tytułu instancji, jeśli został ustawiony. Objaśnienia tytułów znajdziesz';

  @override
  String get tocTitleDocumentationLink => 'tutaj';

  @override
  String get tocFindUsages => 'Znajdź';

  @override
  String get tocRefactorMenu => 'Refaktoryzacja';

  @override
  String get tocSafeDelete => 'Bezpieczne usuwanie';

  @override
  String get tocDuplicate => 'Duplikuj';

  @override
  String get tocDuplicateFilename => 'Nazwa pliku tematu:';

  @override
  String get tocDuplicateDialog => 'Duplikuj temat';

  @override
  String get pdfTitlePage => 'Strona tytułowa';

  @override
  String get pdfIncludeTitlePage => 'Dołącz stronę tytułową';

  @override
  String get pdfTitlePageNote =>
      'Ta strona nie zawiera nagłówka, stopki ani widocznego numeru strony.';

  @override
  String get pdfTitlePageTitle => 'Tytuł';

  @override
  String get pdfTitlePageSubtitle => 'Podtytuł';

  @override
  String get pdfTitlePageAuthor => 'Autor';

  @override
  String get pdfTitlePageOrganization => 'Organizacja';

  @override
  String get pdfTitlePageVersion => 'Wersja';

  @override
  String get pdfTitlePageDate => 'Data';

  @override
  String get pdfTitlePageTitleRequired => 'Wpisz tytuł strony tytułowej.';

  @override
  String get pdfTocSectionNote =>
      'Zaczyna się na osobnej stronie i może zajmować wiele stron.';

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Edytor plików Markdown i projektów dokumentacji zgodnych z Writerside.';

  @override
  String get aboutBusyMark => 'O aplikacji BusyMark';

  @override
  String get aboutTagline => 'Edytor Markdown i Writerside';

  @override
  String get aboutLicenseLabel => 'Licencja';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Strona internetowa';

  @override
  String get aboutSourceCode => 'Kod źródłowy';

  @override
  String get reportIssue => 'Zgłoś problem';

  @override
  String get feedbackCategory => 'Kategoria';

  @override
  String get feedbackChooseCategory => 'Wybierz kategorię';

  @override
  String get feedbackCategoryProblem => 'Problem lub błąd';

  @override
  String get feedbackCategoryFeature => 'Prośba o funkcję';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Obawy dotyczące prywatności lub bezpieczeństwa';

  @override
  String get feedbackCategoryUsability => 'Problem z użytecznością';

  @override
  String get feedbackCategoryOther => 'Inne';

  @override
  String get feedbackSubject => 'Temat';

  @override
  String get feedbackMessage => 'Szczegółowa wiadomość';

  @override
  String get feedbackReplyEmail => 'Adres e-mail do odpowiedzi (opcjonalnie)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Dołącz dane techniczne';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Po włączeniu dodawane są wyłącznie wersja systemu operacyjnego Linux i ustawienia regionalne aplikacji BusyMark. Nie są dołączane dzienniki, pliki, dane konta ani inne dane diagnostyczne.';

  @override
  String get feedbackSubmit => 'Wyślij';

  @override
  String get feedbackSubmitting => 'Wysyłanie…';

  @override
  String get feedbackCategoryRequired => 'Wybierz kategorię.';

  @override
  String get feedbackSubjectLength => 'Temat musi mieć od 3 do 120 znaków.';

  @override
  String get feedbackMessageLength =>
      'Wiadomość musi mieć od 10 do 5000 znaków.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Wpisz prawidłowy adres e-mail albo pozostaw to pole puste.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark nie mógł się połączyć. Sprawdź połączenie z Internetem i spróbuj ponownie.';

  @override
  String get feedbackTimeoutFailure =>
      'Upłynął limit czasu żądania. Spróbuj ponownie.';

  @override
  String get feedbackRateLimitedFailure =>
      'Z tego połączenia wysłano zbyt wiele zgłoszeń. Poczekaj i spróbuj ponownie.';

  @override
  String get feedbackRejectedFailure =>
      'Serwer odrzucił zgłoszenie. Sprawdź pola formularza i spróbuj ponownie.';

  @override
  String get feedbackServerFailure =>
      'Serwer nie mógł przyjąć zgłoszenia. Spróbuj ponownie później.';

  @override
  String feedbackSuccess(String id) {
    return 'Opinia została wysłana. Identyfikator referencyjny: $id';
  }

  @override
  String get advanced => 'Zaawansowane';

  @override
  String get addToGit => 'Dodaj do Git';

  @override
  String get appearance => 'Wygląd';

  @override
  String get apply => 'Zastosuj';

  @override
  String get back => 'Wstecz';

  @override
  String get bottomLeft => 'Na dole po lewej';

  @override
  String get bottomRight => 'Na dole po prawej';

  @override
  String get cancel => 'Anuluj';

  @override
  String get choose => 'Wybierz';

  @override
  String get chooseLocation => 'Wybierz lokalizację';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copyPlainText => 'Kopiuj jako zwykły tekst';

  @override
  String get clipboardCopyFailed =>
      'Nie udało się skopiować zaznaczenia do schowka.';

  @override
  String get copyName => 'Kopiuj nazwę';

  @override
  String get copyFileName => 'Kopiuj nazwę pliku';

  @override
  String get copyPath => 'Kopiuj ścieżkę';

  @override
  String get create => 'Utwórz';

  @override
  String get creating => 'Tworzenie...';

  @override
  String get cut => 'Wytnij';

  @override
  String get promoteSection => 'Podnieś rangę sekcji';

  @override
  String get demoteSection => 'Obniż rangę sekcji';

  @override
  String get moveSectionUp => 'Przenieś sekcję wyżej';

  @override
  String get moveSectionDown => 'Przenieś sekcję niżej';

  @override
  String get confirmDeleteSectionTitle => 'Usunąć sekcję?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Usunąć „$name” i całą zawartość tej sekcji? Tej operacji nie można cofnąć.';
  }

  @override
  String get darkTheme => 'Ciemny';

  @override
  String get delete => 'Usuń';

  @override
  String get discard => 'Odrzuć';

  @override
  String get editor => 'Edytor';

  @override
  String get file => 'Plik';

  @override
  String get fileHistory => 'Historia pliku';

  @override
  String get folder => 'Folder';

  @override
  String get insert => 'Wstaw';

  @override
  String get keyboardShortcuts => 'Skróty klawiaturowe';

  @override
  String get commandUnavailableInContext =>
      'To polecenie nie jest dostępne w bieżącym kontekście.';

  @override
  String get lightTheme => 'Jasny';

  @override
  String get mainMenu => 'Menu główne';

  @override
  String get fullScreen => 'Pełny ekran';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Otwórz';

  @override
  String get openInFiles => 'Otwórz w Plikach';

  @override
  String get pathActions => 'Działania na ścieżce';

  @override
  String get outline => 'Konspekt';

  @override
  String get overwrite => 'Nadpisz';

  @override
  String get paste => 'Wklej';

  @override
  String get reading => 'Widok do czytania';

  @override
  String get removeFromRecent => 'Usuń z ostatnich';

  @override
  String get recent => 'Ostatnie';

  @override
  String get redo => 'Ponów';

  @override
  String get save => 'Zapisz';

  @override
  String get search => 'Szukaj';

  @override
  String get selectAll => 'Zaznacz wszystko';

  @override
  String get settings => 'Ustawienia';

  @override
  String get source => 'Źródło';

  @override
  String get split => 'Dzielony';

  @override
  String get systemTheme => 'Systemowy';

  @override
  String get theme => 'Motyw';

  @override
  String get appLanguage => 'Język aplikacji';

  @override
  String get systemLanguage => 'Systemowy';

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
  String get toggleSidebar => 'Panel boczny';

  @override
  String get topLeft => 'U góry po lewej';

  @override
  String get topRight => 'U góry po prawej';

  @override
  String get undo => 'Cofnij';

  @override
  String get validate => 'Sprawdź poprawność';

  @override
  String get validation => 'Sprawdzanie poprawności';

  @override
  String get viewMode => 'Tryb widoku';

  @override
  String get welcome => 'Witaj';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Obrazy';

  @override
  String get openMarkdownFile => 'Otwórz plik Markdown';

  @override
  String get markdownFileExtensions => '.md lub .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Otwórz folder lub projekt Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Folder z plikami Markdown lub projekt zgodny z Writerside';

  @override
  String get noOpenFile => 'Brak otwartego pliku';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Usuń wybrany element w widoku Pliki lub usuń wybrany temat ze spisu treści';

  @override
  String get shortcutGroupGeneral => 'Ogólne';

  @override
  String get shortcutNewDocument => 'Utwórz';

  @override
  String get shortcutNewDocumentDescription =>
      'Utwórz plik Markdown lub projekt Writerside';

  @override
  String get shortcutOpenDescription =>
      'Otwórz plik Markdown, folder lub projekt Writerside';

  @override
  String get shortcutSaveDescription => 'Zapisz bieżący dokument';

  @override
  String get shortcutSearchDescription => 'Przeszukaj bieżący obszar roboczy';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Dostosuj skróty klawiaturowe aplikacji';

  @override
  String get shortcutSyntaxReferenceDescription =>
      'Otwórz dokumentację składni';

  @override
  String get shortcutSettingsDescription => 'Otwórz ustawienia BusyMark';

  @override
  String get shortcutNextTab => 'Następna karta';

  @override
  String get shortcutNextTabDescription =>
      'Przejdź do następnej otwartej karty';

  @override
  String get shortcutPreviousTab => 'Poprzednia karta';

  @override
  String get shortcutPreviousTabDescription =>
      'Przejdź do poprzedniej otwartej karty';

  @override
  String get shortcutCloseTab => 'Zamknij kartę';

  @override
  String get shortcutCloseTabDescription => 'Zamknij aktywną kartę';

  @override
  String get shortcutCloseAllTabs => 'Zamknij wszystkie karty';

  @override
  String get shortcutCloseAllTabsDescription =>
      'Zamknij wszystkie otwarte karty';

  @override
  String get shortcutGroupTextEditing => 'Edycja tekstu';

  @override
  String get shortcutSelectAllDescription =>
      'W trybie Źródło zaznacz cały tekst; w trybie edytora naciśnij dwa razy, aby zaznaczyć wszystkie bloki';

  @override
  String get shortcutCutDescription => 'Wytnij zaznaczony tekst';

  @override
  String get shortcutCopyDescription => 'Skopiuj zaznaczony tekst';

  @override
  String get shortcutPasteDescription => 'Wklej ze schowka';

  @override
  String get shortcutPastePlainTextDescription =>
      'Wklej tekst ze schowka bez formatowania';

  @override
  String get shortcutUndoDescription => 'Cofnij ostatnią edycję';

  @override
  String get shortcutRedoDescription => 'Ponów ostatnią cofniętą edycję';

  @override
  String get shortcutInsertIndentation => 'Wstaw wcięcie';

  @override
  String get shortcutInsertIndentationDescription =>
      'Wstaw wcięcie w miejscu kursora';

  @override
  String get shortcutOutdentSource => 'Zmniejsz wcięcie źródła';

  @override
  String get shortcutOutdentSourceDescription =>
      'Usuń jeden poziom wcięcia w trybie Źródło';

  @override
  String get shortcutEscape =>
      'Zamknij wyszukiwanie lub wyczyść zaznaczenie bloków';

  @override
  String get shortcutEscapeDescription =>
      'Zamknij wyszukiwanie w obszarze roboczym lub wyczyść zaznaczenie bloków w trybie edytora';

  @override
  String get shortcutGroupFormatting => 'Formatowanie';

  @override
  String get shortcutBoldDescription =>
      'Włącz lub wyłącz pogrubienie zaznaczonego tekstu';

  @override
  String get shortcutItalicDescription =>
      'Włącz lub wyłącz kursywę zaznaczonego tekstu';

  @override
  String get shortcutUnderlineDescription =>
      'Włącz lub wyłącz podkreślenie zaznaczonego tekstu';

  @override
  String get shortcutLinkDescription => 'Wstaw lub edytuj łącze';

  @override
  String get shortcutInlineCodeDescription =>
      'Włącz lub wyłącz formatowanie zaznaczonego tekstu jako kod w tekście';

  @override
  String get shortcutStrikethroughDescription =>
      'Włącz lub wyłącz przekreślenie zaznaczonego tekstu';

  @override
  String get shortcutGroupBlocks => 'Bloki';

  @override
  String get shortcutParagraphDescription => 'Ustaw bieżący blok jako akapit';

  @override
  String get shortcutHeading1Description =>
      'Ustaw bieżący blok jako nagłówek 1';

  @override
  String get shortcutHeading2Description =>
      'Ustaw bieżący blok jako nagłówek 2';

  @override
  String get shortcutHeading3Description =>
      'Ustaw bieżący blok jako nagłówek 3';

  @override
  String get shortcutHeading4Description =>
      'Ustaw bieżący blok jako nagłówek 4';

  @override
  String get shortcutHeading5Description =>
      'Ustaw bieżący blok jako nagłówek 5';

  @override
  String get shortcutHeading6Description =>
      'Ustaw bieżący blok jako nagłówek 6';

  @override
  String get shortcutGroupLists => 'Listy';

  @override
  String get numberedList => 'Lista numerowana';

  @override
  String get shortcutNumberedListDescription =>
      'Włącz lub wyłącz formatowanie listy numerowanej';

  @override
  String get bulletedList => 'Lista punktowana';

  @override
  String get shortcutBulletedListDescription =>
      'Włącz lub wyłącz formatowanie listy punktowanej';

  @override
  String get checklist => 'Lista kontrolna';

  @override
  String get shortcutChecklistDescription =>
      'Włącz lub wyłącz formatowanie listy kontrolnej';

  @override
  String get shortcutGroupSidebar => 'Pasek boczny';

  @override
  String get sidebarViewMenu => 'Widok paska bocznego';

  @override
  String get createMarkdownFile => 'Utwórz plik Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Utwórz niezapisany lokalny dokument Markdown';

  @override
  String get createWritersideProject => 'Utwórz projekt Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Utwórz lokalny projekt zgodny z Writerside';

  @override
  String get defaultProjectName => 'Dokumentacja';

  @override
  String get defaultInstanceName => 'Podręcznik użytkownika';

  @override
  String get defaultStartTopicTitle => 'Pierwsze kroki';

  @override
  String get projectName => 'Nazwa projektu';

  @override
  String get directoryName => 'Nazwa katalogu';

  @override
  String get instanceName => 'Nazwa instancji';

  @override
  String get instanceId => 'Identyfikator instancji';

  @override
  String get startTopicTitle => 'Tytuł tematu początkowego';

  @override
  String get location => 'Lokalizacja';

  @override
  String get projectNameRequired => 'Nazwa projektu jest wymagana.';

  @override
  String get directoryNameRequired => 'Nazwa katalogu jest wymagana.';

  @override
  String get useSingleSafeDirectoryName =>
      'Użyj pojedynczej bezpiecznej nazwy katalogu.';

  @override
  String get useLowercaseIdentifier =>
      'Użyj identyfikatora pisanego małymi literami; może zawierać litery, cyfry, podkreślenia lub łączniki.';

  @override
  String get startTopicTitleRequired =>
      'Tytuł tematu początkowego jest wymagany.';

  @override
  String get createWritersideProjectFailed =>
      'Nie można utworzyć projektu Writerside.';

  @override
  String get settingsTitle => 'Ustawienia BusyMark';

  @override
  String get autoSave => 'Automatyczne zapisywanie';

  @override
  String get autoSaveDescription =>
      'Automatycznie zapisuj zmiany w pliku po krótkiej chwili bezczynności.';

  @override
  String get wordWrap => 'Zawijanie wierszy';

  @override
  String get wordWrapDescription =>
      'Zawijaj długie wiersze do szerokości edytora zamiast przewijać je poziomo.';

  @override
  String get editorFontSize => 'Rozmiar czcionki edytora';

  @override
  String get validateOnEdit => 'Sprawdzaj poprawność podczas edycji';

  @override
  String get clearRecentWorkspaces => 'Wyczyść ostatnią historię';

  @override
  String get editingButtonsPosition => 'Położenie przycisków edycji';

  @override
  String get editingButtonsPositionDescription =>
      'Wybierz miejsce wyświetlania pływających przycisków edycji WYSIWYG.';

  @override
  String get editingButtonsDirection => 'Kierunek układu przycisków edycji';

  @override
  String get editingButtonsDirectionDescription =>
      'Wybierz, czy pływające przyciski edycji WYSIWYG mają być ułożone poziomo, czy pionowo.';

  @override
  String get horizontal => 'Poziomo';

  @override
  String get vertical => 'Pionowo';

  @override
  String get privacy => 'Prywatność';

  @override
  String get allowRemoteImages => 'Wczytuj obrazy zdalne';

  @override
  String get allowRemoteImagesDescription =>
      'Zezwalaj na wczytywanie obrazów w podglądzie Markdown i edytorze z adresów URL http i https.';

  @override
  String get clearRemoteImagePermissions =>
      'Wyczyść uprawnienia do obrazów zdalnych';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Zapomnij obszary robocze, którym zezwolono na wczytywanie obrazów zdalnych.';

  @override
  String get clearGitWorkspaceTrust => 'Wyczyść zaufane obszary robocze Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Pytaj przed włączeniem funkcji Git w zaufanych wcześniej obszarach roboczych.';

  @override
  String get settingsEditingButtonsSectionTitle => 'Przyciski edycji';

  @override
  String get spellingDictionaries => 'Słowniki pisowni';

  @override
  String get spellingDictionariesDescription =>
      'Instaluj słowniki pisowni i zarządzaj nimi';

  @override
  String get settingsDictionariesSectionTitle => 'Słowniki';

  @override
  String get availableSpellingDictionaries => 'Dostępne słowniki';

  @override
  String get customSpellingDictionaries => 'Słowniki niestandardowe';

  @override
  String get spellingDictionaryProblems => 'Problemy ze słownikami';

  @override
  String get settingsWindowSectionTitle => 'Okno';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Otwieraj poprzedni obszar roboczy przy uruchamianiu';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Otwórz obszar roboczy i karty z poprzedniej sesji podczas uruchamiania BusyMark.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Potwierdzaj zamknięcie przy niezapisanych zmianach';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Pytaj przed zamknięciem BusyMark, gdy dokumenty mają niezapisane zmiany.';

  @override
  String get closeUnsavedChangesTitle => 'Niezapisane zmiany';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Ten dokument ma niezapisane zmiany. Zapisać zmiany przed zamknięciem BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumentu ma niezapisane zmiany. Zapisać zmiany przed zamknięciem BusyMark?',
      many:
          '$count dokumentów ma niezapisane zmiany. Zapisać zmiany przed zamknięciem BusyMark?',
      few:
          '$count dokumenty mają niezapisane zmiany. Zapisać zmiany przed zamknięciem BusyMark?',
      one:
          '$count dokument ma niezapisane zmiany. Zapisać zmiany przed zamknięciem BusyMark?',
      zero: 'Zapisać zmiany przed zamknięciem BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Anuluj';

  @override
  String get closeUnsavedChangesDiscard => 'Odrzuć';

  @override
  String get closeUnsavedChangesSave => 'Zapisz';

  @override
  String get currentFile => 'bieżącym pliku';

  @override
  String get unsavedChanges => 'Niezapisane zmiany';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'Masz niezapisane zmiany w $fileName. Zapisać je przed kontynuowaniem?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dokumentu ma niezapisane zmiany. Zapisz je przed kontynuowaniem.',
      many:
          '$count dokumentów ma niezapisane zmiany. Zapisz je przed kontynuowaniem.',
      few:
          '$count dokumenty mają niezapisane zmiany. Zapisz je przed kontynuowaniem.',
      one: '1 dokument ma niezapisane zmiany. Zapisz go przed kontynuowaniem.',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Plik zmieniony na dysku';

  @override
  String get fileChangedOnDiskMessage =>
      'Ten plik został zmieniony na dysku od czasu jego otwarcia. Nadpisać wersję na dysku?';

  @override
  String get untitledMarkdownFileName => 'Bez tytułu.md';

  @override
  String get unorderedList => 'Lista nienumerowana';

  @override
  String get orderedList => 'Lista numerowana';

  @override
  String get taskList => 'Lista zadań';

  @override
  String get toggleTaskChecked => 'Zaznacz lub odznacz zadanie';

  @override
  String get indentListItem => 'Zwiększ wcięcie elementu listy';

  @override
  String get outdentListItem => 'Zmniejsz wcięcie elementu listy';

  @override
  String get blockquote => 'Cytat blokowy';

  @override
  String get codeBlock => 'Blok kodu';

  @override
  String get codeBlockLanguage => 'Język bloku kodu';

  @override
  String get image => 'Obraz';

  @override
  String get video => 'Wideo';

  @override
  String get openVideo => 'Odtwórz wideo';

  @override
  String get pauseVideo => 'Wstrzymaj wideo';

  @override
  String get videoUnavailable => 'Wideo jest niedostępne';

  @override
  String get videoPreview => 'Podgląd wideo';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'Wideo nie ma atrybutu src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Nieobsługiwane źródło wideo: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Plik wideo nie istnieje: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Obraz podglądu wideo nie istnieje: $preview';
  }

  @override
  String get inlineImage => 'Obraz w tekście';

  @override
  String get table => 'Tabela';

  @override
  String get htmlBlock => 'Blok HTML';

  @override
  String get htmlContentDefault => 'Treść HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Wstaw lub edytuj blok HTML';

  @override
  String get renderedHtml => 'Wyrenderowany HTML';

  @override
  String get editHtml => 'Edytuj HTML';

  @override
  String get htmlSource => 'Źródło HTML';

  @override
  String get thematicBreak => 'Linia pozioma';

  @override
  String get bold => 'Pogrubienie';

  @override
  String get italic => 'Kursywa';

  @override
  String get underline => 'Podkreślenie';

  @override
  String get strikethrough => 'Przekreślenie';

  @override
  String get inlineCode => 'Kod w tekście';

  @override
  String get link => 'Łącze';

  @override
  String get hardLineBreak => 'Twardy podział wiersza';

  @override
  String get insertBlankLine => 'Wstaw pusty wiersz';

  @override
  String get textStyle => 'Styl tekstu';

  @override
  String get paragraph => 'Akapit';

  @override
  String get heading1 => 'Nagłówek 1';

  @override
  String get heading2 => 'Nagłówek 2';

  @override
  String get heading3 => 'Nagłówek 3';

  @override
  String get heading4 => 'Nagłówek 4';

  @override
  String get heading5 => 'Nagłówek 5';

  @override
  String get heading6 => 'Nagłówek 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Usuń tabelę';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Kolumna $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Wstaw kolumnę po lewej';

  @override
  String get insertColumnRight => 'Wstaw kolumnę po prawej';

  @override
  String get deleteColumn => 'Usuń kolumnę';

  @override
  String get tableAlignmentUnspecified => 'Wyrównanie: nieokreślone';

  @override
  String get tableAlignmentLeft => 'Wyrównanie: do lewej';

  @override
  String get tableAlignmentCenter => 'Wyrównanie: do środka';

  @override
  String get tableAlignmentRight => 'Wyrównanie: do prawej';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Wiersz $rowNumber';
  }

  @override
  String get insertRowAbove => 'Wstaw wiersz powyżej';

  @override
  String get insertRowBelow => 'Wstaw wiersz poniżej';

  @override
  String get deleteRow => 'Usuń wiersz';

  @override
  String get tableHeaderHint => 'Nagłówek';

  @override
  String get tableCellHint => 'Komórka';

  @override
  String get language => 'Język';

  @override
  String get hideEditingButtons => 'Ukryj przyciski edycji';

  @override
  String get showEditingButtons => 'Pokaż przyciski edycji';

  @override
  String get altText => 'Tekst alternatywny';

  @override
  String get editorPlaceholderText => 'tekst';

  @override
  String get editorPlaceholderCode => 'kod';

  @override
  String get editorPlaceholderAltText => 'tekst alternatywny';

  @override
  String get describeTheImage => 'Opisz obraz';

  @override
  String get columns => 'Kolumny';

  @override
  String get rows => 'Wiersze';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Nagłówek $columnNumber';
  }

  @override
  String get tableCellDefault => 'Komórka';

  @override
  String get noImageSource => 'Brak źródła obrazu';

  @override
  String get remoteImageBlocked => 'Zablokowano obraz zdalny';

  @override
  String get remoteImageBlockedTooltip =>
      'Wybierz, czy BusyMark może wczytywać obrazy zdalne.';

  @override
  String get remoteImagesBlockedTitle => 'Obrazy zdalne są zablokowane';

  @override
  String get remoteImagesBlockedMessage =>
      'Ten dokument odwołuje się do obrazów z internetu. Ich wczytanie może ujawnić informacje o twojej sieci serwerom udostępniającym te obrazy.';

  @override
  String get loadRemoteImagesForWorkspace => 'Wczytaj w tym obszarze roboczym';

  @override
  String get alwaysLoadRemoteImages => 'Zawsze wczytuj obrazy zdalne';

  @override
  String get hideSidebar => 'Ukryj panel boczny';

  @override
  String get showSidebar => 'Pokaż panel boczny';

  @override
  String get showPreview => 'Pokaż podgląd';

  @override
  String get hidePreview => 'Ukryj podgląd';

  @override
  String get workspaceKindUnsavedMarkdown => 'Niezapisany plik Markdown';

  @override
  String get workspaceKindSingleMarkdown => 'Pojedynczy plik Markdown';

  @override
  String get workspaceKindMarkdownFolder => 'Folder z plikami Markdown';

  @override
  String get workspaceKindWritersideModule => 'Moduł Writerside';

  @override
  String get problems => 'Problemy';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komunikatu diagnostycznego',
      many: '$count komunikatów diagnostycznych',
      few: '$count komunikaty diagnostyczne',
      one: '$count komunikat diagnostyczny',
      zero: 'Brak komunikatów diagnostycznych',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Pliki';

  @override
  String get toc => 'Spis treści';

  @override
  String get tocActions => 'Działania dotyczące spisu treści';

  @override
  String get markdownUnsaved => 'Markdown – niezapisany';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pliku',
      many: '$count plików',
      few: '$count pliki',
      one: '$count plik',
      zero: '0 plików',
    );
    return '$kind — $_temp0';
  }

  @override
  String get noFiles => 'Brak plików';

  @override
  String get newFile => 'Nowy plik';

  @override
  String get noWritersideToc => 'Brak spisu treści Writerside';

  @override
  String get tocSection => 'Sekcja spisu treści';

  @override
  String get newTopic => 'Nowy temat';

  @override
  String get newChildTopic => 'Nowy temat podrzędny';

  @override
  String get newSiblingTopic => 'Nowy temat';

  @override
  String get renameTopicFile => 'Zmień nazwę pliku tematu';

  @override
  String get topicPlacement => 'Położenie w spisie treści';

  @override
  String get tocRoot => 'Na najwyższym poziomie spisu treści';

  @override
  String get afterSelectedTopic => 'Po wybranym temacie';

  @override
  String get insideSelectedTopic => 'Wewnątrz wybranego tematu';

  @override
  String get pasteAfterTopic => 'Wklej poniżej';

  @override
  String get pasteAsChildTopic => 'Wklej jako temat podrzędny';

  @override
  String get removeFromToc => 'Usuń ze spisu treści';

  @override
  String get confirmRemoveFromTocTitle => 'Usunąć ze spisu treści?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Usunąć $name z tego spisu treści? Plik tematu zostanie zachowany.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Usunąć plik tematu?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Usunąć $name i jego wpisy ze wszystkich spisów treści? Tej operacji nie można cofnąć.';
  }

  @override
  String get safeDeleteTopicFile => 'Bezpiecznie usuń plik tematu…';

  @override
  String get removeTocElement => 'Usuń element spisu treści';

  @override
  String get removeTocElements => 'Usuń elementy spisu treści';

  @override
  String get reviewUsages => 'Przejrzyj użycia';

  @override
  String get deleteTopicFile => 'Usuń plik tematu';

  @override
  String get removeAction => 'Usuń';

  @override
  String topicRemovalSummary(String topic) {
    return 'Usunąć element spisu treści „$topic”? Plik źródłowy powiązany ze spisem treści nie zostanie usunięty.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Usuń „$topic” i bezpiecznie zaktualizuj odwołania do niego w całym tym projekcie Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tematu podrzędnego zostanie przeniesione o poziom wyżej.',
      many:
          '$count tematów podrzędnych zostanie przeniesionych o poziom wyżej.',
      few: '$count tematy podrzędne zostaną przeniesione o poziom wyżej.',
      one: '1 temat podrzędny zostanie przeniesiony o poziom wyżej.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsHomePageRemovalWarning =>
      'Ten temat jest stroną główną tej instancji. Wybierz inną stronę główną przed usunięciem go ze spisu treści.';

  @override
  String get newHomePage => 'Nowa strona główna';

  @override
  String get chooseHomePage => 'Wybierz stronę główną';

  @override
  String get noHomePageReplacement =>
      'Dodaj lub połącz inny odpowiedni temat z tą instancją przed usunięciem jej strony głównej.';

  @override
  String get topicIsStartPageRemovalWarning =>
      'Ten temat jest stroną główną instancji. Ustaw inną stronę główną przed usunięciem jego pliku źródłowego.';

  @override
  String topicUsagesCount(int count) {
    return 'Znalezione użycia: $count.';
  }

  @override
  String get noBreakingTopicUsages =>
      'Nie znaleziono odwołań, które przestałyby działać.';

  @override
  String get topicUsagesFound =>
      'BusyMark znalazł następujące odwołania do tego tematu.';

  @override
  String get topicUsageTocElements => 'Elementy spisu treści';

  @override
  String get topicUsageStartPages => 'Strony główne';

  @override
  String get topicUsageTopicLinks => 'Linki do tematów';

  @override
  String get topicUsageIncludes => 'Dołączenia';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count użycia',
      many: '$count użyć',
      few: '$count użycia',
      one: '1 użycie',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Opcje refaktoryzacji';

  @override
  String get updateUsagesAutomatically => 'Aktualizuj użycia automatycznie';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Usuń odwołania w spisie treści i dołączenia oraz zachowaj tekst linków.';

  @override
  String get manualUsageUpdatesRequired =>
      'Niektóre użycia wymagają ręcznych zmian przed tą refaktoryzacją.';

  @override
  String get setRedirectTo => 'Ustaw przekierowanie do:';

  @override
  String get noRedirectDescription =>
      'Nie przekierowuj starej opublikowanej strony.';

  @override
  String get redirectTarget => 'Cel przekierowania';

  @override
  String get remainingUsagesBlockRemoval =>
      'Przejrzyj i zaktualizuj pozostałe użycia przed kontynuowaniem albo włącz automatyczne aktualizacje, jeśli są dostępne.';

  @override
  String usagesOfTopic(String topic) {
    return 'Użycia tematu $topic';
  }

  @override
  String get noUsagesFound => 'Nie znaleziono użyć';

  @override
  String get outsideSelectedInstance => 'poza wybraną instancją';

  @override
  String get doRefactor => 'Wykonaj refaktoryzację';

  @override
  String get preview => 'Podgląd';

  @override
  String get topicRenamePreviewTitle => 'Podgląd zmiany nazwy';

  @override
  String topicRenamePathChange(String oldPath, String newPath) {
    return 'Ścieżka: $oldPath → $newPath';
  }

  @override
  String topicRenameIdChange(String oldId, String newId) {
    return 'Identyfikator tematu: $oldId → $newId';
  }

  @override
  String topicRenameUrlChange(String instance, String oldName, String newName) {
    return 'Instancja $instance: $oldName → $newName';
  }

  @override
  String get topicRenameAffectedFiles => 'Pliki objęte zmianą';

  @override
  String get orphanTopicTitle => 'Plik tematu nie jest już używany';

  @override
  String get keepTopicFile => 'Zachowaj plik tematu';

  @override
  String orphanTopicMessage(String topic) {
    return '„$topic” nie jest już używany nigdzie w tym projekcie Writerside. Usuń plik albo zachowaj go do użycia w innej instancji.';
  }

  @override
  String get defaultNewTopicTitle => 'Nowy temat';

  @override
  String get topicTitle => 'Tytuł tematu';

  @override
  String get fileName => 'Nazwa pliku';

  @override
  String get topicTitleRequired => 'Tytuł tematu jest wymagany.';

  @override
  String get fileNameRequired => 'Nazwa pliku jest wymagana.';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get confirmDeleteFileTitle => 'Usunąć plik?';

  @override
  String get confirmDeleteFolderTitle => 'Usunąć folder?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Usunąć $name? Tej operacji nie można cofnąć.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Usunąć $name i wszystkie pliki w środku? Tej operacji nie można cofnąć.';
  }

  @override
  String get useSingleSafeFileName => 'Użyj jednej bezpiecznej nazwy pliku.';

  @override
  String useExpectedExtension(String extension) {
    return 'Użyj rozszerzenia $extension dla wybranego formatu.';
  }

  @override
  String get useIdentifierCharacters =>
      'Przed rozszerzeniem użyj liter, cyfr, podkreśleń lub łączników.';

  @override
  String get topicIdAlreadyExists => 'Identyfikator tematu już istnieje.';

  @override
  String get createWritersideTopicFailed =>
      'Nie można utworzyć tematu Writerside.';

  @override
  String get noOutline => 'Brak konspektu';

  @override
  String expandKind(String kind) {
    return 'Rozwiń $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Zwiń $kind';
  }

  @override
  String get foldKindSection => 'sekcję';

  @override
  String get foldKindList => 'listę';

  @override
  String get foldKindQuote => 'cytat';

  @override
  String get foldKindTag => 'tag';

  @override
  String get sourceSearchPreviousMatch => 'Poprzednie dopasowanie';

  @override
  String get sourceSearchNextMatch => 'Następne dopasowanie';

  @override
  String get sourceSearchReplacement => 'Zamień na';

  @override
  String get sourceSearchReplaceCurrent => 'Zamień bieżące dopasowanie';

  @override
  String get sourceSearchReplaceAndFindNext => 'Zamień i znajdź następne';

  @override
  String get sourceSearchReplaceAll => 'Zamień wszystko';

  @override
  String get workspaceReplace => 'Zamień w obszarze roboczym';

  @override
  String get reviewReplacements => 'Przejrzyj zamiany';

  @override
  String get applyReplacements => 'Zastosuj zamiany';

  @override
  String get skippedFiles => 'Pominięte pliki';

  @override
  String get workspaceReplaceDirtyBuffer => 'Niezapisana zawartość edytora';

  @override
  String get workspaceReplaceDiskContent => 'Zawartość zapisana na dysku';

  @override
  String selectFileMatches(int count) {
    return 'Wybierz wszystkie dopasowania ($count)';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Zamieniono $matches dopasowań w $files plikach; pominięto $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Końcowy znak nowego wiersza';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Brak końcowego znaku nowego wiersza';
  }

  @override
  String get normalizeLineEndings => 'Normalizuj zakończenia wierszy';

  @override
  String get mixedLineEndingsSavePrompt =>
      'Ten dokument zawiera mieszane zakończenia wierszy. Wybierz format.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName używa mieszanych zakończeń wierszy. Wybierz format przed zamianą.';
  }

  @override
  String get workspaceReplaceIssueOversized => 'Pominięto zbyt duży plik.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Pominięto plik, którego nie można odczytać.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Pominięto plik z nieprawidłowym kodowaniem UTF-8.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Podgląd zamian został skrócony.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Pominięto plik zmieniony po utworzeniu podglądu.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Pominięto bufor edytora zmieniony po utworzeniu podglądu.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Przed zamianą wybierz normalizację LF lub CRLF.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Wycofywanie zatrzymano, ponieważ plik został jednocześnie zmieniony. Niektóre zamiany mogą pozostać; zastąpioną zawartość zachowano w poniższej ścieżce.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Nie zastosowano żadnych zamian, ponieważ sprawdzonego zestawu nie można było bezpiecznie zapisać.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Zmiany zewnętrzne — $fileName';
  }

  @override
  String get externalFileDeleted => 'Ten plik został usunięty z dysku.';

  @override
  String get externalFileChanged =>
      'Ten plik zmienił się na dysku, gdy masz niezapisane zmiany.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Odzyskano niezapisaną treść pliku $fileName. Przejrzyj ją, a następnie zapisz, zapisz jako lub odrzuć.';
  }

  @override
  String get compare => 'Porównaj';

  @override
  String get reloadFromDisk => 'Wczytaj ponownie z dysku';

  @override
  String get keepMine => 'Zachowaj moją wersję';

  @override
  String get saveAs => 'Zapisz jako';

  @override
  String get workspaceSearchIncomplete =>
      'Wyświetlono tylko część wyników. Pokaż więcej lub zawęź wyszukiwanie.';

  @override
  String get workspaceSearchShowMore => 'Pokaż więcej wyników';

  @override
  String get workspaceSearchSkippedFiles =>
      'Wyszukiwanie jest niepełne. Te pliki przekraczają 1 MiB lub nie można ich odczytać:';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Duży plik: podświetlanie i zwijanie są wstrzymane';

  @override
  String get nothingToRead => 'Brak treści do przeczytania';

  @override
  String get admonition => 'Adnotacja';

  @override
  String get quote => 'Cytat';

  @override
  String get note => 'Uwaga';

  @override
  String get tip => 'Wskazówka';

  @override
  String get warning => 'Ostrzeżenie';

  @override
  String get tabs => 'Karty';

  @override
  String get tab => 'Karta';

  @override
  String get procedure => 'Procedura';

  @override
  String get step => 'Krok';

  @override
  String get topic => 'Temat';

  @override
  String get chapter => 'Rozdział';

  @override
  String couldNotOpenTarget(String target) {
    return 'Nie można otworzyć: $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Nie znaleziono celu łącza: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Nie można otworzyć tego typu pliku w edytorze';

  @override
  String anchorNotFound(String anchor) {
    return 'Nie znaleziono kotwicy: $anchor';
  }

  @override
  String get noProblemsFound => 'Nie znaleziono żadnych problemów';

  @override
  String get noResults => 'Brak wyników';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath — wiersz $lineNumber';
  }

  @override
  String get untitledResult => 'Wynik bez tytułu';

  @override
  String get documentKindMarkdownFile => 'Plik Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Temat Markdown w Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Temat XML w Writerside';

  @override
  String get documentKindWritersideTree => 'Drzewo Writerside';

  @override
  String get documentKindConfigurationFile => 'Plik konfiguracyjny';

  @override
  String get documentKindVariablesFile => 'Plik zmiennych';

  @override
  String get documentKindCategoriesFile => 'Plik kategorii';

  @override
  String get documentKindResourceFile => 'Plik zasobów';

  @override
  String workspaceErrorRecentWorkspaceUpdateFailed(String error) {
    return 'Nie udało się zaktualizować ostatnich elementów: $error.';
  }

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Otwieranie nie powiodło się: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Nie można utworzyć projektu Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Nie można utworzyć tematu Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Nie można otworzyć pliku: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Wybierz, gdzie zapisać ten plik Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Zapis zablokowany: plik został zmieniony na dysku.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Zapisywanie nie powiodło się: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Operacja na pliku nie powiodła się: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Sprawdzanie poprawności nie powiodło się: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Odzyskano $count niezapisanego dokumentu. Przejrzyj go przed zapisaniem lub odrzuceniem.',
      many:
          'Odzyskano $count niezapisanych dokumentów. Przejrzyj każdy przed zapisaniem lub odrzuceniem.',
      few:
          'Odzyskano $count niezapisane dokumenty. Przejrzyj każdy przed zapisaniem lub odrzuceniem.',
      one:
          'Odzyskano 1 niezapisany dokument. Przejrzyj go przed zapisaniem lub odrzuceniem.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nie udało się przywrócić $count uszkodzonego rekordu odzyskiwania. Prawidłowe rekordy odzyskiwania pozostają dostępne.',
      many:
          'Nie udało się przywrócić $count uszkodzonych rekordów odzyskiwania. Prawidłowe rekordy odzyskiwania pozostają dostępne.',
      few:
          'Nie udało się przywrócić $count uszkodzonych rekordów odzyskiwania. Prawidłowe rekordy odzyskiwania pozostają dostępne.',
      one:
          'Nie udało się przywrócić 1 uszkodzonego rekordu odzyskiwania. Oryginalny plik odzyskiwania zachowano do przeglądu.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Ścieżka nie istnieje: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Katalog docelowy już istnieje i nie jest pusty: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Ścieżka docelowa już istnieje, ale nie jest katalogiem: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Wygenerowany plik już istnieje: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Wymagany jest katalog nadrzędny.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Katalog nadrzędny nie istnieje: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Katalog nie istnieje: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Ścieżka już istnieje: $path';
  }

  @override
  String get errorFileNameRequired => 'Nazwa pliku jest wymagana.';

  @override
  String get errorFileNameUnsafe =>
      'Nazwa pliku musi być pojedynczym bezpiecznym segmentem ścieżki.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Nie można przenieść folderu do niego samego.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Operacja na pliku musi pozostać w obrębie obszaru roboczego.';

  @override
  String get errorFileOperationRoot =>
      'Nie można zmienić katalogu głównego obszaru roboczego z poziomu drzewa plików.';

  @override
  String get errorProjectNameRequired => 'Nazwa projektu jest wymagana.';

  @override
  String get errorDirectoryNameRequired => 'Nazwa katalogu jest wymagana.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Nazwa katalogu musi być pojedynczym bezpiecznym segmentem ścieżki.';

  @override
  String get errorInstanceIdInvalid =>
      'Identyfikator instancji musi zaczynać się małą literą i może zawierać tylko małe litery, cyfry, podkreślenia oraz łączniki.';

  @override
  String get errorTopicFileInvalid =>
      'Nazwa pliku tematu musi być nazwą pliku Markdown bez separatorów ścieżki.';

  @override
  String get errorTopicTitleRequired => 'Tytuł tematu jest wymagany.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Katalog główny modułu Writerside nie istnieje: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Aby utworzyć temat, musi być otwarty moduł Writerside.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Moduł Writerside nie ma drzewa instancji.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Plik drzewa Writerside nie istnieje: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Identyfikator tematu „$topicId” już istnieje w tym module pomocy.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Plik tematu już istnieje: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Temat odniesienia nie występuje w wybranym drzewie: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Wybrany wpis spisu treści już nie istnieje.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Wpisu spisu treści nie można przenieść do niego samego ani do żadnego z jego elementów podrzędnych.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Nie można usunąć strony głównej $topic. Najpierw wybierz inną stronę główną.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Użyj bezpiecznego usuwania dla plików tematów Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Nie udało się zakończyć wyszukiwania użyć tematu. Nie zmieniono żadnych plików.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Niektóre użycia tematu nadal wymagają uwagi. Przejrzyj je przed kontynuowaniem.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Wybrany cel przekierowania nie jest już prawidłowy. Wybierz go ponownie.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Nie udało się całkowicie wycofać usunięcia tematu. Przed kontynuowaniem przejrzyj te ścieżki: $paths';
  }

  @override
  String errorWritersideTopicRenameIncompleteProjectIndex(
    String module,
    String count,
    String paths,
  ) {
    return 'Zmiana nazwy nie może bezpiecznie zaktualizować wszystkich odwołań w projekcie, ponieważ nie przeanalizowano $count plików tematów w module $module: $paths';
  }

  @override
  String get errorWritersideTopicRenameProjectBuffersDirty =>
      'Pliki projektu Writerside zawierają niezapisane zmiany. Rozwiąż je i przygotuj nowy podgląd zmiany nazwy.';

  @override
  String get errorWritersideTopicRenameProjectInventoryChanged =>
      'Zestaw modułów projektu Writerside uległ zmianie. Przed refaktoryzacją przygotuj nowy podgląd zmiany nazwy.';

  @override
  String get errorTopicsRootUnsafe =>
      'Katalog główny tematów musi być bezpiecznym katalogiem względnym.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Nazwa pliku tematu musi być pojedynczym bezpiecznym segmentem ścieżki.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Rozszerzenie pliku tematu musi odpowiadać wybranemu formatowi ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Nazwa pliku tematu może zawierać wyłącznie litery, cyfry, podkreślenia i łączniki.';

  @override
  String errorUnknown(String code) {
    return 'Nieznany błąd: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Nie można odczytać metadanych pliku: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Wykryto duży obszar roboczy. Część plików pominięto, aby aplikacja nadal szybko reagowała.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Nie można sprawdzić elementu obszaru roboczego: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Plik przekracza limit automatycznego analizowania w wersji beta.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Nie można odczytać pliku Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Nieprawidłowy blok atrybutów nagłówka Writerside.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Powielony identyfikator nagłówka „$id”.';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Dodatkowe nagłówki H1 najwyższego poziomu są traktowane jako rozdziały.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Temat Markdown w Writerside nie ma nagłówka H1 ani tytułu w front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'Brakuje tytułu tematu XML.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'W temacie „$fileName” brakuje tytułu.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Sekcja front matter nie jest zamknięta.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Niebezpieczny element HTML.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Cel łącza nie istnieje: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Kotwica „$anchor” nie istnieje.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Obraz „$destination” nie ma tekstu alternatywnego.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Obraz nie istnieje: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Nieprawidłowy XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Element główny pliku writerside.cfg musi być <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'W deklaracji snippets brakuje atrybutu src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'W deklaracji instance-groups brakuje atrybutu src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Nieobsługiwany tryb mapowania klawiszy: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'W deklaracji instancji brakuje atrybutu src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'Plik writerside.cfg nie rejestruje instancji.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Element główny pliku .tree musi być <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'W profilu instancji brakuje identyfikatora.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Nazwa pliku drzewa bez rozszerzenia nie pasuje do identyfikatora instancji „$id”.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'Instancji niebędącej biblioteką brakuje atrybutu start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Strona początkowa „$startPage” nie istnieje.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Temat „$topic” pojawia się więcej niż raz w spisie treści tej instancji.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Deklaracja zmiennej musi zawierać nazwę i wartość.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Zmienna „$name” została zadeklarowana więcej niż raz.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'Kategoria nie ma identyfikatora.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Kategoria „$id” została zadeklarowana więcej niż raz.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Wartość kolejności kategorii „$order” zadeklarowano więcej niż raz.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Element główny pliku .topic musi być <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'W temacie XML brakuje identyfikatora elementu głównego.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Identyfikator elementu głównego tematu XML „$id” musi odpowiadać nazwie pliku „$expectedId”.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Identyfikator elementu „$elementId” pojawia się więcej niż raz.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'Elementowi <a> brakuje atrybutu href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Tryb Writerside wymaga pliku writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Brak skonfigurowanego katalogu konfiguracji kompilacji: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Brak skonfigurowanego katalogu specyfikacji API: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Brak skonfigurowanego katalogu fragmentów kodu: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Brak skonfigurowanego pliku zmiennych: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Brak skonfigurowanego pliku kategorii: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Brak skonfigurowanego pliku grup instancji: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Zarejestrowane drzewo instancji „$source” nie istnieje.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Nie można odczytać pliku tematu: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Brak domyślnego katalogu tematów: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Brak skonfigurowanego katalogu tematów: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Brak skonfigurowanego katalogu obrazów: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Identyfikator elementu „$id” pojawia się więcej niż raz.';
  }

  @override
  String diagnosticWritersideWebFileNameInvalid(
    String instanceId,
    String webFileName,
    String topic,
  ) {
    return 'Instancja \"$instanceId\" publikuje nieprawidłową nazwę pliku internetowego \"$webFileName\" dla tematu \"$topic\".';
  }

  @override
  String diagnosticWritersideWebFileNameCollision(
    String instanceId,
    String webFileName,
    String firstTopic,
    String secondTopic,
  ) {
    return 'Instancja \"$instanceId\" publikuje zarówno \"$firstTopic\", jak i \"$secondTopic\" jako \"$webFileName\".';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Spis treści odwołuje się do brakującego tematu „$topic”.';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Zewnętrzny adres href „$href” jest nieprawidłowy.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Zmienna „%$name%” nie została zadeklarowana.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Łącze do tematu „$destination” nie wskazuje prawidłowego celu.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Kotwica „$anchor” nie istnieje w „$targetName”.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'Elementowi <include> brakuje atrybutu from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Źródło elementu include „$from” nie istnieje.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Element include „$elementId” nie istnieje w „$from”.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Kategoria seealso „$ref” nie została zadeklarowana.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Odniesienie do tematu „$reference” jest niejednoznaczne.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Nieznany komunikat diagnostyczny: $code';
  }

  @override
  String get close => 'Zamknij';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Różnice Git';

  @override
  String get gitShowDiff => 'Pokaż różnice';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'stary zakres $oldRange → nowy zakres $newRange';
  }

  @override
  String get gitDiffNoLines => 'brak wierszy';

  @override
  String get gitUnavailableTitle => 'Git jest niedostępny';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Zainstaluj Git lub skonfiguruj BusyMark tak, aby używał dostępnego pliku wykonywalnego Git. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Zaufać temu obszarowi roboczemu na potrzeby Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Repozytoria Git mogą uruchamiać programy za pomocą hooków, filtrów i innych elementów konfiguracji. Zaufaj temu obszarowi roboczemu, zanim BusyMark odczyta dane repozytorium lub włączy działania Git.';

  @override
  String get gitTrustWorkspace => 'Zaufaj obszarowi roboczemu';

  @override
  String get gitNotRepositoryTitle => 'To nie jest repozytorium Git';

  @override
  String get gitNotRepositoryMessage =>
      'Ten obszar roboczy nie znajduje się w repozytorium Git.';

  @override
  String get gitInitializeRepository => 'Zainicjuj repozytorium';

  @override
  String get gitDetachedHead => 'Odłączony HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Odłączony HEAD: $commit';
  }

  @override
  String get gitNoUpstream => 'Brak gałęzi upstream';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niewysłanego commita',
      many: '$count niewysłanych commitów',
      few: '$count niewysłane commity',
      one: '$count niewysłany commit',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commita do pobrania',
      many: '$count commitów do pobrania',
      few: '$count commity do pobrania',
      one: '$count commit do pobrania',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Bez zmian';

  @override
  String get gitConflicts => 'Konflikty';

  @override
  String get gitChanges => 'Zmiany';

  @override
  String get gitStaged => 'W indeksie';

  @override
  String get gitUnstaged => 'Poza indeksem';

  @override
  String get gitHistory => 'Historia';

  @override
  String get gitBranches => 'Gałęzie';

  @override
  String get gitActions => 'Działania Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Pobierz';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Zatwierdź';

  @override
  String get gitSelectForCommit => 'Dodaj plik do indeksu';

  @override
  String get gitRemoveFromCommit => 'Usuń plik z indeksu';

  @override
  String get gitDiscard => 'Odrzuć';

  @override
  String get gitOpenFile => 'Otwórz plik';

  @override
  String get gitMarkResolved => 'Oznacz jako rozwiązany';

  @override
  String get gitUntracked => 'Pliki nieśledzone';

  @override
  String get gitCommitMessage => 'Komunikat zatwierdzenia';

  @override
  String get gitCommitSelectedFiles => 'Wybrane pliki';

  @override
  String get gitCommitNoSelectedFiles =>
      'Przed utworzeniem commitu dodaj do indeksu co najmniej jeden plik.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plików w indeksie',
      many: '$count plików w indeksie',
      few: '$count pliki w indeksie',
      one: '1 plik w indeksie',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Poza obszarem roboczym';

  @override
  String get gitCommitMessageRequired => 'Wprowadź komunikat zatwierdzenia.';

  @override
  String get gitCreateBranch => 'Utwórz gałąź';

  @override
  String get gitNewBranch => 'Nowa gałąź';

  @override
  String get gitBranchName => 'Nazwa gałęzi';

  @override
  String get gitSwitchBranch => 'Przełącz';

  @override
  String get gitNoChanges => 'Brak zmian';

  @override
  String get gitNoHistory => 'Brak historii';

  @override
  String get gitNoBranches => 'Brak gałęzi';

  @override
  String get gitNoDiff => 'Brak różnic do pokazania';

  @override
  String get gitBinaryFile =>
      'Plik binarny. BusyMark nie wyświetla binarnych poprawek.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Plik binarny ($size bajtów). BusyMark nie wyświetla poprawek binarnych.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Niezapisane zmiany w edytorze nie zostaną uwzględnione, dopóki ich nie zapiszesz.';

  @override
  String get gitConfirmDiscardTitle => 'Odrzucić zmiany Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wszystkie zmiany w indeksie i poza indeksem w wybranych śledzonych plikach zostaną przywrócone do HEAD.',
      one:
          'Wszystkie zmiany w indeksie i poza indeksem w wybranym śledzonym pliku zostaną przywrócone do HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wybrane nieśledzone pliki zostaną usunięte.',
      many: 'Wybrane nieśledzone pliki zostaną usunięte.',
      few: 'Wybrane nieśledzone pliki zostaną usunięte.',
      one: 'Wybrany nieśledzony plik zostanie usunięty.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wybrane pliki zostaną przywrócone lub usunięte zależnie od ich stanu Git.',
      many:
          'Wybrane pliki zostaną przywrócone lub usunięte zależnie od ich stanu Git.',
      few:
          'Wybrane pliki zostaną przywrócone lub usunięte zależnie od ich stanu Git.',
      one:
          'Wybrany plik zostanie przywrócony lub usunięty zależnie od jego stanu Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Przełączyć na $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark ponownie wczyta obszar roboczy z dysku po przełączeniu gałęzi przez Git.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Ustawić gałąź upstream?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Ta gałąź nie ma gałęzi upstream. BusyMark może wypchnąć gałąź $branch i ustawić ją jako upstream, jeśli skonfigurowano dokładnie jedno repozytorium zdalne.';
  }

  @override
  String get gitProjectHistory => 'Historia projektu';

  @override
  String get gitFileHistory => 'Historia pliku';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Historia pliku wymaga otwartego pliku Markdown.';

  @override
  String get gitLoadMore => 'Wczytaj więcej';

  @override
  String get gitChangesInCommit => 'Zmiany w tym commicie';

  @override
  String get gitCompareWithCurrent => 'Porównaj z bieżącą wersją';

  @override
  String get gitRestoreVersion => 'Przywróć tę wersję';

  @override
  String get gitConfirmRestoreTitle => 'Przywrócić tę wersję pliku?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark zastąpi bieżący plik w drzewie roboczym wybraną wersją z commita. Przywrócony plik pozostanie poza indeksem.';

  @override
  String get gitCommitActions => 'Operacje na commicie';

  @override
  String get gitResetCurrentBranchToHere => 'Zresetuj bieżącą gałąź tutaj…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Zresetować $branch do $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Ta operacja przenosi gałąź $branch do commita $commit. Wybierz sposób aktualizacji indeksu i drzewa roboczego przez Git.';
  }

  @override
  String get gitReset => 'Zresetuj';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Przenieś tylko gałąź. Pozostaw indeks i drzewo robocze bez zmian; różnice względem wybranego commita pozostaną w indeksie.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Przenieś gałąź i zresetuj indeks. Pozostaw drzewo robocze bez zmian, a różnice poza indeksem.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Przenieś gałąź oraz zresetuj indeks i drzewo robocze. Śledzone zmiany zostaną odrzucone; blokujące pliki nieśledzone mogą zostać usunięte.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Przenieś gałąź i zresetuj śledzone pliki, zachowując zmiany lokalne. Git przerwie operację, jeśli zmiany kolidują z resetem.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Działania na pliku';

  @override
  String get actions => 'Działania';

  @override
  String get gitStatusAdded => 'Dodany';

  @override
  String get gitStatusDeleted => 'Usunięty';

  @override
  String get gitStatusRenamed => 'Nazwa zmieniona';

  @override
  String get gitStatusCopied => 'Skopiowany';

  @override
  String get gitStatusUntracked => 'Nieśledzony';

  @override
  String get gitStatusConflicted => 'W konflikcie';

  @override
  String get gitStatusIgnored => 'Ignorowany';

  @override
  String get gitStatusTypeChanged => 'Zmieniony typ';

  @override
  String get gitStatusModified => 'Zmodyfikowany';

  @override
  String get gitStatusUnknown => 'Nieznany';

  @override
  String get gitErrorUnavailable => 'Git jest niedostępny.';

  @override
  String get gitErrorNotRepository =>
      'Ten obszar roboczy nie jest repozytorium Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark zablokował niebezpieczną ścieżkę Git.';

  @override
  String get gitErrorInvalidBranchName => 'Wprowadź prawidłową nazwę gałęzi.';

  @override
  String get gitErrorNoRemote =>
      'Nie skonfigurowano zdalnego repozytorium Git.';

  @override
  String get gitErrorNoUpstream => 'Nie skonfigurowano gałęzi upstream.';

  @override
  String get gitErrorMultipleRemotes =>
      'Skonfigurowano wiele repozytoriów zdalnych. Wybierz gałąź upstream poza tą wersją BusyMark.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Przed przełączeniem gałęzi zapisz lub odrzuć zmiany w edytorze BusyMark.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Zapisz lub odrzuć zmiany w edytorze BusyMark przed zresetowaniem bieżącej gałęzi.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Usuń plik z indeksu przed przywróceniem wcześniejszej wersji.';

  @override
  String get gitErrorResetDetachedHead =>
      'Przełącz się na gałąź przed jej zresetowaniem.';

  @override
  String get gitErrorDiverged =>
      'Gałęzie się rozeszły. Rozwiąż scalanie lub wykonaj rebase poza tą wersją BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'Git wymaga nazwy autora i adresu e-mail przed utworzeniem commita.';

  @override
  String get gitAuthorIdentityTitle => 'Tożsamość autora Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Wprowadź tożsamość, którą Git ma zapisywać w commitach. BusyMark ją zapisze i ponowi ten commit.';

  @override
  String get gitAuthorName => 'Nazwa';

  @override
  String get gitAuthorEmail => 'E-mail';

  @override
  String get gitAuthorIdentityGlobal => 'Używaj we wszystkich repozytoriach';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'W instalacji Snap dotyczy to repozytoriów otwieranych w BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Zapisz i utwórz commit';

  @override
  String get gitErrorAuthentication => 'Uwierzytelnianie Git nie powiodło się.';

  @override
  String get gitErrorNetwork => 'Operacja sieciowa Git nie powiodła się.';

  @override
  String get gitErrorConflict => 'Git zgłosił nierozwiązane konflikty.';

  @override
  String get gitErrorCommandFailed => 'Polecenie Git nie powiodło się.';

  @override
  String get syntaxReference => 'Dokumentacja składni';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Bloki Markdown';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Struktury blokowe obsługiwane w źródle Markdown i podglądzie.';

  @override
  String get syntaxReferenceInlineFormatting => 'Markdown w tekście';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      'Formatowanie w akapitach, elementach list i komórkach tabel.';

  @override
  String get syntaxReferenceRawHtmlBlocks => 'Surowe bloki HTML';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'Bezpieczne blokowe tagi HTML renderowane przez widżety podglądu BusyMark.';

  @override
  String get syntaxReferenceRawHtmlInline => 'Surowe tagi HTML w tekście';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'Bezpieczne tagi HTML w tekście renderowane bez pokazywania dosłownych tagów.';

  @override
  String get syntaxReferenceHeadings => 'Nagłówki';

  @override
  String get syntaxReferenceParagraphs => 'Akapity';

  @override
  String get syntaxReferenceLists => 'Listy';

  @override
  String get syntaxReferenceHtmlContainers => 'Kontenery';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'Bloki tekstowe';

  @override
  String get syntaxReferenceHtmlFigures => 'Figury i obrazy';

  @override
  String get syntaxReferenceHtmlPreformatted => 'Kod preformatowany';

  @override
  String get syntaxReferenceHtmlDisclosure => 'Bloki rozwijane';

  @override
  String get syntaxReferenceHtmlDescriptionLists => 'Listy opisów';

  @override
  String get syntaxReferenceHtmlFormattingTags => 'Tagi formatowania';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'Tagi kodu w tekście';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'Semantyczne tagi tekstu';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      'Dozwolony HTML jest konwertowany na bloki podglądu BusyMark, a nie renderowany w przeglądarce.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      'Nieedytowany surowy HTML jest zapisywany dokładnie jako tekst źródłowy.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      'Znaczniki Markdown wewnątrz surowego HTML są wyświetlane jako tekst dosłowny.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'Skrypty, style, ramki, formularze, SVG, MathML, zdarzenia i niebezpieczne atrybuty są blokowane.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'Łącza dopuszczają http, https, mailto, tel, względne adresy URL i fragmenty; niebezpieczne schematy są blokowane.';

  @override
  String get syntaxReferenceCategory => 'Kategoria';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => 'Diagramy i API';

  @override
  String get syntaxReferenceCategoryMathematics => 'Matematyka';

  @override
  String get syntaxReferenceExample => 'Przykład';

  @override
  String get syntaxReferenceIdentifiers => 'Identyfikatory i aliasy';

  @override
  String get syntaxReferenceScope => 'Zakres';

  @override
  String get syntaxReferenceLimitation => 'Ograniczenie BusyMark';

  @override
  String get syntaxReferenceOfficialDocumentation => 'Oficjalna dokumentacja';

  @override
  String get syntaxReferenceScopeWritersideMarkdown =>
      'Tylko Markdown Writerside';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Tylko Markdown Writerside i XML Writerside';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'Podstawowe formy Markdown, które BusyMark umożliwia tworzyć i wyświetlać.';

  @override
  String get syntaxReferenceParagraphExample => 'Akapit tekstu.';

  @override
  String get syntaxReferenceTableLimitation =>
      'Tabele używają składni z pionowymi kreskami GitHub Flavored Markdown.';

  @override
  String get syntaxReferenceHardBreakIdentifiers =>
      'dwie spacje na końcu wiersza, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark akceptuje ograniczony, bezpieczny podzbiór surowego HTML w źródle Markdown.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Bloki ogrodzone Mermaid, PlantUML, D2 i OpenAPI działają w źródle Markdown. Wielkość liter w identyfikatorach nie ma znaczenia, a BusyMark zachowuje ich oryginalną pisownię.';

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
      'Użyj ogrodzonej treści YAML lub JSON. BusyMark nie traktuje dowolnego całego dokumentu YAML lub JSON jako dokumentacji OpenAPI.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks =>
      'Semantyczne bloki kodu diagramów';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'Semantyczne formy code-block i src obsługują Mermaid, PlantUML i D2, ale nie OpenAPI, i tylko w projektach Writerside.';

  @override
  String get syntaxReferenceReferencedDiagramSource =>
      'Źródło diagramu z odwołania';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'Ścieżki muszą być względne i pozostawać w otwartym projekcie Writerside; forma ogrodzona z src działa tylko w Markdown Writerside.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark obsługuje wyrażenia TeX, a nie kompletne dokumenty TeX lub LaTeX.';

  @override
  String get syntaxReferenceInlineMath => 'Matematyka w wierszu';

  @override
  String get syntaxReferenceGithubMath =>
      'Matematyka GitHub ze znakami dolara i grawisu';

  @override
  String get syntaxReferenceDisplayMath => 'Matematyka blokowa';

  @override
  String get syntaxReferenceMathFence => 'Blok ogrodzony math';

  @override
  String get syntaxReferenceTexFence => 'Blok ogrodzony tex';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark nie rozpoznaje \\(...\\) ani \\[...\\] jako ograniczników matematycznych Markdown.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Poza trybem Writerside blok tex pozostaje zwykłym blokiem kodu.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Element math Writerside';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'Element math jest semantyczną składnią Writerside, a nie dozwolonym surowym HTML MathML.';

  @override
  String get syntaxReferenceSemanticTexBlock => 'Semantyczny blok kodu TeX';

  @override
  String get syntaxReferenceWritersideDescription =>
      'Te wybrane rozszerzenia są interpretowane tylko w otwartych projektach Writerside.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => 'Cytat z uwagą';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      'Zwykły cytat blokowy jest wskazówką w Markdown Writerside; w zwykłym Markdown pozostaje zwykłym cytatem.';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'Uwagi semantyczne';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      'Zwykły Markdown nie interpretuje tych semantycznych elementów Writerside.';

  @override
  String get syntaxReferenceCollapsibleHeading => 'Zwijany nagłówek';

  @override
  String get syntaxReferenceCollapsibleCode => 'Zwijany blok kodu';

  @override
  String get syntaxReferenceSemanticCollapsibles =>
      'Semantyczna zawartość zwijana';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark obsługuje zwijane formy chapter, procedure, code-block i list definicji, ale nie cały katalog Writerside.';

  @override
  String get syntaxReferenceSemanticCodeBlocks =>
      'Semantyczne bloki kodu matematyki i diagramów';

  @override
  String get syntaxReferenceVideo => 'Wideo Writerside';

  @override
  String get syntaxReferenceVideoLimitation =>
      'Lokalne wideo używa lokalnego obrazu preview-src; źródła hostowane muszą być obsługiwanymi adresami HTTPS YouTube lub Vimeo.';

  @override
  String get exportAsPdf => 'Eksportuj jako PDF';

  @override
  String get pdfExportDescription =>
      'Wybierz układ strony dla dopracowanego, samodzielnego pliku PDF.';

  @override
  String get pdfRemoteImagesNote =>
      'Obrazy zdalne nie są pobierane podczas eksportu. Dostępne obrazy lokalne zostaną dołączone.';

  @override
  String get pdfPageSize => 'Rozmiar strony';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'US Letter';

  @override
  String get pdfOrientation => 'Orientacja';

  @override
  String get pdfPortrait => 'Pionowa';

  @override
  String get pdfLandscape => 'Pozioma';

  @override
  String get pdfMargins => 'Marginesy';

  @override
  String get pdfMarginNarrow => 'Wąskie';

  @override
  String get pdfMarginNormal => 'Normalne';

  @override
  String get pdfMarginWide => 'Szerokie';

  @override
  String get pdfIncludePageNumbers => 'Dodaj numery stron';

  @override
  String get export => 'Eksportuj';

  @override
  String get exportFormat => 'Format wyjściowy';

  @override
  String get exportingPdf => 'Eksportowanie PDF…';

  @override
  String get fileTypePdf => 'Dokument PDF';

  @override
  String pdfExported(String fileName) {
    return 'Wyeksportowano $fileName.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ostrzeżeniami',
      one: '1 ostrzeżeniem',
    );
    return '$fileName został wyeksportowany z $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'Brakuje składnika eksportu PDF. Zainstaluj ponownie BusyMark i spróbuj jeszcze raz.';

  @override
  String get pdfExportTimedOut =>
      'Eksport PDF trwał zbyt długo i został zatrzymany.';

  @override
  String get pdfExportFailed =>
      'BusyMark nie mógł wyeksportować tego dokumentu jako PDF.';

  @override
  String get visualizationRendering => 'Renderowanie…';

  @override
  String get visualizationStale =>
      'Wyświetlanie ostatniego poprawnego renderingu';

  @override
  String get visualizationShowSource => 'Pokaż źródło';

  @override
  String get visualizationShowRender => 'Pokaż wynik';

  @override
  String get visualizationFitWidth => 'Dopasuj do szerokości';

  @override
  String get visualizationSaveImage => 'Zapisz obraz';

  @override
  String get visualizationCopyImage => 'Kopiuj obraz';

  @override
  String get visualizationImageCopied => 'Obraz skopiowany';

  @override
  String get visualizationOpenApiReference => 'Otwórz dokumentację API';

  @override
  String get visualizationValid => 'Prawidłowy';

  @override
  String get visualizationInvalid => 'Nieprawidłowy';

  @override
  String get visualizationServers => 'Serwery';

  @override
  String get visualizationPaths => 'Ścieżki';

  @override
  String get visualizationOperations => 'Operacje';

  @override
  String get visualizationTags => 'Tagi';

  @override
  String get visualizationNoOperations => 'Brak pasujących operacji';

  @override
  String get visualizationSearchOperations => 'Szukaj operacji';

  @override
  String get visualizationRenderFailed =>
      'Nie udało się wyrenderować tej wizualizacji.';

  @override
  String get visualizationRetry => 'Spróbuj ponownie';

  @override
  String visualizationSaved(String fileName) {
    return 'Zapisano $fileName';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Eksportuj aktywny dokument lub moduł Writerside jako PDF.';

  @override
  String get instances => 'Instancje';

  @override
  String get newInstance => 'Nowa instancja';

  @override
  String get newTocLibrary => 'Nowa biblioteka spisu treści';

  @override
  String get editInstance => 'Edytuj instancję';

  @override
  String get openTocFile => 'Otwórz plik spisu treści';

  @override
  String get createInstance => 'Utwórz instancję';

  @override
  String get createTocLibrary => 'Utwórz bibliotekę spisu treści';

  @override
  String get instanceContent => 'Zawartość';

  @override
  String get instanceContentSource => 'Utwórz z';

  @override
  String get emptyInstance => 'Pusta instancja';

  @override
  String get markdownFiles => 'Lokalne pliki Markdown';

  @override
  String get chooseMarkdownFolder => 'Wybierz folder Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Wybierz folder zawierający pliki Markdown.';

  @override
  String get instanceAppearance => 'Wygląd';

  @override
  String get instanceColor => 'Kolor ikony';

  @override
  String get instanceVersion => 'Wersja';

  @override
  String instanceVersionInherited(String version) {
    return 'Gdy to pole jest puste, wersja projektu to $version.';
  }

  @override
  String get instanceWebPath => 'Ścieżka internetowa';

  @override
  String get instanceStatus => 'Stan';

  @override
  String get instanceStatusRelease => 'Wydanie';

  @override
  String get instanceStatusEap => 'Wczesny dostęp';

  @override
  String get instanceStatusDeprecated => 'Przestarzała';

  @override
  String get allowSearchEngineIndexing =>
      'Zezwalaj na indeksowanie przez wyszukiwarki';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Zezwalaj zewnętrznym wyszukiwarkom na indeksowanie tego wyniku.';

  @override
  String get offlineArtifact => 'Pakiet offline';

  @override
  String get offlineArtifactDescription =>
      'Dołącz zasoby, aby zbudowana dokumentacja była samowystarczalna.';

  @override
  String get instanceOutputSettings => 'Ustawienia wyniku';

  @override
  String get markdownImportSource => 'Źródło Markdown';

  @override
  String get markdownImportFiles => 'Pliki Markdown';

  @override
  String get selectNone => 'Odznacz wszystko';

  @override
  String markdownFilesFound(int count) {
    return 'Znaleziono pliki Markdown: $count';
  }

  @override
  String get noMarkdownFilesFound =>
      'W tym katalogu nie znaleziono plików Markdown.';

  @override
  String get copyReferencedMedia => 'Kopiuj używane multimedia';

  @override
  String get copyReferencedMediaDescription =>
      'Skopiuj lokalne obrazy i filmy używane przez wybrane pliki, zachowując ścieżki względne.';

  @override
  String get instanceIdRenameWarningTitle => 'Zmienić identyfikator instancji?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark zmieni nazwę pliku .tree i zaktualizuje odwołania projektu Writerside z „$oldId” na „$newId”. Skrypty publikowania nie zostaną zmienione i trzeba je zaktualizować oddzielnie.';
  }

  @override
  String get renameAndUpdateReferences => 'Zmień nazwę i zaktualizuj odwołania';

  @override
  String get tocLibraryDescription =>
      'Biblioteka spisu treści przechowuje sekcje wielokrotnego użytku i nie tworzy własnego wyniku.';

  @override
  String get defaultTocLibraryName => 'Wspólny spis treści';

  @override
  String get instanceColorAutomatic => 'Automatyczny';

  @override
  String get instanceColorBlue => 'Niebieski';

  @override
  String get instanceColorGreen => 'Zielony';

  @override
  String get instanceColorOrange => 'Pomarańczowy';

  @override
  String get instanceColorPurple => 'Fioletowy';

  @override
  String get instanceColorRed => 'Czerwony';

  @override
  String get instanceColorTeal => 'Morski';

  @override
  String get instanceColorYellow => 'Żółty';

  @override
  String get errorWritersideInstanceNameRequired => 'Wprowadź nazwę instancji.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Instancja o identyfikatorze „$id” już istnieje.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Drzewo instancji już istnieje: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Katalog źródłowy Markdown nie istnieje: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Wybierz co najmniej jeden plik Markdown do zaimportowania.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'To nie jest czytelny plik Markdown wewnątrz wybranego źródła: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Import nadpisałby istniejący plik projektu: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Pliki instancji zmieniły się na dysku. Przejrzyj je i spróbuj ponownie.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark nie mógł całkowicie wycofać zmiany instancji. Przed kontynuowaniem przejrzyj te pliki: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Biblioteka spisu treści nie może importować tematów Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Ścieżka internetowa musi mieścić się w jednym wierszu.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Konfiguracja instancji Writerside jest nieprawidłowa. Popraw jej diagnostykę i spróbuj ponownie.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark nie mógł bezpiecznie przygotować zmian instancji.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Nieznany stan instancji „$status”. Użyj release, eap lub deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'Identyfikator instancji „$id” jest używany przez więcej niż jeden plik drzewa.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'Elementem głównym pliku buildprofiles.xml musi być <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Wartość $name „$value” musi być równa true lub false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Element <build-profile> musi określać identyfikator instancji.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Element <include> drzewa musi określać zarówno from, jak i element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Element <snippet> drzewa musi określać id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Odwołanie spisu treści między instancjami musi określać zarówno ref, jak i in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Element spisu treści nie może wskazywać więcej niż jednego tematu, odwołania, łącza lub przekierowania.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Identyfikator elementu drzewa „$id” zadeklarowano więcej niż raz.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Elementem głównym pliku grup instancji musi być <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Grupa instancji musi określać niepusty identyfikator i listę instancji.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Identyfikator grupy instancji „$id” zadeklarowano więcej niż raz.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Dołączenie spisu treści „$source#$id” należy do zewnętrznego modułu „$origin” i nie może zostać rozwinięte w tym obszarze roboczym.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Element drzewa „$id” nie istnieje w zarejestrowanym drzewie „$source”.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Dołączenie drzewa „$source#$id” tworzy cykl.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Warunek instancji odwołuje się do nieznanej grupy „@$group”.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Odwołanie między instancjami wskazuje nieznaną instancję „$instance”.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Temat „$topic” nie znajduje się we wskazanej instancji „$instance”.';
  }

  @override
  String get download => 'Pobierz';

  @override
  String get exportWritersideAsPdf => 'Eksportuj Writerside jako PDF';

  @override
  String get writersidePdfContent => 'Zawartość eksportu';

  @override
  String get writersidePdfPage => 'Strona';

  @override
  String get exportingWritersidePdf => 'Eksportowanie PDF Writerside…';

  @override
  String get ai => 'SI';

  @override
  String get aiLocalOllama => 'Lokalny Ollama';

  @override
  String get aiDisabled => 'Wyłączone';

  @override
  String get aiExplicitEditingDescription =>
      'Edycja z użyciem SI jest uruchamiana wyłącznie jawnie. BusyMark wysyła do wybranego dostawcy tylko pokazany kontekst i nigdy nie stosuje propozycji bez jej sprawdzenia.';

  @override
  String get aiProvider => 'Dostawca SI';

  @override
  String get aiDefaultProvider => 'Domyślny dostawca';

  @override
  String get aiConfigureProvider => 'Skonfiguruj dostawcę';

  @override
  String get aiChooseProvider => 'Wybierz dostawcę SI';

  @override
  String get aiOllamaEndpoint => 'Punkt końcowy Ollama';

  @override
  String get aiOllamaModel => 'Model Ollama';

  @override
  String get aiTestConnection => 'Testuj połączenie';

  @override
  String get aiTestingConnection => 'Testowanie…';

  @override
  String aiConnectionReady(int count) {
    return 'Połączono. Znaleziono zainstalowane modele: $count.';
  }

  @override
  String get aiNoModels => 'Nie wybrano modelu.';

  @override
  String get aiConnectionFailed =>
      'BusyMark nie mógł zweryfikować generowania tekstu przez SI.';

  @override
  String get aiConfigureFirst =>
      'Najpierw włącz dostawcę SI i zweryfikuj model w Ustawienia → SI.';

  @override
  String get aiEditWithAi => 'Edytuj za pomocą SI';

  @override
  String get aiRefineWithAi => 'Ulepsz za pomocą SI';

  @override
  String get aiInstruction => 'Polecenie';

  @override
  String get aiChangeTarget => 'Co może się zmienić';

  @override
  String get aiSharedContext => 'Kontekst udostępniany SI';

  @override
  String get aiTargetSelection => 'Zaznaczona treść';

  @override
  String get aiTargetInsertAfterBlock => 'Wstaw po bieżącym bloku';

  @override
  String get aiTargetCurrentBlock => 'Bieżący blok';

  @override
  String get aiTargetCurrentSection => 'Bieżąca sekcja';

  @override
  String get aiTargetCompleteDocument => 'Cały dokument';

  @override
  String get aiContextNone => 'Bez kontekstu dokumentu';

  @override
  String get aiContextSelection => 'Zaznaczona treść';

  @override
  String get aiContextCurrentBlock => 'Bieżący blok';

  @override
  String get aiContextCurrentSection => 'Bieżąca sekcja';

  @override
  String get aiContextCompleteDocument => 'Cały dokument';

  @override
  String get aiGenerating => 'Generowanie propozycji…';

  @override
  String get aiProposal => 'Propozycja SI';

  @override
  String get aiGenerateProposal => 'Wygeneruj propozycję';

  @override
  String aiContextDisclosure(int count) {
    return 'Wybrany dostawca otrzyma $count znaków z pokazanego kontekstu.';
  }

  @override
  String get aiOriginal => 'Tekst oryginalny';

  @override
  String get aiSuggested => 'Propozycja';

  @override
  String get aiApplyProposal => 'Zastosuj propozycję';

  @override
  String aiTokenUsage(int input, int output) {
    return 'Tokeny wejściowe: $input · tokeny wyjściowe: $output';
  }

  @override
  String get aiStaleProposal =>
      'Dokument zmienił się podczas generowania propozycji. Uruchom operację ponownie.';

  @override
  String get gitAiStagedChangesChanged =>
      'Zmiany w indeksie zmieniły się podczas generowania tego komunikatu commita. Uruchom operację ponownie.';

  @override
  String get aiViewContext => 'Pokaż wysłany kontekst';

  @override
  String get aiReviewExactContent => 'Przejrzyj dokładną treść';

  @override
  String get aiContentToChange => 'Treść do zmiany';

  @override
  String get aiContentSentToAi => 'Treść wysyłana do SI';

  @override
  String get aiApiKey => 'Klucz API';

  @override
  String get aiApiKeyStoredHint =>
      'Klucz jest zapisany w systemowym magazynie poświadczeń';

  @override
  String get aiApiKeyEnterHint => 'Wprowadź klucz API dostawcy';

  @override
  String get aiReplaceApiKey => 'Zastąp klucz API';

  @override
  String get aiSaveApiKey => 'Zapisz bezpiecznie klucz API';

  @override
  String get aiRemoveApiKey => 'Usuń zapisany klucz API';

  @override
  String get aiCredentialSaved =>
      'Klucz API zapisano w systemowym magazynie poświadczeń.';

  @override
  String get aiCredentialRemoved => 'Zapisany klucz API został usunięty.';

  @override
  String get aiModelRouting => 'Wybór modelu';

  @override
  String get aiAutomaticRouting => 'Automatycznie według zadania';

  @override
  String get aiFixedModelRouting => 'Użyj wybranego modelu';

  @override
  String get aiPreferredModel => 'Preferowany model';

  @override
  String get aiModel => 'Model';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests żądań · $input tokenów wejściowych · $output tokenów wyjściowych';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Wysłać treść do $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Włącz $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Wysyłana jest wyłącznie treść pokazana w każdym oknie przeglądu SI. Żądania są bezstanowe, propozycje wymagają sprawdzenia, a klucz API jest przechowywany w systemowym magazynie poświadczeń systemu Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Najpierw potwierdź udostępnianie danych usłudze $provider w Ustawienia → SI.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Generowanie zweryfikowano za pomocą $model. Dostępnych zgodnych modeli: $count.';
  }

  @override
  String get aiColdStartObserved => 'Wykryto zimny start modelu lokalnego.';

  @override
  String get aiNoCompatibleModels => 'Brak zgodnego modelu generowania tekstu.';

  @override
  String get aiEnableProvider => 'Najpierw włącz dostawcę SI.';

  @override
  String get aiDraftCommitMessage => 'Utwórz wersję roboczą komunikatu commita';

  @override
  String get aiDrafting => 'Tworzenie wersji roboczej…';

  @override
  String get aiDraftWithAi => 'Utwórz wersję roboczą z SI';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Nagłówek poziomu $level występuje po poziomie $previousLevel; sprawdź zagnieżdżenie sekcji.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Tekst odnośnika jest pusty; podaj dostępną nazwę opisującą jego cel.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Sprawdź, czy tekst odnośnika „$text” opisuje jego cel w kontekście.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Nagłówki tabeli muszą identyfikować kolumny; uzupełnij każdy pusty nagłówek.';

  @override
  String get mathRenderFailed =>
      'Nie udało się wyrenderować wyrażenia matematycznego.';

  @override
  String get inlineMath => 'Matematyka w tekście';

  @override
  String get displayMath => 'Matematyka blokowa';

  @override
  String get goToDeclaration => 'Przejdź do deklaracji';

  @override
  String get findUsages => 'Znajdź użycia';

  @override
  String get cannotRenameSymbol =>
      'Nie można bezpiecznie zmienić nazwy symbolu. Sprawdź nazwę i odśwież odwołanie przed ponowną próbą.';

  @override
  String get renameTopicFileInstead =>
      'Identyfikatory tematów pochodzą z nazw ich plików. Użyj polecenia Zmień nazwę pliku tematu w spisie treści lub na pasku bocznym Pliki.';

  @override
  String get keyboardLayout => 'Układ klawiatury';

  @override
  String get diagnosticWritersideUnsupported =>
      'Nieobsługiwana lub nieprawidłowa treść jest wyświetlana jako źródło.';

  @override
  String diagnosticWritersideSource(String reference, String reason) {
    return 'Nie można rozwiązać źródła „$reference”: $reason';
  }

  @override
  String diagnosticWritersideLink(String destination) {
    return 'Cel odnośnika jest niedostępny w tej instancji: $destination';
  }

  @override
  String diagnosticWritersideSchema(
    String element,
    String attribute,
    String reason,
  ) {
    return 'Nieprawidłowy znacznik Writerside: $element, $attribute. $reason';
  }

  @override
  String get diagnosticWritersideLlmsTxt =>
      'Użyj <llms-txt>true</llms-txt> lub <llms-txt>false</llms-txt>; single-file nie jest już obsługiwane.';

  @override
  String diagnosticWritersideReference(String kind, String reference) {
    return 'Nie można rozwiązać $kind: $reference';
  }

  @override
  String get exportAsHtml => 'Eksportuj jako HTML…';

  @override
  String get fileTypeHtml => 'Dokument HTML';

  @override
  String get exportingHtml => 'Eksportowanie HTML…';

  @override
  String get htmlExported => 'Eksport HTML zakończony';

  @override
  String get htmlExportFailed => 'Eksport HTML nie powiódł się';

  @override
  String get htmlKeepAssetsTogether =>
      'Podczas kopiowania zachowaj razem plik HTML i towarzyszący mu katalog zasobów.';

  @override
  String get htmlInstanceDescription =>
      'Wyeksportuj jedną instancję jako połączone strony offline. Wybierz nazwę osobnego katalogu wyjściowego.';

  @override
  String get htmlInstance => 'Instancja';

  @override
  String get htmlOwnedDirectoryOnly =>
      'Można zastąpić tylko katalog utworzony przez eksport HTML BusyMark. Zmienione lub obce pliki zostaną zachowane.';

  @override
  String get showInFolder => 'Pokaż w folderze';

  @override
  String sortTableColumn(String column) {
    return 'Sortuj $column';
  }

  @override
  String get exportReset => 'Przywróć domyślne';

  @override
  String get exportToc => 'Dołącz spis treści';

  @override
  String get exportTocDepth => 'Głębokość spisu treści';

  @override
  String get exportNumberHeadings => 'Numeruj nagłówki';

  @override
  String get exportLegal => 'US Legal';

  @override
  String get exportCustom => 'Niestandardowy';

  @override
  String get exportPageWidth => 'Szerokość strony (mm)';

  @override
  String get exportPageHeight => 'Wysokość strony (mm)';

  @override
  String get exportMarginTop => 'Margines górny (mm)';

  @override
  String get exportMarginRight => 'Margines prawy (mm)';

  @override
  String get exportMarginBottom => 'Margines dolny (mm)';

  @override
  String get exportMarginLeft => 'Margines lewy (mm)';

  @override
  String get exportTypography => 'Typografia';

  @override
  String get exportSans => 'Bezszeryfowa';

  @override
  String get exportSerif => 'Szeryfowa';

  @override
  String get exportBodySize => 'Rozmiar tekstu';

  @override
  String get exportCodeSize => 'Rozmiar kodu';

  @override
  String get exportRunningText => 'Nagłówek i stopka';

  @override
  String get exportHeader => 'Nagłówek';

  @override
  String get exportFooter => 'Stopka';

  @override
  String get exportNone => 'Brak';

  @override
  String get exportDocumentTitle => 'Tytuł dokumentu';

  @override
  String get exportBottomLeft => 'Na dole po lewej';

  @override
  String get exportBottomCenter => 'Na dole na środku';

  @override
  String get exportBottomRight => 'Na dole po prawej';

  @override
  String get exportFirstPage => 'Pokaż nagłówek i stopkę na pierwszej stronie';

  @override
  String get exportAccent => 'Kolor akcentu / łączy';

  @override
  String get exportTheme => 'Motyw';

  @override
  String get exportAutomatic => 'Automatyczny';

  @override
  String get exportLayout => 'Układ';

  @override
  String get exportContentWidth => 'Maksymalna szerokość treści';

  @override
  String get exportOutput => 'Wyjście';

  @override
  String get exportPackaging => 'Pakowanie';

  @override
  String get exportSingleFile => 'Jeden plik HTML';

  @override
  String get exportAssetsDirectory => 'HTML + katalog zasobów';

  @override
  String get exportCustomCss => 'Własny arkusz stylów…';

  @override
  String get exportRemoveCss => 'Usuń własny arkusz stylów';

  @override
  String get exportCssNote =>
      'Wybierz opcjonalny plik CSS UTF-8 (do 256 KiB). Importy, adresy zasobów oraz wykonywalny CSS lub sekwencje ucieczki są odrzucane. Style następują po arkuszu BusyMark. Zdalne zasoby nie są pobierane.';

  @override
  String get exportSitePackagingNote =>
      'Writerside zachowuje osobne połączone strony tematów. Tryb jednego pliku osadza zasoby w każdej stronie.';

  @override
  String get exportInvalidGeometry =>
      'Po odjęciu marginesów pozostaw co najmniej 20 mm szerokości i wysokości treści.';

  @override
  String get exportInvalidColor => 'Wpisz kolor w formacie #RRGGBB.';

  @override
  String get exportInvalidCss =>
      'Wybierz czytelny plik .css UTF-8 do 256 KiB, bez importów, adresów zasobów, HTML oraz wykonywalnego CSS i sekwencji ucieczki.';

  @override
  String get clipboardHistory => 'Historia w Koszyku';

  @override
  String get clipboardHistoryDescription =>
      'Otwórz historię w koszyku lokalną dla sesji.';

  @override
  String get clipboardCurrent => 'Aktualny koszyk';

  @override
  String get clipboardCurrentExternal => 'Aktualny koszyk z innego programu';

  @override
  String clipboardDestination(String name) {
    return 'Wklej do $name';
  }

  @override
  String get clipboardSessionOnly =>
      'Przechowywane tylko dla tej sesji BusyMark.';

  @override
  String get clipboardNoItems => 'Historia w koszyku jest pusta.';

  @override
  String get clipboardDisabled =>
      'Zbiór \"Historia w koszyku\" wyłączony w Ustawieniach.';

  @override
  String get clipboardUnavailable =>
      'Aktualny zawartość koszyka niedostępna lub nieobsługiwana.';

  @override
  String get clipboardTooLarge =>
      'Ten element schowka jest zbyt duży, aby go zapisać.';

  @override
  String get clipboardPastePlainText => 'Wklej jako zwykły tekst';

  @override
  String get clipboardClearAll => 'Wyczyść historię schowka';

  @override
  String get clipboardEntryText => 'Tekst';

  @override
  String get clipboardEntryRichText => 'Bogaty tekst';

  @override
  String get clipboardEntryImage => 'Obraz';

  @override
  String clipboardOrigin(String name) {
    return 'Skopiowano z $name';
  }

  @override
  String get localHistory => 'Lokalna historia';

  @override
  String get localHistoryEllipsis => 'Lokalna historia…';

  @override
  String get localHistoryDescription =>
      'Pokaż zapisane i automatyczne lokalne wersje dla bieżącego dokumentu.';

  @override
  String get findLocalHistoryEllipsis => 'Znajdź w Lokalnej Historii…';

  @override
  String get findLocalHistoryDescription =>
      'Wyszukaj dokumenty i zawartość wersji w Lokalnej Historii.';

  @override
  String get localHistoryNoDocuments =>
      'Żaden dokument nie ma Lokalnej Historii.';

  @override
  String get localHistoryNoRevisions =>
      'Ten dokument nie ma wersji w Lokalnej Historii.';

  @override
  String get localHistorySelectedRevision => 'Wybrana wersja';

  @override
  String get localHistoryCurrentEditor => 'Aktualny zawartość edytora';

  @override
  String get localHistoryCurrentDisk => 'Aktualna zawartość na dysku';

  @override
  String get localHistoryMissingFile => 'Oryginalny plik nie istnieje.';

  @override
  String get localHistoryRestoreRevision => 'Przywróć Wersję';

  @override
  String get localHistoryRestoreOriginalLocation =>
      'Przywróć do Oryginalnej Lokalizacji';

  @override
  String get localHistoryRestoreNewLocation => 'Przywróć do Nowej Lokalizacji…';

  @override
  String get localHistoryRestoreChange => 'Przywróć Zmianę';

  @override
  String get localHistoryRestoreUnavailable =>
      'Ta zmiana nie może być przywrócona, ponieważ porównanie nie jest już aktualne.';

  @override
  String get localHistoryComparisonSimplified =>
      'To duże porównanie zostało uproszczone. Przywracanie pojedynczych zmian jest niedostępne.';

  @override
  String localHistoryOlderChange(String text) {
    return 'Stara wersja zmiany: $text';
  }

  @override
  String localHistoryCurrentChange(String text) {
    return 'Aktualna zmiana zawartości: $text';
  }

  @override
  String get localHistoryDeleted => 'Usunięto';

  @override
  String get localHistoryUntitled => 'Bez tytułu';

  @override
  String get localHistoryClearDocument => 'Wyczyść historię tego dokumentu';

  @override
  String get localHistoryClearAll => 'Wyczyść całą lokalną historię';

  @override
  String get localHistoryClearDocumentTitle =>
      'Czy chcesz wyczyścić historię dokumentu?';

  @override
  String get localHistoryClearAllTitle =>
      'Czy chcesz wyczyścić całą lokalną historię?';

  @override
  String get localHistoryClearConfirmation =>
      'To trwale usuwa zapisane wersje. Ta akcja nie może być cofnięta.';

  @override
  String get localHistoryWarningIndexRebuilt =>
      'Indeks Lokalnej Historii został uszkodzony i odtworzony z nieuszkodzonych wersji.';

  @override
  String localHistoryWarningUnsupportedFormat(String version) {
    return 'Ta Lokalna Historia używa nieobsługiwanego formatu $version.';
  }

  @override
  String localHistoryWarningUnavailable(String detail) {
    return 'Lokalna Historia jest niedostępna: $detail';
  }

  @override
  String get localHistoryWarningRecordingDisabled =>
      'Nagrywanie jest wyłączone lub ta ścieżka jest wykluczona. Włącz nagrywanie przed przywracaniem.';

  @override
  String localHistoryWarningPathChange(String detail) {
    return 'Lokalna Historia nie mogła zarejestrować zmiany ścieżki: $detail';
  }

  @override
  String localHistoryWarningDeletedPath(String detail) {
    return 'Lokalna historia nie mogła zachować usuniętego ścieżki: $detail';
  }

  @override
  String get localHistoryWarningRevisionMissing =>
      'Wybrana wersja jest nieobecna lub uszkodzona.';

  @override
  String localHistoryWarningRevisionRead(String detail) {
    return 'Wybrana wersja nie może być odczytana: $detail';
  }

  @override
  String localHistoryWarningCapture(String detail) {
    return 'Lokalna historia nie mogła przechwycić tej wersji: $detail';
  }

  @override
  String localHistoryRevisionAt(String reason, String timestamp) {
    return '$reason – $timestamp';
  }

  @override
  String get localHistoryReasonBaseline => 'Podstawa';

  @override
  String get localHistoryReasonSaved => 'Zapisano';

  @override
  String get localHistoryReasonAutomaticCheckpoint => 'Automatyczny checkpoint';

  @override
  String get localHistoryReasonBeforeReload => 'Przed ponownym załadowaniem';

  @override
  String get localHistoryReasonBeforeDiscard => 'Przed wyrzuceniem';

  @override
  String get localHistoryReasonBeforeRestore => 'Przed przywróceniem';

  @override
  String get localHistoryReasonBeforeDelete => 'Przed usunięciem';

  @override
  String get localHistoryReasonExternalChange => 'Zmiana z zewnątrz';

  @override
  String get settingsHistory => 'Historia';

  @override
  String get settingsClipboardHistoryTitle => 'Zapisywanie historii w schowku';

  @override
  String get settingsClipboardHistoryDescription =>
      'Zachowaj skopiowany i pomyślnie wklejony zawartość tylko dla tej sesji BusyMark.';

  @override
  String get settingsLocalHistoryTitle => 'Zapisywanie lokalnej historii';

  @override
  String get settingsLocalHistoryDescription =>
      'Przechowywanie wersji dokumentu na tym urządzeniu w celu odzyskania i porównywania.';

  @override
  String get settingsHistoryCheckpoint =>
      'Automatyczny interwał kontrolnego zapisu';

  @override
  String get settingsHistoryRetention => 'Okres przechowywania';

  @override
  String get settingsHistoryStorage => 'Maksymalna pojemność';

  @override
  String get settingsHistoryExcludedPaths => 'Wykluczone ścieżki';

  @override
  String get settingsHistoryExcludedPathsHint =>
      'Jedna absolutna ścieżka na linię';

  @override
  String settingsSecondsValue(int value) {
    return '$value sekundy';
  }

  @override
  String settingsDaysValue(int value) {
    return '$value dni';
  }

  @override
  String settingsMebibytesValue(int value) {
    return '$value MiB';
  }

  @override
  String get spelling => 'Pisownia';

  @override
  String get automaticSpelling => 'Automatyczne sprawdzanie pisowni';

  @override
  String get defaultSpellingLanguage => 'Domyślny język pisowni';

  @override
  String get projectSpellingLanguage => 'Język sprawdzania pisowni projektu';

  @override
  String get chooseSpellingLanguage => 'Wybierz język pisowni';

  @override
  String get spellingLanguageUnsetStatus => 'Język…';

  @override
  String get spellingOffStatus => 'Pisownia wyłączona';

  @override
  String get checkSpelling => 'Sprawdź pisownię';

  @override
  String get ignoreSpellingOnce => 'Ignoruj raz';

  @override
  String get ignoreSpellingDocument => 'Ignoruj wszystkie w tym dokumencie';

  @override
  String get addPersonalSpellingWord => 'Dodaj do słownika osobistego';

  @override
  String get addProjectSpellingWord => 'Dodaj do słownika projektu';

  @override
  String get inheritSpellingLanguage => 'Użyj języka projektu lub aplikacji';

  @override
  String get disableDocumentSpelling => 'Nie sprawdzaj pisowni';

  @override
  String get importSpellingDictionary => 'Importuj słownik';

  @override
  String get personalSpellingDictionary => 'Słownik osobisty';

  @override
  String get projectSpellingDictionary => 'Słownik projektu';

  @override
  String get noSpellingErrors => 'Brak błędów pisowni';

  @override
  String get noSpellingSuggestions => 'Brak sugestii pisowni';

  @override
  String get spellingWordCheckFailed => 'Nie można sprawdzić tego słowa';

  @override
  String get spellingCheckFailed => 'Sprawdzanie pisowni nie powiodło się';

  @override
  String get spellingSettingsLoadFailed =>
      'Nie można wczytać ustawień sprawdzania pisowni';

  @override
  String get retrySpellingSettings =>
      'Ponów wczytywanie ustawień sprawdzania pisowni';

  @override
  String get spellingCheckIncomplete => 'Sprawdzanie pisowni jest niepełne';

  @override
  String get spellingDictionaryNotInstalled => 'Słownik nie jest zainstalowany';

  @override
  String spellingDictionaryNotInstalledForLanguage(String dictionary) {
    return 'Słownik $dictionary nie jest zainstalowany';
  }

  @override
  String spellingDictionaryNotInstalledWithSize(String size) {
    return 'Niezainstalowany · $size';
  }

  @override
  String get spellingDictionaryInstalled => 'Zainstalowany';

  @override
  String get installSpellingDictionary => 'Zainstaluj słownik';

  @override
  String get removeSpellingDictionary => 'Usuń słownik';

  @override
  String get cancelSpellingDictionaryInstall => 'Anuluj pobieranie słownika';

  @override
  String get retrySpellingDictionaryInstall => 'Ponów instalację słownika';

  @override
  String spellingDictionaryDownloading(String size) {
    return 'Pobieranie $size…';
  }

  @override
  String get spellingDictionaryValidating => 'Sprawdzanie słownika…';

  @override
  String get spellingDictionaryInstallFailed =>
      'Instalacja nie powiodła się — wybierz, aby ponowić';

  @override
  String spellingDictionaryInstallPrompt(String dictionary, String size) {
    return 'Zainstalować $dictionary ($size)? Po instalacji będzie dostępny offline do czasu usunięcia.';
  }

  @override
  String get spellingDictionaryUnavailable => 'Słownik jest niedostępny';

  @override
  String get spellingChecking => 'Sprawdzanie pisowni…';

  @override
  String exportInvalidRange(String field, String minimum, String maximum) {
    return '$field: wpisz liczbę między $minimum a $maximum.';
  }

  @override
  String get spellingDictionaryRecoveryConflict =>
      'Słownik pisowni został zmieniony zewnętrznie. Zachowano kopię odzyskiwania.';

  @override
  String get windowMinimize => 'Minimalizuj';

  @override
  String get windowMaximize => 'Maksymalizuj';

  @override
  String get windowRestore => 'Przywróć';

  @override
  String get nextcloudNotes => 'Nextcloud Notes';

  @override
  String get nextcloudConnect => 'Połącz';

  @override
  String get nextcloudReconnect => 'Połącz ponownie';

  @override
  String get nextcloudDisconnect => 'Rozłącz';

  @override
  String get nextcloudServer => 'Adres serwera';

  @override
  String get nextcloudSignInBrowser => 'Dokończ logowanie w przeglądarce.';

  @override
  String get nextcloudFavorites => 'Ulubione';

  @override
  String get nextcloudNewNote => 'Nowa notatka';

  @override
  String get nextcloudSavedLocally =>
      'Zapisano lokalnie · oczekuje na synchronizację';

  @override
  String get nextcloudSyncing => 'Synchronizowanie';

  @override
  String get nextcloudSynced => 'Zsynchronizowano';

  @override
  String get nextcloudOffline => 'Bez połączenia';

  @override
  String get nextcloudLocked => 'Zablokowane przez serwer';

  @override
  String get nextcloudReconnectRequired => 'Wymagane ponowne połączenie';

  @override
  String get nextcloudCreationUncertain => 'Niepewny wynik utworzenia';

  @override
  String get nextcloudReadOnly => 'Tylko do odczytu';

  @override
  String get nextcloudTakeRemote => 'Użyj wersji z serwera';

  @override
  String get nextcloudMerge => 'Scal';

  @override
  String get nextcloudDeleteNote => 'Usunąć notatkę?';

  @override
  String get nextcloudWorkspaceReplaceUnavailable =>
      'Zastępowanie w obszarze roboczym nie jest dostępne dla Nextcloud Notes. Zastępuj w poszczególnych notatkach.';

  @override
  String get nextcloudSaveLocalCopy => 'Zapisz kopię lokalną…';

  @override
  String get nextcloudDisconnectWarning =>
      'Usunięcie konta usuwa notatki w pamięci podręcznej i oczekujące zmiany z urządzenia. Najpierw zsynchronizuj, aby zachować pracę na serwerze.';

  @override
  String get nextcloudAttachmentRetryWarning =>
      'Jeśli poprzednie przesyłanie się powiodło, ponowienie może pozostawić nieużywany załącznik na serwerze.';

  @override
  String get nextcloudAttachmentReference =>
      'Odnośnik do załącznika na serwerze';

  @override
  String get nextcloudAddAttachment => 'Dodaj załącznik…';

  @override
  String get nextcloudDeleteAttachmentWarning =>
      'Usunięcie tego załącznika spowoduje, że jego odnośniki w notatce będą niedostępne. Zachowane dane można odzyskać z lokalnej historii.';

  @override
  String get nextcloudChooseConflictingAttributes =>
      'Wybierz wartość każdego sprzecznego atrybutu.';

  @override
  String get nextcloudUseServerNote => 'Użyj tej notatki z serwera';

  @override
  String get nextcloudUseServerNoteExplanation =>
      'Łączy ten szkic z wybraną notatką na serwerze, a następnie synchronizuje zachowane zmiany lokalne. Zgodne żądanie nie potwierdza, kto utworzył notatkę.';

  @override
  String get nextcloudExactCandidate =>
      'Dokładna zgodność z żądaniem; tożsamość niepotwierdzona.';

  @override
  String get nextcloudPossibleCandidate =>
      'Możliwa zgodność po normalizacji żądania; tożsamość niepotwierdzona.';

  @override
  String get nextcloudSelectCandidate =>
      'Wybierz notatkę z serwera do sprawdzenia';

  @override
  String get nextcloudCreateSeparate => 'Utwórz osobną notatkę';

  @override
  String get nextcloudCreateSeparateWarning =>
      'Pierwsze żądanie mogło już utworzyć notatkę na serwerze. Ta czynność tworzy osobną notatkę z zachowaną pracą lokalną. Żadne podejrzane duplikaty nie zostaną usunięte.';

  @override
  String get wsSemanticFormats => 'Formatowanie semantyczne';

  @override
  String get wsUiControl => 'Element interfejsu';

  @override
  String get wsFilePath => 'Plik / Ścieżka';

  @override
  String get wsUiPath => 'Ścieżka interfejsu';

  @override
  String get wsDefinitionList => 'Lista definicji';

  @override
  String get wsIncludeContent => 'Dołącz treść wielokrotnego użytku';

  @override
  String get wsVariableReference => 'Odwołanie do zmiennej';

  @override
  String get wsConvertList => 'Przekształć listę w procedurę';

  @override
  String get wsElementProperties => 'Właściwości elementu';

  @override
  String get wsTopicProperties => 'Właściwości tematu';

  @override
  String get wsCollapsible => 'Możliwość zwijania';

  @override
  String get wsPublishedState => 'Opublikowany stan początkowy';

  @override
  String get wsExpanded => 'Rozwinięty';

  @override
  String get wsCollapsed => 'Zwinięty';

  @override
  String get wsCollapsedTitle => 'Zwinięty tytuł';

  @override
  String get wsTerm => 'Termin';

  @override
  String get wsListLayout => 'Układ listy';

  @override
  String get wsSyncGroup => 'Grupa synchronizacji';

  @override
  String get wsTabKey => 'Klucz karty';

  @override
  String get wsSwitcherLabel => 'Etykieta przełącznika';

  @override
  String get wsNavigationElements => 'Elementy nawigacji';

  @override
  String get wsNavigationDepth => 'Głębokość nawigacji';

  @override
  String get wsAddItem => 'Dodaj element';

  @override
  String get wsStep => 'Krok';

  @override
  String get wsPropertyInvalid => 'Nieprawidłowa wartość właściwości';

  @override
  String get wsFilter => 'Filtr';

  @override
  String get wsIdentifier => 'Identyfikator elementu';

  @override
  String get wsTldr => 'Podsumowanie (TLDR)';

  @override
  String get wsFullLayout => 'Pełna szerokość';

  @override
  String get wsMediumLayout => 'Średni (1:2)';

  @override
  String get wsNarrowLayout => 'Wąska kolumna terminu';

  @override
  String get wsTitle => 'Tytuł';

  @override
  String get wsSwitcherKey => 'Klucz przełącznika';

  @override
  String get nextcloudServerSettings => 'Ustawienia Notes na serwerze';

  @override
  String get nextcloudNotesPath => 'Ścieżka folderu notatek';

  @override
  String get nextcloudFileSuffix => 'Rozszerzenie nowych notatek';

  @override
  String get nextcloudServerSettingsExplanation =>
      'Te ustawienia Notes dotyczą innych klientów. Zmiana ścieżki nie przenosi plików; zmiana rozszerzenia nie zmienia nazw istniejących notatek.';

  @override
  String get nextcloudSettingsSaved => 'Zapisano ustawienia serwera';

  @override
  String get nextcloudSettingsNormalized =>
      'Zapisano wartości znormalizowane przez serwer';

  @override
  String get nextcloudPendingUpload => 'Załącznik oczekuje na wysłanie';

  @override
  String nextcloudServerCheck(String time) {
    return 'Ostatnie sprawdzenie serwera: $time';
  }

  @override
  String get nextcloudSettingsLoading => 'Wczytywanie ustawień serwera';

  @override
  String get nextcloudSettingsSaving => 'Zapisywanie ustawień serwera';

  @override
  String get nextcloudPreviousLocalEdit => 'Poprzednia lokalna zmiana';

  @override
  String get nextcloudUsePreviousEdit => 'Użyj poprzedniej zmiany';

  @override
  String get quickOpen => 'Szybkie otwieranie';

  @override
  String get notesAll => 'Wszystkie notatki';

  @override
  String get notesUncategorized => 'Bez kategorii';

  @override
  String get notesRecovery => 'Odzyskiwanie';

  @override
  String get notesRecentlyEdited => 'Ostatnio edytowane';

  @override
  String get notesOldestEdited => 'Najstarsza edycja';

  @override
  String get notesTitleAscending => 'Tytuł A–Z';

  @override
  String get notesTitleDescending => 'Tytuł Z–A';

  @override
  String get notesMove => 'Przenieś do kategorii';

  @override
  String get notesRemoveFavorite => 'Usuń z ulubionych';

  @override
  String get notesOffline => 'Udostępnij offline';

  @override
  String get notesOfflineRemove => 'Usuń przechowywanie offline';

  @override
  String get notesIndexing => 'Indeksowanie notatek…';

  @override
  String get notesSearchHelp =>
      'Terminy używają ORAZ. Użyj \"cytowanych fraz\", title: i category:.';

  @override
  String get notesSourceLocation => 'Pozycja w źródle';

  @override
  String get notesRecoveryHelp =>
      'Tylko zachowane notatki lokalne i historia lokalna. Kosz i historia serwera są niedostępne.';

  @override
  String get notesImport => 'Importuj notatki';

  @override
  String get notesExport => 'Eksportuj notatki';

  @override
  String get notesImportDistinct => 'Importuj jako osobną notatkę';

  @override
  String get notesAvailableOffline => 'Dostępne offline';

  @override
  String get notesIncomplete => 'Niekompletne';

  @override
  String get notesSelected => 'Wybrane notatki';

  @override
  String get notesNoHistory =>
      'Brak zachowanych wersji. Historia może być wyłączona, wygasła lub wyczyszczona.';

  @override
  String get notesTextAvailable => 'Tekst dostępny lokalnie';

  @override
  String get notesLocalVersion => 'Lokalna wersja robocza';

  @override
  String get notesAttachments => 'Załączniki';

  @override
  String get notesSkipped => 'Pominięto';

  @override
  String get notesFailed => 'Niepowodzenie';

  @override
  String get notesCompleted => 'Ukończono';

  @override
  String get notesImportNew => 'Rozpocznij nowy import';

  @override
  String get notesImportResume => 'Wznów przerwany import';

  @override
  String get notesImportAlreadyImported => 'Już zaimportowano w tej operacji';

  @override
  String get references => 'Odwołania';

  @override
  String get referenceIncoming => 'Przychodzące';

  @override
  String get referenceOutgoing => 'Wychodzące';

  @override
  String get referenceChooseTarget => 'Wybierz cel linku';

  @override
  String get referenceWholeDocument => 'Cały dokument';

  @override
  String get referenceSourceLocation => 'Lokalizacja źródła';

  @override
  String get referenceTargetLocation => 'Lokalizacja celu';

  @override
  String get referenceResolved => 'Rozwiązane';

  @override
  String get referenceMissing => 'Brak';

  @override
  String get referenceAmbiguous => 'Niejednoznaczne';

  @override
  String get referenceUnavailable => 'Niedostępne w tym kontekście';

  @override
  String get referenceUnsupported => 'Nieobsługiwane';

  @override
  String get referenceNoPortableId =>
      'Ten cel nie ma zweryfikowanego przenośnego adresu URL notatki.';

  @override
  String get wsIncludeLines => 'Dołącz wiersze';

  @override
  String get wsIncludeSymbol => 'Dołącz symbol';

  @override
  String get wsEmphasizeLines => 'Wyróżnij wyświetlane wiersze';

  @override
  String get wsPropertiesReadOnly =>
      'W tym widoku właściwości są tylko do odczytu.';

  @override
  String get wsPropertiesProtected =>
      'Element jest chroniony. Edytuj jego źródło.';

  @override
  String get wsPropertiesConflict =>
      'Dokument lub element zmieniono. Cofnij szkic i wybierz ponownie.';

  @override
  String get wsPropertiesUnresolved => 'Nie można obecnie rozwiązać odwołania.';

  @override
  String get wsUseDefault => 'Użyj domyślnej wartości';

  @override
  String get wsPropertiesSelection => 'Wybierz jeden element.';

  @override
  String get wsImageDisplay => 'Wyświetlanie obrazu';

  @override
  String get wsImageThumbnail => 'Klikalna miniatura';

  @override
  String get wsEnabled => 'Włączone';

  @override
  String get wsDisabled => 'Wyłączone';

  @override
  String get wsWidth => 'Szerokość';

  @override
  String get wsHeight => 'Wysokość';

  @override
  String get wsPropertiesInactive =>
      'Ta właściwość działa tylko przy opublikowanym zwijaniu.';

  @override
  String get wsNavigationAll => 'Wszystkie elementy z tytułem';

  @override
  String get wsNavigationNone => 'Bez nawigacji';

  @override
  String get wsNavigationCustom => 'Własna nawigacja';

  @override
  String get wsTitleOverride => 'Zastąp tytuł';

  @override
  String get wsCompactLayout => 'Zwarty';

  @override
  String get wsWideLayout => 'Szeroki';

  @override
  String get wsCodeSourceConflict =>
      'Przenieś lub usuń kod napisany w tym bloku przed ustawieniem src. Writerside odrzuca niepusty blok kodu z odwołaniem do źródła.';

  @override
  String get wsInherited => 'Dziedzicz z listy';

  @override
  String get wsExternalImageSize =>
      'Writerside nie ustawia niezawodnie rozmiaru obrazów zewnętrznych. Istniejące wymiary można sprawdzić i usunąć.';

  @override
  String get wsPropertiesNotSerialized =>
      'Ta zmiana nie została zapisana w źródle. Wersja robocza została zachowana.';

  @override
  String get wsListItem => 'Element listy';

  @override
  String get wsSourceFile => 'Plik źródłowy';

  @override
  String get wsLinkTarget => 'Cel linku';

  @override
  String get wsPreviewImage => 'Obraz podglądu';

  @override
  String get wsIncludedElement => 'Dołączany element';

  @override
  String get wsHelpModule => 'Moduł pomocy';

  @override
  String get wsActionId => 'ID akcji';

  @override
  String get wsKeymapHelpInstance => 'Instancja pomocy mapy klawiszy';

  @override
  String get wsShowInSource => 'Pokaż w Źródle';

  @override
  String get wsOriginElement => 'Wartość elementu';

  @override
  String get wsOriginAncestor => 'Element nadrzędny';

  @override
  String get wsOriginModule => 'Domyślna wartość modułu';

  @override
  String get wsOriginBuiltIn => 'Wbudowana wartość domyślna';

  @override
  String get wsOriginUnresolved => 'Nierozwiązane';

  @override
  String wsEffectiveProperty(String value, String origin) {
    return 'Efektywna wartość: $value — $origin';
  }

  @override
  String get wsElementSelector => 'Element';

  @override
  String wsGeneratedAnchorValue(String anchor) {
    return 'Wygenerowano: $anchor';
  }

  @override
  String wsDefaultProperty(String value) {
    return 'Domyślnie: $value';
  }

  @override
  String wsDefaultPropertyOrigin(String value, String origin) {
    return 'Domyślnie: $value · $origin';
  }

  @override
  String wsResolvedProperty(String value) {
    return 'Rozwiązano: $value';
  }

  @override
  String get wsPropertyUnresolved => 'Nierozwiązane';

  @override
  String get wsModule => 'Moduł';

  @override
  String get wsParent => 'Element nadrzędny';

  @override
  String get wsListType => 'Typ listy';

  @override
  String get wsStartingNumber => 'Numer początkowy';

  @override
  String get wsListSorting => 'Sortowanie';

  @override
  String get wsLetteredList => 'Lista literowa';

  @override
  String get wsCheckboxList => 'Lista pól wyboru';

  @override
  String get wsMarkerlessList => 'Lista bez znaczników';

  @override
  String get wsAscending => 'Rosnąco';

  @override
  String get wsDescending => 'Malejąco';

  @override
  String get wsNoSorting => 'Bez sortowania';

  @override
  String get wsAsWritten => 'Jak napisano';

  @override
  String get wsSentenceCase => 'Wielkość liter zdania';

  @override
  String get wsTitleCase => 'Wielkość liter tytułu';

  @override
  String get wsLowerCase => 'Małe litery';

  @override
  String get wsUpperCase => 'Wielkie litery';

  @override
  String get wsNativeMarkers => 'Znaczniki Markdown';

  @override
  String wsListMarkerStart(String number) {
    return 'Znacznik początkowy: $number';
  }

  @override
  String wsListLevel(String level) {
    return 'Poziom $level';
  }

  @override
  String get wsModuleCapsIgnored =>
      'Przypięty kompilator ignoruje reguły <caps> modułu. Użyj lokalnego atrybutu caps lub default-property.';

  @override
  String get wsInsertElements => 'Wstaw elementy';

  @override
  String get wsAdmonitionsAndQuotes => 'Uwagi i cytaty';

  @override
  String get wsSemanticText => 'Tekst semantyczny';

  @override
  String get wsPropertiesUnavailable =>
      'Sprawdzany element jest niedostępny. Sprawdź element, aby kontynuować.';

  @override
  String get searchDocumentsCategory => 'Dokumenty';

  @override
  String get searchTopicsCategory => 'Tematy';

  @override
  String get searchCurrentDocument => 'Bieżący dokument';

  @override
  String get searchCurrentWorkspace => 'Bieżący obszar roboczy';

  @override
  String get browseNotes => 'Przeglądaj notatki';

  @override
  String get searchActionsCommand => 'Szukaj działań';

  @override
  String get searchDocumentsCommand => 'Szukaj dokumentów';

  @override
  String get searchTopicsCommand => 'Szukaj tematów';

  @override
  String get searchRecentCommand => 'Szukaj ostatnich';

  @override
  String get searchResourceUnavailable => 'Ten zasób jest niedostępny.';

  @override
  String get notesSync => 'Synchronizuj notatki';

  @override
  String get searchInWorkspace => 'Szukaj w obszarze roboczym';

  @override
  String get searchCategory => 'Kategoria wyszukiwania';

  @override
  String get clearHistorySearchScope => 'Szukaj w historii dokumentów';

  @override
  String get searchInDocument => 'Szukaj w dokumencie';

  @override
  String get searchDocumentHint => 'Przeszukaj ten dokument…';

  @override
  String get searchWorkspaceHint => 'Przeszukaj ten obszar roboczy…';

  @override
  String get searchOutlineHint => 'Szukaj nagłówków…';

  @override
  String get searchHistoryHint => 'Przeszukaj historię lokalną…';

  @override
  String get searchEnterText => 'Wpisz tekst do wyszukania';

  @override
  String get searchAccountUnavailable => 'Konto niedostępne';

  @override
  String get searchDocumentsHint => 'Szukaj dokumentów…';

  @override
  String get searchTopicsHint => 'Szukaj tematów…';

  @override
  String get searchRecentHint => 'Szukaj ostatnich…';

  @override
  String get searchActionsHint => 'Szukaj działań…';

  @override
  String get searchRequiresNotesWorkspace => 'Wymaga obszaru roboczego Notatek';

  @override
  String get searchSidebarLabel => 'Szukaj:';

  @override
  String get searchDocumentTextCategory => 'Tekst dokumentu';

  @override
  String get searchWorkspaceTextCategory => 'Tekst obszaru roboczego';

  @override
  String get searchHeadingsCategory => 'Nagłówki';

  @override
  String get shortcutUnassigned => 'Nieprzypisany';

  @override
  String get shortcutPressKeys => 'Naciśnij kombinację klawiszy…';

  @override
  String get shortcutRecord => 'Zarejestruj skrót';

  @override
  String get shortcutRestoreAll => 'Przywróć wszystkie domyślne';

  @override
  String get shortcutRestoreAllQuestion =>
      'Przywrócić domyślne skróty wszystkich działań? Własne przypisania zostaną usunięte.';

  @override
  String get shortcutSaveFailed =>
      'Skróty są aktywne, lecz nie udało się ich zapisać. Spróbuj ponownie, aby zachować je po restarcie.';

  @override
  String get shortcutRetry => 'Ponów zapis';

  @override
  String get shortcutChanged =>
      'Przypisania uległy zmianie. Sprawdź bieżące skróty i spróbuj ponownie.';

  @override
  String get shortcutInvalid =>
      'Nie można przypisać tej kombinacji w tym kontekście.';

  @override
  String get shortcutSystemWarning =>
      'Pulpit może używać tej kombinacji. BusyMark nie może zastępować skrótów systemowych.';

  @override
  String get shortcutConflicts => 'Ten skrót koliduje z tymi działaniami:';

  @override
  String get shortcutRemove => 'Usuń przypisanie';

  @override
  String get shortcutRestoreDefault => 'Przywróć domyślny';

  @override
  String get shortcutAssign => 'Przypisz';

  @override
  String get shortcutReassign => 'Przypisz ponownie';

  @override
  String get shortcutContextApplication => 'Aplikacja';

  @override
  String get shortcutContextDocument => 'Widoki dokumentu';

  @override
  String get shortcutContextEditor => 'Edytor i źródło';

  @override
  String get shortcutContextWritersideSource => 'Źródło Writerside';

  @override
  String get shortcutContextWorkspace => 'Nawigacja obszaru roboczego';

  @override
  String get shortcutContextTree => 'Drzewa paska bocznego';

  @override
  String get searchHeadingsCommand => 'Szukaj nagłówków';

  @override
  String get shortcutFixed =>
      'Zarządzane przez edytor; nie można skonfigurować.';

  @override
  String get shortcutDefaultConflict =>
      'Domyślny skrót koliduje z niestandardowym przypisaniem.';

  @override
  String get shortcutCurrentBinding => 'Bieżący skrót';

  @override
  String get shortcutProposedBinding => 'Proponowany skrót';

  @override
  String get notesActions => 'Działania na notatkach';

  @override
  String get noteActions => 'Działania na notatce';

  @override
  String get noteProperties => 'Właściwości notatki';

  @override
  String get notesExportAll => 'Eksportuj notatki · Wszystkie notatki…';

  @override
  String get notesExportCategory => 'Eksportuj notatki · Kategoria…';

  @override
  String get notesOfflineAll => 'Udostępnij offline · Wszystkie notatki';

  @override
  String get notesOfflineCategory => 'Udostępnij offline · Kategoria';

  @override
  String get notesOfflineRemoveAll =>
      'Usuń przechowywanie offline · Wszystkie notatki';

  @override
  String get notesOfflineRemoveCategory =>
      'Usuń przechowywanie offline · Kategoria';

  @override
  String get notesOfflinePause => 'Wstrzymaj pobieranie';

  @override
  String get notesOfflineResume => 'Wznów pobieranie';

  @override
  String get notesOfflineKeep => 'Udostępnij offline';

  @override
  String get notesOfflineRetentionHelp =>
      'Usunięcie tego wymagania zachowuje zawartość pamięci podręcznej. Wymaganie kategorii lub konta może nadal zachowywać notatkę.';

  @override
  String get notesOfflineBroader =>
      'Ta notatka jest też zachowywana przez wymaganie kategorii lub konta.';

  @override
  String get notesOfflineExternal =>
      'Zewnętrzne multimedia wymagają połączenia. BusyMark zachowuje tylko tekst i zarządzane załączniki.';

  @override
  String get notesEmptyAll => 'Nie ma jeszcze notatek. Utwórz pierwszą.';

  @override
  String get notesEmptyFavorites => 'Brak ulubionych notatek.';

  @override
  String get notesEmptyCategory => 'Brak notatek w tej kategorii.';

  @override
  String get notesEmptyUncategorized => 'Brak notatek bez kategorii.';

  @override
  String get notesEmptyRecovery => 'Brak zachowanych notatek do odzyskania.';

  @override
  String get notesLoadFailed =>
      'Nextcloud Notes · Niepowodzenie. Spróbuj ponownie';

  @override
  String get notesOperationFailed =>
      'Operacja nie została ukończona. Szkic jest zachowany. Sprawdź zapisywanie i konflikty, a potem spróbuj ponownie.';

  @override
  String get notesInspectionFailed =>
      'Załączniki · Niepowodzenie. Spróbuj ponownie';

  @override
  String get notesStartingConnection => 'Rozpoczynanie połączenia z Nextcloud…';

  @override
  String get notesVerifyingConnection => 'Weryfikowanie dostępu do notatek…';

  @override
  String get notesCancellingConnection => 'Anulowanie logowania i sprzątanie…';

  @override
  String get notesRemovingConnection => 'Usuwanie konta lokalnego…';

  @override
  String get notesRemovedWarning =>
      'Lokalne konto Nextcloud usunięto. Nie potwierdzono unieważnienia hasła aplikacji. Usuń hasło BusyMark w ustawieniach bezpieczeństwa Nextcloud.';

  @override
  String get notesBuffersNotSaved =>
      'Nie wszystkie otwarte notatki zapisano lokalnie. Sprawdź zapisywanie, konflikty lub normalizację w obszarze roboczym. Lokalne zmiany mogą nadal wymagać synchronizacji z Nextcloud.';

  @override
  String get notesSettingsLeave =>
      'Zapisać zmiany ustawień Nextcloud przed wyjściem?';

  @override
  String get notesSettingsLeaveHelp =>
      'Ustawienia Notes na serwerze · Niezapisane zmiany';

  @override
  String get notesSettingsReload => 'Wczytaj ponownie ustawienia serwera…';

  @override
  String get notesSettingsReloadHelp =>
      'Ponowne wczytanie zastąpi szkic aktualnymi ustawieniami Nextcloud. Odrzucić szkic i wczytać ponownie?';

  @override
  String get notesSettingsRefreshFailed =>
      'Nextcloud zaakceptował ustawienia, lecz odświeżenie notatek nie powiodło się. Pokazano wartości potwierdzone przez serwer. Ponów odświeżenie z Notatek.';

  @override
  String get notesUnavailable =>
      'Bez połączenia · Tekst dostępny lokalnie · Zapisano lokalnie · oczekuje na synchronizację';

  @override
  String get notesStorageFull =>
      'Pamięć Nextcloud jest pełna. Zwolnij miejsce na serwerze i spróbuj ponownie.';

  @override
  String get notesRejected =>
      'Nextcloud odrzucił tę zmianę. Sprawdź notatkę i zapisz lokalną kopię przed ponowieniem.';

  @override
  String get notesThrottled =>
      'Nextcloud zażądał oczekiwania. Synchronizacja wznowi się po upływie wyznaczonego czasu.';

  @override
  String get notesRecoveryRequired => 'Konflikty · Porównaj';

  @override
  String get notesScanning => 'Skanowanie plików…';

  @override
  String get notesCancelling =>
      'Anulowanie… Oczekiwanie na zakończenie bieżącej operacji.';

  @override
  String get notesCancelled => 'Anulowano';

  @override
  String get notesPartial => 'Częściowo ukończono';

  @override
  String get notesTransferFailed => 'Niepowodzenie. Spróbuj ponownie';

  @override
  String get notesImportPartialHelp =>
      'Poprzednie elementy mogą już być zapisane lokalnie. Wznów ten import, aby kontynuować bez duplikatów.';

  @override
  String get notesNotStarted => 'Nie rozpoczęto';

  @override
  String get notesCreated => 'Utworzono';

  @override
  String get notesRemoteDeleteUnavailable =>
      'Adres serwera · Nieobsługiwane · Usuń · Załączniki';

  @override
  String get notesCurrentText => 'Aktualnie zachowany tekst';

  @override
  String get notesRecovering => 'Odzyskiwanie jako nowa notatka…';

  @override
  String get notesReadOnlyHelp =>
      'Tylko do odczytu · Ulubione · Zapisz kopię lokalną…';

  @override
  String get notesSort => 'Sortuj notatki';

  @override
  String get notesPathRelative =>
      'Ścieżka folderu notatek jest względna wobec Twojego magazynu Nextcloud.';

  @override
  String get notesSettingsStale =>
      'Ustawienia zmieniły się w Nextcloud. Wczytaj i sprawdź wartości serwera przed zastąpieniem szkicu.';

  @override
  String get notesDownloadsPaused => 'Pobieranie wstrzymane';

  @override
  String get notesExportNotPublished => 'Nie opublikowano eksportu.';

  @override
  String get notesKeyringUnavailable =>
      'Odblokuj systemowy pęk kluczy i spróbuj ponownie.';

  @override
  String get notesConnectFailed =>
      'Nie można połączyć się z Nextcloud Notes. Sprawdź adres serwera i spróbuj ponownie.';

  @override
  String get notesAccountMismatch =>
      'Zaloguj się na to samo konto Nextcloud. Najpierw usuń to konto, aby połączyć inne.';

  @override
  String get notesLocalRemovalFailed =>
      'Lokalne czyszczenie konta nie powiodło się. Konto zachowano, aby ponowić usuwanie.';

  @override
  String get notesTransferring => 'Przenoszenie notatek…';

  @override
  String get notesTechnicalDetails => 'Szczegóły techniczne';

  @override
  String get notesPauseRequirement => 'Wstrzymaj wymaganie offline';

  @override
  String get notesResumeRequirement => 'Wznów wymaganie offline';

  @override
  String get gitReturnToDocument => 'Wróć do dokumentu';

  @override
  String gitSnapshotLabel(String revision, String path) {
    return 'Migawka tylko do odczytu · $revision · $path';
  }

  @override
  String get gitNonUtf8FilenameMessage =>
      'Nazwa pliku zawiera bajty spoza UTF-8. Przegląd i przygotowanie zmian Git są nadal dostępne; edytor dokumentów wymaga nazwy pliku UTF-8.';

  @override
  String get gitUiMergeInProgress => 'Łączenie się w toku';

  @override
  String get gitUiRebaseInProgress => 'Ponowna baza danych w toku';

  @override
  String get gitUiCherryPickInProgress => 'Trwa wiśniowy wybór';

  @override
  String get gitUiRevertInProgress => 'Powrót w toku';

  @override
  String get gitUiPatchApplicationInProgress =>
      'Rozpoczęto stosowanie systemu Patch';

  @override
  String get gitUiSquashMergeResultAwaitingCommit =>
      'Wynik połączenia Squash, czekając na zobowiązanie';

  @override
  String get gitUiUnresolvedIndexConflicts =>
      'Nierozwiązane konflikty indeksowe';

  @override
  String get gitUiUnresolvedConflicts => ' · nierozwiązane konflikty';

  @override
  String get gitUiReviewOperation => 'Przegląd operacji';

  @override
  String get gitUiRefresh => 'Odśwież';

  @override
  String get gitUiCreateNamedStash => 'Utwórz nazwane schowek';

  @override
  String get gitUiCreateStash => 'Utwórz schowek…';

  @override
  String get gitUiNoStashes => 'Bez schowków';

  @override
  String get gitUiSelectAStashToInspectItsChanges =>
      'Wybierz schowek, aby sprawdzić jego zmiany';

  @override
  String get gitUiStashedUntrackedFiles => 'Utworzono nieokreślone pliki';

  @override
  String get gitUiInspectStashedUntrackedFiles =>
      'Powtórzono ukryte niezamierzone pliki...';

  @override
  String get gitUiReinstateTheStashSStagedIndexStateWhenApplying =>
      'Przywrócić stan schowka w momencie jego złożenia/indeksu';

  @override
  String get gitUiApplyAndRetain => 'Zastosuj i zachowaj';

  @override
  String get gitUiPop => 'Tatku...';

  @override
  String get gitUiCreateBranch => 'Utwórz gałąź…';

  @override
  String get gitUiDropStash => 'Usuń schowek…';

  @override
  String get gitUiBranchFromStash => 'Utwórz gałąź ze schowka';

  @override
  String get gitUiCreateSwitchToABranchAtTheStashSOriginal =>
      'Tworzenie/przeniesienie na gałąź w oryginalnej bazie schowka, a następnie zastosowanie. Oryginalny schowek jest przechowywany do wyraźnego późniejszego usunięcia.';

  @override
  String gitUiArg0ThisStash(String arg0) {
    return '$arg0 to schowek?';
  }

  @override
  String get gitUiTheOriginalStashIsRetainedIfApplyingConflicts =>
      'Oryginalny schowek jest przechowywany w przypadku stosowania konfliktów.';

  @override
  String get gitUiDeletesThisStashEntryItsChangesAreNotApplied =>
      'Usuwa tę pozycję w schowku. Nie stosuje się jej zmian.';

  @override
  String get gitUiResolveTheUnmergedFilesGitHasNoStashContinueOr =>
      'Rozwiąż niescalone pliki. Git nie ma poleceń kontynuacji ani przerwania schowka; oryginalny schowek pozostaje.';

  @override
  String get gitUiStashNameMessage => 'Nazwa/powiadamianie o stanie stash';

  @override
  String get gitUiStashContentAndResultingIndex =>
      'Zawartość i wskaźnik wynikowy';

  @override
  String get gitUiStashTrackedWorkingAndStagedChanges =>
      'Stash śledzono zmiany robocze i wyreżyserowane';

  @override
  String get gitUiStashChangesLeaveStagedChangesInPlaceKeepIndex =>
      'Schowaj zmiany, pozostaw zawartość indeksu (--keep-index)';

  @override
  String get gitUiStashOnlyStagedChangesStaged =>
      'Schowaj tylko zmiany z indeksu (--staged)';

  @override
  String get gitUiIncludeUntrackedFiles => 'Włączenie nieprześledzonych plików';

  @override
  String get gitUiAllEligiblePathsInThisRepository =>
      'Wszystkie kwalifikujące się ścieżki w tym repozytorium';

  @override
  String get gitUiNoEligibleChangesForTheseStashOptions =>
      'Brak zmian kwalifikujących się do tych opcji składowania.';

  @override
  String get gitUiSelectAtLeastOneEligiblePath =>
      'Wybierz co najmniej jedną ścieżkę kwalifikowaną.';

  @override
  String get gitUiCreateStash2 => 'Utwórz schowek';

  @override
  String get gitUiCreateWorktree => 'Twórz pracę...';

  @override
  String get gitUiCreateACommitBeforeCreatingAWorktreeAtHEAD =>
      'Utwórz commit przed utworzeniem drzewa roboczego w HEAD.';

  @override
  String get gitUiDetachedHEAD => 'Odłączony HEAD';

  @override
  String get gitUiCurrent => 'Bieżący ·';

  @override
  String get gitUiLocked => 'Zamknięte ·';

  @override
  String get gitUiOpenInBusyStack => 'Otwarte w zapasie SPAMfighter ·';

  @override
  String get gitUiStatusNotInspected => 'Status niesprawdzony';

  @override
  String get gitUiDirty => 'Brudna';

  @override
  String get gitUiClean => 'Bez zmian';

  @override
  String get gitUiOpenWorkingFolder => 'Otwórz folder roboczy';

  @override
  String get gitUiMoveWorktree => 'Przesuń się...';

  @override
  String get gitUiUnlock => 'Odblokuj';

  @override
  String get gitUiLock => 'Zablokuj';

  @override
  String get gitUiRemoveCleanWorktree => 'Usuń czyste przekładnie...';

  @override
  String get gitUiReviewRemovalIncludingLocalChanges =>
      'Usunięcie przeglądu, w tym zmiany lokalne...';

  @override
  String get gitUiNewWorktreeFolderName => 'Nowa nazwa folderu roboczego';

  @override
  String get gitUiNewWorktreeBranch => 'Nowa gałąź robocza';

  @override
  String gitUiCreateArg0Arg1WithANewLocalBranchAtArg2(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Tworzenie $arg0/$arg1 z nowym lokalnym oddziałem w firmie $arg2 ($arg3).';
  }

  @override
  String get gitUiDestinationFolderName => 'Nazwa folderu docelowego';

  @override
  String get gitUiRemoveWorktree => 'Zdjąć hamulce?';

  @override
  String
  get gitUiExplicitlyDiscardAllLocalTrackedUntrackedChangesInThisWorktree =>
      'Wyraźnie odrzuć wszystkie lokalne zmiany w tym robocie. Zablokowane/wykorzystane prace pozostają chronione.';

  @override
  String get gitUiGitRefusesRemovalIfThereAreLocalChangesUntrackedFiles =>
      'Git odmawia usunięcia, jeśli nastąpią lokalne zmiany, nieokreślone pliki, lub blokada.';

  @override
  String get gitUiDiscardLocalWorktreeContentsAndRemove =>
      'Wyrzuć lokalną zawartość robótki i usuń';

  @override
  String get gitUiRemoveCleanWorktree2 => 'Usuń czyste przekładnie';

  @override
  String
  get gitUiExplicitlyRecurseIntoNestedSubmodulesForUpdatesSynchronization =>
      'Wyraźnie przywrócić do zagnieżdżonych podmodułów w celu aktualizacji/synchronizacji';

  @override
  String get gitUiNoRecordedSubmodules => 'Brak zapisu podmodułów';

  @override
  String get gitUiNotInitialized => 'nie inicjalizowano';

  @override
  String gitUiParentGitlinkArg0CheckedOutArg1(String arg0, String arg1) {
    return 'Gitlink rodzicielski: $arg0 Wymeldowano: $arg1\n';
  }

  @override
  String get gitUiDirtyNestedRepository => 'Repozytorium zagnieżdżone';

  @override
  String get gitUiCleanNestedRepository => 'Czyste zagnieżdżone repozytorium';

  @override
  String get gitUiNestedStatusUnavailable => 'Stan zamrożony niedostępny';

  @override
  String get gitUiEnterNestedRepository => 'Wprowadź repozytorium';

  @override
  String get gitUiInitializeConfiguration => 'Rozpocznij konfigurację';

  @override
  String get gitUiUpdateToParentSRecordedCommit =>
      'Uaktualnij wpisywanie do zarejestrowanego zobowiązania rodzica...';

  @override
  String get gitUiFollowConfiguredRemoteBranch =>
      'Podążaj za skonfigurowaną zdalną gałęzią...';

  @override
  String get gitUiSynchronizeConfiguredURLs =>
      'Synchronizuj skonfigurowane URL...';

  @override
  String get gitUiStageCurrentSubmodulePointerInParent =>
      'Wskaźnik podmodułowy prądu etapowego u rodzica';

  @override
  String get gitUiParentAndSubmoduleCommitsPushesAndDirtyStateRemainSeparate =>
      'Rodzice i podmodułki angażują się, pchają i zabrudzają stan pozostają odrębne. Przeglądanie ich nie uruchamia ani nie aktualizuje.';

  @override
  String gitUiFetchAndCheckOutTheConfiguredRemoteBranchSCommit(String arg0) {
    return 'Pobierz i sprawdź skonfigurowany zdalny odgałęzień. To różni się od nagranego gitlinka rodzica. Reakcyjne: $arg0.';
  }

  @override
  String gitUiInitializeAsNeededAndCheckOutExactlyArg0RecursiveArg1(
    String arg0,
    String arg1,
  ) {
    return 'W razie potrzeby rozpocząć i sprawdzić dokładnie $arg0. Rekursywne: $arg1.';
  }

  @override
  String gitUiApplyTheReviewedSubmoduleConfigurationOperationRecursiveArg0(
    String arg0,
  ) {
    return 'Zastosuj sprawdzoną konfigurację podmodułową. Rekursywne: $arg0.';
  }

  @override
  String get gitUiApplySubmoduleOperation => 'Zastosuj operację podmodułową';

  @override
  String get gitUiInspectARecordedRevisionOrCreateARecoveryBranchReflog =>
      'Ponownie przegląd lub utworzyć oddział odzyskiwania. Reflog nie odzyska arbitralnie zaniechanych lub nieprześledzonych treści.';

  @override
  String get gitUiSelectAReflogEntry => 'Wybierz wpis reflogu';

  @override
  String get gitUiPreviousPage => 'Poprzednia strona';

  @override
  String get gitUiNextPage => 'Następna strona';

  @override
  String get gitUiRecoveryBranchName => 'Nazwa oddziału odzysku';

  @override
  String gitUiCreatesABranchAtArg0WorkingFilesAndTheCurrent(String arg0) {
    return 'Tworzy gałąź w $arg0; pliki robocze i bieżące oddziały są niezmienione.';
  }

  @override
  String get gitUiCreateRecoveryBranch => 'Utwórz gałąź odzyskiwania...';

  @override
  String get gitUiReadOnlyRecoverySnapshot => 'Odzyskanie tylko od odczytu';

  @override
  String get gitUiInspectSnapshot => 'Powtórz migawki...';

  @override
  String get gitUiReviewReset => 'Sprawdź resetowanie…';

  @override
  String gitUiPageArg0(String arg0) {
    return 'Strona $arg0';
  }

  @override
  String get gitUiAGitTextHistoryMustOwnItsEditableField =>
      'Historia tekstu Git musi posiadać swoje pole estry.';

  @override
  String get gitUiEditHEADIndexWorkingTree =>
      'Edytuj HEAD | Indeks | Drzewo robocze…';

  @override
  String
  get gitUiTheReviewedIndexOrWorkingContentChangedRefreshThisComparison =>
      'Zmienił się indeks lub zawartość pracy. Odśwież to porównanie przed rozpoczęciem stagnacji.';

  @override
  String get gitUiRefreshComparison => 'Porównanie odśwież';

  @override
  String get gitUiPreviousChangedFile => 'Poprzedni zmieniony plik';

  @override
  String get gitUiNextChangedFile => 'Następny zmieniony plik';

  @override
  String get gitUiPreviousDifference => 'Poprzednia różnica';

  @override
  String get gitUiNextDifference => 'Następna różnica';

  @override
  String get gitUiComparisonMode => 'Tryb porównania';

  @override
  String get gitUiSideBySide => 'Bok obok siebie';

  @override
  String get gitUiUnified => 'Zjednoczone';

  @override
  String get gitUiDiffDisplayOptions => 'Zróżnicuj opcje wyświetlania';

  @override
  String get gitUiWrap => 'Zawijanie wierszy';

  @override
  String get gitUiWords => 'Słowa';

  @override
  String get gitUiCollapseContext => 'Zwiń kontekst';

  @override
  String get gitUiIgnoreWhitespace => 'Ignoruj odwzorowanie';

  @override
  String get gitUiSearchComparison => 'Porównanie wyszukiwania';

  @override
  String get gitUiSearch => 'Szukaj';

  @override
  String get gitUiCloseSearch => 'Zamknij wyszukiwanie';

  @override
  String get gitUiStagingActions => 'Operacje na indeksie';

  @override
  String get gitUiStagingActions2 => 'Operacje na indeksie…';

  @override
  String get gitUiUnstageSelectedChangedLines =>
      'Usuń wybrane zmienione wiersze z indeksu';

  @override
  String get gitUiStageSelectedChangedLines =>
      'Dodaj wybrane zmienione wiersze do indeksu';

  @override
  String get gitUiUnstageWholeFile => 'Usuń cały plik z indeksu';

  @override
  String get gitUiStageWholeFile => 'Dodaj cały plik do indeksu';

  @override
  String gitUiArg0WhitespaceOnlyChangedLinesHiddenShowExactChanges(
    String arg0,
  ) {
    return '${arg0}Space-tylko zmienione linie ukryte · Pokaż dokładne zmiany';
  }

  @override
  String gitUiArg0ChangedLinesSelectedDisplaySettingsNeverAlterTheStaged(
    String arg0,
  ) {
    return '$arg0 zmieniła wybrane wiersze · Ustawienia wyświetlania nigdy nie zmieniały scedowanych bajtów.';
  }

  @override
  String get gitUiReadOnlyComparisonCopyTextOrAdjustDisplaySettings =>
      'Porównanie tylko do odczytu · Skopiuj tekst lub dostosuj widok.';

  @override
  String get gitUiNoFinalNewline => ' · brak ostatecznej nowej linii';

  @override
  String gitUiArg0Arg1Arg2BytesArg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0 · $arg1 · $arg2 bajty$arg3';
  }

  @override
  String get gitUiTextComparisonIsUnavailableForTheseContents =>
      'Porównanie tekstu jest niedostępne dla tej zawartości.';

  @override
  String get gitUiThisComparisonExceedsTheBoundedTextReviewLimitTheContents =>
      'Porównanie to przekracza limit ograniczonego tekstu przeglądu. Treść nie została uznana za identyczną.';

  @override
  String get gitUiTheComparedContentsAreIdentical =>
      'Porównana zawartość jest identyczna.';

  @override
  String get gitUiUnstage => 'Niestabilny';

  @override
  String get gitUiStage => 'Etap';

  @override
  String gitUiArg0ChangedLine(String arg0) {
    return '$arg0 zmieniono linię';
  }

  @override
  String get gitUiContext => 'Kontekst';

  @override
  String get gitUiExpandUnchangedContext => 'Rozwiń niezmieniony kontekst';

  @override
  String get gitUiUnstageThisHunk => 'Usuń ten fragment z indeksu';

  @override
  String get gitUiStageThisHunk => 'Dodaj ten fragment do indeksu';

  @override
  String gitUiEditStagedContentArg0(String arg0) {
    return 'Edycja treści scedowanych · $arg0';
  }

  @override
  String get gitUiWritingReviewedIndexResult =>
      'Zapisywanie wyników przeglądu indeksu';

  @override
  String get gitUiHead => 'HEAD';

  @override
  String get gitUiIndex => 'Indeks';

  @override
  String get gitUiWorkingTree => 'Drzewo robocze';

  @override
  String gitUiHeadArg0(String arg0) {
    return 'HEAD · $arg0';
  }

  @override
  String get gitUiIndexEditableUTF8Blob => 'Indeks · edycja UTF-8 ?';

  @override
  String get gitUiUndo => 'Cofnij';

  @override
  String get gitUiRedo => 'Ponów';

  @override
  String get gitUiReloadIndexReview => 'Przegląd indeksu ponownie?';

  @override
  String get gitUiReloadTheCurrentHEADIndexAndWorkingVersionsThisReplaces =>
      'Wczytaj ponownie bieżące wersje HEAD, indeksu i plików roboczych. Zastąpi to niezapisany szkic edytora indeksu.';

  @override
  String get gitUiReplaceDraftAndReload => 'Zamień projekt i przeładowuj';

  @override
  String get gitUiReloadVersions => 'Odśwież wersje...';

  @override
  String get gitUiWriteEditedResultToThisIndexEntry =>
      'Zapisz edytowany wynik do tej pozycji indeksowej';

  @override
  String get gitUiWorkingFilesRemainOnDiskReviewTheEditedIndexBefore =>
      'Pliki robocze pozostają na dysku. Przed zastosowaniem przejrzyj edytowany indeks.';

  @override
  String get gitUiReviewIndexTextFormatChanges =>
      'Zmiany w formacie indeksu przeglądu';

  @override
  String gitUiUpdateOnlyTheReviewedIndexEntryForArg0Arg1(
    String arg0,
    String arg1,
  ) {
    return 'Aktualizuj tylko wpis w indeksie przeglądowym dla $arg0. $arg1';
  }

  @override
  String get gitUiWriteReviewedIndexResult =>
      'Zapisz wynik przetestowanego indeksu';

  @override
  String get gitUiTheEditedResultChangedDuringFormatReviewReviewItAgain =>
      'Rezultat edytowany zmienił się podczas przeglądu formatu.';

  @override
  String get gitUiSynchronizeScrolling => 'Przewijanie synchronizacji';

  @override
  String get gitUiReadOnlyRevisionContent =>
      'Treść zmiany wyłącznie do odczytu';

  @override
  String get gitUiEditableIndexContent => 'Zmodyfikowana zawartość indeksu';

  @override
  String get gitUiTheRequestedRevisionIsOutsideTheCurrentFiltersResetFilters =>
      'Wymagana zmiana jest poza bieżącymi filtry. Przewiń filtry, aby ją ujawnić.';

  @override
  String get gitUiFilterLog => 'Dziennik filtru';

  @override
  String get gitUiFilters => 'Filtry...';

  @override
  String gitUiFiltersCount(String count) {
    return 'Filtry ($count)...';
  }

  @override
  String get gitUiMessage => 'Opis…';

  @override
  String get gitUiAuthor => 'Autor…';

  @override
  String get gitUiPath => 'Ścieżka...';

  @override
  String get gitUiDate => 'Randka...';

  @override
  String get gitUiMessageFilter => 'Filtr wiadomości';

  @override
  String get gitUiAuthorFilter => 'Filtr autorski';

  @override
  String get gitUiPathFilter => 'Filtr ścieżki';

  @override
  String get gitUiMessage2 => 'Opis';

  @override
  String get gitUiAuthor2 => 'Autor';

  @override
  String get gitUiPath2 => 'Ścieżka';

  @override
  String get gitUiDateFilter => 'Filtr daty...';

  @override
  String get gitUiResetFilters => 'Przywróć filtry';

  @override
  String get gitUiRefreshLog => 'Odśwież dziennik';

  @override
  String get gitUiGoToCommitReference => 'Przejdź do popełnienia/odsyłania...';

  @override
  String get gitUiBackToHEAD => 'Wróć do HEAD';

  @override
  String get gitUiOrderedCherryPick => 'Cherry-pick w wybranej kolejności';

  @override
  String gitUiReviewCherryPickArg0(String arg0) {
    return 'Przegląd wiśniowy ($arg0)...';
  }

  @override
  String get gitUiCompareTwoSelectedRevisions =>
      'Porównaj dwie wybrane zmiany...';

  @override
  String get gitUiToggleBranchesPane => 'Włącz okienko gałęzi';

  @override
  String get gitUiFilterBranchesAndTags => 'Oddziały i znaczniki filtracyjne';

  @override
  String gitUiCommitArg0(String arg0) {
    return 'Zobowiązanie $arg0';
  }

  @override
  String get gitUiCommitDetails => 'Szczegóły zobowiązań...';

  @override
  String gitUiReferenceArg0(String arg0) {
    return 'Numer referencyjny: $arg0';
  }

  @override
  String get gitUiSelectThisCommit => 'Wybierz ten commit';

  @override
  String get gitUiBranchOrTag => 'Oddział lub znacznik';

  @override
  String get gitUiAllReferences => 'Wszystkie odniesienia';

  @override
  String get gitUiLocal => 'Lokalny';

  @override
  String get gitUiRemote => 'Zdalne';

  @override
  String get gitUiTags => 'Tagi';

  @override
  String get gitUiNoCommitsMatchTheCurrentFilters =>
      'Brak zobowiązań pasuje do bieżących filtrów.';

  @override
  String get gitUiObjectID => 'Identyfikator obiektu';

  @override
  String get gitUiSubjectReferences => 'Przedmiot / odniesienia';

  @override
  String get gitUiDate2 => 'Data';

  @override
  String get gitUiGitCommits => 'Commity Git';

  @override
  String get gitUiParents => 'Commity nadrzędne';

  @override
  String gitUiArg0Parents(String arg0) {
    return '$arg0 rodzic';
  }

  @override
  String get gitUiLoadMoreCommits => 'Wczytaj więcej zobowiązań';

  @override
  String get gitUiLoadingChangedFiles => 'Wczytywanie zmienionych plików';

  @override
  String get gitUiNoChangedFiles => 'Nie zmieniono plików';

  @override
  String get gitUiSelectACommit => 'Wybierz zobowiązanie';

  @override
  String gitUiCompareParentArg0Arg1(String arg0, String arg1) {
    return 'Porównaj rodzica $arg0: $arg1';
  }

  @override
  String get gitUiChangedFiles => 'Zmienione pliki';

  @override
  String gitUiAuthorArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Autor: $arg0 $arg1> $arg2';
  }

  @override
  String gitUiCommitterArg0Arg1Arg2(String arg0, String arg1, String arg2) {
    return 'Zobowiązanie: $arg0 <$arg1> $arg2';
  }

  @override
  String get gitUiShallowPartialBoundaryAParentObjectIsUnavailable =>
      'Granica wierzchołka/częściowa: obiekt rodzicielski jest niedostępny.';

  @override
  String get gitUiParentIsOutsideThisPageOrAShallowBoundary =>
      'Rodzic jest poza tą stroną lub płytką granicą.';

  @override
  String gitUiParentArg0(String arg0) {
    return 'Commit nadrzędny $arg0';
  }

  @override
  String get gitUiCommitActions => 'Zaangażuj działania...';

  @override
  String get gitUiEmptyTree => 'puste drzewo';

  @override
  String get gitUiCreateBranch2 => 'Utwórz gałąź';

  @override
  String get gitUiCreateTag => 'Utwórz tag';

  @override
  String get gitUiCompareRevisions => 'Porównaj korekty';

  @override
  String get gitUiOpenSnapshot => 'Otwarte migawki';

  @override
  String get gitUiRevertCommit => 'Cofnij zobowiązanie';

  @override
  String get gitUiInteractiveRebaseAfterThisBoundary =>
      'Interaktywna rebase po tej granicy';

  @override
  String get gitUiResetCurrentBranch => 'Zresetuj bieżącą gałąź';

  @override
  String get gitUiCopyFullObjectID => 'Kopiuj ID obiektu';

  @override
  String get gitUiGoToCommitReference2 => 'Przejdź do popełnienia/odsyłania';

  @override
  String get gitUiEnterACommitIDOrReferenceToRevealInLog =>
      'Wpisz identyfikator lub odniesienie do ujawnienia w Log.';

  @override
  String get gitUiTheRequestedRevisionIsUnavailable =>
      'Wymagana zmiana jest niedostępna.';

  @override
  String
  get gitUiRepositoryMetadataIsReadOnlyBranchInspectionAndComparisonRemain =>
      'Metadane repozytorium jest tylko odczytywane. Kontrola oddziału i porównanie pozostaje dostępne.';

  @override
  String get gitUiWorkingFilesAreUnavailableOrReadOnlyBranchSwitchingAnd =>
      'Pliki robocze są niedostępne lub tylko do odczytu. Niedostępne są przełączanie i łączenie odgałęzień.';

  @override
  String get gitUiSearchBranchesAndTags => 'Szukaj gałęzi i tagów';

  @override
  String get gitUiNewBranch => 'Nowa gałąź…';

  @override
  String get gitUiLocalBranches => 'Gałęzie lokalne';

  @override
  String get gitUiRemoteBranches => 'Gałęzie zdalne';

  @override
  String gitUiTracksArg0(String arg0) {
    return 'Utwory $arg0';
  }

  @override
  String gitUiCheckedOutAtArg0(String arg0) {
    return 'Wyświetlona w $arg0';
  }

  @override
  String get gitUiRefreshingBranchMetadata =>
      'Odświeżanie metadanych odgałęzień';

  @override
  String gitUiSwitchToArg0(String arg0) {
    return 'Przełącz na $arg0';
  }

  @override
  String get gitUiOpenOccupiedWorktree => 'Otwarte okupowane miejsce pracy';

  @override
  String get gitUiCreateLocalTrackingBranch =>
      'Tworzenie lokalnego oddziału śledzenia...';

  @override
  String get gitUiCompareToCurrentHEAD => 'Porównaj z bieżącym HEAD';

  @override
  String get gitUiMergeIntoCurrentBranch =>
      'Połącz się z bieżącym oddziałem...';

  @override
  String get gitUiRename => 'Zmień nazwę...';

  @override
  String get gitUiChangeUpstream => 'Zmień naprzód...';

  @override
  String get gitUiDelete => 'Usuń...';

  @override
  String get gitUiDeleteFromRemote => 'Usuń z zdalnego...';

  @override
  String gitUiActionsForArg0(String arg0) {
    return 'Akcje dla $arg0';
  }

  @override
  String get gitUiLocalBranchName => 'Lokalnye imię oddziału';

  @override
  String gitUiCreateAtArg0TheNewBranchWillBeCheckedOut(String arg0) {
    return 'Tworzenie na $arg0. Nowa gałąź zostanie sprawdzona.';
  }

  @override
  String gitUiTheLocalBranchWillTrackArg0AndBeCheckedOut(String arg0) {
    return 'Lokalny oddział będzie śledził $arg0 i będzie sprawdzony.';
  }

  @override
  String get gitUiChooseRemoteForDeletion => 'Wybierz pilota do usunięcia';

  @override
  String get gitUiDeleteRemoteReference => 'Usuń zdalne odniesienie';

  @override
  String gitUiMergeArg0IntoArg1(String arg0, String arg1) {
    return 'Połącz $arg0 z $arg1';
  }

  @override
  String gitUiRenameArg0(String arg0) {
    return 'Zmień nazwę $arg0';
  }

  @override
  String gitUiUpstreamForArg0(String arg0) {
    return 'Upstream dla $arg0';
  }

  @override
  String get gitUiNoUpstream => 'Brak upstream';

  @override
  String gitUiDeleteArg0(String arg0) {
    return 'Usuń $arg0?';
  }

  @override
  String gitUiArg0TargetArg1LocalDeletionOnlyAnUnmergedBranchIs(
    String arg0,
    String arg1,
  ) {
    return '$arg0 Target $arg1 Local deletion only. Odmawia się nieśmiertelnego oddziału.';
  }

  @override
  String get gitUiDelete2 => 'Usuń';

  @override
  String gitUiDeleteUnmergedBranchArg0(String arg0) {
    return 'Usuń niezanurzony oddział $arg0?';
  }

  @override
  String gitUiArg0GitReportsThisBranchIsNotFullyMergedExplicitly(String arg0) {
    return '$arg0 Git donosi, że ta gałąź nie jest w pełni połączona. Wyraźnie usunąć lokalny referencje po dokonaniu przeglądu swoich zobowiązań; zdalne kopie są niezmienione.';
  }

  @override
  String get gitUiDeleteUnmergedLocalBranch => 'Usuń lokalną gałąź';

  @override
  String gitUiDestinationArg0Arg1(String arg0, String arg1) {
    return 'Miejsce przeznaczenia: $arg0 · $arg1';
  }

  @override
  String get gitUiSourceBranchOrTag => 'Gałąź lub znacznik źródłowy';

  @override
  String get gitUiMergePolicy => 'Polityka łączenia się';

  @override
  String get gitUiFastForwardWhenPossible =>
      'Jeśli to możliwe, szybko przewiń do przodu';

  @override
  String get gitUiAlwaysCreateAMergeCommit => 'Zawsze tworzyj commit';

  @override
  String get gitUiFastForwardOnly => 'Tylko do tyłu';

  @override
  String get gitUiSquashIntoStagedChanges =>
      'Przekształcić się w zmiany zakończone';

  @override
  String get gitUiStopBeforeCreatingTheMergeCommit =>
      'Zakończ przed utworzeniem commit';

  @override
  String get gitUiFastForwardIsDisabledSoHEADCannotMoveBeforeReview =>
      'Szybkie przewijanie jest wyłączone, aby HEAD nie przesunął się przed przeglądem.';

  @override
  String get gitUiLeavesStagedChangesForASeparateCommitThisIsNot =>
      'Liście wprowadzane zmiany dla oddzielnego zobowiązania; nie jest to ciągłe połączenie.';

  @override
  String get gitUiConflictsRemainAvailableInTheSharedResolutionWorkspace =>
      'W obszarze wspólnej restrukturyzacji i uporządkowanej likwidacji nadal istnieją konflikty.';

  @override
  String get gitUiAddRemote => 'Dodaj zdalne...';

  @override
  String gitUiFetchArg0PushArg1(String arg0, String arg1) {
    return 'Fetch: $arg0 Push: $arg1';
  }

  @override
  String get gitUiRemoveRemote => 'Usuń pilota...';

  @override
  String get gitUiChangeFetchURL => 'Zmień adres URL pobrań...';

  @override
  String get gitUiAddPushDestination => 'Dodaj cel...';

  @override
  String get gitUiRemovePushDestination => 'Usuń cel...';

  @override
  String gitUiManageArg0(String arg0) {
    return 'Zarządzaj $arg0';
  }

  @override
  String get gitUiRemoteName => 'Zdalna nazwa';

  @override
  String get gitUiNewRemoteName => 'Nowa zdalna nazwa';

  @override
  String get gitUiRepositoryURLOrLocalSource =>
      'Repozytorium URL lub lokalne źródło';

  @override
  String get gitUiEnterTheExactReviewedDestinationToRemove =>
      'Podaj dokładny cel, który należy usunąć.';

  @override
  String get gitUiCredentialsAreSuppliedByConfiguredHelpersOrAPrivatePrompt =>
      'Powierzchnie dostarczane są przez skonfigurowanych pomocników lub prywatny pośpiech.';

  @override
  String gitUiRemoveRemoteArg0(String arg0) {
    return 'Usuń pilota $arg0?';
  }

  @override
  String
  get gitUiRemovesLocalRemoteConfigurationAndTrackingReferencesItDoesNot =>
      'Usuwa lokalną zdalną konfigurację i referencje do śledzenia. Nie usuwa repozytorium serwera.';

  @override
  String get gitUiRemoveRemote2 => 'Usuń pilota';

  @override
  String get gitUiCommitScopeEntireRepository =>
      'Zakres zobowiązań: cały repozytorium';

  @override
  String get gitUiCachedTracking => 'Sklepowane śledzenie';

  @override
  String get gitUiAmendLastCommit => 'Popraw ostatni commit';

  @override
  String get gitUiConfiguredHooksAndSigningAreRespected =>
      'Skonfigurowane haki i podpisywanie są respektowane.';

  @override
  String get gitUiRewritesTheSelectedHEADCommitRemoteTrackingCannotProveIt =>
      'Przepisuje wybrany commit HEAD. Śledzenie zdalne nie dowodzi, że nie został opublikowany.';

  @override
  String get gitUiRepository => 'Repozytorium';

  @override
  String gitUiDetachedArg0(String arg0) {
    return 'Oddzielone $arg0';
  }

  @override
  String get gitUiLog => 'Historia';

  @override
  String get gitUiRepositoryActions => 'Działania repozytorium';

  @override
  String gitUiCachedTrackingUpstreamAheadAheadBehindBehind(
    String upstream,
    String ahead,
    String behind,
  ) {
    return 'Śledzenie w pamięci podręcznej · $upstream · $ahead do przodu · $behind do tyłu';
  }

  @override
  String get gitUiBareRepositoryNoWorkingTreeOpenLogToInspectIts =>
      'Repozytorium Bare · brak drzewa roboczego. Otwórz log aby sprawdzić jego historię.';

  @override
  String get gitUiReadOnlyRepositoryStagingAndCommitsAreUnavailable =>
      'Repozytorium tylko do odczytu · staging i commits są niedostępne.';

  @override
  String get gitUiRepositoryStatusUnavailable =>
      'Status repozytorium niedostępny';

  @override
  String gitUiAmendRevision(String revision) {
    return 'Zmiana $revision';
  }

  @override
  String get gitUiAddSignOffTrailer => 'Dodaj stopkę poświadczenia';

  @override
  String get gitUiUseConfiguredSigningPolicy =>
      'Użyj skonfigurowanej polityki podpisania';

  @override
  String get gitUiCryptographicallySignThisCommit =>
      'Kryptograficznie podpisz to zobowiązanie';

  @override
  String get gitUiDoNotSignThisCommit => 'Nie podpisuj tego zobowiązania';

  @override
  String get gitUiRecentCommitMessages => 'Niedawne komunikaty wyemitowane...';

  @override
  String get gitUiUseConfiguredCommitTemplate =>
      'Użyj skonfigurowanego szablonu...';

  @override
  String get gitUiAuthorIdentityAndConfiguredHooks =>
      'Tożsamość autora i skonfigurowane haki...';

  @override
  String get gitUiDraftMessage => 'Projekt wiadomości...';

  @override
  String get gitUiCommitOptions => 'Opcje commitu';

  @override
  String gitUiDraftRetainedInMemorySavingItFailedArg0(String arg0) {
    return 'Projekt zatrzymany w pamięci; zapis nie powiodł się. $arg0';
  }

  @override
  String get gitUiCommitMessage => 'Opis commitu';

  @override
  String get gitUiGitOperationInProgress => 'Operacja Git w toku';

  @override
  String get gitUiCancel => 'Anuluj';

  @override
  String get gitUiAmendStaged => 'Zmiana wprowadzona';

  @override
  String gitUiCommitStagedCount(String count) {
    return 'Zatwierdź zmiany z indeksu ($count)';
  }

  @override
  String get gitUiCommitAndPush => 'Zatwierdź i wyślij…';

  @override
  String get gitUiNoReadableCommitTemplateIsConfigured =>
      'Nie skonfigurowano żadnego czytelnego szablonu popełnienia zobowiązania.';

  @override
  String get gitUiCommitIdentityAndHooks => 'Tożsamość i haki';

  @override
  String get gitUiRecentMessages => 'Ostatnie wiadomości';

  @override
  String get gitUiReplaceMessageDraft => 'Zastąpić projekt wiadomości?';

  @override
  String get gitUiReplaceTheExistingCommitMessageWithTheSelectedMessage =>
      'Zastąpić istniejącą wiadomość powierzając zaznaczeniem wybranej wiadomości?';

  @override
  String get gitUiReplaceDraft => 'Zastąp projekt';

  @override
  String gitUiLocalCommitArg0Exists(String arg0) {
    return 'Rezygnacja lokalna $arg0 istnieje.';
  }

  @override
  String gitUiLocalCommitArg0ExistsReviewLogBeforeAttemptingAnotherCommit(
    String arg0,
  ) {
    return 'Local commit $arg0 istnieje. Review Log przed próbą kolejnego zobowiązania. Projekt wiadomości został zatrzymany.';
  }

  @override
  String get gitUiCommitAuthorName => 'Nazwa autora zobowiązania';

  @override
  String get gitUiCommitAuthorEmail => 'Zaangażuj autora e- maila';

  @override
  String get gitUiConfiguredDefault => 'Skonfigurowany domyślny';

  @override
  String get gitUiOpenpgp => 'OpenPGP';

  @override
  String gitUiSigningArg0Arg1(String arg0, String arg1) {
    return 'Podpisanie: $arg0 · $arg1';
  }

  @override
  String gitUiConfiguredHooksArg0(String arg0) {
    return 'Skonfigurowane haki: $arg0';
  }

  @override
  String get gitUiASignOffTrailerIsAStatementInTheMessage =>
      'Stopka poświadczenia jest deklaracją w opisie, odrębną od podpisu kryptograficznego. Tożsamość jest zapisywana tylko w konfiguracji tego repozytorium; szkic zostaje zachowany.';

  @override
  String get gitUiSaveRepositoryIdentity => 'Zapisz tożsamość repozytorium';

  @override
  String get gitUiStaged => 'W indeksie';

  @override
  String get gitUiUntracked => 'Nieśledzone';

  @override
  String get gitUiUnstaged => 'Poza indeksem';

  @override
  String get gitUiConflicts => 'Konflikty';

  @override
  String get gitUiNoChanges => 'Brak zmian';

  @override
  String get gitUiRepositoryChangeTree => 'Repozytorium';

  @override
  String get gitUiChanges => 'Zmiany';

  @override
  String gitUiGroupCount(String group, String count) {
    return '$group ($count)';
  }

  @override
  String get gitUiExpand => 'Rozwiń';

  @override
  String get gitUiCollapse => 'Zwiń';

  @override
  String get gitUiUnstageFile => 'Usuń plik z indeksu';

  @override
  String get gitUiStageFile => 'Dodaj plik do indeksu';

  @override
  String get gitUiExpandGroup => 'Rozwiń grupę';

  @override
  String get gitUiCollapseGroup => 'Zwiń grupę';

  @override
  String get gitUiReviewDifference => 'Różnica w przeglądzie';

  @override
  String get gitUiUnstageSelectedFiles => 'Usuń wybrane pliki z indeksu';

  @override
  String get gitUiStageSelectedFiles => 'Dodaj wybrane pliki do indeksu';

  @override
  String get gitUiFileHistoryAndBlame => 'Historia plików i wina...';

  @override
  String get gitUiDeleteUntrackedFile => 'Usuń niezamierzony plik...';

  @override
  String get gitUiDiscardUnstagedChange => 'Odrzuć niestabilną zmianę...';

  @override
  String get gitUiFileHistory => 'Historia pliku';

  @override
  String gitUiDiscardUnstagedArg0(String arg0) {
    return 'Porzuć niestacjonowany $arg0?';
  }

  @override
  String gitUiArg0BytesArg1ReplacesWorkingContentWithTheIndexOr(
    String arg0,
    String arg1,
  ) {
    return '$arg0 bajty · $arg1 Zastępuje treści robocze indeksem lub usuwa ten nieśledzony plik. Zachowuje się zarysowaną zawartość. Niezarejestrowane dokumenty hosta muszą zostać poddane przeglądowi.';
  }

  @override
  String get gitUiDeleteUntrackedFile2 => 'Usuń nieoznaczony plik';

  @override
  String get gitUiDiscardWorkingChange => 'Odrzuć zmiany w pracy';

  @override
  String gitUiDeleteREMOTEReferenceArg0(String arg0) {
    return 'Usuń odniesienie REMOTE $arg0';
  }

  @override
  String get gitUiThisRemovesTheReferenceOnEveryActualPushDestinationListed =>
      'To usuwa odniesienie do każdego konkretnego miejsca przeznaczenia wymienionego poniżej. Lokalne oddziały/tagi są przechowywane. Oczekiwane wskazówki są ustalone w ramach niniejszego przeglądu.';

  @override
  String get gitUiReferenceDoesNotExist => 'odniesienie nie istnieje';

  @override
  String gitUiArg0ExpectedTipArg1(String arg0, String arg1) {
    return '$arg0 Oczekiwana wskazówka: $arg1';
  }

  @override
  String get gitUiRemoteDeletionCompleted => 'Zdalne usuwanie zakończone.';

  @override
  String gitUiDeleteArg0FromTheRemote(String arg0) {
    return 'Usuń $arg0 z pilota?';
  }

  @override
  String get gitUiTheExactDestinationTipsShownAboveWillBeRemovedAny =>
      'Dokładne wskazówki dotyczące miejsca przeznaczenia przedstawione powyżej zostaną usunięte. Wszelkie zmienione zdalne końce zatrzymują działanie dla innej recenzji.';

  @override
  String get gitUiReviewAndDeleteFromRemote =>
      'Przegląd i usuwanie z zdalnego...';

  @override
  String get gitUiDestinationReference =>
      'Odniesienie do miejsca przeznaczenia';

  @override
  String get gitUiReviewDestinations => 'Przewiń miejsca przeznaczenia';

  @override
  String get gitUiNewRemoteBranch => 'nowa zdalna gałąź';

  @override
  String gitUiArg0Arg1ExpectedArg2(String arg0, String arg1, String arg2) {
    return '$arg0\n$arg1 · oczekiwano: $arg2';
  }

  @override
  String get gitUiADestinationHasCommitsThatAreUnavailableLocallyFetchThat =>
      'Miejsce przeznaczenia zobowiązuje się, które są niedostępne lokalnie.Weź ten przegląd miejsca przeznaczenia przed przeglądem historii wyjazdu.';

  @override
  String get gitUiFetchReviewedDestination =>
      'Pobieranie zweryfikowanych miejsc przeznaczenia';

  @override
  String get gitUiChooseADestinationAndReviewTheOutgoingCommits =>
      'Wybierz cel i przejrzyj wychodzące zobowiązania.';

  @override
  String get gitUiNoOutgoingCommits => 'Brak wychodzących zobowiązań';

  @override
  String get gitUiSelectAnOutgoingCommit => 'Wybierz wychodzące zobowiązanie';

  @override
  String get gitUiLoadMoreOutgoingCommits =>
      'Wczytaj więcej wychodzących zobowiązań';

  @override
  String get gitUiSetThisDestinationAsUpstream => 'Ustaw ten cel naprzód';

  @override
  String get gitUiChooseExactTagsToPublish =>
      'Wybierz dokładne znaczniki do publikacji';

  @override
  String get gitUiTagsNone => 'Znaczniki: none';

  @override
  String gitUiTagsArg0Selected(String arg0) {
    return 'Tagi: $arg0 wybrane';
  }

  @override
  String gitUiPublishExactlyArg0(String arg0) {
    return 'Publikacja dokładnie: $arg0';
  }

  @override
  String get gitUiPushCompletedTheLocalCommitRemainsAvailableInLog =>
      'Push zakończone. Zdefiniowane lokalne zobowiązanie pozostaje dostępne w Log.';

  @override
  String get gitUiForceRequiresTheExactDestinationTipsShownInThisReview =>
      'Wymuszenie wymaga dokładnie tych końcowych rewizji docelowych, które pokazano do sprawdzenia.';

  @override
  String get gitUiForceWithReviewedLease =>
      'Siły z rewitalizowaną dzierżawą...';

  @override
  String get gitUiPush => 'Wyślij';

  @override
  String get gitUiForcePushWithReviewedLeases => 'Zmusić do rewizji dzierżawy?';

  @override
  String gitUiRewriteArg0OnlyIfEveryRemoteDestinationStillHasThe(String arg0) {
    return 'Zapisz ponownie $arg0 tylko wtedy, gdy każdy odległy cel nadal ma dokładną wskazówkę pokazano powyżej.\n';
  }

  @override
  String get gitUiOtherPeopleMayAlreadyUseThisHistoryABackgroundFetch =>
      'Inni mogą już korzystać z tej historii. Pobieranie w tle nie odnawia tej dzierżawy bezpieczeństwa.';

  @override
  String get gitUiForceWithLease => 'Siła dzierżawy';

  @override
  String
  get gitUiTheRemoteOutcomeIsUncertainReviewDestinationsAgainBeforeAnother =>
      'Zdalny wynik jest niepewny. Przegląd miejsc ponownie przed kolejnym pchnięciem.';

  @override
  String gitUiParentArg0Arg1(String arg0, String arg1) {
    return 'Rodzic $arg0 · $arg1';
  }

  @override
  String get gitUiRemoteToFetch => 'Zdalnie do pobrania';

  @override
  String get gitUiPruneDeletedRemoteTrackingBranches =>
      'Oddziały zdalnie śledzące pruty usunięte';

  @override
  String
  get gitUiFetchUpdatesRemoteTrackingInformationWithoutReplacingWorkingFiles =>
      'Pobierz aktualizacje informacji zdalnie śledzących bez wymiany plików roboczych.';

  @override
  String get gitUiFetch => 'Pobierz';

  @override
  String get gitUiSourceRemote => 'Odizolowanie źródła';

  @override
  String get gitUiSourceBranch => 'Oddział źródłowy';

  @override
  String get gitUiReviewedStrategy => 'Przeglądowana strategia';

  @override
  String get gitUiMerge => 'Scal';

  @override
  String get gitUiRebase => 'Przebazuj';

  @override
  String get gitUiStopIfTheDestinationCannotFastForwardNeverMergeOr =>
      'Zatrzymaj, jeśli cel nie jest w stanie szybko przewinąć; nigdy nie przekształcić ani nie przekształcić bazy.';

  @override
  String get gitUiMergeWithAMergeCommitIncludingWhenFastForwardIs =>
      'Połącz się z powiązką łączącą, w tym w przypadku, gdy jest to możliwe.';

  @override
  String get gitUiMergeAllowFastForwardWhenPossible =>
      'Łączenie; w miarę możliwości umożliwia szybkie przewidzenie.';

  @override
  String get gitUiRebaseLocalHistoryWhilePreservingLocalMergeCommits =>
      'Ponownie oprzeć lokalną historię przy zachowaniu lokalnego połączenia zobowiązań.';

  @override
  String get gitUiRebaseLocalCommitsAsALinearHistory =>
      'Powtórzmy lokalną historię.';

  @override
  String get gitUiGitIsConfiguredForInteractiveRebaseSelectAPullStrategy =>
      'Git jest skonfigurowany do interaktywnej rebase. Wybierz strategię pociągu wyraźnie tutaj, lub pobrać i otworzyć Rebase..., aby przeglądać plan.';

  @override
  String get gitUiUseReviewedOrdinaryRebaseForThisPull =>
      'Użyj przeglądu zwykłej bazy dla tego ciągnięcia';

  @override
  String get gitUiOptions => 'Opcje';

  @override
  String get gitUiAlwaysCreateAMergeCommitNoFastForward =>
      'Zawsze tworzyć commit commit (bez szybkiej zmiany)';

  @override
  String get gitUiPreserveLocalMergeCommits => 'Zachowaj lokalne połączenie';

  @override
  String get gitUiLocalChangesMayPreventPullReviewCommitThemOrExplicitly =>
      'Zmiany lokalne mogą zapobiec ciągnięciu. Przegląd/załącz je lub wyraźnie utworzyć schowka.';

  @override
  String get gitUiStashes => 'Schowki';

  @override
  String get gitUiCreateOrReviewStash =>
      'Tworzenie lub przeglądanie schowka...';

  @override
  String get gitUiPullWithSelectedStrategy =>
      'Pociągnij za pomocą wybranej strategii';

  @override
  String get gitUiRepositoryURLOrLocalGitSource =>
      'Repozytorium URL lub lokalne źródło Git';

  @override
  String get gitUiHttpsSSHOrLocalPath => 'HTTPS, SSH lub lokalna ścieżka';

  @override
  String get gitUiFolderToInitialize => 'Katalog do inauguracji';

  @override
  String get gitUiFinalCloneDestination =>
      'Ostateczne miejsce przeznaczenia klonu';

  @override
  String get gitUiChoose => 'Wybierz...';

  @override
  String get gitUiCreatesGitMetadataOnlyExistingFilesAreNotStagedOr =>
      'Tworzy tylko metadane Git. Istniejące pliki nie są skonfigurowane ani angażowane.';

  @override
  String get gitUiTheFinalDestinationMustBeAbsentOrEmptyExistingUser =>
      'Katalog docelowy nie może istnieć lub musi być pusty. Istniejące dane użytkownika nigdy nie są nadpisywane.';

  @override
  String get gitUiInitialBranchBlankUsesEffectiveGitPolicy =>
      'Początkowy oddział · pusty wykorzystuje skuteczną politykę Git';

  @override
  String get gitUiSelectedBranchOptional => 'Zaznaczony oddział · opcjonalnie';

  @override
  String get gitUiExplicitlyInitializeUpdateSubmodulesRecursively =>
      'Wyraźnie inauguruje/zaktualizuje podmoduły rekonstrukcyjnie';

  @override
  String get gitUiPreparingGitOperation => 'Przygotowywanie operacji Git...';

  @override
  String get gitUiThisAttemptCreated => 'Ta próba powstała';

  @override
  String get gitUiTheDestinationExistedBeforeThisAttempt =>
      'Miejsce przeznaczenia istniało przed tą próbą:';

  @override
  String get gitUiTheDirectoryRemainsForInspectionReviewItBeforeAnotherClone =>
      'Katalog pozostaje do inspekcji. Sprawdź go przed kolejną próbą klonowania.';

  @override
  String get gitUiNoDestinationDirectoryRemains =>
      'Brak katalogu docelowego pozostaje.';

  @override
  String get gitUiCancelProcess => 'Anuluj proces';

  @override
  String get gitUiInitialize => 'Zainicjuj';

  @override
  String get gitUiClone => 'Klonuj';

  @override
  String get gitUiChooseNewBase => 'Wybierz nową bazę';

  @override
  String get gitUiChooseUpstreamBoundary => 'Wybierz granicę upstream';

  @override
  String get gitUiNewBase => 'Nowa baza';

  @override
  String get gitUiUpstreamBoundaryExcluded => 'Granica upstream · wyłączona';

  @override
  String get gitUiSameAsUpstreamBoundary => 'Taka jak granica upstream';

  @override
  String get gitUiChooseBranchTagOrCommit => 'Wybierz gałąź, tag lub commit…';

  @override
  String get gitUiUseUpstreamAsNewBase => 'Użyj w górę jako nowej bazy';

  @override
  String get gitUiChooseAValidBranchTagOrCommitFromLog =>
      'Wybierz poprawną gałąź, znacznik lub powierzenie się z dziennika.';

  @override
  String get gitUiTheFirstRetainedCommitInABranchBlockCannotSquash =>
      'Pierwszy zachowany commit bloku gałęzi nie może mieć akcji squash ani fixup: brak wcześniejszego commitu docelowego.';

  @override
  String gitUiBranchBlockArg0(String arg0) {
    return 'Blok oddziału $arg0\n';
  }

  @override
  String get gitUiRewordWillRequestANewMessage =>
      '[Reword zażąda nowej wiadomości]\n';

  @override
  String get gitUiPlannedCommitMessages =>
      'Przewidziane komunikaty w sprawie zobowiązań';

  @override
  String
  get gitUiOriginalCombinedMessagePreviewGitRequestsTheFinalRewordSquash =>
      'Podgląd oryginalnej/ połączonej wiadomości · Git żąda ostatecznego przekształcenia/squash wiadomości';

  @override
  String gitUiResultArg0Arg1(String arg0, String arg1) {
    return 'Wynik $arg0 $arg1';
  }

  @override
  String gitUiCurrentBranchBranch(String branch) {
    return 'Bieżąca gałąź: $branch';
  }

  @override
  String get gitUiDetachedHEAD2 => 'Odłączony HEAD';

  @override
  String
  get gitUiRebaseRewritesCommitIdentitiesRemoteTrackingInformationCannotProveHistory =>
      'Przebazowanie zmienia tożsamości commitów. Dane śledzenia zdalnego nie dowodzą, że historia nigdy nie została opublikowana.';

  @override
  String get gitUiIncludeRootCommits => 'Uwzględnij commity główne';

  @override
  String get gitUiMergeCommits => 'Łączenie zobowiązań';

  @override
  String get gitUiFlattenHistory => 'Spłaszcz historię';

  @override
  String get gitUiPreserveBranchStructure => 'Zachowaj strukturę gałęzi';

  @override
  String get gitUiAutosquash => 'Automatyczne łączenie';

  @override
  String get gitUiPrepareGitPlan => 'Przygotuj plan Git';

  @override
  String gitUiCommitsToReplayCount(String count) {
    return 'Commity do ponownego zastosowania: $count';
  }

  @override
  String get gitUiIncludesAllRootCommitsReachableFromThisBranch =>
      'Obejmuje wszystkie zobowiązania korzeniowe osiągalne z tego gałęzi.';

  @override
  String gitUiCommitsAfterBoundaryWillBeReplayedOntoBaseTheBoundary(
    String boundary,
    String base,
  ) {
    return 'Commity po $boundary zostaną ponownie zastosowane na $base; sam commit graniczny jest wyłączony.';
  }

  @override
  String get gitUiRoot => 'Korzenie';

  @override
  String get gitUiGitBranchLabelResetMergeStructure =>
      'Oddział Git/oznaczenie/odbiór/zamocowanie/zamocowanie';

  @override
  String get gitUiChooseAnExplicitOldBoundaryOrRootModeThenPrepare =>
      'Wybierz wyraźną starą granicę lub tryb korzeniowy, a następnie przygotuj plan.';

  @override
  String get gitUiMoveUp => 'Przesuń w górę';

  @override
  String get gitUiMoveDown => 'Przesuń w dół';

  @override
  String get gitUiResetPlan => 'Przywróć plan';

  @override
  String gitUiBranchBlockArg02(String arg0) {
    return ' · Blok oddziału $arg0';
  }

  @override
  String get gitUiSelectACommitForDetailsAndChangedFiles =>
      'Wybierz popełnienie szczegółów i zmienione pliki';

  @override
  String get gitUiPreviewCombinedCommitMessages =>
      'Podgląd połączonych wiadomości...';

  @override
  String get gitUiAltMovesTheSelectedCommitUnrelatedBranchReferencesWillNot =>
      'Alt+↑/↓ przesuwa zaznaczone zobowiązanie. Niepowiązane odniesienia odboczne nie zostaną automatycznie uaktualnione.';

  @override
  String get gitUiCancelPlan => 'Anuluj plan';

  @override
  String get gitUiStartReviewedRebase => 'Rozpocząć sprawdzone przebazowanie?';

  @override
  String gitUiRewriteArg0PlannedCommitsOnArg1DroppedCommitsRemainVisibly(
    String arg0,
    String arg1,
  ) {
    return 'Przepisz $arg0 planowane zobowiązania na $arg1. Utracone zobowiązania pozostają w tym planie wyraźnie oznaczone do rozpoczęcia.';
  }

  @override
  String get gitUiStartRebase => 'Rozpocznij przebazowanie';

  @override
  String get gitUiNoContinuingGitOperation => 'Brak kontynuacji operacji Git';

  @override
  String get gitUiStoppedForEditingAmend => ' · zatrzymano dla edycji/zmiana';

  @override
  String get gitUiTheseAreUnmergedIndexEntriesPossiblyFromAStashApplication =>
      'To są wpisy w indeksie niezanurzonym, być może z aplikacji schowka. Git nie ma żadnych ukrytych danych ani polecenia anulowania.';

  @override
  String get gitUiEditTheWorkingFilesStageAndAmendTheCurrentCommit =>
      'Edytuj pliki robocze, skonfiguruj i zmień bieżące zobowiązanie, a następnie kontynuuj ponownie bazę.';

  @override
  String gitUiArg0Arg1UnmergedStagesArg2(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return '$arg0$arg1 · niescalone etapy indeksu $arg2';
  }

  @override
  String get gitUiTheIndexHasNoUnresolvedEntries =>
      'Indeks nie zawiera nierozwiązanych wpisów.';

  @override
  String get gitUiKeepTheCurrentCommitAsAnEmptyCommit =>
      'Utrzymuj bieżące zobowiązanie jako puste zobowiązanie';

  @override
  String get gitUiTheRealIndexHasNoStagedChangesCreateAnExplicit =>
      'Realny indeks nie ma zmian w scenie. Tworzenie wyraźnego pustego zobowiązania, a następnie kontynuować sekwencjoner, jeśli pozostaje aktywny.';

  @override
  String get gitUiKeepEmptyCommit => 'Zachować puste popełnienie...';

  @override
  String get gitUiGitWillTryToReturnToTheOperationSStarting =>
      'Git spróbuje wrócić do punktu początkowego operacji. Odzyskanie wcześniejszej treści poza indeksem, nieśledzonej lub niezapisanej nie jest gwarantowane.';

  @override
  String get gitUiSkipTheCurrentCommitAndContinueWithTheNextPlanned =>
      'Pomiń bieżące zobowiązanie i kontynuuj planowane zobowiązanie.';

  @override
  String
  get gitUiForgetThisOperationSBookkeepingWhileRetainingTheCurrentFiles =>
      'Zapomnij o księgowaniu operacji podczas przechowywania bieżących plików i indeksu.';

  @override
  String gitUiContinueArg0(String arg0) {
    return 'Kontynuuj $arg0';
  }

  @override
  String get gitUiReloadConflictVersions => 'Przeładować wersje konfliktów?';

  @override
  String get gitUiReplaceTheUnsavedResultDraftWithTheCurrentWorkingFile =>
      'Zamień nieuszkodzony projekt wyniku bieżącym plikiem roboczym. Zapisany tekst roboczy jest przechowywany.';

  @override
  String get gitUiLoadingConflictVersions => 'Wczytywanie wersji konfliktu...';

  @override
  String get gitUiLoadingConflict => 'Wczytywanie konfliktu';

  @override
  String get gitUiBaseLeft => 'Baza bazowa → w lewo';

  @override
  String get gitUiBaseRight => 'Base → w prawo';

  @override
  String get gitUiNoBaseEntryForThisConflict =>
      'Brak wstępu dla tego konfliktu';

  @override
  String get gitUiAcceptEntireLeftFile => 'Zaakceptuj cały lewy plik...';

  @override
  String get gitUiAcceptEntireRightFile => 'Przyjmij cały plik z prawej…';

  @override
  String get gitUiPreviousConflictRegion => 'Poprzedni region konfliktu';

  @override
  String get gitUiNextConflictRegion => 'Następny region konfliktu';

  @override
  String get gitUiManualResolution => 'Rozdzielczość ręczna';

  @override
  String gitUiRegionArg0Arg1Arg2Reviewed(
    String arg0,
    String arg1,
    String arg2,
  ) {
    return 'Region $arg0/$arg1 · $arg2 przejrzał';
  }

  @override
  String
  get gitUiSourceAlignmentExceededTheTextComparisonLimitSourcePanesRemain =>
      'Dostosowanie źródła przekroczyło limit porównania tekstu; tablice źródłowe pozostają dostępne do przeglądu ręcznego.';

  @override
  String get gitUiAcceptLeftRegion => 'Akceptuj lewy region';

  @override
  String get gitUiAcceptRightRegion => 'Akceptuj właściwy region';

  @override
  String get gitUiKeepManualResultForRegion =>
      'Zachować wynik ręczny dla regionu';

  @override
  String get gitUiApplyGitSNonConflictingChanges =>
      'Czy zastosować zmiany niekonfliktujące Git?';

  @override
  String get gitUiReplaceTheCurrentResultDraftWithGitSMergePreview =>
      'Zamień bieżący projekt programu za pomocą podglądu połączenia Git. Ten odrzuca nieupoważniony ręczny wynik edytuje; plik roboczy jest niezmieniony aż do Zapisz.';

  @override
  String get gitUiUseMergePreview => 'Użyj podglądu połączenia';

  @override
  String get gitUiApplyNonConflictingChanges =>
      'Zastosuj zmiany niekonfliktujące...';

  @override
  String get gitUiLeftSource => 'Lewe źródło';

  @override
  String get gitUiResult => 'Wynik';

  @override
  String get gitUiRightSource => 'Prawo źródło';

  @override
  String get gitUiStage2 => 'Etap 2';

  @override
  String get gitUiStage3 => 'Etap 3';

  @override
  String
  get gitUiConflictVersionsAreUnavailableRefreshToReviewTheirCurrentState =>
      'Wersje konfliktu są niedostępne. Odśwież, aby sprawdzić ich aktualny stan.';

  @override
  String get gitUiResultSavedToDiskTheIndexStillDeterminesWhetherThis =>
      'Wynik zapisany na dysku. Indeks nadal określa, czy plik jest rozwiązany.';

  @override
  String get gitUiSaveResultDraft => 'Zapisz szkic wyniku';

  @override
  String get gitUiApplyResultAndStageResolution =>
      'Zastosuj wynik i dodaj rozwiązanie do indeksu';

  @override
  String get gitUiResultEditableUTF8WorkingContent =>
      'Wynik · edycja zawartości roboczej UTF-8';

  @override
  String get gitUiEditableConflictResult => 'Rezultat rzekomego konfliktu';

  @override
  String gitUiLeftArg0Arg1RightArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return 'Lewa: $arg0 · $arg1\nPrawa: $arg2 · $arg3';
  }

  @override
  String get gitUiChooseContentDeletionOrASubmoduleCommitExplicitlyNoBinary =>
      'Wybierz zawartość, usunięcie lub submoduł wyrażony wyraźnie. Brak danych binarnych jest odkodowywanych jako tekst modyfikujący.';

  @override
  String get gitUiUseEntireLeftContent => 'Użyj całej lewej zawartości...';

  @override
  String get gitUiUseEntireRightContent => 'Użyj całej zawartości z prawej…';

  @override
  String get gitUiDeleteThisPath => 'Usuń tę ścieżkę...';

  @override
  String get gitUiResolvedSubmoduleCommit =>
      'Rozpuszczone zobowiązanie podmodułowe';

  @override
  String get gitUiStageThisExactGitlinkInTheParentThisDoesNot =>
      'Włączyć dokładnie ten gitlink w rodzicu. Nie sprawdza się ani nie wykonuje podmodułu.';

  @override
  String get gitUiSetResolvedGitlink => 'Ustaw rozwiązany gitlink...';

  @override
  String gitUiBaseStageArg0(String arg0) {
    return 'Podstawa → stadium $arg0';
  }

  @override
  String get gitUiTheResultWasEditedKeepTheManualResultOrSelect =>
      'Rezultat został zredagowany. Zachować wynik ręczny lub wybrać inny region niezmieniony.';

  @override
  String gitUiApplyArg0Resolution(String arg0) {
    return 'Zastosować rozwiązanie „$arg0”?';
  }

  @override
  String get gitUiStageTheChosenGitlinkCommitInTheParentTheSubmodule =>
      'Etap wybrany gitlink zobowiązuje się w rodzicu. Wykaz podmodułowy i jego pliki nie są zastępowane.';

  @override
  String gitUiReplacesTheEntireWorkingPathArg0AndStagesTheDecision(
    String arg0,
  ) {
    return 'Zastępuje całą ścieżkę roboczą $arg0 i rozpoczyna decyzję. Obecna zawartość robocza i nieokreślony projekt wyników zostaną odrzucone.';
  }

  @override
  String get gitUiApplyEntireFileDecision => 'Zastosuj całą decyzję o pliku';

  @override
  String get gitUiStageThisConflictResolution =>
      'Zajmować się rozwiązaniem konfliktów?';

  @override
  String gitUiUseTheEntireEditedResultAsArg0GitRecordsThe(
    String arg0,
    String arg1,
  ) {
    return 'Użyj całej edytowanej Rezultat jako $arg0. Git rejestruje ścieżkę rozłożoną podczas jej scenowania. Najpierw przejrzyj wszystkie zamierzone treści.$arg1';
  }

  @override
  String get gitUiApplyAndStage => 'Zastosuj i dodaj do indeksu';

  @override
  String get gitUiReviewResultTextFormatChanges =>
      'Zmiany wyniku przeglądu w formacie tekstu';

  @override
  String get gitUiSaveReviewedResult => 'Zapisz recenzowany wynik';

  @override
  String
  get gitUiNativeGitTableAccessibilityIsUnavailableRetryAfterReconnectingThe =>
      'Dostępność tabeli Git jest niedostępna. Ponownie połączyć aplikację.';

  @override
  String get gitUiSans => 'Sans Przewodniczący';

  @override
  String get gitUiSelect => 'Wybierz';

  @override
  String get gitUiContextMenu => 'Menu kontekstowe';

  @override
  String get gitUiCopyText => 'Kopiuj tekst';

  @override
  String get gitUiLoadingRow => 'Wczytywanie wiersza';

  @override
  String get gitUiRetry => 'Ponów';

  @override
  String get gitUiGitMessage => 'Wiadomość Git';

  @override
  String get gitUiCancelPrompt => 'Anuluj pośpiech';

  @override
  String get gitUiUseMessageAndContinue => 'Użyj wiadomości i kontynuuj';

  @override
  String get gitUiRespondPrivately => 'Odpowiedz na pytanie prywatnie';

  @override
  String gitUiViewPreferencesCouldNotBeSavedArg0(String arg0) {
    return 'Preferencje widoku nie mogły zostać zapisane: $arg0';
  }

  @override
  String gitUiCommitDraftStorageArg0(String arg0) {
    return 'Składanie projektu zobowiązań: $arg0';
  }

  @override
  String gitUiViewPreferencesCouldNotBeReadArg0(String arg0) {
    return 'Nie można było odczytać preferencji widoku: $arg0';
  }

  @override
  String gitUiCommitDraftWasRetainedInMemoryButCouldNotBe(String arg0) {
    return 'Projekt zobowiązań został zachowany w pamięci, ale nie mógł zostać zapisany: $arg0';
  }

  @override
  String get gitUiTheReviewedRepositoryIsReadOnlyForThisOperationHistory =>
      'Przegląd repozytorium jest tylko do odczytu dla tej operacji.';

  @override
  String gitUiGitReturnedArg0TheApplicationCouldNotRefreshItsDocuments(
    String arg0,
    String arg1,
  ) {
    return 'Git zwrócił $arg0. Aplikacja nie mogła odświeżyć dokumentów: $arg1';
  }

  @override
  String get gitUiSelectCommitInLog => 'Wybierz commit z historii…';

  @override
  String get gitUiCurrentBranch => 'Bieżąca gałąź';

  @override
  String get gitUiNoMatchingBranchesOrTagsSelectACommitInLog =>
      'Brak pasujących gałęzi i znaczników. Wybierz popełnienie w Log.';

  @override
  String get gitUiBranches => 'Gałęzie';

  @override
  String get gitUiPushCommits => 'Wyślij commity';

  @override
  String gitUiPullIntoArg0(String arg0) {
    return 'Wciągnij w $arg0';
  }

  @override
  String gitUiResolveArg0(String arg0) {
    return 'Rezolucja $arg0';
  }

  @override
  String get gitUiCurrentOperation => 'Bieżąca operacja';

  @override
  String get gitUiRebaseCommits => 'Przebazuj commity';

  @override
  String get gitUiFetch2 => 'Pobierz…';

  @override
  String get gitUiPull => 'Pobierz i zintegruj…';

  @override
  String get gitUiPush2 => 'Wyślij…';

  @override
  String get gitUiBranches2 => 'Gałęzie…';

  @override
  String get gitUiManageRemotes => 'Zarządzaj repozytoriami zdalnymi…';

  @override
  String gitUiMergeIntoArg0(String arg0) {
    return 'Połącz się z $arg0...';
  }

  @override
  String get gitUiRebase2 => 'Przebazuj…';

  @override
  String get gitUiConflictsAndCurrentOperation =>
      'Konflikty i bieżące działanie...';

  @override
  String get gitUiStashes2 => 'Schowki…';

  @override
  String get gitUiWorktrees => 'Drzewa robocze…';

  @override
  String get gitUiSubmodules => 'Podmoduły…';

  @override
  String get gitUiReflogAndRecovery => 'Reflog i odzyskiwanie…';

  @override
  String get gitUiCloneRepository => 'Klonuj repozytorium…';

  @override
  String get gitUiRevokeRepositoryTrust => 'Cofnij zaufanie do repozytorium';

  @override
  String get gitUiWaitingForRepositoryStatus =>
      'Czekanie na status repozytorium';

  @override
  String get gitUiRepositoryStatusUnavailableRefresh =>
      'Status repozytorium niedostępny; odśwież';

  @override
  String get gitUiManageRemotes2 => 'Zarządzaj repozytoriami zdalnymi';

  @override
  String gitUiMergeIntoArg02(String arg0) {
    return 'Połącz się z $arg0';
  }

  @override
  String get gitUiWorktrees2 => 'Drzewa robocze';

  @override
  String get gitUiSubmodules2 => 'Podmoduły';

  @override
  String get gitUiReflogAndRecovery2 => 'Reflog i odzyskiwanie';

  @override
  String gitUiCloneRepositoryArg0(String arg0) {
    return 'Slone repozytorium · $arg0';
  }

  @override
  String get gitUiApply => 'Zastosuj';

  @override
  String get gitUiResizeGitPanes => 'Zmień rozmiar tafli gita';

  @override
  String gitUiArg0Percent(String arg0) {
    return '$arg0 procent';
  }

  @override
  String gitUiExitStatusStatus(String status) {
    return 'Status wyjścia: $status';
  }

  @override
  String get gitUiRepositoryChangedRefreshAndReviewBeforeTryingAgain =>
      'Repozytorium zmieniło się. Odśwież i przejrzyj przed próbą ponownie.';

  @override
  String get gitUiAnotherOperationHoldsTheRepositoryOrIndexLockWaitThen =>
      'Inna operacja trzyma repozytorium lub indeks zablokowanie.';

  @override
  String get gitUiRepositoryTrustIsRequiredForThisOperation =>
      'Do tej operacji konieczne jest repozytorium zaufania.';

  @override
  String get gitUiTheGitServiceDisconnectedReconnectAndReconcileTheRepository =>
      'Usługa Git odłączona, połączyć i pogodzić repozytorium.';

  @override
  String
  get gitUiTheInstalledGitExecutableCannotSupportThisOperationReviewIts =>
      'Zainstalowany plik wykonywalny Git nie może poprzeć tej operacji. Przejrzyj jego wymagania dotyczące czasu runtime poniżej.';

  @override
  String get gitUiThisRepositoryIsReadOnlyForTheRequestedOperationReview =>
      'Repozytorium to tylko do odczytu dla wymaganej operacji. Przegląd i historia pozostają dostępne.';

  @override
  String
  get gitUiTheOperationNeedsReconciliationReviewTheResultingRepositoryOrRemote =>
      'Operacja wymaga pojednania. Sprawdź wynik repozytorium lub stan zdalny przed powtórzeniem.';

  @override
  String get gitUiGitAuthenticationFailedReviewTheCredentialHelperOrUnlockThe =>
      'Uwierzytelnianie Git nie powiodło się. Przejrzyj powiernika lub odblokuj skonfigurowany klucz.';

  @override
  String get gitUiSshHostVerificationFailedReviewTheHostIdentityThroughYour =>
      'Weryfikacja serwera SSH nie powiodła się. Przejrzyj tożsamość hosta za pomocą skonfigurowanych narzędzi SSH.';

  @override
  String get gitUiCommitSigningFailedOrWasCancelledReviewTheSigningKey =>
      'Podpisanie zobowiązania nie powiodło się lub zostało anulowane. Przegląd klucza podpisującego, agenta i skonfigurowanego narzędzia podpisującego.';

  @override
  String get gitUiSetARepositoryAuthorNameAndEmailThenReturnTo =>
      'Ustaw nazwę autora repozytorium i e-mail, a następnie zwróć się do zapisanego projektu wiadomości.';

  @override
  String get gitUiGitRejectedTheReviewedUpdateRefreshAndReviewTheActual =>
      'Git odrzucił przegląd aktualizacji. Odśwież i przejrzyj rzeczywiste miejsce przeznaczenia przed próbą ponownie.';

  @override
  String get gitUiWorkingOrStagedChangesPreventThisOperationReviewCommitOr =>
      'Zmiany w pracy lub skonfigurowane zapobiegają tej operacji. Przegląd, zaangażowanie lub wyraźnie schować je.';

  @override
  String get gitUiARequiredGitObjectIsUnavailableReviewShallowOrPartial =>
      'Niedostępny jest wymagany obiekt Git. Wyświetl płytkie lub częściowe granice repozytorium i pobierz wyraźnie, jeśli jest to konieczne.';

  @override
  String gitUiGitOperationFailedArg0(String arg0) {
    return 'Operacja Git nie powiodła się: $arg0';
  }

  @override
  String get gitUiDiagnostics => 'Diagnostyka';

  @override
  String get gitUiAuthorizeGitInspection => 'Kontrola Git jest autoryzowana...';

  @override
  String get gitUiCopyDiagnostics => 'Kopiuj diagnostykę';

  @override
  String get gitUiActions => 'Działania';

  @override
  String gitUiBranchAtArg0(String arg0) {
    return 'Oddział na $arg0';
  }

  @override
  String get gitUiCreatesALocalBranchWithoutCheckingItOut =>
      'Tworzy lokalną gałąź bez sprawdzenia jej.';

  @override
  String gitUiTagArg0(String arg0) {
    return 'Tag $arg0';
  }

  @override
  String gitUiReadOnlySnapshotArg0(String arg0) {
    return 'Jedynie migawka do odczytu · $arg0';
  }

  @override
  String get gitUiCherryPickCommits => 'Zastosuj commity przez cherry-pick';

  @override
  String get gitUiRevertCommits => 'Cofnij zobowiązania';

  @override
  String get gitUiCompareToFullRevisionID =>
      'Porównanie do pełnego identyfikatora zmiany';

  @override
  String gitUiTreeComparisonDirectionArg0TheRevisionEnteredHere(String arg0) {
    return 'Kierunek porównania drzew: $arg0 → wprowadzona tutaj zmiana.';
  }

  @override
  String get gitUiEnterAFullValidObjectID =>
      'Podaj pełną poprawną identyfikację obiektu.';

  @override
  String gitUiArg0Arg1TreeComparison(String arg0, String arg1) {
    return '$arg0 → $arg1 · Porównanie drzew';
  }

  @override
  String gitUiResetArg0ToArg1(String arg0, String arg1) {
    return 'Reset $arg0 na $arg1';
  }

  @override
  String
  get gitUiMovesHEADCurrentBranchReflogDoesNotRecoverArbitraryUntracked =>
      'Przesuwa HEAD/bieżącą gałąź. Reflog nie odzyskuje dowolnych nieśledzonych lub niezapisanych treści.';

  @override
  String get gitUiMoveHEADKeepIndexAndWorkingFiles =>
      'Przesuń HEAD; zachowaj indeks i pliki robocze.';

  @override
  String get gitUiMoveHEADAndReplaceIndexKeepWorkingFiles =>
      'Przesuń HEAD i zastąp indeks; zachowaj pliki robocze.';

  @override
  String
  get gitUiReplaceHEADIndexAndTrackedWorkingFilesMayOverwriteObstructing =>
      'Zastąp HEAD, indeks i śledzone pliki robocze; kolidujące pliki nieśledzone mogą zostać nadpisane.';

  @override
  String get gitUiReplaceHEADIndexAndEligibleFilesRefuseIfLocalChanges =>
      'Zastąp HEAD, indeks i odpowiednie pliki; odmów, jeśli lokalne zmiany zostałyby utracone.';

  @override
  String gitUiResetWithArg0(String arg0) {
    return 'Przywrócić ponownie na $arg0?';
  }

  @override
  String gitUiArg0Arg1ReviewTheSelectedModeSEffectsBeforeApplying(
    String arg0,
    String arg1,
  ) {
    return '$arg0 → $arg1 Sprawdź przed zastosowaniem efekty wybranego trybu.';
  }

  @override
  String gitUiResetArg0(String arg0) {
    return 'Reset $arg0';
  }

  @override
  String gitUiTargetArg0(String arg0) {
    return 'Cel $arg0';
  }

  @override
  String get gitUiTagName => 'Nazwa tagu';

  @override
  String get gitUiAnnotatedTag => 'Tag z adnotacją';

  @override
  String get gitUiCryptographicSigning => 'Podpis kryptograficzny';

  @override
  String get gitUiConfiguredPolicy => 'Konfigurowana polityka';

  @override
  String get gitUiSignThisTag => 'Podpisz ten znacznik';

  @override
  String get gitUiDoNotSign => 'Nie podpisuj';

  @override
  String get gitUiTagMessage => 'Wiadomość znacznika';

  @override
  String get gitUiCreatesTheTagLocallyPublishSelectedTagsExplicitlyInPush =>
      'Tworzy lokalnie znacznik. Publikacja wybranych znaczników wyraźnie w przeglądzie Push.';

  @override
  String gitUiCompleteTreesArg0Arg1(String arg0, String arg1) {
    return 'Drzewa kompletne: $arg0 → $arg1';
  }

  @override
  String get gitUiNextChangedFilePage => 'Następna strona pliku zmienionego';

  @override
  String get gitUiReadOnlyRepositorySnapshotOpeningAFileNeverChecksOut =>
      'Tylko do odczytu repozytorium migawki. Otwieranie pliku nigdy nie sprawdza tej zmiany.';

  @override
  String get gitUiOpenReadOnlyVersion => 'Otwarta wersja tylko do odczytu';

  @override
  String get gitUiRestoreThisPathWaitingForRepositoryStatus =>
      'Przywróć tę ścieżkę... · Czekanie na status repozytorium';

  @override
  String get gitUiRestoreThisPath => 'Przywróć tę ścieżkę...';

  @override
  String gitUiHistoryArg0(String arg0) {
    return 'Historia · $arg0';
  }

  @override
  String gitUiRestoreArg0(String arg0) {
    return 'Przywrócić $arg0?';
  }

  @override
  String gitUiReplaceThisWorkingPathWithRevisionArg0ExistingStagedContent(
    String arg0,
  ) {
    return 'Zamień tę ścieżkę roboczą na przeglądzie $arg0. Istniejąca zawartość sceniczna jest zachowana.';
  }

  @override
  String get gitUiRestoreWorkingFile => 'Przywróć plik roboczy';

  @override
  String gitUiFileHistoryFollowsRenamesArg0(String arg0) {
    return 'Historia pliku następuje po zmianie nazwy · $arg0';
  }

  @override
  String get gitUiBlameCommittedContent =>
      'Autorstwo wierszy · zatwierdzona treść';

  @override
  String get gitUiBlame => 'Autorstwo wierszy…';

  @override
  String gitUiArg0WorkingTree(String arg0) {
    return '$arg0 → Drzewo robocze';
  }

  @override
  String get gitUiOpenReadOnlyHistoricalFile =>
      'Otwórz plik historyczny tylko do odczytu';

  @override
  String get gitUiCompareToCurrentFile => 'Porównanie do bieżącego pliku';

  @override
  String get gitUiCompareToParent => 'W porównaniu do rodzica...';

  @override
  String gitUiCommittedArg0UnsavedEditorContentIsNotPartOfThese(String arg0) {
    return 'Autoryzowany $arg0 · Nieużyte treści redakcyjne nie są częścią tych uwag';
  }

  @override
  String gitUiHistoryFromArg0(String arg0) {
    return 'Historia $arg0';
  }

  @override
  String get gitUiBoundary => ' · Granica';

  @override
  String gitUiArg0Arg1OriginalLineArg2Arg3(
    String arg0,
    String arg1,
    String arg2,
    String arg3,
  ) {
    return '$arg0  $arg1\nPierwotny wiersz $arg2$arg3';
  }

  @override
  String get gitUiPreviousLines => 'Poprzednie wiersze';

  @override
  String get gitUiNextLines => 'Następny wiersz';

  @override
  String gitUiExplicitApplicationOrderDestinationArg0(String arg0) {
    return 'Explicit order aplikation · destination $arg0';
  }

  @override
  String get gitUiAddFullCommitObjectID => 'Dodaj ID obiektu';

  @override
  String get gitUiAddReviewedCommit => 'Dodaj rewidencjonowane zobowiązanie...';

  @override
  String get gitUiMoveEarlier => 'Ruszać się wcześniej';

  @override
  String get gitUiMoveLater => 'Przesuń się później.';

  @override
  String get gitUiRemoveFromReviewedSequence => 'Usuń z przeglądanej sekwencji';

  @override
  String get gitUiApplyChangesWithoutCreatingCommits =>
      'Zastosuj zmiany bez tworzenia zobowiązań';

  @override
  String get gitUiUseThisExplicitMainlineParentForMergeCommits =>
      'Użyj tego wyraźnego rodzica mainline do powiązywania się';

  @override
  String get gitUiEmptyOrAlreadyAppliedCommitsMayStopGitForAn =>
      'Puste lub już stosowane zobowiązania mogą zatrzymać Git w celu podjęcia wyraźnej decyzji o pominięciu lub kontynuacji.';

  @override
  String get gitUiRevertInReviewedOrder => 'Powrót w porządku przeglądowym';

  @override
  String get gitUiCherryPickInReviewedOrder =>
      'Wybór wiśniowy w porządku przeglądowym';

  @override
  String get gitUiReturnToFiles => 'Powrót do plików';

  @override
  String get gitUiGit => 'Git';

  @override
  String get gitUiCommit => 'Zatwierdź';

  @override
  String get gitUiBackToCommit => 'Powrót do zobowiązania';

  @override
  String get gitUiSelectAChangeToReview => 'Wybierz zmianę do przeglądu';

  @override
  String get gitUiLoadingBranch => 'Wczytywanie gałęzi...';

  @override
  String get gitUiBranchUnavailable => 'Oddział niedostępny';

  @override
  String get gitUiUnbornHEAD => 'HEAD bez commitów';

  @override
  String gitUiDetachedHEADRevision(String revision) {
    return 'Odłączony HEAD · $revision';
  }

  @override
  String get gitUiContinueAction => 'Kontynuuj';

  @override
  String get gitUiPick => 'Zachowaj';

  @override
  String get gitUiReword => 'Zmień opis';

  @override
  String get gitUiEdit => 'Edytuj';

  @override
  String get gitUiSquash => 'Połącz';

  @override
  String get gitUiFixup => 'Połącz bez opisu';

  @override
  String get gitUiDrop => 'Pomiń';

  @override
  String get gitUiAbort => 'Przerwij';

  @override
  String get gitUiSkip => 'Pomiń';

  @override
  String get gitUiQuit => 'Zakończ operację';

  @override
  String get gitUiSoft => 'Miękki';

  @override
  String get gitUiMixed => 'Mieszany';

  @override
  String get gitUiHard => 'Twardy';

  @override
  String get gitUiKeep => 'Zachowaj';

  @override
  String get gitUiCreate => 'Utwórz';

  @override
  String get gitUiApplyStash => 'Zastosuj schowek';

  @override
  String get gitUiPopStash => 'Zastosuj schowek i usuń po sukcesie';

  @override
  String get gitUiDropStashAction => 'Usuń schowek';

  @override
  String get gitUiEditedResult => 'Zmodyfikowany wynik';

  @override
  String get gitUiLeftContent => 'Zawartość w lewo';

  @override
  String get gitUiRightContent => 'Treść prawa';

  @override
  String get gitUiDeletePath => 'Usuń ścieżkę';

  @override
  String get gitUiSubmoduleCommit => 'Zobowiązanie podmodułowe';

  @override
  String get gitUiPresentContent => 'Dostępna zawartość';

  @override
  String get gitUiAbsentContent => 'Nieobecny';

  @override
  String get gitUiBinaryContent => 'Zawartość domyślna';

  @override
  String get gitUiTooLargeContent => 'Zawartość przekracza limit wyświetlania';

  @override
  String get gitUiUnavailableContent => 'Niedostępna zawartość';

  @override
  String get gitUiGitlinkContent => 'Wskaźnik podmodułowy';

  @override
  String get gitUiSymlinkContent => 'Odnośnik symboliczny';

  @override
  String get gitUiNoOperation => 'Brak operacji';

  @override
  String get gitUiCherryPickOperation => 'Wybierz commit';

  @override
  String get gitUiRevertOperation => 'Odwróć commit';

  @override
  String get gitUiApplyMailboxOperation => 'Naklej plastry';

  @override
  String get gitUiSquashOperation => 'Squash combination';

  @override
  String get gitUiUnmergedOperation => 'Niezanumerowany indeks';

  @override
  String get gitUiWaitingForPromptPhase => 'Czekanie na odpowiedź';

  @override
  String get gitUiStoppedPhase => 'Zatrzymany do przeglądu';

  @override
  String get gitUiCompletedPhase => 'Ukończono';

  @override
  String get gitUiFailedPhase => 'Niepowodzenie';

  @override
  String get gitUiCancelledPhase => 'Anulowano';

  @override
  String get gitUiUncertainPhase => 'Wynik wymaga pojednania';

  @override
  String gitUiStageVersion(String stage) {
    return 'Etap konfliktu $stage';
  }

  @override
  String get gitUiGitMergePreview => 'Podgląd połączenia Git';

  @override
  String get gitUiNormalizedWorking => 'Drzewo robocze · Git znormalizowana';

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
  String get gitUiUtf8Bom => 'UTF-8 ze znakiem porządkowym (BOM)';

  @override
  String get gitUiUtf8NoBom => 'UTF-8 bez znaku porządkowego (BOM)';

  @override
  String get gitUiAddsBom =>
      'Edycja dodaje znak porządkowy UTF-8 (BOM) na początku pliku.';

  @override
  String get gitUiRemovesBom =>
      'Edycja ta usuwa znak porządkowy UTF-8 (BOM) od początku pliku.';

  @override
  String get gitUiNoLineTerminators => 'Brak końcówek linii';

  @override
  String gitUiLineEndings(String format) {
    return 'Zakończenia wierszy $format';
  }

  @override
  String gitUiMixedLineEndings(String formats) {
    return 'Zakończenie mieszane linii ($formats)';
  }

  @override
  String gitUiNoFinalLf(String format) {
    return '$format · brak ostatecznego LF';
  }

  @override
  String gitUiLineEndingChange(String before, String after) {
    return 'Zmiana formatu zakończenia linii z $before do $after. Tekst schowka może używać różnych zakończeń linii od oryginalnego pliku.';
  }

  @override
  String get gitUiGitFailure =>
      'Operacja Git nie powiodła się. Przejrzyj poniższą diagnozę.';

  @override
  String get gitUiAbortInline => 'Przerwij';

  @override
  String get gitUiSkipInline => 'Pomiń';

  @override
  String get gitUiQuitInline => 'rzucić';

  @override
  String get gitUiMergeInline => 'Scal';

  @override
  String get gitUiRebaseInline => 'Przebazuj';

  @override
  String get gitUiCherryPickInline => 'Wybierz commit';

  @override
  String get gitUiRevertInline => 'Odwróć commit';

  @override
  String get gitUiApplyMailboxInline => 'aplikuj skrzynkę pocztową';

  @override
  String get gitUiSquashInline => 'Połącz';

  @override
  String get gitUiUnmergedInline => 'niezanurzone';

  @override
  String get gitHostFetch => 'Pobierz';

  @override
  String get gitHostRefreshGitStatus => 'Odśwież status Git';

  @override
  String get gitHostCommitStaged => 'Zaangażowanie wprowadzone';

  @override
  String get gitHostGitBranches => 'Oddziały Git';

  @override
  String get gitHostReviewPush => 'Przesunięcie przeglądu';

  @override
  String get gitHostGit => 'Git';

  @override
  String get gitHostGitOperationsApplyToThisEntireRepositoryAndMay =>
      'Operacje Git mają zastosowanie do całego repozytorium i mogą wykonać swoje skonfigurowane haki, filtry, narzędzia poświadczające i podpisujące.';

  @override
  String get gitHostContentUnavailable => 'Zawartość niedostępna';

  @override
  String get gitHostInitializeRepository => 'Zainicjuj repozytorium';

  @override
  String get gitHostCloneRepository => 'Klonuj repozytorium';

  @override
  String get gitHostInitializeHere => 'Rozpocznijmy tutaj...';

  @override
  String get gitHostCloneRepository2 => 'Klonuj repozytorium…';

  @override
  String get gitHostGitLog => 'Dziennik Git';

  @override
  String get gitUiAbsentPlaceholder => '(zgoda)';

  @override
  String get gitUiUnborn => 'nienazwany';

  @override
  String gitUiRebasedHistoryRevision(String revision) {
    return 'Przebazowana historia · $revision';
  }

  @override
  String gitUiCurrentHistoryRevision(String revision) {
    return 'Bieżąca historia · $revision';
  }

  @override
  String gitUiReplayedCommitRevision(String revision) {
    return 'Ponownie zastosowany commit · $revision';
  }

  @override
  String gitUiIncomingContentRevision(String revision) {
    return 'Treść przychodząca · $revision';
  }

  @override
  String get gitUiContentConflict => 'Konflikt treści';

  @override
  String get gitUiSubmoduleConflict => 'Konflikt podmodułowy';

  @override
  String get gitUiSymlinkConflict => 'Konflikty symboliczne';

  @override
  String get gitUiAddAddConflict => 'Dodano z obu stron';

  @override
  String get gitUiModifyDeleteConflict =>
      'Zmodyfikowana/ usunięta lub przemianowana na zmianę nazwy/umyta';

  @override
  String gitUiConflictIdentity(String path, String kind) {
    return '$path · $kind';
  }

  @override
  String get gitUiDiscardUnsavedIndexDraft =>
      'Odrzucić niezapisany szkic indeksu?';

  @override
  String get gitUiClosingTheIndexEditorDiscardsOnlyItsDraft =>
      'Zamknięcie edytora indeksu odrzuca tylko jego szkic. Indeks i plik roboczy pozostają bez zmian.';

  @override
  String get gitUiDiscardIndexDraft => 'Odrzuć szkic indeksu';

  @override
  String get gitUiDiscardUnsavedConflictDraft =>
      'Odrzucić niezapisany wynik konfliktu?';

  @override
  String get gitUiClosingTheConflictEditorDiscardsOnlyItsDraft =>
      'Zamknięcie edytora konfliktów odrzuca tylko niezapisaną wersję roboczą wyniku. Zapisana zawartość robocza i indeks pozostają bez zmian.';

  @override
  String get gitUiDiscardConflictDraft => 'Odrzuć wersję roboczą konfliktu';

  @override
  String get gitUiOpenCurrentFile => 'Otwórz bieżący plik';

  @override
  String get gitUiPreviousSearchMatch => 'Poprzedni wynik wyszukiwania';

  @override
  String get gitUiNextSearchMatch => 'Następny wynik wyszukiwania';

  @override
  String gitUiSearchMatchPosition(String current, String count) {
    return 'Wynik $current z $count';
  }

  @override
  String gitUiSearchResultsLimited(String count) {
    return 'Wyświetlono pierwsze $count wyników. Zawęź wyszukiwanie, aby przejrzeć więcej.';
  }

  @override
  String get gitUiRevealRevisionWithoutFilters => 'Pokaż rewizję bez filtrów';

  @override
  String get gitUiRestoreHistoryFilters => 'Przywróć filtry historii';

  @override
  String get gitUiShowAllAffectedFiles => 'Pokaż wszystkie objęte pliki';

  @override
  String get gitUiGraphLanes => 'Tory grafu';

  @override
  String gitUiRebaseArg0OntoArg1(String arg0, String arg1) {
    return 'Przenieś bazę $arg0 na $arg1';
  }

  @override
  String get gitUiChangedLine => 'Zmieniony wiersz';

  @override
  String get gitUiCopyHeadRegionIntoIndexDraft =>
      'Kopiuj obszar HEAD do wersji roboczej indeksu';

  @override
  String get gitUiCopyWorkingRegionIntoIndexDraft =>
      'Kopiuj obszar roboczy do wersji roboczej indeksu';

  @override
  String get gitUiUpdatingConflictRegions =>
      'Aktualizowanie obszarów konfliktu';

  @override
  String gitUiRemainingConflictMarkers(String count) {
    return 'Obszary wyniku ze znacznikami konfliktu: $count';
  }

  @override
  String get gitUiIgnoreLeftRegion => 'Ignoruj lewą propozycję';

  @override
  String get gitUiIgnoreRightRegion => 'Ignoruj prawą propozycję';

  @override
  String get gitUiIndexAppliedNewerDraftPreserved =>
      'Przesłaną wersję roboczą zapisano w indeksie. Nowszy tekst pozostaje w tym edytorze. Przed jego zastosowaniem wczytaj ponownie i sprawdź bieżące wersje.';

  @override
  String get gitUiNewerConflictDraftRetained =>
      'Przesłany wynik został zapisany. Nowsza wersja robocza wyniku nadal nie jest zapisana.';

  @override
  String get gitUiNoFileHistoryForThisPathAndRevision =>
      'Brak historii pliku dla tej ścieżki i rewizji.';

  @override
  String get gitUiReviewSavedIndexAndKeepDraft =>
      'Przejrzyj zapisany indeks i zachowaj wersję roboczą';

  @override
  String get gitUiIndexSourcesChangedSinceApply =>
      'Zapisany indeks lub jego źródła uległy zmianie. Nowsza wersja robocza została zachowana; przed jej zastosowaniem przejrzyj te zmiany osobno.';
}
