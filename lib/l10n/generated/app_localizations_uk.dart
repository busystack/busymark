// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Редактор файлів Markdown і проєктів документації, сумісних із Writerside.';

  @override
  String get aboutBusyMark => 'Про BusyMark';

  @override
  String get aboutTagline => 'Редактор Markdown і Writerside';

  @override
  String get aboutLicenseLabel => 'Ліцензія';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Вебсайт';

  @override
  String get aboutSourceCode => 'Вихідний код';

  @override
  String get reportIssue => 'Повідомити про проблему';

  @override
  String get feedbackCategory => 'Категорія';

  @override
  String get feedbackChooseCategory => 'Виберіть категорію';

  @override
  String get feedbackCategoryProblem => 'Проблема або помилка';

  @override
  String get feedbackCategoryFeature => 'Запит на функцію';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Проблема конфіденційності або безпеки';

  @override
  String get feedbackCategoryUsability => 'Проблема зручності використання';

  @override
  String get feedbackCategoryOther => 'Інше';

  @override
  String get feedbackSubject => 'Тема';

  @override
  String get feedbackMessage => 'Докладне повідомлення';

  @override
  String get feedbackReplyEmail => 'Ел. пошта для відповіді (необов’язково)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Додати технічні відомості';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Якщо цей параметр увімкнено, додаються лише версія операційної системи Linux і мова та регіон програми BusyMark. Журнали, файли, дані облікового запису й інші діагностичні відомості не додаються.';

  @override
  String get feedbackSubmit => 'Надіслати';

  @override
  String get feedbackSubmitting => 'Надсилання…';

  @override
  String get feedbackCategoryRequired => 'Виберіть категорію.';

  @override
  String get feedbackSubjectLength => 'Тема має містити від 3 до 120 символів.';

  @override
  String get feedbackMessageLength =>
      'Повідомлення має містити від 10 до 5000 символів.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Введіть дійсну адресу електронної пошти або залиште поле порожнім.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark не вдалося підключитися. Перевірте інтернет-з’єднання та повторіть спробу.';

  @override
  String get feedbackTimeoutFailure =>
      'Час очікування запиту минув. Повторіть спробу.';

  @override
  String get feedbackRateLimitedFailure =>
      'Із цього з’єднання надіслано забагато звітів. Зачекайте та повторіть спробу.';

  @override
  String get feedbackRejectedFailure =>
      'Сервер відхилив повідомлення. Перевірте поля форми та повторіть спробу.';

  @override
  String get feedbackServerFailure =>
      'Сервер не зміг прийняти звіт. Повторіть спробу пізніше.';

  @override
  String feedbackSuccess(String id) {
    return 'Відгук надіслано. Ідентифікатор звернення: $id';
  }

  @override
  String get advanced => 'Додатково';

  @override
  String get addToGit => 'Додати до Git';

  @override
  String get appearance => 'Зовнішній вигляд';

  @override
  String get apply => 'Застосувати';

  @override
  String get back => 'Назад';

  @override
  String get bottomLeft => 'Внизу ліворуч';

  @override
  String get bottomRight => 'Внизу праворуч';

  @override
  String get cancel => 'Скасувати';

  @override
  String get choose => 'Вибрати';

  @override
  String get chooseLocation => 'Вибрати розташування';

  @override
  String get copy => 'Копіювати';

  @override
  String get copyName => 'Копіювати назву';

  @override
  String get copyFileName => 'Копіювати назву файлу';

  @override
  String get copyPath => 'Копіювати шлях';

  @override
  String get create => 'Створити';

  @override
  String get creating => 'Створення…';

  @override
  String get cut => 'Вирізати';

  @override
  String get promoteSection => 'Підвищити рівень розділу';

  @override
  String get demoteSection => 'Знизити рівень розділу';

  @override
  String get moveSectionUp => 'Перемістити розділ вище';

  @override
  String get moveSectionDown => 'Перемістити розділ нижче';

  @override
  String get confirmDeleteSectionTitle => 'Видалити розділ?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Видалити розділ «$name» з усім його вмістом? Цю дію не можна скасувати.';
  }

  @override
  String get darkTheme => 'Темна';

  @override
  String get delete => 'Видалити';

  @override
  String get discard => 'Відкинути';

  @override
  String get editor => 'Редактор';

  @override
  String get file => 'Файл';

  @override
  String get fileHistory => 'Історія файлу';

  @override
  String get folder => 'Папка';

  @override
  String get insert => 'Вставити';

  @override
  String get keyboardShortcuts => 'Комбінації клавіш';

  @override
  String get commandPalette => 'Палітра команд';

  @override
  String get commandPaletteHint => 'Введіть команду';

  @override
  String get commandPaletteEmpty => 'Немає відповідних команд';

  @override
  String get commandUnavailableInContext =>
      'Ця команда недоступна в поточному контексті.';

  @override
  String get lightTheme => 'Світла';

  @override
  String get mainMenu => 'Головне меню';

  @override
  String get fullScreen => 'Повноекранний режим';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Відкрити';

  @override
  String get openInFiles => 'Відкрити у Файлах';

  @override
  String get pathActions => 'Дії зі шляхом';

  @override
  String get outline => 'Структура';

  @override
  String get overwrite => 'Перезаписати';

  @override
  String get paste => 'Вставити';

  @override
  String get pasteWithoutFormatting => 'Вставити без форматування';

  @override
  String get reading => 'Режим читання';

  @override
  String get removeFromRecent => 'Вилучити з нещодавніх';

  @override
  String get recent => 'Останні';

  @override
  String get redo => 'Повторити';

  @override
  String get save => 'Зберегти';

  @override
  String get search => 'Пошук';

  @override
  String get selectAll => 'Вибрати все';

  @override
  String get settings => 'Налаштування';

  @override
  String get source => 'Вихідний текст';

  @override
  String get split => 'Розділений перегляд';

  @override
  String get systemTheme => 'Системна';

  @override
  String get theme => 'Тема';

  @override
  String get appLanguage => 'Мова';

  @override
  String get systemLanguage => 'Системна';

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
  String get toggleSidebar => 'Бічна панель';

  @override
  String get topLeft => 'Вгорі ліворуч';

  @override
  String get topRight => 'Вгорі праворуч';

  @override
  String get undo => 'Скасувати';

  @override
  String get validate => 'Перевірити';

  @override
  String get validation => 'Перевірка';

  @override
  String get viewMode => 'Режим перегляду';

  @override
  String get welcome => 'Ласкаво просимо';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Зображення';

  @override
  String get openMarkdownFile => 'Відкрити файл Markdown';

  @override
  String get markdownFileExtensions => '.md або .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Відкрити папку або проєкт Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Папка Markdown або проєкт, сумісний із Writerside';

  @override
  String get noOpenFile => 'Немає відкритого файлу';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Видалити вибраний елемент у розділі «Файли» або вилучити вибрану тему зі змісту';

  @override
  String get shortcutGroupGeneral => 'Загальні';

  @override
  String get shortcutNewDocument => 'Створити';

  @override
  String get shortcutNewDocumentDescription =>
      'Створити файл Markdown або проєкт Writerside';

  @override
  String get shortcutOpenDescription =>
      'Відкрити файл Markdown, папку або проєкт Writerside';

  @override
  String get shortcutSaveDescription => 'Зберегти поточний документ';

  @override
  String get shortcutSearchDescription =>
      'Шукати в поточному робочому просторі';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Показати довідку з комбінацій клавіш';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Відкрити довідку з Markdown і HTML';

  @override
  String get shortcutSettingsDescription => 'Відкрити налаштування BusyMark';

  @override
  String get shortcutNextTab => 'Наступна вкладка';

  @override
  String get shortcutNextTabDescription =>
      'Перейти до наступної відкритої вкладки';

  @override
  String get shortcutPreviousTab => 'Попередня вкладка';

  @override
  String get shortcutPreviousTabDescription =>
      'Перейти до попередньої відкритої вкладки';

  @override
  String get shortcutCloseTab => 'Закрити вкладку';

  @override
  String get shortcutCloseTabDescription => 'Закрити активну вкладку';

  @override
  String get shortcutCloseAllTabs => 'Закрити всі вкладки';

  @override
  String get shortcutCloseAllTabsDescription => 'Закрити всі відкриті вкладки';

  @override
  String get shortcutGroupTextEditing => 'Редагування тексту';

  @override
  String get shortcutSelectAllDescription =>
      'У режимі вихідного тексту виділити весь текст; у режимі редактора натиснути двічі, щоб виділити всі блоки';

  @override
  String get shortcutCutDescription => 'Вирізати виділений текст';

  @override
  String get shortcutCopyDescription => 'Копіювати виділений текст';

  @override
  String get shortcutPasteDescription => 'Вставити з буфера обміну';

  @override
  String get shortcutPastePlainTextDescription =>
      'Вставити текст із буфера обміну без форматування';

  @override
  String get shortcutUndoDescription => 'Скасувати останню зміну';

  @override
  String get shortcutRedoDescription => 'Повторити останню скасовану зміну';

  @override
  String get shortcutInsertIndentation => 'Вставити відступ';

  @override
  String get shortcutInsertIndentationDescription =>
      'Вставити відступ у позицію курсора';

  @override
  String get shortcutOutdentSource => 'Зменшити відступ у вихідному тексті';

  @override
  String get shortcutOutdentSourceDescription =>
      'Прибрати один рівень відступу в режимі вихідного тексту';

  @override
  String get shortcutEscape => 'Закрити пошук або зняти виділення блоків';

  @override
  String get shortcutEscapeDescription =>
      'Закрити пошук у робочому просторі або зняти виділення блоків у режимі редактора';

  @override
  String get shortcutGroupFormatting => 'Форматування';

  @override
  String get shortcutBoldDescription =>
      'Увімкнути або вимкнути жирний шрифт для виділеного тексту';

  @override
  String get shortcutItalicDescription =>
      'Увімкнути або вимкнути курсив для виділеного тексту';

  @override
  String get shortcutUnderlineDescription =>
      'Увімкнути або вимкнути підкреслення для виділеного тексту';

  @override
  String get shortcutLinkDescription => 'Вставити або відредагувати посилання';

  @override
  String get shortcutInlineCodeDescription =>
      'Увімкнути або вимкнути вбудований код для виділеного тексту';

  @override
  String get shortcutStrikethroughDescription =>
      'Увімкнути або вимкнути закреслення для виділеного тексту';

  @override
  String get shortcutGroupBlocks => 'Блоки';

  @override
  String get shortcutParagraphDescription => 'Зробити поточний блок абзацом';

  @override
  String get shortcutHeading1Description =>
      'Зробити поточний блок заголовком 1';

  @override
  String get shortcutHeading2Description =>
      'Зробити поточний блок заголовком 2';

  @override
  String get shortcutHeading3Description =>
      'Зробити поточний блок заголовком 3';

  @override
  String get shortcutHeading4Description =>
      'Зробити поточний блок заголовком 4';

  @override
  String get shortcutHeading5Description =>
      'Зробити поточний блок заголовком 5';

  @override
  String get shortcutHeading6Description =>
      'Зробити поточний блок заголовком 6';

  @override
  String get shortcutGroupLists => 'Списки';

  @override
  String get numberedList => 'Нумерований список';

  @override
  String get shortcutNumberedListDescription =>
      'Увімкнути або вимкнути форматування нумерованого списку';

  @override
  String get bulletedList => 'Маркований список';

  @override
  String get shortcutBulletedListDescription =>
      'Увімкнути або вимкнути форматування маркованого списку';

  @override
  String get checklist => 'Контрольний список';

  @override
  String get shortcutChecklistDescription =>
      'Увімкнути або вимкнути форматування контрольного списку';

  @override
  String get shortcutGroupSidebar => 'Бічна панель';

  @override
  String get sidebarViewMenu => 'Подання бічної панелі';

  @override
  String get createMarkdownFile => 'Створити файл Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Створити незбережений локальний документ Markdown';

  @override
  String get createWritersideProject => 'Створити проєкт Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Створити локальний проєкт, сумісний із Writerside';

  @override
  String get defaultProjectName => 'Документація';

  @override
  String get defaultInstanceName => 'Посібник користувача';

  @override
  String get defaultStartTopicTitle => 'Початок роботи';

  @override
  String get projectName => 'Назва проєкту';

  @override
  String get directoryName => 'Назва каталогу';

  @override
  String get instanceName => 'Назва екземпляра';

  @override
  String get instanceId => 'Ідентифікатор екземпляра';

  @override
  String get startTopicTitle => 'Назва початкової теми';

  @override
  String get location => 'Розташування';

  @override
  String get projectNameRequired => 'Потрібно вказати назву проєкту.';

  @override
  String get directoryNameRequired => 'Потрібно вказати назву каталогу.';

  @override
  String get useSingleSafeDirectoryName =>
      'Використовуйте одну допустиму назву каталогу.';

  @override
  String get useLowercaseIdentifier =>
      'Використовуйте ідентифікатор у нижньому регістрі з літерами, цифрами, знаками підкреслення або дефісами.';

  @override
  String get startTopicTitleRequired =>
      'Потрібно вказати назву початкової теми.';

  @override
  String get createWritersideProjectFailed =>
      'Не вдалося створити проєкт Writerside.';

  @override
  String get settingsTitle => 'Налаштування BusyMark';

  @override
  String get autoSave => 'Автозбереження';

  @override
  String get autoSaveDescription =>
      'Автоматично зберігати зміни у файлах після короткої паузи в редагуванні.';

  @override
  String get wordWrap => 'Перенесення рядків';

  @override
  String get editorFontSize => 'Розмір шрифту редактора';

  @override
  String get validateOnEdit => 'Перевіряти під час редагування';

  @override
  String get clearRecentWorkspaces =>
      'Очистити список останніх робочих областей';

  @override
  String get editingButtonsPosition => 'Розташування кнопок редагування';

  @override
  String get editingButtonsPositionDescription =>
      'Виберіть, де відображатимуться плаваючі кнопки редагування WYSIWYG.';

  @override
  String get editingButtonsDirection => 'Орієнтація кнопок редагування';

  @override
  String get editingButtonsDirectionDescription =>
      'Виберіть, як розташувати плаваючі кнопки редагування WYSIWYG: горизонтально чи вертикально.';

  @override
  String get horizontal => 'Горизонтально';

  @override
  String get vertical => 'Вертикально';

  @override
  String get privacy => 'Конфіденційність';

  @override
  String get allowRemoteImages => 'Завантажувати віддалені зображення';

  @override
  String get allowRemoteImagesDescription =>
      'Дозволяти завантаження зображень у попередньому перегляді Markdown і редакторі з URL-адрес http та https.';

  @override
  String get clearRemoteImagePermissions =>
      'Очистити дозволи для віддалених зображень';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Забути робочі області, яким було дозволено завантажувати віддалені зображення.';

  @override
  String get clearGitWorkspaceTrust =>
      'Очистити список довірених робочих областей Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Запитувати перед увімкненням функцій Git для раніше довірених робочих областей.';

  @override
  String get settingsWindowSectionTitle => 'Вікно';

  @override
  String get settingsReopenWorkspaceOnStartupTitle =>
      'Відкривати попередній робочий простір під час запуску';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'Відкривати робочий простір і вкладки попереднього сеансу під час запуску BusyMark.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Підтверджувати закриття за наявності незбережених змін';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Запитувати перед закриттям BusyMark, якщо документи мають незбережені зміни.';

  @override
  String get closeUnsavedChangesTitle => 'Незбережені зміни';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'Цей документ має незбережені зміни. Зберегти зміни перед закриттям BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count документа має незбережені зміни. Зберегти зміни перед закриттям BusyMark?',
      many:
          '$count документів мають незбережені зміни. Зберегти зміни перед закриттям BusyMark?',
      few:
          '$count документи мають незбережені зміни. Зберегти зміни перед закриттям BusyMark?',
      one:
          '$count документ має незбережені зміни. Зберегти зміни перед закриттям BusyMark?',
      zero: 'Зберегти зміни перед закриттям BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Скасувати';

  @override
  String get closeUnsavedChangesDiscard => 'Відкинути';

  @override
  String get closeUnsavedChangesSave => 'Зберегти';

  @override
  String get currentFile => 'поточний файл';

  @override
  String get unsavedChanges => 'Незбережені зміни';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName містить незбережені зміни. Зберегти їх перед продовженням?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count документів мають незбережені зміни. Збережіть кожен перед продовженням.',
      one:
          '1 документ має незбережені зміни. Збережіть його перед продовженням.',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'Файл змінено на диску';

  @override
  String get fileChangedOnDiskMessage =>
      'Цей файл змінився на диску з моменту відкриття. Перезаписати?';

  @override
  String get untitledMarkdownFileName => 'Без назви.md';

  @override
  String get unorderedList => 'Маркований список';

  @override
  String get orderedList => 'Упорядкований список';

  @override
  String get taskList => 'Список завдань';

  @override
  String get toggleTaskChecked => 'Позначити або зняти позначку із завдання';

  @override
  String get indentListItem => 'Збільшити відступ елемента списку';

  @override
  String get outdentListItem => 'Зменшити відступ елемента списку';

  @override
  String get blockquote => 'Блок цитати';

  @override
  String get codeBlock => 'Блок коду';

  @override
  String get codeBlockLanguage => 'Мова блоку коду';

  @override
  String get image => 'Зображення';

  @override
  String get video => 'Відео';

  @override
  String get openVideo => 'Відтворити відео';

  @override
  String get pauseVideo => 'Призупинити відео';

  @override
  String get videoUnavailable => 'Відео недоступне';

  @override
  String get videoPreview => 'Попередній перегляд відео';

  @override
  String get diagnosticWritersideVideoMissingSource =>
      'У відео відсутній атрибут src.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'Непідтримуване джерело відео: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return 'Відеофайл не існує: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return 'Зображення попереднього перегляду відео не існує: $preview';
  }

  @override
  String get inlineImage => 'Вбудоване зображення';

  @override
  String get table => 'Таблиця';

  @override
  String get htmlBlock => 'Блок HTML';

  @override
  String get htmlContentDefault => 'Вміст HTML';

  @override
  String get shortcutHtmlBlockDescription =>
      'Вставити або редагувати блок HTML';

  @override
  String get renderedHtml => 'Відтворений HTML';

  @override
  String get editHtml => 'Редагувати HTML';

  @override
  String get htmlSource => 'Вихідний HTML';

  @override
  String get thematicBreak => 'Горизонтальна лінія';

  @override
  String get bold => 'Жирний';

  @override
  String get italic => 'Курсив';

  @override
  String get underline => 'Підкреслення';

  @override
  String get strikethrough => 'Закреслення';

  @override
  String get inlineCode => 'Вбудований код';

  @override
  String get link => 'Посилання';

  @override
  String get hardLineBreak => 'Примусовий розрив рядка';

  @override
  String get textStyle => 'Стиль тексту';

  @override
  String get paragraph => 'Абзац';

  @override
  String get heading1 => 'Заголовок 1';

  @override
  String get heading2 => 'Заголовок 2';

  @override
  String get heading3 => 'Заголовок 3';

  @override
  String get heading4 => 'Заголовок 4';

  @override
  String get heading5 => 'Заголовок 5';

  @override
  String get heading6 => 'Заголовок 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => 'Видалити таблицю';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Стовпець $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Вставити стовпець зліва';

  @override
  String get insertColumnRight => 'Вставити стовпець справа';

  @override
  String get deleteColumn => 'Видалити стовпець';

  @override
  String get tableAlignmentUnspecified => 'Вирівнювання: не вказано';

  @override
  String get tableAlignmentLeft => 'Вирівнювання: ліворуч';

  @override
  String get tableAlignmentCenter => 'Вирівнювання: по центру';

  @override
  String get tableAlignmentRight => 'Вирівнювання: праворуч';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Рядок $rowNumber';
  }

  @override
  String get insertRowAbove => 'Вставити рядок вище';

  @override
  String get insertRowBelow => 'Вставити рядок нижче';

  @override
  String get deleteRow => 'Видалити рядок';

  @override
  String get tableHeaderHint => 'Заголовок';

  @override
  String get tableCellHint => 'Комірка';

  @override
  String get language => 'Мова';

  @override
  String get hideEditingButtons => 'Сховати кнопки редагування';

  @override
  String get showEditingButtons => 'Показати кнопки редагування';

  @override
  String get altText => 'Альтернативний текст';

  @override
  String get editorPlaceholderText => 'текст';

  @override
  String get editorPlaceholderCode => 'код';

  @override
  String get editorPlaceholderAltText => 'альтернативний текст';

  @override
  String get describeTheImage => 'Опишіть зображення';

  @override
  String get columns => 'Стовпці';

  @override
  String get rows => 'Рядки';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Заголовок $columnNumber';
  }

  @override
  String get tableCellDefault => 'Комірка';

  @override
  String get noImageSource => 'Немає джерела зображення';

  @override
  String get remoteImageBlocked => 'Віддалене зображення заблоковано';

  @override
  String get remoteImageBlockedTooltip =>
      'Виберіть, чи може BusyMark завантажувати віддалені зображення.';

  @override
  String get remoteImagesBlockedTitle => 'Віддалені зображення заблоковано';

  @override
  String get remoteImagesBlockedMessage =>
      'Цей документ посилається на зображення з інтернету. Їх завантаження може розкрити відомості про вашу мережу серверам, на яких розміщено зображення.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Завантажити для цієї робочої області';

  @override
  String get alwaysLoadRemoteImages =>
      'Завжди завантажувати віддалені зображення';

  @override
  String get hideSidebar => 'Приховати бічну панель';

  @override
  String get showSidebar => 'Показати бічну панель';

  @override
  String get showPreview => 'Показати попередній перегляд';

  @override
  String get hidePreview => 'Приховати попередній перегляд';

  @override
  String get workspaceKindUnsavedMarkdown => 'Незбережений файл Markdown';

  @override
  String get workspaceKindSingleMarkdown => 'Окремий файл Markdown';

  @override
  String get workspaceKindMarkdownFolder => 'Папка Markdown';

  @override
  String get workspaceKindWritersideModule => 'Модуль Writerside';

  @override
  String get problems => 'Проблеми';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count діагностичного повідомлення',
      many: '$count діагностичних повідомлень',
      few: '$count діагностичні повідомлення',
      one: '$count діагностичне повідомлення',
      zero: 'Немає діагностичних повідомлень',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Файли';

  @override
  String get toc => 'Зміст';

  @override
  String get tocActions => 'Дії зі змістом';

  @override
  String get markdownUnsaved => 'Markdown — незбережено';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлів',
      few: '$count файли',
      one: '$count файл',
    );
    return '$kind — $_temp0';
  }

  @override
  String get noFiles => 'Немає файлів';

  @override
  String get newFile => 'Новий файл';

  @override
  String get noWritersideToc => 'Немає змісту Writerside';

  @override
  String get tocSection => 'Розділ змісту';

  @override
  String get newTopic => 'Нова тема';

  @override
  String get newChildTopic => 'Нова дочірня тема';

  @override
  String get newSiblingTopic => 'Нова тема на тому самому рівні';

  @override
  String get renameTopicFile => 'Перейменувати файл теми';

  @override
  String get topicPlacement => 'Розташування у змісті';

  @override
  String get tocRoot => 'У корені змісту';

  @override
  String get afterSelectedTopic => 'Після вибраної теми';

  @override
  String get insideSelectedTopic => 'Усередині вибраної теми';

  @override
  String get pasteAfterTopic => 'Вставити після';

  @override
  String get pasteAsChildTopic => 'Вставити як дочірню тему';

  @override
  String get removeFromToc => 'Вилучити зі змісту';

  @override
  String get confirmRemoveFromTocTitle => 'Вилучити зі змісту?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Вилучити $name із цього змісту? Файл теми буде збережено.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Видалити файл теми?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Видалити файл теми $name і вилучити тему з усіх змістів? Цю дію не можна скасувати.';
  }

  @override
  String get safeDeleteTopicFile => 'Безпечно видалити файл теми…';

  @override
  String get removeTocElement => 'Вилучити елемент змісту';

  @override
  String get reviewUsages => 'Переглянути використання';

  @override
  String get deleteTopicFile => 'Видалити файл теми';

  @override
  String get removeAction => 'Вилучити';

  @override
  String topicRemovalSummary(String topic) {
    return 'Вилучити «$topic» із вибраного екземпляра. Файл теми буде збережено.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Видалити «$topic» і безпечно оновити посилання на неї в усьому цьому проєкті Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дочірньої теми буде переміщено на рівень вище.',
      many: '$count дочірніх тем буде переміщено на рівень вище.',
      few: '$count дочірні теми буде переміщено на рівень вище.',
      one: '1 дочірню тему буде переміщено на рівень вище.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Ця тема використовується як початкова сторінка екземпляра. Перегляньте її використання та призначте іншу початкову сторінку, перш ніж продовжити.';

  @override
  String topicUsagesCount(int count) {
    return 'Використання ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Посилань, які перестали б працювати, не знайдено.';

  @override
  String get topicUsagesFound =>
      'BusyMark знайшов наведені нижче посилання на цю тему.';

  @override
  String get topicUsageTocElements => 'Елементи змісту';

  @override
  String get topicUsageStartPages => 'Початкові сторінки';

  @override
  String get topicUsageTopicLinks => 'Посилання на теми';

  @override
  String get topicUsageIncludes => 'Включення';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count використання',
      many: '$count використань',
      few: '$count використання',
      one: '1 використання',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Параметри рефакторингу';

  @override
  String get updateUsagesAutomatically => 'Оновити використання автоматично';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Вилучити посилання зі змісту й включення та зберегти текст посилань.';

  @override
  String get manualUsageUpdatesRequired =>
      'Деякі використання потрібно змінити вручну перед цим рефакторингом.';

  @override
  String get setRedirectTo => 'Переспрямувати на';

  @override
  String get noRedirectDescription =>
      'Не переспрямовувати стару опубліковану сторінку.';

  @override
  String get redirectTarget => 'Ціль переспрямування';

  @override
  String get remainingUsagesBlockRemoval =>
      'Перегляньте й оновіть решту використань, перш ніж продовжити, або ввімкніть автоматичне оновлення, якщо воно доступне.';

  @override
  String usagesOfTopic(String topic) {
    return 'Використання теми $topic';
  }

  @override
  String get noUsagesFound => 'Використань не знайдено';

  @override
  String get outsideSelectedInstance => 'поза вибраним екземпляром';

  @override
  String get doRefactor => 'Виконати рефакторинг';

  @override
  String get orphanTopicTitle => 'Файл теми більше не використовується';

  @override
  String get keepTopicFile => 'Зберегти файл теми';

  @override
  String orphanTopicMessage(String topic) {
    return '«$topic» більше ніде не використовується в цьому проєкті Writerside. Видаліть файл або збережіть його для використання в іншому екземплярі.';
  }

  @override
  String get defaultNewTopicTitle => 'Нова тема';

  @override
  String get topicTitle => 'Назва теми';

  @override
  String get fileName => 'Ім’я файлу';

  @override
  String get topicTitleRequired => 'Необхідно вказати назву теми.';

  @override
  String get fileNameRequired => 'Потрібно вказати назву файлу.';

  @override
  String get rename => 'Перейменувати';

  @override
  String get confirmDeleteFileTitle => 'Видалити файл?';

  @override
  String get confirmDeleteFolderTitle => 'Видалити папку?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Видалити $name? Цю дію не можна скасувати.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Видалити $name і всі файли всередині? Цю дію не можна скасувати.';
  }

  @override
  String get useSingleSafeFileName =>
      'Використовуйте одну допустиму назву файлу.';

  @override
  String useExpectedExtension(String extension) {
    return 'Використовуйте розширення $extension для вибраного формату.';
  }

  @override
  String get useIdentifierCharacters =>
      'Використовуйте літери, цифри, знаки підкреслення або дефіси перед розширенням.';

  @override
  String get topicIdAlreadyExists => 'Ідентифікатор теми вже існує.';

  @override
  String get createWritersideTopicFailed =>
      'Не вдалося створити тему Writerside.';

  @override
  String get noOutline => 'Немає структури';

  @override
  String expandKind(String kind) {
    return 'Розгорнути: $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Згорнути: $kind';
  }

  @override
  String get foldKindSection => 'розділ';

  @override
  String get foldKindList => 'список';

  @override
  String get foldKindQuote => 'цитата';

  @override
  String get foldKindTag => 'тег';

  @override
  String get sourceSearchPreviousMatch => 'Попередній збіг';

  @override
  String get sourceSearchNextMatch => 'Наступний збіг';

  @override
  String get sourceSearchCaseSensitive => 'З урахуванням регістру';

  @override
  String get sourceSearchWholeWord => 'Ціле слово';

  @override
  String get sourceSearchRegex => 'Регулярний вираз';

  @override
  String get sourceSearchReplacement => 'Замінити на';

  @override
  String get sourceSearchReplaceCurrent => 'Замінити поточний збіг';

  @override
  String get sourceSearchReplaceAndFindNext => 'Замінити й знайти наступне';

  @override
  String get sourceSearchReplaceAll => 'Замінити все';

  @override
  String get workspaceReplace => 'Замінити в робочій області';

  @override
  String get reviewReplacements => 'Переглянути заміни';

  @override
  String get applyReplacements => 'Застосувати заміни';

  @override
  String get skippedFiles => 'Пропущені файли';

  @override
  String get workspaceReplaceDirtyBuffer => 'Незбережений вміст редактора';

  @override
  String get workspaceReplaceDiskContent => 'Вміст, збережений на диску';

  @override
  String selectFileMatches(int count) {
    return 'Вибрати всі збіги: $count';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return 'Замінено збігів: $matches у файлах: $files; пропущено: $skipped.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Кінцеве перенесення рядка';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · Немає кінцевого перенесення рядка';
  }

  @override
  String get normalizeLineEndings => 'Нормалізувати закінчення рядків';

  @override
  String get mixedLineEndingsSavePrompt =>
      'У документі використовуються змішані закінчення рядків. Виберіть формат.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return 'У $fileName використовуються змішані закінчення рядків. Виберіть формат перед заміною.';
  }

  @override
  String get workspaceReplaceIssueOversized => 'Завеликий файл пропущено.';

  @override
  String get workspaceReplaceIssueUnreadable =>
      'Файл, який не вдалося прочитати, пропущено.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 =>
      'Файл із неприпустимим UTF-8 пропущено.';

  @override
  String get workspaceReplaceIssueTruncated =>
      'Попередній перегляд замін було скорочено.';

  @override
  String get workspaceReplaceIssueFileChanged =>
      'Файл, змінений після попереднього перегляду, пропущено.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'Буфер редактора, змінений після попереднього перегляду, пропущено.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      'Перед заміною виберіть нормалізацію LF або CRLF.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'Відкат зупинено, оскільки файл було одночасно змінено. Деякі заміни могли залишитися; витіснений вміст збережено за шляхом нижче.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      'Заміни не застосовано, оскільки перевірений набір не вдалося безпечно зберегти.';

  @override
  String externalChangesTitle(String fileName) {
    return 'Зовнішні зміни — $fileName';
  }

  @override
  String get externalFileDeleted => 'Цей файл було видалено з диска.';

  @override
  String get externalFileChanged =>
      'Цей файл змінився на диску, поки у вас були незбережені зміни.';

  @override
  String recoveredDocumentReview(String fileName) {
    return 'Відновлено незбережений вміст файлу $fileName. Перегляньте його, потім збережіть, збережіть як новий файл або відкиньте.';
  }

  @override
  String get compare => 'Порівняти';

  @override
  String get reloadFromDisk => 'Перезавантажити з диска';

  @override
  String get keepMine => 'Залишити мою версію';

  @override
  String get saveAs => 'Зберегти як';

  @override
  String get sourceSearchInvalidRegex => 'Некоректний регулярний вираз';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Великий файл: підсвічування та згортання призупинено';

  @override
  String get nothingToRead => 'Немає вмісту для читання';

  @override
  String get admonition => 'Блок-примітка';

  @override
  String get quote => 'Цитата';

  @override
  String get note => 'Примітка';

  @override
  String get tip => 'Підказка';

  @override
  String get warning => 'Попередження';

  @override
  String get tabs => 'Вкладки';

  @override
  String get tab => 'Вкладка';

  @override
  String get procedure => 'Процедура';

  @override
  String get step => 'Крок';

  @override
  String get topic => 'Тема';

  @override
  String get chapter => 'Розділ';

  @override
  String couldNotOpenTarget(String target) {
    return 'Не вдалося відкрити $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Ціль посилання не знайдено: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Файл цього типу неможливо відкрити в редакторі';

  @override
  String anchorNotFound(String anchor) {
    return 'Якір не знайдено: $anchor';
  }

  @override
  String get noProblemsFound => 'Проблем не виявлено';

  @override
  String get noResults => 'Немає результатів';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath — рядок $lineNumber';
  }

  @override
  String get untitledResult => 'Результат без назви';

  @override
  String get documentKindMarkdownFile => 'Файл Markdown';

  @override
  String get documentKindWritersideMarkdownTopic => 'Markdown-тема Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'XML-тема Writerside';

  @override
  String get documentKindWritersideTree => 'Дерево Writerside';

  @override
  String get documentKindConfigurationFile => 'Файл конфігурації';

  @override
  String get documentKindVariablesFile => 'Файл змінних';

  @override
  String get documentKindCategoriesFile => 'Файл категорій';

  @override
  String get documentKindResourceFile => 'Файл ресурсів';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Не вдалося відкрити: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Не вдалося створити проєкт Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Не вдалося створити тему Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Не вдалося відкрити файл: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Виберіть, де зберегти цей файл Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Збереження заблоковано: файл змінено на диску.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Не вдалося зберегти: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Не вдалося виконати файлову операцію: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Помилка перевірки: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Відновлено $count незбережених документів. Перегляньте кожен перед збереженням або відхиленням.',
      one:
          'Відновлено 1 незбережений документ. Перегляньте його перед збереженням або відхиленням.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count пошкоджених записів відновлення не вдалося відновити. Дійсні записи відновлення залишаються доступними.',
      one:
          'Не вдалося відновити 1 пошкоджений запис відновлення. Оригінальний файл відновлення збережено для перегляду.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Шлях не існує: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Цільовий каталог уже існує та не порожній: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Цільовий шлях уже існує та не є каталогом: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Згенерований файл уже існує: $path';
  }

  @override
  String get errorParentDirectoryRequired =>
      'Потрібно вказати батьківський каталог.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Батьківський каталог не існує: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Каталог не існує: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Шлях уже існує: $path';
  }

  @override
  String get errorFileNameRequired => 'Потрібна назва файлу.';

  @override
  String get errorFileNameUnsafe =>
      'Назва файлу має бути одним безпечним сегментом шляху.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Не можна перемістити папку всередину самої себе.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Файлова операція має виконуватися в межах робочої області.';

  @override
  String get errorFileOperationRoot =>
      'Корінь робочої області не можна змінити з дерева файлів.';

  @override
  String get errorProjectNameRequired => 'Потрібно вказати назву проєкту.';

  @override
  String get errorDirectoryNameRequired => 'Потрібно вказати назву каталогу.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Назва каталогу має бути одним допустимим сегментом шляху.';

  @override
  String get errorInstanceIdInvalid =>
      'Ідентифікатор екземпляра має починатися з малої літери та містити лише малі літери, цифри, знаки підкреслення та дефіси.';

  @override
  String get errorTopicFileInvalid =>
      'Назва файлу теми має бути назвою файлу Markdown без роздільників шляху.';

  @override
  String get errorTopicTitleRequired => 'Необхідно вказати назву теми.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Корінь модуля Writerside не існує: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Щоб створити тему, модуль Writerside має бути відкритим.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'У модулі Writerside немає дерева екземпляра.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Файл дерева Writerside не існує: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'Ідентифікатор теми «$topicId» вже існує в цьому модулі довідки.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Файл теми вже існує: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Вказаної теми немає у вибраному дереві: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Вибраного запису змісту більше не існує.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Запис змісту не можна перемістити в нього самого чи в один із його дочірніх елементів.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Початкову тему $topic не можна видалити. Спочатку виберіть іншу початкову сторінку.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Використовуйте безпечне видалення для файлів тем Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Не вдалося завершити пошук використань теми. Жоден файл не змінено.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Деякі використання теми все ще потребують уваги. Перегляньте їх, перш ніж продовжити.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Вибрана ціль переспрямування більше не дійсна. Виберіть її знову.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Не вдалося повністю відкотити видалення теми. Перш ніж продовжити, перевірте такі шляхи: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Кореневий каталог тем має бути допустимим відносним каталогом.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Назва файлу теми має бути одним допустимим сегментом шляху.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Розширення файлу теми має відповідати вибраному формату ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Назва файлу теми має містити лише літери, цифри, знаки підкреслення та дефіси.';

  @override
  String errorUnknown(String code) {
    return 'Невідома помилка: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Не вдалося прочитати метадані файлу: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Виявлено велику робочу область. Деякі файли пропущено, щоб програма продовжувала швидко реагувати.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Не вдалося перевірити елемент робочої області: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Файл перевищує обмеження бета-версії для автоматичного аналізу.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Не вдалося прочитати файл Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Некоректний блок атрибутів заголовка Writerside.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Повторюваний ідентифікатор заголовка «$id».';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Додаткові заголовки H1 верхнього рівня розглядаються як розділи.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Markdown-тема Writerside не має заголовка H1 або заголовка у front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'XML-тема не має заголовка.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Тема «$fileName» не має назви.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Блок front matter не закрито.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Небезпечний HTML-елемент.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Ціль посилання не існує: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Якір «$anchor» не існує.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'Для зображення «$destination» не вказано альтернативний текст.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Зображення не існує: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Некоректний XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Кореневим елементом writerside.cfg має бути <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'В оголошенні snippets відсутній атрибут src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'В оголошенні instance-groups відсутній атрибут src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Непідтримуваний режим keymaps: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'В оголошенні instance відсутній атрибут src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg не реєструє жодного екземпляра.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Кореневим елементом .tree має бути <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'У профілі екземпляра відсутній id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Ім’я файлу дерева без розширення не відповідає ідентифікатору екземпляра «$id».';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'В екземплярі, який не є бібліотекою, відсутній атрибут start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Початкова сторінка «$startPage» не існує.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Тема «$topic» трапляється більше ніж один раз у змісті цього екземпляра.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Оголошення змінної має містити ім’я та значення.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Змінна «$name» оголошена більше одного разу.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'У категорії відсутній id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Категорія «$id» оголошена більше одного разу.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Порядок категорії «$order» оголошено більше одного разу.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Кореневим елементом .topic має бути <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'В XML-темі відсутній ідентифікатор кореневого елемента.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Ідентифікатор кореневого елемента XML-теми «$id» має відповідати назві файлу «$expectedId».';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Ідентифікатор елемента «$elementId» з’являється більше одного разу.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'В елементі <a> відсутній атрибут href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Режим Writerside потребує writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Вказаний каталог конфігурації збірки відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Вказаний каталог специфікацій API відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Вказаний каталог snippets відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Вказаний файл змінних відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Вказаний файл категорій відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Вказаний файл груп екземплярів відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Зареєстроване дерево екземпляра «$source» не існує.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Не вдалося прочитати файл теми: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Каталог тем за замовчуванням відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Налаштований каталог тем відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Налаштований каталог зображень відсутній: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Ідентифікатор елемента «$id» з’являється більше одного разу.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'У змісті є посилання на відсутню тему «$topic».';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Зовнішній href «$href» некоректний.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Змінна «%$name%» не оголошена.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Посилання на тему «$destination» не вказує на наявну тему.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Якір «$anchor» не існує в «$targetName».';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'В елементі <include> відсутній атрибут from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Джерело include «$from» не існує.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Елемент include «$elementId» не існує в «$from».';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'Категорія seealso «$ref» не оголошена.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Посилання на тему «$reference» неоднозначне.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Невідоме діагностичне повідомлення: $code';
  }

  @override
  String get close => 'Закрити';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Відмінності Git';

  @override
  String get gitShowDiff => 'Показати відмінності';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'старий діапазон $oldRange → новий $newRange';
  }

  @override
  String get gitDiffNoLines => 'немає рядків';

  @override
  String get gitUnavailableTitle => 'Git недоступний';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Установіть Git або налаштуйте BusyMark на використання доступного виконуваного файлу Git. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Довіряти цій робочій області під час роботи з Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Репозиторії Git можуть запускати програми за допомогою хуків, фільтрів та інших налаштувань. Позначте цю робочу область як довірену, перш ніж BusyMark прочитає дані репозиторію або ввімкне дії Git.';

  @override
  String get gitTrustWorkspace => 'Довіряти робочій області';

  @override
  String get gitNotRepositoryTitle => 'Це не репозиторій Git';

  @override
  String get gitNotRepositoryMessage =>
      'Ця робоча область не належить до репозиторію Git.';

  @override
  String get gitInitializeRepository => 'Ініціалізувати репозиторій';

  @override
  String get gitDetachedHead => 'Відокремлений HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Відокремлений HEAD: $commit';
  }

  @override
  String get gitNoUpstream => 'Немає upstream-гілки';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count невідправленого коміта',
      many: '$count невідправлених комітів',
      few: '$count невідправлені коміти',
      one: '$count невідправлений коміт',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Потрібно отримати $count коміта',
      many: 'Потрібно отримати $count комітів',
      few: 'Потрібно отримати $count коміти',
      one: 'Потрібно отримати $count коміт',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Без змін';

  @override
  String get gitConflicts => 'Конфлікти';

  @override
  String get gitChanges => 'Зміни';

  @override
  String get gitStaged => 'Індексовані';

  @override
  String get gitUnstaged => 'Неіндексовані';

  @override
  String get gitHistory => 'Історія';

  @override
  String get gitBranches => 'Гілки';

  @override
  String get gitActions => 'Дії Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Отримати';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Зафіксувати';

  @override
  String get gitSelectForCommit => 'Додати файл до індексу';

  @override
  String get gitRemoveFromCommit => 'Вилучити файл з індексу';

  @override
  String get gitDiscard => 'Відкинути';

  @override
  String get gitOpenFile => 'Відкрити файл';

  @override
  String get gitMarkResolved => 'Позначити як розв’язаний';

  @override
  String get gitUntracked => 'Невідстежувані файли';

  @override
  String get gitCommitMessage => 'Повідомлення коміту';

  @override
  String get gitCommitSelectedFiles => 'Вибрані файли';

  @override
  String get gitCommitNoSelectedFiles =>
      'Перед створенням коміту додайте до індексу принаймні один файл.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проіндексованих файлів',
      many: '$count проіндексованих файлів',
      few: '$count проіндексовані файли',
      one: '1 проіндексований файл',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Поза робочим простором';

  @override
  String get gitCommitMessageRequired => 'Введіть повідомлення коміту.';

  @override
  String get gitCreateBranch => 'Створити гілку';

  @override
  String get gitNewBranch => 'Нова гілка';

  @override
  String get gitBranchName => 'Назва гілки';

  @override
  String get gitSwitchBranch => 'Перемкнутися';

  @override
  String get gitNoChanges => 'Немає змін';

  @override
  String get gitNoHistory => 'Немає історії';

  @override
  String get gitNoBranches => 'Немає гілок';

  @override
  String get gitNoDiff => 'Немає різниці для показу';

  @override
  String get gitBinaryFile =>
      'Двійковий файл. BusyMark не відображає двійкові патчі.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Двійковий файл ($size байтів). BusyMark не відображає двійкові патчі.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Незбережені зміни в редакторі не буде враховано, доки ви їх не збережете.';

  @override
  String get gitConfirmDiscardTitle => 'Відкинути зміни Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Усі індексовані та неіндексовані зміни в обраних файлах з відстеженням будуть відновлені в HEAD.',
      one:
          'Усі індексовані та неіндексовані зміни у вибраному файлі з відстеженням будуть відновлені в HEAD.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Вибрані невідстежувані файли буде видалено.',
      many: 'Вибрані невідстежувані файли буде видалено.',
      few: 'Вибрані невідстежувані файли буде видалено.',
      one: 'Вибраний невідстежуваний файл буде видалено.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Вибрані файли буде відновлено або видалено залежно від їхнього стану Git.',
      many:
          'Вибрані файли буде відновлено або видалено залежно від їхнього стану Git.',
      few:
          'Вибрані файли буде відновлено або видалено залежно від їхнього стану Git.',
      one:
          'Вибраний файл буде відновлено або видалено залежно від його стану Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Перемкнутися на $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark перезавантажить робочу область із диска після перемикання гілки в Git.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Налаштувати upstream-гілку?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'Ця гілка не має upstream-гілки. BusyMark може надіслати гілку $branch і призначити її upstream-гілкою, якщо налаштовано рівно один віддалений репозиторій.';
  }

  @override
  String get gitProjectHistory => 'Історія проєкту';

  @override
  String get gitFileHistory => 'Історія файлу';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Для історії файлу потрібен відкритий файл Markdown.';

  @override
  String get gitLoadMore => 'Завантажити ще';

  @override
  String get gitChangesInCommit => 'Зміни в цьому коміті';

  @override
  String get gitCompareWithCurrent => 'Порівняти з поточною версією';

  @override
  String get gitRestoreVersion => 'Відновити цю версію';

  @override
  String get gitConfirmRestoreTitle => 'Відновити цю версію файлу?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark замінить поточний файл робочого дерева вибраною версією з коміту. Відновлений файл залишиться неіндексованим.';

  @override
  String get gitCommitActions => 'Дії з комітом';

  @override
  String get gitResetCurrentBranchToHere => 'Скинути поточну гілку сюди…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Скинути $branch на $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Гілку $branch буде переміщено на коміт $commit. Виберіть, як Git має оновити індекс і робоче дерево.';
  }

  @override
  String get gitReset => 'Скинути';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Перемістити лише гілку. Залишити індекс і робоче дерево без змін; відмінності від вибраного коміту залишаться індексованими.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Перемістити гілку й скинути індекс. Залишити робоче дерево без змін, а відмінності — неіндексованими.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Перемістити гілку й скинути індекс і робоче дерево. Відстежувані зміни буде відкинуто; не відстежувані файли, що заважають операції, може бути видалено.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Перемістити гілку й скинути відстежувані файли, зберігши локальні зміни. Git перерве операцію, якщо ці зміни конфліктують зі скиданням.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Дії з файлом';

  @override
  String get actions => 'Дії';

  @override
  String get gitStatusAdded => 'Додано';

  @override
  String get gitStatusDeleted => 'Видалено';

  @override
  String get gitStatusRenamed => 'Перейменовано';

  @override
  String get gitStatusCopied => 'Скопійовано';

  @override
  String get gitStatusUntracked => 'Не відстежується';

  @override
  String get gitStatusConflicted => 'Конфлікт';

  @override
  String get gitStatusIgnored => 'Проігноровано';

  @override
  String get gitStatusTypeChanged => 'Тип змінено';

  @override
  String get gitStatusModified => 'Змінено';

  @override
  String get gitStatusUnknown => 'Невідомо';

  @override
  String get gitErrorUnavailable => 'Git недоступний.';

  @override
  String get gitErrorNotRepository =>
      'Ця робоча область не є репозиторієм Git.';

  @override
  String get gitErrorUnsafePath => 'BusyMark заблокував небезпечний шлях Git.';

  @override
  String get gitErrorInvalidBranchName => 'Введіть припустиму назву гілки.';

  @override
  String get gitErrorNoRemote => 'Віддалений репозиторій Git не налаштовано.';

  @override
  String get gitErrorNoUpstream => 'Upstream-гілку не налаштовано.';

  @override
  String get gitErrorMultipleRemotes =>
      'Налаштовано кілька віддалених репозиторіїв. Ця версія BusyMark не дає змоги вибрати upstream-гілку; налаштуйте її поза програмою.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Перед перемиканням гілки збережіть або відкиньте зміни в редакторі BusyMark.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Збережіть або відкиньте зміни в редакторі BusyMark перед скиданням поточної гілки.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Приберіть файл з індексу перед відновленням попередньої версії.';

  @override
  String get gitErrorResetDetachedHead =>
      'Перейдіть на гілку перед її скиданням.';

  @override
  String get gitErrorDiverged =>
      'Гілка розійшлася з upstream-гілкою. Виконайте злиття або rebase поза цією версією BusyMark.';

  @override
  String get gitErrorAuthorIdentity =>
      'Перед створенням коміту Git потребує ім’я та адресу електронної пошти автора.';

  @override
  String get gitAuthorIdentityTitle => 'Дані автора Git';

  @override
  String get gitAuthorIdentityMessage =>
      'Введіть дані, які Git має записувати в комітах. BusyMark збереже їх і повторить цей коміт.';

  @override
  String get gitAuthorName => 'Ім’я';

  @override
  String get gitAuthorEmail => 'Електронна пошта';

  @override
  String get gitAuthorIdentityGlobal => 'Використовувати для всіх репозиторіїв';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Під час установлення через Snap це стосується репозиторіїв, відкритих у BusyMark.';

  @override
  String get gitSaveIdentityAndCommit => 'Зберегти й створити коміт';

  @override
  String get gitErrorAuthentication => 'Не вдалося автентифікуватися в Git.';

  @override
  String get gitErrorNetwork => 'Не вдалося виконати мережеву операцію Git.';

  @override
  String get gitErrorConflict => 'Git повідомив про нерозв’язані конфлікти.';

  @override
  String get gitErrorCommandFailed => 'Не вдалося виконати команду Git.';

  @override
  String get markdownAndHtml => 'Markdown і HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Блоки Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Блокові структури, що підтримуються у вихідному Markdown і попередньому перегляді.';

  @override
  String get markdownHtmlInlineFormatting => 'Вбудований Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Форматування всередині абзаців, елементів списків і комірок таблиць.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Блоки необробленого HTML';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Безпечні блокові HTML-теги, що відображаються через віджети перегляду BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Вбудовані HTML-теги';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Безпечні вбудовані HTML-теги відображаються без показу самих тегів.';

  @override
  String get markdownHtmlSafety => 'Правила безпеки';

  @override
  String get markdownHtmlSafetyDescription =>
      'Необроблений HTML аналізується й очищується перед попереднім переглядом.';

  @override
  String get markdownHtmlHeadings => 'Заголовки';

  @override
  String get markdownHtmlParagraphs => 'Абзаци';

  @override
  String get markdownHtmlLists => 'Списки';

  @override
  String get markdownHtmlHtmlContainers => 'Контейнери';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Текстові блоки';

  @override
  String get markdownHtmlHtmlFigures => 'Фігури та зображення';

  @override
  String get markdownHtmlHtmlPreformatted => 'Попередньо форматований код';

  @override
  String get markdownHtmlHtmlDisclosure => 'Розкривні блоки';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Списки описів';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Теги форматування';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Вбудовані теги коду';

  @override
  String get markdownHtmlHtmlNeutralInlineTags => 'Семантичні текстові теги';

  @override
  String get markdownHtmlSanitizedPreview => 'Очищений перегляд';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Дозволений HTML перетворюється на блоки перегляду BusyMark, а не відтворюється в браузері.';

  @override
  String get markdownHtmlSourcePreserved => 'Вихідний текст зберігається';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Незмінений необроблений HTML зберігається точно як вихідний текст.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown всередині HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown-розмітка всередині необробленого HTML відображається як звичайний текст.';

  @override
  String get markdownHtmlBlockedContent => 'Активний вміст заблоковано';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Скрипти, стилі, фрейми, форми, SVG, MathML, події та небезпечні атрибути блокуються.';

  @override
  String get markdownHtmlSafeUrls => 'Лише безпечні URL';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Посилання дозволяють http, https, mailto, tel, відносні URL і фрагменти; небезпечні схеми блокуються.';

  @override
  String get exportAsPdf => 'Експортувати як PDF';

  @override
  String get pdfExportDescription =>
      'Виберіть макет сторінки для охайного автономного PDF-файлу.';

  @override
  String get pdfRemoteImagesNote =>
      'Віддалені зображення під час експорту не завантажуються. Доступні локальні зображення буде додано.';

  @override
  String get pdfPageSize => 'Розмір сторінки';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'US Letter';

  @override
  String get pdfOrientation => 'Орієнтація';

  @override
  String get pdfPortrait => 'Книжкова';

  @override
  String get pdfLandscape => 'Альбомна';

  @override
  String get pdfMargins => 'Поля';

  @override
  String get pdfMarginNarrow => 'Вузькі';

  @override
  String get pdfMarginNormal => 'Звичайні';

  @override
  String get pdfMarginWide => 'Широкі';

  @override
  String get pdfIncludePageNumbers => 'Додати номери сторінок';

  @override
  String get export => 'Експортувати';

  @override
  String get exportingPdf => 'Експорт PDF…';

  @override
  String get fileTypePdf => 'Документ PDF';

  @override
  String pdfExported(String fileName) {
    return 'Файл $fileName експортовано.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count попередженнями',
      one: '1 попередженням',
    );
    return '$fileName експортовано з $_temp0.';
  }

  @override
  String get pdfExportUnavailable =>
      'Компонент експорту PDF відсутній. Перевстановіть BusyMark і повторіть спробу.';

  @override
  String get pdfExportTimedOut =>
      'Експорт PDF тривав надто довго й був зупинений.';

  @override
  String get pdfExportFailed =>
      'BusyMark не вдалося експортувати цей документ як PDF.';

  @override
  String get visualizationRendering => 'Візуалізація…';

  @override
  String get visualizationStale =>
      'Відображається останній коректний результат';

  @override
  String get visualizationShowSource => 'Показати вихідний код';

  @override
  String get visualizationShowRender => 'Показати результат';

  @override
  String get visualizationFitWidth => 'Припасувати до ширини';

  @override
  String get visualizationSaveImage => 'Зберегти зображення';

  @override
  String get visualizationCopyImage => 'Копіювати зображення';

  @override
  String get visualizationImageCopied => 'Зображення скопійовано';

  @override
  String get visualizationOpenApiReference => 'Відкрити довідник API';

  @override
  String get visualizationValid => 'Коректно';

  @override
  String get visualizationInvalid => 'Некоректно';

  @override
  String get visualizationServers => 'Сервери';

  @override
  String get visualizationPaths => 'Шляхи';

  @override
  String get visualizationOperations => 'Операції';

  @override
  String get visualizationTags => 'Теги';

  @override
  String get visualizationNoOperations => 'Відповідних операцій не знайдено';

  @override
  String get visualizationSearchOperations => 'Пошук операцій';

  @override
  String get visualizationRenderFailed =>
      'Не вдалося відобразити цю візуалізацію.';

  @override
  String get visualizationRetry => 'Повторити';

  @override
  String visualizationSaved(String fileName) {
    return 'Файл $fileName збережено';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Експортувати активний документ або модуль Writerside як PDF.';

  @override
  String get instances => 'Екземпляри';

  @override
  String get newInstance => 'Новий екземпляр';

  @override
  String get newTocLibrary => 'Нова бібліотека змісту';

  @override
  String get editInstance => 'Змінити екземпляр';

  @override
  String get openTocFile => 'Відкрити файл змісту';

  @override
  String get createInstance => 'Створити екземпляр';

  @override
  String get createTocLibrary => 'Створити бібліотеку змісту';

  @override
  String get instanceContent => 'Вміст';

  @override
  String get instanceContentSource => 'Створити з';

  @override
  String get emptyInstance => 'Порожній екземпляр';

  @override
  String get markdownFiles => 'Локальні файли Markdown';

  @override
  String get chooseMarkdownFolder => 'Вибрати папку Markdown';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Виберіть папку, що містить файли Markdown.';

  @override
  String get instanceAppearance => 'Вигляд';

  @override
  String get instanceColor => 'Колір піктограми';

  @override
  String get instanceVersion => 'Версія';

  @override
  String instanceVersionInherited(String version) {
    return 'Коли це поле порожнє, використовується версія проєкту $version.';
  }

  @override
  String get instanceWebPath => 'Вебшлях';

  @override
  String get instanceStatus => 'Стан';

  @override
  String get instanceStatusRelease => 'Випуск';

  @override
  String get instanceStatusEap => 'Ранній доступ';

  @override
  String get instanceStatusDeprecated => 'Застарілий';

  @override
  String get allowSearchEngineIndexing =>
      'Дозволити індексацію пошуковими системами';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Дозволити зовнішнім пошуковим системам індексувати цей результат.';

  @override
  String get offlineArtifact => 'Пакунок для автономної роботи';

  @override
  String get offlineArtifactDescription =>
      'Додати ресурси, щоб зібрана документація була самодостатньою.';

  @override
  String get instanceOutputSettings => 'Налаштування результату';

  @override
  String get markdownImportSource => 'Джерело Markdown';

  @override
  String get markdownImportFiles => 'Файли Markdown';

  @override
  String get selectNone => 'Зняти всі позначки';

  @override
  String markdownFilesFound(int count) {
    return 'Знайдено файлів Markdown: $count';
  }

  @override
  String get noMarkdownFilesFound =>
      'У цьому каталозі файлів Markdown не знайдено.';

  @override
  String get copyReferencedMedia => 'Копіювати використані медіафайли';

  @override
  String get copyReferencedMediaDescription =>
      'Копіювати локальні зображення й відео, на які посилаються вибрані файли, зі збереженням відносних шляхів.';

  @override
  String get instanceIdRenameWarningTitle =>
      'Перейменувати ідентифікатор екземпляра?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark перейменує файл .tree й оновить посилання проєкту Writerside з «$oldId» на «$newId». Скрипти публікації не змінюються — їх потрібно оновити окремо.';
  }

  @override
  String get renameAndUpdateReferences => 'Перейменувати й оновити посилання';

  @override
  String get tocLibraryDescription =>
      'Бібліотека змісту зберігає повторно використовувані розділи й не створює власного результату.';

  @override
  String get defaultTocLibraryName => 'Спільний зміст';

  @override
  String get instanceColorAutomatic => 'Автоматично';

  @override
  String get instanceColorBlue => 'Синій';

  @override
  String get instanceColorGreen => 'Зелений';

  @override
  String get instanceColorOrange => 'Помаранчевий';

  @override
  String get instanceColorPurple => 'Фіолетовий';

  @override
  String get instanceColorRed => 'Червоний';

  @override
  String get instanceColorTeal => 'Бірюзовий';

  @override
  String get instanceColorYellow => 'Жовтий';

  @override
  String get errorWritersideInstanceNameRequired => 'Введіть назву екземпляра.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Екземпляр з ідентифікатором «$id» уже існує.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Дерево екземпляра вже існує: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Каталог джерела Markdown не існує: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Виберіть принаймні один файл Markdown для імпорту.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Це не придатний для читання файл Markdown усередині вибраного джерела: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Імпорт перезапише наявний файл проєкту: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Файли екземпляра змінилися на диску. Перегляньте їх і повторіть спробу.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark не вдалося повністю відкотити зміну екземпляра. Перегляньте ці файли, перш ніж продовжити: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Бібліотека змісту не може імпортувати теми Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Вебшлях має складатися з одного рядка.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Конфігурація екземпляра Writerside некоректна. Виправте її діагностичні повідомлення й повторіть спробу.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark не вдалося безпечно підготувати зміни екземпляра.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Невідомий стан екземпляра «$status». Використовуйте release, eap або deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'Ідентифікатор екземпляра «$id» використовується в кількох файлах дерева.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'Кореневим елементом buildprofiles.xml має бути <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Значення $name «$value» має бути true або false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Елемент <build-profile> має вказувати ідентифікатор екземпляра.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Елемент дерева <include> має вказувати й from, і element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Елемент дерева <snippet> має вказувати id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Міжекземплярне посилання змісту має вказувати й ref, і in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Елемент змісту не може одночасно посилатися на кілька тем, посилань, адрес або перенаправлень.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'Ідентифікатор елемента дерева «$id» оголошено кілька разів.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Кореневим елементом файлу груп екземплярів має бути <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Група екземплярів має вказувати непорожній ідентифікатор і список екземплярів.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'Ідентифікатор групи екземплярів «$id» оголошено кілька разів.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Включення змісту «$source#$id» належить зовнішньому модулю «$origin» і не може бути розгорнуте в цій робочій області.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Елемент дерева «$id» відсутній у зареєстрованому дереві «$source».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Включення дерева «$source#$id» створює цикл.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Умова екземпляра посилається на невідому групу «@$group».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Міжекземплярне посилання вказує на невідомий екземпляр «$instance».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Теми «$topic» немає у вказаному екземплярі «$instance».';
  }

  @override
  String get download => 'Завантажити';

  @override
  String get exportWritersideAsPdf => 'Експорт Writerside у PDF';

  @override
  String get writersidePdfContent => 'Вміст експорту';

  @override
  String get writersidePdfPage => 'Сторінка';

  @override
  String get exportingWritersidePdf => 'Експорт PDF Writerside…';

  @override
  String get ai => 'ШІ';

  @override
  String get aiLocalOllama => 'Локальний Ollama';

  @override
  String get aiDisabled => 'Вимкнено';

  @override
  String get aiExplicitEditingDescription =>
      'Редагування за допомогою ШІ запускається лише явно. BusyMark надсилає вибраному постачальнику тільки показаний контекст і ніколи не застосовує пропозицію без перевірки.';

  @override
  String get aiProvider => 'Постачальник ШІ';

  @override
  String get aiDefaultProvider => 'Постачальник за замовчуванням';

  @override
  String get aiConfigureProvider => 'Налаштувати постачальника';

  @override
  String get aiChooseProvider => 'Виберіть постачальника ШІ';

  @override
  String get aiOllamaEndpoint => 'Кінцева точка Ollama';

  @override
  String get aiOllamaModel => 'Модель Ollama';

  @override
  String get aiTestConnection => 'Перевірити підключення';

  @override
  String get aiTestingConnection => 'Перевірка…';

  @override
  String aiConnectionReady(int count) {
    return 'Підключено. Знайдено встановлених моделей: $count.';
  }

  @override
  String get aiNoModels => 'Модель не вибрана.';

  @override
  String get aiConnectionFailed =>
      'BusyMark не вдалося перевірити генерування тексту за допомогою ШІ.';

  @override
  String get aiConfigureFirst =>
      'Увімкніть постачальника ШІ та перевірте модель у розділі «Налаштування → ШІ».';

  @override
  String get aiEditWithAi => 'Редагувати за допомогою ШІ';

  @override
  String get aiRefineWithAi => 'Покращити за допомогою ШІ';

  @override
  String get aiInstruction => 'Інструкція';

  @override
  String get aiChangeTarget => 'Що можна змінити';

  @override
  String get aiSharedContext => 'Контекст, що передається ШІ';

  @override
  String get aiTargetSelection => 'Вибраний вміст';

  @override
  String get aiTargetInsertAfterBlock => 'Вставити після поточного блоку';

  @override
  String get aiTargetCurrentBlock => 'Поточний блок';

  @override
  String get aiTargetCurrentSection => 'Поточний розділ';

  @override
  String get aiTargetCompleteDocument => 'Увесь документ';

  @override
  String get aiContextNone => 'Без контексту документа';

  @override
  String get aiContextSelection => 'Вибраний вміст';

  @override
  String get aiContextCurrentBlock => 'Поточний блок';

  @override
  String get aiContextCurrentSection => 'Поточний розділ';

  @override
  String get aiContextCompleteDocument => 'Увесь документ';

  @override
  String get aiGenerating => 'Створення пропозиції…';

  @override
  String get aiProposal => 'Пропозиція ШІ';

  @override
  String get aiGenerateProposal => 'Створити пропозицію';

  @override
  String aiContextDisclosure(int count) {
    return 'Вибраний постачальник отримає $count символів із показаного контексту.';
  }

  @override
  String get aiOriginal => 'Початковий текст';

  @override
  String get aiSuggested => 'Пропозиція';

  @override
  String get aiApplyProposal => 'Застосувати пропозицію';

  @override
  String aiTokenUsage(int input, int output) {
    return 'Вхідні токени: $input · вихідні токени: $output';
  }

  @override
  String get aiStaleProposal =>
      'Документ змінився під час створення цієї пропозиції. Запустіть дію ще раз.';

  @override
  String get gitAiStagedChangesChanged =>
      'Індексовані зміни змінилися під час створення цього повідомлення коміту. Запустіть дію ще раз.';

  @override
  String get aiViewContext => 'Показати надісланий контекст';

  @override
  String get aiReviewExactContent => 'Переглянути точний вміст';

  @override
  String get aiContentToChange => 'Вміст для зміни';

  @override
  String get aiContentSentToAi => 'Вміст, що надсилається ШІ';

  @override
  String get aiApiKey => 'Ключ API';

  @override
  String get aiApiKeyStoredHint =>
      'Ключ збережено в системному сховищі облікових даних';

  @override
  String get aiApiKeyEnterHint => 'Введіть ключ API постачальника';

  @override
  String get aiReplaceApiKey => 'Замінити ключ API';

  @override
  String get aiSaveApiKey => 'Безпечно зберегти ключ API';

  @override
  String get aiRemoveApiKey => 'Видалити збережений ключ API';

  @override
  String get aiCredentialSaved =>
      'Ключ API збережено в системному сховищі облікових даних.';

  @override
  String get aiCredentialRemoved => 'Збережений ключ API видалено.';

  @override
  String get aiModelRouting => 'Вибір моделі';

  @override
  String get aiAutomaticRouting => 'Автоматично за завданням';

  @override
  String get aiFixedModelRouting => 'Використовувати вибрану модель';

  @override
  String get aiPreferredModel => 'Бажана модель';

  @override
  String get aiModel => 'Модель';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests запитів · $input вхідних токенів · $output вихідних токенів';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return 'Надіслати вміст постачальнику $provider?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return 'Увімкнути $provider';
  }

  @override
  String get aiCloudConsentMessage =>
      'Надсилається лише вміст, показаний у кожному діалозі перевірки ШІ. Запити не зберігають стан, пропозиції потребують перевірки, а ключ API зберігається в системному сховищі облікових даних Linux.';

  @override
  String aiCloudConsentRequired(String provider) {
    return 'Спочатку підтвердьте передавання даних постачальнику $provider у розділі «Налаштування → ШІ».';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return 'Генерування за допомогою $model перевірено. Доступно сумісних моделей: $count.';
  }

  @override
  String get aiColdStartObserved =>
      'Виявлено холодний запуск локальної моделі.';

  @override
  String get aiNoCompatibleModels =>
      'Немає доступної сумісної моделі генерування тексту.';

  @override
  String get aiEnableProvider => 'Спочатку ввімкніть постачальника ШІ.';

  @override
  String get aiDraftCommitMessage => 'Створити чернетку повідомлення коміту';

  @override
  String get aiDrafting => 'Створення чернетки…';

  @override
  String get aiDraftWithAi => 'Створити чернетку за допомогою ШІ';

  @override
  String get generateOrUpdateMarkdownToc => 'Створити/оновити зміст';

  @override
  String get markdownTocTitle => 'Зміст';

  @override
  String markdownTocUpdated(int count) {
    return 'Зміст оновлено, записів: $count.';
  }

  @override
  String get markdownTocNoHeadings =>
      'Додайте принаймні один заголовок розділу перед створенням змісту.';

  @override
  String get markdownTocMalformedMarkers =>
      'Маркери змісту BusyMark відсутні, повторюються або розташовані в неправильному порядку.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return 'Після заголовка рівня $previousLevel іде рівень $level; перевірте вкладеність розділів.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'Текст посилання порожній; укажіть доступну назву, що описує його призначення.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'Перевірте, чи описує текст посилання «$text» його призначення в контексті.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      'Заголовки таблиці мають позначати стовпці; заповніть кожен порожній заголовок.';

  @override
  String get mathRenderFailed => 'Не вдалося відобразити математичний вираз.';

  @override
  String get inlineMath => 'Формула в рядку';

  @override
  String get displayMath => 'Формула окремим блоком';
}
