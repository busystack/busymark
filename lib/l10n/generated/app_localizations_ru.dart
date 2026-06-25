// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Редактор документации, совместимый с Markdown и Writerside.';

  @override
  String get aboutBusyMark => 'О BusyMark';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get aboutDescription =>
      'BusyMark — это специализированный редактор документации, совместимый с Markdown и Writerside, для локальных проектов.';

  @override
  String get advanced => 'Передовой';

  @override
  String get appearance => 'Появление';

  @override
  String get apply => 'Применять';

  @override
  String get back => 'Назад';

  @override
  String get bottomLeft => 'Внизу слева';

  @override
  String get bottomRight => 'Внизу справа';

  @override
  String get cancel => 'Отмена';

  @override
  String get choose => 'Выбирать';

  @override
  String get chooseLocation => 'Выберите местоположение';

  @override
  String get copy => 'Копировать';

  @override
  String get create => 'Создавать';

  @override
  String get creating => 'Создание...';

  @override
  String get cut => 'Резать';

  @override
  String get darkTheme => 'Темный';

  @override
  String get discard => 'Отказаться';

  @override
  String get editor => 'Редактор';

  @override
  String get file => 'Файл';

  @override
  String get find => 'Находить';

  @override
  String get folder => 'Папка';

  @override
  String get insert => 'Вставлять';

  @override
  String get keyboardShortcuts => 'Сочетания клавиш';

  @override
  String get lightTheme => 'Свет';

  @override
  String get mainMenu => 'Главное меню';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Открыть';

  @override
  String get outline => 'Контур';

  @override
  String get overwrite => 'Перезаписать';

  @override
  String get paste => 'Вставить';

  @override
  String get pasteWithoutFormatting => 'Вставить без форматирования';

  @override
  String get preview => 'Предварительный просмотр';

  @override
  String get recent => 'Недавний';

  @override
  String get redo => 'Повторить';

  @override
  String get save => 'Сохранять';

  @override
  String get search => 'Поиск';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get settings => 'Настройки';

  @override
  String get source => 'Источник';

  @override
  String get split => 'Расколоть';

  @override
  String get systemTheme => 'Система';

  @override
  String get theme => 'Тема';

  @override
  String get appLanguage => 'Язык';

  @override
  String get systemLanguage => 'Системный';

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
  String get toggleSidebar => 'Переключить боковую панель';

  @override
  String get topLeft => 'Вверху слева';

  @override
  String get topRight => 'Вверху справа';

  @override
  String get undo => 'Отменить';

  @override
  String get validate => 'Подтвердить';

  @override
  String get validation => 'Валидация';

  @override
  String get viewMode => 'Режим просмотра';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => 'Изображения';

  @override
  String get openMarkdownFile => 'Открыть файл Markdown';

  @override
  String get markdownFileExtensions => '.md or .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Открыть папку или проект Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Папка Markdown или проект, совместимый с Writerside.';

  @override
  String get shortcutGroupFile => 'Файл';

  @override
  String get shortcutNewDocument => 'Новый документ';

  @override
  String get shortcutNewDocumentDescription =>
      'Создайте новый несохраненный документ Markdown.';

  @override
  String get shortcutOpenDescription =>
      'Открыть файл Markdown, папку или проект Writerside';

  @override
  String get shortcutSaveDescription => 'Сохраните текущий файл Markdown';

  @override
  String get shortcutFindDescription => 'Поиск в текущей рабочей области';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Показать эту ссылку на сочетания клавиш';

  @override
  String get shortcutGroupTextEditing => 'Редактирование текста';

  @override
  String get shortcutSelectAllDescription => 'Выделить весь текст редактора';

  @override
  String get shortcutCutDescription => 'Вырезать выделенный текст';

  @override
  String get shortcutCopyDescription => 'Скопировать выделенный текст';

  @override
  String get shortcutPasteDescription => 'Вставить из буфера обмена';

  @override
  String get shortcutPastePlainTextDescription =>
      'Вставить текст из буфера обмена без форматирования';

  @override
  String get shortcutUndoDescription => 'Отменить последнее редактирование';

  @override
  String get shortcutRedoDescription =>
      'Повторить последнее отмененное редактирование';

  @override
  String get clearEditorSelection => 'Очистить выбор редактора';

  @override
  String get shortcutClearEditorSelectionDescription =>
      'Оставить текущий выбор редактора или фокус поиска';

  @override
  String get shortcutGroupFormatting => 'Форматирование';

  @override
  String get shortcutBoldDescription =>
      'Переключить жирный шрифт на выделенный текст';

  @override
  String get shortcutItalicDescription =>
      'Переключить курсив на выделенный текст';

  @override
  String get shortcutUnderlineDescription =>
      'Переключить подчеркивание выделенного текста';

  @override
  String get shortcutLinkDescription => 'Вставка или редактирование ссылки';

  @override
  String get shortcutInlineCodeDescription =>
      'Переключить встроенный код в выделенном тексте';

  @override
  String get shortcutStrikethroughDescription =>
      'Переключить зачеркивание выделенного текста';

  @override
  String get shortcutGroupBlocks => 'Блоки';

  @override
  String get shortcutParagraphDescription => 'Установить текущий блок в абзац';

  @override
  String get shortcutHeading1Description =>
      'Установить текущий блок на заголовок 1';

  @override
  String get shortcutHeading2Description =>
      'Установить текущий блок на заголовок 2';

  @override
  String get shortcutHeading3Description =>
      'Установить текущий блок на заголовок 3';

  @override
  String get shortcutHeading4Description =>
      'Установите текущий блок на заголовок 4.';

  @override
  String get shortcutHeading5Description =>
      'Установить текущий блок на заголовок 5';

  @override
  String get shortcutHeading6Description =>
      'Установите текущий блок на заголовок 6.';

  @override
  String get shortcutGroupLists => 'Списки';

  @override
  String get numberedList => 'Нумерованный список';

  @override
  String get shortcutNumberedListDescription =>
      'Переключить форматирование нумерованного списка';

  @override
  String get bulletedList => 'Маркированный список';

  @override
  String get shortcutBulletedListDescription =>
      'Переключить форматирование маркированного списка';

  @override
  String get checklist => 'Контрольный список';

  @override
  String get shortcutChecklistDescription =>
      'Переключить форматирование контрольного списка';

  @override
  String get createMarkdownFile => 'Создать файл Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Запустите несохраненный локальный документ Markdown.';

  @override
  String get createWritersideProject => 'Создать проект Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Запустите локальный проект, совместимый с Writerside.';

  @override
  String get defaultProjectName => 'Документация';

  @override
  String get defaultInstanceName => 'Руководство пользователя';

  @override
  String get defaultStartTopicTitle => 'Начиная';

  @override
  String get projectName => 'Название проекта';

  @override
  String get directoryName => 'Имя каталога';

  @override
  String get instanceName => 'Имя экземпляра';

  @override
  String get instanceId => 'ID экземпляра';

  @override
  String get startTopicTitle => 'Начало названия темы';

  @override
  String get location => 'Расположение';

  @override
  String get projectNameRequired => 'Укажите название проекта.';

  @override
  String get directoryNameRequired => 'Требуется имя каталога.';

  @override
  String get useSingleSafeDirectoryName =>
      'Используйте одно безопасное имя каталога.';

  @override
  String get useLowercaseIdentifier =>
      'Используйте идентификатор в нижнем регистре с буквами, цифрами, подчеркиваниями или дефисами.';

  @override
  String get startTopicTitleRequired => 'Укажите название стартовой темы.';

  @override
  String get createWritersideProjectFailed =>
      'Не удалось создать проект Writerside.';

  @override
  String get settingsTitle => 'Настройки BusyMark';

  @override
  String get wordWrap => 'перенос слов';

  @override
  String get editorFontSize => 'Размер шрифта редактора';

  @override
  String get validateOnEdit => 'Подтвердить редактирование';

  @override
  String get clearRecentWorkspaces => 'Очистить недавние рабочие области';

  @override
  String get editingButtons => 'Редактирование кнопок';

  @override
  String get editingButtonsDescription =>
      'Выберите, где будут появляться плавающие кнопки редактирования WYSIWYG.';

  @override
  String get currentFile => 'текущий файл';

  @override
  String get unsavedChanges => 'Несохраненные изменения';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'У вас есть несохраненные изменения в $fileName. Сохранить их, прежде чем продолжить?';
  }

  @override
  String get fileChangedOnDisk => 'Файл изменен на диске';

  @override
  String get fileChangedOnDiskMessage =>
      'Этот файл изменился на диске с тех пор, как вы его открыли. Перезаписать?';

  @override
  String get untitledMarkdownFileName => 'Без названия.md';

  @override
  String get unorderedList => 'Неупорядоченный список';

  @override
  String get orderedList => 'Упорядоченный список';

  @override
  String get taskList => 'Список задач';

  @override
  String get toggleTaskChecked => 'Переключить задачу отмечено';

  @override
  String get indentListItem => 'Отступ элемента списка';

  @override
  String get outdentListItem => 'Отступ элемента списка';

  @override
  String get blockquote => 'Цитата';

  @override
  String get codeBlock => 'Кодовый блок';

  @override
  String get codeBlockLanguage => 'Язык кодовых блоков';

  @override
  String get image => 'Изображение';

  @override
  String get inlineImage => 'Встроенное изображение';

  @override
  String get table => 'Стол';

  @override
  String get thematicBreak => 'Тематическая пауза';

  @override
  String get bold => 'Смелый';

  @override
  String get italic => 'Курсив';

  @override
  String get underline => 'Подчеркнуть';

  @override
  String get strikethrough => 'Зачеркивание';

  @override
  String get inlineCode => 'Встроенный код';

  @override
  String get link => 'Связь';

  @override
  String get hardLineBreak => 'Жесткий разрыв строки';

  @override
  String get textStyle => 'Стиль текста';

  @override
  String get paragraph => 'Параграф';

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
  String get deleteTable => 'Удалить таблицу';

  @override
  String tableColumnNumber(int columnNumber) {
    return 'Столбец $columnNumber';
  }

  @override
  String get insertColumnLeft => 'Вставить столбец слева';

  @override
  String get insertColumnRight => 'Вставить столбец справа';

  @override
  String get deleteColumn => 'Удалить столбец';

  @override
  String tableRowNumber(int rowNumber) {
    return 'Строка $rowNumber';
  }

  @override
  String get insertRowAbove => 'Вставить строку выше';

  @override
  String get insertRowBelow => 'Вставить строку ниже';

  @override
  String get deleteRow => 'Удалить строку';

  @override
  String get tableHeaderHint => 'Заголовок';

  @override
  String get tableCellHint => 'Клетка';

  @override
  String get language => 'Язык';

  @override
  String get hideEditingButtons => 'Скрыть кнопки редактирования';

  @override
  String get showEditingButtons => 'Показать кнопки редактирования';

  @override
  String get altText => 'Альтернативный текст';

  @override
  String get describeTheImage => 'Опишите изображение';

  @override
  String get columns => 'Столбцы';

  @override
  String get rows => 'Строки';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'Заголовок $columnNumber';
  }

  @override
  String get tableCellDefault => 'Клетка';

  @override
  String get noImageSource => 'Нет источника изображения';

  @override
  String get hideSidebar => 'Скрыть боковую панель';

  @override
  String get showSidebar => 'Показать боковую панель';

  @override
  String get showPreview => 'Показать предварительный просмотр';

  @override
  String get hidePreview => 'Скрыть предварительный просмотр';

  @override
  String get workspaceKindUnsavedMarkdown => 'Несохраненный файл Markdown';

  @override
  String get workspaceKindSingleMarkdown => 'Отдельный файл Markdown';

  @override
  String get workspaceKindMarkdownFolder => 'Папка Markdown';

  @override
  String get workspaceKindWritersideModule => 'Модуль Writerside';

  @override
  String get problems => 'Проблемы';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count диагностики',
      many: '$count диагностик',
      few: '$count диагностики',
      one: '$count диагностика',
      zero: 'Нет диагностик',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Файлы';

  @override
  String get toc => 'TOC';

  @override
  String get markdownUnsaved => 'Markdown — не сохранено';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла',
      many: '$count файлов',
      few: '$count файла',
      one: '$count файл',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'Нет файлов';

  @override
  String get noWritersideToc => 'Нет TOC Writerside';

  @override
  String get tocSection => 'Раздел TOC';

  @override
  String get newTopic => 'Новая тема';

  @override
  String get newChildTopic => 'Новая дочерняя тема';

  @override
  String get defaultNewTopicTitle => 'Новая тема';

  @override
  String get topicTitle => 'Название темы';

  @override
  String get fileName => 'Имя файла';

  @override
  String get topicTitleRequired => 'Требуется название темы.';

  @override
  String get fileNameRequired => 'Требуется имя файла.';

  @override
  String get useSingleSafeFileName => 'Используйте одно безопасное имя файла.';

  @override
  String useExpectedExtension(String extension) {
    return 'Используйте расширение $extension для выбранного формата.';
  }

  @override
  String get useIdentifierCharacters =>
      'Перед расширением используйте буквы, цифры, подчеркивания или дефисы.';

  @override
  String get topicIdAlreadyExists => 'ID темы уже существует.';

  @override
  String get createWritersideTopicFailed =>
      'Не удалось создать тему Writerside.';

  @override
  String get noOutline => 'Нет контура';

  @override
  String expandKind(String kind) {
    return 'Развернуть $kind';
  }

  @override
  String collapseKind(String kind) {
    return 'Свернуть $kind';
  }

  @override
  String get foldKindSection => 'раздел';

  @override
  String get foldKindList => 'список';

  @override
  String get foldKindQuote => 'цитировать';

  @override
  String get foldKindTag => 'ярлык';

  @override
  String get noPreview => 'Нет предварительного просмотра';

  @override
  String get note => 'Примечание';

  @override
  String get tip => 'Кончик';

  @override
  String get warning => 'Предупреждение';

  @override
  String get tabs => 'Вкладки';

  @override
  String get tab => 'Вкладка';

  @override
  String get procedure => 'Процедура';

  @override
  String get step => 'Шаг';

  @override
  String get topic => 'Тема';

  @override
  String get chapter => 'Глава';

  @override
  String couldNotOpenTarget(String target) {
    return 'Не удалось открыть $target';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'Цель ссылки не найдена: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor =>
      'Невозможно открыть этот тип файла в редакторе';

  @override
  String anchorNotFound(String anchor) {
    return 'Якорь не найден: $anchor';
  }

  @override
  String get noProblemsFound => 'Проблем не обнаружено';

  @override
  String get noResults => 'Нет результатов';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath — Строка $lineNumber';
  }

  @override
  String get untitledResult => 'Результат без названия';

  @override
  String get documentKindMarkdownFile => 'Файл Markdown';

  @override
  String get documentKindWritersideMarkdownTopic =>
      'Тема Markdown для Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'Тема Writerside XML';

  @override
  String get documentKindWritersideTree => 'Дерево Writerside';

  @override
  String get documentKindConfigurationFile => 'Конфигурационный файл';

  @override
  String get documentKindVariablesFile => 'Файл переменных';

  @override
  String get documentKindCategoriesFile => 'Файл категорий';

  @override
  String get documentKindResourceFile => 'Файл ресурсов';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Открытие не удалось: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Не удалось создать проект Writerside: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Не удалось создать тему Writerside: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'Не удалось открыть файл: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'Выберите, где сохранить этот файл Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Сохранение заблокировано: файл на диске изменен.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return 'Проверка не удалась: $error';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'Путь не существует: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return 'Целевой каталог уже существует и не пуст: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return 'Целевой путь уже существует и не является каталогом: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return 'Сгенерированный файл уже существует: $path';
  }

  @override
  String get errorParentDirectoryRequired => 'Требуется родительский каталог.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Родительский каталог не существует: $path';
  }

  @override
  String get errorProjectNameRequired => 'Укажите название проекта.';

  @override
  String get errorDirectoryNameRequired => 'Требуется имя каталога.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Имя каталога должно представлять собой один сегмент безопасного пути.';

  @override
  String get errorInstanceIdInvalid =>
      'ID экземпляра должен начинаться со строчной буквы и содержать только строчные буквы, цифры, символы подчеркивания и дефисы.';

  @override
  String get errorTopicFileInvalid =>
      'Имя файла темы должно быть именем файла Markdown без разделителей пути.';

  @override
  String get errorTopicTitleRequired => 'Требуется название темы.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Корень модуля Writerside не существует: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Для создания темы модуль Writerside должен быть открыт.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Модуль Writerside не имеет дерева экземпляров справки.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Файл дерева Writerside не существует: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'ID темы \"$topicId\" уже существует в этом модуле справки.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Файл темы уже существует: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Справочная тема отсутствует в выбранном дереве: $topic';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Корень темы должен быть безопасным относительным каталогом.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Имя файла темы должно представлять собой один сегмент безопасного пути.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Расширение файла темы должно соответствовать выбранному формату ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Имя файла темы должно содержать только буквы, цифры, символы подчеркивания и дефисы.';

  @override
  String errorUnknown(String code) {
    return 'Неизвестная ошибка: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'Не удалось прочитать метаданные файла: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      'Обнаружено большое рабочее пространство. Некоторые файлы были пропущены, чтобы приложение быстрее реагировало.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Не удалось проверить запись рабочей области: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Размер файла превышает предел автоматического анализа бета-версии.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Не удалось прочитать файл Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Неверный блок атрибутов заголовка Writerside.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Дублирующийся ID заголовка \"$id\".';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Дополнительные заголовки H1 верхнего уровня рассматриваются как главы.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Тема Writerside Markdown не имеет заголовка H1 или заголовка.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'В теме XML отсутствует заголовок.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'Теме «$fileName» не хватает названия.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Передняя часть не закрыта.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => 'Небезопасный HTML-элемент.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'Цель ссылки не существует: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'Якорь «$anchor» не существует.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return 'На изображении «$destination» отсутствует замещающий текст.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Изображение не существует: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Неверный XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Корневой файл writeside.cfg должен быть <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'В объявлении фрагментов отсутствует src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'В объявлении групп экземпляров отсутствует src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Неподдерживаемый режим раскладки клавиатуры: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'В объявлении экземпляра отсутствует src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writeside.cfg не регистрирует экземпляр.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Корень .tree должен быть <профиль-экземпляра>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'В профиле экземпляра отсутствует идентификатор.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Основа файла дерева не соответствует идентификатору экземпляра «$id».';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'В экземпляре, не являющемся библиотекой, отсутствует стартовая страница.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Стартовая страница «$startPage» не существует.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Тема \"$topic\" встречается в этом TOC более одного раза.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Объявление переменной должно иметь имя и значение.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Переменная «$name» объявляется более одного раза.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'В категории отсутствует идентификатор.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Категория «$id» объявлена ​​более одного раза.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Порядок категории «$order» объявляется более одного раза.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Корень .topic должен быть <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'В теме XML отсутствует корневой идентификатор.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Корневой идентификатор темы XML «$id» должен соответствовать имени файла «$expectedId».';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'Идентификатор элемента «$elementId» появляется более одного раза.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'В <a> отсутствует href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Для режима Writerside требуется файл Writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Отсутствует настроенный каталог конфигурации сборки: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Отсутствует настроенный каталог спецификаций API: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Отсутствует настроенный каталог фрагментов: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Файл сконфигурированных переменных отсутствует: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Файл настроенных категорий отсутствует: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Отсутствует файл настроенных групп экземпляров: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Зарегистрированное дерево экземпляров «$source» не существует.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'Не удалось прочитать файл темы: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'Отсутствует каталог тем по умолчанию: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return 'Отсутствует каталог настроенных тем: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Отсутствует каталог настроенных изображений: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'Идентификатор элемента «$id» появляется более одного раза.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC ссылается на отсутствующую тему \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Внешняя ссылка \"$href\" недействительна.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Переменная \"%$name%\" не объявлена.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Ссылка на тему «$destination» не разрешается.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Привязка «$anchor» не существует в «$targetName».';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom => '<include> отсутствует.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Включить источник \"$from\" не существует.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return 'Включаемый элемент «$elementId» не существует в «$from».';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'См. также, категория «$ref» не объявлена.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Ссылка на тему «$reference» неоднозначна.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Неизвестная диагностика: $code';
  }
}
