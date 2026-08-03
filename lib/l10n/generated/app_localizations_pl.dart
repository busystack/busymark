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
  String get copyPath => 'Kopiuj ścieżkę';

  @override
  String get create => 'Utwórz';

  @override
  String get creating => 'Tworzenie...';

  @override
  String get cut => 'Wytnij';

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
  String get lightTheme => 'Jasny';

  @override
  String get mainMenu => 'Menu główne';

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
  String get preview => 'Podgląd';

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
  String get shortcutNewDocument => 'Nowy dokument';

  @override
  String get shortcutNewDocumentDescription =>
      'Utwórz nowy niezapisany dokument Markdown';

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
  String get shortcutMarkdownAndHtmlDescription =>
      'Otwórz dokumentację Markdown i HTML';

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
    return 'Usuń „$topic” z wybranej instancji pomocy. Plik tematu zostanie zachowany.';
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
  String get sourceSearchInvalidRegex => 'Nieprawidłowe wyrażenie regularne';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Duży plik: podświetlanie i zwijanie są wstrzymane';

  @override
  String get noPreview => 'Brak podglądu';

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
      'Moduł Writerside nie ma drzewa instancji pomocy.';

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
  String get gitHistory => 'Historia';

  @override
  String get gitBranches => 'Gałęzie';

  @override
  String get gitBranchActions => 'Działania na gałęziach';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Zatwierdź';

  @override
  String get gitSelectForCommit => 'Wybierz do zatwierdzenia';

  @override
  String get gitRemoveFromCommit => 'Wyklucz z zatwierdzenia';

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
      'Przed zatwierdzeniem wybierz co najmniej jeden plik.';

  @override
  String get gitCommitMessageRequired => 'Wprowadź komunikat zatwierdzenia.';

  @override
  String get gitCreateBranch => 'Utwórz gałąź';

  @override
  String get gitNewBranch => '+ Nowa gałąź';

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
  String get gitUnsavedChangesBanner =>
      'Niezapisane zmiany w edytorze nie zostaną uwzględnione, dopóki ich nie zapiszesz.';

  @override
  String get gitConfirmDiscardTitle => 'Odrzucić zmiany Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wybrane śledzone pliki zostaną przywrócone z Git.',
      many: 'Wybrane śledzone pliki zostaną przywrócone z Git.',
      few: 'Wybrane śledzone pliki zostaną przywrócone z Git.',
      one: 'Wybrany śledzony plik zostanie przywrócony z Git.',
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
  String get gitProjectHistory => 'Projekt';

  @override
  String get gitFileHistory => 'Bieżący plik';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get gitFileActions => 'Działania na pliku';

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
  String get gitErrorDiverged =>
      'Gałęzie się rozeszły. Rozwiąż scalanie lub wykonaj rebase poza tą wersją BusyMark.';

  @override
  String get gitErrorAuthentication =>
      'Uwierzytelnianie Git nie powiodło się. W pakiecie snap repozytoria SSH mogą wymagać podłączenia interfejsu ssh-keys.';

  @override
  String get gitErrorNetwork => 'Operacja sieciowa Git nie powiodła się.';

  @override
  String get gitErrorConflict => 'Git zgłosił nierozwiązane konflikty.';

  @override
  String get gitErrorCommandFailed => 'Polecenie Git nie powiodło się.';

  @override
  String get markdownAndHtml => 'Markdown i HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Bloki Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Struktury blokowe obsługiwane w źródle Markdown i podglądzie.';

  @override
  String get markdownHtmlInlineFormatting => 'Markdown w tekście';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Formatowanie w akapitach, elementach list i komórkach tabel.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Surowe bloki HTML';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Bezpieczne blokowe tagi HTML renderowane przez widżety podglądu BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Surowe tagi HTML w tekście';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Bezpieczne tagi HTML w tekście renderowane bez pokazywania dosłownych tagów.';

  @override
  String get markdownHtmlSafety => 'Reguły bezpieczeństwa';

  @override
  String get markdownHtmlSafetyDescription =>
      'Surowy HTML jest analizowany i oczyszczany przed renderowaniem podglądu.';

  @override
  String get markdownHtmlHeadings => 'Nagłówki';

  @override
  String get markdownHtmlParagraphs => 'Akapity';

  @override
  String get markdownHtmlLists => 'Listy';

  @override
  String get markdownHtmlHtmlContainers => 'Kontenery';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Bloki tekstowe';

  @override
  String get markdownHtmlHtmlFigures => 'Figury i obrazy';

  @override
  String get markdownHtmlHtmlPreformatted => 'Kod preformatowany';

  @override
  String get markdownHtmlHtmlDisclosure => 'Bloki rozwijane';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Listy opisów';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Tagi formatowania';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Tagi kodu w tekście';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Semantyczne tagi tekstu';

  @override
  String get markdownHtmlSanitizedPreview => 'Oczyszczony podgląd';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Dozwolony HTML jest konwertowany na bloki podglądu BusyMark, a nie renderowany w przeglądarce.';

  @override
  String get markdownHtmlSourcePreserved => 'Źródło jest zachowane';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Nieedytowany surowy HTML jest zapisywany dokładnie jako tekst źródłowy.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown wewnątrz HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Znaczniki Markdown wewnątrz surowego HTML są wyświetlane jako tekst dosłowny.';

  @override
  String get markdownHtmlBlockedContent => 'Zablokowana aktywna zawartość';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Skrypty, style, ramki, formularze, SVG, MathML, zdarzenia i niebezpieczne atrybuty są blokowane.';

  @override
  String get markdownHtmlSafeUrls => 'Tylko bezpieczne adresy URL';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Łącza dopuszczają http, https, mailto, tel, względne adresy URL i fragmenty; niebezpieczne schematy są blokowane.';
}
