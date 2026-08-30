// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle =>
      'Markdown ファイルおよび Writerside 互換のドキュメントプロジェクト用エディター。';

  @override
  String get aboutBusyMark => 'BusyMark について';

  @override
  String get aboutTagline => 'Markdown と Writerside のエディター';

  @override
  String get aboutLicenseLabel => 'ライセンス';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => 'ウェブサイト';

  @override
  String get aboutSourceCode => 'ソースコード';

  @override
  String get reportIssue => '問題を報告';

  @override
  String get feedbackCategory => 'カテゴリ';

  @override
  String get feedbackChooseCategory => 'カテゴリを選択';

  @override
  String get feedbackCategoryProblem => '問題またはバグ';

  @override
  String get feedbackCategoryFeature => '機能リクエスト';

  @override
  String get feedbackCategoryPrivacySecurity => 'プライバシーまたはセキュリティに関する懸念';

  @override
  String get feedbackCategoryUsability => '使いやすさに関する懸念';

  @override
  String get feedbackCategoryOther => 'その他';

  @override
  String get feedbackSubject => '件名';

  @override
  String get feedbackMessage => '詳細なメッセージ';

  @override
  String get feedbackReplyEmail => '返信用メールアドレス（任意）';

  @override
  String get feedbackIncludeTechnicalDetails => '技術的な詳細を含める';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      '有効にすると、Linux のオペレーティングシステムのバージョンと BusyMark のアプリケーション言語のみが追加されます。ログ、ファイル、アカウントデータ、その他の診断情報は添付されません。';

  @override
  String get feedbackSubmit => '送信';

  @override
  String get feedbackSubmitting => '送信中…';

  @override
  String get feedbackCategoryRequired => 'カテゴリを選択してください。';

  @override
  String get feedbackSubjectLength => '件名は 3～120 文字で入力してください。';

  @override
  String get feedbackMessageLength => 'メッセージは 10～5,000 文字で入力してください。';

  @override
  String get feedbackReplyEmailInvalid => '有効なメールアドレスを入力するか、この項目を空欄にしてください。';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark は接続できませんでした。インターネット接続を確認して、もう一度お試しください。';

  @override
  String get feedbackTimeoutFailure => 'リクエストがタイムアウトしました。もう一度お試しください。';

  @override
  String get feedbackRateLimitedFailure =>
      'この接続から送信されたレポートが多すぎます。しばらく待ってから、もう一度お試しください。';

  @override
  String get feedbackRejectedFailure =>
      'サーバーがこのレポートを拒否しました。フォームの項目を確認して、もう一度お試しください。';

  @override
  String get feedbackServerFailure => 'サーバーがレポートを受け付けられませんでした。後でもう一度お試しください。';

  @override
  String feedbackSuccess(String id) {
    return 'フィードバックを送信しました。参照 ID：$id';
  }

  @override
  String get advanced => '詳細設定';

  @override
  String get addToGit => 'Git に追加';

  @override
  String get appearance => '外観';

  @override
  String get apply => '適用';

  @override
  String get back => '戻る';

  @override
  String get bottomLeft => '左下';

  @override
  String get bottomRight => '右下';

  @override
  String get cancel => 'キャンセル';

  @override
  String get choose => '選択';

  @override
  String get chooseLocation => '場所を選択';

  @override
  String get copy => 'コピー';

  @override
  String get copyName => '名前をコピー';

  @override
  String get copyFileName => 'ファイル名をコピー';

  @override
  String get copyPath => 'パスをコピー';

  @override
  String get create => '作成';

  @override
  String get creating => '作成中…';

  @override
  String get cut => '切り取り';

  @override
  String get promoteSection => 'セクションのレベルを上げる';

  @override
  String get demoteSection => 'セクションのレベルを下げる';

  @override
  String get moveSectionUp => 'セクションを上へ移動';

  @override
  String get moveSectionDown => 'セクションを下へ移動';

  @override
  String get confirmDeleteSectionTitle => 'このセクションを削除しますか？';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '「$name」と、そのセクション内のすべての内容を削除しますか？この操作は取り消せません。';
  }

  @override
  String get darkTheme => 'ダーク';

  @override
  String get delete => '削除';

  @override
  String get discard => '破棄';

  @override
  String get editor => 'エディター';

  @override
  String get file => 'ファイル';

  @override
  String get fileHistory => 'ファイル履歴';

  @override
  String get folder => 'フォルダー';

  @override
  String get insert => '挿入';

  @override
  String get keyboardShortcuts => 'キーボードショートカット';

  @override
  String get commandPalette => 'コマンドパレット';

  @override
  String get commandPaletteHint => 'コマンドを入力';

  @override
  String get commandPaletteEmpty => '一致するコマンドはありません';

  @override
  String get commandUnavailableInContext => '現在のエディターのコンテキストでは利用できません';

  @override
  String get lightTheme => 'ライト';

  @override
  String get mainMenu => 'メインメニュー';

  @override
  String get fullScreen => '全画面';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => '開く';

  @override
  String get openInFiles => 'ファイルで開く';

  @override
  String get pathActions => 'パスの操作';

  @override
  String get outline => 'アウトライン';

  @override
  String get overwrite => '上書き';

  @override
  String get paste => '貼り付け';

  @override
  String get pasteWithoutFormatting => '書式なしで貼り付け';

  @override
  String get reading => '閲覧';

  @override
  String get removeFromRecent => '最近使った項目から削除';

  @override
  String get recent => '最近使った項目';

  @override
  String get redo => 'やり直し';

  @override
  String get save => '保存';

  @override
  String get search => '検索';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get settings => '設定';

  @override
  String get source => 'ソース';

  @override
  String get split => '分割';

  @override
  String get systemTheme => 'システム';

  @override
  String get theme => 'テーマ';

  @override
  String get appLanguage => '言語';

  @override
  String get systemLanguage => 'システム';

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
  String get toggleSidebar => 'サイドバーパネル';

  @override
  String get topLeft => '左上';

  @override
  String get topRight => '右上';

  @override
  String get undo => '元に戻す';

  @override
  String get validate => '検証';

  @override
  String get validation => '検証';

  @override
  String get viewMode => '表示モード';

  @override
  String get welcome => 'ようこそ';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => '画像';

  @override
  String get openMarkdownFile => 'Markdown ファイルを開く';

  @override
  String get markdownFileExtensions => '.md または .markdown';

  @override
  String get openFolderOrWritersideProject => 'フォルダーまたは Writerside プロジェクトを開く';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown フォルダーまたは Writerside 互換プロジェクト';

  @override
  String get noOpenFile => '開いているファイルはありません';

  @override
  String get shortcutDeleteTreeItemDescription =>
      '選択したファイル項目を削除するか、選択したトピックを目次から削除';

  @override
  String get shortcutGroupGeneral => '全般';

  @override
  String get shortcutNewDocument => '作成';

  @override
  String get shortcutNewDocumentDescription =>
      'Markdown ファイルまたは Writerside プロジェクトを作成';

  @override
  String get shortcutOpenDescription =>
      'Markdown ファイル、フォルダー、または Writerside プロジェクトを開く';

  @override
  String get shortcutSaveDescription => '現在のドキュメントを保存';

  @override
  String get shortcutSearchDescription => '現在のワークスペースを検索';

  @override
  String get shortcutKeyboardShortcutsDescription => 'このキーボードショートカット一覧を表示';

  @override
  String get shortcutSyntaxReferenceDescription => '構文リファレンスを開く';

  @override
  String get shortcutSettingsDescription => 'BusyMark の設定を開く';

  @override
  String get shortcutNextTab => '次のタブ';

  @override
  String get shortcutNextTabDescription => '次に開いているタブへ移動';

  @override
  String get shortcutPreviousTab => '前のタブ';

  @override
  String get shortcutPreviousTabDescription => '前に開いているタブへ移動';

  @override
  String get shortcutCloseTab => 'タブを閉じる';

  @override
  String get shortcutCloseTabDescription => 'アクティブなタブを閉じる';

  @override
  String get shortcutCloseAllTabs => 'すべてのタブを閉じる';

  @override
  String get shortcutCloseAllTabsDescription => '開いているすべてのタブを閉じる';

  @override
  String get shortcutGroupTextEditing => 'テキスト編集';

  @override
  String get shortcutSelectAllDescription =>
      'ソースモードではすべてのテキストを選択し、エディターモードでは 2 回押すとすべてのブロックを選択';

  @override
  String get shortcutCutDescription => '選択したテキストを切り取り';

  @override
  String get shortcutCopyDescription => '選択したテキストをコピー';

  @override
  String get shortcutPasteDescription => 'クリップボードから貼り付け';

  @override
  String get shortcutPastePlainTextDescription => '書式なしのクリップボードテキストを貼り付け';

  @override
  String get shortcutUndoDescription => '直前の編集を元に戻す';

  @override
  String get shortcutRedoDescription => '直前に元に戻した編集をやり直す';

  @override
  String get shortcutInsertIndentation => 'インデントを挿入';

  @override
  String get shortcutInsertIndentationDescription => 'カーソル位置にインデントを挿入';

  @override
  String get shortcutOutdentSource => 'ソースのインデントを減らす';

  @override
  String get shortcutOutdentSourceDescription => 'ソースモードでインデントを 1 レベル減らす';

  @override
  String get shortcutEscape => '検索を閉じるか、ブロックの選択を解除';

  @override
  String get shortcutEscapeDescription => 'ワークスペース検索を閉じるか、エディターモードでブロックの選択を解除';

  @override
  String get shortcutGroupFormatting => '書式設定';

  @override
  String get shortcutBoldDescription => '選択したテキストの太字を切り替え';

  @override
  String get shortcutItalicDescription => '選択したテキストの斜体を切り替え';

  @override
  String get shortcutUnderlineDescription => '選択したテキストの下線を切り替え';

  @override
  String get shortcutLinkDescription => 'リンクを挿入または編集';

  @override
  String get shortcutInlineCodeDescription => '選択したテキストのインラインコードを切り替え';

  @override
  String get shortcutStrikethroughDescription => '選択したテキストの取り消し線を切り替え';

  @override
  String get shortcutGroupBlocks => 'ブロック';

  @override
  String get shortcutParagraphDescription => '現在のブロックを段落に設定';

  @override
  String get shortcutHeading1Description => '現在のブロックを見出し 1 に設定';

  @override
  String get shortcutHeading2Description => '現在のブロックを見出し 2 に設定';

  @override
  String get shortcutHeading3Description => '現在のブロックを見出し 3 に設定';

  @override
  String get shortcutHeading4Description => '現在のブロックを見出し 4 に設定';

  @override
  String get shortcutHeading5Description => '現在のブロックを見出し 5 に設定';

  @override
  String get shortcutHeading6Description => '現在のブロックを見出し 6 に設定';

  @override
  String get shortcutGroupLists => 'リスト';

  @override
  String get numberedList => '番号付きリスト';

  @override
  String get shortcutNumberedListDescription => '番号付きリストの書式を切り替え';

  @override
  String get bulletedList => '箇条書きリスト';

  @override
  String get shortcutBulletedListDescription => '箇条書きリストの書式を切り替え';

  @override
  String get checklist => 'チェックリスト';

  @override
  String get shortcutChecklistDescription => 'チェックリストの書式を切り替え';

  @override
  String get shortcutGroupSidebar => 'サイドバー';

  @override
  String get sidebarViewMenu => 'サイドバーの表示';

  @override
  String get createMarkdownFile => 'Markdown ファイルを作成';

  @override
  String get createMarkdownFileDescription => '未保存のローカル Markdown ドキュメントの作成を開始';

  @override
  String get createWritersideProject => 'Writerside プロジェクトを作成';

  @override
  String get createWritersideProjectDescription =>
      'ローカルの Writerside 互換プロジェクトの作成を開始';

  @override
  String get defaultProjectName => 'ドキュメント';

  @override
  String get defaultInstanceName => 'ユーザーガイド';

  @override
  String get defaultStartTopicTitle => 'はじめに';

  @override
  String get projectName => 'プロジェクト名';

  @override
  String get directoryName => 'ディレクトリ名';

  @override
  String get instanceName => 'インスタンス名';

  @override
  String get instanceId => 'インスタンス ID';

  @override
  String get startTopicTitle => '開始トピックのタイトル';

  @override
  String get location => '場所';

  @override
  String get projectNameRequired => 'プロジェクト名は必須です。';

  @override
  String get directoryNameRequired => 'ディレクトリ名は必須です。';

  @override
  String get useSingleSafeDirectoryName => '安全な単一のディレクトリ名を使用してください。';

  @override
  String get useLowercaseIdentifier =>
      '小文字、数字、アンダースコア、ハイフンのみを含む小文字の識別子を使用してください。';

  @override
  String get startTopicTitleRequired => '開始トピックのタイトルは必須です。';

  @override
  String get createWritersideProjectFailed => 'Writerside プロジェクトを作成できませんでした。';

  @override
  String get settingsTitle => 'BusyMark の設定';

  @override
  String get autoSave => '自動保存';

  @override
  String get autoSaveDescription => '短時間操作がないときにファイルの変更を自動保存';

  @override
  String get wordWrap => '折り返し';

  @override
  String get editorFontSize => 'エディターのフォントサイズ';

  @override
  String get validateOnEdit => '編集時に検証';

  @override
  String get clearRecentWorkspaces => '最近使ったワークスペースを消去';

  @override
  String get editingButtonsPosition => '編集ボタンの位置';

  @override
  String get editingButtonsPositionDescription =>
      'フローティング WYSIWYG 編集ボタンを表示する位置を選択';

  @override
  String get editingButtonsDirection => '編集ボタンの方向';

  @override
  String get editingButtonsDirectionDescription =>
      'フローティング WYSIWYG 編集ボタンを水平または垂直に配置するか選択';

  @override
  String get horizontal => '水平';

  @override
  String get vertical => '垂直';

  @override
  String get privacy => 'プライバシー';

  @override
  String get allowRemoteImages => 'リモート画像を読み込む';

  @override
  String get allowRemoteImagesDescription =>
      'Markdown のプレビューとエディターで http および https URL の画像を読み込めるようにする';

  @override
  String get clearRemoteImagePermissions => 'リモート画像の権限を消去';

  @override
  String get clearRemoteImagePermissionsDescription =>
      'リモート画像の読み込みを許可したワークスペースの権限を忘れる';

  @override
  String get clearGitWorkspaceTrust => '信頼済み Git ワークスペースを消去';

  @override
  String get clearGitWorkspaceTrustDescription =>
      '以前信頼したワークスペースで Git 機能を有効にする前に確認する';

  @override
  String get settingsWindowSectionTitle => 'ウィンドウ';

  @override
  String get settingsReopenWorkspaceOnStartupTitle => '起動時に前回のワークスペースを再び開く';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark の起動時に前回のセッションのワークスペースとタブを開く';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      '未保存の変更がある場合は閉じる前に確認';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      'ドキュメントに未保存の変更がある場合、BusyMark を閉じる前に確認する';

  @override
  String get closeUnsavedChangesTitle => '未保存の変更';

  @override
  String get closeUnsavedChangesSingleMessage =>
      'このドキュメントには未保存の変更があります。BusyMark を閉じる前に変更を保存しますか？';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未保存の変更があるドキュメントが $count 件あります。BusyMark を閉じる前に変更を保存しますか？',
      one: '未保存の変更があるドキュメントが 1 件あります。BusyMark を閉じる前に変更を保存しますか？',
      zero: 'BusyMark を閉じる前に変更を保存しますか？',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => 'キャンセル';

  @override
  String get closeUnsavedChangesDiscard => '破棄';

  @override
  String get closeUnsavedChangesSave => '保存';

  @override
  String get currentFile => '現在のファイル';

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName に未保存の変更があります。続行する前に保存しますか？';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未保存の変更があるドキュメントが $count 件あります。続行する前に保存しますか？',
      one: '未保存の変更があるドキュメントが 1 件あります。続行する前に保存しますか？',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => 'ディスク上でファイルが変更されました';

  @override
  String get fileChangedOnDiskMessage => 'このファイルは開いた後にディスク上で変更されています。上書きしますか？';

  @override
  String get untitledMarkdownFileName => '無題.md';

  @override
  String get unorderedList => '箇条書きリスト';

  @override
  String get orderedList => '番号付きリスト';

  @override
  String get taskList => 'タスクリスト';

  @override
  String get toggleTaskChecked => 'タスクの完了状態を切り替え';

  @override
  String get indentListItem => 'リスト項目をインデント';

  @override
  String get outdentListItem => 'リスト項目のインデントを減らす';

  @override
  String get blockquote => '引用ブロック';

  @override
  String get codeBlock => 'コードブロック';

  @override
  String get codeBlockLanguage => 'コードブロックの言語';

  @override
  String get image => '画像';

  @override
  String get video => '動画';

  @override
  String get openVideo => '動画を再生';

  @override
  String get pauseVideo => '動画を一時停止';

  @override
  String get videoUnavailable => '動画を利用できません';

  @override
  String get videoPreview => '動画のプレビュー';

  @override
  String get diagnosticWritersideVideoMissingSource => '動画に src 属性がありません。';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return 'サポートされていない動画ソース：$source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return '動画ファイルが存在しません：$source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return '動画のプレビュー画像が存在しません：$preview';
  }

  @override
  String get inlineImage => 'インライン画像';

  @override
  String get table => '表';

  @override
  String get htmlBlock => 'HTML ブロック';

  @override
  String get htmlContentDefault => 'HTML コンテンツ';

  @override
  String get shortcutHtmlBlockDescription => 'HTML ブロックを挿入または編集';

  @override
  String get renderedHtml => 'レンダリングされた HTML';

  @override
  String get editHtml => 'HTML を編集';

  @override
  String get htmlSource => 'HTML ソース';

  @override
  String get thematicBreak => '水平線';

  @override
  String get bold => '太字';

  @override
  String get italic => '斜体';

  @override
  String get underline => '下線';

  @override
  String get strikethrough => '取り消し線';

  @override
  String get inlineCode => 'インラインコード';

  @override
  String get link => 'リンク';

  @override
  String get hardLineBreak => '強制改行';

  @override
  String get textStyle => 'テキストスタイル';

  @override
  String get paragraph => '段落';

  @override
  String get heading1 => '見出し 1';

  @override
  String get heading2 => '見出し 2';

  @override
  String get heading3 => '見出し 3';

  @override
  String get heading4 => '見出し 4';

  @override
  String get heading5 => '見出し 5';

  @override
  String get heading6 => '見出し 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => '表を削除';

  @override
  String tableColumnNumber(int columnNumber) {
    return '列 $columnNumber';
  }

  @override
  String get insertColumnLeft => '左に列を挿入';

  @override
  String get insertColumnRight => '右に列を挿入';

  @override
  String get deleteColumn => '列を削除';

  @override
  String get tableAlignmentUnspecified => '配置：未指定';

  @override
  String get tableAlignmentLeft => '配置：左';

  @override
  String get tableAlignmentCenter => '配置：中央';

  @override
  String get tableAlignmentRight => '配置：右';

  @override
  String tableRowNumber(int rowNumber) {
    return '行 $rowNumber';
  }

  @override
  String get insertRowAbove => '上に行を挿入';

  @override
  String get insertRowBelow => '下に行を挿入';

  @override
  String get deleteRow => '行を削除';

  @override
  String get tableHeaderHint => 'ヘッダー';

  @override
  String get tableCellHint => 'セル';

  @override
  String get language => '言語';

  @override
  String get hideEditingButtons => '編集ボタンを非表示';

  @override
  String get showEditingButtons => '編集ボタンを表示';

  @override
  String get altText => '代替テキスト';

  @override
  String get editorPlaceholderText => 'テキスト';

  @override
  String get editorPlaceholderCode => 'コード';

  @override
  String get editorPlaceholderAltText => '代替テキスト';

  @override
  String get describeTheImage => '画像を説明';

  @override
  String get columns => '列';

  @override
  String get rows => '行';

  @override
  String tableHeaderNumber(int columnNumber) {
    return 'ヘッダー $columnNumber';
  }

  @override
  String get tableCellDefault => 'セル';

  @override
  String get noImageSource => '画像ソースがありません';

  @override
  String get remoteImageBlocked => 'リモート画像がブロックされています';

  @override
  String get remoteImageBlockedTooltip => 'BusyMark にリモート画像の読み込みを許可するか選択';

  @override
  String get remoteImagesBlockedTitle => 'リモート画像がブロックされています';

  @override
  String get remoteImagesBlockedMessage =>
      'このドキュメントはインターネット上の画像を参照しています。読み込むと、画像ホストにネットワーク情報が公開される可能性があります。';

  @override
  String get loadRemoteImagesForWorkspace => 'このワークスペースで読み込む';

  @override
  String get alwaysLoadRemoteImages => '常にリモート画像を読み込む';

  @override
  String get hideSidebar => 'サイドバーパネルを非表示';

  @override
  String get showSidebar => 'サイドバーパネルを表示';

  @override
  String get showPreview => 'プレビューを表示';

  @override
  String get hidePreview => 'プレビューを非表示';

  @override
  String get workspaceKindUnsavedMarkdown => '未保存の Markdown ファイル';

  @override
  String get workspaceKindSingleMarkdown => '単一の Markdown ファイル';

  @override
  String get workspaceKindMarkdownFolder => 'Markdown フォルダー';

  @override
  String get workspaceKindWritersideModule => 'Writerside モジュール';

  @override
  String get problems => '問題';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '診断情報 $count 件',
      one: '診断情報 1 件',
      zero: '診断情報はありません',
    );
    return '$_temp0';
  }

  @override
  String get files => 'ファイル';

  @override
  String get toc => '目次';

  @override
  String get tocActions => '目次の操作';

  @override
  String get markdownUnsaved => 'Markdown - 未保存';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ファイル $count 件',
      one: 'ファイル 1 件',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => 'ファイルはありません';

  @override
  String get newFile => '新しいファイル';

  @override
  String get noWritersideToc => 'Writerside の目次はありません';

  @override
  String get tocSection => '目次セクション';

  @override
  String get newTopic => '新しいトピック';

  @override
  String get newChildTopic => '新しい子トピック';

  @override
  String get newSiblingTopic => '新しい兄弟トピック';

  @override
  String get renameTopicFile => 'トピックファイルの名前を変更';

  @override
  String get topicPlacement => '目次内の位置';

  @override
  String get tocRoot => '目次のルート';

  @override
  String get afterSelectedTopic => '選択したトピックの後';

  @override
  String get insideSelectedTopic => '選択したトピック内';

  @override
  String get pasteAfterTopic => '後に貼り付け';

  @override
  String get pasteAsChildTopic => '子として貼り付け';

  @override
  String get removeFromToc => '目次から削除';

  @override
  String get confirmRemoveFromTocTitle => '目次から削除しますか？';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '$name をこの目次から削除しますか？トピックファイルは保持されます。';
  }

  @override
  String get confirmDeleteTopicTitle => 'トピックファイルを削除しますか？';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name を削除し、すべての目次から削除しますか？この操作は取り消せません。';
  }

  @override
  String get safeDeleteTopicFile => 'トピックファイルを安全に削除…';

  @override
  String get removeTocElement => '目次要素を削除';

  @override
  String get reviewUsages => '使用箇所を確認';

  @override
  String get deleteTopicFile => 'トピックファイルを削除';

  @override
  String get removeAction => '削除';

  @override
  String topicRemovalSummary(String topic) {
    return '選択したインスタンスから「$topic」を削除します。トピックファイルは保持されます。';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '「$topic」を削除し、この Writerside プロジェクト全体の参照を安全に更新します。';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '子トピック $count 件を 1 レベル上へ移動します。',
      one: '子トピック 1 件を 1 レベル上へ移動します。',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      'このトピックはインスタンスの開始ページとして使用されています。使用箇所を確認し、続行する前に別の開始ページを割り当ててください。';

  @override
  String topicUsagesCount(int count) {
    return '使用箇所（$count）';
  }

  @override
  String get noBreakingTopicUsages => 'リンク切れになる参照は見つかりませんでした。';

  @override
  String get topicUsagesFound => 'BusyMark はこのトピックへの次の参照を見つけました。';

  @override
  String get topicUsageTocElements => '目次要素';

  @override
  String get topicUsageStartPages => '開始ページ';

  @override
  String get topicUsageTopicLinks => 'トピックリンク';

  @override
  String get topicUsageIncludes => 'インクルード';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '使用箇所 $count 件',
      one: '使用箇所 1 件',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => 'リファクタリングのオプション';

  @override
  String get updateUsagesAutomatically => '使用箇所を自動的に更新';

  @override
  String get updateUsagesAutomaticallyDescription =>
      '目次の参照とインクルードを削除し、リンクテキストを保持';

  @override
  String get manualUsageUpdatesRequired => 'このリファクタリングの前に手動で変更が必要な使用箇所があります。';

  @override
  String get setRedirectTo => 'リダイレクト先を設定';

  @override
  String get noRedirectDescription => '以前公開されたページをリダイレクトしない';

  @override
  String get redirectTarget => 'リダイレクト先';

  @override
  String get remainingUsagesBlockRemoval =>
      '続行する前に残りの使用箇所を確認して更新するか、利用可能な場合は自動更新を有効にしてください。';

  @override
  String usagesOfTopic(String topic) {
    return '$topic の使用箇所';
  }

  @override
  String get noUsagesFound => '使用箇所は見つかりませんでした';

  @override
  String get outsideSelectedInstance => '選択したインスタンスの外部';

  @override
  String get doRefactor => 'リファクタリングを実行';

  @override
  String get orphanTopicTitle => 'トピックファイルは使用されていません';

  @override
  String get keepTopicFile => 'トピックファイルを保持';

  @override
  String orphanTopicMessage(String topic) {
    return '「$topic」はこの Writerside プロジェクト内で使用されていません。ファイルを削除するか、別のインスタンスで使用するために保持してください。';
  }

  @override
  String get defaultNewTopicTitle => '新しいトピック';

  @override
  String get topicTitle => 'トピックのタイトル';

  @override
  String get fileName => 'ファイル名';

  @override
  String get topicTitleRequired => 'トピックのタイトルは必須です。';

  @override
  String get fileNameRequired => 'ファイル名は必須です。';

  @override
  String get rename => '名前を変更';

  @override
  String get confirmDeleteFileTitle => 'ファイルを削除しますか？';

  @override
  String get confirmDeleteFolderTitle => 'フォルダーを削除しますか？';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name を削除しますか？この操作は取り消せません。';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name と、その中のすべてのファイルを削除しますか？この操作は取り消せません。';
  }

  @override
  String get useSingleSafeFileName => '安全な単一のファイル名を使用してください。';

  @override
  String useExpectedExtension(String extension) {
    return '選択した形式の拡張子 $extension を使用してください。';
  }

  @override
  String get useIdentifierCharacters =>
      '拡張子の前には、文字、数字、アンダースコア、ハイフンのみを使用してください。';

  @override
  String get topicIdAlreadyExists => 'トピック ID はすでに存在します。';

  @override
  String get createWritersideTopicFailed => 'Writerside トピックを作成できませんでした。';

  @override
  String get noOutline => 'アウトラインはありません';

  @override
  String expandKind(String kind) {
    return '$kind を展開';
  }

  @override
  String collapseKind(String kind) {
    return '$kind を折りたたむ';
  }

  @override
  String get foldKindSection => 'セクション';

  @override
  String get foldKindList => 'リスト';

  @override
  String get foldKindQuote => '引用';

  @override
  String get foldKindTag => 'タグ';

  @override
  String get sourceSearchPreviousMatch => '前の一致';

  @override
  String get sourceSearchNextMatch => '次の一致';

  @override
  String get sourceSearchCaseSensitive => '大文字と小文字を区別';

  @override
  String get sourceSearchWholeWord => '単語単位';

  @override
  String get sourceSearchRegex => '正規表現';

  @override
  String get sourceSearchReplacement => '置換後';

  @override
  String get sourceSearchReplaceCurrent => '現在の一致を置換';

  @override
  String get sourceSearchReplaceAndFindNext => '置換して次を検索';

  @override
  String get sourceSearchReplaceAll => 'すべて置換';

  @override
  String get workspaceReplace => 'ワークスペースで置換';

  @override
  String get reviewReplacements => '置換内容を確認';

  @override
  String get applyReplacements => '置換を適用';

  @override
  String get skippedFiles => 'スキップしたファイル';

  @override
  String get workspaceReplaceDirtyBuffer => '未保存のエディター内容';

  @override
  String get workspaceReplaceDiskContent => 'ディスク上の保存済み内容';

  @override
  String selectFileMatches(int count) {
    return '$count 件の一致をすべて選択';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$files 個のファイルで $matches 件の一致を置換しました。$skipped 件をスキップしました。';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾に改行あり';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 末尾に改行なし';
  }

  @override
  String get normalizeLineEndings => '行末を正規化';

  @override
  String get mixedLineEndingsSavePrompt => 'このドキュメントには混在した行末があります。形式を選択してください。';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName には混在した行末があります。置換前に使用する形式を選択してください。';
  }

  @override
  String get workspaceReplaceIssueOversized => 'サイズが大きすぎるファイルをスキップしました。';

  @override
  String get workspaceReplaceIssueUnreadable => '読み取れないファイルをスキップしました。';

  @override
  String get workspaceReplaceIssueInvalidUtf8 => '有効な UTF-8 ではないファイルをスキップしました。';

  @override
  String get workspaceReplaceIssueTruncated => '置換プレビューは途中で切り詰められました。';

  @override
  String get workspaceReplaceIssueFileChanged => 'プレビュー後に変更されたファイルをスキップしました。';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      'プレビュー後に変更されたエディターバッファーをスキップしました。';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      '置換前に LF または CRLF の正規化を選択してください。';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      'ファイルが同時に変更されたため、ロールバックを停止しました。一部の置換が残っている可能性があります。置き換えられた内容は下記のパスに保存されています。';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      '確認済みの置換をコミットできませんでした。ファイルは変更されていません。';

  @override
  String externalChangesTitle(String fileName) {
    return '外部変更 — $fileName';
  }

  @override
  String get externalFileDeleted => 'このファイルはディスク上で削除されました。';

  @override
  String get externalFileChanged => '未保存の編集を行っている間に、このファイルがディスク上で変更されました。';

  @override
  String recoveredDocumentReview(String fileName) {
    return '$fileName の未保存の内容を復元しました。確認してから保存、名前を付けて保存、または破棄してください。';
  }

  @override
  String get compare => '比較';

  @override
  String get reloadFromDisk => 'ディスクから再読み込み';

  @override
  String get keepMine => '自分の変更を保持';

  @override
  String get saveAs => '名前を付けて保存';

  @override
  String get sourceSearchInvalidRegex => '無効な正規表現';

  @override
  String get sourceLargeFileFeaturesPaused => '大きなファイル：ハイライトと折りたたみを一時停止しています';

  @override
  String get nothingToRead => '読み取るものはありません';

  @override
  String get admonition => '注記';

  @override
  String get quote => '引用';

  @override
  String get note => '注記';

  @override
  String get tip => 'ヒント';

  @override
  String get warning => '警告';

  @override
  String get tabs => 'タブ';

  @override
  String get tab => 'タブ';

  @override
  String get procedure => '手順';

  @override
  String get step => 'ステップ';

  @override
  String get topic => 'トピック';

  @override
  String get chapter => '章';

  @override
  String couldNotOpenTarget(String target) {
    return '$target を開けませんでした';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return 'リンク先が見つかりません：$targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor => 'このファイル形式はエディターで開けません';

  @override
  String anchorNotFound(String anchor) {
    return 'アンカーが見つかりません：$anchor';
  }

  @override
  String get noProblemsFound => '問題は見つかりませんでした';

  @override
  String get noResults => '結果はありません';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - $lineNumber 行目';
  }

  @override
  String get untitledResult => '無題の結果';

  @override
  String get documentKindMarkdownFile => 'Markdown ファイル';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown トピック';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML トピック';

  @override
  String get documentKindWritersideTree => 'Writerside ツリー';

  @override
  String get documentKindConfigurationFile => '構成ファイル';

  @override
  String get documentKindVariablesFile => '変数ファイル';

  @override
  String get documentKindCategoriesFile => 'カテゴリファイル';

  @override
  String get documentKindResourceFile => 'リソースファイル';

  @override
  String workspaceErrorOpenFailed(String error) {
    return '開くことができませんでした：$error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Writerside プロジェクトを作成できませんでした：$error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Writerside トピックを作成できませんでした：$error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return 'ファイルを開けませんでした：$error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      'この Markdown ファイルの保存場所を選択してください。';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      '保存できません：ファイルがディスク上で変更されました。';

  @override
  String workspaceErrorSaveFailed(String error) {
    return '保存に失敗しました：$error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return 'ファイル操作に失敗しました：$error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return '検証に失敗しました：$error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未保存のドキュメント $count 件を復元しました。保存または破棄する前にそれぞれ確認してください。',
      one: '未保存のドキュメント 1 件を復元しました。保存または破棄する前に確認してください。',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '破損した復元レコード $count 件を復元できませんでした。有効な復元レコードは引き続き利用できます。',
      one: '破損した復元レコード 1 件を復元できませんでした。元の復元ファイルは確認用に保持されています。',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return 'パスが存在しません：$path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return '対象ディレクトリはすでに存在し、空ではありません：$path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return '対象パスはすでに存在しますが、ディレクトリではありません：$path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return '生成されたファイルはすでに存在します：$path';
  }

  @override
  String get errorParentDirectoryRequired => '親ディレクトリは必須です。';

  @override
  String errorParentDirectoryMissing(String path) {
    return '親ディレクトリが存在しません：$path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return 'ディレクトリが存在しません：$path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return 'パスはすでに存在します：$path';
  }

  @override
  String get errorFileNameRequired => 'ファイル名は必須です。';

  @override
  String get errorFileNameUnsafe => 'ファイル名は安全な単一のパスセグメントである必要があります。';

  @override
  String get errorFileOperationInvalidTarget => 'フォルダーをその中へ移動することはできません。';

  @override
  String get errorFileOperationOutsideRoot => 'ファイル操作はワークスペース内で行う必要があります。';

  @override
  String get errorFileOperationRoot => 'ファイルツリーからワークスペースのルートを変更することはできません。';

  @override
  String get errorProjectNameRequired => 'プロジェクト名は必須です。';

  @override
  String get errorDirectoryNameRequired => 'ディレクトリ名は必須です。';

  @override
  String get errorDirectoryNameUnsafe => 'ディレクトリ名は安全な単一のパスセグメントである必要があります。';

  @override
  String get errorInstanceIdInvalid =>
      'インスタンス ID は小文字で始まり、小文字、数字、アンダースコア、ハイフンのみを含む必要があります。';

  @override
  String get errorTopicFileInvalid =>
      'トピックファイル名は、パス区切り文字を含まない Markdown ファイル名である必要があります。';

  @override
  String get errorTopicTitleRequired => 'トピックのタイトルは必須です。';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside モジュールのルートが存在しません：$path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      'トピックを作成するには Writerside モジュールを開く必要があります。';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside モジュールにインスタンスツリーがありません。';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside ツリーファイルが存在しません：$path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return 'トピック ID「$topicId」はこのヘルプモジュールにすでに存在します。';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return 'トピックファイルはすでに存在します：$path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return '選択したツリーに参照トピックがありません：$topic';
  }

  @override
  String get errorWritersideTocNodeMissing => '選択した目次エントリはすでに存在しません。';

  @override
  String get errorWritersideTocInvalidMove =>
      '目次エントリを自分自身またはその子の中へ移動することはできません。';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '開始トピック $topic は削除できません。先に別の開始ページを選択してください。';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Writerside トピックファイルには「安全な削除」を使用してください。';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      'トピックの使用箇所をスキャンできませんでした。ファイルは変更されていません。';

  @override
  String get errorWritersideTopicUsagesRemain =>
      '一部のトピックの使用箇所には引き続き対応が必要です。続行する前に確認してください。';

  @override
  String get errorWritersideRedirectInvalid =>
      '選択したリダイレクト先は無効になっています。もう一度選択してください。';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return 'トピックの削除を完全にはロールバックできませんでした。続行する前に次のパスを確認してください：$paths';
  }

  @override
  String get errorTopicsRootUnsafe => 'トピックのルートは安全な相対ディレクトリである必要があります。';

  @override
  String get errorTopicFileNameUnsafe => 'トピックファイル名は安全な単一のパスセグメントである必要があります。';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return 'トピックファイルの拡張子は、選択した形式（$extension）と一致する必要があります。';
  }

  @override
  String get errorTopicFileNameInvalid =>
      'トピックファイル名には、文字、数字、アンダースコア、ハイフンのみを使用できます。';

  @override
  String errorUnknown(String code) {
    return '不明なエラー：$code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return 'ファイルのメタデータを読み取れませんでした：$error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      '大きなワークスペースが検出されました。アプリの応答性を保つため、一部のファイルをスキップしました。';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return 'ワークスペース項目を検査できませんでした：$error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge => 'ファイルがベータ版自動解析の上限を超えています。';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Markdown ファイルを読み取れませんでした：$error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      'Writerside の見出し属性ブロックの形式が正しくありません。';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return '見出し ID「$id」が重複しています。';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      '追加のトップレベル H1 見出しは章として扱われます。';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown トピックに H1 または front matter のタイトルがありません。';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle => 'XML トピックにタイトルがありません。';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return 'トピック「$fileName」にタイトルがありません。';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'front matter が閉じられていません。';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => '安全でない HTML 要素です。';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return 'リンク先が存在しません：$targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return 'アンカー「$anchor」が存在しません。';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '画像「$destination」に代替テキストがありません。';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return '画像が存在しません：$destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return '無効な XML：$message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg のルートは <ihp> である必要があります。';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      'snippets 宣言に src がありません。';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      'instance-groups 宣言に src がありません。';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return 'サポートされていない keymaps モード：$mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      'instance 宣言に src がありません。';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg にインスタンスが登録されていません。';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree のルートは <instance-profile> である必要があります。';

  @override
  String get diagnosticWritersideTreeMissingId => 'インスタンスプロファイルに id がありません。';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return 'ツリーファイルの拡張子を除いた名前がインスタンス ID「$id」と一致しません。';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      'ライブラリ以外のインスタンスに start-page がありません。';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '開始ページ「$startPage」が存在しません。';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return 'トピック「$topic」がこのインスタンスの目次に複数回登場します。';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      '変数宣言には名前と値が必要です。';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '変数「$name」が複数回宣言されています。';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => 'カテゴリに id がありません。';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return 'カテゴリ「$id」が複数回宣言されています。';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return 'カテゴリの順序「$order」が複数回宣言されています。';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic のルートは <topic> である必要があります。';

  @override
  String get diagnosticWritersideTopicMissingRootId =>
      'XML トピックにルート id がありません。';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML トピックのルート ID「$id」はファイル名「$expectedId」と一致する必要があります。';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return '要素 ID「$elementId」が複数回登場します。';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a> に href がありません。';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside モードには writerside.cfg が必要です。';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return '設定されたビルド構成ディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return '設定された API 仕様ディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return '設定された snippets ディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return '設定された変数ファイルがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return '設定されたカテゴリファイルがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return '設定されたインスタンスグループファイルがありません：$relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return '登録されたインスタンスツリー「$source」が存在しません。';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return 'トピックファイルを読み取れませんでした：$error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return 'デフォルトのトピックディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return '設定されたトピックディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return '設定された画像ディレクトリがありません：$relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return '要素 ID「$id」が複数回登場します。';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return '目次が存在しないトピック「$topic」を参照しています。';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return '外部 href「$href」が無効です。';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '変数「%$name%」が宣言されていません。';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return 'トピックリンク「$destination」を解決できません。';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '「$targetName」にアンカー「$anchor」が存在しません。';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include> に from がありません。';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return 'インクルードソース「$from」が存在しません。';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '「$from」にインクルード要素「$elementId」が存在しません。';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso カテゴリ「$ref」が宣言されていません。';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return 'トピック参照「$reference」があいまいです。';
  }

  @override
  String diagnosticUnknown(String code) {
    return '不明な診断情報：$code';
  }

  @override
  String get close => '閉じる';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git の差分';

  @override
  String get gitShowDiff => '差分を表示';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return '旧 $oldRange → 新 $newRange';
  }

  @override
  String get gitDiffNoLines => '行はありません';

  @override
  String get gitUnavailableTitle => 'Git を利用できません';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other':
          'Git をインストールするか、利用可能な Git 実行ファイルを使用するよう BusyMark を設定してください。$reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'このワークスペースを信頼して Git を使用しますか？';

  @override
  String get gitTrustRequiredMessage =>
      'Git リポジトリでは、フック、フィルター、その他の設定を通じてプログラムを実行できます。BusyMark がリポジトリデータを読み取ったり Git 操作を有効にしたりする前に、このワークスペースを信頼してください。';

  @override
  String get gitTrustWorkspace => 'ワークスペースを信頼';

  @override
  String get gitNotRepositoryTitle => 'Git リポジトリではありません';

  @override
  String get gitNotRepositoryMessage => 'このワークスペースは Git リポジトリ内にありません。';

  @override
  String get gitInitializeRepository => 'リポジトリを初期化';

  @override
  String get gitDetachedHead => '分離した HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return 'HEAD は $commit で分離しています';
  }

  @override
  String get gitNoUpstream => 'アップストリームなし';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未プッシュのコミット $count 件',
      one: '未プッシュのコミット 1 件',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'プルが必要なコミット $count 件',
      one: 'プルが必要なコミット 1 件',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => 'クリーン';

  @override
  String get gitConflicts => '競合';

  @override
  String get gitChanges => '変更';

  @override
  String get gitStaged => 'ステージ済み';

  @override
  String get gitUnstaged => '未ステージ';

  @override
  String get gitHistory => '履歴';

  @override
  String get gitBranches => 'ブランチ';

  @override
  String get gitActions => 'Git の操作';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => 'ファイルをステージ';

  @override
  String get gitRemoveFromCommit => 'ファイルをアンステージ';

  @override
  String get gitDiscard => 'ロールバック';

  @override
  String get gitOpenFile => 'ファイルを開く';

  @override
  String get gitMarkResolved => '解決済みとしてマーク';

  @override
  String get gitUntracked => '未追跡';

  @override
  String get gitCommitMessage => 'コミットメッセージ';

  @override
  String get gitCommitSelectedFiles => '選択したファイル';

  @override
  String get gitCommitNoSelectedFiles => 'コミットする前に、少なくとも 1 つのファイルをステージしてください。';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ステージ済みファイル $count 件',
      one: 'ステージ済みファイル 1 件',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => 'ワークスペース外';

  @override
  String get gitCommitMessageRequired => 'コミットメッセージを入力してください。';

  @override
  String get gitCreateBranch => 'ブランチを作成';

  @override
  String get gitNewBranch => '新しいブランチ';

  @override
  String get gitBranchName => 'ブランチ名';

  @override
  String get gitSwitchBranch => '切り替え';

  @override
  String get gitNoChanges => '変更はありません';

  @override
  String get gitNoHistory => '履歴はありません';

  @override
  String get gitNoBranches => 'ブランチはありません';

  @override
  String get gitNoDiff => '表示する差分はありません';

  @override
  String get gitBinaryFile => 'バイナリファイルです。BusyMark はバイナリパッチをレンダリングしません。';

  @override
  String gitBinaryFileInfo(int size) {
    return 'バイナリファイル（$size バイト）です。BusyMark はバイナリパッチをレンダリングしません。';
  }

  @override
  String get gitUnsavedChangesBanner => '保存するまで、未保存のエディターの変更は含まれません。';

  @override
  String get gitConfirmDiscardTitle => 'Git の変更を破棄しますか？';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '選択した追跡対象ファイルのステージ済みおよび未ステージの変更をすべて HEAD に復元します。',
      one: '選択した追跡対象ファイルのステージ済みおよび未ステージの変更をすべて HEAD に復元します。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '選択した未追跡ファイルを削除します。',
      one: '選択した未追跡ファイルを削除します。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Git の状態に応じて、選択したファイルを復元または削除します。',
      one: 'Git の状態に応じて、選択したファイルを復元または削除します。',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '$branch に切り替えますか？';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'Git がブランチを切り替えた後、BusyMark はディスクからワークスペースを再読み込みします。';

  @override
  String get gitConfirmPushSetUpstreamTitle => 'アップストリームブランチを設定しますか？';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return 'このブランチにはアップストリームがありません。リモートが 1 つだけ設定されている場合、BusyMark は $branch をプッシュしてアップストリームを設定できます。';
  }

  @override
  String get gitProjectHistory => 'プロジェクト履歴';

  @override
  String get gitFileHistory => 'ファイル履歴';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      'ファイル履歴を表示するには Markdown ファイルを開く必要があります。';

  @override
  String get gitLoadMore => 'さらに読み込む';

  @override
  String get gitChangesInCommit => 'このコミットの変更';

  @override
  String get gitCompareWithCurrent => '現在の状態と比較';

  @override
  String get gitRestoreVersion => 'このバージョンを復元';

  @override
  String get gitConfirmRestoreTitle => 'このファイルのバージョンを復元しますか？';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark は、現在の作業ツリーのファイルを選択したコミット済みバージョンで置き換えます。復元されたファイルは未ステージのままになります。';

  @override
  String get gitCommitActions => 'コミット操作';

  @override
  String get gitResetCurrentBranchToHere => '現在のブランチをここにリセット…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '$branch を $commit にリセットしますか？';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return 'ブランチ $branch をコミット $commit に移動します。Git がインデックスと作業ツリーを更新する方法を選択してください。';
  }

  @override
  String get gitReset => 'リセット';

  @override
  String get gitResetModeSoft => 'ソフト';

  @override
  String get gitResetModeSoftDescription =>
      'ブランチのみを移動します。インデックスと作業ツリーは変更せず、選択したコミットとの差分をステージ済みのままにします。';

  @override
  String get gitResetModeMixed => 'ミックス';

  @override
  String get gitResetModeMixedDescription =>
      'ブランチを移動してインデックスをリセットします。作業ツリーは変更せず、差分を未ステージの状態にします。';

  @override
  String get gitResetModeHard => 'ハード';

  @override
  String get gitResetModeHardDescription =>
      'ブランチを移動してインデックスと作業ツリーをリセットします。追跡対象の変更は破棄され、妨げとなる未追跡ファイルは削除される可能性があります。';

  @override
  String get gitResetModeKeep => '保持';

  @override
  String get gitResetModeKeepDescription =>
      'ローカルの変更を保持しながら、ブランチを移動して追跡対象ファイルをリセットします。変更がリセットと競合する場合、Git は中止します。';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => 'ファイル操作';

  @override
  String get actions => '操作';

  @override
  String get gitStatusAdded => '追加済み';

  @override
  String get gitStatusDeleted => '削除済み';

  @override
  String get gitStatusRenamed => '名前変更済み';

  @override
  String get gitStatusCopied => 'コピー済み';

  @override
  String get gitStatusUntracked => '未追跡';

  @override
  String get gitStatusConflicted => '競合あり';

  @override
  String get gitStatusIgnored => '無視済み';

  @override
  String get gitStatusTypeChanged => '種類を変更済み';

  @override
  String get gitStatusModified => '変更済み';

  @override
  String get gitStatusUnknown => '不明';

  @override
  String get gitErrorUnavailable => 'Git を利用できません。';

  @override
  String get gitErrorNotRepository => 'このワークスペースは Git リポジトリではありません。';

  @override
  String get gitErrorUnsafePath => 'BusyMark は安全でない Git パスをブロックしました。';

  @override
  String get gitErrorInvalidBranchName => '有効なブランチ名を入力してください。';

  @override
  String get gitErrorNoRemote => 'Git のリモートが設定されていません。';

  @override
  String get gitErrorNoUpstream => 'アップストリームブランチが設定されていません。';

  @override
  String get gitErrorMultipleRemotes =>
      '複数のリモートが設定されています。BusyMark の外部でアップストリームを選択してください。';

  @override
  String get gitErrorDirtyWorkspace =>
      'ブランチを切り替える前に、BusyMark エディターの変更を保存または破棄してください。';

  @override
  String get gitErrorResetDirtyWorkspace =>
      '現在のブランチをリセットする前に、BusyMark エディターの変更を保存または破棄してください。';

  @override
  String get gitErrorRestoreStagedFile =>
      '過去のバージョンを復元する前に、このファイルをアンステージしてください。';

  @override
  String get gitErrorResetDetachedHead => 'リセットする前にブランチをチェックアウトしてください。';

  @override
  String get gitErrorDiverged =>
      'ブランチが分岐しています。BusyMark の外部でマージまたはリベースの問題を解決してください。';

  @override
  String get gitErrorAuthorIdentity => 'コミットするには、Git に作成者名とメールアドレスが必要です。';

  @override
  String get gitAuthorIdentityTitle => 'Git の作成者情報';

  @override
  String get gitAuthorIdentityMessage =>
      'コミットに記録する Git の識別情報を入力してください。BusyMark はそれを保存して、このコミットを再試行します。';

  @override
  String get gitAuthorName => '名前';

  @override
  String get gitAuthorEmail => 'メールアドレス';

  @override
  String get gitAuthorIdentityGlobal => 'すべてのリポジトリに使用';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Snap としてインストールした場合、BusyMark で開いたリポジトリに適用されます。';

  @override
  String get gitSaveIdentityAndCommit => '保存してコミット';

  @override
  String get gitErrorAuthentication => 'Git の認証に失敗しました。';

  @override
  String get gitErrorNetwork => 'Git のネットワーク操作に失敗しました。';

  @override
  String get gitErrorConflict => 'Git から未解決の競合が報告されました。';

  @override
  String get gitErrorCommandFailed => 'Git コマンドに失敗しました。';

  @override
  String get syntaxReference => '構文リファレンス';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown ブロック';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown のソースとプレビューでサポートされるブロック構造';

  @override
  String get syntaxReferenceInlineFormatting => 'インライン Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      '段落、リスト項目、表のセル内で使用できる書式';

  @override
  String get syntaxReferenceRawHtmlBlocks => '生 HTML ブロック';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'BusyMark のプレビューウィジェットでレンダリングされる安全なブロックレベル HTML タグ';

  @override
  String get syntaxReferenceRawHtmlInline => '生 HTML インラインタグ';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      'リテラルタグを表示せずにレンダリングされる安全なインライン HTML タグ';

  @override
  String get syntaxReferenceSafety => '安全性のルール';

  @override
  String get syntaxReferenceSafetyDescription =>
      '生 HTML はプレビューのレンダリング前に解析およびサニタイズされます。';

  @override
  String get syntaxReferenceHeadings => '見出し';

  @override
  String get syntaxReferenceParagraphs => '段落';

  @override
  String get syntaxReferenceLists => 'リスト';

  @override
  String get syntaxReferenceHtmlContainers => 'コンテナー';

  @override
  String get syntaxReferenceHtmlTextBlocks => 'テキストブロック';

  @override
  String get syntaxReferenceHtmlFigures => '図と画像';

  @override
  String get syntaxReferenceHtmlPreformatted => '整形済みコード';

  @override
  String get syntaxReferenceHtmlDisclosure => '折りたたみブロック';

  @override
  String get syntaxReferenceHtmlDescriptionLists => '説明リスト';

  @override
  String get syntaxReferenceHtmlFormattingTags => '書式タグ';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => 'インラインコードタグ';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => 'セマンティックテキストタグ';

  @override
  String get syntaxReferenceSanitizedPreview => 'サニタイズ済みプレビュー';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      '許可された HTML はブラウザーでレンダリングされず、BusyMark のプレビューブロックに変換されます。';

  @override
  String get syntaxReferenceSourcePreserved => 'ソースを保持';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      '編集されていない生 HTML はソーステキストのまま正確に保存されます。';

  @override
  String get syntaxReferenceMarkdownInsideHtml => 'HTML 内の Markdown';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      '生 HTML 内の Markdown マーカーはリテラルテキストとしてレンダリングされます。';

  @override
  String get syntaxReferenceBlockedContent => 'ブロックされたアクティブコンテンツ';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      'スクリプト、スタイル、フレーム、フォーム、SVG、MathML、イベント、安全でない属性はブロックされます。';

  @override
  String get syntaxReferenceSafeUrls => '安全な URL のみ';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      'リンクでは http、https、mailto、tel、相対パス、フラグメント URL が許可されます。安全でないスキームはブロックされます。';

  @override
  String get syntaxReferenceCategory => 'カテゴリ';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => '図と API';

  @override
  String get syntaxReferenceCategoryMathematics => '数式';

  @override
  String get syntaxReferenceExample => '例';

  @override
  String get syntaxReferenceIdentifiers => '識別子と別名';

  @override
  String get syntaxReferenceScope => '対象';

  @override
  String get syntaxReferenceLimitation => 'BusyMark での制限';

  @override
  String get syntaxReferenceOfficialDocumentation => '公式ドキュメント';

  @override
  String get syntaxReferenceScopeMarkdownAndWritersideMarkdown =>
      '通常の Markdown と Writerside Markdown';

  @override
  String get syntaxReferenceScopeWritersideMarkdown => 'Writerside Markdown のみ';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Writerside Markdown と Writerside XML のみ';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'BusyMark で作成およびプレビューできる主要な Markdown 形式です。';

  @override
  String get syntaxReferenceParagraphExample => 'テキストの段落です。';

  @override
  String get syntaxReferenceTableLimitation =>
      '表では GitHub Flavored Markdown のパイプ構文を使用します。';

  @override
  String get syntaxReferenceHardBreakIdentifiers => '行末の半角スペース 2 個、\\、<br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark は Markdown ソース内の限定された安全な生 HTML のみを受け付けます。';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Mermaid、PlantUML、D2、OpenAPI のフェンス付きブロックは Markdown ソースで機能します。フェンス識別子では大文字と小文字を区別せず、BusyMark は元の表記を保持します。';

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
      'フェンス内に YAML または JSON を記述してください。BusyMark は任意の YAML または JSON ファイル全体を OpenAPI リファレンスとして扱いません。';

  @override
  String get syntaxReferenceSemanticDiagramBlocks => '図用のセマンティックコードブロック';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      'セマンティックな code-block と src 形式で使用できるのは Mermaid、PlantUML、D2 です。OpenAPI には使用できず、Writerside プロジェクト内でのみ機能します。';

  @override
  String get syntaxReferenceReferencedDiagramSource => '参照する図のソース';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      'パスは相対パスで、開いている Writerside プロジェクト内に収まる必要があります。フェンスと src の形式は Writerside Markdown 専用です。';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark が対応するのは TeX 式であり、完全な TeX または LaTeX 文書ではありません。';

  @override
  String get syntaxReferenceInlineMath => 'インライン数式';

  @override
  String get syntaxReferenceGithubMath => 'ドル記号とバッククォートによる GitHub 数式';

  @override
  String get syntaxReferenceDisplayMath => '別行立て数式';

  @override
  String get syntaxReferenceMathFence => 'math フェンス';

  @override
  String get syntaxReferenceTexFence => 'tex フェンス';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark は \\(...\\) と \\[...\\] を Markdown の数式区切りとして認識しません。';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Writerside モード以外では、tex フェンスは通常のコードブロックのままです。';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside の math 要素';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math 要素は Writerside のセマンティック構文であり、許可された生 HTML MathML ではありません。';

  @override
  String get syntaxReferenceSemanticTexBlock => 'セマンティック TeX コードブロック';

  @override
  String get syntaxReferenceWritersideDescription =>
      'ここで示す拡張は、開いている Writerside プロジェクト内でのみ解釈されます。';

  @override
  String get syntaxReferenceAdmonitionBlockquote => '注意書きの引用';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      '通常のブロック引用は Writerside Markdown ではヒントになり、通常の Markdown では通常の引用のままです。';

  @override
  String get syntaxReferenceSemanticAdmonitions => 'セマンティックな注意書き';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      '通常の Markdown は、これらの Writerside セマンティック要素を解釈しません。';

  @override
  String get syntaxReferenceCollapsibleHeading => '折りたたみ可能な見出し';

  @override
  String get syntaxReferenceCollapsibleCode => '折りたたみ可能なコードフェンス';

  @override
  String get syntaxReferenceSemanticCollapsibles => 'セマンティックな折りたたみコンテンツ';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark が対応する折りたたみ形式は chapter、procedure、code-block、定義リストです。Writerside の全カタログには対応しません。';

  @override
  String get syntaxReferenceSemanticCodeBlocks => '数式と図用のセマンティックコードブロック';

  @override
  String get syntaxReferenceVideo => 'Writerside 動画';

  @override
  String get syntaxReferenceVideoLimitation =>
      'ローカル動画にはローカルの preview-src 画像を使用します。ホスト動画は対応する YouTube または Vimeo の HTTPS URL に限られます。';

  @override
  String get exportAsPdf => 'PDF としてエクスポート';

  @override
  String get pdfExportDescription => 'ページレイアウトを選択して、整った自己完結型の PDF を生成';

  @override
  String get pdfRemoteImagesNote =>
      'エクスポート中にリモート画像はダウンロードされません。利用可能な場合はローカル画像が含まれます。';

  @override
  String get pdfPageSize => 'ページサイズ';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => '向き';

  @override
  String get pdfPortrait => '縦向き';

  @override
  String get pdfLandscape => '横向き';

  @override
  String get pdfMargins => '余白';

  @override
  String get pdfMarginNarrow => '狭い';

  @override
  String get pdfMarginNormal => '標準';

  @override
  String get pdfMarginWide => '広い';

  @override
  String get pdfIncludePageNumbers => 'ページ番号を含める';

  @override
  String get export => 'エクスポート';

  @override
  String get exportingPdf => 'PDF をエクスポート中…';

  @override
  String get fileTypePdf => 'PDF ドキュメント';

  @override
  String pdfExported(String fileName) {
    return '$fileName をエクスポートしました。';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の警告',
      one: '1 件の警告',
    );
    return '$fileName は $_temp0 とともにエクスポートされました。';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF エクスポートコンポーネントがありません。BusyMark を再インストールして、もう一度お試しください。';

  @override
  String get pdfExportTimedOut => 'PDF のエクスポートに時間がかかりすぎたため停止しました。';

  @override
  String get pdfExportFailed => 'BusyMark はこのドキュメントを PDF としてエクスポートできませんでした。';

  @override
  String get visualizationRendering => 'レンダリング中…';

  @override
  String get visualizationStale => '最後に有効だったレンダリング結果を表示中';

  @override
  String get visualizationShowSource => 'ソースを表示';

  @override
  String get visualizationShowRender => 'レンダリング結果を表示';

  @override
  String get visualizationFitWidth => '幅に合わせる';

  @override
  String get visualizationSaveImage => '画像を保存';

  @override
  String get visualizationCopyImage => '画像をコピー';

  @override
  String get visualizationImageCopied => '画像をコピーしました';

  @override
  String get visualizationOpenApiReference => 'API リファレンスを開く';

  @override
  String get visualizationValid => '有効';

  @override
  String get visualizationInvalid => '無効';

  @override
  String get visualizationServers => 'サーバー';

  @override
  String get visualizationPaths => 'パス';

  @override
  String get visualizationOperations => '操作';

  @override
  String get visualizationTags => 'タグ';

  @override
  String get visualizationNoOperations => '一致する操作はありません';

  @override
  String get visualizationSearchOperations => '操作を検索';

  @override
  String get visualizationRenderFailed => 'この可視化をレンダリングできませんでした。';

  @override
  String get visualizationRetry => '再試行';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName を保存しました';
  }

  @override
  String get shortcutExportPdfDescription =>
      '現在のドキュメントまたは Writerside モジュールを PDF としてエクスポート';

  @override
  String get instances => 'インスタンス';

  @override
  String get newInstance => '新しいインスタンス';

  @override
  String get newTocLibrary => '新しい目次ライブラリ';

  @override
  String get editInstance => 'インスタンスを編集';

  @override
  String get openTocFile => '目次ファイルを開く';

  @override
  String get createInstance => 'インスタンスを作成';

  @override
  String get createTocLibrary => '目次ライブラリを作成';

  @override
  String get instanceContent => 'コンテンツ';

  @override
  String get instanceContentSource => '作成元';

  @override
  String get emptyInstance => '空のインスタンス';

  @override
  String get markdownFiles => 'ローカル Markdown ファイル';

  @override
  String get chooseMarkdownFolder => 'Markdown フォルダーを選択';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Markdown ファイルを含むフォルダーを選択してください。';

  @override
  String get instanceAppearance => '外観';

  @override
  String get instanceColor => 'アイコンの色';

  @override
  String get instanceVersion => 'バージョン';

  @override
  String instanceVersionInherited(String version) {
    return 'この項目が空の場合、プロジェクトのバージョンは $version です。';
  }

  @override
  String get instanceWebPath => 'ウェブパス';

  @override
  String get instanceStatus => 'ステータス';

  @override
  String get instanceStatusRelease => 'リリース';

  @override
  String get instanceStatusEap => '早期アクセス';

  @override
  String get instanceStatusDeprecated => '非推奨';

  @override
  String get allowSearchEngineIndexing => '検索エンジンによるインデックス登録を許可';

  @override
  String get allowSearchEngineIndexingDescription =>
      '外部検索エンジンによるこの出力のインデックス登録を許可';

  @override
  String get offlineArtifact => 'オフラインアーティファクト';

  @override
  String get offlineArtifactDescription => '構築したドキュメントを自己完結させるためにリソースをバンドル';

  @override
  String get instanceOutputSettings => '出力設定';

  @override
  String get markdownImportSource => 'Markdown ソース';

  @override
  String get markdownImportFiles => 'Markdown ファイル';

  @override
  String get selectNone => 'すべて選択解除';

  @override
  String markdownFilesFound(int count) {
    return 'Markdown ファイルが $count 件見つかりました';
  }

  @override
  String get noMarkdownFilesFound => 'このディレクトリに Markdown ファイルは見つかりませんでした。';

  @override
  String get copyReferencedMedia => '参照されたメディアをコピー';

  @override
  String get copyReferencedMediaDescription =>
      '選択したファイルから参照されているローカル画像と動画を、相対パスを保持したままコピー';

  @override
  String get instanceIdRenameWarningTitle => 'インスタンス ID の名前を変更しますか？';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark は .tree ファイルの名前を変更し、Writerside プロジェクトの参照を「$oldId」から「$newId」に更新します。公開スクリプトは変更されないため、別途更新する必要があります。';
  }

  @override
  String get renameAndUpdateReferences => '名前を変更して参照を更新';

  @override
  String get tocLibraryDescription =>
      '目次ライブラリには再利用可能なセクションが保存され、独自の出力は生成されません。';

  @override
  String get defaultTocLibraryName => '共有目次';

  @override
  String get instanceColorAutomatic => '自動';

  @override
  String get instanceColorBlue => '青';

  @override
  String get instanceColorGreen => '緑';

  @override
  String get instanceColorOrange => 'オレンジ';

  @override
  String get instanceColorPurple => '紫';

  @override
  String get instanceColorRed => '赤';

  @override
  String get instanceColorTeal => '青緑';

  @override
  String get instanceColorYellow => '黄';

  @override
  String get errorWritersideInstanceNameRequired => 'インスタンス名を入力してください。';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'ID「$id」のインスタンスはすでに存在します。';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return 'インスタンスツリーはすでに存在します：$path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown ソースディレクトリが存在しません：$path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      'インポートする Markdown ファイルを少なくとも 1 つ選択してください。';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return '選択したソース内に読み取り可能な Markdown ファイルではないものがあります：$path';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return 'インポートすると既存のプロジェクトファイルが上書きされます：$path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      'インスタンスのファイルがディスク上で変更されました。確認して、もう一度お試しください。';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark はインスタンスの変更を完全にはロールバックできませんでした。続行する前に次のファイルを確認してください：$paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      '目次ライブラリに Markdown トピックをインポートすることはできません。';

  @override
  String get errorWritersideInstanceWebPathInvalid => 'ウェブパスは 1 行である必要があります。';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside インスタンスの構成が無効です。診断情報を修正して、もう一度お試しください。';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark はインスタンスの変更を安全にステージできませんでした。';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return '不明なインスタンスステータス「$status」です。release、eap、deprecated のいずれかを使用してください。';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return 'インスタンス ID「$id」が複数のツリーファイルで使用されています。';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml には <buildprofiles> ルート要素が必要です。';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '$name の値「$value」は true または false である必要があります。';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> 要素にはインスタンス ID の指定が必要です。';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      'ツリーの <include> には from と element-id の両方を指定する必要があります。';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      'ツリーの <snippet> には id の指定が必要です。';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      'インスタンス間の目次参照には ref と in の両方を指定する必要があります。';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      '目次要素が複数のトピック、参照、リンク、またはリダイレクトを対象にすることはできません。';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return 'ツリー要素 ID「$id」が複数回宣言されています。';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      'インスタンスグループファイルには <instance-groups> ルート要素が必要です。';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      'インスタンスグループには空でない id とインスタンスリストの指定が必要です。';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return 'インスタンスグループ ID「$id」が複数回宣言されています。';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return '目次のインクルード「$source#$id」は外部モジュール「$origin」に属しているため、このワークスペースでは展開できません。';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '登録されたツリー「$source」にツリー要素「$id」が存在しません。';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return 'ツリーのインクルード「$source#$id」が循環を作成しています。';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return 'インスタンス条件が不明なグループ「@$group」を参照しています。';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return 'インスタンス間参照が不明なインスタンス「$instance」を対象にしています。';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return 'トピック「$topic」は参照先のインスタンス「$instance」にありません。';
  }

  @override
  String get download => 'ダウンロード';

  @override
  String get exportWritersideAsPdf => 'Writerside を PDF としてエクスポート';

  @override
  String get writersidePdfContent => 'エクスポートする内容';

  @override
  String get writersidePdfPage => 'ページ';

  @override
  String get exportingWritersidePdf => 'Writerside PDF をエクスポート中…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => 'ローカル Ollama';

  @override
  String get aiDisabled => '無効';

  @override
  String get aiExplicitEditingDescription =>
      'AI による編集は明示的に実行されます。BusyMark は選択したプロバイダーに表示されたコンテキストのみを送信し、確認なしに提案を適用することはありません。';

  @override
  String get aiProvider => 'AI プロバイダー';

  @override
  String get aiDefaultProvider => 'デフォルトのプロバイダー';

  @override
  String get aiConfigureProvider => 'プロバイダーを設定';

  @override
  String get aiChooseProvider => 'AI プロバイダーを選択';

  @override
  String get aiOllamaEndpoint => 'Ollama エンドポイント';

  @override
  String get aiOllamaModel => 'Ollama モデル';

  @override
  String get aiTestConnection => '接続をテスト';

  @override
  String get aiTestingConnection => 'テスト中…';

  @override
  String aiConnectionReady(int count) {
    return '接続しました。インストール済みのモデルが $count 件見つかりました。';
  }

  @override
  String get aiNoModels => 'モデルが選択されていません。';

  @override
  String get aiConnectionFailed => 'BusyMark は AI によるテキスト生成を確認できませんでした。';

  @override
  String get aiConfigureFirst => '設定 → AI で AI プロバイダーを有効にして、モデルを確認してください。';

  @override
  String get aiEditWithAi => 'AI で編集';

  @override
  String get aiRefineWithAi => 'AI で改善';

  @override
  String get aiInstruction => '指示';

  @override
  String get aiChangeTarget => '変更対象';

  @override
  String get aiSharedContext => 'AI と共有するコンテキスト';

  @override
  String get aiTargetSelection => '選択したコンテンツ';

  @override
  String get aiTargetInsertAfterBlock => '現在のブロックの後に挿入';

  @override
  String get aiTargetCurrentBlock => '現在のブロック';

  @override
  String get aiTargetCurrentSection => '現在のセクション';

  @override
  String get aiTargetCompleteDocument => 'ドキュメント全体';

  @override
  String get aiContextNone => 'ドキュメントのコンテキストなし';

  @override
  String get aiContextSelection => '選択したコンテンツ';

  @override
  String get aiContextCurrentBlock => '現在のブロック';

  @override
  String get aiContextCurrentSection => '現在のセクション';

  @override
  String get aiContextCompleteDocument => 'ドキュメント全体';

  @override
  String get aiGenerating => '提案を生成中…';

  @override
  String get aiProposal => 'AI の提案';

  @override
  String get aiGenerateProposal => '提案を生成';

  @override
  String aiContextDisclosure(int count) {
    return '選択したプロバイダーは、表示されたコンテキストから $count 文字を受け取ります。';
  }

  @override
  String get aiOriginal => '元の内容';

  @override
  String get aiSuggested => '提案された内容';

  @override
  String get aiApplyProposal => '提案を適用';

  @override
  String aiTokenUsage(int input, int output) {
    return '入力トークン：$input · 出力トークン：$output';
  }

  @override
  String get aiStaleProposal => 'この提案の生成中にドキュメントが変更されました。操作をもう一度実行してください。';

  @override
  String get gitAiStagedChangesChanged =>
      'コミットメッセージの生成中にステージ済みの変更が変わりました。操作をもう一度実行してください。';

  @override
  String get aiViewContext => '送信されたコンテキストを表示';

  @override
  String get aiReviewExactContent => '正確な内容を確認';

  @override
  String get aiContentToChange => '変更する内容';

  @override
  String get aiContentSentToAi => 'AI に送信された内容';

  @override
  String get aiApiKey => 'API キー';

  @override
  String get aiApiKeyStoredHint => 'キーはシステムの認証情報ストアに保存されています';

  @override
  String get aiApiKeyEnterHint => 'プロバイダーの API キーを入力';

  @override
  String get aiReplaceApiKey => 'API キーを置き換え';

  @override
  String get aiSaveApiKey => 'API キーを安全に保存';

  @override
  String get aiRemoveApiKey => '保存した API キーを削除';

  @override
  String get aiCredentialSaved => 'API キーをシステムの認証情報ストアに保存しました。';

  @override
  String get aiCredentialRemoved => '保存した API キーを削除しました。';

  @override
  String get aiModelRouting => 'モデルのルーティング';

  @override
  String get aiAutomaticRouting => 'タスクに応じて自動選択';

  @override
  String get aiFixedModelRouting => '選択したモデルを使用';

  @override
  String get aiPreferredModel => '優先モデル';

  @override
  String get aiModel => 'モデル';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests 件のリクエスト · 入力トークン $input · 出力トークン $output';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '$provider にコンテンツを送信しますか？';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '$provider を有効にする';
  }

  @override
  String get aiCloudConsentMessage =>
      '各 AI レビューダイアログに表示された内容のみが送信されます。リクエストは状態を保持せず、提案には確認が必要です。API キーは Linux のシステム認証情報ストアに保存されます。';

  @override
  String aiCloudConsentRequired(String provider) {
    return '先に設定 → AI で $provider とのデータ共有を確認してください。';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '$model で生成機能を確認しました。互換性のあるモデルが $count 件利用できます。';
  }

  @override
  String get aiColdStartObserved => 'ローカルモデルのコールドスタートを検出しました。';

  @override
  String get aiNoCompatibleModels => '互換性のあるテキスト生成モデルがありません。';

  @override
  String get aiEnableProvider => '先に AI プロバイダーを有効にしてください。';

  @override
  String get aiDraftCommitMessage => 'コミットメッセージを下書き';

  @override
  String get aiDrafting => '下書き中…';

  @override
  String get aiDraftWithAi => 'AI で下書き';

  @override
  String get generateOrUpdateMarkdownToc => '目次を生成／更新';

  @override
  String get markdownTocTitle => '目次';

  @override
  String markdownTocUpdated(int count) {
    return '$count 件の項目で目次を更新しました。';
  }

  @override
  String get markdownTocNoHeadings => '目次を生成する前に、セクション見出しを 1 つ以上追加してください。';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMark の目次マーカーがないか、重複しているか、順序が正しくありません。';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '見出しレベル $level はレベル $previousLevel の後に続いています。セクションの入れ子を確認してください。';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      'リンクテキストが空です。用途を説明するアクセシブルな名前を指定してください。';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return 'リンクテキスト「$text」が文脈内で用途を説明しているか確認してください。';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      '表のヘッダーセルは列を識別できる必要があります。空のヘッダーをすべて入力してください。';

  @override
  String get mathRenderFailed => '数式をレンダリングできませんでした。';

  @override
  String get inlineMath => 'インライン数式';

  @override
  String get displayMath => 'ディスプレイ数式';
}
