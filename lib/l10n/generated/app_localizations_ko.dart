// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'BusyMark';

  @override
  String get appSubtitle => 'Markdown 파일 및 Writerside 호환 문서 프로젝트용 편집기입니다.';

  @override
  String get aboutBusyMark => 'BusyMark 소개';

  @override
  String get aboutTagline => '마크다운 및 Writerside 편집기';

  @override
  String get aboutLicenseLabel => '라이선스';

  @override
  String get aboutLicenseName => 'Apache License 2.0';

  @override
  String get aboutWebsite => '웹사이트';

  @override
  String get aboutSourceCode => '소스 코드';

  @override
  String get reportIssue => '문제 신고';

  @override
  String get feedbackCategory => '범주';

  @override
  String get feedbackChooseCategory => '카테고리를 선택하세요';

  @override
  String get feedbackCategoryProblem => '문제 또는 버그';

  @override
  String get feedbackCategoryFeature => '기능 요청';

  @override
  String get feedbackCategoryPrivacySecurity => '개인 정보 보호 또는 보안 문제';

  @override
  String get feedbackCategoryUsability => '사용성 문제';

  @override
  String get feedbackCategoryOther => '기타';

  @override
  String get feedbackSubject => '제목';

  @override
  String get feedbackMessage => '자세한 메시지';

  @override
  String get feedbackReplyEmail => '회신용 이메일 주소(선택)';

  @override
  String get feedbackIncludeTechnicalDetails => '기술 세부정보 포함';

  @override
  String get feedbackTechnicalDetailsDisclosure =>
      '사용 설정하면 Linux 운영 체제 버전과 BusyMark 애플리케이션 언어만 추가됩니다. 로그, 파일, 계정 데이터 또는 기타 진단 정보는 첨부되지 않습니다.';

  @override
  String get feedbackSubmit => '제출';

  @override
  String get feedbackSubmitting => '제출 중…';

  @override
  String get feedbackCategoryRequired => '카테고리를 선택하세요.';

  @override
  String get feedbackSubjectLength => '제목은 3~120자 사이여야 합니다.';

  @override
  String get feedbackMessageLength => '메시지는 10~5,000자 사이여야 합니다.';

  @override
  String get feedbackReplyEmailInvalid => '유효한 이메일 주소를 입력하거나 이 필드를 비워 두세요.';

  @override
  String get feedbackConnectionFailure =>
      'BusyMark를 연결할 수 없습니다. 인터넷 연결을 확인하고 다시 시도하세요.';

  @override
  String get feedbackTimeoutFailure => '요청 시간이 초과되었습니다. 다시 시도해 보세요.';

  @override
  String get feedbackRateLimitedFailure =>
      '이 연결에서 너무 많은 보고서가 전송되었습니다. 기다렸다가 다시 시도해 보세요.';

  @override
  String get feedbackRejectedFailure =>
      '서버가 이 보고서를 거부했습니다. 양식 필드를 확인하고 다시 시도하세요.';

  @override
  String get feedbackServerFailure => '서버가 보고서를 수락할 수 없습니다. 나중에 다시 시도하세요.';

  @override
  String feedbackSuccess(String id) {
    return '피드백이 전송되었습니다. 참조 ID: $id';
  }

  @override
  String get advanced => '고급';

  @override
  String get addToGit => 'Git에 추가';

  @override
  String get appearance => '화면 모양';

  @override
  String get apply => '적용';

  @override
  String get back => '뒤로';

  @override
  String get bottomLeft => '왼쪽 하단';

  @override
  String get bottomRight => '오른쪽 하단';

  @override
  String get cancel => '취소';

  @override
  String get choose => '선택';

  @override
  String get chooseLocation => '위치 선택';

  @override
  String get copy => '복사';

  @override
  String get copyName => '이름 복사';

  @override
  String get copyFileName => '파일 이름 복사';

  @override
  String get copyPath => '경로 복사';

  @override
  String get create => '만들기';

  @override
  String get creating => '만드는 중...';

  @override
  String get cut => '잘라내기';

  @override
  String get promoteSection => '섹션 수준 올리기';

  @override
  String get demoteSection => '섹션 수준 내리기';

  @override
  String get moveSectionUp => '섹션을 위로 이동';

  @override
  String get moveSectionDown => '섹션을 아래로 이동';

  @override
  String get confirmDeleteSectionTitle => '섹션을 삭제하시겠습니까?';

  @override
  String confirmDeleteSectionMessage(String name) {
    return '“$name” 및 해당 섹션의 모든 콘텐츠를 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get darkTheme => '어둡게';

  @override
  String get delete => '삭제';

  @override
  String get discard => '버리기';

  @override
  String get editor => '편집기';

  @override
  String get file => '파일';

  @override
  String get fileHistory => '파일 기록';

  @override
  String get folder => '폴더';

  @override
  String get insert => '삽입';

  @override
  String get keyboardShortcuts => '키보드 단축키';

  @override
  String get commandPalette => '명령 팔레트';

  @override
  String get commandPaletteHint => '명령을 입력하세요';

  @override
  String get commandPaletteEmpty => '일치하는 명령이 없습니다.';

  @override
  String get commandUnavailableInContext => '현재 편집기 컨텍스트에서는 사용할 수 없습니다.';

  @override
  String get lightTheme => '밝게';

  @override
  String get mainMenu => '메인 메뉴';

  @override
  String get fullScreen => '전체 화면';

  @override
  String get markdown => 'Markdown';

  @override
  String get open => '열기';

  @override
  String get openInFiles => '파일에서 열기';

  @override
  String get pathActions => '경로 작업';

  @override
  String get outline => '개요';

  @override
  String get overwrite => '덮어쓰기';

  @override
  String get paste => '붙여넣기';

  @override
  String get pasteWithoutFormatting => '서식 없이 붙여넣기';

  @override
  String get reading => '읽기';

  @override
  String get removeFromRecent => '최근 항목에서 삭제';

  @override
  String get recent => '최근 항목';

  @override
  String get redo => '다시 실행';

  @override
  String get save => '저장';

  @override
  String get search => '검색';

  @override
  String get selectAll => '모두 선택';

  @override
  String get settings => '설정';

  @override
  String get source => '소스';

  @override
  String get split => '분할';

  @override
  String get systemTheme => '시스템';

  @override
  String get theme => '테마';

  @override
  String get appLanguage => '언어';

  @override
  String get systemLanguage => '시스템 언어';

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
  String get toggleSidebar => '사이드바 패널';

  @override
  String get topLeft => '왼쪽 상단';

  @override
  String get topRight => '오른쪽 상단';

  @override
  String get undo => '실행 취소';

  @override
  String get validate => '검증';

  @override
  String get validation => '검증';

  @override
  String get viewMode => '보기 모드';

  @override
  String get welcome => '환영합니다';

  @override
  String get writerside => 'Writerside';

  @override
  String get xml => 'XML';

  @override
  String get fileTypeMarkdown => 'Markdown';

  @override
  String get fileTypeImages => '이미지';

  @override
  String get openMarkdownFile => 'Markdown 파일 열기';

  @override
  String get markdownFileExtensions => '.md 또는 .markdown';

  @override
  String get openFolderOrWritersideProject => '폴더 또는 Writerside 프로젝트 열기';

  @override
  String get markdownFolderOrWritersideProject =>
      'Markdown 폴더 또는 Writerside 호환 프로젝트';

  @override
  String get noOpenFile => '열린 파일 없음';

  @override
  String get shortcutDeleteTreeItemDescription =>
      '선택한 파일 항목을 삭제하거나 목차에서 선택한 항목을 제거합니다.';

  @override
  String get shortcutGroupGeneral => '일반';

  @override
  String get shortcutNewDocument => '만들기';

  @override
  String get shortcutNewDocumentDescription =>
      'Markdown 파일 또는 Writerside 프로젝트 만들기';

  @override
  String get shortcutOpenDescription => 'Markdown 파일, 폴더 또는 Writerside 프로젝트 열기';

  @override
  String get shortcutSaveDescription => '현재 문서 저장';

  @override
  String get shortcutSearchDescription => '현재 작업공간 검색';

  @override
  String get shortcutKeyboardShortcutsDescription => '이 키보드 단축키 참조 표시';

  @override
  String get shortcutSyntaxReferenceDescription => '구문 참조 열기';

  @override
  String get shortcutSettingsDescription => 'BusyMark 설정 열기';

  @override
  String get shortcutNextTab => '다음 탭';

  @override
  String get shortcutNextTabDescription => '열려 있는 다음 탭으로 이동';

  @override
  String get shortcutPreviousTab => '이전 탭';

  @override
  String get shortcutPreviousTabDescription => '이전에 열린 탭으로 이동';

  @override
  String get shortcutCloseTab => '탭 닫기';

  @override
  String get shortcutCloseTabDescription => '활성 탭 닫기';

  @override
  String get shortcutCloseAllTabs => '모든 탭 닫기';

  @override
  String get shortcutCloseAllTabsDescription => '열려 있는 탭을 모두 닫습니다.';

  @override
  String get shortcutGroupTextEditing => '텍스트 편집';

  @override
  String get shortcutSelectAllDescription =>
      '소스 모드에서는 모든 텍스트를 선택합니다. 편집기 모드에서는 두 번 눌러 모든 블록을 선택합니다.';

  @override
  String get shortcutCutDescription => '선택한 텍스트 잘라내기';

  @override
  String get shortcutCopyDescription => '선택한 텍스트 복사';

  @override
  String get shortcutPasteDescription => '클립보드에서 붙여넣기';

  @override
  String get shortcutPastePlainTextDescription => '서식 없이 클립보드 텍스트 붙여넣기';

  @override
  String get shortcutUndoDescription => '마지막 편집 취소';

  @override
  String get shortcutRedoDescription => '마지막으로 실행 취소된 편집 다시 실행';

  @override
  String get shortcutInsertIndentation => '들여쓰기 삽입';

  @override
  String get shortcutInsertIndentationDescription => '커서에 들여쓰기 삽입';

  @override
  String get shortcutOutdentSource => '소스를 내어쓰기';

  @override
  String get shortcutOutdentSourceDescription => '소스 모드에서 들여쓰기 수준 하나 제거';

  @override
  String get shortcutEscape => '검색 닫기 또는 블록 선택 지우기';

  @override
  String get shortcutEscapeDescription => '작업공간 검색을 닫거나 편집기 모드에서 블록 선택을 취소하세요.';

  @override
  String get shortcutGroupFormatting => '서식';

  @override
  String get shortcutBoldDescription => '선택한 텍스트를 굵게 전환합니다.';

  @override
  String get shortcutItalicDescription => '선택한 텍스트에서 기울임체를 전환합니다.';

  @override
  String get shortcutUnderlineDescription => '선택한 텍스트에 밑줄을 토글합니다.';

  @override
  String get shortcutLinkDescription => '링크 삽입 또는 편집';

  @override
  String get shortcutInlineCodeDescription => '선택한 텍스트에서 인라인 코드 전환';

  @override
  String get shortcutStrikethroughDescription => '선택한 텍스트에 취소선을 토글합니다.';

  @override
  String get shortcutGroupBlocks => '블록';

  @override
  String get shortcutParagraphDescription => '현재 블록을 단락으로 설정';

  @override
  String get shortcutHeading1Description => '현재 블록을 제목 1로 설정';

  @override
  String get shortcutHeading2Description => '현재 블록을 제목 2로 설정';

  @override
  String get shortcutHeading3Description => '현재 블록을 제목 3으로 설정';

  @override
  String get shortcutHeading4Description => '현재 블록을 제목 4로 설정';

  @override
  String get shortcutHeading5Description => '현재 블록을 제목 5로 설정';

  @override
  String get shortcutHeading6Description => '현재 블록을 제목 6으로 설정';

  @override
  String get shortcutGroupLists => '목록';

  @override
  String get numberedList => '번호 매기기 목록';

  @override
  String get shortcutNumberedListDescription => '번호 매기기 목록 형식 전환';

  @override
  String get bulletedList => '글머리 기호 목록';

  @override
  String get shortcutBulletedListDescription => '글머리 기호 목록 형식 전환';

  @override
  String get checklist => '체크리스트';

  @override
  String get shortcutChecklistDescription => '체크리스트 형식 전환';

  @override
  String get shortcutGroupSidebar => '사이드바';

  @override
  String get sidebarViewMenu => '사이드바 보기';

  @override
  String get createMarkdownFile => '마크다운 파일 생성';

  @override
  String get createMarkdownFileDescription => '저장되지 않은 로컬 Markdown 문서 시작';

  @override
  String get createWritersideProject => 'Writerside 프로젝트 만들기';

  @override
  String get createWritersideProjectDescription => '로컬 Writerside 호환 프로젝트 시작';

  @override
  String get defaultProjectName => '문서';

  @override
  String get defaultInstanceName => '사용자 가이드';

  @override
  String get defaultStartTopicTitle => '시작하기';

  @override
  String get projectName => '프로젝트 이름';

  @override
  String get directoryName => '디렉토리 이름';

  @override
  String get instanceName => '인스턴스 이름';

  @override
  String get instanceId => '인스턴스 ID';

  @override
  String get startTopicTitle => '시작 토픽 제목';

  @override
  String get location => '위치';

  @override
  String get projectNameRequired => '프로젝트 이름이 필요합니다.';

  @override
  String get directoryNameRequired => '디렉터리 이름이 필요합니다.';

  @override
  String get useSingleSafeDirectoryName => '단일 안전한 디렉터리 이름을 사용하세요.';

  @override
  String get useLowercaseIdentifier => '문자, 숫자, 밑줄 또는 하이픈이 포함된 소문자 식별자를 사용하세요.';

  @override
  String get startTopicTitleRequired => '시작 토픽 제목이 필요합니다.';

  @override
  String get createWritersideProjectFailed => 'Writerside 프로젝트를 생성할 수 없습니다.';

  @override
  String get settingsTitle => 'BusyMark 설정';

  @override
  String get autoSave => '자동 저장';

  @override
  String get autoSaveDescription => '파일 변경 사항은 짧은 유휴 기간이 지나면 자동으로 저장됩니다.';

  @override
  String get wordWrap => '자동 줄 바꿈';

  @override
  String get editorFontSize => '편집기 글꼴 크기';

  @override
  String get validateOnEdit => '편집할 때 검증';

  @override
  String get clearRecentWorkspaces => '최근 작업공간 지우기';

  @override
  String get editingButtonsPosition => '편집 버튼 위치';

  @override
  String get editingButtonsPositionDescription =>
      '부동 WYSIWYG 편집 버튼이 나타나는 위치를 선택합니다.';

  @override
  String get editingButtonsDirection => '편집 버튼 방향';

  @override
  String get editingButtonsDirectionDescription =>
      '부동 WYSIWYG 편집 버튼을 수평 또는 수직으로 정렬할지 선택합니다.';

  @override
  String get horizontal => '가로';

  @override
  String get vertical => '세로';

  @override
  String get privacy => '개인정보 보호';

  @override
  String get allowRemoteImages => '원격 이미지 로드';

  @override
  String get allowRemoteImagesDescription =>
      'Markdown 미리보기 및 편집기 이미지가 http 및 https URL에서 로드되도록 허용합니다.';

  @override
  String get clearRemoteImagePermissions => '원격 이미지 권한 초기화';

  @override
  String get clearRemoteImagePermissionsDescription =>
      '원격 이미지 로드 권한이 허용된 작업공간의 저장된 권한을 삭제합니다.';

  @override
  String get clearGitWorkspaceTrust => '신뢰할 수 있는 Git 작업공간 초기화';

  @override
  String get clearGitWorkspaceTrustDescription =>
      '이전에 신뢰한 작업공간에서 Git 기능을 활성화하기 전에 확인하도록 설정합니다.';

  @override
  String get settingsWindowSectionTitle => '창';

  @override
  String get settingsReopenWorkspaceOnStartupTitle => '시작 시 이전 작업공간 다시 열기';

  @override
  String get settingsReopenWorkspaceOnStartupDescription =>
      'BusyMark가 시작될 때 이전 세션의 작업공간과 탭을 엽니다.';

  @override
  String get settingsConfirmCloseWithUnsavedChangesTitle =>
      '저장되지 않은 변경 사항이 있을 때 닫기 전에 확인';

  @override
  String get settingsConfirmCloseWithUnsavedChangesDescription =>
      '문서에 저장되지 않은 변경 사항이 있는 경우 BusyMark를 닫기 전에 물어보세요.';

  @override
  String get closeUnsavedChangesTitle => '저장되지 않은 변경 사항';

  @override
  String get closeUnsavedChangesSingleMessage =>
      '이 문서에는 저장되지 않은 변경사항이 있습니다. BusyMark를 닫기 전에 변경 사항을 저장하시겠습니까?';

  @override
  String closeUnsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '미저장 문서가 $count개 있습니다. BusyMark를 닫기 전에 저장하시겠습니까?',
      one: '미저장 문서가 1개 있습니다. BusyMark를 닫기 전에 저장하시겠습니까?',
      zero: 'BusyMark를 닫기 전에 변경 사항을 저장하시겠습니까?',
    );
    return '$_temp0';
  }

  @override
  String get closeUnsavedChangesCancel => '취소';

  @override
  String get closeUnsavedChangesDiscard => '버리기';

  @override
  String get closeUnsavedChangesSave => '저장';

  @override
  String get currentFile => '현재 파일';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항';

  @override
  String unsavedChangesMessage(String fileName) {
    return '$fileName에 저장되지 않은 변경사항이 있습니다. 계속하기 전에 저장하시겠습니까?';
  }

  @override
  String unsavedChangesMultipleMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '미저장 문서가 $count개 있습니다. 계속하기 전에 저장하시겠습니까?',
      one: '미저장 문서가 1개 있습니다. 계속하기 전에 저장하시겠습니까?',
    );
    return '$_temp0';
  }

  @override
  String get fileChangedOnDisk => '디스크에서 파일이 변경됨';

  @override
  String get fileChangedOnDiskMessage =>
      '이 파일은 사용자가 연 이후 디스크에서 변경되었습니다. 덮어쓰시겠습니까?';

  @override
  String get untitledMarkdownFileName => '제목 없음.md';

  @override
  String get unorderedList => '글머리 기호 목록';

  @override
  String get orderedList => '번호 매기기 목록';

  @override
  String get taskList => '작업 목록';

  @override
  String get toggleTaskChecked => '작업 완료 상태 전환';

  @override
  String get indentListItem => '들여쓰기 목록 항목';

  @override
  String get outdentListItem => '내어쓰기 목록 항목';

  @override
  String get blockquote => '인용문';

  @override
  String get codeBlock => '코드 블록';

  @override
  String get codeBlockLanguage => '코드 블록 언어';

  @override
  String get image => '이미지';

  @override
  String get video => '동영상';

  @override
  String get openVideo => '동영상 재생';

  @override
  String get pauseVideo => '동영상 일시 중지';

  @override
  String get videoUnavailable => '동영상을 사용할 수 없음';

  @override
  String get videoPreview => '동영상 미리 보기';

  @override
  String get diagnosticWritersideVideoMissingSource => '비디오에 src 속성이 없습니다.';

  @override
  String diagnosticWritersideVideoUnsupportedSource(String source) {
    return '지원되지 않는 비디오 소스: $source';
  }

  @override
  String diagnosticWritersideVideoMissingFile(String source) {
    return '동영상 파일이 존재하지 않습니다: $source';
  }

  @override
  String diagnosticWritersideVideoMissingPreview(String preview) {
    return '동영상 미리보기 이미지가 존재하지 않습니다: $preview';
  }

  @override
  String get inlineImage => '인라인 이미지';

  @override
  String get table => '표';

  @override
  String get htmlBlock => 'HTML 블록';

  @override
  String get htmlContentDefault => 'HTML 콘텐츠';

  @override
  String get shortcutHtmlBlockDescription => 'HTML 블록 삽입 또는 편집';

  @override
  String get renderedHtml => '렌더링된 HTML';

  @override
  String get editHtml => 'HTML 편집';

  @override
  String get htmlSource => 'HTML 소스';

  @override
  String get thematicBreak => '수평선';

  @override
  String get bold => '굵게';

  @override
  String get italic => '기울임꼴';

  @override
  String get underline => '밑줄';

  @override
  String get strikethrough => '취소선';

  @override
  String get inlineCode => '인라인 코드';

  @override
  String get link => '링크';

  @override
  String get hardLineBreak => '강제 줄 바꿈';

  @override
  String get textStyle => '텍스트 스타일';

  @override
  String get paragraph => '단락';

  @override
  String get heading1 => '제목 1';

  @override
  String get heading2 => '제목 2';

  @override
  String get heading3 => '제목 3';

  @override
  String get heading4 => '제목 4';

  @override
  String get heading5 => '제목 5';

  @override
  String get heading6 => '제목 6';

  @override
  String headingLevelAbbreviation(int level) {
    return 'H$level';
  }

  @override
  String get deleteTable => '테이블 삭제';

  @override
  String tableColumnNumber(int columnNumber) {
    return '열 $columnNumber';
  }

  @override
  String get insertColumnLeft => '왼쪽에 열 삽입';

  @override
  String get insertColumnRight => '오른쪽에 열 삽입';

  @override
  String get deleteColumn => '열 삭제';

  @override
  String get tableAlignmentUnspecified => '정렬: 지정되지 않음';

  @override
  String get tableAlignmentLeft => '정렬: 왼쪽';

  @override
  String get tableAlignmentCenter => '정렬: 중앙';

  @override
  String get tableAlignmentRight => '정렬: 오른쪽';

  @override
  String tableRowNumber(int rowNumber) {
    return '행 $rowNumber';
  }

  @override
  String get insertRowAbove => '위에 행 삽입';

  @override
  String get insertRowBelow => '아래에 행 삽입';

  @override
  String get deleteRow => '행 삭제';

  @override
  String get tableHeaderHint => '헤더';

  @override
  String get tableCellHint => '셀';

  @override
  String get language => '언어';

  @override
  String get hideEditingButtons => '편집 버튼 숨기기';

  @override
  String get showEditingButtons => '편집 버튼 표시';

  @override
  String get altText => '대체 텍스트';

  @override
  String get editorPlaceholderText => '텍스트';

  @override
  String get editorPlaceholderCode => '코드';

  @override
  String get editorPlaceholderAltText => '대체 텍스트';

  @override
  String get describeTheImage => '이미지 설명';

  @override
  String get columns => '열';

  @override
  String get rows => '행';

  @override
  String tableHeaderNumber(int columnNumber) {
    return '헤더 $columnNumber';
  }

  @override
  String get tableCellDefault => '셀';

  @override
  String get noImageSource => '이미지 소스 없음';

  @override
  String get remoteImageBlocked => '원격 이미지가 차단됨';

  @override
  String get remoteImageBlockedTooltip =>
      'BusyMark가 원격 이미지를 로드할 수 있는지 여부를 선택합니다.';

  @override
  String get remoteImagesBlockedTitle => '원격 이미지가 차단되었습니다.';

  @override
  String get remoteImagesBlockedMessage =>
      '이 문서는 인터넷의 이미지를 참조합니다. 이를 로드하면 이미지 호스트에 네트워크 정보가 공개될 수 있습니다.';

  @override
  String get loadRemoteImagesForWorkspace => '이 작업공간에서 로드';

  @override
  String get alwaysLoadRemoteImages => '항상 원격 이미지 로드';

  @override
  String get hideSidebar => '사이드바 패널 숨기기';

  @override
  String get showSidebar => '사이드바 패널 표시';

  @override
  String get showPreview => '미리보기 표시';

  @override
  String get hidePreview => '미리보기 숨기기';

  @override
  String get workspaceKindUnsavedMarkdown => '저장되지 않은 마크다운 파일';

  @override
  String get workspaceKindSingleMarkdown => '단일 마크다운 파일';

  @override
  String get workspaceKindMarkdownFolder => '마크다운 폴더';

  @override
  String get workspaceKindWritersideModule => 'Writerside 모듈';

  @override
  String get problems => '문제';

  @override
  String diagnosticCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '진단 $count개',
      one: '진단 1개',
      zero: '진단 없음',
    );
    return '$_temp0';
  }

  @override
  String get files => '파일';

  @override
  String get toc => '목차';

  @override
  String get tocActions => '목차 작업';

  @override
  String get markdownUnsaved => '마크다운 - 저장되지 않음';

  @override
  String workspaceDetail(String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
      one: '파일 1개',
    );
    return '$kind - $_temp0';
  }

  @override
  String get noFiles => '파일 없음';

  @override
  String get newFile => '새 파일';

  @override
  String get noWritersideToc => 'Writerside 목차 없음';

  @override
  String get tocSection => '목차 섹션';

  @override
  String get newTopic => '새 토픽';

  @override
  String get newChildTopic => '새 하위 토픽';

  @override
  String get newSiblingTopic => '새 형제 토픽';

  @override
  String get renameTopicFile => '토픽 파일 이름 바꾸기';

  @override
  String get topicPlacement => '목차 배치';

  @override
  String get tocRoot => '목차 루트';

  @override
  String get afterSelectedTopic => '선택한 토픽 뒤';

  @override
  String get insideSelectedTopic => '선택한 토픽 내부';

  @override
  String get pasteAfterTopic => '토픽 뒤에 붙여넣기';

  @override
  String get pasteAsChildTopic => '하위 토픽으로 붙여넣기';

  @override
  String get removeFromToc => '목차에서 제거';

  @override
  String get confirmRemoveFromTocTitle => '목차에서 삭제하시겠습니까?';

  @override
  String confirmRemoveFromTocMessage(String name) {
    return '이 목차에서 $name을(를) 제거하시겠습니까? 토픽 파일은 유지됩니다.';
  }

  @override
  String get confirmDeleteTopicTitle => '토픽 파일을 삭제하시겠습니까?';

  @override
  String confirmDeleteTopicMessage(String name) {
    return '$name을(를) 삭제하고 모든 목차에서 제거하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get safeDeleteTopicFile => '토픽 파일 안전 삭제…';

  @override
  String get removeTocElement => 'TOC 요소 제거';

  @override
  String get reviewUsages => '사용 검토';

  @override
  String get deleteTopicFile => '토픽 파일 삭제';

  @override
  String get removeAction => '제거';

  @override
  String topicRemovalSummary(String topic) {
    return '선택한 인스턴스에서 “$topic”을(를) 제거합니다. 토픽 파일은 유지됩니다.';
  }

  @override
  String safeDeleteTopicSummary(String topic) {
    return '“$topic”을 삭제하고 이 Writerside 프로젝트 전체에서 해당 참조를 안전하게 업데이트하세요.';
  }

  @override
  String childTopicsPromoted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '하위 토픽 $count개가 한 단계 위로 이동합니다.',
      one: '하위 토픽 1개가 한 단계 위로 이동합니다.',
    );
    return '$_temp0';
  }

  @override
  String get topicIsStartPageRemovalWarning =>
      '이 토픽은 인스턴스 시작 페이지로 사용됩니다. 계속하기 전에 사용처를 검토하고 다른 시작 페이지를 지정하세요.';

  @override
  String topicUsagesCount(int count) {
    return '사용처 ($count)';
  }

  @override
  String get noBreakingTopicUsages => '깨질 수 있는 참조가 발견되지 않았습니다.';

  @override
  String get topicUsagesFound => 'BusyMark에서 이 토픽에 대한 다음 참조를 찾았습니다.';

  @override
  String get topicUsageTocElements => '목차 요소';

  @override
  String get topicUsageStartPages => '시작 페이지';

  @override
  String get topicUsageTopicLinks => '토픽 링크';

  @override
  String get topicUsageIncludes => 'include 요소';

  @override
  String usageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용처 $count개',
      one: '사용처 1개',
    );
    return '$_temp0';
  }

  @override
  String get refactoringOptions => '리팩토링 옵션';

  @override
  String get updateUsagesAutomatically => '참조 위치를 자동으로 업데이트';

  @override
  String get updateUsagesAutomaticallyDescription =>
      '목차 참조와 include 요소를 제거하고 링크 텍스트를 유지합니다.';

  @override
  String get manualUsageUpdatesRequired => '일부 사용처는 이 리팩터링 전에 수동으로 변경해야 합니다.';

  @override
  String get setRedirectTo => '다음으로 리디렉션 설정';

  @override
  String get noRedirectDescription => '이전에 게시된 페이지를 리디렉션하지 마세요.';

  @override
  String get redirectTarget => '리디렉션 대상';

  @override
  String get remainingUsagesBlockRemoval =>
      '계속하기 전에 남은 사용처를 검토하고 업데이트하거나, 가능한 경우 자동 업데이트를 활성화하세요.';

  @override
  String usagesOfTopic(String topic) {
    return '$topic의 사용처';
  }

  @override
  String get noUsagesFound => '사용처를 찾을 수 없습니다.';

  @override
  String get outsideSelectedInstance => '선택한 인스턴스 외부';

  @override
  String get doRefactor => '리팩토링 수행';

  @override
  String get orphanTopicTitle => '토픽 파일이 더 이상 사용되지 않습니다.';

  @override
  String get keepTopicFile => '토픽 파일 유지';

  @override
  String orphanTopicMessage(String topic) {
    return '\"$topic\"은(는) 이 Writerside 프로젝트의 어느 곳에서도 더 이상 사용되지 않습니다. 파일을 삭제하거나 다른 인스턴스에서 사용할 수 있도록 보관하세요.';
  }

  @override
  String get defaultNewTopicTitle => '새 토픽';

  @override
  String get topicTitle => '토픽 제목';

  @override
  String get fileName => '파일 이름';

  @override
  String get topicTitleRequired => '토픽 제목이 필요합니다.';

  @override
  String get fileNameRequired => '파일 이름은 필수입니다.';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get confirmDeleteFileTitle => '파일을 삭제하시겠습니까?';

  @override
  String get confirmDeleteFolderTitle => '폴더를 삭제하시겠습니까?';

  @override
  String confirmDeleteFileMessage(String name) {
    return '$name을(를) 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String confirmDeleteFolderMessage(String name) {
    return '$name 및 그 안의 모든 파일을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get useSingleSafeFileName => '하나의 안전한 파일 이름을 사용하십시오.';

  @override
  String useExpectedExtension(String extension) {
    return '선택한 형식에 대해 $extension 확장자를 사용하세요.';
  }

  @override
  String get useIdentifierCharacters => '확장자 앞에 문자, 숫자, 밑줄 또는 하이픈을 사용하십시오.';

  @override
  String get topicIdAlreadyExists => '토픽 ID가 이미 존재합니다.';

  @override
  String get createWritersideTopicFailed => 'Writerside 토픽을 생성할 수 없습니다.';

  @override
  String get noOutline => '개요 없음';

  @override
  String expandKind(String kind) {
    return '$kind 펼치기';
  }

  @override
  String collapseKind(String kind) {
    return '$kind 접기';
  }

  @override
  String get foldKindSection => '부분';

  @override
  String get foldKindList => '목록';

  @override
  String get foldKindQuote => '인용문';

  @override
  String get foldKindTag => '태그';

  @override
  String get sourceSearchPreviousMatch => '이전 일치 항목';

  @override
  String get sourceSearchNextMatch => '다음 일치 항목';

  @override
  String get sourceSearchCaseSensitive => '대소문자 구분';

  @override
  String get sourceSearchWholeWord => '전체 단어';

  @override
  String get sourceSearchRegex => '정규식';

  @override
  String get sourceSearchReplacement => '다음으로 바꾸기';

  @override
  String get sourceSearchReplaceCurrent => '현재 일치 항목 바꾸기';

  @override
  String get sourceSearchReplaceAndFindNext => '바꾸고 다음 찾기';

  @override
  String get sourceSearchReplaceAll => '모두 바꾸기';

  @override
  String get workspaceReplace => '작업공간에서 바꾸기';

  @override
  String get reviewReplacements => '바꾸기 결과 검토';

  @override
  String get applyReplacements => '바꾸기 적용';

  @override
  String get skippedFiles => '건너뛴 파일';

  @override
  String get workspaceReplaceDirtyBuffer => '저장되지 않은 편집기 콘텐츠';

  @override
  String get workspaceReplaceDiskContent => '저장된 디스크 내용';

  @override
  String selectFileMatches(int count) {
    return '$count개 일치 항목 모두 선택';
  }

  @override
  String workspaceReplaceApplied(int matches, int files, int skipped) {
    return '$files개 파일에서 $matches개 일치 항목을 바꿨습니다. $skipped개는 건너뛰었습니다.';
  }

  @override
  String documentFormatWithFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 마지막 개행';
  }

  @override
  String documentFormatWithoutFinalNewline(String encoding, String lineEnding) {
    return '$encoding · $lineEnding · 마지막 개행 없음';
  }

  @override
  String get normalizeLineEndings => '줄 끝 표준화';

  @override
  String get mixedLineEndingsSavePrompt =>
      '이 문서에는 혼합된 줄 끝이 포함되어 있습니다. 형식을 선택하세요.';

  @override
  String workspaceReplaceMixedLineEndings(String fileName) {
    return '$fileName에서 줄바꿈 형식이 섞여 있습니다. 바꾸기 전에 사용할 형식을 선택하세요.';
  }

  @override
  String get workspaceReplaceIssueOversized => '크기가 큰 파일을 건너뛰었습니다.';

  @override
  String get workspaceReplaceIssueUnreadable => '읽을 수 없는 파일을 건너뛰었습니다.';

  @override
  String get workspaceReplaceIssueInvalidUtf8 => '유효한 UTF-8이 아닌 파일을 건너뛰었습니다.';

  @override
  String get workspaceReplaceIssueTruncated => '바꾸기 미리 보기가 잘렸습니다.';

  @override
  String get workspaceReplaceIssueFileChanged => '미리보기 이후에 변경된 파일을 건너뛰었습니다.';

  @override
  String get workspaceReplaceIssueBufferChanged =>
      '미리보기 이후에 변경된 편집기 버퍼를 건너뛰었습니다.';

  @override
  String get workspaceReplaceIssueNormalizationRequired =>
      '바꾸기 전에 LF 또는 CRLF 정규화를 선택하세요.';

  @override
  String get workspaceReplaceIssuePartialConflict =>
      '파일이 동시에 변경되어 롤백이 중지되었습니다. 일부 바꾸기 결과가 남아 있을 수 있습니다. 기존 내용은 아래 경로에 보존되었습니다.';

  @override
  String get workspaceReplaceIssueApplyFailed =>
      '검토한 바꾸기 결과를 커밋할 수 없습니다. 파일은 변경되지 않았습니다.';

  @override
  String externalChangesTitle(String fileName) {
    return '외부 변경 사항 — $fileName';
  }

  @override
  String get externalFileDeleted => '이 파일은 디스크에서 삭제되었습니다.';

  @override
  String get externalFileChanged => '저장되지 않은 수정사항이 있는 동안 이 파일이 디스크에서 변경되었습니다.';

  @override
  String recoveredDocumentReview(String fileName) {
    return '$fileName의 저장되지 않은 콘텐츠가 복구되었습니다. 검토한 다음 저장, 다른 이름으로 저장 또는 변경사항을 버리세요.';
  }

  @override
  String get compare => '비교';

  @override
  String get reloadFromDisk => '디스크에서 다시 불러오기';

  @override
  String get keepMine => '내 변경 사항 유지';

  @override
  String get saveAs => '다른 이름으로 저장';

  @override
  String get sourceSearchInvalidRegex => '잘못된 정규식';

  @override
  String get sourceLargeFileFeaturesPaused => '대용량 파일: 강조 표시 및 접기가 일시 중지됩니다.';

  @override
  String get nothingToRead => '읽을 내용 없음';

  @override
  String get admonition => '주의 사항';

  @override
  String get quote => '인용';

  @override
  String get note => '참고';

  @override
  String get tip => '팁';

  @override
  String get warning => '경고';

  @override
  String get tabs => '탭';

  @override
  String get tab => '탭';

  @override
  String get procedure => '절차';

  @override
  String get step => '단계';

  @override
  String get topic => '토픽';

  @override
  String get chapter => '장';

  @override
  String couldNotOpenTarget(String target) {
    return '$target을(를) 열 수 없습니다.';
  }

  @override
  String linkTargetNotFound(String targetPath) {
    return '링크 대상을 찾을 수 없습니다: $targetPath';
  }

  @override
  String get cannotOpenFileTypeInEditor => '이 파일 형식을 편집기에서 열 수 없습니다';

  @override
  String anchorNotFound(String anchor) {
    return '앵커를 찾을 수 없음: $anchor';
  }

  @override
  String get noProblemsFound => '문제가 발견되지 않음';

  @override
  String get noResults => '결과 없음';

  @override
  String searchResultLine(String relativePath, int lineNumber) {
    return '$relativePath - $lineNumber번째 줄';
  }

  @override
  String get untitledResult => '제목 없는 결과';

  @override
  String get documentKindMarkdownFile => '마크다운 파일';

  @override
  String get documentKindWritersideMarkdownTopic => 'Writerside Markdown 토픽';

  @override
  String get documentKindWritersideXmlTopic => 'Writerside XML 토픽';

  @override
  String get documentKindWritersideTree => 'Writerside 트리';

  @override
  String get documentKindConfigurationFile => '구성 파일';

  @override
  String get documentKindVariablesFile => '변수 파일';

  @override
  String get documentKindCategoriesFile => '카테고리 파일';

  @override
  String get documentKindResourceFile => '리소스 파일';

  @override
  String workspaceErrorOpenFailed(String error) {
    return '열기 실패: $error';
  }

  @override
  String workspaceErrorCreateWritersideProjectFailed(String error) {
    return 'Writerside 프로젝트를 생성할 수 없습니다: $error';
  }

  @override
  String workspaceErrorCreateWritersideTopicFailed(String error) {
    return 'Writerside 토픽을 생성할 수 없습니다: $error';
  }

  @override
  String workspaceErrorCouldNotOpenFile(String error) {
    return '파일을 열 수 없습니다: $error';
  }

  @override
  String get workspaceErrorChooseWhereToSaveMarkdown =>
      '이 마크다운 파일을 저장할 위치를 선택하세요.';

  @override
  String get workspaceErrorSaveBlockedFileChangedOnDisk =>
      '저장이 차단되었습니다. 디스크에서 파일이 변경되었습니다.';

  @override
  String workspaceErrorSaveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String workspaceErrorFileOperationFailed(String error) {
    return '파일 작업 실패: $error';
  }

  @override
  String workspaceErrorValidationFailed(String error) {
    return '검증 실패: $error';
  }

  @override
  String workspaceRecoveryRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장되지 않은 문서 $count개를 복구했습니다. 각 문서를 저장하거나 삭제하기 전에 검토하세요.',
      one: '저장되지 않은 문서 1개를 복구했습니다. 저장하거나 삭제하기 전에 검토하세요.',
    );
    return '$_temp0';
  }

  @override
  String workspaceRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '손상된 복구 기록 $count개를 복원하지 못했습니다. 유효한 복구 기록은 계속 사용할 수 있습니다.',
      one: '손상된 복구 기록 1개를 복원하지 못했습니다. 검사를 위해 원본 복구 파일을 보존했습니다.',
    );
    return '$_temp0';
  }

  @override
  String errorPathDoesNotExist(String path) {
    return '경로가 존재하지 않습니다: $path';
  }

  @override
  String errorTargetDirectoryNotEmpty(String path) {
    return '대상 디렉터리가 이미 존재하며 비어 있지 않습니다: $path';
  }

  @override
  String errorTargetPathNotDirectory(String path) {
    return '대상 경로가 이미 존재하며 디렉터리가 아닙니다: $path';
  }

  @override
  String errorGeneratedFileAlreadyExists(String path) {
    return '생성된 파일이 이미 존재합니다: $path';
  }

  @override
  String get errorParentDirectoryRequired => '상위 디렉터리가 필요합니다.';

  @override
  String errorParentDirectoryMissing(String path) {
    return '상위 디렉터리가 존재하지 않습니다: $path';
  }

  @override
  String errorDirectoryMissing(String path) {
    return '디렉터리가 존재하지 않습니다: $path';
  }

  @override
  String errorPathAlreadyExists(String path) {
    return '경로가 이미 존재합니다: $path';
  }

  @override
  String get errorFileNameRequired => '파일 이름은 필수입니다.';

  @override
  String get errorFileNameUnsafe => '파일 이름은 단일 안전 경로 세그먼트여야 합니다.';

  @override
  String get errorFileOperationInvalidTarget => '폴더를 폴더 자체로 이동할 수 없습니다.';

  @override
  String get errorFileOperationOutsideRoot => '파일 작업은 작업공간 내부에서 수행해야 합니다.';

  @override
  String get errorFileOperationRoot => '작업공간 루트는 파일 트리에서 변경할 수 없습니다.';

  @override
  String get errorProjectNameRequired => '프로젝트 이름이 필요합니다.';

  @override
  String get errorDirectoryNameRequired => '디렉터리 이름이 필요합니다.';

  @override
  String get errorDirectoryNameUnsafe => '디렉터리 이름은 단일 안전 경로 세그먼트여야 합니다.';

  @override
  String get errorInstanceIdInvalid =>
      '인스턴스 ID는 소문자로 시작해야 하며 소문자, 숫자, 밑줄, 하이픈만 포함할 수 있습니다.';

  @override
  String get errorTopicFileInvalid =>
      '토픽 파일 이름은 경로 구분 기호가 없는 Markdown 파일 이름이어야 합니다.';

  @override
  String get errorTopicTitleRequired => '토픽 제목이 필요합니다.';

  @override
  String errorWritersideModuleRootMissing(String path) {
    return 'Writerside 모듈 루트가 존재하지 않습니다: $path';
  }

  @override
  String get errorWritersideModuleNotOpen =>
      '토픽을 생성하려면 Writerside 모듈이 열려 있어야 합니다.';

  @override
  String get errorWritersideInstanceTreeMissing =>
      'Writerside 모듈에는 인스턴스 트리가 없습니다.';

  @override
  String errorWritersideTreeFileMissing(String path) {
    return 'Writerside 트리 파일이 존재하지 않습니다: $path';
  }

  @override
  String errorTopicIdAlreadyExists(String topicId) {
    return '이 도움말 모듈에는 토픽 ID \"$topicId\"가 이미 있습니다.';
  }

  @override
  String errorTopicFileAlreadyExists(String path) {
    return '토픽 파일이 이미 존재합니다: $path';
  }

  @override
  String errorReferenceTopicMissing(String topic) {
    return '선택한 트리에 참조 토픽이 없습니다: $topic';
  }

  @override
  String get errorWritersideTocNodeMissing => '선택한 목차 항목이 더 이상 존재하지 않습니다.';

  @override
  String get errorWritersideTocInvalidMove =>
      'TOC 항목은 자체 항목이나 해당 하위 항목 중 하나로 이동할 수 없습니다.';

  @override
  String errorWritersideStartTopicDelete(String topic) {
    return '시작 토픽 $topic을(를) 삭제할 수 없습니다. 먼저 다른 시작 페이지를 선택하세요.';
  }

  @override
  String get errorWritersideSafeDeleteRequired =>
      'Writerside 토픽 파일에는 안전 삭제를 사용하세요.';

  @override
  String get errorWritersideTopicUsageScanFailed =>
      '토픽 사용처 검색을 완료할 수 없습니다. 변경된 파일이 없습니다.';

  @override
  String get errorWritersideTopicUsagesRemain =>
      '일부 토픽 사용처는 여전히 검토가 필요합니다. 계속하기 전에 확인하세요.';

  @override
  String get errorWritersideRedirectInvalid =>
      '선택한 리디렉션 대상이 더 이상 유효하지 않습니다. 다시 선택하세요.';

  @override
  String errorWritersideRollbackFailed(String paths) {
    return '토픽 삭제를 완전히 롤백할 수 없습니다. 계속하기 전에 다음 경로를 검토하세요. $paths';
  }

  @override
  String get errorTopicsRootUnsafe => '토픽 루트는 안전한 상대 디렉터리여야 합니다.';

  @override
  String get errorTopicFileNameUnsafe => '토픽 파일 이름은 안전한 단일 경로 세그먼트여야 합니다.';

  @override
  String errorTopicFileExtensionMismatch(String extension) {
    return '토픽 파일 확장자는 선택한 형식($extension)과 일치해야 합니다.';
  }

  @override
  String get errorTopicFileNameInvalid =>
      '토픽 파일 이름에는 문자, 숫자, 밑줄, 하이픈만 포함해야 합니다.';

  @override
  String errorUnknown(String code) {
    return '알 수 없는 오류: $code';
  }

  @override
  String diagnosticWorkspaceFileStatFailed(String error) {
    return '파일 메타데이터를 읽을 수 없습니다: $error';
  }

  @override
  String get diagnosticWorkspaceScanSkipped =>
      '큰 작업공간이 감지되었습니다. 앱의 응답성을 유지하기 위해 일부 파일을 건너뛰었습니다.';

  @override
  String diagnosticWorkspaceScanInspectFailed(String error) {
    return '작업공간 항목을 검사할 수 없습니다: $error';
  }

  @override
  String get diagnosticWorkspaceFileTooLarge => '이 파일은 베타 자동 파싱 한도보다 큽니다.';

  @override
  String diagnosticWorkspaceFileReadFailed(String error) {
    return 'Markdown 파일을 읽을 수 없습니다: $error';
  }

  @override
  String get diagnosticMarkdownAttributeMalformed =>
      '잘못된 Writerside 제목 속성 블록입니다.';

  @override
  String diagnosticMarkdownHeadingDuplicateId(String id) {
    return '제목 ID \"$id\"이(가) 중복되었습니다.';
  }

  @override
  String get diagnosticWritersideTopicH1ConvertedToChapter =>
      '추가 최상위 H1 제목은 장으로 처리됩니다.';

  @override
  String get diagnosticWritersideMarkdownTopicMissingTitle =>
      'Writerside Markdown 주제에 H1 또는 front matter 제목이 없습니다.';

  @override
  String get diagnosticWritersideXmlTopicMissingTitle => 'XML 토픽에 제목이 없습니다.';

  @override
  String diagnosticWritersideTopicFileMissingTitle(String fileName) {
    return '\"$fileName\" 토픽에 제목이 없습니다.';
  }

  @override
  String get diagnosticMarkdownFrontMatterMalformed =>
      'front matter가 닫히지 않았습니다.';

  @override
  String get diagnosticMarkdownRawHtmlUnsafe => '안전하지 않은 HTML 요소.';

  @override
  String diagnosticMarkdownLinkUnresolvedTarget(String targetPath) {
    return '링크 대상이 존재하지 않습니다: $targetPath';
  }

  @override
  String diagnosticMarkdownLinkUnresolvedAnchor(String anchor) {
    return '앵커 \"$anchor\"이(가) 존재하지 않습니다.';
  }

  @override
  String diagnosticMarkdownImageMissingAlt(String destination) {
    return '이미지 \"$destination\"에 대체 텍스트가 없습니다.';
  }

  @override
  String diagnosticMarkdownImageMissingFile(String destination) {
    return '이미지가 존재하지 않습니다: $destination';
  }

  @override
  String diagnosticInvalidXml(String message) {
    return '잘못된 XML: $message';
  }

  @override
  String get diagnosticWritersideConfigInvalidRoot =>
      'writerside.cfg 루트는 <ihp>여야 합니다.';

  @override
  String get diagnosticWritersideConfigMissingSnippetsSrc =>
      '스니펫 선언에 src가 없습니다.';

  @override
  String get diagnosticWritersideConfigMissingInstanceGroupsSrc =>
      '인스턴스 그룹 선언에 src가 없습니다.';

  @override
  String diagnosticWritersideConfigInvalidKeymapsMode(String mode) {
    return '지원되지 않는 키맵 모드: $mode';
  }

  @override
  String get diagnosticWritersideConfigMissingInstanceSrc =>
      '인스턴스 선언에 src가 없습니다.';

  @override
  String get diagnosticWritersideConfigMissingInstance =>
      'writerside.cfg는 인스턴스를 등록하지 않습니다.';

  @override
  String get diagnosticWritersideTreeInvalidRoot =>
      '.tree 루트는 <instance-profile>이어야 합니다.';

  @override
  String get diagnosticWritersideTreeMissingId => '인스턴스 프로필에 ID가 없습니다.';

  @override
  String diagnosticWritersideTreeIdMismatch(String id) {
    return '트리 파일의 기본 이름이 인스턴스 ID \"$id\"와 일치하지 않습니다.';
  }

  @override
  String get diagnosticWritersideTreeMissingStartPage =>
      '라이브러리가 아닌 인스턴스에 start-page가 누락되었습니다.';

  @override
  String diagnosticWritersideStartPageMissing(String startPage) {
    return '시작 페이지 \"$startPage\"이(가) 존재하지 않습니다.';
  }

  @override
  String diagnosticWritersideTreeDuplicateTopic(String topic) {
    return '이 인스턴스 목차에 \"$topic\" 토픽이 두 번 이상 나타납니다.';
  }

  @override
  String get diagnosticWritersideVariableMalformedDeclaration =>
      '변수 선언에는 이름과 값이 있어야 합니다.';

  @override
  String diagnosticWritersideVariableDuplicateName(String name) {
    return '\"$name\" 변수가 두 번 이상 선언되었습니다.';
  }

  @override
  String get diagnosticWritersideCategoryMissingId => '카테고리에 ID가 없습니다.';

  @override
  String diagnosticWritersideCategoryDuplicateId(String id) {
    return '카테고리 \"$id\"이(가) 두 번 이상 선언되었습니다.';
  }

  @override
  String diagnosticWritersideCategoryDuplicateOrder(String order) {
    return '카테고리 순서 \"$order\"이(가) 두 번 이상 선언되었습니다.';
  }

  @override
  String get diagnosticWritersideTopicInvalidRoot =>
      '.topic 루트는 <topic>이어야 합니다.';

  @override
  String get diagnosticWritersideTopicMissingRootId => 'XML 토픽에 루트 ID가 없습니다.';

  @override
  String diagnosticWritersideTopicRootIdMismatch(String id, String expectedId) {
    return 'XML 토픽 루트 ID \"$id\"는 파일 이름 \"$expectedId\"와 일치해야 합니다.';
  }

  @override
  String diagnosticWritersideTopicDuplicateElementId(String elementId) {
    return '요소 ID \"$elementId\"이(가) 두 번 이상 나타납니다.';
  }

  @override
  String get diagnosticWritersideTopicAnchorMissingHref => '<a>에 href가 없습니다.';

  @override
  String get diagnosticWritersideConfigMissing =>
      'Writerside 모드에는writerside.cfg가 필요합니다.';

  @override
  String diagnosticWritersideConfigMissingBuildConfigDirectory(
    String relativePath,
  ) {
    return '구성된 빌드 구성 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingApiSpecificationsDirectory(
    String relativePath,
  ) {
    return '구성된 API 사양 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingSnippetsDirectory(
    String relativePath,
  ) {
    return '구성된 스니펫 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingVarsFile(String relativePath) {
    return '구성된 변수 파일이 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingCategoriesFile(String relativePath) {
    return '구성된 카테고리 파일이 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceGroupsFile(
    String relativePath,
  ) {
    return '구성된 인스턴스 그룹 파일이 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideConfigMissingInstanceTree(String source) {
    return '등록된 인스턴스 트리 \"$source\"이(가) 존재하지 않습니다.';
  }

  @override
  String diagnosticWritersideTopicReadFailed(String error) {
    return '토픽 파일을 읽을 수 없습니다: $error';
  }

  @override
  String diagnosticWritersideDefaultTopicsDirectoryMissing(
    String relativePath,
  ) {
    return '기본 토픽 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideTopicsDirectoryMissing(String relativePath) {
    return '구성된 토픽 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideImagesDirectoryMissing(String relativePath) {
    return '구성된 이미지 디렉터리가 누락되었습니다: $relativePath';
  }

  @override
  String diagnosticWritersideTopicDuplicateId(String id) {
    return '요소 ID \"$id\"이(가) 두 번 이상 나타납니다.';
  }

  @override
  String diagnosticWritersideTreeMissingTopic(String topic) {
    return 'TOC에서 존재하지 않는 주제를 참조합니다: \"$topic\".';
  }

  @override
  String diagnosticWritersideTreeInvalidHref(String href) {
    return '외부 href \"$href\"이(가) 잘못되었습니다.';
  }

  @override
  String diagnosticWritersideVariableUnresolved(String name) {
    return '변수 \"%$name%\"이(가) 선언되지 않았습니다.';
  }

  @override
  String diagnosticWritersideTopicLinkUnresolved(String destination) {
    return '토픽 링크 \"$destination\"을 확인할 수 없습니다.';
  }

  @override
  String diagnosticWritersideAnchorUnresolved(
    String anchor,
    String targetName,
  ) {
    return '대상 \"$targetName\"에 앵커 \"$anchor\"가 존재하지 않습니다.';
  }

  @override
  String get diagnosticWritersideIncludeMissingFrom =>
      '<include>에 from 속성이 없습니다.';

  @override
  String diagnosticWritersideIncludeSourceMissing(String from) {
    return '포함 소스 \"$from\"이(가) 존재하지 않습니다.';
  }

  @override
  String diagnosticWritersideIncludeElementMissing(
    String elementId,
    String from,
  ) {
    return '포함 요소 \"$elementId\"이(가) \"$from\"에 존재하지 않습니다.';
  }

  @override
  String diagnosticWritersideCategoryUnresolved(String ref) {
    return 'seealso 카테고리 \"$ref\"가 선언되지 않았습니다.';
  }

  @override
  String diagnosticWritersideTopicAmbiguousReference(String reference) {
    return '토픽 참조 \"$reference\"이(가) 모호합니다.';
  }

  @override
  String diagnosticUnknown(String code) {
    return '알 수 없는 진단: $code';
  }

  @override
  String get close => '닫기';

  @override
  String get git => 'Git';

  @override
  String get gitDiff => 'Git diff';

  @override
  String get gitShowDiff => 'diff 표시';

  @override
  String gitDiffHunkRange(String oldRange, String newRange) {
    return '이전 $oldRange → 새 $newRange';
  }

  @override
  String get gitDiffNoLines => '줄 없음';

  @override
  String get gitUnavailableTitle => 'Git을 사용할 수 없음';

  @override
  String gitUnavailableMessage(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'other': 'Git을 설치하거나 BusyMark가 사용할 수 있는 Git 실행 파일을 구성하세요. $reason',
    });
    return '$_temp0';
  }

  @override
  String get gitTrustRequiredTitle => 'Git에 대한 이 작업공간을 신뢰하시나요?';

  @override
  String get gitTrustRequiredMessage =>
      'Git 저장소는 후크, 필터 및 기타 구성을 통해 프로그램을 실행할 수 있습니다. BusyMark가 저장소 데이터를 읽거나 Git 작업을 활성화하기 전에 이 작업공간을 신뢰하세요.';

  @override
  String get gitTrustWorkspace => '작업공간 신뢰';

  @override
  String get gitNotRepositoryTitle => 'Git 저장소가 아님';

  @override
  String get gitNotRepositoryMessage => '이 작업공간은 Git 저장소 내부에 없습니다.';

  @override
  String get gitInitializeRepository => '저장소 초기화';

  @override
  String get gitDetachedHead => '분리된 HEAD';

  @override
  String gitDetachedHeadAt(String commit) {
    return '$commit에 분리됨';
  }

  @override
  String get gitNoUpstream => '업스트림 없음';

  @override
  String gitAheadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '푸시하지 않은 커밋 $count개',
      one: '푸시하지 않은 커밋 1개',
    );
    return '$_temp0';
  }

  @override
  String gitBehindCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '가져올 커밋 $count개',
      one: '가져올 커밋 1개',
    );
    return '$_temp0';
  }

  @override
  String get gitClean => '변경 사항 없음';

  @override
  String get gitConflicts => '충돌';

  @override
  String get gitChanges => '변경 사항';

  @override
  String get gitStaged => '스테이징됨';

  @override
  String get gitUnstaged => '스테이징되지 않음';

  @override
  String get gitHistory => '기록';

  @override
  String get gitBranches => '브랜치';

  @override
  String get gitActions => 'Git 작업';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitPush => 'Push';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitSelectForCommit => '파일 스테이징';

  @override
  String get gitRemoveFromCommit => '파일 스테이징 해제';

  @override
  String get gitDiscard => '롤백';

  @override
  String get gitOpenFile => '파일 열기';

  @override
  String get gitMarkResolved => '해결됨으로 표시';

  @override
  String get gitUntracked => '추적되지 않음';

  @override
  String get gitCommitMessage => '커밋 메시지';

  @override
  String get gitCommitSelectedFiles => '선택한 파일';

  @override
  String get gitCommitNoSelectedFiles => '커밋하기 전에 하나 이상의 파일을 준비하세요.';

  @override
  String gitStagedFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스테이징된 파일 $count개',
      one: '스테이징된 파일 1개',
    );
    return '$_temp0';
  }

  @override
  String get gitOutsideWorkspace => '작업공간 외부';

  @override
  String get gitCommitMessageRequired => '커밋 메시지를 입력하세요.';

  @override
  String get gitCreateBranch => '브랜치 만들기';

  @override
  String get gitNewBranch => '새 브랜치';

  @override
  String get gitBranchName => '브랜치 이름';

  @override
  String get gitSwitchBranch => '전환';

  @override
  String get gitNoChanges => '변경 사항 없음';

  @override
  String get gitNoHistory => '기록 없음';

  @override
  String get gitNoBranches => '브랜치 없음';

  @override
  String get gitNoDiff => '표시할 diff 없음';

  @override
  String get gitBinaryFile => '바이너리 파일. BusyMark는 바이너리 패치를 렌더링하지 않습니다.';

  @override
  String gitBinaryFileInfo(int size) {
    return '바이너리 파일($size바이트). BusyMark는 바이너리 패치를 렌더링하지 않습니다.';
  }

  @override
  String get gitUnsavedChangesBanner => '저장되지 않은 편집기 변경 사항은 저장될 때까지 포함되지 않습니다.';

  @override
  String get gitConfirmDiscardTitle => 'Git 변경사항을 버리시겠습니까?';

  @override
  String gitConfirmDiscardTracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '선택한 추적 파일의 스테이징 및 비스테이징 변경 사항이 모두 HEAD로 복원됩니다.',
      one: '선택한 추적 파일의 스테이징 및 비스테이징 변경 사항이 모두 HEAD로 복원됩니다.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardUntracked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '선택한 추적되지 않은 파일이 삭제됩니다.',
      one: '선택한 추적되지 않은 파일이 삭제됩니다.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmDiscardMixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '선택한 파일이 Git 상태에 따라 복원되거나 삭제됩니다.',
      one: '선택한 파일이 Git 상태에 따라 복원되거나 삭제됩니다.',
    );
    return '$_temp0';
  }

  @override
  String gitConfirmSwitchBranchTitle(String branch) {
    return '$branch로 전환하시겠습니까?';
  }

  @override
  String get gitConfirmSwitchBranchMessage =>
      'Git에서 브랜치를 전환한 후 BusyMark가 디스크에서 작업공간을 다시 불러옵니다.';

  @override
  String get gitConfirmPushSetUpstreamTitle => '업스트림 분기를 설정하시겠습니까?';

  @override
  String gitConfirmPushSetUpstreamMessage(String branch) {
    return '이 브랜치에는 업스트림이 없습니다. 원격 저장소가 정확히 하나 구성된 경우 BusyMark에서 $branch를 푸시하고 업스트림을 설정할 수 있습니다.';
  }

  @override
  String get gitProjectHistory => '프로젝트 이력';

  @override
  String get gitFileHistory => '파일 기록';

  @override
  String get gitFileHistoryRequiresOpenFile =>
      '파일 기록을 사용하려면 열려 있는 Markdown 파일이 필요합니다.';

  @override
  String get gitLoadMore => '더 로드하기';

  @override
  String get gitChangesInCommit => '이 커밋의 변경 사항';

  @override
  String get gitCompareWithCurrent => '현재 버전과 비교';

  @override
  String get gitRestoreVersion => '이 버전을 복원하세요';

  @override
  String get gitConfirmRestoreTitle => '이 파일 버전을 복원하시겠습니까?';

  @override
  String get gitConfirmRestoreMessage =>
      'BusyMark는 현재 작업 트리 파일을 선택한 커밋된 버전으로 대체합니다. 복원된 파일은 스테이지되지 않은 상태로 유지됩니다.';

  @override
  String get gitCommitActions => '커밋 작업';

  @override
  String get gitResetCurrentBranchToHere => '현재 분기를 여기로 재설정합니다…';

  @override
  String gitResetCurrentBranchTitle(String branch, String commit) {
    return '$branch을(를) $commit(으)로 재설정하시겠습니까?';
  }

  @override
  String gitResetCurrentBranchMessage(String branch, String commit) {
    return '그러면 $branch 분기가 $commit 커밋으로 이동됩니다. Git이 인덱스와 작업 트리를 업데이트하는 방법을 선택하세요.';
  }

  @override
  String get gitReset => '재설정';

  @override
  String get gitResetModeSoft => '소프트';

  @override
  String get gitResetModeSoftDescription =>
      '브랜치만 이동합니다. 인덱스와 작업 트리는 변경하지 않습니다. 선택한 커밋과의 차이점은 스테이징된 상태로 유지됩니다.';

  @override
  String get gitResetModeMixed => '혼합';

  @override
  String get gitResetModeMixedDescription =>
      '브랜치를 이동하고 인덱스를 재설정합니다. 작업 트리는 변경하지 않으며 차이점은 스테이징되지 않은 상태로 남습니다.';

  @override
  String get gitResetModeHard => '하드';

  @override
  String get gitResetModeHardDescription =>
      '브랜치를 이동하고 인덱스와 작업 트리를 재설정합니다. 추적된 변경 사항은 삭제되며, 방해가 되는 추적되지 않은 파일은 삭제될 수 있습니다.';

  @override
  String get gitResetModeKeep => '유지';

  @override
  String get gitResetModeKeepDescription =>
      '로컬 변경 사항을 유지하면서 분기를 이동하고 추적된 파일을 재설정합니다. 해당 변경 사항이 재설정과 충돌하면 Git이 중단됩니다.';

  @override
  String gitAdditionsDeletions(int additions, int deletions) {
    return '+$additions -$deletions';
  }

  @override
  String get fileActions => '파일 작업';

  @override
  String get actions => '작업';

  @override
  String get gitStatusAdded => '추가됨';

  @override
  String get gitStatusDeleted => '삭제됨';

  @override
  String get gitStatusRenamed => '이름 변경됨';

  @override
  String get gitStatusCopied => '복사됨';

  @override
  String get gitStatusUntracked => '추적되지 않음';

  @override
  String get gitStatusConflicted => '충돌함';

  @override
  String get gitStatusIgnored => '무시됨';

  @override
  String get gitStatusTypeChanged => '유형 변경됨';

  @override
  String get gitStatusModified => '수정됨';

  @override
  String get gitStatusUnknown => '알 수 없음';

  @override
  String get gitErrorUnavailable => 'Git을 사용할 수 없습니다.';

  @override
  String get gitErrorNotRepository => '이 작업공간은 Git 저장소가 아닙니다.';

  @override
  String get gitErrorUnsafePath => 'BusyMark가 안전하지 않은 Git 경로를 차단했습니다.';

  @override
  String get gitErrorInvalidBranchName => '유효한 브랜치 이름을 입력하세요.';

  @override
  String get gitErrorNoRemote => 'Git 원격이 구성되지 않았습니다.';

  @override
  String get gitErrorNoUpstream => '업스트림 분기가 구성되지 않았습니다.';

  @override
  String get gitErrorMultipleRemotes =>
      '여러 원격 저장소가 구성되어 있습니다. 이 BusyMark 버전 외부에서 업스트림을 선택하세요.';

  @override
  String get gitErrorDirtyWorkspace =>
      'Git 분기를 전환하기 전에 BusyMark 편집기 변경 사항을 저장하거나 버리세요.';

  @override
  String get gitErrorResetDirtyWorkspace =>
      '현재 브랜치를 재설정하기 전에 BusyMark 편집기 변경 사항을 저장하거나 버리세요.';

  @override
  String get gitErrorRestoreStagedFile => '기록 버전을 복원하기 전에 이 파일을 스테이지 해제하세요.';

  @override
  String get gitErrorResetDetachedHead => '재설정하기 전에 브랜치를 체크아웃하세요.';

  @override
  String get gitErrorDiverged =>
      '브랜치가 분기되었습니다. 이 BusyMark 버전 외부에서 병합 또는 리베이스를 해결하세요.';

  @override
  String get gitErrorAuthorIdentity => '커밋하기 전에 Git에 작성자 이름과 이메일 주소가 필요합니다.';

  @override
  String get gitAuthorIdentityTitle => 'Git 작성자 ID';

  @override
  String get gitAuthorIdentityMessage =>
      'Git이 커밋 시 기록해야 하는 ID를 입력하세요. BusyMark는 이를 저장하고 이 커밋을 다시 시도합니다.';

  @override
  String get gitAuthorName => '이름';

  @override
  String get gitAuthorEmail => '이메일';

  @override
  String get gitAuthorIdentityGlobal => '모든 저장소에 사용';

  @override
  String get gitAuthorIdentityGlobalDescription =>
      'Snap으로 설치하면 BusyMark에서 열린 저장소에 적용됩니다.';

  @override
  String get gitSaveIdentityAndCommit => 'ID 저장 및 커밋';

  @override
  String get gitErrorAuthentication => 'Git 인증에 실패했습니다.';

  @override
  String get gitErrorNetwork => 'Git 네트워크 작업이 실패했습니다.';

  @override
  String get gitErrorConflict => 'Git이 해결되지 않은 충돌을 보고했습니다.';

  @override
  String get gitErrorCommandFailed => 'Git 명령이 실패했습니다.';

  @override
  String get syntaxReference => '구문 참조';

  @override
  String get syntaxReferenceMarkdownBlocks => 'Markdown 블록';

  @override
  String get syntaxReferenceMarkdownBlocksDescription =>
      'Markdown 소스 및 미리보기에서 블록 구조가 지원됩니다.';

  @override
  String get syntaxReferenceInlineFormatting => '인라인 Markdown';

  @override
  String get syntaxReferenceInlineFormattingDescription =>
      '단락, 목록 항목 및 표 셀 내부에 나타날 수 있는 서식입니다.';

  @override
  String get syntaxReferenceRawHtmlBlocks => '원시 HTML 블록';

  @override
  String get syntaxReferenceRawHtmlBlocksDescription =>
      'BusyMark 미리보기 위젯을 통해 렌더링되는 안전한 블록 수준 HTML 태그입니다.';

  @override
  String get syntaxReferenceRawHtmlInline => '원시 HTML 인라인 태그';

  @override
  String get syntaxReferenceRawHtmlInlineDescription =>
      '리터럴 태그를 표시하지 않고 렌더링되는 안전한 인라인 HTML 태그입니다.';

  @override
  String get syntaxReferenceHeadings => '제목';

  @override
  String get syntaxReferenceParagraphs => '단락';

  @override
  String get syntaxReferenceLists => '목록';

  @override
  String get syntaxReferenceHtmlContainers => '컨테이너';

  @override
  String get syntaxReferenceHtmlTextBlocks => '텍스트 블록';

  @override
  String get syntaxReferenceHtmlFigures => '그림 및 이미지';

  @override
  String get syntaxReferenceHtmlPreformatted => '미리 서식이 지정된 코드';

  @override
  String get syntaxReferenceHtmlDisclosure => '접기 블록';

  @override
  String get syntaxReferenceHtmlDescriptionLists => '설명 목록';

  @override
  String get syntaxReferenceHtmlFormattingTags => '서식 태그';

  @override
  String get syntaxReferenceHtmlInlineCodeTags => '인라인 코드 태그';

  @override
  String get syntaxReferenceHtmlNeutralInlineTags => '의미 있는 텍스트 태그';

  @override
  String get syntaxReferenceSanitizedPreviewDescription =>
      '허용된 HTML은 브라우저에서 렌더링되지 않고 BusyMark 미리보기 블록으로 변환됩니다.';

  @override
  String get syntaxReferenceSourcePreservedDescription =>
      '편집되지 않은 원시 HTML은 소스 텍스트와 동일하게 다시 저장됩니다.';

  @override
  String get syntaxReferenceMarkdownInsideHtmlDescription =>
      '원시 HTML 내부의 마크다운 마커는 리터럴 텍스트로 렌더링됩니다.';

  @override
  String get syntaxReferenceBlockedContentDescription =>
      '스크립트, 스타일, 프레임, 양식, SVG, MathML, 이벤트 및 안전하지 않은 속성이 차단됩니다.';

  @override
  String get syntaxReferenceSafeUrlsDescription =>
      '링크에는 http, https, mailto, tel, 상대 URL 및 프래그먼트 URL만 허용됩니다. 안전하지 않은 스킴은 차단됩니다.';

  @override
  String get syntaxReferenceCategory => '범주';

  @override
  String get syntaxReferenceCategoryHtml => 'HTML';

  @override
  String get syntaxReferenceCategoryDiagramsAndApi => '다이어그램 및 API';

  @override
  String get syntaxReferenceCategoryMathematics => '수학';

  @override
  String get syntaxReferenceExample => '예제';

  @override
  String get syntaxReferenceIdentifiers => '식별자 및 별칭';

  @override
  String get syntaxReferenceScope => '적용 범위';

  @override
  String get syntaxReferenceLimitation => 'BusyMark 제한 사항';

  @override
  String get syntaxReferenceOfficialDocumentation => '공식 문서';

  @override
  String get syntaxReferenceScopeWritersideMarkdown => 'Writerside Markdown 전용';

  @override
  String get syntaxReferenceScopeWritersideMarkdownAndXml =>
      'Writerside Markdown 및 Writerside XML 전용';

  @override
  String get syntaxReferenceMarkdownDescription =>
      'BusyMark에서 작성하고 미리 볼 수 있는 핵심 Markdown 형식입니다.';

  @override
  String get syntaxReferenceParagraphExample => '텍스트 문단입니다.';

  @override
  String get syntaxReferenceTableLimitation =>
      '표는 GitHub Flavored Markdown의 파이프 구문을 사용합니다.';

  @override
  String get syntaxReferenceHardBreakIdentifiers => '줄 끝 공백 두 개, \\, <br>';

  @override
  String get syntaxReferenceHtmlDescription =>
      'BusyMark는 Markdown 소스에서 제한된 안전한 원시 HTML 하위 집합만 허용합니다.';

  @override
  String get syntaxReferenceDiagramsDescription =>
      'Mermaid, PlantUML, D2 및 OpenAPI 펜스 블록은 Markdown 소스에서 작동합니다. 펜스 식별자는 대소문자를 구분하지 않으며 BusyMark는 원래 표기를 유지합니다.';

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
      '펜스 안에 YAML 또는 JSON 콘텐츠를 사용하세요. BusyMark는 임의의 전체 YAML 또는 JSON 문서를 OpenAPI 참조로 취급하지 않습니다.';

  @override
  String get syntaxReferenceSemanticDiagramBlocks => '다이어그램용 의미론적 코드 블록';

  @override
  String get syntaxReferenceSemanticDiagramLimitation =>
      '의미론적 code-block 및 src 형식은 Mermaid, PlantUML 및 D2만 지원하고 OpenAPI는 지원하지 않으며 Writerside 프로젝트 안에서만 작동합니다.';

  @override
  String get syntaxReferenceReferencedDiagramSource => '참조된 다이어그램 소스';

  @override
  String get syntaxReferenceReferencedDiagramLimitation =>
      '경로는 상대 경로여야 하고 열린 Writerside 프로젝트 안에 있어야 합니다. 펜스와 src 형식은 Writerside Markdown 전용입니다.';

  @override
  String get syntaxReferenceMathematicsDescription =>
      'BusyMark는 TeX 수식을 지원하지만 완전한 TeX 또는 LaTeX 문서는 지원하지 않습니다.';

  @override
  String get syntaxReferenceInlineMath => '인라인 수식';

  @override
  String get syntaxReferenceGithubMath => '달러와 백틱을 사용하는 GitHub 수식';

  @override
  String get syntaxReferenceDisplayMath => '표시 수식';

  @override
  String get syntaxReferenceMathFence => 'math 펜스';

  @override
  String get syntaxReferenceTexFence => 'tex 펜스';

  @override
  String get syntaxReferenceMathDelimitersLimitation =>
      'BusyMark는 \\(...\\) 또는 \\[...\\]를 Markdown 수식 구분자로 인식하지 않습니다.';

  @override
  String get syntaxReferenceTexFenceLimitation =>
      'Writerside 모드 밖에서는 tex 펜스가 일반 코드 블록으로 남습니다.';

  @override
  String get syntaxReferenceWritersideMathElement => 'Writerside math 요소';

  @override
  String get syntaxReferenceWritersideMathElementLimitation =>
      'math 요소는 의미론적 Writerside 구문이며 허용된 원시 HTML MathML이 아닙니다.';

  @override
  String get syntaxReferenceSemanticTexBlock => '의미론적 TeX 코드 블록';

  @override
  String get syntaxReferenceWritersideDescription =>
      '이 확장 기능은 열린 Writerside 프로젝트 안에서만 해석됩니다.';

  @override
  String get syntaxReferenceAdmonitionBlockquote => '알림 인용구';

  @override
  String get syntaxReferenceAdmonitionLimitation =>
      '일반 블록 인용은 Writerside Markdown에서는 팁이고 일반 Markdown에서는 일반 인용으로 남습니다.';

  @override
  String get syntaxReferenceSemanticAdmonitions => '의미론적 알림';

  @override
  String get syntaxReferenceSemanticMarkupLimitation =>
      '일반 Markdown은 이러한 Writerside 의미론적 요소를 해석하지 않습니다.';

  @override
  String get syntaxReferenceCollapsibleHeading => '접을 수 있는 제목';

  @override
  String get syntaxReferenceCollapsibleCode => '접을 수 있는 코드 펜스';

  @override
  String get syntaxReferenceSemanticCollapsibles => '의미론적 접이식 콘텐츠';

  @override
  String get syntaxReferenceSemanticCollapsiblesLimitation =>
      'BusyMark는 접을 수 있는 chapter, procedure, code-block 및 정의 목록 형식을 지원하지만 전체 Writerside 카탈로그를 지원하지는 않습니다.';

  @override
  String get syntaxReferenceSemanticCodeBlocks => '수식 및 다이어그램용 의미론적 코드 블록';

  @override
  String get syntaxReferenceVideo => 'Writerside 동영상';

  @override
  String get syntaxReferenceVideoLimitation =>
      '로컬 동영상은 로컬 preview-src 이미지를 사용합니다. 호스팅 동영상은 지원되는 YouTube 또는 Vimeo HTTPS URL이어야 합니다.';

  @override
  String get exportAsPdf => 'PDF로 내보내기';

  @override
  String get pdfExportDescription => '세련된 독립형 PDF를 위한 페이지 레이아웃을 선택하세요.';

  @override
  String get pdfRemoteImagesNote =>
      '내보내기 중에는 원격 이미지가 다운로드되지 않습니다. 가능한 경우 로컬 이미지가 포함됩니다.';

  @override
  String get pdfPageSize => '페이지 크기';

  @override
  String get pdfPageSizeA4 => 'A4';

  @override
  String get pdfPageSizeLetter => 'Letter';

  @override
  String get pdfOrientation => '방향';

  @override
  String get pdfPortrait => '세로';

  @override
  String get pdfLandscape => '가로';

  @override
  String get pdfMargins => '여백';

  @override
  String get pdfMarginNarrow => '좁게';

  @override
  String get pdfMarginNormal => '보통';

  @override
  String get pdfMarginWide => '넓게';

  @override
  String get pdfIncludePageNumbers => '페이지 번호 포함';

  @override
  String get export => '내보내기';

  @override
  String get exportingPdf => 'PDF 내보내기 중…';

  @override
  String get fileTypePdf => 'PDF 문서';

  @override
  String pdfExported(String fileName) {
    return '$fileName을(를) 내보냈습니다.';
  }

  @override
  String pdfExportedWithWarnings(String fileName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '경고 $count개',
      one: '경고 1개',
    );
    return '$fileName을(를) $_temp0와 함께 내보냈습니다.';
  }

  @override
  String get pdfExportUnavailable =>
      'PDF 내보내기 구성 요소가 누락되었습니다. BusyMark를 다시 설치하고 다시 시도하세요.';

  @override
  String get pdfExportTimedOut => 'PDF 내보내기가 너무 오래 걸려 중지되었습니다.';

  @override
  String get pdfExportFailed => 'BusyMark가 이 문서를 PDF로 내보낼 수 없습니다.';

  @override
  String get visualizationRendering => '렌더링 중…';

  @override
  String get visualizationStale => '마지막으로 유효한 렌더링 표시 중';

  @override
  String get visualizationShowSource => '소스 표시';

  @override
  String get visualizationShowRender => '렌더링 표시';

  @override
  String get visualizationFitWidth => '너비에 맞추기';

  @override
  String get visualizationSaveImage => '이미지 저장';

  @override
  String get visualizationCopyImage => '이미지 복사';

  @override
  String get visualizationImageCopied => '이미지가 복사됨';

  @override
  String get visualizationOpenApiReference => 'OpenAPI 참조 열기';

  @override
  String get visualizationValid => '유효함';

  @override
  String get visualizationInvalid => '유효하지 않음';

  @override
  String get visualizationServers => '서버';

  @override
  String get visualizationPaths => '경로';

  @override
  String get visualizationOperations => '작업';

  @override
  String get visualizationTags => '태그';

  @override
  String get visualizationNoOperations => '일치하는 작업 없음';

  @override
  String get visualizationSearchOperations => '작업 검색';

  @override
  String get visualizationRenderFailed => '이 시각화를 렌더링할 수 없습니다.';

  @override
  String get visualizationRetry => '다시 시도';

  @override
  String visualizationSaved(String fileName) {
    return '$fileName을(를) 저장했습니다.';
  }

  @override
  String get shortcutExportPdfDescription =>
      '활성 문서 또는 Writerside 모듈을 PDF로 내보냅니다.';

  @override
  String get instances => '인스턴스';

  @override
  String get newInstance => '새 인스턴스';

  @override
  String get newTocLibrary => '새 목차 라이브러리';

  @override
  String get editInstance => '인스턴스 편집';

  @override
  String get openTocFile => '목차 파일 열기';

  @override
  String get createInstance => '인스턴스 만들기';

  @override
  String get createTocLibrary => '목차 라이브러리 만들기';

  @override
  String get instanceContent => '콘텐츠';

  @override
  String get instanceContentSource => '생성 원본';

  @override
  String get emptyInstance => '빈 인스턴스';

  @override
  String get markdownFiles => '로컬 Markdown 파일';

  @override
  String get chooseMarkdownFolder => 'Markdown 폴더 선택';

  @override
  String get errorWritersideInstanceImportSourceRequired =>
      'Markdown 파일이 포함된 폴더를 선택합니다.';

  @override
  String get instanceAppearance => '화면 모양';

  @override
  String get instanceColor => '아이콘 색상';

  @override
  String get instanceVersion => '버전';

  @override
  String instanceVersionInherited(String version) {
    return '이 필드가 비어 있으면 프로젝트 버전은 $version입니다.';
  }

  @override
  String get instanceWebPath => '웹 경로';

  @override
  String get instanceStatus => '상태';

  @override
  String get instanceStatusRelease => '릴리스';

  @override
  String get instanceStatusEap => '얼리 액세스';

  @override
  String get instanceStatusDeprecated => '더 이상 사용되지 않음';

  @override
  String get allowSearchEngineIndexing => '검색 엔진 색인 생성 허용';

  @override
  String get allowSearchEngineIndexingDescription =>
      '외부 검색 엔진이 이 출력을 색인화하도록 허용합니다.';

  @override
  String get offlineArtifact => '오프라인 아티팩트';

  @override
  String get offlineArtifactDescription => '빌드된 문서가 자체적으로 포함되도록 리소스를 번들로 묶습니다.';

  @override
  String get instanceOutputSettings => '출력 설정';

  @override
  String get markdownImportSource => 'Markdown 소스';

  @override
  String get markdownImportFiles => 'Markdown 파일';

  @override
  String get selectNone => '선택 안 함';

  @override
  String markdownFilesFound(int count) {
    return '$count개의 마크다운 파일을 찾았습니다.';
  }

  @override
  String get noMarkdownFilesFound => '이 디렉터리에서 Markdown 파일을 찾을 수 없습니다.';

  @override
  String get copyReferencedMedia => '참조된 미디어 복사';

  @override
  String get copyReferencedMediaDescription =>
      '상대 경로를 유지하면서 선택한 파일이 참조하는 로컬 이미지와 비디오를 복사합니다.';

  @override
  String get instanceIdRenameWarningTitle => '인스턴스 ID의 이름을 바꾸시겠습니까?';

  @override
  String instanceIdRenameWarning(String oldId, String newId) {
    return 'BusyMark는 .tree 파일의 이름을 바꾸고 Writerside 프로젝트 참조를 \"$oldId\"에서 \"$newId\"로 업데이트합니다. 게시 스크립트는 변경되지 않으며 별도로 업데이트해야 합니다.';
  }

  @override
  String get renameAndUpdateReferences => '이름 변경 및 참조 업데이트';

  @override
  String get tocLibraryDescription =>
      'TOC 라이브러리는 재사용 가능한 섹션을 저장하고 자체 출력을 생성하지 않습니다.';

  @override
  String get defaultTocLibraryName => '공유 목차';

  @override
  String get instanceColorAutomatic => '자동';

  @override
  String get instanceColorBlue => '파란색';

  @override
  String get instanceColorGreen => '녹색';

  @override
  String get instanceColorOrange => '주황색';

  @override
  String get instanceColorPurple => '보라색';

  @override
  String get instanceColorRed => '빨간색';

  @override
  String get instanceColorTeal => '청록색';

  @override
  String get instanceColorYellow => '노란색';

  @override
  String get errorWritersideInstanceNameRequired => '인스턴스 이름을 입력하세요.';

  @override
  String errorWritersideInstanceIdExists(String id) {
    return 'ID가 \"$id\"인 인스턴스가 이미 존재합니다.';
  }

  @override
  String errorWritersideInstanceTreeExists(String path) {
    return '인스턴스 트리가 이미 존재합니다: $path';
  }

  @override
  String errorWritersideInstanceImportSourceMissing(String path) {
    return 'Markdown 소스 디렉터리가 존재하지 않습니다: $path';
  }

  @override
  String get errorWritersideInstanceImportSelectionRequired =>
      '가져올 Markdown 파일을 하나 이상 선택하세요.';

  @override
  String errorWritersideInstanceImportFileInvalid(String path) {
    return '선택한 소스: $path 내에서 읽을 수 있는 Markdown 파일이 아닙니다.';
  }

  @override
  String errorWritersideInstanceImportTargetExists(String path) {
    return '가져오기를 하면 기존 프로젝트 파일을 덮어쓰게 됩니다: $path';
  }

  @override
  String get errorWritersideInstanceFilesChanged =>
      '인스턴스 파일이 디스크에서 변경되었습니다. 검토한 후 다시 시도하세요.';

  @override
  String errorWritersideInstanceRollbackFailed(String paths) {
    return 'BusyMark가 인스턴스 변경 사항을 완전히 롤백할 수 없습니다. 계속하기 전에 다음 파일을 검토하세요. $paths';
  }

  @override
  String get errorWritersideInstanceLibraryImport =>
      'TOC 라이브러리는 Markdown 항목을 가져올 수 없습니다.';

  @override
  String get errorWritersideInstanceWebPathInvalid => '웹 경로는 한 줄이어야 합니다.';

  @override
  String get errorWritersideInstanceConfigurationInvalid =>
      'Writerside 인스턴스 구성이 잘못되었습니다. 진단을 수정하고 다시 시도하십시오.';

  @override
  String get errorWritersideInstanceTemporaryFile =>
      'BusyMark가 인스턴스 변경 사항을 안전하게 스테이징할 수 없습니다.';

  @override
  String diagnosticWritersideTreeInvalidStatus(String status) {
    return '알 수 없는 인스턴스 상태 “$status”. release, eap 또는 deprecated를 사용하세요.';
  }

  @override
  String diagnosticWritersideDuplicateInstanceId(String id) {
    return '인스턴스 ID \"$id\"는 둘 이상의 트리 파일에서 사용됩니다.';
  }

  @override
  String get diagnosticWritersideBuildProfilesInvalidRoot =>
      'buildprofiles.xml에는 <buildprofiles> 루트 요소가 있어야 합니다.';

  @override
  String diagnosticWritersideBuildProfilesInvalidBoolean(
    String name,
    String value,
  ) {
    return '설정 값 $name “$value”는 true 또는 false 여야 합니다.';
  }

  @override
  String get diagnosticWritersideBuildProfileMissingInstance =>
      '<build-profile> 요소는 인스턴스 ID를 지정해야 합니다.';

  @override
  String get diagnosticWritersideTreeInvalidInclude =>
      '트리 <include>는 from과 element-id를 모두 지정해야 합니다.';

  @override
  String get diagnosticWritersideTreeMissingSnippetId =>
      '트리 <snippet>은 ID를 지정해야 합니다.';

  @override
  String get diagnosticWritersideTreeInvalidCrossInstanceReference =>
      '인스턴스 간 TOC 참조는 ref와 in을 모두 지정해야 합니다.';

  @override
  String get diagnosticWritersideTreeConflictingTargets =>
      '목차 요소는 둘 이상의 토픽, 참조, 링크 또는 리디렉션을 대상으로 할 수 없습니다.';

  @override
  String diagnosticWritersideTreeDuplicateElementId(String id) {
    return '트리 요소 ID “$id”이(가) 두 번 이상 선언되었습니다.';
  }

  @override
  String get diagnosticWritersideInstanceGroupsInvalidRoot =>
      '인스턴스 그룹 파일에는 <instance-groups> 루트 요소가 있어야 합니다.';

  @override
  String get diagnosticWritersideInstanceGroupInvalid =>
      '인스턴스 그룹은 비어 있지 않은 ID와 인스턴스 목록을 지정해야 합니다.';

  @override
  String diagnosticWritersideInstanceGroupDuplicateId(String id) {
    return '인스턴스 그룹 ID “$id”이(가) 두 번 이상 선언되었습니다.';
  }

  @override
  String diagnosticWritersideExternalTreeInclude(
    String source,
    String id,
    String origin,
  ) {
    return '목차 포함 “$source#$id”는 외부 모듈 “$origin”에 속하며 이 작업공간에서 확장할 수 없습니다.';
  }

  @override
  String diagnosticWritersideTreeIncludeElementMissing(
    String source,
    String id,
  ) {
    return '등록된 트리 \"$source\"에 트리 요소 \"$id\"이(가) 존재하지 않습니다.';
  }

  @override
  String diagnosticWritersideTreeCircularInclude(String source, String id) {
    return '트리 포함 “$source#$id”는 주기를 생성합니다.';
  }

  @override
  String diagnosticWritersideUnknownInstanceGroup(String group) {
    return '인스턴스 조건이 알 수 없는 그룹 \"@$group\"을 참조합니다.';
  }

  @override
  String diagnosticWritersideReferenceInstanceMissing(String instance) {
    return '인스턴스 간 참조는 알 수 없는 인스턴스 “$instance”를 대상으로 합니다.';
  }

  @override
  String diagnosticWritersideReferenceTopicMissing(
    String topic,
    String instance,
  ) {
    return '\"$topic\" 토픽이 참조된 인스턴스 \"$instance\"에 없습니다.';
  }

  @override
  String get download => '다운로드';

  @override
  String get exportWritersideAsPdf => 'Writerside를 PDF로 내보내기';

  @override
  String get writersidePdfContent => '콘텐츠 내보내기';

  @override
  String get writersidePdfPage => '페이지';

  @override
  String get exportingWritersidePdf => 'Writerside PDF를 내보내는 중…';

  @override
  String get ai => 'AI';

  @override
  String get aiLocalOllama => '로컬 Ollama';

  @override
  String get aiDisabled => '사용 안 함';

  @override
  String get aiExplicitEditingDescription =>
      'AI 편집은 명시적입니다. BusyMark는 선택한 공급자에 대해 표시된 컨텍스트만 보내고 검토 없이 제안을 적용하지 않습니다.';

  @override
  String get aiProvider => 'AI 제공업체';

  @override
  String get aiDefaultProvider => '기본 공급자';

  @override
  String get aiConfigureProvider => '공급자 구성';

  @override
  String get aiChooseProvider => 'AI 제공업체 선택';

  @override
  String get aiOllamaEndpoint => 'Ollama 엔드포인트';

  @override
  String get aiOllamaModel => 'Ollama 모델';

  @override
  String get aiTestConnection => '테스트 연결';

  @override
  String get aiTestingConnection => '테스트 중…';

  @override
  String aiConnectionReady(int count) {
    return '연결되었습니다. 설치된 모델 $count개를 찾았습니다.';
  }

  @override
  String get aiNoModels => '선택한 모델이 없습니다.';

  @override
  String get aiConnectionFailed => 'BusyMark가 AI 텍스트 생성을 확인할 수 없습니다.';

  @override
  String get aiConfigureFirst => 'AI 제공자를 활성화하고 설정 → AI에서 모델을 확인하세요.';

  @override
  String get aiEditWithAi => 'AI로 편집';

  @override
  String get aiRefineWithAi => 'AI로 개선';

  @override
  String get aiInstruction => '지침';

  @override
  String get aiChangeTarget => '무엇이 바뀔 수 있나요?';

  @override
  String get aiSharedContext => 'AI와 컨텍스트 공유';

  @override
  String get aiTargetSelection => '선택한 콘텐츠';

  @override
  String get aiTargetInsertAfterBlock => '현재 블록 뒤에 삽입';

  @override
  String get aiTargetCurrentBlock => '현재 블록';

  @override
  String get aiTargetCurrentSection => '현재 섹션';

  @override
  String get aiTargetCompleteDocument => '전체 문서';

  @override
  String get aiContextNone => '문서 컨텍스트 없음';

  @override
  String get aiContextSelection => '선택한 콘텐츠';

  @override
  String get aiContextCurrentBlock => '현재 블록';

  @override
  String get aiContextCurrentSection => '현재 섹션';

  @override
  String get aiContextCompleteDocument => '전체 문서';

  @override
  String get aiGenerating => '제안 생성 중…';

  @override
  String get aiProposal => 'AI 제안';

  @override
  String get aiGenerateProposal => '제안 생성';

  @override
  String aiContextDisclosure(int count) {
    return '선택한 공급자는 표시된 컨텍스트에서 $count자를 수신합니다.';
  }

  @override
  String get aiOriginal => '원본';

  @override
  String get aiSuggested => '제안';

  @override
  String get aiApplyProposal => '제안 적용';

  @override
  String aiTokenUsage(int input, int output) {
    return '$input 입력 토큰 · $output 출력 토큰';
  }

  @override
  String get aiStaleProposal => '이 제안이 생성되는 동안 문서가 변경되었습니다. 작업을 다시 실행하십시오.';

  @override
  String get gitAiStagedChangesChanged =>
      '스테이징된 변경 사항이 이 커밋 메시지 생성 중에 변경되었습니다. 작업을 다시 실행하세요.';

  @override
  String get aiViewContext => '전송된 컨텍스트 보기';

  @override
  String get aiReviewExactContent => '정확한 내용을 검토하세요';

  @override
  String get aiContentToChange => '변경할 내용';

  @override
  String get aiContentSentToAi => 'AI로 전송된 콘텐츠';

  @override
  String get aiApiKey => 'API 키';

  @override
  String get aiApiKeyStoredHint => '키는 시스템 자격 증명 저장소에 저장됩니다.';

  @override
  String get aiApiKeyEnterHint => '공급자 API 키를 입력하세요.';

  @override
  String get aiReplaceApiKey => 'API 키 교체';

  @override
  String get aiSaveApiKey => 'API 키를 안전하게 저장';

  @override
  String get aiRemoveApiKey => '저장된 API 키 제거';

  @override
  String get aiCredentialSaved => '시스템 자격 증명 저장소에 저장된 API 키입니다.';

  @override
  String get aiCredentialRemoved => '저장된 API 키가 삭제되었습니다.';

  @override
  String get aiModelRouting => '모델 라우팅';

  @override
  String get aiAutomaticRouting => '작업별 자동';

  @override
  String get aiFixedModelRouting => '선택한 모델 사용';

  @override
  String get aiPreferredModel => '선호하는 모델';

  @override
  String get aiModel => '모델';

  @override
  String aiUsageThisMonth(int requests, int input, int output) {
    return '$requests 요청 · $input 입력 토큰 · $output 출력 토큰';
  }

  @override
  String aiCloudConsentTitle(String provider) {
    return '$provider에 콘텐츠를 보내시겠습니까?';
  }

  @override
  String aiCloudConsentEnable(String provider) {
    return '$provider 활성화';
  }

  @override
  String get aiCloudConsentMessage =>
      '각 AI 검토 대화 상자에 표시된 콘텐츠만 전송됩니다. 요청은 상태 비저장이고 제안에는 검토가 필요하며 API 키는 Linux 시스템 자격 증명 저장소에 저장됩니다.';

  @override
  String aiCloudConsentRequired(String provider) {
    return '먼저 설정 → AI에서 $provider 데이터 공유를 확인하세요.';
  }

  @override
  String aiGenerationVerified(String model, int count) {
    return '$model로 생성을 확인했습니다. 호환 가능한 모델 $count개를 사용할 수 있습니다.';
  }

  @override
  String get aiColdStartObserved => '로컬 모델 콜드 스타트가 관찰되었습니다.';

  @override
  String get aiNoCompatibleModels => '호환 가능한 텍스트 생성 모델이 없습니다.';

  @override
  String get aiEnableProvider => '먼저 AI 제공자를 활성화하세요.';

  @override
  String get aiDraftCommitMessage => '초안 커밋 메시지';

  @override
  String get aiDrafting => '작성 중…';

  @override
  String get aiDraftWithAi => 'AI를 활용한 초안';

  @override
  String get generateOrUpdateMarkdownToc => '목차 생성/업데이트';

  @override
  String get markdownTocTitle => '목차';

  @override
  String markdownTocUpdated(int count) {
    return '$count개의 항목으로 목차가 업데이트되었습니다.';
  }

  @override
  String get markdownTocNoHeadings => '목차를 생성하기 전에 하나 이상의 섹션 제목을 추가하세요.';

  @override
  String get markdownTocMalformedMarkers =>
      'BusyMark 목차 표시가 없거나 중복되었거나 순서가 잘못되었습니다.';

  @override
  String diagnosticMarkdownHeadingSkippedLevel(int level, int previousLevel) {
    return '제목 수준 $level은(는) $previousLevel 수준을 따릅니다. 섹션 중첩을 검토하세요.';
  }

  @override
  String get diagnosticMarkdownLinkEmptyText =>
      '링크 텍스트가 비어 있습니다. 링크의 목적을 설명하는 접근 가능한 이름을 제공하세요.';

  @override
  String diagnosticMarkdownLinkReviewText(String text) {
    return '링크 텍스트 \"$text\"가 문맥상 목적을 설명하는지 검토하세요.';
  }

  @override
  String get diagnosticMarkdownTableEmptyHeader =>
      '테이블 머리글 셀은 해당 열을 식별해야 합니다. 각각의 빈 헤더를 완성하세요.';

  @override
  String get mathRenderFailed => '수학적 표현을 렌더링할 수 없습니다.';

  @override
  String get inlineMath => '인라인 수학';

  @override
  String get displayMath => '수학 표시';
}
