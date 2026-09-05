// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

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
  String get commandPalette => 'Paleta poleceń';

  @override
  String get commandPaletteHint => 'Wpisz polecenie';

  @override
  String get commandPaletteEmpty => 'Brak pasujących poleceń';

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
  String get pasteWithoutFormatting => 'Wklej bez formatowania';

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
      'Pokaż ten wykaz skrótów klawiaturowych';

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
  String get editorFontSize => 'Rozmiar czcionki edytora';

  @override
  String get validateOnEdit => 'Sprawdzaj poprawność podczas edycji';

  @override
  String get clearRecentWorkspaces =>
      'Wyczyść listę ostatnich obszarów roboczych';

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
  String get newSiblingTopic => 'Nowy temat równorzędny';

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
  String get reviewUsages => 'Przejrzyj użycia';

  @override
  String get deleteTopicFile => 'Usuń plik tematu';

  @override
  String get removeAction => 'Usuń';

  @override
  String topicRemovalSummary(String topic) {
    return 'Usuń „$topic” z wybranej instancji. Plik tematu zostanie zachowany.';
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
  String get topicIsStartPageRemovalWarning =>
      'Ten temat jest używany jako strona początkowa instancji. Przejrzyj jego użycia i przypisz inną stronę początkową przed kontynuowaniem.';

  @override
  String topicUsagesCount(int count) {
    return 'Użycia ($count)';
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
  String get topicUsageStartPages => 'Strony początkowe';

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
  String get setRedirectTo => 'Ustaw przekierowanie do';

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
  String get sourceSearchCaseSensitive => 'Uwzględniaj wielkość liter';

  @override
  String get sourceSearchWholeWord => 'Całe słowo';

  @override
  String get sourceSearchRegex => 'Wyrażenie regularne';

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
  String get sourceSearchInvalidRegex => 'Nieprawidłowe wyrażenie regularne';

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
    return 'Nie można usunąć tematu początkowego $topic. Najpierw wybierz inną stronę początkową.';
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
          'Wszystkie oznaczone i nieoznaczone zmiany w wybranych śledzonych plikach zostaną przywrócone do HEAD.',
      one:
          'Wszystkie oznaczone i nieoznaczone zmiany w wybranym śledzonym pliku zostaną przywrócone do HEAD.',
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
  String get generateOrUpdateMarkdownToc => 'Wygeneruj/zaktualizuj spis treści';

  @override
  String get markdownTocTitle => 'Spis treści';

  @override
  String markdownTocUpdated(int count) {
    return 'Zaktualizowano spis treści zawierający $count pozycji.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Przed wygenerowaniem spisu treści dodaj co najmniej jeden nagłówek sekcji.';

  @override
  String get markdownTocMalformedMarkers =>
      'Znaczniki spisu treści BusyMark są nieobecne, powielone lub ułożone w niewłaściwej kolejności.';

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
