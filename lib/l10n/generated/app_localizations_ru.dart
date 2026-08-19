// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

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
      'Редактор файлов Markdown и проектов документации, совместимых с Writerside.';

  @override
  String get aboutBusyMark => 'О приложении BusyMark';

  @override
  String get aboutTagline => 'Редактор Markdown и Writerside-проектов';

  @override
  String get aboutLicenseLabel => 'Лицензия';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'Веб-сайт';

  @override
  String get aboutSourceCode => 'Исходный код';

  @override
  String get reportIssue => 'Сообщить о проблеме';

  @override
  String get feedbackCategory => 'Категория';

  @override
  String get feedbackChooseCategory => 'Выберите категорию';

  @override
  String get feedbackCategoryProblem => 'Проблема или ошибка';

  @override
  String get feedbackCategoryFeature => 'Запрос функции';

  @override
  String get feedbackCategoryPrivacySecurity =>
      'Проблема конфиденциальности или безопасности';

  @override
  String get feedbackCategoryUsability => 'Проблема удобства использования';

  @override
  String get feedbackCategoryOther => 'Другое';

  @override
  String get feedbackSubject => 'Тема';

  @override
  String get feedbackMessage => 'Подробное сообщение';

  @override
  String get feedbackReplyEmail => 'Эл. почта для ответа (необязательно)';

  @override
  String get feedbackIncludeTechnicalDetails => 'Включить технические сведения';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      'Если этот параметр включён, добавляются только версия операционной системы Linux и язык и регион приложения BusyMark. Журналы, файлы, данные учётной записи и другие диагностические сведения не прикрепляются.';

  @override
  String get feedbackSubmit => 'Отправить';

  @override
  String get feedbackSubmitting => 'Отправка…';

  @override
  String get feedbackCategoryRequired => 'Выберите категорию.';

  @override
  String get feedbackSubjectLength =>
      'Тема должна содержать от 3 до 120 символов.';

  @override
  String get feedbackMessageLength =>
      'Сообщение должно содержать от 10 до 5000 символов.';

  @override
  String get feedbackReplyEmailInvalid =>
      'Введите действительный адрес электронной почты или оставьте поле пустым.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark не удалось подключиться. Проверьте интернет-соединение и повторите попытку.';

  @override
  String get feedbackTimeoutFailure =>
      'Время ожидания запроса истекло. Повторите попытку.';

  @override
  String get feedbackRateLimitedFailure =>
      'Из этого соединения отправлено слишком много отчётов. Подождите и повторите попытку.';

  @override
  String get feedbackRejectedFailure =>
      'Сервер отклонил сообщение. Проверьте поля формы и повторите попытку.';

  @override
  String get feedbackServerFailure =>
      'Сервер не смог принять отчёт. Повторите попытку позже.';

  @override
  String feedbackSuccess(String id) {
    return 'Отзыв отправлен. Идентификатор обращения: $id';
  }

  @override
  String get advanced => 'Дополнительно';

  @override
  String get addToGit => 'Добавить в Git';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get apply => 'Применить';

  @override
  String get back => 'Назад';

  @override
  String get bottomLeft => 'Внизу слева';

  @override
  String get bottomRight => 'Внизу справа';

  @override
  String get cancel => 'Отмена';

  @override
  String get choose => 'Выбрать';

  @override
  String get chooseLocation => 'Выбрать расположение';

  @override
  String get copy => 'Копировать';

  @override
  String get copyName => 'Копировать имя';

  @override
  String get copyFileName => 'Копировать имя файла';

  @override
  String get copyPath => 'Копировать путь';

  @override
  String get create => 'Создать';

  @override
  String get creating => 'Создание…';

  @override
  String get cut => 'Вырезать';

  @override
  String get promoteSection => 'Повысить уровень раздела';

  @override
  String get demoteSection => 'Понизить уровень раздела';

  @override
  String get moveSectionUp => 'Переместить раздел вверх';

  @override
  String get moveSectionDown => 'Переместить раздел вниз';

  @override
  String get confirmDeleteSectionTitle => 'Удалить раздел?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return 'Удалить раздел «$name» со всем его содержимым? Это действие нельзя отменить.';
  }

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get delete => 'Удалить';

  @override
  String get discard => 'Не сохранять';

  @override
  String get editor => 'Редактор';

  @override
  String get file => 'Файл';

  @override
  String get fileHistory => 'История файла';

  @override
  String get folder => 'Папка';

  @override
  String get insert => 'Вставить';

  @override
  String get keyboardShortcuts => 'Сочетания клавиш';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get mainMenu => 'Главное меню';

  @override
  String get fullScreen => 'Полноэкранный режим';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => 'Открыть';

  @override
  String get openInFiles => 'Открыть в Файлах';

  @override
  String get pathActions => 'Действия с путём';

  @override
  String get outline => 'Структура';

  @override
  String get overwrite => 'Перезаписать';

  @override
  String get paste => 'Вставить';

  @override
  String get pasteWithoutFormatting => 'Вставить без форматирования';

  @override
  String get preview => 'Предварительный просмотр';

  @override
  String get recent => 'Недавние';

  @override
  String get redo => 'Повторить';

  @override
  String get save => 'Сохранить';

  @override
  String get search => 'Поиск';

  @override
  String get selectAll => 'Выделить всё';

  @override
  String get settings => 'Настройки';

  @override
  String get source => 'Исходный текст';

  @override
  String get split => 'Разделённый вид';

  @override
  String get systemTheme => 'Как в системе';

  @override
  String get theme => 'Тема оформления';

  @override
  String get appLanguage => 'Язык интерфейса';

  @override
  String get systemLanguage => 'Как в системе';

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
  String get toggleSidebar => 'Боковая панель';

  @override
  String get topLeft => 'Вверху слева';

  @override
  String get topRight => 'Вверху справа';

  @override
  String get undo => 'Отменить';

  @override
  String get validate => 'Проверить';

  @override
  String get validation => 'Проверка';

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
  String get markdownFileExtensions => '.md или .markdown';

  @override
  String get openFolderOrWritersideProject =>
      'Открыть папку или проект Writerside';

  @override
  String get markdownFolderOrWritersideProject =>
      'Папка с Markdown или проект, совместимый с Writerside';

  @override
  String get noOpenFile => 'Нет открытого файла';

  @override
  String get shortcutDeleteTreeItemDescription =>
      'Удалить выбранный элемент в разделе «Файлы» или убрать выбранную тему из оглавления';

  @override
  String get shortcutGroupGeneral => 'Общие';

  @override
  String get shortcutNewDocument => 'Создать';

  @override
  String get shortcutNewDocumentDescription =>
      'Создать файл Markdown или проект Writerside';

  @override
  String get shortcutOpenDescription =>
      'Открыть файл Markdown, папку или проект Writerside';

  @override
  String get shortcutSaveDescription => 'Сохранить текущий документ';

  @override
  String get shortcutSearchDescription =>
      'Искать в текущем рабочем пространстве';

  @override
  String get shortcutKeyboardShortcutsDescription =>
      'Показать справку по сочетаниям клавиш';

  @override
  String get shortcutMarkdownAndHtmlDescription =>
      'Открыть справку по Markdown и HTML';

  @override
  String get shortcutSettingsDescription => 'Открыть настройки BusyMark';

  @override
  String get shortcutNextTab => 'Следующая вкладка';

  @override
  String get shortcutNextTabDescription =>
      'Перейти к следующей открытой вкладке';

  @override
  String get shortcutPreviousTab => 'Предыдущая вкладка';

  @override
  String get shortcutPreviousTabDescription =>
      'Перейти к предыдущей открытой вкладке';

  @override
  String get shortcutCloseTab => 'Закрыть вкладку';

  @override
  String get shortcutCloseTabDescription => 'Закрыть активную вкладку';

  @override
  String get shortcutCloseAllTabs => 'Закрыть все вкладки';

  @override
  String get shortcutCloseAllTabsDescription => 'Закрыть все открытые вкладки';

  @override
  String get shortcutGroupTextEditing => 'Редактирование текста';

  @override
  String get shortcutSelectAllDescription =>
      'В режиме исходного текста выделить весь текст; в режиме редактора нажать дважды, чтобы выделить все блоки';

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
  String get shortcutUndoDescription => 'Отменить последнее изменение';

  @override
  String get shortcutRedoDescription =>
      'Повторить последнее отменённое изменение';

  @override
  String get shortcutInsertIndentation => 'Вставить отступ';

  @override
  String get shortcutInsertIndentationDescription =>
      'Вставить отступ в позицию курсора';

  @override
  String get shortcutOutdentSource => 'Уменьшить отступ в исходном тексте';

  @override
  String get shortcutOutdentSourceDescription =>
      'Убрать один уровень отступа в режиме исходного текста';

  @override
  String get shortcutEscape => 'Закрыть поиск или снять выделение блоков';

  @override
  String get shortcutEscapeDescription =>
      'Закрыть поиск по рабочему пространству или снять выделение блоков в режиме редактора';

  @override
  String get shortcutGroupFormatting => 'Форматирование';

  @override
  String get shortcutBoldDescription =>
      'Включить или отключить полужирное начертание для выделенного текста';

  @override
  String get shortcutItalicDescription =>
      'Включить или отключить курсив для выделенного текста';

  @override
  String get shortcutUnderlineDescription =>
      'Включить или отключить подчёркивание для выделенного текста';

  @override
  String get shortcutLinkDescription => 'Вставить или изменить ссылку';

  @override
  String get shortcutInlineCodeDescription =>
      'Включить или отключить встроенный код для выделенного текста';

  @override
  String get shortcutStrikethroughDescription =>
      'Включить или отключить зачёркивание для выделенного текста';

  @override
  String get shortcutGroupBlocks => 'Блоки';

  @override
  String get shortcutParagraphDescription => 'Сделать текущий блок абзацем';

  @override
  String get shortcutHeading1Description => 'Сделать текущий блок заголовком 1';

  @override
  String get shortcutHeading2Description => 'Сделать текущий блок заголовком 2';

  @override
  String get shortcutHeading3Description => 'Сделать текущий блок заголовком 3';

  @override
  String get shortcutHeading4Description => 'Сделать текущий блок заголовком 4';

  @override
  String get shortcutHeading5Description => 'Сделать текущий блок заголовком 5';

  @override
  String get shortcutHeading6Description => 'Сделать текущий блок заголовком 6';

  @override
  String get shortcutGroupLists => 'Списки';

  @override
  String get numberedList => 'Нумерованный список';

  @override
  String get shortcutNumberedListDescription =>
      'Включить или отключить форматирование нумерованного списка';

  @override
  String get bulletedList => 'Маркированный список';

  @override
  String get shortcutBulletedListDescription =>
      'Включить или отключить форматирование маркированного списка';

  @override
  String get checklist => 'Контрольный список';

  @override
  String get shortcutChecklistDescription =>
      'Включить или отключить форматирование списка задач';

  @override
  String get shortcutGroupSidebar => 'Боковая панель';

  @override
  String get sidebarViewMenu => 'Вид боковой панели';

  @override
  String get createMarkdownFile => 'Создать файл Markdown';

  @override
  String get createMarkdownFileDescription =>
      'Создать локальный несохранённый документ Markdown';

  @override
  String get createWritersideProject => 'Создать проект Writerside';

  @override
  String get createWritersideProjectDescription =>
      'Создать локальный проект, совместимый с Writerside';

  @override
  String get defaultProjectName => 'Документация';

  @override
  String get defaultInstanceName => 'Руководство пользователя';

  @override
  String get defaultStartTopicTitle => 'Начало работы';

  @override
  String get projectName => 'Название проекта';

  @override
  String get directoryName => 'Имя каталога';

  @override
  String get instanceName => 'Имя экземпляра';

  @override
  String get instanceId => 'ID экземпляра';

  @override
  String get startTopicTitle => 'Заголовок стартовой темы';

  @override
  String get location => 'Расположение';

  @override
  String get projectNameRequired => 'Укажите название проекта.';

  @override
  String get directoryNameRequired => 'Укажите имя каталога.';

  @override
  String get useSingleSafeDirectoryName =>
      'Используйте одно допустимое имя каталога.';

  @override
  String get useLowercaseIdentifier =>
      'Используйте идентификатор в нижнем регистре: буквы, цифры, подчёркивания или дефисы.';

  @override
  String get startTopicTitleRequired => 'Укажите заголовок стартовой темы.';

  @override
  String get createWritersideProjectFailed =>
      'Не удалось создать проект Writerside.';

  @override
  String get settingsTitle => 'Настройки BusyMark';

  @override
  String get autoSave => 'Автосохранение';

  @override
  String get autoSaveDescription =>
      'Автоматически сохранять изменения в файле после короткой паузы бездействия.';

  @override
  String get wordWrap => 'Перенос строк';

  @override
  String get editorFontSize => 'Размер шрифта редактора';

  @override
  String get validateOnEdit => 'Проверять при редактировании';

  @override
  String get clearRecentWorkspaces =>
      'Очистить список недавних рабочих областей';

  @override
  String get editingButtonsPosition => 'Положение кнопок редактирования';

  @override
  String get editingButtonsPositionDescription =>
      'Выберите, где будут отображаться плавающие кнопки редактирования WYSIWYG.';

  @override
  String get editingButtonsDirection => 'Ориентация кнопок редактирования';

  @override
  String get editingButtonsDirectionDescription =>
      'Выберите, как расположить плавающие кнопки редактирования WYSIWYG: горизонтально или вертикально.';

  @override
  String get horizontal => 'Горизонтально';

  @override
  String get vertical => 'Вертикально';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get allowRemoteImages => 'Загружать удалённые изображения';

  @override
  String get allowRemoteImagesDescription =>
      'Разрешить загрузку изображений в предварительном просмотре Markdown и редакторе по URL-адресам http и https.';

  @override
  String get clearRemoteImagePermissions =>
      'Сбросить разрешения на удалённые изображения';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'Забыть рабочие области, которым было разрешено загружать удалённые изображения.';

  @override
  String get clearGitWorkspaceTrust =>
      'Очистить список доверенных рабочих областей Git';

  @override
  String get clearGitWorkspaceTrustDescription =>
      'Спрашивать перед включением функций Git для ранее доверенных рабочих областей.';

  @override
  String get settingsWindowSectionTitle => 'Окно';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      'Подтверждать закрытие при несохранённых изменениях';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'Спрашивать перед закрытием BusyMark, если в документах есть несохранённые изменения.';

  @override
  String get closeUnsavedChangesTitle => 'Несохранённые изменения';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'В этом документе есть несохранённые изменения. Сохранить изменения перед закрытием BusyMark?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'В $count документах есть несохранённые изменения. Сохранить изменения перед закрытием BusyMark?',
      many:
          'В $count документах есть несохранённые изменения. Сохранить изменения перед закрытием BusyMark?',
      few:
          'В $count документах есть несохранённые изменения. Сохранить изменения перед закрытием BusyMark?',
      one:
          'В $count документе есть несохранённые изменения. Сохранить изменения перед закрытием BusyMark?',
      zero: 'Сохранить изменения перед закрытием BusyMark?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'Отмена';

  @override
  String get closeUnsavedChangesDiscard => 'Не сохранять';

  @override
  String get closeUnsavedChangesSave => 'Сохранить';

  @override
  String get currentFile => 'текущий файл';

  @override
  String get unsavedChanges => 'Несохранённые изменения';

  @override
  String unsavedChangesMessage(String fileName) {
    return 'В файле $fileName есть несохранённые изменения. Сохранить их перед продолжением?';
  }

  @override
  String get fileChangedOnDisk => 'Файл изменён на диске';

  @override
  String get fileChangedOnDiskMessage =>
      'Этот файл был изменён на диске после открытия. Перезаписать его?';

  @override
  String get untitledMarkdownFileName => 'Без названия.md';

  @override
  String get unorderedList => 'Маркированный список';

  @override
  String get orderedList => 'Нумерованный список';

  @override
  String get taskList => 'Список задач';

  @override
  String get toggleTaskChecked => 'Установить или снять отметку с задачи';

  @override
  String get indentListItem => 'Увеличить отступ элемента списка';

  @override
  String get outdentListItem => 'Уменьшить отступ элемента списка';

  @override
  String get blockquote => 'Цитата';

  @override
  String get codeBlock => 'Блок кода';

  @override
  String get codeBlockLanguage => 'Язык блока кода';

  @override
  String get image => 'Изображение';

  @override
  String get inlineImage => 'Встроенное изображение';

  @override
  String get table => 'Таблица';

  @override
  String get htmlBlock => 'Блок HTML';

  @override
  String get htmlContentDefault => 'Содержимое HTML';

  @override
  String get shortcutHtmlBlockDescription => 'Вставить или изменить блок HTML';

  @override
  String get renderedHtml => 'Отрисованный HTML';

  @override
  String get editHtml => 'Редактировать HTML';

  @override
  String get htmlSource => 'Исходный HTML';

  @override
  String get thematicBreak => 'Горизонтальная линия';

  @override
  String get bold => 'Полужирный';

  @override
  String get italic => 'Курсив';

  @override
  String get underline => 'Подчёркивание';

  @override
  String get strikethrough => 'Зачёркивание';

  @override
  String get inlineCode => 'Встроенный код';

  @override
  String get link => 'Ссылка';

  @override
  String get hardLineBreak => 'Принудительный перенос строки';

  @override
  String get textStyle => 'Стиль текста';

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
  String get tableCellHint => 'Ячейка';

  @override
  String get language => 'Язык';

  @override
  String get hideEditingButtons => 'Скрыть кнопки редактирования';

  @override
  String get showEditingButtons => 'Показать кнопки редактирования';

  @override
  String get altText => 'Альтернативный текст';

  @override
  String get editorPlaceholderText => 'текст';

  @override
  String get editorPlaceholderCode => 'код';

  @override
  String get editorPlaceholderAltText => 'альтернативный текст';

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
  String get tableCellDefault => 'Ячейка';

  @override
  String get noImageSource => 'Источник изображения не указан';

  @override
  String get remoteImageBlocked => 'Удалённое изображение заблокировано';

  @override
  String get remoteImageBlockedTooltip =>
      'Выберите, может ли BusyMark загружать удалённые изображения.';

  @override
  String get remoteImagesBlockedTitle => 'Удалённые изображения заблокированы';

  @override
  String get remoteImagesBlockedMessage =>
      'Этот документ ссылается на изображения из интернета. Их загрузка может раскрыть сведения о вашей сети серверам, на которых размещены изображения.';

  @override
  String get loadRemoteImagesForWorkspace =>
      'Загрузить для этой рабочей области';

  @override
  String get alwaysLoadRemoteImages => 'Всегда загружать удалённые изображения';

  @override
  String get hideSidebar => 'Скрыть боковую панель';

  @override
  String get showSidebar => 'Показать боковую панель';

  @override
  String get showPreview => 'Показать предварительный просмотр';

  @override
  String get hidePreview => 'Скрыть предварительный просмотр';

  @override
  String get workspaceKindUnsavedMarkdown => 'Несохранённый файл Markdown';

  @override
  String get workspaceKindSingleMarkdown => 'Отдельный файл Markdown';

  @override
  String get workspaceKindMarkdownFolder => 'Папка с Markdown';

  @override
  String get workspaceKindWritersideModule => 'Модуль Writerside';

  @override
  String get problems => 'Проблемы';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count диагностического сообщения',
      many: '$count диагностических сообщений',
      few: '$count диагностических сообщения',
      one: '$count диагностическое сообщение',
      zero: 'Нет диагностических сообщений',
    );
    return '$_temp0';
  }

  @override
  String get files => 'Файлы';

  @override
  String get toc => 'Оглавление';

  @override
  String get tocActions => 'Действия с оглавлением';

  @override
  String get markdownUnsaved => 'Markdown — не сохранён';

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
    return '$kind — $_temp0';
  }

  @override
  String get noFiles => 'Файлов нет';

  @override
  String get newFile => 'Новый файл';

  @override
  String get noWritersideToc => 'Оглавление Writerside отсутствует';

  @override
  String get tocSection => 'Раздел оглавления';

  @override
  String get newTopic => 'Новая тема';

  @override
  String get newChildTopic => 'Новая дочерняя тема';

  @override
  String get newSiblingTopic => 'Новая тема на том же уровне';

  @override
  String get renameTopicFile => 'Переименовать файл темы';

  @override
  String get topicPlacement => 'Расположение в оглавлении';

  @override
  String get tocRoot => 'В корне оглавления';

  @override
  String get afterSelectedTopic => 'После выбранной темы';

  @override
  String get insideSelectedTopic => 'Внутри выбранной темы';

  @override
  String get pasteAfterTopic => 'Вставить после';

  @override
  String get pasteAsChildTopic => 'Вставить как дочернюю тему';

  @override
  String get removeFromToc => 'Удалить из оглавления';

  @override
  String get confirmRemoveFromTocTitle => 'Удалить из оглавления?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return 'Удалить $name из этого оглавления? Файл темы будет сохранён.';
  }

  @override
  String get confirmDeleteTopicTitle => 'Удалить файл темы?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return 'Удалить файл темы $name и убрать тему из всех оглавлений? Это действие нельзя отменить.';
  }

  @override
  String get safeDeleteTopicFile => 'Безопасно удалить файл темы…';

  @override
  String get removeTocElement => 'Удалить элемент оглавления';

  @override
  String get reviewUsages => 'Просмотреть использования';

  @override
  String get deleteTopicFile => 'Удалить файл темы';

  @override
  String get removeAction => 'Удалить';

  @override
  String topicRemovalSummary(String topic) {
    return 'Удалить «$topic» из выбранного экземпляра справки. Файл темы будет сохранён.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return 'Удалить «$topic» и безопасно обновить ссылки на неё во всём этом проекте Writerside.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дочерней темы будут перемещены на уровень выше.',
      many: '$count дочерних тем будут перемещены на уровень выше.',
      few: '$count дочерние темы будут перемещены на уровень выше.',
      one: '1 дочерняя тема будет перемещена на уровень выше.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'Эта тема используется как стартовая страница экземпляра. Просмотрите её использования и назначьте другую стартовую страницу, прежде чем продолжить.';

  @override
  String topicUsagesCount(int count) {
    return 'Использования ($count)';
  }

  @override
  String get noBreakingTopicUsages =>
      'Ссылок, которые перестали бы работать, не найдено.';

  @override
  String get topicUsagesFound => 'BusyMark нашёл следующие ссылки на эту тему.';

  @override
  String get topicUsageTocElements => 'Элементы оглавления';

  @override
  String get topicUsageStartPages => 'Стартовые страницы';

  @override
  String get topicUsageTopicLinks => 'Ссылки на темы';

  @override
  String get topicUsageIncludes => 'Включения';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count использования',
      many: '$count использований',
      few: '$count использования',
      one: '1 использование',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'Параметры рефакторинга';

  @override
  String get updateUsagesAutomatically =>
      'Обновить использования автоматически';

  @override
  String get updateUsagesAutomaticallyDescription =>
      'Удалить ссылки из оглавлений и включения, сохранив текст ссылок.';

  @override
  String get manualUsageUpdatesRequired =>
      'Некоторые использования необходимо изменить вручную перед этим рефакторингом.';

  @override
  String get setRedirectTo => 'Перенаправить на';

  @override
  String get noRedirectDescription =>
      'Не перенаправлять старую опубликованную страницу.';

  @override
  String get redirectTarget => 'Цель перенаправления';

  @override
  String get remainingUsagesBlockRemoval =>
      'Просмотрите и обновите оставшиеся использования, прежде чем продолжить, или включите автоматическое обновление, если оно доступно.';

  @override
  String usagesOfTopic(String topic) {
    return 'Использования темы $topic';
  }

  @override
  String get noUsagesFound => 'Использований не найдено';

  @override
  String get outsideSelectedInstance => 'вне выбранного экземпляра';

  @override
  String get doRefactor => 'Выполнить рефакторинг';

  @override
  String get orphanTopicTitle => 'Файл темы больше не используется';

  @override
  String get keepTopicFile => 'Сохранить файл темы';

  @override
  String orphanTopicMessage(String topic) {
    return '«$topic» больше нигде не используется в этом проекте Writerside. Удалите файл или сохраните его для использования в другом экземпляре.';
  }

  @override
  String get defaultNewTopicTitle => 'Новая тема';

  @override
  String get topicTitle => 'Название темы';

  @override
  String get fileName => 'Имя файла';

  @override
  String get topicTitleRequired => 'Укажите название темы.';

  @override
  String get fileNameRequired => 'Укажите имя файла.';

  @override
  String get rename => 'Переименовать';

  @override
  String get confirmDeleteFileTitle => 'Удалить файл?';

  @override
  String get confirmDeleteFolderTitle => 'Удалить папку?';

  @override
  String confirmDeleteFileMessage(String name) {
    return 'Удалить $name? Это действие нельзя отменить.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return 'Удалить $name и все файлы внутри? Это действие нельзя отменить.';
  }

  @override
  String get useSingleSafeFileName => 'Используйте одно допустимое имя файла.';

  @override
  String useExpectedExtension(String extension) {
    return 'Используйте расширение $extension для выбранного формата.';
  }

  @override
  String get useIdentifierCharacters =>
      'Перед расширением используйте только буквы, цифры, подчёркивания или дефисы.';

  @override
  String get topicIdAlreadyExists => 'ID темы уже существует.';

  @override
  String get createWritersideTopicFailed =>
      'Не удалось создать тему Writerside.';

  @override
  String get noOutline => 'Структура отсутствует';

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
  String get foldKindQuote => 'цитату';

  @override
  String get foldKindTag => 'тег';

  @override
  String get sourceSearchPreviousMatch => 'Предыдущее совпадение';

  @override
  String get sourceSearchNextMatch => 'Следующее совпадение';

  @override
  String get sourceSearchCaseSensitive => 'С учётом регистра';

  @override
  String get sourceSearchWholeWord => 'Слово целиком';

  @override
  String get sourceSearchRegex => 'Регулярное выражение';

  @override
  String get sourceSearchInvalidRegex => 'Некорректное регулярное выражение';

  @override
  String get sourceLargeFileFeaturesPaused =>
      'Большой файл: подсветка и сворачивание приостановлены';

  @override
  String get noPreview => 'Нет предварительного просмотра';

  @override
  String get note => 'Примечание';

  @override
  String get tip => 'Совет';

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
      'Этот тип файла нельзя открыть в редакторе';

  @override
  String anchorNotFound(String anchor) {
    return 'Якорь не найден: $anchor';
  }

  @override
  String get noProblemsFound => 'Проблем не найдено';

  @override
  String get noResults => 'Нет результатов';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath — строка $lineNumber';
  }

  @override
  String get untitledResult => 'Результат без названия';

  @override
  String get documentKindMarkdownFile => 'Файл Markdown';

  @override
  String get documentKindWritersideMarkdownTopic => 'Markdown-тема Writerside';

  @override
  String get documentKindWritersideXmlTopic => 'XML-тема Writerside';

  @override
  String get documentKindWritersideTree => 'Дерево Writerside';

  @override
  String get documentKindConfigurationFile => 'Файл конфигурации';

  @override
  String get documentKindVariablesFile => 'Файл переменных';

  @override
  String get documentKindCategoriesFile => 'Файл категорий';

  @override
  String get documentKindResourceFile => 'Файл ресурсов';

  @override
  String workspaceErrorOpenFailed(String error) {
    return 'Не удалось открыть: $error';
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
      'Выберите место для сохранения этого файла Markdown.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      'Сохранение заблокировано: файл на диске изменён.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'Операция с файлом не удалась: $error';
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
  String get errorParentDirectoryRequired => 'Укажите родительский каталог.';

  @override
  String errorParentDirectoryMissing(String path) {
    return 'Родительский каталог не существует: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'Каталог не существует: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'Путь уже существует: $path';
  }

  @override
  String get errorFileNameRequired => 'Требуется имя файла.';

  @override
  String get errorFileNameUnsafe =>
      'Имя файла должно быть одним безопасным сегментом пути.';

  @override
  String get errorFileOperationInvalidTarget =>
      'Нельзя переместить папку внутрь самой себя.';

  @override
  String get errorFileOperationOutsideRoot =>
      'Операция с файлом должна выполняться в пределах рабочей области.';

  @override
  String get errorFileOperationRoot =>
      'Корень рабочей области нельзя изменить через дерево файлов.';

  @override
  String get errorProjectNameRequired => 'Укажите название проекта.';

  @override
  String get errorDirectoryNameRequired => 'Укажите имя каталога.';

  @override
  String get errorDirectoryNameUnsafe =>
      'Имя каталога должно быть одним допустимым сегментом пути.';

  @override
  String get errorInstanceIdInvalid =>
      'ID экземпляра должен начинаться со строчной буквы и содержать только строчные буквы, цифры, подчёркивания и дефисы.';

  @override
  String get errorTopicFileInvalid =>
      'Имя файла темы должно быть именем Markdown-файла без разделителей пути.';

  @override
  String get errorTopicTitleRequired => 'Укажите название темы.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Корень модуля Writerside не существует: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'Для создания темы модуль Writerside должен быть открыт.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'В модуле Writerside отсутствует дерево экземпляра справки.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Файл дерева Writerside не существует: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'ID темы «$topicId» уже существует в этом модуле справки.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'Файл темы уже существует: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return 'Опорная тема отсутствует в выбранном дереве: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing =>
      'Выбранной записи оглавления больше не существует.';

  @override
  String get errorWritersideTocInvalidMove =>
      'Запись оглавления нельзя переместить внутрь самой себя или одного из её дочерних элементов.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return 'Стартовую тему $topic нельзя удалить. Сначала выберите другую стартовую страницу.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Используйте безопасное удаление для файлов тем Writerside.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'Не удалось завершить поиск использований темы. Файлы не были изменены.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      'Некоторые использования темы всё ещё требуют внимания. Просмотрите их перед продолжением.';

  @override
  String get errorWritersideRedirectInvalid =>
      'Выбранная цель перенаправления больше недействительна. Выберите её снова.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'Не удалось полностью откатить удаление темы. Перед продолжением проверьте следующие пути: $paths';
  }

  @override
  String get errorTopicsRootUnsafe =>
      'Корневой каталог тем должен быть допустимым относительным каталогом.';

  @override
  String get errorTopicFileNameUnsafe =>
      'Имя файла темы должно быть одним допустимым сегментом пути.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'Расширение файла темы должно соответствовать выбранному формату ($extension).';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'Имя файла темы должно содержать только буквы, цифры, подчёркивания и дефисы.';

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
      'Обнаружена большая рабочая область. Некоторые файлы пропущены, чтобы приложение оставалось отзывчивым.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'Не удалось проверить элемент рабочей области: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge =>
      'Размер файла превышает предел автоматического анализа в бета-версии.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Не удалось прочитать файл Markdown: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Некорректный блок атрибутов заголовка Writerside.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return 'Повторяющийся ID заголовка «$id».';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      'Дополнительные заголовки H1 верхнего уровня рассматриваются как главы.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'В Markdown-теме Writerside нет заголовка H1 или поля title в блоке front matter.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle =>
      'У XML-темы отсутствует заголовок.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'У темы «$fileName» отсутствует заголовок.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'Блок front matter не закрыт.';

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
    return 'У изображения «$destination» отсутствует альтернативный текст.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return 'Файл изображения не существует: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return 'Некорректный XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'Корневым элементом writerside.cfg должен быть <ihp>.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'В объявлении snippets отсутствует атрибут src.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'В объявлении instance-groups отсутствует атрибут src.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'Неподдерживаемый режим keymaps: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'В объявлении instance отсутствует атрибут src.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'В writerside.cfg не зарегистрирован ни один экземпляр.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      'Корневым элементом файла .tree должен быть <instance-profile>.';

  @override
  String get diagnosticWritersideTreeMissingId =>
      'У профиля экземпляра отсутствует id.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'Имя файла дерева без расширения не совпадает с id экземпляра «$id».';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'В экземпляре, не являющемся библиотекой, отсутствует start-page.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return 'Стартовая страница «$startPage» не существует.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'Тема «$topic» встречается в оглавлении этого экземпляра несколько раз.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      'Объявление переменной должно содержать имя и значение.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return 'Переменная «$name» объявлена несколько раз.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId =>
      'У категории отсутствует id.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'Категория «$id» объявлена несколько раз.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'Значение order категории «$order» объявлено несколько раз.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      'Корневым элементом файла .topic должен быть <topic>.';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'В XML-теме отсутствует атрибут id корневого элемента.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'Атрибут id корневого элемента XML-темы «$id» должен совпадать с именем файла «$expectedId».';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return 'ID элемента «$elementId» встречается несколько раз.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref =>
      'У элемента <a> отсутствует атрибут href.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Для режима Writerside требуется файл writerside.cfg.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return 'Отсутствует заданный каталог конфигурации сборки: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return 'Отсутствует заданный каталог спецификаций API: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return 'Отсутствует заданный каталог фрагментов: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return 'Отсутствует заданный файл переменных: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return 'Отсутствует заданный файл категорий: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return 'Отсутствует заданный файл групп экземпляров: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return 'Зарегистрированное дерево экземпляра «$source» не существует.';
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
    return 'Отсутствует заданный каталог тем: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return 'Отсутствует заданный каталог изображений: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return 'ID элемента «$id» встречается несколько раз.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'Оглавление ссылается на отсутствующую тему «$topic».';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return 'Внешний href «$href» недопустим.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return 'Переменная «%$name%» не объявлена.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'Ссылка на тему «$destination» не указывает на существующую тему.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return 'Якорь «$anchor» не существует в «$targetName».';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      'У элемента <include> отсутствует атрибут from.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'Источник <include> «$from» не существует.';
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
    return 'Категория seealso «$ref» не объявлена.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'Ссылка на тему «$reference» неоднозначна.';
  }

  @override
  String diagnosticUnknown(String code) {
    return 'Неизвестное диагностическое сообщение: $code';
  }

  @override
  String get close => 'Закрыть';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Различия Git';

  @override
  String get gitShowDiff => 'Показать различия';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return 'старый диапазон $oldRange → новый $newRange';
  }

  @override
  String get gitDiffNoLines => 'нет строк';

  @override
  String get gitUnavailableTitle => 'Git недоступен';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Установите Git или настройте BusyMark для использования доступного исполняемого файла Git. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle =>
      'Доверять этой рабочей области при работе с Git?';

  @override
  String get gitTrustRequiredMessage =>
      'Репозитории Git могут запускать программы с помощью хуков, фильтров и других настроек. Подтвердите доверие к этой рабочей области, прежде чем BusyMark прочитает данные репозитория или включит действия Git.';

  @override
  String get gitTrustWorkspace => 'Доверять рабочей области';

  @override
  String get gitNotRepositoryTitle => 'Это не репозиторий Git';

  @override
  String get gitNotRepositoryMessage =>
      'Эта рабочая область не находится в репозитории Git.';

  @override
  String get gitInitializeRepository => 'Инициализировать репозиторий';

  @override
  String get gitDetachedHead => 'Отсоединённый HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'Отсоединённый HEAD: $commit';
  }

  @override
  String get gitNoUpstream => 'Нет upstream-ветки';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count неотправленных коммита',
      many: '$count неотправленных коммитов',
      few: '$count неотправленных коммита',
      one: '$count неотправленный коммит',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Нужно получить $count коммита',
      many: 'Нужно получить $count коммитов',
      few: 'Нужно получить $count коммита',
      one: 'Нужно получить $count коммит',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'Нет изменений';

  @override
  String get gitConflicts => 'Конфликты';

  @override
  String get gitChanges => 'Изменения';

  @override
  String get gitStaged => 'Индексированные';

  @override
  String get gitUnstaged => 'Неиндексированные';

  @override
  String get gitHistory => 'История';

  @override
  String get gitBranches => 'Ветки';

  @override
  String get gitActions => 'Действия Git';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Получить';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Зафиксировать';

  @override
  String get gitSelectForCommit => 'Добавить файл в индекс';

  @override
  String get gitRemoveFromCommit => 'Убрать файл из индекса';

  @override
  String get gitDiscard => 'Отменить изменения';

  @override
  String get gitOpenFile => 'Открыть файл';

  @override
  String get gitMarkResolved => 'Отметить как разрешённый';

  @override
  String get gitUntracked => 'Неотслеживаемые файлы';

  @override
  String get gitCommitMessage => 'Сообщение коммита';

  @override
  String get gitCommitSelectedFiles => 'Выбранные файлы';

  @override
  String get gitCommitNoSelectedFiles =>
      'Перед созданием коммита добавьте в индекс хотя бы один файл.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count индексированных файлов',
      one: '1 индексированный файл',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'Вне рабочего пространства';

  @override
  String get gitCommitMessageRequired => 'Введите сообщение коммита.';

  @override
  String get gitCreateBranch => 'Создать ветку';

  @override
  String get gitNewBranch => 'Новая ветка';

  @override
  String get gitBranchName => 'Название ветки';

  @override
  String get gitSwitchBranch => 'Переключиться';

  @override
  String get gitNoChanges => 'Нет изменений';

  @override
  String get gitNoHistory => 'Нет истории';

  @override
  String get gitNoBranches => 'Нет веток';

  @override
  String get gitNoDiff => 'Нет различий для показа';

  @override
  String get gitBinaryFile =>
      'Двоичный файл. BusyMark не отображает двоичные патчи.';

  @override
  String gitBinaryFileInfo(int size) {
    return 'Двоичный файл ($size байт). BusyMark не отображает двоичные патчи.';
  }

  @override
  String get gitUnsavedChangesBanner =>
      'Несохранённые изменения в редакторе не будут включены, пока вы их не сохраните.';

  @override
  String get gitConfirmDiscardTitle => 'Отменить изменения Git?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбранные отслеживаемые файлы будут восстановлены из Git.',
      many: 'Выбранные отслеживаемые файлы будут восстановлены из Git.',
      few: 'Выбранные отслеживаемые файлы будут восстановлены из Git.',
      one: 'Выбранный отслеживаемый файл будет восстановлен из Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбранные неотслеживаемые файлы будут удалены.',
      many: 'Выбранные неотслеживаемые файлы будут удалены.',
      few: 'Выбранные неотслеживаемые файлы будут удалены.',
      one: 'Выбранный неотслеживаемый файл будет удалён.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Выбранные файлы будут восстановлены или удалены в зависимости от их статуса Git.',
      many:
          'Выбранные файлы будут восстановлены или удалены в зависимости от их статуса Git.',
      few:
          'Выбранные файлы будут восстановлены или удалены в зависимости от их статуса Git.',
      one:
          'Выбранный файл будет восстановлен или удалён в зависимости от его статуса Git.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return 'Переключиться на $branch?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'BusyMark перезагрузит рабочую область с диска после переключения ветки в Git.';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'Настроить upstream-ветку?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'У этой ветки нет upstream-ветки. BusyMark может отправить ветку $branch и назначить её upstream-веткой, если настроен ровно один удалённый репозиторий.';
  }

  @override
  String get gitProjectHistory => 'Проект';

  @override
  String get gitFileHistory => 'Текущий файл';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'Для истории файла требуется открытый файл Markdown.';

  @override
  String get gitLoadMore => 'Загрузить ещё';

  @override
  String get gitChangesInCommit => 'Изменения в этом коммите';

  @override
  String get gitCompareWithCurrent => 'Сравнить с текущей версией';

  @override
  String get gitRestoreVersion => 'Восстановить эту версию';

  @override
  String get gitConfirmRestoreTitle => 'Восстановить эту версию файла?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark заменит текущий файл рабочего дерева выбранной версией из коммита. Восстановленный файл останется неиндексированным.';

  @override
  String get gitCommitActions => 'Действия с коммитом';

  @override
  String get gitResetCurrentBranchToHere => 'Сбросить текущую ветку сюда…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return 'Сбросить $branch на $commit?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'Ветка $branch будет перемещена на коммит $commit. Выберите, как Git должен обновить индекс и рабочее дерево.';
  }

  @override
  String get gitReset => 'Сбросить';

  @override
  String get gitResetModeSoft => 'Soft';

  @override
  String get gitResetModeSoftDescription =>
      'Переместить только ветку. Оставить индекс и рабочее дерево без изменений; отличия от выбранного коммита останутся индексированными.';

  @override
  String get gitResetModeMixed => 'Mixed';

  @override
  String get gitResetModeMixedDescription =>
      'Переместить ветку и сбросить индекс. Оставить рабочее дерево без изменений, а отличия — неиндексированными.';

  @override
  String get gitResetModeHard => 'Hard';

  @override
  String get gitResetModeHardDescription =>
      'Переместить ветку и сбросить индекс и рабочее дерево. Отслеживаемые изменения будут отброшены; мешающие неотслеживаемые файлы могут быть удалены.';

  @override
  String get gitResetModeKeep => 'Keep';

  @override
  String get gitResetModeKeepDescription =>
      'Переместить ветку и сбросить отслеживаемые файлы, сохранив локальные изменения. Git прервёт операцию, если эти изменения конфликтуют со сбросом.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'Действия с файлом';

  @override
  String get gitStatusAdded => 'Добавлен';

  @override
  String get gitStatusDeleted => 'Удалён';

  @override
  String get gitStatusRenamed => 'Переименован';

  @override
  String get gitStatusCopied => 'Скопирован';

  @override
  String get gitStatusUntracked => 'Не отслеживается';

  @override
  String get gitStatusConflicted => 'Конфликт';

  @override
  String get gitStatusIgnored => 'Игнорируется';

  @override
  String get gitStatusTypeChanged => 'Тип изменён';

  @override
  String get gitStatusModified => 'Изменён';

  @override
  String get gitStatusUnknown => 'Неизвестен';

  @override
  String get gitErrorUnavailable => 'Git недоступен.';

  @override
  String get gitErrorNotRepository =>
      'Эта рабочая область не является репозиторием Git.';

  @override
  String get gitErrorUnsafePath =>
      'BusyMark заблокировал небезопасный путь Git.';

  @override
  String get gitErrorInvalidBranchName => 'Введите допустимое название ветки.';

  @override
  String get gitErrorNoRemote => 'Удалённый репозиторий Git не настроен.';

  @override
  String get gitErrorNoUpstream => 'Upstream-ветка не настроена.';

  @override
  String get gitErrorMultipleRemotes =>
      'Настроено несколько удалённых репозиториев. Эта версия BusyMark не позволяет выбрать upstream-ветку; настройте её вне приложения.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Перед переключением ветки сохраните или отмените изменения в редакторе BusyMark.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      'Сохраните или отмените изменения в редакторе BusyMark перед сбросом текущей ветки.';

  @override
  String get gitErrorRestoreStagedFile =>
      'Уберите файл из индекса перед восстановлением предыдущей версии.';

  @override
  String get gitErrorResetDetachedHead =>
      'Переключитесь на ветку перед её сбросом.';

  @override
  String get gitErrorDiverged =>
      'Ветка разошлась с upstream-веткой. Выполните слияние или rebase вне этой версии BusyMark.';

  @override
  String get gitErrorAuthentication =>
      'Не удалось пройти аутентификацию Git. Для удалённых SSH-репозиториев в snap может потребоваться подключить интерфейс ssh-keys.';

  @override
  String get gitErrorNetwork => 'Сетевая операция Git не удалась.';

  @override
  String get gitErrorConflict => 'Git сообщил о неразрешённых конфликтах.';

  @override
  String get gitErrorCommandFailed => 'Не удалось выполнить команду Git.';

  @override
  String get markdownAndHtml => 'Markdown и HTML';

  @override
  String get markdownHtmlMarkdownBlocks => 'Блоки Markdown';

  @override
  String get markdownHtmlMarkdownBlocksDescription =>
      'Блочные структуры, поддерживаемые в исходном Markdown и предварительном просмотре.';

  @override
  String get markdownHtmlInlineFormatting => 'Встроенный Markdown';

  @override
  String get markdownHtmlInlineFormattingDescription =>
      'Форматирование внутри абзацев, элементов списков и ячеек таблиц.';

  @override
  String get markdownHtmlRawHtmlBlocks => 'Блоки исходного HTML';

  @override
  String get markdownHtmlRawHtmlBlocksDescription =>
      'Безопасные блочные HTML-теги, отображаемые через виджеты предварительного просмотра BusyMark.';

  @override
  String get markdownHtmlRawHtmlInline => 'Встроенные HTML-теги';

  @override
  String get markdownHtmlRawHtmlInlineDescription =>
      'Безопасные встроенные HTML-теги отображаются без показа самих тегов.';

  @override
  String get markdownHtmlSafety => 'Правила безопасности';

  @override
  String get markdownHtmlSafetyDescription =>
      'Исходный HTML разбирается и очищается перед отображением в предварительном просмотре.';

  @override
  String get markdownHtmlHeadings => 'Заголовки';

  @override
  String get markdownHtmlParagraphs => 'Абзацы';

  @override
  String get markdownHtmlLists => 'Списки';

  @override
  String get markdownHtmlHtmlContainers => 'Контейнеры';

  @override
  String get markdownHtmlHtmlTextBlocks => 'Текстовые блоки';

  @override
  String get markdownHtmlHtmlFigures => 'Фигуры и изображения';

  @override
  String get markdownHtmlHtmlPreformatted => 'Предформатированный код';

  @override
  String get markdownHtmlHtmlDisclosure => 'Раскрывающиеся блоки';

  @override
  String get markdownHtmlHtmlDescriptionLists => 'Списки описаний';

  @override
  String get markdownHtmlHtmlFormattingTags => 'Теги форматирования';

  @override
  String get markdownHtmlHtmlInlineCodeTags => 'Встроенные теги кода';

  @override
  String get markdownHtmlHtmlNeutralInlineTags =>
      'Семантические текстовые теги';

  @override
  String get markdownHtmlSanitizedPreview =>
      'Очищенный предварительный просмотр';

  @override
  String get markdownHtmlSanitizedPreviewDescription =>
      'Разрешённый HTML преобразуется в блоки предварительного просмотра BusyMark, а не отображается в браузере.';

  @override
  String get markdownHtmlSourcePreserved => 'Исходный текст сохраняется';

  @override
  String get markdownHtmlSourcePreservedDescription =>
      'Неизменённый исходный HTML сохраняется в точности как исходный текст.';

  @override
  String get markdownHtmlMarkdownInsideHtml => 'Markdown внутри HTML';

  @override
  String get markdownHtmlMarkdownInsideHtmlDescription =>
      'Markdown-разметка внутри исходного HTML отображается как обычный текст.';

  @override
  String get markdownHtmlBlockedContent => 'Активный контент заблокирован';

  @override
  String get markdownHtmlBlockedContentDescription =>
      'Скрипты, стили, фреймы, формы, SVG, MathML, события и небезопасные атрибуты блокируются.';

  @override
  String get markdownHtmlSafeUrls => 'Только безопасные URL';

  @override
  String get markdownHtmlSafeUrlsDescription =>
      'Ссылки допускают http, https, mailto, tel, относительные URL и фрагменты; небезопасные схемы блокируются.';

  @override
  String get exportAsPdf => 'Экспортировать в PDF';

  @override
  String get pdfExportDescription =>
      'Выберите макет страницы для аккуратного автономного PDF-файла.';

  @override
  String get pdfRemoteImagesNote =>
      'Удалённые изображения при экспорте не загружаются. Доступные локальные изображения будут добавлены.';

  @override
  String get pdfPageSize => 'Размер страницы';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'US Letter';

  @override
  String get pdfOrientation => 'Ориентация';

  @override
  String get pdfPortrait => 'Книжная';

  @override
  String get pdfLandscape => 'Альбомная';

  @override
  String get pdfMargins => 'Поля';

  @override
  String get pdfMarginNarrow => 'Узкие';

  @override
  String get pdfMarginNormal => 'Обычные';

  @override
  String get pdfMarginWide => 'Широкие';

  @override
  String get pdfIncludePageNumbers => 'Добавить номера страниц';

  @override
  String get export => 'Экспортировать';

  @override
  String get exportingPdf => 'Экспорт PDF…';

  @override
  String get fileTypePdf => 'Документ PDF';

  @override
  String pdfExported(String fileName) {
    return 'Файл $fileName экспортирован.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    return 'Файл $fileName экспортирован. Не удалось добавить изображений: $count.';
  }

  @override
  String get pdfExportUnavailable =>
      'Компонент экспорта PDF отсутствует. Переустановите BusyMark и повторите попытку.';

  @override
  String get pdfExportTimedOut =>
      'Экспорт PDF занял слишком много времени и был остановлен.';

  @override
  String get pdfExportFailed =>
      'BusyMark не удалось экспортировать этот документ в PDF.';

  @override
  String get visualizationRendering => 'Отрисовка…';

  @override
  String get visualizationStale => 'Показан последний корректный результат';

  @override
  String get visualizationShowSource => 'Показать исходный код';

  @override
  String get visualizationShowRender => 'Показать результат';

  @override
  String get visualizationFitWidth => 'Подогнать по ширине';

  @override
  String get visualizationSaveImage => 'Сохранить изображение';

  @override
  String get visualizationCopyImage => 'Копировать изображение';

  @override
  String get visualizationImageCopied => 'Изображение скопировано';

  @override
  String get visualizationOpenApiReference => 'Открыть справочник API';

  @override
  String get visualizationValid => 'Корректно';

  @override
  String get visualizationInvalid => 'Некорректно';

  @override
  String get visualizationServers => 'Серверы';

  @override
  String get visualizationPaths => 'Пути';

  @override
  String get visualizationOperations => 'Операции';

  @override
  String get visualizationTags => 'Теги';

  @override
  String get visualizationNoOperations => 'Подходящие операции не найдены';

  @override
  String get visualizationSearchOperations => 'Поиск операций';

  @override
  String get visualizationRenderFailed =>
      'Не удалось отобразить эту визуализацию.';

  @override
  String get visualizationRetry => 'Повторить';

  @override
  String visualizationSaved(String fileName) {
    return 'Файл $fileName сохранён';
  }

  @override
  String get shortcutExportPdfDescription =>
      'Экспортировать активный документ или модуль Writerside в PDF.';

  @override
  String get newHelpInstance => 'Новый экземпляр справки';

  @override
  String get importMarkdownInstance => 'Новый экземпляр из файлов Markdown';

  @override
  String get newTocLibrary => 'Новая библиотека оглавления';

  @override
  String get editInstance => 'Изменить экземпляр';

  @override
  String get openTocFile => 'Открыть файл оглавления';

  @override
  String get changeInstanceColor => 'Изменить цвет экземпляра';

  @override
  String get createHelpInstance => 'Создать экземпляр справки';

  @override
  String get createTocLibrary => 'Создать библиотеку оглавления';

  @override
  String get importMarkdownAsInstance => 'Импортировать Markdown как экземпляр';

  @override
  String get instanceVersion => 'Версия';

  @override
  String instanceVersionInherited(String version) {
    return 'Если это поле пусто, используется версия проекта $version.';
  }

  @override
  String get instanceWebPath => 'Веб-путь';

  @override
  String get instanceStatus => 'Статус';

  @override
  String get instanceStatusRelease => 'Выпуск';

  @override
  String get instanceStatusEap => 'Ранний доступ';

  @override
  String get instanceStatusDeprecated => 'Устаревший';

  @override
  String get allowSearchEngineIndexing =>
      'Разрешить индексацию поисковыми системами';

  @override
  String get allowSearchEngineIndexingDescription =>
      'Разрешить внешним поисковым системам индексировать этот результат.';

  @override
  String get offlineArtifact => 'Пакет для автономной работы';

  @override
  String get offlineArtifactDescription =>
      'Включить ресурсы, чтобы собранная документация была самодостаточной.';

  @override
  String get instanceOutputSettings => 'Параметры результата';

  @override
  String get markdownImportSource => 'Источник Markdown';

  @override
  String get markdownImportFiles => 'Файлы Markdown';

  @override
  String get selectNone => 'Снять выделение';

  @override
  String markdownFilesFound(int count) {
    return 'Найдено файлов Markdown: $count';
  }

  @override
  String get noMarkdownFilesFound =>
      'В этом каталоге файлы Markdown не найдены.';

  @override
  String get copyReferencedMedia => 'Копировать используемые медиафайлы';

  @override
  String get copyReferencedMediaDescription =>
      'Копировать локальные изображения и видео, на которые ссылаются выбранные файлы, сохраняя относительные пути.';

  @override
  String get instanceIdRenameWarningTitle => 'Переименовать ID экземпляра?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark переименует файл .tree и обновит ссылки проекта Writerside с «$oldId» на «$newId». Скрипты публикации не изменяются, их необходимо обновить отдельно.';
  }

  @override
  String get renameAndUpdateReferences => 'Переименовать и обновить ссылки';

  @override
  String get tocLibraryDescription =>
      'Библиотека оглавления хранит повторно используемые разделы и не создаёт собственный результат.';

  @override
  String get defaultTocLibraryName => 'Общее оглавление';

  @override
  String get instanceColorAutomatic => 'Автоматически';

  @override
  String get instanceColorBlue => 'Синий';

  @override
  String get instanceColorGreen => 'Зелёный';

  @override
  String get instanceColorOrange => 'Оранжевый';

  @override
  String get instanceColorPurple => 'Фиолетовый';

  @override
  String get instanceColorRed => 'Красный';

  @override
  String get instanceColorTeal => 'Бирюзовый';

  @override
  String get instanceColorYellow => 'Жёлтый';

  @override
  String get errorWritersideInstanceNameRequired => 'Введите имя экземпляра.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'Экземпляр с ID «$id» уже существует.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'Дерево экземпляра уже существует: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Каталог источника Markdown не существует: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'Выберите хотя бы один файл Markdown для импорта.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return 'Это не читаемый файл Markdown внутри выбранного источника: $path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'Импорт перезапишет существующий файл проекта: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'Файлы экземпляра изменились на диске. Проверьте их и повторите попытку.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark не удалось полностью откатить изменение экземпляра. Проверьте эти файлы перед продолжением: $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'Библиотека оглавления не может импортировать темы Markdown.';

  @override
  String get errorWritersideInstanceWebPathInvalid =>
      'Веб-путь должен состоять из одной строки.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Конфигурация экземпляра Writerside некорректна. Исправьте диагностические сообщения и повторите попытку.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark не удалось безопасно подготовить изменения экземпляра.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return 'Неизвестный статус экземпляра «$status». Используйте release, eap или deprecated.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'ID экземпляра «$id» используется более чем в одном файле дерева.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'Корневым элементом buildprofiles.xml должен быть <buildprofiles>.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return 'Значение $name «$value» должно быть true или false.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      'Элемент <build-profile> должен указывать ID экземпляра.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'Элемент дерева <include> должен указывать и from, и element-id.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'Элемент дерева <snippet> должен указывать id.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'Межэкземплярная ссылка оглавления должна указывать и ref, и in.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      'Элемент оглавления не может одновременно ссылаться на несколько тем, ссылок, адресов или перенаправлений.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ID элемента дерева «$id» объявлен более одного раза.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'Корневым элементом файла групп экземпляров должен быть <instance-groups>.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'Группа экземпляров должна указывать непустой ID и список экземпляров.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'ID группы экземпляров «$id» объявлен более одного раза.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return 'Включение оглавления «$source#$id» относится к внешнему модулю «$origin» и не может быть раскрыто в этой рабочей области.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return 'Элемент дерева «$id» отсутствует в зарегистрированном дереве «$source».';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'Включение дерева «$source#$id» создаёт цикл.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'Условие экземпляра ссылается на неизвестную группу «@$group».';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'Межэкземплярная ссылка указывает неизвестный экземпляр «$instance».';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'Тема «$topic» отсутствует в указанном экземпляре «$instance».';
  }

  @override
  String get download => 'Скачать';

  @override
  String get exportWritersideAsPdf => 'Экспорт Writerside в PDF';

  @override
  String get writersidePdfExportDescription =>
      'Соберите один экземпляр Writerside с помощью официального сборщика JetBrains.';

  @override
  String get writersidePdfContent => 'Содержимое экспорта';

  @override
  String get writersidePdfSettings => 'Настройки PDF';

  @override
  String get writersidePdfConfigureHere => 'Настроить для этого экспорта';

  @override
  String get writersidePdfProjectConfiguration =>
      'Использовать конфигурацию проекта';

  @override
  String get writersidePdfConfigurationFile => 'Файл конфигурации PDF';

  @override
  String get writersidePdfPage => 'Страница';

  @override
  String get writersidePdfKeymap => 'Раскладка клавиш';

  @override
  String get writersidePdfNoKeymap => 'Без раскладки клавиш';

  @override
  String get writersidePdfTocTitle => 'Заголовок оглавления';

  @override
  String get writersidePdfCover => 'Титульная страница';

  @override
  String get writersidePdfIncludeCover => 'Добавить титульную страницу';

  @override
  String get writersidePdfCoverTitle => 'Заголовок обложки';

  @override
  String get writersidePdfCoverDescription => 'Описание на обложке';

  @override
  String get writersidePdfCopyright => 'Авторские права';

  @override
  String get writersidePdfCoverLogo => 'Логотип на обложке';

  @override
  String get writersidePdfChooseCoverLogo => 'Выбрать логотип для обложки';

  @override
  String get writersidePdfHeaderAndFooter => 'Верхний и нижний колонтитулы';

  @override
  String get writersidePdfHeader => 'Верхний колонтитул';

  @override
  String get writersidePdfFooter => 'Нижний колонтитул';

  @override
  String get writersidePdfAdvancedDescription =>
      'Эти значения сопоставляют открытый модуль со структурой исходных файлов сборщика.';

  @override
  String get writersidePdfModuleName => 'Имя модуля';

  @override
  String get writersidePdfSourceRoot => 'Корневая папка исходных файлов';

  @override
  String get writersidePdfChooseSourceRoot =>
      'Выбрать корневую папку исходных файлов';

  @override
  String get writersidePdfBuilderVersion => 'Версия сборщика';

  @override
  String get writersidePdfAllowNetwork => 'Разрешить сеть во время сборки';

  @override
  String get writersidePdfAllowNetworkDescription =>
      'По умолчанию отключено. Включайте, только если проекту намеренно нужны удалённые ресурсы сборки.';

  @override
  String get writersidePdfModuleNameRequired => 'Введите имя модуля.';

  @override
  String get writersidePdfSourceRootRequired =>
      'Выберите корневую папку исходных файлов.';

  @override
  String get writersidePdfBuilderVersionInvalid =>
      'Введите допустимую версию сборщика.';

  @override
  String get writersidePdfBuilderRequired => 'Требуется сборщик Writerside';

  @override
  String writersidePdfBuilderDownloadDescription(String image) {
    return 'BusyMark использует официальный образ контейнера $image. Скачать его сейчас? Образ имеет большой размер и будет храниться в Docker.';
  }

  @override
  String get writersidePdfDownloadingBuilder => 'Загрузка сборщика Writerside…';

  @override
  String get exportingWritersidePdf => 'Экспорт PDF Writerside…';

  @override
  String get writersidePdfDockerUnavailable =>
      'Для экспорта Writerside в PDF требуется Docker. Установите и запустите Docker, затем повторите попытку.';

  @override
  String get writersidePdfBuilderUnavailable =>
      'Запрошенный образ сборщика Writerside недоступен.';

  @override
  String get writersidePdfConfigurationInvalid =>
      'Недопустимая конфигурация PDF Writerside.';

  @override
  String get writersidePdfBuildFailed =>
      'Сборщику Writerside не удалось создать PDF.';

  @override
  String get writersidePdfInvalidOutput =>
      'Сборщик Writerside не создал допустимый PDF.';

  @override
  String get ai => 'ИИ';

  @override
  String get aiLocalOllama => 'Локальный Ollama';

  @override
  String get aiDisabled => 'Отключено';

  @override
  String get aiLocalOnlyDescription =>
      'Редактирование с помощью ИИ запускается явно и выполняется только локально. BusyMark отправляет исключительно показанный контекст службе Ollama на интерфейсе обратной связи и никогда не применяет предложение без проверки.';

  @override
  String get aiProvider => 'Поставщик ИИ';

  @override
  String get aiOllamaEndpoint => 'Конечная точка Ollama';

  @override
  String get aiOllamaModel => 'Модель Ollama';

  @override
  String get aiTestConnection => 'Проверить подключение';

  @override
  String get aiTestingConnection => 'Проверка…';

  @override
  String aiConnectionReady(int count) {
    return 'Подключено. Найдено установленных моделей: $count.';
  }

  @override
  String get aiNoModels =>
      'Ollama запущен, но установленные модели не найдены.';

  @override
  String get aiConnectionFailed =>
      'BusyMark не удалось проверить локальное подключение к Ollama.';

  @override
  String get aiConfigureFirst =>
      'Включите локальный Ollama и выберите установленную модель в разделе «Настройки → ИИ».';

  @override
  String get aiRewrite => 'Переписать';

  @override
  String get aiShorten => 'Сократить';

  @override
  String get aiSummarize => 'Обобщить';

  @override
  String get aiChangeTone => 'Изменить тон…';

  @override
  String get aiTranslate => 'Перевести…';

  @override
  String get aiProofread => 'Вычитать';

  @override
  String get aiDraft => 'Создать черновик…';

  @override
  String get aiSelectionRequired => 'Выделите текст для этого действия ИИ.';

  @override
  String get aiTonePrompt => 'Опишите требуемый тон';

  @override
  String get aiLanguagePrompt => 'Целевой язык';

  @override
  String get aiDraftPrompt => 'Что должен подготовить BusyMark?';

  @override
  String get aiGenerating => 'Создание предложения…';

  @override
  String get aiProposal => 'Предложение ИИ';

  @override
  String aiContextDisclosure(int count) {
    return 'Локальный Ollama получит $count символов из текущего контекста редактора.';
  }

  @override
  String get aiOriginal => 'Исходный текст';

  @override
  String get aiSuggested => 'Предложение';

  @override
  String get aiApplyProposal => 'Применить предложение';

  @override
  String aiTokenUsage(int input, int output) {
    return 'Входные токены: $input · выходные токены: $output';
  }

  @override
  String get aiStaleProposal =>
      'Документ изменился во время создания этого предложения. Запустите действие ещё раз.';

  @override
  String get aiViewContext => 'Показать отправленный контекст';
}
